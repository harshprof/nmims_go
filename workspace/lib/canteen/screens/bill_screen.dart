import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:no_screenshot/no_screenshot.dart';
import 'package:intl/intl.dart';

class BillScreen extends StatefulWidget {
  final String orderId;
  final double totalAmount;
  final Map<String, int> cart;
  final List<dynamic> menuItems;
  final DateTime generationTime;

  const BillScreen({
    Key? key,
    required this.orderId,
    required this.totalAmount,
    required this.cart,
    required this.menuItems,
    required this.generationTime,
  }) : super(key: key);

  @override
  _BillScreenState createState() => _BillScreenState();
}

class _BillScreenState extends State<BillScreen> with WidgetsBindingObserver {
  late Timer _timer;
  int _secondsRemaining = 1 * 60; // 1 minute
  final _noScreenshot = NoScreenshot.instance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startTimer();
    _preventScreenshots();
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
        } else {
          _timer.cancel();
          Navigator.of(context).pop();
        }
      });
    });
  }

  void _preventScreenshots() async {
    // Use NoScreenshot plugin
    bool result = await _noScreenshot.screenshotOff();
    debugPrint('Screenshot Off: $result');

    // Use Flutter's built-in methods
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
    ));

    // Set FLAG_SECURE on the window
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
        SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
        ));
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _preventScreenshots();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer.cancel();
    _noScreenshot.screenshotOn();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: SystemUiOverlay.values);
    super.dispose();
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bill'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Order ID: ${widget.orderId}',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('Bill Generated: ${DateFormat('yyyy-MM-dd – kk:mm').format(widget.generationTime)}',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600])),
              SizedBox(height: 16),
              Text('Items:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ...widget.cart.entries.map((entry) {
                var item = widget.menuItems.firstWhere(
                  (item) => item['id'] == entry.key,
                  orElse: () => null,
                );

                if (item != null) {
                  double price = (item['price'] as num).toDouble();
                  return ListTile(
                    title: Text(item['name']),
                    subtitle:
                        Text('₹${price.toStringAsFixed(2)} x ${entry.value}'),
                    trailing:
                        Text('₹${(price * entry.value).toStringAsFixed(2)}'),
                  );
                } else {
                  return SizedBox.shrink();
                }
              }).toList(),
              Divider(),
              ListTile(
                title: Text('Total',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                trailing: Text('₹${widget.totalAmount.toStringAsFixed(2)}',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              SizedBox(height: 16),
              Center(
                child: Text(
                  'Time remaining: ${_formatTime(_secondsRemaining)}',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.red),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}