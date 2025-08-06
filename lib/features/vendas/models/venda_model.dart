class Venda {
  final String id;
  final DateTime data;
  final String pontoId;
  final String vendedorId;
  final double troco;
  final double valorPix;
  final double valorDinheiro;

  Venda({
    required this.id,
    required this.data,
    required this.pontoId,
    required this.vendedorId,
    this.troco = 0.0,
    this.valorPix = 0.0,
    this.valorDinheiro = 0.0,
  });

  factory Venda.fromJson(Map<String, dynamic> json) {
    return Venda(
      id: json['id'],
      data: DateTime.parse(json['data']),
      pontoId: json['ponto_id'],
      vendedorId: json['vendedor_id'],
      troco: (json['troco'] ?? 0.0).toDouble(),
      valorPix: (json['valor_pix'] ?? 0.0).toDouble(),
      valorDinheiro: (json['valor_dinheiro'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'data': data.toIso8601String().split('T')[0], // Formato YYYY-MM-DD
      'ponto_id': pontoId,
      'vendedor_id': vendedorId,
      'troco': troco,
      'valor_pix': valorPix,
      'valor_dinheiro': valorDinheiro,
    };
  }

  Venda copyWith({
    String? id,
    DateTime? data,
    String? pontoId,
    String? vendedorId,
    double? troco,
    double? valorPix,
    double? valorDinheiro,
  }) {
    return Venda(
      id: id ?? this.id,
      data: data ?? this.data,
      pontoId: pontoId ?? this.pontoId,
      vendedorId: vendedorId ?? this.vendedorId,
      troco: troco ?? this.troco,
      valorPix: valorPix ?? this.valorPix,
      valorDinheiro: valorDinheiro ?? this.valorDinheiro,
    );
  }

  @override
  String toString() {
    return 'Venda(id: $id, data: $data, pontoId: $pontoId, vendedorId: $vendedorId, troco: $troco, valorPix: $valorPix, valorDinheiro: $valorDinheiro)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Venda &&
        other.id == id &&
        other.data == data &&
        other.pontoId == pontoId &&
        other.vendedorId == vendedorId &&
        other.troco == troco &&
        other.valorPix == valorPix &&
        other.valorDinheiro == valorDinheiro;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        data.hashCode ^
        pontoId.hashCode ^
        vendedorId.hashCode ^
        troco.hashCode ^
        valorPix.hashCode ^
        valorDinheiro.hashCode;
  }

  // Calcula o valor total da venda baseado na soma dos itens
  // Por enquanto retorna PIX + Dinheiro, mas será calculado dinamicamente
  double get valorTotal => valorPix + valorDinheiro;

  // Método para calcular valor total baseado nos itens (será usado quando disponível)
  static double calcularValorTotalItens(List<Map<String, dynamic>> itens) {
    return itens.fold(0.0, (total, item) => total + (item['subtotal'] ?? 0.0));
  }
}
