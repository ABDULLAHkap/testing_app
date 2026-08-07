import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/api_client.dart';

const _bg = Color(0xFF061320);
const _card = Color(0xFF101F32);
const _cyan = Color(0xFF20D5C5);

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final ApiClient _api = ApiClient();
  Map<String, dynamic>? _status;
  bool _loading = true;
  bool _openingCheckout = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final status = await _api.getSubscriptionStatus();
      if (mounted) setState(() => _status = status);
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not load subscription: $error')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _subscribe() async {
    setState(() => _openingCheckout = true);
    try {
      final checkout = await _api.createSubscriptionCheckout('monthly');
      final uri = Uri.parse(checkout['checkout_url'].toString());
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw Exception('Could not open Safepay checkout');
      }
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Checkout could not start: $error')));
    } finally {
      if (mounted) setState(() => _openingCheckout = false);
    }
  }

  String _expiryText() {
    final raw = _status?['subscription_expires_at'];
    if (raw == null) return 'Not subscribed';
    return 'Active until ${DateFormat.yMMMd().format(DateTime.parse(raw).toLocal())}';
  }

  @override
  Widget build(BuildContext context) {
    final plan = Map<String, dynamic>.from(_status?['plan'] ?? const {});
    final configured = _status?['checkout_configured'] == true;
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(title: const Text('Subscription'), backgroundColor: _bg),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(22), border: Border.all(color: _cyan.withOpacity(.35))),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.workspace_premium, color: _cyan, size: 42),
                        const SizedBox(height: 16),
                        Text(plan['name']?.toString() ?? '30-Day Unlimited Access', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        const Text('PKR 2,000', style: TextStyle(color: _cyan, fontSize: 30, fontWeight: FontWeight.w800)),
                        const Text('for 30 days', style: TextStyle(color: Colors.white54)),
                        const SizedBox(height: 22),
                        const _Benefit('Unlimited practice tests'),
                        const _Benefit('Unlimited full mock tests'),
                        const _Benefit('All features for your selected exam'),
                        const _Benefit('Secure checkout through Safepay'),
                        const SizedBox(height: 22),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: configured && !_openingCheckout ? _subscribe : null,
                            icon: const Icon(Icons.lock_outline),
                            label: Text(_openingCheckout ? 'Opening Safepay...' : 'Pay PKR 2,000'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  ListTile(
                    tileColor: _card,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    leading: const Icon(Icons.verified_outlined, color: _cyan),
                    title: Text(_expiryText(), style: const TextStyle(color: Colors.white)),
                    subtitle: Text('${_status?['free_tests_remaining'] ?? 0} free tests remaining', style: const TextStyle(color: Colors.white54)),
                    trailing: IconButton(tooltip: 'Refresh payment status', onPressed: _load, icon: const Icon(Icons.refresh, color: Colors.white70)),
                  ),
                  const SizedBox(height: 12),
                  const Text('Sandbox mode uses test payments only. Access is activated only after Safepay sends a valid signed confirmation.', style: TextStyle(color: Colors.white54, fontSize: 12)),
                ],
              ),
            ),
    );
  }
}

class _Benefit extends StatelessWidget {
  final String text;
  const _Benefit(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(children: [
      const Icon(Icons.check_circle, color: _cyan, size: 19),
      const SizedBox(width: 10),
      Expanded(child: Text(text, style: const TextStyle(color: Colors.white70))),
    ]),
  );
}
