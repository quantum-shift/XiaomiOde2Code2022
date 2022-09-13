import 'dart:io' show Platform;

import 'package:flutter/material.dart';

import 'package:flutter/foundation.dart' show kIsWeb;

String baseUrl = 'http://localhost:8000';

MaterialColor createMaterialColor(Color color) {
  List strengths = <double>[.05];
  Map<int, Color> swatch = {};
  final int r = color.red, g = color.green, b = color.blue;

  for (int i = 1; i < 10; i++) {
    strengths.add(0.1 * i);
  }
  for (var strength in strengths) {
    final double ds = 0.5 - strength;
    swatch[(strength * 1000).round()] = Color.fromRGBO(
      r + ((ds < 0 ? r : (255 - r)) * ds).round(),
      g + ((ds < 0 ? g : (255 - g)) * ds).round(),
      b + ((ds < 0 ? b : (255 - b)) * ds).round(),
      1,
    );
  }
  return MaterialColor(color.value, swatch);
}

var getButtonStyle = (context) => ButtonStyle(
      backgroundColor: MaterialStateProperty.resolveWith<Color?>(
        (Set<MaterialState> states) {
          if (states.contains(MaterialState.pressed)) {
            return Theme.of(context).colorScheme.primary.withOpacity(0.5);
          }
          return null; // Use the component's default.
        },
      ),
      shape: MaterialStateProperty.all<RoundedRectangleBorder>(
          RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      )),
    );

MaterialColor miOrange = createMaterialColor(const Color(0xffff6801));

void setBaseUrl() {
  if (kIsWeb) {
    ;
  } else {
    if (Platform.isAndroid) {
      print("Base url correctly set!");
      baseUrl = 'http://10.0.2.2:8000';
    } else if (Platform.isMacOS) {
      print("Base url correctly set!");
      baseUrl = 'http://pc01.local:8000';
      // print(baseUrl);
    }
  }
}
