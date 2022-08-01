enum RouterStatusHelper { ONGOING, DONE, CANCELED }

extension RouterStatusHelperExt on RouterStatusHelper {
  static Map<RouterStatusHelper, String> get mapToString => {
        RouterStatusHelper.ONGOING: "Em curso",
        RouterStatusHelper.CANCELED: "Cancelado",
        RouterStatusHelper.DONE: "Finalizado"
      };

  String get getString => mapToString[this]!;
}
