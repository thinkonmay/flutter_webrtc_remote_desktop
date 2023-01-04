
class HID {
  // List<Shorcut> shortcuts;
  // bool relativeMouse;
  Screen screen = Screen(null, null, null, null, null, null);
  late void Function({String? data}) sendFunc;
  HID(void Function({String? data}) SendFunc) {
    // this.relatvieMouse = false;
    this.sendFunc = SendFunc;
    this.screen = Screen(0, 0, 0, 0, 0, 0);
  }
  
  // video element but in android devices, it isn't this method

}

class Screen {
  /*
  * frame resolution used to transport to client
  */
  int? StreamWidth;
  int? StreamHeight;

  /*
  * client resolution display on client screen
  */
  int? ClientWidth;
  int? ClientHeight;
  /*
  * client resolution display on client screen
  */
  int? ClientTop;
  int? ClientLeft;

  Screen(this.ClientWidth, this.ClientHeight, this.StreamWidth,
      this.StreamHeight, this.ClientTop, this.ClientLeft);
}
