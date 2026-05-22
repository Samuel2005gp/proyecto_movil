import 'package:flutter/material.dart';

/// Utilidades para hacer la app responsive
class ResponsiveUtils {
  /// Breakpoints para diferentes tamaños de pantalla
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;

  /// Obtiene el ancho de la pantalla
  static double screenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  /// Obtiene el alto de la pantalla
  static double screenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  /// Verifica si es un dispositivo móvil pequeño
  static bool isSmallMobile(BuildContext context) {
    return screenWidth(context) < 360;
  }

  /// Verifica si es un dispositivo móvil
  static bool isMobile(BuildContext context) {
    return screenWidth(context) < mobileBreakpoint;
  }

  /// Verifica si es una tablet
  static bool isTablet(BuildContext context) {
    return screenWidth(context) >= mobileBreakpoint &&
        screenWidth(context) < tabletBreakpoint;
  }

  /// Verifica si es desktop
  static bool isDesktop(BuildContext context) {
    return screenWidth(context) >= tabletBreakpoint;
  }

  /// Obtiene padding horizontal responsive
  static double horizontalPadding(BuildContext context) {
    if (isSmallMobile(context)) return 12;
    if (isMobile(context)) return 16;
    if (isTablet(context)) return 24;
    return 32;
  }

  /// Obtiene padding vertical responsive
  static double verticalPadding(BuildContext context) {
    if (isSmallMobile(context)) return 12;
    if (isMobile(context)) return 16;
    if (isTablet(context)) return 20;
    return 24;
  }

  /// Obtiene el número de columnas para un grid
  static int gridColumns(BuildContext context,
      {int mobile = 2, int tablet = 3, int desktop = 4}) {
    if (isMobile(context)) return mobile;
    if (isTablet(context)) return tablet;
    return desktop;
  }

  /// Obtiene un valor escalado según el tamaño de pantalla
  static double scale(BuildContext context, double baseValue) {
    final width = screenWidth(context);
    if (width < 360) return baseValue * 0.85;
    if (width < mobileBreakpoint) return baseValue;
    if (width < tabletBreakpoint) return baseValue * 1.2;
    return baseValue * 1.4;
  }

  /// Obtiene tamaño de fuente responsive
  static double fontSize(BuildContext context, double baseSize) {
    if (isSmallMobile(context)) return baseSize * 0.9;
    if (isMobile(context)) return baseSize;
    if (isTablet(context)) return baseSize * 1.1;
    return baseSize * 1.2;
  }

  /// Obtiene tamaño de icono responsive
  static double iconSize(BuildContext context, double baseSize) {
    if (isSmallMobile(context)) return baseSize * 0.9;
    if (isMobile(context)) return baseSize;
    if (isTablet(context)) return baseSize * 1.15;
    return baseSize * 1.3;
  }

  /// Obtiene border radius responsive
  static double borderRadius(BuildContext context, double baseRadius) {
    if (isSmallMobile(context)) return baseRadius * 0.8;
    if (isMobile(context)) return baseRadius;
    if (isTablet(context)) return baseRadius * 1.2;
    return baseRadius * 1.4;
  }

  /// Obtiene spacing responsive
  static double spacing(BuildContext context, double baseSpacing) {
    if (isSmallMobile(context)) return baseSpacing * 0.8;
    if (isMobile(context)) return baseSpacing;
    if (isTablet(context)) return baseSpacing * 1.2;
    return baseSpacing * 1.4;
  }

  /// Widget responsive que cambia según el tamaño de pantalla
  static Widget responsive(
    BuildContext context, {
    required Widget mobile,
    Widget? tablet,
    Widget? desktop,
  }) {
    if (isDesktop(context) && desktop != null) return desktop;
    if (isTablet(context) && tablet != null) return tablet;
    return mobile;
  }

  /// Obtiene el aspect ratio para cards
  static double cardAspectRatio(BuildContext context) {
    if (isSmallMobile(context)) return 1.5;
    if (isMobile(context)) return 1.7;
    if (isTablet(context)) return 1.8;
    return 2.0;
  }

  /// Obtiene el máximo ancho para contenido centrado
  static double maxContentWidth(BuildContext context) {
    if (isMobile(context)) return double.infinity;
    if (isTablet(context)) return 800;
    return 1200;
  }

  /// Wrapper para contenido con ancho máximo centrado
  static Widget constrainedContent(BuildContext context, Widget child) {
    final maxWidth = maxContentWidth(context);
    if (maxWidth == double.infinity) return child;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

/// Extension para facilitar el uso de responsive utils
extension ResponsiveContext on BuildContext {
  bool get isSmallMobile => ResponsiveUtils.isSmallMobile(this);
  bool get isMobile => ResponsiveUtils.isMobile(this);
  bool get isTablet => ResponsiveUtils.isTablet(this);
  bool get isDesktop => ResponsiveUtils.isDesktop(this);

  double get screenWidth => ResponsiveUtils.screenWidth(this);
  double get screenHeight => ResponsiveUtils.screenHeight(this);

  double get horizontalPadding => ResponsiveUtils.horizontalPadding(this);
  double get verticalPadding => ResponsiveUtils.verticalPadding(this);

  double get cardAspectRatio => ResponsiveUtils.cardAspectRatio(this);

  double scale(double value) => ResponsiveUtils.scale(this, value);
  double fontSize(double size) => ResponsiveUtils.fontSize(this, size);
  double iconSize(double size) => ResponsiveUtils.iconSize(this, size);
  double borderRadius(double radius) =>
      ResponsiveUtils.borderRadius(this, radius);
  double spacing(double space) => ResponsiveUtils.spacing(this, space);
}
