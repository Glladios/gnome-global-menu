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
    <signal name="ItemsPropertiesUpdated">
      <arg type="a(ia{sv})" name="updatedProps"/>
      <arg type="a(ias)" name="removedProps"/>
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
        
        // Monitora mudanças de janela ativa
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
        
        // Atualiza o label com o nome do app
        this._appLabel.text = app.get_name();
        
        // Tenta conectar ao menu DBus do aplicativo
        this._connectToAppMenu(window);
    }
    
    _connectToAppMenu(window) {
        try {
            const xid = window.get_id();
            
            // Busca o menu no DBus
            Gio.DBus.session.call(
                'org.freedesktop.DBus',
                '/org/freedesktop/DBus',
                'org.freedesktop.DBus',
                'ListNames',
                null,
                null,
                Gio.DBusCallFlags.NONE,
                -1,
                null,
                (connection, result) => {
                    try {
                        const reply = connection.call_finish(result);
                        const names = reply.deep_unpack()[0];
                        
                        // Procura por nomes de menu relacionados à janela
                        for (let name of names) {
                            if (name.includes('menu') || name.includes('appmenu')) {
                                this._tryConnectProxy(name, xid);
                            }
                        }
                    } catch (e) {
                        log(`Erro ao listar nomes DBus: ${e}`);
                    }
                }
            );
        } catch (e) {
            log(`Erro ao conectar ao menu: ${e}`);
        }
    }
    
    _tryConnectProxy(busName, windowId) {
        try {
            const objectPath = `/com/canonical/menu/${windowId}`;
            
            new DBusMenuProxy(
                Gio.DBus.session,
                busName,
                objectPath,
                (proxy, error) => {
                    if (error) {
                        return;
                    }
                    
                    this._menuProxy = proxy;
                    this._loadMenuItems();
                    
                    // Monitora atualizações do menu
                    this._menuProxy.connectSignal(
                        'LayoutUpdated',
                        this._onMenuLayoutUpdated.bind(this)
                    );
                }
            );
        } catch (e) {
            // Menu não disponível para este aplicativo
        }
    }
    
    _loadMenuItems() {
        if (!this._menuProxy) {
            return;
        }
        
        try {
            this._menuProxy.GetLayoutRemote(0, -1, [], (result, error) => {
                if (error) {
                    log(`Erro ao obter layout: ${error}`);
                    return;
                }
                
                const [revision, layout] = result;
                this._buildMenuFromLayout(layout);
            });
        } catch (e) {
            log(`Erro ao carregar items: ${e}`);
        }
    }
    
    _buildMenuFromLayout(layout) {
        this.menu.removeAll();
        
        if (!layout || layout.length < 3) {
            return;
        }
        
        const [id, props, children] = layout;
        
        if (!children || children.length === 0) {
            return;
        }
        
        // Constrói os items do menu
        for (let child of children) {
            this._addMenuItem(child);
        }
    }
    
    _addMenuItem(itemData) {
        if (!itemData || itemData.length < 2) {
            return;
        }
        
        const [id, props] = itemData;
        const properties = props || {};
        
        // Extrai propriedades
        const label = this._getProperty(properties, 'label');
        const type = this._getProperty(properties, 'type');
        const enabled = this._getProperty(properties, 'enabled') !== false;
        const visible = this._getProperty(properties, 'visible') !== false;
        
        if (!visible) {
            return;
        }
        
        if (type === 'separator') {
            this.menu.addMenuItem(new PopupMenu.PopupSeparatorMenuItem());
            return;
        }
        
        if (!label) {
            return;
        }
        
        const menuItem = new PopupMenu.PopupMenuItem(label);
        menuItem.setSensitive(enabled);
        
        // Conecta o evento de clique
        menuItem.connect('activate', () => {
            this._activateMenuItem(id);
        });
        
        this.menu.addMenuItem(menuItem);
        
        // Adiciona subitems se existirem
        if (itemData.length > 2 && itemData[2] && itemData[2].length > 0) {
            const subMenu = new PopupMenu.PopupSubMenuMenuItem(label);
            subMenu.setSensitive(enabled);
            
            for (let subItem of itemData[2]) {
                this._addSubMenuItem(subMenu.menu, subItem);
            }
            
            this.menu.addMenuItem(subMenu);
        }
    }
    
    _addSubMenuItem(parentMenu, itemData) {
        if (!itemData || itemData.length < 2) {
            return;
        }
        
        const [id, props] = itemData;
        const properties = props || {};
        
        const label = this._getProperty(properties, 'label');
        const enabled = this._getProperty(properties, 'enabled') !== false;
        const visible = this._getProperty(properties, 'visible') !== false;
        
        if (!visible || !label) {
            return;
        }
        
        const menuItem = new PopupMenu.PopupMenuItem(label);
        menuItem.setSensitive(enabled);
        
        menuItem.connect('activate', () => {
            this._activateMenuItem(id);
        });
        
        parentMenu.addMenuItem(menuItem);
    }
    
    _getProperty(props, name) {
        if (!props || !props[name]) {
            return null;
        }
        return props[name].deep_unpack();
    }
    
    _activateMenuItem(itemId) {
        if (!this._menuProxy) {
            return;
        }
        
        try {
            this._menuProxy.EventRemote(
                itemId,
                'clicked',
                new GLib.Variant('i', 0),
                GLib.get_monotonic_time() / 1000
            );
        } catch (e) {
            log(`Erro ao ativar item: ${e}`);
        }
    }
    
    _onMenuLayoutUpdated() {
        this._loadMenuItems();
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
        
        // Adiciona à esquerda do AppMenu (ou onde estava o AppMenu)
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
