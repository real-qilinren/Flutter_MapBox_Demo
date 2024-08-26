// import 'package:flutter/material.dart';
// import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
// import 'package:permission_handler/permission_handler.dart';
//
// import 'page.dart';
//
// class MapScreen extends ExamplePage {
//   MapScreen() : super(const Icon(Icons.map), 'Location Component');
//
//   @override
//   Widget build(BuildContext context) {
//     return const LocationPageBody();
//   }
// }
//
// class LocationPageBody extends StatefulWidget {
//   const LocationPageBody();
//
//   @override
//   State<StatefulWidget> createState() => LocationPageBodyState();
// }
//
// class LocationPageBodyState extends State<LocationPageBody> {
//   MapboxMap? mapboxMap;
//
//   @override
//   void initState() {
//     super.initState();
//     _requestLocationPermission();
//   }
//
//   Future<void> _requestLocationPermission() async {
//     var status = await Permission.locationWhenInUse.request();
//     if (status.isGranted) {
//       print("Location permission granted.");
//       _showUserLocation();
//     } else {
//       print("Location permission denied.");
//     }
//   }
//
//   void _onMapCreated(MapboxMap mapboxMap) {
//     this.mapboxMap = mapboxMap;
//     _showUserLocation();
//     _hardcodeUserLocation();
//   }
//
//   void _showUserLocation() {
//     mapboxMap?.location.updateSettings(
//       LocationComponentSettings(
//         enabled: true,
//         puckBearingEnabled: true,
//       ),
//     );
//   }
//
//   void _hardcodeUserLocation() {
//     final Position hardcodedUserLocation = Position(151.21111, -33.859972);
//
//     mapboxMap?.setCamera(
//       CameraOptions(
//         center: Point(coordinates: hardcodedUserLocation),
//         zoom: 14.0,
//         bearing: 0,
//         pitch: 0,
//       ),
//     );
//
//     mapboxMap?.location.updateSettings(
//       LocationComponentSettings(
//         enabled: true,
//         puckBearingEnabled: true,
//         locationPuck: LocationPuck(
//           locationPuck2D: DefaultLocationPuck2D(),
//         ),
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final MapWidget mapWidget =
//     MapWidget(key: ValueKey("mapWidget"), onMapCreated: _onMapCreated);
//
//     return Scaffold(
//       body: SizedBox.expand(
//         child: mapWidget,
//       ),
//     );
//   }
// }
