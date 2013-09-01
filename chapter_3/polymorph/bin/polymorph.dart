main() {
  var duck1 = new Duck();
  var duck2 = new Duck('blue');
  var duck3 = new Duck.yellow();
  // exception: Cannot instantiate abstract class Quackable
  // var duck4 = new Quackable();
  polytest(new Duck()); // Quack   I'm gone, quack!
  polytest(new Person()); // human_quack   I am a person swimming
}

polytest(Duck duck) {
  print('${duck.sayQuack()}');
  print('${duck.swimAway()}');
}

abstract class Quackable {
  String sayQuack();
}

class Duck implements Quackable {
  var color;
  Duck([this.color='red']);
  Duck.yellow() { this.color = 'yellow'; }

  String sayQuack() => 'Quack';
  String swimAway() => "I'm gone, quack!";
}

class Person implements Duck, Quackable {
  var color;
  sayQuack() => 'human_quack';
  // swimAway() => 'I am a person swimming';

  noSuchMethod(mirror) {
     if (mirror.memberName == 'swimAway') print("I'm not really a duck!");
  }
}


