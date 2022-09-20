import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:xiaomi_billing/constants.dart';
import 'package:xiaomi_billing/states/credential_manager.dart';

import '../../states/global_data.dart';

class LoginPage extends StatelessWidget {
  LoginPage({super.key});

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String? formFieldValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Fields cannot be empty';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Xiaomi Billing"),
        backgroundColor: miOrange,
        foregroundColor: Colors.white,
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
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 16.0, horizontal: 8.0),
                  child: ElevatedButton(
                    style: getButtonStyle(context),
                    onPressed: () {
                      context
                          .read<GlobalData>()
                          .setOperatorId(_usernameController.text);
                      saveDataToFile<String>(
                          'operatorId', _usernameController.text);
                      if (_formKey.currentState!.validate()) {
                        try {
                          context.read<CredentialManager>().doRegister(
                              _usernameController.text,
                              _passwordController.text);
                        } catch (error) {
                          showSnackBar(context, "Username already exists");
                        }
                      }
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
                        } catch (error) {
                          showSnackBar(context, "Improper usename or password");
                        }
                      }
                    },
                    child: const Text('Login'),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
