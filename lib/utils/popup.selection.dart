import 'package:flutter/material.dart';
import 'package:flutter_webrtc_remote_desktop/model/devices.model.dart';

enum TypeDeviceSelection { soundcard, monitor, bitrate, framerate }

showAlertDeviceSelection({
  required List<dynamic> data,
  required final TypeDeviceSelection type,
  required DeviceSelectionResult deviceSelectionResult,
  required BuildContext context,
}) async {
  dynamic chosenValue;
  await showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text("Select ${type.name.toString()}"),
        content: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
          SingleChildScrollView(  
              scrollDirection: Axis.horizontal,
              child: DropdownButton<dynamic>(
                hint: Text('Select one option'),
                underline: Container(),
                items: data.map((e) {
                  dynamic value = "";
                  String key = "";
                  switch (type) {
                    case TypeDeviceSelection.monitor:
                      value = e.MonitorHandle.toString();
                      key = e.MonitorName;
                      break;
                    case TypeDeviceSelection.soundcard:
                      value = e.DeviceID;
                      key = e.Name;
                      break;
                    case TypeDeviceSelection.bitrate:
                      value = e;
                      key = '${e / 1000} mps';
                      break;
                    case TypeDeviceSelection.framerate:
                      value = e;
                      key = '$e fps';
                      break;
                    default:
                  }
                  return DropdownMenuItem<dynamic>(
                    value: value,
                    child: Text(
                      key,
                    ),
                  );
                }).toList(),
                onChanged: (dynamic value) {
                  chosenValue = value;
                  Navigator.of(context).pop();
                },
              )),
        ]),
      );
    },
  );
  return chosenValue;
}
