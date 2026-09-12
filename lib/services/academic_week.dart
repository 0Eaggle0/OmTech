/// Номер учебной недели и её чётность.
///
/// Считается локально от понедельника недели, в которую попадает 1 сентября
/// текущего учебного года: в API `rasp.omgtu.ru` этого поля нет.
/// Неделя 1 (та, что с 1 сентября) — нечётная.
({int number, bool isOdd}) academicWeekOf(DateTime date) {
  final academicYearStart = date.month >= 9 ? date.year : date.year - 1;
  final firstMonday = mondayOf(DateTime(academicYearStart, 9, 1));
  final weeksSince = mondayOf(date).difference(firstMonday).inDays ~/ 7;
  final number = weeksSince + 1;
  return (number: number, isOdd: number.isOdd);
}

DateTime mondayOf(DateTime d) {
  final day = DateTime(d.year, d.month, d.day);
  return day.subtract(Duration(days: day.weekday - DateTime.monday));
}
