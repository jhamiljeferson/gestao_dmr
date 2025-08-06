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
import '../models/venda_model.dart';
import '../models/item_venda_model.dart';
import '../controllers/venda_controller.dart';
import '../../pontos/controllers/ponto_controller.dart';
import '../../vendedores/controllers/vendedor_controller.dart';
import '../../produtos/controllers/produto_controller.dart';
import '../../estoque/controllers/estoque_controller.dart';
import 'package:intl/intl.dart';

class VendasView extends ConsumerStatefulWidget {
  const VendasView({Key? key}) : super(key: key);

  @override
  ConsumerState<VendasView> createState() => _VendasViewState();
}

class _VendasViewState extends ConsumerState<VendasView> {
  final _formKey = GlobalKey<FormState>();
  final _dataController = TextEditingController();
  final _trocoController = TextEditingController();
  final _valorPixController = TextEditingController();
  final _valorDinheiroController = TextEditingController();

  // Controllers para itens
  final _itemFormKey = GlobalKey<FormState>();
  final _retiradaController = TextEditingController();
  final _reposicaoController = TextEditingController();
  final _retornoController = TextEditingController();
  final _precoUnitarioController = TextEditingController();

  bool _isLoading = false;
  Venda? _editingVenda;
  String? _selectedPontoId;
  String? _selectedVendedorId;
  String? _selectedProdutoId;

  // Lista de itens temporários
  List<Map<String, dynamic>> _itensTemp = [];

