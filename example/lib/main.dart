import 'package:flutter/material.dart';

import 'package:device_display_name/device_display_name.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  static const _deviceName = PlatformDeviceDisplayName();
  static const _withUserName = PlatformDeviceDisplayName(
    userAssignedName: UserAssignedName.preferred,
  );

  DisplayName? _name;
  DisplayName? _nameWithUserName;
  Map<Object?, Object?>? _sources;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final name = await _deviceName.read();
    final nameWithUserName = await _withUserName.read();
    final sources = await _deviceName.readSources();
    if (!mounted) return;
    setState(() {
      _name = name;
      _nameWithUserName = nameWithUserName;
      _sources = sources;
      _loaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('device_display_name')),
        body: !_loaded
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _NameTile(title: 'Name', name: _name),
                  _NameTile(
                    title: 'Name, user-assigned preferred',
                    name: _nameWithUserName,
                  ),
                  const Divider(),
                  Text(
                    'What the platform read',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  for (final line in _lines(_sources))
                    SelectableText(line, key: ValueKey(line)),
                ],
              ),
      ),
    );
  }

  static Iterable<String> _lines(Map<Object?, Object?>? sources) sync* {
    if (sources == null) {
      yield 'nothing - the platform is not supported';
      return;
    }
    for (final MapEntry(:key, :value) in sources.entries) {
      if (value is Map) {
        for (final MapEntry(key: inner, value: innerValue) in value.entries) {
          yield '$key / $inner = $innerValue';
        }
        if (value.isEmpty) yield '$key = (none readable)';
      } else {
        yield '$key = $value';
      }
    }
  }
}

IconData _iconOf(DeviceKind kind) => switch (kind) {
  DeviceKind.phone => Icons.smartphone,
  DeviceKind.tablet => Icons.tablet_android,
  DeviceKind.foldable => Icons.devices_fold,
  DeviceKind.watch => Icons.watch,
  DeviceKind.tv => Icons.tv,
  DeviceKind.car => Icons.directions_car,
  DeviceKind.desktop => Icons.laptop,
  DeviceKind.headset => Icons.vrpano,
  DeviceKind.unknown => Icons.device_unknown,
};

class _NameTile extends StatelessWidget {
  const _NameTile({required this.title, required this.name});

  final String title;
  final DisplayName? name;

  @override
  Widget build(BuildContext context) {
    final name = this.name;
    return ListTile(
      leading: Icon(_iconOf(name?.kind ?? DeviceKind.unknown)),
      title: Text(name?.name ?? '-'),
      subtitle: Text(
        name == null
            ? title
            : '$title - ${name.source.name}${name.key == null ? '' : ' (${name.key})'}\n'
                  'kind: ${name.kind.name} - full: ${name.fullName}\n'
                  'User-Agent: ${name.userAgentToken}',
      ),
    );
  }
}
