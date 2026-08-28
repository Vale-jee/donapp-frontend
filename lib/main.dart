import 'package:flutter/material.dart';

import 'screens/session_gate.dart';
import 'services/session_coordinator.dart';
import 'theme/app_theme.dart';

void main() => runApp(const DonApp());

class DonApp extends StatelessWidget {
  const DonApp({this.sessionCoordinator, super.key});

  final SessionCoordinator? sessionCoordinator;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DonApp',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: SessionGate(coordinator: sessionCoordinator),
    );
  }
}
