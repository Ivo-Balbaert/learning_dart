part of puremvc;

/**
 * The interface definition for a PureMVC MultiCore Facade.
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
 * See [IModel], [IView], [IController], [IProxy], [IMediator], [ICommand], [INotification]
 */
abstract class IFacade extends INotifier
{

	/**
     * Register an [IProxy] instance with the [IModel].
     *
     * -  Param [proxy] - an object reference to be held by the [IModel].
	 */
	void registerProxy( IProxy proxy );

    /**
     * Retrieve an [IProxy] instance from the [IModel].
     *
     * -  Param [proxyName] - the name of the [IProxy] instance to retrieve.
     * -  Returns the [IProxy] instance previously registered with the given [proxyName].
     */
    IProxy retrieveProxy( String proxyName );

    /**
     * Remove an [IProxy] instance from the [IModel].
     *
     * -  Param [proxyName] - name of the [IProxy] instance to be removed.
     * -  Returns [IProxy] - the [IProxy] that was removed from the [IModel].
     */
    IProxy removeProxy( String proxyName );

    /**
     * Check if an [IProxy] is registered with the [IModel].
     *
     * -  Param [proxyName] - the name of the [IProxy] instance you're looking for.
     * -  Returns [bool] - whether an [IProxy] is currently registered with the given [proxyName].
     */
    bool hasProxy( String proxyName );

    /**
     * Register an [INotification] to [ICommand] mapping with the [IController].
     *
     * -  Param [noteName] - the name of the [INotification] to associate the [ICommand] with.
     * -  Param [commandFactory] - a function that creates a new instance of the [ICommand].
     */
    void registerCommand( String noteName, Function commandFactory );

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
    void registerMediator( IMediator mediator );

    /**
     * Retrieve an [IMediator] from the [IView].
     *
     * -  Param [mediatorName] - the name of the [IMediator] instance to retrieve.
     * -  Returns [IMediator] - the [IMediator] instance previously registered in this core with the given [mediatorName].
     */
    IMediator retrieveMediator( String mediatorName );

    /**
     * Remove an [IMediator] from the [IView].
     *
     * -  Param [mediatorName] - name of the [IMediator] instance to be removed.
     * -  Returns [IMediator] - the [IMediator] that was removed from this core's [IView].
     */
    IMediator removeMediator( String mediatorName );

    /**
     * Check if an [IMediator] is registered with the [IView].
     *
     * -  Param [mediatorName] - the name of the [IMediator] you're looking for.
     * -  Returns [bool] - whether an [IMediator] is registered in this core with the given [mediatorName].
     */
    bool hasMediator( String mediatorName );

    /**
     * Register an [IObserver] to be notified of [INotification]s with a given name.
     *
     * -  Param [noteName] - the name of the [INotification] to notify this [IObserver] of.
     * -  Param [observer] - the [IObserver] to register.
     */
    void registerObserver( String noteName, IObserver observer );

    /**
     * Remove an [IObserver] from the list for a given [INotification] name.
     *
     * -  Param [noteName] - which [IObserver] list to remove from.
     * -  Param [notifyContext] - remove [IObserver]s with this object as the [notifyContext].
     */
    void removeObserver( String noteName, Object notifyContext );

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
    void notifyObservers( INotification notification );

    /**
     * This [IFacade]'s Multiton key
     */
    void set multitonKey( String key );
    String get multitonKey;

    /**
     * This [IFacade]'s [IModel]
     */
    void set model( IModel modelInstance );
    IModel get model;

    /**
     * This [IFacade]'s [IView]
     */
    void set view( IView viewInstance );
    IView get view;

    /**
     * This [IFacade]'s [IController]
     */
    void set controller( IController controllerInstance );
    IController get controller;

}
