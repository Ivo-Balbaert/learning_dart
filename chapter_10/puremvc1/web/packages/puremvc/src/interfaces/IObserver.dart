part of puremvc;

/**
 * The interface definition for a PureMVC MultiCore Observer.
 *
 * In PureMVC, [IObserver] implementors assume these responsibilities:
 *
 * -  Encapsulate the notification (callback) method of the interested object.
 * -  Encapsulate the notification context (this) of the interested object.
 * -  Provide methods for setting the interested object's notification method and context.
 * -  Provide a method for notifying the interested object.
 *
 * The Observer Pattern as implemented within PureMVC exists
 * to support publish/subscribe communication between actors.
 *
 * An [IObserver] is an object that encapsulates information
 * about an interested object with a notification (callback)
 * method that should be called when an [INotification] is
 * broadcast. The [IObserver] then acts as a conduit for
 * notifying the interested object.
 *
 * [IObserver]s can receive [Notification]s by having their
 * [notifyObserver] method invoked, passing in an object
 * implementing the [INotification] interface.
 *
 * See [IView], [INotification]
 */
abstract class IObserver
{
    /**
     * Set the notification method.
     *
     * The notification method should take one parameter of type [INotification].
     *
     * -  Param [notifyMethod] - the notification (callback) method of the interested object.
     */
    void setNotifyMethod( Function callback );

    /**
     * Set the notification context.
     *
     * -  Param [caller] - a reference to the object to be notified.
     */
    void setNotifyContext( Object caller );

    /**
     * Get the notification method.
     *
     * -  Returns [Function] - the notification (callback) method of the interested object.
     */
    Function getNotifyMethod();

    /**
     * Get the notification context.
     *
     * -  Returns [Object] - the caller.
     */
    Object getNotifyContext();

    /**
     * Compare a given object to the [notifyContext] (caller) object.
     *
     * -  Param [Object] - the object to compare.
     * -  Returns [bool] - whether the given object and the [notifyContext] (caller) are the same.
     */
    bool compareNotifyContext( Object object );

    /**
     * Notify the interested object.
     *
     * -  Param [note] - the [INotification] to pass to the caller's [notifyMethod].
     */
    void notifyObserver( INotification note );

    /**
     * This [IObserver]'s [notifyMethod] (i.e., callback)
     */
    void set notifyMethod( Function callback );
    Function get notifyMethod;

    /**
     * This [IObserver]'s [notifyContext] (i.e., caller)
     */
    void set notifyContext( Object caller );
    Object get notifyContext;

}

