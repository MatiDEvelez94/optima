import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppText {
  // Titulos: Cormorant Garamond
  static TextStyle get logo => GoogleFonts.cormorantGaramond(
      fontSize: 38, letterSpacing: 14, color: AppColors.navy);

  static TextStyle get tagline => GoogleFonts.cormorantGaramond(
      fontSize: 13, letterSpacing: 3, color: AppColors.navy);

  static TextStyle get title => GoogleFonts.cormorantGaramond(
      fontSize: 32, fontWeight: FontWeight.w500, color: AppColors.navy);

  static TextStyle get banner => GoogleFonts.cormorantGaramond(
      fontSize: 26, color: AppColors.cream);

  // Subtitulos y mensajes: Lato
  static TextStyle get subtitle => GoogleFonts.lato(
      fontSize: 15, letterSpacing: 0.3, color: AppColors.navy);

  // Campos de texto, botones, tarjetas y enlaces: Lato
  static TextStyle get input =>
      GoogleFonts.lato(fontSize: 13, color: AppColors.hint);

  // Mini titulos de cada dato (formularios, detalles, perfil, historial)
  static TextStyle get label => GoogleFonts.lato(
      fontSize: 13, letterSpacing: 0.5, color: AppColors.navy);

  // Nombre de cada dato a completar en los formularios
  static TextStyle get campo => GoogleFonts.lato(
      fontSize: 13, letterSpacing: 0.5, color: AppColors.navy);

  static TextStyle get link => GoogleFonts.lato(
      fontSize: 16,
      color: Colors.black,
      decoration: TextDecoration.underline);

  static TextStyle get eventText =>
      GoogleFonts.lato(fontSize: 10, color: AppColors.cream);
}
