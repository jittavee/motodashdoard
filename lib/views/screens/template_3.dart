import 'package:flutter/material.dart';

class TemplateThreeScreen extends StatelessWidget {
  const TemplateThreeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: 
        Center(
          child: Text('Template 3 Screen'),
        ),
      ),
    );
  }
}