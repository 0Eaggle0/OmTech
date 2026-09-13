import 'package:campus2_0/models/contact_work.dart';
import 'package:campus2_0/services/teacher_contacts_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('extractContacts', () {
    test('почта, телеграм и телефон из одного сообщения', () {
      final c = extractContacts(
        'Добрый день! Мои контакты: почта ivanov.ii@omgtu.tech, '
        'тг @ivanov_teacher, тел. 8 (913) 123-45-67.',
      );
      expect(c.map((e) => e.kind), [
        TeacherContactKind.email,
        TeacherContactKind.telegram,
        TeacherContactKind.phone,
      ]);
      expect(c[0].value, 'ivanov.ii@omgtu.tech');
      expect(c[0].uri, 'mailto:ivanov.ii@omgtu.tech');
      expect(c[1].value, '@ivanov_teacher');
      expect(c[1].uri, 'https://t.me/ivanov_teacher');
      expect(c[2].value, '+7 (913) 123-45-67');
      expect(c[2].uri, 'tel:+79131234567');
    });

    test('email не порождает ложный telegram', () {
      final c = extractContacts('Отчёты присылайте на petrov@mail.ru');
      expect(c, hasLength(1));
      expect(c.single.kind, TeacherContactKind.email);
    });

    test('ссылка-приглашение t.me и «telegram:» без собачки', () {
      final c = extractContacts(
          'Чат группы: https://t.me/+AbCdEf123 ; telegram: sidorov_pp');
      expect(c.map((e) => e.value), ['t.me/+AbCdEf123', '@sidorov_pp']);
      expect(c.first.uri, 'https://t.me/+AbCdEf123');
    });

    test('«тг:» перед ссылкой не превращается в юзернейм https', () {
      final c = extractContacts('тг: https://t.me/kuznetsov_av');
      expect(c.map((e) => e.value), ['@kuznetsov_av']);
    });

    test('VK и MAX', () {
      final c = extractContacts(
          'Пишите в vk.com/id12345 или https://max.ru/u/abc123');
      expect(c.map((e) => e.kind),
          [TeacherContactKind.vk, TeacherContactKind.max]);
      expect(c.map((e) => e.value), ['vk.com/id12345', 'max.ru/u/abc123']);
    });

    test('дубликаты схлопываются, телефон приводится к +7', () {
      final c = extractContacts(
          '+7 913 123 45 67, повторю: 89131234567, @Ivanov_Teacher и @ivanov_teacher');
      expect(c.map((e) => e.value), ['@Ivanov_Teacher', '+7 (913) 123-45-67']);
    });

    test('обычное задание без контактов', () {
      expect(
        extractContacts(
            'Лабораторная работа №3. Срок сдачи 12.10.2025, вариант 8, аудитория 6-412'),
        isEmpty,
      );
    });
  });

  group('sameTeacher', () {
    test('полное ФИО, инициалы, регистр, ё и должность', () {
      expect(teacherKey('Иванов Иван Иванович'), 'иванов ии');
      expect(teacherKey('ИВАНОВ И.И.'), 'иванов ии');
      expect(sameTeacher('Иванов Иван Иванович', 'ИВАНОВ И.И.'), isTrue);
      expect(sameTeacher('Иванов И.', 'Иванов Иван Иванович'), isTrue);
      expect(sameTeacher('Семёнова А.В.', 'СЕМЕНОВА Анна Викторовна'), isTrue);
      expect(sameTeacher('доц. Иванов И.И.', 'Иванов И.И.'), isTrue);
    });

    test('однофамильцы и разные фамилии — разные люди', () {
      expect(sameTeacher('Иванов П.С.', 'Иванов Иван Иванович'), isFalse);
      expect(sameTeacher('Петров И.И.', 'Иванов И.И.'), isFalse);
      expect(sameTeacher('', 'Иванов И.И.'), isFalse);
    });
  });

  test('scanTasksForContacts: самые старые задания своего преподавателя', () {
    ContactWorkItem task(int n, String day, String teacher, String comment) =>
        ContactWorkItem(
          number: n,
          comment: comment,
          files: const [],
          createdAt: DateTime.parse(day),
          teacher: teacher,
        );
    final tasks = [
      task(3, '2025-10-20', 'ИВАНОВ И.И.', 'Лабораторная №2'),
      task(2, '2025-09-05', 'ПЕТРОВ П.П.', 'Мой тг @petrov_pp'),
      task(1, '2025-09-02', 'ИВАНОВ Иван Иванович',
          'Знакомство. Почта ivanov@omgtu.ru'),
      task(4, '2025-11-01', 'ИВАНОВ И.И.', 'Новый телеграм @ivanov_new'),
      // Дальше окна «первое найденное + два следующих» — не смотрим.
      task(5, '2025-12-01', 'ИВАНОВ И.И.', 'Телефон 89130000000'),
    ];
    final c = scanTasksForContacts(tasks, 'Иванов Иван Иванович');
    expect(c.map((e) => e.value), ['ivanov@omgtu.ru', '@ivanov_new']);
  });
}
