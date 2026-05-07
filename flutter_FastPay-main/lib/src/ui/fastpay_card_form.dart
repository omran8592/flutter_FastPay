import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../utils/card_input_formatters.dart';
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
  late final TextEditingController _cardholderController;

  @override
  void initState() {
    super.initState();
    _cardNumberController = TextEditingController();
    _expiryController = TextEditingController();
    _cvvController = TextEditingController();
    _cardholderController = TextEditingController();
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _cardholderController.dispose();
    super.dispose();
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
            'Card information',
            style: theme.textTheme.titleLarge?.copyWith(
              color: FastPayCheckoutPalette.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Enter the details exactly as they appear on your card.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: FastPayCheckoutPalette.textSecondary,
              height: 1.45,
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE0E0E0)),
            ),
            child: Column(
              children: [
                TextFormField(
                  controller: _cardholderController,
                  enabled: widget.enabled,
                  textCapitalization: TextCapitalization.words,
                  decoration: fastpayInputDecorationUnified(
                    hint: 'Cardholder name',
                    prefixIcon: const Icon(Icons.person_outline_rounded),
                  ),
                  validator: (String? value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter the cardholder name.';
                    }
                    return null;
                  },
                ),
                const Divider(height: 1, color: Color(0xFFE0E0E0)),
                TextFormField(
                  controller: _cardNumberController,
                  enabled: widget.enabled,
                  obscureText: true,
                  obscuringCharacter: '*',
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  decoration: fastpayInputDecorationUnified(
                    hint: 'Card number',
                    prefixIcon: const Icon(Icons.credit_card_rounded),
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
                            hint: 'Expiry...',
                            prefixIcon: const Icon(Icons.calendar_today_outlined),
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
                            hint: 'Security...',
                            prefixIcon: const Icon(Icons.lock_outline_rounded),
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
              minimumSize: const Size.fromHeight(56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              textStyle: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            onPressed: widget.enabled ? _submit : null,
            child: Text(
              'Pay ${formatFastPayAmount(widget.amount, widget.currency)}',
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
        cardholderName: _cardholderController.text.trim(),
        last4: number.length >= 4 ? number.substring(number.length - 4) : null,
      ),
    );
  }
}
