import 'package:ecopulse/data/models/location_sample_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

class LocationService {
  Future<LocationSampleModel> getCurrentLocation() async {
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.bestForNavigation,
    );

    return LocationSampleModel.fromPosition(position);
  }

  Stream<LocationSampleModel> watchLocation() {
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 5,
    );

    return Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).map(LocationSampleModel.fromPosition);
  }
}