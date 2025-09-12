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
const keyI = ScopeKey<I>('I');
const keyInt = ScopeKey<int>('int');

const oneSecond = Duration(seconds: 1);
void main() {
  test('scope ...', () async {
    final syncVal = Scope().runSync(syncTest);

    expect(syncVal, equals(1));

    final scope = Scope();
    final asyncVal = await scope.run(asyncTest);

    expect(asyncVal, equals(5));
  });

  test('scope ...', () async {
    const keyAge = ScopeKey<int>('an int');
    const keyName = ScopeKey<String>('a String');
    const keySeed = ScopeKey<String>('Random Seed');
    const keyRandom = ScopeKey<String>('Random Sequency');

    final scope = Scope()
      ..value<int>(keyAge, 10)
      ..value<String>(keyName, 'Help me')
      ..single<String>(keySeed, () => getRandString(5))
      ..sequence<String>(keyRandom, () => getRandString(6));
    await scope.run(() async {
      Future.delayed(oneSecond, () {
        print('Age: ${use(keyAge)} Name: ${use(keyName)} '
            'Random Factory: ${use(keyRandom)}');
      });
    });
  });

  group('async calls', () {
    test('scope ...', () async {
      const keyAge = ScopeKey<int>('age');

      final scope = Scope()..value<int>(keyAge, 18);

      final result = await scope.run<int>(() {
        final delayedvalue = Future<int>.delayed(oneSecond, () => use(keyAge));

        return delayedvalue;
      });

      expect(result, equals(18));
    });
  });

  group('existance', () {
    test('withinScope', () async {
      await Scope().run(() => Future.delayed(oneSecond, () {
            expect(isWithinScope(), isTrue);
          }));
    });
    test(
        'not withinScope',
        () => Future.delayed(oneSecond, () {
              expect(isWithinScope(), isFalse);
            }));

    test('hasScopeKey', () async {
      final scope = Scope()..value<A>(keyA, A('A'));
      await scope.run(() => Future.delayed(oneSecond, () {
            expect(hasScopeKey<A>(keyA), isTrue);
          }));
    });
    test(
        'not hasScopeKey',
        () => Future.delayed(oneSecond, () {
              expect(hasScopeKey<A>(keyA), isFalse);
            }));
  });
  group('use()', () {
    test('outside of provide() fails', () async {
      await Future.delayed(oneSecond, () {
        expect(() => use(keyS1), throwsMissingDependencyException);
      });
    });

    test('with not-provided key fails', () async {
      final scope = Scope()..value<String>(keyS2, 'value S2');
      await scope.run(() => Future.delayed(oneSecond, () {
            expect(() => use(keyS1), throwsMissingDependencyException);
          }));
    });

    test('with not-provided key uses default value if available', () async {
      await Future.delayed(oneSecond, () {
        expect(use(keyStrWithDefault), 'StrWithDefault default value');
        expect(use(keyNullStrWithDefault), isNull);
        expect(use(keyNullStrWithDefault), isNull);
      });
    });

    test('use withDefault', () async {
      expect(use(keyS1, withDefault: () => 'local default'), 'local default');
      expect(
          () => use(keyS1), throwsA(isA<MissingDependencyException<String>>()));

      expect(use(keyStrWithDefault), 'StrWithDefault default value');
      expect(use(keyStrWithDefault, withDefault: () => 'My default'),
          'My default');

      final scope = Scope()
        ..value<String>(keyS1, 'Hellow')
        ..value<String?>(keyStrWithDefault, 'Hellow');
      await scope.run(() async {
        expect(use(keyS1), 'Hellow');
        expect(use(keyS1, withDefault: () => 'bye'), 'Hellow');

        expect(use(keyStrWithDefault), 'Hellow');
        expect(use(keyStrWithDefault, withDefault: () => 'bye'), 'Hellow');
      });
    });

    test('prefers provided to default value', () async {
      final scope = Scope()
        ..value<String?>(keyStrWithDefault, 'provided')
        ..value<String>(keyS1, 'S1 value');
      await scope.run(() async {
        expect(use(keyStrWithDefault), 'provided');
      });
    });

    test('Test String?', () async {
      final scope = Scope()..value<String?>(keyStrWithDefault, null);
      await scope.run(() async {
        expect(use(keyStrWithDefault), isNull);
      });
    });
  });

  test('prefers innermost provided value', () async {
    final scope = Scope()..value<String>(keyS1, 'outer');
    await scope.run(() async {
      final innerScope = Scope()..value(keyS1, 'inner');
      await innerScope.run(() async {
        expect(use(keyS1), 'inner');
      });
    });
  });

  group('provide()', () {
    test('throws a CastError if key/value types are not compatible', () {
      expect(() async {
        final scope = Scope()..value(keyS1, 1);
        await scope.run(() async {});
      }, throwsA(const TypeMatcher<TypeError>()));
    });
  });

  group('return values', () {
    test('return an int', () async {
      const ageKey = ScopeKey<int>();
      final scope = Scope()..value<int>(ageKey, 18);
      final age = await scope.run<int>(() async => use(ageKey));

      expect(age, equals(18));
    });
  });
  group('Scope.single()', () {
    test('calls all singleons in own zone', () async {
      final outerA = A('outer');
      final innerA = A('inner');
      final outerI = I('outer');

      // final scopeB = Scope()..value<B>(keyB, innerB);
      // B singleB() => scopeB.run(() => B());
      // C singleC() => C();

      final scope = Scope()
        ..value(keyANull, outerA)
        ..value(keyI, outerI)
        ..single<B>(keyB, B.new);
      await scope.run(() async {
        final innerScope = Scope()
          ..single<A>(keyA, () => innerA)
          ..single<C>(keyC, C.new);
        await innerScope.run(() async {
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

    test('detects circular dependencies', () async {
      try {
        final scope = Scope()
          ..single<A>(keyA, () => A('value'))
          ..single<C>(keyC, C.new)
          ..single<D>(keyD, D.new)
          ..single<E>(keyE, E.new)
          ..single<F>(keyF, F.new)
          ..single<G>(keyG, G.new);
        await scope.run(() async {});
        fail('should have thrown CircularDependencyException');
      } on CircularDependencyException<dynamic> catch (e) {
        expect(e.keys, [keyE, keyF, keyG]);
      }

      try {
        final scope = Scope()..single(keyS1, () => use(keyS1));
        await scope.run(
          () async {},
        );
        fail('should have thrown CircularDependencyException');
      } on CircularDependencyException<dynamic> catch (e) {
        expect(e.keys, [keyS1]);
      }
    });

    test('handles null values', () async {
      final scope = Scope()
        ..single(keyANull, () => null)
        ..single(keyC, C.new);
      await scope.run(() async {
        expect(use(keyANull), isNull);
        expect(use(keyC).a, isNull);
      });
    });

    test('sequence', () async {
      var counter = 0;
      final scope = Scope()..sequence(keyInt, () => counter++);
      await scope.run(() async {
        use(keyInt);
        expect(use(keyInt), 1);
      });
    });

    test('duplicate dependencies', () async {
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
      final scope = Scope()..single<A>(keyA, () => A('first'));
      await scope.run(() async {
        final firstA = use(keyA);
        expect(firstA.value, equals('first'));

        final innerScope = Scope()..single<A>(keyA, () => A('second'));
        await innerScope.run(() async {
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

class I {
  // used in test.
  // ignore: unreachable_from_main
  final String value;

  I(this.value);
}

int syncTest() => 1;

Future<int> asyncTest() => Future.delayed(const Duration(seconds: 5), () => 5);
