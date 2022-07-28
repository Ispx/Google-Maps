import 'package:cloud_functions/cloud_functions.dart';

class FirebaseFunctionsController {
  Future<void> getRoutes() async {
    HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('routes');
    final results = await callable();
    List fruit =
        results.data; // ["Apple", "Banana", "Cherry", "Date", "Fig", "Grapes"]
  }
}
