class CurrencyFormatter {
  const CurrencyFormatter._();

  static String lkr(num value) {
    final rounded = value.round();
    final text = rounded.toString();
    final buffer = StringBuffer();

    for (var i = 0; i < text.length; i++) {
      final remaining = text.length - i;
      buffer.write(text[i]);

      if (remaining > 1 && remaining % 3 == 1) {
        buffer.write(',');
      }
    }

    return 'Rs. $buffer';
  }
}
