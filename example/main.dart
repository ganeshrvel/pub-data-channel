// ignore_for_file: avoid_print, dangling_library_doc_comments, unreachable_from_main

/// **Complete Implementation Examples:**
///
/// https://github.com/ganeshrvel/flutter_mobx_dio_boilerplate/blob/master/lib/features/login/data/data_sources/login_local_data_source.dart
/// https://github.com/ganeshrvel/flutter_mobx_dio_boilerplate/blob/master/lib/features/login/data/controllers/login_controller.dart
/// https://github.com/ganeshrvel/flutter_mobx_dio_boilerplate/blob/master/lib/features/login/data/repositories/login_repository.dart
/// https://github.com/ganeshrvel/flutter_mobx_dio_boilerplate/blob/master/lib/features/login/ui/store/login_store.dart

import 'package:data_channel/data_channel.dart';

// Mock classes for examples
class User {
  User(this.id, this.name);

  final String id;
  final String name;
}

class Profile {
  Profile({this.id, this.name});

  final String? id;
  final String? name;
}

class NetworkException implements Exception {
  NetworkException(this.message);

  final String message;

  @override
  String toString() => 'NetworkException: $message';
}

class CacheException implements Exception {
  CacheException(this.message);

  final String message;

  @override
  String toString() => 'CacheException: $message';
}

class UserFacingException implements Exception {
  UserFacingException(this.message);

  final String message;

  @override
  String toString() => 'UserFacingException: $message';
}

void main() {
  print('Data Channel Examples\n');

  basicErrorHandlingExample();
  checkingResultStateExample();
  pickMethodExample();
  pickWithOnNoErrorExample();
  foldPatternExample();
  mapDataExample();
  mapErrorExample();
  forwardExample();
  chainedTransformationsExample();
  realWorldScenarioExample();
}

void basicErrorHandlingExample() {
  print('=== Basic Error Handling ===');

  final successResult = DC<NetworkException, User>.data(
    User('123', 'John Doe'),
  );

  print('Success case:');
  print('  Has data: ${successResult.hasData}');
  print('  Has error: ${successResult.hasError}');
  print('  User: ${successResult.data?.name}');

  final errorResult = DC<NetworkException, User>.error(
    NetworkException('Connection timeout'),
  );

  print('Error case:');
  print('  Has data: ${errorResult.hasData}');
  print('  Has error: ${errorResult.hasError}');
  print('  Error: ${errorResult.error}');
}

void checkingResultStateExample() {
  print('=== Checking Result State ===');

  final result = DC<Exception, String>.data('Operation successful');

  if (result.hasError) {
    print('Error occurred: ${result.error}');
  } else if (result.hasData) {
    print('Success! Data: ${result.data}');
  }
}

void pickMethodExample() {
  print('=== Using pick() Method ===');

  DC<CacheException, User>.data(User('456', 'Alice')).pick(
    onError: (error) {
      print('Error handler called: $error');
    },
    onData: (user) {
      print('Data handler called: ${user.name}');
    },
    onNoData: () {
      print('No data handler called');
    },
  );
}

void pickWithOnNoErrorExample() {
  print('=== Using pick() with onNoError ===');

  DC<Exception, String?>.data(null).pick(
    onError: (error) {
      print('Error: $error');
    },
    onNoError: (data) {
      if (data != null) {
        print('Data available: $data');
      } else {
        print('Data is null, using default');
      }
    },
  );
}

void foldPatternExample() {
  print('=== Using fold() Pattern ===');

  final successResult = DC<Exception, User>.data(User('789', 'Bob'));

  final message = successResult.fold(
    onError: (error) => 'Failed to load user: $error',
    onData: (user) => 'Welcome ${user?.name}!',
  );

  print('Fold result: $message');

  final errorResult = DC<Exception, User>.error(Exception('Network error'));

  final errorMessage = errorResult.fold(
    onError: (error) => 'Error occurred: $error',
    onData: (user) => 'User: ${user?.name}',
  );

  print('Fold error result: $errorMessage');
}

void mapDataExample() {
  print('=== Using mapData() ===');

  final result = DC<Exception, User>.data(User('999', 'Charlie'));

  final nameResult = result.mapData((user) => user.name);

  print('Original data type: User');
  print('Mapped data type: String');
  print('Mapped value: ${nameResult.data}');

  final upperResult = nameResult.mapData((name) => name.toUpperCase());
  print('Chained mapping: ${upperResult.data}');
}

void mapErrorExample() {
  print('=== Using mapError() ===');

  final result = DC<NetworkException, String>.error(
    NetworkException('502 Bad Gateway'),
  );

  final friendlyResult = result.mapError(
    (error) => UserFacingException('Service temporarily unavailable'),
  );

  print('Original error: ${result.error}');
  print('Mapped error: ${friendlyResult.error}');
}

void forwardExample() {
  print('=== Using DC.forward() ===');

  final userResult = DC<Exception, User>.data(User('111', 'David'));

  final profileResult = DC.forward(
    userResult,
    Profile(
      id: userResult.data?.id,
      name: userResult.data?.name,
    ),
  );

  print('User result has data: ${userResult.hasData}');
  print('Profile result has data: ${profileResult.hasData}');
  print(
    'Profile: id=${profileResult.data?.id}, name=${profileResult.data?.name}',
  );

  final errorResult = DC<Exception, User>.error(Exception('Fetch failed'));

  final errorProfileResult = DC.forward(
    errorResult,
    Profile(id: 'default', name: 'default'),
  );

  print('Error forwarded: ${errorProfileResult.hasError}');
  print('Forwarded error: ${errorProfileResult.error}');
}

void chainedTransformationsExample() {
  print('=== Chained Transformations ===');

  final result = DC<Exception, User>.data(User('222', 'eve'));

  final displayName = result
      .mapData((user) => user.name)
      .mapData((name) => name.toUpperCase())
      .mapData((name) => 'User: $name');

  print('Chained result: ${displayName.data}');
}

void realWorldScenarioExample() {
  print('=== Real World Scenario ===');

  final apiResult = simulateApiCall('333');

  final greeting = apiResult.fold(
    onError: (error) => 'Could not load user profile',
    onData: (user) => 'Hello, ${user?.name}!',
  );

  print('API response: $greeting');

  apiResult
      .mapData((user) => user.name)
      .mapError((error) => UserFacingException('Please try again later'))
      .pick(
        onError: (error) => print('UI Error: $error'),
        onData: (name) => print('Display name: $name'),
      );
}

DC<NetworkException, User> simulateApiCall(String id) {
  return DC<NetworkException, User>.data(User(id, 'Frank'));
}
