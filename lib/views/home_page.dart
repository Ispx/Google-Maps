import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_routes/controllers/maps_controller.dart';
import 'package:google_maps_routes/utils/routers.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  late MapsController controller;
  TextEditingController addressOriginEditingController =
      TextEditingController();
  TextEditingController addressDestinationEditingController =
      TextEditingController();

  FocusNode focusNode = FocusNode();
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _changeSystemUiOverlay(SystemUiMode.leanBack);
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

  _changeSystemUiOverlay(SystemUiMode systemUiMode) {
    SystemChrome.setEnabledSystemUIMode(systemUiMode);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: SizedBox(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          child: ChangeNotifierProvider.value(
            value: controller,
            builder: (context, _) => Consumer<MapsController>(
              builder: (context, valueController, child) {
                if (valueController.isLoading) {
                  return Center(
                    child: CircularProgressIndicator(),
                  );
                }
                if (valueController.locationIsEnable == false) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Para utilizar os serviços do app é necessário ativar a localização do dispositovo',
                        textAlign: TextAlign.center,
                      ),
                      TextButton(
                        onPressed: () async =>
                            await valueController.onRequestPermission(),
                        child: Text('Ativar'),
                      )
                    ],
                  );
                }
                return Stack(
                  alignment: Alignment.topCenter,
                  children: [
                    GoogleMap(
                      initialCameraPosition:
                          valueController.initialCameraPosition,
                      onMapCreated: controller.changeMapsController,
                      markers: Set<Marker>.from(valueController.markers),
                      polylines: valueController.polylines,
                      // onTap: controller.onTap,
                      myLocationButtonEnabled: false,
                      zoomControlsEnabled: false,
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width * .85,
                        height: MediaQuery.of(context).size.height * .30,
                        child: Card(
                          color: Colors.grey.shade200,
                          margin: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Text(
                                  'Pesquisar',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                TextFieldWidget(
                                  controller: addressOriginEditingController,
                                  key: ValueKey('origin'),
                                  labelText: 'Origem',
                                  hintText: 'Pesquisar endereço de início',
                                  suffixIcon: IconButton(
                                    onPressed: () async {
                                      Position myPosition =
                                          await valueController
                                              .currentPosition();
                                      Placemark placemark =
                                          (await placemarkFromCoordinates(
                                        myPosition.latitude,
                                        myPosition.longitude,
                                        localeIdentifier: 'pt_BR',
                                      ))
                                              .first;
                                      valueController.setPlaceAddressOrigin(
                                        placemark,
                                        Location(
                                          latitude: myPosition.latitude,
                                          longitude: myPosition.longitude,
                                          timestamp: myPosition.timestamp ??
                                              DateTime.now(),
                                        ),
                                      );
                                      addressOriginEditingController.text =
                                          valueController.addressOrigin;
                                    },
                                    icon: Icon(
                                      Icons.location_searching,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  onTap: () async {
                                    var result = await Navigator.pushNamed(
                                      context,
                                      Routes.SEARCH_ADDRESS,
                                      arguments: 'Pesquisar endereço de início',
                                    );
                                    if (result != null) {
                                      valueController
                                          .setPlaceAddressOriginFromSearch(
                                              result as Placemark);
                                      addressOriginEditingController.text =
                                          valueController.addressOrigin;
                                    }
                                  },
                                ),
                                TextFieldWidget(
                                  controller:
                                      addressDestinationEditingController,
                                  key: ValueKey('destination'),
                                  labelText: 'Destino',
                                  hintText: 'Pesquisar endereço de destino',
                                  onTap: () async {
                                    var result = await Navigator.pushNamed(
                                      context,
                                      Routes.SEARCH_ADDRESS,
                                      arguments:
                                          'Pesquisar endereço de destino',
                                    );
                                    if (result != null) {
                                      valueController
                                          .setPlaceAddressDestinationFromSearch(
                                              result as Placemark);
                                      addressDestinationEditingController.text =
                                          valueController.addressDestination;
                                    }
                                  },
                                ),
                                SizedBox(
                                  width: double.maxFinite,
                                  child: ElevatedButton(
                                    style: ButtonStyle(
                                      shape: MaterialStateProperty.resolveWith(
                                        (states) => RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                      ),
                                    ),
                                    onPressed: addressOriginEditingController
                                                .text.isNotEmpty &&
                                            addressDestinationEditingController
                                                .text.isNotEmpty
                                        ? () async => await valueController
                                            .onConfirmRouters()
                                        : null,
                                    child: Text('Confirmar'),
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
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
      ),
    );
  }
}

class ListAddressWidget extends StatelessWidget {
  final List<Placemark> address;
  final Function(Placemark e) onSelected;
  const ListAddressWidget(
      {Key? key, required this.address, required this.onSelected})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height,
      width: MediaQuery.of(context).size.width,
      child: SingleChildScrollView(
        child: Column(
          children: [
            ...address.map(
              (e) => InkWell(
                onTap: () {
                  onSelected(e);
                },
                child: Column(
                  children: [
                    AddressWidget(address: e),
                    Divider(),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class AddressWidget extends StatelessWidget {
  final Placemark address;
  const AddressWidget({Key? key, required this.address}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: ListTile(
        title: Text(
          "${address.street}, ${address.subThoroughfare}, ${address.subLocality}, CEP: ${address.postalCode} - ${address.subAdministrativeArea}/${address.administrativeArea}",
        ),
      ),
    );
  }
}

class TextFieldWidget extends StatelessWidget {
  final TextEditingController? controller;
  final String? hintText;
  final String? labelText;
  final Widget? suffixIcon;
  final Function(String? e)? onChange;
  final VoidCallback? onTap;
  const TextFieldWidget({
    Key? key,
    this.controller,
    this.hintText,
    this.labelText,
    this.onChange,
    this.suffixIcon,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: TextField(
        controller: controller,
        onChanged: onChange,
        onTap: onTap,
        style: TextStyle(fontSize: 12),
        decoration: InputDecoration(
          hintText: hintText,
          labelText: labelText,
          suffixIcon: suffixIcon,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(width: 2, color: Colors.green.shade300),
          ),
        ),
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
