enum TripSortOption {
  newest,
  oldest,
  highestConsumption,
  lowestConsumption,
  highestDistance,
  lowestDistance,
  highestDuration,
  lowestDuration,
  highestCost,
  lowestCost,
  bestScore,
  worstScore,
}

extension TripSortOptionExtension on TripSortOption {
  String get label {
    switch (this) {
      case TripSortOption.newest:
        return 'Más recientes';
      case TripSortOption.oldest:
        return 'Más antiguos';
      case TripSortOption.highestConsumption:
        return 'Mayor consumo';
      case TripSortOption.lowestConsumption:
        return 'Menor consumo';
      case TripSortOption.highestDistance:
        return 'Mayor distancia';
      case TripSortOption.lowestDistance:
        return 'Menor distancia';
      case TripSortOption.highestDuration:
        return 'Mayor duración';
      case TripSortOption.lowestDuration:
        return 'Menor duración';
      case TripSortOption.highestCost:
        return 'Mayor costo';
      case TripSortOption.lowestCost:
        return 'Menor costo';
      case TripSortOption.bestScore:
        return 'Mejor score';
      case TripSortOption.worstScore:
        return 'Peor score';
    }
  }

  String get column {
    switch (this) {
      case TripSortOption.newest:
      case TripSortOption.oldest:
        return 'started_at';
      case TripSortOption.highestConsumption:
      case TripSortOption.lowestConsumption:
        return 'estimated_fuel_consumed_gallons';
      case TripSortOption.highestDistance:
      case TripSortOption.lowestDistance:
        return 'distance_km';
      case TripSortOption.highestDuration:
      case TripSortOption.lowestDuration:
        return 'duration_seconds';
      case TripSortOption.highestCost:
      case TripSortOption.lowestCost:
        return 'estimated_cost_cop';
      case TripSortOption.bestScore:
      case TripSortOption.worstScore:
        return 'eco_score';
    }
  }

  bool get ascending {
    switch (this) {
      case TripSortOption.oldest:
      case TripSortOption.lowestConsumption:
      case TripSortOption.lowestDistance:
      case TripSortOption.lowestDuration:
      case TripSortOption.lowestCost:
      case TripSortOption.worstScore:
        return true;
      case TripSortOption.newest:
      case TripSortOption.highestConsumption:
      case TripSortOption.highestDistance:
      case TripSortOption.highestDuration:
      case TripSortOption.highestCost:
      case TripSortOption.bestScore:
        return false;
    }
  }
}