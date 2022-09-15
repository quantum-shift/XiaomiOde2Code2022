import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:xiaomi_billing/constants.dart';
import 'package:xiaomi_billing/screens/checkout_page/checkout_page.dart';

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
  }

  String? formFieldValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Fields cannot be empty';
    }
    return null;
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
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8.0)),
                  ),
                  suffixIcon: Icon(Icons.phone),
                  labelText: 'Phone Number'),
              validator: formFieldValidator,
              controller: _phoneController,
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
              validator: formFieldValidator,
              controller: _emailController,
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
                      setState(() {
                        communicationPreference = value!;
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
          Padding(
              padding: const EdgeInsets.fromLTRB(0, 20, 0, 0),
              child: Divider(thickness: 3)),
          Container(
              width: size.width * 0.9,
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: ElevatedButton(
                child: Text('Proceed'),
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
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => CheckoutPage()));
                  }
                },
              ))
        ]),
      ),
    );
  }
}
