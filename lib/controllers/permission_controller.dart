import 'dart:async';
import 'package:google_maps_routes/main.dart';
import 'package:google_maps_routes/utils/routers.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionController {
  Permission permission;
  StreamController<PermissionStatus> permissionStatus =
      StreamController<PermissionStatus>();
  PermissionController(this.permission);

  init() async {
    var status = await permission.status;
    _onChageStatus(status);
    if (status.isGranted) {
      navigatorKey.currentState!.pushNamed(Routes.HOME);
    }
  }

  onRequest() async {
    var status = await permission.request();
    _onChageStatus(status);
  }

  _onChageStatus(PermissionStatus status) {
    permissionStatus.sink.add(status);
  }
}
