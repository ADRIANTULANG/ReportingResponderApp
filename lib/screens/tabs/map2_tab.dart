import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class Map2Tab extends StatefulWidget {
  const Map2Tab({super.key});

  @override
  State<Map2Tab> createState() => _Map2TabState();
}

class _Map2TabState extends State<Map2Tab> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    determinePosition();

    getMyReports();
    Geolocator.getCurrentPosition().then((position) {
      setState(() {
        lat = position.latitude;
        long = position.longitude;
        hasloaded = true;
      });
    }).catchError((error) {
      print('Error getting location: $error');
    });
  }

  // List<LatLng> dijkstra(LatLng source, LatLng destination) {
  //   Map<String, double> distances = {}; // Store shortest distances from source
  //   Map<String, LatLng?> previous = {}; // Store previous nodes in optimal path
  //   List<LatLng> path = []; // Store the shortest path

  //   // Convert LatLng objects to strings for use as keys in maps
  //   String sourceKey = "${source.latitude}_${source.longitude}";
  //   String destinationKey = "${destination.latitude}_${destination.longitude}";

  //   // Initialize distances and previous nodes
  //   markers.forEach((marker) {
  //     String markerKey =
  //         "${marker.position.latitude}_${marker.position.longitude}";
  //     distances[markerKey] = double.infinity;
  //     previous[markerKey] = null;
  //   });

  //   distances[sourceKey] = 0; // Distance from source to itself is zero

  //   Set<String> visited = Set<String>();

  //   while (visited.length != markers.length) {
  //     String currentKey = _minDistance(distances, visited);
  //     visited.add(currentKey);

  //     LatLng current = _convertToLatLng(currentKey);

  //     markers.forEach((marker) {
  //       String markerKey =
  //           "${marker.position.latitude}_${marker.position.longitude}";
  //       if (!visited.contains(markerKey)) {
  //         double edgeDistance = _calculateDistance(current, marker.position);
  //         double currentDistance = distances[currentKey] ?? double.infinity;
  //         double totalDistance = currentDistance + edgeDistance;

  //         double? markerDistance = distances[markerKey];
  //         if (markerDistance == null || totalDistance < markerDistance) {
  //           distances[markerKey] = totalDistance;
  //           previous[markerKey] = current;
  //         }
  //       }
  //     });
  //   }

  //   String currentKey = destinationKey;
  //   while (previous[currentKey] != null) {
  //     LatLng? currentLatLng = _convertToLatLng(currentKey);
  //     path.insert(0, currentLatLng);
  //     currentKey =
  //         "${previous[currentKey]!.latitude}_${previous[currentKey]!.longitude}";
  //   }
  //   path.insert(0, source);

  //   return path;
  // }

  // double _calculateDistance(LatLng start, LatLng end) {
  //   return Geolocator.distanceBetween(
  //     start.latitude,
  //     start.longitude,
  //     end.latitude,
  //     end.longitude,
  //   );
  // }

  // String _minDistance(Map<String, double> distances, Set<String> visited) {
  //   String minNode = '';
  //   double min = double.infinity;

  //   distances.forEach((key, value) {
  //     if (!visited.contains(key) && value < min) {
  //       min = value;
  //       minNode = key;
  //     }
  //   });
  //   return minNode;
  // }

  // LatLng _convertToLatLng(String key) {
  //   List<String> parts = key.split('_');
  //   double lat = double.parse(parts[0]);
  //   double lng = double.parse(parts[1]);
  //   return LatLng(lat, lng);
  // }
  bool hasloaded = false;
  GoogleMapController? mapController;

  double lat = 0;
  double long = 0;
  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();

  Set<Marker> markers = {};
  Set<Polyline> poly = {};

  addMarker(userData) async {
    markers.add(Marker(
      markerId: MarkerId(userData.id),
      icon: BitmapDescriptor.defaultMarker,
      position: LatLng(userData['lat'], userData['long']),
      infoWindow: InfoWindow(
        title: 'Caption: ${userData['caption']}',
        snippet: 'Reporter Name: ${userData['name']}',
      ),
    ));

    poly.add(
      Polyline(
          color: Colors.red,
          width: 2,
          points: [
            LatLng(lat, long),
            LatLng(userData['lat'], userData['long']),
          ],
          polylineId: PolylineId(userData.id)),
    );
    setState(() {});
  }

  getMyReports() async {
    FirebaseFirestore.instance
        .collection('Reports')
        .where('status', isEqualTo: 'Pending')
        .where('responder', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
        .get()
        .then((QuerySnapshot querySnapshot) async {
      for (var doc in querySnapshot.docs) {
        addMarker(doc);
      }
    });

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    CameraPosition kGooglePlex = CameraPosition(
      target: LatLng(lat, long),
      zoom: 14.4746,
    );
    return hasloaded
        ? GoogleMap(
            polylines: poly,
            myLocationEnabled: true,
            markers: markers,
            mapType: MapType.normal,
            initialCameraPosition: kGooglePlex,
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
            },
          )
        : const Center(
            child: CircularProgressIndicator(),
          );
  }

  Future<Position> determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    return await Geolocator.getCurrentPosition();
  }
}
