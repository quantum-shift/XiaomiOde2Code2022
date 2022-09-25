import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:xiaomi_billing/states/cart_model.dart';
import 'package:xiaomi_billing/states/credential_manager.dart';

/// Cart Icon showing number of items in the cart
class Cart extends StatelessWidget {
  const Cart({super.key});

  @override
  Widget build(BuildContext context) {
    if (context.watch<CredentialManager>().getToken() == '') {
      return const SizedBox.shrink();
    } else {
      return Stack(children: [
        const CircleAvatar(
          radius: 35,
          backgroundColor: Color(0xffff6801),
          child: Icon(
            color: Colors.white,
            IconData(0xe59c, fontFamily: 'MaterialIcons'),
            size: 50,
          ),
        ),
        Positioned(
            left: 30,
            top: 17,
            child: Material(
              color: Colors.white.withOpacity(0),
              child: Text(
                '${context.watch<CartModel>().getCartItemCount()}',
                style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xffff6801),
                    fontWeight: FontWeight.bold),
              ),
            ))
      ]);
    }
  }
}
