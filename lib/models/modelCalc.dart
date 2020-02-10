import 'package:macarbi_racing/services/productsRead.dart';


calc(int index, String product) 
{

double cpr = double.parse(productData['Products']['$product']['$index']['Price']) * double.parse(productData['Products']['$product']['Exchange Rate']);//x=Price*Exchange Rate
double scd = double.parse(productData['Products']['$product']['$index']['Weight']) * double.parse(productData['Products']['$product']['Shipping']);//y=weight*Shipping
double scr = scd * double.parse(productData['Products']['$product']['Exchange Rate']);//z=y*Exchange Rate
double iv = (cpr *1.1)*0.15;//m=(x*1.1)*0.15
double ctu = cpr + scr + iv;//n=x+z+m //our cost
String ctc = (ctu+(ctu*0.3)).toStringAsFixed(0);//k=(n+(n*0.3)) //cost to customer (30% mark up)
String custPrice = '$ctc';
  return custPrice;
}
