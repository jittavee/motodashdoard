import 'package:flutter/material.dart';

class TemplateTwoScreen extends StatelessWidget {
  const TemplateTwoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: 
        Center(
          child: Text('Template 2 Screen'),
        ),
      ),
    );
  }
}