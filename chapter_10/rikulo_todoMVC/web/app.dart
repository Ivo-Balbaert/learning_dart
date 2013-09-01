library todoMVC;

import 'dart:html';
import 'dart:json' as json;
import 'package:rikulo_ui/view.dart';
import 'package:rikulo_ui/event.dart';
import 'package:rikulo_uxl/uxl.dart';

part 'models/Todo.dart';
part 'views/app.uxl.dart';
part 'controllers/TodoAppControl.dart';
part 'controllers/TodoItemControl.dart';

/** The entry point of Dart application.
 */
void main() {
  TodoMVCTemplate(list: loadModel())[0].addToDocument();
}

/** Load model from local storage, or return an empty [Todo] list if not 
 * available.
 */
List<Todo> loadModel() {
  final List<Todo> list = new List<Todo>();
  final String jsonstr = window.localStorage['todos-rikulo'];
  if (jsonstr != null) {
    try {
      for (Map m in json.parse(jsonstr))
        list.add(new Todo.fromJson(m));
      
    } catch (e) {
      print("Cannot load from local storage.");
    }
  }
  return list;
}

/** Save model to local storage.
 */
void saveModel(List<Todo> list) {
  window.localStorage['todos-rikulo'] = json.stringify(list);
}

final int ENTER_KEY = 13;
