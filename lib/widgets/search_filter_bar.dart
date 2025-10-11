import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/responsive_helper.dart';

class SearchFilterBar extends StatelessWidget {
  final List<String> categories;
  final String selectedCategory;
  final Function(String) onCategoryChanged;
  final Function(String) onSearchChanged;

  const SearchFilterBar({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.onCategoryChanged,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);
    
    return Column(
      children: [
        // Search Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            onChanged: onSearchChanged,
            decoration: const InputDecoration(
              hintText: 'Search products, categories, sellers...',
              border: InputBorder.none,
              icon: Icon(Icons.search, color: AppTheme.primaryGreen),
              hintStyle: TextStyle(color: AppTheme.textGrey),
            ),
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Category Filters
        SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 0 : 8),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              final isSelected = category == selectedCategory;
              
              return Container(
                margin: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(
                    category,
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppTheme.textGrey,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: isMobile ? 12 : 14,
                    ),
                  ),
                  selected: isSelected,
                  onSelected: (_) => onCategoryChanged(category),
                  backgroundColor: Colors.white,
                  selectedColor: AppTheme.primaryGreen,
                  checkmarkColor: Colors.white,
                  elevation: isSelected ? 4 : 2,
                  shadowColor: AppTheme.primaryGreen.withValues(alpha: 0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isSelected 
                          ? AppTheme.primaryGreen 
                          : AppTheme.borderGrey,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}