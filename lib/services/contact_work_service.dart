import '../controllers/lk_controller.dart';
import '../models/contact_work.dart';

/// Результат загрузки списка дисциплин.
class ContactWorkResult {
  final List<WorkDiscipline> items;
  final bool isDemo;
  final bool fromCache;

  const ContactWorkResult({
    required this.items,
    required this.isDemo,
    this.fromCache = false,
  });
}

/// Адаптер: если ЛК подключён — данные тянем из [LkContactWorkApi],
/// иначе отдаём демо-список.
class ContactWorkService {
  final LkController? lk;

  ContactWorkService({this.lk});

  /// Поток: сначала кэш (если есть), затем свежие данные с сервера.
  Stream<ContactWorkResult> watchDisciplines(
      {bool forceRefresh = false}) async* {
    final controller = lk;
    if (controller != null && controller.isConnected) {
      final cached = await controller.contactWorkApi.readDisciplinesCache();
      if (cached != null && !forceRefresh) {
        yield ContactWorkResult(
            items: cached, isDemo: false, fromCache: true);
      }
      try {
        final fresh = await controller.contactWorkApi.fetchDisciplinesFresh();
        yield ContactWorkResult(items: fresh, isDemo: false);
      } catch (_) {
        if (cached == null) {
          yield ContactWorkResult(items: _demo, isDemo: true);
        }
        rethrow;
      }
    } else {
      yield ContactWorkResult(items: _demo, isDemo: true);
    }
  }

  /// Поток заданий конкретной дисциплины. Используется на экране деталей.
  /// Если ЛК не подключён — отдаёт пустой список (детали демо-дисциплин
  /// уже лежат в самой `WorkDiscipline.items`).
  Stream<List<ContactWorkItem>> watchTasks(String disciplineId,
      {bool forceRefresh = false}) {
    final controller = lk;
    if (controller == null || !controller.isConnected) {
      return const Stream.empty();
    }
    return controller.contactWorkApi
        .watchTasks(disciplineId, forceRefresh: forceRefresh);
  }

