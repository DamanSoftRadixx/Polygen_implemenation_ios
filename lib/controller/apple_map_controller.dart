/*
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:apple_maps_flutter/apple_maps_flutter.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:maps_toolkit/maps_toolkit.dart' as mapTol;
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:path_provider/path_provider.dart';
class AppMapController extends GetxController {
  AppleMapController? mapController;
  var iconUniCode = Rxn<Uint8List>();
  var polygon = <Polygon>{};
  RxMap<AnnotationId, LatLng> markerPositions = RxMap<AnnotationId, LatLng>();

  var pentagonEnable = false.obs;
  var isDraggingPolygon = false.obs;
  var isLongPressEnable = false.obs;
  var totalArea = RxnString('');
  double oneSquareMileInSquareMeters = 2599999.0;
  double oneMileSquareMeter = 2599999.0;
  LatLng? initialDragPosition;
  Timer? debounce;
  Timer? debounceIdeal;

  @override
  void onInit() {
    // getImages('assets/png/custom_marker_two.png', 100);
    super.onInit();
  }

  changePentagonStatus(bool value) {
    pentagonEnable.value = value;
    pentagonEnable.refresh();
  }

  changeDraggingPolygonStatus(bool value) {
    isDraggingPolygon.value = value;
    isDraggingPolygon.refresh();
  }

  changeLongPressStatus(bool value) {
    isLongPressEnable.value = value;
    isLongPressEnable.refresh();
  }

  void onMapCreated(AppleMapController controller) {
    mapController = controller;
  }

  Future<Uint8List> getImages(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(),
        targetHeight: width);
    ui.FrameInfo fi = await codec.getNextFrame();
    var icon = (await fi.image.toByteData(format: ui.ImageByteFormat.png))!
        .buffer
        .asUint8List();
    iconUniCode.value = icon;
    return icon;
    //await appleMap.BitmapDescriptor.fromBytes(markerIcon)
    // icon: await googleMap.BitmapDescriptor.fromBytes(markerIcon), png iamge
  }

  void onClearAllData() async {
    changePolygenAreaAcdoingtToZoom();
    await _deleteCacheDir();
    polygon.clear();
    markerPositions.clear();
    changeDraggingPolygonStatus(false);
    initialDragPosition = null;
    totalArea.value = null;
    var zoomLevel = await mapController?.getZoomLevel() ?? 0;
    if (zoomLevel > 10.20 && markerPositions.value.isEmpty) {
      changePentagonStatus(true);
    } else {
      changePentagonStatus(false);
    }
    changeLongPressStatus(true);
  }
  Future<void> _deleteCacheDir() async {
    try {
      var tempDir = await getTemporaryDirectory();

      if (await tempDir.exists()) {
        // Get the list of files in the directory
        var files = tempDir.listSync();

        // Delete each file
        for (var file in files) {
          try {
            if (file is File) {
              await file.delete();
            } else if (file is Directory) {
              await file.delete(recursive: true);
            }
          } catch (e) {
            print("Error deleting file: $e");
          }
        }
        print("Temporary cache cleared");
      }
    } catch (e) {
      print("Error clearing cache: $e");
    }
   /* try {
      var tempDir = await getTemporaryDirectory();
      if (await tempDir.exists()) {
        final dir = Directory(tempDir.path);
        await dir.delete(recursive: true);
        print("Temporary cache cleared");
      }
    } catch (e) {
      print("Error clearing cache: $e");
    }*/

  }
  double calculateRadiusForAreaa(double area, int numberOfSides) {
    return math.sqrt(
        (2 * area) / (numberOfSides * math.sin((2 * math.pi) / numberOfSides)));
  }

  // Future<List<LatLng>> getPentagonCoordinates() async {
  //   if (pentagonEnable.value) {
  //     return [];
  //   }
  //   const int numberOfSides = 5;
  //   double radiusInMeters =
  //   calculateRadiusForAreaa(oneSquareMileInSquareMeters, numberOfSides);
  //   GoogleMapController controllerr = await controller.future;
  //   LatLngBounds bounds = await controllerr.getVisibleRegion();
  //   LatLng center = LatLng(
  //     (bounds.northeast.latitude + bounds.southwest.latitude) / 2,
  //     (bounds.northeast.longitude + bounds.southwest.longitude) / 2,
  //   );
  //   const double angleBetweenVertices = 360.0 / numberOfSides;
  //   final List<LatLng> pentagonPoints = [];
  //   var tempList = <MarkerId, LatLng>{};
  //   for (var i = 0; i < numberOfSides; i++) {
  //     final double currentAngle = angleBetweenVertices * i;
  //     final double angleInRadians = math.pi * currentAngle / 180.0;
  //     final double xOffset = math.cos(angleInRadians) * radiusInMeters;
  //     final double yOffset = math.sin(angleInRadians) * radiusInMeters;
  //     var latLng = LatLng(
  //         center.latitude + (yOffset / 111320),
  //         center.longitude +
  //             (xOffset / (111320 * math.cos(center.latitude * math.pi / 180))));
  //     pentagonPoints.add(latLng);
  //     var length = tempList.length;
  //     var markerId = MarkerId('Marker ${length == 0 ? 1 : (length + 1)}');
  //     tempList[markerId] = latLng;
  //   }
  //   // polygon.clear();
  //   // markerPositions.value = tempList;
  //   initializePolygonsFirstTime(tempList);
  //   return pentagonPoints;
  // }
  Future<Map<AnnotationId, LatLng>> getPentagonCoordinates(
      BuildContext context) async {
    if (mapController == null) {
      return {};
    }
    const int numberOfSides = 5;
    double radiusInMeters =
        calculateRadiusForAreaa(oneSquareMileInSquareMeters, numberOfSides);
    LatLngBounds bounds = await mapController!.getVisibleRegion();
    LatLng center = LatLng(
      (bounds.northeast.latitude + bounds.southwest.latitude) / 2,
      (bounds.northeast.longitude + bounds.southwest.longitude) / 2,
    );
    const double angleBetweenVertices = 360.0 / numberOfSides;
    final Map<AnnotationId, LatLng> pentagonPoints = {};
    for (var i = 0; i < numberOfSides; i++) {
      final double currentAngle = angleBetweenVertices * i;
      final double angleInRadians = math.pi * currentAngle / 180.0;
      final double xOffset = math.cos(angleInRadians) * radiusInMeters;
      final double yOffset = math.sin(angleInRadians) * radiusInMeters;
      var latLng = LatLng(
          center.latitude + (yOffset / 111320),
          center.longitude +
              (xOffset / (111320 * math.cos(center.latitude * math.pi / 180))));
      var length = pentagonPoints.length;
      var markerId = AnnotationId('Marker ${length == 0 ? 1 : (length + 1)}');

      pentagonPoints[markerId] = latLng;
      print('inside for loop $i $length and pentagonPoints${pentagonPoints.length}');
    }
    print('marker position length before ${markerPositions.values.length} and ${pentagonPoints.length}');
    markerPositions.value = pentagonPoints;
    print('marker position length after ${markerPositions.values.length}and ${pentagonPoints.length}');
    initializePolygons(firstTimeCreate: true, context: context);
    changePentagonStatus(false);
    return pentagonPoints;
  }

  changePolygenAreaAcdoingtToZoom() async {
    var zoomLevel = await mapController?.getZoomLevel() ?? 0.0;
    print('zoomLevel for adujct $zoomLevel');
    switch (zoomLevel) {
      case >= 18.50:
        oneSquareMileInSquareMeters = 900;
      case >= 18:
        oneSquareMileInSquareMeters = 5000.0;
      case >= 17.50:
        oneSquareMileInSquareMeters = 10000.0;
      case >= 17:
        oneSquareMileInSquareMeters = 18000.0;
      case >= 16.50:
        oneSquareMileInSquareMeters = 22000.0;
      case >= 16:
        oneSquareMileInSquareMeters = 25000.0;
      case >= 15.50:
        oneSquareMileInSquareMeters = 109999.0;
      case >= 15:
        oneSquareMileInSquareMeters = 209999.0;
      case >= 14.70:
        oneSquareMileInSquareMeters = 2299999.0;
      default:
        oneSquareMileInSquareMeters = 2599999.0;
        break;
    }
    print('oneSquareMileInSquareMeters $oneSquareMileInSquareMeters');
    // oneSquareMileInSquareMeters=zoomLevel;
  }

