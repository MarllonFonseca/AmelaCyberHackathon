import 'package:flutter_test/flutter_test.dart';
import 'package:credelec_direct/credelec_api/api_exception.dart';
import 'package:credelec_direct/credelec_api/credelec_api.dart';

void main() {
  group('Credelec mock data', () {
    test('finds only registered meters and their locations', () async {
      final api = CredelecApi();
      final meter = await api.verifyMeter('10000000001');

      expect(meter.location, 'Casa, Matola');
      expect(meter.type, 'Residencial');
      await expectLater(
          api.verifyMeter('12345678901'), throwsA(isA<ApiException>()));
    });

    test('uses 11 kWh per 100 MT and increments the meter balance', () async {
      final api = CredelecApi();
      final meter = await api.verifyMeter('10000000002');
      final response = await api.processPayment(
        meterNumber: meter.meterNumber,
        amount: 100,
        phone: '841234567',
        method: 'M-pesa',
      );
      final updatedMeter = await api.verifyMeter(meter.meterNumber);

      expect(CredelecApi.calculateKwh(100), 11);
      expect(response.kwh, 11);
      expect(response.meterNumber, meter.meterNumber);
      expect(response.balanceKwh, meter.balanceKwh + 11);
      expect(updatedMeter.balanceKwh, response.balanceKwh);
    });

    test('validates phone length and provider prefixes', () {
      expect(CredelecApi.validatePhone('841234567', 'M-pesa'), isNull);
      expect(CredelecApi.validatePhone('851234567', 'M-pesa'), isNull);
      expect(CredelecApi.validatePhone('861234567', 'e-Mola'), isNull);
      expect(CredelecApi.validatePhone('871234567', 'e-Mola'), isNull);
      expect(CredelecApi.validatePhone('861234567', 'M-pesa'), isNotNull);
      expect(CredelecApi.validatePhone('841234567', 'e-Mola'), isNotNull);
      expect(CredelecApi.validatePhone('84123456', 'M-pesa'), isNotNull);
      expect(CredelecApi.validatePhone('8412345670', 'M-pesa'), isNotNull);
    });

    test('rejects invalid payment amounts', () async {
      final api = CredelecApi();

      await expectLater(
        api.processPayment(
          meterNumber: '10000000001',
          amount: 0,
          phone: '841234567',
          method: 'M-pesa',
        ),
        throwsA(isA<ApiException>()),
      );
      await expectLater(
        api.processPayment(
          meterNumber: '10000000001',
          amount: 10.001,
          phone: '841234567',
          method: 'M-pesa',
        ),
        throwsA(isA<ApiException>()),
      );
    });
  });
}
