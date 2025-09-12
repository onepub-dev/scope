// used by unit tests.
// ignore_for_file: unreachable_from_main

/* Copyright (C) S. Brett Sutton - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Brett Sutton <bsutton@onepub.dev>, Jan 2022
 */

import 'dart:convert';
import 'dart:math';

import 'package:scope/scope.dart';
import 'package:test/test.dart';

final throwsMissingDependencyException =
    throwsA(const TypeMatcher<MissingDependencyException<dynamic>>());

const keyS1 = ScopeKey<String>('S1');
const keyS2 = ScopeKey<String>('S2');
final keyStrWithDefault = ScopeKey<String?>.withDefault(
    'StrWithDefault default value', 'StrWithDefault');
final keyNullStrWithDefault =
    ScopeKey<String?>.withDefault(null, 'NullStrWithDefault');

const keyA = ScopeKey<A>('A');
const keyANull = ScopeKey<A?>('A?');
const keyB = ScopeKey<B>('B');
const keyC = ScopeKey<C>('C');
const keyD = ScopeKey<D>('D');
const keyE = ScopeKey<E>('E');
const keyF = ScopeKey<F>('F');
const keyG = ScopeKey<G>('G');
const keyGNull = ScopeKey<G?>('G?');
const keyI = ScopeKey<I>('I');
const keyInt = ScopeKey<int>('int');