/*  onMarkerTap(LatLng lat, BuildContext context) async {
    var length = markerPositions.value.length;
    if (length < 5) {
      var markerId = AnnotationId('Marker ${length == 0 ? 1 : (length + 1)}');
      markerPositions.value[markerId] = lat;
      await initializePolygons(context: context);
    }
  }*/

  onDragEnd(
      AnnotationId markerId, LatLng position, BuildContext context) async {
    changeDraggingPolygonStatus(false);
    initialDragPosition = null;
    changeLongPressStatus(true);
    var previousLatLang = markerPositions[markerId];
    markerPositions[markerId] = position;
    if (await isAreaMoreThanOneSquareMile(context: context)) {
      Future.delayed(const Duration(milliseconds: 250), () {
        markerPositions[markerId] = previousLatLang!;
      });
    } else {
      await initializePolygonsWithout(context);
    }
    // Future.delayed(
    //   const Duration(milliseconds: 200),
    //   () {
    //     markerPositions.refresh();
    //   },
    // );
  }

  Future<num> getArea() async {
    if (markerPositions.value.length > 2) {
      List<mapTol.LatLng> points = markerPositions.value.values
          .map((point) => mapTol.LatLng(point.latitude, point.longitude))
          .toList();
      final area = (mapTol.SphericalUtil.computeArea(points)); // square meters.
      return area;
    } else {
      return 0;
    }
  }

  Future<bool> isAreaMoreThanOneSquareMile(
      {bool showSnap = true, required BuildContext context}) async {
    final areaInSquareMeters = await getArea();
    // var isMoreThan = areaInSquareMeters > oneSquareMileInSquareMeters;
    var isMoreThan = areaInSquareMeters > oneMileSquareMeter;
    if (isMoreThan && showSnap) {
      Fluttertoast.showToast(
          // msg: "Area selection is limited to ${totalArea.value} square mile.",
          msg: "Area selection is limited to 1 square mile.",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.TOP,
          timeInSecForIosWeb: 1,
          textColor: Colors.white,
          backgroundColor: Colors.red,
          fontSize: 16.0);
    }
    return isMoreThan;
  }

  Future initializePolygonsWithout(BuildContext context) async {
    var list = markerPositions.value.values.toList();
    await Future.delayed(
      const Duration(milliseconds: 250),
      () async {
        polygon.clear();
        markerPositions.refresh();
        await _deleteCacheDir();
        // await Future.delayed(const Duration(milliseconds: 0));
        await Future.delayed(const Duration(milliseconds: 250));
        polygon.add(Polygon(
          visible: true,
          polygonId: PolygonId(math.Random.secure().nextInt(1000).toString()),
          // PolygonId('1'),
          points: list,
          fillColor: const Color(0xFF00ACDB).withOpacity(0.3),
          strokeColor: const Color(0xFF00ACDB),
          strokeWidth: 4,
        ));
        await calculateArea(context: context);
        markerPositions.refresh();
      },
    );
  }

  initializePolygons(
      {bool firstTimeCreate = false, required BuildContext context}) {
    if (markerPositions.length > 2) {
      if (debounce?.isActive ?? false) debounce?.cancel();
      debounce =
          Timer(Duration(milliseconds: firstTimeCreate ? 0 : 250), () async {
            if(!firstTimeCreate) {
              polygon.clear();
              markerPositions.refresh();
            }
        await Future.delayed(
           Duration(milliseconds: firstTimeCreate ? 0 : 250),
          () {},
        );
        List<LatLng> markList = markerPositions.entries
            .where((entry) => !(entry.key.toString().startsWith('center')))
            .map((entry) => entry.value)
            .toList();
        polygon.add(Polygon(
          visible: true,
          // polygonId:  PolygonId('1'),
          polygonId: PolygonId(math.Random.secure().nextInt(1000).toString()),
          points: markList,
          fillColor: Color(0xFF00ACDB).withOpacity(0.3),
          strokeColor: Color(0xFF00ACDB),
          strokeWidth: 4,
        ));

        markerPositions.refresh();

        calculateArea(fromClick: false, context: context);
      });
    }
    return true;
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

  void onCameraMove(CameraPosition position, BuildContext context) async {
    print('inside onCamera move');
    var zoomLevel = await mapController?.getZoomLevel() ?? 0;
    if (zoomLevel > 10.20 && markerPositions.value.isEmpty) {
      changePentagonStatus(true);
    } else {
      changePentagonStatus(false);
    }
    if (markerPositions.length > 2) {
      if (isDraggingPolygon.value &&
          initialDragPosition != null &&
          isLongPressEnable.value) {
        LatLng newDragPosition = position.target;
        double deltaLat =
            newDragPosition.latitude - initialDragPosition!.latitude;
        double deltaLng =
            newDragPosition.longitude - initialDragPosition!.longitude;
        var newMarkerPositions =
            Map<AnnotationId, LatLng>.from(markerPositions.value);
        await Future.forEach(newMarkerPositions.entries, (entry) async {
          var key = entry.key;
          var value = entry.value;
          newMarkerPositions[key] =
              LatLng(value.latitude + deltaLat, value.longitude + deltaLng);
        });
        initialDragPosition = newDragPosition;
        markerPositions.value = newMarkerPositions;
        initializePolygons(context: context);
        // initializePolygons(list: markerPositions);

        // LatLng newDragPosition = position.target;
        // double deltaLat =
        //     newDragPosition.latitude - initialDragPosition!.latitude;
        // double deltaLng =
        //     newDragPosition.longitude - initialDragPosition!.longitude;
        // markerPositions.value.updateAll((key, value) =>
        //     LatLng(value.latitude + deltaLat, value.longitude + deltaLng));
        // initialDragPosition = newDragPosition;
        // markerPositions.refresh();
        // await initializePolygons(context: context);
      }
    } else {
      changePolygenAreaAcdoingtToZoom();
    }
  }

  Future calculateArea(
      {bool fromClick = false, required BuildContext context}) async {
    if (markerPositions.value.length > 2) {
      List<mapTol.LatLng> points = markerPositions.value.values
          .map((point) => mapTol.LatLng(point.latitude, point.longitude))
          .toList();
      final area =
          (await mapTol.SphericalUtil.computeArea(points)); // square meters.

      // Convert area to appropriate units and format it.
      const sqMetersToSqFeet = 10.7639;
      const sqMetersToSqMiles = 3.861e-7;

      String formattedArea;
      if (area > 2.58999e+6) {
        // 1 square mile in square meters
        final areaInSquareMiles = area * sqMetersToSqMiles;
        formattedArea = '${areaInSquareMiles.toStringAsFixed(2)} sq miles';
      } else {
        final areaInSquareFeet = area * sqMetersToSqFeet;
        if (areaInSquareFeet > 1000) {
          // formattedArea =
          //     '${(areaInSquareFeet / 1000).toStringAsFixed(2)} sqft';
          formattedArea = '${areaInSquareFeet.toInt()} sqft';
        } else {
          formattedArea = '${areaInSquareFeet.toStringAsFixed(2)} sqft';
        }
      }
      totalArea.value = formattedArea;

      print('Area of polygon: $area square meters');
      if (fromClick) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text("Property Area"),
              content: Text("The area of the property is $area sqft."),
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
      }
    } else {
      print('Not enough points to form a polygon');
    }
  }

  Future checkInsidePolygonOrNot(LatLng lat) async {
    var pointCheck = mapTol.LatLng(lat.latitude, lat.longitude);
    var points = markerPositions.value.values
        .map((value) => mapTol.LatLng(value.latitude, value.longitude))
        .toList();
    final insidePolyOrNot =
        mapTol.PolygonUtil.containsLocation(pointCheck, points, false);
    if (insidePolyOrNot) {
      changeDraggingPolygonStatus(true);
      Future.delayed(Duration(milliseconds: 200),() {

      mapController?.onClickTempTap();
      },);
      Future.delayed(
        const Duration(milliseconds: 2500),
        () {
          if (initialDragPosition == lat) {
            changeLongPressStatus(true);
            changeDraggingPolygonStatus(false);
          }
        },
      );
      print('after on Tap evint initialDragPosition');

      initialDragPosition = lat;
    } else {
      changeLongPressStatus(true);
      changeDraggingPolygonStatus(false);
    }
  }

  void onLongPress(LatLng lat) async {
    var length = markerPositions.value.length;
    if (length > 3 && isLongPressEnable.value) {
      await checkInsidePolygonOrNot(lat);
    }
  }

  onCameraIdeal() {
    if (debounceIdeal?.isActive ?? false) debounceIdeal?.cancel();
    debounceIdeal = Timer(const Duration(milliseconds: 800), () async {
      changeDraggingPolygonStatus(false);
      initialDragPosition = null;
      changeLongPressStatus(true);
    });
  }

  onDragStart({required LatLng value}) {
    changeLongPressStatus(false);
    changeDraggingPolygonStatus(false);
    initialDragPosition = null;
  }
}
 */

