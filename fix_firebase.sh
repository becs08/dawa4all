#!/bin/bash
# Script pour résoudre l'erreur PigeonUserDetails

echo "Nettoyage du projet Flutter..."
flutter clean

echo "Suppression des fichiers de cache..."
rm -rf ~/.pub-cache/hosted/pub.dartlang.org/firebase_*
rm -rf build/
rm -rf .dart_tool/

echo "Récupération des dépendances..."
flutter pub get

echo "Nettoyage Android..."
cd android
./gradlew clean
cd ..

echo "Reconstruction du projet..."
flutter run

echo "Terminé!"