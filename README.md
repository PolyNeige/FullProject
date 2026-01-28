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

*(Note pour Linux/KDE : Si vous avez une erreur `ksshaskpass`, faites `unset SSH_ASKPASS` dans le terminal).*

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

## 🐳 Lancement de l'Infrastructure
Pour démarrer Kafka et les Bases de Données :
1. `docker compose up -d` (Lancement) (-d optionnel, fait tourner tout en arrière plan)
2. `docker compose ps` (Vérification)
3. `docker compose down` (Arrêt)

---

### En résumé

1. `git submodule update --init --recursive` pour réparer les dossiers vides.
2. Toujours se mettre sur `main` dans un module avant de coder.
3. Toujours **Push le module** avant de **Push le parent**.