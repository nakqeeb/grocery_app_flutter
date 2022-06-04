import 'package:flutter/material.dart';
import 'package:grocery_app/models/product_model.dart';
import 'package:grocery_app/providers/products_provider.dart';
import 'package:provider/provider.dart';
import '../services/utils.dart';
import '../widgets/back_widget.dart';
import '../widgets/empty_products_widget.dart';
import '../widgets/feed_item_widget.dart';
import '../widgets/text_widget.dart';

class CatScreen extends StatefulWidget {
  static const routeName = '/CatScreen';

  const CatScreen({super.key});

  @override
  State<CatScreen> createState() => _CatScreenState();
}

class _CatScreenState extends State<CatScreen> {
  final TextEditingController? _searchTextController = TextEditingController();
  final FocusNode _searchTextFocusNode = FocusNode();
  List<ProductModel> _listProdcutSearch = [];
  @override
  void dispose() {
    _searchTextController!.dispose();
    _searchTextFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Size size = Utils(context).getScreenSize;
    Color color = Utils(context).color;
    final productsProvider = Provider.of<ProductsProvider>(context);
    final catName = ModalRoute.of(context)!.settings.arguments as String;
    List<ProductModel> productsByCat = productsProvider.findByCategory(catName);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        iconTheme: Theme.of(context).iconTheme,
        elevation: 0,
        leading: const BackWidget(),
        title: TextWidget(
          text: catName,
          color: color,
          textSize: 20,
          isTitle: true,
        ),
        centerTitle: true,
      ),
      body: productsByCat.isEmpty
          ? EmptyProductsWidget(text: 'No products belong to $catName')
          : SingleChildScrollView(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: SizedBox(
                      height: kBottomNavigationBarHeight,
                      child: TextField(
                        controller: _searchTextController,
                        onChanged: (value) {
                          setState(() {
                            // L105
                            _listProdcutSearch =
                                productsProvider.searchQuery(value);
                          });
                        },
                        focusNode: _searchTextFocusNode,
                        decoration: InputDecoration(
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: Colors.greenAccent, width: 1),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: Colors.greenAccent, width: 1),
                          ),
                          hintText: "What's in your mind?",
                          prefixIcon: const Icon(
                            Icons.search,
                          ),
                          suffixIcon: !_searchTextFocusNode.hasFocus
                              ? null
                              : IconButton(
                                  onPressed: () {
                                    _searchTextController!.clear();
                                    _searchTextFocusNode.unfocus();
                                  },
                                  //borderRadius: BorderRadius.circular(12),
                                  icon: const Icon(
                                    Icons.close,
                                    color: Colors.red,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                  _searchTextController!.text.isNotEmpty &&
                          _listProdcutSearch.isEmpty
                      ? EmptyProductsWidget(
                          text: 'No products found, please try another keyword')
                      : GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          //padding: EdgeInsets.zero,
                          //crossAxisSpacing: 10,
                          childAspectRatio: size.width / (size.height * 0.57),
                          children: List.generate(
                            _searchTextController!.text.isNotEmpty
                                ? _listProdcutSearch.length
                                : productsByCat.length,
                            (index) {
                              return ChangeNotifierProvider.value(
                                value: _searchTextController!.text.isNotEmpty
                                    ? _listProdcutSearch[index]
                                    : productsByCat[index],
                                child: const FeedItemWidget(),
                              );
                            },
                          ),
                        )
                ],
              ),
            ),
    );
  }
}
