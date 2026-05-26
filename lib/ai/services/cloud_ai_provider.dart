/// Contrato para proveedores de IA conversacional en la nube.
abstract class CloudAiProvider {
  String get displayName;
  bool get isConfigured;

  /// Devuelve JSON estructurado parseado desde la respuesta del modelo.
  Future<Map<String, dynamic>> completeStructured({
    required List<Map<String, String>> messages,
  });
}
