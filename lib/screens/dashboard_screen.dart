import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/speed_gauge.dart';
import '../widgets/info_grid.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    _listenToConnectionState();
  }

  void _listenToConnectionState() {
    final provider = Provider.of<DashboardProvider>(context, listen: false);
    
    // Listen for connection state changes
    provider.addListener(() {
      if (provider.connectionState == fbp.BluetoothConnectionState.disconnected && mounted) {
        _handleDisconnection();
      }
      
      if (provider.errorMessage != null && mounted) {
        _showErrorDialog('Error', provider.errorMessage!);
        provider.clearError();
      }
    });
  }

  void _handleDisconnection() {
    if (mounted) {
      _showErrorDialog(
        AppStrings.connectionLostTitle,
        'Disconnected from device.',
        true,
      );
    }
  }

  void _showErrorDialog(String title, String message, [bool popTwice = false]) {
    if (!mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(message),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text(AppStrings.okButtonText),
              onPressed: () {
                Navigator.of(context).pop();
                if (popTwice) {
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _disconnect() async {
    final provider = Provider.of<DashboardProvider>(context, listen: false);
    await provider.disconnect();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardProvider>(
      builder: (context, provider, child) {
        final deviceName = provider.connectedDevice?.platformName ?? 'Unknown Device';
        
        return PopScope(
          onPopInvokedWithResult: (didPop, result) async {
            if (didPop) {
              debugPrint("Back button pressed. Disconnecting...");
              await provider.disconnect();
            }
          },
          child: Scaffold(
            appBar: AppBar(
              title: Text(deviceName),
              backgroundColor: Colors.black,
              actions: [
                IconButton(
                  icon: const Icon(Icons.bluetooth_disabled),
                  tooltip: AppStrings.disconnectTooltip,
                  onPressed: _disconnect,
                )
              ],
            ),
            body: ListView(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              children: [
                SpeedGauge(speed: provider.speed),
                const SizedBox(height: 20),
                InfoGrid(sensorData: provider.sensorData),
              ],
            ),
          ),
        );
      },
    );
  }
}