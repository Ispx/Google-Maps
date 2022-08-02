import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_routes/helpers/collections_helper.dart';
import 'package:google_maps_routes/helpers/image_to_bytes.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_routes/helpers/router_status_helper.dart';
import 'package:maps_launcher/maps_launcher.dart';
import '../helpers/search_router_state_helper.dart';
import '../utils/map_style_util.dart';

class MapsController extends ChangeNotifier {
  factory MapsController() => _instance;
  static final MapsController _instance = MapsController._();
  MapsController._() {
    _initController();
    _onListenLocationSearchStream();
    _onListenSearchStream();
  }
  Completer<BitmapDescriptor> iconBitMap = Completer<BitmapDescriptor>();
  GoogleMapController? mapController;
  late LocationSettings locationSettings;
  late CameraPosition initialCameraPosition;
  Position? lastPosition;
  Set<Marker> markers = <Marker>{};
  Set<Polyline> polylines = <Polyline>{};
  PolylinePoints polylinePoints = PolylinePoints();
  List<LatLng> polylineCoordinates = [];
  SearchRouterStateHelper searchRouteState = SearchRouterStateHelper.INIT;
  bool isLoading = false;
  late bool locationIsEnable;
  Map<Location, List<Placemark>> mapLocationPlaceMark = {};
  Map<Location?, Placemark?>? _placeAddressOrigin = {};
  Map<Location?, Placemark?>? _placeAddressDestination = {};
  Location? get locationOrigin => _placeAddressOrigin?.keys.first;
  Location? get locationDestination => _placeAddressDestination?.keys.first;
  Placemark? get placeMarkOrigin => _placeAddressOrigin?.values.first;
  Placemark? get placeMarkDestination => _placeAddressDestination?.values.first;
  StreamController<List<Location>> streamLocationSearchController =
      StreamController();
  StreamController<MapEntry<Location, Set<Placemark>>> streamSearchController =
      StreamController();
  Stream<Map<Location, List<Placemark>>> get streamSearch =>
      streamSearchController.stream
          .map((event) => {event.key: event.value.toList()});
  StreamController streamOnUpdateMyPositionInFirebase = StreamController();
  String get addressOrigin => _placeAddressOrigin != null
      ? "${_placeAddressOrigin?.values.first?.street}, ${_placeAddressOrigin?.values.first?.subThoroughfare}, ${_placeAddressOrigin?.values.first?.subLocality}, CEP: ${_placeAddressOrigin?.values.first?.postalCode} - ${_placeAddressOrigin?.values.first?.subAdministrativeArea}/${_placeAddressOrigin?.values.first?.administrativeArea}"
      : '';
  String get addressDestination => _placeAddressDestination != null
      ? "${_placeAddressDestination?.values.first?.street}, ${_placeAddressDestination?.values.first?.subThoroughfare}, ${_placeAddressDestination?.values.first?.subLocality}, CEP: ${_placeAddressDestination?.values.first?.postalCode} - ${_placeAddressDestination?.values.first?.subAdministrativeArea}/${_placeAddressDestination?.values.first?.administrativeArea}"
      : '';
  List<Placemark> get placemarks => mapLocationPlaceMark.values.single;

  Future<bool> _updateMyPositionInFirebase(Position myPosition) async {
    try {
      await FirebaseFirestore.instance
          .collection(CollectionsHelper.IN_ROUTER.getString)
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .update(
        {
          "current-position": myPosition.toJson(),
        },
      );
      return true;
    } catch (e) {
      debugPrint(e.toString());
      return false;
    }
  }

  _changeRouterState(SearchRouterStateHelper state) {
    searchRouteState = state;
    notifyListeners();
  }

  changeMarkerOriginAddress() {
    _removeMarkerByIds('origin-address-marker');
    markers.add(
      Marker(
        markerId: MarkerId('origin-address-marker'),
        position: LatLng(_placeAddressOrigin?.keys.first?.latitude ?? 0.0,
            _placeAddressOrigin?.keys.first?.longitude ?? 0.0),
        infoWindow: InfoWindow(
          title: 'Origem',
          snippet: addressOrigin,
        ),
      ),
    );
    notifyListeners();
  }

