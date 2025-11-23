import 'package:flutter/material.dart';

class SearchHistoryChips extends StatelessWidget {
  final Function(String)? onChipPressed;

  const SearchHistoryChips({super.key, this.onChipPressed});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: ['周杰伦', '林俊杰', '邓紫棋', '薛之谦', '李荣浩']
          .map(
            (term) => ActionChip(
              label: Text(term),
              onPressed: () => onChipPressed?.call(term),
            ),
          )
          .toList(),
    );
  }
}