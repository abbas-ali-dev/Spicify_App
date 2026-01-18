import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTypography {
  static const String fontFamily = 'Poppins';

  static const TextStyle heading16Bold = TextStyle(
      fontFamily: fontFamily,
      fontWeight: FontWeight.w600,
      fontSize: 16,
      height: 1.0, // 100% line height
      letterSpacing: 0,
      color: AppColors.white,
      decoration: TextDecoration.none);

  static const TextStyle sectionHeaderLabel = TextStyle(
      fontFamily: fontFamily,
      fontWeight: FontWeight.w500,
      fontSize: 16,
      height: 1.0, // 100% line height
      letterSpacing: 0,
      color: AppColors.white,
      decoration: TextDecoration.none);

  static const TextStyle buttonText = TextStyle(
      fontFamily: fontFamily,
      fontWeight: FontWeight.w500,
      fontSize: 16,
      color: AppColors.white,
      decoration: TextDecoration.none);

  static const TextStyle hintText = TextStyle(
      fontFamily: fontFamily,
      fontWeight: FontWeight.w400,
      fontSize: 14,
      color: AppColors.white70,
      decoration: TextDecoration.none);

  static const TextStyle medium14Text = TextStyle(
      fontFamily: fontFamily,
      fontWeight: FontWeight.w500,
      fontSize: 14,
      color: AppColors.white,
      decoration: TextDecoration.none);

  static const TextStyle regular16Text = TextStyle(
      fontFamily: fontFamily,
      fontWeight: FontWeight.w400,
      fontSize: 16,
      color: AppColors.white,
      decoration: TextDecoration.none);

  static const TextStyle labelText = TextStyle(
      fontFamily: fontFamily,
      fontWeight: FontWeight.w500,
      fontSize: 14,
      color: AppColors.white,
      decoration: TextDecoration.none);

  static const TextStyle linkText = TextStyle(
      fontFamily: fontFamily,
      fontWeight: FontWeight.w500,
      fontSize: 14,
      color: AppColors.buttonRed,
      decoration: TextDecoration.none);

  static const TextStyle appTitle = TextStyle(
      fontFamily: fontFamily,
      fontWeight: FontWeight.w600,
      fontSize: 28,
      color: AppColors.buttonRed,
      decoration: TextDecoration.none);

  static const TextStyle homeTitle = TextStyle(
      fontFamily: fontFamily,
      fontWeight: FontWeight.bold,
      fontSize: 24,
      color: AppColors.white,
      decoration: TextDecoration.none);
}
