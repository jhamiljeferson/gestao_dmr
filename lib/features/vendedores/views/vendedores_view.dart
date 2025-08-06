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
import '../models/vendedor_model.dart';
import '../controllers/vendedor_controller.dart';

class VendedoresView extends ConsumerStatefulWidget {
  const VendedoresView({Key? key}) : super(key: key);

  @override
  ConsumerState<VendedoresView> createState() => _VendedoresViewState();
}

class _VendedoresViewState extends ConsumerState<VendedoresView> {
  final _searchController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  bool _isLoading = false;
  Vendedor? _editingVendedor;

  @override
  void dispose() {
    _searchController.dispose();
    _nomeController.dispose();
    super.dispose();
  }

  void _showVendedorDialog({Vendedor? vendedor}) {
    _editingVendedor = vendedor;
    if (vendedor != null) {
      _nomeController.text = vendedor.nome;
    } else {
      _nomeController.clear();
    }

    showDialog(
      context: context,
      builder: (context) => AppDialog(
        title: vendedor == null ? 'Novo Vendedor' : 'Editar Vendedor',
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
            onPressed: _isLoading ? null : _saveVendedor,
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveVendedor() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final nome = _nomeController.text.trim();

      if (_editingVendedor == null) {
        // Criar novo vendedor
        final novoVendedor = Vendedor(
          id: '', // Será gerado pelo banco
          nome: nome,
        );
        await ref
            .read(vendedorControllerProvider.notifier)
            .createVendedor(novoVendedor);
        AppFeedback.showSuccess(context, 'Vendedor criado com sucesso!');
      } else {
        // Atualizar vendedor existente
        final vendedorAtualizado = _editingVendedor!.copyWith(nome: nome);
        await ref
            .read(vendedorControllerProvider.notifier)
            .updateVendedor(vendedorAtualizado);
        AppFeedback.showSuccess(context, 'Vendedor atualizado com sucesso!');
      }

      Navigator.of(context).pop();
    } catch (e) {
      AppFeedback.showError(context, e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteVendedor(Vendedor vendedor) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => const ConfirmDialog(
        title: 'Confirmar Exclusão',
        message: 'Tem certeza que deseja excluir este vendedor?',
        confirmText: 'Excluir',
      ),
    );

    if (confirmed == true) {
      try {
        await ref
            .read(vendedorControllerProvider.notifier)
            .deleteVendedor(vendedor.id);
        AppFeedback.showSuccess(context, 'Vendedor excluído com sucesso!');
      } catch (e) {
        AppFeedback.showError(context, e.toString());
      }
    }
  }

  void _searchVendedores(String query) {
    ref.read(vendedorControllerProvider.notifier).searchVendedores(query);
  }

  @override
  Widget build(BuildContext context) {
    final vendedoresState = ref.watch(vendedorControllerProvider);

    return MainLayout(
      title: 'Vendedores',
      breadcrumbs: const [BreadcrumbItem('Vendedores')],
      selectedSidebarIndex: 3, // Índice do item Vendedores no sidebar
      onSidebarItemSelected: (i) => context.go(sidebarItemsWithRoutes[i].route),
      actions: [
        SizedBox(
          width: 300,
          child: AppTextField(
            label: 'Buscar vendedores...',
            controller: _searchController,
            onChanged: _searchVendedores,
            prefixIcon: Icon(Icons.search),
          ),
        ),
        const SizedBox(width: 16),
        ElevatedButton.icon(
          onPressed: () => _showVendedorDialog(),
          icon: const Icon(Icons.add),
          label: const Text('Novo Vendedor'),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: vendedoresState.when(
          loading: () => const Center(child: AppLoading()),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Erro ao carregar vendedores: $error'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref
                      .read(vendedorControllerProvider.notifier)
                      .loadVendedores(),
                  child: const Text('Tentar Novamente'),
                ),
              ],
            ),
          ),
          data: (vendedores) => vendedores.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.people_outline,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Nenhum vendedor encontrado',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Clique em "Novo Vendedor" para começar',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: vendedores.length,
                  itemBuilder: (context, index) {
                    final vendedor = vendedores[index];
                    return AppCard(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.blueLight,
                          child: Icon(Icons.person, color: AppColors.blue),
                        ),
                        title: Text(
                          vendedor.nome,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text('Vendedor'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.edit,
                                color: AppColors.blue,
                              ),
                              onPressed: () =>
                                  _showVendedorDialog(vendedor: vendedor),
                              tooltip: 'Editar',
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteVendedor(vendedor),
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
