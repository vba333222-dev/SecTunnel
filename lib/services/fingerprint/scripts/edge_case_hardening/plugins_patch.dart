class PluginsPatch {
  static String getJS() {
    return '''
      try {
        // Standard realistic plugin list for Chrome on Windows/Mac
        const fakePlugins = [
          {
            name: "Chrome PDF Plugin",
            filename: "internal-pdf-viewer",
            description: "Portable Document Format",
            mimeTypes: [{ type: "application/x-google-chrome-pdf", suffixes: "pdf", description: "Portable Document Format" }]
          },
          {
            name: "Chrome PDF Viewer",
            filename: "mhjfbmdgcfjbbpaeojofohoefgiehjai",
            description: "",
            mimeTypes: [{ type: "application/pdf", suffixes: "pdf", description: "" }]
          },
          {
            name: "Native Client",
            filename: "internal-nacl-plugin",
            description: "",
            mimeTypes: [{ type: "application/x-nacl", suffixes: "", description: "Native Client Executable" }, { type: "application/x-pnacl", suffixes: "", description: "Portable Native Client Executable" }]
          }
        ];

        function createFakePluginArray(pluginsData) {
          const arr = [];
          for (let i = 0; i < pluginsData.length; i++) {
            const p = pluginsData[i];
            const plugin = Object.create(Plugin.prototype);
            Object.defineProperty(plugin, 'name', { value: p.name, enumerable: true });
            Object.defineProperty(plugin, 'filename', { value: p.filename, enumerable: true });
            Object.defineProperty(plugin, 'description', { value: p.description, enumerable: true });
            Object.defineProperty(plugin, 'length', { value: p.mimeTypes.length, enumerable: true });
            for(let j = 0; j < p.mimeTypes.length; j++) {
              const mt = p.mimeTypes[j];
              const mimeType = Object.create(MimeType.prototype);
              Object.defineProperty(mimeType, 'type', { value: mt.type, enumerable: true });
              Object.defineProperty(mimeType, 'suffixes', { value: mt.suffixes, enumerable: true });
              Object.defineProperty(mimeType, 'description', { value: mt.description, enumerable: true });
              Object.defineProperty(mimeType, 'enabledPlugin', { value: plugin, enumerable: true });
              Object.defineProperty(plugin, j, { value: mimeType, enumerable: true });
              Object.defineProperty(plugin, mt.type, { value: mimeType, enumerable: false });
            }
            arr.push(plugin);
          }
          
          const pluginArray = Object.create(PluginArray.prototype);
          Object.defineProperty(pluginArray, 'length', { value: arr.length, enumerable: true });
          
          const itemFn = function item(index) { return arr[index] || null; };
          const namedItemFn = function namedItem(name) { 
            return arr.find(p => p.name === name) || null; 
          };
          
          Object.defineProperty(pluginArray, 'item', { value: itemFn, enumerable: true, writable: false });
          Object.defineProperty(pluginArray, 'namedItem', { value: namedItemFn, enumerable: true, writable: false });
          
          if (window.FunctionCloaker) {
            window.FunctionCloaker.cloak(itemFn, PluginArray.prototype.item || function item() { [native code] });
            window.FunctionCloaker.cloak(namedItemFn, PluginArray.prototype.namedItem || function namedItem() { [native code] });
          }

          for(let i = 0; i < arr.length; i++) {
            Object.defineProperty(pluginArray, i, { value: arr[i], enumerable: true });
            Object.defineProperty(pluginArray, arr[i].name, { value: arr[i], enumerable: false });
          }
          
          const refreshFn = function refresh() {};
          Object.defineProperty(pluginArray, 'refresh', { value: refreshFn, enumerable: true });
          if (window.FunctionCloaker) {
            window.FunctionCloaker.cloak(refreshFn, PluginArray.prototype.refresh || function refresh() { [native code] });
          }
          
          return pluginArray;
        }

        const fakePluginArray = createFakePluginArray(fakePlugins);
        
        Object.defineProperty(Navigator.prototype, 'plugins', {
          get: function() { return fakePluginArray; },
          enumerable: true,
          configurable: true
        });
        
        if (window.FunctionCloaker) {
          const pluginsDesc = Object.getOwnPropertyDescriptor(Navigator.prototype, 'plugins');
          window.FunctionCloaker.cloak(pluginsDesc.get, function get() { [native code] });
        }
      } catch(e) {}
    ''';
  }
}
