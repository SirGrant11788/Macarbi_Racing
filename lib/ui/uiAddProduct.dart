import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:macarbi_racing/services/productAdd.dart';

class AddProductPage extends StatefulWidget {
  @override
  _AddProductPageState createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {

  TextEditingController _textFieldControllerName = TextEditingController();
  TextEditingController _textFieldControllerPrice = TextEditingController();
  TextEditingController _textFieldControllerStock = TextEditingController();
  TextEditingController _textFieldControllerWeight = TextEditingController();

  _onClear() {
    setState(() {
      _textFieldControllerName.text = "";
      _textFieldControllerPrice.text = "";
      _textFieldControllerStock.text = "";
      _textFieldControllerWeight.text = "";
    });
  }
  //todo auto drop list
  static const menuItems = <String>[
    'NK',
    'ActiveTools',
    'Coxmate',
    'Concept 2',
    'Croker',
    'Hudson',
    'Swift',
    'Rowshop',
  ];
  final List<DropdownMenuItem<String>> _dropDownMenuItems = menuItems
      .map(
        (String value) => DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        ),
      )
      .toList();
  String _btnSelectedVal;
  bool _weight;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Add Product"),
      ),
      body: Container(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(8.0),
            child:ListTile(
              title: Text('Select Brand:'),
              trailing: DropdownButton(
                value: _btnSelectedVal,
                hint: Text('Brand'),
                onChanged: ((String newValue) {
                  setState(() {
                    _btnSelectedVal = newValue;
                    print(_btnSelectedVal);////
                    //todo if bool enable textf
                    if(_btnSelectedVal=='NK'||_btnSelectedVal=='ActiveTools'||_btnSelectedVal=='Coxmate'){
                      _weight=true;
                    }else{
                      _weight=false;
                    }
                  });
                }),
                items: _dropDownMenuItems,
              ),
            ),
            ),
            Divider(
              thickness: 2.0,
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
          child:TextFormField(
            controller: _textFieldControllerName,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Product Name',
              labelText: 'Product Name',
            ),
            maxLines: 1,
          ),
            ),
          Padding(
              padding: const EdgeInsets.all(8.0),
          child:TextFormField(
            controller:_textFieldControllerPrice,
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            inputFormatters: <TextInputFormatter>[
        WhitelistingTextInputFormatter(RegExp("[0-9.]"))],
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Product Price',
              labelText: 'Product Price',
            ),
            maxLines: 1,
          ),),
          Padding(
              padding: const EdgeInsets.all(8.0),
          child:TextFormField(
            controller:_textFieldControllerStock,
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            inputFormatters: <TextInputFormatter>[
        WhitelistingTextInputFormatter(RegExp("[0-9.]"))],
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Product Stock',
              labelText: 'Product Stock',
            ),
            maxLines: 1,
          ),),
          Padding(
              padding: const EdgeInsets.all(8.0),
          child:TextFormField(
            controller:_textFieldControllerWeight,
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            inputFormatters: <TextInputFormatter>[
        WhitelistingTextInputFormatter(RegExp("[0-9.]"))],
            enabled: _weight,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Product Weight',
              labelText: 'Product Weight',
            ),
            maxLines: 1,
          ),),
          ButtonBar(
              alignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                RaisedButton(
                  child: Text('SAVE'),
                  color: Colors.blue,
                  highlightColor: Colors.grey,
                  shape: new RoundedRectangleBorder(
                    borderRadius: new BorderRadius.circular(30.0),
                  ),
                  onPressed: () {
                    Fluttertoast.showToast(
                    msg: 'ADDED: \n$_btnSelectedVal \nName: ${_textFieldControllerName.text} \nPrice: ${_textFieldControllerPrice.text} \nQty: ${_textFieldControllerStock.text} \nWeight: ${_textFieldControllerWeight.text}',
                    toastLength: Toast.LENGTH_LONG,
                  );
                    addProduct('$_btnSelectedVal','${_textFieldControllerName.text}','${_textFieldControllerPrice.text}','${_textFieldControllerStock.text}','${_textFieldControllerWeight.text}' );

                     _onClear();
                
                    
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
