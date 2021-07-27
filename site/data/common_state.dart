import 'package:flutter/cupertino.dart';

enum SortMethod { None }

class CommonState extends ChangeNotifier {
  bool _connected = false;
  bool get connected => _connected;
  void setConnected(bool value) => _connected = value;

  int _entities = 0;
  int get entities => _entities;
  void setEntities(int value) {
    _entities = value;
    notifyListeners();
  }

  void entitiesDecr() {
    _entities--;
    notifyListeners();
  }

  void entitiesIncr() {
    _entities++;
    notifyListeners();
  }
}
