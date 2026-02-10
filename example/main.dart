// ignore_for_file: avoid_print, unreachable_from_main

/// **Complete Implementation Examples:**
///
/// For comprehensive test examples and usage patterns, see:
/// - DC (Data Channel) tests: https://github.com/ganeshrvel/pub-data-channel/blob/master/test/data_channel_test.dart
/// - Option type tests: https://github.com/ganeshrvel/pub-data-channel/blob/master/test/option_test.dart

import 'dart:convert';
import 'dart:io';

import 'package:data_channel/data_channel.dart';
import 'package:data_channel/src/option.dart';

// Mock classes for examples
class User {
  User(this.id, this.name, {this.isVerified = false});

  final String id;
  final String name;
  final bool isVerified;

  @override
  String toString() => 'User(id: $id, name: $name, verified: $isVerified)';
}

class Profile {
  Profile(this.userId, this.bio);

  final String userId;
  final String bio;

  @override
  String toString() => 'Profile(userId: $userId, bio: $bio)';
}

class NetworkException implements Exception {
  NetworkException(this.message);

  final String message;

  @override
  String toString() => 'NetworkException: $message';
}

class ValidationException implements Exception {
  ValidationException(this.field);

  final String field;

  @override
  String toString() => 'ValidationException: $field';
}

class UserFacingException implements Exception {
  UserFacingException(this.message);

  final String message;

  @override
  String toString() => 'UserFacingException: $message';
}

void main() {
  print('For more examples, see:');
  print('  test/data_channel_test.dart');
  print('  test/option_test.dart\n');

  basicDCUsageExample();
  optionBasicsExample();
  dcFoldExample();
  dcForwardErrorOrExample();
  dcForwardErrorOrElseExample();
  dcMapErrorExample();
  chainedOperationsExample();
  realWorldApiExample();
  nullHandlingWithOptionsExample();
  workflowExample();
}

void basicDCUsageExample() {
  // Success with data
  final successResult = DC<NetworkException, User>.data(
    User('123', 'Alice'),
  );

  print('Success case:');
  print('  hasError: ${successResult.hasError}');
  print('  hasOptionalData: ${successResult.hasOptionalData}');
  // Expected:
  //   hasError: false
  //   hasOptionalData: true

  // Error case
  final errorResult = DC<NetworkException, User>.error(
    NetworkException('Connection timeout'),
  );

  print('Error case:');
  print('  hasError: ${errorResult.hasError}');
  print('  hasOptionalData: ${errorResult.hasOptionalData}\n');
  // Expected:
  //   hasError: true
  //   hasOptionalData: false

  // Success with no data
  final nullDataResult = DC<NetworkException, User>.nullData();
  print('Null data case:');
  print('  hasError: ${nullDataResult.hasError}');
  print('  hasOptionalData: ${nullDataResult.hasOptionalData}\n');
  // Expected:
  //   hasError: false
  //   hasOptionalData: true
}

void optionBasicsExample() {
  // Creating Options
  const some = Some(42);
  const none = None<int>();
  final fromNullable = Option.from(null);

  print('Some(42).isSome: ${some.isSome}');
  // Expected: Some(42).isSome: true

  print('None().isNone: ${none.isNone}');
  // Expected: None().isNone: true

  print('Option.from(null).isNone: ${fromNullable.isNone}');
  // Expected: Option.from(null).isNone: true

  // Using Option methods
  final doubled = some.map((x) => x * 2);
  print('Some(42).map(x * 2): ${doubled.tryMaybe()}');
  // Expected: Some(42).map(x * 2): 84

  final withDefault = none.orElse(0);
  print('None().orElse(0): $withDefault');
  // Expected: None().orElse(0): 0

  // Filtering
  final evenOnly = some.filter((x) => x.isEven);
  print('Some(42).filter(isEven): ${evenOnly.tryMaybe()}\n');
  // Expected: Some(42).filter(isEven): 42
}

void dcFoldExample() {
  final successResult = DC<NetworkException, User>.data(
    User('789', 'Bob'),
  );

  final message = successResult.fold(
    onError: (error) => 'Failed: ${error.message}',
    onData: (userOption) => userOption.fold(
      onSome: (user) => 'Welcome ${user.name}!',
      onNone: () => 'No user data',
    ),
  );

  print('Success fold: $message');
  // Expected: Success fold: Welcome Bob!

  final errorResult = DC<NetworkException, User>.error(
    NetworkException('Network error'),
  );

  final errorMessage = errorResult.fold(
    onError: (error) => 'Error: ${error.message}',
    onData: (userOption) => 'User loaded',
  );

  print('Error fold: $errorMessage\n');
  // Expected: Error fold: Error: Network error
}

