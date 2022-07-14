import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_routes/helpers/image_to_bytes.dart';

import '../utils/map_style_util.dart';

class MapsController extends ChangeNotifier {
  Completer<BitmapDescriptor> iconBitMap = Completer<BitmapDescriptor>();
  GoogleMapController? mapController;
  late LocationSettings locationSettings;
  late CameraPosition initialCameraPosition;
  Position? lastPosition;
  Set<Marker> markers = <Marker>{};
  Set<Polyline> polylines = <Polyline>{};
  bool isLoadingInit = false;
  late bool locationIsEnable;
  MapsController() {
    _initController();
  }
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
          changeCameraAndMyMarkerPosition(
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

  _initController() async {
    _changeLoadingInit(true);
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
    _changeLoadingInit(false);
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

  _changeLoadingInit(bool isLoading) {
    isLoadingInit = isLoading;
    notifyListeners();
  }

  _changeMyMarkerPosition(LatLng latLng) async {
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

  changeCameraAndMyMarkerPosition(LatLng latLng) {
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

  _initPolylines({
    required LatLng latLng1,
    required LatLng latLng2,
  }) {
    Polyline polyline = Polyline(
      polylineId: PolylineId(latLng1.hashCode.toString()),
      color: Colors.blue,
      jointType: JointType.bevel,
      points: [
        latLng1,
        latLng2,
      ],
    );
    polylines.add(polyline);
  }

  onRequestPermission() async {
    try {
      final permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse) {
        final position = await Geolocator.getCurrentPosition();
        changeCameraAndMyMarkerPosition(
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
    _initPolylines(
      latLng1: LatLng(-19.7999877, -43.9744977),
      latLng2: LatLng(-19.8532936, -43.9241141),
    );
    changeCameraAndMyMarkerPosition(
      LatLng(position.latitude, position.longitude),
    );
  }
}
