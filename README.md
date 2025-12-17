Global Menu Extension para GNOME 48/49
Uma extensão moderna para GNOME Shell que traz de volta o menu global na barra superior, exibindo os menus dos aplicativos ativos.

🌟 Recursos
Menu Global Integrado: Exibe o menu do aplicativo ativo na barra superior
Suporte DBus: Conecta-se aos menus via protocolo DBus Menu
Design Moderno: Segue as diretrizes de design do GNOME 48/49
Compatibilidade: Funciona com GNOME 48 e 49
Performance: Leve e eficiente, sem impacto no desempenho
📋 Pré-requisitos
GNOME Shell 48 ou 49
gnome-shell-extensions instalado
Aplicativos que suportam DBus Menu (a maioria dos apps GTK/Qt modernos)
🚀 Instalação
Método 1: Instalação Manual
Crie o diretório da extensão:
bash
mkdir -p ~/.local/share/gnome-shell/extensions/globalmenu@gnome-shell-extensions
Copie os arquivos:
bash
cd ~/.local/share/gnome-shell/extensions/globalmenu@gnome-shell-extensions

# Crie o arquivo extension.js (cole o código fornecido)
nano extension.js

# Crie o arquivo metadata.json (cole o conteúdo fornecido)
nano metadata.json

# Crie o arquivo stylesheet.css (cole os estilos fornecidos)
nano stylesheet.css
Reinicie o GNOME Shell:
No Xorg: Pressione Alt+F2, digite r, pressione Enter
No Wayland: Faça logout e login novamente
Ative a extensão:
bash
gnome-extensions enable globalmenu@gnome-shell-extensions
Método 2: Via GNOME Extensions App
Instale o GNOME Extensions (se ainda não tiver):
bash
sudo apt install gnome-shell-extension-prefs  # Ubuntu/Debian
sudo dnf install gnome-extensions-app         # Fedora
Abra o app "Extensões" e ative "Global Menu"
🎯 Como Usar
Automático: Assim que ativada, a extensão começa a funcionar automaticamente
Visualização: O nome do aplicativo ativo aparece na barra superior
Acesso ao Menu: Clique no nome do app para ver o menu
Interação: Navegue pelos menus como em qualquer menu nativo
🔧 Aplicativos Compatíveis
A extensão funciona melhor com aplicativos que implementam o protocolo DBus Menu:

✅ Totalmente Compatíveis
Aplicativos GNOME: Files (Nautilus), Text Editor, Terminal, etc.
Aplicativos GTK: LibreOffice, GIMP, Inkscape, Evolution
Aplicativos Qt: Telegram, VLC, Krita
Electron Apps: VS Code, Slack, Discord (com configurações específicas)
⚠️ Compatibilidade Parcial
Firefox: Requer configuração adicional via unity-menubar
Chrome/Chromium: Funciona com flag --enable-features=UseOzonePlatform
❌ Não Compatíveis
Aplicativos que não expõem menus via DBus
Alguns apps Flatpak (dependendo das permissões)
🐛 Solução de Problemas
Menu não aparece
bash
# Verifique se a extensão está ativa
gnome-extensions list --enabled

# Veja os logs
journalctl -f -o cat /usr/bin/gnome-shell

# Reinicie a extensão
gnome-extensions disable globalmenu@gnome-shell-extensions
gnome-extensions enable globalmenu@gnome-shell-extensions
Erro ao carregar
bash
# Verifique as permissões
chmod +x ~/.local/share/gnome-shell/extensions/globalmenu@gnome-shell-extensions/extension.js

# Valide os arquivos
gnome-extensions show globalmenu@gnome-shell-extensions
Menu vazio para alguns apps
Alguns aplicativos precisam de configuração adicional:

Para Firefox:

bash
# Instale o pacote unity-menubar
sudo apt install appmenu-gtk-module-common appmenu-gtk3-module
Para apps Flatpak:

bash
# Garanta permissões DBus
flatpak override --user --talk-name=org.kde.StatusNotifierItem com.exemplo.App
🎨 Personalização
Você pode modificar o stylesheet.css para personalizar a aparência:

css
/* Exemplo: Mudar cor do texto */
.global-menu-app-label {
    color: #ff6b6b;  /* Sua cor preferida */
    font-size: 11pt;  /* Tamanho da fonte */
}
📝 Desenvolvimento
Estrutura do Projeto
globalmenu@gnome-shell-extensions/
├── extension.js      # Código principal
├── metadata.json     # Metadados da extensão
├── stylesheet.css    # Estilos CSS
└── README.md         # Este arquivo
Modo Debug
Para ativar logs detalhados:

javascript
// No extension.js, mude:
log('Global Menu: ...');
// Para:
console.log('[Global Menu]', ...);
Contribuindo
Melhorias são bem-vindas! Algumas ideias:

 Suporte a ícones nos menus
 Cache de menus para performance
 Configurações via GNOME Settings
 Suporte a atalhos de teclado
 Integração com mais protocolos de menu
📄 Licença
GPL-3.0 - Veja o arquivo LICENSE para detalhes

🙏 Créditos
Baseado no antigo AppMenu do GNOME
Inspirado em extensões como TopIcons e AppIndicator
Protocolo DBus Menu da Canonical
📞 Suporte
Issues: Reporte bugs no GitHub
Discussões: Fórum GNOME Discourse
Email: seu-email@exemplo.com
🔄 Changelog
v1.0.0 (2025-12-17)
Lançamento inicial
Suporte para GNOME 48 e 49
Implementação básica do menu global
Suporte a submenus
Detecção automática de aplicativos
Nota: Esta extensão está em desenvolvimento ativo. Feedback e contribuições são muito bem-vindos!

