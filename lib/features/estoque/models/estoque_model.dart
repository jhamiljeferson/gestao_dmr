class Estoque {
  final String id;
  final String produtoId;
  final int quantidade;

  Estoque({
    required this.id,
    required this.produtoId,
    required this.quantidade,
  });

  factory Estoque.fromJson(Map<String, dynamic> json) {
    return Estoque(
      id: json['id'],
      produtoId: json['produto_id'],
      quantidade: json['quantidade'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'produto_id': produtoId, 'quantidade': quantidade};
  }

  Estoque copyWith({String? id, String? produtoId, int? quantidade}) {
    return Estoque(
      id: id ?? this.id,
      produtoId: produtoId ?? this.produtoId,
      quantidade: quantidade ?? this.quantidade,
    );
  }
}
