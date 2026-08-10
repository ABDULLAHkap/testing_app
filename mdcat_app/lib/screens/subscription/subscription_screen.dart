import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/api_client.dart';
import '../../theme/app_theme.dart';

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

  Color get _bg => context.pageBackground;
  Color get _card => context.panelColor;
  Color get _text => context.primaryTextColor;
  Color get _muted => context.secondaryTextColor;

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
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not load subscription: $error')),
        );
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
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Checkout could not start: $error')),
        );
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
    final price = (plan['price_pkr'] as num?)?.toInt() ?? 2000;
    final priceText = NumberFormat.decimalPattern().format(price);
    final days = (plan['days'] as num?)?.toInt() ?? 30;
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
                    decoration: BoxDecoration(
                      color: _card,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: _cyan.withOpacity(.35)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.workspace_premium,
                          color: _cyan,
                          size: 42,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          plan['name']?.toString() ?? '30-Day Unlimited Access',
                          style: TextStyle(
                            color: _text,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'PKR $priceText',
                          style: const TextStyle(
                            color: _cyan,
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text('for $days days', style: TextStyle(color: _muted)),
                        const SizedBox(height: 22),
                        const _Benefit('Unlimited practice tests'),
                        const _Benefit('Unlimited full mock tests'),
                        const _Benefit('All features for your selected exam'),
                        const _Benefit('Secure checkout through Safepay'),
                        const SizedBox(height: 22),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: configured && !_openingCheckout
                                ? _subscribe
                                : null,
                            icon: const Icon(Icons.lock_outline),
                            label: Text(
                              _openingCheckout
                                  ? 'Opening Safepay...'
                                  : 'Pay PKR $priceText',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  ListTile(
                    tileColor: _card,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    leading: const Icon(Icons.verified_outlined, color: _cyan),
                    title: Text(_expiryText(), style: TextStyle(color: _text)),
                    subtitle: Text(
                      '${_status?['free_tests_remaining'] ?? 0} free tests remaining',
                      style: TextStyle(color: _muted),
                    ),
                    trailing: IconButton(
                      tooltip: 'Refresh payment status',
                      onPressed: _load,
                      icon: Icon(Icons.refresh, color: _muted),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Sandbox mode uses test payments only. Access is activated only after Safepay sends a valid signed confirmation.',
                    style: TextStyle(color: _muted, fontSize: 12),
                  ),
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
    child: Row(
      children: [
        const Icon(Icons.check_circle, color: _cyan, size: 19),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: context.secondaryTextColor),
          ),
        ),
      ],
    ),
  );
}
