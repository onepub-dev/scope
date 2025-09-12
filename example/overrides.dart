//
// ignore_for_file: unreachable_from_main

/* Copyright (C) S. Brett Sutton - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Brett Sutton <bsutton@onepub.dev>, Jan 2022
 */

import 'package:scope/scope.dart';

const userKey = ScopeKey<User>();
const counterKey = ScopeKey<int>();

final globalUser = User('real');
final testUser = User('test');
final innerUser = User('inner');

final globalDb = Db('global_db');
final liveDb = Db('live_db');
final testDb = Db('test_db');
final dbKey = ScopeKey<Db>.withDefault(liveDb);

/// Demonstrates how the `use` method resolves overridden
/// scope keys.
void main() {
  var counter = 0;
  GlobalScope()
    ..value<User>(userKey, globalUser)
    ..sequence<int>(counterKey, () => counter++);

  /// just GlobalScope in scope
  assert(use(userKey) == globalUser, 'take from global scope');

  /// override the GlobalScope with outerscope
  Scope('outerscope')
    ..value<User>(userKey, testUser)
    ..runSync(() {
      assert(use(userKey) == testUser, 'take from outerscope');
      assert(use(counterKey) == 0, 'always from the GlobalScope');
    });
  assert(use(userKey) == globalUser, 'take from GlobalScope');
  assert(use(counterKey) == 1, 'always from the GlobalScope');

  /// override the GlobalScope and outerscope with
  /// innerscope
  Scope('outerscope')
    ..value<User>(userKey, testUser)
    ..runSync(() {
      assert(use(counterKey) == 2, 'always from the GlobalScope');

      Scope('innerscope')
        ..value<User>(userKey, innerUser)
        ..runSync(() {
          assert(use(userKey) == innerUser, 'take from innerscope');
          assert(use(counterKey) == 3, 'always from the GlobalScope');
        });

      assert(use(userKey) == testUser, 'take from outerscope');
    });

  /// we are out of all Scope's so GlobalScope back in play
  assert(use(userKey) == globalUser, 'take from GlobalScope');
  assert(use(counterKey) == 4, 'always from the GlobalScope');

  /// No key in scope; get the keys default
  assert(use(dbKey) == liveDb, 'take from the withDefault value of the dbKey');

  /// No key in scope; use the default value provided to use
  assert(use(dbKey, withDefault: () => testDb) == testDb,
      'take from the withDefault provided to use');

  /// inject a dbKey into the global scope
  GlobalScope().value<Db>(dbKey, globalDb);

  /// Global key in scope; so use it.
  assert(
      use(dbKey, withDefault: () => testDb) == globalDb, 'use the global key');

  /// override the GlobalScope with outerscope
  Scope('outerscope')
    ..value<Db>(dbKey, globalDb)
    ..runSync(() {
      assert(use(dbKey) == globalDb, 'take from outerscope');
      assert(use(counterKey) == 5, 'always from the GlobalScope');
    });
}

class User {
  String name;

  User(this.name);
}

class Db {
  String databaseName;

  Db(this.databaseName);
}