import 'dart:async';
import 'dart:io';
import 'package:apple_maps_flutter/apple_maps_flutter.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_rx/src/rx_workers/utils/debouncer.dart';
import 'package:maps_toolkit/maps_toolkit.dart' as mapTol;
import 'dart:math' as math;
import 'package:path_provider/path_provider.dart';

enum MileKeyName { oneMile, twoMile, threeMile }

class AppMapController extends GetxController {
  AppleMapController? mapController;
  RxnString totalArea = RxnString();
  double squareInMiles = 7799999.0;
  Debouncer moveCameraBouncer =
  Debouncer(delay: const Duration(milliseconds: 300));
  var moving=false.obs;
  var milesInSquare = {
    MileKeyName.oneMile: (2599999.0),
    MileKeyName.twoMile: (5199999.0),
    MileKeyName.threeMile: (7799999.0),
  };
  var milesZoomLevel = {
    MileKeyName.oneMile: (14.16),
    MileKeyName.twoMile: (13.50),
    MileKeyName.threeMile: (13.0),
    // MileKeyName.oneMile: (12.00),
    // MileKeyName.twoMile: (13.54),
    // MileKeyName.threeMile: (14.0),
    // MileKeyName.oneMile: (13.98),
    // MileKeyName.twoMile: (13.54),
    // MileKeyName.threeMile: (14.0),
    // MileKeyName.oneMile: (13.85),
    // MileKeyName.twoMile: (13.40),
    // MileKeyName.threeMile: (14.0),
  };
  var defaultZoomLevel = (14.0);

