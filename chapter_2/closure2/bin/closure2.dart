main() {
  var lstFun = [];
  for(var i in [10, 20, 30]) {
    lstFun.add( () => print(i) );
  }

  print(lstFun[0]()); //  10  null
  print(lstFun[1]()); //  20  null
  print(lstFun[2]()); //  30  null
}
