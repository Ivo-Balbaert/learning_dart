part of puremvc;

/**
 * The interface definition for a PureMVC MultiCore Proxy.
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
abstract class IProxy extends INotifier
{
    /**
     * Get the [IProxy] [name].
     *
     * -  Returns [String] - the [IProxy] instance [name].
     */
    String getName();

    /**
     * Set the [dataObject].
     *
     * -  Param [Dynamic] - the [dataObject] this [IProxy] will tend.
     */
    void setData( dynamic dataObject );

    /**
     * Get the [dataObject].
     *
     * -  Returns [Dynamic] - the [dataObject].
     */
    dynamic getData();

    /**
     * Called by the [IModel] when the [IProxy] is registered.
     */
    void onRegister( );

    /**
     * Called by the [IModel] when the [IProxy] is removed.
     */
    void onRemove( );

    /**
     * This [IProxy]'s [dataObject].
     */
    void set data( dynamic dataObject );
    dynamic get data;

    /**
     * This [IProxy]'s [name].
     */
    void set name( String proxyName );
    String get name;


}
