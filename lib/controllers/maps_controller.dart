import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_routes/helpers/image_to_bytes.dart';
import 'package:geocoding/geocoding.dart';

import '../utils/map_style_util.dart';

class MapsController extends ChangeNotifier {
  factory MapsController() => _instance;
  static final MapsController _instance = MapsController._();
  MapsController._() {
    _initController();
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

  bool isLoading = false;
  late bool locationIsEnable;
  bool isLoadingAddresses = false;
  Map<Location, List<Placemark>> mapLocationPlaceMark = {};
  Set<Placemark> addressesPlaceMarks = {};
  Map<Location?, Placemark?>? _placeAddressOrigin = {};
  Map<Location?, Placemark?>? _placeAddressDestination = {};
  Location? get locationOrigin => _placeAddressOrigin?.keys.first;
  Location? get locationDestination => _placeAddressDestination?.keys.first;
  Placemark? get placeMarkOrigin => _placeAddressOrigin?.values.first;
  Placemark? get placeMarkDestination => _placeAddressDestination?.values.first;

  String get addressOrigin => _placeAddressOrigin != null
      ? "${_placeAddressOrigin?.values.first?.street}, ${_placeAddressOrigin?.values.first?.subThoroughfare}, ${_placeAddressOrigin?.values.first?.subLocality}, CEP: ${_placeAddressOrigin?.values.first?.postalCode} - ${_placeAddressOrigin?.values.first?.subAdministrativeArea}/${_placeAddressOrigin?.values.first?.administrativeArea}}"
      : '';
  String get addressDestination => _placeAddressDestination != null
      ? "${_placeAddressDestination?.values.first?.street}, ${_placeAddressDestination?.values.first?.subThoroughfare}, ${_placeAddressDestination?.values.first?.subLocality}, CEP: ${_placeAddressDestination?.values.first?.postalCode} - ${_placeAddressDestination?.values.first?.subAdministrativeArea}/${_placeAddressDestination?.values.first?.administrativeArea}}"
      : '';

  listenPosition() {
    Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen(
      (Position? position) {
        lastPosition = position;
        if (position != null) {
          _animatedCameraAndMyMarkerPosition(
            LatLng(position.latitude, position.longitude),
          );
        }
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

  changeLocationServiceIsEnable(bool isTrue) {
    locationIsEnable = isTrue;
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

  _changeIsLoadingAddresses(bool isTrue) {
    isLoadingAddresses = isTrue;
    notifyListeners();
  }

  _clearAddressSearchMemoryStore() {
    mapLocationPlaceMark = {};
    addressesPlaceMarks.clear();
  }

  Future<Position> currentPosition() async {
    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  }

  Future<void> searchAddress(String address) async {
    mapLocationPlaceMark = {};
    try {
      _changeIsLoadingAddresses(true);
      final locations =
          await locationFromAddress(address, localeIdentifier: 'pt_BR');
      for (var location in locations) {
        var places = (await placemarkFromCoordinates(
                location.latitude, location.longitude,
                localeIdentifier: 'pt_BR'))
            .toSet();
        var values = places.map((e) => MapEntry(location, [...places]));
        mapLocationPlaceMark.addEntries(values);
        addressesPlaceMarks.addAll(places);
      }
    } catch (e) {
      print(e.toString());
    } finally {
      _changeIsLoadingAddresses(false);
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
    markers.removeWhere(
        (element) => element.markerId.value == 'my-marker-position');
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

  changeMapsController(GoogleMapController controller) async {
    controller.setMapStyle(jsonEncode(mapStyleUtil));
    mapController = controller;
    notifyListeners();
  }

  Future<void> changePolylines({
    required LatLng latLng1,
    required LatLng latLng2,
  }) async {
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      'AIzaSyCwaNOwrJ3bgX5rslX7vI32LtDRu_KeWHU',
      PointLatLng(
        latLng1.latitude,
        latLng1.latitude,
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
    Polyline polyline = Polyline(
      polylineId: PolylineId("${latLng1.toString()}-${latLng2.toString()}"),
      color: Colors.blue,
      jointType: JointType.bevel,
      points: [...polylineCoordinates],
    );
    polylines.add(polyline);
    _animatedCameraToLatings(latLng1, latLng2, 120);
  }

  changeMarkerOriginAddress() {
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

  changeMarkerDestinationAddress() {
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

  void getCurrentLocation() async {
    final position = await Geolocator.getCurrentPosition();
    await _animatedCameraAndMyMarkerPosition(
      LatLng(position.latitude, position.longitude),
    );
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

  void onTap(LatLng latLng) async {
    setMarkerPosition(latLng);
    await newCameraPosition(latLng);
    notifyListeners();
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
}
