import 'dart:math';

const int NO_YEARS = 10;
const int GROWTH_FACTOR = 15;

void main() {
  print("The number of rabbits increases as:\n");
  for (int years = 0; years <= NO_YEARS; years++) {
    print("${calculateRabbits(years)}");
  }
}

String calculateRabbits(int years) {
  calc(years) => (2 * pow(E, log(GROWTH_FACTOR) * years)).round().toInt();

// long notation:
//  calc(years) {
//    return (2 * pow(E, log(GROWTH_FACTOR) * years)).round().toInt();
//  }

  var out = "After $years years:\t ${calc(years)} animals";
  return out;
}
