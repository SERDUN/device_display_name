import 'package:flutter_test/flutter_test.dart';

import 'package:device_display_name/device_display_name.dart';

void main() {
  // What real devices report to an app (targetSdk 36, no permissions).
  // The names the owners gave their phones are replaced.
  group('devices measured', () {
    final cases = <String, (AndroidNameSources, DisplayName)>{
      'Redmi 9A, MIUI, Android 10': (
        const AndroidNameSources(
          manufacturer: 'Xiaomi',
          brand: 'Redmi',
          model: 'M2006C3LG',
          device: 'dandelion',
          product: 'dandelion_global',
          properties: {
            'ro.product.marketname': 'Redmi 9A',
            'ro.product.odm.marketname': 'Redmi 9A',
            'ro.product.vendor.marketname': 'Redmi 9A',
            'persist.sys.device_name': 'Redmi 9A',
          },
          globalSettings: {'device_name': 'M2006C3LG'},
        ),
        const DisplayName(
          'Redmi 9A',
          NameSource.vendorProperty,
          key: 'ro.product.marketname',
        ),
      ),
      'Galaxy XCover 5, One UI, Android 14': (
        const AndroidNameSources(
          manufacturer: 'samsung',
          brand: 'samsung',
          model: 'SM-G525F',
          device: 'xcover5',
          product: 'xcover5eea',
          globalSettings: {
            'device_name': "Anna's XCover 5",
            'default_device_name': 'Galaxy XCover 5',
          },
        ),
        const DisplayName(
          'Galaxy XCover 5',
          NameSource.factorySetting,
          key: 'default_device_name',
        ),
      ),
      'Galaxy M32, One UI, Android 13': (
        const AndroidNameSources(
          manufacturer: 'samsung',
          brand: 'samsung',
          model: 'SM-M325FV',
          device: 'm32',
          product: 'm32xx',
          globalSettings: {
            'device_name': "Ганна's M32",
            'default_device_name': 'Galaxy M32',
          },
        ),
        const DisplayName(
          'Galaxy M32',
          NameSource.factorySetting,
          key: 'default_device_name',
        ),
      ),
      'HUAWEI nova 11i, EMUI 14.2, Android 12': (
        const AndroidNameSources(
          manufacturer: 'HUAWEI',
          brand: 'HUAWEI',
          model: 'MAO-LX9N',
          device: 'HWMAO-Q',
          product: 'MAO-L29N',
          properties: {'ro.config.marketing_name': 'HUAWEI nova 11i'},
          globalSettings: {
            'device_name': 'MAO-LX9N',
            'unified_default_device_name': 'HUAWEI nova 11i',
          },
        ),
        const DisplayName(
          'HUAWEI nova 11i',
          NameSource.factorySetting,
          key: 'unified_default_device_name',
        ),
      ),
      'Galaxy Tab A7, One UI, Android 12': (
        const AndroidNameSources(
          manufacturer: 'samsung',
          brand: 'samsung',
          model: 'SM-T505',
          device: 'gta4l',
          product: 'gta4leea',
          globalSettings: {
            'device_name': 'Galaxy Tab A7',
            'default_device_name': 'Galaxy Tab A7',
          },
        ),
        const DisplayName(
          'Galaxy Tab A7',
          NameSource.factorySetting,
          key: 'default_device_name',
        ),
      ),
      'Lenovo Tab M8 (4th Gen), Android 13': (
        const AndroidNameSources(
          manufacturer: 'LENOVO',
          brand: 'Lenovo',
          model: 'TB300FU',
          device: 'TB300FU',
          product: 'TB300FU',
          properties: {'ro.odm.lenovo.series': 'Lenovo Tab M8 (4th Gen)'},
          globalSettings: {'device_name': 'Lenovo Tab M8 (4th Gen)'},
        ),
        const DisplayName(
          'Lenovo Tab M8 (4th Gen)',
          NameSource.vendorProperty,
          key: 'ro.odm.lenovo.series',
        ),
      ),
      'Redmi A5, HyperOS, Android 15': (
        const AndroidNameSources(
          manufacturer: 'Xiaomi',
          brand: 'Redmi',
          model: '25028RN03Y',
          device: 'serenity',
          product: 'serenity_eea',
          properties: {
            'ro.product.marketname': 'Redmi A5',
            'ro.product.odm.marketname': 'Redmi A5',
            'ro.product.vendor.marketname': 'serenity_eea_TBD',
            'ro.product.system.marketname': 'serenity_eea_TBD',
          },
          globalSettings: {'device_name': 'Redmi A5'},
        ),
        const DisplayName(
          'Redmi A5',
          NameSource.vendorProperty,
          key: 'ro.product.marketname',
        ),
      ),
      'Pixel 9, Android 17': (
        const AndroidNameSources(
          manufacturer: 'Google',
          brand: 'google',
          model: 'Pixel 9',
          device: 'tokay',
          product: 'tokay',
          globalSettings: {'device_name': 'Pixel 9'},
        ),
        const DisplayName('Pixel 9', NameSource.model),
      ),
    };

    for (final MapEntry(key: device, value: (sources, expected))
        in cases.entries) {
      test(device, () => expect(chooseAndroidName(sources), expected));
    }
  });

  // Values found in real firmware property files (docs/name-sources.md).
  group('values seen in firmware dumps', () {
    test('OnePlus on OxygenOS 12+: the English oplus name', () {
      const sources = AndroidNameSources(
        manufacturer: 'OnePlus',
        brand: 'OnePlus',
        model: 'NE2213',
        properties: {
          'ro.vendor.oplus.market.name': '一加 10 Pro',
          'ro.vendor.oplus.market.enname': 'OnePlus 10 Pro 5G',
        },
      );
      expect(
        chooseAndroidName(sources),
        const DisplayName(
          'OnePlus 10 Pro 5G',
          NameSource.vendorProperty,
          key: 'ro.vendor.oplus.market.enname',
        ),
      );
    });

    test('OPPO on ColorOS 11 and older', () {
      const sources = AndroidNameSources(
        manufacturer: 'OPPO',
        brand: 'OPPO',
        model: 'CPH1989',
        properties: {'ro.oppo.market.name': 'OPPO Reno2 F'},
      );
      expect(chooseAndroidName(sources).name, 'OPPO Reno2 F');
    });

    test('an oplus property holding only the model code is passed over', () {
      const sources = AndroidNameSources(
        manufacturer: 'OPPO',
        brand: 'OPPO',
        model: 'CPH2469',
        properties: {'ro.vendor.oplus.market.name': 'CPH2469'},
      );
      expect(
        chooseAndroidName(sources),
        const DisplayName('OPPO CPH2469', NameSource.brandAndModel),
      );
    });

    test('OnePlus on OxygenOS 11 and older: ro.display.series', () {
      const sources = AndroidNameSources(
        manufacturer: 'OnePlus',
        brand: 'OnePlus',
        model: 'KB2005',
        properties: {'ro.display.series': 'OnePlus 8T'},
      );
      expect(chooseAndroidName(sources).name, 'OnePlus 8T');
    });

    test('vivo: the edition suffix is dropped', () {
      const sources = AndroidNameSources(
        manufacturer: 'vivo',
        brand: 'iQOO',
        model: 'V1936A',
        properties: {'ro.vivo.market.name': 'iQOO Neo 855版'},
      );
      expect(chooseAndroidName(sources).name, 'iQOO Neo 855');
    });

    test('Huawei for China: the brand the name lacks is put in front', () {
      const sources = AndroidNameSources(
        manufacturer: 'HUAWEI',
        brand: 'HUAWEI',
        model: 'BLK-AL80',
        properties: {'ro.config.marketing_name': 'nova 13'},
        globalSettings: {
          'device_name': 'BLK-AL80',
          'unified_default_device_name': 'nova 13',
        },
      );
      expect(
        chooseAndroidName(sources),
        const DisplayName(
          'HUAWEI nova 13',
          NameSource.factorySetting,
          key: 'unified_default_device_name',
        ),
      );
    });

    test('Huawei nova 11 SE on BrowserStack: the brand is put in front', () {
      const sources = AndroidNameSources(
        manufacturer: 'HUAWEI',
        brand: 'HUAWEI',
        model: 'BON-AL00',
        device: 'HWBNE-Q',
        product: 'BNE-AL00X',
        properties: {'ro.config.marketing_name': 'nova 11 SE'},
        globalSettings: {
          'unified_default_device_name': 'nova 11 SE',
          'device_name': 'BON-AL00',
        },
      );
      expect(chooseAndroidName(sources).name, 'HUAWEI nova 11 SE');
    });

    test(
      'vivo T4x 5G on BrowserStack: the hotspot name before the release name',
      () {
        const sources = AndroidNameSources(
          manufacturer: 'vivo',
          brand: 'vivo',
          model: 'V2437',
          device: 'V2437',
          product: 'V2437i',
          properties: {'ro.vivo.product.release.name': 'T4x 5G'},
          globalSettings: {
            'device_name': 'V2437',
            'wifi_hotspot_default_name': 'vivo T4x 5G',
          },
        );
        expect(
          chooseAndroidName(sources),
          const DisplayName(
            'vivo T4x 5G',
            NameSource.factorySetting,
            key: 'wifi_hotspot_default_name',
          ),
        );
      },
    );

    test('vivo: a hotspot name not shaped "vivo <model>" is passed over', () {
      const sources = AndroidNameSources(
        manufacturer: 'vivo',
        brand: 'vivo',
        model: 'V2318',
        properties: {'ro.vivo.market.name': 'vivo V30'},
        globalSettings: {'wifi_hotspot_default_name': 'AndroidAP'},
      );
      expect(
        chooseAndroidName(sources),
        const DisplayName(
          'vivo V30',
          NameSource.vendorProperty,
          key: 'ro.vivo.market.name',
        ),
      );
    });

    test('vivo: a hotspot name without a model is passed over', () {
      const sources = AndroidNameSources(
        manufacturer: 'vivo',
        brand: 'vivo',
        model: 'V2318',
        globalSettings: {'wifi_hotspot_default_name': 'vivo hotspot'},
      );
      expect(chooseAndroidName(sources).source, NameSource.brandAndModel);
    });

    test('an iQOO sold with the vivo brand keeps one brand', () {
      const sources = AndroidNameSources(
        manufacturer: 'vivo',
        brand: 'vivo',
        model: 'V2338A',
        properties: {'ro.vivo.product.release.name': 'iQOO Neo 9'},
      );
      expect(chooseAndroidName(sources).name, 'iQOO Neo 9');
    });

    test('an Honor made by Huawei keeps one brand', () {
      const sources = AndroidNameSources(
        manufacturer: 'HUAWEI',
        brand: 'HUAWEI',
        model: 'STK-LX1',
        properties: {'ro.config.marketing_name': 'HONOR 9X'},
      );
      expect(chooseAndroidName(sources).name, 'HONOR 9X');
    });

    test('an empty brand: the manufacturer is put in front', () {
      const sources = AndroidNameSources(
        manufacturer: 'HUAWEI',
        brand: '',
        model: 'BLK-AL80',
        globalSettings: {'unified_default_device_name': 'nova 13'},
      );
      expect(chooseAndroidName(sources).name, 'HUAWEI nova 13');
    });

    test('the brand is spelled the way the maker spells it', () {
      for (final (brand, model, expected) in [
        ('vivo', 'V2239', 'vivo V2239'),
        ('samsung', 'SM-A146B', 'Samsung SM-A146B'),
        ('OPPO', 'CPH2469', 'OPPO CPH2469'),
        ('Acme', 'AC-100', 'Acme AC-100'),
        ('acme', 'AC-100', 'Acme AC-100'),
      ]) {
        expect(
          chooseAndroidName(
            AndroidNameSources(manufacturer: brand, brand: brand, model: model),
          ).name,
          expected,
        );
      }
    });

    test('vivo V30 on BrowserStack: the factory hotspot name', () {
      const sources = AndroidNameSources(
        manufacturer: 'vivo',
        brand: 'vivo',
        model: 'V2318',
        device: 'V2318',
        product: 'V2318T',
        globalSettings: {
          'device_name': 'V2318',
          'wifi_hotspot_default_name': 'vivo V30',
        },
      );
      expect(
        chooseAndroidName(sources),
        const DisplayName(
          'vivo V30',
          NameSource.factorySetting,
          key: 'wifi_hotspot_default_name',
        ),
      );
    });

    test('vivo T5x on BrowserStack: the release name gets the brand', () {
      const sources = AndroidNameSources(
        manufacturer: 'vivo',
        brand: 'vivo',
        model: 'V2545',
        properties: {'ro.vivo.product.release.name': 'T5x 5G'},
        globalSettings: {'device_name': 'V2545'},
      );
      expect(
        chooseAndroidName(sources),
        const DisplayName(
          'vivo T5x 5G',
          NameSource.vendorProperty,
          key: 'ro.vivo.product.release.name',
        ),
      );
    });

    test('vivo: a release name that is only a code is passed over', () {
      const sources = AndroidNameSources(
        manufacturer: 'vivo',
        brand: 'vivo',
        model: 'V2307',
        properties: {'ro.vivo.product.release.name': 'V2307'},
      );
      expect(chooseAndroidName(sources).source, NameSource.brandAndModel);
    });

    test('vivo Y100 on BrowserStack: nothing readable names it', () {
      const sources = AndroidNameSources(
        manufacturer: 'vivo',
        brand: 'vivo',
        model: 'V2239',
        globalSettings: {'device_name': 'V2239'},
      );
      expect(
        chooseAndroidName(sources),
        const DisplayName('vivo V2239', NameSource.brandAndModel),
      );
    });

    test('Tecno: the Transsion device name', () {
      const sources = AndroidNameSources(
        manufacturer: 'TECNO',
        brand: 'TECNO',
        model: 'TECNO BG7n',
        properties: {'ro.vendor.tran.device.name': 'TECNO SPARK 20C'},
      );
      expect(chooseAndroidName(sources).name, 'TECNO SPARK 20C');
    });

    test('Motorola: the model code suffix is dropped', () {
      const sources = AndroidNameSources(
        manufacturer: 'motorola',
        brand: 'motorola',
        model: 'moto g stylus - 2026',
        properties: {
          'ro.vendor.product.display': 'moto g stylus - 2026 (XT2619V)',
        },
      );
      expect(chooseAndroidName(sources).name, 'moto g stylus - 2026');
    });

    test('Motorola without a display property: the model is the name', () {
      const sources = AndroidNameSources(
        manufacturer: 'motorola',
        brand: 'motorola',
        model: 'moto g54 5G',
      );
      expect(
        chooseAndroidName(sources),
        const DisplayName('moto g54 5G', NameSource.model),
      );
    });

    test('Huawei: a trailing space is trimmed', () {
      const sources = AndroidNameSources(
        manufacturer: 'HUAWEI',
        brand: 'HUAWEI',
        model: 'POT-LX1',
        properties: {'ro.config.marketing_name': 'HUAWEI P smart 2019 '},
      );
      expect(chooseAndroidName(sources).name, 'HUAWEI P smart 2019');
    });

    test('Xiaomi: padding inside the value is collapsed', () {
      const sources = AndroidNameSources(
        manufacturer: 'Xiaomi',
        brand: 'Redmi',
        model: 'M2006C3LI',
        properties: {'ro.product.odm.marketname': 'Redmi 9i     '},
      );
      expect(chooseAndroidName(sources).name, 'Redmi 9i');
    });

    test('Xiaomi: only placeholder copies leaves the brand and the code', () {
      const sources = AndroidNameSources(
        manufacturer: 'Xiaomi',
        brand: 'Redmi',
        model: '25028RN03Y',
        device: 'serenity',
        properties: {
          'ro.product.vendor.marketname': 'serenity_eea_TBD',
          'ro.product.system.marketname': 'TBD',
        },
      );
      expect(
        chooseAndroidName(sources),
        const DisplayName('Redmi 25028RN03Y', NameSource.brandAndModel),
      );
    });

    test('Xiaomi: a codename equal to Build.DEVICE is passed over', () {
      const sources = AndroidNameSources(
        manufacturer: 'Xiaomi',
        brand: 'Xiaomi',
        model: '23078PND5G',
        device: 'xaga',
        properties: {
          'ro.product.system.marketname': 'xaga',
          'ro.product.vendor.marketname': 'Xiaomi 13T',
        },
      );
      expect(chooseAndroidName(sources).name, 'Xiaomi 13T');
    });

    test('Fairphone: a code-shaped model gets its brand', () {
      const sources = AndroidNameSources(
        manufacturer: 'Fairphone',
        brand: 'Fairphone',
        model: 'FP5',
      );
      expect(
        chooseAndroidName(sources),
        const DisplayName('Fairphone FP5', NameSource.brandAndModel),
      );
    });

    test('Nothing: no source names it', () {
      const sources = AndroidNameSources(
        manufacturer: 'Nothing',
        brand: 'Nothing',
        model: 'A065',
      );
      expect(
        chooseAndroidName(sources),
        const DisplayName('Nothing A065', NameSource.brandAndModel),
      );
    });

    test('a key of another maker is not looked at', () {
      const sources = AndroidNameSources(
        manufacturer: 'samsung',
        brand: 'samsung',
        model: 'SM-A146B',
        properties: {'ro.config.marketing_name': 'Something Else'},
      );
      expect(chooseAndroidName(sources).source, NameSource.brandAndModel);
    });

    test('an unknown maker: the generic marketname keys are tried', () {
      const sources = AndroidNameSources(
        manufacturer: 'Acme',
        brand: 'Acme',
        model: 'AC-100',
        properties: {'ro.product.marketname': 'Acme One'},
      );
      expect(chooseAndroidName(sources).name, 'Acme One');
    });
  });

  group('the name the user gave the device', () {
    const samsungWithoutDefault = AndroidNameSources(
      manufacturer: 'samsung',
      brand: 'samsung',
      model: 'SM-G525F',
      globalSettings: {'device_name': "Anna's XCover 5"},
    );

    test('is not used unless the app allows it', () {
      expect(
        chooseAndroidName(samsungWithoutDefault),
        const DisplayName('Samsung SM-G525F', NameSource.brandAndModel),
      );
    });

    test('is used when the app allows it and nothing better is there', () {
      expect(
        chooseAndroidName(
          samsungWithoutDefault,
          userAssignedName: UserAssignedName.fallback,
        ),
        const DisplayName(
          "Anna's XCover 5",
          NameSource.userAssigned,
          key: 'device_name',
        ),
      );
    });

    test('does not win over the factory name', () {
      const sources = AndroidNameSources(
        manufacturer: 'samsung',
        brand: 'samsung',
        model: 'SM-G525F',
        globalSettings: {
          'device_name': "Anna's XCover 5",
          'default_device_name': 'Galaxy XCover 5',
        },
      );
      expect(
        chooseAndroidName(
          sources,
          userAssignedName: UserAssignedName.fallback,
        ).name,
        'Galaxy XCover 5',
      );
    });

    test('equal to the model code is still passed over', () {
      const sources = AndroidNameSources(
        manufacturer: 'Xiaomi',
        brand: 'Redmi',
        model: 'M2006C3LG',
        globalSettings: {'device_name': 'M2006C3LG'},
      );
      expect(
        chooseAndroidName(
          sources,
          userAssignedName: UserAssignedName.fallback,
        ).source,
        NameSource.brandAndModel,
      );
    });
  });

  // For a list of the user's own sessions: the name they chose tells two
  // phones apart better than two "Galaxy" names.
  group('the name the user gave the device, preferred', () {
    DisplayName preferred(AndroidNameSources sources) => chooseAndroidName(
      sources,
      userAssignedName: UserAssignedName.preferred,
    );

    test('a renamed Samsung: the user name wins over the factory name', () {
      const sources = AndroidNameSources(
        manufacturer: 'samsung',
        brand: 'samsung',
        model: 'SM-G525F',
        device: 'xcover5',
        globalSettings: {
          'device_name': "Anna's XCover 5",
          'default_device_name': 'Galaxy XCover 5',
        },
      );
      expect(
        preferred(sources),
        const DisplayName(
          "Anna's XCover 5",
          NameSource.userAssigned,
          key: 'device_name',
        ),
      );
    });

    test('a Samsung never renamed: the default equals the factory name', () {
      const sources = AndroidNameSources(
        manufacturer: 'samsung',
        brand: 'samsung',
        model: 'SM-T505',
        globalSettings: {
          'device_name': 'Galaxy Tab A7',
          'default_device_name': 'Galaxy Tab A7',
        },
      );
      expect(preferred(sources).name, 'Galaxy Tab A7');
    });

    test('a default made of the maker and the code is passed over', () {
      const sources = AndroidNameSources(
        manufacturer: 'samsung',
        brand: 'samsung',
        model: 'SM-G525F',
        globalSettings: {
          'device_name': 'samsung SM-G525F',
          'default_device_name': 'Galaxy XCover 5',
        },
      );
      expect(
        preferred(sources),
        const DisplayName(
          'Galaxy XCover 5',
          NameSource.factorySetting,
          key: 'default_device_name',
        ),
      );
    });

    test('Huawei: device_name holds the code, the factory name stays', () {
      const sources = AndroidNameSources(
        manufacturer: 'HUAWEI',
        brand: 'HUAWEI',
        model: 'MAO-LX9N',
        globalSettings: {
          'device_name': 'MAO-LX9N',
          'unified_default_device_name': 'HUAWEI nova 11i',
        },
      );
      expect(preferred(sources).name, 'HUAWEI nova 11i');
    });

    test(
      'Redmi 9A: device_name is the code, the MIUI name property is used',
      () {
        const sources = AndroidNameSources(
          manufacturer: 'Xiaomi',
          brand: 'Redmi',
          model: 'M2006C3LG',
          properties: {
            'ro.product.marketname': 'Redmi 9A',
            'persist.sys.device_name': 'Redmi 9A',
          },
          globalSettings: {'device_name': 'M2006C3LG'},
        );
        expect(
          preferred(sources),
          const DisplayName(
            'Redmi 9A',
            NameSource.userAssigned,
            key: 'persist.sys.device_name',
          ),
        );
      },
    );

    test(
      'an empty Build.MODEL does not pass over every name the user gave',
      () {
        const sources = AndroidNameSources(
          manufacturer: 'samsung',
          brand: 'samsung',
          model: '',
          globalSettings: {
            'device_name': "Anna's phone",
            'default_device_name': 'Galaxy A14',
          },
        );
        expect(
          chooseAndroidName(
            sources,
            userAssignedName: UserAssignedName.preferred,
          ).name,
          "Anna's phone",
        );
      },
    );

    test('Pixel: the AOSP default "Google Pixel 9" is passed over', () {
      const sources = AndroidNameSources(
        manufacturer: 'Google',
        brand: 'google',
        model: 'Pixel 9',
        globalSettings: {'device_name': 'Google Pixel 9'},
      );
      expect(
        preferred(sources),
        const DisplayName('Pixel 9', NameSource.model),
      );
    });
  });

  test('isMarketingName tells a found name from a put-together one', () {
    expect(
      const DisplayName(
        'Galaxy M32',
        NameSource.factorySetting,
      ).isMarketingName,
      isTrue,
    );
    expect(
      const DisplayName('Pixel 9', NameSource.model).isMarketingName,
      isTrue,
    );
    expect(
      const DisplayName(
        'Samsung SM-G525F',
        NameSource.brandAndModel,
      ).isMarketingName,
      isFalse,
    );
    expect(
      const DisplayName('iPhone99,1', NameSource.identifier).isMarketingName,
      isFalse,
    );
  });

  test(
    'every maker\'s keys are in the table, and the generic ones under null',
    () {
      final table = androidKeysByMaker();
      expect(table['samsung']!.globalSettings, contains('default_device_name'));
      expect(
        table['iqoo']!.properties,
        contains('ro.vivo.product.release.name'),
      );
      expect(table[null]!.properties, contains('ro.product.marketname'));
      expect(
        androidKeysOfAllMakers().properties,
        containsAll([
          'ro.config.marketing_name',
          'ro.odm.lenovo.series',
          'ro.vendor.oplus.market.name',
        ]),
      );
    },
  );

  group('androidKeysFor', () {
    test(
      'Huawei: its settings and property keys, and the user-assigned ones',
      () {
        final keys = androidKeysFor(manufacturer: 'HUAWEI', brand: 'HUAWEI');
        expect(keys.properties, [
          'ro.config.marketing_name',
          'persist.sys.device_name',
        ]);
        expect(keys.globalSettings, [
          'unified_default_device_name',
          'device_name',
        ]);
      },
    );

    test('a brand of a known maker is found by the manufacturer too', () {
      final keys = androidKeysFor(manufacturer: 'Xiaomi', brand: 'POCO');
      expect(keys.properties, contains('ro.product.odm.marketname'));
    });

    test('no key of another maker is asked for', () {
      final keys = androidKeysFor(manufacturer: 'OPPO', brand: 'OPPO');
      expect(keys.properties, isNot(contains('ro.odm.lenovo.series')));
      expect(keys.globalSettings, isNot(contains('default_device_name')));
    });

    test('an unknown maker: the generic marketname keys', () {
      final keys = androidKeysFor(manufacturer: 'Acme', brand: 'Acme');
      expect(keys.properties, [
        'ro.product.marketname',
        'ro.product.odm.marketname',
        'persist.sys.device_name',
      ]);
    });
  });
}
