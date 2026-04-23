class NutritionAIService {
  String recommendForWeight(double peso) {
    if (peso > 400) return 'Dieta alta en proteína';
    if (peso < 300) return 'Dieta de engorde';
    return 'Dieta balanceada';
  }

  String recommendDetail(double peso) {
    final base = recommendForWeight(peso);
    if (base == 'Dieta alta en proteína') {
      return 'Dieta alta en proteína: prioriza fuentes proteicas, balance mineral y acceso constante a agua.';
    }
    if (base == 'Dieta de engorde') {
      return 'Dieta de engorde: incrementa energía con carbohidratos de calidad y controla la transición de raciones.';
    }
    return 'Dieta balanceada: mantén proporción adecuada de energía y proteína con forraje de buena calidad.';
  }
}

