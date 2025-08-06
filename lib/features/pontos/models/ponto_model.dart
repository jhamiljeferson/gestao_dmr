class Ponto {
  final String id;
  final String nome;

  Ponto({required this.id, required this.nome});

  factory Ponto.fromJson(Map<String, dynamic> json) {
    return Ponto(id: json['id'] as String, nome: json['nome'] as String);
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'nome': nome};
  }

  Ponto copyWith({String? id, String? nome}) {
    return Ponto(id: id ?? this.id, nome: nome ?? this.nome);
  }

  @override
  String toString() {
    return 'Ponto(id: $id, nome: $nome)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Ponto && other.id == id && other.nome == nome;
  }

  @override
  int get hashCode => id.hashCode ^ nome.hashCode;
}
