import '../device_display_name.dart';
import 'device_kind.dart';

/// What an Android device carries that can name it, read by the platform side.
///
/// Only values that were present and not blank are kept: a key missing from
/// [properties] or [globalSettings] was empty, unset or not readable by the app.
final class AndroidNameSources {
  const AndroidNameSources({
    required this.manufacturer,
    required this.brand,
    required this.model,
    this.device = '',
    this.product = '',
    this.properties = const {},
    this.globalSettings = const {},
    this.features = const {},
    this.smallestScreenWidthDp,
    this.characteristics = '',
  });

  factory AndroidNameSources.fromMap(Map<Object?, Object?> map) {
    Map<String, String> strings(Object? value) => {
      if (value is Map)
        for (final MapEntry(:key, :value) in value.entries)
          if (key is String && value is String) key: value,
    };

    return AndroidNameSources(
      manufacturer: map['manufacturer'] as String? ?? '',
      brand: map['brand'] as String? ?? '',
      model: map['model'] as String? ?? '',
      device: map['device'] as String? ?? '',
      product: map['product'] as String? ?? '',
      properties: strings(map['properties']),
      globalSettings: strings(map['globalSettings']),
      features: {
        if (map['features'] case final List<Object?> list)
          for (final f in list)
            if (f is String) f,
      },
      smallestScreenWidthDp: map['smallestScreenWidthDp'] as int?,
      characteristics: map['characteristics'] as String? ?? '',
    );
  }

  /// `Build.MANUFACTURER`.
  final String manufacturer;

  /// `Build.BRAND`.
  final String brand;

  /// `Build.MODEL`.
  final String model;

  /// `Build.DEVICE`.
  final String device;

  /// `Build.PRODUCT`.
  final String product;

  /// System properties by key.
  final Map<String, String> properties;

  /// `Settings.Global` values by key.
  final Map<String, String> globalSettings;

  /// The system features of [androidKindFeatures] the device has.
  final Set<String> features;

  /// `Configuration.smallestScreenWidthDp`.
  final int? smallestScreenWidthDp;

  /// `ro.build.characteristics`: "tablet", "tv", "watch", "automotive",
  /// "default", sometimes with more after a comma ("tablet,nosdcard").
  final String characteristics;
}

/// Where a maker keeps the factory name of its devices.
///
/// Every key here was found holding a marketing name in real firmware or on a
/// real device. A key of one maker is not tried on another: on a foreign device it is either unset or
/// holds something else.
final class _Maker {
  const _Maker(
    this.names, {
    this.settings = const [],
    this.properties = const [],
  });

  /// Lower-case values of `Build.BRAND` or `Build.MANUFACTURER` the maker ships under.
  final List<String> names;

  /// `Settings.Global` keys holding the factory name, in the order to try.
  final List<String> settings;

  /// System property keys holding the factory name, in the order to try.
  final List<String> properties;
}

const _xiaomiProperties = [
  'ro.product.marketname',
  'ro.product.odm.marketname',
  'ro.product.vendor.marketname',
  'ro.product.product.marketname',
  'ro.product.system.marketname',
];

