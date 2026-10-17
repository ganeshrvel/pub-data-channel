import 'package:data_channel/src/main.dart';
import 'package:data_channel/src/option.dart';
import 'package:meta/meta.dart';

/// Data Channel Required - a result type for handling errors and data that
/// is always present on success.
///
/// Every DCRequired is either:
/// - DCRequiredError: contains an error
/// - DCRequiredData: contains a value that is never null
///
/// DCRequired is not a DC. Use [toDC] to hand it to code that expects a DC.
sealed class DCRequired<Err, Data extends Object> {
  const DCRequired();

  /// Creates a DCRequired with an error.
  ///
  /// ```dart
  /// DCRequired.error(Exception('Failed'))
  /// ```
  const factory DCRequired.error(Err error) = DCRequiredError<Err, Data>;

  /// Creates a DCRequired with a value that is never null.
  ///
  /// ```dart
  /// DCRequired.data(user)
  /// ```
  const factory DCRequired.data(Data value) = DCRequiredData<Err, Data>;

  /// Returns true if this is a DCRequiredError.
  bool get hasError;

  /// Applies a function based on whether this is an error or data.
  ///
  /// ```dart
  /// dcRequired.fold(
  ///   onError: (e) => 'Error: $e',
  ///   onData: (user) => 'User: ${user.name}',
  /// )
  /// ```
  U fold<U>({
    required U Function(Err error) onError,
    required U Function(Data value) onData,
  });

  /// Maps the error value if present, preserves the value otherwise.
  ///
  /// ```dart
  /// dcRequired.mapError((e) => UserFriendlyException(e.message))
  /// ```
  DCRequired<NewErr, Data> mapError<NewErr>(
    NewErr Function(Err error) transform,
  );

  /// Converts this DCRequired into a DC, for code that expects a DC.
  ///
  /// ```dart
  /// DC<Exception, User> result = dcRequired.toDC();
  /// // DCRequiredData(user) → DCData(Some(user))
  /// // DCRequiredError(e)   → DCError(e)
  /// ```
  DC<Err, Data> toDC();

  /// Forwards error if present, otherwise creates a DC with provided data.
  ///
  /// ```dart
  /// final userResult = await fetchUser();
  /// return DCRequired.forwardErrorOr(userResult, profile);
  /// ```
  static DC<Err, NewData>
      forwardErrorOr<Err, Data extends Object, NewData extends Object>(
    DCRequired<Err, Data> dcRequired,
    NewData data,
  ) {
    return dcRequired.fold(
      onError: DC.error,
      onData: (_) => DC.some(data),
    );
  }

  /// Forwards error if present, otherwise creates a DC with None.
  ///
  /// ```dart
  /// return DCRequired.forwardErrorOrNull(userResult);
  /// ```
  static DC<Err, NewData>
      forwardErrorOrNull<Err, Data extends Object, NewData extends Object>(
    DCRequired<Err, Data> dcRequired,
  ) {
    return dcRequired.fold(
      onError: DC.error,
      onData: (_) => DC.none(),
    );
  }
}

/// DCRequired containing an error.
@immutable
final class DCRequiredError<Err, Data extends Object>
    extends DCRequired<Err, Data> {
  const DCRequiredError(this.error);

  /// The error value.
  final Err error;

  @override
  bool get hasError => true;

  @override
  U fold<U>({
    required U Function(Err error) onError,
    required U Function(Data value) onData,
  }) {
    return onError(error);
  }

  @override
  DCRequired<NewErr, Data> mapError<NewErr>(
    NewErr Function(Err error) transform,
  ) {
    return DCRequiredError(transform(error));
  }

  @override
  DC<Err, Data> toDC() => DC.error(error);

  @override
  String toString() => 'DCRequiredError($error)';

  @override
  bool operator ==(Object other) {
    return other is DCRequiredError<Err, Data> && other.error == error;
  }

  @override
  int get hashCode => error.hashCode;
}

/// DCRequired containing a value that is never null.
@immutable
final class DCRequiredData<Err, Data extends Object>
    extends DCRequired<Err, Data> {
  const DCRequiredData(this.value);

  /// The value, never null.
  final Data value;

  @override
  bool get hasError => false;

  @override
  U fold<U>({
    required U Function(Err error) onError,
    required U Function(Data value) onData,
  }) {
    return onData(value);
  }

  @override
  DCRequired<NewErr, Data> mapError<NewErr>(
    NewErr Function(Err error) transform,
  ) {
    return DCRequiredData(value);
  }

  @override
  DC<Err, Data> toDC() => DC.some(value);

  @override
  String toString() => 'DCRequiredData($value)';

  @override
  bool operator ==(Object other) {
    return other is DCRequiredData<Err, Data> && other.value == value;
  }

  @override
  int get hashCode => value.hashCode;
}

/// Converts a DC into a DCRequired.
extension DCRequiredConversion<Err, Data extends Object> on DC<Err, Data> {
  /// Converts this DC into a DCRequired, turning an empty data arm into the
  /// error built by [onNoneErr].
  ///
  /// ```dart
  /// final userResult = (await fetchUser()).intoDCRequired(
  ///   onNoneErr: () => Exception('user returned none'),
  /// );
  /// ```
  DCRequired<Err, Data> intoDCRequired({required Err Function() onNoneErr}) {
    return switch (this) {
      DCError(:final error) => DCRequired.error(error),
      DCData(data: Some(:final value)) => DCRequired.data(value),
      DCData(data: None()) => DCRequired.error(onNoneErr()),
    };
  }
}
