//Copyright (C) 2012 Potix Corporation. All Rights Reserved.
//History: Mon, Sep 03, 2012  02:51:12 PM
// Author: hernichen

part of rikulo_mirrors;

final ClassMirror
  LIST_MIRROR = ClassUtil.forName("dart.core.List"),
  MAP_MIRROR = ClassUtil.forName("dart.core.Map"),
  DATE_TIME_MIRROR = ClassUtil.forName("dart.core.DateTime"),
  QUEUE_MIRROR = ClassUtil.forName("dart.collection.Queue"),
  SET_MIRROR = ClassUtil.forName("dart.core.Set"),
  NUM_MIRROR = ClassUtil.forName("dart.core.num"),
  STRING_MIRROR = reflect("").type,
  OBJECT_MIRROR = reflect(const Object()).type,
  INT_MIRROR = reflect(0).type,
  DOUBLE_MIRROR = reflect(0.0).type,
  BOOL_MIRROR = reflect(false).type;

/** Utility class used with Mirror. */
class ClassUtil {
  /**
   * Return the ClassMirror of the qualified class name
   *
   * + [qname] - qualified class name (*libname.classname*), such as
   * `dart:core.List` and `rikulo_mirrors.ClassMirror`.
   */
  static ClassMirror forName(String qname) {
    Map splited = _splitQualifiedName(qname);
    if (splited != null) {
      String libName = splited["lib"];
      String clsName = splited["class"];
      for (final lib in currentMirrorSystem().findLibrary(new Symbol(libName))) {
        final cm = lib.classes[new Symbol(clsName)];
        if (cm != null)
          return cm;
      }
    }
    throw new NoSuchClassError(qname);
  }

  /**
   * Returns whether a source class is assignable to target class.
   *
   * + [tgt] - target class
   * + [src] - source class
   */
  static bool isAssignableFrom(ClassMirror tgt, ClassMirror src) {
    if (tgt.qualifiedName == src.qualifiedName)
      return true;
    if (isTopClass(src)) //no more super class
      return false;

    //TypedefMirror does not implement superinterfaces/superclass
    if (src is TypedefMirror)
      return false;

    //check superinterfaces and superclass
    for (ClassMirror inf in src.superinterfaces)
      if (isAssignableFrom(tgt, inf))
        return true; //recursive

    return isAssignableFrom(tgt, src.superclass); //recursive
  }

  /**
   * Returns the generic element class of the collection class.
   */
  static ClassMirror getElementClassMirror(ClassMirror collection) {
    int idx = isAssignableFrom(MAP_MIRROR, collection) ? 1 : 0;
    return _getElementClassMirror0(collection, idx);
  }

  /**
   * Returns the generic key class of the map class.
   */
  static ClassMirror getKeyClassMirror(ClassMirror map)
    => _getElementClassMirror0(map, 0);

  static ClassMirror _getElementClassMirror0(ClassMirror collection, int idx) {
//TODO(henri): Dart have not implemented typeArguments!
//    List<TypeMirror> vars = collection.typeArguments.getValues();
//    return getCorrespondingClassMirror(vars[idx]);
    return OBJECT_MIRROR;
  }

  /**
   * Returns whether the specified object is an instance of the specified class.
   *
   * + [classMirror] - the class
   * + [instance] - the object
   */
  static bool isInstance(ClassMirror classMirror, Object instance)
    => isAssignableFrom(classMirror, reflect(instance).type);

  static Map<String, String> _splitQualifiedName(String qname) {
    int j = qname.lastIndexOf(".");
    return j < 1 || j >= (qname.length - 1) ?
      {"lib" : null, "class" : qname} :
      {"lib" : qname.substring(0, j), "class" : qname.substring(j+1)};
  }

  /**
   * Returns the types of the specified parameters
   */
  static List<TypeMirror> getParameterTypes(List<ParameterMirror> params) {
    List<TypeMirror> types = new List();
    for (ParameterMirror param in params) {
//TODO(henri) : we have not supported named parameter
//      if (param.isNamed) {
//        continue;
//      }
      types.add(param.type);
    }
    return types;
  }

  /**
   * Invoke a method of the specified instance.
   *
   * + [instance] - the object instance.
   * + [method] - the method
   * + [params] - the positional + optional parameters.
   * + [namedArgs] - the optional named arguments. Ignored if the method is a getter or setter.
   */
  static Object invoke(Object instance, MethodMirror method, List<Object> params,
      [Map<String, Object> namedArgs])
    => invokeByMirror(reflect(instance), method, params, namedArgs);
  /**
   * Invoke a method of the specified ObjectMirror.
   *
   * + [instance] - the ObjectMirror.
   * + [method] - the method.
   * + [params] - the positional + optional parameters.
   * + [namedArgs] - the optional named arguments. Ignored if the method is a getter or setter.
   */
  static Object invokeByMirror(ObjectMirror instance, MethodMirror method,
      List<Object> params, [Map<String, Object> namedArgs]) {
    InstanceMirror result;
    if (method.isGetter) {
      result = instance.getField(method.simpleName);
    } else if (method.isSetter) {
      result = instance.setField(method.simpleName, params[0]);
    } else {
      result = instance.invoke(method.simpleName, params, _toNamedParams(namedArgs));
    }
    return result.reflectee;
  }

