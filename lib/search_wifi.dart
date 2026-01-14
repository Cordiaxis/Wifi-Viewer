import 'dart:io';
import 'package:xml/xml.dart';

class WifiNetwork {
  final String ssid;
  final String password;
  final String securityType;
  final bool isHidden;

  WifiNetwork({
    required this.ssid,
    required this.password,
    this.securityType = 'WPA/WPA2',
    this.isHidden = false,
  });

  @override
  String toString() =>
      'SSID: $ssid, Password: $password, Security: $securityType, Hidden: $isHidden';
}

class WifiPasswordExtractor {
  static const _locations = [
    '/data/misc/apexdata/com.android.wifi/WifiConfigStore.xml',
    '/data/misc/wifi/WifiConfigStore.xml',
    '/data/misc/wifi/wpa_supplicant.conf',
  ];

  Future<List<WifiNetwork>> extractWifiPasswords() async {
    for (final location in _locations) {
      try {
        final content = await _readFile(location);

        if (content != null && content.isNotEmpty) {
          if (location.endsWith('.xml')) {
            return _parseXml(content);
          } else {
            return _parseConf(content);
          }
        }
      } catch (e) {
        print('Error en $location: $e');
        continue;
      }
    }

    throw Exception('No se encontró ningún archivo de configuración WiFi');
  }

  Future<String?> _readFile(String path) async {
    final result = await Process.run('su', ['-c', 'cat $path']);

    if (result.exitCode == 0) {
      final content = result.stdout.toString();
      return content.isNotEmpty ? content : null;
    }

    return null;
  }

  List<WifiNetwork> _parseXml(String content) {
    final networks = <WifiNetwork>[];

    try {
      final document = XmlDocument.parse(content);

      final networkElements = document.findAllElements('Network');

      for (final network in networkElements) {
        String? ssid;
        String? password;
        String securityType = 'Open';
        bool isHidden = false;

        final wifiConfig = network
            .findElements('WifiConfiguration')
            .firstOrNull;
        if (wifiConfig == null) continue;

        // Extraer SSID
        final ssidElement = wifiConfig
            .findElements('string')
            .firstWhere(
              (element) => element.getAttribute('name') == 'SSID',
              orElse: () => XmlElement(XmlName('string')),
            );

        if (ssidElement.innerText.isNotEmpty) {
          ssid = ssidElement.innerText.replaceAll('"', '');
        }

        // Extraer Password (PreSharedKey)
        final pskElement = wifiConfig
            .findElements('string')
            .firstWhere(
              (element) => element.getAttribute('name') == 'PreSharedKey',
              orElse: () => XmlElement(XmlName('string')),
            );

        if (pskElement.innerText.isNotEmpty) {
          password = pskElement.innerText.replaceAll('"', '');
        }

        // Detectar si está oculta (HiddenSSID)
        final hiddenElement = wifiConfig
            .findElements('boolean')
            .firstWhere(
              (element) => element.getAttribute('name') == 'HiddenSSID',
              orElse: () => XmlElement(XmlName('boolean')),
            );

        if (hiddenElement.getAttribute('value') == 'true') {
          isHidden = true;
        }

        // Detectar tipo de seguridad
        final allowedKeyMgmt = wifiConfig
            .findElements('string')
            .firstWhere(
              (element) => element.getAttribute('name') == 'AllowedKeyMgmt',
              orElse: () => XmlElement(XmlName('string')),
            );

        if (allowedKeyMgmt.innerText.isNotEmpty) {
          securityType = _parseSecurityType(allowedKeyMgmt.innerText);
        } else if (password != null && password.isNotEmpty) {
          securityType = 'WPA/WPA2';
        }

        if (ssid != null && password != null && password.isNotEmpty) {
          networks.add(
            WifiNetwork(
              ssid: ssid,
              password: password,
              securityType: securityType,
              isHidden: isHidden,
            ),
          );
        }
      }
    } catch (e) {
      print('Error parseando XML: $e');
    }

    return networks;
  }

  List<WifiNetwork> _parseConf(String content) {
    final networks = <WifiNetwork>[];

    try {
      final networkBlocks = content.split('network=');

      for (final block in networkBlocks) {
        if (!block.contains('ssid')) continue;

        String? ssid;
        String? password;
        String securityType = 'Open';
        bool isHidden = false;

        final lines = block.split('\n');
        for (final line in lines) {
          final trimmed = line.trim();

          if (trimmed.startsWith('ssid=')) {
            ssid = trimmed.substring(5).replaceAll('"', '').trim();
          } else if (trimmed.startsWith('psk=')) {
            password = trimmed.substring(4).replaceAll('"', '').trim();
            securityType = 'WPA/WPA2';
          } else if (trimmed.startsWith('wep_key0=')) {
            password = trimmed.substring(9).replaceAll('"', '').trim();
            securityType = 'WEP';
          } else if (trimmed.startsWith('key_mgmt=')) {
            final keyMgmt = trimmed.substring(9).trim();
            securityType = _parseSecurityType(keyMgmt);
          } else if (trimmed.startsWith('scan_ssid=1')) {
            isHidden = true;
          }
        }

        if (ssid != null && password != null && password.isNotEmpty) {
          networks.add(
            WifiNetwork(
              ssid: ssid,
              password: password,
              securityType: securityType,
              isHidden: isHidden,
            ),
          );
        }
      }
    } catch (e) {
      print('Error parseando CONF: $e');
    }

    return networks;
  }

  String _parseSecurityType(String keyMgmt) {
    final lower = keyMgmt.toLowerCase();

    if (lower.contains('sae')) {
      return 'WPA3';
    } else if (lower.contains('wpa2')) {
      return 'WPA2';
    } else if (lower.contains('wpa')) {
      return 'WPA/WPA2';
    } else if (lower.contains('wep')) {
      return 'WEP';
    } else if (lower.contains('none') || lower.isEmpty) {
      return 'Open';
    }

    return 'WPA/WPA2'; // Default
  }
}
