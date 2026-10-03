import 'api_exception.dart';
import 'models.dart';

class CredelecApi {
  static const double kwhPer100Mzn = 11;
  static int _nextTransactionId = 1;

  static final Map<String, MeterInfo> _meters = {
    '10000000001': MeterInfo(
      meterNumber: '10000000001',
      location: 'Casa, Matola',
      type: 'Residencial',
      balanceKwh: 24,
    ),
    '10000000002': MeterInfo(
      meterNumber: '10000000002',
      location: 'Apartamento, Maputo',
      type: 'Residencial',
      balanceKwh: 8,
    ),
    '10000000003': MeterInfo(
      meterNumber: '10000000003',
      location: 'Casa, Beira',
      type: 'Residencial',
    ),
  };

  static List<String> get availableMockMeters =>
      List.unmodifiable(_meters.keys);

  static double calculateKwh(double amount) => amount * kwhPer100Mzn / 100;

  static String? validatePhone(String phone, String method) {
    if (!RegExp(r'^\d{9}$').hasMatch(phone)) {
      return 'O contacto deve conter exactamente 9 dígitos.';
    }

    final normalizedMethod = method.toLowerCase().replaceAll('-', '');
    if (normalizedMethod == 'mpesa' && !RegExp(r'^(84|85)').hasMatch(phone)) {
      return 'Para M-Pesa, use um contacto iniciado por 84 ou 85.';
    }
    if (normalizedMethod == 'emola' && !RegExp(r'^(86|87)').hasMatch(phone)) {
      return 'Para e-Mola, use um contacto iniciado por 86 ou 87.';
    }
    if (!['mpesa', 'emola', 'visa'].contains(normalizedMethod)) {
      return 'Método de pagamento inválido.';
    }
    return null;
  }

  Future<MeterInfo> verifyMeter(String meterNumber) async {
    final normalizedMeter = meterNumber.trim();
    if (!RegExp(r'^\d{11}$').hasMatch(normalizedMeter)) {
      throw ApiException('O número do contador deve conter 11 dígitos.');
    }

    await Future.delayed(const Duration(milliseconds: 800));
    final meter = _meters[normalizedMeter];
    if (meter == null) {
      throw ApiException(
          'Contador não encontrado no cadastro de demonstração.');
    }
    return meter;
  }

  Future<RechargeResponse> processPayment({
    required String meterNumber,
    required double amount,
    required String phone,
    required String method,
  }) async {
    if (!amount.isFinite || amount <= 0) {
      throw ApiException('O valor do carregamento deve ser superior a zero.');
    }
    if ((amount * 100 - (amount * 100).round()).abs() > 0.000001) {
      throw ApiException('O valor deve ter no máximo duas casas decimais.');
    }
    final phoneError = validatePhone(phone, method);
    if (phoneError != null) throw ApiException(phoneError);
    final meter = _meters[meterNumber];
    if (meter == null) {
      throw ApiException(
          'Contador não encontrado no cadastro de demonstração.');
    }

    await Future.delayed(const Duration(seconds: 2));
    final purchasedKwh = calculateKwh(amount);
    final updatedMeter = meter.copyWith(
      balanceKwh: meter.balanceKwh + purchasedKwh,
    );
    _meters[meterNumber] = updatedMeter;
    final transactionId = _nextTransactionId++;

    return RechargeResponse(
      token: 'MOCK-${transactionId.toString().padLeft(6, '0')}',
      kwh: purchasedKwh,
      status: 'success',
      meterNumber: meterNumber,
      amount: amount,
      balanceKwh: updatedMeter.balanceKwh,
    );
  }
}
