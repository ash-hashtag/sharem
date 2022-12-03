import 'package:flutter/material.dart';

class ConnectionDetails extends StatefulWidget {
  const ConnectionDetails({super.key});

  @override
  State<ConnectionDetails> createState() => ConnectionDetailsState();
}

class ConnectionDetailsState extends State<ConnectionDetails> {
  final ipController = TextEditingController(),
      portController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    ipController.dispose();
    portController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.7,
            child: TextField(
              controller: ipController,
              decoration:
                  const InputDecoration(labelText: 'reciever ip address'),
            ),
          ),
          Expanded(
            child: TextField(
              controller: portController,
              decoration: const InputDecoration(labelText: 'port of the reciever'),
            ),
          ),
        ],
      ),
    );
  }

  String? ipAddrValidation() {
    final ipAddr = ipController.text;
    final values = ipAddr.split('.');
    const errorText = 'invalid ip';
    if (values.length != 4) {
      return errorText;
    } else {
      if (!values.every((e) {
        final value = int.tryParse(e);
        return value != null && value >= 0 && value < 256;
      })) {
        return errorText;
      }
    }
    return null;
  }
}
