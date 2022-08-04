enum CollectionsHelper { EN_ROUTE, HISTORIC }

extension CollectionsHelperExt on CollectionsHelper {
  static Map<CollectionsHelper, String> get _map => {
        CollectionsHelper.EN_ROUTE: 'en-route',
        CollectionsHelper.HISTORIC: 'historic',
      };

  String get getString => _map[this]!;
}
