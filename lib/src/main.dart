import 'package:data_channel/src/option.dart';
import 'package:meta/meta.dart';

// Type aliases
typedef DCOption<T extends Object> = Option<T>;
typedef DCSome<T extends Object> = Some<T>;
typedef DCNone<T extends Object> = None<T>;

/// Data Channel - A result type for handling errors and data.
///
/// Every DC is either:
/// - DCError: contains an error
/// - DCData: contains optional data
sealed class DC<Err, Data extends Object> {
  const DC();

  /// Creates a DC with an error.
  ///
  /// ```dart
  /// DC.error(Exception('Failed'))
  /// ```
  factory DC.error(Err error) = DCError<Err, Data>;

  /// Automatically creates a DC from a nullable value.
  ///
  /// - If value is non-null → returns DCData(Some(value))
  /// - If value is null → returns DCData(None())
  ///
  /// Use this to eliminate manual null checks when wrapping nullable values.
  ///
  /// ```dart
  /// DC.auto(user)           // DCData(Some(user)) if user is non-null
  /// DC.auto(null)           // DCData(None())
  ///
  /// // Replaces manual checking
  /// String? name = getUserName();
  /// DC<Exception, String> result = DC.auto(name);  // auto-handles null
  ///
  /// // With dynamic values (recommended pattern)
  /// dynamic apiResponse = fetchData();
  /// DC<Exception, User> result = DC.auto(apiResponse as User?);  // Safe - handles null
  /// // Don't use: DC.some(apiResponse as User) - crashes if null!
  /// ```
  factory DC.auto(Data? data) {
    return data != null ? DCData.some(data) : DCData<Err, Data>.none();
  }

  /// Creates a DC with data wrapped in Some.
  ///
  /// The value is always wrapped in Some and must be NON-NULL.
  ///
  /// ```dart
  /// DC.some(user)  // DCData(Some(user)) - user must be NON-NULL
  ///
  /// // For nullable values, use DC.auto() instead
  /// String? name = getName();
  /// DC.auto(name)  // Automatically handles null
  /// ```
  factory DC.some(Data data) = DCData<Err, Data>.some;

  /// Creates a DC with no data (None).
  ///
  /// ```dart
  /// DC.none()  // DCData(None())
  /// ```
  factory DC.none() = DCData<Err, Data>.none;

  /// Creates a DC from an existing Option without double-wrapping.
  ///
  /// Lifts an Option directly into DCData without creating `Option<Option<T>>`.
  ///
  /// ```dart
  /// Option<User> userOpt = getUserOption();
  /// DC<Exception, User> result = DC.fromOption(userOpt);
  /// // If userOpt is Some(user) → DCData(Some(user))
  /// // If userOpt is None() → DCData(None())
  /// ```
  factory DC.fromOption(Option<Data> option) {
    return DCData(option);
  }

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
  static DC<Err, NewData>
      forwardErrorOr<Err, Data extends Object, NewData extends Object>(
    DC<Err, Data> dc,
    NewData data,
  ) {
    return dc.fold(
      onError: DC.error,
      onData: (_) => DC.some(data),
    );
  }

  /// Forwards error if present, otherwise creates DCData with None.
  ///
  /// ```dart
  /// return DC.forwardErrorOrNull(userResult);
  /// ```
  static DC<Err, NewData>
      forwardErrorOrNull<Err, Data extends Object, NewData extends Object>(
    DC<Err, Data> dc,
  ) {
    return dc.fold(
      onError: DC.error,
      onData: (_) => DC.none(),
    );
  }

  /// Forwards error if present, otherwise lazily calls builder to produce a new Option.
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
  static DC<Err, NewData>
      forwardErrorOrElse<Err, Data extends Object, NewData extends Object>(
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
final class DCError<Err, Data extends Object> extends DC<Err, Data> {
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
final class DCData<Err, Data extends Object> extends DC<Err, Data> {
  const DCData(this.data);

  /// Creates DCData with a value wrapped in Some.
  DCData.some(Data value) : data = Some(value);

  /// Creates DCData with None (no value).
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
