
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_scanner/mobile_scanner.dart';

void main() {
  runApp(const NutriScanApp());
}

class NutriScanApp extends StatelessWidget {
  const NutriScanApp({super.key});

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF16865B);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'NutriScan',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF7FAF8),
        colorScheme: ColorScheme.fromSeed(seedColor: green),
        fontFamily: 'Roboto',
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int selectedIndex = 0;
  final searchController = TextEditingController();

  // Android emulator uses 10.0.2.2 to access your Mac.
  static const String apiBaseUrl = 'http://10.0.2.2:8001';

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> searchProducts(String query) async {
    final searchText = query.trim();

    if (searchText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a food or brand name.')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SearchResultsScreen(
          query: searchText,
          apiBaseUrl: apiBaseUrl,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    height: 48,
                    width: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F3E9),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Icon(
                      Icons.eco_rounded,
                      color: Color(0xFF16865B),
                      size: 29,
                    ),
                  ),
                  const SizedBox(width: 11),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'NutriScan',
                        style: TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF183D30),
                        ),
                      ),
                      Text(
                        'Know what you eat.',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(
                      Icons.notifications_none_rounded,
                      size: 27,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // Welcome
              const Text(
                'Eat Smart,',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF183D30),
                ),
              ),
              const Text(
                'Live Healthy.',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF16865B),
                ),
              ),
              const SizedBox(height: 9),
              const Text(
                'Discover what is inside your favourite foods.',
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),

              const SizedBox(height: 23),

              // Search
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE6ECE8)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: Color(0xFF16865B)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: searchController,
                        textInputAction: TextInputAction.search,
                        decoration: const InputDecoration(
                          hintText: 'Search food or brand...',
                          border: InputBorder.none,
                        ),
                        onSubmitted: searchProducts,
                      ),
                    ),
                    IconButton(
                      onPressed: () => searchProducts(searchController.text),
                      icon: const Icon(
                        Icons.arrow_forward_rounded,
                        color: Color(0xFF16865B),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 19),

              // Scanner card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(21),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(23),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF16865B), Color(0xFF0B6544)],
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'SCAN YOUR FOOD',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 9),
                          const Text(
                            'Know your food\nin seconds!',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 15),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const BarcodeScannerScreen(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.qr_code_scanner),
                            label: const Text('Scan Barcode'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF16865B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.document_scanner_rounded,
                      color: Colors.white,
                      size: 76,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 29),

              // Features
              const Text(
                'Explore NutriScan',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF183D30),
                ),
              ),
              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: featureCard(
                      icon: Icons.restaurant_menu_rounded,
                      title: 'Nutrition',
                      subtitle: 'Food details',
                      color: const Color(0xFFE3F3E9),
                      onTap: () => showFeatureMessage(context, 'Nutrition'),
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: featureCard(
                      icon: Icons.compare_arrows_rounded,
                      title: 'Compare',
                      subtitle: 'Compare foods',
                      color: const Color(0xFFFFF0DA),
                      onTap: () => showFeatureMessage(context, 'Compare'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 13),

              Row(
                children: [
                  Expanded(
                    child: featureCard(
                      icon: Icons.recommend_rounded,
                      title: 'Smart Picks',
                      subtitle: 'Better alternatives',
                      color: const Color(0xFFE9E5FA),
                      onTap: () => showFeatureMessage(
                        context,
                        'Smart Recommendations',
                      ),
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: featureCard(
                      icon: Icons.favorite_rounded,
                      title: 'Favourites',
                      subtitle: 'Saved products',
                      color: const Color(0xFFFCE5E8),
                      onTap: () => showFeatureMessage(context, 'Favourites'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 25),

              // Footer
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(17),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF5EE),
                  borderRadius: BorderRadius.circular(17),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline_rounded,
                      color: Color(0xFF16865B),
                      size: 27,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Small food choices can make a big difference!',
                        style: TextStyle(
                          color: Color(0xFF285B43),
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),

      // Bottom navigation
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            selectedIndex = index;
          });

          if (index == 1) {
            searchController.clear();
            FocusScope.of(context).unfocus();
          } else if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const BarcodeScannerScreen(),
              ),
            );
          } else if (index == 3) {
            showFeatureMessage(context, 'Profile');
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_rounded),
            label: 'Explore',
          ),
          NavigationDestination(
            icon: Icon(Icons.qr_code_scanner_rounded),
            label: 'Scan',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget featureCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(19),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(19),
          border: Border.all(color: const Color(0xFFE9EFEB)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 45,
              width: 45,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: const Color(0xFF16865B),
                size: 25,
              ),
            ),
            const SizedBox(height: 13),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(color: Colors.black54, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  void showFeatureMessage(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature screen will be connected next.'),
      ),
    );
  }
}

