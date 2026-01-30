# 🚀 Guide d'Installation & Workflow Git (Projet Centralisé)

Ce projet fonctionne comme un **"Monorepo"** utilisant des **Git Submodules**. Cela signifie que le dossier principal contient des références vers d'autres dépôts (`PlatformModule`, `PlayerModule`, etc.).

**⚠️ À lire absolument pour éviter les dossiers vides ou les conflits !**

## 1. Récupérer le projet (Clone)

Il y a deux façons de faire, selon si vous avez déjà cloné ou non.

### Cas A : Vous n'avez pas encore récupéré le projet

Utilisez cette commande magique qui télécharge le projet ET les sous-modules d'un coup :

```bash
git clone --recurse-submodules git@github.com:PolyNeige/FullProject.git

```

### Cas B : Vous avez déjà cloné (et les dossiers modules sont vides)

Si vous avez des dossiers vides (`PlatformModule`, `AvroRepo`...), lancez ceci à la racine du projet :

```bash
git submodule update --init --recursive

```

---

## 2. Configuration Authentification (Indispensable)

GitHub refuse désormais les mots de passe en ligne de commande. Vous devez configurer **SSH** (recommandé) ou un **Token**.

**Si vous avez une erreur `Permission denied (publickey)` :**

1. Générez une clé SSH sur votre PC :
```bash
ssh-keygen -t ed25519 -C "votre_email@etudiant.fr"
# Appuyez sur Entrée jusqu'à la fin

```


2. Affichez votre clé publique :
```bash
cat ~/.ssh/id_ed25519.pub

```


3. Copiez tout le texte affiché.
4. Allez sur GitHub : **Settings > SSH and GPG keys > New SSH key** et collez la clé.

---

## 3. Workflow de développement (La Règle d'Or)

Travailler avec des sous-modules demande une discipline stricte pour ne pas perdre de code.

### 🛑 Le piège du "Detached HEAD"

Par défaut, git place les sous-modules sur un commit précis, pas sur une branche.
**AVANT de modifier du code dans un module (ex: `PlatformModule`) :**

1. Allez dans le dossier du module.
2. Assurez-vous d'être sur la branche `main` (ou `master`).
* **Via Terminal :** `cd PlatformModule && git checkout main && git pull`
* **Via IntelliJ :** Widget Git en bas à droite > Sélectionnez le module > `main` > `Checkout`.



### 🔄 L'ordre de Push (Très important)

Si vous avez modifié du code dans un module, vous devez **toujours push le module AVANT de push le projet parent**.

1. **Commit & Push dans le module** (ex: `PlatformModule`).
2. Revenez à la racine (Projet Parent).
3. Vous verrez que le module est marqué comme "modifié" (mise à jour du pointeur).
4. **Commit & Push le projet parent**.

> **Astuce IntelliJ :** Utilisez `Ctrl + K` (Commit) et `Ctrl + Shift + K` (Push). IntelliJ détectera les modules et vous avertira si vous essayez de push le parent alors que le module a des commits en attente.

---

## 4. Configuration IntelliJ IDEA

Si IntelliJ vous affiche une erreur *"The following directories are registered as VCS roots, but they are not"*, ou s'il ne détecte pas les modules :

1. Allez dans **Settings > Version Control > Directory Mappings**.
2. Supprimez les lignes rouges (les sous-modules).
3. Gardez uniquement la ligne `<Project>` pointant vers le dossier racine.
4. Faites **Apply**. IntelliJ détectera automatiquement le reste grâce au fichier `.gitmodules`.

---

## 🐳 Lancement du projet

Le projet est composé de 3 modules qui sont lancés indépendamment et liés avec Kafka sur Docker.

Pour lancer le projet, allez dans le répertoire du projet (`/FullProject`).

Tout d'abord, utilisez `mvn clean generate-sources` afin de générer les classes liées aux fichiers Avro.

Exécutez ensuite le script shell nommé start_demo.sh (`./start_demo.sh`)

Normalement, ce script se charge de lancer le docker et les différents modules et d'ouvrir un terminal par module pour que l'utilisateur puisse utiliser l'application.

Le lancement et l'initialisation du projet la première fois est très long (cela peut durer environ 10 minutes), et c'est normal, car il doit télécharger les dépendances pour chaque module.

De plus, le lancement classique (sans initialisation des librairies, après la première fois) peut aussi prendre environ une minute à cause de l'initialisation du Kafka.

Faites attention cependant à bien vider votre docker avant d'exécuter cette fonction, car cela ne marchera pas si vous utilisez déjà les ports que nous utilisons.

Nous avons également rencontré des problèmes de terminaux qui crashent à l'ouverture. Nous n'avons pas de solution définitive à ce problème, mais si cela arrive, nous vous suggère tout d'abord d'essayer de relancer le script,
et si cela ne fonctionne toujours pas, faites `docker compose down -v`, cela nettoiera la base de donnée, mais le retour à 0 règle parfois le problème des terminaux.

Si vous récupérez le projet via github, faites attention à bien être situé sur les bonnes branches. Les branches les plus à jour sont les branches main ou master de chaque module. La branche sur laquelle le projet récupère les données est modifiable sur intelliJ depuis l'onglet git.


---

### En résumé

1. `git submodule update --init --recursive` pour réparer les dossiers vides.
2. Toujours se mettre sur `main` dans un module avant de coder.
3. Toujours **Push le module** avant de **Push le parent**.