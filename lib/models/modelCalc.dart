import 'package:macarbi_racing/services/productsRead.dart';


calc(int index, String product) 
{

double cpr = double.parse(productData['Products']['$product']['$index']['Price']) * double.parse(productData['Products']['$product']['Exchange Rate']);
double scd = double.parse(productData['Products']['$product']['$index']['Weight']) * double.parse(productData['Products']['$product']['Shipping']);
double scr = scd * double.parse(productData['Products']['$product']['Exchange Rate']);
double iv = (cpr *1.1)*0.15;
double ctu = cpr + scr + iv;
String ctc = (ctu+(ctu*0.3)).toStringAsFixed(0);
String custPrice = '$ctc';
  return custPrice;
}
