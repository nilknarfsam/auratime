import 'package:auratime/domain/insights/insights_engine.dart';
import 'package:auratime/screens/widgets/dashboard_insights_panel.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Dashboard status-card insight filtering', () {
    test('Hides noisy overtime pattern message', () {
      const item = InsightItem(
        message: 'Padrão de hora extra em 4 dias recentes.',
        severity: InsightSeverity.success,
      );
      expect(shouldShowInsightInStatusCard(item), isFalse);
    });

    test('Keeps other insights visible', () {
      const item = InsightItem(
        message: 'Saldo médio diário (7 dias): +00:32',
        severity: InsightSeverity.success,
      );
      expect(shouldShowInsightInStatusCard(item), isTrue);
    });
  });
}
