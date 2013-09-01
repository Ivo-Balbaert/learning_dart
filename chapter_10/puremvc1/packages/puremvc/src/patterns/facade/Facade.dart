part of puremvc;

/**
 * A base Multiton [IFacade] implementation.
 *
 * The Facade Pattern suggests providing a single
 * class to act as a central point of communication
 * for a subsystem.
 *
 * In PureMVC, the [IFacade] acts as an interface between
 * the core MVC actors [IModel], [IView], [IController], and
 * the rest of your application, which (aside from view components
 * and data objects) is mostly expressed with [ICommand]s,
 * [IMediator]s, and [IProxy]s.
 *
 * This means you don't need to communicate with the [IModel],
 * [IView], [IController] instances directly, you can just go through
 * the [IFacade]. And conveniently, [ICommand]s, [IMediator]s, and
 * [IProxy]s all have a built-in reference to their [IFacade] after
 * initialization, so they're all plugged in and ready to communicate
 * with each other.
 *
 * See [Model], [View], [Controller], [INotification], [ICommand], [IMediator], [IProxy]
 */
class Facade implements IFacade
{
  /**
   * Constructor.
   *
   * This [IFacade] implementation is a Multiton,  so you should not call the constructor directly,
   * but instead call the static [getInstance] method.
   *
   * -  Throws [MultitonErrorFacadeExists] if instance for this Multiton key has already been constructed.
   */
  Facade( String key )
  {
    if ( instanceMap[ key ] != null ) throw new MultitonErrorFacadeExists();
    initializeNotifier( key );
    instanceMap[ multitonKey ] = this;
    initializeFacade();
  }

  /**
   * Initialize the Multiton [Facade] instance.
   *
   * Called automatically by the constructor. Override in your
   * subclass to do any subclass specific initializations. Be
   * sure to call [super.initializeFacade()], though.
   */
  void initializeFacade(  )
  {
    initializeModel();
    initializeController();
    initializeView();
  }

  /**
   * [IFacade] Multiton Factory method
   *
   * -  Returns the [IFacade] Multiton instance for the specified key.
   */
  static IFacade getInstance( String key )
  {
    if ( key == null || key == "" ) return null;
    if ( instanceMap == null ) instanceMap = new Map<String,IFacade>();
    if ( instanceMap[ key ] == null ) instanceMap[ key ] = new Facade( key );
    return instanceMap[ key ];
  }

  /**
   * Initialize the [IController].
   *
   * Called by the [initializeFacade] method.
   *
   * Override this method in a subclass of [Facade] if you want to provide a different [IController].
   */
  void initializeController( )
  {
    if ( controller != null ) return;
    controller = Controller.getInstance( multitonKey );
  }

  /**
   * Initialize the [IModel].
   *
   * Called by the [initializeFacade] method.
   *
   * Override this method in a subclass of [Facade] if you wish to initialize a different [IModel].
   */
  void initializeModel( )
  {
    if ( model != null ) return;
    model = Model.getInstance( multitonKey );
  }


  /**
   * Initialize the [IView].
   *
   * Called by the [initializeFacade] method.
   *
   * Override this method in a subclass of [Facade] if you wish to initialize a different [IView].
   */
  void initializeView( )
  {
    if ( view != null ) return;
    view = View.getInstance( multitonKey );
  }

  /**
   * Register an [INotification] to [ICommand] mapping with the [Controller].
   *
   * -  Param [noteName] - the name of the [INotification] to associate the [ICommand] with.
   * -  Param [commandFactory] - a function that creates a new instance of the [ICommand].
   */
  void registerCommand( String noteName, Function commandFactory )
  {
    controller.registerCommand( noteName, commandFactory );
  }

  /**
   * Remove a previously registered [INotification] to [ICommand] mapping from the [IController].
   *
   * -  Param [noteName] - the name of the [INotification] to remove the [ICommand] mapping for
   */
  void removeCommand( String noteName )
  {
    controller.removeCommand( noteName );
  }

  /**
   * Check if an [ICommand] is registered for a given [INotification] name with the [IController].
   *
   * -  Param [noteName] - the name of the [INotification].
   * -  Returns [bool] - whether an [ICommand] is currently registered for the given [noteName].
   */
  bool hasCommand( String noteName )
  {
    return controller.hasCommand( noteName );
  }

  /**
   * Register an [IProxy] instance with the [IModel].
   *
   * -  Param [proxy] - an object reference to be held by the [IModel].
   */
  void registerProxy( IProxy proxy )
  {
    model.registerProxy( proxy );
  }

  /**
   * Retrieve an [IProxy] instance from the [IModel].
   *
   * -  Param [proxyName] - the name of the [IProxy] instance to retrieve.
   * -  Returns the [IProxy] instance previously registered with the given [proxyName].
   */
  IProxy retrieveProxy( String proxyName )
  {
    return model.retrieveProxy( proxyName );
  }

