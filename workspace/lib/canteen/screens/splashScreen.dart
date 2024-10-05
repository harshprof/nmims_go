import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.orange[100], // Light orange background
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.restaurant_menu,
              size: 100,
              color: Colors.orange[800],
            )
                .animate()
                .scale(duration: 500.ms, curve: Curves.easeOutBack)
                .then()
                .shake(duration: 500.ms),
            const SizedBox(height: 24),
            Text(
              'NMIMS Canteen',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.orange[800],
                    fontWeight: FontWeight.bold,
                  ),
            )
                .animate()
                .fadeIn(duration: 800.ms, delay: 300.ms)
                .then()
                .slide(duration: 500.ms),
            const SizedBox(height: 8),
            Text(
              'Delicious food at your fingertips',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.orange[600],
                  ),
            ).animate().fadeIn(duration: 800.ms, delay: 800.ms),
          ],
        ),
      ),
    );
  }
}