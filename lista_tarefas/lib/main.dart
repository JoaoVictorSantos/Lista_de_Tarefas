import "dart:async";
import 'dart:convert';
import 'dart:io';

import "package:flutter/material.dart";
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(MaterialApp(home: Home()));
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final toDoController = TextEditingController();
  List _toDoList = [];
  Map<String, dynamic> _lastRemoved;
  int _lastRemovedPos;

  @override
  void initState() {
    //esse método é chamando toda vez que a tela é carregada.
    //Assim, ele irá busca os dados salvos, quando a tela for carregada.
    super.initState();

    _readFile().then((data) {
      setState(() {
        _toDoList = json.decode(data);
      });
    });
  }

  void _addToDo() {
    setState(() {
      Map<String, dynamic> newToDo = Map();
      newToDo["title"] = toDoController.text;
      toDoController.text = "";
      newToDo["ok"] = false;
      _toDoList.add(newToDo);
      _saveFile();
    });
  }

  Future<Null> _refresh() async {
    //forma de fazer o programa esperar por um certo tempo.
    await Future.delayed(Duration(seconds: 1));
    setState(() {
      _toDoList.sort((a, b) {
        if (a["ok"] && !b["ok"]) return 1;
        if (!a["ok"] && b["ok"]) return -1;
        return 0;
      });
      _saveFile();
    });
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text("Lista de tarefas"),
          backgroundColor: Colors.blueAccent,
          centerTitle: true),
      body: Column(
        children: <Widget>[
          Container(
            padding: EdgeInsets.fromLTRB(17.0, 1.0, 7.0, 1.0),
            child: Row(
              children: <Widget>[
                Expanded(
                  //forma de limitar um widget na tela
                  child: TextField(
                      controller: toDoController,
                      decoration: InputDecoration(
                          labelText: "Nova Tarefa",
                          labelStyle: TextStyle(color: Colors.blueAccent))),
                ),
                RaisedButton(
                  child: Text("ADD"),
                  onPressed: _addToDo,
                  color: Colors.blueAccent,
                  textColor: Colors.white,
                )
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
                //forma de atualizar a lista rolando ela pra baixo.
                child: ListView.builder(
                    // forma de construir uma lista dinamica,
                    //onde os dados só são carregados, quando eles aparecem na tela
                    padding: EdgeInsets.only(top: 10.0),
                    itemCount: _toDoList.length,
                    itemBuilder: buildItem),
                onRefresh: _refresh),
          )
        ],
      ),
    );
  }

  Widget buildItem(context, index) {
    //return ListTile(//forma de mostrar uma lista simplificada
    //  title: Text(_toDoList[index]),
    //);
    return Dismissible(
      //forma de fazer o witget ser arrastado para o lado.
      key: Key(DateTime.now().millisecondsSinceEpoch.toString()),
      direction: DismissDirection.startToEnd,

      background: Container(
        color: Colors.red,
        child: Align(
            //forma de deixar o item alinhado com base no x e y.
            alignment: Alignment(-0.9, -0.0),
            child: Icon(Icons.delete, color: Colors.white)),
      ),
      child: CheckboxListTile(
        title: Text(_toDoList[index]["title"]),
        value: _toDoList[index]["ok"],
        secondary: CircleAvatar(
          child: Icon(_toDoList[index]["ok"] ? Icons.check : Icons.error),
        ),
        onChanged: (c) {
          //Indica se o item foi selecionado ou desselecionado.
          setState(() {
            _toDoList[index]["ok"] = c;
            _saveFile();
          });
        },
      ),
      onDismissed: (direction) {
        //Quando a direção não é definida, conseguimos saber a direção pela variavel
        setState(() {
          _lastRemoved = Map.from(_toDoList[index]);
          _lastRemovedPos = index;
          _toDoList.removeAt(index);
          _saveFile();
        });

        final snackBar = SnackBar(
          //forma de criar uma snackBar com ação
          content: Text("Tarefa \"${_lastRemoved["title"]}\" removida!"),
          action: SnackBarAction(
              label: "Desfazer",
              onPressed: () {
                setState(() {
                  _toDoList.insert(_lastRemovedPos, _lastRemoved);
                  _saveFile();
                });
              }),
          duration: Duration(seconds: 2),
        );
        //Removendo a snackBar anterior(se tiver) antes de mostrar a proxima.
        Scaffold.of(context).removeCurrentSnackBar();
        Scaffold.of(context).showSnackBar(snackBar);
      },
    );
  }

  Future<File> _getFile() async {
    //pegando o path ideal(para android e ios) para salvar os arquivos com os dados
    final directory = await getApplicationDocumentsDirectory();
    return File("${directory.path}/data.json");
  }

  Future<File> _saveFile() async {
    String data = json.encode(_toDoList);
    final file = await _getFile();
    return file.writeAsString(data);
  }

  Future<String> _readFile() async {
    try {
      final file = await _getFile();
      return file.readAsString();
    } catch (e) {
      print(e);
      return null;
    }
  }
}
