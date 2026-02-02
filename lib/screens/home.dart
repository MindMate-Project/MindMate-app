import 'package:flutter/material.dart';
import 'package:mindmate/themes/app_theme.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: Center(child: Text('welcome to home')),
    );
  }
}
