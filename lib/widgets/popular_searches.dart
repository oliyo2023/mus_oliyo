import 'package:flutter/material.dart';

class PopularSearches extends StatelessWidget {
  final Function(String)? onSearchPressed;

  const PopularSearches({super.key, this.onSearchPressed});

  @override
  Widget build(BuildContext context) {
    final searches = [
      {'term': '孤勇者', 'hot': true},
      {'term': '漠河舞厅', 'hot': false},
      {'term': '错位时空', 'hot': true},
      {'term': '白月光与朱砂痣', 'hot': false},
    ];

    return Column(
      children: searches
          .map(
            (search) => ListTile(
              leading: Icon(
                search['hot'] == true
                    ? Icons.local_fire_department
                    : Icons.trending_up,
                color: search['hot'] == true ? Colors.red : Colors.grey,
              ),
              title: Text(search['term'] as String),
              trailing: search['hot'] == true
                  ? const Icon(Icons.trending_up)
                  : null,
              onTap: () => onSearchPressed?.call(search['term'] as String),
            ),
          )
          .toList(),
    );
  }
}