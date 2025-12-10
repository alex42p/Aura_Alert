import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import 'package:aura_alert/services/algorithm_service.dart';
import 'package:aura_alert/services/notification_service.dart';

class FakeNotifier implements NotificationService {
  final List<String> messages = [];

  @override
  final unreadCount = ValueNotifier<int>(0);

  @override
  Future<void> init() async {}

  @override
  Future<void> sendNotification(String message) async {
    messages.add(message);
    // simulate persisted unread count increment
    unreadCount.value = unreadCount.value + 1;
  }

  @override
  Future<void> markRead(int id) async {
    // marking read in this fake won't inspect DB — just decrement unread count
    unreadCount.value = (unreadCount.value - 1).clamp(0, 9999);
  }

  @override
  Future<int> clearReadNotifications() async {
    final removed = unreadCount.value;
    unreadCount.value = 0;
    return removed;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AlgorithmService', () {
    setUp(() {
      // reset state between tests
      AlgorithmService.instance.clear();
    });

    test('classifies normal and does not notify', () {
      final svc = AlgorithmService.instance;
      final fake = FakeNotifier();
      svc.notifier = fake;

      final ts = DateTime.now();

      svc.addReading('hr', svc.hrBaseline, ts);
      svc.addReading('o2', svc.o2Max, ts);
      svc.addReading('temp', svc.tempBaseline, ts);

      expect(svc.currentSI, isNotNull);
      expect(svc.currentStressLevel, equals(StressLevel.normal));
      expect(fake.messages, isEmpty);
    });

    test('detects moderate and high stress and sends notifications with cooldown', () async {
      final svc = AlgorithmService.instance;
      final fake = FakeNotifier();
      svc.notifier = fake;

      // shorten cooldown for test speed
      svc.notificationCooldown = const Duration(seconds: 5);

      final ts = DateTime.now();

      // create inputs that produce a moderate SI (~0.65)
      // under the current weights HR dominates so pick hrNorm ~0.7
      final hrValModerate = svc.hrBaseline + 0.7 * (svc.hrMax - svc.hrBaseline);
      final o2ValModerate = svc.o2Min + 0.5 * (svc.o2Max - svc.o2Min);
      final tempValModerate = svc.tempBaseline + 0.7 * (svc.tempMax - svc.tempBaseline);

      svc.addReading('hr', hrValModerate, ts);
      svc.addReading('o2', o2ValModerate, ts);
      svc.addReading('temp', tempValModerate, ts);

      expect(svc.currentStressLevel, equals(StressLevel.moderate));
      expect(fake.messages.length, equals(1));
      expect(fake.messages.first, contains('MODERATE'));

      // second similar reading within cooldown -> should not spam
      svc.addReading('hr', hrValModerate, ts.add(const Duration(seconds: 1)));
      svc.addReading('o2', o2ValModerate, ts.add(const Duration(seconds: 1)));
      svc.addReading('temp', tempValModerate, ts.add(const Duration(seconds: 1)));

      expect(fake.messages.length, equals(1));

      // escalate to a HIGH stress reading
      final hrValHigh = svc.hrMax;
      final o2ValHigh = svc.o2Min; // low O2
      final tempValHigh = svc.tempMax;

      // advance beyond the sliding window so previous moderate samples are evicted
      svc.addReading('hr', hrValHigh, ts.add(const Duration(minutes: 6)));
      svc.addReading('o2', o2ValHigh, ts.add(const Duration(minutes: 6)));
      svc.addReading('temp', tempValHigh, ts.add(const Duration(minutes: 6)));

      // should notify again (different level)
      expect(svc.currentStressLevel, equals(StressLevel.high));
      expect(fake.messages.length, equals(2));
      expect(fake.messages.last, contains('HIGH'));
    });
  });
}
