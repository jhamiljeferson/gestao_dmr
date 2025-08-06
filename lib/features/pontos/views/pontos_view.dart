import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/layouts/main_layout.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_loading.dart';
import '../../../shared/widgets/app_breadcrumbs.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/app_dialog.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../../../config/theme.dart';
import '../../../shared/widgets/app_sidebar.dart';
import '../models/ponto_model.dart';
import '../controllers/ponto_controller.dart';

class PontosView extends ConsumerStatefulWidget {
  const PontosView({Key? key}) : super(key: key);

  @override
  ConsumerState<PontosView> createState() => _PontosViewState();
}

class _PontosViewState extends ConsumerState<PontosView> {
  final _searchController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  bool _isLoading = false;
  Ponto? _editingPonto;

  @override
  void dispose() {
    _searchController.dispose();
    _nomeController.dispose();
    super.dispose();
  }

  void _showPontoDialog({Ponto? ponto}) {
    _editingPonto = ponto;
    if (ponto != null) {
      _nomeController.text = ponto.nome;
    } else {
      _nomeController.clear();
    }

    showDialog(
      context: context,
      builder: (context) => AppDialog(
        title: ponto == null ? 'Novo Ponto de Venda' : 'Editar Ponto de Venda',
        isLoading: _isLoading,
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              AppTextField(
                label: 'Nome',
                controller: _nomeController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Informe o nome';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: _isLoading ? null : _savePonto,
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  Future<void> _savePonto() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final nome = _nomeController.text.trim();

      if (_editingPonto == null) {
        // Criar novo ponto
        final novoPonto = Ponto(
          id: '', // Será gerado pelo banco
          nome: nome,
        );
        await ref.read(pontoControllerProvider.notifier).createPonto(novoPonto);
        AppFeedback.showSuccess(context, 'Ponto de venda criado com sucesso!');
      } else {
        // Atualizar ponto existente
        final pontoAtualizado = _editingPonto!.copyWith(nome: nome);
        await ref
            .read(pontoControllerProvider.notifier)
            .updatePonto(pontoAtualizado);
        AppFeedback.showSuccess(
          context,
          'Ponto de venda atualizado com sucesso!',
        );
      }

      Navigator.of(context).pop();
    } catch (e) {
      AppFeedback.showError(context, e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deletePonto(Ponto ponto) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => const ConfirmDialog(
        title: 'Confirmar Exclusão',
        message: 'Tem certeza que deseja excluir este ponto de venda?',
        confirmText: 'Excluir',
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(pontoControllerProvider.notifier).deletePonto(ponto.id);
        AppFeedback.showSuccess(
          context,
          'Ponto de venda excluído com sucesso!',
        );
      } catch (e) {
        AppFeedback.showError(context, e.toString());
      }
    }
  }

  void _searchPontos(String query) {
    ref.read(pontoControllerProvider.notifier).searchPontos(query);
  }

  @override
  Widget build(BuildContext context) {
    final pontosState = ref.watch(pontoControllerProvider);

    return MainLayout(
      title: 'Pontos de Venda',
      breadcrumbs: const [BreadcrumbItem('Pontos de Venda')],
      selectedSidebarIndex: 1, // Índice do item Lojas no sidebar
      onSidebarItemSelected: (i) => context.go(sidebarItemsWithRoutes[i].route),
      actions: [
        SizedBox(
          width: 300,
          child: AppTextField(
            label: 'Buscar pontos...',
            controller: _searchController,
            onChanged: _searchPontos,
            prefixIcon: Icon(Icons.search),
          ),
        ),
        const SizedBox(width: 16),
        ElevatedButton.icon(
          onPressed: () => _showPontoDialog(),
          icon: const Icon(Icons.add),
          label: const Text('Novo Ponto'),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: pontosState.when(
          loading: () => const Center(child: AppLoading()),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Erro ao carregar pontos: $error'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () =>
                      ref.read(pontoControllerProvider.notifier).loadPontos(),
                  child: const Text('Tentar Novamente'),
                ),
              ],
            ),
          ),
          data: (pontos) => pontos.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.store_outlined,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Nenhum ponto de venda encontrado',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Clique em "Novo Ponto" para começar',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: pontos.length,
                  itemBuilder: (context, index) {
                    final ponto = pontos[index];
                    return AppCard(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.blueLight,
                          child: Icon(Icons.store, color: AppColors.blue),
                        ),
                        title: Text(
                          ponto.nome,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text('Ponto de Venda'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.edit,
                                color: AppColors.blue,
                              ),
                              onPressed: () => _showPontoDialog(ponto: ponto),
                              tooltip: 'Editar',
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deletePonto(ponto),
                              tooltip: 'Excluir',
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}
