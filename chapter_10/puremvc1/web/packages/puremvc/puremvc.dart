/**
 * The PureMVC MultiCore Framework for Dart.
 *
 * - PureMVC is a lightweight framework for creating applications based upon the classic [Model-View-Controller](http://en.wikipedia.org/wiki/Model%E2%80%93view%E2%80%93controller) design meta-pattern.
 * - It supports modular programming through the use of [Multiton](http://en.wikipedia.org/wiki/Multiton_pattern) Core actors.
 * - [PureMVC Dart on Github](https://github.com/PureMVC/puremvc-dart-multicore-framework/wiki)
 * - [PureMVC.org](http://puremvc.org)
 *
 * General Overview:
 *
 * - To separate coding concerns, an application (or a module in an application) is divided into three 'tiers': Model, View, and Controller.
 * - PureMVC implements these tiers as Multiton classes which register and manage communications between the workhorse actors that operate within those tiers.
 * - PureMVC also provides a handy frontend to the whole system called a [Facade](http://en.wikipedia.org/wiki/Facade_pattern).
 * - Since methods for message passing vary from platform to platform, PureMVC implements its own internal Observer Notification system for its actors to communicate with each other. These are not an alternative for Events. Your application's boundary classes will still interact with the DOM and services and PureMVC via Events.
 *
 * The Model Tier is handled by the [Model] Multiton.
 *
 * - In the Model tier, you usually create some [Value Object](http://en.wikipedia.org/wiki/Value_object) classes. These aren't tied to the framework and shouldn't know anything about the framework classes, they just hold data for the rest of the program to use.
 * - The [Model] registers and holds instances of the [Proxy] class (or your subclasses)
 * - [Proxy] instances are registered and retrieved from the [Model] by name.
 * - [Proxy] classes provide access to data, local storage, and remote services. Usually a [Proxy] will manage a single Value Object instance or collection. For example, rather than return raw XML or JSON for the rest of the app to parse, the [Proxy] will convert raw data coming from sevices into typed Value Objects, easily consumed by the rest of the program.
 * - [Proxy] classes do not respond to [Notifications]. They can be directly updated by [Mediator]s and [ICommand]s.
 * - [Proxy] classes should not send Notification names defined elsewhere in the application. They should define their own notification names, so that the classes of the Model tier remain portable and may be unit tested or reused in other applications.
 *
 * The View Tier is handled by the [View] Multiton.
 *
 * - Within the View Tier, you will usually create one or more view components, which you will write to interact directly with the Browser/DOM, listening for button presses, etc. These do not use any PureMVC framework classes and should only know about your Value Object classes in order to display, create, and modify data used by the rest of the app. They will hide the implementation of the DOM from the rest of the app, translating the button clicks and keystrokes into higher-level events that represent user intentions for initiating use-cases.
 * - The [View] Multiton registers and holds instances of [Mediator] subclasses.
 * - [Mediator]s don't do heavy lifting. They are essentially switchboard operators that receive data from the rest of the app via [Notification], and pass it to their view components, or receive events from their view components and in turn pass the user intention on to the rest of the app in the form of a [Notification].
 * - A [Mediator] will tend a particular view component, setting event listeners on it, which it handles usually by sending off [Notification]s to be dealt with by other [Mediator]s and/or [ICommand]s.
 * - A [Mediator] also may assert an interest in certain [Notification] names, which it will be notified about if sent by other actors or itself.
 * - A [Mediator] may also retrieve a [Proxy] and call a method on it, bypassing the Controller tier.
 *
 * The Controller Tier is handled by the [Controller] Multiton.
 *
 * - Within the Controller tier, you will usually create any Notification name constants that are shared by the View and Controller tiers. Remember that Notification names sent from [Proxy]s should be defined on the [Proxy]s themselves for portability.
 * - The [Controller] Multiton registers [Notification] name to [ICommand] mappings.
 * - When a [Notification] with a registered name is sent by a [Proxy], [Mediator], or [ICommand], the mapped [ICommand] is instantiated and its [execute()] method is called, passing in a reference to the [Notification] that triggered the [ICommand].
 * - The framework provides two types of [ICommand] implementors: [MacroCommand] and [SimpleCommand], which you subclass to add SubCommands and business logic, respectively.
 * - The [MacroCommand] executes a given set of [ICommand]s in order, passing the [Notification] to each 'SubCommand' in turn. Note that a SubCommand may modify the [Notification] body and type and the next SubCommand will receive the modified [Notification].
 * - The [SimpleCommand] executes some business logic which you define. It only stays in memory until its code has been executed unless some other actor keeps a reference to it, which usually isn't desirable, but there is a formal request pattern that can be implemented that makes sense ([See the O'Reilly book for info](http://oreil.ly/puremvc)).
 *
 * The [Facade] Multiton provides access to the [Model], [View], and [Controller] Multitons.
 *
 * - This keeps the developer from needing to interact with all the Multitons separately.
 * - The [Facade] Multiton implements all the methods of the the [Model], [View], and [Controller] Multitons and manages their creation.
 * - Calling [Facade.getInstance('someMultitonKey')] for the first time, creates each of the [Model], [View], and [Controller] Multitons for that key automatically. After that, the same instance will always be returned for a given key.
 * - All [Proxy], [Mediator], and [ICommand] instances already have a reference to their [Facade] instance when their [onRegister()] or [execute()] methods are called. Thus you never have to retrieve the [Facade] except when the Core is created.
 *
 * Bootstrapping your Application:
 *
 * - Usually, your main application class will retrieve the Facade instance, register a [StartupCommand], and trigger it by sending a [STARTUP] notification.
 * - The [StartupCommand] may be a [SimpleCommand] or a [MacroCommand] that breaks the startup process into several [SimpleCommands].
 * - Regardless of implementation, the business of the [StartupCommand] is to prepare the [Controller], [Model], and [View] - in that order.
 * - The [Controller] is prepared by registering all the [Notification]/[ICommand] mappings (or at least those needed initially).
 * - The [Model] is prepared by registering all the [Proxy] instances needed. (Don't make service calls at this point).
 * - The [View] is prepared by registering all the [Mediator] instances needed.
 * - When the [Mediator]s are registered, they usually retrieve the [Proxy] instances required to supply their view components with data and potentially make [Proxy] method calls that result in service calls. Those service calls, when they return will usually result in [Notification]s that trigger [ICommand]s and/or one or more [Mediator]s are interested in.
 *
 * MultiCore Functionality:
 *
 * - Applications are composed of one or more 'Core's. A Core is a group of Multitons that share the same multiton key, an arbitrary, but unique name you provide (such as the name of your application).
 * - Although most programs only need one 'Core', you can request more Facade instances using different multiton keys, in order to get multiple, isolated sets of [Model], [View], and [Controller] actors.
 * - This allows you to do modular programming. Each 'Core' is like a separate program. It has its own group of Multitons, its own startup process, and all the workhorse classes communicate with each other through the set of Multitons they were registered with.
 *
 */
library puremvc;
part 'src/interfaces/ICommand.dart';
part 'src/interfaces/INotifier.dart';
part 'src/interfaces/INotification.dart';
part 'src/interfaces/IObserver.dart';
part 'src/interfaces/IMediator.dart';
part 'src/interfaces/IProxy.dart';
part 'src/interfaces/IModel.dart';
part 'src/interfaces/IView.dart';
part 'src/interfaces/IController.dart';
part 'src/interfaces/IFacade.dart';
part 'src/patterns/observer/Observer.dart';
part 'src/patterns/observer/Notification.dart';
part 'src/patterns/observer/Notifier.dart';
part 'src/patterns/proxy/Proxy.dart';
part 'src/patterns/mediator/Mediator.dart';
part 'src/patterns/command/SimpleCommand.dart';
part 'src/patterns/command/MacroCommand.dart';
part 'src/patterns/facade/Facade.dart';
part 'src/core/Model.dart';
part 'src/core/View.dart';
part 'src/core/Controller.dart';
