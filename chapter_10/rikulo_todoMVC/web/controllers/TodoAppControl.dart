part of todoMVC;

/** The main controller of application.
 */
class TodoAppControl extends Control {
  
  List<Todo> _todos;
  int _completedCount;
  
  List<Todo> get todos => _todos;
  int get completedCount => _completedCount;
  int get activeCount => _todos.length - _completedCount;
  
  TextBox get input => view.query("#new-todo");
  
  TodoAppControl(this._todos) {
    _completedCount = 0;
    _todos.forEach((Todo t) {
      if (t.completed)
        _completedCount++;
    });
  }
  
  void enterNewTodo(DomEvent event) {
    if (event.keyCode == ENTER_KEY) {
      final String title = input.value.trim();
      if (!title.isEmpty) {
        _todos.add(new Todo(title));
        save();
        render();
        input.node.focus();
      }
    }
  }
  
  void selectAll(ChangeEvent<bool> event) {
    final bool completed = event.value;
    _todos.forEach((Todo t) {
      t.completed = completed;
    });
    _completedCount = completed ? _todos.length : 0;
    save();
    render();
  }
  
  void clearCompleted(ViewEvent event) {
    _todos = new List.from(_todos.where((Todo t) => !t.completed));
    _completedCount = 0;
    save();
    render();
  }
  
  void increaseCompleted(bool completed) {
    _completedCount += completed ? 1 : -1;
    save();
    render();
  }
  
  void destroy(Todo t) {
    if (_todos.removeAt(_todos.indexOf(t)).completed)
      _completedCount--;
    save();
    render();
  }
  
  void save() => saveModel(_todos);
  
}
