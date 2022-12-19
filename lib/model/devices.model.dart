import 'dart:convert';

class Soundcard {
  late String DeviceID;
  late String Name;
  late String Api;
  late bool IsDefault;
  late bool IsLoopback;

  Soundcard(dynamic data) {
    DeviceID = data.id;
    Name = data.name;
    Api = data.api;
    IsDefault = data.isDefault;
    IsLoopback = data.isLoopback;
  }

  Soundcard.fromJson(Map<String, dynamic> json)
      : DeviceID = json['id'],
        Name = json['name'],
        Api = json['api'],
        IsDefault = json['isDefault'],
        IsLoopback = json['isLoopback'];
}

class Monitor {
  late int MonitorHandle;
  late String MonitorName;
  late String DeviceName;
  late String Adapter;
  late int Width;
  late int Height;
  late int Framerate;
  late bool IsPrimary;

  Monitor(dynamic data) {
    MonitorHandle = data.handle;
    MonitorName = data.name;
    DeviceName = data.device;
    Adapter = data.adapter;
    Width = data.width;
    Height = data.height;
    Framerate = data.framerate;
    IsPrimary = data.isPrimary;
  }

  Monitor.fromJson(Map<String, dynamic> json)
      : MonitorHandle = json['handle'],
        MonitorName = json['name'],
        DeviceName = json['device'],
        Adapter = json['adapter'],
        Width = json['width'],
        Height = json['height'],
        Framerate = json['framerate'],
        IsPrimary = json['isPrimary'];
}

class DeviceSelection {
  late List<Monitor> monitors;
  late List<Soundcard> soundcards;

  DeviceSelection(String data) {
    monitors = <Monitor>[];
    soundcards = <Soundcard>[];

    var parseResult = jsonDecode(data);

    for (var i in parseResult["monitors"]) {
      monitors.add(Monitor.fromJson(i));
    }
    for (var i in parseResult["soundcards"]) {
      soundcards.add(Soundcard.fromJson(i));
    }
  }
}

class DeviceSelectionResult {
  String? MonitorHandle;
  String? SoundcardDeviceID;

  DeviceSelectionResult(
      String? soundcard, String? monitor) {
    this.SoundcardDeviceID = soundcard;
    this.MonitorHandle = monitor;
  }

  @override
  String toString() {
    return jsonEncode({
      "monitor": this.MonitorHandle,
      "soundcard": this.SoundcardDeviceID,
    });
  }
}
