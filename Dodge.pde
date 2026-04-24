import org.gamecontrolplus.gui.*;
import org.gamecontrolplus.*;
import net.java.games.input.*;

static final int TIMELIMIT = 180000;  // 3 min
// static final int TIMELIMIT = 30000;  // 3 min

static final String PADNAME = "gamepad";
static final String STARTBUTTON = "STARTBUTTON";
static final String XPOS = "XPOS";
static final String YPOS = "YPOS";
static final String SPEEDDOWN = "SPEEDDOWN";
static final String SPEEDUP = "SPEEDUP";
static final float SPEED_MAX = 5.0;
static final float SPEED_MIN = 3.0;
static final float SPEED_DELTA = 1.0;
static final int PENALTYTIME = 2000;

static final int BALLSIZE = 200;
static final int BALLAREA_X_L = -100;
static final int BALLAREA_X_R = 900;
static final int BALLAREA_Y_T = -100;
static final int BALLAREA_Y_B = 900;
static final int NUMBALLS = 3;

// for peltier
static final int DELTA_TEMP = 50;
static final int TEMP_PERIOD = 15000;  // 同じ温度の継続時間

Logger logger = null;

ControlIO control;
ControlDevice gpad;
boolean isPad = true;
boolean startButtonPressed = false;
boolean goNextMode = false;
boolean speedupPressed = false;
boolean speeddownPressed = false;
float moveX, moveY;
float speed = 5.0;

int mode = 0;  // 0: waiting, 1: in game, 2: game over
int startTime;  // ゲーム開始時刻
int time = 0;  // 残り時間
int lastMissTime;  // 最終ミスの時刻
int surviveTime;  // 最終ミスからの経過時間
int miss = 0;  // ミス回数
float x, y;  // 自機の位置
int penaltyTime;
int numPenalty;  // ミス回数

int[] bx = new int[NUMBALLS], by = new int[NUMBALLS], bu = new int[NUMBALLS], bv = new int[NUMBALLS];  // ball position and speed
static final int[] INIT_U = {5, 7, 9};
static final int[] INIT_V = {2, 4, 6};

PeltierControl peltier;
int peltierMode = 0;  // 0 off, 1 hot, 2, cool, 3, time hot, 4, time cool, 5 random
boolean pModeRandom = false;
int[] pModes = {0, 1, 2, 3, 4, 5};
int pModesCount = 0;
boolean peltierWorking = false;
int initTemp = 0;
int standardTemp = 0;
int lastLevel = 0;
int lastTimeLevel = 0;
int randomTime;


void setup() {
  size(800, 800);

  control = ControlIO.getInstance(this);
  gpad = control.filter(GCP.GAMEPAD).getMatchedDevice(PADNAME);
  if (gpad == null) {
    println("no gamepad found, use mouse instead");
    isPad = false;
    // System.exit(-1);
  }
  
  peltier = new PeltierControl(this);
}

void shufflePeltierModes() {
  for (int i = 0; i < pModes.length; i++) {
    int target = (int)random(pModes.length);
    int buf = pModes[i];
    pModes[i] = pModes[target];
    pModes[target] = buf;
  }
  print("pModes = ");
  for (int i = 0; i < pModes.length; i++) {
    print(pModes[i] + ", ");
  }
  println();
  pModesCount = 0;
}

