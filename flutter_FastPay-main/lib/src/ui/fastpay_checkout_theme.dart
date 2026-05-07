import 'package:flutter/material.dart';

class FastPayCheckoutPalette {
  const FastPayCheckoutPalette._();

  static const Color background = Color(0xFFF3F5FB);
  static const Color surface = Colors.white;
  static const Color surfaceMuted = Color(0xFFF7F8FC);
  static const Color border = Color(0xFFE3E7F2);
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF667085);
  static const Color primary = Color(0xFF2957F6);
  static const Color primaryDark = Color(0xFF1638B8);
  static const Color primarySoft = Color(0xFFE9EEFF);
  static const Color success = Color(0xFF18A957);
  static const Color successSoft = Color(0xFFEAF8F0);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningSoft = Color(0xFFFFF4DB);
  static const Color danger = Color(0xFFEB5757);
  static const Color dangerSoft = Color(0xFFFFEAEA);
  static const Color shadow = Color(0x14243B53);
  static const Color inputFill = Color(0xFFF9F9F9);
}

BoxDecoration fastPaySurfaceDecoration({
  Color color = FastPayCheckoutPalette.surface,
  Color borderColor = FastPayCheckoutPalette.border,
}) {
  return BoxDecoration(
    color: color,
    borderRadius: BorderRadius.circular(25),
    border: Border.all(color: borderColor),
    boxShadow: const <BoxShadow>[
      BoxShadow(
        color: FastPayCheckoutPalette.shadow,
        blurRadius: 32,
        offset: Offset(0, 16),
      ),
    ],
  );
}

InputDecoration fastPayInputDecoration({
  String? label,
  required String hint,
  Widget? prefixIcon,
}) {
  final OutlineInputBorder border = OutlineInputBorder(
    borderRadius: const BorderRadius.all(Radius.circular(10)),
    borderSide: BorderSide.none,
  );

  return InputDecoration(
    labelText: label,
    hintText: hint,
    filled: true,
    fillColor: FastPayCheckoutPalette.inputFill,
    prefixIcon: prefixIcon,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    labelStyle: const TextStyle(color: FastPayCheckoutPalette.textSecondary),
    hintStyle: const TextStyle(color: Color(0xFFC4C4C4)), // AppColors.hintColor
    border: border,
    enabledBorder: border,
    focusedBorder: border.copyWith(
      borderSide: const BorderSide(
        color: FastPayCheckoutPalette.primary,
        width: 1.4,
      ),
    ),
    errorBorder: border.copyWith(
      borderSide: const BorderSide(
        color: FastPayCheckoutPalette.danger,
        width: 1.2,
      ),
    ),
    focusedErrorBorder: border.copyWith(
      borderSide: const BorderSide(
        color: FastPayCheckoutPalette.danger,
        width: 1.4,
      ),
    ),
  );
}

InputDecoration fastpayInputDecorationUnified({
  String? label,
  required String hint,
  Widget? prefixIcon,
}) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    filled: true,
    fillColor: Colors.transparent, // Transparent for unified container
    prefixIcon: prefixIcon,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    labelStyle: const TextStyle(color: FastPayCheckoutPalette.textSecondary),
    hintStyle: const TextStyle(color: Color(0xFFC4C4C4)),
    border: InputBorder.none,
    enabledBorder: InputBorder.none,
    focusedBorder: InputBorder.none,
    errorBorder: InputBorder.none,
    focusedErrorBorder: InputBorder.none,
  );
}

String formatFastPayAmount(num amount, String currency) {
  return '${amount.toStringAsFixed(2)} $currency';
}

String formatFastPayId(String value) {
  if (value.length <= 10) {
    return value;
  }

  return '${value.substring(0, 4)}...${value.substring(value.length - 4)}';
}
