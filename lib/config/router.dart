import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/controllers/auth_controller.dart';
import '../features/auth/views/login_view.dart';
import '../features/dashboard/views/dashboard_view.dart';
import '../features/produtos/views/produtos_view.dart';
import '../features/pontos/views/pontos_view.dart';
import '../features/vendedores/views/vendedores_view.dart';
import '../features/vendas/views/vendas_view.dart';
import '../features/vendas/views/itens_venda_view.dart';
import '../features/movimentacoes/views/entradas_view.dart';
import '../features/movimentacoes/views/saidas_view.dart';
import '../features/estoque/views/estoque_view.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final isLoggedIn = authState;
      final isLoggingIn = state.uri.toString() == '/login';

      if (!isLoggedIn && !isLoggingIn) return '/login';
      if (isLoggedIn && isLoggingIn) return '/dashboard';

      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginView()),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardView(),
      ),
      GoRoute(path: '/lojas', builder: (context, state) => const PontosView()),
      GoRoute(
        path: '/produtos',
        builder: (context, state) => const ProdutosView(),
      ),
      GoRoute(
        path: '/vendedores',
        builder: (context, state) => const VendedoresView(),
      ),
      GoRoute(path: '/vendas', builder: (context, state) => const VendasView()),
      GoRoute(
        path: '/vendas/:vendaId/itens',
        builder: (context, state) {
          final vendaId = state.pathParameters['vendaId']!;
          return ItensVendaView(vendaId: vendaId);
        },
      ),
      GoRoute(
        path: '/entradas',
        builder: (context, state) => const EntradasView(),
      ),
      GoRoute(path: '/saidas', builder: (context, state) => const SaidasView()),
      GoRoute(
        path: '/estoque',
        builder: (context, state) => const EstoqueView(),
      ),
      GoRoute(
        path: '/configuracoes',
        builder: (context, state) => const Scaffold(
          body: Center(
            child: Text('Página de Configurações - Em desenvolvimento'),
          ),
        ),
      ),
      GoRoute(
        path: '/acesso-negado',
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('Acesso negado'))),
      ),
    ],
  );
});