  var enableCameraMove = false;
  var polygonList = RxSet<Polygon>();

  @override
  void onInit() {
    super.onInit();
  }

  void onMapCreated(AppleMapController controller) {
    mapController = controller;
  }

  Future<void> _deleteCacheDir() async {
    try {
      var tempDir = await getTemporaryDirectory();

      if (await tempDir.exists()) {
        // Get the list of files in the directory
        var files = tempDir.listSync();

        // Delete each file
        for (var file in files) {
          try {
            if (file is File) {
              await file.delete();
            } else if (file is Directory) {
              await file.delete(recursive: true);
            }
          } catch (e) {
            print("Error deleting file: $e");
          }
        }
        print("Temporary cache cleared");
      }
    } catch (e) {
      print("Error clearing cache: $e");
    }
    /* try {
      var tempDir = await getTemporaryDirectory();
      if (await tempDir.exists()) {
        final dir = Directory(tempDir.path);
        await dir.delete(recursive: true);
        print("Temporary cache cleared");
      }
    } catch (e) {
      print("Error clearing cache: $e");
    }*/
  }

  Future<double> calculateRadiusForAreaa(double area, int numberOfSides) async {
    return await math.sqrt(
        (2 * area) / (numberOfSides * math.sin((2 * math.pi) / numberOfSides)));
  }

