# device_display_name example

Shows what the plugin gives on the device it runs on: the name in the default mode and with
`UserAssignedName.preferred`, where each came from, the device kind with its icon, `fullName`,
`userAgentToken`, and every source the plugin read.

```sh
flutter run
```

The integration tests run against the real platform side:

```sh
flutter test integration_test -d <device>
```
