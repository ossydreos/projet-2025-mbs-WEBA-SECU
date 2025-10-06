#!/bin/bash

# Script pour lancer l'app iOS avec Xcode
# Utilise le bon chemin pour Xcode

export DEVELOPER_DIR="/Applications/Programmation/Xcode.app/Contents/Developer"

echo "🔧 Configuration de Xcode..."
echo "📱 Lancement de l'app iOS..."

# Nettoyer et reconstruire si nécessaire
if [ "$1" = "--clean" ]; then
    echo "🧹 Nettoyage du projet..."
    flutter clean
    flutter pub get
    cd ios
    pod install
    cd ..
fi

# Ouvrir le projet dans Xcode
echo "🚀 Ouverture dans Xcode..."
open ios/Runner.xcworkspace

echo "✅ Projet ouvert dans Xcode !"
echo "📋 Instructions :"
echo "   1. Sélectionnez votre iPhone dans la liste des appareils"
echo "   2. Cliquez sur le bouton ▶️ pour lancer l'app"
echo "   3. Si c'est la première fois, acceptez les certificats de développement"
