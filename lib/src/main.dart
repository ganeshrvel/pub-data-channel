import 'package:meta/meta.dart';

///
/// data_channel class
class DC<Error, Data> {
  Error error;
  Data data;

  DC({
    @required this.error,
    @required this.data,
  });

  // checks whether an error is present
  bool get hasError => error != null;

  // checks whether data is available
  bool get hasData => data != null;

  // returns just error
  factory DC.error(Error error) {
    return DC(
      error: error,
      data: null,
    );
  }

  // returns just data
  factory DC.data(Data data) {
    return DC(
      error: null,
      data: data,
    );
  }

  // forwards error or data
  factory DC.forward(DC _dc, Data data) {
    if (_dc.hasError) {
      return DC.error(_dc.error as Error);
    }

    return DC.data(data);
  }

  // pick onError, onNoError, onData or onNoData
  void pick({
    Function(Error error) onError,
    Function(Data data) onNoError,
    Function(Data data) onData,
    Function() onNoData,
  }) {
    if (hasError) {
      if (onError != null) {
        onError(error);
      }

      return;
    }

    if (onNoError != null) {
      onNoError(data);

      return;
    }

    if (hasData) {
      if (onData != null) {
        onData(data);
      }

      return;
    }

    if (onNoData != null) {
      onNoData();

      return;
    }
  }
}
