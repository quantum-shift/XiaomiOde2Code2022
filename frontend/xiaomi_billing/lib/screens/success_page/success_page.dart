import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:xiaomi_billing/screens/home_page/home_page.dart';

import '../../constants.dart';

class SuccessPage extends StatefulWidget {
  const SuccessPage({super.key});

  @override
  State<SuccessPage> createState() => _SuccessPageState();
}

class _SuccessPageState extends State<SuccessPage> {
  double _imageHeight = 400;

  void onMount() {
    Timer(Duration(seconds: 0), () {
      setState(() {
        _imageHeight = 550;
      });
    });
  }

  // refresh cart on mount
  @override
  void initState() {
    super.initState();
    onMount();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return WillPopScope(
        child: Scaffold(
            appBar: AppBar(
                automaticallyImplyLeading: false, backgroundColor: miOrange),
            backgroundColor: Colors.white,
            body: ListView(children: [
              Container(
                  padding: EdgeInsets.fromLTRB(20, 0, 20, 0),
                  child: Column(
                    children: [
                      AnimatedContainer(
                          duration: Duration(milliseconds: 200),
                          height: _imageHeight,
                          child: Image.asset('assets/success.jpg')),
                      Container(
                        margin: EdgeInsetsDirectional.all(0),
                        child: TextButton(
                          child: Text('Back to Home',
                              style: TextStyle(fontSize: 18.5)),
                          onPressed: () {
                            Navigator.of(context).push(MaterialPageRoute(
                                builder: (context) => const HomePage()));
                          },
                        ),
                      )
                    ],
                  )),
            ])),
        onWillPop: () async {
          return false;
        });
  }
}
