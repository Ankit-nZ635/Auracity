import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationService {
  static Future<Position> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied, we cannot request permissions.');
    } 

    return await Geolocator.getCurrentPosition();
  }

  static Future<String> getAddressFromLatLng(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String city = place.locality ?? place.subAdministrativeArea ?? 'Unknown City';
        String country = place.country ?? '';
        return country.isNotEmpty ? "$city, $country" : city;
      }
      return 'Unknown Location';
    } catch (e) {
      return 'Location not found';
    }
  }

  static List<List<T>> clusterItems<T>(
    List<T> items, 
    double Function(T) getLat, 
    double Function(T) getLng, 
    {double radius = 50.0}
  ) {
    List<List<T>> clusters = [];
    List<T> remaining = List.from(items);

    while (remaining.isNotEmpty) {
      T current = remaining.removeAt(0);
      List<T> cluster = [current];
      List<T> toRemove = [];

      for (var other in remaining) {
        double dist = Geolocator.distanceBetween(
          getLat(current), getLng(current), 
          getLat(other), getLng(other)
        );
        if (dist <= radius) {
          cluster.add(other);
          toRemove.add(other);
        }
      }

      for (var item in toRemove) {
        remaining.remove(item);
      }
      clusters.add(cluster);
    }
    return clusters;
  }
}
