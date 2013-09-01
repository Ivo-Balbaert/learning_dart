import 'dart:html';

CanvasRenderingContext2D context;

void main() {
  CanvasElement canvas = query('#canvas');
  CanvasRenderingContext2D context = canvas.getContext('2d');
//// 1- drawing quadratic curves:
  context.moveTo(188, 150);
  context.quadraticCurveTo(288, 0, 388, 150);
  context.lineWidth = 8;
  context.strokeStyle = 'yellow';
  context.stroke();
  context.moveTo(188, 130);
//// 2- drawing quadratic curves:
//  context.bezierCurveTo(140, 10, 388, 10, 388, 170);
//  context.lineWidth = 6;
//  context.strokeStyle = 'gray';
//  context.stroke();
//// 3- combining both:
//  context.moveTo(100, 20);
//  // line 1
//  context.lineTo(200, 160);
//  // quadratic curve
//  context.quadraticCurveTo(230, 200, 250, 120);
//  // bezier curve
//  context.bezierCurveTo(290, -40, 300, 200, 400, 150);
//  // line 2
//  context.lineTo(500, 90);
//  context.lineWidth = 5;
//  context.strokeStyle = 'lightblue';
//  context.stroke();
//// 4- line join styles:
//  // set line width for all lines
//  context.lineWidth = 12;
//  // miter line join (left)
//  context.moveTo(99, 150);
//  context.lineTo(149, 50);
//  context.lineTo(199, 150);
//  context.lineJoin = 'miter';
//  context.stroke();
//  // round line join (middle)
//  context.moveTo(239, 150);
//  context.lineTo(289, 50);
//  context.lineTo(339, 150);
//  context.lineJoin = 'round';
//  context.stroke();
//  // bevel line join (right)
//  context.moveTo(379, 150);
//  context.lineTo(429, 50);
//  context.lineTo(479, 150);
//  context.lineJoin = 'bevel';
//  context.stroke();
//// 5- custom shapes:
// begin custom shape
//  context.beginPath();
//  context.moveTo(170, 80);
//  context.bezierCurveTo(130, 100, 130, 150, 230, 150);
//  context.bezierCurveTo(250, 180, 320, 180, 340, 150);
//  context.bezierCurveTo(420, 150, 420, 120, 390, 100);
//  context.bezierCurveTo(430, 40, 370, 30, 340, 50);
//  context.bezierCurveTo(320, 5, 250, 20, 250, 50);
//  context.bezierCurveTo(200, 5, 150, 20, 170, 80);
//  context.closePath();
//   complete custom shape
//  context.lineWidth = 5;
//  context.strokeStyle = 'gray';
//  context.stroke();
//// 6- rectangle with border and interior:
//  context.rect(188, 50, 200, 100);
//  context.fillStyle = 'yellow';
//  context.fill();
//  context.lineWidth = 4;
//  context.strokeStyle = 'black';
//  context.stroke();
//// 7- linear gradients:
//  context.rect(0, 0, canvas.width, canvas.height);
//// add linear gradient
//  var grd = context.createLinearGradient(0, 0, canvas.width, canvas.height);
//// light blue
//  grd.addColorStop(0, '#8ed6ff');
//// dark blue
//  grd.addColorStop(1, '#004cb3');
//  context.fillStyle = grd;
//  context.fill();
//// 8- radial gradients:
//  context.rect(0, 0, canvas.width, canvas.height);
//  var grd = context.createRadialGradient(238, 50, 10, 238, 50, 300);
//  grd.addColorStop(0, '#8ed6ff'); // light blue
//  grd.addColorStop(1, '#004cb3'); // dark blue
//  context.fillStyle = grd;
//  context.fill();
//// 9- draw image:
//  ImageElement spaceShip = query('#space_ship');
//  context.drawImage(spaceShip, 20, 50);
//// 10- drawing text:
//  context.font = "40pt Calibri";
//  context.fillStyle = "blue";
//  context.fillText('Canvas Examples', 150, 100);
}

