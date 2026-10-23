# device_display_name

[![pub package](https://img.shields.io/pub/v/device_display_name.svg)](https://pub.dev/packages/device_display_name)

A Flutter plugin that gives the name a person knows their device by - **"Redmi 9A"**, **"Galaxy XCover 5"**,
**"iPhone 12 mini"** - instead of the hardware code the platform reports as the model ("M2006C3LG", "SM-G525F",
"iPhone"), and tells what kind of device it is.

A list of signed-in devices - a sessions screen, a "too many devices" prompt - usually shows `Build.MODEL` or
`UIDevice.model`. On many Android phones that is a code nobody recognizes, and on every iPhone it is just
"iPhone", so a user with two of them cannot tell which one to sign out. No single field holds the real name on
every phone: each maker keeps it somewhere else. This plugin knows where, reads it, and picks the best one.

## Features

- **The maker's own name** - read where each maker keeps it: Samsung, Xiaomi/Redmi/POCO, OPPO, realme, OnePlus,
  Huawei, Honor, vivo, Lenovo, Motorola, Tecno/Infinix/itel, ZTE/nubia, HMD, Sony, Asus, LG and more.
- **Never a wrong device** - codes, placeholders and codenames are rejected; when nothing better is there, you get
  the brand and the code ("Samsung SM-G525F") and `isMarketingName` tells you so.
- **The device kind** - phone, tablet, foldable, watch, TV, car, desktop or headset, for the right icon.
- **The user's own name, only if you want it** - "Anna's XCover 5" tells two Galaxies apart, but it can carry a
  person's name, so it is off unless you ask.
- **Ready for a sessions list** - `fullName` with the brand in front, a `userAgentToken` safe for a header, and
  `distinctLabels` for two devices that share a name.
- **Offline and small** - no network, no device database: only what the device itself carries, plus a table of
  Apple identifiers.
- **No permissions**, never throws.

## Requirements

- Flutter 3.47 or later.
- Android 7.0 (API 24) or later, built with Android Gradle Plugin 9 or later.
- iOS 15 or later.

## Installation

```yaml
dependencies:
  device_display_name: ^0.1.0
```

```sh
flutter pub get
```

## Usage

```dart
import 'package:device_display_name/device_display_name.dart';

final device = await const PlatformDeviceDisplayName().read();

device?.name;            // "Galaxy Tab A7"
device?.fullName;        // "Samsung Galaxy Tab A7"
device?.kind;            // DeviceKind.tablet
device?.isMarketingName; // true - false when only the brand and the code were left
device?.source;          // NameSource.factorySetting - where the name came from
```

`read()` returns `null` only on a platform it does not support (web, desktop) or when the platform could not be
asked. The device is asked once; later calls answer from memory.

### The name the user gave the device

```dart
const PlatformDeviceDisplayName(userAssignedName: UserAssignedName.preferred);
```

| Mode | What you get on a renamed Galaxy XCover 5 |
|---|---|
| `never` (default) | "Galaxy XCover 5" |
| `fallback` | the maker's name, and the user's name only where the maker's is missing |
| `preferred` | "Anna's XCover 5" - the user's name first; a phone never renamed still gets "Galaxy XCover 5" |

On iOS an app cannot read the name the user gave the device, so every mode gives the model name.

### A list of devices

```dart
// For a User-Agent header or any one-line field: no ; ( ), ASCII only.
device.userAgentToken; // "Lenovo Tab M8 [4th Gen]", "Ганна's M32" -> "%D0%93...'s M32"

// Two devices with one name:
distinctLabels([
  (name: 'Galaxy S24', detail: 'Android 15'),
  (name: 'Galaxy S24', detail: 'Android 14'),
]); // ["Galaxy S24 (Android 15)", "Galaxy S24 (Android 14)"]
```

`Uri.decodeComponent` turns a `userAgentToken` back into the name.

### Testing

Depend on the `DeviceDisplayName` interface and pass a fake:

```dart
class FakeDeviceName implements DeviceDisplayName {
  @override
  Future<DisplayName?> read() async =>
      const DisplayName('Pixel 9', NameSource.model, kind: DeviceKind.phone);
}
```

## Where the name comes from

| Platform | Source |
|---|---|
| **Android** | Only the keys of the device's own maker are read, in this order: the maker's factory name in settings (Samsung `default_device_name`, Huawei `unified_default_device_name`, vivo's hotspot name), the maker's marketing properties (`ro.product.marketname` on Xiaomi, `ro.vendor.oplus.market.name` on OPPO/realme/OnePlus, `ro.config.marketing_name` on Huawei and so on), `Build.MODEL` when it already is a name (Pixel, Motorola), the brand and the code. |
| **iOS** | The hardware identifier (`iPhone13,1`) looked up in a table of Apple identifiers; the identifier itself for a device newer than the table. |
| **Others** | `null`. |

The kind comes from the Android system features, the build's own `ro.build.characteristics` and the screen width,
or from the iOS interface idiom.

## Things to know

- **A few vivo models keep their name from apps.** vivo Y100, Y22 and Y21 carry no name an app may read; they get
  the brand and the code ("vivo V2239").
- **Honor and Asus** keys come from firmware research and have not been run on a real phone yet.
- **New iPhones** need the table updated: `dart run tool/apple_identifiers/generate.dart`, with
  `tool/apple_identifiers/overrides.json` for models the upstream list does not have yet.
- **The user's name is personal data.** Keep `userAssignedName` at `never` unless the name stays with the user,
  such as a list of their own devices.
- **The name is as the maker writes it** - "motorola edge 50 fusion" in lower case, "Lenovo Tab M8 (4th Gen)" with
  parentheses. Use `userAgentToken` where those characters matter.

<details>
<summary><b>Verified devices</b> - 42 Android devices and two iOS simulators</summary>

The example app at targetSdk 36. The kind is phone unless the name says otherwise. "Run":
**device** - a device at hand; **BrowserStack** - a BrowserStack App Live device; **BrowserStack values** - the
values a BrowserStack device reported, the name checked by a unit test; **simulator** - an iOS simulator.
`preferred` is the name in that mode where it differs; `(owner)` stands for the name of the person who renamed
the phone.

| Maker | Device | Android | Name | Source | `preferred` | Run |
|---|---|---|---|---|---|---|
| Xiaomi | Redmi 9A | 10 | Redmi 9A | `ro.product.marketname` | Redmi 9A (`persist.sys.device_name`) | device |
| Xiaomi | Redmi A5 | 15 | Redmi A5 | `ro.product.marketname` | | device |
| Xiaomi | Redmi Note 11 | 11 | Redmi Note 11 | `ro.product.marketname` | | BrowserStack |
| Xiaomi | Redmi Note 12 4G | 13 | Redmi Note 12 | `ro.product.marketname` | | BrowserStack |
| Xiaomi | Redmi Note 12 Pro | 12 | Redmi Note 12 Pro 5G | `ro.product.marketname` | | BrowserStack |
| Xiaomi | Redmi Note 13 Pro 5G | 14 | Redmi Note 13 Pro 5G | `ro.product.marketname` | | BrowserStack |
| Xiaomi | Redmi Note 14 Pro 5G | 15 | Redmi Note 14 Pro 5G | `ro.product.marketname` | | BrowserStack |
| Samsung | Galaxy XCover 5 | 14 | Galaxy XCover 5 | `default_device_name` | (owner)'s XCover 5 | device |
| Samsung | Galaxy M32 | 13 | Galaxy M32 | `default_device_name` | (owner)'s M32 | device |
| Samsung | Galaxy Tab A7 | 12 | Galaxy Tab A7 - tablet | `default_device_name` | | device |
| Samsung | Galaxy S26 | 16 | Galaxy S26 | `default_device_name` | | BrowserStack |
| Samsung | Galaxy S22+ | 12 | Galaxy S22+ | `default_device_name` | | BrowserStack |
| Huawei | nova 11i | 12 | HUAWEI nova 11i | `unified_default_device_name` | | device |
| Huawei | nova 11 SE | 12 | HUAWEI nova 11 SE | `unified_default_device_name`, brand added | | BrowserStack values |
| Huawei | nova 13 | 12 | HUAWEI nova 13 | `unified_default_device_name`, brand added | | BrowserStack values |
| Lenovo | Tab M8 (4th Gen) | 13 | Lenovo Tab M8 (4th Gen) - tablet | `ro.odm.lenovo.series` | | device |
| Google | Pixel 9 | 17 | Pixel 9 | `Build.MODEL` | | device |
| OPPO | Reno8 T 5G | 14 | OPPO Reno8 T 5G | `ro.vendor.oplus.market.name` | | BrowserStack |
| OPPO | A78 5G | 13 | OPPO A78 5G | `ro.vendor.oplus.market.name` | | BrowserStack |
| OPPO | A54 | 11 | OPPO A54 | `ro.vendor.oplus.market.name` | | BrowserStack |
| OPPO | A96 | 12 | OPPO A96 | `ro.vendor.oplus.market.name` | | BrowserStack |
| OPPO | F29 5G | 15 | OPPO F29 5G | `ro.vendor.oplus.market.name` | | BrowserStack |
| OPPO | K14x 5G | 16 | OPPO K14x 5G | `ro.vendor.oplus.market.enname` | | BrowserStack |
| realme | 11x 5G | 13 | realme 11x 5G | `ro.vendor.oplus.market.enname` | | BrowserStack |
| realme | 12+ 5G | 14 | realme 12+ 5G | `ro.vendor.oplus.market.name` | | BrowserStack |
| realme | P3 5G | 15 | realme P3 5G | `ro.vendor.oplus.market.name` | | BrowserStack |
| realme | P4 Power 5G | 16 | realme P4 Power 5G | `ro.vendor.oplus.market.name` | | BrowserStack |
| OnePlus | 11R 5G | 13 | OnePlus 11R 5G | `ro.vendor.oplus.market.name` | | BrowserStack |
| OnePlus | 12R | 14 | OnePlus 12R | `ro.vendor.oplus.market.name` | | BrowserStack |
| OnePlus | 13R | 15 | OnePlus 13R | `ro.vendor.oplus.market.name` | | BrowserStack |
| OnePlus | 15R | 16 | OnePlus 15R | `ro.vendor.oplus.market.name` | | BrowserStack |
| Motorola | edge 40 neo | 13 | motorola edge 40 neo | `Build.MODEL` | | BrowserStack |
| Motorola | edge 50 fusion | 14 | motorola edge 50 fusion | `Build.MODEL` | | BrowserStack |
| Motorola | edge 60 fusion | 15 | motorola edge 60 fusion | `Build.MODEL` | | BrowserStack |
| Motorola | edge 70 fusion | 16 | motorola edge 70 fusion | `Build.MODEL` | | BrowserStack |
| Motorola | moto g71 5G | 11 | moto g71 5G | `Build.MODEL` | | BrowserStack |
| vivo | V30 | 14 | vivo V30 | `wifi_hotspot_default_name` | | BrowserStack values |
| vivo | T4x 5G | 15 | vivo T4x 5G | `wifi_hotspot_default_name` | | BrowserStack values |
| vivo | T5x 5G | 16 | vivo T5x 5G | `ro.vivo.product.release.name`, brand added | | BrowserStack values |
| vivo | Y100 | 13 | **vivo V2239** | brand and code - nothing readable names it | | BrowserStack |
| vivo | Y22 | 12 | **vivo V2207** | brand and code (the name is only in `bluetooth_name`, closed to apps on API 32+) | | BrowserStack |
| vivo | Y21 | 11 | **vivo V2111** | brand and code (as Y22) | | BrowserStack |
| Apple | iPhone 17e | iOS simulator | iPhone 17e - phone | identifier table | | simulator |
| Apple | iPad Pro 13-inch (M5) | iOS simulator | iPad Pro 13-inch (M5) - tablet | identifier table | | simulator |

The device kind was checked on Galaxy Tab A7 and Lenovo Tab M8 (`tablet`), Redmi A5, HUAWEI nova 11i and Galaxy M32
(`phone`) and both simulators; a foldable, a watch and a TV have not been run.

</details>

## Repository

| Path | What |
|---|---|
| `lib/` | the plugin |
| `example/` | an example app that shows the name, the kind and every source the plugin read |
| `tool/apple_identifiers/` | generates the table of Apple identifiers |

## License

MIT - see [LICENSE](LICENSE).
