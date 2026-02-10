### Introduction

##### Data Channel for Dart and Flutter.

**data_channel** (DC) is a lightweight Dart utility designed to simplify exception handling and data
routing in your applications. Rather than cluttering your code with try-catch blocks at every
function call, `data_channel` provides a clean, composable way to handle both success and error
cases.

### Installation

Visit https://pub.dev/packages/data_channel#-installing-tab- for the latest version of *
*data_channel**

### Examples

#### Basic Usage

Return either error or data from any method:

```dart
import 'package:data_channel/data_channel.dart';

Future<DC<Exception, LoginModel>> getSomeLoginData() async {
  try {
    return DC<Exception, LoginModel>.data(someData);
  } on Exception {
    return DC<Exception, LoginModel>.error(CacheException());
  }
}
```

Check for errors in the calling code:

```dart
void doSomething() async {
  final value = await getSomeLoginData();

  if (value.hasError) {
    // handle error case
  } else if (value.hasData) {
    // handle success case
  }
}
```

#### DC.forward

Eliminate redundant error checks when transforming data models. `DC.forward` automatically
propagates errors while allowing you to transform successful data:

```dart
Future<DC<Exception, UserModel>> checkSomethingAndReturn() async {
  final loginData = await getSomeLoginData();

  return DC.forward(
    loginData,
    UserModel(id: loginData.data?.tokenId),
  );
}
```

#### DC.pick

Handle different scenarios with optional callbacks:

```dart
final appData = await getSomeLoginData();

appData.pick(
  onError: (error) {
    if (error is CacheException) {
      alerts.setException(context, error);
    }
  },
  onData: (data) {
    value1 = data;
  },
  onNoData: () {
    value1 = getDefaultValue();
  },
);

// Alternative: use onNoError for combined data/no-data handling
appData.pick(
  onError: (error) {
    if (error is CacheException) {
      alerts.setException(context, error);
    }
  },
  onNoError: (data) {
    if (data != null) {
      value1 = data;
      return;
    }
    value1 = getDefaultValue();
  },
);
```

#### DC.fold

Handle both cases exhaustively with a clean functional approach:

```dart

final message = result.fold(
  onError: (error) => 'Operation failed: $error',
  onData: (data) => 'Success: $data',
);

// Use in widget building
final widget = result.fold(
  onError: (error) => ErrorWidget(error),
  onData: (data) => SuccessView(data),
);
```

#### Transforming Results

Transform data or errors while preserving the result structure:

```dart
// Transform successful data
final theme = await

getTheme();

final colorName = theme.mapData((t) => t.colorName);

// Transform errors into user-friendly messages
final userFriendly = theme.mapError(
      (error) => UserFacingException(error.message),
);

// Chain transformations
final uppercaseColor = theme
    .mapData((t) => t.colorName)
    .mapData((name) => name.toUpperCase());
```

### Buy me a coffee

Help keep this package free and open for everyone.  
PayPal: [paypal.me/ganeshrvel](https://paypal.me/ganeshrvel "paypal.me/ganeshrvel")

### Contact

Feel free to reach out at ganeshrvel@outlook.com

### About

- Author: [Ganesh Rathinavel](https://www.linkedin.com/in/ganeshrvel "Ganesh Rathinavel")
- License: [MIT](https://github.com/ganeshrvel/openmtp/blob/master/LICENSE "MIT")
-
Package: [pub.dev/packages/data_channel](https://pub.dev/packages/data_channel "https://pub.dev/packages/data_channel")
-
Repository: [github.com/ganeshrvel/pub-data-channel](https://github.com/ganeshrvel/pub-data-channel/ "https://github.com/ganeshrvel/pub-data-channel")
- Email: ganeshrvel@outlook.com

### License

data_channel | Data Channel for Dart and Flutter  
[MIT License](https://github.com/ganeshrvel/pub-data-channel/blob/master/LICENSE "MIT License")

Copyright © 2018-Present Ganesh Rathinavel
