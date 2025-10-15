import 'package:get/get.dart';
import 'package:koduge_kart/controllers/auth_controller.dart';
import 'package:koduge_kart/controllers/donation_controller.dart';

class ControllerBindings extends Bindings {
  @override
  void dependencies() {
    // Initialize AuthController as a singleton
    Get.put(AuthController(), permanent: true);

    // Initialize DonationController
    Get.put(DonationController());
  }
}
