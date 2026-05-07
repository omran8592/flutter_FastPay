import '../models/payment_result.dart';
import '../models/payment_details.dart';
import '../models/payment_method.dart';
import '../models/payment_session.dart';

/// Internal checkout stages used by the SDK UI.
enum FastPayFlowStage {
  initial,
  creatingSession,
  ready,
  processing,
  success,
  failure,
  pending,
}

/// Immutable state snapshot for the payment flow controller.
class FastPayFlowState {
  /// Creates a [FastPayFlowState].
  const FastPayFlowState({
    required this.stage,
    this.session,
    this.payment,
    this.result,
    this.errorMessage,
    this.paymentMethods,
  });

  /// Initial empty flow state.
  const FastPayFlowState.initial()
    : stage = FastPayFlowStage.initial,
      session = null,
      payment = null,
      result = null,
      errorMessage = null,
      paymentMethods = null;

  /// Current stage.
  final FastPayFlowStage stage;

  /// Current payment session.
  final PaymentSession? session;

  /// Latest payment snapshot.
  final PaymentDetails? payment;

  /// Final or latest payment result.
  final PaymentResult? result;

  /// Latest error message.
  final String? errorMessage;

  /// Available payment methods fetched from the backend.
  final List<PaymentMethod>? paymentMethods;

  /// Whether the flow is busy with a network-bound task.
  bool get isBusy =>
      stage == FastPayFlowStage.creatingSession ||
      stage == FastPayFlowStage.processing;

  /// Whether the hosted-checkout state is ready for user interaction.
  bool get canSubmitCard => stage == FastPayFlowStage.ready;

  /// Returns a copy with the provided overrides.
  FastPayFlowState copyWith({
    FastPayFlowStage? stage,
    Object? session = _sentinel,
    Object? payment = _sentinel,
    Object? result = _sentinel,
    Object? errorMessage = _sentinel,
    Object? paymentMethods = _sentinel,
    bool clearErrorMessage = false,
    bool clearResult = false,
  }) {
    return FastPayFlowState(
      stage: stage ?? this.stage,
      session: identical(session, _sentinel)
          ? this.session
          : session as PaymentSession?,
      payment: identical(payment, _sentinel)
          ? this.payment
          : payment as PaymentDetails?,
      result: clearResult
          ? null
          : identical(result, _sentinel)
          ? this.result
          : result as PaymentResult?,
      errorMessage: clearErrorMessage
          ? null
          : identical(errorMessage, _sentinel)
          ? this.errorMessage
          : errorMessage as String?,
      paymentMethods: identical(paymentMethods, _sentinel)
          ? this.paymentMethods
          : paymentMethods as List<PaymentMethod>?,
    );
  }
}

const Object _sentinel = Object();
