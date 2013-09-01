part of todoMVC;

/** The todo item model.
 */
class Todo {
  
  String title;
  bool completed;
  
  Todo(this.title, [this.completed = false]);
  
  // JSON //
  Todo.fromJson(Map m) : this(m["title"], m["completed"]);
  
  Map toJson() => { "title": title, "completed": completed };
  
}
