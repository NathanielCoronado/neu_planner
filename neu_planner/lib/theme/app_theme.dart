import 'package:flutter/material.dart';

import '../models/task.dart';

/// NEU-inspired palette: deep university blue with a gold accent.
/// Adjust these hex values to match your official logo if needed.
class AppColors {
  static const navy = Color(0xFF12357A);
  static const navyDeep = Color(0xFF0C2557);
  static const gold = Color(0xFFE3B23C);
  static const goldSoft = Color(0xFFF7E7BC);
  static const paper = Color(0xFFF3F5F9);
  static const ink = Color(0xFF1B2333);
  static const muted = Color(0xFF5D6B82);
  static const line = Color(0xFFDDE2EB);
  static const danger = Color(0xFFC2352B);
  static const dangerSoft = Color(0xFFFBE4E1);
  static const success = Color(0xFF2E7D5B);

  /// Colors a student can assign to a subject.
  static const subjectPalette = <int>[
    0xFF12357A, // NEU blue
    0xFFC28A12, // gold
    0xFF2E7D5B, // green
    0xFFB0413E, // brick
    0xFF6A4C93, // violet
    0xFF1F8A9E, // teal
    0xFFD9632B, // orange
    0xFF4E5D78, // slate
  ];

  static Color priority(Priority p) => switch (p) {
    Priority.high => danger,
    Priority.medium => const Color(0xFFB07A0B),
    Priority.low => muted,
  };
}

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.navy,
    primary: AppColors.navy,
    secondary: AppColors.gold,
    error: AppColors.danger,
    surface: Colors.white,
  );

  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: const BorderSide(color: AppColors.line),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.paper,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.paper,
      foregroundColor: AppColors.ink,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontFamily: 'Roboto',
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: AppColors.ink,
        letterSpacing: -0.3,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      errorMaxLines: 2,
      filled: true,
      fillColor: Colors.white,
      border: border,
      enabledBorder: border,
      focusedBorder: border.copyWith(
        borderSide: const BorderSide(color: AppColors.navy, width: 2),
      ),
    ),
    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: AppColors.goldSoft,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.navy,
      foregroundColor: Colors.white,
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
  );
}

/// Small sentence-case heading used above each list section.
class SectionTitle extends StatelessWidget {
  final String text;
  final Widget? trailing;
  const SectionTitle(this.text, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

class EmptyNote extends StatelessWidget {
  final String text;
  const EmptyNote(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Text(text, style: const TextStyle(color: AppColors.muted)),
    );
  }
}
