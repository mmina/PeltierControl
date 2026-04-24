PeltierControl peltier;
boolean working = false;
boolean controlling = false;

static final int DELTA_T = 10;

void setup() {
  peltier = new PeltierControl(this);

  size(400, 300);
  textSize(32);
  fill(0, 0, 0);
  textAlign(CENTER, CENTER);
  frameRate(30);
}

void draw() {
  background(255);
  if (working) {
    int temp = peltier.getCurrentTemp();
    text(temp, 200, 150);
  }
}

void keyTyped() {
  switch(key) {
    case ENTER:
    case RETURN:
      working = !working;
      if (working) {
        peltier.start();
      } else {
        peltier.stop();
      }
      break;
    case ' ':
      controlling = !controlling;
      if (controlling) {
        peltier.startControl();
      } else {
        peltier.stopControl();
      }
      break;
    case 'h':
    case 'H':
      peltier.increseTargetTemp(DELTA_T);
      break;
    case 'c':
    case 'C':
      peltier.decreseTargetTemp(DELTA_T);
      break;
    default:
      // do nothing
  }
}
