import 'package:flutter/material.dart';
import 'package:workspace/canteen/widgets/customToast.dart';
import '../widgets/category_icon.dart';
import '../widgets/menu_item.dart';
import '../services/database_service.dart';
import 'cart_screen.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String username = 'Guest';
  List<String> categories = ['Chaat', 'Drinks', 'Snacks', 'Desserts'];
  String selectedCategory = 'Chaat';
  List<dynamic> menuItems = [];
  List<dynamic> filteredMenuItems = [];
  Map<String, int> cart = {};

  @override
  void initState() {
    super.initState();
    fetchUsername();
    fetchMenu();
  }

  Future<void> fetchUsername() async {
    String fetchedUsername = await DatabaseService().getUsername() ?? 'Guest';
    setState(() {
      username = fetchedUsername;
    });
  }

  Future<void> fetchMenu() async {
    List<dynamic> fetchedMenuItems = await DatabaseService().getMenu();
    fetchedMenuItems = fetchedMenuItems.map((item) {
      if (!item.containsKey('id')) {
        item['id'] = generateUniqueId(item);
      }
      return item;
    }).toList();

    setState(() {
      menuItems = fetchedMenuItems;
      filterMenuItems();
    });
  }

  void filterMenuItems() {
    filteredMenuItems = menuItems
        .where((item) => item['category'] == selectedCategory)
        .toList();
  }

  void updateCart(String itemId, int change) {
    setState(() {
      if (cart.containsKey(itemId)) {
        cart[itemId] = (cart[itemId] ?? 0) + change;
        if (cart[itemId]! <= 0) {
          cart.remove(itemId);
        }
      } else if (change > 0) {
        cart[itemId] = change;
      }
    });
  }

  void addToCart(String itemId) {
    updateCart(itemId, 1);
    CustomToast.show(
      context,
      "Item added to cart",
      icon: Icons.favorite,
    );
  }

  void removeFromCart(String itemId) {
    updateCart(itemId, -1);
  }

  String generateUniqueId(Map<String, dynamic> item) {
    return '${item['category']}${item['name']}${DateTime.now().millisecondsSinceEpoch}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text('Heyy $username'),
            const SizedBox(width: 8.0),
            const CircleAvatar(
              backgroundImage: AssetImage('assets/logo.png'),
            ),
          ],
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('NMIMS',
                    style:
                        TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const Text('Canteen',
                    style: TextStyle(fontSize: 20, color: Colors.grey)),
                const SizedBox(height: 16),
                SizedBox(
                  height: 120,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      return CategoryIcon(
                        category: categories[index],
                        isSelected: selectedCategory == categories[index],
                        onTap: () {
                          setState(() {
                            selectedCategory = categories[index];
                            filterMenuItems();
                          });
                        },
                        imagePath:
                            'assets/icons/${categories[index].toLowerCase()}.png',
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: filteredMenuItems.isEmpty
                ? Center(
                    child: Text(
                        'Sorry, could not find any items for $selectedCategory'))
                : GridView.builder(
                    padding: const EdgeInsets.all(8),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.7,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: filteredMenuItems.length,
                    itemBuilder: (context, index) {
                      final item = filteredMenuItems[index];
                      final itemId = item['id'] ?? 'unknown_id';
                      return MenuItem(
                        menuItem: item,
                        onAdd: () => addToCart(itemId),
                        onRemove: () => removeFromCart(itemId),
                        quantity: cart[itemId] ?? 0,
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: cart.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () async {
                final updatedCart = await Navigator.push<Map<String, int>>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CartScreen(
                      cart: cart,
                      menuItems: menuItems,
                      onUpdateCart: updateCart,
                    ),
                  ),
                );
                if (updatedCart != null) {
                  setState(() {
                    cart = updatedCart;
                  });
                }
              },
              label: Text('View Cart (${cart.length})'),
              icon: const Icon(Icons.shopping_cart),
            )
          : null,
    );
  }
}