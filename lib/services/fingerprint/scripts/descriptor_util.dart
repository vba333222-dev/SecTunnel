class DescriptorUtil {
  static String get jsCode => r'''
    function getNativeDescriptor(target, property) {
      return Object.getOwnPropertyDescriptor(target, property) || {
        configurable: true,
        enumerable: true,
        writable: true
      };
    }

    function createMethodDescriptor(method, originalDescriptor) {
      return {
        value: method,
        configurable: originalDescriptor ? originalDescriptor.configurable : true,
        enumerable: originalDescriptor ? originalDescriptor.enumerable : true,
        writable: originalDescriptor ? originalDescriptor.writable : true,
      };
    }

    function createGetterDescriptor(getter, originalDescriptor) {
      return {
        get: getter,
        set: originalDescriptor ? originalDescriptor.set : undefined,
        configurable: originalDescriptor ? originalDescriptor.configurable : true,
        enumerable: originalDescriptor ? originalDescriptor.enumerable : true,
      };
    }
''';
}
