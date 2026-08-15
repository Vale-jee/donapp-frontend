import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/category.dart';

class CategoryService {
  const CategoryService();

  Future<List<Category>> getCategories() async {
    try {
      final response = await http
          .get(
            ApiConfig.endpoint('/api/categorias'),
            headers: const {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw CategoryServiceException(
          'La API respondio con el estado HTTP ${response.statusCode}.',
        );
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic> || decoded['success'] != true) {
        throw const FormatException('Respuesta principal invalida.');
      }
      final data = decoded['data'];
      if (data is! Map<String, dynamic> || data['categorias'] is! List) {
        throw const FormatException('Listado de categorias invalido.');
      }
      return (data['categorias'] as List)
          .map((item) {
            if (item is! Map<String, dynamic>) {
              throw const FormatException('Categoria invalida.');
            }
            return Category.fromJson(item);
          })
          .toList(growable: false);
    } on ApiConfigException catch (error) {
      throw CategoryServiceException(error.message);
    } on TimeoutException {
      throw const CategoryServiceException(
        'La conexion con la API supero el tiempo de espera.',
      );
    } on http.ClientException {
      throw const CategoryServiceException(
        'No fue posible conectar con la API. Verifique el backend y adb reverse.',
      );
    } on FormatException {
      throw const CategoryServiceException(
        'La API devolvio una respuesta con formato inesperado.',
      );
    }
  }
}

class CategoryServiceException implements Exception {
  const CategoryServiceException(this.message);
  final String message;
  @override
  String toString() => message;
}
