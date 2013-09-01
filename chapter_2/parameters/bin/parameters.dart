main() {
  print(webLanguage());  // The best web language is: null
  print(webLanguage('JavaScript')); // The best web language is: JavaScript
  print(webLanguage2()); // The best web language is: Dart
  print(webLanguage2('JavaScript')); // The best web language is: JavaScript

// optional positional parameters [param]:
  print(hi('hi')); // hi from null to null
  print(hi('hi', 'me')); // hi from me to null
  print(hi('hi', 'me', 'you')); // hi from me to you
// optional positional parameters with default values [param=value]:
  print(hi2('hi')); // hi from me to you
  print(hi2('hi', 'him')); // hi from him to you
  print(hi2('hi', 'him', 'her')); // hi from him to her
// optional named parameters {param}:
  print(hi3('hi')); // hi from null to null
  print(hi3('hi', to:'you')); // hi from null to you
  print(hi3('hi',  to:'you', from:'me')); // hi from me to you
// optional named parameters with default values {param:value}:
  print(hi4('hi')); // hi from me to you
  print(hi4('hi', to:'her')); // hi from me to her
  print(hi4('hi', from:'you')); // hi from you to you

}

webLanguage([name]) =>  'The best web language is: $name';
webLanguage2([name='Dart']) =>  'The best web language is: $name';

String hi(String msg, [String from, String to]) => '$msg from $from to $to';
String hi2(String msg, [String from='me', String to='you'])
                                                => '$msg from $from to $to';
String hi3(String msg, {String from, String to})
                                                => '$msg from $from to $to';
String hi4(String msg, {String from:'me', String to:'you'})
                                                => '$msg from $from to $to';