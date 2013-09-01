part of effects;

typedef TimeManager TimeManagerFactory();

abstract class TimeManager extends DisposableImpl {
  int _callbackId;

  bool get callbackRegistered => _callbackId != null;

  void registerCallback(RequestAnimationFrameCallback callback) {
    assert(_callbackId == null);
    assert(callback != null);
    final id = requestFrame(callback);
    assert(id != null);
    _callbackId = id;
  }

  void clearCallback() {
    assert(_callbackId != null);
    cancelAnimationFrame(_callbackId);
    _callbackId = null;
  }

  @protected
  /**
   * Do not call this method directly. Call [dispose] instead.
   * Subclasses should override this method to implement [Disposable] behavior.
   */
  void disposeInternal() {
    if(_callbackId != null) {
      cancelAnimationFrame(_callbackId);
      _callbackId = null;
    }
    super.disposeInternal();
  }

  @protected
  int requestFrame(RequestAnimationFrameCallback callback);

  @protected
  void cancelAnimationFrame(int id);

  @protected
  num getNowMilliseconds();
}
