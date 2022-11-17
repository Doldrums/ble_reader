import 'package:flutter/material.dart';

import 'package:ble_reader/ble_reader.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: StreamBuilder(
            stream: BleReader.receivedDataStream.asBroadcastStream(),
            initialData: 'None',
            builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
              return Text('Data received: ${snapshot.data}');
            },
          ),
        ),
      ),
    );
  }
}
