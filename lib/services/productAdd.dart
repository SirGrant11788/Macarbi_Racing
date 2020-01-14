import 'package:firebase_database/firebase_database.dart';
import 'package:macarbi_racing/services/productsRead.dart';

addProduct(String brand, String name, String price, String stock,
    String weight) {
  final databaseReference = FirebaseDatabase.instance.reference();

  databaseReference
      .child('Products')
      .child('$brand')
      .child('${productData['Products']['$brand'].length - 2}')
      .update({
    'Name': '$name',
    'Price': '$price',
    'Stock': '$stock',
    'Weight': '$weight'
  });
}
