import 'package:flutter/material.dart';
import 'package:connectivity/connectivity.dart';
import 'dart:async';

class ConnectivityChecker extends StatefulWidget {
  final Widget child;

  const ConnectivityChecker({super.key, required this.child});

  @override
  _ConnectivityCheckerState createState() => _ConnectivityCheckerState();
}

class _ConnectivityCheckerState extends State<ConnectivityChecker> {
  late bool _isConnected;
  late bool _isLoading;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _isLoading = true;
    checkConnectivity();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> checkConnectivity() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    setState(() {
      _isConnected = connectivityResult != ConnectivityResult.none;
      _isLoading = false;
    });
  }

  void _startAutoRefresh() {
    _timer = Timer.periodic(Duration(seconds: 30), (timer) async {
      if (!_isConnected) {
        await _refreshConnectivity();
      }
    });
  }

  Future<void> _refreshConnectivity() async {
    setState(() {
      _isLoading = true;
    });
    await checkConnectivity();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    } else if (!_isConnected) {
      return Scaffold(
        body: RefreshIndicator(
          onRefresh: _refreshConnectivity,
          child: ListView(
            children: [
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    SizedBox(height: 400),
                    Text(
                      'Отсутствует подключение к интернету',
                      style: TextStyle(fontSize: 20),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      return RefreshIndicator(
        onRefresh: _refreshConnectivity,
        child: widget.child,
      );
    }
  }
}
