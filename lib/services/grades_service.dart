import '../models/grade.dart';

class GradesService {
  Future<List<Semester>> fetchSemesters() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return _demo;
  }

  static const List<Semester> _demo = [
    Semester(
      title: '1 семестр (Осень 2022/2023)',
      grades: [
        Grade(discipline: 'Математика', controlType: 'Экзамен', mark: 'хорошо', score: 74),
        Grade(discipline: 'Физика', controlType: 'Экзамен', mark: 'удовлетворительно', score: 61),
        Grade(discipline: 'Введение в программирование', controlType: 'Зачёт', mark: 'зачтено'),
        Grade(discipline: 'История России', controlType: 'Зачёт', mark: 'зачтено'),
        Grade(discipline: 'Иностранный язык', controlType: 'Зачёт', mark: 'зачтено'),
        Grade(discipline: 'Физическая культура', controlType: 'Зачёт', mark: 'зачтено'),
      ],
    ),
    Semester(
      title: '2 семестр (Весна 2022/2023)',
      grades: [
        Grade(discipline: 'Математика (продолжение)', controlType: 'Экзамен', mark: 'хорошо', score: 77),
        Grade(discipline: 'Дискретная математика', controlType: 'Экзамен', mark: 'хорошо', score: 80),
        Grade(discipline: 'Основы информатики', controlType: 'Экзамен', mark: 'отлично', score: 91),
        Grade(discipline: 'Иностранный язык', controlType: 'Зачёт', mark: 'зачтено'),
        Grade(discipline: 'Физическая культура', controlType: 'Зачёт', mark: 'зачтено'),
        Grade(discipline: 'Экономика', controlType: 'Зачёт', mark: 'зачтено'),
      ],
    ),
    Semester(
      title: '3 семестр (Осень 2023/2024)',
      grades: [
        Grade(discipline: 'Алгоритмы и структуры данных', controlType: 'Экзамен', mark: 'отлично', score: 88),
        Grade(discipline: 'Объектно-ориентированное программирование', controlType: 'Экзамен', mark: 'хорошо', score: 82),
        Grade(discipline: 'Операционные системы', controlType: 'Экзамен', mark: 'хорошо', score: 79),
        Grade(discipline: 'Иностранный язык (профессиональный)', controlType: 'Зачёт', mark: 'зачтено'),
        Grade(discipline: 'Курсовая работа по ООП', controlType: 'Курсовая', mark: 'отлично', score: 93),
      ],
    ),
    Semester(
      title: '4 семестр (Весна 2023/2024)',
      grades: [
        Grade(discipline: 'Базы данных', controlType: 'Экзамен', mark: 'отлично', score: 92),
        Grade(discipline: 'Компьютерные сети', controlType: 'Экзамен', mark: 'хорошо', score: 83),
        Grade(discipline: 'Математическая статистика', controlType: 'Экзамен', mark: 'хорошо', score: 76),
        Grade(discipline: 'Веб-технологии', controlType: 'Зачёт', mark: 'зачтено'),
        Grade(discipline: 'Курсовая работа по БД', controlType: 'Курсовая', mark: 'хорошо', score: 85),
        Grade(discipline: 'Философия', controlType: 'Зачёт', mark: 'зачтено'),
      ],
    ),
    Semester(
      title: '5 семестр (Осень 2024/2025)',
      grades: [
        Grade(discipline: 'Программная инженерия', controlType: 'Экзамен', mark: 'отлично', score: 90),
        Grade(discipline: 'Теория автоматов', controlType: 'Экзамен', mark: 'хорошо', score: 78),
        Grade(discipline: 'Мобильная разработка', controlType: 'Зачёт', mark: 'зачтено'),
        Grade(discipline: 'Безопасность информационных систем', controlType: 'Зачёт', mark: 'зачтено'),
        Grade(discipline: 'Курсовая работа по ПИ', controlType: 'Курсовая', mark: 'отлично', score: 94),
      ],
    ),
    Semester(
      title: '6 семестр (Весна 2024/2025)',
      grades: [
        Grade(discipline: 'Качество и надёжность ПО', controlType: 'Экзамен', mark: 'хорошо', score: 81),
        Grade(discipline: 'Машинное обучение', controlType: 'Экзамен', mark: 'хорошо', score: 79),
        Grade(discipline: 'Разработка игр', controlType: 'Зачёт', mark: 'зачтено'),
        Grade(discipline: 'Иностранный язык делового общения', controlType: 'Зачёт', mark: 'зачтено'),
        Grade(discipline: 'Курсовая работа по МО', controlType: 'Курсовая', mark: 'хорошо', score: 84),
        Grade(discipline: 'Экономика предприятия', controlType: 'Зачёт', mark: 'зачтено'),
      ],
    ),
    Semester(
      title: '7 семестр (Осень 2025/2026)',
      grades: [
        Grade(discipline: 'Распределённые системы', controlType: 'Экзамен', mark: 'хорошо', score: 83),
        Grade(discipline: 'Визуализация данных', controlType: 'Зачёт', mark: 'зачтено'),
        Grade(discipline: 'Управление проектами', controlType: 'Зачёт', mark: 'зачтено'),
        Grade(discipline: 'Преддипломная практика', controlType: 'Зачёт', mark: 'зачтено'),
      ],
    ),
    Semester(
      title: '8 семестр (Весна 2025/2026)',
      grades: [
        Grade(discipline: 'Государственный экзамен', controlType: 'Экзамен', mark: '—'),
        Grade(discipline: 'Выпускная квалификационная работа', controlType: 'ВКР', mark: '—'),
      ],
    ),
  ];
}
