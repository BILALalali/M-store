import 'package:flutter/material.dart';

class BalanceScreen extends StatelessWidget {
  const BalanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'شاشة شحن الأرصدة',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
    );
  }
}
