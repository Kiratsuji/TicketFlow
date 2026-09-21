import 'package:flutter/material.dart';
import '../../widgets/appWidgets.dart';

class PlaceholderPage extends StatelessWidget {
  final String title;
  const PlaceholderPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionTitle(title),
            const EmptyState(message: 'Em construção', icon: Icons.construction_rounded),
          ],
        ),
      ),
    );
  }
}