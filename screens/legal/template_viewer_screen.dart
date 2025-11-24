import 'package:flutter/material.dart';

class TemplateViewerScreen extends StatelessWidget {
  final String title;
  final String content;

  const TemplateViewerScreen({
    Key? key,
    required this.title,
    required this.content,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        centerTitle: true,
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: SelectableText(
            content,
            style: const TextStyle(
              fontSize: 16,
              height: 1.4,
            ),
          ),
        ),
      ),
    );
  }
}
