import '../../breeding/bin/breeding.dart';

int years;

void main() {
  years = 5;
  print("The number of rabbits has attained:");
  print("${calculateRabbits(years)}");
  // warning - exception: cannot resolve _s2
  // print('$s1 and $_s2');
}
//The number of rabbits has attained:
//After 5 years:   1518750 rabbits
