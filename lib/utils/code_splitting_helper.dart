import 'package:flutter/material.dart';

/// Code Splitting Helper
/// Provides utilities for lazy loading and deferred imports
class CodeSplittingHelper {
  static final CodeSplittingHelper _instance = CodeSplittingHelper._internal();
  factory CodeSplittingHelper() => _instance;
  CodeSplittingHelper._internal();

  final Map<String, bool> _loadedModules = {};
  final Map<String, DateTime> _loadTimestamps = {};

  // ==================== LAZY LOADING ====================

  /// Load module lazily with loading indicator
  Future<T?> loadModule<T>({
    required Future<T> Function() loader,
    required String moduleName,
    BuildContext? context,
    bool showLoading = true,
  }) async {
    // Check if already loaded
    if (_loadedModules[moduleName] == true) {
      debugPrint('CodeSplitting: Module $moduleName already loaded');
      return null;
    }

    final startTime = DateTime.now();

    try {
      if (showLoading && context != null && context.mounted) {
        // Show loading dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading module...'),
                  ],
                ),
              ),
            ),
          ),
        );
      }

      // Load the module
      final result = await loader();

      // Mark as loaded
      _loadedModules[moduleName] = true;
      _loadTimestamps[moduleName] = DateTime.now();

      final loadTime = DateTime.now().difference(startTime).inMilliseconds;
      debugPrint('CodeSplitting: Module $moduleName loaded in ${loadTime}ms');

      if (showLoading && context != null && context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog
      }

      return result;
    } catch (e) {
      debugPrint('CodeSplitting: Error loading module $moduleName - $e');

      if (showLoading && context != null && context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog

        // Show error dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Loading Error'),
            content: Text('Failed to load module: $e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }

      return null;
    }
  }

  /// Preload module in background
  Future<void> preloadModule({
    required Future<void> Function() loader,
    required String moduleName,
  }) async {
    if (_loadedModules[moduleName] == true) {
      return;
    }

    try {
      await loader();
      _loadedModules[moduleName] = true;
      _loadTimestamps[moduleName] = DateTime.now();
      debugPrint('CodeSplitting: Module $moduleName preloaded');
    } catch (e) {
      debugPrint('CodeSplitting: Error preloading module $moduleName - $e');
    }
  }

  // ==================== MODULE STATUS ====================

  /// Check if module is loaded
  bool isModuleLoaded(String moduleName) {
    return _loadedModules[moduleName] ?? false;
  }

  /// Get module load timestamp
  DateTime? getModuleLoadTime(String moduleName) {
    return _loadTimestamps[moduleName];
  }

  /// Get all loaded modules
  List<String> getLoadedModules() {
    return _loadedModules.entries
        .where((entry) => entry.value == true)
        .map((entry) => entry.key)
        .toList();
  }

  /// Unload module (clear from memory)
  void unloadModule(String moduleName) {
    _loadedModules.remove(moduleName);
    _loadTimestamps.remove(moduleName);
    debugPrint('CodeSplitting: Module $moduleName unloaded');
  }

  /// Clear all modules
  void clearAllModules() {
    _loadedModules.clear();
    _loadTimestamps.clear();
    debugPrint('CodeSplitting: All modules cleared');
  }

  // ==================== STATISTICS ====================

  /// Get module loading statistics
  Map<String, dynamic> getStatistics() {
    final now = DateTime.now();

    return {
      'total_modules': _loadedModules.length,
      'loaded_modules': _loadedModules.values.where((v) => v).length,
      'modules': _loadedModules.entries.map((entry) {
        final loadTime = _loadTimestamps[entry.key];
        return {
          'name': entry.key,
          'loaded': entry.value,
          'load_time': loadTime?.toIso8601String(),
          'loaded_ago':
              loadTime != null ? now.difference(loadTime).inMinutes : null,
        };
      }).toList(),
    };
  }
}

// ==================== DEFERRED MODULE WRAPPER ====================

/// Wrapper for deferred loaded routes
class DeferredRoute<T> {
  final String moduleName;
  final Future<Widget> Function() builder;

  DeferredRoute({
    required this.moduleName,
    required this.builder,
  });

  /// Build the route with lazy loading
  Future<Route<T>> buildRoute({
    required BuildContext context,
    RouteSettings? settings,
  }) async {
    return MaterialPageRoute<T>(
      settings: settings,
      builder: (context) => FutureBuilder<Widget>(
        future: _loadAndBuild(context),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading...'),
                  ],
                ),
              ),
            );
          }

          if (snapshot.hasError) {
            return Scaffold(
              appBar: AppBar(title: const Text('Error')),
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Error loading page: ${snapshot.error}'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Go Back'),
                    ),
                  ],
                ),
              ),
            );
          }

          return snapshot.data!;
        },
      ),
    );
  }

  Future<Widget> _loadAndBuild(BuildContext context) async {
    return await CodeSplittingHelper().loadModule(
          loader: builder,
          moduleName: moduleName,
          context: context,
          showLoading: false,
        ) ??
        const SizedBox();
  }
}

// ==================== LAZY WIDGET ====================

/// Widget that loads lazily
class LazyWidget extends StatefulWidget {
  final String moduleName;
  final Future<Widget> Function() builder;
  final Widget? placeholder;

  const LazyWidget({
    super.key,
    required this.moduleName,
    required this.builder,
    this.placeholder,
  });

  @override
  State<LazyWidget> createState() => _LazyWidgetState();
}

class _LazyWidgetState extends State<LazyWidget> {
  late Future<Widget> _widgetFuture;

  @override
  void initState() {
    super.initState();
    _widgetFuture = _loadWidget();
  }

  Future<Widget> _loadWidget() async {
    return await CodeSplittingHelper().loadModule(
          loader: widget.builder,
          moduleName: widget.moduleName,
          context: context,
          showLoading: false,
        ) ??
        const SizedBox();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _widgetFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return widget.placeholder ??
              const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red),
                Text('Error: ${snapshot.error}'),
              ],
            ),
          );
        }

        return snapshot.data!;
      },
    );
  }
}

// ==================== LAZY LIST ====================

/// Lazy loading list view
class LazyListView extends StatefulWidget {
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final ScrollController? controller;
  final int threshold;
  final VoidCallback? onLoadMore;

  const LazyListView({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.controller,
    this.threshold = 5,
    this.onLoadMore,
  });

  @override
  State<LazyListView> createState() => _LazyListViewState();
}

class _LazyListViewState extends State<LazyListView> {
  late ScrollController _scrollController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.controller ?? ScrollController();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    if (widget.controller == null) {
      _scrollController.dispose();
    }
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - (widget.threshold * 100)) {
      if (!_isLoading && widget.onLoadMore != null) {
        setState(() => _isLoading = true);
        widget.onLoadMore!();
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: _scrollController,
      itemCount: widget.itemCount + (_isLoading ? 1 : 0),
      addAutomaticKeepAlives: true,
      addRepaintBoundaries: true,
      cacheExtent: 500,
      itemBuilder: (context, index) {
        if (index == widget.itemCount && _isLoading) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          );
        }
        return widget.itemBuilder(context, index);
      },
    );
  }
}
