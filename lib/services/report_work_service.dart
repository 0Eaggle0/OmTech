import '../controllers/lk_controller.dart';
import '../models/report_work.dart';

/// Результат загрузки отчётных работ.
class ReportWorksOutcome {
  final ReportWorksResult result;
  final bool isDemo;
  final bool fromCache;

  const ReportWorksOutcome({
    required this.result,
    required this.isDemo,
    this.fromCache = false,
  });
}

/// Адаптер: если ЛК подключён — данные тянем из [LkReportWorkApi],
/// иначе отдаём демо-набор.
class ReportWorkService {
  final LkController? lk;

  ReportWorkService({this.lk});

  /// Поток: сначала кэш (если есть), затем свежие данные с сервера.
  Stream<ReportWorksOutcome> watch({bool forceRefresh = false}) async* {
    final controller = lk;
    if (controller != null && controller.isConnected) {
      final cached = await controller.reportWorkApi.readCache();
      if (cached != null && !forceRefresh) {
        yield ReportWorksOutcome(
            result: cached, isDemo: false, fromCache: true);
      }
      try {
        final fresh = await controller.reportWorkApi.fetchFresh();
        yield ReportWorksOutcome(result: fresh, isDemo: false);
      } catch (_) {
        if (cached == null) {
          yield ReportWorksOutcome(result: _demo, isDemo: true);
        }
        rethrow;
      }
    } else {
      yield ReportWorksOutcome(result: _demo, isDemo: true);
    }
  }

  static final ReportWorksResult _demo = ReportWorksResult(
    academicYear: 2025,
    courseWorks: [
      ReportCourseWork(
        hexnrec: 'demo-cw-1',
        groupName: 'ИСТ-241',
        studentName: 'ИВАНОВ Иван Иванович',
        workType: 'Проектная деятельность',
        title: 'Маркетинг нового цифрового продукта для сферы развлечений',
      ),
    ],
    otherWorks: [
      ReportWork(
        fileId: 'demo-1',
        date: DateTime(2026, 4, 9),
        discipline: 'История России',
        semester: 4,
        workNumber: '3067051',
        title: 'Домашняя работа',
        status: ReportWorkStatus.accepted,
        teacher: 'НОСОВА Марина Сергеевна',
        comment:
            'Неправильно оформленный титульный лист. Посмотрите ещё раз методические указания.',
      ),
      ReportWork(
        fileId: 'demo-2',
        date: DateTime(2026, 4, 7),
        discipline: 'Game-development',
        semester: 4,
        workNumber: '3063706',
        title: 'Лабораторная работа №3',
        status: ReportWorkStatus.accepted,
        teacher: 'КОМАРОВА Виктория',
        comment: null,
      ),
      ReportWork(
        fileId: 'demo-3',
        date: DateTime(2026, 5, 26),
        discipline: 'Проектирование архитектуры цифровых решений',
        semester: 4,
        workNumber: '3130400',
        title: 'Лабораторная работа №1',
        status: ReportWorkStatus.pending,
        teacher: '',
        comment: null,
      ),
      ReportWork(
        fileId: 'demo-4',
        date: DateTime(2024, 11, 8),
        discipline: 'Инфографика',
        semester: 1,
        workNumber: '2522871',
        title: 'Отчёт',
        status: ReportWorkStatus.rejected,
        teacher: 'БОЛЬШАКОВА Мария Сергеевна',
        comment: 'можно удалить',
      ),
    ],
  );
}