  void onClearAllData() async {
    await _deleteCacheDir();
    polygonList.clear();
    totalArea.value = null;
  }

  Future drawPolygonAtCenter(BuildContext context) async {
    if (mapController == null) {
      return true;
    }

    await changeZoomLevel();
    LatLngBounds bounds = await mapController!.getVisibleRegion();
    LatLng? center = LatLng(
      (bounds.northeast.latitude + bounds.southwest.latitude) / 2,
      (bounds.northeast.longitude + bounds.southwest.longitude) / 2,
    );
    var polyList = await getCenterPolyListLatLag(center: center);
    polygonList.value = await getPolygenList(polyList: polyList);
    await calculateArea();
    var animateZoomLevel = await getZoomLevelForPlygen();
    double threeZoom =
        milesZoomLevel[MileKeyName.threeMile] ?? defaultZoomLevel;
    if (animateZoomLevel >= threeZoom) {
      enableCameraMove = false;
      await animateTo(centerPosition: center, zoomLevel: animateZoomLevel);
      await Future.delayed(
        const Duration(milliseconds: 800),
            () {
              moving.value=false;
          enableCameraMove = true;
        },
      );
    }

    return true;
  }

  Future<List<LatLng>> getCenterPolyListLatLag({required LatLng center}) async {
    var polyList = <LatLng>[];
    const int numberOfSides = 5;
    double radiusInMeters =
    await calculateRadiusForAreaa(squareInMiles, numberOfSides);

    const double angleBetweenVertices = 360.0 / numberOfSides;
    for (var i = 0; i < numberOfSides; i++) {
      final double currentAngle = angleBetweenVertices * i;
      final double angleInRadians = math.pi * currentAngle / 180.0;
      final double xOffset = math.cos(angleInRadians) * radiusInMeters;
      final double yOffset = math.sin(angleInRadians) * radiusInMeters;
      var latLng = LatLng(
          center.latitude + (yOffset / 111320),
          center.longitude +
              (xOffset / (111320 * math.cos(center.latitude * math.pi / 180))));
      polyList.add(latLng);
    }
    return polyList;
  }

