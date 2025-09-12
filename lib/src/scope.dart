/* Copyright (C) S. Brett Sutton - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Brett Sutton <bsutton@onepub.dev>, Jan 2022
 */

library;

import 'dart:async';

import 'package:meta/meta.dart';

import 'exceptions.dart';
import 'global_scope.dart';
import 'injector.dart';
import 'single_injector.dart';

part 'scope_key.dart';

typedef _Factory = dynamic Function();

/// Creates a Scope providing dependency injection to your call stack.
///
/// Scopes may be nested with the nearest Scope overriding parent scopes.
class Scope {
  late final String _debugName;

  final _provided = <ScopeKey<dynamic>, dynamic>{};

  final _singles = <ScopeKey<dynamic>, _Factory>{};

  final _sequences = <ScopeKey<dynamic>, _Factory>{};

  /// Create a [Scope] that allows you to inject values.
  ///
  /// Any methods directly or indirectly called from the
  /// [Scope]s [runSync] method have access to those injected values.
  ///
  /// The [debugName] is useful when debugging allowing yo to
  /// provide each [Scope] with a unique name.
  ///
  /// ```dart
  /// final ageKey = ScopeKey<int>();
  /// final daysOldKey = ScopeKey<int>();
  /// final countKey = ScopeKey<int>();
  /// Scope()
  ///   ..value<int>(ageKey, 18)
  ///   ..single<int>(daysOldKey, () => calculateDaysOld(use(ageKey)))
  ///   ..sequence<int>(countKey, () => count++)
  ///   ..run(() {
  ///       print('You are ${use(ageKey)} which is ${use(daysOldKey)} '
  ///         'count: ${use(countKey)}'));
  ///   });
  Scope([String? debugName]) {
    _debugName = debugName ?? 'Unnamed Scope - pass debugName to ctor';
  }

  @override
  String toString() => _debugName;

  /// Injects [value] into the [Scope].
  ///
  /// The [value] can be retrieve by calling
  /// [use] from anywhere within the action
  /// method provided to [runSync]
  ///
  /// ```dart
  /// Scope()
  ///   ..value<int>(ageKey, 18)
  ///   ..value<int>(heightKey, getHeight())
  ///   ..run(() {}
  /// ```
  void value<T>(ScopeKey<T> key, T value) {
    _checkDuplicateKey(key);
    _provided.putIfAbsent(key, () => value);
  }

  void _checkDuplicateKey<T>(ScopeKey<T> key) {
    if (_provided.containsKey(key)) {
      throw DuplicateDependencyException(key);
    }
    if (_singles.containsKey(key)) {
      throw DuplicateDependencyException(key);
    }
    if (_sequences.containsKey(key)) {
      throw DuplicateDependencyException(key);
    }
  }

  @Deprecated('Use single')

  /// Use [single].
  void factory<T>(ScopeKey<T> key, T Function() factory) =>
      single(key, factory);

  /// Injects a single value into the [Scope] from a factory method.
  ///
  /// The [single]'s factory method may [use] [value]s, other [single]s
  /// and [sequence]s registered within the SAME [Scope].
  ///
  /// Each [single] is eagerly called when [Scope.runSync] is called
  /// and are fully resolved when the [Scope.runSync]'s s action is called.
  ///
  /// ```dart
  /// Scope()
  ///   ..single<int>(ageKey, () => getDbConnection())
  ///   ..run(() {}
  /// ```

  void single<T>(ScopeKey<T> key, T Function() factory) {
    _checkDuplicateKey(key);
    _singles.putIfAbsent(key, () => factory);
  }

  /// Injects a generated sequence of values into the [Scope]
  /// from a factory method.
  ///
  /// The [sequence]'s factory method may [use] [value]s, [single]s
  /// and other [sequence]s registered within the SAME [Scope].
  ///
  /// The [sequence]'s [factory] method is called each time [use]
  /// for [key] is called.
  ///
  /// The difference between [single] and [sequence] is that
  /// for a [single] the [factory] method is only called once where as
  /// the [sequence]s [factory] method is called each time [use] for
  /// the [sequence]'s [key] is called.
  ///
  /// The [sequence] [factory] method is NOT called when the [runSync] method
  /// is called.
  ///
  /// ```dart
  /// Scope()
  ///   ..sequence<int>(ageKey, () => genRandomInt())
  ///   ..run(() {}
  /// ```
  ///
  void sequence<T>(ScopeKey<T> key, T Function() factory) {
    _checkDuplicateKey(key);
    value<dynamic>(key, factory);
  }

  /// Runs [action] within the defined [Scope].
  Future<R> run<R>(Future<R> Function() action) async {
    _resolveSingles();

    // /// run the action adding our values into the zone map.
    // return runZoned(action, zoneValues: {
    //   _Injector: _Injector(_provided.map<ScopeKey<dynamic>, dynamic>(
    //       (key, dynamic v) => MapEntry<ScopeKey<dynamic>, dynamic>(key, v))),
    // });

    return await runZoned(action, zoneValues: {
      Injector:
          Injector(_provided.map<ScopeKey<dynamic>, dynamic>((key, dynamic v) {
        if (v is Function) {
          return MapEntry<ScopeKey<dynamic>, dynamic>(
              key, key.testFunctionCast(v));
        } else {
          return MapEntry<ScopeKey<dynamic>, dynamic>(key, key.testCast(v));
        }
      })),
    });
  }

