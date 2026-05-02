import 'dart:math';

import 'package:fastpay_sdk/fastpay_sdk.dart';
import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Mock PaymentService — simulates the FastPay backend locally.
// No network calls, no real credentials needed.
// ---------------------------------------------------------------------------

class MockPaymentService implements PaymentService {
  MockPaymentService();

  int _nextId = 1000;
  final Map<String, PaymentDetails> _payments = <String, PaymentDetails>{};

  @override
  Future<List<PaymentMethod>> listMethods() async {
    await _simulateLatency();
    return <PaymentMethod>[
      PaymentMethod.fromJson(const <String, dynamic>{
        'id': 'card',
        'name': 'Credit / Debit Card',
      }),
      PaymentMethod.fromJson(const <String, dynamic>{
        'id': 'fawry',
        'name': 'Fawry',
      }),
      PaymentMethod.fromJson(const <String, dynamic>{
        'id': 'wallet',
        'name': 'Mobile Wallet',
      }),
    ];
  }

  @override
  Future<PaymentSession> createSession({
    required double amount,
    required String currency,
    required Customer customer,
    required String merchantOrderId,
    required String callbackUrl,
    Map<String, dynamic>? metadata,
    String? redirectUrl,
  }) async {
    await _simulateLatency(millis: 1200);

    final String paymentId = 'fp_pay_${_nextId++}';
    final String reference = 'REF-${Random().nextInt(99999).toString().padLeft(5, '0')}';
    const String checkoutUrl = 'https://checkout.fastpay.example/demo-session';

    // Store a mock payment record so getPayment can resolve it.
    _payments[paymentId] = PaymentDetails(
      paymentId: paymentId,
      amount: amount.toStringAsFixed(2),
      currency: currency.toUpperCase(),
      status: 'initiated',
      paymentMethod: 'card',
      customer: customer,
    );

    return PaymentSession(
      paymentId: paymentId,
      reference: reference,
      status: 'initiated',
      checkoutUrl: checkoutUrl,
    );
  }

  @override
  Future<PaymentDetails> getPayment({required String paymentId}) async {
    await _simulateLatency();

    final PaymentDetails? existing = _payments[paymentId];
    if (existing == null) {
      throw NotFoundApiException(message: 'Payment $paymentId not found.');
    }

    // Simulate status progression: initiated → pending → success
    final String currentStatus = (existing.status ?? 'initiated').toLowerCase();
    final String nextStatus;
    if (currentStatus == 'initiated') {
      nextStatus = 'pending';
    } else if (currentStatus == 'pending') {
      nextStatus = 'success';
    } else {
      nextStatus = currentStatus;
    }

    final PaymentDetails updated = PaymentDetails(
      paymentId: existing.paymentId,
      id: existing.id,
      amount: existing.amount,
      currency: existing.currency,
      status: nextStatus,
      paymentMethod: existing.paymentMethod,
      customer: existing.customer,
      metadata: existing.metadata,
    );

    _payments[paymentId] = updated;
    return updated;
  }

  @override
  Future<RetryPaymentResult> retryPayment({
    required String paymentId,
    String? paymentMethod,
    String? redirectUrl,
    String? callbackUrl,
  }) async {
    await _simulateLatency();

    // Reset the payment to initiated so the flow can be retried.
    final PaymentDetails? existing = _payments[paymentId];
    if (existing != null) {
      _payments[paymentId] = PaymentDetails(
        paymentId: existing.paymentId,
        amount: existing.amount,
        currency: existing.currency,
        status: 'initiated',
        paymentMethod: paymentMethod ?? existing.paymentMethod,
        customer: existing.customer,
      );
    }

    return RetryPaymentResult.fromJson(<String, dynamic>{
      'payment_id': paymentId,
      'status': 'initiated',
      'checkout_url': 'https://checkout.fastpay.example/retry-session',
    });
  }

  @override
  Future<CancelPaymentResult> cancelPayment({
    required String paymentId,
  }) async {
    await _simulateLatency();

    _payments[paymentId] = PaymentDetails(
      paymentId: paymentId,
      status: 'cancelled',
    );

    return CancelPaymentResult.fromJson(<String, dynamic>{
      'payment_id': paymentId,
      'status': 'cancelled',
    });
  }

  Future<void> _simulateLatency({int millis = 800}) =>
      Future<void>.delayed(Duration(milliseconds: millis));
}

// ---------------------------------------------------------------------------
// Example App
// ---------------------------------------------------------------------------

final MockPaymentService _mockService = MockPaymentService();

