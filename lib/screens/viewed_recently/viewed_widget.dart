import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fancy_shimmer_image/fancy_shimmer_image.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:grocery_app/inner_screens/product_details_screen.dart';
import 'package:grocery_app/providers/viewed_prod_provider.dart';
import 'package:grocery_app/services/global_methods.dart';
import 'package:provider/provider.dart';
import '../../consts/firebase_consts.dart';
import '../../models/product_model.dart';
import '../../models/viewed_model.dart';
import '../../providers/cart_provider.dart';
import '../../providers/products_provider.dart';
import '../../services/utils.dart';
import '../../widgets/text_widget.dart';

class ViewedRecentlyWidget extends StatefulWidget {
  const ViewedRecentlyWidget({Key? key}) : super(key: key);

  @override
  _ViewedRecentlyWidgetState createState() => _ViewedRecentlyWidgetState();
}

class _ViewedRecentlyWidgetState extends State<ViewedRecentlyWidget> {
  @override
  Widget build(BuildContext context) {
    Color color = Utils(context).color;
    Size size = Utils(context).getScreenSize;
    final viewedProdModel = Provider.of<ViewedProdModel>(context);
    final productsProvider = Provider.of<ProductsProvider>(context);
    ProductModel getCurrProduct =
        productsProvider.findProdById(viewedProdModel.productId);
    double usedPrice = getCurrProduct.isOnSale
        ? getCurrProduct.salePrice
        : getCurrProduct.price;
    final cartProvider = Provider.of<CartProvider>(context);
    bool isInCart = cartProvider.getCartItems.containsKey(getCurrProduct.id);
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            ProductDetailsScreen.routeName,
            arguments: viewedProdModel.productId,
          );
          /* GlobalMethods.navigateTo(
              ctx: context, screen: ProductDetailsScreen()); */
        },
        child: Container(
          color: Theme.of(context).cardColor.withOpacity(0.5),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FancyShimmerImage(
                imageUrl: getCurrProduct.imageUrl,
                boxFit: BoxFit.fill,
                height: size.width * 0.27,
                width: size.width * 0.25,
              ),
              const SizedBox(
                width: 12,
              ),
              Column(
                children: [
                  TextWidget(
                    text: getCurrProduct.title,
                    color: color,
                    textSize: 24,
                    isTitle: true,
                  ),
                  const SizedBox(
                    height: 12,
                  ),
                  TextWidget(
                    text: '\$${usedPrice.toStringAsFixed(2)}',
                    color: color,
                    textSize: 20,
                    isTitle: false,
                  ),
                ],
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: Material(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.green,
                  child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: isInCart
                          ? null
                          : () async {
                              final User? user = authInstance.currentUser;
                              if (user == null) {
                                GlobalMethods.errorDialog(
                                    subtitle: 'Please login first',
                                    context: context);
                                return;
                              }
                              /* cartProvider.addProductToCart(
                                  productId: getCurrProduct.id, quantity: 1); */
                              await GlobalMethods.addToCart(
                                  productId: getCurrProduct.id,
                                  quantity: 1,
                                  context: context);
                              await cartProvider.fetchCart();
                            },
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Icon(
                          isInCart ? Icons.check : CupertinoIcons.plus,
                          color: Colors.white,
                          size: 20,
                        ),
                      )),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
