import 'dart:html';

void main() {
  // binding to the user interface:
  TextAreaElement textArea = querySelector('#text');
  TextAreaElement wordsArea = querySelector('#words');
  var wordsBtn = querySelector('#frequency');
  var clearBtn = querySelector('#clear');

  wordsBtn.onClick.listen((MouseEvent e) {
    wordsArea.value = 'Word: frequency \n';
    var text = textArea.value.trim();
    if (text != '') {
      var wordsList = fromTextToWords(text);
      var wordsMap = analyzeWordFreq(wordsList);
      var sortedWordsList = sortWords(wordsMap);
      sortedWordsList.skip(1).forEach((word) =>
          wordsArea.value = '${wordsArea.value} \n${word}');
    }
  });

  clearBtn.onClick.listen((MouseEvent e) {
    textArea.value =  wordsArea.value = '';
   });
}

List fromTextToWords(String text) {
  var regexp = new RegExp(r"(\W\s?)");
  var textWithout = text.replaceAll(regexp, ' ');
  return textWithout.split(' ');
}

Map analyzeWordFreq(List wordList) {
  var wordFreqMap = new Map();
  for (var w in wordList) {
    var word = w.trim();
    wordFreqMap.putIfAbsent(word, () => 0);
    wordFreqMap[word] += 1;
  }
  return wordFreqMap;
}

List sortWords(Map wordFreqMap) {
  var temp = new List<String>();
  wordFreqMap.forEach((k, v) => temp.add('${k}: ${v.toString()}'));
  temp.sort();
  return temp;
}