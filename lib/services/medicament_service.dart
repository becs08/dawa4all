// lib/services/medicament_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/medicament_model.dart';

class MedicamentService {
  // Remplacez cette URL par l'adresse IP de votre machine si vous testez sur un appareil réel
  // Si vous utilisez l'émulateur Android, utilisez 10.0.2.2 au lieu de localhost
  final String baseUrl = 'http://10.0.2.2:5000';  // Pour l'émulateur Android
  // final String baseUrl = 'http://localhost:5000';  // Pour le web ou le simulateur iOS
  String? _authHeader;

  void setAuth(String username, String password) {
    _authHeader = '$username:$password';
  }

  void clearAuth() {
    _authHeader = null;
  }

  Map<String, String> _getHeaders() {
    final headers = {'Content-Type': 'application/json'};
    if (_authHeader != null) {
      headers['Authorization'] = _authHeader!;
    }
    return headers;
  }

  // Récupérer tous les médicaments
  Future<List<Medicament>> getMedicaments() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/medicaments'));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Medicament.fromJson(json)).toList();
      } else {
        throw Exception('Échec de chargement des médicaments: ${response.reasonPhrase}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de la récupération des médicaments: $e');
      }
      throw Exception('Erreur réseau ou serveur: $e');
    }
  }

  // Récupérer un médicament par son ID
  Future<Medicament> getMedicament(String id) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/medicaments/$id'));

      if (response.statusCode == 200) {
        return Medicament.fromJson(json.decode(response.body));
      } else {
        throw Exception('Médicament non trouvé: ${response.reasonPhrase}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de la récupération du médicament: $e');
      }
      throw Exception('Erreur réseau ou serveur: $e');
    }
  }

  // Ajouter un nouveau médicament
  Future<Medicament> addMedicament(Medicament medicament) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/medicaments'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(medicament.toJson()),
      );

      if (response.statusCode == 201) {
        return Medicament.fromJson(json.decode(response.body));
      } else {
        throw Exception('Échec de création du médicament: ${response.reasonPhrase}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de l\'ajout du médicament: $e');
      }
      throw Exception('Erreur réseau ou serveur: $e');
    }
  }

  // Mettre à jour un médicament
  Future<void> updateMedicament(String id, Medicament medicament) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/medicaments/$id'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(medicament.toJson()),
      );

      if (response.statusCode != 200) {
        throw Exception('Échec de mise à jour du médicament: ${response.reasonPhrase}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de la mise à jour du médicament: $e');
      }
      throw Exception('Erreur réseau ou serveur: $e');
    }
  }

  // Supprimer un médicament
  Future<void> deleteMedicament(String id) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/medicaments/$id'));

      if (response.statusCode != 200) {
        throw Exception('Échec de suppression du médicament: ${response.reasonPhrase}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de la suppression du médicament: $e');
      }
      throw Exception('Erreur réseau ou serveur: $e');
    }
  }

  //Statistique & Gestion des stocks
  Future<Map<String, dynamic>> getStatistiques() async {
    final response = await http.get(
      Uri.parse('$baseUrl/statistiques'),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body)['error'] ?? 'Erreur inconnue';
      throw Exception('Impossible de charger les statistiques: $error');
    }
  }
}