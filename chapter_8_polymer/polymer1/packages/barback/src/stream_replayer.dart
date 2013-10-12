// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library barback.stream_replayer;

import 'dart:async';
import 'dart:collection';

import 'utils.dart';

/// Records the values and errors that are sent through a stream and allows them
/// to be replayed arbitrarily many times.
class StreamReplayer<T> {
  /// The wrapped stream.
  final Stream<T> _stream;

  /// Whether or not [_stream] has been closed.
  bool _isClosed = false;

  /// The buffer of events or errors that have already been emitted by
  /// [_stream].
  ///
  /// Each element is a [Either] that's either a value or an error sent through
  /// the stream.
  final _buffer = new Queue<Either<T, dynamic>>();

  /// The controllers that are listening for future events from [_stream].
  final _controllers = new Set<StreamController<T>>();

  StreamReplayer(this._stream) {
    _stream.listen((data) {
      _buffer.add(new Either<T, dynamic>.withFirst(data));
      for (var controller in _controllers) {
        controller.add(data);
      }
    }, onError: (error) {
      _buffer.add(new Either<T, dynamic>.withSecond(error));
      for (var controller in _controllers) {
        controller.addError(error);
      }
    }, onDone: () {
      _isClosed = true;
      for (var controller in _controllers) {
        controller.close();
      }
      _controllers.clear();
    });
  }

  /// Returns a stream that replays the values and errors of the input stream.
  ///
  /// This stream is a buffered stream regardless of whether the input stream
  /// was broadcast or buffered.
  Stream<T> getReplay() {
    var controller = new StreamController<T>();
    for (var eventOrError in _buffer) {
      eventOrError.match(controller.add, controller.addError);
    }
    if (_isClosed) {
      controller.close();
    } else {
      _controllers.add(controller);
    }
    return controller.stream;
  }
}
