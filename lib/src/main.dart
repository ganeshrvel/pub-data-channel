/// Data Channel for Dart and Flutter.
///
/// DC is a simple utility for handling exceptions and data routing.
class DC<Err, Data> {
  /// Returns just error.
  factory DC.error(Err error) => DC._(error: error);

  const DC._({this.error, this.data});

  /// Returns just data.
  factory DC.data(Data? data) => DC._(data: data);

  /// Forwards error or data.
  factory DC.forward(DC<Err, dynamic> dc, Data? data) {
    if (dc.hasError) {
      return DC.error(dc.error as Err);
    }

    return DC.data(data);
  }

  final Err? error;
  final Data? data;

  /// Checks whether an error is present.
  bool get hasError => error != null;

  /// Checks whether data is available.
  bool get hasData => data != null;

  /// Pick handler based on result state.
  void pick({
    void Function(Err error)? onError,
    void Function(Data? data)? onNoError,
    void Function(Data data)? onData,
    void Function()? onNoData,
  }) {
    if (hasError) {
      if (onError != null) {
        onError(error as Err);
      }

      return;
    }

    if (onNoError != null) {
      onNoError(data);

      return;
    }

    if (hasData) {
      if (onData != null) {
        onData(data as Data);
      }

      return;
    }

    if (onNoData != null) {
      onNoData();

      return;
    }
  }

  /// Fold pattern - handle both cases with a simple function call.
  T fold<T>({
    required T Function(Err error) onError,
    required T Function(Data? data) onData,
  }) {
    if (hasError) {
      return onError(error as Err);
    }
    return onData(data);
  }

  /// Map the data value if present, preserve error otherwise.
  DC<Err, NewData> mapData<NewData>(NewData Function(Data data) transform) {
    if (hasError) {
      return DC.error(error as Err);
    }
    return DC.data(transform(data as Data));
  }

  /// Map the error value if present, preserve data otherwise.
  DC<NewError, Data> mapError<NewError>(
    NewError Function(Err error) transform,
  ) {
    if (hasError) {
      return DC.error(transform(error as Err));
    }

    return DC.data(data);
  }
}
