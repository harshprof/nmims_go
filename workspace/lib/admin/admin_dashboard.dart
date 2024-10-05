import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:workspace/auth/LoginPage.dart';

class AdminDashboard extends StatefulWidget {
  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  List<dynamic> menuItems = [];
  List<String> categories = []; // List to store categories

  @override
  void initState() {
    super.initState();
    fetchMenuItems();
    fetchCategories(); // Fetch categories at initialization
  }

  Future<void> fetchMenuItems() async {
    var menuCollection =
        await FirebaseFirestore.instance.collection('menu').get();
    setState(() {
      menuItems = menuCollection.docs.map((doc) {
        var data = doc.data();
        data['id'] = doc.id; // Add document ID for future updates/deletes
        return data;
      }).toList();
    });
  }

  Future<void> fetchCategories() async {
    var categoryCollection =
        await FirebaseFirestore.instance.collection('categories').get();
    setState(() {
      categories =
          categoryCollection.docs.map((doc) => doc['name'] as String).toList();
    });
    print("Fetched categories: $categories");
  }

  void addMenuItem(
      String name, double price, String category, int stock) async {
    await FirebaseFirestore.instance.collection('menu').add({
      'name': name,
      'price': price,
      'category': category,
      'stock': stock,
    });
    fetchMenuItems(); // Refresh the menu items after adding
  }

  void addCategory(String categoryName) async {
    await FirebaseFirestore.instance.collection('categories').add({
      'name': categoryName,
    });
    fetchCategories(); // Refresh the category list after adding
  }

  void updateMenuItem(String itemId, Map<String, dynamic> updatedData) async {
    await FirebaseFirestore.instance
        .collection('menu')
        .doc(itemId)
        .update(updatedData);
    fetchMenuItems(); // Refresh after update
  }

  void deleteMenuItem(String itemId) async {
    await FirebaseFirestore.instance.collection('menu').doc(itemId).delete();
    fetchMenuItems(); // Refresh after deletion
  }

  void logout() {
    // Implement logout functionality here
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (context) => LoginPage()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Admin Dashboard"),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: menuItems.length,
        itemBuilder: (context, index) {
          var item = menuItems[index];
          return ListTile(
            title: Text(item['name']),
            subtitle: Text(
                'Price: ₹${item['price']} | Stock: ${item['stock']} | Category: ${item['category']}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () {
                    showEditMenuDialog(item['id'], item);
                  },
                ),
                IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () {
                    deleteMenuItem(item['id']);
                  },
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            onPressed: () {
              showAddCategoryDialog();
            },
            child: Icon(Icons.category),
            tooltip: "Add Category",
          ),
          SizedBox(height: 10),
          FloatingActionButton(
            onPressed: () {
              showAddMenuDialog();
            },
            child: Icon(Icons.add),
            tooltip: "Add Menu Item",
          ),
        ],
      ),
    );
  }

  void showAddMenuDialog() {
    String name = '';
    double price = 0;
    String category =
        categories.isNotEmpty ? categories[0] : ''; // Default to first category
    int stock = 0;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Add Menu Item"),
          content: SingleChildScrollView(
            // Add this to make it scrollable
            child: Column(
              mainAxisSize: MainAxisSize.min, // Avoid overflow
              children: [
                TextField(
                  onChanged: (val) => name = val,
                  decoration: InputDecoration(labelText: "Name"),
                ),
                TextField(
                  onChanged: (val) => price = double.parse(val),
                  decoration: InputDecoration(labelText: "Price"),
                  keyboardType: TextInputType.number,
                ),
                DropdownButtonFormField<String>(
                  value: category,
                  onChanged: (val) => category = val ?? '',
                  items: categories.map((cat) {
                    return DropdownMenuItem(value: cat, child: Text(cat));
                  }).toList(),
                  decoration: InputDecoration(labelText: "Category"),
                ),
                TextField(
                  onChanged: (val) => stock = int.parse(val),
                  decoration: InputDecoration(labelText: "Stock"),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                addMenuItem(name, price, category, stock);
                Navigator.pop(context);
              },
              child: Text("Add"),
            ),
          ],
        );
      },
    );
  }

  void showEditMenuDialog(String itemId, Map<String, dynamic> itemData) {
    String name = itemData['name'];
    double price = itemData['price'];
    String category = itemData['category'];
    int stock = itemData['stock'];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Edit Menu Item"),
          content: SingleChildScrollView(
            // Add this to make it scrollable
            child: Column(
              mainAxisSize: MainAxisSize.min, // Avoid overflow
              children: [
                TextFormField(
                  initialValue: name,
                  onChanged: (val) => name = val,
                  decoration: InputDecoration(labelText: "Name"),
                ),
                TextFormField(
                  initialValue: price.toString(),
                  onChanged: (val) => price = double.parse(val),
                  decoration: InputDecoration(labelText: "Price"),
                  keyboardType: TextInputType.number,
                ),
                GestureDetector(
                  onTap: () {
                    print("DropdownButton tapped");
                  },
                  child: DropdownButtonFormField<String>(
                    value: category,
                    onChanged: (val) => category = val ?? '',
                    items: categories.map((cat) {
                      return DropdownMenuItem(value: cat, child: Text(cat));
                    }).toList(),
                    decoration: InputDecoration(labelText: "Category"),
                  ),
                ),
                TextFormField(
                  initialValue: stock.toString(),
                  onChanged: (val) => stock = int.parse(val),
                  decoration: InputDecoration(labelText: "Stock"),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                updateMenuItem(itemId, {
                  'name': name,
                  'price': price,
                  'category': category,
                  'stock': stock,
                });
                Navigator.pop(context);
              },
              child: Text("Update"),
            ),
          ],
        );
      },
    );
  }

  void showAddCategoryDialog() {
    String newCategory = '';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Add Category"),
          content: TextField(
            onChanged: (val) => newCategory = val,
            decoration: InputDecoration(labelText: "Category Name"),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                addCategory(newCategory);
                Navigator.pop(context);
              },
              child: Text("Add"),
            ),
          ],
        );
      },
    );
  }
}
