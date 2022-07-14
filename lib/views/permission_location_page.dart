import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_maps_routes/controllers/permission_controller.dart';
import 'package:google_maps_routes/main.dart';
import 'package:permission_handler/permission_handler.dart';

import '../utils/routers.dart';

class PermissionLocationPage extends StatefulWidget {
  const PermissionLocationPage({Key? key}) : super(key: key);

  @override
  State<PermissionLocationPage> createState() => _PermissionLocationPageState();
}

class _PermissionLocationPageState extends State<PermissionLocationPage>
    with WidgetsBindingObserver {
  final controller = PermissionController(Permission.locationWhenInUse);
  bool hasOpenSettings = false;
  void goToHome() {
    navigatorKey.currentState!.pushNamed(Routes.HOME);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed && hasOpenSettings) {
      if (await checkPermissionLocationIsGranted()) {
        goToHome();
        return;
      }
      showDialogAccessLocationPermission();
    }
  }

  Future<bool> checkPermissionLocationIsGranted() async {
    return (await Permission.location.status) == PermissionStatus.granted;
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    hasOpenSettings = false;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    controller.permissionStatus.stream.listen(
      (status) async {
        switch (status) {
          case PermissionStatus.granted:
            goToHome();
            break;
          case PermissionStatus.denied:
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content:
                    Text('Necessário conceder acesso a localização do app.'),
              ),
            );
            break;
          case PermissionStatus.permanentlyDenied:
            await showDialogAccessLocationPermission();
            break;
          default:
        }
      },
    );
  }

  showDialogAccessLocationPermission() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Permissão de acesso'),
        content: Text(
          'Para utilizar os serviços do app é necessário conceder acesso a localização',
        ),
        actions: [
          TextButton(
            onPressed: () => exit(0),
            child: Text('Sair do app'),
          ),
          TextButton(
            onPressed: () async {
              hasOpenSettings = await openAppSettings();
            },
            child: Text('Ativar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        body: SizedBox(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text('Ative a permissão de localização'),
              TextButton(
                onPressed: () async => await controller.onRequest(),
                child: Text('Ativar'),
              )
            ],
          ),
        ),
      ),
    );
  }
}