const _makers = [
  // One UI keeps no marketing name in any system property; the factory name is
  // a settings value next to the user-editable `device_name`.
  _Maker(['samsung'], settings: ['default_device_name']),
  _Maker(
    ['huawei', 'honor'],
    settings: ['unified_default_device_name'],
    properties: ['ro.config.marketing_name'],
  ),
  // The system and product copies are the first to hold a codename or "TBD"
  // instead of the name, so they come last.
  _Maker([
    'xiaomi',
    'redmi',
    'poco',
    'blackshark',
  ], properties: _xiaomiProperties),
  // The English name first: `market.name` is in Chinese on some ColorOS builds.
  _Maker(
    ['oppo', 'realme', 'oneplus'],
    properties: [
      'ro.vendor.oplus.market.enname',
      'ro.vendor.oplus.market.name',
      'ro.vendor.oppo.market.name',
      'ro.oppo.market.enname',
      'ro.oppo.market.name',
      'ro.display.series',
    ],
  ),
  // Funtouch keeps its name properties from apps (none was readable on four
  // vivo phones, Android 11-14); the factory hotspot name is the one readable
  // place the name shows up ("vivo V30"), and only on some models.
  _Maker(
    ['vivo', 'iqoo'],
    settings: ['wifi_hotspot_default_name'],
    properties: [
      'ro.vivo.internet.name',
      'ro.vivo.market.name',
      'ro.vivo.product.release.name',
    ],
  ),
  _Maker(
    ['zte', 'nubia'],
    properties: ['ro.vendor.product.ztename', 'ro.product.ztename'],
  ),
  _Maker(
    ['tecno', 'infinix', 'itel'],
    properties: [
      'ro.vendor.tran.device.name',
      'ro.product.tran.device.name',
      'ro.product.product.tran.device.name.default',
      'ro.product.system_ext.tran.device.name.default',
      'ro.transsion.device.name',
      'transsion.device.name',
    ],
  ),
  // Lenovo and Motorola are one company with separate firmware: each one's
  // keys are blocked on the other (ro.vendor.product.display on a Lenovo tab).
  _Maker(
    ['lenovo'],
    properties: [
      'ro.odm.lenovo.series',
      'ro.lenovo.series',
      'ro.zuk.product.market',
      'ro.product.en.display',
    ],
  ),
  _Maker(
    ['motorola'],
    properties: ['ro.vendor.product.display', 'ro.product.display'],
  ),
  _Maker(
    ['hmd', 'hmd global', 'nokia'],
    properties: [
      'ro.product.nickname',
      'ro.build.model.displayname',
      'ro.vendor.product.nickname',
    ],
  ),
  _Maker(['sony'], properties: ['ro.semc.product.name']),
  _Maker(
    ['asus'],
    properties: ['ro.asus.product.mkt_name', 'ro.vendor.asus.product.mkt_name'],
  ),
  _Maker(['lge', 'lg'], properties: ['ro.lge.petname']),
  _Maker(
    ['umidigi'],
    properties: [
      'persist.sys.umicustom.model',
      'persist.vendor.umicustom.model',
    ],
  ),
];

/// Tried on a device of a maker not listed above: custom firmware of small
/// brands reuses the Xiaomi keys.
const _anyMakerProperties = [
  'ro.product.marketname',
  'ro.product.odm.marketname',
];

/// Names the user gives the device, read only when the app asks for them.
const _userAssignedSetting = 'device_name';
const _userAssignedProperty = 'persist.sys.device_name';

/// The system properties the choice tries for the factory name on a device of
/// [maker]: the maker's own, or the generic marketname keys for a maker not
/// listed. The one place both the reading and the choice take them from.
List<String> _propertiesOf(_Maker? maker) =>
    maker?.properties ?? _anyMakerProperties;

List<String> _settingsOf(_Maker? maker) => maker?.settings ?? const [];

typedef AndroidKeys = ({List<String> properties, List<String> globalSettings});

AndroidKeys _keysOf(_Maker? maker) => (
  properties: [..._propertiesOf(maker), _userAssignedProperty],
  globalSettings: [..._settingsOf(maker), _userAssignedSetting],
);

/// The keys the choice looks at on a device of [manufacturer] and [brand].
///
/// Only the device's own maker's keys: a vendor key of another maker is not
/// just unset there but usually blocked by SELinux, and every blocked read
/// leaves an "Access denied finding property" line in the device log.
AndroidKeys androidKeysFor({
  required String manufacturer,
  required String brand,
}) => _keysOf(_makerOf(brand: brand, manufacturer: manufacturer));

/// Every key of every maker, for diagnostics on a device of a maker not
/// listed, which may reuse another maker's keys.
AndroidKeys androidKeysOfAllMakers() => (
  properties: {
    for (final maker in _makers) ..._propertiesOf(maker),
    ..._anyMakerProperties,
    _userAssignedProperty,
  }.toList(),
  globalSettings: {
    for (final maker in _makers) ..._settingsOf(maker),
    _userAssignedSetting,
  }.toList(),
);

/// The keys to read, by lower-case `Build.BRAND` or `Build.MANUFACTURER`, for
/// the platform side to pick from in a single call; `null` stands for a maker
/// not listed.
Map<String?, AndroidKeys> androidKeysByMaker() => {
  for (final maker in _makers)
    for (final name in maker.names) name: _keysOf(maker),
  null: _keysOf(null),
};

/// Picks the best name among [sources].
///
/// Order: the maker's factory name in settings, then in system properties,
/// then `Build.MODEL` when it already is a name ("Pixel 9", "moto g54"), then
/// the brand and the model ("Samsung SM-G525F"). Where the name the user gave
/// the device goes is up to [userAssignedName]: nowhere by default, since it
/// can carry a person's name and nothing on the device tells a renamed device
/// from one that kept its default.
DisplayName chooseAndroidName(
  AndroidNameSources sources, {
  UserAssignedName userAssignedName = UserAssignedName.never,
}) {
  final chosen = _choose(sources, userAssignedName);
  return DisplayName(
    chosen.name,
    chosen.source,
    key: chosen.key,
    fullName: chosen.source == NameSource.userAssigned
        ? chosen.name
        : _withAnyBrand(sources, chosen.name),
    kind: androidKind(
      sources.features,
      sources.smallestScreenWidthDp,
      characteristics: sources.characteristics,
    ),
  );
}

