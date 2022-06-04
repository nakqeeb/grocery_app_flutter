import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:grocery_app/screens/auth/forget_pass.dart';
import 'package:grocery_app/screens/auth/login.dart';
import 'package:grocery_app/screens/orders/orders_screen.dart';
import 'package:grocery_app/screens/viewed_recently/viewed_recently_screen.dart';
import 'package:grocery_app/screens/wishlist/wishlist_screen.dart';
import 'package:grocery_app/services/global_methods.dart';
import 'package:grocery_app/widgets/loading_manager.dart';
import 'package:grocery_app/widgets/text_widget.dart';
import 'package:provider/provider.dart';

import '../consts/firebase_consts.dart';
import '../providers/dark_theme_provider.dart';
import '../providers/orders_provider.dart';

class UserScreen extends StatefulWidget {
  const UserScreen({Key? key}) : super(key: key);

  @override
  State<UserScreen> createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  final TextEditingController _addressTextController = TextEditingController();
  final User? user = authInstance.currentUser;

  String? _email;
  String? _name;
  String? address;
  bool _isLoading = false;

  @override
  void initState() {
    getUserData();
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    _addressTextController.dispose();
  }

  Future<void> getUserData() async {
    setState(() {
      _isLoading = true;
    });
    if (user == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }
    try {
      String _uid = user!.uid;

      final DocumentSnapshot userDoc =
          await FirebaseFirestore.instance.collection('users').doc(_uid).get();
      if (userDoc == null) /* L91 */ {
        return;
      } else {
        _email = userDoc.get('email');
        _name = userDoc.get('name');
        address = userDoc.get('shipping-address');
        _addressTextController.text = userDoc.get('shipping-address');
      }
    } catch (error) {
      setState(() {
        _isLoading = false;
      });
      GlobalMethods.errorDialog(subtitle: '$error', context: context);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeState = Provider.of<DarkThemeProvider>(context);
    final Color color = themeState.getDarkTheme ? Colors.white : Colors.black;
    final ordersProvider = Provider.of<OrdersProvider>(context);
    return SafeArea(
      child: Scaffold(
        body: LoadingManager(
          isLoading: _isLoading,
          child: SingleChildScrollView(
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(10),
                child: RichText(
                  text: TextSpan(
                    text: 'Hi,  ',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 27,
                      color: Colors.cyan,
                    ),
                    children: [
                      TextSpan(
                        text: _name ??
                            'User', // equivalent to (_name == null ? 'User': _name)
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w600,
                          fontSize: 25,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            print('My name is Khaled');
                          },
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(
                  left: 10,
                  bottom: 15,
                ),
                child: TextWidget(
                    text: _email ?? 'Email', color: color, textSize: 18),
              ),
              const Divider(
                thickness: 2,
              ),
              _listTile(
                icon: IconlyLight.location,
                title: 'Address',
                subtitle: address,
                color: color,
                onPressed: () async {
                  await _showAddressDialog();
                },
              ),
              _listTile(
                icon: IconlyLight.wallet,
                title: 'Orders',
                color: color,
                onPressed: () {
                  GlobalMethods.navigateFromRight(
                    ctx: context,
                    screen: OrdersScreen(),
                  );
                },
              ),
              _listTile(
                  icon: IconlyLight.heart,
                  title: 'Wishlist',
                  color: color,
                  onPressed: () {
                    GlobalMethods.navigateFromRight(
                      ctx: context,
                      screen: WishlistScreen(),
                    );
                  }),
              _listTile(
                icon: IconlyLight.show,
                title: 'Viewed',
                color: color,
                onPressed: () {
                  GlobalMethods.navigateFromRight(
                    ctx: context,
                    screen: ViewedRecentlyScreen(),
                  );
                },
              ),
              _listTile(
                icon: IconlyLight.unlock,
                title: 'Forget Password',
                color: color,
                onPressed: () {
                  GlobalMethods.navigateFromRight(
                    ctx: context,
                    screen: const ForgetPasswordScreen(),
                  );
                },
              ),
              SwitchListTile(
                title: TextWidget(
                  text: themeState.getDarkTheme ? 'Dark mode' : 'Light mode',
                  color: color,
                  textSize: 18,
                ),
                secondary: Icon(themeState.getDarkTheme
                    ? Icons.dark_mode_outlined
                    : Icons.light_mode_outlined),
                onChanged: (bool value) {
                  setState(() {
                    themeState.setDarkTheme = value;
                  });
                },
                value: themeState.getDarkTheme,
              ),
              _listTile(
                icon: user == null ? IconlyLight.login : IconlyLight.logout,
                title: user == null ? 'Login' : 'Logout',
                color: color,
                onPressed: () {
                  if (user == null) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (ctx) => const LoginScreen(),
                      ),
                    );
                    return;
                  }
                  GlobalMethods.warningDialog(
                    title: 'Sign out',
                    subtitle: 'Do you really want to sign out?',
                    fct: () async {
                      await authInstance.signOut();
                      // I added
                      ordersProvider.clearLocalOrders();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (ctx) => const LoginScreen(),
                        ),
                      );
                    },
                    context: context,
                  );
                },
              ),
            ],
          )),
        ),
      ),
    );
  }

  Future<void> _showAddressDialog() {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Update'),
          content: TextField(
            controller: _addressTextController,
            maxLines: 5,
            decoration: const InputDecoration(hintText: 'Your address'),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                String _uid = user!.uid;
                try {
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(_uid)
                      .update({
                    'shipping-address': _addressTextController.text,
                  });

                  Navigator.pop(context);
                  setState(() {
                    address = _addressTextController.text;
                  });
                } catch (err) {
                  GlobalMethods.errorDialog(
                      subtitle: err.toString(), context: context);
                }
              },
              child: const Text('Update'),
            )
          ],
        );
      },
    );
  }

  Widget _listTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 10),
      child: ListTile(
        leading: Icon(
          icon,
        ),
        title: TextWidget(text: title, color: color, textSize: 18),
        subtitle: subtitle == null
            ? null
            : TextWidget(text: subtitle, color: color, textSize: 12),
        trailing: const Icon(
          IconlyLight.arrowRight2,
        ),
        onTap: onPressed,
      ),
    );
  }
}
