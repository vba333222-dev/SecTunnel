import 'function_cloaker.dart';
import 'descriptor_util.dart';

class NativeEmulationEngine {
  static String buildEmulationScript(String patchesJs) {
    return '''
(function() {
  try {
    ${FunctionCloaker.jsCode}
    ${DescriptorUtil.jsCode}

    const EmulationEngine = {
      patchGetter(target, property, getterImpl) {
        const originalDescriptor = getNativeDescriptor(target, property);
        const originalGetter = originalDescriptor.get || function() {};
        
        const cloakedGetter = cloakFunction(getterImpl, originalGetter);
        const newDescriptor = createGetterDescriptor(cloakedGetter, originalDescriptor);
        
        Object.defineProperty(target, property, newDescriptor);
      },

      patchMethod(target, property, methodImpl) {
        const originalMethod = target[property] || function() {};
        const originalDescriptor = getNativeDescriptor(target, property);
        
        const cloakedMethod = cloakFunction(methodImpl, originalMethod);
        const newDescriptor = createMethodDescriptor(cloakedMethod, originalDescriptor);
        
        Object.defineProperty(target, property, newDescriptor);
      }
    };

    // Execute provided patches
    $patchesJs

  } catch (e) {
    // Fail silently to avoid detection
  }
})();
''';
  }
}
