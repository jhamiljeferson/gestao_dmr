class Vendedor {
  final String id;
  final String nome;

  Vendedor({required this.id, required this.nome});

  factory Vendedor.fromJson(Map<String, dynamic> json) {
    return Vendedor(id: json['id'] as String, nome: json['nome'] as String);
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'nome': nome};
  }

  Vendedor copyWith({String? id, String? nome}) {
    return Vendedor(id: id ?? this.id, nome: nome ?? this.nome);
  }

  @override
  String toString() {
    return 'Vendedor(id: $id, nome: $nome)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Vendedor && other.id == id && other.nome == nome;
  }

  @override
  int get hashCode => id.hashCode ^ nome.hashCode;
}
