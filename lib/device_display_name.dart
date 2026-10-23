import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'src/android_name_choice.dart';
import 'src/device_kind.dart';
import 'src/ios_name_choice.dart';
import 'src/labels.dart' as labels;

export 'src/android_name_choice.dart'
    show
        AndroidKeys,
        AndroidNameSources,
        chooseAndroidName,
        androidKeysFor,
        androidKeysOfAllMakers,
        androidKeysByMaker;
export 'src/device_kind.dart' show DeviceKind, androidKind, iosKind;
export 'src/ios_name_choice.dart' show chooseIosName;
export 'src/labels.dart' show distinctLabels, userAgentToken;

/// Where a [DisplayName] was taken from.
enum NameSource {
  /// A settings value the maker fills with the factory name
  /// (`Settings.Global default_device_name` on Samsung).
  factorySetting,

  /// A system property the maker fills with the marketing name
  /// (`ro.product.marketname` on Xiaomi, `ro.config.marketing_name` on Huawei).
  vendorProperty,

  /// `Build.MODEL`, which already is a name on this device ("Pixel 9").
  model,

  /// The name the user gave the device. Only with [UserAssignedName.fallback]
  /// or [UserAssignedName.preferred].
  userAssigned,

  /// The brand and the hardware code ("Samsung SM-G525F"): nothing better was found.
  brandAndModel,

  /// The table of Apple hardware identifiers.
  identifierTable,

  /// The Apple hardware identifier itself ("iPhone19,2"): the table does not know it yet.
  identifier,
}

/// Where the name the user gave the device ("Anna's XCover 5") goes among the
/// sources. Android only: an iOS app cannot read it without a special Apple
/// entitlement, and gets the model name either way.
enum UserAssignedName {
  /// Never used. The default: the name can carry a person's name.
  never,

  /// Used when the maker's name is not found and `Build.MODEL` is only a code,
  /// before falling back to the brand and the code.
  fallback,

  /// Used first, ahead of the maker's name - for a list of the user's own
  /// devices, where the name they chose tells them apart best. A value that is
  /// only a code, or carries `Build.MODEL` (a default such as
  /// "samsung SM-G525F"), is passed over, so a device that was never renamed
  /// still gets its marketing name.
  preferred,
}

/// The name a person knows their device by, and where it came from.
@immutable
final class DisplayName {
  const DisplayName(
    this.name,
    this.source, {
    this.key,
    String? fullName,
    this.kind = DeviceKind.unknown,
    // A named parameter cannot be private, so the field is set from it.
    // ignore: prefer_initializing_formals
  }) : _fullName = fullName;

  /// "Redmi 9A", "Galaxy XCover 5", "iPhone 12 mini" - as the maker writes it.
  ///
  /// May contain any character a maker puts in a name, parentheses included
  /// ("Lenovo Tab M8 (4th Gen)"); escape it for the place it goes to, or use
  /// [userAgentToken].
  final String name;

  final NameSource source;

  /// The settings or property key, or the Apple identifier, the name was read from.
  final String? key;

  final String? _fullName;

  /// [name] with the brand in front when the maker leaves it out
  /// ("Samsung Galaxy S26", "Google Pixel 9"), in the maker's own spelling.
  /// The name the user gave the device is kept as it is.
  String get fullName => _fullName ?? name;

  /// Phone, tablet, foldable, watch, TV and so on - for an icon or a word
  /// next to the name.
  final DeviceKind kind;

  /// Whether [name] is a real marketing name rather than a code put together
  /// from what was left.
  bool get isMarketingName =>
      source != NameSource.brandAndModel && source != NameSource.identifier;

  /// [fullName] safe for a User-Agent header: no `;`, `(` or `)`, ASCII only
  /// (the rest percent-encoded as UTF-8).
  String get userAgentToken => labels.userAgentToken(fullName);

  /// Equality covers [name], [source] and [key]; [fullName] and [kind] are
  /// read from the same device and follow from them.
  @override
  bool operator ==(Object other) =>
      other is DisplayName &&
      other.name == name &&
      other.source == source &&
      other.key == key;

  @override
  int get hashCode => Object.hash(name, source, key);

  @override
  String toString() =>
      'DisplayName($name, ${source.name}${key == null ? '' : ', $key'}, ${kind.name})';
}

/// Gives the marketing name of the device the app runs on.
abstract interface class DeviceDisplayName {
  /// The name of this device, or null where the platform is not supported or
  /// could not be asked.
  ///
  /// Never throws. On Android and iOS a name is always given, at worst the
  /// brand and the hardware code - see [DisplayName.isMarketingName].
  Future<DisplayName?> read();
}

/// [DeviceDisplayName] answered by the platform side of this plugin.
///
/// The platform side only reads what the device carries; the choice among the
/// values is made here, in [chooseAndroidName] and [chooseIosName].
class PlatformDeviceDisplayName implements DeviceDisplayName {
  const PlatformDeviceDisplayName({
    this.userAssignedName = UserAssignedName.never,
  });

  /// Whether and where the name the user gave the device is used. It can
  /// carry a person's name, so it is off unless the app asks.
  final UserAssignedName userAssignedName;

  static const MethodChannel _methodChannel = MethodChannel(
    'device_display_name',
  );

  /// What the platform gave once. It cannot change while the process lives,
  /// so the platform is asked once; a failure is not kept.
  static Map<Object?, Object?>? _known;

  /// Forgets what was kept from an earlier call.
  @visibleForTesting
  static void debugForget() => _known = null;

  @override
  Future<DisplayName?> read() async {
    final raw = await readSources();
    if (raw == null) return null;

    try {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        final machine = raw['machine'] as String?;
        return machine == null || machine.isEmpty
            ? null
            : chooseIosName(machine, idiom: raw['idiom'] as String?);
      }
      return chooseAndroidName(
        AndroidNameSources.fromMap(raw),
        userAssignedName: userAssignedName,
      );
    } catch (_) {
      // A platform side of another version answering in another shape.
      return null;
    }
  }

  /// Everything the platform side read, as it read it, or null where the
  /// platform is not supported or could not be asked. For diagnostics: it shows
  /// which keys a new device fills.
  ///
  /// [allMakerKeys] reads every maker's keys instead of the device's own - for
  /// a device of a maker not listed, which may reuse another maker's keys. It
  /// leaves "Access denied" lines in the device log for the blocked ones, and
  /// is not kept for [read].
  Future<Map<Object?, Object?>?> readSources({
    bool allMakerKeys = false,
  }) async {
    final known = _known;
    if (known != null && !allMakerKeys) return known;

    try {
      if (kIsWeb) return null;
      final Map<Object?, Object?>? raw;
      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
          // One call: the platform side picks the keys of the device's maker
          // from the table by Build.BRAND, then Build.MANUFACTURER.
          final table = allMakerKeys
              ? {null: androidKeysOfAllMakers()}
              : androidKeysByMaker();
          raw = await _methodChannel.invokeMapMethod<Object?, Object?>('read', {
            'keysByMaker': {
              for (final MapEntry(:key, :value) in table.entries)
                key: {
                  'properties': value.properties,
                  'globalSettings': value.globalSettings,
                },
            },
            'features': androidKindFeatures,
          });
        case TargetPlatform.iOS:
          raw = await _methodChannel.invokeMapMethod<Object?, Object?>('read');
        default:
          return null;
      }
      if (raw == null || allMakerKeys) return raw;
      return _known = raw;
    } catch (_) {
      // The native side refused, the plugin is not registered in this isolate,
      // the binding is not up yet: no name from here, and the caller falls back.
      return null;
    }
  }
}
