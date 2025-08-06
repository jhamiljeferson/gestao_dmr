import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/layouts/main_layout.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_loading.dart';
import '../../../shared/widgets/app_breadcrumbs.dart';
import '../../../config/theme.dart';
import '../../../shared/widgets/app_sidebar.dart';
import '../../../core/services/supabase_service.dart';
import 'package:intl/intl.dart';

final dashboardKpiProvider = FutureProvider<Map<String, String>>((ref) async {
  final supabase = SupabaseService().client;
  final now = DateTime.now();

  final todayStart = DateTime(now.year, now.month, now.day);
  final monthStart = DateTime(now.year, now.month, 1);

  // Vendas do dia
  final vendasHoje = await supabase
      .from('itens_venda')
      .select('vendidos, subtotal, venda_id, vendas!inner(data)')
      .gte('vendas.data', todayStart.toIso8601String());

  // Vendas do mês
  final vendasMes = await supabase
      .from('itens_venda')
      .select('vendidos, subtotal, venda_id, vendas!inner(data)')
      .gte('vendas.data', monthStart.toIso8601String());

  int qtdHoje = 0;
  double totalHoje = 0;
  for (final item in vendasHoje) {
    qtdHoje += (item['vendidos'] ?? 0) as int;
    totalHoje += (item['subtotal'] ?? 0) as num;
  }

  int qtdMes = 0;
  double totalMes = 0;
  for (final item in vendasMes) {
    qtdMes += (item['vendidos'] ?? 0) as int;
    totalMes += (item['subtotal'] ?? 0) as num;
  }
  // Estoque total
  final estoque = await supabase.from('estoque').select('quantidade');
  int qtdEstoque = 0;
  for (final item in estoque) {
    qtdEstoque += (item['quantidade'] ?? 0) as int;
  }
  final moeda = NumberFormat.simpleCurrency(locale: 'pt_BR');

  return {
    'Itens Hoje': '$qtdHoje',
    'Total Hoje': moeda.format(totalHoje),
    'Itens Mês': '$qtdMes',
    'Total Mês': moeda.format(totalMes),
    'Estoque Total': '$qtdEstoque peças',
  };
});

class DashboardView extends ConsumerWidget {
  const DashboardView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kpis = ref.watch(dashboardKpiProvider);
    final isWide = MediaQuery.of(context).size.width >= 900;
    return MainLayout(
      title: 'Dashboard',
      breadcrumbs: const [BreadcrumbItem('Dashboard')],
      selectedSidebarIndex: 0,
      onSidebarItemSelected: (i) => context.go(sidebarItemsWithRoutes[i].route),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () {},
          tooltip: 'Notificações',
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: CircleAvatar(
            backgroundColor: AppColors.blueAccent,
            child: const Icon(Icons.person, color: Colors.white),
          ),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            kpis.when(
              loading: () => const AppLoading(),
              error: (e, _) => Center(child: Text('Erro ao carregar KPIs')),
              data: (data) => LayoutBuilder(
                builder: (context, constraints) {
                  // Sempre 2 cards por linha, responsivo a partir de 320px
                  final double gridSpacing = 16;
                  final double minCardWidth = 240;
                  final int crossAxisCount = 2;
                  return Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 700),
                      child: GridView.count(
                        crossAxisCount: crossAxisCount,
                        shrinkWrap: true,
                        mainAxisSpacing: gridSpacing,
                        crossAxisSpacing: 0,
                        childAspectRatio: 1.5,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          _DashboardCard(
                            title: 'Itens Vendidos (Hoje)',
                            value: data['Itens Hoje'] ?? '-',
                            icon: Icons.shopping_bag,
                            color: Colors.green,
                          ),
                          _DashboardCard(
                            title: 'Total em R\$ (Hoje)',
                            value: data['Total Hoje'] ?? '-',
                            icon: Icons.attach_money,
                            color: Colors.green.shade700,
                          ),
                          _DashboardCard(
                            title: 'Itens Vendidos (Mês)',
                            value: data['Itens Mês'] ?? '-',
                            icon: Icons.shopping_cart,
                            color: Colors.orange,
                          ),
                          _DashboardCard(
                            title: 'Total em R\$ (Mês)',
                            value: data['Total Mês'] ?? '-',
                            icon: Icons.monetization_on,
                            color: Colors.orange.shade700,
                          ),
                          _DashboardCard(
                            title: 'Estoque Total',
                            value: data['Estoque Total'] ?? '-',
                            icon: Icons.inventory_2,
                            color: Colors.blue,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _DashboardCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final double iconSize = width < 320
        ? 14
        : width < 400
        ? 18
        : width < 700
        ? 24
        : 28;

    final double valueFontSize = width < 320
        ? 12
        : width < 400
        ? 14
        : width < 700
        ? 16
        : 18;

    final double titleFontSize = width < 320
        ? 8
        : width < 400
        ? 10
        : width < 700
        ? 12
        : 13;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      shadowColor: color.withOpacity(0.2),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.15),
              child: Icon(icon, color: color, size: iconSize),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    value,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: color,
                      fontSize: valueFontSize,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: titleFontSize,
                      letterSpacing:
                          -0.2, // reduz ligeiramente o espaçamento entre letras
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
