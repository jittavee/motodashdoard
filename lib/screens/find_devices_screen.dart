import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../providers/dashboard_provider.dart';
import '../screens/dashboard_screen.dart';

class FindDevicesScreen extends StatefulWidget {
  const FindDevicesScreen({super.key});

  @override
  State<FindDevicesScreen> createState() => _FindDevicesScreenState();
}

class _FindDevicesScreenState extends State<FindDevicesScreen> {
  List<fbp.ScanResult> _scanResults = [];
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _startScan();
  }

  Future<void> _startScan() async {
    if (!mounted) return;
    
    setState(() {
      _isScanning = true;
    });

    try {
      final provider = Provider.of<DashboardProvider>(context, listen: false);
      final results = await provider.scanForDevices();
      
      if (mounted) {
        setState(() {
          _scanResults = results;
          _isScanning = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isScanning = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Scan failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _connectToDevice(fbp.BluetoothDevice device) async {
    try {
      final provider = Provider.of<DashboardProvider>(context, listen: false);
      await provider.connectToDevice(device);
      
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const DashboardScreen(),
          ),
        );
      }
    } catch (e) {
      debugPrint('Connection failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to connect: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.findDevicesTitle),
        backgroundColor: Colors.black,
      ),
      body: RefreshIndicator(
        onRefresh: _startScan,
        child: _isScanning
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Scanning for devices...'),
                  ],
                ),
              )
            : _scanResults.isEmpty
                ? const Center(
                    child: Text('No devices found. Pull to refresh.'),
                  )
                : ListView.builder(
                    itemCount: _scanResults.length,
                    itemBuilder: (context, index) {
                      final result = _scanResults[index];
                      final device = result.device;
                      
                      if (device.platformName.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      
                      return ListTile(
                        title: Text(device.platformName),
                        subtitle: Text(device.remoteId.toString()),
                        trailing: ElevatedButton(
                          child: const Text(AppStrings.connectButtonText),
                          onPressed: () => _connectToDevice(device),
                        ),
                      );
                    },
                  ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isScanning ? null : _startScan,
        backgroundColor: _isScanning ? Colors.grey : Colors.blue,
        child: _isScanning
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.search),
      ),
    );
  }
}