import 'dart:html';
import 'dart:math';

CanvasRenderingContext2D context;
var width, height;

void main() {
  //get a reference to the canvas
  CanvasElement canvas = query('#canvas');
  width = canvas.width;
  height = canvas.height;
  context = canvas.getContext('2d');
  // lines(); 
  arcs();
}

//drawing lines
void lines() {
  context.moveTo(100, 150);
  context.lineTo(450, 50);
  context.lineWidth = 2;
  context.lineCap = 'round'; // other values: 'square' or 'butt'
  context.stroke(); 
}

//drawing arcs
void arcs() {
  var x = width / 2;
  var y = height / 2;
  var radius = 75;
  var startAngle = 1.1 * PI;
  var endAngle = 1.9 * PI;
  var antiClockWise = false;
  context.arc(x, y, radius, startAngle, endAngle, antiClockWise);
  context.stroke();
}
