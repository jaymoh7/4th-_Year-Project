import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/detection_viewmodel.dart';

class CommentsScreen extends StatelessWidget {
  const CommentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Comments'),
      ),
      body: const Center(
        child: Text('Comments coming soon...'),
      ),
    );
  }
}