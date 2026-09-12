import 'package:flutter/material.dart';

import 'link_launcher.dart';

/// Корпус ОмГТУ → адрес.
const campusAddresses = {
  'УЛК-1': 'пр. Мира, 11',
  'УЛК-2': 'пр. Мира, 11к2',
  'УЛК-3': 'пр. Мира, 11к3',
  'УЛК-4': 'пр. Мира, 11к4',
  'УЛК-5': 'пр. Мира, 11к5',
  'УЛК-6': 'пр. Мира, 11к6',
  'УЛК-7': 'пр. Мира, 11к7',
  'УЛК-8': 'пр. Мира, 11к8',
  'ГУК': 'пр. Мира, 11',
  'СК': 'пр. Мира, 11',
};

/// Известен ли адрес корпуса — по этому решаем, показывать ли «Маршрут».
bool hasCampusAddress(String building) =>
    campusAddresses.containsKey(building);

/// Открывает корпус в Яндекс.Картах.
Future<void> openCampusRoute(BuildContext context, String building) {
  final address = campusAddresses[building];
  final query = Uri.encodeComponent(
    address != null ? '$building $address Омск' : '$building Омск ОмГТУ',
  );
  return openExternal(context, 'https://maps.yandex.ru/?text=$query');
}
