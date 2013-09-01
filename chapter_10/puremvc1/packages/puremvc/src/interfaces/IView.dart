part of puremvc;

/**
 * The interface definition for a PureMVC MultiCore View.
 *
 * In PureMVC, [IView] implementors assume these responsibilities:
 *
 * -  Maintain a cache of [IMediator] instances.
 * -  Provide methods for registering, retrieving, and removing [IMediator]s.
 * -  Managing the [IObserver] lists for each [INotification].
 * -  Providing a method for attaching [IObserver]s to an [INotification]'s [IObserver] list.
 * -  Providing a method for broadcasting an [INotification] to each of the [IObserver]s in a list.
 * -  Notifying the [IObservers] of a given [INotification] when it broadcast.
 *
 * See [IMediator], [IObserver], [INotification]
 */
abstract class IView
{
  /**
   * Register an [IObserver] to be notified of [INotification]s with a given name.
   *
   * -  Param [noteName] - the name of the [INotification] to notify this [IObserver] of.
   * -  Param [observer] - the [IObserver] to register.
   */
  void registerObserver( String noteName, IObserver observer);

  /**
   * Remove an [IObserver] from the list for a given [INotification] name.
   *
   * -  Param [noteName] - which [IObserver] list to remove from.
   * -  Param [notifyContext] - remove [IObserver]s with this object as the [notifyContext].
   */
  void removeObserver( String noteName, Object notifyContext );

  /**
   * Notify the [IObserver]s for a particular [INotification].
   *
   * All previously attached [IObserver]s for this [INotification]'s
   * list are notified and are passed a reference to the [INotification] in
   * the order in which they were registered.
   *
   * -  Param [note] - the [INotification] to notify [IObservers] of.
   */
  void notifyObservers( INotification note );

  /**
   * Register an [IMediator] instance with the [IView].
   *
   * Registers the [IMediator] so that it can be retrieved by name,
   * and interrogates the [IMediator] for its [INotification] interests.
   *
   * If the [IMediator] returns a list of [INotification]
   * names to be notified about, an [Observer] is created encapsulating
   * the [IMediator] instance's [handleNotification] method
   * and registering it as an [IObserver] for all [INotification]s the
   * [IMediator] is interested in.
   *
   * -  Param [mediator] - a reference to the [IMediator] instance.
   */
  void registerMediator( IMediator mediator );

  /**
   * Retrieve an [IMediator] from the [IView].
   *
   * -  Param [mediatorName] - the name of the [IMediator] instance to retrieve.
   * -  Returns [IMediator] - the [IMediator] instance previously registered in this core with the given [mediatorName].
   */
  IMediator retrieveMediator( String mediatorName );

  /**
   * Remove an [IMediator] from the [IView].
   *
   * -  Param [mediatorName] - name of the [IMediator] instance to be removed.
   * -  Returns [IMediator] - the [IMediator] that was removed from this core's [IView].
   */
  IMediator removeMediator( String mediatorName );

  /**
   * Check if an [IMediator] is registered with the [IView].
   *
   * -  Param [mediatorName] - the name of the [IMediator] you're looking for.
   * -  Returns [bool] - whether an [IMediator] is registered in this core with the given [mediatorName].
   */
  bool hasMediator( String mediatorName );

  /**
   * This [IView]'s Multiton key
   */
  void set multitonKey( String key );
  String get multitonKey;

}

