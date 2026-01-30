#!/bin/bash

# --- CONFIGURATION ---
PLAYER_CONTAINER="player-app"
PLATFORM_CONTAINER="platform-app"
EDITOR_CONTAINER="editor-app"

# --- 1. GÉNÉRATEUR DE COMMANDE ROBUSTE ---
# Cette fonction crée la chaîne de commande "Infinie" pour éviter que la fenêtre ne ferme
get_robust_command() {
    local title="$1"
    local container="$2"

    # On retourne une chaîne BASH complexe qui sera exécutée dans le nouveau terminal
    echo "echo -e '\033[1;34m=== $title ===\033[0m'; \
    while true; do \
        docker attach $container; \
        echo -e '\033[1;31m⚠️ Déconnecté (ou conteneur pas prêt). Reconnexion dans 3s...\033[0m'; \
        sleep 3; \
    done; \
    read -p 'Appuyez sur Entrée pour fermer...'"
}

# --- 2. FONCTION D'OUVERTURE DE TERMINAL ---
open_terminal() {
    local title="$1"
    local command="$2"

    # A. WINDOWS
    if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" || -n "$WSL_DISTRO_NAME" ]]; then
        cmd.exe /c start "$title" cmd /k "$command"
        return
    fi

    # B. MACOS
    if [[ "$OSTYPE" == "darwin"* ]]; then
        osascript -e "tell application \"Terminal\" to do script \"$command\""
        return
    fi

    # C. LINUX
    # On enlève 'setsid' qui casse le lien avec Wayland sur Bazzite
    local terms=("ptyxis" "kgx" "gnome-console" "gnome-terminal" "konsole" "xfce4-terminal" "xterm" "flatpak run org.gnome.Terminal")

    if [ -n "$USER_CHOSEN_TERM" ]; then
        terms=("$USER_CHOSEN_TERM")
    fi

    for t in "${terms[@]}"; do
        check_cmd=$(echo "$t" | awk '{print $1}')

        if command -v "$check_cmd" &> /dev/null; then

            # --- CORRECTION MAJEURE ICI ---
            # 1. On utilise 'nohup' pour que le terminal survive à la fin du script
            # 2. On redirige tout vers /dev/null
            # 3. On met '&' pour le background
            # 4. On ajoute 'disown' pour détacher proprement le process du shell actuel

            case "$t" in
                gnome-terminal|mate-terminal|tilix|"flatpak run org.gnome.Terminal")
                    nohup "$t" --title="$title" -- bash -c "$command" < /dev/null > /dev/null 2>&1 & disown
                    ;;
                ptyxis)
                    # Ptyxis a besoin de --new-window explicitement pour ne pas bugger en multi-launch
                    nohup "$t" --new-window --title "$title" -- bash -c "$command" < /dev/null > /dev/null 2>&1 & disown
                    ;;
                kgx|console|gnome-console|"flatpak run org.gnome.Console")
                    nohup "$t" -- bash -c "$command" < /dev/null > /dev/null 2>&1 & disown
                    ;;
                konsole)
                    nohup "$t" -e bash -c "$command" < /dev/null > /dev/null 2>&1 & disown
                    ;;
                *)
                    nohup "$t" -e "$command" < /dev/null > /dev/null 2>&1 & disown
                    ;;
            esac
            
            USER_CHOSEN_TERM="$check_cmd"
            return
        fi
    done

    echo "⚠️ Echec lancement terminal pour $title"
}

# --- DÉBUT DU SCRIPT ---
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
echo "[2/3] Waiting for apps..."
# On attend un peu que Kafka/Postgres soient chauds
sleep 5

# 3. Launch Terminals
echo ""
echo "[3/3] Opening Windows..."

# On construit la commande robuste pour chaque module
CMD_PLAYER=$(get_robust_command "PLAYER (CLIENT)" "$PLAYER_CONTAINER")
CMD_PLATFORM=$(get_robust_command "PLATFORM (ADMIN)" "$PLATFORM_CONTAINER")
CMD_EDITOR=$(get_robust_command "EDITOR (PUBLISHER)" "$EDITOR_CONTAINER")

# On lance !
open_terminal "PLAYER" "$CMD_PLAYER"
sleep 1

open_terminal "PLATFORM" "$CMD_PLATFORM"
sleep 1

open_terminal "EDITOR" "$CMD_EDITOR"

echo "✅ Done."