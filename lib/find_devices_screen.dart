import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:motodashboard/dashboard_screen.dart';

class FindDevicesScreen extends StatefulWidget {
  const FindDevicesScreen({super.key});

  @override
  State<FindDevicesScreen> createState() => _FindDevicesScreenState();
}

class _FindDevicesScreenState extends State<FindDevicesScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Dashboard Device'),
        backgroundColor: Colors.black,
      ),
      body: RefreshIndicator(
        onRefresh: () => FlutterBluePlus.startScan(timeout: const Duration(seconds: 4)),
        child: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              StreamBuilder<List<ScanResult>>(
                stream: FlutterBluePlus.scanResults,
                initialData: const [],
                builder: (c, snapshot) => Column(
                  children: snapshot.data!
                      .where((r) => r.device.platformName.isNotEmpty) // Filter out unnamed devices
                      .map(
                        (r) => ListTile(
                          title: Text(r.device.platformName),
                          subtitle: Text(r.device.remoteId.toString()),
                          trailing: ElevatedButton(
                            child: const Text('CONNECT'),
                            onPressed: () async {
                              await r.device.connect();
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => DashboardScreen(device: r.device),
                                ),
                              );
                            },
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: StreamBuilder<bool>(
        stream: FlutterBluePlus.isScanning,
        initialData: false,
        builder: (c, snapshot) {
          if (snapshot.data!) {
            return FloatingActionButton(
              onPressed: () => FlutterBluePlus.stopScan(),
              backgroundColor: Colors.red,
              child: const Icon(Icons.stop),
            );
          } else {
            return FloatingActionButton(
              child: const Icon(Icons.search),
              onPressed: () => FlutterBluePlus.startScan(timeout: const Duration(seconds: 4)),
            );
          }
        },
      ),
    );
  }
}