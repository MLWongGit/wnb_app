import 'package:connectivity_plus/connectivity_plus.dart';

class WifiChecker {
  static Future<bool> isNetworkConnected() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult == ConnectivityResult.wifi ||
           connectivityResult == ConnectivityResult.mobile;
  }
}