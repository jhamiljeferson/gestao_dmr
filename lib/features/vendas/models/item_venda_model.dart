class ItemVenda {
  final String id;
  final String vendaId;
  final String produtoId;
  final int retirada;
  final int reposicao;
  final int retorno;
  final double precoUnitario;
  final int vendidos;
  final double subtotal;

  ItemVenda({
    required this.id,
    required this.vendaId,
    required this.produtoId,
    this.retirada = 0,
    this.reposicao = 0,
    this.retorno = 0,
    required this.precoUnitario,
    required this.vendidos,
    required this.subtotal,
  });

  factory ItemVenda.fromJson(Map<String, dynamic> json) {
    return ItemVenda(
      id: json['id'],
      vendaId: json['venda_id'],
      produtoId: json['produto_id'],
      retirada: json['retirada'] ?? 0,
      reposicao: json['reposicao'] ?? 0,
      retorno: json['retorno'] ?? 0,
      precoUnitario: (json['preco_unitario'] ?? 0.0).toDouble(),
      vendidos: json['vendidos'] ?? 0,
      subtotal: (json['subtotal'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'venda_id': vendaId,
      'produto_id': produtoId,
      'retirada': retirada,
      'reposicao': reposicao,
      'retorno': retorno,
      'preco_unitario': precoUnitario,
      'vendidos': vendidos,
      'subtotal': subtotal,
    };
  }

  ItemVenda copyWith({
    String? id,
    String? vendaId,
    String? produtoId,
    int? retirada,
    int? reposicao,
    int? retorno,
    double? precoUnitario,
    int? vendidos,
    double? subtotal,
  }) {
    return ItemVenda(
      id: id ?? this.id,
      vendaId: vendaId ?? this.vendaId,
      produtoId: produtoId ?? this.produtoId,
      retirada: retirada ?? this.retirada,
      reposicao: reposicao ?? this.reposicao,
      retorno: retorno ?? this.retorno,
      precoUnitario: precoUnitario ?? this.precoUnitario,
      vendidos: vendidos ?? this.vendidos,
      subtotal: subtotal ?? this.subtotal,
    );
  }

  // Calcula vendidos baseado em retirada, reposicao e retorno
  static int calcularVendidos(int retirada, int reposicao, int retorno) {
    return retirada + reposicao - retorno;
  }

  // Calcula subtotal baseado em vendidos e preço unitário
  static double calcularSubtotal(int vendidos, double precoUnitario) {
    return vendidos * precoUnitario;
  }

  @override
  String toString() {
    return 'ItemVenda(id: $id, vendaId: $vendaId, produtoId: $produtoId, retirada: $retirada, reposicao: $reposicao, retorno: $retorno, precoUnitario: $precoUnitario, vendidos: $vendidos, subtotal: $subtotal)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ItemVenda &&
        other.id == id &&
        other.vendaId == vendaId &&
        other.produtoId == produtoId &&
        other.retirada == retirada &&
        other.reposicao == reposicao &&
        other.retorno == retorno &&
        other.precoUnitario == precoUnitario &&
        other.vendidos == vendidos &&
        other.subtotal == subtotal;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        vendaId.hashCode ^
        produtoId.hashCode ^
        retirada.hashCode ^
        reposicao.hashCode ^
        retorno.hashCode ^
        precoUnitario.hashCode ^
        vendidos.hashCode ^
        subtotal.hashCode;
  }
}
