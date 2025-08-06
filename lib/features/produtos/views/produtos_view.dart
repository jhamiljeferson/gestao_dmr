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
import '../models/produto_model.dart';
import '../controllers/produto_controller.dart';
import '../../estoque/controllers/estoque_controller.dart';

class ProdutosView extends ConsumerStatefulWidget {
  const ProdutosView({Key? key}) : super(key: key);

  @override
  ConsumerState<ProdutosView> createState() => _ProdutosViewState();
}

class _ProdutosViewState extends ConsumerState<ProdutosView> {
  final _searchController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _codigoController = TextEditingController();
  final _nomeController = TextEditingController();
  bool _isLoading = false;
  Produto? _editingProduto;

  @override
  void dispose() {
    _searchController.dispose();
    _codigoController.dispose();
    _nomeController.dispose();
    super.dispose();
  }

  void _showProdutoDialog({Produto? produto}) {
    _editingProduto = produto;
    if (produto != null) {
      _codigoController.text = produto.codigo.toString();
      _nomeController.text = produto.nome;
    } else {
      _codigoController.clear();
      _nomeController.clear();
    }

    showDialog(
      context: context,
      builder: (context) => AppDialog(
        title: produto == null ? 'Novo Produto' : 'Editar Produto',
        isLoading: _isLoading,
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              AppTextField(
                label: 'Código',
                controller: _codigoController,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Informe o código';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Código deve ser um número';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
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
            onPressed: _isLoading ? null : _saveProduto,
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveProduto() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final codigo = int.parse(_codigoController.text);
      final nome = _nomeController.text.trim();

      if (_editingProduto == null) {
        // Criar novo produto
        final novoProduto = Produto(
          id: '', // Será gerado pelo banco
          codigo: codigo,
          nome: nome,
        );
        await ref
            .read(produtoControllerProvider.notifier)
            .createProduto(novoProduto);

        // Invalidar provider de estoque para atualizar a lista
        ref.invalidate(estoqueProvider);

        AppFeedback.showSuccess(context, 'Produto criado com sucesso!');
      } else {
        // Atualizar produto existente
        final produtoAtualizado = _editingProduto!.copyWith(
          codigo: codigo,
          nome: nome,
        );
        await ref
            .read(produtoControllerProvider.notifier)
            .updateProduto(produtoAtualizado);
        AppFeedback.showSuccess(context, 'Produto atualizado com sucesso!');
      }

      Navigator.of(context).pop();
    } catch (e) {
      AppFeedback.showError(context, e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteProduto(Produto produto) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => const ConfirmDialog(
        title: 'Confirmar Exclusão',
        message: 'Tem certeza que deseja excluir este produto?',
        confirmText: 'Excluir',
      ),
    );

    if (confirmed == true) {
      try {
        await ref
            .read(produtoControllerProvider.notifier)
            .deleteProduto(produto.id);
        AppFeedback.showSuccess(context, 'Produto excluído com sucesso!');
      } catch (e) {
        AppFeedback.showError(context, e.toString());
      }
    }
  }

  void _searchProdutos(String query) {
    ref.read(produtoControllerProvider.notifier).searchProdutos(query);
  }

  @override
  Widget build(BuildContext context) {
    final produtosState = ref.watch(produtoControllerProvider);

    return MainLayout(
      title: 'Produtos',
      breadcrumbs: const [BreadcrumbItem('Produtos')],
      selectedSidebarIndex: 2, // Índice do item Produtos no sidebar
      onSidebarItemSelected: (i) => context.go(sidebarItemsWithRoutes[i].route),
      actions: [
        SizedBox(
          width: 300,
          child: AppTextField(
            label: 'Buscar produtos...',
            controller: _searchController,
            onChanged: _searchProdutos,
            prefixIcon: Icon(Icons.search),
          ),
        ),
        const SizedBox(width: 16),
        ElevatedButton.icon(
          onPressed: () => _showProdutoDialog(),
          icon: const Icon(Icons.add),
          label: const Text('Novo Produto'),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: produtosState.when(
          loading: () => const Center(child: AppLoading()),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Erro ao carregar produtos: $error'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref
                      .read(produtoControllerProvider.notifier)
                      .loadProdutos(),
                  child: const Text('Tentar Novamente'),
                ),
              ],
            ),
          ),
          data: (produtos) => produtos.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.inventory_2_outlined,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Nenhum produto encontrado',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Clique em "Novo Produto" para começar',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: produtos.length,
                  itemBuilder: (context, index) {
                    final produto = produtos[index];
                    return AppCard(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.blueLight,
                          child: Text(
                            produto.codigo.toString(),
                            style: const TextStyle(
                              color: AppColors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          produto.nome,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text('Código: ${produto.codigo}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.edit,
                                color: AppColors.blue,
                              ),
                              onPressed: () =>
                                  _showProdutoDialog(produto: produto),
                              tooltip: 'Editar',
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteProduto(produto),
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
