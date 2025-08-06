class MovimentacaoEstoque {
  final String id;
  final DateTime data;
  final String produtoId;
  final String tipo; // 'entrada', 'saida', 'venda'
  final int quantidade;
  final String? referenciaId;
  final String? observacao;

  MovimentacaoEstoque({
    required this.id,
    required this.data,
    required this.produtoId,
    required this.tipo,
    required this.quantidade,
    this.referenciaId,
    this.observacao,
  });

  factory MovimentacaoEstoque.fromJson(Map<String, dynamic> json) {
    return MovimentacaoEstoque(
      id: json['id'],
      data: DateTime.parse(json['data']),
      produtoId: json['produto_id'],
      tipo: json['tipo'],
      quantidade: json['quantidade'],
      referenciaId: json['referencia_id'],
      observacao: json['observacao'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'data': data.toIso8601String(),
      'produto_id': produtoId,
      'tipo': tipo,
      'quantidade': quantidade,
      'referencia_id': referenciaId,
      'observacao': observacao,
    };
  }

  MovimentacaoEstoque copyWith({
    String? id,
    DateTime? data,
    String? produtoId,
    String? tipo,
    int? quantidade,
    String? referenciaId,
    String? observacao,
  }) {
    return MovimentacaoEstoque(
      id: id ?? this.id,
      data: data ?? this.data,
      produtoId: produtoId ?? this.produtoId,
      tipo: tipo ?? this.tipo,
      quantidade: quantidade ?? this.quantidade,
      referenciaId: referenciaId ?? this.referenciaId,
      observacao: observacao ?? this.observacao,
    );
  }
}
