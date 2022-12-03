import 'package:flutter/material.dart';

class SyncPastedData extends StatefulWidget {
  const SyncPastedData({super.key});

  @override
  State<SyncPastedData> createState() => _SyncPastedDataState();
}

class _SyncPastedDataState extends State<SyncPastedData> {
  final tc = TextEditingController();

  @override
  void dispose() {
    tc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        TextField(
          controller: tc,
          maxLines: 10,
        ),
        TextButton(onPressed: send, child: const Text('send'))
      ],
    );
  }

  void send() async {
    
  }
}
