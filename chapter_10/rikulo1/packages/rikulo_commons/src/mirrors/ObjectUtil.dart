//Copyright (C) 2013 Potix Corporation. All Rights Reserved.
//History: Tue, Feb 19, 2013 12:33:05 PM
// Author: tomyeh
part of rikulo_mirrors;

/**
 * Object utilities used with mirrors.
 */
class ObjectUtil {
  /** Injects the given values into the given object.
   *
   * For example,
   *
   *     ObjectUtil.inject(instance, {"user.name": userName, "foo": whatever});
   *
   * * [instance] - the object to inject the value.
   * * [values] - the map of values. The key is the field name, such as `name`,
   * `field1.field2` and so on.
   * * [coerce] - used to coerce the given object to the given type.
   * If omitted or null is returned, the default coercion will be done (
   * it handles the basic types: `int`, `double`, `String`, `num`, and `Datetime`).
   * * [onCoerceError] - used to handle the coercion error.
   * If not specified, the exception won't be caught.
   * * [onSetterError] - used to handle the error thrown by a setter.
   * If not specified, the exception won't be caught.
   ** [validate] - used to validate if the coerced value can be assigned.
   * * [silent] - whether to ignore if no field matches the keys of the given
   * values.
   * If false (default), an exception will be thrown.
   *
   * * Returns [instance]
   */
  static Object inject(Object instance, Map<String, dynamic> values,
      {coerce(value, ClassMirror targetClass),
      void onCoerceError(o, String field, value, ClassMirror targetClass, error),
      void onSetterError(o, String field, value, error),
      void validate(o, String field, value),
      bool silent: false}) {
    l_keys:
    for (var key in values.keys) {
      final fields = key.split('.');
      final value = values[key];
      var o2 = instance;
      for (int i = 0, until = fields.length - 1; i < until; ++i) {
        final field = fields[i].trim();

        //nothing to do if silent && no getter matches the first element of fields
        if (silent && ClassUtil.getGetterType(reflect(o2).type, field) == null)
          continue l_keys;

        var o3 = reflect(o2).getField(new Symbol(field)).reflectee;
        if (o3 == null) {
          if (silent && ClassUtil.getSetterType(reflect(o2).type, field) == null)
            continue l_keys;

          if (onSetterError != null) {
            try {
              o3 = _autoCreate(o2, field);
            } catch (err) {
              onSetterError(o2, field, o3, err);
              continue l_keys;
            }
          } else {
            o3 = _autoCreate(o2, field);
          }
        }
        o2 = o3;
      }

      _inject(o2, fields.last.trim(), value,
        coerce, onCoerceError, onSetterError, validate, silent);
    }
    return instance;
  }
  ///Instantiates and injects automatically if a field is null.
  static Object _autoCreate(Object o2, String field) {
    final clz = ClassUtil.getSetterType(reflect(o2).type, field);
    if (clz == null)
      throw new NoSuchMethodError(o2, "$field=", null, null);

    final o3 = clz.newInstance(const Symbol(""), []).reflectee;
      //1. use getSetterType since it will be assigned through setField
      //2. assume there must be a default constructor. otherwise, it is caller's issue
    reflect(o2).setField(new Symbol(field), o3);
    return o3;
  }
  static void _inject(Object instance, String name, value,
      coerce(o, ClassMirror tClass),
      void onCoerceError(o, String field, value, ClassMirror tClass, err),
      void onSetterError(o, String field, value, err),
      void validate(o, String field, value),
      bool silent) {
    final clz = ClassUtil.getSetterType(reflect(instance).type, name);
    if (clz == null) { //not found
      if (!silent) {
        final err = new NoSuchMethodError(instance, "$name=", null, null);
        if (onSetterError == null)
          throw err;
        onSetterError(instance, name, value, err);
      }
      return;
    }

    if (onCoerceError != null) {
      try {
        value = ClassUtil.coerce(value, clz, coerce: coerce);
      } catch (ex) {
        onCoerceError(instance, name, value, clz, ex);
      }
    } else {
      value = ClassUtil.coerce(value, clz, coerce: coerce);
    }

    if (validate != null)
      validate(instance, name, value);

    final om = reflect(instance),
      symbol = new Symbol(name);
    if (onSetterError != null) {
      try {
        om.setField(symbol, value);
      } catch (err) {
        onSetterError(instance, name, value, err);
      }
    } else {
      om.setField(symbol, value);
    }
  }

