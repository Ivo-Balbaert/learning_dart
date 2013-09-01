part of puremvc;

/**
 * A base [ICommand] implementation for executing a block of business logic.
 *
 * Your subclass should override the [execute] method where your business logic will handle the [INotification].
 *
 * See [ICommand], [IController], [INotification], [MacroCommand], [INotifier]
 */
class SimpleCommand extends Notifier implements ICommand
{

  /**
   * Respond to the [INotification] that triggered this [SimpleCommand].
   *
   * Perform business logic e.g., complex validation, processing, model changes.
   *
   * -  Param [note] - an [INotification] object that triggered the execution of this [SimpleCommand]
   */
  void execute( INotification note ){ }

}