  Future animateTo(
      {required double? zoomLevel, required LatLng centerPosition}) async {
    print('zoomLevel zommLevle ${zoomLevel}');
    // await mapController?.moveCamera(CameraUpdate.zoomTo(zoomLevel ?? (14)));// 13.98 == 18.79

    // mapController?.moveCamera(
    //   CameraUpdate.zoomBy(zoomLevel ?? (14)),
    // ); // 13.98 == 16.06

    // mapController?.moveCamera(
    //   CameraUpdate.newLatLngZoom(centerPosition, zoomLevel ?? (14)),
    // ); // 13.98 == 12.99

    await mapController?.moveCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          heading: 270.0,
          target: centerPosition,
          pitch: 0.0,
          zoom: zoomLevel ?? (14),
        ),
      ),
    ); // 13.98 == 13.02
  }

  Future calculateArea() async {
    if (polygonList.isNotEmpty == true) {
      List<mapTol.LatLng> points = polygonList.first.points
          .map(
            (point) => mapTol.LatLng(point.latitude, point.longitude),
      )
          .toList();
      final area =
      (await mapTol.SphericalUtil.computeArea(points)); // square meters.
      // Convert area to appropriate units and format it.
      const sqMetersToSqFeet = 10.7639;
      const sqMetersToSqMiles = 3.861e-7;
      String formattedArea;
      if (area > 2.58999e+6) {
        // 1 square mile in square meters
        final areaInSquareMiles = area * sqMetersToSqMiles;
        formattedArea = '${areaInSquareMiles.toStringAsFixed(2)} sq miles';
      } else {
        final areaInSquareFeet = area * sqMetersToSqFeet;
        if (areaInSquareFeet > 1000) {
          // formattedArea =
          //     '${(areaInSquareFeet / 1000).toStringAsFixed(2)} sqft';
          formattedArea = '${areaInSquareFeet.toInt()} sqft';
        } else {
          formattedArea = '${areaInSquareFeet.toStringAsFixed(2)} sqft';
        }
      }
      totalArea.value = formattedArea;
    }
  }

  onCameraMove(CameraPosition position) {
    if(!moving.value) {
      moving.value = true;
    }
    moveCameraBouncer.cancel();
    moveCameraBouncer.call(
          () async {
        if (polygonList.isNotEmpty && enableCameraMove) {
          await changeZoomLevel();
          await getZoomLevelForPlygen();
          changePolygenOnMove(center: position.target);
          moving.value=false;
        }
      },
    );
  }

  changePolygenOnMove({required LatLng center}) async {
    var polyList = await getCenterPolyListLatLag(center: center);
    polygonList.value = await getPolygenList(polyList: polyList);
    polygonList.refresh();
    await calculateArea();
  }

  Future<Set<Polygon>> getPolygenList({required List<LatLng> polyList}) async {
    return {
      await Polygon(
        visible: true,
        polygonId: PolygonId('1'),
        // polygonId: PolygonId(math.Random.secure().nextInt(1000).toString()),
        points: polyList,
        fillColor: const Color(0xFF00ACDB).withOpacity(0.3),
        strokeColor: const Color(0xFF00ACDB),
        strokeWidth: 4,
      )
    };
  }

  Future<bool> ableToMove() async {
    double threeZoomLevel =
    (milesZoomLevel[MileKeyName.threeMile] ?? defaultZoomLevel);
    var zoom = (await mapController?.getZoomLevel() ?? defaultZoomLevel);
    print('zoom area is ' '${zoom} ${zoom > threeZoomLevel}');
    if (zoom > threeZoomLevel) {
      return false;
    } else {
      return true;
    }
    return true;
  }

  Future changeZoomLevel() async {
    var zoom = (await mapController?.getZoomLevel() ?? defaultZoomLevel);
    double oneZoom = milesZoomLevel[MileKeyName.oneMile] ?? defaultZoomLevel;
    double twoZoom = milesZoomLevel[MileKeyName.twoMile] ?? defaultZoomLevel;
    double threeZoom =
        milesZoomLevel[MileKeyName.threeMile] ?? defaultZoomLevel;
    double one = milesInSquare[MileKeyName.oneMile] ?? defaultZoomLevel;
    double two = milesInSquare[MileKeyName.twoMile] ?? defaultZoomLevel;
    double three = milesInSquare[MileKeyName.threeMile] ?? defaultZoomLevel;
    // MileKeyName.oneMile: (12.00),
    // MileKeyName.twoMile: (13.54),
    // MileKeyName.threeMile: (14.0),

    // MileKeyName.oneMile: (14.16),
    // MileKeyName.twoMile: (13.50),
    // MileKeyName.threeMile: (13.0),

    if (zoom > oneZoom) {
      print(
          '--------------===----------------------------===--------one--$zoom----changeZoomLevel ${threeZoom}');
      squareInMiles = one;
    } else if (zoom < oneZoom && zoom > threeZoom) {
      print(
          '--------------===----------------------------===-------two--$zoom-----changeZoomLevel ${twoZoom}');
      squareInMiles = two;
    } else {
      print(
          '--------------===----------------------------===------three $zoom--------changeZoomLevel ${oneZoom}');
      squareInMiles = three;
    }

    // if(zoom<threeZoom){
    //   print('--------------===----------------------------===--------three--$zoom----changeZoomLevel ${threeZoom}');
    //   squareInMiles = three;
    // }else if(zoom>twoZoom && zoom<threeZoom){
    //   print('--------------===----------------------------===-------two--$zoom-----changeZoomLevel ${twoZoom}');
    //   squareInMiles = two;
    // }else{
    //   print('--------------===----------------------------===------one $zoom--------changeZoomLevel ${oneZoom}');
    //   squareInMiles = one;
    // }

    // if (zoom >= oneZoom) {
    //   print('--------------===----------------------------===------one $zoom--------changeZoomLevel ${oneZoom}');
    //   squareInMiles = one;
    // } else if (zoom <= oneZoom && zoom >= twoZoom ) {
    //   // value > twoMile && value <= threeMile
    //   print('--------------===----------------------------===-------two--$zoom-----changeZoomLevel ${twoZoom}');
    //   squareInMiles = two;
    // } else {
    //   print('--------------===----------------------------===--------three--$zoom----changeZoomLevel ${threeZoom}');
    //   squareInMiles = three;
    // }
    return true;
  }

  Future<double> getZoomLevelForPlygen() async {
    var zoom = (await mapController?.getZoomLevel() ?? defaultZoomLevel);
    double oneZoom = milesZoomLevel[MileKeyName.oneMile] ?? defaultZoomLevel;
    double twoZoom = milesZoomLevel[MileKeyName.twoMile] ?? defaultZoomLevel;
    double threeZoom =
        milesZoomLevel[MileKeyName.threeMile] ?? defaultZoomLevel;
    if (zoom > oneZoom) {
      print(
          '--------------===----------------------------===--$zoom----one-------- ${oneZoom}');
      return oneZoom;
    } else if (zoom < oneZoom && zoom > threeZoom) {
      print(
          '--------------===----------------------------===---$zoom----two------- ${twoZoom}');
      return twoZoom;
    } else {
      print(
          '--------------===----------------------------===---$zoom-----three------ ${threeZoom}');
      return threeZoom;
    }

    if (zoom < threeZoom) {
      print(
          '--------------===----------------------------===---$zoom-----three------ ${threeZoom}');
      return threeZoom;
    } else if (zoom > twoZoom && zoom < threeZoom) {
      print(
          '--------------===----------------------------===---$zoom----two------- ${twoZoom}');
      return twoZoom;
    } else {
      print(
          '--------------===----------------------------===--$zoom----one-------- ${oneZoom}');
      return oneZoom;
    }
    if (zoom >= oneZoom) {
      print(
          '--------------===----------------------------===--$zoom----one-------- ${oneZoom}');
      return oneZoom;
    } else if (zoom <= oneZoom && zoom >= twoZoom) {
      print(
          '--------------===----------------------------===---$zoom----two------- ${twoZoom}');
      return twoZoom;
    } else {
      print(
          '--------------===----------------------------===---$zoom-----three------ ${threeZoom}');
      return threeZoom;
    }
  }

  double calculateWidth() {
    List<LatLng> polygonCoordinates = [];
    if (polygonList.isNotEmpty) {
      polygonCoordinates = polygonList.first.points;
    }
    if (polygonCoordinates.isEmpty) {
      return 20;
    }


    // Calculate the center of the polygon
    double centerLat = polygonCoordinates.map((p) => p.latitude).reduce((value,
        element) => value + element) / polygonCoordinates.length;
    double centerLng = polygonCoordinates.map((p) => p.longitude).reduce((value,
        element) => value + element) / polygonCoordinates.length;
    LatLng center = LatLng(centerLat, centerLng);

    // Calculate distances to corners
    double maxWidth = 0;
    for (LatLng point in polygonCoordinates) {
      double distance = calculateDistanceInMeters(center, point);
      if (distance > maxWidth) {
        maxWidth = distance;
      }
    }

    return maxWidth * 2; // Multiply by 2 to get the full width
    double minLng = double.infinity;
    double maxLng = -double.infinity;
    for (LatLng point in polygonCoordinates) {
      minLng = math.min(minLng, point.longitude);
      maxLng = math.max(maxLng, point.longitude);
    }

    return (maxLng - minLng).abs();
  }

  double calculateHeight() {
    List<LatLng> polygonCoordinates = [];
    if (polygonList.isNotEmpty) {
      polygonCoordinates = polygonList.first.points;
    }
    if (polygonCoordinates.isEmpty) {
      return 20;
    }
    // Calculate the center of the polygon
    double centerLat = polygonCoordinates.map((p) => p.latitude).reduce((value,
        element) => value + element) / polygonCoordinates.length;
    double centerLng = polygonCoordinates.map((p) => p.longitude).reduce((value,
        element) => value + element) / polygonCoordinates.length;
    LatLng center = LatLng(centerLat, centerLng);

    // Calculate distances to corners
    double maxHeight = 0;
    for (LatLng point in polygonCoordinates) {
      double distance = calculateDistanceInMeters(center, point);
      if (distance > maxHeight) {
        maxHeight = distance;
      }
    }

    return maxHeight; // Multiply by 2 to get the full height

    double minLat = double.infinity;
    double maxLat = -double.infinity;
    for (LatLng point in polygonCoordinates) {
      minLat = math.min(minLat, point.latitude);
      maxLat = math.max(maxLat, point.latitude);
    }

    return (maxLat - minLat).abs();
  }


  double calculateDistanceInMeters(LatLng point1, LatLng point2) {
    const double _earthRadius = 6371000.0; // Earth's radius in meters
    double lat1Rad = point1.latitude * (math.pi / 180);
    double lng1Rad = point1.longitude * (math.pi / 180);
    double lat2Rad = point2.latitude * (math.pi / 180);
    double lng2Rad = point2.longitude * (math.pi / 180);

    double dLat = lat2Rad - lat1Rad;
    double dLng = lng2Rad - lng1Rad;

    double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1Rad) * math.cos(lat2Rad) *
            math.sin(dLng / 2) * math.sin(dLng / 2);
    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));


    return _earthRadius * c;
  }
}
