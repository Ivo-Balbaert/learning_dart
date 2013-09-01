part of puremvc;

/**
 * The interface definition for a PureMVC MultiCore Notification.
 *
 * The Observer Pattern as implemented within PureMVC exists
 * to support publish/subscribe communication between actors.
 *
 * [INotification]s are not meant to be a replacement for [Event]s,
 * but rather an internal communication mechanism that ensures
 * PureMVC is portable regardless of what type of Event mechanism
 * is supported (or not) on a given platform.
 *
 * Generally, [IMediator] implementors place [Event] listeners on
 * their view components, and [IProxy] implementors place [Event]
 * listeners on service components. Those [Event]s are then handled in
 * the usual way, and may lead to the broadcast of [INotification]s
 * that trigger [ICommand]s or notify [IMediator]s.
 *
 * See [IView], [IObserver]
 */
abstract class INotification
{

    /**
     * Get the [name] of the [INotification].
     *
     * -  Returns [String] - the name of the [INotification].
     */
    String getName();

    /**
     * Set the [body] of the [INotification].
     *
     * -  Param [body] - the body of the [INotification].
     */
    void setBody( Object body );

    /**
     * Get the [body] of the [INotification].
     *
     * -  Returns [Dynamic] - the body of the [INotification].
     */
    dynamic getBody();

    /**
     * Set the [type] of the [INotification].
     *
     * -  Param [type] - the type of the [INotification].
     */
    void setType( String type );

    /**
     * Get the [type] of the [INotification].
     *
     * -  Returns [String] - the type of the [INotification].
     */
    String getType();

    /**
     * This [INotifications]'s [body]
     */
    void set body( dynamic bodyObject );
    dynamic get body;

    /**
     * This [INotifications]'s [name]
     */
    void set name( String noteName );
    String get name;

    /**
     * This [INotifications]'s [type]
     */
    void set type( String noteType );
    String get type;


}
