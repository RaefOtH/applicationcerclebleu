import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:ota_update/ota_update.dart';
import 'dart:io';

class UpdateService {
  /// Vérifie si une mise à jour est disponible et lance l'UI de téléchargement
  static Future<void> checkAndUpdate(BuildContext context) async {
    if (!Platform.isAndroid) return;
    
    try {
      // 1. Récupérer les données depuis Remote Config
      final remoteConfig = FirebaseRemoteConfig.instance;
      await remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(minutes: 1),
        minimumFetchInterval: const Duration(hours: 1),
      ));
      await remoteConfig.fetchAndActivate();

      final String latestVersion = remoteConfig.getString('latest_version'); // ex: "1.0.1"
      final String apkUrl = remoteConfig.getString('apk_url');               // URL directe de l'APK

      if (apkUrl.isEmpty) return;

      // 2. Récupérer la version actuelle installée
      final packageInfo = await PackageInfo.fromPlatform();
      final String currentVersion = packageInfo.version;                     // ex: "1.0.0"

      // 3. Comparer les versions (Si différentes, on lance la mise à jour)
      if (latestVersion != currentVersion) {
        if (context.mounted) {
          _startInAppUpdate(context, apkUrl);
        }
      }
    } catch (e) {
      debugPrint("Erreur lors de la vérification de la mise à jour: $e");
    }
  }

  /// Affiche la boîte de dialogue avec la progression du téléchargement OTA
  static void _startInAppUpdate(BuildContext context, String apkUrl) {
    showDialog(
      context: context,
      barrierDismissible: false, // Empêche de fermer la boîte en cliquant à côté
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            String progressStatus = "Préparation...";
            
            // Lancer le téléchargement et l'installation via OTA
            OtaUpdate().execute(
              apkUrl, 
              androidProviderAuthority: 'com.example.applicationstagepfe.provider' // /!\ À remplacer par votre package ID
            ).listen(
              (OtaEvent event) {
                setState(() {
                  switch (event.status) {
                    case OtaStatus.DOWNLOADING:
                      progressStatus = "Téléchargement : ${event.value}%";
                      break;
                    case OtaStatus.INSTALLING:
                      progressStatus = "Installation en cours...";
                      break;
                    case OtaStatus.INTERNAL_ERROR:
                    case OtaStatus.DOWNLOAD_ERROR:
                      progressStatus = "Erreur lors du téléchargement.";
                      break;
                    default:
                      break;
                  }
                });
              },
            );

            return AlertDialog(
              title: const Text("Mise à jour disponible"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 20),
                  Text(progressStatus),
                ],
              ),
            );
          },
        );
      },
    );
  }
}