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
import '../controllers/estoque_controller.dart';

class EstoqueView extends ConsumerStatefulWidget {
  const EstoqueView({Key? key}) : super(key: key);

  @override
  ConsumerState<EstoqueView> createState() => _EstoqueViewState();
}

class _EstoqueViewState extends ConsumerState<EstoqueView> {
  final _formKey = GlobalKey<FormState>();
  final _quantidadeController = TextEditingController();
  String? _selectedProdutoId;
  bool _isLoading = false;

  @override
  void dispose() {
    _quantidadeController.dispose();
    super.dispose();
  }

  void _showAjusteDialog(
    String produtoId,
    String produtoNome,
    int quantidadeAtual,
  ) {
    _selectedProdutoId = produtoId;
    _quantidadeController.text = quantidadeAtual.toString();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: Container(
          constraints: const BoxConstraints(maxHeight: 400),
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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Ajustar Estoque',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            produtoNome,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
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
                        // Quantidade atual
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.inventory, color: Colors.grey),
                              const SizedBox(width: 8),
                              Text(
                                'Quantidade Atual: $quantidadeAtual',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Nova quantidade
                        AppTextField(
                          label: 'Nova Quantidade',
                          controller: _quantidadeController,
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Informe a nova quantidade';
                            }
                            if (int.tryParse(value) == null) {
                              return 'Valor deve ser um número';
                            }
                            if (int.parse(value) < 0) {
                              return 'Quantidade não pode ser negativa';
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
                        onPressed: _isLoading ? null : _saveAjuste,
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

  Future<void> _saveAjuste() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final novaQuantidade = int.parse(_quantidadeController.text);

      await ref
          .read(estoqueControllerProvider.notifier)
          .updateQuantidade(_selectedProdutoId!, novaQuantidade);

      // Invalida os providers para atualizar a lista
      ref.invalidate(estoqueProvider);

      Navigator.of(context).pop();
      AppFeedback.showSuccess(context, 'Estoque atualizado com sucesso!');
    } catch (error) {
      AppFeedback.showError(context, 'Erro ao atualizar estoque: $error');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Color _getEstoqueColor(int quantidade) {
    if (quantidade == 0) return Colors.red;
    if (quantidade < 10) return Colors.orange;
    return Colors.green;
  }

  String _getEstoqueStatus(int quantidade) {
    if (quantidade == 0) return 'Sem Estoque';
    if (quantidade < 10) return 'Estoque Baixo';
    return 'Em Estoque';
  }

  @override
  Widget build(BuildContext context) {
    final estoqueState = ref.watch(estoqueProvider);

    return MainLayout(
      title: 'Controle de Estoque',
      breadcrumbs: const [
        BreadcrumbItem('Estoque'),
        BreadcrumbItem('Controle'),
      ],
      selectedSidebarIndex: 7,
      onSidebarItemSelected: (i) =>
          GoRouter.of(context).go(sidebarItemsWithRoutes[i].route),
      actions: [
        IconButton(
          onPressed: () async {
            // Testar se a tabela estoque existe
            final service = ref.read(estoqueServiceProvider);
            final tabelaExiste = await service.testarTabelaEstoque();

            if (tabelaExiste) {
              ref.invalidate(estoqueProvider);
              AppFeedback.showSuccess(context, 'Dados atualizados!');
            } else {
              AppFeedback.showError(
                context,
                'Tabela estoque não existe! Execute o script SQL primeiro.',
              );
            }
          },
          icon: const Icon(Icons.refresh),
          tooltip: 'Atualizar dados',
        ),
        IconButton(
          onPressed: () async {
            // Testar criação manual de estoque
            final service = ref.read(estoqueServiceProvider);
            try {
              await service.testarTabelaEstoque();
              AppFeedback.showSuccess(
                context,
                'Tabela estoque está funcionando!',
              );
            } catch (error) {
              AppFeedback.showError(context, 'Erro na tabela estoque: $error');
            }
          },
          icon: const Icon(Icons.bug_report),
          tooltip: 'Testar tabela estoque',
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: estoqueState.when(
          loading: () => const Center(child: AppLoading()),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Erro ao carregar estoque: $error'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.invalidate(estoqueProvider),
                  child: const Text('Tentar Novamente'),
                ),
              ],
            ),
          ),
          data: (estoque) => estoque.isEmpty
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
                        'Nenhum produto em estoque',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Adicione produtos para começar',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Resumo do estoque
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
                            Icons.analytics,
                            color: AppColors.blue,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Resumo do Estoque',
                                  style: TextStyle(
                                    color: AppColors.blue,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${estoque.length} produtos cadastrados',
                                  style: TextStyle(
                                    color: AppColors.blue.withOpacity(0.8),
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
                              '${estoque.where((e) => e['quantidade'] > 0).length} em estoque',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Lista de produtos
                    Expanded(
                      child: ListView.builder(
                        itemCount: estoque.length,
                        itemBuilder: (context, index) {
                          final item = estoque[index];
                          final produto =
                              item['produtos'] as Map<String, dynamic>;
                          final quantidade = item['quantidade'] as int;
                          final estoqueColor = _getEstoqueColor(quantidade);
                          final estoqueStatus = _getEstoqueStatus(quantidade);

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
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '${produto['codigo']} - ${produto['nome']}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: estoqueColor.withOpacity(
                                                  0.1,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: estoqueColor,
                                                ),
                                              ),
                                              child: Text(
                                                estoqueStatus,
                                                style: TextStyle(
                                                  color: estoqueColor,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            quantidade.toString(),
                                            style: TextStyle(
                                              color: estoqueColor,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 24,
                                            ),
                                          ),
                                          Text(
                                            'unidades',
                                            style: TextStyle(
                                              color: estoqueColor.withOpacity(
                                                0.7,
                                              ),
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),

                                  // Actions
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      OutlinedButton.icon(
                                        onPressed: () => _showAjusteDialog(
                                          item['produto_id'],
                                          produto['nome'],
                                          quantidade,
                                        ),
                                        icon: const Icon(Icons.edit, size: 16),
                                        label: const Text('Ajustar'),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: AppColors.blue,
                                          side: BorderSide(
                                            color: AppColors.blue,
                                          ),
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
}
