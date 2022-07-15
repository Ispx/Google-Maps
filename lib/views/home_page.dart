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
              return Stack(
                alignment: Alignment.topCenter,
                children: [
                  GoogleMap(
                    initialCameraPosition: value.initialCameraPosition,
                    onMapCreated: controller.changeMapsController,
                    markers: Set<Marker>.from(value.markers),
                    polylines: value.polylines,
                    onTap: controller.onTap,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                  ),
                  AddressesWidget(),
                ],
              );
            },
          ),
        ),
      ),
      floatingActionButton: SizedBox(
        height: 200,
        width: 60,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ZommButtomWidget(
              onPressed: () => controller.zoomIn(),
              icon: Icons.add,
            ),
            ZommButtomWidget(
              onPressed: () => controller.zommOut(),
              icon: Icons.remove,
            ),
            FloatingActionButton(
              onPressed: () => controller.getCurrentLocation(),
              child: Icon(
                Icons.location_on,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AddressesWidget extends StatefulWidget {
  const AddressesWidget({Key? key}) : super(key: key);

  @override
  State<AddressesWidget> createState() => _AddressesWidgetState();
}

class _AddressesWidgetState extends State<AddressesWidget> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height * .3,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.5),
      ),
      padding: EdgeInsets.symmetric(horizontal: 30),
      child: Column(
        children: const [
          SizedBox(height: 8),
          Text('Endereços'),
          SizedBox(height: 8),
          TextField(
            decoration: InputDecoration(
              hintText: 'Origem',
              border: OutlineInputBorder(),
            ),
          ),
          SizedBox(height: 8),
          TextField(
            decoration: InputDecoration(
              hintText: 'Destino',
              border: OutlineInputBorder(),
            ),
          ),
          SizedBox(height: 8),
          ElevatedButton(
            onPressed: null,
            child: Text('Confirmar'),
          )
        ],
      ),
    );
  }
}

class ZommButtomWidget extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  const ZommButtomWidget(
      {Key? key, required this.icon, required this.onPressed})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: Material(
        child: IconButton(
          onPressed: () => onPressed(),
          icon: Icon(icon),
        ),
      ),
    );
  }
}
