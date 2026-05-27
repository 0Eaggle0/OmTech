import '../models/course_material.dart';

/// Материалы курсов.
///
/// ЗАГЛУШКА: реальные данные доступны только через личный кабинет (авторизация).
/// Структура готова под подключение реального источника позже.
class MaterialsService {
  Future<List<CourseMaterial>> fetchMaterials() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return _demo;
  }

  static const List<CourseMaterial> _demo = [
    CourseMaterial(
      discipline: 'Базы данных',
      teacher: 'доц. Цыганенко В.Н.',
      files: [
        MaterialFile(name: 'Лекция 12. Транзакции.pdf', type: 'pdf', url: 'https://www.omgtu.ru/'),
        MaterialFile(name: 'Практикум по SQL.docx', type: 'docx', url: 'https://www.omgtu.ru/'),
        MaterialFile(name: 'Методичка к курсовой.pdf', type: 'pdf', url: 'https://www.omgtu.ru/'),
      ],
    ),
    CourseMaterial(
      discipline: 'Качество и надёжность ПО',
      teacher: 'доц. Цыганенко В.Н.',
      files: [
        MaterialFile(name: 'Слайды. Тестирование.pptx', type: 'pptx', url: 'https://www.omgtu.ru/'),
        MaterialFile(name: 'Список литературы', type: 'link', url: 'https://www.omgtu.ru/'),
      ],
    ),
    CourseMaterial(
      discipline: 'Веб-разработка',
      teacher: 'ст. преп. Иванов И.И.',
      files: [
        MaterialFile(name: 'Задание на лабораторную №5.pdf', type: 'pdf', url: 'https://www.omgtu.ru/'),
        MaterialFile(name: 'Шаблон проекта (репозиторий)', type: 'link', url: 'https://www.omgtu.ru/'),
      ],
    ),
  ];
}
