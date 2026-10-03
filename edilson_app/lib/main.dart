import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'credelec_api/credelec_api.dart';
import 'credelec_api/recharge_controller.dart';
import 'credelec_api/models.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CredelecApp());
}

class CredelecApp extends StatelessWidget {
  const CredelecApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Credelec Direct',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFFF58220),
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFF58220),
          primary: const Color(0xFFF58220),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const WelcomeScreen(),
        '/confirm': (context) => const ConfirmScreen(),
        '/payment': (context) => const PaymentScreen(),
        '/progress': (context) => const ProgressScreen(),
        '/keypad': (context) => const KeypadScreen(),
        '/dashboard': (context) => const DashboardScreen(),
      },
    );
  }
}

// ==========================================
// 1. ECRÃ DE BOAS-VINDAS (Com segurança de input)
// ==========================================
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final TextEditingController _meterController = TextEditingController();
  final RechargeController _controller = RechargeController();
  final _storage = const FlutterSecureStorage();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSavedMeter();
  }

  Future<void> _loadSavedMeter() async {
    String? savedMeter = await _storage.read(key: 'last_meter');
    if (savedMeter != null && mounted) {
      setState(() {
        _meterController.text = savedMeter;
      });
    }
  }

  void _proceed() async {
    String meter = _meterController.text.trim();
    if (meter.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Por favor, insira o número do contador.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    // Validação via backend controller
    MeterInfo? info = await _controller.verify(meter);
    setState(() => _isLoading = false);

    if (info != null) {
      // Salva de forma segura no dispositivo
      await _storage.write(key: 'last_meter', value: meter);
      if (mounted) {
        Navigator.pushNamed(context, '/confirm', arguments: info);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(_controller.errorMessage ?? 'Erro ao validar contador')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              RichText(
                text: const TextSpan(
                  text: 'Bem vindo ao\n',
                  style: TextStyle(
                      fontSize: 28,
                      color: Colors.black,
                      fontWeight: FontWeight.w300),
                  children: [
                    TextSpan(
                      text: 'Credelec Direct',
                      style: TextStyle(
                          fontSize: 32,
                          color: Color(0xFFF58220),
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Carregue rápido, seguro, e fácil!',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
              const SizedBox(height: 48),
              const Text('Número de Contador',
                  style: TextStyle(fontSize: 14, color: Colors.black54)),
              const SizedBox(height: 8),
              TextField(
                controller: _meterController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(11),
                ],
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  helperText:
                      'Contadores de teste: ${CredelecApi.availableMockMeters.join(', ')}',
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF58220),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: _isLoading ? null : _proceed,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Pagar',
                          style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 2. CONFIRME O CONTADOR
// ==========================================
class ConfirmScreen extends StatelessWidget {
  const ConfirmScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final MeterInfo meterInfo =
        ModalRoute.of(context)!.settings.arguments as MeterInfo;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Text(
                'Confirme o\ncontador',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
            ),
            const Center(
                child: Text('Leia atentamente',
                    style: TextStyle(color: Colors.grey))),
            const SizedBox(height: 32),
            _buildReadOnlyField('Número de Contador', meterInfo.meterNumber),
            const SizedBox(height: 16),
            _buildReadOnlyField('Local', meterInfo.location),
            const SizedBox(height: 16),
            _buildReadOnlyField('Tipo', meterInfo.type),
            const SizedBox(height: 24),
            const Text('Este é o carregador que deseja recarregar?',
                style: TextStyle(fontSize: 14, color: Colors.black87)),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF58220),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  Navigator.pushNamed(context, '/payment',
                      arguments: meterInfo);
                },
                child: const Text('Sim',
                    style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  side: const BorderSide(color: Color(0xFFF58220)),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text('Voltar',
                    style: TextStyle(fontSize: 16, color: Color(0xFFF58220))),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReadOnlyField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Text(value,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        ),
      ],
    );
  }
}

// ==========================================
// 3. EFECTUE O PAGAMENTO (M-Pesa / e-Mola)
// ==========================================
class PaymentScreen extends StatefulWidget {
  const PaymentScreen({Key? key}) : super(key: key);

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final TextEditingController _amountController =
      TextEditingController(text: '100.00');
  final TextEditingController _phoneController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String _selectedMethod = 'M-pesa';

  double get _calculatedKwh {
    double amount = double.tryParse(_amountController.text) ?? 0.0;
    return CredelecApi.calculateKwh(amount);
  }

  void _submitPayment(MeterInfo meterInfo) {
    if (!_formKey.currentState!.validate()) return;

    Navigator.pushNamed(
      context,
      '/progress',
      arguments: {
        'meter': meterInfo,
        'amount': double.parse(_amountController.text),
        'phone': _phoneController.text,
        'method': _selectedMethod,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final MeterInfo meterInfo =
        ModalRoute.of(context)!.settings.arguments as MeterInfo;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Text(
                  'Efectue o\npagamento',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                ),
              ),
              const Center(
                  child: Text('Insira dados correctos',
                      style: TextStyle(color: Colors.grey))),
              const SizedBox(height: 24),
              const Text('Valor',
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                onChanged: (val) => setState(() {}),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                validator: (value) {
                  final text = value?.trim() ?? '';
                  final amount = double.tryParse(text);
                  if (!RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(text) ||
                      amount == null ||
                      !amount.isFinite ||
                      amount <= 0) {
                    return 'Introduza um valor válido superior a 0 MT (máximo 2 casas decimais).';
                  }
                  return null;
                },
                decoration: const InputDecoration(
                    suffixText: 'MT', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              const Text('Quantidade estimada',
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8)),
                child: Text('${_calculatedKwh.toStringAsFixed(2)} kWh',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 16),
              const Text('Método de pagamento',
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
              DropdownButtonFormField<String>(
                initialValue: _selectedMethod,
                items: ['M-pesa', 'e-Mola', 'Visa']
                    .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                    .toList(),
                onChanged: (val) {
                  if (val == null) return;
                  if (CredelecApi.validatePhone(_phoneController.text, val) !=
                      null) {
                    _phoneController.clear();
                  }
                  setState(() => _selectedMethod = val);
                },
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              const Text('Número',
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(9),
                ],
                validator: (value) => CredelecApi.validatePhone(
                    value?.trim() ?? '', _selectedMethod),
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  hintText: _selectedMethod == 'M-pesa'
                      ? '84 ou 85, seguido de 7 dígitos'
                      : _selectedMethod == 'e-Mola'
                          ? '86 ou 87, seguido de 7 dígitos'
                          : '9 dígitos',
                  helperText: 'Introduza 9 dígitos, sem +258.',
                  counterText: '',
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF58220),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => _submitPayment(meterInfo),
                  child: const Text('Pagar',
                      style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8))),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar',
                      style: TextStyle(fontSize: 16, color: Colors.black54)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 4. CRÉDITO ENTREGUE (Processamento com Backend seguro)
// ==========================================
class ProgressScreen extends StatefulWidget {
  const ProgressScreen({Key? key}) : super(key: key);

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  final RechargeController _controller = RechargeController();
  bool _success = false;
  bool _started = false;
  RechargeResponse? _response;
  MeterInfo? _meter;
  double? _requestedKwh;
  String? _errorMessage;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _executeRecharge();
  }

  Future<void> _executeRecharge() async {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    if (args == null) return;

    MeterInfo meter = args['meter'];
    double amount = args['amount'];
    String phone = args['phone'];
    String method = args['method'];
    _meter = meter;
    _requestedKwh = CredelecApi.calculateKwh(amount);

    RechargeResponse? res = await _controller.recharge(
      meterNumber: meter.meterNumber,
      amount: amount,
      phone: phone,
      method: method,
    );

    if (res != null && mounted) {
      setState(() {
        _response = res;
        _success = true;
      });
    } else if (mounted) {
      setState(() => _errorMessage = _controller.errorMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Código Credelec',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
                '${_requestedKwh?.toStringAsFixed(2) ?? '0.00'} kWh solicitados\nContador: ${_meter?.meterNumber ?? ''}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey)),
            if (_response != null) ...[
              const SizedBox(height: 16),
              SelectableText(
                _response!.token,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ],
            const SizedBox(height: 48),
            if (!_success && _errorMessage == null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: const Row(
                  children: [
                    Text('Recarregando...',
                        style: TextStyle(fontWeight: FontWeight.w500)),
                    Spacer(),
                    Icon(Icons.hourglass_top, color: Colors.orange),
                  ],
                ),
              ),
            if (_errorMessage != null)
              Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            if (_success)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: const Row(
                  children: [
                    Text('Recarregado com sucesso..',
                        style: TextStyle(
                            fontWeight: FontWeight.w500, color: Colors.green)),
                    Spacer(),
                    Icon(Icons.check_circle, color: Colors.green),
                  ],
                ),
              ),
            const Spacer(),
            if (_success)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF58220),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => Navigator.pushNamed(
                    context,
                    '/keypad',
                    arguments: {'response': _response, 'meter': _meter},
                  ),
                  child: const Text('Ver crédito no contador',
                      style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.bold)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 5. TECLADO VIRTUAL / KEYPAD
// ==========================================
class KeypadScreen extends StatelessWidget {
  const KeypadScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map?;
    final RechargeResponse? response = args?['response'] as RechargeResponse?;
    final MeterInfo? meter = args?['meter'] as MeterInfo?;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade300),
              ),
              child: Column(
                children: [
                  const Text('CRÉDITO RECEBIDO',
                      style: TextStyle(
                          color: Colors.green, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('+${response?.kwh.toStringAsFixed(2) ?? '0.00'} kWh',
                        style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Contador: ${meter?.meterNumber ?? ''}'),
                  Text('Código: ${response?.token ?? ''}'),
                ],
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Column(
                children: [
                  _buildRow(['1', '2', '3']),
                  _buildRow(['4', '5', '6']),
                  _buildRow(['7', '8', '9']),
                  _buildRow(['*', '0', '#']),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: response == null
                      ? null
                      : () => Navigator.pushNamed(
                            context,
                            '/dashboard',
                            arguments: {'response': response, 'meter': meter},
                          ),
                  child: const Text('Concluir'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(List<String> items) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: items
            .map(
              (item) => CircleAvatar(
                radius: 30,
                backgroundColor: Colors.grey.shade200,
                child: Text(
                  item,
                  style: const TextStyle(fontSize: 22, color: Colors.black87),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

// ==========================================
// 6. O MEU CONTADOR & HISTÓRICO
// ==========================================
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map?;
    final RechargeResponse? response = args?['response'] as RechargeResponse?;
    final MeterInfo? meter = args?['meter'] as MeterInfo?;
    final double balanceKwh = response?.balanceKwh ?? meter?.balanceKwh ?? 0;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('O meu\ncontador',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
              const Text('Crédito disponível',
                  style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEEAD0),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${balanceKwh.toStringAsFixed(2)} kWh',
                        style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFD36200))),
                    const SizedBox(height: 4),
                    Text(meter?.location ?? 'Contador não seleccionado',
                        style: const TextStyle(color: Colors.black54)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text('Histórico',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  children: response == null
                      ? [const Text('Ainda não há recargas nesta sessão.')]
                      : [
                          _buildHistoryItem(
                            'Recarga: ${response.amount.toStringAsFixed(2)} MT · +${response.kwh.toStringAsFixed(2)} kWh · ${response.meterNumber}',
                          ),
                        ],
                ),
              ),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF58220),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => Navigator.pushNamed(context, '/'),
                  child: const Text('Comprar mais',
                      style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryItem(String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.history, size: 20, color: Colors.grey),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}
