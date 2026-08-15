import 'package:flutter/material.dart';

import 'screens/login_screen.dart';

void main() => runApp(const DonApp());

class DonApp extends StatelessWidget {
  const DonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DonApp',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}
