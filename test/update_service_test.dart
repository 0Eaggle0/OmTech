import 'package:campus2_0/services/update_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('isNewer compares versions numerically, ignoring build suffix', () {
    expect(UpdateService.isNewer('1.2.1', '1.2.0'), isTrue);
    expect(UpdateService.isNewer('1.10.0', '1.9.9'), isTrue);
    expect(UpdateService.isNewer('2.0', '1.9.9'), isTrue);
    expect(UpdateService.isNewer('1.2.0', '1.2.0'), isFalse);
    expect(UpdateService.isNewer('1.2.0+40', '1.2.0'), isFalse);
    expect(UpdateService.isNewer('1.1.9', '1.2.0'), isFalse);
  });
}
