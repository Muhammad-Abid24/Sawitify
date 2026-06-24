import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

import '../model/concert_model.dart';

class ConcertRepository {
  final DatabaseReference _ref = FirebaseDatabase.instanceFor(
    app: Firebase.app(),

    databaseURL:
        'https://sawitify-default-rtdb.asia-southeast1.firebasedatabase.app/',
  ).ref('concerts');

  Future<List<ConcertModel>> getConcerts() async {
    final snapshot = await _ref.child('items').get();

    if (!snapshot.exists) {
      return [];
    }

    final map = Map<String, dynamic>.from(snapshot.value as Map);

    final concerts = map.values
        .map((e) => ConcertModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    concerts.sort((a, b) {
      final aDate = DateTime.tryParse(a.eventDate ?? '');

      final bDate = DateTime.tryParse(b.eventDate ?? '');

      if (aDate == null) {
        return 1;
      }

      if (bDate == null) {
        return -1;
      }

      return aDate.compareTo(bDate);
    });

    return concerts;
  }
}
