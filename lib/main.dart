import 'dart:convert';
import 'dart:developer';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:grocery_app/consts/theme_data.dart';
import 'package:grocery_app/fetch_screen.dart';
import 'package:grocery_app/inner_screens/cat_screen.dart';
import 'package:grocery_app/inner_screens/product_details_screen.dart';
import 'package:grocery_app/providers/cart_provider.dart';
import 'package:grocery_app/providers/orders_provider.dart';
import 'package:grocery_app/providers/products_provider.dart';
import 'package:grocery_app/providers/viewed_prod_provider.dart';
import 'package:grocery_app/providers/wishlist_provider.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import 'providers/dark_theme_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Stripe.publishableKey =
      "pk_test_51L6usrSEHmVHeFFuUCu4WIqmWphuvwiu9kP0i8kEe5lddiC1dG7pwz29fCLtbKf3fcMbEqFnQdJUcXBreCSwoaQ700SlV1rGFy";
  await Stripe.instance.applySettings();
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  DarkThemeProvider themeChangeProvider = DarkThemeProvider();

  void getCurrentAppTheme() async {
    themeChangeProvider.setDarkTheme =
        await themeChangeProvider.darkThemePrefs.getTheme();
  }

  @override
  void initState() {
    getCurrentAppTheme();
    super.initState();
  }

  final Future<FirebaseApp> _firebaseInitialization = Firebase.initializeApp();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: _firebaseInitialization,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const MaterialApp(
              debugShowCheckedModeBanner: false,
              home: Scaffold(
                  body: Center(
                child: CircularProgressIndicator(),
              )),
            );
          } else if (snapshot.hasError) {
            const MaterialApp(
              debugShowCheckedModeBanner: false,
              home: Scaffold(
                  body: Center(
                child: Text('An error occured'),
              )),
            );
          }
          return MultiProvider(
            providers: [
              ChangeNotifierProvider(
                create: (_) {
                  return themeChangeProvider;
                },
              ),
              ChangeNotifierProvider(create: (_) => ProductsProvider()),
              ChangeNotifierProvider(create: (_) => CartProvider()),
              ChangeNotifierProvider(create: (_) => WishlistProvider()),
              ChangeNotifierProvider(create: (_) => ViewedProdProvider()),
              ChangeNotifierProvider(create: (_) => OrdersProvider()),
            ],
            child: Consumer<DarkThemeProvider>(
                builder: (context, themeProvider, child) {
              return MaterialApp(
                debugShowCheckedModeBanner: false,
                title: 'Flutter Demo',
                theme: Styles.themeData(themeProvider.getDarkTheme, context),
                //home: BottomBarScreen(),
                home: const FetchScreen(),
                routes: {
                  // OnSaleScreen.routeName: (context) => const OnSaleScreen(),
                  ProductDetailsScreen.routeName: (context) =>
                      const ProductDetailsScreen(),
                  CatScreen.routeName: (context) => const CatScreen(),
                },
              );
            }),
          );
        });
  }
}

/* class PaymentDemo extends StatelessWidget {
  const PaymentDemo({Key? key}) : super(key: key);
  Future<void> initPayment(
      {required String email,
      required double amount,
      required BuildContext context}) async {
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
      // 2. Initialize the payment sheet
      await Stripe.instance.initPaymentSheet(
          paymentSheetParameters: SetupPaymentSheetParameters(
        paymentIntentClientSecret: jsonResponse['paymentIntent'],
        merchantDisplayName: 'Grocery Flutter course',
        customerId: jsonResponse['customer'],
        customerEphemeralKeySecret: jsonResponse['ephemeralKey'],
        testEnv: true,
        merchantCountryCode: 'SG',
      ));
      await Stripe.instance.presentPaymentSheet();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment is successful'),
        ),
      );
    } catch (errorr) {
      if (errorr is StripeException) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An error occured ${errorr.error.localizedMessage}'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An error occured $errorr'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
          child: ElevatedButton(
        child: const Text('Pay 20\$'),
        onPressed: () async {
          await initPayment(
              amount: 50.0, context: context, email: 'email@test.com');
        },
      )),
    );
  } 
}*/

