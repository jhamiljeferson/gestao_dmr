import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../shared/layouts/main_layout.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_loading.dart';
import '../../../shared/widgets/app_breadcrumbs.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../../../config/theme.dart';
import '../../../shared/widgets/app_sidebar.dart';
import '../controllers/movimentacao_controller.dart';
import '../../produtos/controllers/produto_controller.dart';

class RelatorioMovimentacoesView extends ConsumerStatefulWidget {
  const RelatorioMovimentacoesView({Key? key}) : super(key: key);

  @override
  ConsumerState<RelatorioMovimentacoesView> createState() =>
      _RelatorioMovimentacoesViewState();
}

class _RelatorioMovimentacoesViewState
    extends ConsumerState<RelatorioMovimentacoesView> {
  String? _selectedTipo;
  String? _selectedProdutoId;
  DateTime? _dataInicio;
  DateTime? _dataFim;
  bool _showFilters = false;

  final Map<String, dynamic> _filtros = {};

  @override
  void initState() {
    super.initState();
    _aplicarFiltros();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Forçar atualização do provider após as dependências estarem disponíveis
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.invalidate(movimentacoesFiltradasProvider(_filtros));
      }
    });
  }

  void _aplicarFiltros() {
    _filtros.clear();
    if (_selectedTipo != null && _selectedTipo!.isNotEmpty) {
      _filtros['tipo'] = _selectedTipo;
    }
    if (_selectedProdutoId != null && _selectedProdutoId!.isNotEmpty) {
      _filtros['produtoId'] = _selectedProdutoId;
    }
    if (_dataInicio != null) {
      _filtros['dataInicio'] = _dataInicio;
    }
    if (_dataFim != null) {
      _filtros['dataFim'] = _dataFim;
    }
  }

  void _limparFiltros() {
    setState(() {
      _selectedTipo = null;
      _selectedProdutoId = null;
      _dataInicio = null;
      _dataFim = null;
    });
    _aplicarFiltros();
  }

  Future<void> _selecionarData(BuildContext context, bool isInicio) async {
    final DateTime? dataSelecionada = await showDatePicker(
      context: context,
      initialDate: isInicio
          ? DateTime.now().subtract(const Duration(days: 30))
          : DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (dataSelecionada != null) {
      setState(() {
        if (isInicio) {
          _dataInicio = dataSelecionada;
        } else {
          _dataFim = dataSelecionada;
        }
      });
      _aplicarFiltros();
    }
  }

  Color _getTipoColor(String tipo) {
    switch (tipo) {
      case 'entrada':
        return Colors.green;
      case 'saida':
        return Colors.red;
      case 'venda':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getTipoIcon(String tipo) {
    switch (tipo) {
      case 'entrada':
        return Icons.add_circle;
      case 'saida':
        return Icons.remove_circle;
      case 'venda':
        return Icons.shopping_cart;
      default:
        return Icons.inventory;
    }
  }

  String _getTipoLabel(String tipo) {
    switch (tipo) {
      case 'entrada':
        return 'Entrada';
      case 'saida':
        return 'Saída';
      case 'venda':
        return 'Venda';
      default:
        return tipo;
    }
  }

  @override
  Widget build(BuildContext context) {
    final movimentacoesState = ref.watch(
      movimentacoesFiltradasProvider(_filtros),
    );

    return MainLayout(
      title: 'Relatório de Movimentações',
      breadcrumbs: const [
        BreadcrumbItem('Estoque'),
        BreadcrumbItem('Relatório de Movimentações'),
      ],
      selectedSidebarIndex: 8, // Ajustar conforme necessário
      onSidebarItemSelected: (i) =>
          GoRouter.of(context).go(sidebarItemsWithRoutes[i].route),
      actions: [
        IconButton(
          onPressed: () {
            ref.invalidate(movimentacoesFiltradasProvider(_filtros));
            AppFeedback.showSuccess(context, 'Dados atualizados!');
          },
          icon: const Icon(Icons.refresh),
          tooltip: 'Atualizar dados',
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: () {
            setState(() {
              _showFilters = !_showFilters;
            });
          },
          icon: Icon(
            _showFilters ? Icons.filter_alt : Icons.filter_alt_outlined,
          ),
          tooltip: 'Filtros',
        ),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          onPressed: _limparFiltros,
          icon: const Icon(Icons.clear),
          label: const Text('Limpar Filtros'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey,
            foregroundColor: Colors.white,
          ),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Filtros
            if (_showFilters) ...[
              AppCard(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.filter_list, color: AppColors.blue),
                          const SizedBox(width: 8),
                          const Text(
                            'Filtros',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          // Tipo de movimentação
                          Expanded(
                            child: Consumer(
                              builder: (context, ref, child) {
                                return DropdownButtonFormField<String>(
                                  value: _selectedTipo,
                                  decoration: const InputDecoration(
                                    labelText: 'Tipo de Movimentação',
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                  ),
                                  items: [
                                    const DropdownMenuItem(
                                      value: null,
                                      child: Text('Todos os tipos'),
                                    ),
                                    const DropdownMenuItem(
                                      value: 'entrada',
                                      child: Text('Entradas'),
                                    ),
                                    const DropdownMenuItem(
                                      value: 'saida',
                                      child: Text('Saídas'),
                                    ),
                                    const DropdownMenuItem(
                                      value: 'venda',
                                      child: Text('Vendas'),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedTipo = value;
                                    });
                                    _aplicarFiltros();
                                  },
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Produto
                          Expanded(
                            child: Consumer(
                              builder: (context, ref, child) {
                                final produtosState = ref.watch(
                                  produtoControllerProvider,
                                );
                                return produtosState.when(
                                  loading: () =>
                                      DropdownButtonFormField<String>(
                                        value: null,
                                        decoration: const InputDecoration(
                                          labelText: 'Produto',
                                          border: OutlineInputBorder(),
                                        ),
                                        items: const [],
                                        onChanged: (value) {},
                                      ),
                                  error: (error, stack) =>
                                      DropdownButtonFormField<String>(
                                        value: null,
                                        decoration: const InputDecoration(
                                          labelText: 'Produto',
                                          border: OutlineInputBorder(),
                                        ),
                                        items: const [],
                                        onChanged: (value) {},
                                      ),
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
                                        items: [
                                          const DropdownMenuItem(
                                            value: null,
                                            child: Text('Todos os produtos'),
                                          ),
                                          ...produtos.map((produto) {
                                            return DropdownMenuItem(
                                              value: produto.id,
                                              child: Text(
                                                '${produto.codigo} - ${produto.nome}',
                                              ),
                                            );
                                          }).toList(),
                                        ],
                                        onChanged: (value) {
                                          setState(() {
                                            _selectedProdutoId = value;
                                          });
                                          _aplicarFiltros();
                                        },
                                      ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          // Data início
                          Expanded(
                            child: InkWell(
                              onTap: () => _selecionarData(context, true),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 16,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.grey.shade400,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.calendar_today, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      _dataInicio != null
                                          ? DateFormat(
                                              'dd/MM/yyyy',
                                            ).format(_dataInicio!)
                                          : 'Data início',
                                      style: TextStyle(
                                        color: _dataInicio != null
                                            ? Colors.black
                                            : Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Data fim
                          Expanded(
                            child: InkWell(
                              onTap: () => _selecionarData(context, false),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 16,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.grey.shade400,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.calendar_today, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      _dataFim != null
                                          ? DateFormat(
                                              'dd/MM/yyyy',
                                            ).format(_dataFim!)
                                          : 'Data fim',
                                      style: TextStyle(
                                        color: _dataFim != null
                                            ? Colors.black
                                            : Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Lista de movimentações
            Expanded(
              child: movimentacoesState.when(
                loading: () => const Center(child: AppLoading()),
                error: (error, stack) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text('Erro ao carregar movimentações: $error'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => ref.invalidate(
                          movimentacoesFiltradasProvider(_filtros),
                        ),
                        child: const Text('Tentar Novamente'),
                      ),
                    ],
                  ),
                ),
                data: (movimentacoes) => movimentacoes.isEmpty
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
                              'Nenhuma movimentação encontrada',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tente ajustar os filtros ou adicionar movimentações',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: movimentacoes.length,
                        itemBuilder: (context, index) {
                          final movimentacao = movimentacoes[index];
                          final produto =
                              movimentacao['produtos'] as Map<String, dynamic>;
                          final data = DateTime.parse(movimentacao['data']);
                          final tipo = movimentacao['tipo'] as String;
                          final quantidade = movimentacao['quantidade'] as int;
                          final observacao =
                              movimentacao['observacao'] as String?;

                          return AppCard(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  // Ícone do tipo
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: _getTipoColor(
                                        tipo,
                                      ).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      _getTipoIcon(tipo),
                                      color: _getTipoColor(tipo),
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 16),

                                  // Informações da movimentação
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                '${produto['codigo']} - ${produto['nome']}',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: _getTipoColor(tipo),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                _getTipoLabel(tipo),
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.calendar_today,
                                              size: 16,
                                              color: Colors.grey[600],
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              DateFormat(
                                                'dd/MM/yyyy HH:mm',
                                              ).format(data),
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 14,
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            Icon(
                                              Icons.inventory,
                                              size: 16,
                                              color: Colors.grey[600],
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '$quantidade unidades',
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (observacao != null &&
                                            observacao.isNotEmpty) ...[
                                          const SizedBox(height: 8),
                                          Text(
                                            'Obs: $observacao',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 14,
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
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
