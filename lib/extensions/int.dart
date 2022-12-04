extension FormattedString on int {
  String toFormattedString() {
    const map = {
      0: '',
      1: '',
      1000: 'K',
      1000000: 'M',
      1000000000: 'G',
      1000000000000: 'T',
    };
    final entry = map.entries.lastWhere((e) => e.key < this);
    return "${(this / entry.key).toStringAsFixed(2)}${entry.value}B";
  }
}
