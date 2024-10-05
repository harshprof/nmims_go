import 'package:flutter/material.dart';

class MenuItem extends StatelessWidget {
  final Map<String, dynamic> menuItem;
  final VoidCallback onAdd;
  final VoidCallback onRemove;
  final int quantity;

  const MenuItem({
    Key? key,
    required this.menuItem,
    required this.onAdd,
    required this.onRemove,
    required this.quantity,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    print("Building MenuItem for ${menuItem['name']} with quantity $quantity");
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image section
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            child: Image.asset(
              menuItem['image'] ?? 'assets/default_food_image.jpeg',
              height: 100,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          // Details section
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  menuItem['name'],
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '₹${menuItem['price']}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove, size: 20),
                      onPressed: quantity > 0 ? onRemove : null,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    Text(
                      quantity.toString(),
                      style: const TextStyle(fontSize: 14),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, size: 20),
                      onPressed: onAdd,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}