import 'dart:io';

import 'package:flutter/material.dart';

class LocalIpAddress extends StatefulWidget {
  const LocalIpAddress({super.key});

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
    getIpAddress().then((value) => setState(() => ipAddr = value.toString()));
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
        ],
      ),
    );
  }
}
