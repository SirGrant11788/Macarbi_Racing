  import 'package:firebase_database/firebase_database.dart';
Map productData={};
readData()
{
  final databaseReference = FirebaseDatabase.instance.reference();
  databaseReference.once().then((DataSnapshot snapshot) {
  productData = snapshot.value;
  print("DB READ readData()!!!");
  });
  return productData;
}