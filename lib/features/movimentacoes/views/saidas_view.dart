import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../shared/layouts/main_layout.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_loading.dart';
import '../../../shared/widgets/app_breadcrumbs.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/app_dialog.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../../../config/theme.dart';
import '../../../shared/widgets/app_sidebar.dart';
import '../controllers/movimentacao_controller.dart';
import '../../produtos/controllers/produto_controller.dart';
import '../../estoque/controllers/estoque_controller.dart';

class SaidasView extends ConsumerStatefulWidget {
  const SaidasView({Key? key}) : super(key: key);

  @override
  ConsumerState<SaidasView> createState() => _SaidasViewState();
}

class _SaidasViewState extends ConsumerState<SaidasView> {
  final _formKey = GlobalKey<FormState>();
  final _quantidadeController = TextEditingController();
  final _observacaoController = TextEditingController();
  String? _selectedProdutoId;
  bool _isLoading = false;

  @override
  void dispose() {
    _quantidadeController.dispose();
    _observacaoController.dispose();
    super.dispose();
  }

  void _showSaidaDialog() {
    _selectedProdutoId = null;
    _quantidadeController.clear();
    _observacaoController.clear();

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
                  color: AppColors.red,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.remove_circle,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Nova Saída',
                        style: TextStyle(
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

                        // Quantidade
                        AppTextField(
                          label: 'Quantidade',
                          controller: _quantidadeController,
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Informe a quantidade';
                            }
                            if (int.tryParse(value) == null) {
                              return 'Valor deve ser um número';
                            }
                            if (int.parse(value) <= 0) {
                              return 'Quantidade deve ser maior que zero';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Observação
                        TextFormField(
                          controller: _observacaoController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Observação (opcional)',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
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
                        onPressed: _isLoading ? null : _saveSaida,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.red,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Registrar'),
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

  void _showEditSaidaDialog(Map<String, dynamic> saida) {
    final produto = saida['produtos'] as Map<String, dynamic>;
    _selectedProdutoId = saida['produto_id'];
    _quantidadeController.text = saida['quantidade'].toString();
    _observacaoController.text = saida['observacao'] ?? '';

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
                    const Icon(Icons.edit, color: Colors.white, size: 24),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Editar Saída',
                        style: TextStyle(
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
                        // Produto (readonly)
                        TextFormField(
                          initialValue:
                              '${produto['codigo']} - ${produto['nome']}',
                          enabled: false,
                          decoration: const InputDecoration(
                            labelText: 'Produto',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Quantidade
                        AppTextField(
                          label: 'Quantidade',
                          controller: _quantidadeController,
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Informe a quantidade';
                            }
                            if (int.tryParse(value) == null) {
                              return 'Valor deve ser um número';
                            }
                            if (int.parse(value) <= 0) {
                              return 'Quantidade deve ser maior que zero';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Observação
                        TextFormField(
                          controller: _observacaoController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Observação (opcional)',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
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
                        onPressed: _isLoading
                            ? null
                            : () => _updateSaida(saida['id']),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.blue,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Salvar'),
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

  Future<void> _saveSaida() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final quantidade = int.parse(_quantidadeController.text);
      final observacao = _observacaoController.text.trim().isEmpty
          ? null
          : _observacaoController.text.trim();

      // Verificar estoque antes de salvar
      final estoqueAtual = await ref
          .read(estoqueControllerProvider.notifier)
          .getEstoqueProduto(_selectedProdutoId!);

      if (estoqueAtual != null) {
        final estoqueDisponivel = estoqueAtual.quantidade;
        final estoqueRestante = estoqueDisponivel - quantidade;

        if (estoqueRestante < 0) {
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
                    'A quantidade solicitada ($quantidade) é maior que o estoque disponível ($estoqueDisponivel).',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Após esta saída, o estoque ficaria negativo em ${estoqueRestante.abs()} unidades.',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Não é possível registrar esta saída. Verifique o estoque disponível.',
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

      await ref
          .read(movimentacaoControllerProvider.notifier)
          .createSaida(
            produtoId: _selectedProdutoId!,
            quantidade: quantidade,
            observacao: observacao,
          );

      // Invalida os providers para atualizar a lista
      ref.invalidate(saidasProvider);
      ref.invalidate(estoqueProvider);

      Navigator.of(context).pop();
      AppFeedback.showSuccess(context, 'Saída registrada com sucesso!');
    } catch (error) {
      AppFeedback.showError(context, 'Erro ao registrar saída: $error');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateSaida(String id) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final quantidade = int.parse(_quantidadeController.text);
      final observacao = _observacaoController.text.trim().isEmpty
          ? null
          : _observacaoController.text.trim();

      await ref
          .read(movimentacaoControllerProvider.notifier)
          .updateMovimentacao(
            id: id,
            produtoId: _selectedProdutoId!,
            tipo: 'saida',
            quantidade: quantidade,
            observacao: observacao,
          );

      // Invalida os providers para atualizar a lista
      ref.invalidate(saidasProvider);
      ref.invalidate(estoqueProvider);

      Navigator.of(context).pop();
      AppFeedback.showSuccess(context, 'Saída atualizada com sucesso!');
    } catch (error) {
      AppFeedback.showError(context, 'Erro ao atualizar saída: $error');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteSaida(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => ConfirmDialog(
        title: 'Confirmar Exclusão',
        message: 'Tem certeza que deseja excluir esta saída?',
        confirmText: 'Excluir',
        cancelText: 'Cancelar',
      ),
    );

    if (confirmed != true) return;

    try {
      await ref
          .read(movimentacaoControllerProvider.notifier)
          .deleteMovimentacao(id);
      ref.invalidate(saidasProvider);
      ref.invalidate(estoqueProvider);
      AppFeedback.showSuccess(context, 'Saída excluída com sucesso!');
    } catch (error) {
      AppFeedback.showError(context, 'Erro ao excluir saída: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final saidasState = ref.watch(saidasProvider);

    return MainLayout(
      title: 'Saídas de Estoque',
      breadcrumbs: const [BreadcrumbItem('Estoque'), BreadcrumbItem('Saídas')],
      selectedSidebarIndex: 6,
      onSidebarItemSelected: (i) =>
          GoRouter.of(context).go(sidebarItemsWithRoutes[i].route),
      actions: [
        IconButton(
          onPressed: () {
            ref.invalidate(saidasProvider);
            AppFeedback.showSuccess(context, 'Dados atualizados!');
          },
          icon: const Icon(Icons.refresh),
          tooltip: 'Atualizar dados',
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: () async {
            try {
              await ref
                  .read(movimentacaoControllerProvider.notifier)
                  .testConnection();
              AppFeedback.showSuccess(context, 'Teste de conexão realizado!');
            } catch (error) {
              AppFeedback.showError(context, 'Erro no teste: $error');
            }
          },
          icon: const Icon(Icons.bug_report),
          tooltip: 'Testar conexão',
        ),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          onPressed: () => _showSaidaDialog(),
          icon: const Icon(Icons.remove),
          label: const Text('Nova Saída'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.red,
            foregroundColor: Colors.white,
          ),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: saidasState.when(
          loading: () => const Center(child: AppLoading()),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Erro ao carregar saídas: $error'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.invalidate(saidasProvider),
                  child: const Text('Tentar Novamente'),
                ),
              ],
            ),
          ),
          data: (saidas) => saidas.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.outbox_outlined,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Nenhuma saída encontrada',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Clique em "Nova Saída" para começar',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: saidas.length,
                  itemBuilder: (context, index) {
                    final saida = saidas[index];
                    final produto = saida['produtos'] as Map<String, dynamic>;
                    final data = DateTime.parse(saida['data']);

                    return AppCard(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.red.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppColors.red),
                                  ),
                                  child: Text(
                                    'Saída',
                                    style: TextStyle(
                                      color: AppColors.red,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  DateFormat('dd/MM/yyyy HH:mm').format(data),
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Produto
                            Row(
                              children: [
                                const Icon(
                                  Icons.inventory,
                                  size: 16,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${produto['codigo']} - ${produto['nome']}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // Quantidade
                            Row(
                              children: [
                                const Icon(
                                  Icons.numbers,
                                  size: 16,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Quantidade: ${saida['quantidade']}',
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ],
                            ),

                            // Observação (se houver)
                            if (saida['observacao'] != null) ...[
                              const SizedBox(height: 8),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.note,
                                    size: 16,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Obs: ${saida['observacao']}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],

                            const SizedBox(height: 16),

                            // Actions - Desabilitadas por segurança
                            // Row(
                            //   mainAxisAlignment: MainAxisAlignment.end,
                            //   children: [
                            //     OutlinedButton.icon(
                            //       onPressed: () => _showEditSaidaDialog(saida),
                            //       icon: const Icon(Icons.edit, size: 16),
                            //       label: const Text('Editar'),
                            //       style: OutlinedButton.styleFrom(
                            //         foregroundColor: AppColors.blue,
                            //         side: const BorderSide(
                            //           color: AppColors.blue,
                            //         ),
                            //       ),
                            //     ),
                            //     const SizedBox(width: 8),
                            //     OutlinedButton.icon(
                            //       onPressed: () => _deleteSaida(saida['id']),
                            //       icon: const Icon(Icons.delete, size: 16),
                            //       label: const Text('Excluir'),
                            //       style: OutlinedButton.styleFrom(
                            //         foregroundColor: Colors.red,
                            //         side: const BorderSide(color: Colors.red),
                            //       ),
                            //     ),
                            //   ],
                            // ),
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
