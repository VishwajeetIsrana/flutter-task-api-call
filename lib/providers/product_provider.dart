import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../services/api_service.dart';

class ProductProvider with ChangeNotifier {
  List<Product> _products = [];
  Product? _selectedProduct;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;
  String _searchQuery = '';
  String _sortBy = 'title';
  String _order = 'asc';
  String? _selectedCategory;
  List<String>? _categories;
  bool _hasMore = true;
  int _currentPage = 0;
  final int _perPage = 10;

  List<Product> get products => _filterAndSortProducts();
  Product? get selectedProduct => _selectedProduct;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  String get sortBy => _sortBy;
  String get order => _order;
  String? get selectedCategory => _selectedCategory;
  List<String>? get categories => _categories;
  bool get hasMore => _hasMore;

  final ApiService _apiService = ApiService();

  Future<void> fetchProducts({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 0;
      _hasMore = true;
    }

    if (!refresh && !_hasMore) return;

    _isLoading = true;
    if (refresh) {
      notifyListeners(); // Only notify if it's a refresh to avoid UI jumps
    }

    try {
      final newProducts = await _apiService.getProducts(
        skip: _currentPage * _perPage,
        limit: _perPage,
      );

      if (refresh) {
        _products = newProducts;
      } else {
        _products.addAll(newProducts);
      }

      _hasMore = newProducts.length == _perPage;
      _currentPage++;

      if (_categories == null) {
        await _fetchCategories();
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> _fetchCategories() async {
    try {
      _categories = await _apiService.getCategories();
      notifyListeners();
    } catch (e) {
      // Don't fail the whole operation if categories fail
      debugPrint('Failed to load categories: $e');
    }
  }

  Future<void> loadMoreProducts() async {
    if (_isLoadingMore || !_hasMore) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      final newProducts = await _apiService.getProducts(
        skip: _currentPage * _perPage,
        limit: _perPage,
      );

      _products.addAll(newProducts);
      _hasMore = newProducts.length == _perPage;
      _currentPage++;

      _isLoadingMore = false;
      notifyListeners();
    } catch (e) {
      _isLoadingMore = false;
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> fetchProductById(int id) async {
    _isLoading = true;
    notifyListeners();

    try {
      _selectedProduct = await _apiService.getProductById(id);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> addProduct(Product product) async {
    _isLoading = true;
    notifyListeners();

    try {
      final newProduct = await _apiService.addProduct(product);
      _products.insert(0, newProduct); // Add at beginning
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateProduct(Product product) async {
    _isLoading = true;
    notifyListeners();

    try {
      final updatedProduct = await _apiService.updateProduct(product);
      final index = _products.indexWhere((p) => p.id == product.id);
      if (index != -1) {
        _products[index] = updatedProduct;
      }
      _selectedProduct = updatedProduct;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteProduct(int id) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _apiService.deleteProduct(id);
      _products.removeWhere((product) => product.id == id);
      if (_selectedProduct?.id == id) {
        _selectedProduct = null;
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> searchProducts(String query) async {
    _isLoading = true;
    _searchQuery = query;
    notifyListeners();

    try {
      if (query.isEmpty) {
        await fetchProducts(refresh: true);
      } else {
        _products = await _apiService.searchProducts(query);
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setSortOrder(String sortBy, String order) {
    _sortBy = sortBy;
    _order = order;
    notifyListeners();
  }

  void setSelectedCategory(String? category) {
    _selectedCategory = category;
    notifyListeners();
  }

  List<Product> _filterAndSortProducts() {
    List<Product> filteredProducts = List.from(_products);

    // Apply search filter if not using API search
    if (_searchQuery.isNotEmpty && _products.length < 100) {
      filteredProducts = filteredProducts
          .where((product) =>
              product.title.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    // Apply category filter
    if (_selectedCategory != null) {
      filteredProducts = filteredProducts
          .where((product) => product.category == _selectedCategory)
          .toList();
    }

    // Apply sorting
    filteredProducts.sort((a, b) {
      int compareResult;
      if (_sortBy == 'title') {
        compareResult = a.title.compareTo(b.title);
      } else {
        compareResult = a.price.compareTo(b.price);
      }
      return _order == 'asc' ? compareResult : -compareResult;
    });

    return filteredProducts;
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void resetFilters() {
    _searchQuery = '';
    _selectedCategory = null;
    _sortBy = 'title';
    _order = 'asc';
    notifyListeners();
  }
}
