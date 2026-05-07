import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../utils/card_input_formatters.dart';
import '../utils/card_validator.dart';
import '../models/card_details.dart';
import 'fastpay_checkout_theme.dart';

/// Card entry form embedded in the FastPay checkout page.
class FastPayCardForm extends StatefulWidget {
  /// Creates a [FastPayCardForm].
  const FastPayCardForm({
    super.key,
    required this.amount,
    required this.currency,
    required this.enabled,
    required this.onSubmit,
  });

  /// Display amount used in the CTA.
  final double amount;

  /// Display currency used in the CTA.
  final String currency;

  /// Whether inputs should be interactive.
  final bool enabled;

  /// Callback triggered after successful validation.
  final ValueChanged<CardDetails> onSubmit;

  @override
  State<FastPayCardForm> createState() => _FastPayCardFormState();
}

class _FastPayCardFormState extends State<FastPayCardForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _cardNumberController;
  late final TextEditingController _expiryController;
  late final TextEditingController _cvvController;

  CardType _detectedCardType = CardType.unknown;
  bool _isFormValid = false;

  @override
  void initState() {
    super.initState();
    _cardNumberController = TextEditingController();
    _expiryController = TextEditingController();
    _cvvController = TextEditingController();

    _cardNumberController.addListener(_onCardNumberChanged);
    _cardNumberController.addListener(_validateForm);
    _expiryController.addListener(_validateForm);
    _cvvController.addListener(_validateForm);
  }

  @override
  void dispose() {
    _cardNumberController.removeListener(_onCardNumberChanged);
    _cardNumberController.removeListener(_validateForm);
    _expiryController.removeListener(_validateForm);
    _cvvController.removeListener(_validateForm);
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  void _onCardNumberChanged() {
    final String digits = _cardNumberController.text.replaceAll(RegExp(r'\D'), '');
    final CardType type = detectCardType(digits);
    if (type != _detectedCardType) {
      setState(() {
        _detectedCardType = type;
      });
    }
  }

  void _validateForm() {
    bool isValid = true;

    final String cardDigits = _cardNumberController.text.replaceAll(RegExp(r'\D'), '');
    if (cardDigits.length != 16) {
      isValid = false;
    }

    final List<String> expiryParts = _expiryController.text.split('/');
    if (expiryParts.length != 2) {
      isValid = false;
    } else {
      final int? month = int.tryParse(expiryParts[0]);
      final int? year = int.tryParse(expiryParts[1]);
      if (month == null || year == null || month < 1 || month > 12) {
        isValid = false;
      }
    }

    final String cvvDigits = _cvvController.text.replaceAll(RegExp(r'\D'), '');
    if (cvvDigits.length != 3) {
      isValid = false;
    }

    if (isValid != _isFormValid) {
      setState(() {
        _isFormValid = isValid;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            'Card Information',
            style: theme.textTheme.titleMedium?.copyWith(
              color: const Color(0xFF0F365A),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE0E0E0)),
            ),
            child: Column(
              children: [
                TextFormField(
                  controller: _cardNumberController,
                  enabled: widget.enabled,
                  obscureText: true,
                  obscuringCharacter: '•',
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  decoration: fastpayInputDecorationUnified(
                    hint: '•••• •••• •••• 1234',
                    suffixIcon: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: _detectedCardType != CardType.unknown
                          ? Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: cardTypeIcon(_detectedCardType),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ),
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.digitsOnly,
                    CardNumberInputFormatter(),
                  ],
                  validator: (String? value) {
                    final String digits = value?.replaceAll(RegExp(r'\D'), '') ?? '';
                    if (digits.length != 16) {
                      return 'Enter a valid 16-digit card number.';
                    }
                    return null;
                  },
                ),
                const Divider(height: 1, color: Color(0xFFE0E0E0)),
                IntrinsicHeight(
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: TextFormField(
                          controller: _expiryController,
                          enabled: widget.enabled,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.next,
                          decoration: fastpayInputDecorationUnified(
                            hint: 'MM / YY',
                          ),
                          inputFormatters: <TextInputFormatter>[
                            FilteringTextInputFormatter.digitsOnly,
                            ExpiryDateInputFormatter(),
                          ],
                          validator: (String? value) {
                            final List<String> parts = (value ?? '').split('/');
                            if (parts.length != 2) {
                              return 'Use MM/YY.';
                            }

                            final int? month = int.tryParse(parts[0]);
                            final int? year = int.tryParse(parts[1]);
                            if (month == null || year == null || month < 1 || month > 12) {
                              return 'Invalid expiry date.';
                            }

                            return null;
                          },
                        ),
                      ),
                      const VerticalDivider(width: 1, color: Color(0xFFE0E0E0)),
                      Expanded(
                        child: TextFormField(
                          controller: _cvvController,
                          enabled: widget.enabled,
                          keyboardType: TextInputType.number,
                          decoration: fastpayInputDecorationUnified(
                            hint: 'CVC',
                          ),
                          inputFormatters: <TextInputFormatter>[
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(3),
                          ],
                          validator: (String? value) {
                            final String digits = value?.replaceAll(RegExp(r'\D'), '') ?? '';
                            if (digits.length != 3) {
                              return 'Invalid CVV.';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: FastPayCheckoutPalette.primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xFFE0E0E0),
              disabledForegroundColor: const Color(0xFFA0A0A0),
              minimumSize: const Size.fromHeight(56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              textStyle: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            onPressed: (widget.enabled && _isFormValid) ? _submit : null,
            child: Text(
              'Pay ${formatFastPayAmount(widget.amount, widget.currency)} Now',
            ),
          ),
        ],
      ),
    );
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) {
      return;
    }

    final List<String> parts = _expiryController.text.split('/');
    final int month = int.parse(parts[0]);
    final int year = int.parse(parts[1]) + 2000;
    final String number = _cardNumberController.text.replaceAll(
      RegExp(r'\D'),
      '',
    );

    widget.onSubmit(
      CardDetails(
        number: number,
        expiryMonth: month,
        expiryYear: year,
        cvv: _cvvController.text,
        cardholderName: null,
        last4: number.length >= 4 ? number.substring(number.length - 4) : null,
      ),
    );
  }
}
