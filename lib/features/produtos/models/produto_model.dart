class Produto {
  final String id;
  final int codigo;
  final String nome;

  Produto({required this.id, required this.codigo, required this.nome});

  factory Produto.fromJson(Map<String, dynamic> json) {
    return Produto(
      id: json['id'] as String,
      codigo: json['codigo'] as int,
      nome: json['nome'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'codigo': codigo, 'nome': nome};
  }

  Produto copyWith({String? id, int? codigo, String? nome}) {
    return Produto(
      id: id ?? this.id,
      codigo: codigo ?? this.codigo,
      nome: nome ?? this.nome,
    );
  }

  @override
  String toString() {
    return 'Produto(id: $id, codigo: $codigo, nome: $nome)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Produto &&
        other.id == id &&
        other.codigo == codigo &&
        other.nome == nome;
  }

  @override
  int get hashCode => id.hashCode ^ codigo.hashCode ^ nome.hashCode;
}
