import 'package:meta/meta.dart';

/// Represents an optional value: every Option is either Some and contains a value, or None.
sealed class Option<T> {
  const Option();

  /// Creates an Option from a nullable value.
  /// Returns Some if value is non-null, None otherwise.
  ///
  /// ```dart
  /// Option.from(5)     // Some(5)
  /// Option.from(null)  // None()
  /// ```
  factory Option.from(T? value) {
    return value != null ? Some(value) : None<T>();
  }

  /// Returns true if the option is a Some value.
  bool get isSome;

  /// Returns true if the option is a None value.
  bool get isNone;

  /// Returns the contained value or null if None.
  ///
  /// Useful for pattern matching:
  /// ```dart
  /// switch (option.tryMaybe()) {
  ///   case null: print('No value');
  ///   case 1: print('Got one');
  ///   case final v: print('Got $v');
  /// }
  /// ```
  T? tryMaybe();

  /// Returns the contained value or a default.
  ///
  /// ```dart
  /// Some(5).orElse(0)  // 5
  /// None().orElse(0)   // 0
  /// ```
  T orElse(T defaultValue);

  /// Returns the contained value or computes it from a function.
  /// The function is only called if this is None.
  ///
  /// ```dart
  /// Some(5).orElseGet(() => expensiveComputation())  // 5 (function not called)
  /// None().orElseGet(() => expensiveComputation())   // calls function
  /// ```
  T orElseGet(T Function() getDefault);

  /// Maps an `Option<T>` to `Option<U>` by applying a function to a contained value.
  ///
  /// ```dart
  /// Some(5).map((x) => x * 2)  // Some(10)
  /// None().map((x) => x * 2)   // None()
  /// ```
  Option<U> map<U>(U Function(T value) transform);

  /// Maps an `Option<T>` to `Option<U>` by applying a function that returns an Option.
  /// Flattens nested Options.
  ///
  /// ```dart
  /// Some(5).flatMap((x) => Some(x * 2))  // Some(10)
  /// Some(5).flatMap((x) => None())       // None()
  /// None().flatMap((x) => Some(x * 2))   // None()
  /// ```
  Option<U> flatMap<U>(Option<U> Function(T value) transform);

  /// Returns None if the option is None, otherwise calls predicate with the
  /// wrapped value and returns Some if predicate returns true, None if false.
  ///
  /// ```dart
  /// Some(5).filter((x) => x > 3)   // Some(5)
  /// Some(5).filter((x) => x > 10)  // None()
  /// None().filter((x) => x > 3)    // None()
  /// ```
  Option<T> filter(bool Function(T value) predicate);

  /// Applies a function to the contained value (if Some), or returns a default (if None).
  ///
  /// ```dart
  /// Some(5).fold(
  ///   onSome: (x) => x * 2,
  ///   onNone: () => 0,
  /// )  // 10
  ///
  /// None().fold(
  ///   onSome: (x) => x * 2,
  ///   onNone: () => 0,
  /// )  // 0
  /// ```
  U fold<U>({
    required U Function(T value) onSome,
    required U Function() onNone,
  });
}

/// Some value of type T.
@immutable
final class Some<T> extends Option<T> {
  const Some(this.value);

  /// The contained value.
  final T value;

  @override
  bool get isSome => true;

  @override
  bool get isNone => false;

  @override
  T? tryMaybe() => value;

  @override
  T orElse(T defaultValue) => value;

  @override
  T orElseGet(T Function() getDefault) => value;

  @override
  Option<U> map<U>(U Function(T value) transform) {
    return Some(transform(value));
  }

  @override
  Option<U> flatMap<U>(Option<U> Function(T value) transform) {
    return transform(value);
  }

  @override
  Option<T> filter(bool Function(T value) predicate) {
    return predicate(value) ? this : None<T>();
  }

  @override
  U fold<U>({
    required U Function(T value) onSome,
    required U Function() onNone,
  }) {
    return onSome(value);
  }

  @override
  String toString() => 'Some($value)';

  @override
  bool operator ==(Object other) {
    return other is Some<T> && other.value == value;
  }

  @override
  int get hashCode => value.hashCode;
}

/// No value.
@immutable
final class None<T> extends Option<T> {
  const None();

  @override
  bool get isSome => false;

  @override
  bool get isNone => true;

  @override
  T? tryMaybe() => null;

  @override
  T orElse(T defaultValue) => defaultValue;

  @override
  T orElseGet(T Function() getDefault) => getDefault();

  @override
  Option<U> map<U>(U Function(T value) transform) => None<U>();

  @override
  Option<U> flatMap<U>(Option<U> Function(T value) transform) => None<U>();

  @override
  Option<T> filter(bool Function(T value) predicate) => this;

  @override
  U fold<U>({
    required U Function(T value) onSome,
    required U Function() onNone,
  }) {
    return onNone();
  }

  @override
  String toString() => 'None';

  @override
  bool operator ==(Object other) => other is None<T>;

  @override
  int get hashCode => 0;
}
