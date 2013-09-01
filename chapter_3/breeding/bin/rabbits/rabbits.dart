part of breeding;

String calculateRabbits(int years) {
  // print('$s1 and $_s2');
  calc() => (2 * pow(E, log(GROWTH_FACTOR) * years)).round().toInt();

  var out = "After $years years:\t ${calc()} rabbits";
  return out;
}

