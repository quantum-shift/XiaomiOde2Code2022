import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:xiaomi_billing/states/credential_manager.dart';

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
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _usernameController,
            decoration: const InputDecoration.collapsed(hintText: 'Username'),
            validator: formFieldValidator,
          ),
          TextFormField(
            controller: _passwordController,
            decoration: const InputDecoration.collapsed(hintText: 'Password'),
            validator: formFieldValidator,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Logging in!')));
                  context.read<CredentialManager>().doRegister(
                      _usernameController.text, _passwordController.text);
                }
              },
              child: const Text('Register'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Logging in!')));
                  context.read<CredentialManager>().doLogin(
                      _usernameController.text, _passwordController.text);
                }
              },
              child: const Text('Login'),
            ),
          ),
        ],
      ),
    );
  }
}
