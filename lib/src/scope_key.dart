/* Copyright (C) S. Brett Sutton - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Brett Sutton <bsutton@onepub.dev>, Jan 2022
 */

part of 'scope.dart';

/// The only purpose of [ScopeKey]s is to be globally unique so that they
/// can be used to  uniquely identify injected values. [ScopeKey]s are opaque
/// – you are not supposed to read any other information from them except t
/// heir identity.
///
/// You must NOT extend or implement this class.
///
/// The `debugName` is only used in error messages. We recommend that
/// you use a debugName of the form:
/// `package_name.library_name.variableName`
///
/// If a key is created with a default value, it will be returned by [use]
/// when no value was provided for this key. `null` is a valid default value,
/// provided the [T] is nullable (e.g. String?), and is distinct from no value.
///
/// The type argument [T] is used to infer the return type of [use].
///
/// ```dart
///
/// ScopeKey<int> countKey = ScopeKey<int>(0);
///
/// ScopeKey<int> countKey = ScopeKey.withDefault<int>(0);
/// ```
@sealed
class ScopeKey<T> {
  final String _debugName;

  /// We use [Object] to hold the default as it
  /// can contain [_Sentinel.noValue]
  /// A [_defaultValue] has three states
  /// * [_Sentinel.noValue] indicating no default value
  /// * null - a default value of null has been supplied
  /// * some value.
  final Object? _defaultValue;

  /// Create a ScopeKey with a specific type.
  ///
  /// You MUST provide the type!
  ///
  /// ```dart
  ///  ScopeKey<int> countKey = ScopeKey<int>();
  ///  Scope()
  ///  ..value(countKey, 1)
  ///  .. run(() {
  ///     int count = use(countKey);
  /// });
  /// ```
  const ScopeKey([String? debugName])
      : _defaultValue = _Sentinel.noValue,
        _debugName = debugName ?? 'debugName=?';

  /// Create a ScopeKey that provides a default value if the
  /// key has not been added to the scope.
  ///
  /// ```dart
  ///  ScopeKey<int> countKey = ScopeKey.withDefault<int>(0);
  ///
  ///  int count = use(countKey);
  /// ```
  ScopeKey.withDefault(T defaultValue, [String? debugName])
      : _defaultValue = defaultValue,
        _debugName = debugName ?? 'debugName=?';

  /// Returns true if the key was created with a default value.
  /// A default has three states
  /// * no value set
  /// * null - a default value of null has been supplied
  /// * some value.
  bool get hasDefault => _defaultValue != _Sentinel.noValue;

  /// test if the keys value is of type T.
  T testCast(dynamic v) => v as T;

  /// test if the keys function returns a value of type T.
  T Function() testFunctionCast(dynamic v) => v as T Function();

  @override
  String toString() => 'ScopeKey<${_typeOf<T>()}>($_debugName)';
}

Type _typeOf<T>() => T;

/// Used when callng [ScopeKey()] to indicate that no default value has
/// been provides (as opposed to the default being null)
enum _Sentinel {
  /// Used to indicate that a [ScopeKey] has no default value – which is
  /// different from a default value of `null`.
  noValue
}

/// Returns [ScopeKey._defaultValue]
T defaultValue<T>(ScopeKey<T> key) => key._defaultValue as T;

// /// These cast values are designed to force a [TypeError]
// /// to be thrown at the point of injection of the type of the
// /// passed value doesn't match the type of the key.

// /// test if the keys value is of type T.
// T testCast<T>(ScopeKey<T> key, dynamic v) => v as T;

// /// test if the keys function returns a value of type T.
// dynamic Function() testFunctionCast(ScopeKey<dynamic> key, dynamic v) =>
//     v as T Function();
