import 'package:auratime/domain/work_schedule/work_schedule_models.dart';

class HolidayPresets {
  static List<Holiday> brazilNational(int year) {
    return [
      Holiday(date: DateTime(year, 1, 1), name: 'Confraternização Universal'),
      Holiday(date: DateTime(year, 4, 21), name: 'Tiradentes'),
      Holiday(date: DateTime(year, 5, 1), name: 'Dia do Trabalhador'),
      Holiday(date: DateTime(year, 9, 7), name: 'Independência do Brasil'),
      Holiday(date: DateTime(year, 10, 12), name: 'Nossa Senhora Aparecida'),
      Holiday(date: DateTime(year, 11, 2), name: 'Finados'),
      Holiday(date: DateTime(year, 11, 15), name: 'Proclamação da República'),
      Holiday(date: DateTime(year, 11, 20), name: 'Dia da Consciência Negra'),
      Holiday(date: DateTime(year, 12, 25), name: 'Natal'),
    ];
  }

  static List<Holiday> manausAmazonas(int year) {
    return [
      Holiday(date: DateTime(year, 9, 5), name: 'Elevação do Amazonas'),
      Holiday(date: DateTime(year, 10, 24), name: 'Aniversário de Manaus'),
      Holiday(date: DateTime(year, 12, 8), name: 'Nossa Senhora da Conceição'),
    ];
  }
}
