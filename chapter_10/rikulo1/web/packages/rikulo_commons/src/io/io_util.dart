//Copyright (C) 2013 Potix Corporation. All Rights Reserved.
//History: Mon, Mar 18, 2013 11:01:44 AM
// Author: tomyeh
part of rikulo_io;

///A collection of I/O related utilities
class IOUtil {
  /** Reads the entire stream as a string using the given [Encoding].
   */
  static Future<String> readAsString(Stream<List<int>> stream, 
      {Encoding encoding: Encoding.UTF_8}) {
    final List<int> result = [];
    return stream.listen((data) {
      result.addAll(data);
    }).asFuture().then((_) {
      return decodeString(result, encoding: encoding);
    });
  }
  /** Reads the entire stream as a JSON string using the given [Encoding],
   * and then convert to an object.
   */
  static Future<dynamic> readAsJson(Stream<List<int>> stream,
      {Encoding encoding: Encoding.UTF_8})
  => readAsString(stream, encoding: encoding).then((data) => Json.parse(data));
}

/** Decodes a list of bytes into a String synchronously.
 */
String decodeString(List<int> bytes, {Encoding encoding: Encoding.UTF_8}) {
  if (bytes.length == 0) return "";

  var string, error;
  var controller = new StreamController(sync: true);
  controller.stream
    .transform(new StringDecoder(encoding))
    .listen((data) => string = data,
      onError: (e) => error = e);
  controller.add(bytes);
  controller.close();
  if (error != null) throw error;
  return string; //note: it is done synchronously
}

/** Encodes a String into a list of bytes synchronously.
 * It will throw an exception if the encoding is invalid.
 */
List<int> encodeString(String string, {Encoding encoding: Encoding.UTF_8}) {
  if (string.length == 0) return [];

  var bytes;
  var controller = new StreamController(sync: true);
  controller.stream
    .transform(new StringEncoder(encoding))
    .listen((data) => bytes = data);
  controller.add(string);
  controller.close();
  return bytes;
}
