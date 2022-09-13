import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:xiaomi_billing/constants.dart';
import 'package:xiaomi_billing/screens/home_page/components/cart_page.dart';
import 'package:xiaomi_billing/screens/home_page/components/orders_page.dart';
import 'package:xiaomi_billing/states/credential_manager.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin{
  late TabController controller = TabController(length: 2, vsync: this);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: Material(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.8),
        child: TabBar(
          indicatorColor: Colors.white,
          tabs: const <Tab>[
            Tab(
              icon: Icon(Icons.shopping_cart),
            ),
            Tab(
              icon: Icon(Icons.airplanemode_on),
            ),
          ],
          controller: controller,
        ),
      ),
      body: TabBarView(
        controller: controller,
        children: const <Widget>[CartPage(), OrdersPage()],
      ),
    );
  }
}