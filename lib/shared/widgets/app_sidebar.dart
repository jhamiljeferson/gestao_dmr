import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../features/auth/controllers/auth_controller.dart';

class SidebarItemWithRoute {
  final IconData icon;
  final String label;
  final String route;
  const SidebarItemWithRoute({
    required this.icon,
    required this.label,
    required this.route,
  });
}

const List<SidebarItemWithRoute> sidebarItemsWithRoutes = [
  SidebarItemWithRoute(
    icon: Icons.dashboard,
    label: 'Dashboard',
    route: '/dashboard',
  ),
  SidebarItemWithRoute(icon: Icons.store, label: 'Lojas', route: '/lojas'),
  SidebarItemWithRoute(
    icon: Icons.inventory,
    label: 'Produtos',
    route: '/produtos',
  ),
  SidebarItemWithRoute(
    icon: Icons.people,
    label: 'Vendedores',
    route: '/vendedores',
  ),
  SidebarItemWithRoute(
    icon: Icons.receipt_long,
    label: 'Vendas',
    route: '/vendas',
  ),
  SidebarItemWithRoute(
    icon: Icons.add_box,
    label: 'Entradas',
    route: '/entradas',
  ),
  SidebarItemWithRoute(
    icon: Icons.remove_circle,
    label: 'Saídas',
    route: '/saidas',
  ),
  SidebarItemWithRoute(
    icon: Icons.assessment,
    label: 'Relatório',
    route: '/relatorio-movimentacoes',
  ),
  SidebarItemWithRoute(
    icon: Icons.inventory_2,
    label: 'Estoque',
    route: '/estoque',
  ),
  SidebarItemWithRoute(
    icon: Icons.settings,
    label: 'Configurações',
    route: '/configuracoes',
  ),
];

class AppSidebar extends ConsumerWidget {
  final int selectedIndex;
  final void Function(int) onItemSelected;
  final bool isCollapsed;

  const AppSidebar({
    Key? key,
    required this.selectedIndex,
    required this.onItemSelected,
    this.isCollapsed = false,
  }) : super(key: key);

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Logout'),
        content: const Text('Tem certeza que deseja sair do sistema?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sair'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Usar o authProvider para fazer logout
        await ref.read(authProvider.notifier).logout();
        // O redirecionamento será automático pelo router
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao fazer logout: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: isCollapsed ? 60 : 220,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                DrawerHeader(
                  decoration: const BoxDecoration(color: AppColors.blue),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'ERP Multi-Lojas',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text('Menu', style: TextStyle(color: Colors.white70)),
                    ],
                  ),
                ),
                ...List.generate(sidebarItemsWithRoutes.length, (i) {
                  final item = sidebarItemsWithRoutes[i];
                  return ListTile(
                    leading: Icon(
                      item.icon,
                      color: i == selectedIndex
                          ? AppColors.blue
                          : AppColors.blueAccent,
                    ),
                    title: Text(item.label),
                    selected: selectedIndex == i,
                    selectedTileColor: AppColors.blueLight,
                    onTap: () {
                      context.go(item.route);
                      onItemSelected(i);
                    },
                  );
                }),
              ],
            ),
          ),
          // Botão de Logout no final da sidebar
          Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.grey.shade200, width: 1),
              ),
            ),
            child: ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Sair', style: TextStyle(color: Colors.red)),
              onTap: () => _logout(context, ref),
            ),
          ),
        ],
      ),
    );
  }
}
