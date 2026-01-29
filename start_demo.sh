#!/bin/bash

# --- CONFIGURATION ---
PLAYER_CONTAINER="player-app"
PLATFORM_CONTAINER="platform-app"
EDITOR_CONTAINER="editor-app"

# --- FONCTION DE DETECTION INTELLIGENTE ---
open_terminal() {
    local title="$1"
    local command="$2"

    # 1. WINDOWS (Git Bash / WSL)
    if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" || -n "$WSL_DISTRO_NAME" ]]; then
        cmd.exe /c start "$title" cmd /k "$command"
        return
    fi

    # 2. MACOS
    if [[ "$OSTYPE" == "darwin"* ]]; then
        osascript -e "tell application \"Terminal\" to do script \"$command\""
        return
    fi

    # 3. LINUX (Liste de priorités)
    # On teste les commandes courantes sur Fedora/Bazzite/Ubuntu
    # "gnome-terminal" = Le classique
    # "kgx" = GNOME Console (souvent appelé juste "Terminal" dans les versions récentes)
    # "flatpak run..." = Si c'est installé via le centre logiciel
    local terms=("gnome-terminal" "kgx" "console" "ptyxis" "konsole" "xfce4-terminal" "xterm" "flatpak run org.gnome.Terminal" "flatpak run org.gnome.Console")

    # Si l'utilisateur a déjà donné une commande perso (voir fin de fonction), on l'utilise
    if [ -n "$USER_CHOSEN_TERM" ]; then
        terms=("$USER_CHOSEN_TERM")
    fi

    for t in "${terms[@]}"; do
        # Astuce pour vérifier si la commande existe (gère les espaces pour flatpak)
        check_cmd=$(echo "$t" | awk '{print $1}')

        if command -v "$check_cmd" &> /dev/null; then
            # On a trouvé un terminal compatible !
            case "$t" in
                gnome-terminal|mate-terminal|tilix|"flatpak run org.gnome.Terminal")
                    "$t" --title="$title" -- bash -c "$command" &
                    ;;
                kgx|console|"flatpak run org.gnome.Console")
                    # GNOME Console (kgx) est capricieux sur les arguments
                    "$t" -- bash -c "$command" &
                    ;;
                ptyxis)
                    "$t" --new-window -- bash -c "$command" &
                    ;;
                konsole)
                    "$t" -e bash -c "$command" &
                    ;;
                *)
                    # Tentative générique
                    "$t" -e "$command" &
                    ;;
            esac
            USER_CHOSEN_TERM="$check_cmd" # On mémorise pour les prochaines fenêtres
            return
        fi
    done

    # 4. ÉCHEC : ON DEMANDE A L'UTILISATEUR
    echo ""
    echo "[⚠️] Je ne trouve pas votre terminal automatiquement."
    echo "Quel est la commande pour lancer votre terminal ? (ex: gnome-terminal, kgx, alacritty...)"
    read -p "> " USER_INPUT

    if [ -n "$USER_INPUT" ]; then
        USER_CHOSEN_TERM="$USER_INPUT"
        # On relance la fonction avec la commande fournie par l'utilisateur
        open_terminal "$title" "$command"
        return
    else
        echo "[ERROR] Abandon. Veuillez lancer : $command"
    fi
}

# --- DÉBUT DU SCRIPT ---
# Nettoyage automatique des retours à la ligne Windows (CRLF)
sed -i 's/\r$//' "$0" 2>/dev/null

clear
echo "======================================================"
echo "      STEAM SIMULATION LAUNCHER"
echo "======================================================"

# 1. Cleanup and Start
echo ""
echo "[1/3] Restarting Infrastructure..."
docker compose down
docker compose up -d --build

if [ $? -ne 0 ]; then
    echo "[ERROR] Docker failed."
    exit 1
fi

# 2. Wait Loop
echo ""
echo "[2/3] Waiting for apps to be ready..."
until [ "$(docker inspect -f {{.State.Running}} $EDITOR_CONTAINER 2>/dev/null)" == "true" ]; do
    echo -n "."
    sleep 1
done

echo ""
echo "Apps are running. Waiting 5s for Java..."
sleep 5

# 3. Launch Terminals
echo ""
echo "[3/3] Opening Windows..."

# On lance les fenêtres avec un petit délai
open_terminal "PLAYER (CLIENT)" "docker attach $PLAYER_CONTAINER"
sleep 1
open_terminal "PLATFORM (ADMIN)" "docker attach $PLATFORM_CONTAINER"
sleep 1
open_terminal "EDITOR (PUBLISHER)" "docker attach $EDITOR_CONTAINER"

echo ""
echo "Done."