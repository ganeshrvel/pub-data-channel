import 'package:data_channel/data_channel.dart';
import 'package:test/test.dart';

// Mock models for testing
class User {
  User(this.id, this.name);

  final String id;
  final String name;
}

class Profile {
  Profile({this.id, this.name});

  // ignore: unreachable_from_main
  final String? id;
  final String? name;
}

class NetworkException implements Exception {
  NetworkException(this.message);

  final String message;

  @override
  String toString() => 'NetworkException: $message';
}

class UserFacingException implements Exception {
  UserFacingException(this.message);

  final String message;

  @override
  String toString() => 'UserFacingException: $message';
}

void main() {
  group('DC Basic Usage', () {
    test('DC.data creates successful result', () {
      final result = DC<Exception, User>.data(User('123', 'John'));

      expect(result.hasData, true);
      expect(result.hasError, false);
      expect(result.data?.name, 'John');
    });

    test('DC.error creates error result', () {
      final result = DC<NetworkException, User>.error(
        NetworkException('Connection failed'),
      );

      expect(result.hasError, true);
      expect(result.hasData, false);
      expect(result.error.toString(), contains('Connection failed'));
    });
  });

  group('DC State Checking', () {
    test('hasError returns true when error present', () {
      final result = DC<Exception, String>.error(Exception('Failed'));

      expect(result.hasError, true);
      expect(result.hasData, false);
    });

    test('hasData returns true when data present', () {
      final result = DC<Exception, String>.data('Success');

      expect(result.hasData, true);
      expect(result.hasError, false);
    });

    test('can access error and data properties', () {
      final errorResult = DC<Exception, String>.error(Exception('Error'));
      final dataResult = DC<Exception, String>.data('Data');

      expect(errorResult.error, isA<Exception>());
      expect(dataResult.data, 'Data');
    });
  });

  group('DC.pick Method', () {
    test('pick calls onError when error present', () {
      final result = DC<Exception, String>.error(Exception('Failed'));
      String? captured;

      result.pick(
        onError: (error) {
          captured = error.toString();
        },
        onData: (data) {
          captured = data;
        },
      );

      expect(captured, contains('Failed'));
    });

    test('pick calls onData when data present', () {
      final result = DC<Exception, String>.data('Success');
      String? captured;

      result.pick(
        onError: (error) {
          captured = 'error';
        },
        onData: (data) {
          captured = data;
        },
      );

      expect(captured, 'Success');
    });

    test('pick calls onNoData when no data present', () {
      final result = DC<Exception, String?>.data(null);
      var noDataCalled = false;

      result.pick(
        onError: (error) {},
        onData: (data) {},
        onNoData: () {
          noDataCalled = true;
        },
      );

      expect(noDataCalled, true);
    });

    test('pick calls onNoError for both data and no-data cases', () {
      final resultWithData = DC<Exception, String>.data('Test');
      final resultWithNull = DC<Exception, String?>.data(null);

      String? capturedFromData;
      String? capturedFromNull;

      resultWithData.pick(
        onError: (error) {},
        onNoError: (data) {
          capturedFromData = data;
        },
      );

      resultWithNull.pick(
        onError: (error) {},
        onNoError: (data) {
          capturedFromNull = data;
        },
      );

      expect(capturedFromData, 'Test');
      expect(capturedFromNull, null);
    });
  });

  group('DC.fold Method', () {
    test('fold returns error handler result when error present', () {
      final result = DC<Exception, String>.error(Exception('Failed'));

      final message = result.fold(
        onError: (error) => 'Error occurred',
        onData: (data) => 'Success: $data',
      );

      expect(message, 'Error occurred');
    });

    test('fold returns data handler result when data present', () {
      final result = DC<Exception, String>.data('John');

      final message = result.fold(
        onError: (error) => 'Error occurred',
        onData: (data) => 'Hello $data',
      );

      expect(message, 'Hello John');
    });

    test('fold handles nullable data', () {
      final result = DC<Exception, String?>.data(null);

      final message = result.fold(
        onError: (error) => 'Error',
        onData: (data) => data ?? 'No data',
      );

      expect(message, 'No data');
    });

    test('fold can return different types', () {
      final result = DC<Exception, int>.data(42);

      final doubled = result.fold(
        onError: (error) => 0,
        onData: (data) => (data ?? 0) * 2,
      );

      expect(doubled, 84);
    });
  });

  group('DC.mapData Method', () {
    test('mapData transforms data when present', () {
      final result = DC<Exception, User>.data(User('123', 'John'));

      final nameResult = result.mapData((user) => user.name);

      expect(nameResult.hasData, true);
      expect(nameResult.data, 'John');
    });

    test('mapData preserves error when present', () {
      final result = DC<NetworkException, User>.error(
        NetworkException('Failed'),
      );

      final nameResult = result.mapData((user) => user.name);

      expect(nameResult.hasError, true);
      expect(nameResult.error.toString(), contains('Failed'));
    });

    test('mapData can be chained', () {
      final result = DC<Exception, User>.data(User('123', 'john'));

      final upperName = result
          .mapData((user) => user.name)
          .mapData((name) => name.toUpperCase());

      expect(upperName.data, 'JOHN');
    });
  });

  group('DC.mapError Method', () {
    test('mapError transforms error when present', () {
      final result = DC<NetworkException, String>.error(
        NetworkException('Connection failed'),
      );

      final friendlyResult = result.mapError(
        (error) => UserFacingException('Please check your connection'),
      );

      expect(friendlyResult.hasError, true);
      expect(
        friendlyResult.error.toString(),
        contains('Please check your connection'),
      );
    });

    test('mapError preserves data when present', () {
      final result = DC<NetworkException, String>.data('Success');

      final mappedResult = result.mapError(
        (error) => UserFacingException('Friendly error'),
      );

      expect(mappedResult.hasData, true);
      expect(mappedResult.data, 'Success');
    });
  });

  group('DC.forward Method', () {
    test('forward propagates error', () {
      final userResult = DC<Exception, User>.error(Exception('Failed'));

      final profileResult = DC.forward(
        userResult,
        Profile(id: '123', name: 'John'),
      );

      expect(profileResult.hasError, true);
      expect(profileResult.error.toString(), contains('Failed'));
    });

    test('forward transforms data when no error', () {
      final userResult = DC<Exception, User>.data(User('123', 'John'));

      final profileResult = DC.forward(
        userResult,
        Profile(id: userResult.data?.id, name: userResult.data?.name),
      );

      expect(profileResult.hasData, true);
      expect(profileResult.data?.name, 'John');
    });
  });

  group('DC Real-world Scenarios', () {
    test('complete user fetch flow with error', () async {
      // Simulate API call that fails
      Future<DC<NetworkException, User>> fetchUser(String id) async {
        await Future<void>.delayed(const Duration(milliseconds: 10));
        return DC<NetworkException, User>.error(
          NetworkException('API timeout'),
        );
      }

      final result = await fetchUser('123');
      String? message;

      result.pick(
        onError: (error) {
          message = 'Failed to load user';
        },
        onData: (user) {
          message = 'Welcome ${user.name}';
        },
      );

      expect(message, 'Failed to load user');
    });

    test('complete user fetch flow with success', () async {
      // Simulate successful API call
      Future<DC<NetworkException, User>> fetchUser(String id) async {
        await Future<void>.delayed(const Duration(milliseconds: 10));
        return DC<NetworkException, User>.data(User(id, 'Alice'));
      }

      final result = await fetchUser('456');

      final greeting = result.fold(
        onError: (error) => 'Error loading user',
        onData: (user) => 'Hello ${user?.name}!',
      );

      expect(greeting, 'Hello Alice!');
    });

    test('transform and forward user to profile', () async {
      // Simulate fetching user
      Future<DC<Exception, User>> fetchUser(String id) async {
        return DC<Exception, User>.data(User(id, 'Bob'));
      }

      // Transform to profile
      Future<DC<Exception, Profile>> getUserProfile(String id) async {
        final userResult = await fetchUser(id);

        return DC.forward(
          userResult,
          Profile(
            id: userResult.data?.id,
            name: userResult.data?.name,
          ),
        );
      }

      final profile = await getUserProfile('789');

      expect(profile.hasData, true);
      expect(profile.data?.name, 'Bob');
    });

    test('chain multiple transformations', () {
      final result = DC<Exception, User>.data(User('999', 'charlie'));

      final displayName = result
          .mapData((user) => user.name)
          .mapData((name) => name.toUpperCase())
          .mapData((name) => 'User: $name');

      expect(displayName.data, 'User: CHARLIE');
    });

    test('handle error transformation for UI', () {
      final result = DC<NetworkException, User>.error(
        NetworkException('502 Bad Gateway'),
      );

      final uiReady = result
          .mapError(
            (error) => UserFacingException('Service temporarily unavailable'),
          )
          .fold(
            onError: (error) => error.message,
            onData: (user) => user?.name ?? 'Unknown',
          );

      expect(uiReady, 'Service temporarily unavailable');
    });
  });
}
