import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ListUiScreen extends StatelessWidget {
  const ListUiScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return  Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            ListTile(
              onTap: () {
                Get.toNamed('/template-1');
              },
              title: Text('UI-Screen-1'),
            ),
            ListTile(
               onTap: () {
                Get.toNamed('/template-2');
              },
              title: Text('UI-Screen-2'),
            ),
            ListTile(
               onTap: () {
                Get.toNamed('/template-3');
              },
              title: Text('UI-Screen-3'),
            ),
            ListTile(
               onTap: () {
                Get.toNamed('/template-4');
              },
              title: Text('UI-Screen-4'),
            ),
            ListTile( 
               onTap: () {
                Get.toNamed('/template-5');
              },
              title: Text('UI-Screen-5'),
            ),
            
          ],
        ),

        // Column(
        //   children: [
        //     Text('UI-Screen-1'),
        //     Text('UI-Screen-2'),
        //     Text('UI-Screen-3'),
        //     Text('UI-Screen-4'),
        //     Text('UI-Screen-5'),
        //   ],
        // ),
      ),
    );
  }
}