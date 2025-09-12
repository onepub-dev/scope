// ignore_for_file: document_ignores

/* Copyright (C) S. Brett Sutton - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Brett Sutton <bsutton@onepub.dev>, Jan 2022
 */

import '../scope.dart';
import 'scope.dart';

/// Experimental.
/// Use with caution as the api is likely to change.
/// This is intended as a replacement for Get It
/// but with a consistent api to Scope as well
/// as being sensitive to [ScopeKey]s in [Scope].
/// Values injected into a [GlobalScope] by injecting the
/// same key into a [Scope].
class GlobalScope {
  static final _self = GlobalScope._internal();

  // ignore: strict_raw_type
  final _values = <ScopeKey, dynamic>{};

  /// Get the [GlobalScope] singleon
  factory GlobalScope() => _self;

  GlobalScope._internal();

  ///
  void value<T>(ScopeKey<T> key, T value) {
    _checkDuplicate(key);
    _values.putIfAbsent(key, () => value);
  }

  /// In the [GlobalScope] the [single] method
  /// is no different to the [value] method as the
  /// [GlobalScope] doesn't have a run method.
  /// It does however have access to any [ScopeKey]s
  /// that you have already addes to the [GlobalScope]
  /// any other scope that is active when the [single]
  /// method is called.
  ///
  /// This method is provided for consistency with
  /// the rest of the api.
  void single<T>(ScopeKey<T> key, T Function() factory) {
    _checkDuplicate(key);
    _values.putIfAbsent(key, () => factory());
  }

  ///
  void sequence<T>(ScopeKey<T> key, T Function() factory) {
    _checkDuplicate(key);
    value<dynamic>(key, factory);
  }

  /// Returns the value provided for [key], or the keys default value if no
  /// value was provided.
  ///
  /// A [MissingDependencyException] will be thrown if the passed [key]
  /// is not in scope.
  ///
  /// A [CircularDependencyException] will be thrown if a circular
  /// dependency is discovered values provided by [Scope.single]
  /// or [Scope.sequence].
  T use<T>(ScopeKey<T> key, {T Function()? withDefault}) =>
      _use(key, withDefault: withDefault);

  T _use<T>(ScopeKey<T> key, {T Function()? withDefault}) {
    T value;
    if (hasScopeKey(key)) {
      final dynamic tmpValue = _values[key];
      if (tmpValue is Function) {
        // ignore: avoid_dynamic_calls
        value = tmpValue.call() as T;
      } else {
        value = tmpValue as T;
      }
    } else if (withDefault != null) {
      value = withDefault();
    } else {
      /// the key is not in scope but may still have a default so lets get it
      /// or throw a MissingDependencyException
      value = defaultValue(key);
    }

    return value;
  }

  void _checkDuplicate<T>(ScopeKey<T> key) {
    if (_values.containsKey(key)) {
      throw DuplicateDependencyException(key);
    }
  }

  /// Returns true if [key] is contained within the [GlobalScope].
  ///
  /// For nullable types even if the value is null [hasScopeKey]
  /// will return true if a value was injected.
  bool hasScopeKey<T>(ScopeKey<T> key) => _values.containsKey(key);
}
