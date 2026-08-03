import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Airy light-blue palette shared with the customer application.
class AppColors {
  static const brandDark = Color(0xFF17212B);
  static const ink = Color(0xFF17212B);
  static const slate = Color(0xFF687783);
  static const primary = Color(0xFF4C9ED6);
  static const primaryDark = Color(0xFF327FB5);
  static const secondary = Color(0xFF75B9A9);
  static const background = Color(0xFFF7FBFE);
  static const card = Color(0xFFFFFFFF);
  static const border = Color(0xFFD6E8F3);
  static const muted = slate;
  static const accent = Color(0xFFE9F5FD);
  static const warning = Color(0xFF7A91A3);
  static const success = Color(0xFF35A28D);
  static const info = Color(0xFF69B6E5);
  static const danger = Color(0xFFB85C68);
  static const coral = Color(0xFFEE6F65);
  static const amber = Color(0xFFF2A93B);
  static const mint = Color(0xFF32A98F);
  static const violet = Color(0xFF8267D8);
  static const coralSoft = Color(0xFFFFEFED);
  static const amberSoft = Color(0xFFFFF5E2);
  static const mintSoft = Color(0xFFE8F8F3);
  static const violetSoft = Color(0xFFF1EDFF);
  static const headerSurface = Color(0xFFFFFFFF);
  static const softGreen = Color(0xFFEAF8F4);
  static const productSurface = Color(0xFFF7FBFE);
  static const navySoft = Color(0xFFE9F5FD);
  static const shadow = Color(0x174C7894);

  static const brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFBCE5FA), Color(0xFF82CAF2)],
  );

  static const pageGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFF9FCFE), Color(0xFFEFF8FD)],
  );
}

class AppTheme {
  static const fontFamily = 'P4URoboto';

  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: fontFamily,
    );
    final textTheme = base.textTheme
        .copyWith(
          displayLarge: const TextStyle(
              fontSize: 36, height: 1.15, fontWeight: FontWeight.w600),
          displayMedium: const TextStyle(
              fontSize: 32, height: 1.18, fontWeight: FontWeight.w600),
          displaySmall: const TextStyle(
              fontSize: 28, height: 1.2, fontWeight: FontWeight.w600),
          headlineLarge: const TextStyle(
              fontSize: 26, height: 1.2, fontWeight: FontWeight.w600),
          headlineMedium: const TextStyle(
              fontSize: 24, height: 1.22, fontWeight: FontWeight.w600),
          headlineSmall: const TextStyle(
              fontSize: 22, height: 1.25, fontWeight: FontWeight.w600),
          titleLarge: const TextStyle(
              fontSize: 20, height: 1.3, fontWeight: FontWeight.w600),
          titleMedium: const TextStyle(
              fontSize: 18, height: 1.32, fontWeight: FontWeight.w600),
          titleSmall: const TextStyle(
              fontSize: 16, height: 1.35, fontWeight: FontWeight.w600),
          bodyLarge: const TextStyle(
              fontSize: 16, height: 1.5, fontWeight: FontWeight.w400),
          bodyMedium: const TextStyle(
              fontSize: 14, height: 1.5, fontWeight: FontWeight.w400),
          bodySmall: const TextStyle(
              fontSize: 12, height: 1.45, fontWeight: FontWeight.w400),
          labelLarge: const TextStyle(
              fontSize: 14, height: 1.3, fontWeight: FontWeight.w600),
          labelMedium: const TextStyle(
              fontSize: 12, height: 1.3, fontWeight: FontWeight.w600),
          labelSmall: const TextStyle(
              fontSize: 10, height: 1.3, fontWeight: FontWeight.w600),
        )
        .apply(
          fontFamily: fontFamily,
          bodyColor: AppColors.ink,
          displayColor: AppColors.brandDark,
        );
    const inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(15)),
      borderSide: BorderSide(color: AppColors.border),
    );
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
        },
      ),
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.card,
        error: AppColors.danger,
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.brandDark,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle.dark.copyWith(
          statusBarColor: AppColors.background,
          systemNavigationBarColor: Colors.white,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: const TextStyle(
          fontFamily: fontFamily,
          color: AppColors.brandDark,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: -.2,
        ),
      ),
      iconTheme: const IconThemeData(color: AppColors.slate, size: 22),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: AppColors.slate,
          minimumSize: const Size(40, 40),
          maximumSize: const Size(44, 44),
          padding: const EdgeInsets.all(8),
          visualDensity: VisualDensity.compact,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(Radius.circular(20)),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        border: inputBorder,
        enabledBorder: inputBorder,
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(15)),
          borderSide: BorderSide(color: AppColors.primary, width: 1.7),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(15)),
          borderSide: BorderSide(color: AppColors.danger),
        ),
        hintStyle: const TextStyle(color: AppColors.muted),
        labelStyle: const TextStyle(color: AppColors.muted),
        prefixIconColor: AppColors.slate,
        suffixIconColor: AppColors.slate,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.border,
          disabledForegroundColor: AppColors.muted,
          minimumSize: const Size(40, 44),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          textStyle: const TextStyle(
              fontWeight: FontWeight.w600, fontSize: 13, height: 1.15),
          elevation: 0,
          visualDensity: VisualDensity.compact,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.brandDark,
          side: const BorderSide(color: AppColors.primary, width: 1.1),
          backgroundColor: Colors.white,
          minimumSize: const Size(40, 42),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          textStyle: const TextStyle(
              fontWeight: FontWeight.w600, fontSize: 13, height: 1.15),
          visualDensity: VisualDensity.compact,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.brandDark,
          minimumSize: const Size(32, 36),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          visualDensity: VisualDensity.compact,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: Colors.white,
        selectedColor: AppColors.accent,
        side: const BorderSide(color: AppColors.border),
        labelStyle:
            const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
      ),
      tabBarTheme: const TabBarThemeData(
        indicatorColor: AppColors.primary,
        indicatorSize: TabBarIndicatorSize.label,
        labelColor: AppColors.brandDark,
        unselectedLabelColor: AppColors.muted,
        labelStyle: TextStyle(fontWeight: FontWeight.w600),
        dividerColor: AppColors.border,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: AppColors.accent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
              color: states.contains(WidgetState.selected)
                  ? AppColors.brandDark
                  : AppColors.muted,
              fontSize: 11,
              fontWeight: states.contains(WidgetState.selected)
                  ? FontWeight.w600
                  : FontWeight.w600,
            )),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.slate,
        unselectedItemColor: AppColors.muted,
        selectedIconTheme: IconThemeData(color: AppColors.slate),
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: AppColors.muted,
        textColor: AppColors.ink,
        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.border),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.brandDark,
        contentTextStyle:
            const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        behavior: SnackBarBehavior.floating,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      progressIndicatorTheme:
          const ProgressIndicatorThemeData(color: AppColors.primary),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }
}
