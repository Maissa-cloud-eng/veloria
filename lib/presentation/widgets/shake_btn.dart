import 'dart:math';

import 'package:flutter/material.dart';

class ShakeButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onPressed;

  const ShakeButton({super.key, required this.child, required this.onPressed});

  @override
  State<ShakeButton> createState() => _ShakeButtonState();
}

class _ShakeButtonState extends State<ShakeButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    // On lance l'animation en boucle avec une pause
    _startAnimation();
  }

  void _startAnimation() async {
    while (mounted) {
      await Future.delayed(
        const Duration(seconds: 3),
      ); // Pause entre chaque shake
      if (mounted) await _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Calcul du décalage (offset) pour l'effet de tremblement
        final double sineValue = sin(4 * pi * _controller.value);
        return Transform.translate(
          offset: Offset(sineValue * 4, 0), // 4 pixels de mouvement horizontal
          child: child,
        );
      },
      child: ElevatedButton(
        onPressed: widget.onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFE91E63),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 4,
        ),
        child: widget.child,
      ),
    );
  }
}
