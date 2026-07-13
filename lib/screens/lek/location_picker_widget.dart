import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong2.dart'; // Le vrai import officiel !

class LocationPickerWidget extends StatefulWidget {
  const LocationPickerWidget({super.key});

  @override
  State<LocationPickerWidget> createState() => _LocationPickerWidgetState();
}

class _LocationPickerWidgetState extends State<LocationPickerWidget> {
  // On utilise le vrai type LatLng attendu par le package
  LatLng _currentPosition = const LatLng(48.8566, 2.3522);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choisir une localisation'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: Colors.green),
            onPressed: () {
              // On extrait le texte pour la page principale
              String textResult = "${_currentPosition.latitude}, ${_currentPosition.longitude}";
              Navigator.pop(context, textResult);
            },
          )
        ],
      ),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: _currentPosition, // Plus aucun conflit de type !
          initialZoom: 13.0,
          onTap: (tapPosition, point) {
            setState(() {
              _currentPosition = point; // 'point' est déjà un LatLng parfait
            });
          },
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: _currentPosition,
                width: 40,
                height: 40,
                child: const Icon(Icons.location_on, color: Colors.red, size: 40),
              ),
            ],
          ),
        ],
      ),
    );
  }
}