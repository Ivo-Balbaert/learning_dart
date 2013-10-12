// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Support for observing changes in model-view architectures.
 *
 * **Warning:** This library is experimental, and APIs are subject to change.
 *
 * This library is used to observe changes to [Observable] types. It also
 * has helpers to make implementing and using [Observable] objects easy.
 *
 * You can provide an observable object in two ways. The simplest way is to
 * use dirty checking to discover changes automatically:
 *
 *     class Monster extends Unit with ObservableMixin {
 *       @observable int health = 100;
 *
 *       void damage(int amount) {
 *         print('$this takes $amount damage!');
 *         health -= amount;
 *       }
 *
 *       toString() => 'Monster with $health hit points';
 *     }
 *
 *     main() {
 *       var obj = new Monster();
 *       obj.changes.listen((records) {
 *         print('Changes to $obj were: $records');
 *       });
 *       // No changes are delivered until we check for them
 *       obj.damage(10);
 *       obj.damage(20);
 *       print('dirty checking!');
 *       Observable.dirtyCheck();
 *       print('done!');
 *     }
 *
 * A more sophisticated approach is to implement the change notification
 * manually. This avoids the potentially expensive [Observable.dirtyCheck]
 * operation, but requires more work in the object:
 *
 *     class Monster extends Unit with ChangeNotifierMixin {
 *       int _health = 100;
 *       get health => _health;
 *       set health(val) {
 *         _health = notifyPropertyChange(const Symbol('health'), _health, val);
 *       }
 *
 *       void damage(int amount) {
 *         print('$this takes $amount damage!');
 *         health -= amount;
 *       }
 *
 *       toString() => 'Monster with $health hit points';
 *     }
 *
 *     main() {
 *       var obj = new Monster();
 *       obj.changes.listen((records) {
 *         print('Changes to $obj were: $records');
 *       });
 *       // Schedules asynchronous delivery of these changes
 *       obj.damage(10);
 *       obj.damage(20);
 *       print('done!');
 *     }
 *
 * [Tools](https://www.dartlang.org/polymer-dart/) exist to convert the first
 * form into the second form automatically, to get the best of both worlds.
 */
library observe;

import 'dart:async';
import 'dart:collection';
import 'dart:mirrors';

// Note: this is an internal library so we can import it from tests.
// TODO(jmesserly): ideally we could import this with a prefix, but it caused
// strange problems on the VM when I tested out the dirty-checking example
// above.
import 'src/dirty_check.dart';

part 'src/bind_property.dart';
part 'src/change_notifier.dart';
part 'src/change_record.dart';
part 'src/compound_binding.dart';
part 'src/list_path_observer.dart';
part 'src/observable.dart';
part 'src/observable_box.dart';
part 'src/observable_list.dart';
part 'src/observable_map.dart';
part 'src/path_observer.dart';
part 'src/to_observable.dart';
