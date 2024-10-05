import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import './bill_screen.dart';
// import 'stock_checker.dart'; // Commented out since stock management is not being used yet

class CartScreen extends StatefulWidget {
  final Map<String, int> cart;
  final List<dynamic> menuItems;
  final Function(String, int) onUpdateCart;

  const CartScreen({
    Key? key,
    required this.cart,
    required this.menuItems,
    required this.onUpdateCart,
  }) : super(key: key);

  @override
  _CartScreenState createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  late Map<String, int> cart;
  bool _isCheckingOut = false;

  @override
  void initState() {
    super.initState();
    cart = Map<String, int>.from(widget.cart);
  }

  double calculateTotalAmount() {
    double totalAmount = 0.0;
    cart.forEach((itemId, quantity) {
      var item = widget.menuItems.firstWhere(
        (item) => item['id'] == itemId,
        orElse: () => null,
      );
      if (item != null) {
        double price = (item['price'] as num).toDouble();
        totalAmount += price * quantity;
      }
    });
    return totalAmount;
  }

  void _removeItem(String key) {
    setState(() {
      cart.remove(key);
    });
    widget.onUpdateCart(key, -widget.cart[key]!);
  }

  void _reduceItemQuantity(String key) {
    setState(() {
      if (cart[key]! > 1) {
        cart[key] = cart[key]! - 1;
        widget.onUpdateCart(key, -1);
      } else {
        _removeItem(key);
      }
    });
  }

  void _increaseItemQuantity(String key) {
    setState(() {
      cart[key] = (cart[key] ?? 0) + 1;
    });
    widget.onUpdateCart(key, 1);
  }

  Future<String> generateOrderId() async {
    final today = DateTime.now().toLocal().toString().split(' ')[0];
    DocumentReference orderIdRef =
        FirebaseFirestore.instance.collection('orderIds').doc(today);

    return FirebaseFirestore.instance
        .runTransaction<String>((transaction) async {
      DocumentSnapshot snapshot = await transaction.get(orderIdRef);
      if (!snapshot.exists) {
        transaction.set(orderIdRef, {'lastOrderId': 1});
        return '1';
      } else {
        int lastOrderId =
            (snapshot.data() as Map<String, dynamic>)['lastOrderId'] as int;
        int newOrderId = lastOrderId + 1;
        transaction.update(orderIdRef, {'lastOrderId': newOrderId});
        return newOrderId.toString();
      }
    });
  }

  Future _checkout() async {
    setState(() {
      _isCheckingOut = true;
    });

    try {
      String orderId = await generateOrderId();

      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      Map<String, int> typedCart = Map<String, int>.from(cart);

      double totalAmount = calculateTotalAmount();

      Map<String, dynamic> orderDetails = {
        'orderId': orderId,
        'cart': typedCart, // Pass the cart correctly
        'totalAmount': totalAmount, // Calculate total amount
        'isOrderPending': true,
        'createdAt': FieldValue.serverTimestamp(),
        'userId': user.uid,
      };

      await FirebaseFirestore.instance.collection('orders').add(orderDetails);

      // Pass the typed cart to BillScreen
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => BillScreen(
            orderId: orderId,
            totalAmount: totalAmount,
            cart: typedCart, // Pass the correct cart
            menuItems: widget.menuItems,
            generationTime: DateTime.now(), // Pass the current time or the time from your order data
          ),
        ),
      );

      setState(() {
        cart.clear(); // Clear cart after checkout
      });
    } catch (e) {
      print('Error during checkout: $e');
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Checkout Error'),
          content: const Text(
              'An error occurred during checkout. Please try again later.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } finally {
      setState(() {
        _isCheckingOut = false;
      });
    }
  }

  Future<void> completeOrder(String orderId) async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('orderId', isEqualTo: orderId)
          .get();

      for (var doc in snapshot.docs) {
        await doc.reference.update({'isOrderPending': false});
      }
    } catch (e) {
      print('Error updating order status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    double totalAmount = calculateTotalAmount();

    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pop(cart);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Your Cart'),
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.of(context).pop(cart);
            },
          ),
        ),
        body: cart.isEmpty
            ? Center(
                child: Text(
                  'Your cart is empty',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              )
            : ListView(
                padding: const EdgeInsets.all(8.0),
                children: cart.keys.map((key) {
                  var item = widget.menuItems.firstWhere(
                      (item) => item['id'] == key,
                      orElse: () => null);
                  if (item == null) {
                    return const ListTile(
                      title: Text('Unknown item'),
                      subtitle: Text('No price available'),
                      trailing: Text('0'),
                    );
                  } else {
                    double price = (item['price'] as num).toDouble();
                    double itemTotalPrice = price * cart[key]!;
                    return Card(
                      elevation: 4,
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['name'],
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '₹${price.toStringAsFixed(2)} x ${cart[key]}',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Total: ₹${itemTotalPrice.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline),
                                  onPressed: () => _reduceItemQuantity(key),
                                ),
                                Text(
                                  '${cart[key]}',
                                  style: const TextStyle(fontSize: 18),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline),
                                  onPressed: () => _increaseItemQuantity(key),
                                ),
                              ],
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => _removeItem(key),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                }).toList(),
              ),
        bottomNavigationBar: BottomAppBar(
          child: Container(
            padding: const EdgeInsets.all(16.0),
            height: 60,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total: ₹${totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton(
                  onPressed: _isCheckingOut ? null : _checkout,
                  child: _isCheckingOut
                      ? const CircularProgressIndicator()
                      : const Text('Checkout'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