  /**
   * Remove an [IProxy] instance from the [IModel].
   *
   * -  Param [proxyName] - name of the [IProxy] instance to be removed.
   * -  Returns [IProxy] - the [IProxy] that was removed from the [IModel].
   */
  IProxy removeProxy( String proxyName )
  {
    IProxy proxy;
    if ( model != null ) proxy = model.removeProxy ( proxyName );
    return proxy;
  }

  /**
   * Check if an [IProxy] is registered with the [IModel].
   *
   * -  Param [proxyName] - the name of the [IProxy] instance you're looking for.
   * -  Returns [bool] - whether an [IProxy] is currently registered with the given [proxyName].
   */
  bool hasProxy( String proxyName )
  {
    return model.hasProxy( proxyName );
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
    if ( view != null ) view.registerMediator( mediator );
  }

  /**
   * Retrieve an [IMediator] from the [IView].
   *
   * -  Param [mediatorName] - the name of the [IMediator] instance to retrieve.
   * -  Returns  [IMediator] - the [IMediator] instance previously registered in this core with the given [mediatorName].
   */
  IMediator retrieveMediator( String mediatorName )
  {
    return view.retrieveMediator( mediatorName );
  }

  /**
   * Remove an [IMediator] from the [IView].
   *
   * -  Param [mediatorName] - name of the [IMediator] instance to be removed.
   * -  Returns [IMediator] - the [IMediator] that was removed from this core's [IView].
   */
  IMediator removeMediator( String mediatorName )
  {
    IMediator mediator;
    if ( view != null ) mediator = view.removeMediator( mediatorName );
    return mediator;
  }

  /**
   * Check if a Mediator is registered or not
   *
   * Param [mediatorName]
   * Returns [bool] - whether an [IMediator] is registered in this core with the given [mediatorName].
   */
  bool hasMediator( String mediatorName )
  {
    return view.hasMediator( mediatorName );
  }

  /**
   * Send an [INotification].
   *
   * Convenience method to prevent having to construct new
   * [INotification] instances in our implementation code.
   *
   * -  Param [noteName] the name of the note to send
   * -  Param [body] - the body of the note (optional)
   * -  Param [type] - the type of the note (optional)
   */
  void sendNotification( String noteName, [dynamic body, String type] )
  {
    notifyObservers( new Notification( noteName, body, type ) );
  }

  /**
   * Register an [IObserver] to be notified of [INotification]s with a given name.
   *
   * -  Param [noteName] - the name of the [INotification] to notify this [IObserver] of.
   * -  Param [observer] - the [IObserver] to register.
   */
  void registerObserver( String noteName, IObserver observer )
  {
    view.registerObserver(noteName, observer);
  }

  /**
   * Remove an [IObserver] from the list for a given [INotification] name.
   *
   * -  Param [noteName] - which [IObserver] list to remove from.
   * -  Param [notifyContext] - remove [IObserver]s with this object as the [notifyContext].
   */
  void removeObserver( String noteName, Object notifyContext )
  {
    view.removeObserver( noteName, notifyContext );
  }

  /**
   * Notify [IObserver]s.
   *
   * This method allows you to send custom [INotification] classes using the [IFacade].
   *
   * Usually you should just call [sendNotification] and pass the parameters,
   * never having to construct an [INotification] yourself.
   *
   * -  Param [note] the [INotification] to have the [View] notify [Observers] of.
   */
  void notifyObservers( INotification note )
  {
    if ( view != null ) view.notifyObservers( note );
  }

  /**
   * Initialize this [INotifier].
   *
   * This is how an [INotifier] gets its [multitonKey].
   * Calls to [sendNotification] or to access the
   * [facade] will fail until after this method
   * has been called.
   *
   * -  Param [key] - the [multitonKey] for this [INotifier] to use.
   */
  void initializeNotifier( String key )
  {
    multitonKey = key;
  }

  /**
   * Check if a Core is registered or not.
   *
   * -  Param [key] - the Multiton key for the Core.
   * -  Returns [bool] - whether a Core is registered with the given [key].
   */
  static bool hasCore( String key )
  {
    return ( instanceMap[ key ] != null );
  }

  /**
   * Remove a Core.
   *
   * Remove the [IModel], [IView], [IController], and [IFacade]
   * instances for the given key.</P>
   *
   * -  Param [key] - the Multiton key of the Core to remove.
   */
  static void removeCore( String key )
  {
    if ( instanceMap[ key ] == null ) return;
    Model.removeModel( key );
    View.removeView( key );
    Controller.removeController( key );
    instanceMap[ key ] = null;
  }

  // References to [IModel], [IView], and [IController]
  IController controller;
  IModel model;
  IView view;

  // This [IFacade]'s Multiton key
  String multitonKey;

  // The [IFacade] Multiton instanceMap.
  static Map<String,IFacade> instanceMap;
}

class MultitonErrorFacadeExists {
  const MultitonErrorFacadeExists ();

  String toString() {
    return "IFacade Multiton instance already constructed for this key.";
  }
}

