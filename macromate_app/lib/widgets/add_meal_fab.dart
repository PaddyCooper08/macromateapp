import 'package:flutter/material.dart';
import 'add_meal_bottom_sheet.dart';

class AddMealFab extends StatelessWidget {
  const AddMealFab({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => const AddMealBottomSheet(),
        );
      },
      backgroundColor: Colors.blue[500],
      foregroundColor: Colors.white,
      child: const Icon(Icons.add),
    );
  }
}
