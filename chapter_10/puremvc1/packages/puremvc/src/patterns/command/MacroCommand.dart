part of puremvc;

/**
 * A base [ICommand] implementation that synchronously executes other [ICommand]s.
 *
 * An [MacroCommand] maintains an list of [ICommand] factories called 'SubCommands'.
 *
 * When [execute] is called, the [MacroCommand] instantiates and calls [execute] on each of its 'SubCommands' turn.
 * Each 'SubCommand' will be passed a reference to the original [INotification].
 *
 * Unlike [SimpleCommand], your subclass should not override [execute], but instead,
 * should override the [initializeMacroCommand] method, calling [addSubCommand] once for each 'SubCommand' to be executed.
 *
 * See [ICommand], [IController], [INotification], [SimpleCommand], [INotifier]
 */
class MacroCommand extends Notifier implements ICommand
{
  /**
   * Constructor.
   *
   * You should not need to define a constructor,
   * instead, override the [initializeMacroCommand]
   * method.
   */
  MacroCommand()
  {
    subCommands = new List<Function>();
    initializeMacroCommand();
  }

  /**
   * Initialize the [MacroCommand].
   *
   * In your subclass, override this method to initialize the [MacroCommand]'s 'SubCommand' list
   * with [ICommand] factories by calling [addSubCommand].
   *
   * Note that 'SubCommand's may be any [ICommand] implementor, [MacroCommand]s or [SimpleCommands] are both acceptable.
   */
  void initializeMacroCommand(){}

  /**
   * Add a 'SubCommand'.
   *
   * The 'SubCommand' will be called in First In/First Out (FIFO) order.
   *
   * -  Param [commandFactory] - a Function that constructs an instance of an [ICommand].
   */
  void addSubCommand( Function commandFactory )
  {
      subCommands.add( commandFactory );
  }

  /**
   * Execute this [MacroCommand]'s 'SubCommands'.
   *
   * The 'SubCommands' will be called in First In/First Out (FIFO) order.
   *
   * -  Param [note] - the [INotification] object to be passed to each 'SubCommand'.
   */
  void execute( INotification note )
  {
      for ( Function commandFactory in subCommands ) {
          ICommand commandInstance = commandFactory();
          commandInstance.initializeNotifier( multitonKey );
          commandInstance.execute( note );
      }
  }

  // This [MacroCommand]'s 'SubCommands'
  List<Function> subCommands;
}
