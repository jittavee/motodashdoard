import 'package:flutter/material.dart';

class TemplateFourScreen extends StatelessWidget {
  const TemplateFourScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: 
        Center(
          child: Text('Template 4 Screen'),
        ),
      ),
    );
  }
}