  static final List<WorkDiscipline> _demo = [
    WorkDiscipline(
      discipline: 'Game-development',
      teachers: ['БЕЛЯЕВА К.И.', 'КОМАРОВА В.'],
      items: [
        ContactWorkItem(
          number: 1,
          comment:
              'Лекция №5 на тему "Игровой интерфейс. HUD. Механики интерфейса. Схема экранов. Макеты игровых экранов"',
          files: [
            WorkFile(
                name: 'Лекция 5.pdf',
                url: 'https://www.omgtu.ru/',
                type: 'pdf')
          ],
          createdAt: DateTime(2026, 4, 17, 15, 28),
          teacher: 'БЕЛЯЕВА Ксения Игоревна',
        ),
        ContactWorkItem(
          number: 2,
          comment:
              'Лекция №4 на тему "Gameplay. Игровые механики. Машина состояний"',
          files: [
            WorkFile(
                name: 'Лекция 4.pdf',
                url: 'https://www.omgtu.ru/',
                type: 'pdf')
          ],
          createdAt: DateTime(2026, 4, 17, 15, 27),
          teacher: 'БЕЛЯЕВА Ксения Игоревна',
        ),
        ContactWorkItem(
          number: 3,
          comment: 'Лекция №3 на тему "Сценарий игры и создание персонажей"',
          files: [
            WorkFile(
                name: 'Лекция 3.pdf',
                url: 'https://www.omgtu.ru/',
                type: 'pdf')
          ],
          createdAt: DateTime(2026, 4, 17, 15, 26),
          teacher: 'БЕЛЯЕВА Ксения Игоревна',
        ),
        ContactWorkItem(
          number: 4,
          comment: 'Лабораторные работы по Unity',
          files: [
            WorkFile(
                name: 'ЛР1. Знакомство с Unity.pdf',
                url: 'https://www.omgtu.ru/',
                type: 'pdf'),
            WorkFile(
                name: 'ЛР2. Создание интерфейса.pdf',
                url: 'https://www.omgtu.ru/',
                type: 'pdf'),
            WorkFile(
                name: 'ЛР3. Физика и коллайдеры.pdf',
                url: 'https://www.omgtu.ru/',
                type: 'pdf'),
          ],
          createdAt: DateTime(2026, 4, 10, 12, 0),
          teacher: 'КОМАРОВА В.',
        ),
        ContactWorkItem(
          number: 5,
          comment: 'Лекция №2 на тему "Жанры и концепция игры"',
          files: [
            WorkFile(
                name: 'Лекция 2.pdf',
                url: 'https://www.omgtu.ru/',
                type: 'pdf')
          ],
          createdAt: DateTime(2026, 4, 3, 10, 0),
          teacher: 'БЕЛЯЕВА Ксения Игоревна',
        ),
        ContactWorkItem(
          number: 6,
          comment: 'Лекция №1 на тему "Введение в разработку игр"',
          files: [
            WorkFile(
                name: 'Лекция 1.pdf',
                url: 'https://www.omgtu.ru/',
                type: 'pdf')
          ],
          createdAt: DateTime(2026, 3, 27, 9, 0),
          teacher: 'БЕЛЯЕВА Ксения Игоревна',
        ),
        ContactWorkItem(
          number: 7,
          comment: 'Методические указания по курсовой работе',
          files: [
            WorkFile(
                name: 'Курсовая работа.pdf',
                url: 'https://www.omgtu.ru/',
                type: 'pdf')
          ],
          createdAt: DateTime(2026, 3, 20, 14, 0),
          teacher: 'КОМАРОВА В.',
        ),
        ContactWorkItem(
          number: 8,
          comment: 'Дополнительные материалы по C# для Unity',
          files: [
            WorkFile(
                name: 'C# Basics.pdf',
                url: 'https://www.omgtu.ru/',
                type: 'pdf'),
            WorkFile(
                name: 'Unity API Reference.pdf',
                url: 'https://unity.com/',
                type: 'link'),
          ],
          createdAt: DateTime(2026, 3, 13, 11, 30),
          teacher: 'КОМАРОВА В.',
        ),
        ContactWorkItem(
          number: 9,
          comment: 'Требования к оформлению отчётов',
          files: [
            WorkFile(
                name: 'Требования.docx',
                url: 'https://www.omgtu.ru/',
                type: 'docx')
          ],
          createdAt: DateTime(2026, 3, 6, 9, 0),
          teacher: 'БЕЛЯЕВА Ксения Игоревна',
        ),
        ContactWorkItem(
          number: 10,
          comment: 'Примеры игровых проектов для изучения',
          files: [
            WorkFile(
                name: 'Примеры проектов.zip',
                url: 'https://www.omgtu.ru/',
                type: 'link'),
          ],
          createdAt: DateTime(2026, 2, 27, 16, 0),
          teacher: 'КОМАРОВА В.',
        ),
      ],
    ),
    WorkDiscipline(
      discipline: 'История России',
      teachers: ['МУЛИНА С.А.', 'НОСОВА М.С.'],
      items: [
        ContactWorkItem(
          number: 1,
          comment:
              'Методические рекомендации по подготовке к семинарским занятиям',
          files: [
            WorkFile(
                name: 'Метод. рек. семинары.pdf',
                url: 'https://www.omgtu.ru/',
                type: 'pdf')
          ],
          createdAt: DateTime(2026, 4, 15, 10, 0),
          teacher: 'МУЛИНА С.А.',
        ),
        ContactWorkItem(
          number: 2,
          comment: 'Темы рефератов и требования к оформлению',
          files: [
            WorkFile(
                name: 'Темы рефератов.docx',
                url: 'https://www.omgtu.ru/',
                type: 'docx')
          ],
          createdAt: DateTime(2026, 4, 8, 14, 0),
          teacher: 'НОСОВА М.С.',
        ),
        ContactWorkItem(
          number: 3,
          comment: 'Учебное пособие: Россия в XX веке',
          files: [
            WorkFile(
                name: 'Россия XX век.pdf',
                url: 'https://www.omgtu.ru/',
                type: 'pdf')
          ],
          createdAt: DateTime(2026, 4, 1, 9, 0),
          teacher: 'МУЛИНА С.А.',
        ),
        ContactWorkItem(
          number: 4,
          comment: 'Задание по теме "Отечественная война 1812 года"',
          files: [
            WorkFile(
                name: 'Задание 1812.pdf',
                url: 'https://www.omgtu.ru/',
                type: 'pdf')
          ],
          createdAt: DateTime(2026, 3, 25, 10, 0),
          teacher: 'НОСОВА М.С.',
        ),
        ContactWorkItem(
          number: 5,
          comment: 'Вопросы к зачёту',
          files: [
            WorkFile(
                name: 'Вопросы к зачёту.docx',
                url: 'https://www.omgtu.ru/',
                type: 'docx')
          ],
          createdAt: DateTime(2026, 3, 18, 11, 0),
          teacher: 'МУЛИНА С.А.',
        ),
      ],
    ),
    WorkDiscipline(
      discipline: 'Математика',
      teachers: ['БОВА Т.И.', 'СТРАТИЛАТОВА Е.Н.', 'ПРИВАЛОВА Ю.И.'],
      items: [
        ContactWorkItem(
          number: 1,
          comment:
              'Лекция: Дифференциальные уравнения. Теория и методы решения',
          files: [
            WorkFile(
                name: 'Диф. уравнения.pdf',
                url: 'https://www.omgtu.ru/',
                type: 'pdf')
          ],
          createdAt: DateTime(2026, 4, 20, 8, 30),
          teacher: 'БОВА Т.И.',
        ),
        ContactWorkItem(
          number: 2,
          comment:
              'Варианты контрольных работ по теме "Матрицы и определители"',
          files: [
            WorkFile(
                name: 'КР Матрицы.pdf',
                url: 'https://www.omgtu.ru/',
                type: 'pdf')
          ],
          createdAt: DateTime(2026, 4, 13, 9, 0),
          teacher: 'СТРАТИЛАТОВА Е.Н.',
        ),
        ContactWorkItem(
          number: 3,
          comment: 'Практические задания по интегральному исчислению',
          files: [
            WorkFile(
                name: 'Интегралы практика.pdf',
                url: 'https://www.omgtu.ru/',
                type: 'pdf')
          ],
          createdAt: DateTime(2026, 4, 6, 10, 0),
          teacher: 'ПРИВАЛОВА Ю.И.',
        ),
        ContactWorkItem(
          number: 4,
          comment: 'Лекция: Ряды Фурье и их применение',
          files: [
            WorkFile(
                name: 'Ряды Фурье.pdf',
                url: 'https://www.omgtu.ru/',
                type: 'pdf')
          ],
          createdAt: DateTime(2026, 3, 30, 8, 0),
          teacher: 'БОВА Т.И.',
        ),
        ContactWorkItem(
          number: 5,
          comment: 'Индивидуальные задания для самостоятельной работы',
          files: [
            WorkFile(
                name: 'Индив. задания.docx',
                url: 'https://www.omgtu.ru/',
                type: 'docx')
          ],
          createdAt: DateTime(2026, 3, 23, 11, 0),
          teacher: 'СТРАТИЛАТОВА Е.Н.',
        ),
      ],
    ),
    WorkDiscipline(
      discipline: 'Объектно-ориентированное программирование',
      teachers: ['УБАЛЕХТ И.П.', 'ВИКУЛОВ Е.О.'],
      items: [
        ContactWorkItem(
          number: 1,
          comment:
              'Лекция: Принципы ООП. Инкапсуляция, наследование, полиморфизм',
          files: [
            WorkFile(
                name: 'ООП Лекция 1.pdf',
                url: 'https://www.omgtu.ru/',
                type: 'pdf')
          ],
          createdAt: DateTime(2026, 4, 18, 9, 0),
          teacher: 'УБАЛЕХТ И.П.',
        ),
        ContactWorkItem(
          number: 2,
          comment: 'Лабораторная работа №1: Классы и объекты в C++',
          files: [
            WorkFile(
                name: 'ЛР1 ООП.pdf',
                url: 'https://www.omgtu.ru/',
                type: 'pdf'),
            WorkFile(
                name: 'Шаблон отчёта.docx',
                url: 'https://www.omgtu.ru/',
                type: 'docx'),
          ],
          createdAt: DateTime(2026, 4, 11, 10, 0),
          teacher: 'ВИКУЛОВ Е.О.',
        ),
        ContactWorkItem(
          number: 3,
          comment: 'Задание по теме "Паттерны проектирования"',
          files: [
            WorkFile(
                name: 'Паттерны.pdf',
                url: 'https://www.omgtu.ru/',
                type: 'pdf')
          ],
          createdAt: DateTime(2026, 4, 4, 14, 0),
          teacher: 'УБАЛЕХТ И.П.',
        ),
        ContactWorkItem(
          number: 4,
          comment: 'Вопросы к экзамену по ООП',
          files: [
            WorkFile(
                name: 'Вопросы к экзамену.docx',
                url: 'https://www.omgtu.ru/',
                type: 'docx')
          ],
          createdAt: DateTime(2026, 3, 28, 11, 0),
          teacher: 'УБАЛЕХТ И.П.',
        ),
      ],
    ),
  ];
}
