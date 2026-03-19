# Déploiement sur Railway (Laravel 10 + PHP 8.2 + Nginx)

## Vue d’ensemble
- Image multi-étapes avec PHP-FPM 8.2, Nginx, Composer, (optionnel) build front Laravel Mix.
- Nginx écoute sur le port 8080 (convention Railway). PHP-FPM écoute sur 9000.
- Racine du site : `/app` (index.php à la racine du projet) ; assets dans `/public`.

## Fichiers ajoutés
- `Dockerfile` : build multi-étapes (composer, assets optionnels, runtime PHP-FPM+Nginx).
- `deploy/nginx.conf` : config globale Nginx.
- `deploy/default.conf` : vhost Nginx pour Railway (port 8080).
- `deploy/entrypoint.sh` : lance PHP-FPM puis Nginx.
- `Procfile` : commande web alternative (Railway auto détecte aussi Dockerfile).

## Variables d’environnement minimales
- `APP_KEY` : générer avant le déploiement (php artisan key:generate --show).
- `APP_ENV=production`
- `APP_DEBUG=false`
- `APP_URL=https://<votre-domaine-railway>`
- Base de données (exemple MySQL Railway) :
  - `DB_CONNECTION=mysql`
  - `DB_HOST=<railway-host>`
  - `DB_PORT=<railway-port>`
  - `DB_DATABASE=<railway-db>`
  - `DB_USERNAME=<railway-user>`
  - `DB_PASSWORD=<railway-password>`
- `LOG_CHANNEL=stderr` (déjà défini dans Dockerfile via ENV).

## Build & assets
- Le Dockerfile accepte `--build-arg BUILD_ASSETS=true` pour compiler le front (Laravel Mix / webpack). Si omis, il crée des dossiers vides `public/js` et `public/css`.
- Si vous avez besoin du thème compilé, utiliser `BUILD_ASSETS=true` et fournir `yarn.lock` ou npm selon le projet.

## Commandes Railway (exemple)
### Déploiement avec Dockerfile (recommandé)
Railway détecte le Dockerfile et build :
- Build : `docker build -t app .` (Railway le fera automatiquement)
- Run : expose 8080 et exécute `/entrypoint.sh` (CMD)

### Déploiement avec Procfile (optionnel)
- Railway peut utiliser `Procfile` : `web: php-fpm -D && nginx -g 'daemon off;'`
- Assurez-vous que `nginx.conf` et `default.conf` sont présents.

## Étapes après déploiement
1) `php artisan migrate --force`
2) `php artisan storage:link` (si nécessaire pour les uploads)
3) Vérifier les permissions : le conteneur applique `chown www-data` sur `storage` et `bootstrap/cache` au démarrage.

## Notes
- Le projet utilise `index.php` à la racine (pas dans public). La config Nginx `root /app;` et `try_files ... /index.php` le prend en compte.
- Les assets statiques servis depuis `/public` restent accessibles via `/assets`, `/public`, `/storage` (dossiers inclus dans `location`).
- Pour forcer HTTPS côté app, basculer `FORCE_HTTPS=On` dans l’ENV si supporté par la config applicative.
