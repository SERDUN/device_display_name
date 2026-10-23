/// What sort of device it is, for an icon or a word next to the name
/// ("Galaxy Tab A7 - tablet").
enum DeviceKind {
  phone,
  tablet,

  /// A phone that unfolds into a tablet (it has a hinge sensor).
  foldable,
  watch,
  tv,
  car,

  /// A desktop or laptop running a phone OS (ChromeOS running Android apps,
  /// an iPad app on a Mac).
  desktop,

  /// A headset (Apple Vision).
  headset,

  /// The platform gave nothing to tell.
  unknown,
}

/// The Android system features the kind is told by; the platform side reports
/// which of them the device has.
const androidKindFeatures = [
  'android.hardware.type.watch',
  'android.hardware.type.automotive',
  'android.software.leanback',
  'android.hardware.type.television',
  'android.hardware.type.pc',
  'android.hardware.sensor.hinge_angle',
];

/// The kind of an Android device, from its system [features], the build's
/// `ro.build.characteristics` ("tablet", "tv", "watch", "automotive" or
/// "default") and its smallest screen width in dp.
///
/// A hinge sensor is checked before the rest: an unfolded Galaxy Z Fold is
/// 600 dp wide and would pass for a tablet. The build's own "tablet" comes
/// before the width: an 8-inch Lenovo Tab M8 is only 533 dp wide. 600 dp is
/// where Android itself draws the line between a phone and a tablet layout.
DeviceKind androidKind(
  Set<String> features,
  int? smallestScreenWidthDp, {
  String characteristics = '',
}) {
  final traits = characteristics
      .toLowerCase()
      .split(',')
      .map((t) => t.trim())
      .toSet();
  if (features.contains('android.hardware.type.watch') ||
      traits.contains('watch')) {
    return DeviceKind.watch;
  }
  if (features.contains('android.hardware.type.automotive') ||
      traits.contains('automotive')) {
    return DeviceKind.car;
  }
  if (features.contains('android.software.leanback') ||
      features.contains('android.hardware.type.television') ||
      traits.contains('tv')) {
    return DeviceKind.tv;
  }
  if (features.contains('android.hardware.type.pc')) return DeviceKind.desktop;
  if (features.contains('android.hardware.sensor.hinge_angle')) {
    return DeviceKind.foldable;
  }
  if (traits.contains('tablet')) return DeviceKind.tablet;
  if (smallestScreenWidthDp == null || smallestScreenWidthDp <= 0) {
    return DeviceKind.unknown;
  }
  return smallestScreenWidthDp >= 600 ? DeviceKind.tablet : DeviceKind.phone;
}

/// The kind of an Apple device, from `UIDevice.userInterfaceIdiom`.
DeviceKind iosKind(String? idiom) => switch (idiom) {
  'phone' => DeviceKind.phone,
  'pad' => DeviceKind.tablet,
  'tv' => DeviceKind.tv,
  'carPlay' => DeviceKind.car,
  'mac' => DeviceKind.desktop,
  'vision' => DeviceKind.headset,
  _ => DeviceKind.unknown,
};