  _changeMarkerDestinationAddress() {
    _removeMarkerByIds('destination-address-marker');
    markers.add(
      Marker(
        markerId: MarkerId('destination-address-marker'),
        position: LatLng(_placeAddressDestination?.keys.first?.latitude ?? 0.0,
            _placeAddressDestination?.keys.first?.longitude ?? 0.0),
        infoWindow: InfoWindow(
          title: 'Destino',
          snippet: addressDestination,
        ),
        icon: BitmapDescriptor.defaultMarker,
      ),
    );
    notifyListeners();
  }

  changeLocationServiceIsEnable(bool isTrue) {
    locationIsEnable = isTrue;
    notifyListeners();
  }

  Future<void> changePolylines({
    required LatLng latLng1,
    required LatLng latLng2,
  }) async {
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      'AIzaSyDhSFZrpQ6qz4Ssbzj61mdAd7LaGJ1_dgk',
      PointLatLng(
        latLng1.latitude,
        latLng1.longitude,
      ),
      PointLatLng(
        latLng2.latitude,
        latLng2.longitude,
      ),
      travelMode: TravelMode.transit,
    );
    for (var point in result.points) {
      polylineCoordinates.add(LatLng(point.latitude, point.longitude));
    }
    _removePolylinesByIds("origin-and-destination-coordenates");
    Polyline polyline = Polyline(
      polylineId: PolylineId("origin-and-destination-coordenates"),
      color: Colors.blue,
      jointType: JointType.bevel,
      points: [...polylineCoordinates],
    );
    polylines.add(polyline);
    _animatedCameraToLatings(latLng1, latLng2, 120);
  }

  changeMapsController(GoogleMapController controller) async {
    controller.setMapStyle(jsonEncode(mapStyleUtil));
    mapController = controller;
    notifyListeners();
  }

  setPlaceAddressDestination(Placemark address, Location location) {
    _placeAddressDestination = {};
    _placeAddressDestination?.addAll({location: address});
    notifyListeners();
  }

  setPlaceAddressOrigin(Placemark address, Location location) {
    _placeAddressOrigin = {};
    _placeAddressOrigin?.addAll({location: address});
    notifyListeners();
  }

  setPlaceAddressOriginFromSearch(Placemark address) {
    _placeAddressOrigin = {};
    var location = mapLocationPlaceMark.entries
        .where((element) =>
            element.value.map((e) => e.postalCode).contains(address.postalCode))
        .first
        .key;
    _placeAddressOrigin?.addAll({location: address});
    _clearAddressSearchMemoryStore();
    notifyListeners();
  }

  setPlaceAddressDestinationFromSearch(Placemark address) {
    _placeAddressDestination = {};
    var location = mapLocationPlaceMark.entries
        .where((element) =>
            element.value.map((e) => e.postalCode).contains(address.postalCode))
        .first
        .key;
    _placeAddressDestination?.addAll({location: address});
    _clearAddressSearchMemoryStore();
    notifyListeners();
  }

  _changeLoading(bool isLoading) {
    this.isLoading = isLoading;
    notifyListeners();
  }

  void zoomIn() {
    mapController!.animateCamera(CameraUpdate.zoomIn());
    notifyListeners();
  }

  void zommOut() {
    mapController!.animateCamera(CameraUpdate.zoomOut());
    notifyListeners();
  }

  Future<void> newCameraPosition(LatLng latLng) async {
    mapController!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: latLng,
          zoom: await mapController!.getZoomLevel(),
        ),
      ),
    );
    notifyListeners();
  }

  _clearAddressSearchMemoryStore() {
    mapLocationPlaceMark = {};
  }

  Future<Position> currentPosition() async {
    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  }

  Future<void> searhAddress(String address) async {
    _changeRouterState(SearchRouterStateHelper.SEARCHING);
    try {
      streamLocationSearchController.sink
          .add(await locationFromAddress(address, localeIdentifier: 'pt_BR'));
    } catch (e) {
      print(e.toString());
    } finally {
      _changeRouterState(SearchRouterStateHelper.INIT);
      notifyListeners();
    }
  }

  _changeMyMarkerPosition(
    LatLng latLng,
  ) async {
    double rotation = 0;
    if (lastPosition != null) {
      rotation = Geolocator.bearingBetween(
        lastPosition!.latitude,
        lastPosition!.longitude,
        latLng.latitude,
        latLng.longitude,
      );
    }
    _removeMarkerByIds('my-marker-position');
    Marker marker = Marker(
      markerId: MarkerId('my-marker-position'),
      icon: await iconBitMap.future,
      anchor: Offset(0.5, 0.5),
      position: latLng,
      rotation: rotation,
    );
    markers.add(marker);
  }

  setMarkerPosition(LatLng latLng) async {
    markers
        .removeWhere((element) => element.markerId.value == 'marker-position');
    Marker marker = Marker(
      markerId: MarkerId('marker-position'),
      icon: BitmapDescriptor.defaultMarker,
      position: latLng,
    );
    markers.add(marker);
  }

  _animatedCameraToLatings(
      LatLng fromLocationLatLng, LatLng toLocationLatLng, double zoom) {
    final cameraUpdate = CameraUpdate.newLatLngBounds(
      LatLngBounds(
        southwest: LatLng(
          fromLocationLatLng.latitude <= toLocationLatLng.latitude
              ? fromLocationLatLng.latitude
              : toLocationLatLng.latitude,
          fromLocationLatLng.longitude <= toLocationLatLng.longitude
              ? fromLocationLatLng.longitude
              : toLocationLatLng.longitude,
        ),
        northeast: LatLng(
          fromLocationLatLng.latitude <= toLocationLatLng.latitude
              ? toLocationLatLng.latitude
              : fromLocationLatLng.latitude,
          fromLocationLatLng.longitude <= toLocationLatLng.longitude
              ? toLocationLatLng.longitude
              : fromLocationLatLng.longitude,
        ),
      ),
      zoom,
    );
    mapController!.animateCamera(cameraUpdate);
    notifyListeners();
  }

  _animatedCameraAndMyMarkerPosition(LatLng latLng) {
    _changeMyMarkerPosition(latLng);
    if (mapController != null) {
      final cameraUpdate = CameraUpdate.newLatLngZoom(
        latLng,
        25,
      );
      mapController!.animateCamera(cameraUpdate);
      notifyListeners();
    }
  }

  onInitRouter() async {
    try {
      await MapsLauncher.launchQuery(addressDestination);
    } catch (e) {
      print(e.toString());
    }
  }

  closeStreams() {
    streamLocationSearchController.close();
    streamSearchController.close();
  }

  Future<void> _registerRouterInFirebase(
      {required LatLng origin, required LatLng destination}) async {
    await FirebaseFirestore.instance
        .collection(CollectionsHelper.IN_ROUTER.getString)
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .set(
      {
        "userId": FirebaseAuth.instance.currentUser!.uid,
        "name": FirebaseAuth.instance.currentUser?.displayName,
        "email": FirebaseAuth.instance.currentUser?.email,
        "origin": {
          "lating": origin.toJson(),
          "street": addressOrigin,
        },
        "destination": {
          "lating": destination.toJson(),
          "street": addressDestination,
        },
        "polylines": [...polylineCoordinates],
        "status": RouterStatusHelper.ONGOING.getString,
        "createdAt": DateTime.now(),
      },
    );
  }

  onConfirmRouters() async {
    _changeRouterState(SearchRouterStateHelper.SEARCHING);
    await _registerRouterInFirebase(
      origin: LatLng(
        locationOrigin!.latitude,
        locationOrigin!.longitude,
      ),
      destination: LatLng(
        locationDestination!.latitude,
        locationDestination!.longitude,
      ),
    );
    await changePolylines(
      latLng1: LatLng(
        locationOrigin!.latitude,
        locationOrigin!.longitude,
      ),
      latLng2: LatLng(
        locationDestination!.latitude,
        locationDestination!.longitude,
      ),
    );
    _changeMarkerDestinationAddress();
    _changeRouterState(SearchRouterStateHelper.DONE);
  }

  onTap(LatLng latLng) async {
    setMarkerPosition(latLng);
    await newCameraPosition(latLng);
    notifyListeners();
  }

  onRequestPermission() async {
    try {
      final permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse) {
        final position = await Geolocator.getCurrentPosition();
        _animatedCameraAndMyMarkerPosition(
            LatLng(position.latitude, position.longitude));
        changeLocationServiceIsEnable(true);
      }
    } on PermissionDefinitionsNotFoundException catch (e) {
      changeLocationServiceIsEnable(false);
      print(e);
    }
  }

  _removeMarkerByIds(String id) {
    markers.removeWhere((element) => element.mapsId.value == id);
    notifyListeners();
  }

  _removePolylinesByIds(String id) {
    polylines.removeWhere((element) => element.polylineId.value == id);
    notifyListeners();
  }

  void getCurrentLocation() async {
    final position = await Geolocator.getCurrentPosition();
    await _animatedCameraAndMyMarkerPosition(
      LatLng(position.latitude, position.longitude),
    );
  }

  _initController() async {
    _changeLoading(true);
    changeLocationServiceIsEnable(
        (await Geolocator.isLocationServiceEnabled()));
    var imageInBytes = await imageToBytes(
      'assets/images/cargo_truck.png', // 'assets/images/cargo_truck.png',
      targetHeight: 60,
      targetWidth: 60,
      //fromNetwork: true,
    ); //'https://cdn-icons-png.flaticon.com/512/713/713311.png'
    iconBitMap.complete(BitmapDescriptor.fromBytes(imageInBytes));
    await _initCameraPosition();
    await _initLocationSettings();
    _changeLoading(false);
    listenPosition();
    listenLocationService();
  }

  Future<void> _initCameraPosition() async {
    Position position;
    if (locationIsEnable) {
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: Duration(milliseconds: 10000),
        );
      } catch (e) {
        position = await Geolocator.getLastKnownPosition() ??
            Position(
              longitude: 0,
              latitude: 0,
              timestamp: DateTime.now(),
              accuracy: 0,
              altitude: 0,
              heading: 0,
              speed: 0,
              speedAccuracy: 0,
            );
      }

      initialCameraPosition = CameraPosition(
        target: LatLng(position.latitude, position.longitude),
        zoom: 25,
      );
    } else {
      position = (await Geolocator.getLastKnownPosition()) ??
          Position(
            longitude: 0,
            latitude: 0,
            timestamp: DateTime.now(),
            accuracy: 0,
            altitude: 0,
            heading: 0,
            speed: 0,
            speedAccuracy: 0,
          );
      initialCameraPosition = CameraPosition(
        target: LatLng(position.latitude, position.longitude),
        zoom: 25,
      );
    }

    _animatedCameraAndMyMarkerPosition(
      LatLng(position.latitude, position.longitude),
    );
  }

  Future<void> _initLocationSettings() async {
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        locationSettings = AndroidSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 50,
          forceLocationManager: true,
          intervalDuration: const Duration(seconds: 10),
          //(Optional) Set foreground notification config to keep the app alive
          //when going to the background
          foregroundNotificationConfig: const ForegroundNotificationConfig(
            notificationText:
                "Example app will continue to receive your location even when you aren't using it",
            notificationTitle: "Rodando em Background",
            enableWakeLock: true,
          ),
        );
      } else if (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS) {
        locationSettings = AppleSettings(
          accuracy: LocationAccuracy.high,
          activityType: ActivityType.fitness,
          distanceFilter: 50,
          pauseLocationUpdatesAutomatically: true,
          // Only set to true if our app will be started up in the background.
          showBackgroundLocationIndicator: false,
        );
      } else {
        locationSettings = LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 100,
        );
      }
    } catch (e) {
      print(e.toString());
    }
  }

  listenPosition() {
    Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen(
      (Position? position) async {
        lastPosition = position;
        if (position != null) {
          _animatedCameraAndMyMarkerPosition(
            LatLng(position.latitude, position.longitude),
          );
        }
        streamOnUpdateMyPositionInFirebase.sink.add(
          await _updateMyPositionInFirebase(position!),
        );
      },
    );
  }

  listenLocationService() {
    Geolocator.getServiceStatusStream().listen(
      (status) => changeLocationServiceIsEnable(
        status == ServiceStatus.enabled,
      ),
    );
  }

  _onListenSearchStream() {
    streamSearch.listen(
      (data) async {
        mapLocationPlaceMark.clear();
        mapLocationPlaceMark.addAll(data);
        notifyListeners();
      },
    ).onError((e) {
      print(e.toString());
    });
  }

  _onListenLocationSearchStream() {
    streamLocationSearchController.stream.listen(
      (locations) async {
        for (var location in locations) {
          streamSearchController.sink.add(
            MapEntry(
              location,
              (await placemarkFromCoordinates(
                location.latitude,
                location.longitude,
                localeIdentifier: 'pt_BR',
              ))
                  .toSet(),
            ),
          );
        }
        notifyListeners();
      },
    ).onError((e) {
      print(e.toString());
    });
  }
}