DisplayName _choose(
  AndroidNameSources sources,
  UserAssignedName userAssignedName,
) {
  final maker = _makerOf(
    brand: sources.brand,
    manufacturer: sources.manufacturer,
  );
  final codes = {
    for (final code in [sources.model, sources.device, sources.product])
      if (code.isNotEmpty) code.toLowerCase(),
  };

  String? accept(String? raw) {
    if (raw == null) return null;
    final name = _clean(raw);
    if (name.isEmpty || codes.contains(name.toLowerCase()) || _isJunk(name)) {
      return null;
    }
    return name;
  }

  DisplayName? userAssigned({required bool first}) {
    final model = sources.model.toLowerCase();
    for (final (key, raw) in [
      (_userAssignedSetting, sources.globalSettings[_userAssignedSetting]),
      (_userAssignedProperty, sources.properties[_userAssignedProperty]),
    ]) {
      final name = accept(raw);
      if (name == null) continue;
      // Ahead of the factory name, a default that is only the maker and the
      // code ("samsung SM-G525F", the AOSP default "Google Pixel 9") would win
      // over "Galaxy XCover 5"; a name the user typed rarely carries the code.
      if (first && model.isNotEmpty && name.toLowerCase().contains(model)) {
        continue;
      }
      return DisplayName(name, NameSource.userAssigned, key: key);
    }
    return null;
  }

  if (userAssignedName == UserAssignedName.preferred) {
    final name = userAssigned(first: true);
    if (name != null) return name;
  }

  for (final key in _settingsOf(maker)) {
    final name = accept(sources.globalSettings[key]);
    if (name != null && _fits(maker, name, key)) {
      return DisplayName(
        _withBrand(sources, maker, name, key),
        NameSource.factorySetting,
        key: key,
      );
    }
  }

  for (final key in _propertiesOf(maker)) {
    final name = accept(sources.properties[key]);
    if (name != null && _fits(maker, name, key)) {
      return DisplayName(
        _withBrand(sources, maker, name, key),
        NameSource.vendorProperty,
        key: key,
      );
    }
  }

  final model = _clean(sources.model);
  if (model.isNotEmpty && !_isJunk(model)) {
    return DisplayName(model, NameSource.model);
  }

  if (userAssignedName == UserAssignedName.fallback) {
    final name = userAssigned(first: false);
    if (name != null) return name;
  }

  return DisplayName(_brandAndModel(sources), NameSource.brandAndModel);
}

_Maker? _makerOf({required String brand, required String manufacturer}) {
  final b = brand.toLowerCase();
  final m = manufacturer.toLowerCase();
  for (final maker in _makers) {
    if (maker.names.contains(b) || maker.names.contains(m)) return maker;
  }
  return null;
}

final _spaces = RegExp(r'\s+');

// Motorola appends the model code to the name: "moto g stylus - 2026 (XT2619V)".
final _motorolaCode = RegExp(r'\s*\(XT\d+\w*\)$');

// A Chinese "edition" suffix vivo puts after the name: "iQOO Neo 855版".
final _editionSuffix = RegExp(r'版$');

String _clean(String raw) => raw
    .replaceAll(_spaces, ' ')
    .trim()
    .replaceFirst(_motorolaCode, '')
    .replaceFirst(_editionSuffix, '')
    .trim();

final _digit = RegExp(r'\d');
final _placeholder = RegExp(r'(^|[^A-Za-z])TBD([^A-Za-z]|$)');

/// A value that is not a name: a placeholder, a codename with an underscore
/// ("serenity_eea_TBD", "Nord_series"), or a hardware code - one word, upper
/// case, with a digit ("M2006C3LG", "SM-G525F", "CPH2469", "A065").
bool _isJunk(String value) {
  if (value.contains('_') || _placeholder.hasMatch(value)) return true;
  return !value.contains(' ') &&
      _digit.hasMatch(value) &&
      value == value.toUpperCase();
}

