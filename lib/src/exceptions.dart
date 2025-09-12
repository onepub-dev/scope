/* Copyright (C) S. Brett Sutton - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Brett Sutton <bsutton@onepub.dev>, Jan 2022
 */

import 'package:meta/meta.dart';

import 'scope.dart';

/// Thrown by [use] when no value has been registered in the [Scope]
/// for [_key] and it has no default value.
class MissingDependencyException<T> implements Exception {
  final ScopeKey<T> _key;

  /// Thrown by [use] when no value has been registered in the [Scope]
  /// for [_key] and it has no default value.
  MissingDependencyException(this._key);

  @override
  String toString() => 'MissingDependencyException: '
      'No value has been provided for $_key '
      'and it has no default value.';
}

/// Thrown by [use] when called inside a [Scope.single] or [Scope.sequence]
/// callback and the [keys] factories try to mutually inject each other.
class CircularDependencyException<T> implements Exception {
  @visibleForTesting

  /// The key that caused the circular dependency.
  final List<ScopeKey<T>> keys;

  /// Thrown by [use] when called inside a [Scope.single] or [Scope.sequence]
  /// callback and the [keys] factories try to mutually inject each other.
  CircularDependencyException(this.keys);

  @override
  String toString() => 'CircularDependencyException: The factories for these '
      'keys depend on each other: ${keys.join(" -> ")} -> ${keys.first}';
}

/// Thrown if an attempt is made to inject the same [ScopeKey]
/// twice into the same Scope.
class DuplicateDependencyException<T> implements Exception {
  @visibleForTesting

  /// the key that was a duplicate.
  final ScopeKey<T> key;

  /// Thrown if an attempt is made to inject the same [ScopeKey]
  /// twice.
  DuplicateDependencyException(this.key);

  @override
  String toString() => 'DuplicateDependencyException: '
      'The key $key has already been added to this Scope.';
}
