import 'package:cloud_functions/cloud_functions.dart';

class FirebaseFunctionsController {
  Future<void> getRoutes() async {
    HttpsCallable callable =
        FirebaseFunctions.instance.httpsCallable('en-route');
    final results = await callable();
    print(results.toString());
  }
}
