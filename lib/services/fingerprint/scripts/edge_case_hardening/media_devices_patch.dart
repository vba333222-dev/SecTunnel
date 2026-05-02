class MediaDevicesPatch {
  static String getJS() {
    return '''
      try {
        if (!navigator.mediaDevices || !navigator.mediaDevices.enumerateDevices) return;

        const originalEnumerate = navigator.mediaDevices.enumerateDevices;
        
        // Emulate realistic media devices
        // This stops bots from seeing 0 media devices in headless environments
        const fakeDevices = [
          {
            deviceId: "default",
            kind: "audioinput",
            label: "Default - Microphone (Realtek Audio)",
            groupId: "default-audio-group"
          },
          {
            deviceId: "video-1",
            kind: "videoinput",
            label: "USB Video Device",
            groupId: "video-group"
          },
          {
            deviceId: "default-out",
            kind: "audiooutput",
            label: "Default - Speakers (Realtek Audio)",
            groupId: "default-audio-group"
          }
        ];

        const createFakeMediaDeviceInfo = (device) => {
          const info = Object.create(MediaDeviceInfo.prototype);
          Object.defineProperty(info, 'deviceId', { value: device.deviceId, enumerable: true });
          Object.defineProperty(info, 'kind', { value: device.kind, enumerable: true });
          Object.defineProperty(info, 'label', { value: device.label, enumerable: true });
          Object.defineProperty(info, 'groupId', { value: device.groupId, enumerable: true });
          
          if (info.toJSON === undefined) {
             const toJSON = function() {
               return {
                 deviceId: this.deviceId,
                 kind: this.kind,
                 label: this.label,
                 groupId: this.groupId
               };
             };
             Object.defineProperty(info, 'toJSON', { value: toJSON, enumerable: true });
             if (window.FunctionCloaker) window.FunctionCloaker.cloak(toJSON, function toJSON() { [native code] });
          }
          return info;
        };

        const fakeInfoList = fakeDevices.map(createFakeMediaDeviceInfo);

        const newEnumerate = async function enumerateDevices() {
          try {
            // Return fake list instead of native empty list or native list with 0 devices
            return Promise.resolve(fakeInfoList);
          } catch(e) {
            return await originalEnumerate.call(this);
          }
        };

        Object.defineProperty(MediaDevices.prototype, 'enumerateDevices', {
          value: newEnumerate,
          enumerable: true,
          configurable: true,
          writable: true
        });

        if (window.FunctionCloaker) {
          window.FunctionCloaker.cloak(newEnumerate, originalEnumerate);
        }
      } catch(e) {}
    ''';
  }
}
