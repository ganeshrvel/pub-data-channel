// ignore_for_file: cascade_invocations

import 'package:data_channel/data_channel.dart';
import 'package:data_channel/src/option.dart';
import 'package:meta/meta.dart';
import 'package:test/test.dart';

// Mock classes for testing
@immutable
class User {
  const User(this.id, this.name, {this.isVerified = false});

  final String id;
  final String name;
  final bool isVerified;

  @override
  bool operator ==(Object other) =>
      other is User &&
      other.id == id &&
      other.name == name &&
      other.isVerified == isVerified;

  @override
  int get hashCode => Object.hash(id, name, isVerified);

  @override
  String toString() => 'User($id, $name, verified: $isVerified)';
}

@immutable
class Profile {
  const Profile(this.userId, this.bio);

  final String userId;
  final String bio;

  @override
  bool operator ==(Object other) =>
      other is Profile && other.userId == userId && other.bio == bio;

  @override
  int get hashCode => Object.hash(userId, bio);

  @override
  String toString() => 'Profile($userId, $bio)';
}

@immutable
class NetworkError {
  const NetworkError(this.message);

  final String message;

  @override
  bool operator ==(Object other) =>
      other is NetworkError && other.message == message;

  @override
  int get hashCode => message.hashCode;

  @override
  String toString() => 'NetworkError($message)';
}

@immutable
class ValidationError {
  const ValidationError(this.field);

  final String field;

  @override
  bool operator ==(Object other) =>
      other is ValidationError && other.field == field;

  @override
  int get hashCode => field.hashCode;

  @override
  String toString() => 'ValidationError($field)';
}

