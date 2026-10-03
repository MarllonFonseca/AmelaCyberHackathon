import 'credelec_api.dart';
import 'models.dart';

class RechargeController {
  final CredelecApi _api = CredelecApi();

  bool isLoading = false;
  String? errorMessage;

  Future<MeterInfo?> verify(String meterNumber) async {
    isLoading = true;
    errorMessage = null;
    try {
      return await _api.verifyMeter(meterNumber);
    } catch (e) {
      errorMessage = e.toString();
      return null;
    } finally {
      isLoading = false;
    }
  }

  Future<RechargeResponse?> recharge({
    required String meterNumber,
    required double amount,
    required String phone,
    required String method,
  }) async {
    isLoading = true;
    errorMessage = null;
    try {
      return await _api.processPayment(
        meterNumber: meterNumber,
        amount: amount,
        phone: phone,
        method: method,
      );
    } catch (e) {
      errorMessage = e.toString();
      return null;
    } finally {
      isLoading = false;
    }
  }
}
