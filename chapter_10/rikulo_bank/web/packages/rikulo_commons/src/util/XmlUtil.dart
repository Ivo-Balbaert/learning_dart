//Copyright (C) 2012 Potix Corporation. All Rights Reserved.
//History: Tue, Sep 11, 2012 12:00:59 PM
// Author: tomyeh
part of rikulo_util;

/**
 * XML Utilities.
 */
class XmlUtil {
  static const Map<String, String>
    _decs = const {'lt': '<', 'gt': '>', 'amp': '&', 'quot': '"'},
    _encs = const {'<': 'lt', '>': 'gt', '&': 'amp', '"': 'quot'};

  /** Encodes the string to a valid XML string.
   *
   * + [txt] is the text to encode.
   * + [pre] - whether to replace whitespace with &nbsp;
   * + [multiline] - whether to replace linefeed with <br/>
   * + [maxlength] - the maximal allowed length of the text
   */
  static String encode(String txt,
  {bool multiline: false, int maxlength: 0, bool pre: false}) {
    if (txt == null) return null; //as it is

    int tl = txt.length;
    multiline = pre || multiline;

    if (!multiline && maxlength > 0 && tl > maxlength) {
      int j = maxlength;
      while (j > 0 && StringUtil.isChar(txt[j - 1], whitespace: true))
        --j;
      return encode("${txt.substring(0, j)}...", pre:pre, multiline:multiline);
    }

    final StringBuffer out = new StringBuffer();
    int k = 0;
    String enc;
    if (multiline || pre) {
      for (int j = 0; j < tl; ++j) {
        String cc = txt[j];
        if ((enc = _encs[cc]) != null){
          out..write(txt.substring(k, j))
            ..write('&')..write(enc)..write(';');
          k = j + 1;
        } else if (multiline && cc == '\n') {
          out..write(txt.substring(k, j))..write("<br/>\n");
          k = j + 1;
        } else if (pre && (cc == ' ' || cc == '\t')) {
          out..write(txt.substring(k, j))..write("&nbsp;");
          if (cc == '\t')
            out.write("&nbsp;&nbsp;&nbsp;");
          k = j + 1;
        }
      }
    } else {
      for (int j = 0; j < tl; ++j) {
        if ((enc = _encs[txt[j]]) != null) {
          out..write(txt.substring(k, j))
            ..write('&')..write(enc)..write(';');
          k = j + 1;
        }
      }
    }

    if (k == 0) return txt;
    if (k < tl)
      out.write(txt.substring(k));
    return out.toString();
  }

  /** Decodes the XML string into a normal string.
   * For example, `&lt;` is convert to `<`.
   *
   * + [txt] is the text to decode.
   */
  static String decode(String txt) {
    if (txt == null) return null; //as it is

    final StringBuffer out = new StringBuffer();
    int k = 0, tl = txt.length;
    for (int j = 0; j < tl; ++j) {
      if (txt[j] == '&') {
        int l = txt.indexOf(';', j + 1);
        if (l >= 0) {
          String dec = txt[j + 1] == '#' ?
            new String.fromCharCodes(
              [int.parse(
                txt[j + 2].toLowerCase() == 'x' ? "0x${txt.substring(j + 3, l)}":
                  txt.substring(j + 2, l))]):
            _decs[txt.substring(j + 1, l)];
          if (dec != null) {
            out..write(txt.substring(k, j))..write(dec);
            k = (j = l) + 1;
          }
        }
      }
    }
    return k == 0 ? txt: k < tl ? _sb2s(out, txt.substring(k)): out.toString();
  }
}
