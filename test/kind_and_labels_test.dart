import 'package:flutter_test/flutter_test.dart';

import 'package:device_display_name/device_display_name.dart';

void main() {
  group('androidKind', () {
    test('a phone: under 600 dp, no special feature', () {
      expect(androidKind({}, 360), DeviceKind.phone);
    });

    test('a tablet: 600 dp and wider', () {
      expect(androidKind({}, 600), DeviceKind.tablet);
      expect(androidKind({}, 800), DeviceKind.tablet);
    });

    test('a foldable: the hinge sensor wins over the unfolded width', () {
      expect(
        androidKind({'android.hardware.sensor.hinge_angle'}, 600),
        DeviceKind.foldable,
      );
    });

    test('watch, car, TV and desktop by their features', () {
      expect(
        androidKind({'android.hardware.type.watch'}, 192),
        DeviceKind.watch,
      );
      expect(
        androidKind({'android.hardware.type.automotive'}, 720),
        DeviceKind.car,
      );
      expect(androidKind({'android.software.leanback'}, 540), DeviceKind.tv);
      expect(
        androidKind({'android.hardware.type.television'}, 540),
        DeviceKind.tv,
      );
      expect(
        androidKind({'android.hardware.type.pc'}, 800),
        DeviceKind.desktop,
      );
    });

    test('the build says tablet: a tablet narrower than 600 dp', () {
      expect(
        androidKind({}, 533, characteristics: 'tablet'),
        DeviceKind.tablet,
      );
      expect(
        androidKind({}, 533, characteristics: 'tablet,nosdcard'),
        DeviceKind.tablet,
      );
      expect(
        androidKind({}, 411, characteristics: 'default'),
        DeviceKind.phone,
      );
    });

    test('the build says tv, watch or automotive', () {
      expect(androidKind({}, 540, characteristics: 'tv'), DeviceKind.tv);
      expect(androidKind({}, 192, characteristics: 'watch'), DeviceKind.watch);
      expect(
        androidKind({}, 720, characteristics: 'automotive'),
        DeviceKind.car,
      );
    });

    test('nothing to tell by: unknown', () {
      expect(androidKind({}, null), DeviceKind.unknown);
      expect(androidKind({}, 0), DeviceKind.unknown);
    });
  });

  test('iosKind by userInterfaceIdiom', () {
    expect(iosKind('phone'), DeviceKind.phone);
    expect(iosKind('pad'), DeviceKind.tablet);
    expect(iosKind('tv'), DeviceKind.tv);
    expect(iosKind('carPlay'), DeviceKind.car);
    expect(iosKind('mac'), DeviceKind.desktop);
    expect(iosKind('vision'), DeviceKind.headset);
    expect(iosKind('unspecified'), DeviceKind.unknown);
    expect(iosKind(null), DeviceKind.unknown);
  });

  group('the chosen name carries the kind', () {
    test('Galaxy Tab A7: a tablet', () {
      const sources = AndroidNameSources(
        manufacturer: 'samsung',
        brand: 'samsung',
        model: 'SM-T505',
        globalSettings: {'default_device_name': 'Galaxy Tab A7'},
        smallestScreenWidthDp: 800,
      );
      expect(chooseAndroidName(sources).kind, DeviceKind.tablet);
    });

    test('an iPhone: a phone', () {
      expect(
        chooseIosName('iPhone13,1', idiom: 'phone').kind,
        DeviceKind.phone,
      );
    });
  });

  group('fullName', () {
    DisplayName choose(
      String brand,
      String model, {
      Map<String, String> settings = const {},
      Map<String, String> props = const {},
    }) => chooseAndroidName(
      AndroidNameSources(
        manufacturer: brand,
        brand: brand,
        model: model,
        globalSettings: settings,
        properties: props,
      ),
    );

    test('Samsung: the brand goes in front of "Galaxy"', () {
      final n = choose(
        'samsung',
        'SM-S942B',
        settings: {'default_device_name': 'Galaxy S26'},
      );
      expect(n.name, 'Galaxy S26');
      expect(n.fullName, 'Samsung Galaxy S26');
    });

    test('Google: "Pixel 9" becomes "Google Pixel 9"', () {
      expect(choose('google', 'Pixel 9').fullName, 'Google Pixel 9');
    });

    test('a name that already starts with its brand stays', () {
      expect(
        choose(
          'OPPO',
          'CPH2239',
          props: {'ro.vendor.oplus.market.name': 'OPPO A54'},
        ).fullName,
        'OPPO A54',
      );
      expect(
        choose(
          'Xiaomi',
          'M2006C3LG',
          props: {'ro.product.marketname': 'Redmi 9A'},
        ).fullName,
        'Redmi 9A',
      );
      expect(
        choose('motorola', 'motorola edge 50 fusion').fullName,
        'motorola edge 50 fusion',
      );
    });

    test('Motorola: "moto" counts as the brand', () {
      expect(choose('motorola', 'moto g71 5G').fullName, 'moto g71 5G');
    });

    test('OPPO without the brand in the name gets it', () {
      expect(
        choose(
          'OPPO',
          'CPH2505',
          props: {'ro.vendor.oplus.market.name': 'Reno8 T 5G'},
        ).fullName,
        'OPPO Reno8 T 5G',
      );
    });

    test('the name the user gave the device is kept as it is', () {
      final n = chooseAndroidName(
        const AndroidNameSources(
          manufacturer: 'samsung',
          brand: 'samsung',
          model: 'SM-G525F',
          globalSettings: {
            'device_name': "Anna's XCover 5",
            'default_device_name': 'Galaxy XCover 5',
          },
        ),
        userAssignedName: UserAssignedName.preferred,
      );
      expect(n.fullName, "Anna's XCover 5");
    });

    test('iOS: the table name is already full', () {
      expect(chooseIosName('iPhone13,1').fullName, 'iPhone 12 mini');
    });
  });

  group('userAgentToken', () {
    test('any value, not only a DisplayName, is escaped the same way', () {
      expect(userAgentToken('SM-G525F'), 'SM-G525F');
      expect(userAgentToken('Tab (Wi-Fi); 2'), 'Tab [Wi-Fi], 2');
      expect(
        userAgentToken('Lenovo Tab M8 (4th Gen)'),
        const DisplayName(
          'Lenovo Tab M8 (4th Gen)',
          NameSource.vendorProperty,
        ).userAgentToken,
      );
    });

    test('a plain name is kept', () {
      expect(
        const DisplayName(
          'Galaxy S26',
          NameSource.factorySetting,
          fullName: 'Samsung Galaxy S26',
        ).userAgentToken,
        'Samsung Galaxy S26',
      );
    });

    test('the characters a User-Agent comment is parsed by are replaced', () {
      expect(
        const DisplayName(
          'Lenovo Tab M8 (4th Gen)',
          NameSource.vendorProperty,
        ).userAgentToken,
        'Lenovo Tab M8 [4th Gen]',
      );
      expect(
        const DisplayName('A; B', NameSource.model).userAgentToken,
        'A, B',
      );
    });

    test('non-ASCII is percent-encoded as UTF-8, and decodes back', () {
      const name = "Ганна's M32";
      final token = const DisplayName(
        name,
        NameSource.userAssigned,
      ).userAgentToken;
      expect(token, "%D0%93%D0%B0%D0%BD%D0%BD%D0%B0's M32");
      expect(Uri.decodeComponent(token), name);
      expect(token.codeUnits.every((c) => c >= 0x20 && c < 0x7F), isTrue);
    });

    test('a literal percent survives the round trip', () {
      final token = const DisplayName(
        '100% phone',
        NameSource.userAssigned,
      ).userAgentToken;
      expect(Uri.decodeComponent(token), '100% phone');
    });

    test('control characters and runs of spaces become one space', () {
      expect(
        const DisplayName('Pixel\t\n  9 ', NameSource.model).userAgentToken,
        'Pixel 9',
      );
    });
  });

  group('distinctLabels', () {
    test('a name that occurs once is left as it is', () {
      expect(
        distinctLabels([
          (name: 'Pixel 9', detail: 'Android 17'),
          (name: 'Galaxy S26', detail: null),
        ]),
        ['Pixel 9', 'Galaxy S26'],
      );
    });

    test('repeated names get their details when they differ', () {
      expect(
        distinctLabels([
          (name: 'Galaxy S24', detail: 'Android 15'),
          (name: 'Pixel 9', detail: null),
          (name: 'Galaxy S24', detail: 'Android 14'),
        ]),
        ['Galaxy S24 (Android 15)', 'Pixel 9', 'Galaxy S24 (Android 14)'],
      );
    });

    test(
      'repeated names get numbers when the details do not tell them apart',
      () {
        expect(
          distinctLabels([
            (name: 'Galaxy S24', detail: 'Android 15'),
            (name: 'Galaxy S24', detail: 'Android 15'),
          ]),
          ['Galaxy S24 (1)', 'Galaxy S24 (2)'],
        );
        expect(
          distinctLabels([
            (name: 'iPhone 15', detail: null),
            (name: 'iPhone 15', detail: 'iOS 26'),
          ]),
          ['iPhone 15 (1)', 'iPhone 15 (2)'],
        );
      },
    );
  });
}
