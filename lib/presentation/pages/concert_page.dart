import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class ConcertPage extends StatelessWidget {
  const ConcertPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background fills entire screen
        Container(decoration: BoxDecoration(color: AppColors.background1)),

        // Content on top
        SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search, size: 80, color: AppColors.primary),
                const SizedBox(height: 16),
                Text(
                  'Search',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Cari lagu, artis, atau album',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