void main() {
  FastPay.initialize(
    const FastPayConfig(
      baseUrl: 'https://api.fastpay.dpdns.org',
      apiKey: 'pk_test_demo',
      accessToken: 'mock_access_token',
      merchantId: 'merchant_demo',
    ),
    paymentService: _mockService,
  );

  runApp(const ExampleApp());
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FastPay SDK Example',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: FastPayCheckoutPalette.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: FastPayCheckoutPalette.primary,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const ExampleHomePage(),
    );
  }
}

class ExampleHomePage extends StatefulWidget {
  const ExampleHomePage({super.key});

  @override
  State<ExampleHomePage> createState() => _ExampleHomePageState();
}

class _ExampleHomePageState extends State<ExampleHomePage> {
  PaymentResult? _lastResult;
  bool _busy = false;
  List<PaymentMethod>? _methods;

  @override
  void initState() {
    super.initState();
    _loadMethods();
  }

  Future<void> _loadMethods() async {
    try {
      final List<PaymentMethod> methods =
          await FastPay.payments.listMethods();
      if (mounted) {
        setState(() {
          _methods = methods;
        });
      }
    } catch (_) {
      // ignore for demo
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String paymentId =
        _lastResult?.payment?.paymentId ??
        _lastResult?.session?.paymentId ??
        'n/a';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('FastPay SDK Example'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: <Widget>[
          // --- Demo Payment Card ---
          Container(
            padding: const EdgeInsets.all(24),
            decoration: fastPaySurfaceDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: FastPayCheckoutPalette.primarySoft,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.payments_outlined,
                        color: FastPayCheckoutPalette.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Demo Payment',
                        style: TextStyle(
                          color: FastPayCheckoutPalette.textPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  '150.00 EGP',
                  style: TextStyle(
                    color: FastPayCheckoutPalette.textPrimary,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'This example uses a mock PaymentService — no real backend needed. '
                  'Tap "Check payment status" twice in the checkout to simulate: '
                  'initiated → pending → success.',
                  style: TextStyle(
                    color: FastPayCheckoutPalette.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),

          // --- Payment Methods ---
          if (_methods != null && _methods!.isNotEmpty) ...<Widget>[
            const SizedBox(height: 20),
            Text(
              'Available Payment Methods',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            ..._methods!.map(
              (PaymentMethod method) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: FastPayCheckoutPalette.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: FastPayCheckoutPalette.border,
                  ),
                ),
                child: Row(
                  children: <Widget>[
                    Icon(
                      _iconForMethod(method.id),
                      color: FastPayCheckoutPalette.primary,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      method.name ?? method.id ?? 'Unknown',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: FastPayCheckoutPalette.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 24),

          // --- Checkout Button ---
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: FastPayCheckoutPalette.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            onPressed: _busy ? null : _openCheckout,
            child: Text(_busy ? 'Opening...' : 'Open FastPay Checkout'),
          ),

          // --- Last Result ---
          if (_lastResult != null) ...<Widget>[
            const SizedBox(height: 24),
            Text(
              'Last Result',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: fastPaySurfaceDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _ResultRow(
                    label: 'Outcome',
                    value: _lastResult!.outcome.name.toUpperCase(),
                    color: _colorForOutcome(_lastResult!.outcome),
                  ),
                  const SizedBox(height: 8),
                  _ResultRow(
                    label: 'Status',
                    value: _lastResult!.status ?? 'unknown',
                  ),
                  const SizedBox(height: 8),
                  _ResultRow(
                    label: 'Message',
                    value: _lastResult!.errorMessage ?? 'n/a',
                  ),
                  const SizedBox(height: 8),
                  _ResultRow(
                    label: 'Payment ID',
                    value: paymentId,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _openCheckout() async {
    setState(() {
      _busy = true;
    });

    final PaymentResult result = await FastPayCheckout.show(
      context,
      amount: 150.0,
      currency: 'EGP',
      customer: const Customer(
        name: 'Elmira Stokes',
        email: 'elmira@example.com',
        phone: '+201000000000',
      ),
      merchantOrderId: 'ORD-10001',
      callbackUrl: 'https://merchant.example.com/api/fastpay/callback',
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _busy = false;
      _lastResult = result;
    });
  }

  IconData _iconForMethod(String? id) {
    switch (id) {
      case 'card':
        return Icons.credit_card;
      case 'fawry':
        return Icons.storefront;
      case 'wallet':
        return Icons.account_balance_wallet;
      default:
        return Icons.payment;
    }
  }

  Color _colorForOutcome(PaymentOutcome outcome) {
    switch (outcome) {
      case PaymentOutcome.success:
        return FastPayCheckoutPalette.success;
      case PaymentOutcome.pending:
        return FastPayCheckoutPalette.warning;
      case PaymentOutcome.failure:
        return FastPayCheckoutPalette.danger;
    }
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({
    required this.label,
    required this.value,
    this.color,
  });

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(
              color: FastPayCheckoutPalette.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: color ?? FastPayCheckoutPalette.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
