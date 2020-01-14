  import 'package:firebase_database/firebase_database.dart';
Map noteData={};
readNote()
{
  final databaseReference = FirebaseDatabase.instance.reference();
  databaseReference.once().then((DataSnapshot snapshot) {
  noteData = snapshot.value;
  print("DB READ readNote()!!!");
  });
  return noteData;
}