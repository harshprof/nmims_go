import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class CartScreen extends StatefulWidget {
  final Map<String, int> cart;
  final List<dynamic> menuItems;

  const CartScreen({Key? key, required this.cart, required this.menuItems})
      : super(key: key);

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
    return cart.entries.fold(0.0, (total, entry) {
      var item = widget.menuItems
          .firstWhere((item) => item['id'] == entry.key, orElse: () => null);
      return total +
          (item != null
              ? (item['price'] as num).toDouble() * entry.value
              : 0.0);
    });
  }

  Future<bool> checkStockAvailability() async {
    bool isStockSufficient = true;
    String insufficientItems = '';

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      for (String itemName in cart.keys) {
        try {
          // Query Firestore by 'name' field instead of document ID
          QuerySnapshot querySnapshot = await FirebaseFirestore.instance
              .collection('menu')
              .where('name', isEqualTo: itemName)
              .get();

          if (querySnapshot.docs.isNotEmpty) {
            DocumentSnapshot itemDoc = querySnapshot.docs.first;
            int stock = itemDoc['stock'] ?? 0;
            if (stock < cart[itemName]!) {
              insufficientItems += '${itemDoc['name']} (available: $stock), ';
              isStockSufficient = false;
            }
          } else {
            throw Exception('Menu item not found: $itemName');
          }
        } catch (e) {
          print('Error checking stock for item $itemName: $e');
          throw Exception('Menu item not found: $itemName');
        }
      }

      if (!isStockSufficient) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Insufficient Stock'),
            content: Text(
                'The following items have insufficient stock: $insufficientItems'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      print('Error checking stock availability: $e');
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: const Text(
              'An error occurred while checking stock availability. Please try again later.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return false;
    }

    return isStockSufficient;
  }

  Future<void> updateStockAfterPayment() async {
    WriteBatch batch = FirebaseFirestore.instance.batch();

    try {
      for (String itemId in cart.keys) {
        DocumentReference itemRef =
            FirebaseFirestore.instance.collection('menu').doc(itemId);
        DocumentSnapshot itemSnapshot = await itemRef.get();

        if (itemSnapshot.exists) {
          int currentStock = itemSnapshot['stock'];
          int newStock = currentStock - cart[itemId]!;

          if (newStock < 0) {
            throw Exception(
                'Insufficient stock for item: ${itemSnapshot['name']}');
          }

          batch.update(itemRef, {'stock': newStock});
        } else {
          throw Exception('Menu item not found: $itemId');
        }
      }

      await batch.commit();
    } catch (e) {
      print('Error updating stock: $e');
      throw Exception('Failed to update stock: $e');
    }
  }

  void _removeItem(String key) {
    setState(() {
      cart.remove(key);
    });
  }

  void _reduceItemQuantity(String key) {
    setState(() {
      if (cart[key]! > 1) {
        cart[key] = cart[key]! - 1;
      } else {
        _removeItem(key);
      }
    });
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

  Future<void> _checkout() async {
    setState(() {
      _isCheckingOut = true;
    });

    try {
      bool isStockAvailable = await checkStockAvailability();

      if (isStockAvailable) {
        await updateStockAfterPayment();

        String orderId = await generateOrderId();

        User? user = FirebaseAuth.instance.currentUser;
        if (user == null) throw Exception('User not authenticated');

        Map<String, dynamic> orderDetails = {
          'orderId': orderId,
          'cart': cart,
          'totalAmount': calculateTotalAmount(),
          'isOrderPending': true,
          'createdAt': FieldValue.serverTimestamp(),
          'userId': user.uid,
        };

        DocumentReference orderRef = await FirebaseFirestore.instance
            .collection('orders')
            .add(orderDetails);
        DocumentSnapshot orderSnapshot = await orderRef.get();
        Timestamp createdAtTimestamp = orderSnapshot['createdAt'] as Timestamp;

        String formattedTime = DateFormat('yyyy-MM-dd – kk:mm')
            .format(createdAtTimestamp.toDate());

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Payment Successful'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Thank you for your purchase!'),
                const SizedBox(height: 10),
                Text('Order ID: $orderId'),
                const SizedBox(height: 10),
                Text(
                    'Total Amount: ₹${calculateTotalAmount().toStringAsFixed(2)}'),
                const SizedBox(height: 10),
                Text('Bill Generated At: $formattedTime'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('OK'),
              ),
              TextButton(
                onPressed: () async {
                  await completeOrder(orderId);
                  Navigator.pop(context);
                },
                child: const Text('Mark as Completed'),
              ),
            ],
          ),
        );

        // Clear the cart after successful checkout
        setState(() {
          cart.clear();
        });
      }
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Cart'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(8.0),
        children: cart.keys.map((key) {
          var item = widget.menuItems
              .firstWhere((item) => item['id'] == key, orElse: () => null);
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
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _removeItem(key),
                        ),
                      ],
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
                onPressed: cart.isEmpty || _isCheckingOut ? null : _checkout,
                child: _isCheckingOut
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Checkout'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
