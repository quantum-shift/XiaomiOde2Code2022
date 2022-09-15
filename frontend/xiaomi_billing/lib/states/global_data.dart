import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class GlobalData extends ChangeNotifier {
  bool visitedCart = false;
  String operatorId = '';
  String storeType = 'Mobile Store';

  void setVisitedCart(bool visitedCart) {
    this.visitedCart = visitedCart;
    notifyListeners();
  }

  void setOperatorId(String operatorId) {
    this.operatorId = operatorId;
    notifyListeners();
  }

  void setStoreType(String storeType) {
    this.storeType = storeType;
    notifyListeners();
  }
}

void saveDataToFile<T>(String key, T value) async {
  var box = await Hive.openBox('global');
  box.put(key, value);
}

Future<T> readDataFromFile<T>(String key) async {
  var box = await Hive.openBox('global');
  return box.get(key);
}
