part of puremvc;

/**
 * The interface definition for a PureMVC MultiCore Command.
 *
 * See [IController], [INotification]
 */
abstract class ICommand extends INotifier
{
  /**
   * Execute the [ICommand]'s logic to handle a given [INotification].
   *
   * -  Param [note] - an [INotification] to handle.
   */
  void execute( INotification note );
}
