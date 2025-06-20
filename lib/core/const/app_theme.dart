import 'package:file_manager2/core/const/app_color.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData appTheme = ThemeData(
    textTheme: GoogleFonts.interTextTheme(),
    bottomAppBarTheme: BottomAppBarTheme(
      color: const Color.fromARGB(255, 192, 108, 108),
    ),
    appBarTheme: AppBarTheme(elevation: 0, color: Colors.white),
    scaffoldBackgroundColor: AppColor.backgroundColor,

    // Enhanced InputDecorationTheme
    inputDecorationTheme: InputDecorationTheme(
      // Border styles
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: Colors.transparent, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: Colors.transparent, width: 2.0),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: Colors.transparent, width: 2.0),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: Colors.transparent, width: 2.0),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: Colors.grey.shade200, width: 1.0),
      ),

      // Fill and background
      filled: true,
      fillColor: Colors.grey.shade50,

      // Content padding
      contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),

      // Label and hint styles
      labelStyle: TextStyle(
        color: Colors.grey.shade600,
        fontSize: 16.0,
        fontWeight: FontWeight.w500,
      ),
      floatingLabelStyle: TextStyle(
        color: const Color.fromARGB(255, 192, 108, 108),
        fontSize: 14.0,
        fontWeight: FontWeight.w600,
      ),
      hintStyle: TextStyle(
        color: Colors.grey.shade400,
        fontSize: 14.0,
        fontWeight: FontWeight.w400,
      ),

      // Error style
      errorStyle: TextStyle(
        color: Colors.red.shade600,
        fontSize: 12.0,
        fontWeight: FontWeight.w500,
      ),

      // Helper text style
      helperStyle: TextStyle(color: Colors.grey.shade500, fontSize: 12.0),

      // Floating label behavior
      floatingLabelBehavior: FloatingLabelBehavior.auto,

      // Alignment
      alignLabelWithHint: true,

      // Dense layout
      isDense: false,
    ),
  );
}
