part of puremvc;

/**
 * A base [IMediator] implementation.
 *
 * In PureMVC, [IMediator] implementors assume these responsibilities:
 *
 * -  Implement a common method which returns a list of all [INotification]s the [IMediator] has interest in.
 * -  Implement a notification (callback) method for handling [INotification]s.
 * -  Implement methods that are called when the [IMediator] is registered or removed from an [IView].
 *
 * Additionally, [IMediator]s typically:
 *
 * -  Act as an intermediary between one or more view components and the rest of the application.
 * -  Place [Event] listeners on view components, and implement handlers which often send [INotification]s or interact with [IProxy]s to post or retrieve data.
 * -  Receive [INotification]s, (typically containing data) and updating view components in response.
 *
 * When an [IMediator] is registered with the [IView], the [IMediator]'s [listNotificationInterests] method is called
 * The [IMediator] will return a [List] of [INotification] names which it wishes to be notified about.
 *
 * The [IView] will then create an [IObserver] object encapsulating that [IMediator]'s and its [handleNotification] method
 * and register the [IObserver] for each [INotification] name returned by the [IMediator]'s [listNotificationInterests] method.
 *
 * See [INotification], [IView]
 */
class Mediator extends Notifier implements IMediator
{

  /**
   * Constructor
   *
   * -  Param [name] - the [name] this [IMediator] will be registered with.
   * -  Param [viewComponent] - the View Component (optional)
   */
  Mediator( String this.name, [dynamic this.viewComponent] ){ }

  /**
   * Get the [IMediator] instance's [name].
   *
   * -  Returns [String] - the [IMediator] instance's [name].
   */
  String getName()
  {
    return name;
  }

  /**
   * Set the [IMediator]'s [viewComponent].
   *
   * -  Param [Dynamic] - the [viewComponent].
   */
  void setViewComponent( dynamic component )
  {
    viewComponent = component;
  }

  /**
   * Get the [IMediator]'s [viewComponent].
   *
   * -  Returns [Dynamic] - the View Component
   */
  dynamic getViewComponent()
  {
    return viewComponent;
  }

  /**
   * List [INotification] interests.
   *
   * -  Returns [List] - a [List] of the [INotification] names this [IMediator] has an interest in.
   */
  List<String> listNotificationInterests( )
  {
    return new List<String>();
  }

  /**
   * Handle an [INotification].
   *
   * -  Param [note] - the [INotification] to be handled.
   */
  void handleNotification( INotification note ) {}

  /**
   * Called by the [IView] when the [IMediator] is registered.
   */
  void onRegister( ) {}

  /**
   * Called by the [IView] when the [IMediator] is removed.
   */
  void onRemove( ) {}

  /**
   * This [IMediator]'s [name].
   */
  String name;

  /**
   * This [IMediator]'s [viewComponent].
   */
  dynamic viewComponent;
}
