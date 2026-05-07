import 'package:flutter/material.dart';

/// Supported card network types.
enum CardType { visa, mastercard, amex, discover, maestro, unknown }

/// Detects the card network from the leading digits.
CardType detectCardType(String digits) {
  if (digits.isEmpty) return CardType.unknown;

  if (digits.startsWith('4')) return CardType.visa;

  if (digits.length >= 2) {
    final int prefix2 = int.tryParse(digits.substring(0, 2)) ?? 0;
    if (prefix2 >= 51 && prefix2 <= 55) return CardType.mastercard;
  }
  if (digits.length >= 4) {
    final int prefix4 = int.tryParse(digits.substring(0, 4)) ?? 0;
    if (prefix4 >= 2221 && prefix4 <= 2720) return CardType.mastercard;
  }

  if (digits.startsWith('34') || digits.startsWith('37')) return CardType.amex;

  if (digits.startsWith('6011') || digits.startsWith('65')) {
    return CardType.discover;
  }
  if (digits.length >= 3) {
    final int prefix3 = int.tryParse(digits.substring(0, 3)) ?? 0;
    if (prefix3 >= 644 && prefix3 <= 649) return CardType.discover;
  }

  const List<String> maestroPrefixes = [
    '5018', '5020', '5038', '6304', '6759', '6761', '6763',
  ];
  for (final String prefix in maestroPrefixes) {
    if (digits.startsWith(prefix)) return CardType.maestro;
  }

  return CardType.unknown;
}

/// Returns a display name for the card type.
String cardTypeName(CardType type) {
  switch (type) {
    case CardType.visa:
      return 'Visa';
    case CardType.mastercard:
      return 'Mastercard';
    case CardType.amex:
      return 'Amex';
    case CardType.discover:
      return 'Discover';
    case CardType.maestro:
      return 'Maestro';
    case CardType.unknown:
      return '';
  }
}

/// Returns a representative icon for the card type.
Widget cardTypeIcon(CardType type, {double size = 28}) {
  switch (type) {
    case CardType.visa:
      return _CardBrandChip(label: 'VISA', color: const Color(0xFF1A1F71), size: size);
    case CardType.mastercard:
      return _CardBrandChip(label: 'MC', color: const Color(0xFFEB001B), size: size);
    case CardType.amex:
      return _CardBrandChip(label: 'AMEX', color: const Color(0xFF2E77BC), size: size);
    case CardType.discover:
      return _CardBrandChip(label: 'DISC', color: const Color(0xFFFF6000), size: size);
    case CardType.maestro:
      return _CardBrandChip(label: 'MST', color: const Color(0xFF0099DF), size: size);
    case CardType.unknown:
      return SizedBox(width: size, height: size);
  }
}

/// Validates a card number using the Luhn algorithm.
bool isValidLuhn(String digits) {
  if (digits.isEmpty) return false;

  int sum = 0;
  bool alternate = false;

  for (int i = digits.length - 1; i >= 0; i--) {
    int digit = int.parse(digits[i]);

    if (alternate) {
      digit *= 2;
      if (digit > 9) digit -= 9;
    }

    sum += digit;
    alternate = !alternate;
  }

  return sum % 10 == 0;
}

/// Small branded chip shown as a suffix in the card number field.
class _CardBrandChip extends StatelessWidget {
  const _CardBrandChip({
    required this.label,
    required this.color,
    required this.size,
  });

  final String label;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          height: size,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: size * 0.38,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }
}
