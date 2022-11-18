[![pub package](https://img.shields.io/pub/v/ble_reader?include_prereleases)](https://pub.dartlang.org/packages/ble_reader)
[![style: lint](https://img.shields.io/badge/style-lint-4BC0F5.svg)](https://pub.dev/packages/lint)
# Bluetooth Low Energy Received Data Reader
## Install
This project is a flutter plugin,so you use it by add dependencies in your pubspec.yaml.
```yaml
dependencies:
  flutter:
    sdk: flutter
  ble_reader: ^0.1.0
```
```shell script
$ flutter pub get
```


## How to use
Please check the example app to see how to broadcast received data.

## Getting Started
### Android

You need to add the following permissions to your AndroidManifest.xml file:

```xml
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" android:usesPermissionFlags="neverForLocation" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" android:maxSdkVersion="30" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" android:maxSdkVersion="30" />
```

If you use `BLUETOOTH_SCAN` to determine location, modify your AndroidManfiest.xml file to include the following entry:

```xml
 <uses-permission android:name="android.permission.BLUETOOTH_SCAN" 
                     tools:remove="android:usesPermissionFlags"
                     tools:targetApi="s" />
```

If you use location services in your app, remove `android:maxSdkVersion="30"` from the location permission tags

### Android ProGuard rules
In case you are using ProGuard add the following snippet to your `proguard-rules.pro` file:

```
-keep class com.signify.hue.** { *; }
```

This will prevent issues like [#131](https://github.com/PhilipsHue/flutter_reactive_ble/issues/131).

### iOS

For iOS it is required you add the following entries to the `Info.plist` file of your app. It is not allowed to access Core BLuetooth without this. See [our example app](https://github.com/PhilipsHue/flutter_reactive_ble/blob/master/example/ios/Runner/Info.plist) on how to implement this. For more indepth details: [Blog post on iOS bluetooth permissions](https://medium.com/flawless-app-stories/handling-ios-13-bluetooth-permissions-26c6a8cbb816)

iOS13 and higher
* NSBluetoothAlwaysUsageDescription

iOS12 and lower
* NSBluetoothPeripheralUsageDescription

## Usage
### Import
Import plugin module where you need use.
```dart
import 'package:ble_reader/ble_reader.dart';
```

### Initialization

Initializing the library should be done the following:

```dart
final bleReader = BleReader();
```

### Setup connectivity and configure GATT server.
```dart
final result = await BleReader.setupConnection;
if (!result) throw Exception('error bitches!!');
// do something
 ```

### 
```dart
StreamBuilder(
  stream: BleReader.receivedDataStream,
  initialData: 'None',
  builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
      return Text('Data received: ${snapshot.data}');
    },
  );
```