void draw() {
  background(255, 255, 255);
  if (isPad)  getInput();
  
  if (mode == 0) {
    textSize(64);
    textAlign(CENTER);
    fill(0, 255, 0);
    if (pModeRandom) {
      text("GAME " + (pModesCount + 1), width / 2, height / 2 - 60);
    }
    text("READY?", width / 2, height / 2);
    if (goNextMode) {
      x = width / 2;
      y = height / 2;
      // speed = 5.0;  リセットしない
      for (int i = 0; i < NUMBALLS; i++) {
        bx[i] = BALLAREA_X_L + BALLSIZE / 2;
        by[i] = BALLAREA_Y_T + BALLSIZE / 2 + i * BALLSIZE;
        bu[i] = INIT_U[i];
        bv[i] = INIT_V[i];
      }
      time = 0;
      startTime = millis();
      lastMissTime = startTime;
      lastLevel = 0;
      lastTimeLevel = 0;
      numPenalty = 0;
      if (pModeRandom) {
        peltierMode = pModes[pModesCount];
        println("peltier mode = " + peltierMode);
        if (logger != null)  logger.logMillis(0 + ", peltier mode, " + peltierMode);
        pModesCount++;
        if (pModesCount >= pModes.length) {
          shufflePeltierModes();
        }
      }
      if (peltierWorking && peltierMode != 0) {
        if (peltierMode != 0) {
          randomTime = millis();
          initTemp = peltier.getCurrentTemp();
          if (standardTemp == 0)  standardTemp = initTemp;  // 初期設定忘れ防止のため
          peltier.setTargetTemp(initTemp);
          println("initTemp = " + initTemp);
          peltier.startControl();
        } else {
          peltier.stopControl();  // 初期温度調整中かもしれないので念のため止める
        }
      } else {
        randomTime = millis();
      }
      mode = 1;
      if (logger != null) {
        logger.logMillis(0 + ", game start");
        logger.logMillis(0 + ", peltierWorking, " + peltierWorking + ", mode, " + peltierMode);
        if (peltierWorking)  logger.logMillis(0 + ", initTemp, " + initTemp);
      }
      goNextMode = false;
    }
  }
  
  if (mode == 1 || mode == 2) {
    time = millis() - startTime;
    surviveTime = millis() - lastMissTime;
    if (peltierMode == 1 || peltierMode == 2) {
      int level = surviveTime / TEMP_PERIOD;
      // println("level = " + level);
      if (level != lastTimeLevel) {
        if (peltierWorking) {
          int sign = peltierMode == 1 ? 1 : -1;
          peltier.setTargetTemp(initTemp + level * DELTA_TEMP * sign);
          if (logger != null)  logger.logMillis(time + ", targetTemp, " + (initTemp + level * DELTA_TEMP * sign));
        } else {
          // for debug
          int sign = peltierMode == 1 ? 1 : -1;
          println("temp = " + (initTemp + level * DELTA_TEMP * sign));
        }
        lastTimeLevel = level;
      }
    }
    if (peltierMode == 3 || peltierMode == 4) {
      int level = time / TEMP_PERIOD;
      // println("level = " + level);
      if (level != lastTimeLevel) {
        if (peltierWorking) {
          int sign = peltierMode == 3 ? 1 : -1;
          peltier.setTargetTemp(initTemp + level * DELTA_TEMP * sign);
          if (logger != null)  logger.logMillis(time + ", targetTemp, " + (initTemp + level * DELTA_TEMP * sign));
        } else {
          // for debug
          int sign = peltierMode == 3 ? 1 : -1;
          println("temp = " + (initTemp + level * DELTA_TEMP * sign));
        }
        lastTimeLevel = level;
      }
    }
    if (peltierMode == 5) {
      if (peltierWorking && (millis() - randomTime >= TEMP_PERIOD)) {
        int randomLevel = (int)random(21) - 10;
        peltier.setTargetTemp(initTemp + randomLevel * DELTA_TEMP);
        if (logger != null)  logger.logMillis(time + ", targetTemp, " + (initTemp + randomLevel * DELTA_TEMP));
        randomTime = millis();
      } else if (millis() - randomTime >= TEMP_PERIOD) {
        // for debug
        int randomLevel = (int)random(21) - 10;
        println("temp = " + (initTemp + randomLevel * DELTA_TEMP));
        randomTime = millis();
      }
    }
    
    textSize(32);
    textAlign(RIGHT);
    if (TIMELIMIT - time > TIMELIMIT / 2) {
      fill(0, 255, 0);
    } else if (TIMELIMIT - time > TIMELIMIT / 4) {
      fill(255, 128, 0);
    } else {
      fill(255, 0, 0);
    }
    text("TIME: ", 90, 30);
    text(TIMELIMIT - time, 190, 30);
    
    setSpeedColor();
    text("SPEED: ", 112, 60);
    text((int)speed, 140, 60);
    
    fill(255, 0, 0);
    text("PENALTY: ", 138, 90);
    text(numPenalty, 164, 90);
    
    /*
    fill(255, 255, 255);
    text("MODE: ", 104, 90);
    text(peltierMode, 120, 90);
    */
    
    fill(0, 0, 0);
    stroke(0, 0, 0);
    for (int i = 0; i < NUMBALLS; i++) {
      circle(bx[i], by[i], BALLSIZE);
    }

    if (mode == 1) {
      if (isPad) {
        x += moveX;
        if (x < 0)  x = 0;
        if (x > width)  x = width;
        y += moveY;
        if (y < 0)  y = 0;
        if (y > height)  y = height;
      } else {
        x = mouseX;
        y = mouseY;
      }
      switch (check()) {
        case -1:
          penaltyTime = millis();
          if (penaltyTime - lastMissTime > PENALTYTIME + 500) {
            // ペナルティ開け直後の連続ミスはカウントしない
            int temp = 0;
            if (peltierWorking) {
              temp = peltier.getCurrentTemp();
            }
            numPenalty++;
            if (logger != null)  logger.logMillis(time + ", penalty, " + temp);
          }
          lastMissTime = penaltyTime;
          mode = 2;
          break;
        case -2:
          mode = 3;  // go to gameover
          if (logger != null)  logger.logMillis(time + ", game over");
          break;
        /*
        case 1:
          mode = 4;  // go to clear
          if (logger != null)  logger.logMillis(time + ", game clear");
          break;
        */
        default:
          // do nothing
      }
      setSpeedColor();
      circle(x, y, 10);
    }
    if (mode == 2) {
      int penalty = PENALTYTIME - (millis() - penaltyTime);
      if (penalty <= 0) {
        mode = 1;
      }
      setSpeedColor();
      circle(x, y, 10);
      textSize(64);
      textAlign(CENTER);
      if (penalty <= 1000) {
        fill(0, 255, 0);
        text("READY?", width / 2, height / 2);
      } else {
        fill(255, 0, 0);
        text("PENALTY", width / 2, height / 2);
      }
    }
    for (int i = 0; i < NUMBALLS; i++) {
      bx[i] += bu[i];
      by[i] += bv[i];
      if (bx[i] < BALLAREA_X_L + BALLSIZE / 2 || BALLAREA_X_R - BALLSIZE / 2 < bx[i]) {
        bu[i] = -bu[i];
      }
      if (by[i] < BALLAREA_Y_T + BALLSIZE / 2 || BALLAREA_Y_B - BALLSIZE / 2 < by[i]) {
        bv[i] = -bv[i];
      }
    }
  }

  if (mode == 3) {
    // game over
    if (peltierWorking && peltierMode != 0) {
        peltier.stopControl();
    }
    setSpeedColor();
    circle(x, y, 10);    
    textSize(64);
    textAlign(CENTER);
    fill(255, 0, 0);
    text("FINISH!", width / 2, height / 2);
    stroke(255, 0, 0);
    fill(255, 0, 0);
    if (goNextMode) {
      goNextMode = false;
      mode = 0;
    }
  }
  
  if (mode == 4) {
    // claer
    if (peltierWorking && peltierMode != 0) {
        peltier.stopControl();
    }
    setSpeedColor();
    circle(x, y, 10);    
    textSize(64);
    textAlign(CENTER);
    fill(64, 64, 255);
    text("CLEAR!!", width / 2, height / 2);
    stroke(255, 0, 0);
    fill(255, 0, 0);
    if (goNextMode) {
      goNextMode = false;
      mode = 0;
    }
  }
    
}

