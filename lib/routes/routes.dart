import 'package:get/get.dart';
import 'package:polygen_new_implementation_ios/apple_map_example.dart';


class Routes {
  Routes._();

  static const String root = "/";
  static const String appleMapTwo = "/appleMapTwo";

}

List<GetPage> appPages() => [
GetPage(
name: Routes.root,
page: () => const AppleMapsExample(),
fullscreenDialog: true,
),
];