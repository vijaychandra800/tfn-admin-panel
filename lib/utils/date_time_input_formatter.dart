import 'package:flutter/services.dart';

///
/// Created by Varnica Gupta on 14/03/25
///

class DateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    String text = newValue.text.replaceAll(RegExp(r'[^0-9]'), ''); // Remove non-numeric characters

    if (text.length > 8) {
      text = text.substring(0, 8); // Limit to 8 digits
    }

    String formattedText = '';
    for (int i = 0; i < text.length; i++) {
      formattedText += text[i];
      if ((i == 1 || i == 3) && i < text.length - 1) {
        formattedText += '-'; // Add dash after DD and MM
      }
    }

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
}

class TimeInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    String text = newValue.text.replaceAll(RegExp(r'[^0-9APMapm]'), ''); // Allow only numbers and AM/PM

    if (text.length > 6) {
      text = text.substring(0, 6); // Limit to hh:mm AM/PM
    }

    String formattedText = '';
    for (int i = 0; i < text.length; i++) {
      formattedText += text[i];
      if (i == 1 && text.length > 2) {
        formattedText += ':'; // Add colon after hh
      }
      if (i == 3 && text.length > 4) {
        formattedText += ' '; // Add space before AM/PM
      }
    }

    return TextEditingValue(
      text: formattedText.toUpperCase(), // Convert AM/PM to uppercase
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
}