import 'package:chronora/core/utils/backend_date_time_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Funcionalidade: parser de horario do backend', () {
    test('trata LocalDateTime sem offset como UTC quando ha desvio de fuso',
        () {
      final parsed = BackendDateTimeParser.parse(
        '2026-06-17T15:02:00',
        now: DateTime(2026, 6, 17, 12, 0),
      );

      expect(parsed, DateTime.utc(2026, 6, 17, 15, 2).toLocal());
    });

    test('mantem LocalDateTime local quando nao ha desvio relevante', () {
      final parsed = BackendDateTimeParser.parse(
        '2026-06-17T12:02:00',
        now: DateTime(2026, 6, 17, 12, 0),
      );

      expect(parsed, DateTime(2026, 6, 17, 12, 2));
    });

    test('respeita timezone explicito quando o backend envia offset', () {
      final parsed = BackendDateTimeParser.parse('2026-06-17T15:02:00Z');

      expect(parsed, DateTime.utc(2026, 6, 17, 15, 2).toLocal());
    });
  });
}
