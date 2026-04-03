import 'package:flutter/foundation.dart';

/// Lightweight state management for reducing setState() calls
/// Use this for simple state that doesn't need Provider/Riverpod
class StateNotifier<T> extends ValueNotifier<T> {
  StateNotifier(super.value);
  
  /// Update state with new value
  void update(T newValue) {
    if (value != newValue) {
      value = newValue;
    }
  }
  
  /// Update state with a transformation function
  void transform(T Function(T current) transformer) {
    value = transformer(value);
  }
}

/// Loading state wrapper
class LoadingState<T> {
  final bool isLoading;
  final T? data;
  final String? error;
  
  const LoadingState({
    this.isLoading = false,
    this.data,
    this.error,
  });
  
  LoadingState<T> copyWith({
    bool? isLoading,
    T? data,
    String? error,
  }) {
    return LoadingState<T>(
      isLoading: isLoading ?? this.isLoading,
      data: data ?? this.data,
      error: error ?? this.error,
    );
  }
  
  bool get hasData => data != null;
  bool get hasError => error != null;
  bool get isIdle => !isLoading && !hasError;
}

/// Multiple state notifiers for different UI sections
class MarketplaceState {
  final StateNotifier<bool> isLoading;
  final StateNotifier<List<dynamic>> products;
  final StateNotifier<String?> error;
  final StateNotifier<String> searchQuery;
  final StateNotifier<String> selectedCategory;
  
  MarketplaceState()
      : isLoading = StateNotifier<bool>(true),
        products = StateNotifier<List<dynamic>>([]),
        error = StateNotifier<String?>(null),
        searchQuery = StateNotifier<String>(''),
        selectedCategory = StateNotifier<String>('All');
  
  void dispose() {
    isLoading.dispose();
    products.dispose();
    error.dispose();
    searchQuery.dispose();
    selectedCategory.dispose();
  }
}
