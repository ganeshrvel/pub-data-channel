### Introduction

##### Data Channel for Dart and Flutter.

**data_channel** (DC) is a lightweight, type-safe utility for exception handling and null safety in
Dart applications. Rather than cluttering your code with try-catch blocks and null checks,
`data_channel` provides a clean, composable way to handle errors, data, and optional values.

**Core Concepts:**

- **DC (Data Channel)** - Represents either an error or optional data (similar to Result/Either
  types)
- **Option** - Represents presence (Some) or absence (None) of a value (eliminates nullable types)
- **Type Safety** - Explicit error and data types in your function signatures
- **Composability** - Chain operations without repetitive error/null checking

### Prerequisites

**Breaking Changes in 4.0.0:**

- Complete API redesign with Option type
- Requires Dart 3.0+ for sealed class support

**What version to use**

- Use `data_channel` 4.0.0 and above if you have **Dart SDK >= 3.0.0**
- Use `data_channel` 3.0.0+2 and below if you have **Dart SDK >= 2.12.0**

### Installation

Visit https://pub.dev/packages/data_channel#-installing-tab- for the latest version of *
*data_channel**

---

## API Reference

### Data Channel (DC) API

#### Constructors

- **`DC.error(error)`** - Creates a DC containing an error
- **`DC.data(data)`** - Creates a DC containing data (as Some)
- **`DC.nullData()`** - Creates a DC with no data (as None)

#### Instance Methods

- **`hasError`** - Returns true if this is a DCError
- **`hasOptionalData`** - Returns true if this is DCData (with Some or None), false if DCError
    - Note: To check if actual data is present, use the Option's `isSome`/`isNone` methods
- **`fold<U>({onError, onData})`** - Pattern match on error or data, returning a value
- **`mapError<NewErr>(transform)`** - Transform the error type while preserving data

#### Static Methods

- **`DC.forwardErrorOr(dc, newData)`** - Forward error if present, otherwise create new DCData with
  provided data
- **`DC.forwardErrorOrNull(dc)`** - Forward error if present, otherwise create DCData with None
- **`DC.forwardErrorOrElse(dc, builder)`** - Forward error if present, otherwise transform data using
  Option methods

### Option API

The `Option<T>` type represents optional values and is used within `DCData` to hold the actual data.

#### Constructors

- **`Some(value)`** - Creates an Option containing a value
- **`None()`** - Creates an empty Option
- **`Option.from(nullable)`** - Creates Some if non-null, None otherwise

#### Instance Methods

- **`isSome`** - Returns true if contains a value
- **`isNone`** - Returns true if empty
- **`tryMaybe()`** - Returns the value or null
- **`orElse(defaultValue)`** - Returns the value or a default
- **`orElseGet(getDefault)`** - Returns the value or computes a default (lazy)
- **`map<U>(transform)`** - Transform the contained value
- **`flatMap<U>(transform)`** - Transform and flatten nested Options
- **`filter(predicate)`** - Returns None if predicate fails
- **`fold<U>({onSome, onNone})`** - Pattern match on Some or None

#### Type Aliases

- **`DCOption<T>`** - Alias for `Option<T>`
- **`DCSome<T>`** - Alias for `Some<T>`
- **`DCNone<T>`** - Alias for `None<T>`

---

## Examples

### Basic Usage

Return either error or data from any method:

```dart
import 'package:data_channel/data_channel.dart';

Future<DC<Exception, LoginModel>> getSomeLoginData() async {
  try {
    return DC<Exception, LoginModel>.data(someData);
  } on Exception catch (e) {
    return DC<Exception, LoginModel>.error(e);
  }
}
```

Check for errors in the calling code:

```dart
void doSomething() async {
  final value = await getSomeLoginData();

  if (value.hasError) {
    // handle error case
  } else if (value.hasOptionalData) {
    // handle success case - but data might be None!
    // Use fold or access .data to check Option
  }
}
```

### Using DC.fold

Handle both cases exhaustively with a clean functional approach:

```dart

final message = result.fold(
  onError: (error) => 'Operation failed: $error',
  onData: (dataOption) =>
      dataOption.fold(
        onSome: (data) => 'Success: $data',
        onNone: () => 'No data available',
      ),
);

// Use in widget building
final widget = result.fold(
  onError: (error) => ErrorWidget(error),
  onData: (dataOption) =>
      dataOption.fold(
        onSome: (data) => SuccessView(data),
        onNone: () => EmptyStateWidget(),
      ),
);
```

### DC.forwardErrorOr - Propagate Errors

Eliminate redundant error checks when transforming data models. `DC.forwardErrorOr` automatically
propagates errors while allowing you to transform successful data:

```dart
Future<DC<Exception, UserModel>> checkSomethingAndReturn() async {
  final loginData = await getSomeLoginData();

  // If loginData has error, it's forwarded automatically
  // If loginData has success, old data is discarded and new UserModel is wrapped
  return DC.forwardErrorOr(
    loginData,
    UserModel(id: 'some-id'),
  );
}
```

### DC.forwardErrorOrNull - Propagate Errors, Discard Data

When you want to acknowledge success but don't need to return data:

```dart
Future<DC<Exception, void>> deleteUser(String id) async {
  final result = await apiDeleteUser(id);

  // Forward error if present, otherwise return success with no data
  return DC.forwardErrorOrNull(result);
}
```

### DC.forwardErrorOrElse - Transform with Option Methods

The most powerful forwarding method - use Option transformations on the data:

