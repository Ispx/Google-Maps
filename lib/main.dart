import 'package:flutter/material.dart';
import 'package:google_maps_routes/utils/routers.dart';
import 'package:google_maps_routes/views/home_page.dart';
import 'package:google_maps_routes/views/permission_location_page.dart';
import 'package:google_maps_routes/views/search_address_page.dart';
import 'package:google_maps_routes/views/spash_page.dart';

final navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      initialRoute: Routes.SPLASH,
      onGenerateRoute: (onRouter) {
        var routerName = onRouter.name;
        if (routerName == Routes.SPLASH) {
          return MaterialPageRoute(builder: (context) => SplashPage());
        }
        if (routerName == Routes.HOME) {
          return MaterialPageRoute(builder: (context) => HomePage());
        }
        if (routerName == '${Routes.PERMISSION}/location') {
          return MaterialPageRoute(
            builder: (context) => PermissionLocationPage(),
          );
        }
        if (routerName == '/search-address/') {
          return MaterialPageRoute(
            builder: (context) => SearchAddressPage(
              hint: onRouter.arguments.toString(),
            ),
          );
        }
        return null;
      },
    );
  }
}
