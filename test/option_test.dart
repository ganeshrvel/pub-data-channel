import 'package:data_channel/data_channel.dart';
import 'package:data_channel/src/option.dart';
import 'package:meta/meta.dart';
import 'package:test/test.dart';

// Mock class for testing
@immutable
class User {
  const User(this.id, this.name);

  final String id;
  final String name;

  @override
  bool operator ==(Object other) =>
      other is User && other.id == id && other.name == name;

  @override
  int get hashCode => Object.hash(id, name);
}

void main() {
  group('Option Constructors', () {
    test('Some(value) creates Some with value', () {
      const option = Some(5);

      expect(option.isSome, true);
      expect(option.tryMaybe(), 5);
    });

    test('None() creates None', () {
      const option = None<int>();

      expect(option.isNone, true);
      expect(option.tryMaybe(), null);
    });

    test('Option.auto(value) creates Some when non-null', () {
      final option = Option.auto(5);

      expect(option.isSome, true);
      expect(option.tryMaybe(), 5);
    });

    test('Option.auto(null) creates None', () {
      final option = Option<int>.auto(null);

      expect(option.isNone, true);
      expect(option.tryMaybe(), null);
    });

    test('Option.auto with dynamic non-null value', () {
      // ignore: prefer_final_locals
      dynamic dynamicValue = 'test';
      final option = Option<String>.auto(dynamicValue as String?);

      expect(option.isSome, true);
      expect(option.tryMaybe(), 'test');
    });

    test('Option.auto with dynamic null value', () {
      // ignore: prefer_final_locals, avoid_init_to_null
      dynamic dynamicValue = null;
      final option = Option<String>.auto(dynamicValue as String?);

      expect(option.isNone, true);
      expect(option.tryMaybe(), null);
    });
  });

  group('Option Non-Nullable Constraint Tests', () {
    test('Some guarantees non-null value', () {
      const option = Some(5);

      if (option.isSome) {
        // Safe to unwrap - guaranteed non-null with extends Object
        final value = option.tryMaybe()!;
        expect(value, 5);
        expect(value.isEven, false); // Can use methods without null check
      }
    });

    test('Some with User guarantees non-null object', () {
      const option = Some(User('1', 'Alice'));

      if (option.isSome) {
        final user = option.tryMaybe()!;
        expect(user.name.length, 5); // No null checks needed
      }
    });

    test('None represents absence, not null value', () {
      const option = None<int>();

      expect(option.isNone, true);
      expect(option.isSome, false);
      expect(option.tryMaybe(), null); // Returns null, doesn't contain null
    });

    test('Type inference works with const None', () {
      // Type inferred from context
      const Option<String> option = None();

      expect(option.isNone, true);
      expect(option, isA<Option<String>>());
    });
  });

  group('Option Checks', () {
    test('isSome returns true for Some, false for None', () {
      const some = Some(5);
      const none = None<int>();

      expect(some.isSome, true);
      expect(none.isSome, false);
    });

    test('isNone returns false for Some, true for None', () {
      const some = Some(5);
      const none = None<int>();

      expect(some.isNone, false);
      expect(none.isNone, true);
    });
  });

  group('Option Unwrapping - tryMaybe', () {
    test('Some returns the value', () {
      const option = Some(5);

      expect(option.tryMaybe(), 5);
    });

    test('None returns null', () {
      const option = None<int>();

      expect(option.tryMaybe(), null);
    });

    test('Some with isSome check allows safe unwrap', () {
      const option = Some('hello');

      if (option.isSome) {
        final value = option.tryMaybe()!; // Safe with extends Object
        expect(value.toUpperCase(), 'HELLO');
      }
    });
  });

  group('Option Unwrapping - orElse', () {
    test('Some returns the value (ignores default)', () {
      const option = Some(5);

      expect(option.orElse(0), 5);
    });

    test('None returns the default value', () {
      const option = None<int>();

      expect(option.orElse(4), 4);
    });
  });

  group('Option Unwrapping - orElseGet', () {
    test('Some returns the value (function NOT called)', () {
      const option = Some(5);
      var called = false;

      final result = option.orElseGet(() {
        called = true;
        return 0;
      });

      expect(result, 5);
      expect(called, false);
    });

    test('None calls function and returns result', () {
      const option = None<int>();
      var called = false;

      final result = option.orElseGet(() {
        called = true;
        return 0;
      });

      expect(result, 0);
      expect(called, true);
    });

    test('Verify function only executed when None (lazy evaluation)', () {
      var callCount = 0;

      const Some(5).orElseGet(() {
        callCount++;
        return 0;
      });

      const None<int>().orElseGet(() {
        callCount++;
        return 0;
      });

      expect(callCount, 1); // Only called once for None
    });
  });

  group('Option map - Basic', () {
    test('Some maps value to new value', () {
      const option = Some(5);
      final result = option.map((x) => x * 2);

      expect(result.isSome, true);
      expect(result.tryMaybe(), 10);
    });

    test('None stays None (transform NOT called)', () {
      const option = None<int>();
      var called = false;

      final result = option.map((x) {
        called = true;
        return x * 2;
      });

      expect(result.isNone, true);
      expect(called, false);
    });

    test('Some map preserves non-null guarantee', () {
      const option = Some(5);
      final result = option.map((x) => x.toString());

      if (result.isSome) {
        final str = result.tryMaybe()!;
        expect(str.length, 1); // Can use without null check
      }
    });
  });

  group('Option map - Type Changes', () {
    test('Some(int) maps to String', () {
      const option = Some(5);
      final result = option.map((x) => x.toString());

      expect(result.isSome, true);
      expect(result.tryMaybe(), '5');
    });

    test('Some(String) maps to int', () {
      const option = Some('hello');
      final result = option.map((x) => x.length);

      expect(result.isSome, true);
      expect(result.tryMaybe(), 5);
    });

    test('Some(User) maps to User.name', () {
      const option = Some(User('123', 'John'));
      final result = option.map((user) => user.name);

      expect(result.isSome, true);
      expect(result.tryMaybe(), 'John');
    });
  });

  group('Option map - Chaining', () {
    test('Some chained maps (chain transformations)', () {
      const option = Some(5);
      final result =
          option.map((x) => x * 2).map((x) => x + 1).map((x) => x.toString());

      expect(result.isSome, true);
      expect(result.tryMaybe(), '11');
    });

    test('None chained maps (stays None, no transforms called)', () {
      const option = None<int>();
      var callCount = 0;

      final result = option.map((x) {
        callCount++;
        return x * 2;
      }).map((x) {
        callCount++;
        return x + 1;
      }).map((x) {
        callCount++;
        return x.toString();
      });

      expect(result.isNone, true);
      expect(callCount, 0);
    });
  });

  group('Option flatMap - Basic', () {
    test('Some flatMap returns Some (no nesting)', () {
      const option = Some(5);
      final result = option.flatMap((x) => Some(x * 2));

      expect(result.isSome, true);
      expect(result.tryMaybe(), 10);
    });

    test('Some flatMap returns None (propagates None)', () {
      const option = Some(5);
      final result = option.flatMap((x) => const None<int>());

      expect(result.isNone, true);
    });

    test('None flatMap (stays None, transform NOT called)', () {
      const option = None<int>();
      var called = false;

      final result = option.flatMap((x) {
        called = true;
        return Some(x * 2);
      });

      expect(result.isNone, true);
      expect(called, false);
    });
  });

  group('Option flatMap - Chaining', () {
    test('Some chained flatMap (chain operations)', () {
      const option = Some(5);
      final result = option
          .flatMap((x) => Some(x * 2))
          .flatMap((x) => Some(x + 1))
          .flatMap((x) => Some(x.toString()));

      expect(result.isSome, true);
      expect(result.tryMaybe(), '11');
    });

    test('Some flatMap becomes None, then stays None', () {
      const option = Some(5);
      var secondCallCount = 0;

      final result = option
          .flatMap((x) => Some(x * 2))
          .flatMap((x) => const None<int>())
          .flatMap((x) {
        secondCallCount++;
        return Some(x + 1);
      });

      expect(result.isNone, true);
      expect(secondCallCount, 0);
    });
  });

  group('Option flatMap - Flattening', () {
    test('Verify result is Option<T> not Option<Option<T>>', () {
      const option = Some(5);
      final result = option.flatMap((x) => Some(x * 2));

      // Type check: result should be Option<int>, not Option<Option<int>>
      expect(result, isA<Option<int>>());
      expect(result.tryMaybe(), 10);
    });
  });

  group('Option filter - Basic', () {
    test('Some with predicate true (keeps Some)', () {
      const option = Some(5);
      final result = option.filter((x) => x > 3);

      expect(result.isSome, true);
      expect(result.tryMaybe(), 5);
    });

    test('Some with predicate false (becomes None)', () {
      const option = Some(5);
      final result = option.filter((x) => x > 10);

      expect(result.isNone, true);
    });

    test('None with predicate (stays None, predicate NOT called)', () {
      const option = None<int>();
      var called = false;

      final result = option.filter((x) {
        called = true;
        return x > 3;
      });

      expect(result.isNone, true);
      expect(called, false);
    });

    test('Filter with non-null guarantee', () {
      const option = Some(User('1', 'Alice'));
      final result = option.filter((u) => u.name.length > 3);

      expect(result.isSome, true);
      if (result.isSome) {
        final user = result.tryMaybe()!;
        expect(user.name, 'Alice');
      }
    });
  });

  group('Option filter - Chaining', () {
    test('Some with all filters true (stays Some)', () {
      const option = Some(5);
      final result = option
          .filter((x) => x > 3)
          .filter((x) => x < 10)
          .filter((x) => x.isOdd);

      expect(result.isSome, true);
      expect(result.tryMaybe(), 5);
    });

    test('Some filter becomes None, stays None through chain', () {
      const option = Some(5);
      var thirdCallCount = 0;

      final result =
          option.filter((x) => x > 3).filter((x) => x > 10).filter((x) {
        thirdCallCount++;
        return x > 0;
      });

      expect(result.isNone, true);
      expect(thirdCallCount, 0);
    });

    test('Some filter fails immediately (becomes None)', () {
      const option = Some(5);
      var secondCallCount = 0;

      final result = option.filter((x) => x > 10).filter((x) {
        secondCallCount++;
        return x > 0;
      });

      expect(result.isNone, true);
      expect(secondCallCount, 0);
    });
  });

  group('Option fold - Basic', () {
    test('Some calls onSome with value', () {
      const option = Some(5);
      final result = option.fold(
        onSome: (x) => x * 2,
        onNone: () => 0,
      );

      expect(result, 10);
    });

    test('None calls onNone', () {
      const option = None<int>();
      final result = option.fold(
        onSome: (x) => x * 2,
        onNone: () => 0,
      );

      expect(result, 0);
    });

    test('Return values work correctly', () {
      const some = Some(5);
      const none = None<int>();

      expect(some.fold(onSome: (x) => true, onNone: () => false), true);
      expect(none.fold(onSome: (x) => true, onNone: () => false), false);
    });

    test('fold onSome receives non-null value', () {
      const Some('test').fold(
        onSome: (value) {
          // value is guaranteed String, not String?
          expect(value.toUpperCase(), 'TEST');
        },
        onNone: () => fail('Should not call onNone'),
      );
    });
  });

  group('Option fold - Type Transformation', () {
    test('Some(int) fold returns String', () {
      const option = Some(5);
      final result = option.fold(
        onSome: (x) => 'Value: $x',
        onNone: () => 'No value',
      );

      expect(result, 'Value: 5');
    });

    test('None fold returns default value', () {
      const option = None<int>();
      final result = option.fold(
        onSome: (x) => 'Value: $x',
        onNone: () => 'No value',
      );

      expect(result, 'No value');
    });
  });

  group('Option Complex Chains - Mixed Operations', () {
    test('Some: map → filter → map → flatMap → fold (all succeed)', () {
      const option = Some(10);
      final result = option
          .map((x) => x * 2) // 20
          .filter((x) => x > 15) // passes
          .map((x) => x ~/ 2) // 10
          .flatMap(Some.new) // 10
          .fold(
            onSome: (x) => 'Result: $x',
            onNone: () => 'Failed',
          );

      expect(result, 'Result: 10');
    });

    test('Some: filter becomes None, rest of chain stays None', () {
      const option = Some(5);
      var mapCount = 0;
      var flatMapCount = 0;

      final result = option.filter((x) => x > 10).map((x) {
        mapCount++;
        return x * 2;
      }).flatMap((x) {
        flatMapCount++;
        return Some(x + 1);
      }).fold(
        onSome: (x) => 'Value: $x',
        onNone: () => 'No value',
      );

      expect(result, 'No value');
      expect(mapCount, 0);
      expect(flatMapCount, 0);
    });

    test('Some: map → flatMap becomes None → filter → map (stays None)', () {
      const option = Some(5);
      var filterCount = 0;
      var finalMapCount = 0;

      final result = option
          .map((x) => x * 2)
          .flatMap((x) => const None<int>())
          .filter((x) {
        filterCount++;
        return x > 0;
      }).map((x) {
        finalMapCount++;
        return x.toString();
      }).fold(
        onSome: (x) => 'Value: $x',
        onNone: () => 'No value',
      );

      expect(result, 'No value');
      expect(filterCount, 0);
      expect(finalMapCount, 0);
    });
  });

  group('Option Complex Chains - Short Circuit', () {
    test('None short-circuits entire chain (no functions called)', () {
      const option = None<int>();
      var mapCount = 0;
      var filterCount = 0;
      var flatMapCount = 0;

      option.map((x) {
        mapCount++;
        return x * 2;
      }).filter((x) {
        filterCount++;
        return x > 5;
      }).flatMap((x) {
        flatMapCount++;
        return Some(x + 1);
      });

      expect(mapCount, 0);
      expect(filterCount, 0);
      expect(flatMapCount, 0);
    });

    test('Some executes all until first None', () {
      const option = Some(5);
      var firstMapCount = 0;
      var secondMapCount = 0;
      var thirdMapCount = 0;

      option.map((x) {
        firstMapCount++;
        return x * 2;
      }).flatMap((x) {
        secondMapCount++;
        return const None<int>();
      }).map((x) {
        thirdMapCount++;
        return x + 1;
      });

      expect(firstMapCount, 1);
      expect(secondMapCount, 1);
      expect(thirdMapCount, 0);
    });
  });

  group('Option Edge Cases - Identity Operations', () {
    test('Some map identity returns same value', () {
      const option = Some(5);
      final result = option.map((x) => x);

      expect(result.isSome, true);
      expect(result.tryMaybe(), 5);
    });

    test('Some filter always true returns same Some', () {
      const option = Some(5);
      final result = option.filter((x) => true);

      expect(result.isSome, true);
      expect(result.tryMaybe(), 5);
    });

    test('Some flatMap identity returns same value', () {
      const option = Some(5);
      final result = option.flatMap(Some.new);

      expect(result.isSome, true);
      expect(result.tryMaybe(), 5);
    });
  });

  group('Option Edge Cases - Empty Transformations', () {
    test('filter with always-false predicate', () {
      const option = Some(5);
      final result = option.filter((x) => false);

      expect(result.isNone, true);
    });
  });

  group('Option Equality', () {
    test('Some(5) == Some(5)', () {
      const option1 = Some(5);
      const option2 = Some(5);

      expect(option1, equals(option2));
      expect(option1 == option2, true);
    });

    test('Some(5) != Some(10)', () {
      const option1 = Some(5);
      const option2 = Some(10);

      expect(option1 == option2, false);
    });

    test('None() == None()', () {
      const option1 = None<int>();
      const option2 = None<int>();

      expect(option1, equals(option2));
      expect(option1 == option2, true);
    });

    test('Some(5) != None()', () {
      const option1 = Some(5);
      const option2 = None<int>();

      // ignore: unrelated_type_equality_checks
      expect(option1 == option2, false);
    });

    test('Custom objects with equality', () {
      const user1 = User('1', 'Alice');
      const user2 = User('1', 'Alice');
      const option1 = Some(user1);
      const option2 = Some(user2);

      expect(option1, equals(option2));
    });
  });

  group('Option toString', () {
    test('Some displays value', () {
      const option = Some(5);

      expect(option.toString(), 'Some(5)');
    });

    test('None displays correctly', () {
      const option = None<int>();

      expect(option.toString(), 'None');
    });
  });

  group('Type Aliases', () {
    test('DCOption works as alias', () {
      final option = DCOption.auto(5);

      expect(option.isSome, true);
      expect(option, isA<Option<int>>());
    });

    test('DCSome works as alias', () {
      const option = DCSome(5);

      expect(option.isSome, true);
      expect(option, isA<Some<int>>());
    });

    test('DCNone works as alias', () {
      const option = DCNone<int>();

      expect(option.isNone, true);
      expect(option, isA<None<int>>());
    });
  });

  group('Real-world Usage Patterns', () {
    test('Safe chaining with validation', () {
      final maybeUser = Option<User>.auto(const User('1', 'a'));

      final result = maybeUser
          .filter((u) => u.name.length > 2)
          .map((u) => u.name.toUpperCase())
          .orElse('GUEST');

      expect(result, 'GUEST');
    });

    test('Combining Option operations for data pipeline', () {
      const users = [
        User('1', 'Alice'),
        User('2', 'Bob'),
        User('3', 'Charlie'),
      ];

      final foundUser = Option<User>.auto(
        users.cast<User?>().firstWhere(
              (u) => u?.id == '2',
              orElse: () => null,
            ),
      );

      final result = foundUser.map((u) => u.name).orElse('Unknown');

      expect(result, 'Bob');
    });
  });

  group('Option Type Transitions', () {
    test('None transitions through multiple type changes via map', () {
      const option = None<int>();

      // int → String → bool → double
      final result = option
          .map((x) => x.toString()) // None<int> → None<String>
          .map((s) => s.isNotEmpty) // None<String> → None<bool>
          .map((b) => b ? 1.0 : 0.0) // None<bool> → None<double>
          .orElse(99.9);

      expect(result, 99.9);
      expect(result, isA<double>());
    });

    test('None transitions through flatMap chains', () {
      const option = None<String>();

      final result = option
          .flatMap<int>((s) => Some(s.length)) // None<String> → None<int>
          .flatMap<bool>((i) => Some(i > 5)) // None<int> → None<bool>
          .flatMap<String>(
              (b) => Some(b.toString())) // None<bool> → None<String>
          .orElse('fallback');

      expect(result, 'fallback');
    });

    test('None type changes through mixed map and flatMap', () {
      const option = None<User>();

      final result = option
          .map((u) => u.name) // None<User> → None<String>
          .flatMap<int>((s) => Some(s.length)) // None<String> → None<int>
          .map((i) => i * 2) // None<int> → None<int>
          .flatMap<bool>((i) => Some(i > 10)) // None<int> → None<bool>
          .orElse(false);

      expect(result, false);
    });

    test('Filter creates None with preserved type', () {
      const option = Some('hello');

      final result = option
          .filter((s) => s.length > 10) // Some<String> → None<String>
          .map((s) => s.toUpperCase()) // None<String> → None<String>
          .orElse('default');

      expect(result, 'default');
      expect(result, isA<String>());
    });

    test('Complex type chain with Some→None→Some via flatMap', () {
      const option = Some(5);

      final result = option
          .map((x) => x * 2) // Some(10)
          .filter((x) => x > 100) // None<int>
          .flatMap<String>((x) => Some('value: $x')) // None<String>
          .map((s) => s.length) // None<int>
          .orElseGet(() => 0);

      expect(result, 0);
    });
  });
}
