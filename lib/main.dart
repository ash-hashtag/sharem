import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sharem/screens/navscreen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<Directory?> directory() async {
    const channel = MethodChannel("channel");
    final String? result = await channel.invokeMethod("getExternalDir");
    if (result == null) {
      return null;
    } else {
      return Directory(result);
    }
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sharem',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: FutureBuilder(
          future: directory(),
          builder: (context, snapshot) {
            return snapshot.hasData && snapshot.data != null
                ? NavScreen(directory: snapshot.data!)
                : const Scaffold(
                    body: Center(child: CircularProgressIndicator.adaptive()),
                  );
          }),
    );
  }
}
