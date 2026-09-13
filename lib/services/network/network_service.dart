import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:network_info_plus/network_info_plus.dart';

class NetworkService {
  final NetworkInfo _networkInfo = NetworkInfo();

  /// Retrieve the best available local IPv4 address for hosting or connecting
  Future<String?> getLocalIpAddress() async {
    if (kIsWeb) {
      return '127.0.0.1';
    }

    try {
      // 1. First try network_info_plus (Wi-Fi IP)
      final wifiIp = await _networkInfo.getWifiIP();
      if (wifiIp != null &&
          wifiIp.isNotEmpty &&
          wifiIp != '0.0.0.0' &&
          wifiIp != '127.0.0.1') {
        return wifiIp;
      }
    } catch (_) {}

    try {
      // 2. Iterate network interfaces (covers Android Hotspot 192.168.43.1, LAN, tethering)
      final interfaces = await NetworkInterface.list(
        includeLoopback: false,
        type: InternetAddressType.IPv4,
      );

      // Prioritize hotspot and local private network subnets
      InternetAddress? bestAddress;

      for (final interface in interfaces) {
        for (final addr in interface.addresses) {
          final ip = addr.address;
          // Android Hotspot standard IP: 192.168.43.1
          if (ip.startsWith('192.168.43.')) {
            return ip;
          }
          if (ip.startsWith('192.168.') ||
              ip.startsWith('10.') ||
              ip.startsWith('172.')) {
            bestAddress ??= addr;
          }
        }
      }

      if (bestAddress != null) {
        return bestAddress.address;
      }

      // If any non-loopback interface exists
      for (final interface in interfaces) {
        if (interface.addresses.isNotEmpty) {
          return interface.addresses.first.address;
        }
      }
    } catch (_) {}

    return null;
  }

  /// Check if device is connected to a local network (Wi-Fi or Hotspot active)
  Future<bool> hasLocalNetwork() async {
    final ip = await getLocalIpAddress();
    return ip != null && ip.isNotEmpty;
  }
}
