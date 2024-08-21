library scrumlab_flutter_masked_text;

import 'package:flutter/material.dart';

class MaskedTextController extends TextEditingController {
  String? mask;
  final Map<String, RegExp>? translator;
  Function(String previous, String next)? afterChange;
  Function(String previous, String next)? beforeChange;

  MaskedTextController(
      {String? text, this.mask, Map<String, RegExp>? translator})
      : translator = translator ?? MaskedTextController.getDefaultTranslator(),
        super(text: text) {
    afterChange = (String previous, String next) {};
    beforeChange = (String previous, String next) => true;

    this.addListener(() {
      var previous = this._lastUpdatedText;
      if (this.beforeChange!(previous, this.text)) {
        this.updateText(this.text);
        this.afterChange!(previous, this.text);
      } else {
        this.updateText(this._lastUpdatedText);
      }
    });

    this.updateText(this.text);
  }

  String _lastUpdatedText = '';

  void updateText(String? text) {
    if (text != null) {
      this.text = this._applyMask(this.mask ?? '', text);
    } else {
      this.text = '';
    }

    this._lastUpdatedText = this.text;
  }

  void updateMask(String? mask, {bool moveCursorToEnd = true}) {
    this.mask = mask;
    this.updateText(this.text);

    if (moveCursorToEnd) {
      this.moveCursorToEnd();
    }
  }

  void moveCursorToEnd() {
    var text = this._lastUpdatedText;
    this.selection =
        TextSelection.fromPosition(TextPosition(offset: (text).length));
  }

  @override
  void set text(String newText) {
    if (super.text != newText) {
      super.text = newText;
      this.moveCursorToEnd();
    }
  }

  static Map<String, RegExp> getDefaultTranslator() {
    return {
      'A': RegExp(r'[A-Za-z]'),
      '0': RegExp(r'[0-9]'),
      '@': RegExp(r'[A-Za-z0-9]'),
      '*': RegExp(r'.*')
    };
  }

  String _applyMask(String mask, String value) {
    String result = '';

    var maskCharIndex = 0;
    var valueCharIndex = 0;

    while (true) {
      if (maskCharIndex == mask.length) break;
      if (valueCharIndex == value.length) break;

      var maskChar = mask[maskCharIndex];
      var valueChar = value[valueCharIndex];

      if (maskChar == valueChar) {
        result += maskChar;
        valueCharIndex += 1;
        maskCharIndex += 1;
        continue;
      }

      if (this.translator!.containsKey(maskChar)) {
        if (this.translator![maskChar]!.hasMatch(valueChar)) {
          result += valueChar;
          maskCharIndex += 1;
        }

        valueCharIndex += 1;
        continue;
      }

      result += maskChar;
      maskCharIndex += 1;
    }

    return result;
  }
}

class MoneyMaskedTextController extends TextEditingController {
  final String decimalSeparator;
  final String thousandSeparator;
  final String rightSymbol;
  final String leftSymbol;
  final int precision;

  Function(String maskedValue, double rawValue)? afterChange;
  double _lastValue = 0.0;

  MoneyMaskedTextController(
      {double initialValue = 0.0,
      this.decimalSeparator = ',',
      this.thousandSeparator = '.',
      this.rightSymbol = '',
      this.leftSymbol = '',
      this.precision = 2}) {
    _validateConfig();

    this.addListener(() {
      this.updateValue(this.numberValue);
      this.afterChange?.call(this.text, this.numberValue);
    });

    this.updateValue(initialValue);
  }

  void updateValue(double value) {
    double valueToUse = value;

    if (value.toStringAsFixed(0).length > 12) {
      valueToUse = _lastValue;
    } else {
      _lastValue = value;
    }

    String masked = this._applyMask(valueToUse);

    if (rightSymbol.isNotEmpty) {
      masked += rightSymbol;
    }

    if (leftSymbol.isNotEmpty) {
      masked = leftSymbol + masked;
    }

    if (masked != this.text) {
      this.text = masked;

      var cursorPosition = super.text.length - this.rightSymbol.length;
      this.selection =
          TextSelection.fromPosition(TextPosition(offset: cursorPosition));
    }
  }

  double get numberValue {
    List<String> parts =
        _getOnlyNumbers(this.text).split('').toList(growable: true);

    parts.insert(parts.length - precision, '.');

    return double.parse(parts.join());
  }

  void _validateConfig() {
    bool rightSymbolHasNumbers = _getOnlyNumbers(this.rightSymbol).length > 0;

    if (rightSymbolHasNumbers) {
      throw ArgumentError("rightSymbol must not have numbers.");
    }
  }

  String _getOnlyNumbers(String text) {
    String cleanedText = text;

    var onlyNumbersRegex = RegExp(r'[^\d]');

    cleanedText = cleanedText.replaceAll(onlyNumbersRegex, '');

    return cleanedText;
  }

  String _applyMask(double value) {
    List<String> textRepresentation = value
        .toStringAsFixed(precision)
        .replaceAll('.', '')
        .split('')
        .reversed
        .toList(growable: true);

    textRepresentation.insert(precision, decimalSeparator);

    for (var i = precision + 4; true; i = i + 4) {
      if (textRepresentation.length > i) {
        textRepresentation.insert(i, thousandSeparator);
      } else {
        break;
      }
    }

    return textRepresentation.reversed.join('');
  }
}
