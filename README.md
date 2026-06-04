# Buckshot

Application Flutter de gestion d'evenements et de "shotguns" avec reservation de places, billets QR code, scan staff, favoris et gestion d'organisations.

Buckshot s'appuie sur Firebase pour l'authentification et les donnees temps reel. L'application cible principalement un usage mobile, avec une configuration Flutter multi-plateforme presente dans le depot.

## Installation de l'application

La version distribuee de l'application est disponible via Firebase App Distribution:

[Installer Buckshot](https://appdistribution.firebase.dev/i/5a10199e4ef6dc21)

Selon la configuration du terminal, Firebase App Distribution peut demander une authentification ou une invitation de testeur avant de permettre le telechargement.

## Fonctionnalites principales

- Creation de compte et connexion par email/mot de passe.
- Reinitialisation de mot de passe via Firebase Auth.
- Accueil avec evenements a venir, inscriptions utilisateur, nouveautes et favoris.
- Recherche d'evenements par nom avec onglets `A Venir`, `En Cours`, `Passes`.
- Reservation et desinscription d'un evenement via transaction Firestore.
- Generation d'un billet avec QR code.
- Scan staff des billets avec detection des billets invalides, deja scannes ou associes a un autre evenement.
- Favoris/rappels d'ouverture de billetterie avec notification locale programmee.
- Profil utilisateur avec modification du nom/prenom, changement de mot de passe et suppression de compte.
- Demande pour rejoindre une organisation en tant que `STAFF` ou `ORGANISATEUR`.
- Gestion des demandes d'acces et des membres staff pour les organisateurs.
- Creation d'evenements pour les utilisateurs rattaches a une organisation avec role privilegie.

## Stack technique

| Domaine | Technologie |
|---|---|
| Application | Flutter, Dart |
| UI | Material 3, theme sombre Buckshot, Google Fonts Jura |
| Authentification | Firebase Auth |
| Base de donnees | Cloud Firestore |
| Notifications | `flutter_local_notifications`, `timezone` |
| QR code | `qr_flutter`, `mobile_scanner` |
| Images | `image_picker`, `image` |
| Markdown | `flutter_markdown_plus` |
| Localisation date | `intl` avec formatage `fr_FR` |

## Prerequis developpement

- Flutter compatible avec Dart SDK `^3.11.4`.
- Un environnement Android Studio ou Xcode selon la cible.
- Acces au projet Firebase `buckshot-a9242` ou a une configuration Firebase equivalente.
- Firebase CLI et FlutterFire CLI si la configuration Firebase doit etre regeneree.

Verifier l'environnement:

```bash
flutter doctor
flutter pub get
```

## Demarrage local

Installer les dependances:

```bash
flutter pub get
```

Lancer l'application:

```bash
flutter run
```

Lancer sur une cible precise:

```bash
flutter run -d chrome
flutter run -d android
flutter run -d windows
```

Le fichier `lib/firebase_options.dart` contient les options Firebase generees par FlutterFire pour Web, Android, iOS, macOS et Windows. Linux n'est pas configure: l'application intercepte l'erreur d'initialisation Firebase et affiche un ecran de mode hors-ligne.

## Build

Android APK:

```bash
flutter build apk --release
```

Android App Bundle:

```bash
flutter build appbundle --release
```

Web:

```bash
flutter build web --release
```

Windows:

```bash
flutter build windows --release
```

## Structure du projet

```text
lib/
  main.dart                  # Initialisation Flutter, Firebase, notifications et routage auth
  firebase_options.dart       # Configuration Firebase generee
  buckshot_theme.dart         # Theme sombre global
  models/                    # Modeles Firestore et enums metier
  services/                  # Auth, users, events, scanner, notifications, seed
  views/                     # Ecrans applicatifs
  widgets/                   # Composants UI reutilisables
assets/
  markdown/                  # Documents Markdown juridiques
  *.png                      # Logos, splash, fallback evenement
docs/
  architecture_technique.md   # Documentation technique detaillee
```

## Architecture applicative

Le projet suit une architecture Flutter pragmatique:

- `main.dart` initialise Firebase, les notifications et choisit entre `LoginView` et `HomeView` selon `FirebaseAuth.authStateChanges()`.
- Les vues gerent l'etat local avec `StatefulWidget`, `TextEditingController`, `TabController` et `setState`.
- Les donnees temps reel sont principalement consommees avec `StreamBuilder`.
- Les services centralisent une partie des acces Firebase: `AuthService`, `UserService`, `EventService`, `ScannerService`, `NotificationService`.
- Plusieurs vues contiennent encore de la logique Firestore directe, notamment `EventDetailView`, `ProfileView`, `CreateEventView`, `MyTicketsView` et `StaffView`.

Documentation complete: [docs/architecture_technique.md](docs/architecture_technique.md)

## Collections Firestore principales

| Collection | Role |
|---|---|
| `users` | Profils applicatifs lies aux comptes Firebase Auth. |
| `events` | Evenements, capacite, dates de billetterie, image Base64. |
| `billets` | Billets reserves; l'id du document est encode dans le QR code. |
| `reminders` | Favoris et rappels d'ouverture de billetterie. |
| `organizers` | Organisations auxquelles les utilisateurs privilegies sont rattaches. |
| `demandes_organisation` | Demandes pour rejoindre une organisation. |
| `tickets` | Ancien flux de validation conserve dans `DatabaseService` et `seed_database.dart`. |

Le flux actif de scan utilise `billets`, pas `tickets`.

## Roles applicatifs

Les roles sont stockes dans `users/{uid}.role` sous forme de chaines:

| Role | Acces |
|---|---|
| `USER` | Reservation, favoris, billets, profil. |
| `STAFF` | Acces utilisateur + scanner + evenements de son organisation + creation d'evenement. |
| `ORGANISATEUR` | Acces staff + gestion des demandes d'organisation + gestion des staffs. |

L'interface masque ou affiche certaines sections selon le role, mais les permissions doivent etre garanties par les regles Firestore.

## Commandes utiles

Analyser le code:

```bash
flutter analyze
```

Lancer les tests:

```bash
flutter test
```

Regenerer les icones d'application:

```bash
dart run flutter_launcher_icons
```

Regenerer le splash screen:

```bash
dart run flutter_native_splash:create
```

## Configuration Firebase

Le projet utilise actuellement:

- Firebase Auth pour les comptes email/mot de passe.
- Cloud Firestore pour les donnees metier.
- Firebase App Distribution pour la distribution de test.

Si le projet Firebase est remplace ou si une nouvelle application cible est ajoutee, regenerer `lib/firebase_options.dart` avec FlutterFire CLI:

```bash
flutterfire configure
```

Les fichiers natifs Firebase presents dans le depot incluent notamment:

- `android/app/google-services.json`
- `lib/firebase_options.dart`

## Donnees de test

Le fichier `lib/services/seed_database.dart` contient une fonction `seedFirebaseDatabase()` qui insere:

- un utilisateur de test;
- une organisation;
- un evenement;
- un ticket dans l'ancien schema `tickets`.

Cette fonction n'est pas appelee dans `main.dart`. Elle doit etre utilisee avec prudence, car son schema ticket ne correspond pas au flux QR actuel base sur `billets`.

## Points d'attention connus

- `lib/models/utilisateur_model.dart` declare une classe nommee `EventModel` alors qu'elle represente un utilisateur.
- Les roles du modele Dart ne sont pas alignes avec les chaines Firestore `USER`, `STAFF`, `ORGANISATEUR`.
- Deux schemas de billets coexistent: `billets` pour le flux actuel et `tickets` pour un ancien service.
- `EventModel.fromFirestore` lit `dateFermetureBilletterie` depuis `dateFinEvent`.
- `FavoritesView` lit `imageUrl`, alors que les evenements utilisent surtout `image` en Base64.
- La suppression de compte nettoie `users` et `demandes_organisation`, mais pas les billets, favoris ou evenements associes.

Ces points sont detailles dans la documentation technique.

## Contribution

Avant d'ajouter une fonctionnalite:

1. Identifier si elle concerne une vue, un widget reutilisable, un modele ou un service.
2. Ajouter les champs Firestore necessaires dans un modele dedie lorsque possible.
3. Centraliser les nouvelles requetes dans un service plutot que dans une vue si la logique est reutilisable.
4. Proteger toute action privilegiee par les regles Firestore, pas uniquement par l'interface.
5. Verifier les flux `USER`, `STAFF` et `ORGANISATEUR`.
6. Executer `flutter analyze` et `flutter test` avant merge.

## Documentation

- [Documentation technique exhaustive](docs/architecture_technique.md)

## Licence et diffusion

Le projet est marque `publish_to: 'none'` dans `pubspec.yaml`, ce qui indique une application privee non destinee a une publication sur pub.dev.

La distribution de test est geree via Firebase App Distribution:

[https://appdistribution.firebase.dev/i/5a10199e4ef6dc21](https://appdistribution.firebase.dev/i/5a10199e4ef6dc21)
