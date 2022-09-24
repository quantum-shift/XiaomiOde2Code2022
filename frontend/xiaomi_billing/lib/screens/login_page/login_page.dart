import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:xiaomi_billing/constants.dart';
import 'package:xiaomi_billing/screens/home_page/home_page.dart';
import 'package:xiaomi_billing/states/credential_manager.dart';

import '../../states/global_data.dart';

class LoginPage extends StatefulWidget {
  LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _usernameController = TextEditingController();

  final TextEditingController _passwordController = TextEditingController();

  String storeType = 'Mi Home';

  final List<String> storeTypeOptions = ['Mi Home', 'Mi Store', 'Mi Support'];

  bool _loading = false;

  String? formFieldValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Fields cannot be empty';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Xiaomi Billing"),
          backgroundColor: miOrange,
          foregroundColor: Colors.white,
          automaticallyImplyLeading: false,
        ),
        body: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.all(25.0),
                child: Image.asset(
                  'assets/mi.svg.png',
                  width: 70,
                  height: 70,
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(
                    vertical: 8.0, horizontal: size.width * 0.1),
                child: TextFormField(
                  controller: _usernameController,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8.0)),
                      ),
                      labelText: 'MI ID'),
                  validator: formFieldValidator,
                  textInputAction: TextInputAction.next,
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(
                    vertical: 8.0, horizontal: size.width * 0.1),
                child: TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8.0)),
                      ),
                      labelText: 'Password'),
                  validator: formFieldValidator,
                  textInputAction: TextInputAction.done,
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(
                    vertical: 8, horizontal: size.width * 0.1),
                child: FormField(
                  builder: (FormFieldState<String> state) => InputDecorator(
                    decoration: const InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(8.0)),
                        ),
                        labelText: 'Communication Type'),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isDense: true,
                        focusColor: miOrange,
                        value: storeType,
                        onChanged: (String? value) {
                          context
                              .read<GlobalData>()
                              .setStoreType(value!);
                          setState(() {
                            storeType = value;
                          });
                        },
                        items: storeTypeOptions
                            .map<DropdownMenuItem<String>>(
                                (String value) => DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(value),
                                    ))
                            .toList(),
                      ),
                    ),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 16.0, horizontal: 8.0),
                    child: ElevatedButton(
                      style: getButtonStyle(context),
                      onPressed: () async {
                        setState(() {
                          _loading = true;
                        });
                        context
                            .read<GlobalData>()
                            .setOperatorId(_usernameController.text);
                        saveDataToFile<String>(
                            'operatorId', _usernameController.text);
                        if (_formKey.currentState!.validate()) {
                          try {
                            await context.read<CredentialManager>().doRegister(
                                _usernameController.text,
                                _passwordController.text);
                            Navigator.of(context).push(MaterialPageRoute(
                                builder: (context) => const HomePage()));
                          } catch (error) {
                            showSnackBar(context, "Username already exists");
                          }
                        }
                        setState(() {
                          _loading = false;
                        });
                      },
                      child: const Text('Register'),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 16.0, horizontal: 8.0),
                    child: ElevatedButton(
                      style: getButtonStyle(context),
                      onPressed: () async {
                        setState(() {
                          _loading = true;
                        });
                        context
                            .read<GlobalData>()
                            .setOperatorId(_usernameController.text);
                        saveDataToFile<String>(
                            'operatorId', _usernameController.text);
                        if (_formKey.currentState!.validate()) {
                          try {
                            await context.read<CredentialManager>().doLogin(
                                _usernameController.text,
                                _passwordController.text);
                            Navigator.of(context).push(MaterialPageRoute(
                                builder: ((context) => const HomePage())));
                          } catch (error) {
                            showSnackBar(
                                context, "Improper usename or password");
                          }
                        }
                        setState(() {
                          _loading = false;
                        });
                      },
                      child: const Text('Login'),
                    ),
                  ),
                  _loading
                      ? Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                  child: const CircularProgressIndicator
                                      .adaptive()),
                            ],
                          ),
                        )
                      : Container()
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