// ------------------------------------------------------------
// SEARCH RESULTS SCREEN
// ------------------------------------------------------------

class SearchResultsScreen extends StatefulWidget {
  final String query;
  final String apiBaseUrl;

  const SearchResultsScreen({
    super.key,
    required this.query,
    required this.apiBaseUrl,
  });

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  bool isLoading = true;
  String? errorMessage;
  List<Map<String, dynamic>> products = [];

  @override
  void initState() {
    super.initState();
    fetchProducts();
  }

  Future<void> fetchProducts() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final uri = Uri.parse(
        '${widget.apiBaseUrl}/products/search',
      ).replace(
        queryParameters: {'q': widget.query},
      );

      final response = await http.get(uri).timeout(
        const Duration(seconds: 20),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final extractedProducts = extractProductList(decoded);

        if (!mounted) return;

        setState(() {
          products = extractedProducts;
          isLoading = false;
        });
      } else {
        throw Exception(
          'Server returned status ${response.statusCode}.',
        );
      }
    } catch (error) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage =
            'Could not load products. Check that your backend is running.';
      });
    }
  }

  List<Map<String, dynamic>> extractProductList(dynamic data) {
    dynamic listData = data;

    if (data is Map) {
      listData = data['products'] ??
          data['results'] ??
          data['data'] ??
          data['items'] ??
          data['results'];

      // Some APIs return a single product object.
      if (listData == null &&
          (data.containsKey('product_name') ||
              data.containsKey('name'))) {
        return [Map<String, dynamic>.from(data)];
      }
    }

    if (listData is List) {
      return listData
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }

    return [];
  }

  String productValue(
    Map<String, dynamic> product,
    List<String> possibleKeys,
  ) {
    for (final key in possibleKeys) {
      final value = product[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Results for "${widget.query}"'),
        backgroundColor: const Color(0xFFF7FAF8),
      ),
      body: RefreshIndicator(
        onRefresh: fetchProducts,
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF16865B),
                ),
              )
            : errorMessage != null
                ? ListView(
                    children: [
                      const SizedBox(height: 130),
                      const Icon(
                        Icons.wifi_off_rounded,
                        size: 55,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 15),
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(
                            errorMessage!,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      Center(
                        child: ElevatedButton(
                          onPressed: fetchProducts,
                          child: const Text('Try again'),
                        ),
                      ),
                    ],
                  )
                : products.isEmpty
                    ? ListView(
                        children: const [
                          SizedBox(height: 140),
                          Icon(
                            Icons.search_off_rounded,
                            size: 60,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 15),
                          Center(
                            child: Text('No matching products found.'),
                          ),
                        ],
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: products.length,
                        itemBuilder: (context, index) {
                          final product = products[index];

                          final name = productValue(
                            product,
                            ['product_name', 'name', 'title'],
                          );

                          final brand = productValue(
                            product,
                            ['brand_name', 'brand'],
                          );

                          final category = productValue(
                            product,
                            ['category', 'sub_category'],
                          );

                          final calories = productValue(
                            product,
                            ['calories_kcal', 'calories'],
                          );

                          final protein = productValue(
                            product,
                            ['proteins_g', 'protein_g'],
                          );

                          final sugar = productValue(
                            product,
                            ['sugar_g', 'sugars_g'],
                          );

                          return Card(
                            color: Colors.white,
                            margin: const EdgeInsets.only(bottom: 13),
                            elevation: 1,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(17),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name.isEmpty ? 'Unnamed product' : name,
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF183D30),
                                    ),
                                  ),
                                  if (brand.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      brand,
                                      style: const TextStyle(
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ],
                                  if (category.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      category,
                                      style: const TextStyle(
                                        color: Color(0xFF16865B),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                  const Divider(height: 22),
                                  const Text(
                                    'Nutrition per 100g',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 9),
                                  Wrap(
                                    spacing: 16,
                                    runSpacing: 9,
                                    children: [
                                      if (calories.isNotEmpty)
                                        nutritionItem(
                                          'Calories',
                                          '$calories kcal',
                                        ),
                                      if (protein.isNotEmpty)
                                        nutritionItem(
                                          'Protein',
                                          '$protein g',
                                        ),
                                      if (sugar.isNotEmpty)
                                        nutritionItem(
                                          'Sugar',
                                          '$sugar g',
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
      ),
    );
  }

  Widget nutritionItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.black54,
            fontSize: 12,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF16865B),
          ),
        ),
      ],
    );
  }
}

