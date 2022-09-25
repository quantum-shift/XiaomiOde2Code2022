
import 'package:flutter/material.dart';

/// Widget displaying an empty cart symbol with required [message] in a [Card] widget
class EmptyCartCard extends StatelessWidget {
  const EmptyCartCard({
    super.key,
    required this.message,
    required this.size,
  });

  final String message;
  final Size size;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: SizedBox(
        height: 200,
        width: size.width * 0.8,
        child: Row(
          children: [
            SizedBox(
                width: size.width * 0.2,
                height: 200,
                child: const Center(
                    child: Icon(Icons.shopping_bag_outlined, size: 30))),
            SizedBox(
                width: size.width * 0.6,
                height: 200,
                child: Center(
                  child: Text(
                    message,
                    maxLines: 6,
                    style: const TextStyle(fontSize: 18),
                  ),
                ))
          ],
        ),
      ),
    );
  }
}
