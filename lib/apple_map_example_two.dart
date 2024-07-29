import 'package:apple_maps_flutter/apple_maps_flutter.dart';
import 'package:flutter/material.dart';
import 'package:maps_toolkit/maps_toolkit.dart' as mapTol;

class AppleMapsExampleTwo extends StatefulWidget {
  @override
  State<AppleMapsExampleTwo> createState() => _AppleMapsExampleState();
}

class _AppleMapsExampleState extends State<AppleMapsExampleTwo> {
  AppleMapController? mapController;

  final Map<AnnotationId, LatLng> _markerPositions = {};

  void _onMapCreated(AppleMapController controller) {
    mapController = controller;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
          child: AppleMap(
        mapType: MapType.satelliteFlyover,
        onTap: _onMarkerTap,
        annotations: _markerPositions.keys.map((markerId) {
          return Annotation(
            annotationId: markerId,
            draggable: true,
            zIndex: 1,
            position: _markerPositions[markerId]!,
            onTap: () => _onMarkerTapped(markerId),
          );
        }).toSet(),
        onMapCreated: _onMapCreated,
        initialCameraPosition: const CameraPosition(
          target: LatLng(0.0, 0.0),
        ),
        onCameraIdle: () {},
      )),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.clear),
        onPressed: () {
          _markerPositions.clear();
          setState(() {});
        },
      ),
    );
  }

  _onMarkerTap(LatLng lat) async {
    var length = _markerPositions.length;
    if (length < 5) {
      var markerId = AnnotationId('Marker ${length == 0 ? 1 : (length + 1)}');
      _markerPositions[markerId] = lat;

      setState(() {});
    }
  }

  _onMarkerTapped(AnnotationId markerId) async {
    var position = _markerPositions[markerId];
    final tappedLat = position?.latitude;
    final tappedLng = position?.longitude;
    print('Tapped marker position: $tappedLat, $tappedLng');
    _calculateArea();
  }



  _onDragEnd(AnnotationId markerId, LatLng position) async {
    print('inside ondrag Marker');
    _markerPositions[markerId] = position;
    setState(() {});
  }

  LatLng calculatePolygonCentroid(List<LatLng> vertices) {
    double totalLat = 0.0;
    double totalLng = 0.0;

    for (LatLng vertex in vertices) {
      totalLat += vertex.latitude;
      totalLng += vertex.longitude;
    }

    double avgLat = totalLat / vertices.length;
    double avgLng = totalLng / vertices.length;

    return LatLng(avgLat, avgLng);
  }

  void _calculateArea() async {
    if (_markerPositions.length > 2) {
      List<mapTol.LatLng> points = _markerPositions.values
          .map((point) => mapTol.LatLng(point.latitude, point.longitude))
          .toList();
      final area = ((await mapTol.SphericalUtil.computeArea(points)) * 10.764)
          .toStringAsFixed(2);
      print('Area of polygon: $area square meters');
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Polygon Area"),
            content: Text("The area of the polygon is $area square meters."),
            actions: [
              TextButton(
                child: Text("OK"),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    } else {
      print('Not enough points to form a polygon');
    }
  }
}