// ------------------------------------------------------------
// BARCODE SCANNER
// ------------------------------------------------------------

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  String apiBaseUrl = 'http://10.0.2.2:8001';
  bool isProcessing = false;

  Future<void> handleBarcode(String barcode) async {
    if (isProcessing) return;
    setState(() => isProcessing = true);

    try {
      final uri = Uri.parse('$apiBaseUrl/product/$barcode');
      final response = await http.get(uri).timeout(
        const Duration(seconds: 20),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is! Map) {
          throw const FormatException('Unexpected product response');
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ScannedProductScreen(
              barcode: barcode,
              product: Map<String, dynamic>.from(decoded),
            ),
          ),
        );
      } else {
        setState(() => isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No product found for barcode $barcode')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not connect to the NutriScan server.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Barcode'),
        backgroundColor: const Color(0xFFF7FAF8),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            onDetect: (capture) {
              if (isProcessing || capture.barcodes.isEmpty) return;
              final code = capture.barcodes.first.rawValue;
              if (code != null && code.isNotEmpty) handleBarcode(code);
            },
          ),
          IgnorePointer(
            child: Center(
              child: Container(
                width: 280,
                height: 180,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: const Color(0xFF35D6A0),
                    width: 3,
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 35,
            left: 24,
            right: 24,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Text(
                isProcessing
                    ? 'Barcode detected. Finding product...'
                    : 'Place the product barcode inside the box',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------
// SCANNED PRODUCT DETAILS
// ------------------------------------------------------------

class ScannedProductScreen extends StatelessWidget {
  final String barcode;
  final Map<String, dynamic> product;

  const ScannedProductScreen({
    super.key,
    required this.barcode,
    required this.product,
  });

  String getValue(List<String> keys) {
    final nested = product['product'];
    final data = nested is Map
        ? Map<String, dynamic>.from(nested)
        : product;

    for (final key in keys) {
      final value = data[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }
    return 'Not available';
  }

  @override
  Widget build(BuildContext context) {
    final name = getValue(['product_name', 'name']);
    final brand = getValue(['brand_name', 'brand']);
    final category = getValue(['category', 'categories']);
    final calories = getValue(['calories_kcal', 'calories']);
    final protein = getValue(['proteins_g', 'protein_g', 'proteins']);
    final carbs = getValue(['carbohydrates_g', 'carbohydrates']);
    final fat = getValue(['total_fat_g', 'fat_g', 'fat']);
    final saturatedFat = getValue(['saturated_fat_g', 'saturated_fat']);
    final sugar = getValue(['sugar_g', 'sugars_g', 'sugars']);
    final sodium = getValue(['sodium_mg', 'sodium']);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Nutrition'),
        backgroundColor: const Color(0xFFF7FAF8),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: Color(0xFF16865B),
              size: 55,
            ),
            const SizedBox(height: 15),
            Text(
              name,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF183D30),
              ),
            ),
            const SizedBox(height: 8),
            Text(brand, style: const TextStyle(color: Colors.black54)),
            const SizedBox(height: 8),
            Text('Category: $category'),
            Text('Barcode: $barcode'),
            const SizedBox(height: 25),
            const Text(
              'Nutrition Information',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF183D30),
              ),
            ),
            const SizedBox(height: 12),
            nutritionRow('Calories', '$calories kcal'),
            nutritionRow('Protein', '$protein g'),
            nutritionRow('Carbohydrates', '$carbs g'),
            nutritionRow('Total Fat', '$fat g'),
            nutritionRow('Saturated Fat', '$saturatedFat g'),
            nutritionRow('Sugar', '$sugar g'),
            nutritionRow('Sodium', '$sodium mg'),
            const SizedBox(height: 20),
            const Text(
              'Nutrition values are displayed as returned by the product database.',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('Scan Another Product'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF16865B),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget nutritionRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFE6ECE8)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF16865B),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
