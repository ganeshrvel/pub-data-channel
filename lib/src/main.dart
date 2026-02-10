import 'package:data_channel/src/option.dart';
import 'package:meta/meta.dart';

// Type aliases
typedef DCOption<T> = Option<T>;
typedef DCSome<T> = Some<T>;
typedef DCNone<T> = None<T>;

/// Data Channel - A result type for handling errors and data.
///
/// Every DC is either:
/// - DCError: contains an error
/// - DCData: contains optional data
sealed class DC<Err, Data> {
  const DC();

  /// Creates a DC with an error.
  ///
  /// ```dart
  /// DC.error(Exception('Failed'))
  /// ```
  factory DC.error(Err error) = DCError<Err, Data>;

  /// Creates a DC with data.
  ///
  /// ```dart
  /// DC.data(user)
  /// ```
  factory DC.data(Data data) = DCData<Err, Data>.some;

  /// Creates a DC with null/no data.
  ///
  /// ```dart
  /// DC.nullData()
  /// ```
  factory DC.nullData() = DCData<Err, Data>.none;

  /// Returns true if this is a DCError.
  bool get hasError;

  /// Returns true if this contains optional data (Some or None), false if this is an error.
  ///
  /// Note: This only indicates the variant type (DCData vs DCError), not whether data exists.
  /// To check if actual data is present, use the Option methods within `fold`:
  ///
  /// ```dart
  /// dc.fold(
  ///   onError: (e) => ...,
  ///   onData: (opt) => opt.isSome ? ... : ...,
  /// )
  /// ```
  /// Or access the data field directly on DCData and use Option's `isSome`/`isNone`.
  bool get hasOptionalData;

  /// Applies a function based on whether this is an error or data.
  ///
  /// ```dart
  /// dc.fold(
  ///   onError: (e) => 'Error: $e',
  ///   onData: (opt) => opt.fold(
  ///     onSome: (v) => 'Value: $v',
  ///     onNone: () => 'No value',
  ///   ),
  /// )
  /// ```
  U fold<U>({
    required U Function(Err error) onError,
    required U Function(Option<Data> data) onData,
  });

  /// Forwards error if present, otherwise creates new DCData with provided data.
  ///
  /// ```dart
  /// final userResult = await fetchUser();
  /// return DC.forwardErrorOr(userResult, profile);
  /// ```
  static DC<Err, NewData> forwardErrorOr<Err, Data, NewData>(
    DC<Err, Data> dc,
    NewData data,
  ) {
    return dc.fold(
      onError: DC.error,
      onData: (_) => DC.data(data),
    );
  }

  /// Forwards error if present, otherwise creates DCData with null.
  ///
  /// ```dart
  /// return DC.forwardErrorOrNull(userResult);
  /// ```
  static DC<Err, NewData> forwardErrorOrNull<Err, Data, NewData>(
    DC<Err, Data> dc,
  ) {
    return dc.fold(
      onError: DC.error,
      onData: (_) => DC.nullData(),
    );
  }

  /// Forwards error if present, otherwise transforms data using Option methods.
  ///
  /// ```dart
  /// // Return Some directly
  /// DC.forwardErrorOrElse(
  ///   userResult,
  ///   (_) => Some(DefaultProfile()),
  /// )
  ///
  /// // Return None explicitly
  /// DC.forwardErrorOrElse(
  ///   userResult,
  ///   (_) => const None(),
  /// )
  ///
  /// // Simple transform
  /// DC.forwardErrorOrElse(
  ///   userResult,
  ///   (userData) => userData.map((user) => Profile(user)),
  /// )
  ///
  /// // With validation/filter
  /// DC.forwardErrorOrElse(
  ///   userResult,
  ///   (userData) => userData.filter((user) => user.isVerified),
  /// )
  ///
  /// // With fallback
  /// DC.forwardErrorOrElse(
  ///   userResult,
  ///   (userData) => userData.map((user) => user.name).orElse('Guest'),
  /// )
  /// ```
  static DC<Err, NewData> forwardErrorOrElse<Err, Data, NewData>(
    DC<Err, Data> dc,
    Option<NewData> Function(Option<Data> data) builder,
  ) {
    return dc.fold(
      onError: DC.error,
      onData: (option) => DCData(builder(option)),
    );
  }

  /// Maps the error value if present, preserves data otherwise.
  ///
  /// ```dart
  /// dc.mapError((e) => UserFriendlyException(e.message))
  /// ```
  DC<NewErr, Data> mapError<NewErr>(NewErr Function(Err error) transform);
}

/// DC containing an error.
@immutable
final class DCError<Err, Data> extends DC<Err, Data> {
  const DCError(this.error);

  /// The error value.
  final Err error;

  @override
  bool get hasError => true;

  @override
  bool get hasOptionalData => false;

  @override
  U fold<U>({
    required U Function(Err error) onError,
    required U Function(Option<Data> data) onData,
  }) {
    return onError(error);
  }

  @override
  DC<NewErr, Data> mapError<NewErr>(NewErr Function(Err error) transform) {
    return DCError(transform(error));
  }

  @override
  String toString() => 'DCError($error)';

  @override
  bool operator ==(Object other) {
    return other is DCError<Err, Data> && other.error == error;
  }

  @override
  int get hashCode => error.hashCode;
}

/// DC containing optional data.
@immutable
final class DCData<Err, Data> extends DC<Err, Data> {
  const DCData(this.data);

  /// Creates DCData with a value.
  DCData.some(Data value) : data = Some(value);

  /// Creates DCData with no value.
  const DCData.none() : data = const None();

  /// The optional data value.
  final Option<Data> data;

  @override
  bool get hasError => false;

  @override
  bool get hasOptionalData => true;

  @override
  U fold<U>({
    required U Function(Err error) onError,
    required U Function(Option<Data> data) onData,
  }) {
    return onData(data);
  }

  @override
  DC<NewErr, Data> mapError<NewErr>(NewErr Function(Err error) transform) {
    return DCData(data);
  }

  @override
  String toString() => 'DCData($data)';

  @override
  bool operator ==(Object other) {
    return other is DCData<Err, Data> && other.data == data;
  }

  @override
  int get hashCode => data.hashCode;
}
