import 'dart:convert';

enum LogLevel { Debug, Infor, Warning, Error, Fatal }

String GetLogLevelString(LogLevel level) {
  switch (level) {
    case LogLevel.Debug:
      return "Debug";
    case LogLevel.Infor:
      return "Infor";
    case LogLevel.Warning:
      return "Warning";
    case LogLevel.Error:
      return "Error";
    case LogLevel.Fatal:
      return "Fatal";
  }
}

enum ConnectionEvent {
  ApplicationStarted,

  WebSocketConnecting,
  WebSocketConnected,
  WebSocketDisconnected,

  WaitingAvailableDevice,
  WaitingAvailableDeviceSelection,

  ExchangingSignalingMessage,

  WebRTCConnectionChecking,
  WebRTCConnectionDoneChecking,
  WebRTCConnectionClosed,

  ReceivedVideoStream,
  ReceivedAudioStream,
  ReceivedDatachannel,
}

String GetEventMessage(ConnectionEvent event) {
  switch (event) {
    case ConnectionEvent.ApplicationStarted:
      return "ApplicationStarted";
    case ConnectionEvent.WebSocketConnecting:
      return "WebSocketConnecting";
    case ConnectionEvent.WebSocketConnected:
      return "WebSocketConnected";
    case ConnectionEvent.WebSocketDisconnected:
      return "WebSocketDisconnected";
    case ConnectionEvent.WaitingAvailableDevice:
      return "WaitingAvailableDevice";
    case ConnectionEvent.WaitingAvailableDeviceSelection:
      return "WaitingAvailableDeviceSelection";
    case ConnectionEvent.ExchangingSignalingMessage:
      return "ExchangingSignalingMessage";
    case ConnectionEvent.WebRTCConnectionChecking:
      return "WebRTCConnectionChecking";
    case ConnectionEvent.WebRTCConnectionDoneChecking:
      return "WebRTCConnectionDoneChecking";
    case ConnectionEvent.ReceivedVideoStream:
      return "ReceivedVideoStream";
    case ConnectionEvent.ReceivedAudioStream:
      return "ReceivedAudioStream";
    case ConnectionEvent.ReceivedDatachannel:
      return "ReceivedDatachannel";
    case ConnectionEvent.WebRTCConnectionClosed:
      return "WebRTCConnectionClosed";
  }
}

typedef FailNotifyType = void Function(String message);

class Logger {
  List<String> logs = [];
  List<FailNotifyType> failNotifiers = [];

  Logger() {
    logs = <String>[];
    failNotifiers = <FailNotifyType>[];
  }

  filterEvent(String data) {
    logs.add(data);
  }

  BroadcastEvent(ConnectionEvent event) {
    failNotifiers.forEach((x) => {x(GetEventMessage(event))});
  }

  AddNotifier(FailNotifyType notifier) {
    failNotifiers.add(notifier);
  }
}

var init = false;
var loggerSingleton = Logger();
Logger getLoggerSingleton() {
  if (!init) {
    loggerSingleton = Logger();
    init = true;
  }

  return loggerSingleton;
}

AddNotifier(FailNotifyType notifier) {
  var logger = getLoggerSingleton();
  logger.AddNotifier(notifier);
}

Log(LogLevel level, String message) {
  var logger = getLoggerSingleton();
  // logger.filterEvent(jsonEncode(level));
  print("[${GetLogLevelString(level)}] : $message");
}

LogConnectionEvent(ConnectionEvent a) {
  var logger = getLoggerSingleton();
  logger.BroadcastEvent(a);
  print("[${GetLogLevelString(LogLevel.Infor)}] : ${GetEventMessage(a)}");
}
