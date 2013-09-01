part of todoMVC;

/** The controller for [Todo] items.
 */
class TodoItemControl extends Control {
  
  final TodoAppControl _appc;
  final Todo _todo;
  
  TextBox get input => view.query("TextBox.edit");
  TextView get label => view.query("TextView.title");
  
  TodoItemControl(this._appc, this._todo);
  
  void toggleCompleted(ChangeEvent<bool> event) {
    _appc.increaseCompleted(_todo.completed = event.value);
  }
  
  void editTitle(ViewEvent event) {
    view.classes.add("editing");
    input.node.focus();
  }
  
  void enterTitle(DomEvent event) {
    if (event.keyCode == ENTER_KEY)
      input.node.blur();
  }
  
  void submitTitle(ViewEvent event) {
    final String title = input.value.trim();
    if (!title.isEmpty) {
      label.text = _todo.title = title;
      _appc.save();
      view.classes.remove("editing");
    } else 
      destroy();
  }
  
  void destroy([ViewEvent event]) => _appc.destroy(_todo);
  
}
