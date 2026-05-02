class ErrorStackPatch {
  static String getJS() {
    return '''
      try {
        const originalStackGetter = Object.getOwnPropertyDescriptor(Error.prototype, 'stack').get;
        if (!originalStackGetter) return; // V8 might handle this differently depending on version
        
        const cleanStack = function(stack) {
          if (!stack) return stack;
          const lines = stack.split('\\n');
          const cleanLines = lines.filter(line => {
            // Remove injected script lines
            if (line.includes('__puppeteer_evaluation_script__')) return false;
            if (line.includes('<anonymous>:')) return false; // Common for eval/injected scripts
            return true;
          });
          return cleanLines.join('\\n');
        };

        const newStackGetter = function() {
          try {
            const stack = originalStackGetter.call(this);
            return cleanStack(stack);
          } catch(e) {
            return '';
          }
        };

        Object.defineProperty(Error.prototype, 'stack', {
          get: newStackGetter,
          set: undefined,
          configurable: true,
          enumerable: false
        });

        if (window.FunctionCloaker) {
          window.FunctionCloaker.cloak(newStackGetter, originalStackGetter);
        }
      } catch(e) {
        // Silent failure protection
      }
    ''';
  }
}