  /** Injects the given values into the given object asynchronously.
   *
   * Notice that the injection is done asynchronously. To continue after the
   * injection is completed, you have to invoke:
   *
   *     ObjectUtil.inject(obj, {"user.name": userName, "foo": whatever}).then((o) {
   *       //do something after completed
   *       //Note: o is the same as obj
   *     });
   *
   * * [instance] - the object to inject the value.
   * * [values] - the map of values. The key is the field name, such as `name`,
   * `field1.field2` and so on.
   * * [coerce] - used to coerce the given object to the given type.
   * If omitted or null is returned, the default coercion will be done (
   * it handles the basic types: `int`, `double`, `String`, `num`, and `Datetime`).
   * * [onCoerceError] - used to handle the coercion error.
   * If not specified, the exception won't be caught.
   * * [onSetterError] - used to handle the error thrown by a setter.
   * If not specified, the exception won't be caught.
   ** [validate] - used to validate if the coerced value can be assigned.
   * * [silent] - whether to ignore if no field matches the keys of the given
   * values.
   * If false (default), an exception will be thrown.
   */
  static Future injectAsync(Object instance, Map<String, dynamic> values,
      {coerce(value, ClassMirror targetClass),
      void onCoerceError(o, String field, value, ClassMirror targetClass, error),
      void onSetterError(o, String field, value, error),
      void validate(o, String field, value),
      bool silent: false})
  => Future.forEach(values.keys, (key) {
      final fields = key.split('.');
      final value = values[key];
      if (fields.length == 1)
        return _injectAsync(instance, key.trim(), value,
            coerce, onCoerceError, onSetterError, validate, silent);

      //nothing to do if silent && no getter matches the first element of fields
      if (silent && ClassUtil.getGetterType(
          reflect(instance).type, fields.first.trim()) == null)
        return new Future.value(instance);

      key = fields.removeLast();
      var o2 = instance;
      return Future.forEach(fields, (String field) {
        field = field.trim();
        final ret = reflect(o2).getFieldAsync(new Symbol(field)).then((inst) {
          final o3 = inst.reflectee;
          if (o3 == null) {
            final clz = ClassUtil.getSetterType(reflect(o2).type, field);
            if (clz == null) {
              if (silent) {
                o2 = null;
                return; //no return to indicate no further processing
              }
              throw new NoSuchMethodError(o2, "$field=", null, null);
            }
            return clz.newInstanceAsync(const Symbol(""), []);
              //1. use getSetterType since it will be assigned through setField
              //2. assume there must be a default constructor. otherwise, it is caller's issue
          }
          o2 = o3;
          //no return to indicate no further processing
        })
        .then((inst) {
          if (inst != null) { //i.e., newInstance was called
            final o3 = inst.reflectee;
            return reflect(o2).setFieldAsync(new Symbol(field), ClassUtil._toAsyncParam(o3))
              .then((_) {
                o2 = o3;
              });
          }
        });
        return onSetterError == null ? ret: ret.catchError((err) {
          onSetterError(o2, field, null, err);
        });
      }).then((_) => _injectAsync(o2, key.trim(), value,
          coerce, onCoerceError, onSetterError, validate, silent));
    }).then((_) => instance);

  static Future _injectAsync(Object instance, String name, value,
      coerce(o, ClassMirror tClass),
      void onCoerceError(o, String field, value, ClassMirror tClass, err),
      void onSetterError(o, String field, value, err),
      void validate(o, String field, value),
      bool silent) {
    final clz = ClassUtil.getSetterType(reflect(instance).type, name);
    if (clz == null) { //not found
      if (!silent) {
        final err = new NoSuchMethodError(instance, "$name=", null, null);
        if (onSetterError == null)
          throw err;
        onSetterError(instance, name, value, err);
      }
      return new Future.value(instance);
    }

    if (onCoerceError != null) {
      try {
        value = ClassUtil.coerce(value, clz, coerce: coerce);
      } catch (ex) {
        onCoerceError(instance, name, value, clz, ex);
      }
    } else {
      value = ClassUtil.coerce(value, clz, coerce: coerce);
    }

    if (validate != null)
      validate(instance, name, value);

    final ret = reflect(instance).setFieldAsync(new Symbol(name), ClassUtil._toAsyncParam(value))
      .then((_) => instance);
    return onSetterError == null ? ret: ret.catchError((err) {
      onSetterError(instance, name, value, err);
    });
  }
}
