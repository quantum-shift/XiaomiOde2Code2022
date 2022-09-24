import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:xiaomi_billing/constants.dart';
import 'package:xiaomi_billing/screens/checkout_page/checkout_page.dart';
import 'package:xiaomi_billing/states/credential_manager.dart';
import 'package:xiaomi_billing/states/global_data.dart';

/// Form widget in the Customer Information page to fill out the customer details
class CustomerInfoForm extends StatefulWidget {
  const CustomerInfoForm({super.key});

  @override
  State<CustomerInfoForm> createState() => _CustomerInfoFormState();
}

List<String> communicationOptions = ['Email', 'WhatsApp'];

class _CustomerInfoFormState extends State<CustomerInfoForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _nameController;
  String? communicationPreference = communicationOptions[1];

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
    _nameController = TextEditingController();
    _phoneController.text = "+91";
  }

  /// Default text field validation function
  String? formFieldValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Fields cannot be empty';
    }
    return null;
  }

  /// Calls */customer* at the backend to create a new customer / update existing customer
  Future<void> submitCustomerInfo() async {
    Dio dio = await context.read<CredentialManager>().getAPIClient();
    await dio.post('/customer', data: {
      "phone": _phoneController.text,
      "email": _emailController.text,
      "name": _nameController.text
    });
    return;
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Form(
      key: _formKey,
      child: Padding(
        padding:
            EdgeInsets.symmetric(vertical: 0, horizontal: size.width * 0.05),
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: TextFormField(
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                  signed: true, decimal: true),
              decoration: const InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8.0)),
                ),
                suffixIcon: Icon(Icons.phone),
                labelText: 'Phone Number',
              ),
              controller: _phoneController,
              validator: (String? value) {  // Phone number should start with +91 and contain 10 decimal digits
                if (value == null ||
                    value.length < 3 ||
                    value.substring(0, 3) != "+91") {
                  return "Must start with +91";
                } else {
                  if (value.length == 13) {
                    if (int.tryParse(value.substring(3, 13)) == null) {
                      return "Phone number should only contain digits";
                    } else {
                      return null;
                    }
                  } else {
                    return "Phone number must be of 10 digits";
                  }
                }
              },
              textInputAction: TextInputAction.next,
              onFieldSubmitted: (String? value) async { // This function is called to try to get existing customer information and autofill
                Dio dio =
                    await context.read<CredentialManager>().getAPIClient();
                try {
                  Response<String> response =
                      await dio.get("/customer/${_phoneController.text}");
                  final data = jsonDecode(response.data.toString());
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: const Text('AutoFill Information'),
                      duration: const Duration(milliseconds: 3000),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      action: SnackBarAction(
                        label: 'Yes',
                        onPressed: () {
                          _emailController.text = data['email'];
                          _nameController.text = data['name'];
                        },
                      )));
                } catch (error) {
                  ;
                }
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: TextFormField(
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8.0)),
                  ),
                  suffixIcon: Icon(Icons.email),
                  labelText: 'Email'),
              validator: (String? value) {  // Function checks if the email address is valid or not
                if (value == null || value.isEmpty) {
                  return "Fields cannot be empty";
                } else {
                  bool emailValid = RegExp(
                          r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
                      .hasMatch(value);
                  return emailValid ? null : "Please enter a proper email";
                }
              },
              controller: _emailController,
              textInputAction: TextInputAction.next,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: TextFormField(
              keyboardType: TextInputType.name,
              decoration: const InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8.0)),
                  ),
                  suffixIcon: Icon(Icons.person),
                  labelText: 'Name'),
              validator: formFieldValidator,
              controller: _nameController,
              textInputAction: TextInputAction.done,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
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
                    value: communicationPreference,
                    onChanged: (String? value) {
                      context
                          .read<GlobalData>()
                          .setPreferredCommunication(value!);
                      setState(() {
                        communicationPreference = value;
                      });
                    },
                    items: communicationOptions
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
          const Padding(
              padding: EdgeInsets.fromLTRB(0, 20, 0, 0),
              child: Divider(thickness: 3)),
          Container(
              width: size.width * 0.9,
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: ElevatedButton(
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.resolveWith<Color?>(
                    (Set<MaterialState> states) {
                      if (states.contains(MaterialState.pressed)) {
                        return Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.5);
                      }
                      return miOrange; // Use the component's default.
                    },
                  ),
                  foregroundColor: MaterialStateProperty.resolveWith<Color?>(
                      (states) => Colors.white),
                  shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                      RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(2.0),
                  )),
                ),
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    try {
                      await submitCustomerInfo();
                    } catch (error) {
                    } finally {
                      context
                          .read<GlobalData>()
                          .setCustomerName(_nameController.text);
                      context
                          .read<GlobalData>()
                          .setCustomerEmail(_emailController.text);
                      context
                          .read<GlobalData>()
                          .setCustomerPhone(_phoneController.text);
                      Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => const CheckoutPage()));
                    }
                  }
                },
                child: const Text('Proceed'),
              ))
        ]),
      ),
    );
  }
}
