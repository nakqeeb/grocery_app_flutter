import 'package:card_swiper/card_swiper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:grocery_app/consts/consts.dart';
import 'package:grocery_app/inner_screens/feed_screen.dart';
import 'package:grocery_app/inner_screens/on_sale_screen.dart';
import 'package:grocery_app/services/global_methods.dart';
import 'package:grocery_app/services/utils.dart';
import 'package:grocery_app/widgets/feed_item_widget.dart';
import 'package:grocery_app/widgets/on_sale_widget.dart';
import 'package:grocery_app/widgets/text_widget.dart';
import 'package:provider/provider.dart';

import '../models/product_model.dart';
import '../providers/products_provider.dart';
import '../providers/viewed_prod_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<String> _offerImages = [
    'assets/images/offers/Offer1.jpg',
    'assets/images/offers/Offer2.jpg',
    'assets/images/offers/Offer3.jpg',
    'assets/images/offers/Offer4.jpg'
  ];

  @override
  Widget build(BuildContext context) {
    final themeState = Utils(context).getTheme;
    Size size = Utils(context).getScreenSize;
    var color = Utils(context).color;
    final productsProvider = Provider.of<ProductsProvider>(context);
    List<ProductModel> allProducts = productsProvider.getProducts;
    List<ProductModel> productsOnSale = productsProvider.getOnSaleProducts;

    return SafeArea(
      child: Scaffold(
        body: SingleChildScrollView(
          child: Column(
            children: [
              // swipe offers
              SizedBox(
                height: size.height * 0.33,
                child: Swiper(
                  itemBuilder: (BuildContext context, int index) {
                    return Image.asset(
                      _offerImages[index],
                      fit: BoxFit.fill,
                    );
                  },
                  itemCount: _offerImages.length,
                  autoplay: true,
                  pagination: const SwiperPagination(
                      alignment: Alignment.bottomCenter,
                      builder: DotSwiperPaginationBuilder(
                          color: Colors.white, activeColor: Colors.red)),
                  /* viewportFraction: 0.8,
                  scale: 0.9, */
                  // control: const SwiperControl(color: Colors.black),
                ),
              ),
              const SizedBox(
                height: 6,
              ),

              // on sales
              productsOnSale.isNotEmpty
                  ? TextButton(
                      onPressed: () {
                        GlobalMethods.navigateFromBottom(
                            ctx: context, screen: OnSaleScreen());
                      },
                      child: TextWidget(
                        text: 'View all',
                        maxLines: 1,
                        color: Colors.blue,
                        textSize: 20,
                      ),
                    )
                  : Container(),

              productsOnSale.isNotEmpty
                  ? Row(
                      children: [
                        RotatedBox(
                          quarterTurns: -1,
                          child: Row(
                            children: [
                              TextWidget(
                                text: 'On sale'.toUpperCase(),
                                color: Colors.red,
                                textSize: 25,
                                isTitle: true,
                              ),
                              const SizedBox(
                                width: 5,
                              ),
                              const Icon(
                                IconlyLight.discount,
                                color: Colors.red,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(
                          width: 8,
                        ),
                        Flexible(
                          child: SizedBox(
                            height: size.height * 0.24,
                            child: ListView.builder(
                              itemCount: productsOnSale.length < 10
                                  ? productsOnSale.length
                                  : 10,
                              scrollDirection: Axis.horizontal,
                              itemBuilder: (ctx, index) {
                                return ChangeNotifierProvider.value(
                                    value: productsOnSale[index],
                                    child: const OnSaleWidget());
                              },
                            ),
                          ),
                        ),
                      ],
                    )
                  : Container(),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextWidget(
                      text: 'Our products',
                      color: color,
                      textSize: 22,
                      isTitle: true,
                    ),
                    // const Spacer(),
                    TextButton(
                      onPressed: () {
                        GlobalMethods.navigateFromBottom(
                            ctx: context, screen: FeedScreen());
                      },
                      child: TextWidget(
                        text: 'Browse all',
                        maxLines: 1,
                        color: Colors.blue,
                        textSize: 20,
                      ),
                    ),
                  ],
                ),
              ),

              // feed products
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                //padding: EdgeInsets.zero,
                //crossAxisSpacing: 10,
                childAspectRatio: size.width / (size.height * 0.57),
                children: List.generate(
                  allProducts.length < 4 ? allProducts.length : 4,
                  (index) {
                    return ChangeNotifierProvider.value(
                      value: allProducts[index],
                      child: const FeedItemWidget(),
                    );
                  },
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
