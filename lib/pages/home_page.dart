import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:sharem/components/receiver.dart';
import 'package:sharem/components/send.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final StreamSubscription _intentSub;
  var _selectedIndex = 0;

  final _senderKey = GlobalKey<SenderWidgetState>();

  late final pages = [
    const ReceiverWidget(),
    SenderWidget(key: _senderKey),
  ];

  @override
  void initState() {
    super.initState();

    ReceiveSharingIntent.instance.getInitialMedia().then(onFilesIntent);

    _intentSub =
        ReceiveSharingIntent.instance.getMediaStream().listen(onFilesIntent);
  }

  void onFilesIntent(List<SharedMediaFile> files) {
    if (files.isEmpty) {
      return;
    }

    if (_senderKey.currentState != null) {
      _senderKey.currentState!
          .onFilesPicked(files.map((file) => File(file.path)).toList());
    }

    setState(() => _selectedIndex = 1);
  }

  @override
  void dispose() {
    super.dispose();
    _intentSub.cancel();
  }

  @override
  Widget build(BuildContext context) {
    final navbar = NavigationBar(
      selectedIndex: _selectedIndex,
      onDestinationSelected: (index) => setState(() => _selectedIndex = index),
      destinations: const [
        NavigationDestination(label: "Receive", icon: Icon(Icons.wifi)),
        NavigationDestination(label: "Send", icon: Icon(Icons.send)),
      ],
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text("Sharem"),
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),
      bottomNavigationBar: navbar,
    );
  }
}