void main() {
  group('DC Constructors', () {
    test('DC.error creates DCError with error', () {
      final dc = DC<NetworkError, User>.error(const NetworkError('Failed'));

      expect(dc, isA<DCError<NetworkError, User>>());
      expect(dc.hasError, true);
      expect(dc.hasOptionalData, false);
    });

    test('DC.data creates DCData with Some value', () {
      const user = User('1', 'Alice');
      final dc = DC<NetworkError, User>.data(user);

      expect(dc, isA<DCData<NetworkError, User>>());
      expect(dc.hasError, false);
      expect(dc.hasOptionalData, true);
    });

    test('DC.nullData creates DCData with None', () {
      final dc = DC<NetworkError, User>.nullData();

      expect(dc, isA<DCData<NetworkError, User>>());
      expect(dc.hasError, false);
      expect(dc.hasOptionalData, true);
    });

    test('Type parameters are preserved correctly', () {
      final error = DC<NetworkError, User>.error(const NetworkError('Failed'));
      final data = DC<NetworkError, User>.data(const User('1', 'Alice'));
      final nullData = DC<NetworkError, User>.nullData();

      expect(error, isA<DC<NetworkError, User>>());
      expect(data, isA<DC<NetworkError, User>>());
      expect(nullData, isA<DC<NetworkError, User>>());
    });
  });

  group('DC State Checks - hasError', () {
    test('DCError.hasError returns true', () {
      final dc = DC<NetworkError, User>.error(const NetworkError('Failed'));

      expect(dc.hasError, true);
    });

    test('DCData.hasError returns false (with Some)', () {
      final dc = DC<NetworkError, User>.data(const User('1', 'Alice'));

      expect(dc.hasError, false);
    });

    test('DCData.hasError returns false (with None)', () {
      final dc = DC<NetworkError, User>.nullData();

      expect(dc.hasError, false);
    });
  });

  group('DC fold - Basic', () {
    test('DCError calls onError with error value', () {
      final dc = DC<NetworkError, User>.error(const NetworkError('Failed'));

      final result = dc.fold(
        onError: (e) => 'Error: ${e.message}',
        onData: (opt) => 'Data',
      );

      expect(result, 'Error: Failed');
    });

    test('DCData with Some calls onData with Some', () {
      final dc = DC<NetworkError, User>.data(const User('1', 'Alice'));

      final result = dc.fold(
        onError: (e) => 'Error',
        onData: (opt) => opt.fold(
          onSome: (u) => 'User: ${u.name}',
          onNone: () => 'No user',
        ),
      );

      expect(result, 'User: Alice');
    });

    test('DCData with None calls onData with None', () {
      final dc = DC<NetworkError, User>.nullData();

      final result = dc.fold(
        onError: (e) => 'Error',
        onData: (opt) => opt.fold(
          onSome: (u) => 'User: ${u.name}',
          onNone: () => 'No user',
        ),
      );

      expect(result, 'No user');
    });
  });

  group('DC fold - Type Transformation', () {
    test('fold can return different type (String → int)', () {
      final dc = DC<NetworkError, User>.data(const User('1', 'Alice'));

      final result = dc.fold(
        onError: (e) => -1,
        onData: (opt) => opt.fold(
          onSome: (u) => u.name.length,
          onNone: () => 0,
        ),
      );

      expect(result, 5);
      expect(result, isA<int>());
    });

    test('fold can return bool for validation', () {
      final success = DC<NetworkError, User>.data(const User('1', 'Alice'));
      final failure =
          DC<NetworkError, User>.error(const NetworkError('Failed'));

      expect(
        success.fold(onError: (_) => false, onData: (_) => true),
        true,
      );
      expect(
        failure.fold(onError: (_) => false, onData: (_) => true),
        false,
      );
    });
  });

  group('DC fold - Function Call Verification', () {
    test('DCError does NOT call onData', () {
      final dc = DC<NetworkError, User>.error(const NetworkError('Failed'));
      var onDataCalled = false;

      dc.fold(
        onError: (e) => 'Error',
        onData: (opt) {
          onDataCalled = true;
          return 'Data';
        },
      );

      expect(onDataCalled, false);
    });

    test('DCData does NOT call onError', () {
      final dc = DC<NetworkError, User>.data(const User('1', 'Alice'));
      var onErrorCalled = false;

      dc.fold(
        onError: (e) {
          onErrorCalled = true;
          return 'Error';
        },
        onData: (opt) => 'Data',
      );

      expect(onErrorCalled, false);
    });
  });

  group('DC fold - Accessing Inner Option', () {
    test('onData receives Option and can use Option methods', () {
      final dc = DC<NetworkError, User>.data(const User('1', 'Alice'));

      final result = dc.fold(
        onError: (e) => 'Error',
        onData: (opt) => opt
            .map((u) => u.name)
            .map((n) => n.toUpperCase())
            .orElse('Unknown'),
      );

      expect(result, 'ALICE');
    });

    test('onData can filter and handle None result', () {
      final dc = DC<NetworkError, User>.data(
        const User('1', 'Alice', isVerified: false),
      );

      final result = dc.fold(
        onError: (e) => 'Error',
        onData: (opt) => opt
            .filter((u) => u.isVerified)
            .map((u) => u.name)
            .orElse('Not verified'),
      );

      expect(result, 'Not verified');
    });
  });

  group('DC.forward - Error Propagation', () {
    test('DCError forwards error, ignores new data', () {
      final userResult =
          DC<NetworkError, User>.error(const NetworkError('Failed'));
      const profile = Profile('1', 'Bio');

      final result = DC.forward(userResult, profile);

      expect(result.hasError, true);
      expect(result.hasOptionalData, false);
      result.fold(
        onError: (e) => expect(e.message, 'Failed'),
        onData: (_) => fail('Should not have data'),
      );
    });

    test('DCError forward does NOT use new data value', () {
      final userResult =
          DC<NetworkError, User>.error(const NetworkError('Failed'));

      DC.forward(userResult, const User('999', 'NewUser')).fold(
            onError: (e) => expect(e, isA<NetworkError>()),
            onData: (opt) => fail('Should not have data'),
          );
    });
  });

  group('DC.forward - Success Transformation', () {
    test('DCData discards old data, creates new DCData with new value', () {
      final userResult = DC<NetworkError, User>.data(const User('1', 'Alice'));
      const profile = Profile('1', 'Software Developer');

      final result = DC.forward(userResult, profile);

      expect(result.hasError, false);
      expect(result.hasOptionalData, true);
      result.fold(
        onError: (_) => fail('Should not have error'),
        onData: (opt) {
          expect(opt.isSome, true);
          expect(opt.tryMaybe(), profile);
        },
      );
    });

    test('DCData.none() forwards to new DCData with Some', () {
      final userResult = DC<NetworkError, User>.nullData();
      const profile = Profile('1', 'Bio');

      final result = DC.forward(userResult, profile);

      expect(result.hasOptionalData, true);
      result.fold(
        onError: (_) => fail('Should not have error'),
        onData: (opt) {
          expect(opt.isSome, true);
          expect(opt.tryMaybe(), profile);
        },
      );
    });
  });

  group('DC.forward - Type Changes', () {
    test('forward changes Data type (User → Profile)', () {
      final userResult = DC<NetworkError, User>.data(const User('1', 'Alice'));
      const profile = Profile('1', 'Bio');

      final result =
          DC.forward<NetworkError, User, Profile>(userResult, profile);

      expect(result, isA<DC<NetworkError, Profile>>());
      result.fold(
        onError: (_) => fail('Should not have error'),
        onData: (opt) => expect(opt.tryMaybe(), isA<Profile>()),
      );
    });

    test('forward changes Data type (User → String)', () {
      final userResult = DC<NetworkError, User>.data(const User('1', 'Alice'));

      final result = DC.forward(userResult, 'Success message');

      expect(result, isA<DC<NetworkError, String>>());
      result.fold(
        onError: (_) => fail('Should not have error'),
        onData: (opt) => expect(opt.tryMaybe(), 'Success message'),
      );
    });
  });

  group('DC.forward - Chaining', () {
    test('chain multiple forward calls', () {
      final step1 = DC<NetworkError, User>.data(const User('1', 'Alice'));
      final step2 = DC.forward(step1, const Profile('1', 'Bio'));
      final step3 = DC.forward(step2, 'Final result');

      expect(step3.hasOptionalData, true);
      step3.fold(
        onError: (_) => fail('Should not have error'),
        onData: (opt) => expect(opt.tryMaybe(), 'Final result'),
      );
    });

    test('chain stops at first error', () {
      final step1 =
          DC<NetworkError, User>.error(const NetworkError('Failed at step 1'));
      final step2 = DC.forward(step1, const Profile('1', 'Bio'));
      final step3 = DC.forward(step2, 'Final result');

      expect(step3.hasError, true);
      step3.fold(
        onError: (e) => expect(e.message, 'Failed at step 1'),
        onData: (_) => fail('Should not have data'),
      );
    });
  });

  group('DC.forwardNull - Error Propagation', () {
    test('DCError forwards error', () {
      final userResult =
          DC<NetworkError, User>.error(const NetworkError('Failed'));

      final result = DC.forwardNull<NetworkError, User, Profile>(userResult);

      expect(result.hasError, true);
      result.fold(
        onError: (e) => expect(e.message, 'Failed'),
        onData: (_) => fail('Should not have data'),
      );
    });
  });

  group('DC.forwardNull - Success to Null', () {
    test('DCData with Some becomes DCData with None', () {
      final userResult = DC<NetworkError, User>.data(const User('1', 'Alice'));

      final result = DC.forwardNull<NetworkError, User, Profile>(userResult);

      expect(result.hasOptionalData, true);
      result.fold(
        onError: (_) => fail('Should not have error'),
        onData: (opt) {
          expect(opt.isNone, true);
          expect(opt.tryMaybe(), null);
        },
      );
    });

    test('DCData with None stays DCData with None', () {
      final userResult = DC<NetworkError, User>.nullData();

      final result = DC.forwardNull<NetworkError, User, Profile>(userResult);

      expect(result.hasOptionalData, true);
      result.fold(
        onError: (_) => fail('Should not have error'),
        onData: (opt) => expect(opt.isNone, true),
      );
    });
  });

  group('DC.forwardNull - Type Changes', () {
    test('forwardNull changes Data type parameter', () {
      final userResult = DC<NetworkError, User>.data(const User('1', 'Alice'));

      final result = DC.forwardNull<NetworkError, User, String>(userResult);

      expect(result, isA<DC<NetworkError, String>>());
      expect(result.hasOptionalData, true);
    });
  });

  group('DC.forwardOrElse - Error Propagation', () {
    test('DCError forwards error, builder NOT called', () {
      final userResult =
          DC<NetworkError, User>.error(const NetworkError('Failed'));
      var builderCalled = false;

      final result = DC.forwardOrElse<NetworkError, User, Profile>(
        userResult,
        (userData) {
          builderCalled = true;
          return const Some(Profile('1', 'Bio'));
        },
      );

      expect(result.hasError, true);
      expect(builderCalled, false);
    });
  });

  group('DC.forwardOrElse - Return Some Directly', () {
    test('builder returns Some(value)', () {
      final userResult = DC<NetworkError, User>.data(const User('1', 'Alice'));

      final result = DC.forwardOrElse(
        userResult,
        (_) => const Some(Profile('1', 'Default Bio')),
      );

      expect(result.hasOptionalData, true);
      result.fold(
        onError: (_) => fail('Should not have error'),
        onData: (opt) {
          expect(opt.isSome, true);
          expect(opt.tryMaybe()?.bio, 'Default Bio');
        },
      );
    });

    test('builder ignores input and returns fixed Some', () {
      final userResult = DC<NetworkError, User>.nullData();

      DC
          .forwardOrElse(
            userResult,
            (_) => const Some(Profile('999', 'Fallback')),
          )
          .fold(
            onError: (_) => fail('Should not have error'),
            onData: (opt) => expect(opt.tryMaybe()?.userId, '999'),
          );
    });
  });

  group('DC.forwardOrElse - Return None Directly', () {
    test('builder returns None explicitly', () {
      final userResult = DC<NetworkError, User>.data(const User('1', 'Alice'));

      final result = DC.forwardOrElse<NetworkError, User, Profile>(
        userResult,
        (_) => const None(),
      );

      expect(result.hasOptionalData, true);
      result.fold(
        onError: (_) => fail('Should not have error'),
        onData: (opt) {
          expect(opt.isNone, true);
          expect(opt.tryMaybe(), null);
        },
      );
    });
  });

  group('DC.forwardOrElse - Transform with map', () {
    test('builder uses option.map() to transform', () {
      final userResult = DC<NetworkError, User>.data(const User('1', 'Alice'));

      DC
          .forwardOrElse(
            userResult,
            (userData) => userData
                .map((user) => Profile(user.id, 'Bio for ${user.name}')),
          )
          .fold(
            onError: (_) => fail('Should not have error'),
            onData: (opt) {
              expect(opt.isSome, true);
              expect(opt.tryMaybe()?.bio, 'Bio for Alice');
            },
          );
    });

    test('builder map on None stays None', () {
      final userResult = DC<NetworkError, User>.nullData();

      DC
          .forwardOrElse(
            userResult,
            (userData) => userData.map((user) => Profile(user.id, user.name)),
          )
          .fold(
            onError: (_) => fail('Should not have error'),
            onData: (opt) => expect(opt.isNone, true),
          );
    });
  });

  group('DC.forwardOrElse - Filter with Validation', () {
    test('builder uses filter, passes validation', () {
      final userResult = DC<NetworkError, User>.data(
        const User('1', 'Alice', isVerified: true),
      );

      DC
          .forwardOrElse(
            userResult,
            (userData) => userData
                .filter((user) => user.isVerified)
                .map((user) => Profile(user.id, user.name)),
          )
          .fold(
            onError: (_) => fail('Should not have error'),
            onData: (opt) {
              expect(opt.isSome, true);
              expect(opt.tryMaybe()?.userId, '1');
            },
          );
    });

    test('builder uses filter, fails validation', () {
      final userResult = DC<NetworkError, User>.data(
        const User('1', 'Alice', isVerified: false),
      );

      final result = DC.forwardOrElse(
        userResult,
        (userData) => userData
            .filter((user) => user.isVerified)
            .map((user) => Profile(user.id, user.name)),
      );

      result.fold(
        onError: (_) => fail('Should not have error'),
        onData: (opt) => expect(opt.isNone, true),
      );
    });
  });

  group('DC.forwardOrElse - Fallback Chaining', () {
    test('builder uses map with orElse fallback (Some case)', () {
      final userResult = DC<NetworkError, User>.data(const User('1', 'Alice'));

      final result = DC.forwardOrElse(
        userResult,
        (userData) => Some(userData.map((user) => user.name).orElse('Guest')),
      );

      result.fold(
        onError: (_) => fail('Should not have error'),
        onData: (opt) => expect(opt.tryMaybe(), 'Alice'),
      );
    });

    test('builder uses map with orElse fallback (None case)', () {
      final userResult = DC<NetworkError, User>.nullData();

      final result = DC.forwardOrElse(
        userResult,
        (userData) => Some(userData.map((user) => user.name).orElse('Guest')),
      );

      result.fold(
        onError: (_) => fail('Should not have error'),
        onData: (opt) => expect(opt.tryMaybe(), 'Guest'),
      );
    });
  });

  group('DC.forwardOrElse - Type Transformations', () {
    test('User → Profile transformation', () {
      final userResult = DC<NetworkError, User>.data(const User('1', 'Alice'));

      final result = DC.forwardOrElse(
        userResult,
        (userData) => userData.map((user) => Profile(user.id, 'Bio')),
      );

      expect(result, isA<DC<NetworkError, Profile>>());
    });

    test('User → String transformation', () {
      final userResult = DC<NetworkError, User>.data(const User('1', 'Alice'));

      final result = DC.forwardOrElse(
        userResult,
        (userData) => userData.map((user) => user.name),
      );

      expect(result, isA<DC<NetworkError, String>>());
    });

    test('User → int transformation', () {
      final userResult = DC<NetworkError, User>.data(const User('1', 'Alice'));

      final result = DC.forwardOrElse(
        userResult,
        (userData) => userData.map((user) => user.name.length),
      );

      result.fold(
        onError: (_) => fail('Should not have error'),
        onData: (opt) => expect(opt.tryMaybe(), 5),
      );
    });
  });

  group('DC.mapError - Basic Error Mapping', () {
    test('DCError maps error to new error type', () {
      final dc =
          DC<NetworkError, User>.error(const NetworkError('Connection failed'));

      final result = dc.mapError((e) => ValidationError(e.message));

      expect(result, isA<DC<ValidationError, User>>());
      expect(result.hasError, true);
      result.fold(
        onError: (e) {
          expect(e, isA<ValidationError>());
          expect(e.field, 'Connection failed');
        },
        onData: (_) => fail('Should not have data'),
      );
    });

    test('DCError maps to different error value', () {
      final dc = DC<NetworkError, User>.error(const NetworkError('404'));

      final result =
          dc.mapError((e) => NetworkError('User friendly: ${e.message}'));

      result.fold(
        onError: (e) => expect(e.message, 'User friendly: 404'),
        onData: (_) => fail('Should not have data'),
      );
    });
  });

  group('DC.mapError - DCData Unchanged', () {
    test('DCData with Some - mapError preserves data', () {
      final dc = DC<NetworkError, User>.data(const User('1', 'Alice'));

      final result = dc.mapError((e) => ValidationError(e.message));

      expect(result, isA<DC<ValidationError, User>>());
      expect(result.hasOptionalData, true);
      result.fold(
        onError: (_) => fail('Should not have error'),
        onData: (opt) {
          expect(opt.isSome, true);
          expect(opt.tryMaybe()?.name, 'Alice');
        },
      );
    });

    test('DCData with None - mapError preserves None', () {
      final dc = DC<NetworkError, User>.nullData();

      final result = dc.mapError((e) => ValidationError(e.message));

      expect(result.hasOptionalData, true);
      result.fold(
        onError: (_) => fail('Should not have error'),
        onData: (opt) => expect(opt.isNone, true),
      );
    });

    test('DCData - mapError transform NOT called', () {
      final dc = DC<NetworkError, User>.data(const User('1', 'Alice'));
      var transformCalled = false;

      dc.mapError((e) {
        transformCalled = true;
        return ValidationError(e.message);
      });

      expect(transformCalled, false);
    });
  });

  group('DC.mapError - Error Type Transformation', () {
    test('NetworkError → ValidationError', () {
      final dc = DC<NetworkError, User>.error(const NetworkError('Failed'));

      final result = dc.mapError((e) => const ValidationError('network'));

      expect(result, isA<DC<ValidationError, User>>());
    });

    test('NetworkError → String', () {
      final dc = DC<NetworkError, User>.error(const NetworkError('Failed'));

      final result = dc.mapError((e) => 'Error: ${e.message}');

      expect(result, isA<DC<String, User>>());
      result.fold(
        onError: (e) => expect(e, 'Error: Failed'),
        onData: (_) => fail('Should not have data'),
      );
    });
  });

  group('DC.mapError - Chaining', () {
    test('chain multiple mapError calls', () {
      final dc = DC<NetworkError, User>.error(const NetworkError('404'));

      final result = dc
          .mapError((e) => 'Network: ${e.message}')
          .mapError((e) => 'Processed: $e')
          .mapError((e) => e.toUpperCase());

      result.fold(
        onError: (e) => expect(e, 'PROCESSED: NETWORK: 404'),
        onData: (_) => fail('Should not have data'),
      );
    });

    test('mapError after forward preserves error', () {
      final step1 = DC<NetworkError, User>.error(const NetworkError('Failed'));
      final step2 = DC.forward(step1, const Profile('1', 'Bio'));
      final step3 = step2.mapError((e) => ValidationError(e.message));

      expect(step3.hasError, true);
      step3.fold(
        onError: (e) => expect(e.field, 'Failed'),
        onData: (_) => fail('Should not have data'),
      );
    });
  });

  group('Complex Workflows - Error Path End-to-End', () {
    test('error → forward → forwardOrElse → fold (stays error)', () {
      final step1 =
          DC<NetworkError, User>.error(const NetworkError('Initial error'));
      final step2 = DC.forward(step1, const Profile('1', 'Bio'));
      final step3 = DC.forwardOrElse(
        step2,
        (data) => data.map((p) => p.bio),
      );

      final result = step3.fold(
        onError: (e) => 'Error: ${e.message}',
        onData: (opt) => 'Success: ${opt.tryMaybe()}',
      );

      expect(result, 'Error: Initial error');
    });

    test('error → mapError → forward → fold', () {
      final step1 =
          DC<NetworkError, User>.error(const NetworkError('Network issue'));
      final step2 = step1.mapError((e) => ValidationError(e.message));
      final step3 = DC.forward(step2, 'Some data');

      step3.fold(
        onError: (e) {
          expect(e, isA<ValidationError>());
          expect(e.field, 'Network issue');
        },
        onData: (_) => fail('Should not have data'),
      );
    });
  });

  group('Complex Workflows - Success Path End-to-End', () {
    test('data → forward → forwardOrElse → fold (transforms data)', () {
      final step1 = DC<NetworkError, User>.data(const User('1', 'Alice'));
      final step2 = DC.forward(step1, const Profile('1', 'Software Developer'));
      final step3 = DC.forwardOrElse(
        step2,
        (profileOpt) => profileOpt.map((p) => 'Bio: ${p.bio}'),
      );

      final result = step3.fold(
        onError: (e) => 'Error',
        onData: (opt) => opt.orElse('No bio'),
      );

      expect(result, 'Bio: Software Developer');
    });

    test('data → forwardOrElse with map → forward → fold', () {
      final step1 = DC<NetworkError, User>.data(const User('1', 'Alice'));
      final step2 = DC.forwardOrElse(
        step1,
        (userOpt) => userOpt.map((u) => Profile(u.id, u.name)),
      );
      final step3 = DC.forward(step2, 'Final result');

      final result = step3.fold(
        onError: (_) => 'Error',
        onData: (opt) => opt.orElse('No result'),
      );

      expect(result, 'Final result');
    });
  });

  group('Complex Workflows - Mixed Scenarios', () {
    test('forwardOrElse filter fails, then forward continues with None', () {
      final step1 = DC<NetworkError, User>.data(
        const User('1', 'Alice', isVerified: false),
      );
      final step2 = DC.forwardOrElse(
        step1,
        (userOpt) => userOpt
            .filter((u) => u.isVerified)
            .map((u) => Profile(u.id, u.name)),
      );
      final step3 = DC.forward(step2, 'Completed');

      final result = step3.fold(
        onError: (_) => 'Error',
        onData: (opt) => opt.orElse('No data'),
      );

      expect(result, 'Completed');
    });

    test('nullData → forwardOrElse with fallback → fold', () {
      final step1 = DC<NetworkError, User>.nullData();
      final step2 = DC.forwardOrElse(
        step1,
        (userOpt) => Some(
          userOpt.map((u) => u.name).orElse('Guest User'),
        ),
      );

      final result = step2.fold(
        onError: (_) => 'Error',
        onData: (opt) => opt.orElse('Fallback'),
      );

      expect(result, 'Guest User');
    });
  });

  group('Complex Workflows - Real-world Simulation', () {
    test('fetchUser → validateUser → createProfile flow (success)', () {
      // Simulate API response
      final fetchResult = DC<NetworkError, User>.data(
        const User('1', 'Alice', isVerified: true),
      );

      // Validate user is verified
      final validateResult = DC.forwardOrElse(
        fetchResult,
        (userOpt) => userOpt.filter((u) => u.isVerified),
      );

      // Create profile from validated user
      final profileResult = DC.forwardOrElse(
        validateResult,
        (userOpt) => userOpt.map((u) => Profile(u.id, 'Bio for ${u.name}')),
      );

      final result = profileResult.fold(
        onError: (e) => 'Failed: ${e.message}',
        onData: (opt) => opt.fold(
          onSome: (p) => 'Created profile for ${p.userId}',
          onNone: () => 'User not verified',
        ),
      );

      expect(result, 'Created profile for 1');
    });

    test('fetchUser → validateUser → createProfile flow (validation fails)',
        () {
      final fetchResult = DC<NetworkError, User>.data(
        const User('1', 'Alice', isVerified: false),
      );

      final validateResult = DC.forwardOrElse(
        fetchResult,
        (userOpt) => userOpt.filter((u) => u.isVerified),
      );

      final profileResult = DC.forwardOrElse(
        validateResult,
        (userOpt) => userOpt.map((u) => Profile(u.id, 'Bio for ${u.name}')),
      );

      final result = profileResult.fold(
        onError: (e) => 'Failed: ${e.message}',
        onData: (opt) => opt.fold(
          onSome: (p) => 'Created profile for ${p.userId}',
          onNone: () => 'User not verified',
        ),
      );

      expect(result, 'User not verified');
    });

    test('fetchUser → validateUser → createProfile flow (network error)', () {
      final fetchResult = DC<NetworkError, User>.error(
        const NetworkError('Connection timeout'),
      );

      final validateResult = DC.forwardOrElse(
        fetchResult,
        (userOpt) => userOpt.filter((u) => u.isVerified),
      );

      final profileResult = DC.forwardOrElse(
        validateResult,
        (userOpt) => userOpt.map((u) => Profile(u.id, 'Bio for ${u.name}')),
      );

      final result = profileResult.fold(
        onError: (e) => 'Failed: ${e.message}',
        onData: (opt) => opt.fold(
          onSome: (p) => 'Created profile for ${p.userId}',
          onNone: () => 'User not verified',
        ),
      );

      expect(result, 'Failed: Connection timeout');
    });
  });

  group('Complex Workflows - Short-circuiting', () {
    test('error short-circuits all builder functions', () {
      final step1 = DC<NetworkError, User>.error(const NetworkError('Failed'));
      var builder1Called = false;
      var builder2Called = false;
      var builder3Called = false;

      final step2 = DC.forwardOrElse(step1, (opt) {
        builder1Called = true;
        return opt.map((u) => Profile(u.id, u.name));
      });

      final step3 = DC.forwardOrElse(step2, (opt) {
        builder2Called = true;
        return opt.map((p) => p.bio);
      });

      final step4 = DC.forwardOrElse(step3, (opt) {
        builder3Called = true;
        return opt.map((bio) => bio.toUpperCase());
      });

      step4.fold(
        onError: (_) {},
        onData: (_) => fail('Should not have data'),
      );

      expect(builder1Called, false);
      expect(builder2Called, false);
      expect(builder3Called, false);
    });

    test('success executes all builders until filter fails', () {
      final step1 = DC<NetworkError, User>.data(
        const User('1', 'Alice', isVerified: true),
      );
      var builder1Called = false;
      var builder2Called = false;

      final step2 = DC.forwardOrElse(step1, (opt) {
        builder1Called = true;
        return opt.filter((u) => u.isVerified);
      });

      final step3 = DC.forwardOrElse(step2, (opt) {
        builder2Called = true;
        return opt.filter((u) => u.name.length > 10); // This fails
      });

      step3.fold(
        onError: (_) => fail('Should not have error'),
        onData: (_) {},
      );

      expect(builder1Called, true);
      expect(builder2Called, true);
    });
  });

  group('Edge Cases - Nullable Data', () {
    test('DCData with Some(null) when Data type is nullable', () {
      final dc = DC<NetworkError, String?>.data(null);

      expect(dc.hasOptionalData, true);
      dc.fold(
        onError: (_) => fail('Should not have error'),
        onData: (opt) {
          expect(opt.isSome, true);
          expect(opt.tryMaybe(), null);
        },
      );
    });

    test('Operations on DCData with Some(null)', () {
      final dc = DC<NetworkError, int?>.data(null);

      final result = DC.forwardOrElse(
        dc,
        (opt) => opt.map((value) => value == null ? 0 : value * 2),
      );

      result.fold(
        onError: (_) => fail('Should not have error'),
        onData: (opt) => expect(opt.tryMaybe(), 0),
      );
    });
  });

  group('Edge Cases - Same Type Forward', () {
    test('forward with same User type', () {
      final dc = DC<NetworkError, User>.data(const User('1', 'Alice'));
      const newUser = User('2', 'Bob');

      final result = DC.forward(dc, newUser);

      result.fold(
        onError: (_) => fail('Should not have error'),
        onData: (opt) => expect(opt.tryMaybe()?.id, '2'),
      );
    });
  });

  group('Edge Cases - Identity Operations', () {
    test('mapError with identity function', () {
      final dc = DC<NetworkError, User>.error(const NetworkError('Failed'));

      final result = dc.mapError((e) => e);

      result.fold(
        onError: (e) => expect(e.message, 'Failed'),
        onData: (_) => fail('Should not have data'),
      );
    });

    test('forwardOrElse with identity transform', () {
      final dc = DC<NetworkError, User>.data(const User('1', 'Alice'));

      final result = DC.forwardOrElse(dc, (opt) => opt);

      result.fold(
        onError: (_) => fail('Should not have error'),
        onData: (opt) => expect(opt.tryMaybe()?.name, 'Alice'),
      );
    });
  });

  group('Edge Cases - Empty Transformations', () {
    test('forwardOrElse that always returns None', () {
      final dc = DC<NetworkError, User>.data(const User('1', 'Alice'));

      final result = DC.forwardOrElse<NetworkError, User, String>(
        dc,
        (_) => const None(),
      );

      result.fold(
        onError: (_) => fail('Should not have error'),
        onData: (opt) => expect(opt.isNone, true),
      );
    });

    test('forwardOrElse with filter that always fails', () {
      final dc = DC<NetworkError, User>.data(const User('1', 'Alice'));

      final result = DC.forwardOrElse(
        dc,
        (opt) => opt.filter((_) => false),
      );

      result.fold(
        onError: (_) => fail('Should not have error'),
        onData: (opt) => expect(opt.isNone, true),
      );
    });
  });

  group('Equality', () {
    test('DCError equality - same error values equal', () {
      final dc1 = DC<NetworkError, User>.error(const NetworkError('Failed'));
      final dc2 = DC<NetworkError, User>.error(const NetworkError('Failed'));

      expect(dc1, equals(dc2));
      expect(dc1 == dc2, true);
    });

    test('DCError equality - different error values not equal', () {
      final dc1 = DC<NetworkError, User>.error(const NetworkError('Failed'));
      final dc2 = DC<NetworkError, User>.error(const NetworkError('Success'));

      expect(dc1 == dc2, false);
    });

    test('DCData equality - same Some values equal', () {
      const user = User('1', 'Alice');
      final dc1 = DC<NetworkError, User>.data(user);
      final dc2 = DC<NetworkError, User>.data(user);

      expect(dc1, equals(dc2));
    });

    test('DCData equality - different Some values not equal', () {
      final dc1 = DC<NetworkError, User>.data(const User('1', 'Alice'));
      final dc2 = DC<NetworkError, User>.data(const User('2', 'Bob'));

      expect(dc1 == dc2, false);
    });

    test('DCData equality - two None values equal', () {
      final dc1 = DC<NetworkError, User>.nullData();
      final dc2 = DC<NetworkError, User>.nullData();

      expect(dc1, equals(dc2));
    });

    test('DCError and DCData not equal', () {
      final error = DC<NetworkError, User>.error(const NetworkError('Failed'));
      final data = DC<NetworkError, User>.data(const User('1', 'Alice'));

      expect(error == data, false);
    });
  });

  group('toString', () {
    test('DCError displays error', () {
      final dc = DC<NetworkError, User>.error(const NetworkError('Failed'));

      expect(dc.toString(), contains('DCError'));
      expect(dc.toString(), contains('NetworkError'));
    });

    test('DCData with Some displays data', () {
      final dc = DC<NetworkError, User>.data(const User('1', 'Alice'));

      expect(dc.toString(), contains('DCData'));
      expect(dc.toString(), contains('Some'));
    });

    test('DCData with None displays correctly', () {
      final dc = DC<NetworkError, User>.nullData();

      expect(dc.toString(), 'DCData(None)');
    });
  });

  group('Type Safety Verification', () {
    test('fold ensures exhaustive handling', () {
      final dc = DC<NetworkError, User>.data(const User('1', 'Alice'));

      // This compiles, proving both branches are required
      final result = dc.fold(
        onError: (e) => 'Error',
        onData: (opt) => 'Data',
      );

      expect(result, isA<String>());
    });

    test('Generic type preservation through operations', () {
      final dc1 = DC<NetworkError, User>.data(const User('1', 'Alice'));

      expect(dc1, isA<DC<NetworkError, User>>());

      final dc2 = DC.forward(dc1, const Profile('1', 'Bio'));
      expect(dc2, isA<DC<NetworkError, Profile>>());

      final dc3 = dc2.mapError((e) => ValidationError(e.message));
      expect(dc3, isA<DC<ValidationError, Profile>>());
    });

    test('Static method type inference works correctly', () {
      final step1 = DC<NetworkError, User>.data(const User('1', 'Alice'));

      // Type inference should work without explicit type parameters
      final step2 = DC.forward(step1, 'Success');
      expect(step2, isA<DC<NetworkError, String>>());

      final step3 = DC.forwardNull<NetworkError, User, String>(step1);
      expect(step3, isA<DC<NetworkError, String>>());
    });
  });

  group('Integration with Option', () {
    test('DCData contains Option - verify Option methods work', () {
      DC<NetworkError, User>.data(const User('1', 'Alice')).fold(
        onError: (_) => fail('Should not have error'),
        onData: (opt) {
          final mapped = opt.map((u) => u.name);
          expect(mapped.tryMaybe(), 'Alice');

          final filtered = opt.filter((u) => u.name.length > 3);
          expect(filtered.isSome, true);

          final flatMapped = opt.flatMap((u) => Some(u.id));
          expect(flatMapped.tryMaybe(), '1');
        },
      );
    });

    test('Nested transformations - DC fold → Option fold chains', () {
      final dc = DC<NetworkError, User>.data(const User('1', 'Alice'));

      final result = dc.fold(
        onError: (e) => 'Error: ${e.message}',
        onData: (opt) => opt.fold(
          onSome: (u) => 'User: ${u.name}',
          onNone: () => 'No user',
        ),
      );

      expect(result, 'User: Alice');
    });

    test('Option operations in forwardOrElse - chaining map, filter, orElse',
        () {
      final dc = DC<NetworkError, User>.data(
        const User('1', 'Alice', isVerified: true),
      );

      DC
          .forwardOrElse(
            dc,
            (userOpt) => Some(
              userOpt
                  .filter((u) => u.isVerified)
                  .map((u) => u.name.toUpperCase())
                  .orElse('GUEST'),
            ),
          )
          .fold(
            onError: (_) => fail('Should not have error'),
            onData: (opt) => expect(opt.tryMaybe(), 'ALICE'),
          );
    });

    test('forwardOrElse with complex Option chain', () {
      final dc =
          DC<NetworkError, User>.data(const User('1', 'A', isVerified: false));

      DC
          .forwardOrElse(
            dc,
            (userOpt) => userOpt
                .filter((u) => u.isVerified)
                .flatMap<String>(
                  (u) =>
                      u.name.length > 2 ? Some(u.name) : const None<String>(),
                )
                .map((name) => name.toUpperCase()),
          )
          .fold(
            onError: (_) => fail('Should not have error'),
            onData: (opt) => expect(opt.isNone, true),
          );
    });
  });
}
