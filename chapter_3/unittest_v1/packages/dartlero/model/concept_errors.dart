part of dartlero;

class DartleroError extends Error {

  final String msg;

  DartleroError(this.msg);

  toString() => '*** $msg ***';

}

class JsonError extends DartleroError {

  JsonError(String msg) : super(msg);

}

