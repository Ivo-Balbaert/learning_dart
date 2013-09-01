import 'dart:math';

const int NO_YEARS = 10;
const int GROWTH_FACTOR = 15;

void main() {
  print("The number of rabbits increases as:\n");
  for (int years = 0; years <= NO_YEARS; years++) {
    lineOut(years, calc(years));
  }
}

calc(years) => (2 * pow(E, log(GROWTH_FACTOR) * years)).round().toInt();

lineOut(yrs, fun) {
  print("After $yrs years:\t ${fun} animals");
}
