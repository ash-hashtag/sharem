import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sharem/screens/homepage.dart';
import 'package:sharem/screens/recieved_files.dart';
import 'package:sharem/screens/recieving_files.dart';
import 'package:sharem/screens/settings.dart';

class NavScreen extends StatefulWidget {
  const NavScreen({super.key});

  @override
  State<NavScreen> createState() => _NavScreenState();
}

class _NavScreenState extends State<NavScreen> {
  final downloadsKey = GlobalKey<RecievingFilesState>();

  final downloadedKey = GlobalKey<RecievedFilesState>();

  Future<Directory?> directory() async {
    const channel = MethodChannel("channel");
    final String? result = await channel.invokeMethod("getExternalDir");
    if (result == null) {
      return null;
    } else {
      return Directory(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: directory(),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data != null) {
            return DefaultTabController(
              length: 4,
              child: Scaffold(
                appBar: AppBar(
                  title: const Text("Sharem"),
                  bottom: const TabBar(
                    tabs: [
                      Tab(icon: Icon(Icons.home)),
                      Tab(icon: Icon(Icons.download)),
                      Tab(icon: Icon(Icons.folder)),
                      Tab(icon: Icon(Icons.settings)),
                    ],
                  ),
                ),
                body: TabBarView(
                  children: [
                    HomePage(
                      dir: snapshot.data!,
                      downloadsKey: downloadsKey,
                      downloadedKey: downloadedKey,
                    ),
                    RecievingFiles(
                      key: downloadsKey,
                    ),
                    RecievedFiles(
                      dir: snapshot.data!,
                      key: downloadedKey,
                    ),
                    const SettingsPage()
                  ],
                ),
              ),
            );
          } else {
            return const Scaffold();
          }
        });
  }
}
