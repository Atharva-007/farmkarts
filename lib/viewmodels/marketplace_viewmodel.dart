import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/product_model.dart';
import '../models/user_model.dart';
import '../services/marketplace_service.dart';
import '../services/product_service.dart';
import '../services/performance_service.dart';

class MarketplaceViewModel extends ChangeNotifier {
  final MarketplaceService _marketplaceService = MarketplaceService();
  final ProductService _productService = ProductService();
  
  List<Product> _sellingProducts = [];
  List<Product> _buyingProducts = [];
  List<String> _categories = ['All'];
  
  String _selectedCategory = 'All';
  String _searchQuery = '';
  bool _isLoading = true;
  String? _error;
  UserRole? _userRole;

  // Getters
  List<Product> get sellingProducts => _sellingProducts;
  List<Product> get buyingProducts => _filteredBuyingProducts();
  List<String> get categories => _categories;
  String get selectedCategory => _selectedCategory;
  bool get isLoading => _isLoading;
  String? get error => _error;
  UserRole? get userRole => _userRole;

  void setCategory(String category) {
    if (_selectedCategory != category) {
      _selectedCategory = category;
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    if (_searchQuery != query) {
      _searchQuery = query;
      notifyListeners();
    }
  }

  List<Product> _filteredBuyingProducts() {
    return _buyingProducts.where((product) {
      final matchesCategory = _selectedCategory == 'All' || product.category == _selectedCategory;
      final matchesSearch = _searchQuery.isEmpty || 
          product.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          product.description.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  Future<void> loadData({bool forceRefresh = false}) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Fetch products and categories in parallel
        final results = await Future.wait([
          _marketplaceService.getProducts(forceRefresh: forceRefresh, excludeCurrentUser: true),
          _marketplaceService.getCategories(),
        ]);

        _buyingProducts = results[0] as List<Product>;
        _categories = ['All', ...(results[1] as List<String>)];
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  void sortProducts(String criteria) {
    if (criteria == 'price_asc') {
      _buyingProducts.sort((a, b) => a.price.compareTo(b.price));
    } else if (criteria == 'price_desc') {
      _buyingProducts.sort((a, b) => b.price.compareTo(a.price));
    } else if (criteria == 'newest') {
      _buyingProducts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    notifyListeners();
  }
}