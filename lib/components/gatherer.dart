import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:sharem_cli/sharem_cli.dart';

class GathererWidget extends StatefulWidget {
  final void Function(SharemPeer peer) onTap;

  const GathererWidget({super.key, required this.onTap});

  @override
  State<GathererWidget> createState() => _GathererWidgetState();
}

class _GathererWidgetState extends State<GathererWidget> {
  final Map<InternetAddress, SharemPeer> _peers = {};

  StreamSubscription? _subscription;

  @override
  void initState() {
    super.initState();

    _subscription = listenForPeers()
        .listen((peer) => setState(() => _peers[peer.address] = peer));
  }

  @override
  void dispose() {
    super.dispose();
    _subscription?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    final peers = _peers.values.toList();

    return ListView.builder(
      itemCount: peers.length,
      itemBuilder: (context, index) => ListTile(
        title: Text(
          peers[index].uniqueName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text("${peers[index].address.host}:${peers[index].port}"),
        onTap: () => widget.onTap(peers[index]),
      ),
    );
  }
}
