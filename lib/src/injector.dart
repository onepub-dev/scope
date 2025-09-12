/* Copyright (C) S. Brett Sutton - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Brett Sutton <bsutton@onepub.dev>, Jan 2022
 */

import 'dart:async';

import 'package:meta/meta.dart';

import 'exceptions.dart';
import 'scope.dart';

/// Implements the key store and lookup mechanism. The Injector [Type] is used
/// as the key into a [Zone] to store the injector instance for that zone.
class Injector {
  @protected

  ///
  final Map<ScopeKey<dynamic>, dynamic> values;

  @protected

  ///
  final Injector? parent;

  ///
  Injector(this.values) : parent = Zone.current[Injector] as Injector?;

  ///
  const Injector.empty()
      : values = const <ScopeKey<dynamic>, dynamic>{},
        parent = null;

  /// get the value associated with [key]
  T get<T>(ScopeKey<T> key) {
    if (values.containsKey(key)) {
      dynamic value = values[key];

      /// If the value is a function then we have a sequence
      /// which is called each time [use] is called.
      if (value is Function) {
        // 
        // ignore: avoid_dynamic_calls
        return value = value() as T;
      }

      return value as T;
    }
    if (parent != null) {
      return parent!.get(key);
    }
    if (key.hasDefault) {
      return defaultValue(key);
    }

    if (!isNullable<T>()) {
      throw MissingDependencyException(key);
    }
    return null as T;
  }

  /// true if the [key] is in scope
  /// or if its not in scope but has a default
  /// value.
  bool hasValue<T>(ScopeKey<T> key) {
    if (values.containsKey(key)) {
      return true;
    }
    if (parent != null) {
      return parent!.hasKey(key);
    }
    if (key.hasDefault) {
      return true;
    }

    return false;
  }

  /// true if [key] is in scope.
  bool hasKey<T>(ScopeKey<T> key) {
    if (values.containsKey(key)) {
      return true;
    }
    if (parent != null) {
      return parent!.hasKey(key);
    }

    return false;
  }
}
