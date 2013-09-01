part of effects;

class AnimationQueue extends DisposableImpl {
  final TimeManager _timeManager;
  final Set<AnimationCore> _items = new Set<AnimationCore>();

  AnimationQueue(this._timeManager) {
    assert(_timeManager != null);
  }

  @protected
  /**
   * Do not call this method directly. Call [dispose] instead.
   * Subclasses should override this method to implement [Disposable] behavior.
   */
  void disposeInternal() {
    _timeManager.dispose();
    _items.clear();
  }

  // internal: called when creating a new Animation
  void _add(AnimationCore animation) {
    assert(animation != null);
    assert(!_items.contains(animation));
    _items.add(animation);
    animation._start(_timeManager.getNowMilliseconds());
    if(!_timeManager.callbackRegistered) {
      _timeManager.registerCallback(_tick);
    }
  }

  void _tick(num timestamp) {
    final toRemove = [];
    _items.forEach((a) {
      assert(!a.ended);
      if(a._tick(timestamp)) {
        assert(a.ended);
        toRemove.add(a);
      }
    });

    _items.removeAll(toRemove);
  }

  //
  // Static instance management
  //
  static AnimationQueue _instance;
  static TimeManagerFactory _timeManagerFactory;

  static AnimationQueue _getInstance() {
    if(_instance == null) {
      _instance = new AnimationQueue(_createTimeManager());
    }
    return _instance;
  }

  // mostly here for testing
  static void disposeInstance() {
    if(_instance != null) {
      _instance.dispose();
      _instance = null;
    }
  }

  static void set timeManagerFactory(TimeManagerFactory value) {
    _timeManagerFactory = value;
  }

  static TimeManager _createTimeManager() {
    if(_timeManagerFactory != null) {
      return _timeManagerFactory();
    } else {
      throw 'no default time manager factory...yet';
    }
  }
}
