part of puremvc;

/**
 * A base [IProxy] implementation.
 *
 * In PureMVC, [IProxy] implementors assume these responsibilities:
 *
 * -  Implement a common method which returns the name of the [IProxy].
 * -  Provide methods for setting and getting a Data Object.
 *
 * Additionally, [IProxy]s typically:
 *
 * -  Provide methods for manipulating the Data Object and referencing it by type.
 * -  Generate [INotification]s when their Data Object changes.
 * -  Expose their name as a [static final String] called [NAME].
 * -  Encapsulate interaction with local or remote services used to fetch and persist data.
 *
 * See [IModel]
 */
class Proxy extends Notifier implements IProxy
{
    /**
     * Constructor
     *
     * -  Param [name] - the [name] this [IProxy] will be registered with.
     * -  Param [data] - the Data Object (optional)
     */
    Proxy( String this.name, [dynamic this.data] ){ }

    /**
     * Get the [IProxy] [name].
     *
     * -  Returns [String] - the [IProxy] instance [name].
     */
    String getName()
    {
        return name;
    }

    /**
     * Set the [dataObject].
     *
     * -  Param [Dynamic] - the [dataObject] this [IProxy] will tend.
     */
    void setData( dynamic dataObject )
    {
       data = dataObject;
    }

    /**
     * Get the [dataObject].
     *
     * -  Returns [Dynamic] - the [dataObject].
     */
    dynamic getData()
    {
        return data;
    }

    /**
     * Called by the [IModel] when the [IProxy] is registered.
     *
     * Override in your subclass and add code to be run at registration time.
     */
    void onRegister(){}

    /**
     * Called by the [IModel] when the [IProxy] is removed
     */
    void onRemove(){}

    /**
     * This [IProxy]'s [name].
     */
    String name;

    /**
     * This [IProxy]'s [dataObject].
     */
    dynamic data;

}
