enum CollectionsHelper { IN_ROUTER, ROUTERS }

extension CollectionsHelperExt on CollectionsHelper {
  static Map<CollectionsHelper, String> get _map => {
        CollectionsHelper.IN_ROUTER: 'in-router',
        CollectionsHelper.ROUTERS: 'routes',
      };

  String get getString => _map[this]!;
}
