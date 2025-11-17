import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:auto_refresh_on_reconnect/auto_refresh_on_reconnect.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Auto Refresh on Reconnect Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const ExamplePage(),
    );
  }
}

class ExamplePage extends StatefulWidget {
  const ExamplePage({super.key});

  @override
  State<ExamplePage> createState() => _ExamplePageState();
}

class _ExamplePageState extends State<ExamplePage> {
  List<Map<String, dynamic>> _products = [];
  DateTime? _lastRefresh;
  int _refreshCount = 0;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Fetch real data from JSONPlaceholder API
      final response = await http.get(
        Uri.parse('https://jsonplaceholder.typicode.com/posts?_limit=10'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _products = data.map((item) => {
            'id': item['id'],
            'title': item['title'],
            'body': item['body'],
          }).toList();
          _lastRefresh = DateTime.now();
          _refreshCount++;
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load products');
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Auto Refresh Demo'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'View Builder API Example',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const BuilderExample()),
              );
            },
          ),
        ],
      ),
      body: AutoRefreshOnReconnect(
        onRefresh: _fetchProducts,
        offlineBuilder: (context) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.wifi_off,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'No Internet Connection',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Waiting for connection to restore...',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
            ],
          ),
        ),
        child: _buildProductList(),
      ),
    );
  }

  Widget _buildProductList() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.blue[50],
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.green[300]!),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.wifi, color: Colors.green[700], size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Connected',
                      style: TextStyle(
                        color: Colors.green[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Refresh Count:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text('$_refreshCount'),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Last Refresh:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    _lastRefresh != null
                        ? '${_lastRefresh!.hour}:${_lastRefresh!.minute}:${_lastRefresh!.second}'
                        : 'Never',
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 48, color: Colors.red),
                          const SizedBox(height: 16),
                          Text('Error: $_error'),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _fetchProducts,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  : _products.isEmpty
                      ? const Center(child: Text('No products available'))
                      : ListView.builder(
                          itemCount: _products.length,
                          itemBuilder: (context, index) {
                            final product = _products[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.blue,
                                  child: Text(
                                    '${product['id']}',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                                title: Text(
                                  product['title'],
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(
                                  product['body'],
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                              ),
                            );
                          },
                        ),
        ),
      ],
    );
  }
}

/// Example using the builder API with real API data
class BuilderExample extends StatelessWidget {
  const BuilderExample({super.key});

  Future<List<Map<String, dynamic>>> _fetchData() async {
    final response = await http.get(
      Uri.parse('https://jsonplaceholder.typicode.com/users?_limit=5'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((item) => {
        'id': item['id'],
        'name': item['name'],
        'email': item['email'],
        'company': item['company']['name'],
      }).toList();
    } else {
      throw Exception('Failed to load users');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Builder API Example'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: AutoRefreshOnReconnectBuilder<List<Map<String, dynamic>>>(
        futureBuilder: _fetchData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                ],
              ),
            );
          }

          if (snapshot.hasData) {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final user = snapshot.data![index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text('${user['id']}'),
                    ),
                    title: Text(user['name']),
                    subtitle: Text('${user['email']}\n${user['company']}'),
                    isThreeLine: true,
                  ),
                );
              },
            );
          }

          return const Center(child: Text('No data'));
        },
        offlineBuilder: (context) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.wifi_off, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              const Text(
                'Offline',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Waiting for connection...',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
