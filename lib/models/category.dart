class Category {
  const Category({
    required this.id,
    required this.nombre,
    required this.descripcion,
  });
  final int id;
  final String nombre;
  final String? descripcion;

  factory Category.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final nombre = json['nombre'];
    final descripcion = json['descripcion'];
    if (id is! int ||
        nombre is! String ||
        (descripcion != null && descripcion is! String)) {
      throw const FormatException('Categoria con formato invalido.');
    }
    return Category(
      id: id,
      nombre: nombre,
      descripcion: descripcion as String?,
    );
  }
}
