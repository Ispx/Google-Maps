import 'package:flutter/material.dart';
import 'package:google_maps_routes/controllers/maps_controller.dart';
import 'package:google_maps_routes/helpers/search_router_state_helper.dart';
import 'package:google_maps_routes/views/home_page.dart';
import 'package:provider/provider.dart';

class SearchAddressPage extends StatefulWidget {
  final String? hint;
  const SearchAddressPage({Key? key, this.hint}) : super(key: key);

  @override
  State<SearchAddressPage> createState() => _SearchAddressPageState();
}

class _SearchAddressPageState extends State<SearchAddressPage> {
  TextEditingController textEditingController = TextEditingController();
  MapsController mapsController = MapsController();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    textEditingController.addListener(() {
      if (mapsController.searchRouteState == SearchRouterStateHelper.SEARCHING)
        return;
      mapsController.searhAddress(textEditingController.text);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SizedBox(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        child: ChangeNotifierProvider.value(
          value: mapsController,
          builder: (context, _) {
            return Consumer<MapsController>(
              builder: (context, valueController, _) {
                return Column(
                  children: [
                    TextField(
                      controller: textEditingController,
                      autofocus: true,
                      decoration: InputDecoration(
                        labelText: 'Pesquisar endereço',
                        hintText: widget.hint,
                      ),
                    ),
                    valueController.searchRouteState ==
                            SearchRouterStateHelper.SEARCHING
                        ? SizedBox(
                            height: 2,
                            width: double.maxFinite,
                            child: LinearProgressIndicator(),
                          )
                        : Center(),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            if (valueController.mapLocationPlaceMark.isNotEmpty)
                              ...valueController
                                  .mapLocationPlaceMark.values.single
                                  .map(
                                (e) => InkWell(
                                  onTap: () => Navigator.pop(context, e),
                                  child: Column(
                                    children: [
                                      AddressWidget(address: e),
                                      Divider(),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}
