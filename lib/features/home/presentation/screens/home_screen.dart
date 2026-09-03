import 'package:flutter/material.dart';
import '../../../../core/constants/app_strings.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.homeTitle),
      ),
      body: const Center(
        child: Text('Welcome to Self Service App'),
      ),
    );
  }
}
