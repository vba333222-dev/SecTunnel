class PermissionsPatch {
  static String getJS() {
    return '''
      try {
        if (!navigator.permissions) return;

        const originalQuery = navigator.permissions.query;
        
        const newQuery = async function query(parameters) {
          try {
            if (parameters && parameters.name === 'notifications') {
              // Notification permissions are often checked by anti-detects
              // Return 'prompt' to simulate a standard fresh session, or match config
              const result = Object.create(PermissionStatus.prototype);
              let state = 'prompt';
              
              // Emulate Notification.permission if it exists to keep coherence
              if (window.Notification && window.Notification.permission === 'denied') {
                state = 'denied';
              }
              
              Object.defineProperty(result, 'state', { value: state, enumerable: true, writable: false });
              Object.defineProperty(result, 'name', { value: 'notifications', enumerable: true, writable: false });
              result.onchange = null;
              
              // Must behave like a promise
              return Promise.resolve(result);
            }
            return await originalQuery.call(this, parameters);
          } catch (e) {
            // Fallback to real API if error to avoid throwing our own anomalous errors
            return await originalQuery.call(this, parameters);
          }
        };

        Object.defineProperty(Permissions.prototype, 'query', {
          value: newQuery,
          enumerable: true,
          configurable: true,
          writable: true
        });

        if (window.FunctionCloaker) {
          window.FunctionCloaker.cloak(newQuery, originalQuery);
        }
      } catch(e) {}
    ''';
  }
}
