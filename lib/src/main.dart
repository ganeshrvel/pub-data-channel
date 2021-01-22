/// Data channel could be used to transport data across the dart program
/// Data channel can move any data ranging from external http api response to internal data.
class DC<Error, Data> {
  Error? error;
  Data? data;

  DC({
    required this.error,
    required this.data,
  });

  /// checks whether an error is present
  bool get hasError => error != null;

  /// checks whether data is available
  bool get hasData => data != null;

  /// returns the error
  factory DC.error(Error error) {
    return DC(
      error: error,
      data: null,
    );
  }

  /// returns just data
  factory DC.data(Data? data) {
    return DC(
      error: null,
      data: data,
    );
  }

  /// forwards the error if present else forwards the data
  factory DC.forward(DC _dc, Data? data) {
    if (_dc.hasError) {
      return DC.error(_dc.error as Error);
    }

    return DC.data(data);
  }

  /// Cherry pick values
  ///
  /// onError will return error, if present
  /// onNoError will return data if error is not present
  /// onData will return data if data is available
  /// onNoData will return if data is not available
  void pick({
    Function(Error error)? onError,
    Function(Data? data)? onNoError,
    Function(Data data)? onData,
    Function()? onNoData,
  }) {
    if (hasError) {
      if (onError != null) {
        onError(error!);
      }

      return;
    }

    if (onNoError != null) {
      onNoError(data);

      return;
    }

    if (hasData) {
      if (onData != null) {
        onData(data!);
      }

      return;
    }

    if (onNoData != null) {
      onNoData();

      return;
    }
  }
}
