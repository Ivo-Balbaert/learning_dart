part of puremvc;

/**
 * The interface definition for a PureMVC MultiCore Controller.
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
abstract class IController
{
  /**
   * Register an [INotification] to [ICommand] mapping with the [IController].
   *
   * -  Param [noteName] - the name of the [INotification] to associate the [ICommand] with.
   * -  Param [commandFactory] - a function that creates a new instance of the [ICommand].
   */
  void registerCommand( String notificationName, Function commandFactory );

  /**
   * Execute the [ICommand] previously registered as the
   * handler for [INotification]s with the given notification's name.
   *
   * -  Param [note] - the [INotification] to execute the associated [ICommand] for
   */
  void executeCommand( INotification note );

  /**
   * Remove a previously registered [INotification] to [ICommand] mapping from the [IController].
   *
   * -  Param [noteName] - the name of the [INotification] to remove the [ICommand] mapping for.
   */
  void removeCommand( String noteName );

  /**
   * Check if an [ICommand] is registered for a given [INotification] name with the [IController].
   *
   * -  Param [noteName] - the name of the [INotification].
   * -  Returns [bool] - whether an [ICommand] is currently registered for the given [noteName].
   */
  bool hasCommand( String noteName );

  /**
   * This IController's Multiton Key
   */
  void set multitonKey( String key );
  String get multitonKey;

}
