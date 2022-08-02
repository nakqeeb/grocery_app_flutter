import 'dart:convert';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:grocery_app/screens/cart/cart_widget.dart';
import 'package:grocery_app/widgets/empty_screen.dart';
import 'package:grocery_app/widgets/loading_manager.dart';
import 'package:grocery_app/widgets/text_widget.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;

import '../../consts/firebase_consts.dart';
import '../../providers/cart_provider.dart';
import '../../providers/orders_provider.dart';
import '../../providers/products_provider.dart';
import '../../services/global_methods.dart';
import '../../services/utils.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({Key? key}) : super(key: key);

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final Color color = Utils(context).color;
    Size size = Utils(context).getScreenSize;
    final cartProvider = Provider.of<CartProvider>(context);
    final cartItemsList = cartProvider.getCartItems.values
        .toList()
        .reversed
        .toList(); // .reversed L70
    //final productsProvider = Provider.of<ProductsProvider>(context);
    return cartItemsList.isEmpty
        ? const EmptyScreen(
            imagePath: 'assets/images/cart.png',
            title: 'Your cart is empty!',
            subtitle: 'Add somthing and make me happy :)',
            buttonText: 'Shop now',
            isCartScreen: true,
          )
        : LoadingManager(
            isLoading: _isLoading,
            child: Scaffold(
              appBar: AppBar(
                  elevation: 0,
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  title: TextWidget(
                    text: 'Cart (${cartItemsList.length})',
                    color: color,
                    isTitle: true,
                    textSize: 22,
                  ),
                  actions: [
                    IconButton(
                      onPressed: () {
                        GlobalMethods.warningDialog(
                          title: 'Empty your cart',
                          subtitle: 'Are you sure?',
                          fct: () async {
                            await cartProvider.clearOnlineCart();
                            cartProvider.clearLocalCart();
                          },
                          context: context,
                        );
                      },
                      icon: Icon(
                        IconlyBroken.delete,
                        color: color,
                      ),
                    ),
                  ]),
              body: Column(
                children: [
                  _checkout(ctx: context),
                  Expanded(
                    child: ListView.builder(
                      itemCount: cartItemsList.length,
                      itemBuilder: (ctx, index) {
                        return ChangeNotifierProvider.value(
                          value: cartItemsList[index],
                          child: CartWidget(),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
  }

  Widget _checkout({required BuildContext ctx}) {
    final Color color = Utils(ctx).color;
    Size size = Utils(ctx).getScreenSize;
    final cartProvider = Provider.of<CartProvider>(ctx);
    final productProvider = Provider.of<ProductsProvider>(ctx);
    final ordersProvider = Provider.of<OrdersProvider>(ctx);
    double total = 0.0;
    cartProvider.getCartItems.forEach((key, value) {
      final getCurrProduct = productProvider.findProdById(value.productId);
      total += (getCurrProduct.isOnSale
              ? getCurrProduct.salePrice
              : getCurrProduct.price) *
          value.quantity;
    });
    return SizedBox(
      width: double.infinity,
      height: size.height * 0.1,
      // color: ,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(children: [
          Material(
            color: Colors.green,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () async {
                User? user = authInstance.currentUser;
                // it is wrong to declare orderId outside forEach block
                // final orderId = const Uuid().v4();
                final productProvider =
                    Provider.of<ProductsProvider>(ctx, listen: false);
                try {
                  await initPayment(
                      email: user!.email ?? '',
                      amount: total * 100,
                      context: ctx,
                      color: color);
                } catch (error) {
                  log('An error occured $error');
                  return; // return if the payment is failed so that the order is not saved
                }
                cartProvider.getCartItems.forEach((key, value) async {
                  // orderId sholud be declared inside forEach block (Not Outside)
                  final orderId = const Uuid().v4();
                  final getCurrProduct = productProvider.findProdById(
                    value.productId,
                  );
                  try {
                    setState(() {
                      _isLoading = true;
                    });

                    await FirebaseFirestore.instance
                        .collection('orders')
                        .doc(orderId)
                        .set({
                      'orderId': orderId,
                      'userId': user.uid,
                      'productId': value.productId,
                      'price': (getCurrProduct.isOnSale
                              ? getCurrProduct.salePrice
                              : getCurrProduct.price) *
                          value.quantity,
                      'totalPrice': total,
                      'quantity': value.quantity,
                      'imageUrl': getCurrProduct.imageUrl,
                      'userName': user
                          .displayName, // L122 in registerScreen, I added this user.updateDisplayName(_fullNameController.text)
                      'orderDate': Timestamp.now(),
                    });
                    await cartProvider.clearOnlineCart();
                    cartProvider.clearLocalCart();
                    ordersProvider.fetchOrders();
                    await Fluttertoast.showToast(
                      msg: "Your order has been placed",
                      toastLength: Toast.LENGTH_SHORT,
                      gravity: ToastGravity.BOTTOM,
                    );
                  } catch (error) {
                    GlobalMethods.errorDialog(
                        subtitle: error.toString(), context: ctx);
                  } finally {
                    setState(() {
                      _isLoading = false;
                    });
                  }
                });
              },
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextWidget(
                  text: 'Order Now',
                  textSize: 20,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const Spacer(),
          FittedBox(
            child: TextWidget(
              text: 'Total: \$${total.toStringAsFixed(2)}',
              color: color,
              textSize: 18,
              isTitle: true,
            ),
          ),
        ]),
      ),
    );
  }

  Future<void> initPayment(
      {required String email,
      required double amount,
      required BuildContext context,
      required Color color}) async {
    try {
      // 1. Create a payment intent on the server
      final response = await http.post(
          Uri.parse(
              'https://us-central1-grocery-flutter-app-5e3aa.cloudfunctions.net/stripePaymentIntentRequest'),
          body: {
            'email': email,
            'amount': amount.toString(),
          });

      final jsonResponse = jsonDecode(response.body);
      log(jsonResponse.toString());
      if (jsonResponse['success'] == false) {
        GlobalMethods.errorDialog(
            subtitle: jsonResponse['error'], context: context);
        throw jsonResponse['error'];
      }
      // 2. Initialize the payment sheet
      await Stripe.instance.initPaymentSheet(
          paymentSheetParameters: SetupPaymentSheetParameters(
        paymentIntentClientSecret: jsonResponse['paymentIntent'],
        merchantDisplayName: 'Grocery Flutter course',
        customerId: jsonResponse['customer'],
        customerEphemeralKeySecret: jsonResponse['ephemeralKey'],
        testEnv: true,
        merchantCountryCode: 'US',
      ));
      await Stripe.instance.presentPaymentSheet();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Payment is successful', style: TextStyle(color: color)),
        ),
      );
    } catch (errorr) {
      if (errorr is StripeException) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An error occured ${errorr.error.localizedMessage}',
                style: TextStyle(color: color)),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An error occured $errorr',
                style: TextStyle(color: color)),
          ),
        );
      }
      throw '$errorr';
    }
  }
}
