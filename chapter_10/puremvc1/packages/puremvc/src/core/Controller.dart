part of puremvc;

/**
 * A PureMVC MultiCore [IController] implementation.
 *
 * In PureMVC, an [IController] implementor
 * follows the 'Command and Controller' strategy, and
 * assumes these responsibilities:
 *
 * -  Remembering which [ICommand]s are intended to handle which [INotification]s.
 * -  Registering itself as an [IObserver] with the [View] for each [INotification] that it has an [ICommand] mapping for.
 * -  Creating a new instance of the proper [ICommand] to handle a given [INotification] when notified by the [IView].
 * -  Calling the [ICommand]'s [execute] method, passing in the [INotification].
 *
 * See [INotification], [ICommand]
 */
class Controller implements IController
{

  /**
   * Constructor.
   *
   * This [IController] implementation is a Multiton, so you should not call the constructor directly,
   * but instead call the static [getInstance] method.
   *
   * -  Throws [MultitonErrorControllerExists] if instance for this Multiton key has already been constructed
   */
  Controller( String key )
  {
    if ( instanceMap[ key ] != null ) throw new MultitonErrorControllerExists();
    multitonKey = key;
    instanceMap[ multitonKey ] = this;
    commandMap = new Map<String,Function>();
    initializeController();
  }

  /**
   * Initialize the [IController] Multiton instance.
   *
   * Called automatically by the constructor.
   *
   * Note that if you are using a custom [IView] implementor in your application,
   * you should also subclass [Controller] and override the [initializeController] method,
   * setting [view] equal to the return value of a call to [getInstance] on your [IView] implementor.
   */
  void initializeController( )
  {
    view = View.getInstance( multitonKey );
  }

  /**
   * [IController] Multiton Factory method.
   *
   * -  Returns the [IController] Multiton instance for the specified key
   */
  static IController getInstance( String key )
  {
    if ( key == null || key == "" ) return null;
    if ( instanceMap == null ) instanceMap = new Map<String,IController>();
    if ( instanceMap[ key ] == null ) instanceMap[ key ] = new Controller( key );
    return instanceMap[ key ];
  }

  /**
   * Execute the [ICommand] previously registered as the
   * handler for [INotification]s with the given notification's name.
   *
   * -  Param [note] - the [INotification] to execute the associated [ICommand] for
   */
  void executeCommand( INotification note )
  {
    Function commandFactory = commandMap[ note.getName() ];
    if ( commandFactory == null ) return;

    ICommand commandInstance = commandFactory();
    commandInstance.initializeNotifier( multitonKey );
    commandInstance.execute( note );
  }

  /**
   * Register an [INotification] to [ICommand] mapping with the [Controller].
   *
   * -  Param [noteName] - the name of the [INotification] to associate the [ICommand] with.
   * -  Param [commandFactory] - a function that creates a new instance of the [ICommand].
   */
  void registerCommand( String noteName, Function commandFactory )
  {
    if ( commandMap[ noteName ] == null ) {
      view.registerObserver( noteName, new Observer( executeCommand, this ) );
    }
    commandMap[ noteName ] = commandFactory;
  }

  /**
   * Check if an [ICommand] is registered for a given [INotification] name with the [IController].
   *
   * -  Param [noteName] - the name of the [INotification].
   * -  Returns [bool] - whether an [ICommand] is currently registered for the given [noteName].
   */
  bool hasCommand( String noteName )
  {
    return commandMap[ noteName ] != null;
  }

  /**
   * Remove a previously registered [INotification] to [ICommand] mapping from the [IController].
   *
   * -  Param [noteName] - the name of the [INotification] to remove the [ICommand] mapping for.
   */
  void removeCommand( String noteName )
  {
    // if the Command is registered...
    if ( hasCommand( noteName ) )
    {
      // remove the observer
      view.removeObserver( noteName, this );

      // remove the command
      commandMap[ noteName ] = null;
    }
  }

  /**
   * Remove an [IController] instance.
   *
   * -  Param [key] multitonKey of the [IController] instance to remove
   */
  static void removeController( String key )
  {
    instanceMap[ key ] = null;
  }

  // Local reference to this core's IView
  IView view;

  // Mapping of Notification names to Command Class references
  Map<String,Function> commandMap;

  // The Multiton Key for this Core
  String multitonKey;

  // Multiton instance map
  static Map<String,IController> instanceMap;

}

class MultitonErrorControllerExists {
  const MultitonErrorControllerExists();

  String toString() {
    return "IController Multiton instance already constructed for this key.";
  }
}
