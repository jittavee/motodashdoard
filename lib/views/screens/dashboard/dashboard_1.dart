import 'package:flutter/material.dart';

class TemplateOneScreen extends StatelessWidget {
  const TemplateOneScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: 
        Center(
          child: Text('Template 1 Screen'),
        ),
      ),
    );
  }
}