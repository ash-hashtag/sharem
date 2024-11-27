import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:sharem/components/gatherer.dart';
import 'package:sharem_cli/sharem_cli.dart';
import 'package:sharem_cli/unique_name.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _tc = TextEditingController();
  Timer? _broadcastTimer;
  HttpServer? _server;

  bool get isReceiving => _broadcastTimer != null && _server != null;

  @override
  void dispose() {
    super.dispose();
    _tc.dispose();
    _broadcastTimer?.cancel();
    _server?.close();
    // Dispose PeerState
  }

  void stopReceiving() {
    setState(() {
      _broadcastTimer?.cancel();
      _broadcastTimer = null;
      _server?.close();
      _server = null;
    });
  }

  Future<void> startReceiving() async {
    final server = await startHttpServer(0);
    debugPrint("Started Server at ${server.address.host}:${server.port}");
    final message =
        SharemPeerMessage(server.port, generateUniqueName()).toJSON();
    final timer = Timer.periodic(const Duration(seconds: 1),
        (_) => sendBroadcast(message, InternetAddress("255.255.255.255")));
    setState(() {
      _server = server;
      _broadcastTimer = timer;
    });
  }

  void onTap(SharemPeer peer) async {
    if (_tc.text.isNotEmpty) {
      await peer.sendText(_tc.text);
      debugPrint("Sent text ${_tc.text} to ${peer.uniqueName}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sharem"),
      ),
      body: Column(children: [
        TextButton(
          child: Text(isReceiving ? "Stop Receiving" : "Start Receiving"),
          onPressed: () async {
            if (isReceiving) {
              stopReceiving();
            } else {
              startReceiving();
            }
          },
        ),
        TextField(
          controller: _tc,
        ),
        Expanded(child: GathererWidget(onTap: onTap)),
      ]),
    );
  }
}
