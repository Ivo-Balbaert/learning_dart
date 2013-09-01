import 'dart:math';

void main() {
  var n = 0; // number of rabbits

  print("The number of rabbits increases as:\n");
  for (int years = 0; years <= 10; years++) {
    n = (2 * pow(E, log(15) * years)).round().toInt();
    print("After $years years:\t $n animals");
  }
}