/// Keys whose value is something else that only holds the name by default:
/// the hotspot name is "vivo V30" out of the box, but it is a network name,
/// and anything not shaped `maker model` ("AndroidAP", "vivo hotspot")
/// is not taken for the device's name.
const _brandedOnly = {'wifi_hotspot_default_name'};

bool _fits(_Maker? maker, String name, String key) {
  if (!_brandedOnly.contains(key)) return true;
  final words = name.split(' ');
  return words.length >= 2 &&
      (maker?.names.contains(words.first.toLowerCase()) ?? false) &&
      _digit.hasMatch(name);
}

/// Keys that may hold the name without the maker in front: always on vivo
/// ("T4x 5G"), on Huawei firmware for China ("nova 13", while the global one
/// says "HUAWEI nova 11i").
const _withoutBrand = {
  'ro.vivo.product.release.name',
  'unified_default_device_name',
  'ro.config.marketing_name',
};

String _withBrand(
  AndroidNameSources sources,
  _Maker? maker,
  String name,
  String key,
) {
  if (!_withoutBrand.contains(key)) return name;
  final lower = name.toLowerCase();
  // Any brand of the same maker counts: an iQOO sold with Build.BRAND "vivo"
  // is "iQOO Neo 9", not "vivo iQOO Neo 9".
  final brands = {
    ...?maker?.names,
    sources.brand.toLowerCase(),
    sources.manufacturer.toLowerCase(),
  }..remove('');
  if (brands.any((b) => lower.startsWith('$b ') || lower == b)) return name;
  final brand = _brandOf(sources);
  return brand.isEmpty ? name : '$brand $name';
}

/// [name] with the brand in front unless it already starts with a brand of
/// the same maker ("Galaxy S26" -> "Samsung Galaxy S26", "OPPO A54" stays).
String _withAnyBrand(AndroidNameSources sources, String name) {
  final maker = _makerOf(
    brand: sources.brand,
    manufacturer: sources.manufacturer,
  );
  final lower = name.toLowerCase();
  final brands = {
    ...?maker?.names,
    ...?_productLines[maker?.names.first],
    sources.brand.toLowerCase(),
    sources.manufacturer.toLowerCase(),
  }..remove('');
  if (brands.any((b) => lower.startsWith('$b ') || lower == b)) return name;
  final brand = _brandOf(sources);
  return brand.isEmpty ? name : '$brand $name';
}

/// Product lines that stand for the maker at the front of a name:
/// "moto g71 5G" is a Motorola, "Galaxy" is not (it gets "Samsung").
const _productLines = {
  'motorola': ['moto'],
};

String _brandAndModel(AndroidNameSources sources) {
  final model = _clean(sources.model);
  final brand = _brandOf(sources);
  if (brand.isEmpty) return model;
  if (model.isEmpty) return brand;
  if (model.toLowerCase().startsWith(brand.toLowerCase())) return model;
  return '$brand $model';
}

/// How each maker spells its own brand; Build.BRAND has "samsung", "google",
/// "HUAWEI", "OnePlus" or "vivo" depending on the maker.
const _brandSpelling = {
  'samsung': 'Samsung',
  'google': 'Google',
  'xiaomi': 'Xiaomi',
  'redmi': 'Redmi',
  'poco': 'POCO',
  'huawei': 'HUAWEI',
  'honor': 'HONOR',
  'oppo': 'OPPO',
  'realme': 'realme',
  'oneplus': 'OnePlus',
  'vivo': 'vivo',
  'iqoo': 'iQOO',
  'motorola': 'motorola',
  'lenovo': 'Lenovo',
  'nokia': 'Nokia',
  'hmd': 'HMD',
  'sony': 'Sony',
  'asus': 'ASUS',
  'zte': 'ZTE',
  'nubia': 'nubia',
  'tecno': 'TECNO',
  'infinix': 'Infinix',
  'itel': 'itel',
  'lge': 'LG',
  'lg': 'LG',
  'nothing': 'Nothing',
  'fairphone': 'Fairphone',
};

/// The brand to put in front of a name: Build.BRAND, or the manufacturer when
/// the brand is empty, in the maker's own spelling; a brand not listed keeps
/// its case, except that an all-lower-case one gets a capital.
String _brandOf(AndroidNameSources sources) {
  final raw = _clean(
    sources.brand.isNotEmpty ? sources.brand : sources.manufacturer,
  );
  if (raw.isEmpty) return raw;
  final known = _brandSpelling[raw.toLowerCase()];
  if (known != null) return known;
  return raw == raw.toLowerCase()
      ? raw[0].toUpperCase() + raw.substring(1)
      : raw;
}
