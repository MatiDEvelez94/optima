import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppText {
  static TextStyle get logo => GoogleFonts.cormorantGaramond(
      fontSize: 38, letterSpacing: 14, color: AppColors.navy);

  static TextStyle get tagline => GoogleFonts.cormorantGaramond(
      fontSize: 13, letterSpacing: 3, color: AppColors.navy);

  static TextStyle get title => GoogleFonts.cormorantGaramond(
      fontSize: 32, fontWeight: FontWeight.w500, color: AppColors.navy);

  static TextStyle get subtitle => GoogleFonts.cormorantGaramond(
      fontSize: 18, letterSpacing: 4, color: AppColors.navy);

  static TextStyle get label => GoogleFonts.cormorantGaramond(
      fontSize: 14, letterSpacing: 3, color: AppColors.navy);

  static TextStyle get input =>
      GoogleFonts.courierPrime(fontSize: 13, color: AppColors.hint);

  static TextStyle get link => GoogleFonts.courierPrime(
      fontSize: 16,
      color: Colors.black,
      decoration: TextDecoration.underline);

  static TextStyle get banner => GoogleFonts.cormorantGaramond(
      fontSize: 26, color: AppColors.cream);

  static TextStyle get eventText =>
      GoogleFonts.courierPrime(fontSize: 10, color: AppColors.cream);
}