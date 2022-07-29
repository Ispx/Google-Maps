import 'package:flutter/material.dart';
import 'package:google_maps_routes/controllers/permission_controller.dart';
import 'package:permission_handler/permission_handler.dart';

import '../main.dart';
import '../utils/routers.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({Key? key}) : super(key: key);

  @override
  State<SplashPage> createState() => _SpashPageState();
}

class _SpashPageState extends State<SplashPage> {
  late final PermissionController permissionController;
  @override
  void initState() {
    super.initState();
    permissionController = PermissionController(Permission.locationWhenInUse);

    Future.delayed(Duration(seconds: 3)).then(
      (e) async {
        permissionController.init();
      },
    );
    permissionController.permissionStatus.stream.listen(
      (event) {
        if (event.isGranted == false) {
          navigatorKey.currentState!.pushNamedAndRemoveUntil(
              '${Routes.PERMISSION}/location', (e) => false);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        color: Colors.blueAccent,
        child: Center(
          child: Icon(
            Icons.location_on,
            size: 60,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
