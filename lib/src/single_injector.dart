/* Copyright (C) S. Brett Sutton - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Brett Sutton <bsutton@onepub.dev>, Jan 2022
 */

import 'dart:async';
import 'dart:collection';

import 'exceptions.dart';
import 'injector.dart';
import 'scope.dart';

typedef _ValueFactory<T> = T? Function();

/// Used by [Scope.single].
class SingleInjector extends Injector {
  ///
  final Map<ScopeKey<dynamic>, _ValueFactory<dynamic>> _factories;

  /// All keys from [_factories] for which the factory function has been called
  /// and not yet returned. Iteration order represents call order.
  // ignore: prefer_collection_literals
  final underConstruction = LinkedHashSet<ScopeKey<dynamic>>();

  /// The zone that holds the injected values in this Scope
  /// ```dart
  ///   zone[Injector] == this
  /// ```
  ///
  /// [Scope.single] and [Scope.sequence] values are run in this zone,
  /// so [Scope]s nested in  [Scope.single]  and [Scope.sequence] methods
  /// can't shadow keys from this [Scope].
  late Zone zone;

  ///
  SingleInjector(this._factories) : super(<ScopeKey<dynamic>, dynamic>{});

  @override
  T get<T>(ScopeKey<T> key) {
    if (!_factories.containsKey(key)) {
      return super.get(key);
    }
    if (!values.containsKey(key)) {
      final underConstructionAlready = !underConstruction.add(key);
      if (underConstructionAlready) {
        throw CircularDependencyException(
            List.unmodifiable(underConstruction.skipWhile((t) => t != key)));
      }
      values[key] = zone.run<T>(_factories[key]! as T Function());
      assert(
          underConstruction.last == key, 'The key must be under construction');
      underConstruction.remove(key);
    }
    return values[key] as T;
  }
}
