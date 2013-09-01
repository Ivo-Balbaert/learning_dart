void main() {
  Animal an1 = new Animal();
  print('${an1.makeNoise()}'); // Miauw
}

abstract class Animal {
  String makeNoise();
  factory Animal() => new Cat();
}

class Cat implements Animal {
  String makeNoise() => "Miauw";
}