  /**
   * apply a closure function.
   *
   * + [function] - the closure function.
   * + [params] - the positional + optional parameters.
   * + [namedArgs] - the optional named arguments.
   */
  static Object apply(Function function, List<Object> params,
      [Map<String, Object> namedArgs])
    => applyByMirror(reflect(function), params, namedArgs);
  /**
   * apply a closure mirror.
   *
   * + [function] - the closure mirror.
   * + [params] - the positional + optional parameters.
   * + [namedArgs] - the optional named arguments.
   */
  static Object applyByMirror(ClosureMirror function, List<Object> params,
      [Map<String, Object> namedArgs])
    => function.apply(params, _toNamedParams(namedArgs)).reflectee;

  ///Converts a list of parameters to Mirror for asynchronous invocation
  static List _toAsyncParams(List params) {
    if (params != null) {
      List ps = new List();
      params.forEach((v) => ps.add(_toAsyncParam(v)));
      return ps;
    }
    return null;
  }
  ///Converts a map of named parameters to Symbol and Mirror for asynchronous invocation
  static Map<Symbol, Object> _toAsyncNamedParams(Map<String, Object> namedArgs) {
    if (namedArgs != null) {
      Map<Symbol, Object> nargs = new HashMap();
      namedArgs.forEach((k,v) => nargs[new Symbol(k)] = _toAsyncParam(v));
      return nargs;
    }
    return null;
  }
  ///Converts a map of named parameters to Symbol for synchronous invocation
  static Map<Symbol, Object> _toNamedParams(Map<String, Object> namedArgs) {
    if (namedArgs != null) {
      Map<Symbol, Object> nargs = new HashMap();
      namedArgs.forEach((k,v) => nargs[new Symbol(k)] = v);
      return nargs;
    }
    return null;
  }
  ///Converts a parameter to Mirror for asynchronous invocation
  static Object _toAsyncParam(var v) {
    if (v == null || v is num || v is bool || v is String || v is Mirror)
      return v;
    return reflect(v);
  }

  /**
   * Returns whether the specified class is the top class (no super class).
   */
  static bool isTopClass(ClassMirror classMirror)
    => OBJECT_MIRROR.qualifiedName == classMirror.qualifiedName || "void" == classMirror.qualifiedName;

  /**
   * Create a new instance of the specified class name.
   */
  static Object newInstance(String className)
    => newInstanceByMirror(forName(className));
  /**
   * Create a new instance of the specified class mirror.
   */
  static Object newInstanceByMirror(ClassMirror classMirror)
    => classMirror.newInstance(const Symbol(""), []).reflectee; //unamed constructor

  /** Coerces the given object to the specified class ([targetClass]).
   *
   * * [coerce] - used to coerce the given object to the given type.
   * If omitted or null is returned, the default coercion will be done (it
   * handles the basic types: `int`, `double`, `String`, `num`, and `Datetime`).
   *
   * It throws [CoercionError] if failed to coerce.
   */
  static coerce(Object instance, ClassMirror targetClass,
      {coerce(o, ClassMirror tClass)}) {
    if (coerce != null) {
      final o = coerce(instance, targetClass);
      if (o != null)
        return o;
    }
    if (instance == null)
      return instance;

    final clz = reflect(instance).type;
    if (isAssignableFrom(targetClass, clz))
      return instance;

    var sval = instance.toString();
    if (targetClass == STRING_MIRROR)
      return sval;
    if (sval.isEmpty)
      return null;
    if (targetClass == INT_MIRROR)
      return int.parse(sval);
    if (targetClass == DOUBLE_MIRROR)
      return double.parse(sval);
    if (targetClass == NUM_MIRROR)
      return sval.indexOf('.') >= 0 ? double.parse(sval): int.parse(sval);
    if (targetClass == DATE_TIME_MIRROR)
      return DateTime.parse(sval);
    if (targetClass == BOOL_MIRROR)
      return !sval.isEmpty && (sval = sval.toLowerCase()) != "false" && sval != "no"
        && sval != "off" && sval != "none";
    throw new CoercionError(instance, targetClass);
  }

  /** Returns the class mirror of the given field (including setter), or null
   * if no such field nor setter.
   */
  static ClassMirror getSetterType(ClassMirror classMirror, String field) {
    var mtd = classMirror.setters[new Symbol("$field=")];
    if (mtd != null)
      return mtd.parameters[0].type;

    mtd = classMirror.members[new Symbol(field)];
    return mtd is VariableMirror ? mtd.type: null;
  }
  /** Returns the class mirror of the given field (including getter), or null
   * if no such field nor getter.
   */
  static ClassMirror getGetterType(ClassMirror classMirror, String field) {
    var mtd = classMirror.getters[new Symbol(field)];
    if (mtd != null)
      return mtd.returnType;

    mtd = classMirror.members[new Symbol(field)];
    return mtd is VariableMirror ? mtd.type: null;
  }
}