void dcForwardErrorOrExample() {
  final userResult = DC<NetworkException, User>.data(
    User('111', 'Charlie'),
  );

  final profileResult = DC.forwardErrorOr(
    userResult,
    Profile('111', 'Software Developer'),
  );

  print('User → Profile (success):');
  profileResult.fold(
    onError: (e) => print('  Error: $e'),
    onData: (profile) => print('  Profile: ${profile.tryMaybe()}'),
  );
  // Expected:
  //   Profile: Profile(userId: 111, bio: Software Developer)

  // Error case - forwards error
  final errorResult = DC<NetworkException, User>.error(
    NetworkException('Fetch failed'),
  );

  final errorProfileResult = DC.forwardErrorOr(
    errorResult,
    Profile('default', 'default'),
  );

  print('User → Profile (error):');
  errorProfileResult.fold(
    onError: (e) => print('  Error forwarded: $e'),
    onData: (profile) => print('  Profile: ${profile.tryMaybe()}'),
  );
  // Expected:
  //   Error forwarded: NetworkException: Fetch failed
}

void dcForwardErrorOrElseExample() {
  final userResult = DC<NetworkException, User>.data(
    User('222', 'Diana', isVerified: true),
  );

  // Example 1: Simple map
  final nameResult = DC.forwardErrorOrElse(
    userResult,
    (userData) => userData.map((user) => user.name),
  );

  print('Extract name:');
  nameResult.fold(
    onError: (e) => print('  Error: $e'),
    onData: (name) => print('  Name: ${name.orElse("Unknown")}'),
  );
  // Expected:
  //   Name: Diana

  // Example 2: Filter with validation
  final verifiedResult = DC.forwardErrorOrElse(
    userResult,
    (userData) => userData.filter((user) => user.isVerified),
  );

  print('Filter verified users:');
  verifiedResult.fold(
    onError: (e) => print('  Error: $e'),
    onData: (user) => user.fold(
      onSome: (u) => print('  Verified user: ${u.name}'),
      onNone: () => print('  User not verified'),
    ),
  );
  // Expected:
  //   Verified user: Diana

  // Example 3: Provide fallback
  final displayNameResult = DC.forwardErrorOrElse(
    userResult,
    (userData) => Some(userData.map((user) => user.name).orElse('Guest')),
  );

  print('With fallback:');
  displayNameResult.fold(
    onError: (e) => print('  Error: $e'),
    onData: (name) => print('  Display name: ${name.tryMaybe()}'),
  );
  // Expected:
  //   Display name: Diana
}

void dcMapErrorExample() {
  final result = DC<NetworkException, User>.error(
    NetworkException('502 Bad Gateway'),
  );

  // Transform to user-friendly error
  final friendlyResult = result.mapError(
    (error) => UserFacingException('Service temporarily unavailable'),
  );

  print('Original error:');
  result.fold<void>(
    onError: (e) => print('  $e'),
    onData: (_) => {},
  );
  // Expected:
  //   NetworkException: 502 Bad Gateway

  print('Mapped error:');
  friendlyResult.fold<void>(
    onError: (e) => print('  $e'),
    onData: (_) => {},
  );
  // Expected:
  //   UserFacingException: Service temporarily unavailable
}

void chainedOperationsExample() {
  final userResult = DC<NetworkException, User>.data(
    User('333', 'eve', isVerified: true),
  );

  DC
      .forwardErrorOrElse(
        userResult,
        (userData) => userData
            .filter((user) => user.isVerified)
            .map((user) => user.name)
            .map((name) => name.toUpperCase()),
      )
      .fold(
        onError: (e) => print('Error: $e'),
        onData: (name) => print('Processed name: ${name.orElse("UNKNOWN")}'),
      );
  // Expected: Processed name: EVE
}

void realWorldApiExample() {
  final apiResult = simulateApiCall('444');

  // Pattern 1: Using fold
  final greeting = apiResult.fold(
    onError: (error) => 'Could not load user: ${error.message}',
    onData: (userOption) => userOption.fold(
      onSome: (user) => 'Hello, ${user.name}!',
      onNone: () => 'No user found',
    ),
  );

  print('API response: $greeting');
  // Expected: API response: Hello, SimulatedUser!

  // Pattern 2: Transform and handle
  apiResult
      .mapError((error) => UserFacingException('Please try again later'))
      .fold(
        onError: (error) => print('UI Error: $error'),
        onData: (userOption) {
          userOption.fold(
            onSome: (user) => print('Display user: ${user.name}'),
            onNone: () => print('Show empty state'),
          );
        },
      );
  // Expected: Display user: SimulatedUser
}

