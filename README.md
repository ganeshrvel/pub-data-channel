### Introduction

##### Data Channel for Dart and Flutter.

**data_channel** (DC) is a simple dart utility for handling exceptions and data routing.
It is not a very ideal solution to handle exceptions using try and catch at every function, use `data_channel` instead. `data_channel` will take care of the routing of errors and data.

### Installation

Go to https://pub.dev/packages/data_channel#-installing-tab- for the latest version of **data_channel**

### Example

Return data from `getStarwarsCharacters` method
```dart
import 'package:data_channel/data_channel.dart';

Future<DC<Exception, StarwarsResponse>> getStarwarsCharacters() async {
    try {
	  final _response = await http.get('https://starwars-api.com/characters');
	  
      if (_response.body != null) {
        _starWarsData = StarwarsResponse.fromJson(
            json.decode(_response.body) as Map<String, dynamic>);
      } else {
        _exception = Exception('No data available');
      }

      if (_exception != null) {
        return DC.error(
          _exception,
        );
      }

      return DC.data(
        _starWarsData,
      );
    } on Exception {
      return DC.error(
       	Exception('Some error occured'),
      );
    }
 }
```

Check for errors
```dart
void getStarwarsCharacters() async {
    final _starWarsData = await getStarwarsCharacters();

    if (_starWarsData.hasError) {
      // do something
    } else if (_starWarsData.hasData) {
      // do something
    }
 }
```

**DC forward**

`forward` will help to avoid redundant error checks. We can easily forward a different data model to the callee instead of the original incoming data model. `DC.forward` will forward the error, if present, else data will be returned.
```dart
Future<DC<Exception, UserModel>> checkSomethingAndReturn() {
      final _starWarsData = await getStarwarsCharacters();

    return DC.forward(
      loginData,
      UserModel(id: _starWarsData.id),
    );
  }
```

**DC pick**

Cherry pick values using `DC.pick`

- onError will return error, if present
- onNoError will return data if error is not present
- onData will return data if data is available
- onNoData will return if data is not available

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

  // or

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


### Buy me a coffee
Help me keep the keep building FREE and Open-Source software for all.
- Donate Via PayPal: [paypal.me/ganeshrvel](https://paypal.me/ganeshrvel "https://paypal.me/ganeshrvel")
- Buy Me A Coffee (UPI, PayPal, Credit/Debit Cards, Internet Banking): [buymeacoffee.com/ganeshrvel](https://buymeacoffee.com/ganeshrvel "https://buymeacoffee.com/ganeshrvel")

### Contacts
Please feel free to contact me at ganeshrvel@outlook.com

### About

- Author: [Ganesh Rathinavel](https://www.linkedin.com/in/ganeshrvel "Ganesh Rathinavel")
- License: [MIT](https://github.com/ganeshrvel/openmtp/blob/master/LICENSE "MIT")
- Package URL: [https://pub.dev/packages/data_channel](https://pub.dev/packages/data_channel "https://pub.dev/packages/data_channel")
- Repo URL: [https://github.com/ganeshrvel/pub-data-channel](https://github.com/ganeshrvel/pub-data-channel/ "https://github.com/ganeshrvel/pub-data-channel")
- Contacts: ganeshrvel@outlook.com

### License
data_channel | Data Channel for Dart and Flutter. [MIT License](https://github.com/ganeshrvel/pub-data-channel/blob/master/LICENSE "MIT License").

Copyright © 2018-Present Ganesh Rathinavel
