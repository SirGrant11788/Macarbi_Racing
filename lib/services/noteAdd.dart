import 'package:firebase_database/firebase_database.dart';

addNote(String title, String note) {
  final databaseReference = FirebaseDatabase.instance.reference();
  databaseReference
      .child('Notes')
      .child('$title')
      .update({'Contents': '$note'});
}