void main() {
  test('scope ...', () {
    const keyAge = ScopeKey<int>('an int');
    const keyName = ScopeKey<String>('a String');
    const keySeed = ScopeKey<String>('Random Seed');
    const keyRandom = ScopeKey<String>('Random Sequency');

    Scope()
      ..value<int>(keyAge, 10)
      ..value<String>(keyName, 'Help me')
      ..single<String>(keySeed, () => getRandString(5))
      ..sequence<String>(keyRandom, () => getRandString(6))
      ..runSync(() {
        print('Age: ${use(keyAge)} Name: ${use(keyName)} '
            'Random Factory: ${use(keyRandom)}');
      });
  });

  group('async calls', () {
    test('scope ...', () async {
      const keyAge = ScopeKey<int>('age');

      final scope = Scope()..value<int>(keyAge, 18);

      final one = await scope.run<int>(() {
        final delayedvalue =
            Future<int>.delayed(const Duration(seconds: 1), () => use(keyAge));

        return delayedvalue;
      });

      expect(one, equals(18));
    });
  });

  group('existance', () {
    test('withinScope', () {
      Scope().runSync(() {
        expect(isWithinScope(), isTrue);
      });
    });
    test('not withinScope', () {
      expect(isWithinScope(), isFalse);
    });

    test('hasScopeKey', () {
      Scope()
        ..value<A>(keyA, A('A'))
        ..runSync(() {
          expect(hasScopeKey<A>(keyA), isTrue);
        });
    });
    test('not hasScopeKey', () {
      expect(hasScopeKey<A>(keyA), isFalse);
    });
  });
  group('use()', () {
    test('outside of provide() fails', () {
      expect(() => use(keyS1), throwsMissingDependencyException);
    });

    test('with not-provided key fails', () {
      Scope()
        ..value<String>(keyS2, 'value S2')
        ..runSync(() {
          expect(() => use(keyS1), throwsMissingDependencyException);
        });
    });

    test('with not-provided key uses default value if available', () {
      expect(use(keyStrWithDefault), 'StrWithDefault default value');
      expect(use(keyNullStrWithDefault), isNull);
      expect(use(keyNullStrWithDefault), isNull);
    });

    test('use withDefault', () {
      expect(use(keyS1, withDefault: () => 'local default'), 'local default');
      expect(
          () => use(keyS1), throwsA(isA<MissingDependencyException<String>>()));

      expect(use(keyStrWithDefault), 'StrWithDefault default value');
      expect(use(keyStrWithDefault, withDefault: () => 'My default'),
          'My default');

      Scope()
        ..value<String>(keyS1, 'Hellow')
        ..value<String?>(keyStrWithDefault, 'Hellow')
        ..runSync(() {
          expect(use(keyS1), 'Hellow');
          expect(use(keyS1, withDefault: () => 'bye'), 'Hellow');

          expect(use(keyStrWithDefault), 'Hellow');
          expect(use(keyStrWithDefault, withDefault: () => 'bye'), 'Hellow');
        });
    });

    test('prefers provided to default value', () {
      Scope()
        ..value<String?>(keyStrWithDefault, 'provided')
        ..value<String>(keyS1, 'S1 value')
        ..runSync(() {
          expect(use(keyStrWithDefault), 'provided');
        });
    });

    test('Test String?', () {
      Scope()
        ..value<String?>(keyStrWithDefault, null)
        ..runSync(() {
          expect(use(keyStrWithDefault), isNull);
        });
    });
  });

  test('prefers innermost provided value', () {
    Scope()
      ..value<String>(keyS1, 'outer')
      ..runSync(() {
        Scope()
          ..value(keyS1, 'inner')
          ..runSync(() {
            expect(use(keyS1), 'inner');
          });
      });
  });

  group('provide()', () {
    test('throws a CastError if key/value types are not compatible', () {
      expect(
          () => Scope()
            ..value(keyS1, 1)
            ..runSync(() {}),
          throwsA(const TypeMatcher<TypeError>()));
    });
  });

  group('return values', () {
    test('return an int', () {
      const ageKey = ScopeKey<int>();
      final scope = Scope()..value<int>(ageKey, 18);
      final age = scope.runSync<int>(() => use(ageKey));

      expect(age, equals(18));
    });
  });
  group('Scope.single()', () {
    test('calls all singleons in own zone', () {
      final outerA = A('outer');
      final innerA = A('inner');
      final outerI = I('outer');

      // final scopeB = Scope()..value<B>(keyB, innerB);
      // B singleB() => scopeB.run(() => B());
      // C singleC() => C();

      Scope()
        ..value(keyANull, outerA)
        ..value(keyI, outerI)
        ..single<B>(keyB, B.new)
        ..runSync(() {
          Scope()
            ..single<A>(keyA, () => innerA)
            ..single<C>(keyC, C.new)
            ..runSync(() {
              final a = use(keyA);
              expect(a, innerA);

              final b = use(keyB);
              expect(b.a, null);
              expect(b.c, null);

              final c = use(keyC);
              expect(c.a, outerA);

              final i = use(keyI);
              expect(i, equals(outerI));
            });
        });
    });

    test('detects circular dependencies', () {
      try {
        Scope()
          ..single<A>(keyA, () => A('value'))
          ..single<C>(keyC, C.new)
          ..single<D>(keyD, D.new)
          ..single<E>(keyE, E.new)
          ..single<F>(keyF, F.new)
          ..single<G>(keyG, G.new)
          ..runSync(() {});
        fail('should have thrown CircularDependencyException');
      } on CircularDependencyException<dynamic> catch (e) {
        expect(e.keys, [keyE, keyF, keyG]);
      }

      try {
        Scope()
          ..single(keyS1, () => use(keyS1))
          ..runSync(
            () {},
          );
        fail('should have thrown CircularDependencyException');
      } on CircularDependencyException<dynamic> catch (e) {
        expect(e.keys, [keyS1]);
      }
    });

    test('handles null values', () {
      Scope()
        ..single(keyANull, () => null)
        ..single(keyC, C.new)
        ..runSync(() {
          expect(use(keyANull), isNull);
          expect(use(keyC).a, isNull);
        });
    });

    test('sequence', () {
      var counter = 0;
      Scope()
        ..sequence(keyInt, () => counter++)
        ..runSync(() {
          use(keyInt);
          expect(use(keyInt), 1);
        });
    });

    test('duplicate dependencies', () {
      /// can add the same key twice to the same scope.
      expect(
          () => Scope()
            ..value<A>(keyA, A('first'))
            ..value<A>(keyA, A('second')),
          throwsA(isA<DuplicateDependencyException<A>>()));

      expect(
          () => Scope()
            ..single<A>(keyA, () => A('first'))
            ..single<A>(keyA, () => A('second')),
          throwsA(isA<DuplicateDependencyException<A>>()));

      /// keys at different leves are not duplicates.
      Scope()
        ..single<A>(keyA, () => A('first'))
        ..runSync(() {
          final firstA = use(keyA);
          expect(firstA.value, equals('first'));

          Scope()
            ..single<A>(keyA, () => A('second'))
            ..runSync(() {
              final secondA = use(keyA);
              expect(secondA.value, equals('second'));
            });
        });
    });
  });
}

String getRandString(int len) {
  final random = Random.secure();
  final values = List<int>.generate(len, (i) => random.nextInt(255));
  return base64UrlEncode(values);
}

class A {
  final String value;

  A(this.value);
}

class B {
  final A? a;

  final C? c;

  B()
      : a = use(keyANull),
        c = use(keyC);
}

class C {
  final A? a;

  C() : a = use(keyANull);
}

class D {
  final E? e;

  D() : e = use(keyE);
}

class E {
  final F? f;

  E() : f = use(keyF);
}

class F {
  final C? c;

  final G? g;

  F()
      : c = use(keyC),
        g = use(keyG);
}

class G {
  final E? e;

  G() : e = use(keyE);
}

class H {
  final G? g;

  H() : g = use(keyGNull);
}

class I {
  final String value;

  I(this.value);
}
