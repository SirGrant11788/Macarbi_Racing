import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:macarbi_racing/services/noteAdd.dart';
import 'package:macarbi_racing/services/noteDelete.dart';
import 'package:macarbi_racing/services/noteRead.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class ToDo extends StatefulWidget {
  @override
  _ToDoState createState() => _ToDoState();
}

class _ToDoState extends State<ToDo> {
  RefreshController _refreshController =
      RefreshController(initialRefresh: false);

  TextEditingController _textFieldControllerTitle = TextEditingController();
  TextEditingController _textFieldControllerNote = TextEditingController();

  _onClear() {
    setState(() {
      _textFieldControllerTitle.text = "";
      _textFieldControllerNote.text = "";
    });
  }

  var noteListValues;

  var noteListKeys;

  void _onRefresh() async {
    // monitor network fetch
    readNote();
    await Future.delayed(Duration(milliseconds: 1000));
    if(noteData.length == 0){
      _onRefresh();
    }
    setState(() {
      noteListValues = noteData["Notes"].values.toList();
      noteListKeys = noteData["Notes"].keys.toList();
    });
    // if failed,use refreshFailed()

    _refreshController.refreshCompleted();
  }

  void _onLoading() async {
    // monitor network fetch
    readNote();
    await Future.delayed(Duration(milliseconds: 1000));
    if(noteData.length == 0){
      _onRefresh();
    }
    // if failed,use loadFailed(),if no data return,use LoadNodata()

    if (mounted) setState(() {});
    _refreshController.loadComplete();
  }

  @override
  Widget build(BuildContext context) {

readNote();
    if (noteData.length == 0 || noteListKeys == null) {
      _onRefresh();
      return Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("To Do"),
      ),
      body: Container(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextFormField(
                controller: _textFieldControllerTitle,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Title',
                  labelText: 'Title',
                ),
                maxLines: 1,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextFormField(
                controller: _textFieldControllerNote,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Note',
                  labelText: 'Note',
                ),
                maxLines: 3,
              ),
            ),
            ButtonBar(
              alignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                RaisedButton(
                  child: Text('POST'),
                  color: Colors.blue,
                  highlightColor: Colors.grey,
                  shape: new RoundedRectangleBorder(
                    borderRadius: new BorderRadius.circular(30.0),
                  ),
                  onPressed: () {
                    addNote('${_textFieldControllerTitle.text}',
                        '${_textFieldControllerNote.text}');
                    _onClear();
                    _onRefresh();
                    
                  },
                ),
              ],
            ),
            Divider(
              color: Colors.blue,
            ),
            Expanded(
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
                child: new ListView.separated(
                  separatorBuilder: (context, index) => Divider(
                    color: Colors.blue,
                  ),
                  //Notes
                  shrinkWrap: true,
                  itemCount: noteData['Notes'].length,
                  itemBuilder: (BuildContext context, int index) {
                    return Dismissible(
                      key: UniqueKey(),
                      onDismissed: (DismissDirection dir) {
                        
                        print('swipe delete note: ${noteListKeys[index]}');
                        deleteNote('${noteListKeys[index]}');
                        
                      },
                      background: Container(
                        color: Colors.red,
                        child: Icon(Icons.delete),
                        alignment: Alignment.centerLeft,
                      ),
                      secondaryBackground: Container(
                        color: Colors.red,
                        child: Icon(Icons.delete),
                        alignment: Alignment.centerRight,
                      ),
                      child: new ListTile(
                        title: Text('${noteListKeys[index]}'),
                        subtitle: Text('${noteListValues[index]['Contents']}'),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
