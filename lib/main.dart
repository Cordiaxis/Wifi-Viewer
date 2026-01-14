import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:safe_device/safe_device.dart';
import 'package:safe_device/safe_device_config.dart';
import 'package:wifiviewer/search_wifi.dart';

bool isRooted = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await init();

  runApp(
    MaterialApp(home: WifiListScreen(), debugShowCheckedModeBanner: false),
  );
}

Future<void> init() async {
  try {
    SafeDevice.init(SafeDeviceConfig(mockLocationCheckEnabled: false));

    Map<String, dynamic> rootDetails = await SafeDevice.rootDetectionDetails;

    isRooted = rootDetails['isRooted'];
  } catch (e) {
    print('Error detectando ROOT: $e');
    isRooted = false;
  }
}

class WifiListScreen extends StatefulWidget {
  const WifiListScreen({super.key});

  @override
  State<WifiListScreen> createState() => _WifiListScreenState();
}

class _WifiListScreenState extends State<WifiListScreen> {
  List<WifiNetwork> _networks = [];
  bool _isLoading = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _loadWifiNetworks();
  }

  Future<void> _loadWifiNetworks() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final extractor = WifiPasswordExtractor();
      final networks = await extractor.extractWifiPasswords();

      setState(() {
        _networks = networks;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!isRooted) {
      return Scaffold(
        appBar: AppBar(
          title: Text('WiFi Passwords'),
          backgroundColor: Colors.red,
        ),
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.warning_amber_rounded, size: 80, color: Colors.red),
                SizedBox(height: 24),
                Text(
                  'ROOT Requerido',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),
                Text(
                  'Esta aplicacion requiere acceso ROOT para funcionar.',
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Text(
                  'Por favor, rootea tu dispositivo e intenta nuevamente.',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () async {
                    await init();
                    setState(() {});
                  },
                  icon: Icon(Icons.refresh),
                  label: Text('Reintentar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('WiFi Passwords'),
        actions: [
          IconButton(icon: Icon(Icons.refresh), onPressed: _loadWifiNetworks),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, size: 64, color: Colors.red),
            SizedBox(height: 16),
            Text('Error: $_error'),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadWifiNetworks,
              child: Text('Reintentar'),
            ),
          ],
        ),
      );
    }
    if (_networks.isEmpty) {
      return Center(child: Text('No se encontraron redes WiFi'));
    }
    return ListView.builder(
      itemCount: _networks.length,
      itemBuilder: (context, index) {
        final network = _networks[index];
        return Card(
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: Icon(
              network.isHidden ? Icons.wifi_lock : Icons.wifi,
              size: 32,
              color: network.securityType == 'Open'
                  ? Colors.orange
                  : Colors.green,
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    network.ssid,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                if (network.isHidden)
                  Icon(Icons.visibility_off, size: 16, color: Colors.grey),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(network.password),
                SizedBox(height: 4),
                Text(
                  network.securityType,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            isThreeLine: true,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.qr_code),
                  onPressed: () => _showQrCode(network),
                ),
                IconButton(
                  icon: Icon(Icons.copy),
                  onPressed: () => _copyPassword(network.password),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showQrCode(WifiNetwork network) {
    String qrSecurityType = 'WPA';
    if (network.securityType.contains('WPA')) {
      qrSecurityType = 'WPA';
    } else if (network.securityType == 'WEP') {
      qrSecurityType = 'WEP';
    } else if (network.securityType == 'Open') {
      qrSecurityType = 'nopass';
    }

    var qrcontent =
        "WIFI:T:$qrSecurityType;S:${network.ssid};P:${network.password};;";
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('QR Code', textAlign: TextAlign.center),
            SizedBox(height: 4),
            Text(
              network.ssid,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        content: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 300, minWidth: 200),
          child: IntrinsicHeight(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 200,
                  height: 200,
                  child: QrImageView(data: qrcontent, version: QrVersions.auto),
                ),
                SizedBox(height: 10),
                Text(
                  "Contraseña: ${network.password}",
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            child: Text('Cerrar'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _copyPassword(String password) {
    Clipboard.setData(ClipboardData(text: password));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Contraseña copiada')));
  }
}
