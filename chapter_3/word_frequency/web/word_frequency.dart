import 'dart:html';

void main() {
// binding to the user interface:
  TextAreaElement textArea = query('#text');
  TextAreaElement wordsArea = query('#words');
  var wordsBtn = query('#frequency');
  var clearBtn = query('#clear');

  wordsBtn.onClick.listen((MouseEvent e) {
    wordsArea.value = 'Word: frequency \n';
    var text = textArea.value.trim();
    if (text != '') {
      var wordsList = fromTextToWords(text);
      var wordsMap = analyzeWordFreq(wordsList);
      var sortedWordsList = sortWords(wordsMap);
      sortedWordsList.forEach((word) =>
          wordsArea.value = '${wordsArea.value} \n${word}');
    }
  });

  clearBtn.onClick.listen((MouseEvent e) {
    textArea.value =  wordsArea.value = '';
   });
}

List fromTextToWords(String text) {
  var regexp = new RegExp('\W+');
  var textWithout = text.replaceAll(regexp, '');
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
  var temp = new Map<String, String>();
  wordFreqMap.forEach((k, v) =>
      temp[k] = '${k}: ${v.toString()}');
  var out = temp.values.toList();
  out.sort();
  return out;
}