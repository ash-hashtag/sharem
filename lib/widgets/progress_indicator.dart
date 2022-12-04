import 'dart:async';

import 'package:flutter/material.dart';

class ProgressionIndicator extends StatefulWidget {
  
  const ProgressionIndicator({Key? key}) : super(key: key);
  @override
  State<ProgressionIndicator> createState() => _ProgressionIndicatorState();
}

class _ProgressionIndicatorState extends State<ProgressionIndicator> {
  double value = 0;
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(20),
      child: LinearProgressIndicator(
        backgroundColor: Colors.lightBlueAccent,
        color: Colors.red,
        minHeight: 15,
        value: value,
      ),
    );
  }

  void determinateIndicator() {
    Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      setState(() {
        if (value == 1) {
          timer.cancel();
        } else {
          value = value + 0.1;
        }
      });
    });
  }
}
