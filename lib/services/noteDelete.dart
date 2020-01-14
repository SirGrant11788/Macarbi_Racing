import 'package:firebase_database/firebase_database.dart';

deleteNote(String title) {
  final databaseReference = FirebaseDatabase.instance.reference();
  databaseReference
      .child('Notes')
      .child('$title')
      .remove();
}