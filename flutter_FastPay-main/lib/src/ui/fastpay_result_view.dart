import 'package:flutter/material.dart';

import '../models/payment_result.dart';
import 'fastpay_checkout_theme.dart';

/// Result UI rendered after processing a payment attempt.
class FastPayResultView extends StatelessWidget {
  /// Creates a [FastPayResultView].
  const FastPayResultView({
    super.key,
    required this.result,
    required this.onDone,
    this.onRetry,
    this.onRefreshStatus,
  });

  /// Payment result to display.
  final PaymentResult result;

  /// Called when the merchant closes the checkout.
  final VoidCallback onDone;

  /// Called when the user wants to retry the payment.
  final VoidCallback? onRetry;

  /// Called when the user wants to refresh a pending payment.
  final VoidCallback? onRefreshStatus;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final _ResultTone tone = _toneForResult(result);
    final String? amount = result.payment?.amount;
    final String? currency = result.payment?.currency;
    final String paymentId =
        result.payment?.paymentId ?? result.session?.paymentId ?? 'Unknown';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(width: 134, height: 3, color: Colors.black),
          const SizedBox(height: 24),
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: tone.iconBackground,
              shape: BoxShape.circle,
            ),
            child: Icon(tone.icon, size: 40, color: tone.iconColor),
          ),
          const SizedBox(height: 16),
          Text(
            tone.title,
            style: theme.textTheme.titleLarge?.copyWith(
              color: tone.iconColor == FastPayCheckoutPalette.success
                  ? FastPayCheckoutPalette.textPrimary
                  : FastPayCheckoutPalette.danger,
              fontWeight: FontWeight.w800,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            result.errorMessage ?? _defaultMessage(result),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: FastPayCheckoutPalette.textSecondary,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          if (result.isSuccess && amount != null && currency != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: FastPayCheckoutPalette.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    '$amount $currency',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Payment completed successfully',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: FastPayCheckoutPalette.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _ResultDetailRow(label: 'Transaction ID', value: paymentId),
                if (result.isSuccess) ...[
                  const SizedBox(height: 10),
                  _ResultDetailRow(
                    label: 'Method',
                    value: result.payment?.paymentMethod ?? 'Card',
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (result.isFailure && onRetry != null) ...<Widget>[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onRetry,
                style: _elevatedButtonStyle(),
                child: const Text(
                  'Try Again',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ] else ...<Widget>[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onDone,
                style: _elevatedButtonStyle(),
                child: const Text(
                  'Done',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  ButtonStyle _elevatedButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: FastPayCheckoutPalette.primary,
      padding: const EdgeInsets.symmetric(vertical: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }

  String _defaultMessage(PaymentResult result) {
    if (result.isSuccess) {
      return 'Your transaction has been confirmed.';
    }

    if (result.isPending) {
      return 'We are waiting for the final payment confirmation from the gateway.';
    }

    return 'We couldn\'t complete payment. No charges were made.';
  }

  _ResultTone _toneForResult(PaymentResult result) {
    if (result.isSuccess) {
      return const _ResultTone(
        title: 'Payment Successful',
        icon: Icons.check_circle_outline_rounded,
        iconBackground: FastPayCheckoutPalette.successSoft,
        iconColor: FastPayCheckoutPalette.success,
        amountBackground: FastPayCheckoutPalette.primary,
        amountForeground: Colors.white,
      );
    }

    if (result.isPending) {
      return const _ResultTone(
        title: 'Payment Pending',
        icon: Icons.schedule_rounded,
        iconBackground: FastPayCheckoutPalette.warningSoft,
        iconColor: FastPayCheckoutPalette.warning,
        amountBackground: FastPayCheckoutPalette.warningSoft,
        amountForeground: FastPayCheckoutPalette.textPrimary,
      );
    }

    return const _ResultTone(
      title: 'Payment Failed',
      icon: Icons.close_rounded,
      iconBackground: FastPayCheckoutPalette.dangerSoft,
      iconColor: FastPayCheckoutPalette.danger,
      amountBackground: FastPayCheckoutPalette.dangerSoft,
      amountForeground: FastPayCheckoutPalette.textPrimary,
    );
  }
}

class _ResultDetailRow extends StatelessWidget {
  const _ResultDetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: FastPayCheckoutPalette.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: FastPayCheckoutPalette.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _ResultTone {
  const _ResultTone({
    required this.title,
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
    required this.amountBackground,
    required this.amountForeground,
  });

  final String title;
  final IconData icon;
  final Color iconBackground;
  final Color iconColor;
  final Color amountBackground;
  final Color amountForeground;
}
