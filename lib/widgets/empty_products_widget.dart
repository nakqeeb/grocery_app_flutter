import 'package:flutter/material.dart';

import '../services/utils.dart';

class EmptyProductsWidget extends StatelessWidget {
  EmptyProductsWidget({super.key, required this.text});
  String text;

  @override
  Widget build(BuildContext context) {
    Color color = Utils(context).color;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(
                top: 50,
                left: 18,
                right: 18,
                bottom: 18,
              ),
              child: Image.asset('assets/images/box.png'),
            ),
            Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontSize: 30,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
