import 'package:apple_maps_flutter/apple_maps_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
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
                  var polygons = controller.polygonList.value;
                  return AppleMap(
                    polygons: !controller.moving.value?polygons:{},
                    mapType: MapType.hybridFlyover,
                    compassEnabled: false,
                    onMapCreated: controller.onMapCreated,
                    initialCameraPosition: const CameraPosition(
                      target: LatLng(0.0, 0.0),
                    ),
                    onCameraMove: (position) =>
                        controller.onCameraMove(position),
                  );
                }),
                Obx(
                  () => controller.polygonList.isEmpty == true
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
                              controller.drawPolygonAtCenter(context);
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
                        // const Column(
                        //   children: [
                        //     Text(
                        //       'Move now',
                        //       style:
                        //           TextStyle(color: Colors.white, fontSize: 30),
                        //     ),
                        //     SizedBox(
                        //       height: 0,
                        //     )
                        //   ],
                        // ),
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
                Obx(() {
                  return controller.moving.value?Center(
                      // child: assets/png/temp.svg,
                      child: Image.asset(
                    'assets/png/custom_marker_two.png',
                    // 'assets/png/temp.svg,',
                    height: 40,
                    width: 40,
                  )):const SizedBox();
                })
              ],
            ),
          ),
          floatingActionButton: Obx(
            () => controller.polygonList.isNotEmpty == true
                ? FloatingActionButton(
                    child: const Icon(Icons.clear),
                    onPressed: () {
                      controller.onClearAllData();
                    },
                  )
                : const SizedBox(),
          )),
    );
  }
}
