import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/network/network_service.dart';

final networkServiceProvider = Provider<NetworkService>((ref) {
  return NetworkService();
});

final localIpProvider = FutureProvider.autoDispose<String?>((ref) async {
  final service = ref.watch(networkServiceProvider);
  return service.getLocalIpAddress();
});
