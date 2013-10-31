import 'dart:html';
import 'dart:math';

const int YEAR_COUNT = 10;
const int GROWTH_FACTOR = 15;

void main() {
  querySelector("#submit").onClick.listen(calcRabbits);
  // alternative:
  //  query("#submit").onClick.listen( (e) => calcRabbits() ); // then in declaration calcRabbits()
}

calcRabbits(e) {
  // binding variables to html elements:
  InputElement yearsInput  = querySelector("#years");
  LabelElement output = querySelector("#output");
  // getting input
  String yearsString = yearsInput.value;
  int years = int.parse(yearsString);
  // calculating and setting output:
  output.innerHtml = "${calculateRabbits(years)}";
}

int calculateRabbits(int years) {
  return (2 * pow(E, log(GROWTH_FACTOR) * years)).round().toInt();
}


