import 'package:flutter/material.dart';
import 'package:sharem/components/receiver.dart';
import 'package:sharem/components/send.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  var _selectedIndex = 0;

  final pages = const [
    ReceiverWidget(),
    SenderWidget(),
  ];

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
