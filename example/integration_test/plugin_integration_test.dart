// Runs on a device, against the real platform side:
//
//   flutter test integration_test -d <device>

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:device_display_name/device_display_name.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const DeviceDisplayName deviceName = PlatformDeviceDisplayName();

  testWidgets('read gives a name', (tester) async {
    final name = await deviceName.read();

    expect(name, isNotNull);
    expect(name!.name, isNotEmpty);
  });

  testWidgets('the platform reads the build fields', (tester) async {
    final sources = await const PlatformDeviceDisplayName().readSources();

    expect(sources, isNotNull);
    expect(sources!.keys, anyOf(contains('model'), contains('machine')));
  });
}
