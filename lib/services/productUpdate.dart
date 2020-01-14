import 'package:firebase_database/firebase_database.dart';
import 'package:macarbi_racing/services/productsRead.dart';

updateQty(String product, int index, String direction){
  final databaseReference = FirebaseDatabase.instance.reference();
  int stock = int.parse((productData['Products']['$product']['$index']['Stock']));
  if(direction == 'up'){
stock++;
  }if(direction == 'down'){
    stock--;
  }
  databaseReference.child('Products').child('$product').child('$index').update({'Stock':'$stock'});
}

delProduct(String product, int index, String name){
final databaseReference = FirebaseDatabase.instance.reference();
databaseReference.child('Products').child('$product').child('$index').update({'Name':'$name,'});
}

updateProduct(String product, int index, String name, String price, String stock, String weight){
  final databaseReference = FirebaseDatabase.instance.reference();
  databaseReference.child('Products').child('$product').child('$index').update({'Name':'$name'});
  databaseReference.child('Products').child('$product').child('$index').update({'Price':'$price'});
  databaseReference.child('Products').child('$product').child('$index').update({'Stock':'$stock'});
  databaseReference.child('Products').child('$product').child('$index').update({'Weight':'$weight'});
}

updateProductGlobal(String product, String exRate, String shipping){
final databaseReference = FirebaseDatabase.instance.reference();
  databaseReference.child('Products').child('$product').update({'Exchange Rate':'$exRate'});
  databaseReference.child('Products').child('$product').update({'Shipping':'$shipping'});

}
