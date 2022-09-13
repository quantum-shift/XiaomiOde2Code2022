import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:provider/provider.dart';

import '../../../constants.dart';
import '../../../states/credential_manager.dart';

class OrdersPage extends StatelessWidget {
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order History'),
        backgroundColor: miOrange,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white, semanticLabel: 'Logout',),
            tooltip: 'Logout',
            onPressed: () {
              context.read<CredentialManager>().doLogout();
            },
          ),
        ],
      ),
      body: Center(
        child: Text('Orders go here'),
      ),
    );
  }
}