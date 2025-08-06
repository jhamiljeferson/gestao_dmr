import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/layouts/main_layout.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_loading.dart';
import '../../../shared/widgets/app_breadcrumbs.dart';
import '../../../config/theme.dart';
import '../../../shared/widgets/app_sidebar.dart';

final dashboardKpiProvider = FutureProvider<Map<String, String>>((ref) async {
  // Simulação: Substitua por chamada real ao backend/service
  await Future.delayed(const Duration(milliseconds: 500));
  return {
    'Empresas': '3',
    'Lojas': '12',
    'Vendas': 'R\$ 12.500',
    'Produtos': '320',
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
                            title: 'Empresas',
                            value: data['Empresas'] ?? '-',
                            icon: Icons.business,
                            color: AppColors.blue,
                          ),
                          _DashboardCard(
                            title: 'Lojas',
                            value: data['Lojas'] ?? '-',
                            icon: Icons.store,
                            color: AppColors.blueAccent,
                          ),
                          _DashboardCard(
                            title: 'Produtos',
                            value: data['Produtos'] ?? '-',
                            icon: Icons.inventory_2,
                            color: AppColors.blueDark,
                          ),
                          _DashboardCard(
                            title: 'Vendas',
                            value: data['Vendas'] ?? '-',
                            icon: Icons.attach_money,
                            color: AppColors.blue,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Últimas atividades',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListView.separated(
                  padding: const EdgeInsets.all(10),
                  itemCount: 5, // Simulação
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.blueLight,
                        child: Icon(
                          Icons.check_circle,
                          color: AppColors.blueAccent,
                        ),
                      ),
                      title: Text(
                        'Atividade ${index + 1}',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      subtitle: Text(
                        'Descrição da atividade ${index + 1}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      trailing: Text(
                        'Agora',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    );
                  },
                ),
              ),
            ),
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
        ? 16
        : width < 400
        ? 20
        : width < 700
        ? 28
        : 32;

    final double valueFontSize = width < 320
        ? 14
        : width < 400
        ? 18
        : width < 700
        ? 22
        : 26;

    final double titleFontSize = width < 320
        ? 10
        : width < 400
        ? 12
        : width < 700
        ? 14
        : 16;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      shadowColor: color.withOpacity(0.2),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.15),
              child: Icon(icon, color: color, size: iconSize),
            ),
            const SizedBox(width: 16),
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
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(fontSize: titleFontSize),
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
