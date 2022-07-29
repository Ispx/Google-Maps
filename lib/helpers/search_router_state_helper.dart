enum SearchRouterStateHelper { INIT, SEARCHING, DONE }

extension SearchRouterStateHelperExt on SearchRouterStateHelper {
  static final Map<SearchRouterStateHelper, String> _map = {
    SearchRouterStateHelper.INIT: "Confirmar",
    SearchRouterStateHelper.SEARCHING: "Pesquisando",
    SearchRouterStateHelper.DONE: "Iniciar rota",
  };

  String get getDescription => _map[this]!;
}
