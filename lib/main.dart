import 'package:flutter/foundation.dart'
    show debugDefaultTargetPlatformOverride;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:macarbi_racing/services/auth.dart';
import 'package:macarbi_racing/services/productUpdate.dart';
import 'package:macarbi_racing/services/productsRead.dart';
import 'package:macarbi_racing/ui/uiAddProduct.dart';
import 'package:macarbi_racing/ui/uiToDo.dart';
import 'package:macarbi_racing/ui/uiWebview.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:flutter/services.dart';
import 'models/modelCalc.dart';
import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';

String _search;

//void main() => runApp(MyApp());
void main() {
  debugDefaultTargetPlatformOverride = TargetPlatform.fuchsia;
  runApp(MyApp());
}

class MyApp extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Macarbi',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Macarbi Stock Managemnt'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  FirebaseMessaging _firebaseMessaging = new FirebaseMessaging();

  RefreshController _refreshController =
      RefreshController(initialRefresh: false);

  var authHandler = new Auth();

  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController _textFieldControllerEditName = TextEditingController();
  TextEditingController _textFieldControllerEditPrice = TextEditingController();
  TextEditingController _textFieldControllerEditStock = TextEditingController();
  TextEditingController _textFieldControllerEditWeight =
      TextEditingController();
  TextEditingController _textFieldControllerEditExRate =
      TextEditingController();
  TextEditingController _textFieldControllerEditShipping =
      TextEditingController();

  bool _switchVal = false;
  bool typing = false;
  bool qtyWarning = false;
  String _userEmail = null;

  @override
  void initState() {
    super.initState();
    _firebaseMessaging.subscribeToTopic("Notes");
    _firebaseMessaging.configure(
      onMessage: (Map<String, dynamic> message) {
        print('on message $message');
      },
      onResume: (Map<String, dynamic> message) {
        print('on resume $message');
      },
      onLaunch: (Map<String, dynamic> message) {
        print('on launch $message');
      },
    );
    _firebaseMessaging.requestNotificationPermissions(
        const IosNotificationSettings(sound: true, badge: true, alert: true));
    _firebaseMessaging.onIosSettingsRegistered
        .listen((IosNotificationSettings settings) {
      print("Settings registered: $settings");
    });
    _firebaseMessaging.getToken().then((String token) {
      assert(token != null);
      print('TOKEN: $token');
    });
  }

  _onClearEdit() {
    _textFieldControllerEditName.text = "";
    _textFieldControllerEditPrice.text = "";
    _textFieldControllerEditStock.text = "";
    _textFieldControllerEditWeight.text = "";
    _textFieldControllerEditExRate.text = "";
    _textFieldControllerEditShipping.text = "";
  }

  _onClear() {
    setState(() {
      emailController.text = "";
      passwordController.text = "";
    });

  }

  void _onRefresh() async {
    // monitor network fetch

    readData();
    await Future.delayed(Duration(milliseconds: 1000));
    if (productData.length == 0 || productData.length == null) {
      _onRefresh();
    }

    setState(() {});
    // if failed,use refreshFailed()

    _refreshController.refreshCompleted();
  }

  void _onLoading() async {
    // monitor network fetch
    await Future.delayed(Duration(milliseconds: 1000));
    // if failed,use loadFailed(),if no data return,use LoadNodata()

    if (mounted) setState(() {});
    _refreshController.loadComplete();
  }


  @override
  Widget build(BuildContext context) {
    if (productData.length == 0 || productData.length == null) {
      _onRefresh();
      return Center(child: CircularProgressIndicator());
    }
    final _kTabPages = <Widget>[
      Center(
        child: SmartRefresher(
          enablePullDown: true,
          enablePullUp: true,
          header: WaterDropHeader(),
          footer: CustomFooter(
            builder: (BuildContext context, LoadStatus mode) {
              Widget body;
              if (mode == LoadStatus.idle) {
                body = Text("pull up load");
              } else if (mode == LoadStatus.loading) {
                body = CupertinoActivityIndicator();
              } else if (mode == LoadStatus.failed) {
                body = Text("Load Failed!Click retry!");
              } else if (mode == LoadStatus.canLoading) {
                body = Text("release to load more");
              } else {
                body = Text("No more Data");
              }
              return Container(
                height: 55.0,
                child: Center(child: body),
              );
            },
          ),
          controller: _refreshController,
          onRefresh: _onRefresh,
          onLoading: _onLoading,
          child: new ListView.builder(
            //NK

            shrinkWrap: true,
            itemCount: productData['Products']['NK'].length -
                2, //note -2 due to Exchange Rate and Shipping
            itemBuilder: (BuildContext context, int index) {
              if (productData['Products']['NK'].length == 0 ||
                  productData['Products']['NK'].length == null)
                return Center(child: CircularProgressIndicator());
              //requested highlight of low stock
              if (int.tryParse(
                          productData['Products']['NK']['$index']['Stock']) >
                      0 ||
                  int.tryParse(
                          productData['Products']['NK']['$index']['Stock']) <
                      5) {
                qtyWarning = true;
              }
              if (int.tryParse(
                          productData['Products']['NK']['$index']['Stock']) ==
                      0 ||
                  int.tryParse(
                          productData['Products']['NK']['$index']['Stock']) >
                      5) {
                qtyWarning = false;
              }
              return _switchVal == false &&
                      !productData['Products']['NK']['$index']['Name']
                          .toString()
                          .endsWith(',')
                  ? _search == null || _search == ""
                      ? buildCardNK(index, context)
                      : productData['Products']['NK']['$index']['Name']
                              .toString()
                              .toLowerCase()
                              .contains('${_search.toLowerCase()}')
                          ? buildCardNK(index, context)
                          : new Container()
                  : _switchVal == true &&
                          productData['Products']['NK']['$index']['Name']
                              .toString()
                              .endsWith(',')
                      ? buildCardNK(index, context)
                      : new Container(); //todo fix filter
            },
          ),
        ),
      ),
      Center(
        child: SmartRefresher(
          enablePullDown: true,
          enablePullUp: true,
          header: WaterDropHeader(),
          footer: CustomFooter(
            builder: (BuildContext context, LoadStatus mode) {
              Widget body;
              if (mode == LoadStatus.idle) {
                body = Text("pull up load");
              } else if (mode == LoadStatus.loading) {
                body = CupertinoActivityIndicator();
              } else if (mode == LoadStatus.failed) {
                body = Text("Load Failed!Click retry!");
              } else if (mode == LoadStatus.canLoading) {
                body = Text("release to load more");
              } else {
                body = Text("No more Data");
              }
              return Container(
                height: 55.0,
                child: Center(child: body),
              );
            },
          ),
          controller: _refreshController,
          onRefresh: _onRefresh,
          onLoading: _onLoading,
          child: new ListView.builder(
            //ActiveTools
            shrinkWrap: true,
            itemCount: productData['Products']['ActiveTools'].length -
                2, //note -2 due to Exchange Rate and Shipping
            itemBuilder: (BuildContext context, int index) {
              if (productData['Products']['ActiveTools'].length == 0 ||
                  productData['Products']['ActiveTools'].length == null)
                return Center(child: CircularProgressIndicator());
              //requested highlight of low stock
              if (int.tryParse(productData['Products']['ActiveTools']['$index']
                          ['Stock']) >
                      0 ||
                  int.tryParse(productData['Products']['ActiveTools']['$index']
                          ['Stock']) <
                      5) {
                qtyWarning = true;
              }
              if (int.tryParse(productData['Products']['ActiveTools']['$index']
                          ['Stock']) ==
                      0 ||
                  int.tryParse(productData['Products']['ActiveTools']['$index']
                          ['Stock']) >
                      5) {
                qtyWarning = false;
              }
              return _switchVal == false &&
                      !productData['Products']['ActiveTools']['$index']['Name']
                          .toString()
                          .endsWith(',')
                  ? _search == null || _search == ""
                      ? buildCardActiveTools(index, context)
                      : productData['Products']['ActiveTools']['$index']['Name']
                              .toString()
                              .toLowerCase()
                              .contains('${_search.toLowerCase()}')
                          ? buildCardActiveTools(index, context)
                          : new Container()
                  : _switchVal == true &&
                          productData['Products']['ActiveTools']['$index']
                                  ['Name']
                              .toString()
                              .endsWith(',')
                      ? buildCardActiveTools(index, context)
                      : new Container(); //todo fix filter
            },
          ),
        ),
      ),
      Center(
        child: SmartRefresher(
          enablePullDown: true,
          enablePullUp: true,
          header: WaterDropHeader(),
          footer: CustomFooter(
            builder: (BuildContext context, LoadStatus mode) {
              Widget body;
              if (mode == LoadStatus.idle) {
                body = Text("pull up load");
              } else if (mode == LoadStatus.loading) {
                body = CupertinoActivityIndicator();
              } else if (mode == LoadStatus.failed) {
                body = Text("Load Failed!Click retry!");
              } else if (mode == LoadStatus.canLoading) {
                body = Text("release to load more");
              } else {
                body = Text("No more Data");
              }
              return Container(
                height: 55.0,
                child: Center(child: body),
              );
            },
          ),
          controller: _refreshController,
          onRefresh: _onRefresh,
          onLoading: _onLoading,
          child: new ListView.builder(
            //Coxmate
            shrinkWrap: true,
            itemCount: productData['Products']['Coxmate'].length -
                2, //note -2 due to Exchange Rate and Shipping
            itemBuilder: (BuildContext context, int index) {
              if (productData['Products']['Coxmate'].length == 0 ||
                  productData['Products']['Coxmate'].length == null)
                return Center(child: CircularProgressIndicator());
              //requested highlight of low stock
              if (int.tryParse(productData['Products']['Coxmate']['$index']
                          ['Stock']) >
                      0 ||
                  int.tryParse(productData['Products']['Coxmate']['$index']
                          ['Stock']) <
                      5) {
                qtyWarning = true;
              }
              if (int.tryParse(productData['Products']['Coxmate']['$index']
                          ['Stock']) ==
                      0 ||
                  int.tryParse(productData['Products']['Coxmate']['$index']
                          ['Stock']) >
                      5) {
                qtyWarning = false;
              }
              return _switchVal == false &&
                      !productData['Products']['Coxmate']['$index']['Name']
                          .toString()
                          .endsWith(',')
                  ? _search == null || _search == ""
                      ? buildCardCoxmate(index, context)
                      : productData['Products']['Coxmate']['$index']['Name']
                              .toString()
                              .toLowerCase()
                              .contains('${_search.toLowerCase()}')
                          ? buildCardCoxmate(index, context)
                          : new Container()
                  : _switchVal == true &&
                          productData['Products']['Coxmate']['$index']['Name']
                              .toString()
                              .endsWith(',')
                      ? buildCardCoxmate(index, context)
                      : new Container(); //todo fix filter
            },
          ),
        ),
      ),
      Center(
        child: SmartRefresher(
          enablePullDown: true,
          enablePullUp: true,
          header: WaterDropHeader(),
          footer: CustomFooter(
            builder: (BuildContext context, LoadStatus mode) {
              Widget body;
              if (mode == LoadStatus.idle) {
                body = Text("pull up load");
              } else if (mode == LoadStatus.loading) {
                body = CupertinoActivityIndicator();
              } else if (mode == LoadStatus.failed) {
                body = Text("Load Failed!Click retry!");
              } else if (mode == LoadStatus.canLoading) {
                body = Text("release to load more");
              } else {
                body = Text("No more Data");
              }
              return Container(
                height: 55.0,
                child: Center(child: body),
              );
            },
          ),
          controller: _refreshController,
          onRefresh: _onRefresh,
          onLoading: _onLoading,
          child: new ListView.builder(
            //Concept 2
            shrinkWrap: true,
            itemCount: productData['Products']['Concept 2'].length -
                2, //note -2 due to Exchange Rate and Shipping
            itemBuilder: (BuildContext context, int index) {
              if (productData['Products']['Concept 2'].length == 0 ||
                  productData['Products']['Concept 2'].length == null)
                return Center(child: CircularProgressIndicator());
              //requested highlight of low stock
              if (int.tryParse(productData['Products']['Concept 2']['$index']
                          ['Stock']) >
                      0 ||
                  int.tryParse(productData['Products']['Concept 2']['$index']
                          ['Stock']) <
                      5) {
                qtyWarning = true;
              }
              if (int.tryParse(productData['Products']['Concept 2']['$index']
                          ['Stock']) ==
                      0 ||
                  int.tryParse(productData['Products']['Concept 2']['$index']
                          ['Stock']) >
                      5) {
                qtyWarning = false;
              }
              return _switchVal == false &&
                      !productData['Products']['Concept 2']['$index']['Name']
                          .toString()
                          .endsWith(',')
                  ? _search == null || _search == ""
                      ? buildCardConcept2(index, context)
                      : productData['Products']['Concept 2']['$index']['Name']
                              .toString()
                              .toLowerCase()
                              .contains('${_search.toLowerCase()}')
                          ? buildCardConcept2(index, context): new Container()
                  : _switchVal == true &&
                          productData['Products']['Concept 2']['$index']['Name']
                              .toString()
                              .endsWith(',')
                      ? buildCardConcept2(index, context): new Container();
            },
          ),
        ),
      ),
      Center(
        child: SmartRefresher(
          enablePullDown: true,
          enablePullUp: true,
          header: WaterDropHeader(),
          footer: CustomFooter(
            builder: (BuildContext context, LoadStatus mode) {
              Widget body;
              if (mode == LoadStatus.idle) {
                body = Text("pull up load");
              } else if (mode == LoadStatus.loading) {
                body = CupertinoActivityIndicator();
              } else if (mode == LoadStatus.failed) {
                body = Text("Load Failed!Click retry!");
              } else if (mode == LoadStatus.canLoading) {
                body = Text("release to load more");
              } else {
                body = Text("No more Data");
              }
              return Container(
                height: 55.0,
                child: Center(child: body),
              );
            },
          ),
          controller: _refreshController,
          onRefresh: _onRefresh,
          onLoading: _onLoading,
          child: new ListView.builder(
            //Croker
            shrinkWrap: true,
            itemCount: productData['Products']['Croker'].length -
                2, //note -2 due to Exchange Rate and Shipping
            itemBuilder: (BuildContext context, int index) {
              if (productData['Products']['Croker'].length == 0 ||
                  productData['Products']['Croker'].length == null)
                return Center(child: CircularProgressIndicator());
              //requested highlight of low stock
              if (int.tryParse(productData['Products']['Croker']['$index']
                          ['Stock']) >
                      0 ||
                  int.tryParse(productData['Products']['Croker']['$index']
                          ['Stock']) <
                      5) {
                qtyWarning = true;
              }
              if (int.tryParse(productData['Products']['Croker']['$index']
                          ['Stock']) ==
                      0 ||
                  int.tryParse(productData['Products']['Croker']['$index']
                          ['Stock']) >
                      5) {
                qtyWarning = false;
              }
              return _switchVal == false &&
                      !productData['Products']['Croker']['$index']['Name']
                          .toString()
                          .endsWith(',')
                  ? _search == null || _search == ""
                      ? buildCardCroker(index, context)
                      : productData['Products']['Croker']['$index']['Name']
                              .toString()
                              .toLowerCase()
                              .contains('${_search.toLowerCase()}')
                          ? buildCardCroker(index, context)
                          : new Container()
                  : _switchVal == true &&
                          productData['Products']['Croker']['$index']['Name']
                              .toString()
                              .endsWith(',')
                      ? buildCardCroker(index, context)
                      : new Container(); 
            },
          ),
        ),
      ),
      Center(
        child: SmartRefresher(
          controller: _refreshController,
          enablePullDown: true,
          onRefresh: () async {
            await Future.delayed(Duration(seconds: 1));
            _refreshController.refreshCompleted();
          },
          child: new ListView.builder(
            //Hudson
            shrinkWrap: true,
            itemCount: productData['Products']['Hudson'].length -
                2, //note -2 due to Exchange Rate and Shipping
            itemBuilder: (BuildContext context, int index) {
              if (productData['Products']['Hudson'].length == 0 ||
                  productData['Products']['Hudson'].length == null)
                return Center(child: CircularProgressIndicator());
              //requested highlight of low stock
              if (int.tryParse(productData['Products']['Hudson']['$index']
                          ['Stock']) >
                      0 ||
                  int.tryParse(productData['Products']['Hudson']['$index']
                          ['Stock']) <
                      5) {
                qtyWarning = true;
              }
              if (int.tryParse(productData['Products']['Hudson']['$index']
                          ['Stock']) ==
                      0 ||
                  int.tryParse(productData['Products']['Hudson']['$index']
                          ['Stock']) >
                      5) {
                qtyWarning = false;
              }
              return _switchVal == false &&
                      !productData['Products']['Hudson']['$index']['Name']
                          .toString()
                          .endsWith(',')
                  ? _search == null || _search == ""
                      ? buildCardHudson(index, context)
                      : productData['Products']['Hudson']['$index']['Name']
                              .toString()
                              .toLowerCase()
                              .contains('${_search.toLowerCase()}')
                          ? buildCardHudson(index, context): new Container()
                  : _switchVal == true &&
                          productData['Products']['Hudson']['$index']['Name']
                              .toString()
                              .endsWith(',')
                      ? buildCardHudson(index, context)
                      : new Container(); //todo fix filter
            },
          ),
        ),
      ),
      Center(
        child: SmartRefresher(
          controller: _refreshController,
          enablePullDown: true,
          onRefresh: () async {
            await Future.delayed(Duration(seconds: 1));
            _refreshController.refreshCompleted();
          },
          child: new ListView.builder(
            //Swift
            shrinkWrap: true,
            itemCount: productData['Products']['Swift'].length -
                2, //note -2 due to Exchange Rate and Shipping
            itemBuilder: (BuildContext context, int index) {
              if (productData['Products']['Swift'].length == 0 ||
                  productData['Products']['Swift'].length == null)
                return Center(child: CircularProgressIndicator());
              //requested highlight of low stock
              if (int.tryParse(
                          productData['Products']['Swift']['$index']['Stock']) >
                      0 ||
                  int.tryParse(
                          productData['Products']['Swift']['$index']['Stock']) <
                      5) {
                qtyWarning = true;
              }
              if (int.tryParse(productData['Products']['Swift']['$index']
                          ['Stock']) ==
                      0 ||
                  int.tryParse(
                          productData['Products']['Swift']['$index']['Stock']) >
                      5) {
                qtyWarning = false;
              }
              return _switchVal == false &&
                      !productData['Products']['Swift']['$index']['Name']
                          .toString()
                          .endsWith(',')
                  ? _search == null || _search == ""
                      ? buildCardSwift(index, context)
                      : productData['Products']['Swift']['$index']['Name']
                              .toString()
                              .toLowerCase()
                              .contains('${_search.toLowerCase()}')
                          ? buildCardSwift(index, context)
                          : new Container()
                  : _switchVal == true &&
                          productData['Products']['Swift']['$index']['Name']
                              .toString()
                              .endsWith(',')
                      ? buildCardSwift(index, context)
                      : new Container(); //todo fix filter
            },
          ),
        ),
      ),
      Center(
        child: SmartRefresher(
          controller: _refreshController,
          enablePullDown: true,
          onRefresh: () async {
            await Future.delayed(Duration(seconds: 1));
            _refreshController.refreshCompleted();
          },
          child: new ListView.builder(
            //Rowshop
            shrinkWrap: true,
            itemCount: productData['Products']['Rowshop'].length -
                2, //note -2 due to Exchange Rate and Shipping
            itemBuilder: (BuildContext context, int index) {
              if (productData['Products']['Rowshop'].length == 0 ||
                  productData['Products']['Rowshop'].length == null)
                return Center(child: CircularProgressIndicator());
              //requested highlight of low stock
              if (int.tryParse(productData['Products']['Rowshop']['$index']
                          ['Stock']) >
                      0 ||
                  int.tryParse(productData['Products']['Rowshop']['$index']
                          ['Stock']) <
                      5) {
                qtyWarning = true;
              }
              if (int.tryParse(productData['Products']['Rowshop']['$index']
                          ['Stock']) ==
                      0 ||
                  int.tryParse(productData['Products']['Rowshop']['$index']
                          ['Stock']) >
                      5) {
                qtyWarning = false;
              }
              return _switchVal == false &&
                      !productData['Products']['Rowshop']['$index']['Name']
                          .toString()
                          .endsWith(',')
                  ? _search == null || _search == ""
                      ? buildCardRowshop(index, context)
                      : productData['Products']['Rowshop']['$index']['Name']
                              .toString()
                              .toLowerCase()
                              .contains('${_search.toLowerCase()}')
                          ? buildCardRowshop(index, context): new Container()
                  : _switchVal == true &&
                          productData['Products']['Rowshop']['$index']['Name']
                              .toString()
                              .endsWith(',')
                      ? buildCardRowshop(index, context)
                      : new Container(); //todo fix filter
            },
          ),
        ),
      ),
    ];
    final _kTabs = <Tab>[
      Tab(text: 'NK'),
      Tab(text: 'ActiveTools'),
      Tab(text: 'Coxmate'),
      Tab(text: 'Concept 2'),
      Tab(text: 'Croker'),
      Tab(text: 'Hudson'),
      Tab(text: 'Swift'),
      Tab(text: 'Rowshop'),
    ];
    return DefaultTabController(
      length: _kTabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: typing
              ? TextBoxSearch()
              : (_userEmail == null ? Text("Macarbi") : Text('$_userEmail')),
          leading: IconButton(
              icon: Icon(typing ? Icons.done : Icons.search),
              onPressed: () {
                setState(() {
                  if (!typing) {
                    _search = "";
                  }
                  typing = !typing;
                });
              }),

          actions: <Widget>[
            Switch(
              onChanged: (bool value) {
                setState(() {
                  this._switchVal = value;
                  Fluttertoast.showToast(
                    msg: 'toast switch $value',
                    toastLength: Toast.LENGTH_SHORT,
                  );
                });
              },
              value: this._switchVal,
              activeColor: Colors.pink,
            ),
            IconButton(
              icon: Icon(Icons.account_circle),
              onPressed: () {
                showDialog<String>(
                  context: context,
                  builder: (BuildContext context) => SimpleDialog(
                    title: Image.asset("assets/MacarbiFullLogo.jpg"),
                    children: <Widget>[
                      SizedBox(height: 24.0),
                      // "Email" form.
                      TextFormField(
                        controller: emailController,
                        decoration: const InputDecoration(
                          border: UnderlineInputBorder(),
                          filled: true,
                          hintText: 'Your email address',
                          labelText: 'E-mail',
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      SizedBox(height: 24.0),
                      TextFormField(
                        controller: passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          border: UnderlineInputBorder(),
                          filled: true,
                          hintText: 'Your password',
                          labelText: 'Password',
                        ),
                      ),
                      ListTile(
                          leading: Icon(Icons.face),
                          title:_userEmail==null? Text('Login'):Text('Logout'),
                          onTap: () {
                            if(_userEmail==null){
                            authHandler
                                .handleSignInEmail(emailController.text,
                                    passwordController.text)
                                .then((FirebaseUser user) {
                              print('logged in: ${user.email}');
                              _userEmail = '${user.email}';
                              Fluttertoast.showToast(
                                msg: 'logged in: $_userEmail',
                                toastLength: Toast.LENGTH_LONG,
                              );
                              _onClear();
                              Navigator.pop(context);
                            }).catchError((e) => Fluttertoast.showToast(
                                      msg: 'Incorrect Login Details',
                                      toastLength: Toast.LENGTH_LONG,
                                    ));
                            }else{
                              _userEmail=null;
                              authHandler.signOut();
                              _onClear();
                              _onRefresh();
                              Navigator.pop(context);
                            }
                          }),
                      ListTile(
                        leading: Icon(Icons.add_circle),
                        title: Text('Register'),
                        onTap: () {
                          if (_userEmail != null) {
                            authHandler
                                .handleSignUp(emailController.text,
                                    passwordController.text)
                                .then((FirebaseUser user) {
                              print('Registered in: ${user.email}');
                              Fluttertoast.showToast(
                                msg: 'Registered: ${emailController.text}',
                                toastLength: Toast.LENGTH_LONG,
                              );
                              _onClear();
                              Navigator.pop(context);
                            }).catchError((e) => Fluttertoast.showToast(
                                      msg: 'ERROR: $e',
                                      toastLength: Toast.LENGTH_LONG,
                                    ));
                          } else {
                            Fluttertoast.showToast(
                              msg:
                                  'You Must Be Logged In To Register A New User',
                              toastLength: Toast.LENGTH_LONG,
                            );
                          }
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
          bottom: TabBar(
            isScrollable: true,
            tabs: _kTabs,
          ),
        ),
        body: TabBarView(
          children: _kTabPages,
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButton: FloatingActionButton(
          child: const Icon(Icons.add),
          mini: true,
          onPressed: () {
            if (_userEmail != null) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddProductPage()),
              );
            } else {
              Fluttertoast.showToast(
                msg: 'You Must Be Logged In To Add A Product',
                toastLength: Toast.LENGTH_LONG,
              );
            }
          },
        ),
        bottomNavigationBar: BottomAppBar(
          shape: CircularNotchedRectangle(),
          notchMargin: 2.0,
          child: new Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              IconButton(
                  icon: Icon(Icons.create),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ToDo()),
                    );
                  }),
              IconButton(
                icon: Icon(Icons.web),
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (BuildContext context) => MyWebView(
                            title: "Macarbi Website",
                            selectedUrl: "https://www.macarbi.com",
                          )));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Card buildCardRowshop(int index, BuildContext context) {
    return new Card(
                        color: qtyWarning ? Colors.grey : Colors.white,
                        child: new ListTile(
                          title: Text(
                              '${productData['Products']['Rowshop']['$index']['Name']}'),
                          subtitle: Text(
                              'R${productData['Products']['Rowshop']['$index']['Price']}\nQTY: ${productData['Products']['Rowshop']['$index']['Stock']}'),
                          trailing: _userEmail != null
                              ? Column(
                                  children: <Widget>[
                                    Expanded(
                                      child: IconButton(
                                        icon: Icon(Icons.arrow_upward),
                                        onPressed: () {
                                          _onRefresh();
                                          updateQty('Rowshop', index, 'up');
                                        },
                                      ),
                                    ),
                                    Expanded(
                                      child: IconButton(
                                        icon: Icon(Icons.arrow_downward),
                                        onPressed: () {
                                          _onRefresh();
                                          updateQty('Rowshop', index, 'down');
                                        },
                                      ),
                                    ),
                                  ],
                                )
                              : Column(),
                          onTap: () {
                            if (_userEmail != null) {
                              String _editBrand = 'Rowshop';
                              _onClearEdit();
                              _textFieldControllerEditName.text =
                                  '${productData['Products']['$_editBrand']['$index']['Name']}';
                              _textFieldControllerEditPrice.text =
                                  '${productData['Products']['$_editBrand']['$index']['Price']}';
                              _textFieldControllerEditStock.text =
                                  '${productData['Products']['$_editBrand']['$index']['Stock']}';
                              _textFieldControllerEditWeight.text =
                                  '${productData['Products']['$_editBrand']['$index']['Weight']}';
                              _textFieldControllerEditExRate.text =
                                  '${productData['Products']['$_editBrand']['Exchange Rate']}';
                              _textFieldControllerEditShipping.text =
                                  '${productData['Products']['$_editBrand']['Shipping']}';

                              showDialog<String>(
                                context: context,
                                builder: (BuildContext context) =>
                                    SimpleDialog(
                                  title: Image.asset(
                                      "assets/MacarbiFullLogo.jpg"),
                                  children: <Widget>[
                                    Row(children: <Widget>[
                                      Expanded(
                                        child: new Container(
                                            margin: const EdgeInsets.only(
                                                left: 10.0, right: 20.0),
                                            child: Divider(
                                              color: Colors.black,
                                              height: 36,
                                            )),
                                      ),
                                      Text(
                                        '$_editBrand',
                                        textAlign: TextAlign.center,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 20.0),
                                      ),
                                      Expanded(
                                        child: new Container(
                                            margin: const EdgeInsets.only(
                                                left: 20.0, right: 10.0),
                                            child: Divider(
                                              color: Colors.black,
                                              height: 36,
                                            )),
                                      ),
                                    ]),
                                    SingleChildScrollView(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: <Widget>[
                                          Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: <Widget>[
                                              Padding(
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                child: TextFormField(
                                                  controller:
                                                      _textFieldControllerEditName,
                                                  decoration: InputDecoration(
                                                    border:
                                                        OutlineInputBorder(),
                                                    helperText:
                                                        'Product Name',
                                                    labelText:
                                                        '${productData['Products']['$_editBrand']['$index']['Name']}',
                                                  ),
                                                  maxLines: 1,
                                                ),
                                              ),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                child: TextFormField(
                                                  controller:
                                                      _textFieldControllerEditPrice,
                                                  keyboardType: TextInputType
                                                      .numberWithOptions(
                                                          decimal: true),
                                                  inputFormatters: <
                                                      TextInputFormatter>[
                                                    WhitelistingTextInputFormatter(
                                                        RegExp("[0-9.]"))
                                                  ],
                                                  decoration: InputDecoration(
                                                    border:
                                                        OutlineInputBorder(),
                                                    helperText:
                                                        'Product Price - Agent Price',
                                                    labelText:
                                                        '${productData['Products']['$_editBrand']['$index']['Price']}',
                                                  ),
                                                  maxLines: 1,
                                                ),
                                              ),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                child: TextFormField(
                                                  controller:
                                                      _textFieldControllerEditStock,
                                                  keyboardType: TextInputType
                                                      .numberWithOptions(
                                                          decimal: true),
                                                  inputFormatters: <
                                                      TextInputFormatter>[
                                                    WhitelistingTextInputFormatter(
                                                        RegExp("[0-9.]"))
                                                  ],
                                                  decoration: InputDecoration(
                                                    border:
                                                        OutlineInputBorder(),
                                                    helperText:
                                                        'Product Stock',
                                                    labelText:
                                                        '${productData['Products']['$_editBrand']['$index']['Stock']}',
                                                  ),
                                                  maxLines: 1,
                                                ),
                                              ),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                child: TextFormField(
                                                  controller:
                                                      _textFieldControllerEditWeight,
                                                  keyboardType: TextInputType
                                                      .numberWithOptions(
                                                          decimal: true),
                                                  inputFormatters: <
                                                      TextInputFormatter>[
                                                    WhitelistingTextInputFormatter(
                                                        RegExp("[0-9.]"))
                                                  ],
                                                  decoration: InputDecoration(
                                                    border:
                                                        OutlineInputBorder(),
                                                    helperText:
                                                        'Product Weight - lbs',
                                                    labelText:
                                                        '${productData['Products']['$_editBrand']['$index']['Weight']}',
                                                  ),
                                                  maxLines: 1,
                                                ),
                                              ),
                                              Row(children: <Widget>[
                                                Expanded(
                                                  child: new Container(
                                                      margin: const EdgeInsets
                                                              .only(
                                                          left: 10.0,
                                                          right: 20.0),
                                                      child: Divider(
                                                        color: Colors.black,
                                                        height: 36,
                                                      )),
                                                ),
                                                Text(
                                                  'Global Settings For $_editBrand',
                                                  textAlign: TextAlign.center,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 15.0),
                                                ),
                                                Expanded(
                                                  child: new Container(
                                                      margin: const EdgeInsets
                                                              .only(
                                                          left: 20.0,
                                                          right: 10.0),
                                                      child: Divider(
                                                        color: Colors.black,
                                                        height: 36,
                                                      )),
                                                ),
                                              ]),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                child: TextFormField(
                                                  controller:
                                                      _textFieldControllerEditExRate,
                                                  decoration: InputDecoration(
                                                    border:
                                                        OutlineInputBorder(),
                                                    helperText:
                                                        'Global Setting Exchange Rate',
                                                    labelText:
                                                        '${productData['Products']['$_editBrand']['Exchange Rate']}',
                                                  ),
                                                  maxLines: 1,
                                                ),
                                              ),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                child: TextFormField(
                                                  controller:
                                                      _textFieldControllerEditShipping,
                                                  decoration: InputDecoration(
                                                    border:
                                                        OutlineInputBorder(),
                                                    helperText:
                                                        'Global Setting Shipping',
                                                    labelText:
                                                        '${productData['Products']['$_editBrand']['Shipping']}',
                                                  ),
                                                  maxLines: 1,
                                                ),
                                              ),
                                              ButtonBar(
                                                alignment: MainAxisAlignment
                                                    .spaceEvenly,
                                                children: <Widget>[
                                                  RaisedButton(
                                                    child: Text('SAVE'),
                                                    color: Colors.blue,
                                                    highlightColor:
                                                        Colors.grey,
                                                    shape:
                                                        new RoundedRectangleBorder(
                                                      borderRadius:
                                                          new BorderRadius
                                                              .circular(30.0),
                                                    ),
                                                    onPressed: () {
                                                      updateProduct(
                                                          '$_editBrand',
                                                          index,
                                                          '${_textFieldControllerEditName.text}',
                                                          '${_textFieldControllerEditPrice.text}',
                                                          '${_textFieldControllerEditStock.text}',
                                                          '${_textFieldControllerEditWeight.text}');
                                                      updateProductGlobal(
                                                          '$_editBrand',
                                                          '${_textFieldControllerEditExRate.text}',
                                                          '${_textFieldControllerEditShipping.text}');
                                                      _onClearEdit();
                                                      _onRefresh();
                                                      Navigator.pop(context);
                                                    },
                                                  ),
                                                  RaisedButton(
                                                    child: Text('DELETE'),
                                                    color: Colors.blue,
                                                    highlightColor:
                                                        Colors.grey,
                                                    shape:
                                                        new RoundedRectangleBorder(
                                                      borderRadius:
                                                          new BorderRadius
                                                              .circular(30.0),
                                                    ),
                                                    onPressed: () {
                                                      delProduct(
                                                          '$_editBrand',
                                                          index,
                                                          '${_textFieldControllerEditName.text}');
                                                      _onClearEdit();
                                                      _onRefresh();
                                                      Navigator.pop(context);
                                                    },
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            } else {
                              Fluttertoast.showToast(
                                msg: 'Login To Edit A Product',
                                toastLength: Toast.LENGTH_LONG,
                              );
                            }
                          },
                          onLongPress: () {
                            Clipboard.setData(new ClipboardData(
                                text:
                                    '${productData['Products']['Rowshop']['$index']['Name']}: R${productData['Products']['Rowshop']['$index']['Price']}'));
                            Fluttertoast.showToast(
                              msg:
                                  'Copied to Clipboard\n${productData['Products']['Rowshop']['$index']['Name']}: R${productData['Products']['Rowshop']['$index']['Price']}',
                              toastLength: Toast.LENGTH_LONG,
                            );
                          },
                        ));
  }

  Card buildCardSwift(int index, BuildContext context) {
    return new Card(
                        color: qtyWarning ? Colors.grey : Colors.white,
                        child: new ListTile(
                          title: Text(
                              '${productData['Products']['Swift']['$index']['Name']}'),
                          subtitle: Text(
                              'R${productData['Products']['Swift']['$index']['Price']}\nQTY: ${productData['Products']['Swift']['$index']['Stock']}'),
                          trailing: _userEmail != null
                              ? Column(
                                  children: <Widget>[
                                    Expanded(
                                      child: IconButton(
                                        icon: Icon(Icons.arrow_upward),
                                        onPressed: () {
                                          _onRefresh();
                                          updateQty('Swift', index, 'up');
                                        },
                                      ),
                                    ),
                                    Expanded(
                                      child: IconButton(
                                        icon: Icon(Icons.arrow_downward),
                                        onPressed: () {
                                          _onRefresh();
                                          updateQty('Swift', index, 'down');
                                        },
                                      ),
                                    ),
                                  ],
                                )
                              : Column(),
                          onTap: () {
                            if (_userEmail != null) {
                              String _editBrand = 'Swift';
                              _onClearEdit();
                              _textFieldControllerEditName.text =
                                  '${productData['Products']['$_editBrand']['$index']['Name']}';
                              _textFieldControllerEditPrice.text =
                                  '${productData['Products']['$_editBrand']['$index']['Price']}';
                              _textFieldControllerEditStock.text =
                                  '${productData['Products']['$_editBrand']['$index']['Stock']}';
                              _textFieldControllerEditWeight.text =
                                  '${productData['Products']['$_editBrand']['$index']['Weight']}';
                              _textFieldControllerEditExRate.text =
                                  '${productData['Products']['$_editBrand']['Exchange Rate']}';
                              _textFieldControllerEditShipping.text =
                                  '${productData['Products']['$_editBrand']['Shipping']}';

                              showDialog<String>(
                                context: context,
                                builder: (BuildContext context) =>
                                    SimpleDialog(
                                  title: Image.asset(
                                      "assets/MacarbiFullLogo.jpg"),
                                  children: <Widget>[
                                    Row(children: <Widget>[
                                      Expanded(
                                        child: new Container(
                                            margin: const EdgeInsets.only(
                                                left: 10.0, right: 20.0),
                                            child: Divider(
                                              color: Colors.black,
                                              height: 36,
                                            )),
                                      ),
                                      Text(
                                        '$_editBrand',
                                        textAlign: TextAlign.center,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 20.0),
                                      ),
                                      Expanded(
                                        child: new Container(
                                            margin: const EdgeInsets.only(
                                                left: 20.0, right: 10.0),
                                            child: Divider(
                                              color: Colors.black,
                                              height: 36,
                                            )),
                                      ),
                                    ]),
                                    SingleChildScrollView(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: <Widget>[
                                          Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: <Widget>[
                                              Padding(
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                child: TextFormField(
                                                  controller:
                                                      _textFieldControllerEditName,
                                                  decoration: InputDecoration(
                                                    border:
                                                        OutlineInputBorder(),
                                                    helperText:
                                                        'Product Name',
                                                    labelText:
                                                        '${productData['Products']['$_editBrand']['$index']['Name']}',
                                                  ),
                                                  maxLines: 1,
                                                ),
                                              ),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                child: TextFormField(
                                                  controller:
                                                      _textFieldControllerEditPrice,
                                                  keyboardType: TextInputType
                                                      .numberWithOptions(
                                                          decimal: true),
                                                  inputFormatters: <
                                                      TextInputFormatter>[
                                                    WhitelistingTextInputFormatter(
                                                        RegExp("[0-9.]"))
                                                  ],
                                                  decoration: InputDecoration(
                                                    border:
                                                        OutlineInputBorder(),
                                                    helperText:
                                                        'Product Price - Agent Price',
                                                    labelText:
                                                        '${productData['Products']['$_editBrand']['$index']['Price']}',
                                                  ),
                                                  maxLines: 1,
                                                ),
                                              ),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                child: TextFormField(
                                                  controller:
                                                      _textFieldControllerEditStock,
                                                  keyboardType: TextInputType
                                                      .numberWithOptions(
                                                          decimal: true),
                                                  inputFormatters: <
                                                      TextInputFormatter>[
                                                    WhitelistingTextInputFormatter(
                                                        RegExp("[0-9.]"))
                                                  ],
                                                  decoration: InputDecoration(
                                                    border:
                                                        OutlineInputBorder(),
                                                    helperText:
                                                        'Product Stock',
                                                    labelText:
                                                        '${productData['Products']['$_editBrand']['$index']['Stock']}',
                                                  ),
                                                  maxLines: 1,
                                                ),
                                              ),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                child: TextFormField(
                                                  controller:
                                                      _textFieldControllerEditWeight,
                                                  keyboardType: TextInputType
                                                      .numberWithOptions(
                                                          decimal: true),
                                                  inputFormatters: <
                                                      TextInputFormatter>[
                                                    WhitelistingTextInputFormatter(
                                                        RegExp("[0-9.]"))
                                                  ],
                                                  decoration: InputDecoration(
                                                    border:
                                                        OutlineInputBorder(),
                                                    helperText:
                                                        'Product Weight - lbs',
                                                    labelText:
                                                        '${productData['Products']['$_editBrand']['$index']['Weight']}',
                                                  ),
                                                  maxLines: 1,
                                                ),
                                              ),
                                              Row(children: <Widget>[
                                                Expanded(
                                                  child: new Container(
                                                      margin: const EdgeInsets
                                                              .only(
                                                          left: 10.0,
                                                          right: 20.0),
                                                      child: Divider(
                                                        color: Colors.black,
                                                        height: 36,
                                                      )),
                                                ),
                                                Text(
                                                  'Global Settings For $_editBrand',
                                                  textAlign: TextAlign.center,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 15.0),
                                                ),
                                                Expanded(
                                                  child: new Container(
                                                      margin: const EdgeInsets
                                                              .only(
                                                          left: 20.0,
                                                          right: 10.0),
                                                      child: Divider(
                                                        color: Colors.black,
                                                        height: 36,
                                                      )),
                                                ),
                                              ]),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                child: TextFormField(
                                                  controller:
                                                      _textFieldControllerEditExRate,
                                                  decoration: InputDecoration(
                                                    border:
                                                        OutlineInputBorder(),
                                                    helperText:
                                                        'Global Setting Exchange Rate',
                                                    labelText:
                                                        '${productData['Products']['$_editBrand']['Exchange Rate']}',
                                                  ),
                                                  maxLines: 1,
                                                ),
                                              ),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                child: TextFormField(
                                                  controller:
                                                      _textFieldControllerEditShipping,
                                                  decoration: InputDecoration(
                                                    border:
                                                        OutlineInputBorder(),
                                                    helperText:
                                                        'Global Setting Shipping',
                                                    labelText:
                                                        '${productData['Products']['$_editBrand']['Shipping']}',
                                                  ),
                                                  maxLines: 1,
                                                ),
                                              ),
                                              ButtonBar(
                                                alignment: MainAxisAlignment
                                                    .spaceEvenly,
                                                children: <Widget>[
                                                  RaisedButton(
                                                    child: Text('SAVE'),
                                                    color: Colors.blue,
                                                    highlightColor:
                                                        Colors.grey,
                                                    shape:
                                                        new RoundedRectangleBorder(
                                                      borderRadius:
                                                          new BorderRadius
                                                              .circular(30.0),
                                                    ),
                                                    onPressed: () {
                                                      updateProduct(
                                                          '$_editBrand',
                                                          index,
                                                          '${_textFieldControllerEditName.text}',
                                                          '${_textFieldControllerEditPrice.text}',
                                                          '${_textFieldControllerEditStock.text}',
                                                          '${_textFieldControllerEditWeight.text}');
                                                      updateProductGlobal(
                                                          '$_editBrand',
                                                          '${_textFieldControllerEditExRate.text}',
                                                          '${_textFieldControllerEditShipping.text}');
                                                      _onClearEdit();
                                                      _onRefresh();
                                                      Navigator.pop(context);
                                                    },
                                                  ),
                                                  RaisedButton(
                                                    child: Text('DELETE'),
                                                    color: Colors.blue,
                                                    highlightColor:
                                                        Colors.grey,
                                                    shape:
                                                        new RoundedRectangleBorder(
                                                      borderRadius:
                                                          new BorderRadius
                                                              .circular(30.0),
                                                    ),
                                                    onPressed: () {
                                                      delProduct(
                                                          '$_editBrand',
                                                          index,
                                                          '${_textFieldControllerEditName.text}');
                                                      _onClearEdit();
                                                      _onRefresh();
                                                      Navigator.pop(context);
                                                    },
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            } else {
                              Fluttertoast.showToast(
                                msg: 'Login To Edit A Product',
                                toastLength: Toast.LENGTH_LONG,
                              );
                            }
                          },
                          onLongPress: () {
                            Clipboard.setData(new ClipboardData(
                                text:
                                    '${productData['Products']['Swift']['$index']['Name']}: R${productData['Products']['Swift']['$index']['Price']}'));
                            Fluttertoast.showToast(
                              msg:
                                  'Copied to Clipboard\n${productData['Products']['Swift']['$index']['Name']}: R${productData['Products']['Swift']['$index']['Price']}',
                              toastLength: Toast.LENGTH_LONG,
                            );
                          },
                        ));
  }

  Card buildCardHudson(int index, BuildContext context) {
    return new Card(
                        color: qtyWarning ? Colors.grey : Colors.white,
                        child: new ListTile(
                          title: Text(
                              '${productData['Products']['Hudson']['$index']['Name']}'),
                          subtitle: Text(
                              'R${productData['Products']['Hudson']['$index']['Price']}\nQTY: ${productData['Products']['Hudson']['$index']['Stock']}'),
                          trailing: _userEmail != null
                              ? Column(
                                  children: <Widget>[
                                    Expanded(
                                      child: IconButton(
                                        icon: Icon(Icons.arrow_upward),
                                        onPressed: () {
                                          _onRefresh();
                                          updateQty('Hudson', index, 'up');
                                        },
                                      ),
                                    ),
                                    Expanded(
                                      child: IconButton(
                                        icon: Icon(Icons.arrow_downward),
                                        onPressed: () {
                                          _onRefresh();
                                          updateQty('Hudson', index, 'down');
                                        },
                                      ),
                                    ),
                                  ],
                                )
                              : Column(),
                          onTap: () {
                            if (_userEmail != null) {
                              String _editBrand = 'Hudson';
                              _onClearEdit();
                              _textFieldControllerEditName.text =
                                  '${productData['Products']['$_editBrand']['$index']['Name']}';
                              _textFieldControllerEditPrice.text =
                                  '${productData['Products']['$_editBrand']['$index']['Price']}';
                              _textFieldControllerEditStock.text =
                                  '${productData['Products']['$_editBrand']['$index']['Stock']}';
                              _textFieldControllerEditWeight.text =
                                  '${productData['Products']['$_editBrand']['$index']['Weight']}';
                              _textFieldControllerEditExRate.text =
                                  '${productData['Products']['$_editBrand']['Exchange Rate']}';
                              _textFieldControllerEditShipping.text =
                                  '${productData['Products']['$_editBrand']['Shipping']}';

                              showDialog<String>(
                                context: context,
                                builder: (BuildContext context) =>
                                    SimpleDialog(
                                  title: Image.asset(
                                      "assets/MacarbiFullLogo.jpg"),
                                  children: <Widget>[
                                    Row(children: <Widget>[
                                      Expanded(
                                        child: new Container(
                                            margin: const EdgeInsets.only(
                                                left: 10.0, right: 20.0),
                                            child: Divider(
                                              color: Colors.black,
                                              height: 36,
                                            )),
                                      ),
                                      Text(
                                        '$_editBrand',
                                        textAlign: TextAlign.center,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 20.0),
                                      ),
                                      Expanded(
                                        child: new Container(
                                            margin: const EdgeInsets.only(
                                                left: 20.0, right: 10.0),
                                            child: Divider(
                                              color: Colors.black,
                                              height: 36,
                                            )),
                                      ),
                                    ]),
                                    SingleChildScrollView(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: <Widget>[
                                          Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: <Widget>[
                                              Padding(
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                child: TextFormField(
                                                  controller:
                                                      _textFieldControllerEditName,
                                                  decoration: InputDecoration(
                                                    border:
                                                        OutlineInputBorder(),
                                                    helperText:
                                                        'Product Name',
                                                    labelText:
                                                        '${productData['Products']['$_editBrand']['$index']['Name']}',
                                                  ),
                                                  maxLines: 1,
                                                ),
                                              ),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                child: TextFormField(
                                                  controller:
                                                      _textFieldControllerEditPrice,
                                                  keyboardType: TextInputType
                                                      .numberWithOptions(
                                                          decimal: true),
                                                  inputFormatters: <
                                                      TextInputFormatter>[
                                                    WhitelistingTextInputFormatter(
                                                        RegExp("[0-9.]"))
                                                  ],
                                                  decoration: InputDecoration(
                                                    border:
                                                        OutlineInputBorder(),
                                                    helperText:
                                                        'Product Price - Agent Price',
                                                    labelText:
                                                        '${productData['Products']['$_editBrand']['$index']['Price']}',
                                                  ),
                                                  maxLines: 1,
                                                ),
                                              ),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                child: TextFormField(
                                                  controller:
                                                      _textFieldControllerEditStock,
                                                  keyboardType: TextInputType
                                                      .numberWithOptions(
                                                          decimal: true),
                                                  inputFormatters: <
                                                      TextInputFormatter>[
                                                    WhitelistingTextInputFormatter(
                                                        RegExp("[0-9.]"))
                                                  ],
                                                  decoration: InputDecoration(
                                                    border:
                                                        OutlineInputBorder(),
                                                    helperText:
                                                        'Product Stock',
                                                    labelText:
                                                        '${productData['Products']['$_editBrand']['$index']['Stock']}',
                                                  ),
                                                  maxLines: 1,
                                                ),
                                              ),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                child: TextFormField(
                                                  controller:
                                                      _textFieldControllerEditWeight,
                                                  keyboardType: TextInputType
                                                      .numberWithOptions(
                                                          decimal: true),
                                                  inputFormatters: <
                                                      TextInputFormatter>[
                                                    WhitelistingTextInputFormatter(
                                                        RegExp("[0-9.]"))
                                                  ],
                                                  decoration: InputDecoration(
                                                    border:
                                                        OutlineInputBorder(),
                                                    helperText:
                                                        'Product Weight - lbs',
                                                    labelText:
                                                        '${productData['Products']['$_editBrand']['$index']['Weight']}',
                                                  ),
                                                  maxLines: 1,
                                                ),
                                              ),
                                              Row(children: <Widget>[
                                                Expanded(
                                                  child: new Container(
                                                      margin: const EdgeInsets
                                                              .only(
                                                          left: 10.0,
                                                          right: 20.0),
                                                      child: Divider(
                                                        color: Colors.black,
                                                        height: 36,
                                                      )),
                                                ),
                                                Text(
                                                  'Global Settings For $_editBrand',
                                                  textAlign: TextAlign.center,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 15.0),
                                                ),
                                                Expanded(
                                                  child: new Container(
                                                      margin: const EdgeInsets
                                                              .only(
                                                          left: 20.0,
                                                          right: 10.0),
                                                      child: Divider(
                                                        color: Colors.black,
                                                        height: 36,
                                                      )),
                                                ),
                                              ]),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                child: TextFormField(
                                                  controller:
                                                      _textFieldControllerEditExRate,
                                                  decoration: InputDecoration(
                                                    border:
                                                        OutlineInputBorder(),
                                                    helperText:
                                                        'Global Setting Exchange Rate',
                                                    labelText:
                                                        '${productData['Products']['$_editBrand']['Exchange Rate']}',
                                                  ),
                                                  maxLines: 1,
                                                ),
                                              ),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                child: TextFormField(
                                                  controller:
                                                      _textFieldControllerEditShipping,
                                                  decoration: InputDecoration(
                                                    border:
                                                        OutlineInputBorder(),
                                                    helperText:
                                                        'Global Setting Shipping',
                                                    labelText:
                                                        '${productData['Products']['$_editBrand']['Shipping']}',
                                                  ),
                                                  maxLines: 1,
                                                ),
                                              ),
                                              ButtonBar(
                                                alignment: MainAxisAlignment
                                                    .spaceEvenly,
                                                children: <Widget>[
                                                  RaisedButton(
                                                    child: Text('SAVE'),
                                                    color: Colors.blue,
                                                    highlightColor:
                                                        Colors.grey,
                                                    shape:
                                                        new RoundedRectangleBorder(
                                                      borderRadius:
                                                          new BorderRadius
                                                              .circular(30.0),
                                                    ),
                                                    onPressed: () {
                                                      updateProduct(
                                                          '$_editBrand',
                                                          index,
                                                          '${_textFieldControllerEditName.text}',
                                                          '${_textFieldControllerEditPrice.text}',
                                                          '${_textFieldControllerEditStock.text}',
                                                          '${_textFieldControllerEditWeight.text}');
                                                      updateProductGlobal(
                                                          '$_editBrand',
                                                          '${_textFieldControllerEditExRate.text}',
                                                          '${_textFieldControllerEditShipping.text}');
                                                      _onClearEdit();
                                                      _onRefresh();
                                                      Navigator.pop(context);
                                                    },
                                                  ),
                                                  RaisedButton(
                                                    child: Text('DELETE'),
                                                    color: Colors.blue,
                                                    highlightColor:
                                                        Colors.grey,
                                                    shape:
                                                        new RoundedRectangleBorder(
                                                      borderRadius:
                                                          new BorderRadius
                                                              .circular(30.0),
                                                    ),
                                                    onPressed: () {
                                                      delProduct(
                                                          '$_editBrand',
                                                          index,
                                                          '${_textFieldControllerEditName.text}');
                                                      _onClearEdit();
                                                      _onRefresh();
                                                      Navigator.pop(context);
                                                    },
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            } else {
                              Fluttertoast.showToast(
                                msg: 'Login To Edit A Product',
                                toastLength: Toast.LENGTH_LONG,
                              );
                            }
                          },
                          onLongPress: () {
                            Clipboard.setData(new ClipboardData(
                                text:
                                    '${productData['Products']['Hudson']['$index']['Name']}: R${productData['Products']['Hudson']['$index']['Price']}'));
                            Fluttertoast.showToast(
                              msg:
                                  'Copied to Clipboard\n${productData['Products']['Hudson']['$index']['Name']}: R${productData['Products']['Hudson']['$index']['Price']}',
                              toastLength: Toast.LENGTH_LONG,
                            );
                          },
                        ));
  }

  Card buildCardCroker(int index, BuildContext context) {
    return new Card(
                        color: qtyWarning ? Colors.grey : Colors.white,
                        child: new ListTile(
                          title: Text(
                              '${productData['Products']['Croker']['$index']['Name']}'),
                          subtitle: Text(
                              'R${productData['Products']['Croker']['$index']['Price']}\nQTY: ${productData['Products']['Croker']['$index']['Stock']}'),
                          trailing: _userEmail != null
                              ? Column(
                                  children: <Widget>[
                                    Expanded(
                                      child: IconButton(
                                        icon: Icon(Icons.arrow_upward),
                                        onPressed: () {
                                          _onRefresh();
                                          updateQty('Croker', index, 'up');
                                        },
                                      ),
                                    ),
                                    Expanded(
                                      child: IconButton(
                                        icon: Icon(Icons.arrow_downward),
                                        onPressed: () {
                                          _onRefresh();
                                          updateQty('Croker', index, 'down');
                                        },
                                      ),
                                    ),
                                  ],
                                )
                              : Column(),
                          onTap: () {
                            if (_userEmail != null) {
                              String _editBrand = 'Croker';
                              _onClearEdit();
                              _textFieldControllerEditName.text =
                                  '${productData['Products']['$_editBrand']['$index']['Name']}';
                              _textFieldControllerEditPrice.text =
                                  '${productData['Products']['$_editBrand']['$index']['Price']}';
                              _textFieldControllerEditStock.text =
                                  '${productData['Products']['$_editBrand']['$index']['Stock']}';
                              _textFieldControllerEditWeight.text =
                                  '${productData['Products']['$_editBrand']['$index']['Weight']}';
                              _textFieldControllerEditExRate.text =
                                  '${productData['Products']['$_editBrand']['Exchange Rate']}';
                              _textFieldControllerEditShipping.text =
                                  '${productData['Products']['$_editBrand']['Shipping']}';

                              showDialog<String>(
                                context: context,
                                builder: (BuildContext context) =>
                                    SimpleDialog(
                                  title: Image.asset(
                                      "assets/MacarbiFullLogo.jpg"),
                                  children: <Widget>[
                                    Row(children: <Widget>[
                                      Expanded(
                                        child: new Container(
                                            margin: const EdgeInsets.only(
                                                left: 10.0, right: 20.0),
                                            child: Divider(
                                              color: Colors.black,
                                              height: 36,
                                            )),
                                      ),
                                      Text(
                                        '$_editBrand',
                                        textAlign: TextAlign.center,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 20.0),
                                      ),
                                      Expanded(
                                        child: new Container(
                                            margin: const EdgeInsets.only(
                                                left: 20.0, right: 10.0),
                                            child: Divider(
                                              color: Colors.black,
                                              height: 36,
                                            )),
                                      ),
                                    ]),
                                    SingleChildScrollView(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: <Widget>[
                                          Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: <Widget>[
                                              Padding(
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                child: TextFormField(
                                                  controller:
                                                      _textFieldControllerEditName,
                                                  decoration: InputDecoration(
                                                    border:
                                                        OutlineInputBorder(),
                                                    helperText:
                                                        'Product Name',
                                                    labelText:
                                                        '${productData['Products']['$_editBrand']['$index']['Name']}',
                                                  ),
                                                  maxLines: 1,
                                                ),
                                              ),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                child: TextFormField(
                                                  controller:
                                                      _textFieldControllerEditPrice,
                                                  keyboardType: TextInputType
                                                      .numberWithOptions(
                                                          decimal: true),
                                                  inputFormatters: <
                                                      TextInputFormatter>[
                                                    WhitelistingTextInputFormatter(
                                                        RegExp("[0-9.]"))
                                                  ],
                                                  decoration: InputDecoration(
                                                    border:
                                                        OutlineInputBorder(),
                                                    helperText:
                                                        'Product Price - Agent Price',
                                                    labelText:
                                                        '${productData['Products']['$_editBrand']['$index']['Price']}',
                                                  ),
                                                  maxLines: 1,
                                                ),
                                              ),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                child: TextFormField(
                                                  controller:
                                                      _textFieldControllerEditStock,
                                                  keyboardType: TextInputType
                                                      .numberWithOptions(
                                                          decimal: true),
                                                  inputFormatters: <
                                                      TextInputFormatter>[
                                                    WhitelistingTextInputFormatter(
                                                        RegExp("[0-9.]"))
                                                  ],
                                                  decoration: InputDecoration(
                                                    border:
                                                        OutlineInputBorder(),
                                                    helperText:
                                                        'Product Stock',
                                                    labelText:
                                                        '${productData['Products']['$_editBrand']['$index']['Stock']}',
                                                  ),
                                                  maxLines: 1,
                                                ),
                                              ),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                child: TextFormField(
                                                  controller:
                                                      _textFieldControllerEditWeight,
                                                  keyboardType: TextInputType
                                                      .numberWithOptions(
                                                          decimal: true),
                                                  inputFormatters: <
                                                      TextInputFormatter>[
                                                    WhitelistingTextInputFormatter(
                                                        RegExp("[0-9.]"))
                                                  ],
                                                  decoration: InputDecoration(
                                                    border:
                                                        OutlineInputBorder(),
                                                    helperText:
                                                        'Product Weight - lbs',
                                                    labelText:
                                                        '${productData['Products']['$_editBrand']['$index']['Weight']}',
                                                  ),
                                                  maxLines: 1,
                                                ),
                                              ),
                                              Row(children: <Widget>[
                                                Expanded(
                                                  child: new Container(
                                                      margin: const EdgeInsets
                                                              .only(
                                                          left: 10.0,
                                                          right: 20.0),
                                                      child: Divider(
                                                        color: Colors.black,
                                                        height: 36,
                                                      )),
                                                ),
                                                Text(
                                                  'Global Settings For $_editBrand',
                                                  textAlign: TextAlign.center,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 15.0),
                                                ),
                                                Expanded(
                                                  child: new Container(
                                                      margin: const EdgeInsets
                                                              .only(
                                                          left: 20.0,
                                                          right: 10.0),
                                                      child: Divider(
                                                        color: Colors.black,
                                                        height: 36,
                                                      )),
                                                ),
                                              ]),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                child: TextFormField(
                                                  controller:
                                                      _textFieldControllerEditExRate,
                                                  decoration: InputDecoration(
                                                    border:
                                                        OutlineInputBorder(),
                                                    helperText:
                                                        'Global Setting Exchange Rate',
                                                    labelText:
                                                        '${productData['Products']['$_editBrand']['Exchange Rate']}',
                                                  ),
                                                  maxLines: 1,
                                                ),
                                              ),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                child: TextFormField(
                                                  controller:
                                                      _textFieldControllerEditShipping,
                                                  decoration: InputDecoration(
                                                    border:
                                                        OutlineInputBorder(),
                                                    helperText:
                                                        'Global Setting Shipping',
                                                    labelText:
                                                        '${productData['Products']['$_editBrand']['Shipping']}',
                                                  ),
                                                  maxLines: 1,
                                                ),
                                              ),
                                              ButtonBar(
                                                alignment: MainAxisAlignment
                                                    .spaceEvenly,
                                                children: <Widget>[
                                                  RaisedButton(
                                                    child: Text('SAVE'),
                                                    color: Colors.blue,
                                                    highlightColor:
                                                        Colors.grey,
                                                    shape:
                                                        new RoundedRectangleBorder(
                                                      borderRadius:
                                                          new BorderRadius
                                                              .circular(30.0),
                                                    ),
                                                    onPressed: () {
                                                      updateProduct(
                                                          '$_editBrand',
                                                          index,
                                                          '${_textFieldControllerEditName.text}',
                                                          '${_textFieldControllerEditPrice.text}',
                                                          '${_textFieldControllerEditStock.text}',
                                                          '${_textFieldControllerEditWeight.text}');
                                                      updateProductGlobal(
                                                          '$_editBrand',
                                                          '${_textFieldControllerEditExRate.text}',
                                                          '${_textFieldControllerEditShipping.text}');
                                                      _onClearEdit();
                                                      _onRefresh();
                                                      Navigator.pop(context);
                                                    },
                                                  ),
                                                  RaisedButton(
                                                    child: Text('DELETE'),
                                                    color: Colors.blue,
                                                    highlightColor:
                                                        Colors.grey,
                                                    shape:
                                                        new RoundedRectangleBorder(
                                                      borderRadius:
                                                          new BorderRadius
                                                              .circular(30.0),
                                                    ),
                                                    onPressed: () {
                                                      delProduct(
                                                          '$_editBrand',
                                                          index,
                                                          '${_textFieldControllerEditName.text}');
                                                      _onClearEdit();
                                                      _onRefresh();
                                                      Navigator.pop(context);
                                                    },
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            } else {
                              Fluttertoast.showToast(
                                msg: 'Login To Edit A Product',
                                toastLength: Toast.LENGTH_LONG,
                              );
                            }
                          },
                          onLongPress: () {
                            Clipboard.setData(new ClipboardData(
                                text:
                                    '${productData['Products']['Croker']['$index']['Name']}: R${productData['Products']['Croker']['$index']['Price']}'));
                            Fluttertoast.showToast(
                              msg:
                                  'Copied to Clipboard\n${productData['Products']['Croker']['$index']['Name']}: R${productData['Products']['Croker']['$index']['Price']}',
                              toastLength: Toast.LENGTH_LONG,
                            );
                          },
                        ));
  }

  Card buildCardConcept2(int index, BuildContext context) {
    return new Card(
                        color: qtyWarning ? Colors.grey : Colors.white,
                        child: new ListTile(
                          title: Text(
                              '${productData['Products']['Concept 2']['$index']['Name']}'),
                          subtitle: Text(
                              'R${productData['Products']['Concept 2']['$index']['Price']}\nQTY: ${productData['Products']['Concept 2']['$index']['Stock']}'),
                          trailing: _userEmail != null
                              ? Column(
                                  children: <Widget>[
                                    Expanded(
                                      child: IconButton(
                                        icon: Icon(Icons.arrow_upward),
                                        onPressed: () {
                                          _onRefresh();
                                          updateQty('Concept 2', index, 'up');
                                        },
                                      ),
                                    ),
                                    Expanded(
                                      child: IconButton(
                                        icon: Icon(Icons.arrow_downward),
                                        onPressed: () {
                                          _onRefresh();
                                          updateQty(
                                              'Concept 2', index, 'down');
                                        },
                                      ),
                                    ),
                                  ],
                                )
                              : Column(),
                          onTap: () {
                            if (_userEmail != null) {
                              String _editBrand = 'Concept 2';
                              _onClearEdit();
                              _textFieldControllerEditName.text =
                                  '${productData['Products']['$_editBrand']['$index']['Name']}';
                              _textFieldControllerEditPrice.text =
                                  '${productData['Products']['$_editBrand']['$index']['Price']}';
                              _textFieldControllerEditStock.text =
                                  '${productData['Products']['$_editBrand']['$index']['Stock']}';
                              _textFieldControllerEditWeight.text =
                                  '${productData['Products']['$_editBrand']['$index']['Weight']}';
                              _textFieldControllerEditExRate.text =
                                  '${productData['Products']['$_editBrand']['Exchange Rate']}';
                              _textFieldControllerEditShipping.text =
                                  '${productData['Products']['$_editBrand']['Shipping']}';

                              showDialog<String>(
                                context: context,
                                builder: (BuildContext context) =>
                                    SimpleDialog(
                                  title: Image.asset(
                                      "assets/MacarbiFullLogo.jpg"),
                                  children: <Widget>[
                                    Row(children: <Widget>[
                                      Expanded(
                                        child: new Container(
                                            margin: const EdgeInsets.only(
                                                left: 10.0, right: 20.0),
                                            child: Divider(
                                              color: Colors.black,
                                              height: 36,
                                            )),
                                      ),
                                      Text(
                                        '$_editBrand',
                                        textAlign: TextAlign.center,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 20.0),
                                      ),
                                      Expanded(
                                        child: new Container(
                                            margin: const EdgeInsets.only(
                                                left: 20.0, right: 10.0),
                                            child: Divider(
                                              color: Colors.black,
                                              height: 36,
                                            )),
                                      ),
                                    ]),
                                    SingleChildScrollView(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: <Widget>[
                                          Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: <Widget>[
                                              Padding(
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                child: TextFormField(
                                                  controller:
                                                      _textFieldControllerEditName,
                                                  decoration: InputDecoration(
                                                    border:
                                                        OutlineInputBorder(),
                                                    helperText:
                                                        'Product Name',
                                                    labelText:
                                                        '${productData['Products']['$_editBrand']['$index']['Name']}',
                                                  ),
                                                  maxLines: 1,
                                                ),
                                              ),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                child: TextFormField(
                                                  controller:
                                                      _textFieldControllerEditPrice,
                                                  keyboardType: TextInputType
                                                      .numberWithOptions(
                                                          decimal: true),
                                                  inputFormatters: <
                                                      TextInputFormatter>[
                                                    WhitelistingTextInputFormatter(
                                                        RegExp("[0-9.]"))
                                                  ],
                                                  decoration: InputDecoration(
                                                    border:
                                                        OutlineInputBorder(),
                                                    helperText:
                                                        'Product Price - Agent Price',
                                                    labelText:
                                                        '${productData['Products']['$_editBrand']['$index']['Price']}',
                                                  ),
                                                  maxLines: 1,
                                                ),
                                              ),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                child: TextFormField(
                                                  controller:
                                                      _textFieldControllerEditStock,
                                                  keyboardType: TextInputType
                                                      .numberWithOptions(
                                                          decimal: true),
                                                  inputFormatters: <
                                                      TextInputFormatter>[
                                                    WhitelistingTextInputFormatter(
                                                        RegExp("[0-9.]"))
                                                  ],
                                                  decoration: InputDecoration(
                                                    border:
                                                        OutlineInputBorder(),
                                                    helperText:
                                                        'Product Stock',
                                                    labelText:
                                                        '${productData['Products']['$_editBrand']['$index']['Stock']}',
                                                  ),
                                                  maxLines: 1,
                                                ),
                                              ),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                child: TextFormField(
                                                  controller:
                                                      _textFieldControllerEditWeight,
                                                  keyboardType: TextInputType
                                                      .numberWithOptions(
                                                          decimal: true),
                                                  inputFormatters: <
                                                      TextInputFormatter>[
                                                    WhitelistingTextInputFormatter(
                                                        RegExp("[0-9.]"))
                                                  ],
                                                  decoration: InputDecoration(
                                                    border:
                                                        OutlineInputBorder(),
                                                    helperText:
                                                        'Product Weight - lbs',
                                                    labelText:
                                                        '${productData['Products']['$_editBrand']['$index']['Weight']}',
                                                  ),
                                                  maxLines: 1,
                                                ),
                                              ),
                                              Row(children: <Widget>[
                                                Expanded(
                                                  child: new Container(
                                                      margin: const EdgeInsets
                                                              .only(
                                                          left: 10.0,
                                                          right: 20.0),
                                                      child: Divider(
                                                        color: Colors.black,
                                                        height: 36,
                                                      )),
                                                ),
                                                Text(
                                                  'Global Settings For $_editBrand',
                                                  textAlign: TextAlign.center,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 15.0),
                                                ),
                                                Expanded(
                                                  child: new Container(
                                                      margin: const EdgeInsets
                                                              .only(
                                                          left: 20.0,
                                                          right: 10.0),
                                                      child: Divider(
                                                        color: Colors.black,
                                                        height: 36,
                                                      )),
                                                ),
                                              ]),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                child: TextFormField(
                                                  controller:
                                                      _textFieldControllerEditExRate,
                                                  decoration: InputDecoration(
                                                    border:
                                                        OutlineInputBorder(),
                                                    helperText:
                                                        'Global Setting Exchange Rate',
                                                    labelText:
                                                        '${productData['Products']['$_editBrand']['Exchange Rate']}',
                                                  ),
                                                  maxLines: 1,
                                                ),
                                              ),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                child: TextFormField(
                                                  controller:
                                                      _textFieldControllerEditShipping,
                                                  decoration: InputDecoration(
                                                    border:
                                                        OutlineInputBorder(),
                                                    helperText:
                                                        'Global Setting Shipping',
                                                    labelText:
                                                        '${productData['Products']['$_editBrand']['Shipping']}',
                                                  ),
                                                  maxLines: 1,
                                                ),
                                              ),
                                              ButtonBar(
                                                alignment: MainAxisAlignment
                                                    .spaceEvenly,
                                                children: <Widget>[
                                                  RaisedButton(
                                                    child: Text('SAVE'),
                                                    color: Colors.blue,
                                                    highlightColor:
                                                        Colors.grey,
                                                    shape:
                                                        new RoundedRectangleBorder(
                                                      borderRadius:
                                                          new BorderRadius
                                                              .circular(30.0),
                                                    ),
                                                    onPressed: () {
                                                      updateProduct(
                                                          '$_editBrand',
                                                          index,
                                                          '${_textFieldControllerEditName.text}',
                                                          '${_textFieldControllerEditPrice.text}',
                                                          '${_textFieldControllerEditStock.text}',
                                                          '${_textFieldControllerEditWeight.text}');
                                                      updateProductGlobal(
                                                          '$_editBrand',
                                                          '${_textFieldControllerEditExRate.text}',
                                                          '${_textFieldControllerEditShipping.text}');
                                                      _onClearEdit();
                                                      _onRefresh();
                                                      Navigator.pop(context);
                                                    },
                                                  ),
                                                  RaisedButton(
                                                    child: Text('DELETE'),
                                                    color: Colors.blue,
                                                    highlightColor:
                                                        Colors.grey,
                                                    shape:
                                                        new RoundedRectangleBorder(
                                                      borderRadius:
                                                          new BorderRadius
                                                              .circular(30.0),
                                                    ),
                                                    onPressed: () {
                                                      delProduct(
                                                          '$_editBrand',
                                                          index,
                                                          '${_textFieldControllerEditName.text}');
                                                      _onClearEdit();
                                                      _onRefresh();
                                                      Navigator.pop(context);
                                                    },
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            } else {
                              Fluttertoast.showToast(
                                msg: 'Login To Edit A Product',
                                toastLength: Toast.LENGTH_LONG,
                              );
                            }
                          },
                          onLongPress: () {
                            Clipboard.setData(new ClipboardData(
                                text:
                                    '${productData['Products']['Concept 2']['$index']['Name']}: R${productData['Products']['Concept 2']['$index']['Price']}'));
                            Fluttertoast.showToast(
                              msg:
                                  'Copied to Clipboard\n${productData['Products']['Concept 2']['$index']['Name']}: R${productData['Products']['Concept 2']['$index']['Price']}',
                              toastLength: Toast.LENGTH_LONG,
                            );
                          },
                        ));
  }

  Card buildCardCoxmate(int index, BuildContext context) {
    return new Card(
                        color: qtyWarning ? Colors.grey : Colors.white,
                        child: new ListTile(
                          title: Text(
                              '${productData['Products']['Coxmate']['$index']['Name']}'),
                          subtitle: Text(
                              'R${calc(index, 'Coxmate')}\nQTY: ${productData['Products']['Coxmate']['$index']['Stock']}'), //todo cust price
                          trailing: _userEmail != null
                              ? Column(
                                  children: <Widget>[
                                    Expanded(
                                      child: IconButton(
                                        icon: Icon(Icons.arrow_upward),
                                        onPressed: () {
                                          _onRefresh();
                                          updateQty('Coxmate', index, 'up');
                                        },
                                      ),
                                    ),
                                    Expanded(
                                      child: IconButton(
                                        icon: Icon(Icons.arrow_downward),
                                        onPressed: () {
                                          _onRefresh();
                                          updateQty('Coxmate', index, 'down');
                                        },
                                      ),
                                    ),
                                  ],
                                )
                              : Column(),
                          onTap: () {
                            if (_userEmail != null) {
                              String _editBrand = 'Coxmate';
                              _onClearEdit();
                              _textFieldControllerEditName.text =
                                  '${productData['Products']['$_editBrand']['$index']['Name']}';
                              _textFieldControllerEditPrice.text =
                                  '${productData['Products']['$_editBrand']['$index']['Price']}';
                              _textFieldControllerEditStock.text =
                                  '${productData['Products']['$_editBrand']['$index']['Stock']}';
                              _textFieldControllerEditWeight.text =
                                  '${productData['Products']['$_editBrand']['$index']['Weight']}';
                              _textFieldControllerEditExRate.text =
                                  '${productData['Products']['$_editBrand']['Exchange Rate']}';
                              _textFieldControllerEditShipping.text =
                                  '${productData['Products']['$_editBrand']['Shipping']}';

                              showDialog<String>(
                                context: context,
                                builder: (BuildContext context) =>
                                    SimpleDialog(
                                  title: Image.asset(
                                      "assets/MacarbiFullLogo.jpg"),
                                  children: <Widget>[
                                    Row(children: <Widget>[
                                      Expanded(
                                        child: new Container(
                                            margin: const EdgeInsets.only(
                                                left: 10.0, right: 20.0),
                                            child: Divider(
                                              color: Colors.black,
                                              height: 36,
                                            )),
                                      ),
                                      Text(
                                        '$_editBrand',
                                        textAlign: TextAlign.center,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 20.0),
                                      ),
                                      Expanded(
                                        child: new Container(
                                            margin: const EdgeInsets.only(
                                                left: 20.0, right: 10.0),
                                            child: Divider(
                                              color: Colors.black,
                                              height: 36,
                                            )),
                                      ),
                                    ]),
                                    SingleChildScrollView(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: <Widget>[
                                          Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: <Widget>[
                                              Padding(
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                child: TextFormField(
                                                  controller:
                                                      _textFieldControllerEditName,
                                                  decoration: InputDecoration(
                                                    border:
                                                        OutlineInputBorder(),
                                                    helperText:
                                                        'Product Name',
                                                    labelText:
                                                        '${productData['Products']['$_editBrand']['$index']['Name']}',
                                                  ),
                                                  maxLines: 1,
                                                ),
                                              ),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                child: TextFormField(
                                                  controller:
                                                      _textFieldControllerEditPrice,
                                                  keyboardType: TextInputType
                                                      .numberWithOptions(
                                                          decimal: true),
                                                  inputFormatters: <
                                                      TextInputFormatter>[
                                                    WhitelistingTextInputFormatter(
                                                        RegExp("[0-9.]"))
                                                  ],
                                                  decoration: InputDecoration(
                                                    border:
                                                        OutlineInputBorder(),
                                                    helperText:
                                                        'Product Price - Agent Price',
                                                    labelText:
                                                        '${productData['Products']['$_editBrand']['$index']['Price']}',
                                                  ),
                                                  maxLines: 1,
                                                ),
                                              ),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                child: TextFormField(
                                                  controller:
                                                      _textFieldControllerEditStock,
                                                  keyboardType: TextInputType
                                                      .numberWithOptions(
                                                          decimal: true),
                                                  inputFormatters: <
                                                      TextInputFormatter>[
                                                    WhitelistingTextInputFormatter(
                                                        RegExp("[0-9.]"))
                                                  ],
                                                  decoration: InputDecoration(
                                                    border:
                                                        OutlineInputBorder(),
                                                    helperText:
                                                        'Product Stock',
                                                    labelText:
                                                        '${productData['Products']['$_editBrand']['$index']['Stock']}',
                                                  ),
                                                  maxLines: 1,
                                                ),
                                              ),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                child: TextFormField(
                                                  controller:
                                                      _textFieldControllerEditWeight,
                                                  keyboardType: TextInputType
                                                      .numberWithOptions(
                                                          decimal: true),
                                                  inputFormatters: <
                                                      TextInputFormatter>[
                                                    WhitelistingTextInputFormatter(
                                                        RegExp("[0-9.]"))
                                                  ],
                                                  decoration: InputDecoration(
                                                    border:
                                                        OutlineInputBorder(),
                                                    helperText:
                                                        'Product Weight - lbs',
                                                    labelText:
                                                        '${productData['Products']['$_editBrand']['$index']['Weight']}',
                                                  ),
                                                  maxLines: 1,
                                                ),
                                              ),
                                              Row(children: <Widget>[
                                                Expanded(
                                                  child: new Container(
                                                      margin: const EdgeInsets
                                                              .only(
                                                          left: 10.0,
                                                          right: 20.0),
                                                      child: Divider(
                                                        color: Colors.black,
                                                        height: 36,
                                                      )),
                                                ),
                                                Text(
                                                  'Global Settings For $_editBrand',
                                                  textAlign: TextAlign.center,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 15.0),
                                                ),
                                                Expanded(
                                                  child: new Container(
                                                      margin: const EdgeInsets
                                                              .only(
                                                          left: 20.0,
                                                          right: 10.0),
                                                      child: Divider(
                                                        color: Colors.black,
                                                        height: 36,
                                                      )),
                                                ),
                                              ]),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                child: TextFormField(
                                                  controller:
                                                      _textFieldControllerEditExRate,
                                                  decoration: InputDecoration(
                                                    border:
                                                        OutlineInputBorder(),
                                                    helperText:
                                                        'Global Setting Exchange Rate',
                                                    labelText:
                                                        '${productData['Products']['$_editBrand']['Exchange Rate']}',
                                                  ),
                                                  maxLines: 1,
                                                ),
                                              ),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                child: TextFormField(
                                                  controller:
                                                      _textFieldControllerEditShipping,
                                                  decoration: InputDecoration(
                                                    border:
                                                        OutlineInputBorder(),
                                                    helperText:
                                                        'Global Setting Shipping',
                                                    labelText:
                                                        '${productData['Products']['$_editBrand']['Shipping']}',
                                                  ),
                                                  maxLines: 1,
                                                ),
                                              ),
                                              ButtonBar(
                                                alignment: MainAxisAlignment
                                                    .spaceEvenly,
                                                children: <Widget>[
                                                  RaisedButton(
                                                    child: Text('SAVE'),
                                                    color: Colors.blue,
                                                    highlightColor:
                                                        Colors.grey,
                                                    shape:
                                                        new RoundedRectangleBorder(
                                                      borderRadius:
                                                          new BorderRadius
                                                              .circular(30.0),
                                                    ),
                                                    onPressed: () {
                                                      updateProduct(
                                                          '$_editBrand',
                                                          index,
                                                          '${_textFieldControllerEditName.text}',
                                                          '${_textFieldControllerEditPrice.text}',
                                                          '${_textFieldControllerEditStock.text}',
                                                          '${_textFieldControllerEditWeight.text}');
                                                      updateProductGlobal(
                                                          '$_editBrand',
                                                          '${_textFieldControllerEditExRate.text}',
                                                          '${_textFieldControllerEditShipping.text}');
                                                      _onClearEdit();
                                                      _onRefresh();
                                                      Navigator.pop(context);
                                                    },
                                                  ),
                                                  RaisedButton(
                                                    child: Text('DELETE'),
                                                    color: Colors.blue,
                                                    highlightColor:
                                                        Colors.grey,
                                                    shape:
                                                        new RoundedRectangleBorder(
                                                      borderRadius:
                                                          new BorderRadius
                                                              .circular(30.0),
                                                    ),
                                                    onPressed: () {
                                                      delProduct(
                                                          '$_editBrand',
                                                          index,
                                                          '${_textFieldControllerEditName.text}');
                                                      _onClearEdit();
                                                      _onRefresh();
                                                      Navigator.pop(context);
                                                    },
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            } else {
                              Fluttertoast.showToast(
                                msg: 'Login To Edit A Product',
                                toastLength: Toast.LENGTH_LONG,
                              );
                            }
                          },
                          onLongPress: () {
                            Clipboard.setData(new ClipboardData(
                                text:
                                    '${productData['Products']['Coxmate']['$index']['Name']}: R${calc(index, 'Coxmate')}.00'));
                            Fluttertoast.showToast(
                              msg:
                                  'Copied to Clipboard\n${productData['Products']['Coxmate']['$index']['Name']}: R${calc(index, 'Coxmate')}',
                              toastLength: Toast.LENGTH_LONG,
                            );
                          },
                        ));
  }

  Card buildCardActiveTools(int index, BuildContext context) {
    return new Card(
                        color: qtyWarning ? Colors.grey : Colors.white,
                        child: new ListTile(
                          title: Text(
                              '${productData['Products']['ActiveTools']['$index']['Name']}'),
                          subtitle: Text(
                              'R${calc(index, 'ActiveTools')}\nQTY: ${productData['Products']['ActiveTools']['$index']['Stock']}'), //todo cust price
                          trailing: _userEmail != null
                              ? Column(
                                  children: <Widget>[
                                    Expanded(
                                      child: IconButton(
                                        icon: Icon(Icons.arrow_upward),
                                        onPressed: () {
                                          _onRefresh();
                                          updateQty(
                                              'ActiveTools', index, 'up');
                                        },
                                      ),
                                    ),
                                    Expanded(
                                      child: IconButton(
                                        icon: Icon(Icons.arrow_downward),
                                        onPressed: () {
                                          _onRefresh();
                                          updateQty(
                                              'ActiveTools', index, 'down');
                                        },
                                      ),
                                    ),
                                  ],
                                )
                              : Column(),
                          onTap: () {
                            if (_userEmail != null) {
                              String _editBrand = 'ActiveTools';
                              _onClearEdit();
                              _textFieldControllerEditName.text =
                                  '${productData['Products']['$_editBrand']['$index']['Name']}';
                              _textFieldControllerEditPrice.text =
                                  '${productData['Products']['$_editBrand']['$index']['Price']}';
                              _textFieldControllerEditStock.text =
                                  '${productData['Products']['$_editBrand']['$index']['Stock']}';
                              _textFieldControllerEditWeight.text =
                                  '${productData['Products']['$_editBrand']['$index']['Weight']}';
                              _textFieldControllerEditExRate.text =
                                  '${productData['Products']['$_editBrand']['Exchange Rate']}';
                              _textFieldControllerEditShipping.text =
                                  '${productData['Products']['$_editBrand']['Shipping']}';

                              showDialog<String>(
                                context: context,
                                builder: (BuildContext context) =>
                                    SimpleDialog(
                                  title: Image.asset(
                                      "assets/MacarbiFullLogo.jpg"),
                                  children: <Widget>[
                                    Row(children: <Widget>[
                                      Expanded(
                                        child: new Container(
                                            margin: const EdgeInsets.only(
                                                left: 10.0, right: 20.0),
                                            child: Divider(
                                              color: Colors.black,
                                              height: 36,
                                            )),
                                      ),
                                      Text(
                                        '$_editBrand',
                                        textAlign: TextAlign.center,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 20.0),
                                      ),
                                      Expanded(
                                        child: new Container(
                                            margin: const EdgeInsets.only(
                                                left: 20.0, right: 10.0),
                                            child: Divider(
                                              color: Colors.black,
                                              height: 36,
                                            )),
                                      ),
                                    ]),
                                    SingleChildScrollView(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: <Widget>[
                                          Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: <Widget>[
                                              Padding(
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                child: TextFormField(
                                                  controller:
                                                      _textFieldControllerEditName,
                                                  decoration: InputDecoration(
                                                    border:
                                                        OutlineInputBorder(),
                                                    helperText:
                                                        'Product Name',
                                                    labelText:
                                                        '${productData['Products']['$_editBrand']['$index']['Name']}',
                                                  ),
                                                  maxLines: 1,
                                                ),
                                              ),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                child: TextFormField(
                                                  controller:
                                                      _textFieldControllerEditPrice,
                                                  keyboardType: TextInputType
                                                      .numberWithOptions(
                                                          decimal: true),
                                                  inputFormatters: <
                                                      TextInputFormatter>[
                                                    WhitelistingTextInputFormatter(
                                                        RegExp("[0-9.]"))
                                                  ],
                                                  decoration: InputDecoration(
                                                    border:
                                                        OutlineInputBorder(),
                                                    helperText:
                                                        'Product Price - Agent Price',
                                                    labelText:
                                                        '${productData['Products']['$_editBrand']['$index']['Price']}',
                                                  ),
                                                  maxLines: 1,
                                                ),
                                              ),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                child: TextFormField(
                                                  controller:
                                                      _textFieldControllerEditStock,
                                                  keyboardType: TextInputType
                                                      .numberWithOptions(
                                                          decimal: true),
                                                  inputFormatters: <
                                                      TextInputFormatter>[
                                                    WhitelistingTextInputFormatter(
                                                        RegExp("[0-9.]"))
                                                  ],
                                                  decoration: InputDecoration(
                                                    border:
                                                        OutlineInputBorder(),
                                                    helperText:
                                                        'Product Stock',
                                                    labelText:
                                                        '${productData['Products']['$_editBrand']['$index']['Stock']}',
                                                  ),
                                                  maxLines: 1,
                                                ),
                                              ),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                child: TextFormField(
                                                  controller:
                                                      _textFieldControllerEditWeight,
                                                  keyboardType: TextInputType
                                                      .numberWithOptions(
                                                          decimal: true),
                                                  inputFormatters: <
                                                      TextInputFormatter>[
                                                    WhitelistingTextInputFormatter(
                                                        RegExp("[0-9.]"))
                                                  ],
                                                  decoration: InputDecoration(
                                                    border:
                                                        OutlineInputBorder(),
                                                    helperText:
                                                        'Product Weight - lbs',
                                                    labelText:
                                                        '${productData['Products']['$_editBrand']['$index']['Weight']}',
                                                  ),
                                                  maxLines: 1,
                                                ),
                                              ),
                                              Row(children: <Widget>[
                                                Expanded(
                                                  child: new Container(
                                                      margin: const EdgeInsets
                                                              .only(
                                                          left: 10.0,
                                                          right: 20.0),
                                                      child: Divider(
                                                        color: Colors.black,
                                                        height: 36,
                                                      )),
                                                ),
                                                Text(
                                                  'Global Settings For $_editBrand',
                                                  textAlign: TextAlign.center,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 15.0),
                                                ),
                                                Expanded(
                                                  child: new Container(
                                                      margin: const EdgeInsets
                                                              .only(
                                                          left: 20.0,
                                                          right: 10.0),
                                                      child: Divider(
                                                        color: Colors.black,
                                                        height: 36,
                                                      )),
                                                ),
                                              ]),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                child: TextFormField(
                                                  controller:
                                                      _textFieldControllerEditExRate,
                                                  decoration: InputDecoration(
                                                    border:
                                                        OutlineInputBorder(),
                                                    helperText:
                                                        'Global Setting Exchange Rate',
                                                    labelText:
                                                        '${productData['Products']['$_editBrand']['Exchange Rate']}',
                                                  ),
                                                  maxLines: 1,
                                                ),
                                              ),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                child: TextFormField(
                                                  controller:
                                                      _textFieldControllerEditShipping,
                                                  decoration: InputDecoration(
                                                    border:
                                                        OutlineInputBorder(),
                                                    helperText:
                                                        'Global Setting Shipping',
                                                    labelText:
                                                        '${productData['Products']['$_editBrand']['Shipping']}',
                                                  ),
                                                  maxLines: 1,
                                                ),
                                              ),
                                              ButtonBar(
                                                alignment: MainAxisAlignment
                                                    .spaceEvenly,
                                                children: <Widget>[
                                                  RaisedButton(
                                                    child: Text('SAVE'),
                                                    color: Colors.blue,
                                                    highlightColor:
                                                        Colors.grey,
                                                    shape:
                                                        new RoundedRectangleBorder(
                                                      borderRadius:
                                                          new BorderRadius
                                                              .circular(30.0),
                                                    ),
                                                    onPressed: () {
                                                      updateProduct(
                                                          '$_editBrand',
                                                          index,
                                                          '${_textFieldControllerEditName.text}',
                                                          '${_textFieldControllerEditPrice.text}',
                                                          '${_textFieldControllerEditStock.text}',
                                                          '${_textFieldControllerEditWeight.text}');
                                                      updateProductGlobal(
                                                          '$_editBrand',
                                                          '${_textFieldControllerEditExRate.text}',
                                                          '${_textFieldControllerEditShipping.text}');
                                                      _onClearEdit();
                                                      _onRefresh();
                                                      Navigator.pop(context);
                                                    },
                                                  ),
                                                  RaisedButton(
                                                    child: Text('DELETE'),
                                                    color: Colors.blue,
                                                    highlightColor:
                                                        Colors.grey,
                                                    shape:
                                                        new RoundedRectangleBorder(
                                                      borderRadius:
                                                          new BorderRadius
                                                              .circular(30.0),
                                                    ),
                                                    onPressed: () {
                                                      delProduct(
                                                          '$_editBrand',
                                                          index,
                                                          '${_textFieldControllerEditName.text}');
                                                      _onClearEdit();
                                                      _onRefresh();
                                                      Navigator.pop(context);
                                                    },
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            } else {
                              Fluttertoast.showToast(
                                msg: 'Logged In To Edit A Product',
                                toastLength: Toast.LENGTH_LONG,
                              );
                            }
                          },
                          onLongPress: () {
                            Clipboard.setData(new ClipboardData(
                                text:
                                    '${productData['Products']['ActiveTools']['$index']['Name']}: R${calc(index, 'ActiveTools')}.00'));
                            Fluttertoast.showToast(
                              msg:
                                  'Copied to Clipboard\n${productData['Products']['ActiveTools']['$index']['Name']}: R${calc(index, 'ActiveTools')}',
                              toastLength: Toast.LENGTH_LONG,
                            );
                          },
                        ));
  }

  Card buildCardNK(int index, BuildContext context) {
    return new Card(
                            color: qtyWarning ? Colors.grey : Colors.white,
                            child: new ListTile(
                              title: Text(
                                  '${productData['Products']['NK']['$index']['Name']}'),
                              subtitle: Text(
                                  'R${calc(index, 'NK')}\nQTY: ${productData['Products']['NK']['$index']['Stock']}'), //todo cust price
                              trailing: _userEmail != null
                                  ? Column(
                                      children: <Widget>[
                                        Expanded(
                                          child: IconButton(
                                            icon: Icon(Icons.arrow_upward),
                                            onPressed: () {
                                              _onRefresh();
                                              updateQty('NK', index, 'up');
                                            },
                                          ),
                                        ),
                                        Expanded(
                                          child: IconButton(
                                            icon: Icon(Icons.arrow_downward),
                                            onPressed: () {
                                              _onRefresh();
                                              updateQty('NK', index, 'down');
                                            },
                                          ),
                                        ),
                                      ],
                                    )
                                  : Column(),
                              onTap: () {
                                if (_userEmail != null) {
                                  String _editBrand = 'NK';
                                  _onClearEdit();
                                  _textFieldControllerEditName.text =
                                      '${productData['Products']['$_editBrand']['$index']['Name']}';
                                  _textFieldControllerEditPrice.text =
                                      '${productData['Products']['$_editBrand']['$index']['Price']}';
                                  _textFieldControllerEditStock.text =
                                      '${productData['Products']['$_editBrand']['$index']['Stock']}';
                                  _textFieldControllerEditWeight.text =
                                      '${productData['Products']['$_editBrand']['$index']['Weight']}';
                                  _textFieldControllerEditExRate.text =
                                      '${productData['Products']['$_editBrand']['Exchange Rate']}';
                                  _textFieldControllerEditShipping.text =
                                      '${productData['Products']['$_editBrand']['Shipping']}';

                                  showDialog<String>(
                                    context: context,
                                    builder: (BuildContext context) =>
                                        SimpleDialog(
                                      title: Image.asset(
                                          "assets/MacarbiFullLogo.jpg"),
                                      children: <Widget>[
                                        Row(children: <Widget>[
                                          Expanded(
                                            child: new Container(
                                                margin: const EdgeInsets.only(
                                                    left: 10.0, right: 20.0),
                                                child: Divider(
                                                  color: Colors.black,
                                                  height: 36,
                                                )),
                                          ),
                                          Text(
                                            '$_editBrand',
                                            textAlign: TextAlign.center,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 20.0),
                                          ),
                                          Expanded(
                                            child: new Container(
                                                margin: const EdgeInsets.only(
                                                    left: 20.0, right: 10.0),
                                                child: Divider(
                                                  color: Colors.black,
                                                  height: 36,
                                                )),
                                          ),
                                        ]),
                                        SingleChildScrollView(
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.stretch,
                                            children: <Widget>[
                                              Column(
                                                mainAxisSize:
                                                    MainAxisSize.min,
                                                children: <Widget>[
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            8.0),
                                                    child: TextFormField(
                                                      controller:
                                                          _textFieldControllerEditName,
                                                      decoration:
                                                          InputDecoration(
                                                        border:
                                                            OutlineInputBorder(),
                                                        helperText:
                                                            'Product Name',
                                                        labelText:
                                                            '${productData['Products']['$_editBrand']['$index']['Name']}',
                                                      ),
                                                      maxLines: 1,
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            8.0),
                                                    child: TextFormField(
                                                      controller:
                                                          _textFieldControllerEditPrice,
                                                      keyboardType: TextInputType
                                                          .numberWithOptions(
                                                              decimal: true),
                                                      inputFormatters: <
                                                          TextInputFormatter>[
                                                        WhitelistingTextInputFormatter(
                                                            RegExp("[0-9.]"))
                                                      ],
                                                      decoration:
                                                          InputDecoration(
                                                        border:
                                                            OutlineInputBorder(),
                                                        helperText:
                                                            'Product Price - Agent Price',
                                                        labelText:
                                                            '${productData['Products']['$_editBrand']['$index']['Price']}',
                                                      ),
                                                      maxLines: 1,
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            8.0),
                                                    child: TextFormField(
                                                      controller:
                                                          _textFieldControllerEditStock,
                                                      keyboardType: TextInputType
                                                          .numberWithOptions(
                                                              decimal: true),
                                                      inputFormatters: <
                                                          TextInputFormatter>[
                                                        WhitelistingTextInputFormatter(
                                                            RegExp("[0-9.]"))
                                                      ],
                                                      decoration:
                                                          InputDecoration(
                                                        border:
                                                            OutlineInputBorder(),
                                                        helperText:
                                                            'Product Stock',
                                                        labelText:
                                                            '${productData['Products']['$_editBrand']['$index']['Stock']}',
                                                      ),
                                                      maxLines: 1,
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            8.0),
                                                    child: TextFormField(
                                                      controller:
                                                          _textFieldControllerEditWeight,
                                                      keyboardType: TextInputType
                                                          .numberWithOptions(
                                                              decimal: true),
                                                      inputFormatters: <
                                                          TextInputFormatter>[
                                                        WhitelistingTextInputFormatter(
                                                            RegExp("[0-9.]"))
                                                      ],
                                                      decoration:
                                                          InputDecoration(
                                                        border:
                                                            OutlineInputBorder(),
                                                        helperText:
                                                            'Product Weight - lbs',
                                                        labelText:
                                                            '${productData['Products']['$_editBrand']['$index']['Weight']}',
                                                      ),
                                                      maxLines: 1,
                                                    ),
                                                  ),
                                                  Row(children: <Widget>[
                                                    Expanded(
                                                      child: new Container(
                                                          margin:
                                                              const EdgeInsets
                                                                      .only(
                                                                  left: 10.0,
                                                                  right:
                                                                      20.0),
                                                          child: Divider(
                                                            color:
                                                                Colors.black,
                                                            height: 36,
                                                          )),
                                                    ),
                                                    Text(
                                                      'Global Settings For $_editBrand',
                                                      textAlign:
                                                          TextAlign.center,
                                                      overflow: TextOverflow
                                                          .ellipsis,
                                                      style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 15.0),
                                                    ),
                                                    Expanded(
                                                      child: new Container(
                                                          margin:
                                                              const EdgeInsets
                                                                      .only(
                                                                  left: 20.0,
                                                                  right:
                                                                      10.0),
                                                          child: Divider(
                                                            color:
                                                                Colors.black,
                                                            height: 36,
                                                          )),
                                                    ),
                                                  ]),
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            8.0),
                                                    child: TextFormField(
                                                      controller:
                                                          _textFieldControllerEditExRate,
                                                      decoration:
                                                          InputDecoration(
                                                        border:
                                                            OutlineInputBorder(),
                                                        helperText:
                                                            'Global Setting Exchange Rate',
                                                        labelText:
                                                            '${productData['Products']['$_editBrand']['Exchange Rate']}',
                                                      ),
                                                      maxLines: 1,
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            8.0),
                                                    child: TextFormField(
                                                      controller:
                                                          _textFieldControllerEditShipping,
                                                      decoration:
                                                          InputDecoration(
                                                        border:
                                                            OutlineInputBorder(),
                                                        helperText:
                                                            'Global Setting Shipping',
                                                        labelText:
                                                            '${productData['Products']['$_editBrand']['Shipping']}',
                                                      ),
                                                      maxLines: 1,
                                                    ),
                                                  ),
                                                  ButtonBar(
                                                    alignment:
                                                        MainAxisAlignment
                                                            .spaceEvenly,
                                                    children: <Widget>[
                                                      RaisedButton(
                                                        child: Text('SAVE'),
                                                        color: Colors.blue,
                                                        highlightColor:
                                                            Colors.grey,
                                                        shape:
                                                            new RoundedRectangleBorder(
                                                          borderRadius:
                                                              new BorderRadius
                                                                      .circular(
                                                                  30.0),
                                                        ),
                                                        onPressed: () {
                                                          updateProduct(
                                                              '$_editBrand',
                                                              index,
                                                              '${_textFieldControllerEditName.text}',
                                                              '${_textFieldControllerEditPrice.text}',
                                                              '${_textFieldControllerEditStock.text}',
                                                              '${_textFieldControllerEditWeight.text}');
                                                          updateProductGlobal(
                                                              '$_editBrand',
                                                              '${_textFieldControllerEditExRate.text}',
                                                              '${_textFieldControllerEditShipping.text}');
                                                          _onClearEdit();
                                                          _onRefresh();
                                                          Navigator.pop(
                                                              context);
                                                        },
                                                      ),
                                                      RaisedButton(
                                                        child: Text('DELETE'),
                                                        color: Colors.blue,
                                                        highlightColor:
                                                            Colors.grey,
                                                        shape:
                                                            new RoundedRectangleBorder(
                                                          borderRadius:
                                                              new BorderRadius
                                                                      .circular(
                                                                  30.0),
                                                        ),
                                                        onPressed: () {
                                                          delProduct(
                                                              '$_editBrand',
                                                              index,
                                                              '${_textFieldControllerEditName.text}');
                                                          _onClearEdit();
                                                          _onRefresh();
                                                          Navigator.pop(
                                                              context);
                                                        },
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                } else {
                                  Fluttertoast.showToast(
                                    msg: 'Login To Edit A Product',
                                    toastLength: Toast.LENGTH_LONG,
                                  );
                                }
                              },
                              onLongPress: () {
                                Clipboard.setData(new ClipboardData(
                                    text:
                                        '${productData['Products']['NK']['$index']['Name']}: R${calc(index, 'NK')}.00'));
                                Fluttertoast.showToast(
                                  msg:
                                      'Copied to Clipboard\n${productData['Products']['NK']['$index']['Name']}: R${calc(index, 'NK')}',
                                  toastLength: Toast.LENGTH_LONG,
                                );
                              },
                            ));
  }
}

//Search Box
class TextBoxSearch extends StatelessWidget {
  TextBoxSearch();
  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerLeft,
      child: TextField(
        onChanged: (value) {
          _search = value;
        },
        style: new TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Search',
        ),
      ),
    );
  }
}