  @override
  void initState() {
    super.initState();
    _dataController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  @override
  void dispose() {
    _dataController.dispose();
    _trocoController.dispose();
    _valorPixController.dispose();
    _valorDinheiroController.dispose();
    _retiradaController.dispose();
    _reposicaoController.dispose();
    _retornoController.dispose();
    _precoUnitarioController.dispose();
    super.dispose();
  }

  void _showVendaDialog({Venda? venda}) async {
    _editingVenda = venda;
    _itensTemp.clear();

    if (venda != null) {
      _dataController.text = DateFormat('yyyy-MM-dd').format(venda.data);
      _selectedPontoId = venda.pontoId;
      _selectedVendedorId = venda.vendedorId;
      _trocoController.text = venda.troco.toString();
      _valorPixController.text = venda.valorPix.toString();
      _valorDinheiroController.text = venda.valorDinheiro.toString();

      // Carregar itens existentes da venda
      try {
        final itens = await ref
            .read(vendaControllerProvider.notifier)
            .getItensVenda(venda.id);
        final produtosState = ref.read(produtoControllerProvider);

        for (final item in itens) {
          final produtoNome = produtosState.when(
            loading: () => 'Carregando...',
            error: (error, stack) => 'Erro',
            data: (produtos) {
              final produto = produtos.firstWhere(
                (p) => p.id == item.produtoId,
                orElse: () => throw Exception('Produto não encontrado'),
              );
              return '${produto.codigo} - ${produto.nome}';
            },
          );

          _itensTemp.add({
            'produtoId': item.produtoId,
            'produtoNome': produtoNome,
            'retirada': item.retirada,
            'reposicao': item.reposicao,
            'retorno': item.retorno,
            'vendidos': item.vendidos,
            'precoUnitario': item.precoUnitario,
            'subtotal': item.subtotal,
          });
        }
      } catch (e) {
        print('Erro ao carregar itens: $e');
      }
    } else {
      _dataController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
      _selectedPontoId = null;
      _selectedVendedorId = null;
      _trocoController.clear();
      _valorPixController.clear();
      _valorDinheiroController.clear();
    }

    // Forçar rebuild do widget para mostrar os itens
    if (mounted) {
      setState(() {});
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            insetPadding: const EdgeInsets.all(16),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 600),
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
                        Icon(Icons.receipt_long, color: Colors.white, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            venda == null ? 'Nova Venda' : 'Editar Venda',
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Seção de dados da venda
                            Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: AppColors.blue,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Dados da Venda',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.blue,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Data
                            AppTextField(
                              label: 'Data',
                              controller: _dataController,
                              keyboardType: TextInputType.datetime,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Informe a data';
                                }
                                try {
                                  DateFormat('yyyy-MM-dd').parse(value);
                                  return null;
                                } catch (e) {
                                  return 'Data inválida (use YYYY-MM-DD)';
                                }
                              },
                            ),
                            const SizedBox(height: 12),

                            // Ponto e Vendedor em linha (se houver espaço)
                            LayoutBuilder(
                              builder: (context, constraints) {
                                if (constraints.maxWidth > 400) {
                                  return Row(
                                    children: [
                                      Expanded(
                                        child: Consumer(
                                          builder: (context, ref, child) {
                                            final pontosState = ref.watch(
                                              pontoControllerProvider,
                                            );
                                            return pontosState.when(
                                              loading: () =>
                                                  const CircularProgressIndicator(),
                                              error: (error, stack) =>
                                                  Text('Erro: $error'),
                                              data: (pontos) =>
                                                  DropdownButtonFormField<
                                                    String
                                                  >(
                                                    value: _selectedPontoId,
                                                    decoration: const InputDecoration(
                                                      labelText:
                                                          'Ponto de Venda',
                                                      border:
                                                          OutlineInputBorder(),
                                                      contentPadding:
                                                          EdgeInsets.symmetric(
                                                            horizontal: 12,
                                                            vertical: 8,
                                                          ),
                                                    ),
                                                    items: pontos.map((ponto) {
                                                      return DropdownMenuItem(
                                                        value: ponto.id,
                                                        child: Text(ponto.nome),
                                                      );
                                                    }).toList(),
                                                    onChanged: (value) {
                                                      setState(() {
                                                        _selectedPontoId =
                                                            value;
                                                      });
                                                    },
                                                    validator: (value) {
                                                      if (value == null ||
                                                          value.isEmpty) {
                                                        return 'Selecione um ponto';
                                                      }
                                                      return null;
                                                    },
                                                  ),
                                            );
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Consumer(
                                          builder: (context, ref, child) {
                                            final vendedoresState = ref.watch(
                                              vendedorControllerProvider,
                                            );
                                            return vendedoresState.when(
                                              loading: () =>
                                                  const CircularProgressIndicator(),
                                              error: (error, stack) =>
                                                  Text('Erro: $error'),
                                              data: (vendedores) =>
                                                  DropdownButtonFormField<
                                                    String
                                                  >(
                                                    value: _selectedVendedorId,
                                                    decoration: const InputDecoration(
                                                      labelText: 'Vendedor',
                                                      border:
                                                          OutlineInputBorder(),
                                                      contentPadding:
                                                          EdgeInsets.symmetric(
                                                            horizontal: 12,
                                                            vertical: 8,
                                                          ),
                                                    ),
                                                    items: vendedores.map((
                                                      vendedor,
                                                    ) {
                                                      return DropdownMenuItem(
                                                        value: vendedor.id,
                                                        child: Text(
                                                          vendedor.nome,
                                                        ),
                                                      );
                                                    }).toList(),
                                                    onChanged: (value) {
                                                      setState(() {
                                                        _selectedVendedorId =
                                                            value;
                                                      });
                                                    },
                                                    validator: (value) {
                                                      if (value == null ||
                                                          value.isEmpty) {
                                                        return 'Selecione um vendedor';
                                                      }
                                                      return null;
                                                    },
                                                  ),
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  );
                                } else {
                                  return Column(
                                    children: [
                                      Consumer(
                                        builder: (context, ref, child) {
                                          final pontosState = ref.watch(
                                            pontoControllerProvider,
                                          );
                                          return pontosState.when(
                                            loading: () =>
                                                const CircularProgressIndicator(),
                                            error: (error, stack) =>
                                                Text('Erro: $error'),
                                            data: (pontos) =>
                                                DropdownButtonFormField<String>(
                                                  value: _selectedPontoId,
                                                  decoration:
                                                      const InputDecoration(
                                                        labelText:
                                                            'Ponto de Venda',
                                                        border:
                                                            OutlineInputBorder(),
                                                        contentPadding:
                                                            EdgeInsets.symmetric(
                                                              horizontal: 12,
                                                              vertical: 8,
                                                            ),
                                                      ),
                                                  items: pontos.map((ponto) {
                                                    return DropdownMenuItem(
                                                      value: ponto.id,
                                                      child: Text(ponto.nome),
                                                    );
                                                  }).toList(),
                                                  onChanged: (value) {
                                                    setState(() {
                                                      _selectedPontoId = value;
                                                    });
                                                  },
                                                  validator: (value) {
                                                    if (value == null ||
                                                        value.isEmpty) {
                                                      return 'Selecione um ponto';
                                                    }
                                                    return null;
                                                  },
                                                ),
                                          );
                                        },
                                      ),
                                      const SizedBox(height: 12),
                                      Consumer(
                                        builder: (context, ref, child) {
                                          final vendedoresState = ref.watch(
                                            vendedorControllerProvider,
                                          );
                                          return vendedoresState.when(
                                            loading: () =>
                                                const CircularProgressIndicator(),
                                            error: (error, stack) =>
                                                Text('Erro: $error'),
                                            data: (vendedores) =>
                                                DropdownButtonFormField<String>(
                                                  value: _selectedVendedorId,
                                                  decoration:
                                                      const InputDecoration(
                                                        labelText: 'Vendedor',
                                                        border:
                                                            OutlineInputBorder(),
                                                        contentPadding:
                                                            EdgeInsets.symmetric(
                                                              horizontal: 12,
                                                              vertical: 8,
                                                            ),
                                                      ),
                                                  items: vendedores.map((
                                                    vendedor,
                                                  ) {
                                                    return DropdownMenuItem(
                                                      value: vendedor.id,
                                                      child: Text(
                                                        vendedor.nome,
                                                      ),
                                                    );
                                                  }).toList(),
                                                  onChanged: (value) {
                                                    setState(() {
                                                      _selectedVendedorId =
                                                          value;
                                                    });
                                                  },
                                                  validator: (value) {
                                                    if (value == null ||
                                                        value.isEmpty) {
                                                      return 'Selecione um vendedor';
                                                    }
                                                    return null;
                                                  },
                                                ),
                                          );
                                        },
                                      ),
                                    ],
                                  );
                                }
                              },
                            ),
                            const SizedBox(height: 12),

                            // Valores em linha (se houver espaço)
                            LayoutBuilder(
                              builder: (context, constraints) {
                                if (constraints.maxWidth > 350) {
                                  return Row(
                                    children: [
                                      Expanded(
                                        child: AppTextField(
                                          label: 'Troco',
                                          controller: _trocoController,
                                          keyboardType: TextInputType.number,
                                          validator: (value) {
                                            if (value == null ||
                                                value.isEmpty) {
                                              return 'Informe o troco';
                                            }
                                            if (double.tryParse(value) ==
                                                null) {
                                              return 'Valor deve ser um número';
                                            }
                                            return null;
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: AppTextField(
                                          label: 'Valor PIX',
                                          controller: _valorPixController,
                                          keyboardType: TextInputType.number,
                                          validator: (value) {
                                            if (value == null ||
                                                value.isEmpty) {
                                              return 'Informe o valor PIX';
                                            }
                                            if (double.tryParse(value) ==
                                                null) {
                                              return 'Valor deve ser um número';
                                            }
                                            return null;
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: AppTextField(
                                          label: 'Valor Dinheiro',
                                          controller: _valorDinheiroController,
                                          keyboardType: TextInputType.number,
                                          validator: (value) {
                                            if (value == null ||
                                                value.isEmpty) {
                                              return 'Informe o valor em dinheiro';
                                            }
                                            if (double.tryParse(value) ==
                                                null) {
                                              return 'Valor deve ser um número';
                                            }
                                            return null;
                                          },
                                        ),
                                      ),
                                    ],
                                  );
                                } else {
                                  return Column(
                                    children: [
                                      AppTextField(
                                        label: 'Troco',
                                        controller: _trocoController,
                                        keyboardType: TextInputType.number,
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Informe o troco';
                                          }
                                          if (double.tryParse(value) == null) {
                                            return 'Valor deve ser um número';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 12),
                                      AppTextField(
                                        label: 'Valor PIX',
                                        controller: _valorPixController,
                                        keyboardType: TextInputType.number,
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Informe o valor PIX';
                                          }
                                          if (double.tryParse(value) == null) {
                                            return 'Valor deve ser um número';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 12),
                                      AppTextField(
                                        label: 'Valor Dinheiro',
                                        controller: _valorDinheiroController,
                                        keyboardType: TextInputType.number,
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Informe o valor em dinheiro';
                                          }
                                          if (double.tryParse(value) == null) {
                                            return 'Valor deve ser um número';
                                          }
                                          return null;
                                        },
                                      ),
                                    ],
                                  );
                                }
                              },
                            ),

                            // Validação dos valores de pagamento
                            Builder(
                              builder: (context) {
                                final totalItens = _calcularTotalItens();
                                final valorPix =
                                    double.tryParse(_valorPixController.text) ??
                                    0.0;
                                final valorDinheiro =
                                    double.tryParse(
                                      _valorDinheiroController.text,
                                    ) ??
                                    0.0;
                                final totalPagamento = valorPix + valorDinheiro;
                                final isValid =
                                    totalPagamento == totalItens &&
                                    totalItens > 0;

                                if (totalItens > 0) {
                                  if (!isValid) {
                                    return TweenAnimationBuilder<double>(
                                      tween: Tween(begin: 0.8, end: 1.0),
                                      duration: const Duration(
                                        milliseconds: 1000,
                                      ),
                                      builder: (context, scale, child) {
                                        return Transform.scale(
                                          scale: scale,
                                          child: Container(
                                            margin: const EdgeInsets.only(
                                              top: 12,
                                            ),
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              color: Colors.red.withOpacity(
                                                0.1,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                color: Colors.red,
                                                width: 2,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.red.withOpacity(
                                                    0.3,
                                                  ),
                                                  blurRadius: 8,
                                                  spreadRadius: 1,
                                                ),
                                              ],
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons
                                                          .warning_amber_rounded,
                                                      color: Colors.red,
                                                      size: 24,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      'ALERTA: Valores Incorretos!',
                                                      style: TextStyle(
                                                        color: Colors.red,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  'A soma dos valores de pagamento não corresponde ao total dos itens:',
                                                  style: TextStyle(
                                                    color: Colors.red[700],
                                                    fontSize: 12,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Container(
                                                  padding: const EdgeInsets.all(
                                                    8,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          4,
                                                        ),
                                                    border: Border.all(
                                                      color: Colors.red,
                                                    ),
                                                  ),
                                                  child: Column(
                                                    children: [
                                                      Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .spaceBetween,
                                                        children: [
                                                          Text(
                                                            'PIX:',
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                            ),
                                                          ),
                                                          Text(
                                                            'R\$ ${valorPix.toStringAsFixed(2)}',
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .spaceBetween,
                                                        children: [
                                                          Text(
                                                            'Dinheiro:',
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                            ),
                                                          ),
                                                          Text(
                                                            'R\$ ${valorDinheiro.toStringAsFixed(2)}',
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      Divider(
                                                        height: 8,
                                                        color: Colors.red,
                                                      ),
                                                      Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .spaceBetween,
                                                        children: [
                                                          Text(
                                                            'Total Pagamento:',
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                          ),
                                                          Text(
                                                            'R\$ ${totalPagamento.toStringAsFixed(2)}',
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              color: Colors.red,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .spaceBetween,
                                                        children: [
                                                          Text(
                                                            'Total Itens:',
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                          ),
                                                          Text(
                                                            'R\$ ${totalItens.toStringAsFixed(2)}',
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              color: AppColors
                                                                  .green,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .spaceBetween,
                                                        children: [
                                                          Text(
                                                            'Diferença:',
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                          ),
                                                          Text(
                                                            'R\$ ${(totalPagamento - totalItens).abs().toStringAsFixed(2)}',
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              color: Colors.red,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  'Corrija os valores de pagamento para que a soma seja igual ao total dos itens.',
                                                  style: TextStyle(
                                                    color: Colors.red[700],
                                                    fontSize: 11,
                                                    fontStyle: FontStyle.italic,
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                SizedBox(
                                                  width: double.infinity,
                                                  child: ElevatedButton.icon(
                                                    onPressed: () {
                                                      final totalItens =
                                                          _calcularTotalItens();
                                                      _valorPixController.text =
                                                          totalItens.toString();
                                                      _valorDinheiroController
                                                              .text =
                                                          '0.00';
                                                      setDialogState(() {});
                                                    },
                                                    icon: const Icon(
                                                      Icons.auto_fix_high,
                                                      size: 16,
                                                    ),
                                                    label: const Text(
                                                      'Preencher Automaticamente',
                                                    ),
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor:
                                                          AppColors.blue,
                                                      foregroundColor:
                                                          Colors.white,
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            vertical: 8,
                                                          ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  } else {
                                    return Container(
                                      margin: const EdgeInsets.only(top: 12),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.green),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.check_circle,
                                            color: Colors.green,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'Valores de pagamento corretos!',
                                              style: TextStyle(
                                                color: Colors.green,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }
                                }
                                return const SizedBox.shrink();
                              },
                            ),

                            const SizedBox(height: 20),

                            // Total dos itens (somente leitura)
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.greenLight,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.green),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.calculate, color: AppColors.green),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Total dos Itens',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.green,
                                            fontSize: 14,
                                          ),
                                        ),
                                        Text(
                                          '${_itensTemp.length} itens adicionados',
                                          style: TextStyle(
                                            color: AppColors.green,
                                            fontSize: 12,
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
                                      color: AppColors.green,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      'R\$ ${_calcularTotalItens().toStringAsFixed(2)}',
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
                            const SizedBox(height: 16),

                            // Valores de pagamento
                            Text(
                              'Valores de Pagamento',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),

                            // Seção de itens
                            Row(
                              children: [
                                Icon(
                                  Icons.shopping_cart,
                                  color: AppColors.blue,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Itens da Venda',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.blue,
                                    fontSize: 16,
                                  ),
                                ),
                                const Spacer(),
                                ElevatedButton.icon(
                                  onPressed: () =>
                                      _showItemDialog(setDialogState),
                                  icon: const Icon(Icons.add, size: 16),
                                  label: const Text('Adicionar'),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    textStyle: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Lista de itens
                            if (_itensTemp.isNotEmpty) ...[
                              Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  children: [
                                    // Header da lista
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[50],
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(8),
                                          topRight: Radius.circular(8),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.list,
                                            color: AppColors.blue,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Itens Adicionados (${_itensTemp.length})',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w500,
                                              color: AppColors.blue,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Lista de itens
                                    ListView.builder(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      itemCount: _itensTemp.length,
                                      itemBuilder: (context, index) {
                                        final item = _itensTemp[index];
                                        return Container(
                                          decoration: BoxDecoration(
                                            border: Border(
                                              bottom: BorderSide(
                                                color: Colors.grey.shade200,
                                                width: 0.5,
                                              ),
                                            ),
                                          ),
                                          child: ListTile(
                                            dense: true,
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                  horizontal: 16,
                                                  vertical: 4,
                                                ),
                                            title: Text(
                                              item['produtoNome'],
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            subtitle: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    _buildQuantityChip(
                                                      'Retirada',
                                                      item['retirada'],
                                                      Colors.blue,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    _buildQuantityChip(
                                                      'Reposição',
                                                      item['reposicao'],
                                                      Colors.orange,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    _buildQuantityChip(
                                                      'Retorno',
                                                      item['retorno'],
                                                      Colors.red,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    _buildQuantityChip(
                                                      'Vendidos',
                                                      item['vendidos'],
                                                      AppColors.green,
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Preço: R\$ ${item['precoUnitario'].toStringAsFixed(2)}',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                              ],
                                            ),
                                            trailing: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 4,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.green,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    'R\$ ${item['subtotal'].toStringAsFixed(2)}',
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                IconButton(
                                                  icon: const Icon(
                                                    Icons.delete,
                                                    color: Colors.red,
                                                    size: 18,
                                                  ),
                                                  onPressed: () {
                                                    setState(() {
                                                      _itensTemp.removeAt(
                                                        index,
                                                      );
                                                    });
                                                    setDialogState(() {});
                                                  },
                                                  padding: EdgeInsets.zero,
                                                  constraints:
                                                      const BoxConstraints(),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.greenLight,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.green),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.calculate,
                                      color: AppColors.green,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Total dos Itens: R\$ ${_calcularTotalItens().toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.green,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ] else ...[
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Center(
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.shopping_cart_outlined,
                                        color: Colors.grey,
                                        size: 32,
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'Nenhum item adicionado',
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        'Clique em "Adicionar" para começar',
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
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
                            onPressed: _isLoading ? null : _saveVenda,
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
          );
        },
      ),
    );
  }

  void _showItemDialog(StateSetter setDialogState) {
    _selectedProdutoId = null;
    _retiradaController.clear();
    _reposicaoController.clear();
    _retornoController.clear();
    _precoUnitarioController.clear();

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
                      Icons.add_shopping_cart,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Adicionar Item',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
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
                    key: _itemFormKey,
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
                        const SizedBox(height: 12),

                        // Quantidades em linha (se houver espaço)
                        LayoutBuilder(
                          builder: (context, constraints) {
                            if (constraints.maxWidth > 300) {
                              return Row(
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
                                        if (value == null || value.isEmpty) {
                                          return 'Informe a reposição';
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
                              );
                            } else {
                              return Column(
                                children: [
                                  AppTextField(
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
                                  const SizedBox(height: 12),
                                  AppTextField(
                                    label: 'Reposição',
                                    controller: _reposicaoController,
                                    keyboardType: TextInputType.number,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Informe a reposição';
                                      }
                                      if (int.tryParse(value) == null) {
                                        return 'Valor deve ser um número';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  AppTextField(
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
                                ],
                              );
                            }
                          },
                        ),
                        const SizedBox(height: 12),

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
                        onPressed: () async => await _addItem(setDialogState),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.blue,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Adicionar'),
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

  Future<void> _addItem(StateSetter setDialogState) async {
    if (!_itemFormKey.currentState!.validate()) return;

    final retirada = int.parse(_retiradaController.text);
    final reposicao = int.parse(_reposicaoController.text);
    final retorno = int.parse(_retornoController.text);
    final precoUnitario = double.parse(_precoUnitarioController.text);
    final vendidos = ItemVenda.calcularVendidos(retirada, reposicao, retorno);
    final subtotal = ItemVenda.calcularSubtotal(vendidos, precoUnitario);

    // Verificar estoque antes de adicionar o item
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
                  'Não é possível adicionar este item. Verifique o estoque disponível.',
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

        return; // Não adiciona o item
      }
    }

    // Buscar nome do produto
    final produtosState = ref.read(produtoControllerProvider);
    final produtoNome = produtosState.when(
      loading: () => 'Carregando...',
      error: (error, stack) => 'Erro',
      data: (produtos) {
        final produto = produtos.firstWhere(
          (p) => p.id == _selectedProdutoId,
          orElse: () => throw Exception('Produto não encontrado'),
        );
        return '${produto.codigo} - ${produto.nome}';
      },
    );

    setState(() {
      _itensTemp.add({
        'produtoId': _selectedProdutoId,
        'produtoNome': produtoNome,
        'retirada': retirada,
        'reposicao': reposicao,
        'retorno': retorno,
        'vendidos': vendidos,
        'precoUnitario': precoUnitario,
        'subtotal': subtotal,
      });
    });

    // Limpar campos após adicionar
    _selectedProdutoId = null;
    _retiradaController.clear();
    _reposicaoController.clear();
    _retornoController.clear();
    _precoUnitarioController.clear();

    Navigator.of(context).pop();

    // Mostrar feedback visual
    AppFeedback.showSuccess(context, 'Item adicionado à lista!');

    // Forçar rebuild do dialog para mostrar o item adicionado
    setDialogState(() {});
  }

  // Método para calcular o total dos itens no formulário
  double _calcularTotalItens() {
    return _itensTemp.fold(
      0.0,
      (total, item) => total + (item['subtotal'] ?? 0.0),
    );
  }

  // Método para verificar se há discrepância entre valores de pagamento e total dos itens
  Future<bool> _verificarDiscrepancia(Venda venda) async {
    try {
      final totalItens = await _calcularTotalVenda(venda.id);
      final totalPagamento = venda.valorPix + venda.valorDinheiro;
      return (totalPagamento - totalItens).abs() >
          0.01; // Tolerância de 1 centavo
    } catch (e) {
      return false; // Em caso de erro, não mostrar alerta
    }
  }

  // Método para calcular a diferença entre valores de pagamento e total dos itens
  Future<double> _calcularDiferenca(Venda venda) async {
    try {
      final totalItens = await _calcularTotalVenda(venda.id);
      final totalPagamento = venda.valorPix + venda.valorDinheiro;
      return totalPagamento - totalItens;
    } catch (e) {
      return 0.0;
    }
  }

  // Método para mostrar alerta de discrepância
  void _mostrarAlertaDiscrepancia(BuildContext context, Venda venda) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 24),
            const SizedBox(width: 8),
            const Text('Discrepância Detectada'),
          ],
        ),
        content: FutureBuilder<double>(
          future: _calcularDiferenca(venda),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final diferenca = snapshot.data ?? 0.0;
            final totalPagamento = venda.valorPix + venda.valorDinheiro;
            final totalItens = totalPagamento - diferenca;

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Esta venda possui valores de pagamento que não correspondem ao total dos itens:',
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'PIX:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text('R\$ ${venda.valorPix.toStringAsFixed(2)}'),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Dinheiro:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text('R\$ ${venda.valorDinheiro.toStringAsFixed(2)}'),
                        ],
                      ),
                      Divider(height: 16, color: Colors.red),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total Pagamento:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'R\$ ${totalPagamento.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total Itens:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'R\$ ${totalItens.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.green,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Diferença:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'R\$ ${diferenca.abs().toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  diferenca > 0
                      ? 'O valor de pagamento está R\$ ${diferenca.toStringAsFixed(2)} acima do total dos itens.'
                      : 'O valor de pagamento está R\$ ${diferenca.abs().toStringAsFixed(2)} abaixo do total dos itens.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.red[700],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showVendaDialog(venda: venda);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Corrigir Venda'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveVenda() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final data = DateFormat('yyyy-MM-dd').parse(_dataController.text);
      final troco = double.parse(_trocoController.text);
      final valorPix = double.parse(_valorPixController.text);
      final valorDinheiro = double.parse(_valorDinheiroController.text);

      // Calcular o total dos itens
      final totalItens = _calcularTotalItens();

      // Verificar se os valores de pagamento somam o total dos itens
      final totalPagamento = valorPix + valorDinheiro;
      if (totalPagamento != totalItens) {
        AppFeedback.showError(
          context,
          'A soma dos valores de pagamento (PIX + Dinheiro) deve ser igual ao total dos itens (R\$ ${totalItens.toStringAsFixed(2)})',
        );
        setState(() => _isLoading = false);
        return;
      }

      // Verificar estoque antes de salvar a venda
      for (final itemData in _itensTemp) {
        final produtoId = itemData['produtoId'];
        final vendidos = itemData['vendidos'];

        // Verificar estoque atual do produto
        final estoqueAtual = await ref
            .read(estoqueControllerProvider.notifier)
            .getEstoqueProduto(produtoId);

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
                  final produto = produtos.firstWhere((p) => p.id == produtoId);
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
                      'Não é possível registrar esta venda. Verifique o estoque disponível.',
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
      }

      if (_editingVenda == null) {
        // Criar nova venda
        final novaVenda = Venda(
          id: '', // Será gerado pelo banco
          data: data,
          pontoId: _selectedPontoId!,
          vendedorId: _selectedVendedorId!,
          troco: troco,
          valorPix: valorPix,
          valorDinheiro: valorDinheiro,
        );

        final vendaCriada = await ref
            .read(vendaControllerProvider.notifier)
            .createVenda(novaVenda);

        // Criar itens da venda
        for (final itemData in _itensTemp) {
          final item = ItemVenda(
            id: '',
            vendaId: vendaCriada.id,
            produtoId: itemData['produtoId'],
            retirada: itemData['retirada'],
            reposicao: itemData['reposicao'],
            retorno: itemData['retorno'],
            precoUnitario: itemData['precoUnitario'],
            vendidos: itemData['vendidos'],
            subtotal: itemData['subtotal'],
          );
          await ref
              .read(vendaControllerProvider.notifier)
              .createItemVenda(item);
        }

        // Invalidar providers para atualizar os dados
        ref.invalidate(vendaControllerProvider);
        ref.invalidate(itensVendaProvider(vendaCriada.id));
        ref.invalidate(estoqueProvider);

        AppFeedback.showSuccess(context, 'Venda criada com sucesso!');
      } else {
        // Atualizar venda existente
        final vendaAtualizada = _editingVenda!.copyWith(
          data: data,
          pontoId: _selectedPontoId!,
          vendedorId: _selectedVendedorId!,
          troco: troco,
          valorPix: valorPix,
          valorDinheiro: valorDinheiro,
        );
        await ref
            .read(vendaControllerProvider.notifier)
            .updateVenda(vendaAtualizada);

        // Atualizar itens da venda (remover todos e recriar)
        final itensExistentes = await ref
            .read(vendaControllerProvider.notifier)
            .getItensVenda(_editingVenda!.id);

        // Remover itens existentes
        for (final item in itensExistentes) {
          await ref
              .read(vendaControllerProvider.notifier)
              .deleteItemVenda(item.id);
        }

        // Criar novos itens
        for (final itemData in _itensTemp) {
          final item = ItemVenda(
            id: '',
            vendaId: _editingVenda!.id,
            produtoId: itemData['produtoId'],
            retirada: itemData['retirada'],
            reposicao: itemData['reposicao'],
            retorno: itemData['retorno'],
            precoUnitario: itemData['precoUnitario'],
            vendidos: itemData['vendidos'],
            subtotal: itemData['subtotal'],
          );
          await ref
              .read(vendaControllerProvider.notifier)
              .createItemVenda(item);
        }

        // Invalidar providers para atualizar os dados
        ref.invalidate(vendaControllerProvider);
        ref.invalidate(itensVendaProvider(_editingVenda!.id));
        ref.invalidate(estoqueProvider);

        AppFeedback.showSuccess(context, 'Venda atualizada com sucesso!');
      }

      Navigator.of(context).pop();
    } catch (e) {
      AppFeedback.showError(context, e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteVenda(Venda venda) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => const ConfirmDialog(
        title: 'Confirmar Exclusão',
        message: 'Tem certeza que deseja excluir esta venda?',
        confirmText: 'Excluir',
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(vendaControllerProvider.notifier).deleteVenda(venda.id);

        // Invalidar providers para atualizar os dados
        ref.invalidate(vendaControllerProvider);
        ref.invalidate(itensVendaProvider(venda.id));
        ref.invalidate(estoqueProvider);

        AppFeedback.showSuccess(context, 'Venda excluída com sucesso!');
      } catch (e) {
        AppFeedback.showError(context, e.toString());
      }
    }
  }

  String _getPontoNome(String pontoId) {
    final pontosState = ref.read(pontoControllerProvider);
    return pontosState.when(
      loading: () => 'Carregando...',
      error: (error, stack) => 'Erro',
      data: (pontos) {
        final ponto = pontos.firstWhere(
          (p) => p.id == pontoId,
          orElse: () => throw Exception('Ponto não encontrado'),
        );
        return ponto.nome;
      },
    );
  }

  String _getVendedorNome(String vendedorId) {
    final vendedoresState = ref.read(vendedorControllerProvider);
    return vendedoresState.when(
      loading: () => 'Carregando...',
      error: (error, stack) => 'Erro',
      data: (vendedores) {
        final vendedor = vendedores.firstWhere(
          (v) => v.id == vendedorId,
          orElse: () => throw Exception('Vendedor não encontrado'),
        );
        return vendedor.nome;
      },
    );
  }

  Widget _buildQuantityChip(String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w500,
          fontSize: 10,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vendasState = ref.watch(vendaControllerProvider);

    return MainLayout(
      title: 'Vendas',
      breadcrumbs: const [BreadcrumbItem('Vendas')],
      selectedSidebarIndex: 4, // Índice do item Vendas no sidebar
      onSidebarItemSelected: (i) => context.go(sidebarItemsWithRoutes[i].route),
      actions: [
        IconButton(
          onPressed: () {
            ref.invalidate(vendaControllerProvider);
            AppFeedback.showSuccess(context, 'Dados atualizados!');
          },
          icon: const Icon(Icons.refresh),
          tooltip: 'Atualizar dados',
        ),
        const SizedBox(width: 8),
        ElevatedButton.icon(
          onPressed: () => _showVendaDialog(),
          icon: const Icon(Icons.add),
          label: const Text('Nova Venda'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.green,
            foregroundColor: Colors.white,
          ),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: vendasState.when(
          loading: () => const Center(child: AppLoading()),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Erro ao carregar vendas: $error'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () =>
                      ref.read(vendaControllerProvider.notifier).loadVendas(),
                  child: const Text('Tentar Novamente'),
                ),
              ],
            ),
          ),
          data: (vendas) => vendas.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.receipt_long_outlined,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Nenhuma venda encontrada',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Clique em "Nova Venda" para começar',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Resumo das vendas
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.greenLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.green),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.analytics,
                            color: AppColors.green,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Resumo das Vendas',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.green,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${vendas.length} vendas registradas',
                                  style: TextStyle(
                                    color: AppColors.green,
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
                              color: AppColors.green,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: FutureBuilder<double>(
                              future: _calcularTotalVendas(vendas),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  );
                                }
                                return Text(
                                  'R\$ ${(snapshot.data ?? 0.0).toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Lista de vendas
                    Expanded(
                      child: ListView.builder(
                        itemCount: vendas.length,
                        itemBuilder: (context, index) {
                          final venda = vendas[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
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
                            child: Column(
                              children: [
                                // Header do card
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppColors.blue.withOpacity(0.1),
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(12),
                                      topRight: Radius.circular(12),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: AppColors.blue,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.receipt_long,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Venda #${venda.id.substring(0, 8).toUpperCase()}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                            Text(
                                              DateFormat(
                                                'dd/MM/yyyy',
                                              ).format(venda.data),
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      FutureBuilder<double>(
                                        future: _calcularTotalVenda(venda.id),
                                        builder: (context, snapshot) {
                                          if (snapshot.connectionState ==
                                              ConnectionState.waiting) {
                                            return const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                      Color
                                                    >(AppColors.green),
                                              ),
                                            );
                                          }
                                          return Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.green,
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              'R\$ ${(snapshot.data ?? 0.0).toStringAsFixed(2)}',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),

                                // Conteúdo do card
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    children: [
                                      // Informações da venda
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _buildInfoItem(
                                              icon: Icons.store,
                                              label: 'Ponto',
                                              value: _getPontoNome(
                                                venda.pontoId,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: _buildInfoItem(
                                              icon: Icons.person,
                                              label: 'Vendedor',
                                              value: _getVendedorNome(
                                                venda.vendedorId,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),

                                      // Valores de pagamento
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[50],
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: _buildPaymentInfo(
                                                label: 'PIX',
                                                value:
                                                    'R\$ ${venda.valorPix.toStringAsFixed(2)}',
                                                color: Colors.green,
                                              ),
                                            ),
                                            Expanded(
                                              child: _buildPaymentInfo(
                                                label: 'Dinheiro',
                                                value:
                                                    'R\$ ${venda.valorDinheiro.toStringAsFixed(2)}',
                                                color: Colors.blue,
                                              ),
                                            ),
                                            Expanded(
                                              child: _buildPaymentInfo(
                                                label: 'Troco',
                                                value:
                                                    'R\$ ${venda.troco.toStringAsFixed(2)}',
                                                color: Colors.orange,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Ações
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    borderRadius: const BorderRadius.only(
                                      bottomLeft: Radius.circular(12),
                                      bottomRight: Radius.circular(12),
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      // Botão de verificar discrepância
                                      FutureBuilder<bool>(
                                        future: _verificarDiscrepancia(venda),
                                        builder: (context, discrepanciaSnapshot) {
                                          final temDiscrepancia =
                                              discrepanciaSnapshot.data ??
                                              false;
                                          if (temDiscrepancia) {
                                            return Container(
                                              width: double.infinity,
                                              margin: const EdgeInsets.only(
                                                bottom: 12,
                                              ),
                                              child: ElevatedButton.icon(
                                                onPressed: () =>
                                                    _mostrarAlertaDiscrepancia(
                                                      context,
                                                      venda,
                                                    ),
                                                icon: const Icon(
                                                  Icons.warning_amber_rounded,
                                                  size: 16,
                                                ),
                                                label: const Text(
                                                  'Verificar Discrepância',
                                                ),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      Colors.orange,
                                                  foregroundColor: Colors.white,
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        vertical: 12,
                                                      ),
                                                ),
                                              ),
                                            );
                                          }
                                          return const SizedBox.shrink();
                                        },
                                      ),
                                      // Botões principais
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        children: [
                                          Expanded(
                                            child: OutlinedButton.icon(
                                              onPressed: () => context.push(
                                                '/vendas/${venda.id}/itens',
                                              ),
                                              icon: const Icon(
                                                Icons.shopping_cart,
                                                size: 16,
                                              ),
                                              label: const Text('Ver Itens'),
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: AppColors.blue,
                                                side: BorderSide(
                                                  color: AppColors.blue,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: OutlinedButton.icon(
                                              onPressed: () => _showVendaDialog(
                                                venda: venda,
                                              ),
                                              icon: const Icon(
                                                Icons.edit,
                                                size: 16,
                                              ),
                                              label: const Text('Editar'),
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: AppColors.blue,
                                                side: BorderSide(
                                                  color: AppColors.blue,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: OutlinedButton.icon(
                                              onPressed: () =>
                                                  _deleteVenda(venda),
                                              icon: const Icon(
                                                Icons.delete,
                                                size: 16,
                                              ),
                                              label: const Text('Excluir'),
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: Colors.red,
                                                side: BorderSide(
                                                  color: Colors.red,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
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

  // Método para calcular o total de uma venda específica baseado nos itens
  Future<double> _calcularTotalVenda(String vendaId) async {
    try {
      final itens = await ref
          .read(vendaControllerProvider.notifier)
          .getItensVenda(vendaId);
      double total = 0.0;
      for (final item in itens) {
        total += item.subtotal;
      }
      return total;
    } catch (e) {
      return 0.0;
    }
  }

  // Método para calcular o total de todas as vendas baseado nos itens
  Future<double> _calcularTotalVendas(List<Venda> vendas) async {
    double total = 0.0;
    for (final venda in vendas) {
      try {
        final itens = await ref
            .read(vendaControllerProvider.notifier)
            .getItensVenda(venda.id);
        final vendaTotal = itens.fold(0.0, (sum, item) => sum + item.subtotal);
        total += vendaTotal;
      } catch (e) {
        // Se houver erro, continua com 0.0
      }
    }
    return total;
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentInfo({
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
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
