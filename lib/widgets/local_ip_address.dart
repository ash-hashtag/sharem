import 'dart:io';

import 'package:flutter/material.dart';

class LocalIpAddress extends StatefulWidget {
  final Function([int? port]) onReset;
  const LocalIpAddress({super.key, required this.onReset});

  @override
  State<LocalIpAddress> createState() => _LocalIpAddressState();
}

class _LocalIpAddressState extends State<LocalIpAddress> {
  var ipAddr = "";
  var port = 8080;

  late final controller = TextEditingController(text: port.toString());

  @override
  void initState() {
    super.initState();
    refresh();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future getIpAddress() =>
      NetworkInterface.list().then((value) => value.first.addresses
          .firstWhere((e) => e.type == InternetAddressType.IPv4,
              orElse: () =>
                  InternetAddress('127.0.0.1', type: InternetAddressType.IPv4))
          .address);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.7,
            child: Text(ipAddr),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              decoration:
                  const InputDecoration(labelText: 'Port', hintText: '8080'),
            ),
          ),
          IconButton(
            onPressed: refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
    );
  }

  void refresh() async {
    final newPort = int.tryParse(controller.text);
    if (newPort == null) {
      widget.onReset();
    } else {
      if (port != newPort) {
        widget.onReset(port = newPort);
      }
    }
    final ip = await getIpAddress();
    if (ip != ipAddr) {
      setState(() {
        ipAddr = ip;
      });
    }
  }
}
