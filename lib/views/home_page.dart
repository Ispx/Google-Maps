import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_routes/controllers/maps_controller.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  late MapsController controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    controller = MapsController();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed &&
        controller.locationIsEnable == false) {
      controller.changeLocationServiceIsEnable(
        await Geolocator.isLocationServiceEnabled(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          'Home',
        ),
      ),
      body: SizedBox(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        child: ChangeNotifierProvider.value(
          value: controller,
          builder: (context, _) => Consumer<MapsController>(
            builder: (context, value, child) {
              if (value.isLoadingInit) {
                return Center(
                  child: CircularProgressIndicator(),
                );
              }
              if (value.locationIsEnable == false) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Para utilizar os serviços do app é necessário ativar a localização do dispositovo',
                      textAlign: TextAlign.center,
                    ),
                    TextButton(
                      onPressed: () async => await value.onRequestPermission(),
                      child: Text('Ativar'),
                    )
                  ],
                );
              }
              return GoogleMap(
                initialCameraPosition: value.initialCameraPosition,
                onMapCreated: controller.changeMapsController,
                markers: value.markers,
                polylines: value.polylines,
                onTap: controller.onTap,
                myLocationButtonEnabled: true,
              );
            },
          ),
        ),
      ),
    );
  }
}
