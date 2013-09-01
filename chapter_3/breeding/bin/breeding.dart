library breeding;

import 'dart:math';

part 'constants.dart';
part 'rabbits/rabbits.dart';

String s1 = 'the breeding of cats';
var _s2   = 'the breeding of dogs';

void main() {
  print("The number of rabbits increases as:\n");
  for (int years = 0; years <= NO_YEARS; years++) {
    print("${calculateRabbits(years)}");
  }
  print('$s1 and $_s2');
}