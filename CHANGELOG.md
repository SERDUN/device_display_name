## 0.1.0

### Added

- `DeviceDisplayName.read()` and its platform-backed implementation `PlatformDeviceDisplayName`, returning a
  `DisplayName` with the name, its `NameSource` and the key it was read from.
- Android: the maker's factory name from `Settings.Global` (Samsung `default_device_name`, Huawei/Honor
  `unified_default_device_name`) or from its system properties (Xiaomi, OPPO/realme/OnePlus, vivo, Huawei, ZTE,
  Transsion, Lenovo/Motorola, HMD, Sony, Asus, LG, Umidigi); `Build.MODEL` when it already is a name; the brand and
  the model otherwise. Placeholders, codenames and hardware codes are rejected.
- Android: the user-assigned name through `userAssignedName`: `never` (default), `fallback` or `preferred`.
- iOS: the hardware identifier looked up in a generated table of Apple identifiers; the identifier itself when
  the table does not know it.
- Android: only the device maker's keys are read (`androidKeysFor`), after a first read of the build fields:
  another maker's vendor key is usually blocked by SELinux and logs an "Access denied finding property" line.
- vivo: `Settings.Global wifi_hotspot_default_name` and `ro.vivo.product.release.name`; the brand is put in front
  of vivo and Huawei names that lack it ("T5x 5G" -> "vivo T5x 5G", "nova 13" -> "HUAWEI nova 13").
- `DisplayName.kind` (`DeviceKind`: phone, tablet, foldable, watch, tv, car, desktop, headset, unknown) from the
  Android system features, `ro.build.characteristics` and the smallest screen width, or the iOS interface idiom.
- `DisplayName.fullName` with the brand in front, `DisplayName.userAgentToken` safe for a header, and
  `distinctLabels` for a list of devices that share a name.
- `readSources()` with the raw values the platform read.
- Other platforms, and every failure, answer `null`.

### Requirements

- Flutter 3.47 or later; on Android an app built with Android Gradle Plugin 9 or later.
