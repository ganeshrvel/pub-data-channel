import 'package:data_channel/data_channel.dart';
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
  group('DCRequired Constructors', () {
    test('DCRequired.error creates DCRequiredError with error', () {
      const dc = DCRequired<NetworkError, User>.error(NetworkError('Failed'));

      expect(dc, isA<DCRequiredError<NetworkError, User>>());
      expect(dc.hasError, true);
    });

    test('DCRequired.data creates DCRequiredData with value', () {
      const user = User('1', 'Alice');
      const dc = DCRequired<NetworkError, User>.data(user);

      expect(dc, isA<DCRequiredData<NetworkError, User>>());
      expect(dc.hasError, false);
      dc.fold(
        onError: (_) => fail('Should not have error'),
        onData: (u) => expect(u, user),
      );
    });

    test('DCRequiredError and DCRequiredData can be const', () {
      const error1 =
          DCRequiredError<NetworkError, User>(NetworkError('Failed'));
      const error2 =
          DCRequiredError<NetworkError, User>(NetworkError('Failed'));
      const data1 = DCRequiredData<NetworkError, User>(User('1', 'Alice'));
      const data2 = DCRequiredData<NetworkError, User>(User('1', 'Alice'));

      expect(identical(error1, error2), true);
      expect(identical(data1, data2), true);
    });

    test('Type parameters are preserved correctly', () {
      const error =
          DCRequired<NetworkError, User>.error(NetworkError('Failed'));
      const data = DCRequired<NetworkError, User>.data(User('1', 'Alice'));

      expect(error, isA<DCRequired<NetworkError, User>>());
      expect(data, isA<DCRequired<NetworkError, User>>());
    });
  });

  group('DCRequired Non-Nullable Constraint Tests', () {
    test('DCRequiredData exposes the value without unwrapping', () {
      const dc = DCRequiredData<NetworkError, User>(User('1', 'Alice'));

      expect(dc.value.name.length, 5); // No null check or unwrap needed
    });

    test('pattern matching gives the value directly', () {
      const dc = DCRequired<NetworkError, User>.data(User('1', 'Alice'));

      switch (dc) {
        case DCRequiredError():
          fail('Should not have error');
        case DCRequiredData(:final value):
          expect(value.name, 'Alice');
      }
    });

    test('pattern matching reads the error from DCRequiredError', () {
      const dc = DCRequired<NetworkError, User>.error(NetworkError('Failed'));

      switch (dc) {
        case DCRequiredError(:final error):
          expect(error.message, 'Failed');
        case DCRequiredData():
          fail('Should not have data');
      }
    });
  });

  group('DCRequired State Checks - hasError', () {
    test('DCRequiredError.hasError returns true', () {
      const dc = DCRequired<NetworkError, User>.error(NetworkError('Failed'));

      expect(dc.hasError, true);
    });

    test('DCRequiredData.hasError returns false', () {
      const dc = DCRequired<NetworkError, User>.data(User('1', 'Alice'));

      expect(dc.hasError, false);
    });
  });

  group('DCRequired fold - Basic', () {
    test('DCRequiredError calls onError with error value', () {
      const dc = DCRequired<NetworkError, User>.error(NetworkError('Failed'));

      final result = dc.fold(
        onError: (e) => 'Error: ${e.message}',
        onData: (u) => 'User: ${u.name}',
      );

      expect(result, 'Error: Failed');
    });

    test('DCRequiredData calls onData with the value', () {
      const dc = DCRequired<NetworkError, User>.data(User('1', 'Alice'));

      final result = dc.fold(
        onError: (e) => 'Error: ${e.message}',
        onData: (u) => 'User: ${u.name}',
      );

      expect(result, 'User: Alice');
    });
  });

  group('DCRequired fold - Type Transformation', () {
    test('fold can return different type (User → int)', () {
      const dc = DCRequired<NetworkError, User>.data(User('1', 'Alice'));

      final result = dc.fold(
        onError: (e) => -1,
        onData: (u) => u.name.length,
      );

      expect(result, 5);
      expect(result, isA<int>());
    });

    test('fold can return bool for validation', () {
      const success = DCRequired<NetworkError, User>.data(User('1', 'Alice'));
      const failure =
          DCRequired<NetworkError, User>.error(NetworkError('Failed'));

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

  group('DCRequired fold - Function Call Verification', () {
    test('DCRequiredError does NOT call onData', () {
      const dc = DCRequired<NetworkError, User>.error(NetworkError('Failed'));
      var onDataCalled = false;

      dc.fold(
        onError: (e) => 'Error',
        onData: (u) {
          onDataCalled = true;
          return 'Data';
        },
      );

      expect(onDataCalled, false);
    });

    test('DCRequiredData does NOT call onError', () {
      const dc = DCRequired<NetworkError, User>.data(User('1', 'Alice'));
      var onErrorCalled = false;

      dc.fold(
        onError: (e) {
          onErrorCalled = true;
          return 'Error';
        },
        onData: (u) => 'Data',
      );

      expect(onErrorCalled, false);
    });
  });

  group('DCRequired.forwardErrorOr - Error Propagation', () {
    test('DCRequiredError forwards error, ignores new data', () {
      const userResult =
          DCRequired<NetworkError, User>.error(NetworkError('Failed'));
      const profile = Profile('1', 'Bio');

      final result = DCRequired.forwardErrorOr(userResult, profile);

      expect(result, isA<DC<NetworkError, Profile>>());
      expect(result.hasError, true);
      result.fold(
        onError: (e) => expect(e.message, 'Failed'),
        onData: (_) => fail('Should not have data'),
      );
    });
  });

  group('DCRequired.forwardErrorOr - Success Transformation', () {
    test('DCRequiredData discards old value, creates DCData with new value',
        () {
      const userResult =
          DCRequired<NetworkError, User>.data(User('1', 'Alice'));
      const profile = Profile('1', 'Bio');

      final result = DCRequired.forwardErrorOr(userResult, profile);

      expect(result, isA<DC<NetworkError, Profile>>());
      result.fold(
        onError: (_) => fail('Should not have error'),
        onData: (opt) => expect(opt.tryMaybe(), profile),
      );
    });
  });

  group('DCRequired.forwardErrorOrNull - Error Propagation', () {
    test('DCRequiredError forwards error', () {
      const userResult =
          DCRequired<NetworkError, User>.error(NetworkError('Failed'));

      final result = DCRequired.forwardErrorOrNull<NetworkError, User, Profile>(
        userResult,
      );

      expect(result, isA<DC<NetworkError, Profile>>());
      result.fold(
        onError: (e) => expect(e.message, 'Failed'),
        onData: (_) => fail('Should not have data'),
      );
    });
  });

  group('DCRequired.forwardErrorOrNull - Success to Null', () {
    test('DCRequiredData creates DCData with None', () {
      const userResult =
          DCRequired<NetworkError, User>.data(User('1', 'Alice'));

      final result = DCRequired.forwardErrorOrNull<NetworkError, User, Profile>(
        userResult,
      );

      expect(result, isA<DC<NetworkError, Profile>>());
      result.fold(
        onError: (_) => fail('Should not have error'),
        onData: (opt) => expect(opt.isNone, true),
      );
    });
  });

  group('DCRequired.mapError - Basic Error Mapping', () {
    test('DCRequiredError maps error to new error type', () {
      const dc = DCRequired<NetworkError, User>.error(
        NetworkError('Connection failed'),
      );

      final result = dc.mapError((e) => ValidationError(e.message));

      expect(result, isA<DCRequired<ValidationError, User>>());
      expect(result.hasError, true);
      result.fold(
        onError: (e) => expect(e.field, 'Connection failed'),
        onData: (_) => fail('Should not have data'),
      );
    });
  });

  group('DCRequired.mapError - DCRequiredData Unchanged', () {
    test('DCRequiredData - mapError preserves value and stays DCRequired', () {
      const dc = DCRequired<NetworkError, User>.data(User('1', 'Alice'));

      final result = dc.mapError((e) => ValidationError(e.message));

      expect(result, isA<DCRequiredData<ValidationError, User>>());
      result.fold(
        onError: (_) => fail('Should not have error'),
        onData: (u) => expect(u.name, 'Alice'),
      );
    });

    test('DCRequiredData - mapError transform NOT called', () {
      const dc = DCRequired<NetworkError, User>.data(User('1', 'Alice'));
      var transformCalled = false;

      dc.mapError((e) {
        transformCalled = true;
        return ValidationError(e.message);
      });

      expect(transformCalled, false);
    });
  });

  group('DCRequired.mapError - Chaining', () {
    test('chain multiple mapError calls', () {
      const dc = DCRequired<NetworkError, User>.error(NetworkError('404'));

      final result = dc
          .mapError((e) => 'Network: ${e.message}')
          .mapError((e) => 'Processed: $e')
          .mapError((e) => e.toUpperCase());

      expect(result, isA<DCRequired<String, User>>());
      result.fold(
        onError: (e) => expect(e, 'PROCESSED: NETWORK: 404'),
        onData: (_) => fail('Should not have data'),
      );
    });
  });

  group('DCRequired.toDC - Conversion to DC', () {
    test('DCRequiredError converts to DCError with the same error', () {
      const dc = DCRequired<NetworkError, User>.error(NetworkError('Failed'));

      final result = dc.toDC();

      expect(result, isA<DCError<NetworkError, User>>());
      expect(
        result,
        equals(DC<NetworkError, User>.error(const NetworkError('Failed'))),
      );
    });

    test('DCRequiredData converts to DCData with Some value', () {
      const user = User('1', 'Alice');
      const dc = DCRequired<NetworkError, User>.data(user);

      final result = dc.toDC();

      expect(result, isA<DCData<NetworkError, User>>());
      result.fold(
        onError: (_) => fail('Should not have error'),
        onData: (opt) {
          expect(opt.isSome, true);
          expect(opt.tryMaybe(), user);
        },
      );
    });

    test('converted DC works with existing DC helpers', () {
      const dc = DCRequired<NetworkError, User>.data(User('1', 'Alice'));

      final result = DC.forwardErrorOr(dc.toDC(), const Profile('1', 'Bio'));

      expect(result, isA<DC<NetworkError, Profile>>());
      result.fold(
        onError: (_) => fail('Should not have error'),
        onData: (opt) => expect(opt.tryMaybe()?.bio, 'Bio'),
      );
    });
  });

  group('DC.intoDCRequired - Conversion from DC', () {
    test('DCError converts to DCRequiredError with the same error', () {
      final dc = DC<NetworkError, User>.error(const NetworkError('Failed'));

      final result = dc.intoDCRequired(
        onNoneErr: () => const NetworkError('No user'),
      );

      expect(result, isA<DCRequiredError<NetworkError, User>>());
      result.fold(
        onError: (e) => expect(e.message, 'Failed'),
        onData: (_) => fail('Should not have data'),
      );
    });

    test('DCData with Some converts to DCRequiredData with the value', () {
      const user = User('1', 'Alice');
      final dc = DC<NetworkError, User>.some(user);

      final result = dc.intoDCRequired(
        onNoneErr: () => const NetworkError('No user'),
      );

      expect(result, isA<DCRequiredData<NetworkError, User>>());
      result.fold(
        onError: (_) => fail('Should not have error'),
        onData: (u) => expect(u, user),
      );
    });

    test('DCData with None converts to DCRequiredError from onNoneErr', () {
      final dc = DC<NetworkError, User>.none();

      final result = dc.intoDCRequired(
        onNoneErr: () => const NetworkError('No user'),
      );

      expect(result, isA<DCRequiredError<NetworkError, User>>());
      result.fold(
        onError: (e) => expect(e.message, 'No user'),
        onData: (_) => fail('Should not have data'),
      );
    });
  });

  group('DC.intoDCRequired - Function Call Verification', () {
    test('DCError does NOT call onNoneErr', () {
      final dc = DC<NetworkError, User>.error(const NetworkError('Failed'));
      var onNoneErrCalled = false;

      dc.intoDCRequired(
        onNoneErr: () {
          onNoneErrCalled = true;
          return const NetworkError('No user');
        },
      );

      expect(onNoneErrCalled, false);
    });

    test('DCData with Some does NOT call onNoneErr', () {
      final dc = DC<NetworkError, User>.some(const User('1', 'Alice'));
      var onNoneErrCalled = false;

      dc.intoDCRequired(
        onNoneErr: () {
          onNoneErrCalled = true;
          return const NetworkError('No user');
        },
      );

      expect(onNoneErrCalled, false);
    });

    test('DCData with None calls onNoneErr exactly once', () {
      final dc = DC<NetworkError, User>.none();
      var callCount = 0;

      dc.intoDCRequired(
        onNoneErr: () {
          callCount++;
          return const NetworkError('No user');
        },
      );

      expect(callCount, 1);
    });
  });

  group('DCRequired Round Trips', () {
    test('DCData with Some → intoDCRequired → toDC equals the original', () {
      final dc = DC<NetworkError, User>.some(const User('1', 'Alice'));

      final result = dc
          .intoDCRequired(onNoneErr: () => const NetworkError('No user'))
          .toDC();

      expect(result, equals(dc));
    });

    test('DCError → intoDCRequired → toDC equals the original', () {
      final dc = DC<NetworkError, User>.error(const NetworkError('Failed'));

      final result = dc
          .intoDCRequired(onNoneErr: () => const NetworkError('No user'))
          .toDC();

      expect(result, equals(dc));
    });

    test('DCRequiredData → toDC → intoDCRequired equals the original', () {
      const dc = DCRequired<NetworkError, User>.data(User('1', 'Alice'));

      final result = dc
          .toDC()
          .intoDCRequired(onNoneErr: () => const NetworkError('No user'));

      expect(result, equals(dc));
    });
  });

  group('Complex Workflows - Internal Helpers to DC', () {
    DCRequired<NetworkError, User> findUser(String id) {
      return id == '1'
          ? const DCRequired.data(User('1', 'Alice'))
          : DCRequired.error(NetworkError('User $id not found'));
    }

    DC<NetworkError, Profile> loadProfile(String id) {
      switch (findUser(id)) {
        case DCRequiredError(:final error):
          return DC.error(error);
        case DCRequiredData(:final value):
          return DC.some(Profile(value.id, 'Bio of ${value.name}'));
      }
    }

    test('success path forwards the value into a DC', () {
      loadProfile('1').fold(
        onError: (_) => fail('Should not have error'),
        onData: (opt) => expect(opt.tryMaybe()?.bio, 'Bio of Alice'),
      );
    });

    test('error path forwards the error into a DC', () {
      loadProfile('2').fold(
        onError: (e) => expect(e.message, 'User 2 not found'),
        onData: (_) => fail('Should not have data'),
      );
    });
  });

  group('Equality', () {
    test('DCRequiredError equality - same error values equal', () {
      const dc1 = DCRequired<NetworkError, User>.error(NetworkError('Failed'));
      final dc2 = DCRequired<NetworkError, User>.error(
        NetworkError(['Fai', 'led'].join()),
      );

      expect(dc1, equals(dc2));
      expect(dc1.hashCode, dc2.hashCode);
    });

    test('DCRequiredError equality - different error values not equal', () {
      const dc1 = DCRequired<NetworkError, User>.error(NetworkError('Failed'));
      const dc2 = DCRequired<NetworkError, User>.error(NetworkError('Other'));

      expect(dc1 == dc2, false);
    });

    test('DCRequiredData equality - same values equal', () {
      const dc1 = DCRequired<NetworkError, User>.data(User('1', 'Alice'));
      final dc2 = DCRequired<NetworkError, User>.data(
        User('1', ['Ali', 'ce'].join()),
      );

      expect(dc1, equals(dc2));
      expect(dc1.hashCode, dc2.hashCode);
    });

    test('DCRequiredData equality - different values not equal', () {
      const dc1 = DCRequired<NetworkError, User>.data(User('1', 'Alice'));
      const dc2 = DCRequired<NetworkError, User>.data(User('2', 'Bob'));

      expect(dc1 == dc2, false);
    });

    test('DCRequiredError and DCRequiredData not equal', () {
      const error = DCRequired<String, String>.error('same');
      const data = DCRequired<String, String>.data('same');

      expect(error == data, false);
    });

    test('DCRequired is never equal to a DC with the same content', () {
      const requiredData =
          DCRequired<NetworkError, User>.data(User('1', 'Alice'));
      const requiredError =
          DCRequired<NetworkError, User>.error(NetworkError('Failed'));

      expect(
        requiredData,
        isNot(equals(DC<NetworkError, User>.some(const User('1', 'Alice')))),
      );
      expect(
        requiredError,
        isNot(
          equals(DC<NetworkError, User>.error(const NetworkError('Failed'))),
        ),
      );
    });
  });

  group('toString', () {
    test('DCRequiredError displays error', () {
      const dc = DCRequired<NetworkError, User>.error(NetworkError('Failed'));

      expect(dc.toString(), 'DCRequiredError(NetworkError(Failed))');
    });

    test('DCRequiredData displays value', () {
      const dc = DCRequired<NetworkError, User>.data(User('1', 'Alice'));

      expect(dc.toString(), 'DCRequiredData(User(1, Alice, verified: false))');
    });
  });

  group('Type Safety Verification', () {
    test('Generic type preservation through operations', () {
      const dc1 = DCRequired<NetworkError, User>.data(User('1', 'Alice'));
      expect(dc1, isA<DCRequired<NetworkError, User>>());

      final dc2 = dc1.mapError((e) => ValidationError(e.message));
      expect(dc2, isA<DCRequired<ValidationError, User>>());

      final dc3 = DCRequired.forwardErrorOr(dc2, const Profile('1', 'Bio'));
      expect(dc3, isA<DC<ValidationError, Profile>>());
    });

    test('DCRequired is not a DC', () {
      const dc = DCRequired<NetworkError, User>.data(User('1', 'Alice'));

      expect(dc, isNot(isA<DC<NetworkError, User>>()));
      expect(dc.toDC(), isA<DC<NetworkError, User>>());
    });
  });
}
