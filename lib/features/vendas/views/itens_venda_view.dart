import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/layouts/main_layout.dart';
import '../../../shared/widgets/app_loading.dart';
import '../../../shared/widgets/app_breadcrumbs.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/app_dialog.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../../../config/theme.dart';
import '../../../shared/widgets/app_sidebar.dart';
import '../models/item_venda_model.dart';
import '../controllers/venda_controller.dart';
import '../../produtos/controllers/produto_controller.dart';
import '../../estoque/controllers/estoque_controller.dart';

class ItensVendaView extends ConsumerStatefulWidget {
  final String vendaId;

  const ItensVendaView({Key? key, required this.vendaId}) : super(key: key);

  @override
  ConsumerState<ItensVendaView> createState() => _ItensVendaViewState();
}

class _ItensVendaViewState extends ConsumerState<ItensVendaView> {
  final _formKey = GlobalKey<FormState>();
  final _retiradaController = TextEditingController();
  final _reposicaoController = TextEditingController();
  final _retornoController = TextEditingController();
  final _precoUnitarioController = TextEditingController();
  final _searchController = TextEditingController();

  bool _isLoading = false;
  ItemVenda? _editingItem;
  String? _selectedProdutoId;
  String _searchQuery = '';

  @override
  void dispose() {
    _retiradaController.dispose();
    _reposicaoController.dispose();
    _retornoController.dispose();
    _precoUnitarioController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _showItemDialog({ItemVenda? item}) {
    _editingItem = item;

    if (item != null) {
      _selectedProdutoId = item.produtoId;
      _retiradaController.text = item.retirada.toString();
      _reposicaoController.text = item.reposicao.toString();
      _retornoController.text = item.retorno.toString();
      _precoUnitarioController.text = item.precoUnitario.toString();
    } else {
      _selectedProdutoId = null;
      _retiradaController.clear();
      _reposicaoController.clear();
      _retornoController.clear();
      _precoUnitarioController.clear();
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: Container(
          constraints: const BoxConstraints(maxHeight: 500),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.blue,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      item == null ? Icons.add_shopping_cart : Icons.edit,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item == null ? 'Adicionar Item' : 'Editar Item',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (_isLoading)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Produto
                        Consumer(
                          builder: (context, ref, child) {
                            final produtosState = ref.watch(
                              produtoControllerProvider,
                            );
                            return produtosState.when(
                              loading: () => const CircularProgressIndicator(),
                              error: (error, stack) => Text('Erro: $error'),
                              data: (produtos) =>
                                  DropdownButtonFormField<String>(
                                    value: _selectedProdutoId,
                                    decoration: const InputDecoration(
                                      labelText: 'Produto',
                                      border: OutlineInputBorder(),
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                    ),
                                    items: produtos.map((produto) {
                                      return DropdownMenuItem(
                                        value: produto.id,
                                        child: Text(
                                          '${produto.codigo} - ${produto.nome}',
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedProdutoId = value;
                                      });
                                    },
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Selecione um produto';
                                      }
                                      return null;
                                    },
                                  ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),

                        // Quantidades
                        Row(
                          children: [
                            Expanded(
                              child: AppTextField(
                                label: 'Retirada',
                                controller: _retiradaController,
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Informe a retirada';
                                  }
                                  if (int.tryParse(value) == null) {
                                    return 'Valor deve ser um número';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: AppTextField(
                                label: 'Reposição',
                                controller: _reposicaoController,
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value != null && value.isNotEmpty && int.tryParse(value) == null) {
                                    return 'Valor deve ser um número';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: AppTextField(
                                label: 'Retorno',
                                controller: _retornoController,
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Informe o retorno';
                                  }
                                  if (int.tryParse(value) == null) {
                                    return 'Valor deve ser um número';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Preço Unitário
                        AppTextField(
                          label: 'Preço Unitário',
                          controller: _precoUnitarioController,
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Informe o preço unitário';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Valor deve ser um número';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Actions
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(8),
                    bottomRight: Radius.circular(8),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveItem,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.blue,
                          foregroundColor: Colors.white,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : Text(
                                _editingItem == null ? 'Adicionar' : 'Salvar',
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveItem() async {
    if (_isLoading) return; // Previne múltiplas execuções simultâneas
    
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final retirada = int.parse(_retiradaController.text);
      final reposicao = _reposicaoController.text.isEmpty ? 0 : int.parse(_reposicaoController.text);
      final retorno = int.parse(_retornoController.text);
      final precoUnitario = double.parse(_precoUnitarioController.text);
      final vendidos = ItemVenda.calcularVendidos(retirada, reposicao, retorno);
      final subtotal = ItemVenda.calcularSubtotal(vendidos, precoUnitario);

      // Verificar estoque antes de salvar o item
      final estoqueAtual = await ref
          .read(estoqueControllerProvider.notifier)
          .getEstoqueProduto(_selectedProdutoId!);

      if (estoqueAtual != null) {
        final estoqueDisponivel = estoqueAtual.quantidade;
        final estoqueRestante = estoqueDisponivel - vendidos;

        if (estoqueRestante < 0) {
          // Buscar nome do produto para mostrar no alerta
          final produtosState = ref.read(produtoControllerProvider);
          String nomeProduto = 'Produto';

          produtosState.when(
            loading: () => nomeProduto = 'Produto',
            error: (error, stack) => nomeProduto = 'Produto',
            data: (produtos) {
              try {
                final produto = produtos.firstWhere(
                  (p) => p.id == _selectedProdutoId,
                );
                nomeProduto = produto.nome;
              } catch (e) {
                nomeProduto = 'Produto';
              }
            },
          );

          // Mostrar alerta de estoque insuficiente
          await showDialog<void>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.error, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Estoque Insuficiente'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Produto: $nomeProduto',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Quantidade a vender: $vendidos unidades',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Estoque disponível: $estoqueDisponivel unidades',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Após esta venda, o estoque ficaria negativo em ${estoqueRestante.abs()} unidades.',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Não é possível registrar este item. Verifique o estoque disponível.',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
              actions: [
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('OK'),
                ),
              ],
            ),
          );

          setState(() => _isLoading = false);
          return;
        }
      }

      if (_editingItem == null) {
        // Criar novo item
        final novoItem = ItemVenda(
          id: '',
          vendaId: widget.vendaId,
          produtoId: _selectedProdutoId!,
          retirada: retirada,
          reposicao: reposicao,
          retorno: retorno,
          precoUnitario: precoUnitario,
          vendidos: vendidos,
          subtotal: subtotal,
        );
        await ref
            .read(vendaControllerProvider.notifier)
            .createItemVenda(novoItem);

        // Invalidar providers para atualizar os dados
        ref.invalidate(vendaControllerProvider);
        ref.invalidate(itensVendaProvider(widget.vendaId));

        AppFeedback.showSuccess(context, 'Item adicionado com sucesso!');
      } else {
        // Atualizar item existente
        final itemAtualizado = _editingItem!.copyWith(
          produtoId: _selectedProdutoId!,
          retirada: retirada,
          reposicao: reposicao,
          retorno: retorno,
          precoUnitario: precoUnitario,
          vendidos: vendidos,
          subtotal: subtotal,
        );
        await ref
            .read(vendaControllerProvider.notifier)
            .updateItemVenda(itemAtualizado);

        // Invalidar providers para atualizar os dados
        ref.invalidate(vendaControllerProvider);
        ref.invalidate(itensVendaProvider(widget.vendaId));

        AppFeedback.showSuccess(context, 'Item atualizado com sucesso!');
      }

      Navigator.of(context).pop();
    } catch (e) {
      AppFeedback.showError(context, e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteItem(ItemVenda item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => const ConfirmDialog(
        title: 'Confirmar Exclusão',
        message: 'Tem certeza que deseja excluir este item?',
        confirmText: 'Excluir',
      ),
    );

    if (confirmed == true) {
      try {
        await ref
            .read(vendaControllerProvider.notifier)
            .deleteItemVenda(item.id);

        // Invalidar providers para atualizar os dados
        ref.invalidate(vendaControllerProvider);
        ref.invalidate(itensVendaProvider(widget.vendaId));

        AppFeedback.showSuccess(context, 'Item excluído com sucesso!');
      } catch (e) {
        AppFeedback.showError(context, e.toString());
      }
    }
  }

  String _getProdutoNome(String produtoId) {
    final produtosState = ref.read(produtoControllerProvider);
    return produtosState.when(
      loading: () => 'Carregando...',
      error: (error, stack) => 'Erro',
      data: (produtos) {
        final produto = produtos.firstWhere(
          (p) => p.id == produtoId,
          orElse: () => throw Exception('Produto não encontrado'),
        );
        return '${produto.codigo} - ${produto.nome}';
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final itensState = ref.watch(itensVendaProvider(widget.vendaId));

    return MainLayout(
      title: 'Itens da Venda',
      breadcrumbs: [
        const BreadcrumbItem('Vendas'),
        BreadcrumbItem(
          'Itens da Venda #${widget.vendaId.substring(0, 8).toUpperCase()}',
        ),
      ],
      selectedSidebarIndex: 4,
      onSidebarItemSelected: (i) => context.go(sidebarItemsWithRoutes[i].route),
      actions: [
        IconButton(
          onPressed: () {
            ref.invalidate(itensVendaProvider(widget.vendaId));
            ref.invalidate(vendaControllerProvider);
            AppFeedback.showSuccess(context, 'Dados atualizados!');
          },
          icon: const Icon(Icons.refresh),
          tooltip: 'Atualizar dados',
        ),
        const SizedBox(width: 8),
        OutlinedButton.icon(
          onPressed: () => context.go('/vendas'),
          icon: const Icon(Icons.arrow_back),
          label: const Text('Voltar às Vendas'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.blue,
            side: BorderSide(color: AppColors.blue),
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          onPressed: () => _showItemDialog(),
          icon: const Icon(Icons.add),
          label: const Text('Adicionar Item'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.green,
            foregroundColor: Colors.white,
          ),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: itensState.when(
          loading: () => const Center(child: AppLoading()),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Erro ao carregar itens: $error'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () =>
                      ref.invalidate(itensVendaProvider(widget.vendaId)),
                  child: const Text('Tentar Novamente'),
                ),
              ],
            ),
          ),
          data: (itens) => itens.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.shopping_cart_outlined,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Nenhum item encontrado',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Clique em "Adicionar Item" para começar',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Resumo dos itens
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.blue),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.shopping_cart,
                            color: AppColors.blue,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Resumo dos Itens',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.blue,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${itens.length} itens na venda',
                                  style: TextStyle(
                                    color: AppColors.blue,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.blue,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'R\$ ${itens.fold(0.0, (total, item) => total + item.subtotal).toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Campo de pesquisa
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Pesquisar por código do produto...',
                          prefixIcon: const Icon(Icons.search, color: AppColors.blue),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, color: Colors.grey),
                                  onPressed: () {
                                    setState(() {
                                      _searchController.clear();
                                      _searchQuery = '';
                                    });
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value.toLowerCase();
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Lista de itens
                    Expanded(
                      child: ListView.builder(
                        itemCount: _getFilteredItens(itens).length,
                        itemBuilder: (context, index) {
                          final item = _getFilteredItens(itens)[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.1),
                                  spreadRadius: 1,
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Header do item
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: AppColors.green,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(
                                          Icons.inventory,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _getProdutoNome(item.produtoId),
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Preço: R\$ ${item.precoUnitario.toStringAsFixed(2)}',
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      // Valor total em uma linha separada para evitar sobreposição
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            'Total',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.green,
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              'R\$ ${item.subtotal.toStringAsFixed(2)}',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),

                                  // Quantidades
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[50],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: _buildQuantityInfo(
                                            label: 'Retirada',
                                            value: item.retirada.toString(),
                                            color: Colors.blue,
                                          ),
                                        ),
                                        Expanded(
                                          child: _buildQuantityInfo(
                                            label: 'Reposição',
                                            value: item.reposicao.toString(),
                                            color: Colors.orange,
                                          ),
                                        ),
                                        Expanded(
                                          child: _buildQuantityInfo(
                                            label: 'Retorno',
                                            value: item.retorno.toString(),
                                            color: Colors.red,
                                          ),
                                        ),
                                        Expanded(
                                          child: _buildQuantityInfo(
                                            label: 'Vendidos',
                                            value: item.vendidos.toString(),
                                            color: AppColors.green,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Ações
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      OutlinedButton.icon(
                                        onPressed: () =>
                                            _showItemDialog(item: item),
                                        icon: const Icon(Icons.edit, size: 16),
                                        label: const Text('Editar'),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: AppColors.blue,
                                          side: BorderSide(
                                            color: AppColors.blue,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      OutlinedButton.icon(
                                        onPressed: () => _deleteItem(item),
                                        icon: const Icon(
                                          Icons.delete,
                                          size: 16,
                                        ),
                                        label: const Text('Excluir'),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.red,
                                          side: BorderSide(color: Colors.red),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  List<ItemVenda> _getFilteredItens(List<ItemVenda> itens) {
    if (_searchQuery.isEmpty) {
      return itens;
    }
    
    return itens.where((item) {
      final produtoNome = _getProdutoNome(item.produtoId).toLowerCase();
      // Pesquisar por nome do produto ou código
      return produtoNome.contains(_searchQuery) || 
             produtoNome.split(' - ').first.contains(_searchQuery);
    }).toList();
  }

  Widget _buildQuantityInfo({
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
