import 'package:apple_maps_flutter/apple_maps_flutter.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:async';
import 'package:polygen_new_implementation_ios/controller/apple_map_controller.dart';

class AppleMapsExample extends StatefulWidget {
  const AppleMapsExample({super.key});

  @override
  State<AppleMapsExample> createState() => _AppleMapsExampleState();
}

class _AppleMapsExampleState extends State<AppleMapsExample> {
  AppMapController controller = Get.put(AppMapController());

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      child: Scaffold(
        body: SafeArea(
          child: Stack(
            children: [
              Obx(() {
                print('inside build method called');
                var annotationList = controller.markerPositions.value;
                return AppleMap(
                  mapType: MapType.hybridFlyover,
                  // onTap: _onMarkerTap,
                  polygons: controller.polygon,
                  onLongPress: controller.onLongPress,
                  compassEnabled: false,
                  annotations: annotationList.keys.map((markerId) {
                    return Annotation(
                      annotationId: markerId,
                      draggable: true,
                      icon: BitmapDescriptor.defaultAnnotationWithHue(193),
                      // icon: iconUniCode != null
                      //     ? BitmapDescriptor.fromBytes(iconUniCode!)
                      //     : BitmapDescriptor.defaultAnnotation(20),
                      position: controller.markerPositions[markerId]!,
                      onDragStart: (value) => controller.onDragStart(value: value),
                      onDragEnd: (value) {
                        controller.onDragEnd(markerId, value, context);
                      },
                    );
                  }).toSet(),
                  onMapCreated: controller.onMapCreated,
                  initialCameraPosition: const CameraPosition(
                    target: LatLng(0.0, 0.0),
                  ),
                  onCameraMove: (position) =>
                      controller.onCameraMove(position, context),
                  onCameraIdle: () => controller.onCameraIdeal(),
                );
              }),
              Obx(
                () => controller.pentagonEnable.value
                    ? Positioned(
                        top: 50,
                        right: 20,
                        child: ElevatedButton(
                          style: ButtonStyle(
                            backgroundColor:
                                MaterialStateProperty.resolveWith((states) {
                              if (states.contains(MaterialState.pressed)) {
                                return Colors.green;
                              }
                              return Colors.blue;
                            }),
                            textStyle:
                                MaterialStateProperty.resolveWith((states) {
                              if (states.contains(MaterialState.pressed)) {
                                return const TextStyle(fontSize: 40);
                              }
                              return const TextStyle(fontSize: 20);
                            }),
                          ),
                          onPressed: () {
                            controller.getPentagonCoordinates(context);
                          },
                          child: const Text(
                            'Draw',
                            style: TextStyle(color: Colors.white),
                          ),
                        ))
                    : const SizedBox(),
              ),
              Positioned(
                top: 10,
                left: 0,
                right: 0,
                child: Center(
                  child: Column(
                    children: [
                      Obx(() => controller.isDraggingPolygon.value
                          ? const Column(
                              children: [
                                Text(
                                  'Move now',
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 30),
                                ),
                                SizedBox(
                                  height: 0,
                                )
                              ],
                            )
                          : const SizedBox()),
                      Obx(
                        () => controller.totalArea.value != null
                            ? Text(
                                '${controller.totalArea.value}',
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 25),
                              )
                            : const SizedBox(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: Obx(() {
          var haveMarkerList = controller.markerPositions.isNotEmpty;
          var pend = !controller.pentagonEnable.value;

          var show = haveMarkerList && pend;

          return show
              ? FloatingActionButton(
                  child: const Icon(Icons.clear),
                  onPressed: () {
                    controller.onClearAllData();
                  },
                )
              : const SizedBox();
        }),
      ),
    );
  }
}
