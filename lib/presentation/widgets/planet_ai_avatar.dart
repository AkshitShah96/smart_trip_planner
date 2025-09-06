import 'package:flutter/material.dart';

class PlanetAiAvatar extends StatelessWidget {
  final double size;
  final bool showAnimation;

  const PlanetAiAvatar({
    super.key,
    this.size = 40.0,
    this.showAnimation = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF4FC3F7), // Light blue
            Color(0xFF29B6F6), // Medium blue
            Color(0xFF81C784), // Light green
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Earth continents (simplified)
          CustomPaint(
            size: Size(size, size),
            painter: EarthPainter(),
          ),
          // Eyes
          Positioned(
            top: size * 0.25,
            left: size * 0.3,
            child: Container(
              width: size * 0.08,
              height: size * 0.08,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            top: size * 0.25,
            right: size * 0.3,
            child: Container(
              width: size * 0.08,
              height: size * 0.08,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Smile
          Positioned(
            bottom: size * 0.3,
            child: Container(
              width: size * 0.4,
              height: size * 0.15,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
            ),
          ),
          // Headphones
          Positioned(
            top: size * 0.1,
            child: Container(
              width: size * 0.8,
              height: size * 0.15,
              decoration: BoxDecoration(
                color: const Color(0xFFFFD54F), // Yellow
                borderRadius: BorderRadius.circular(size * 0.075),
                border: Border.all(
                  color: Colors.white,
                  width: 1,
                ),
              ),
            ),
          ),
          // Musical notes (if animation is enabled)
          if (showAnimation) ...[
            Positioned(
              top: size * 0.05,
              left: size * 0.1,
              child: Icon(
                Icons.music_note,
                size: size * 0.15,
                color: Colors.pink[300],
              ),
            ),
            Positioned(
              top: size * 0.1,
              right: size * 0.1,
              child: Icon(
                Icons.music_note,
                size: size * 0.12,
                color: Colors.pink[300],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class EarthPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF4CAF50) // Green for continents
      ..style = PaintingStyle.fill;

    final path = Path();
    
    // Simplified continent shapes
    // North America
    path.addOval(Rect.fromLTWH(size.width * 0.2, size.height * 0.1, size.width * 0.3, size.height * 0.2));
    
    // Europe/Africa
    path.addOval(Rect.fromLTWH(size.width * 0.5, size.height * 0.15, size.width * 0.25, size.height * 0.4));
    
    // Asia
    path.addOval(Rect.fromLTWH(size.width * 0.6, size.height * 0.2, size.width * 0.3, size.height * 0.25));
    
    // Australia
    path.addOval(Rect.fromLTWH(size.width * 0.7, size.height * 0.6, size.width * 0.2, size.height * 0.15));
    
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

