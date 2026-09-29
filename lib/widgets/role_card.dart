import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

class RoleCard extends StatelessWidget {
  const RoleCard({
    super.key,
    required this.image,
    required this.text,
    required this.onNext,
  });

  final String image;
  final String text;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 190,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(image, fit: BoxFit.cover),
            Center(
              child: Container(
                width: 240,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      text,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.cormorantGaramond(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.navy,
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: onNext,
                      style: OutlinedButton.styleFrom(
                        backgroundColor: const Color(0xFFD9D9D9),
                        side: const BorderSide(color: AppColors.navy),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Siguiente',
                        style: GoogleFonts.courierPrime(
                          fontSize: 13,
                          color: AppColors.hint,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}