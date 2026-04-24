/*
  ペルチェコントローラで温度制御
  
  M1 Macで動かすにはjssc.jarを最新版に置き換える必要がある。
  https://github.com/processing/processing4
  のjava/libraries/serial/libraryからダウンロードし、
  Processing.appのContens/Java/modes/java/libraries/serial/binaly
  に入っているものを置き換える。
*/
import processing.serial.*;

public class PeltierControl extends PApplet {
  PApplet parent;

  static final int UPPER_TEMP = 4200;
  static final int LOWER_TEMP = 2000;

  public Serial myPort;
  int targetTemp;
  int currentTemp;
  int fCount;
  boolean working = false;
  boolean controlling = false;
  boolean panic = false;

  PeltierControl(PApplet _parent) {
    super();
    this.parent = _parent;
    try {
      java.lang.reflect.Method handleSettingsMethod =
        this.getClass().getSuperclass().getDeclaredMethod("handleSettings", null);
      handleSettingsMethod.setAccessible(true);
      handleSettingsMethod.invoke(this, null);
    } catch (Exception ex) {
      ex.printStackTrace();
    }
    PSurface surface = super.initSurface();
    surface.placeWindow(new int[]{0, 0}, new int[]{0, 0});
    this.showSurface();
    this.startSurface();

    String[] serialList = Serial.list();  // ポートのリストを取得
    for (String name : serialList) {
      if (name.startsWith("/dev/tty.usbserial") || name.startsWith("COM")) {
        myPort = new Serial(this, name, 115200);
        println("serial port = " + name);
      }
    }
    if (myPort == null) {
      println("no serial port");
      return;
    }
    myPort.bufferUntil(0x0A);  // 一行ずつバッファリングする
  }
  
  void settings() {
    size(400, 300);
  }
  
  void setup() {
    textSize(32);
  }

  void draw() {
    background(255);
  
    if (panic) {  // 緊急停止メッセージ
      fill(255, 0, 0);
      text("PANIC aborted", 10, 250);
    }
  
    if (working) {
      if (controlling) {
        fill(0, 255, 0);  // 温度制御中は緑文字
      } else {
        fill(0, 0, 255);  // 動作中＆温度制御停止中は青文字
      }
    } else {
      fill(0, 0, 0);  // 停止中は黒文字
    }

    text(" target: " + targetTemp, 10, 40);
    text("current: " + currentTemp, 10, 80);
    
    if (!working)  return;
  
    fCount++;
    if (fCount >= 30) {
      // 温度情報を取得する
      // Serial.writeで文字列を与えるとUTF16になるのでうまくいかない
      sendGetTemp();
      fCount = 0;
      // println("sent a command.");
    }
  }

  void serialEvent(Serial p) {
    String buff = p.readString();
    // println("received: " + buff);
  
    if (buff.startsWith("RTP")) {  // 温度取得
      String[] tokens = split(buff, ',');
      targetTemp = int(tokens[1]);
      currentTemp = int(tokens[2]);
      if (currentTemp < LOWER_TEMP || UPPER_TEMP < currentTemp) {  // 温度が異常な場合緊急停止
        sendStop();
        controlling = false;
        working = false;
        panic = true;
        println("PANIC: temp = " + currentTemp);
      }
    }
  }
  
  public void start() {
    if (myPort == null)  return;
    working = true;
  }
  
  public void stop() {
    if (myPort == null)  return;
    if (controlling) {
      sendStop();
    }
    controlling = false;
    working = false;
  }
  
  public void startControl() {
    if (myPort == null)  return;
    if (!working)  return;
    controlling = true;
    sendTargetTemp(targetTemp);
    sendStart();
  }
  
  public void stopControl() {
    if (myPort == null)  return;
    if (!working)  return;
    controlling = false;
    sendStop();
  }
  
  public int getCurrentTemp() {
    if (myPort == null)  return 0;
    return currentTemp;
  }
  
  public void setTargetTemp(int temp) {
    // println("setTargetTemp, " + temp);
    if (myPort == null)  return;
    if (!working)  return;
    targetTemp = temp;
    if (targetTemp > UPPER_TEMP)  targetTemp = UPPER_TEMP;
    if (targetTemp < LOWER_TEMP)  targetTemp = LOWER_TEMP;
    sendTargetTemp(targetTemp);
  }
  
  public void increseTargetTemp(int delta) {
    if (myPort == null)  return;
    if (!working)  return;
    targetTemp += delta;
    if (targetTemp > UPPER_TEMP)  targetTemp = UPPER_TEMP;
    sendTargetTemp(targetTemp);
  }
  
  public void decreseTargetTemp(int delta) {
    if (myPort == null)  return;
    if (!working)  return;
    targetTemp -= delta;
    if (targetTemp < LOWER_TEMP)  targetTemp = LOWER_TEMP;
    sendTargetTemp(targetTemp);
  }

  private void sendStart() {
    myPort.write('S');
    myPort.write('T');
    myPort.write('A');
    myPort.write(0x0D);
    myPort.write(0x0A);
  }

  private void sendStop() {
    myPort.write('S');
    myPort.write('T');
    myPort.write('O');
    myPort.write(0x0D);
    myPort.write(0x0A);
  }

  private void sendGetTemp() {
    myPort.write('R');
    myPort.write('T');
    myPort.write('P');
    myPort.write(0x0D);
    myPort.write(0x0A);
  }

  private void sendTargetTemp(int temp) {
    // 暫定設定モードを使用
    String str = str(temp);
  
    myPort.write('S');
    myPort.write('P');
    myPort.write('T');
    myPort.write(',');
    myPort.write(str.charAt(0));
    myPort.write(str.charAt(1));
    myPort.write(str.charAt(2));
    myPort.write(str.charAt(3));
    myPort.write(0x0D);
    myPort.write(0x0A);
  }
}
