import 'package:fl_clash/common/common.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:fl_clash/features/vanq/vanq_api.dart';

/// VANQ Core plans page: anime-style plan cards, payment via Xboard web page.
class VanqPlansView extends ConsumerStatefulWidget {
  const VanqPlansView({super.key});

  @override
  ConsumerState<VanqPlansView> createState() => _VanqPlansViewState();
}

class _VanqPlansViewState extends ConsumerState<VanqPlansView> {
  List<VanqPlan>? _plans;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final plans = await VanqApi().getPlans();
      if (mounted) {
        setState(() {
          _plans = plans;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _buy(VanqPlan plan) async {
    // Open Xboard's own payment page in the browser.
    final uri = Uri.parse('${VanqApi.baseUrl}/#/plan');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      context.showSnackBar('无法打开支付页面');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('套餐')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('加载失败: $_error'),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () {
                      setState(() {
                        _loading = true;
                        _error = null;
                      });
                      _load();
                    },
                    child: const Text('重试'),
                  ),
                ],
              ),
            )
          : _plans!.isEmpty
          ? const Center(child: Text('暂无套餐'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _plans!.length,
              itemBuilder: (context, i) =>
                  _PlanCard(plan: _plans![i], onBuy: () => _buy(_plans![i])),
            ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final VanqPlan plan;
  final VoidCallback onBuy;

  const _PlanCard({required this.plan, required this.onBuy});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: ShapeDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF6C5CE7), Color(0xFFFD79A8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: AppShape.all(AppCorner.lg),
        shadows: [
          BoxShadow(
            color: const Color(0xFF6C5CE7).withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('🌸', style: TextStyle(fontSize: 28)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    plan.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            if (plan.content != null) ...[
              const SizedBox(height: 8),
              Text(
                plan.content!,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  '¥${plan.price.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: onBuy,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF6C5CE7),
                  ),
                  child: const Text('立即购买'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
