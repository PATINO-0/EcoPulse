class FuelPriceSanityService {
  static const double minColombianFuelPriceCop = 5000;
  static const double maxRegularFuelPriceCop = 25000;
  static const double maxDieselFuelPriceCop = 25000;

  const FuelPriceSanityService();

  double? parseCopPerGallon(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      return value.toDouble();
    }

    var text = value.toString().trim();

    if (text.isEmpty) {
      return null;
    }

    // Limpia símbolos comunes de moneda y texto.
    text = text
        .replaceAll('COP', '')
        .replaceAll('cop', '')
        .replaceAll(r'$', '')
        .replaceAll('pesos', '')
        .replaceAll('PESOS', '')
        .trim();

    // Caso colombiano: "13.487,50" => 13487.50
    if (text.contains('.') && text.contains(',')) {
      text = text.replaceAll('.', '').replaceAll(',', '.');
      return double.tryParse(text);
    }

    // Caso colombiano frecuente: "13.487" => 13487
    final dotThousandsPattern = RegExp(r'^\d{1,3}(\.\d{3})+$');
    if (dotThousandsPattern.hasMatch(text)) {
      text = text.replaceAll('.', '');
      return double.tryParse(text);
    }

    // Caso alternativo: "13,487" => 13487
    final commaThousandsPattern = RegExp(r'^\d{1,3}(,\d{3})+$');
    if (commaThousandsPattern.hasMatch(text)) {
      text = text.replaceAll(',', '');
      return double.tryParse(text);
    }

    // Caso decimal internacional simple.
    return double.tryParse(text.replaceAll(',', '.'));
  }

  bool isRealisticColombianFuelPrice({
    required String fuelType,
    required double price,
  }) {
    if (price < minColombianFuelPriceCop) {
      return false;
    }

    final normalized = normalizeFuelType(fuelType);

    if (normalized == 'DIESEL') {
      return price <= maxDieselFuelPriceCop;
    }

    if (normalized == 'GASOLINA_CORRIENTE') {
      return price <= maxRegularFuelPriceCop;
    }

    return price <= maxRegularFuelPriceCop;
  }

  String normalizeFuelType(String fuelType) {
    final value = fuelType.trim().toUpperCase();

    if (value.contains('DIESEL') ||
        value.contains('DIÉSEL') ||
        value.contains('ACPM')) {
      return 'DIESEL';
    }

    if (value.contains('CORRIENTE') || value.contains('GASOLINA')) {
      return 'GASOLINA_CORRIENTE';
    }

    return value;
  }
}