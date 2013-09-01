part of puremvc;

/**
 * The interface definition for a PureMVC [Notifier].
 *
 * [MacroCommand], [SimpleCommand], [Mediator] and [Proxy]
 * all have a need to send [Notification]s.
 *
 * The [INotifier] interface provides a common method called
 * [sendNotification] that relieves implementation code of
 * the necessity to actually construct [INotification]s.
 *
 * The [Notifier] class, which all of the above mentioned classes
 * extend, also provides an initialized reference to the [Facade]
 * Multiton, which is required for the convienience method
 * for sending [Notification]s, but also eases implementation as these
 * classes have frequent [IFacade] interactions and usually require
 * access to the facade anyway.
 *
 * See [IFacade], [INotification]
 */
abstract class INotifier {

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
  void sendNotification( String noteName, [dynamic body, String type] );

  /**
   * Initialize this [INotifier] instance.
   *
   * This is how a [INotifier] gets its [multitonKey].
   * Calls to [sendNotification] or access to the
   * [facade] will fail until after this method
   * has been called.
   *
   * -  Param [key] - the Multiton key for this [INotifier].
   */
  void initializeNotifier( String key );

  /**
   * This INotifier's Multiton Key
   */
  void set multitonKey( String key );
  String get multitonKey;

}
