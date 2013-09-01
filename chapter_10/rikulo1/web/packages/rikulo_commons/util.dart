//Copyright (C) 2012 Potix Corporation. All Rights Reserved.
//Feb. 04, 2012
library rikulo_util;

//don't include dart:html since this library is designed to work
//at both client and server
import "dart:math";
import "dart:collection";
import "package:meta/meta.dart";

part "src/util/StringUtil.dart";
part "src/util/XmlUtil.dart";
part "src/util/ListUtil.dart";
part "src/util/MapUtil.dart";
part "src/util/Color.dart";
part "src/util/TreeLink.dart";

/** A task that is a function taking no argument and returning nothing.
 */
typedef void Task();
/** A function that returns an integer.
 */
typedef int AsInt();
/** A function that returns a double.
 */
typedef double AsDouble();
/** A function that returns a string.
 */
typedef String AsString();
/** A function that returns a bool.
 */
typedef bool AsBool();

/** A function that returns a map.
 */
typedef Map AsMap();
/** A function that returns a list.
 */
typedef List AsList();