void nullHandlingWithOptionsExample() {
  // Traditional nullable approach (avoid this)
  const String? nullableName = null;
  final traditionalResult = nullableName?.toUpperCase() ?? 'UNKNOWN';
  print('Traditional nullable: $traditionalResult');
  // Expected: Traditional nullable: UNKNOWN

  // Option approach (preferred)
  final nameOption = Option<String>.from(null);
  final optionResult = nameOption.map((n) => n.toUpperCase()).orElse('UNKNOWN');
  print('Option approach: $optionResult');
  // Expected: Option approach: UNKNOWN

  // Chaining operations safely
  final processedName = Option.from('alice')
      .filter((n) => n.length > 3)
      .map((n) => n.toUpperCase())
      .map((n) => 'User: $n')
      .orElse('Invalid name');

  print('Chained Option: $processedName\n');
  // Expected: Chained Option: User: ALICE
}

void workflowExample() {
  // Simulate: fetchUser → validateUser → createProfile
  final fetchResult = DC<NetworkException, User>.data(
    User('555', 'Frank', isVerified: true),
  );

  print('Step 1: Fetch user');
  fetchResult.fold(
    onError: (e) => print('   Failed: ${e.message}'),
    onData: (user) => print('   Fetched: ${user.tryMaybe()}'),
  );
  // Expected:
  //   Fetched: User(id: 555, name: Frank, verified: true)

  // Validate user is verified
  final validateResult = DC.forwardErrorOrElse(
    fetchResult,
    (userData) => userData.filter((user) => user.isVerified),
  );

  print('Step 2: Validate user');
  validateResult.fold(
    onError: (e) => print('   Failed: ${e.message}'),
    onData: (user) => user.fold(
      onSome: (u) => print('   Validated: ${u.name}'),
      onNone: () => print('   User not verified'),
    ),
  );
  // Expected:
  //   Validated: Frank

  // Create profile from validated user
  final profileResult = DC.forwardErrorOrElse(
    validateResult,
    (userData) =>
        userData.map((user) => Profile(user.id, 'Bio for ${user.name}')),
  );

  print('Step 3: Create profile');
  final finalMessage = profileResult.fold(
    onError: (e) => '   Failed: ${e.message}',
    onData: (profile) => profile.fold(
      onSome: (p) => '   Created: $p',
      onNone: () => '   Cannot create profile: user not verified',
    ),
  );

  print(finalMessage);
  // Expected:
  //   Created: Profile(userId: 555, bio: Bio for Frank)
}

DC<NetworkException, User> simulateApiCall(String id) {
  // Simulate successful API call
  return DC<NetworkException, User>.data(
    User(id, 'SimulatedUser', isVerified: true),
  );
}

/* ================= Starwars HTTP Example ================= */

class StarwarsResponse {
  StarwarsResponse({
    required this.character,
    required this.age,
  });

  factory StarwarsResponse.fromJson(Map<String, dynamic> json) {
    return StarwarsResponse(
      character: json['character'] as String,
      age: json['age'] as int,
    );
  }

  final String character;
  final int age;

  Map<String, dynamic> toJson() {
    return {
      'character': character,
      'age': age,
    };
  }

  @override
  String toString() => 'StarwarsResponse(character: $character, age: $age)';
}

class StarwarsDataSource {
  Future<DC<Exception, StarwarsResponse>> getStarwarsCharacters() async {
    try {
      final client = HttpClient();
      final uri = Uri.parse('https://starwars-api.com/characters');

      final request = await client.getUrl(uri);
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();

      if (response.statusCode != 200) {
        return DC.error(Exception('HTTP ${response.statusCode}'));
      }

      if (body.isEmpty) {
        return DC.nullData(); // Success but no data
      }

      final data = StarwarsResponse.fromJson(
        json.decode(body) as Map<String, dynamic>,
      );

      return DC.data(data);
    } on Exception catch (e) {
      return DC.error(e);
    }
  }
}

class StarwarsController {
  final _dataSource = StarwarsDataSource();

  Future<DC<Exception, StarwarsResponse>> getStarwarsCharacters() async {
    final result = await _dataSource.getStarwarsCharacters();

    // Transform errors to user-friendly messages
    return result.mapError(
      (error) => Exception('Failed to load Star Wars data: $error'),
    );
  }
}

Future<void> starwarsHttpExample() async {
  final controller = StarwarsController();
  final result = await controller.getStarwarsCharacters();

  final message = result.fold(
    onError: (error) => 'Error: $error',
    onData: (data) => data.fold(
      onSome: (character) =>
          'Character: ${character.character}, Age: ${character.age}',
      onNone: () => 'No characters found',
    ),
  );

  print(message);
  // Expected (if API call succeeds):
  //   Character: Luke Skywalker, Age: 19
  // Expected (if API call fails):
  //   Error: Exception: Failed to load Star Wars data: ...
}
