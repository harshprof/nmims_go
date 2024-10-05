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
  Map<String, int> cart = {}; // Updated cart

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

  void addToCart(String itemId) {
    setState(() {
      cart[itemId] = (cart[itemId] ?? 0) + 1;
    });

    // Show custom toast message
    CustomToast.show(
      context,
      "Item added to cart",
      icon: Icons.favorite,
    );
  }

  void removeFromCart(String itemId) {
    setState(() {
      if (cart[itemId] != null && cart[itemId]! > 0) {
        cart[itemId] = cart[itemId]! - 1;
        if (cart[itemId] == 0) {
          cart.remove(itemId);
        }
      }
    });
  }

  String generateUniqueId(Map<String, dynamic> item) {
    return '${item['category']}${item['name']}${DateTime.now().millisecondsSinceEpoch}';
  }

  @override
  Widget build(BuildContext context) {
    print("Building MyHomePage");

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
                      print("Building CategoryIcon for ${categories[index]}");
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
                      print("Building MenuItem for ${item['name']}");
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
                // Await the result from CartScreen and update the cart
                final updatedCart = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CartScreen(cart: cart, menuItems: menuItems),
                  ),
                );

                // Check if the cart was updated and is not null
                if (updatedCart != null) {
                  setState(() {
                    cart = Map<String, int>.from(updatedCart);
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
