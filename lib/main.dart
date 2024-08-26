import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_mapbox_navigation/flutter_mapbox_navigation.dart';
import 'package:geolocator/geolocator.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MapView(),
    );
  }
}

class MapView extends StatefulWidget {
  const MapView({super.key});

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  MapBoxNavigationViewController? _controller;
  String? _instruction;
  bool _isMultipleStop = false;
  double? _distanceRemaining, _durationRemaining;
  bool _routeBuilt = false;
  bool _isNavigating = false;
  bool _arrived = false;
  late MapBoxOptions _navigationOption;
  Position? _currentPosition;
  WayPoint? _destination;
  StreamSubscription<Position>? _positionStreamSubscription;  // 添加位置流订阅变量

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _requestLocationPermission();

    // Initialize the listener to listen to the position stream
    _positionStreamSubscription = Geolocator.getPositionStream(
      desiredAccuracy: LocationAccuracy.high,
      distanceFilter: 10,  // set the distance filter to 10 meters
    ).listen((Position position) {
      setState(() {
        print("Current Position: $position");  // print the current position
        _currentPosition = position;
        _updateNavigationOptions();  // update the navigation options
      });
    });
  }

  void _updateNavigationOptions() {
    if (_currentPosition != null) {
      _navigationOption = MapBoxOptions(
        initialLatitude: _currentPosition!.latitude,
        initialLongitude: _currentPosition!.longitude,
        mode: MapBoxNavigationMode.walking,
        simulateRoute: true,
      );
    }
  }

  Future<void> _requestLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Mapbox Navigation Example"),
      ),
      body: _currentPosition == null
          ? Center(child: CircularProgressIndicator()) // if current position is null, show a loading indicator
          : Column(
        children: [
          Expanded(
            child: GestureDetector(
              onLongPressStart: (details) async {
                final RenderBox box = context.findRenderObject() as RenderBox;
                final Offset offset = box.globalToLocal(details.globalPosition);

                // ToDo: Should be a better way to calculate the latitude and longitude
                final latitude = _currentPosition!.latitude + offset.dy * 0.0001;
                final longitude = _currentPosition!.longitude + offset.dx * 0.0001;

                _destination = WayPoint(
                  name: "Selected Location",
                  latitude: latitude,
                  longitude: longitude,
                );

                setState(() {});
              },
              child: Container(
                color: Colors.grey[100],
                child: MapBoxNavigationView(
                  options: _navigationOption,
                  onRouteEvent: _onRouteEvent,
                  onCreated: (MapBoxNavigationViewController controller) async {
                    _controller = controller;
                    await _controller?.initialize();
                  },
                ),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: _destination == null ? null : startNavigation, // if the destination is null, disable the button
            child: Text("Start Navigation"),
          ),
        ],
      ),
    );
  }

  void startNavigation() async {
    if (_controller != null && _destination != null) {
      final start = WayPoint(
        name: "User Location",
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
      );

      var wayPoints = <WayPoint>[start, _destination!];

      // reset the navigation variables
      _routeBuilt = false;
      _isNavigating = false;
      _arrived = false;

      // reset the instruction
      await _controller?.buildRoute(wayPoints: wayPoints);
      await _controller?.startNavigation();
    }
  }

  Future<void> _onRouteEvent(e) async {
    _distanceRemaining = await MapBoxNavigation.instance.getDistanceRemaining();
    _durationRemaining = await MapBoxNavigation.instance.getDurationRemaining();

    switch (e.eventType) {
      case MapBoxEvent.progress_change:
        var progressEvent = e.data as RouteProgressEvent;
        _arrived = progressEvent.arrived!;
        if (progressEvent.currentStepInstruction != null) {
          _instruction = progressEvent.currentStepInstruction;
        }
        break;
      case MapBoxEvent.route_building:
      case MapBoxEvent.route_built:
        _routeBuilt = true;
        break;
      case MapBoxEvent.route_build_failed:
        _routeBuilt = false;
        break;
      case MapBoxEvent.navigation_running:
        _isNavigating = true;
        break;
      case MapBoxEvent.on_arrival:
        _arrived = true;
        if (!_isMultipleStop) {
          await Future.delayed(const Duration(seconds: 3));
          await _controller?.finishNavigation();
        }
        break;
      case MapBoxEvent.navigation_finished:
      case MapBoxEvent.navigation_cancelled:
        _routeBuilt = false;
        _isNavigating = false;
        break;
      default:
        break;
    }
    setState(() {});
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel(); // cancel the position stream subscription
    _controller?.dispose();
    super.dispose();
  }
}