```dart
Future<DC<Exception, Profile>> createProfile() async {
  final userResult = await fetchUser();

  // Return Some directly
  return DC.forwardErrorOrElse(
    userResult,
        (_) => Some(Profile.defaultProfile()),
  );
}

// Transform the data
Future<DC<Exception, String>> getUserName() async {
  final userResult = await fetchUser();

  return DC.forwardErrorOrElse(
    userResult,
        (userData) => userData.map((user) => user.name),
  );
}

// Filter with validation
Future<DC<Exception, User>> getVerifiedUser() async {
  final userResult = await fetchUser();

  return DC.forwardErrorOrElse(
    userResult,
        (userData) => userData.filter((user) => user.isVerified),
  );
}

// Provide fallback
Future<DC<Exception, String>> getDisplayName() async {
  final userResult = await fetchUser();

  return DC.forwardErrorOrElse(
    userResult,
        (userData) => Some(userData.map((user) => user.name).orElse('Guest')),
  );
}
```

### DC.mapError - Transform Errors

Transform error types while preserving data:

```dart
// Convert technical errors to user-friendly messages
final userFriendly = apiResult.mapError(
      (error) => UserFacingException(error.message),
);

// Chain error transformations
final logged = apiResult
    .mapError((e) => logError(e))
    .mapError((e) => UserFacingException(e.message));
```

### Working with Option Inside DCData

When you have `DCData`, you can work with the inner `Option`:

```dart
void main() {
  final result = await getUserData();

  result.fold(
    onError: (e) => print('Error: $e'),
    onData: (userOption) {
      // userOption is Option

      // Check if data exists
      if (userOption.isSome) {
        final user = userOption.tryMaybe()!;
        print('User: ${user.name}');
      }

      // Or use Option methods
      final name = userOption
          .map((user) => user.name)
          .orElse('Anonymous');

      // Or use fold
      userOption.fold(
        onSome: (user) => print('Found: ${user.name}'),
        onNone: () => print('No user data'),
      );
    },
  );
}
```

### Example: HTTP API with DC

Return data or error from an API call without leaking try-catch everywhere:

```dart
import 'dart:convert';
import 'package:data_channel/data_channel.dart';
import 'package:http/http.dart' as http;

Future<DC<Exception, StarwarsResponse>> getStarwarsCharacters() async {
  try {
    final response = await http.get(
      Uri.parse('https://starwars-api.com/characters'),
    );

    if (response.statusCode != 200) {
      return DC.error(Exception('HTTP ${response.statusCode}'));
    }

    if (response.body.isEmpty) {
      return DC.nullData(); // Success but no data
    }

    final data = StarwarsResponse.fromJson(
      json.decode(response.body) as Map<String, dynamic>,
    );

    return DC.data(data);
  } on Exception catch (e) {
    return DC.error(e);
  }
}
```

### Example: Consuming the API Result

```dart
void loadCharacters() async {
  final result = await getStarwarsCharacters();

  final message = result.fold(
    onError: (error) => 'Failed to load: $error',
    onData: (characters) =>
        characters.fold(
          onSome: (data) => 'Loaded ${data.count} characters',
          onNone: () => 'No characters found',
        ),
  );

  print(message);
}
```

### Example: Chaining Operations

Build complex workflows by chaining DC operations:

```dart
void main() {
  Future<DC> loadUserProfile(String userId) async {
    // Step 1: Fetch user
    final userResult = await fetchUser(userId);

    // Step 2: Validate user is verified, forward error if any
    final verifiedUserResult = DC.forwardErrorOrElse(
      userResult,
          (userData) => userData.filter((user) => user.isVerified),
    );

    // Step 3: Load profile data, forward error if any
    final profileResult = DC.forwardErrorOrElse(
      verifiedUserResult,
          (userData) => userData.map((user) => user.profileId),
    );

    // Step 4: Transform to view model
    return DC.forwardErrorOrElse(
      profileResult,
          (profileIdOption) =>
          profileIdOption.map(
                (profileId) => ProfileView(id: profileId, verified: true),
          ),
    );
  }

  // Use it
  final result = await loadUserProfile('123');

  result.fold(
    onError: (e) => showError('Could not load profile: $e'),
    onData: (profileView) =>
        profileView.fold(
          onSome: (view) => showProfile(view),
          onNone: () => showMessage('User not verified'),
        ),
  );
}
```

### Example: Flutter Widget

```dart
class UserProfileWidget extends StatelessWidget {
  final DC<Exception, User> userResult;

  const UserProfileWidget({required this.userResult});

  @override
  Widget build(BuildContext context) {
    return userResult.fold(
      onError: (error) =>
          ErrorCard(
            message: 'Failed to load user',
            error: error,
          ),
      onData: (userData) =>
          userData.fold(
            onSome: (user) =>
                UserCard(
                  name: user.name,
                  email: user.email,
                  verified: user.isVerified,
                ),
            onNone: () =>
            const EmptyStateCard(
              message: 'No user data available',
            ),
          ),
    );
  }
}
```

### Example: Option Standalone Usage

You can also use `Option` independently for nullable value handling:

```dart
import 'package:data_channel/data_channel.dart';

// Create Options
final some = Some(42);
final none = None<int>();
final fromNullable = Option.from(possiblyNullValue);

// Transform values
final doubled = some.map((x) => x * 2); // Some(84)
final noneDoubled = none.map((x) => x * 2); // None()

// Provide defaults
final value1 = some.orElse(0); // 42
final value2 = none.orElse(0); // 0

// Filter
final evenOnly = some.filter((x) => x.isEven); // Some(42)
final oddOnly = some.filter((x) => x.isOdd); // None()

// Chain operations
final result = Option.from(user)
    .filter((u) => u.isActive)
    .map((u) => u.email)
    .map((e) => e.toLowerCase())
    .orElse('no-email@example.com');

// Pattern matching
final message = option.fold(
  onSome: (value) => 'Got: $value',
  onNone: () => 'Nothing here',
);
```

---

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
