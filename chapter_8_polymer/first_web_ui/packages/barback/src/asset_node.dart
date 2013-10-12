// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library barback.asset_node;

import 'dart:async';

import 'asset.dart';
import 'asset_id.dart';
import 'errors.dart';
import 'transform_node.dart';

/// Describes the current state of an asset as part of a transformation graph.
///
/// An asset node can be in one of three states (see [AssetState]). It provides
/// an [onStateChange] stream that emits an event whenever it changes state.
///
/// Asset nodes are controlled using [AssetNodeController]s.
class AssetNode {
  /// The id of the asset that this node represents.
  final AssetId id;

  /// The transform that created this asset node.
  ///
  /// This is `null` for source assets. It can change if the upstream transform
  /// that created this asset changes; this change will *not* cause an
  /// [onStateChange] event.
  TransformNode get transform => _transform;
  TransformNode _transform;

  /// The current state of the asset node.
  AssetState get state => _state;
  AssetState _state;

  /// The concrete asset that this node represents.
  ///
  /// This is null unless [state] is [AssetState.AVAILABLE].
  Asset get asset => _asset;
  Asset _asset;

  /// A broadcast stream that emits an event whenever the node changes state.
  ///
  /// This stream is synchronous to ensure that when a source asset is modified
  /// or removed, the appropriate portion of the asset graph is dirtied before
  /// any [Barback.getAssetById] calls emit newly-incorrect values.
  Stream<AssetState> get onStateChange => _stateChangeController.stream;

  /// This is synchronous so that a source being updated will always be
  /// propagated through the build graph before anything that depends on it is
  /// requested.
  final _stateChangeController =
      new StreamController<AssetState>.broadcast(sync: true);

  /// Returns a Future that completes when the node's asset is available.
  ///
  /// If the asset is currently available, this completes synchronously to
  /// ensure that the asset is still available in the [Future.then] callback.
  ///
  /// If the asset is removed before becoming available, this will throw an
  /// [AssetNotFoundException].
  Future<Asset> get whenAvailable {
    return _waitForState((state) => state.isAvailable || state.isRemoved)
        .then((state) {
      if (state.isRemoved) throw new AssetNotFoundException(id);
      return asset;
    });
  }

  /// Returns a Future that completes when the node's asset is removed.
  ///
  /// If the asset is already removed when this is called, it completes
  /// synchronously.
  Future get whenRemoved => _waitForState((state) => state.isRemoved);

  /// Runs [callback] repeatedly until the node's asset has maintained the same
  /// value for the duration.
  ///
  /// This will run [callback] as soon as the asset is available (synchronously
  /// if it's available immediately). If the [state] changes at all while
  /// waiting for the Future returned by [callback] to complete, it will be
  /// re-run as soon as it completes and the asset is available again. This will
  /// continue until [state] doesn't change at all.
  ///
  /// If this asset is removed, this will throw an [AssetNotFoundException] as
  /// soon as [callback]'s Future is finished running.
  Future tryUntilStable(Future callback(Asset asset)) {
    return whenAvailable.then((asset) {
      var modifiedDuringCallback = false;
      var subscription;
      subscription = onStateChange.listen((_) {
        modifiedDuringCallback = true;
        subscription.cancel();
      });

      return callback(asset).then((result) {
        subscription.cancel();

        // If the asset was modified at all while running the callback, the
        // result was invalid and we should try again.
        if (modifiedDuringCallback) return tryUntilStable(callback);
        return result;
      });
    });
  }

  /// Returns a Future that completes as soon as the node is in a state that
  /// matches [test].
  ///
  /// The Future completes synchronously if this is already in such a state.
  Future<AssetState> _waitForState(bool test(AssetState state)) {
    if (test(state)) return new Future.sync(() => state);
    return onStateChange.firstWhere(test);
  }

  AssetNode._(this.id, this._transform)
      : _state = AssetState.DIRTY;

  AssetNode._available(Asset asset, this._transform)
      : id = asset.id,
        _asset = asset,
        _state = AssetState.AVAILABLE;
}

/// The controller for an [AssetNode].
///
/// This controls which state the node is in.
class AssetNodeController {
  final AssetNode node;

  /// Creates a controller for a dirty node.
  AssetNodeController(AssetId id, [TransformNode transform])
      : node = new AssetNode._(id, transform);

  /// Creates a controller for an available node with the given concrete
  /// [asset].
  AssetNodeController.available(Asset asset, [TransformNode transform])
      : node = new AssetNode._available(asset, transform);

  /// Creates a controller for a node whose initial state matches the current
  /// state of [node].
  AssetNodeController.from(AssetNode node)
      : node = new AssetNode._(node.id, node.transform) {
    if (node.state.isAvailable) {
      setAvailable(node.asset);
    } else if (node.state.isRemoved) {
      setRemoved();
    }
  }

  /// Marks the node as [AssetState.DIRTY].
  void setDirty() {
    assert(node._state != AssetState.REMOVED);
    node._state = AssetState.DIRTY;
    node._asset = null;
    node._stateChangeController.add(AssetState.DIRTY);
  }

  /// Marks the node as [AssetState.REMOVED].
  ///
  /// Once a node is marked as removed, it can't be marked as any other state.
  /// If a new asset is created with the same id, it will get a new node.
  void setRemoved() {
    assert(node._state != AssetState.REMOVED);
    node._state = AssetState.REMOVED;
    node._asset = null;
    node._stateChangeController.add(AssetState.REMOVED);
  }

  /// Marks the node as [AssetState.AVAILABLE] with the given concrete [asset].
  ///
  /// It's an error to mark an already-available node as available. It should be
  /// marked as dirty first.
  void setAvailable(Asset asset) {
    assert(asset.id == node.id);
    assert(node._state != AssetState.REMOVED);
    assert(node._state != AssetState.AVAILABLE);
    node._state = AssetState.AVAILABLE;
    node._asset = asset;
    node._stateChangeController.add(AssetState.AVAILABLE);
  }

  /// Sets the node's [AssetNode.transform] property.
  ///
  /// This is used when resolving collisions, where a node will stick around but
  /// a different transform will have created it.
  void setTransform(TransformNode transform) {
    node._transform = transform;
  }
}

// TODO(nweiz): add an error state.
/// An enum of states that an [AssetNode] can be in.
class AssetState {
  /// The node has a concrete asset loaded, available, and up-to-date. The asset
  /// is accessible via [AssetNode.asset]. An asset can only be marked available
  /// again from the [AssetState.DIRTY] state.
  static final AVAILABLE = const AssetState._("available");

  /// The asset is no longer available, possibly for good. A removed asset will
  /// never enter another state.
  static final REMOVED = const AssetState._("removed");

  /// The asset will exist in the future (unless it's removed), but the concrete
  /// asset is not yet available.
  static final DIRTY = const AssetState._("dirty");

  /// Whether this state is [AssetState.AVAILABLE].
  bool get isAvailable => this == AssetState.AVAILABLE;

  /// Whether this state is [AssetState.REMOVED].
  bool get isRemoved => this == AssetState.REMOVED;

  /// Whether this state is [AssetState.DIRTY].
  bool get isDirty => this == AssetState.DIRTY;

  final String name;

  const AssetState._(this.name);

  String toString() => name;
}
