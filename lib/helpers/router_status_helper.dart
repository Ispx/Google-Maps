enum RouterStatusHelper { CREATED, ONGOING, DONE, CANCELED, CANCEL, END }

extension RouterStatusHelperExt on RouterStatusHelper {
  static Map<RouterStatusHelper, String> get mapToString => {
        RouterStatusHelper.CREATED: "Criado",
        RouterStatusHelper.ONGOING: "Em andamento",
        RouterStatusHelper.CANCELED: "Cancelado",
        RouterStatusHelper.DONE: "Finalizado",
        RouterStatusHelper.END: "Finalizar",
        RouterStatusHelper.CANCEL: "Cancelar",
      };

  String get getString => mapToString[this]!;
}
