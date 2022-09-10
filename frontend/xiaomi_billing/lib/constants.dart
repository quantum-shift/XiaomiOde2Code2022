import 'dart:io' show Platform;

String baseUrl = 'http://localhost:8000';

void setBaseUrl() {
  if (Platform.isAndroid) {
    print("Base url correctly set!");
    baseUrl = 'http://10.0.2.2:8000';
  }
}
