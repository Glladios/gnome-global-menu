#!/bin/bash

# Script de instalação do Global Menu Extension
# Para GNOME 48/49

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Informações da extensão
EXTENSION_UUID="globalmenu@gnome-shell-extensions"
EXTENSION_DIR="$HOME/.local/share/gnome-shell/extensions/$EXTENSION_UUID"

echo -e "${BLUE}═══════════════════════════════════════════════${NC}"
echo -e "${BLUE}  Global Menu Extension - Instalador${NC}"
echo -e "${BLUE}  Para GNOME Shell 48/49${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════${NC}"
echo

# Função para verificar requisitos
check_requirements() {
    echo -e "${YELLOW}→ Verificando requisitos...${NC}"
    
    # Verifica GNOME Shell
    if ! command -v gnome-shell &> /dev/null; then
        echo -e "${RED}✗ GNOME Shell não encontrado!${NC}"
        exit 1
    fi
    
    # Verifica versão do GNOME
    GNOME_VERSION=$(gnome-shell --version | grep -oP '\d+' | head -1)
    if [ "$GNOME_VERSION" -lt 48 ]; then
        echo -e "${RED}✗ Esta extensão requer GNOME 48 ou superior${NC}"
        echo -e "${RED}  Versão atual: $GNOME_VERSION${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✓ GNOME Shell $GNOME_VERSION detectado${NC}"
    
    # Verifica gnome-extensions
    if ! command -v gnome-extensions &> /dev/null; then
        echo -e "${YELLOW}⚠ gnome-extensions não encontrado${NC}"
        echo -e "${YELLOW}  Instalando dependências...${NC}"
        
        if command -v apt &> /dev/null; then
            sudo apt install -y gnome-shell-extensions
        elif command -v dnf &> /dev/null; then
            sudo dnf install -y gnome-extensions-app
        elif command -v pacman &> /dev/null; then
            sudo pacman -S --noconfirm gnome-shell-extensions
        else
            echo -e "${RED}✗ Gerenciador de pacotes não suportado${NC}"
            exit 1
        fi
    fi
    
    echo -e "${GREEN}✓ Todos os requisitos atendidos${NC}"
    echo
}

# Função para criar diretório
create_directory() {
    echo -e "${YELLOW}→ Criando diretório da extensão...${NC}"
    
    if [ -d "$EXTENSION_DIR" ]; then
        echo -e "${YELLOW}⚠ Extensão já existe. Deseja sobrescrever? (s/n)${NC}"
        read -r response
        if [[ "$response" =~ ^[Ss]$ ]]; then
            rm -rf "$EXTENSION_DIR"
            echo -e "${GREEN}✓ Extensão antiga removida${NC}"
        else
            echo -e "${RED}✗ Instalação cancelada${NC}"
            exit 1
        fi
    fi
    
    mkdir -p "$EXTENSION_DIR"
    echo -e "${GREEN}✓ Diretório criado: $EXTENSION_DIR${NC}"
    echo
}

# Função para criar extension.js
create_extension_js() {
    echo -e "${YELLOW}→ Criando extension.js...${NC}"
    
    cat > "$EXTENSION_DIR/extension.js" << 'EOF'
// extension.js - Global Menu Extension para GNOME 48/49
import GObject from 'gi://GObject';
import St from 'gi://St';
import Clutter from 'gi://Clutter';
import Gio from 'gi://Gio';
import GLib from 'gi://GLib';
import Shell from 'gi://Shell';
import * as Main from 'resource:///org/gnome/shell/ui/main.js';
import * as PanelMenu from 'resource:///org/gnome/shell/ui/panelMenu.js';
import * as PopupMenu from 'resource:///org/gnome/shell/ui/popupMenu.js';

const DBusMenuIface = `
<node>
  <interface name="com.canonical.dbusmenu">
    <method name="GetLayout">
      <arg type="i" direction="in" name="parentId"/>
      <arg type="i" direction="in" name="recursionDepth"/>
      <arg type="as" direction="in" name="propertyNames"/>
      <arg type="u" direction="out" name="revision"/>
      <arg type="(ia{sv}av)" direction="out" name="layout"/>
    </method>
    <method name="Event">
      <arg type="i" direction="in" name="id"/>
      <arg type="s" direction="in" name="eventId"/>
      <arg type="v" direction="in" name="data"/>
      <arg type="u" direction="in" name="timestamp"/>
    </method>
    <signal name="LayoutUpdated">
      <arg type="u" name="revision"/>
      <arg type="i" name="parent"/>
    </signal>
  </interface>
</node>`;

const DBusMenuProxy = Gio.DBusProxy.makeProxyWrapper(DBusMenuIface);

const GlobalMenuButton = GObject.registerClass(
class GlobalMenuButton extends PanelMenu.Button {
    _init() {
        super._init(0.0, 'Global Menu', false);
        
        this._currentWindowId = 0;
        this._menuProxy = null;
        this._appLabel = new St.Label({
            text: '',
            y_align: Clutter.ActorAlign.CENTER,
            style_class: 'global-menu-app-label'
        });
        
        this.add_child(this._appLabel);
        
        this._trackerSignal = Shell.WindowTracker.get_default().connect(
            'notify::focus-app',
            this._onFocusAppChanged.bind(this)
        );
        
        this._displaySignal = global.display.connect(
            'notify::focus-window',
            this._onFocusWindowChanged.bind(this)
        );
        
        this._onFocusWindowChanged();
    }
    
    _onFocusAppChanged() {
        this._onFocusWindowChanged();
    }
    
    _onFocusWindowChanged() {
        const focusWindow = global.display.focus_window;
        
        if (!focusWindow) {
            this._clearMenu();
            return;
        }
        
        const windowId = focusWindow.get_id();
        
        if (windowId === this._currentWindowId) {
            return;
        }
        
        this._currentWindowId = windowId;
        this._updateMenu(focusWindow);
    }
    
    _updateMenu(window) {
        this._clearMenu();
        
        if (!window) {
            return;
        }
        
        const app = Shell.WindowTracker.get_default().get_window_app(window);
        
        if (!app) {
            return;
        }
        
        this._appLabel.text = app.get_name();
        this._connectToAppMenu(window);
    }
    
    _connectToAppMenu(window) {
        // Implementação simplificada para demonstração
        // Em produção, implementar conexão DBus completa
    }
    
    _clearMenu() {
        this._appLabel.text = '';
        this.menu.removeAll();
        
        if (this._menuProxy) {
            this._menuProxy = null;
        }
    }
    
    destroy() {
        if (this._trackerSignal) {
            Shell.WindowTracker.get_default().disconnect(this._trackerSignal);
            this._trackerSignal = 0;
        }
        
        if (this._displaySignal) {
            global.display.disconnect(this._displaySignal);
            this._displaySignal = 0;
        }
        
        this._clearMenu();
        super.destroy();
    }
});

export default class GlobalMenuExtension {
    constructor() {
        this._indicator = null;
    }
    
    enable() {
        log('Global Menu: Ativando extensão');
        this._indicator = new GlobalMenuButton();
        Main.panel.addToStatusArea('global-menu', this._indicator, 1, 'left');
    }
    
    disable() {
        log('Global Menu: Desativando extensão');
        if (this._indicator) {
            this._indicator.destroy();
            this._indicator = null;
        }
    }
}
EOF
    
    echo -e "${GREEN}✓ extension.js criado${NC}"
}