  /// Runs [action] within the defined [Scope].
  R runSync<R>(R Function() action) {
    _resolveSingles();

    // /// run the action adding our values into the zone map.
    // return runZoned(action, zoneValues: {
    //   _Injector: _Injector(_provided.map<ScopeKey<dynamic>, dynamic>(
    //       (key, dynamic v) => MapEntry<ScopeKey<dynamic>, dynamic>(key, v))),
    // });

    return runZoned(action, zoneValues: {
      Injector:
          Injector(_provided.map<ScopeKey<dynamic>, dynamic>((key, dynamic v) {
        if (v is Function) {
          return MapEntry<ScopeKey<dynamic>, dynamic>(
              key, key.testFunctionCast(v));
        } else {
          return MapEntry<ScopeKey<dynamic>, dynamic>(key, key.testCast(v));
        }
      })),
    });
  }

  void _resolveSingles() {
    final injector = SingleInjector(_singles);
    runZoned(() {
      injector.zone = Zone.current;
      // Cause [injector] to call all factories.
      for (final key in _singles.keys) {
        /// Resolve the singlton by calling its factory method
        /// and adding to the list of provided values.
        _provided.putIfAbsent(key, () => injector.get<dynamic>(key));
      }
    }, zoneValues: {Injector: injector});
  }

  /// Returns the value provided for [key], or the keys default value if no
  /// value was provided.
  ///
  /// A [MissingDependencyException] will be thrown if the passed [key]
  /// is not in scope.
  ///
  /// A [CircularDependencyException] will be thrown if a circular
  /// dependency is discovered values provided by [single] or [sequence].
  static T use<T>(ScopeKey<T> key, {T Function()? withDefault}) =>
      _use(key, withDefault: withDefault);

  /// Returns true if [key] is contained within the current [Scope]
  /// or an ancestor [Scope]
  ///
  /// For nullable types even if the value is null [hasScopeKey]
  /// will return true if a value was injected.
  static bool hasScopeKey<T>(ScopeKey<T> key) => _hasScopeKey(key);

  /// Returns true if [key] is contained within the current scope
  /// or an ancestor [Scope] or if the [key] has a default value.
  ///
  /// For nullable types even if the value is null [hasScopeValue]
  /// will return true if a value was injected.
  static bool hasScopeValue<T>(ScopeKey<T> key) => _hasScopeValue(key);

  /// Returns true if the caller is running within a [Scope]
  static bool isWithinScope() => _isWithinScope();
}

/// Returns the value injected for [key]
///
/// The key is searched for in the following order
/// and the first value is returned.
///
/// * the hierarchy of [Scope]s
/// * the [GlobalScope].
/// * check if [withDefault] was passed a value
/// * check if the [key] passed a default to [ScopeKey]
///
/// A [MissingDependencyException] will be thrown if the passed [key]
/// is not in any scope and no defaults were found.
///
/// A [CircularDependencyException] will be thrown if a circular
/// dependency is discovered values provided by [Scope.single]
/// or [Scope.sequence].
T use<T>(ScopeKey<T> key, {T Function()? withDefault}) =>
    _use(key, withDefault: withDefault);

T _use<T>(ScopeKey<T> key, {T Function()? withDefault}) {
  final injector =
      (Zone.current[Injector] as Injector?) ?? const Injector.empty();

  T value;
  if (_hasScopeKey(key)) {
    /// we have a [ScopeKey]
    value = injector.get(key);
  } else if (GlobalScope().hasScopeKey(key)) {
    // we have a global key
    value = GlobalScope().use(key);
  } else if (withDefault != null) {
    /// no key but user called 'use' with a default.
    value = withDefault();
  } else {
    /// no key nor value passed to  [withDefault]
    /// so see if the key has a default.
    /// otherwise throw a MissingDependencyException
    value = injector.get(key);
  }

  return value;
}

/// Returns true if [T] was declared as a nullable type (e.g. String?)
bool isNullable<T>() => null is T;

/// Returns true if [key] is contained within the current [Scope]
/// or an ancestor [Scope]
///
/// For nullable types even if the value is null [hasScopeKey]
/// will return true if a value was injected.
bool hasScopeKey<T>(ScopeKey<T> key) => _hasScopeKey(key);

/// Returns true if [key] is contained within the current scope
/// or an ancestor [Scope] or if the [key] has a default value.
///
/// For nullable types even if the value is null [hasScopeValue]
/// will return true if a value was injected.
bool hasScopeValue<T>(ScopeKey<T> key) => _hasScopeValue(key);

/// Returns true if [key] is contained within the current scope
bool _hasScopeValue<T>(ScopeKey<T> key) {
  var hasScopeKey = true;
  final injector =
      (Zone.current[Injector] as Injector?) ?? const Injector.empty();
  if (injector.hasValue(key)) {
    hasScopeKey = true;
  } else {
    hasScopeKey = false;
  }
  return hasScopeKey;
}

/// Returns true if [key] is contained within the current scope
bool _hasScopeKey<T>(ScopeKey<T> key) {
  var hasScopeKey = true;
  final injector =
      (Zone.current[Injector] as Injector?) ?? const Injector.empty();
  if (injector.hasKey(key)) {
    // final value = injector.get(key);
    // if (isNullable<T>() && value == null) {
    //   _hasScopeKey = false;
    // }
    hasScopeKey = true;
  } else {
    hasScopeKey = false;
  }
  return hasScopeKey;
}

/// Returns true if the caller is running within a [Scope]
bool isWithinScope() => _isWithinScope();

bool _isWithinScope() => Zone.current[Injector] != null;