/* class PaymentDemo extends StatelessWidget {
  PaymentDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
          child: ElevatedButton(
        child: const Text('Pay 20\$'),
        onPressed: () async {
          await makePayment();
        },
      )),
    );
  }

  Map<String, dynamic>? paymentIntentData;
  Future<void> makePayment() async {
    // createPaymentIntent
    // initPaymentSheet
    // displayPaymentSheet
    try {
      paymentIntentData = await createPaymentIntent();
      await Stripe.instance.initPaymentSheet(
          paymentSheetParameters: SetupPaymentSheetParameters(
        paymentIntentClientSecret: paymentIntentData!['client_secret'],
        applePay: true,
        googlePay: true,
        testEnv: true,
        merchantDisplayName: 'Anyname',
        merchantCountryCode: 'us',
      ));

      await displayPaymentSheet();
    } catch (err) {
      print(err);
    }
  }

  createPaymentIntent() async {
    try {
      Map<String, dynamic> body = {
        'amount': '1200',
        'currency': 'USD',
        'payment_method_types[]': 'card'
      };

      final response = await http.post(
          Uri.parse('https://api.stripe.com/v1/payment_intents'),
          body: body,
          headers: {
            'Authorization':
                'Bearer sk_test_51L6usrSEHmVHeFFuNExHXnnRbCue1eSwLnL6ZCgRE0i6yKN5fpeeW7d6ttQcZpezaDqqTyNGy7vmeZUIH4azX0Ro00zSUIgesB', // stripe secret key
            'content-type': 'application/x-www-form-urlencoded',
          });
      print('This is me ${response.body}');
      return jsonDecode(response.body);
    } catch (err) {
      print(err);
    }
  }

  displayPaymentSheet() async {
    try {
      await Stripe.instance.presentPaymentSheet(
        parameters: PresentPaymentSheetParameters(
            clientSecret: paymentIntentData!['client_secret'],
            confirmPayment: true),
      );
    } catch (err) {
      print(err);
    }
  }
}
 */



/* class PaymentDemo extends StatelessWidget {
  PaymentDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
          child: ElevatedButton(
        child: const Text('Pay 20\$'),
        onPressed: () async {
          await makePayment(amount: '1200', currency: 'USD');
        },
      )),
    );
  }

  Map<String, dynamic>? paymentIntentData;

  Future<void> makePayment(
      {required String amount, required String currency}) async {
    try {
      paymentIntentData = await createPaymentIntent(amount, currency);
      if (paymentIntentData != null) {
        await Stripe.instance.initPaymentSheet(
            paymentSheetParameters: SetupPaymentSheetParameters(
          applePay: true,
          googlePay: true,
          testEnv: true,
          merchantCountryCode: 'US',
          merchantDisplayName: 'Prospects',
          customerId: paymentIntentData!['customer'],
          paymentIntentClientSecret: paymentIntentData!['client_secret'],
          customerEphemeralKeySecret: paymentIntentData!['ephemeralKey'],
        ));
        displayPaymentSheet();
      }
    } catch (e, s) {
      print('exception:$e$s');
    }
  }

  displayPaymentSheet() async {
    try {
      await Stripe.instance.presentPaymentSheet();
      print('Payment Successful');
    } on Exception catch (e) {
      if (e is StripeException) {
        print("Error from Stripe: ${e.error.localizedMessage}");
      } else {
        print("Unforeseen error: ${e}");
      }
    } catch (e) {
      print("exception:$e");
    }
  }

  //  Future<Map<String, dynamic>>
  createPaymentIntent(String amount, String currency) async {
    try {
      Map<String, dynamic> body = {
        'amount': calculateAmount(amount),
        'currency': currency,
        'payment_method_types[]': 'card'
      };
      var response = await http.post(
          Uri.parse('https://api.stripe.com/v1/payment_intents'),
          body: body,
          headers: {
            'Authorization':
                'Bearer sk_test_51L6usrSEHmVHeFFuNExHXnnRbCue1eSwLnL6ZCgRE0i6yKN5fpeeW7d6ttQcZpezaDqqTyNGy7vmeZUIH4azX0Ro00zSUIgesB',
            'Content-Type': 'application/x-www-form-urlencoded'
          });
      return jsonDecode(response.body);
    } catch (err) {
      print('err charging user: ${err.toString()}');
    }
  }

  calculateAmount(String amount) {
    final a = (int.parse(amount)) * 100;
    return a.toString();
  }
} */
