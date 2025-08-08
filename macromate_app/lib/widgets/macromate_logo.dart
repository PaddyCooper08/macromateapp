import 'package:flutter/material.dart';

class MacroMateLogo extends StatelessWidget {
  final double size;
  final Color? color;

  const MacroMateLogo({super.key, this.size = 32, this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final asset = isDark ? 'dark icon.png' : 'light icon.png';

    return Container(
      width: size,
      height: size,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.2),
        child: Image.asset(
          asset,
          width: size,
          height: size,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            final logoColor = color ?? (isDark ? Colors.white : Colors.black);
            final backgroundColor = isDark ? Colors.black : Colors.white;

            return Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(size * 0.2),
                color: backgroundColor,
                border: Border.all(color: logoColor.withOpacity(0.2), width: 1),
              ),
              child: Center(
                child: Text(
                  'M',
                  style: TextStyle(
                    fontSize: size * 0.5,
                    fontWeight: FontWeight.bold,
                    color: logoColor,
                    height: 1,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
