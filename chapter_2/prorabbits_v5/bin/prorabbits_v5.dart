// function stored in a variable:
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
  var calc = (years) => (2 * pow(E, log(GROWTH_FACTOR) * years)).round().toInt();
  assert(calc is Function);
  var out = "After $years years:\t ${calc(years)} animals";
  return out;
}

