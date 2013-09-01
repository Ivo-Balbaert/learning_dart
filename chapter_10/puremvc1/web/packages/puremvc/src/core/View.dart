part of puremvc;

/**
 * A PureMVC MultiCore [IView] implementation.
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
class View implements IView
{

  /**
   * Constructor.
   *
   * This [IView] implementation is a Multiton, so you should not call the constructor directly,
   * but instead call the static [getInstance] method.
   *
   * -  Throws [MultitonErrorViewExists] if instance for this Multiton key has already been constructed
   */
  View( String key )
  {
    if (instanceMap[ key ] != null) throw new MultitonErrorViewExists();
    multitonKey = key;
    instanceMap[ multitonKey ] = this;
    mediatorMap = new Map<String,IMediator>();
    observerMap = new Map<String,List<IObserver>>();
    initializeView();
  }

  /**
   * Initialize the Multiton View instance.
   *
   * Called automatically by the constructor, this is your opportunity to initialize the Multiton
   * instance in your subclass without overriding the constructor.
   */
  void initializeView(  ){}

  /**
   * [IView] Multiton Factory method.
   *
   * -  Returns the [IView] Multiton instance for the specified key.
   */
  static IView getInstance( String key )
  {
    if ( key == null || key == "" ) return null;
    if ( instanceMap == null ) instanceMap = new Map<String,IView>();
    if ( instanceMap[ key ] == null ) instanceMap[ key ] = new View( key );
    return instanceMap[ key ];
  }

  /**
   * Register an [IObserver] to be notified of [INotification]s with a given name.
   *
   * -  Param [noteName] - the name of the [INotification] to notify this [IObserver] of.
   * -  Param [observer] - the [IObserver] to register.
   */
  void registerObserver( String noteName, IObserver observer )
  {
    if( observerMap[ noteName ] == null ) {
      observerMap[ noteName ] = new List<IObserver>();
    }
    observerMap[ noteName ].add( observer );
  }

  /**
   * Notify the [IObserver]s for a particular [INotification].
   *
   * All previously attached [IObserver]s for this [INotification]'s
   * list are notified and are passed a reference to the [INotification] in
   * the order in which they were registered.
   *
   * -  Param [note] - the [INotification] to notify [IObservers] of.
   */
  void notifyObservers( INotification note )
  {
    // Get a reference to the observers list for this notification name
    List<IObserver> observers_ref = observerMap[ note.getName() ];
    if( observers_ref != null )
    {
      // Copy observers from reference array to working array,
      // since the reference array may change during the notification loop
      List<IObserver> observers = new List<IObserver>();
      IObserver observer;
      for (var i = 0; i < observers_ref.length; i++) {
        observer = observers_ref[ i ];
        observers.add( observer );
      }

      // Notify Observers from the working array
      for (var i = 0; i < observers.length; i++) {
          observer = observers[ i ];
          observer.notifyObserver( note );
      }
    }
  }

  /**
   * Remove an [IObserver] from the list for a given [INotification] name.
   *
   * -  Param [noteName] - which [IObserver] list to remove from.
   * -  Param [notifyContext] - remove [IObserver]s with this object as the [notifyContext].
   */
  void removeObserver( String noteName, Object notifyContext )
  {
      // the observer list for the notification under inspection
      List<IObserver> observers = observerMap[ noteName ];

      // find the observer for the notifyContext
      for ( var i=0; i<observers.length; i++ )
      {
          if ( observers[i].compareNotifyContext( notifyContext ) == true )
          {
              // there can only be one Observer for a given notifyContext
              // in any given Observer list, so remove it and break
              observers.remove(observers[i]);
              break;
          }
      }

      // Also, when a Notification's Observer list length falls to
      // zero, delete the notification key from the observer map
      if ( observers.length == 0 ) {
          observerMap[ noteName ] = null;
      }
  }

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
  void registerMediator( IMediator mediator )
  {
    // do not allow re-registration (you must call removeMediator first)
    if ( mediatorMap[ mediator.getName() ] != null ) return;

    // Initialize with multiton key
    mediator.initializeNotifier( multitonKey );

    // Register the Mediator for retrieval by name
    mediatorMap[ mediator.getName() ] = mediator;

    // Get Notification interests, if any.
    List<String> interests = mediator.listNotificationInterests();

    // Register Mediator as an observer for each notification of interests
    if ( interests.length > 0 )
    {
      // Create Observer referencing this mediator's handlNotification method
      IObserver observer = new Observer( mediator.handleNotification, mediator );

      // Register Mediator as Observer for its list of Notification interests
      for ( var i=0;  i<interests.length; i++ ) {
          registerObserver( interests[i],  observer );
      }
    }

    // alert the mediator that it has been registered
    mediator.onRegister();
  }

  /**
   * Retrieve an [IMediator] from the [IView].
   *
   * -  Param [mediatorName] - the name of the [IMediator] instance to retrieve.
   * -  Returns [IMediator] - the [IMediator] instance previously registered in this core with the given [mediatorName].
   */
  IMediator retrieveMediator( String mediatorName )
  {
      return mediatorMap[ mediatorName ];
  }

  /**
   * Remove an [IMediator] from the [IView].
   *
   * -  Param [mediatorName] - name of the [IMediator] instance to be removed.
   * -  Returns [IMediator] - the [IMediator] that was removed from this core's [IView].
   */
  IMediator removeMediator( String mediatorName )
  {
      // Retrieve the named mediator
      IMediator mediator = mediatorMap[ mediatorName ];

      if ( mediator != null )
      {
        // for every notification this mediator is interested in...
        List<String> interests = mediator.listNotificationInterests();
        for ( var i=0; i<interests.length; i++ )
        {
          // remove the observer linking the mediator
          // to the notification interest
          removeObserver( interests[i], mediator );
        }

        // remove the mediator from the map
        mediatorMap[ mediatorName ] = null;

        // alert the mediator that it has been removed
        mediator.onRemove();
      }

      return mediator;
  }

  /**
   * Check if an [IMediator] is registered with the [IView].
   *
   * -  Param [mediatorName] - the name of the [IMediator] you're looking for.
   * -  Returns [bool] - whether an [IMediator] is registered in this core with the given [mediatorName].
   */
  bool hasMediator( String mediatorName )
  {
      return mediatorMap[ mediatorName ] != null;
  }

  /**
   * Remove an [IView] Multiton instance.
   *
   * -  Param [key] - the Multiton key of [IView] instance to remove.
   */
  static void removeView( String key )
  {
      instanceMap[ key ] = null;
  }

  // Mapping of IMediator names to IMediator instances
  Map<String,IMediator> mediatorMap;

  // Mapping of INotification names to IObserver lists
  Map<String,List<IObserver>> observerMap;

  // Multiton IView instance map
  static Map<String,IView> instanceMap;

  // The Multiton key for this Core
  String multitonKey;
}

class MultitonErrorViewExists {
  const MultitonErrorViewExists();

  String toString() {
    return "IViewMultiton instance already constructed for this key.";
  }
}