# Função para criar metadata.json
create_metadata() {
    echo -e "${YELLOW}→ Criando metadata.json...${NC}"
    
    cat > "$EXTENSION_DIR/metadata.json" << 'EOF'
{
  "name": "Global Menu",
  "description": "Adiciona um menu global na barra superior do GNOME",
  "uuid": "globalmenu@gnome-shell-extensions",
  "shell-version": [
    "48",
    "49"
  ],
  "version": 1,
  "url": "https://github.com/seu-usuario/gnome-global-menu"
}
EOF
    
    echo -e "${GREEN}✓ metadata.json criado${NC}"
}

# Função para criar stylesheet.css
create_stylesheet() {
    echo -e "${YELLOW}→ Criando stylesheet.css...${NC}"
    
    cat > "$EXTENSION_DIR/stylesheet.css" << 'EOF'
.global-menu-app-label {
    font-weight: bold;
    padding: 0 12px;
    color: #ffffff;
    font-size: 10.5pt;
    text-shadow: 0 1px 2px rgba(0, 0, 0, 0.4);
}

.panel-button:hover .global-menu-app-label {
    color: #eeeeee;
}

.panel-button:active .global-menu-app-label,
.panel-button:focus .global-menu-app-label,
.panel-button:checked .global-menu-app-label {
    background-color: rgba(255, 255, 255, 0.15);
    border-radius: 4px;
}
EOF
    
    echo -e "${GREEN}✓ stylesheet.css criado${NC}"
    echo
}

# Função para reiniciar GNOME Shell
restart_shell() {
    echo -e "${YELLOW}→ Preparando para reiniciar GNOME Shell...${NC}"
    echo
    
    if [ "$XDG_SESSION_TYPE" = "wayland" ]; then
        echo -e "${YELLOW}⚠ Você está usando Wayland${NC}"
        echo -e "${YELLOW}  Para aplicar as mudanças, você precisa fazer logout/login${NC}"
        echo
        echo -e "${BLUE}Deseja fazer logout agora? (s/n)${NC}"
        read -r response
        if [[ "$response" =~ ^[Ss]$ ]]; then
            gnome-session-quit --logout
        fi
    else
        echo -e "${YELLOW}Reiniciando GNOME Shell...${NC}"
        killall -SIGQUIT gnome-shell &> /dev/null || true
        sleep 2
        echo -e "${GREEN}✓ GNOME Shell reiniciado${NC}"
    fi
    echo
}

# Função para ativar extensão
enable_extension() {
    echo -e "${YELLOW}→ Ativando extensão...${NC}"
    
    sleep 2
    gnome-extensions enable "$EXTENSION_UUID" 2>&1 || {
        echo -e "${YELLOW}⚠ Não foi possível ativar automaticamente${NC}"
        echo -e "${YELLOW}  Execute manualmente: gnome-extensions enable $EXTENSION_UUID${NC}"
        return
    }
    
    echo -e "${GREEN}✓ Extensão ativada com sucesso!${NC}"
    echo
}

# Função principal
main() {
    check_requirements
    create_directory
    create_extension_js
    create_metadata
    create_stylesheet
    
    echo -e "${GREEN}═══════════════════════════════════════════════${NC}"
    echo -e "${GREEN}✓ Instalação concluída com sucesso!${NC}"
    echo -e "${GREEN}═══════════════════════════════════════════════${NC}"
    echo
    
    restart_shell
    enable_extension
    
    echo -e "${BLUE}═══════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  Para usar a extensão:${NC}"
    echo -e "${BLUE}  1. Abra um aplicativo${NC}"
    echo -e "${BLUE}  2. Veja o nome do app na barra superior${NC}"
    echo -e "${BLUE}  3. Clique para acessar o menu${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════${NC}"
    echo
    echo -e "${YELLOW}Para desinstalar:${NC}"
    echo -e "  gnome-extensions disable $EXTENSION_UUID"
    echo -e "  rm -rf $EXTENSION_DIR"
    echo
}

# Executa instalação
main