void keyTyped() {
  // peltier mode
  if (key == ' ') {
    peltierMode++;
    if (peltierMode >= pModes.length)  peltierMode = 0;
    println("peltierMode = " + peltierMode);
    return;
  }
  
  // peltier on / off
  if (key == ENTER || key == RETURN) {
    peltierWorking = !peltierWorking;
    if (peltierWorking) {
      peltier.start();
    } else {
      peltier.stop();
    }
    return;
  }
  
  // set standard temp
  if (key == 't' || key == 'T') {
    if (peltierWorking) {
      standardTemp = peltier.getCurrentTemp();
      println("standardTemp = " + standardTemp);
    }
  }
  
  // adjust temp
  if (key == 'i' || key == 'I') {
    if (peltierWorking && standardTemp != 0) {
      println("adjust temp = " + standardTemp);
      peltier.setTargetTemp(standardTemp);
      peltier.startControl();
      mode = 0;  // 強制的にスタート待ち状態にする
    }
  }
  
  // random peltier modes
  if (key == 'r' || key == 'R') {
    pModeRandom = !pModeRandom;
    if (pModeRandom) {
      shufflePeltierModes();
    }
    println("random peltier modes = " + pModeRandom);
  }
  
  if (key == 's' || key == 'S') {
    goNextMode = true;
    return;
  }
  
  // give up
  if (key == 'g' || key == 'G') {
    startTime = millis() - TIMELIMIT;
    return;
  }
  
  // log start / stop
  if (key == 'l' || key == 'L') {
    if (logger == null) {
      println("log open");
      logger = new Logger();
    } else {
      println("log close");
      logger.close();
      logger = null;
    }
  }
}

