import 'dart:html';

const int ENTER = 13;
const int CTRL_ENTER = 10;

InputElement task;
UListElement list;
Element header, el;
List<ButtonElement> btns;

main() {
  // event that is fired when the page is loaded:
  window.onLoad.listen( (e) => window.alert("I am at your disposal") );
  // key event:
  window.onKeyPress.listen( (e) {
    if (e.keyCode == ENTER) {
      window.alert("You pressed ENTER");
      
    }
    if (e.ctrlKey && e.keyCode == CTRL_ENTER) {
      window.alert("You pressed CTRL + ENTER");
    }
 });
  task = query('#task');
  list = query('#list');
  //task.onChange.listen( (e) => addItem() );
  task.onChange.listen( (e) {
    var newTask = new LIElement();
    newTask.text = task.value;
    // changing style attribute in cascade:
//    newTask.style
//      ..fontWeight = 'bold'
//      ..fontSize = '3em'
//      ..color = 'red';
    newTask.onClick.listen( (e) => newTask.remove());
    task.value = '';
    list.children.add(newTask);
  });
  // find the h2 header element:
  header = query('.header');
  // find the buttons: 
  btns = queryAll('button');
  // attach event handler to 1st and 2nd buttons:
  btns[0].onClick.listen( (e) => changeColorHeader() );
  btns[1].onDoubleClick.listen( (e) => changeTextPara() );
  // another way to get the same list of buttons:
  var btns2 = queryAll('#btns .backgr');
  btns2[2].onMouseOver.listen( (e) => changePlaceHolder() );
  btns2[2].onClick.listen((e) => changeBtnsBackColor() );
  // alternative:
  // btns2[2].onClick.listen(changeBtnsBackColor);   
  addElements();
}

void addItem() {
  var newTask = new LIElement();
  newTask.id = 'newTask';
  newTask.text = task.value;
  newTask.onClick.listen( (e) => newTask.remove());
  task.value = '';
  list.children.add(newTask);
}

addElements() {
  var ch1 = new CheckboxInputElement();
  ch1.checked = true;
  document.body.children.add(ch1);
  // named Element constructors:
  var par = new Element.tag('p');
  par.text = 'I am a newly created paragraph!';
  document.body.children.add(par);
  el = new Element.html('<div><h4><b>A small div section</b></h4></div>');
  document.body.children.add(el);
  var btn = new ButtonElement();
  btn.text = 'Replace';
  // changing style attribute in via the attributes map:
  // btn.attributes['disabled'] = 'true';
  btn.onClick.listen(replacePar);
  document.body.children.add(btn);
  var btn2 = new ButtonElement();
  btn2.text = 'Delete all list items';
  btn2.onClick.listen( (e) => list.children.clear() );
  document.body.children.add(btn2);
}

replacePar(Event e) {
  var el2 = new Element.html('<div><h4><b>I replaced this div!</b></h4></div>');
  el.replaceWith(el2);  
}

changeColorHeader() => header.classes.toggle('header2');
changeTextPara() => query('#para').text = "You changed my text!";
changePlaceHolder() => task.placeholder = 'Come on, type something in!';
changeBtnsBackColor() => btns.forEach( (b) => b.classes.add('btns_backgr'));
// alternative:
// changeBtnsBackColor(Event e) => btns.forEach( (b) => b.classes.add('btns_backgr'));

