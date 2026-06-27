// ignore_for_file: avoid_print

void dumpJson(dynamic value, {String path = ''}) {
  if (value is Map) {
    value.forEach((key, val) {
      final current = path.isEmpty ? key : '$path.$key';

      print(current);

      dumpJson(val, path: current);
    });
  } else if (value is List) {
    for (int i = 0; i < value.length; i++) {
      dumpJson(value[i], path: '$path[$i]');
    }
  }
}