int check() {
/* return value: -2 gameover, -1 penalty, 1 clear, 0 playing */
  if (mode == 1) {
    for (int i = 0; i < NUMBALLS; i++) {
      if (dist(x, y, bx[i], by[i]) < BALLSIZE / 2)  return -1;
    }
  }
  if (TIMELIMIT - time < 0)  return -2;  // time up
  return 0;
}

void getInput() {
  if (gpad.getButton(STARTBUTTON).pressed() || gpad.getButton(0).pressed()) {
    if (!startButtonPressed) {
      goNextMode = true;
      startButtonPressed = true;
    }
  } else {
    startButtonPressed = false;
  }
  if (gpad.getButton(SPEEDDOWN).pressed() || gpad.getButton(4).pressed()) {
    if (!speeddownPressed) {
      speed -= SPEED_DELTA;
      if (speed < SPEED_MIN)  speed = SPEED_MIN;
      speeddownPressed = true;
    }
  } else {
    speeddownPressed = false;
  }
  if (gpad.getButton(SPEEDUP).pressed() || gpad.getButton(5).pressed()) {
    if (!speedupPressed) {
      speed += SPEED_DELTA;
      if (speed > SPEED_MAX)  speed = SPEED_MAX;
      speedupPressed = true;
    }
  } else {
    speedupPressed = false;
  }
  moveX = map(gpad.getSlider(XPOS).getValue(), -1.0, 1.0, -speed, speed);
  moveY = map(gpad.getSlider(YPOS).getValue(), -1.0, 1.0, -speed, speed);
}

void setSpeedColor() {
  // int speedLevel = (int)((speed - 0.1) / 0.4);
  int speedLevel = (int)(speed - 3.0) * 2;
  switch (speedLevel) {
  case 0:
    fill(0, 180, 220);
    stroke(0, 180, 220);
    break;
  case 1:
    fill(0, 220, 0);
    stroke(0, 220, 0);
    break;
  case 2:
    fill(220, 220, 0);
    stroke(220, 220, 0);
    break;
  case 3:
    fill(255, 128, 0);
    stroke(255, 128, 0);
    break;
  case 4:
    fill(255, 0, 0);
    stroke(255, 0, 0);
    break;
  default:
    fill(0, 0, 0);
    stroke(0, 0, 0);
    break;
  }
}
