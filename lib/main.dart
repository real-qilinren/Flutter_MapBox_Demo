import 'package:flutter/material.dart';
import 'package:flutter_mapbox_navigation/flutter_mapbox_navigation.dart';

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

  Future<void> initialize() async {
    if (!mounted) return;

    _navigationOption = MapBoxOptions(
      initialLatitude: 151.21111,
      initialLongitude: -33.859972,
      mode: MapBoxNavigationMode.walking,
      simulateRoute: true,  // 启用模拟导航
    );

    MapBoxNavigation.instance.registerRouteEventListener(_onRouteEvent);
  }

  @override
  void initState() {
    initialize();
    super.initState();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void startNavigation() async {
    if (_controller != null) {
      final downtown = WayPoint(
          name: "Downtown Buffalo",
          latitude: 42.8866177,
          longitude: -78.8814924
      );

      final townhall = WayPoint(
          name: "Town Hall",
          latitude: 32.8866177,
          longitude: -70.8814924
      );

      var wayPoints = <WayPoint>[];
      wayPoints.add(downtown);
      wayPoints.add(townhall);

      // 清除上次的导航状态
      _routeBuilt = false;
      _isNavigating = false;
      _arrived = false;

      // 构建并开始导航
      await _controller?.buildRoute(wayPoints: wayPoints);
      await _controller?.startNavigation();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Mapbox Navigation Example"),
      ),
      body: Column(
        children: [
          Expanded(
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
          ElevatedButton(
            onPressed: startNavigation,
            child: Text("Start Navigation"),
          ),
        ],
      ),
    );
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
}
