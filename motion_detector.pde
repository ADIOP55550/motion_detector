import processing.video.*;
import controlP5.*;
import uibooster.*;
import java.util.Optional;
import java.util.List;
import java.util.ArrayList;


ControlP5 cp5;
Movie movie;
PImage prev;

boolean resetPrev = true;
final int rolling_buffer_size = 1;

PImage[] prevs = new PImage[rolling_buffer_size];

float threshold = 50;
float thresholdSize = 200;

final int toolbar_height = 40;
final int seekbar_height = 20;

final String movieFile = "MOV_0017.mp4";

final int v_w = 640;
final int v_h = 480;

int playingSpeed = 1 << 4;

boolean isPlaying = false;
boolean manualSlider = false;
boolean autoPause = false;
boolean _playSingleFrame = false;

Toggle playToggle;
Toggle autoPauseToggle;
Slider seekSlider;
Slider tresholdSlider;
Slider tresholdSizeSlider;
Button singleFrameButton;
Button slowerButton;
Button speedButton;
Button fasterButton;


void settings() {
  size(v_w, v_h + toolbar_height + seekbar_height);
}

void setup() {
  background(10);

  PFont pfont = createFont("Verdana", 30, true); // use true/false for smooth/no-smooth
  ControlFont font = new ControlFont(pfont, 241);

  cp5 = new ControlP5(this);

  int nextX = 0;

  playToggle = cp5
    .addToggle("playTogglePress")
    .setFont(font)
    .setPosition(0, nextX)
    .setSize(120, toolbar_height)
    .setValue(false);

  playToggle
    .getCaptionLabel()
    .setText("Play");

  playToggle
    .getCaptionLabel()
    .setSize(30)
    .getStyle()
    .marginTop = -45;

  playToggle
    .getCaptionLabel()
    .getStyle()
    .marginLeft = 10;

  nextX += 120+10;



  UiBooster booster = new UiBooster();
  Optional<File> file = Optional.ofNullable(booster.showFileSelection());

  if (!file.isPresent()) {
    println("No file selected!");
    exit();
    return;
  }

  file.orElseThrow();



  movie = new Movie(this, file.get().getPath());
  movie.loop();

  for (int i = 0; i < rolling_buffer_size; i++) {
    prevs[i] = createImage(v_w, v_h, RGB);
  }

  prev = createImage(v_w, v_h, RGB);

  // treshold slider

  tresholdSlider = cp5.addSlider("tresholdSliderChange")
    .setPosition(nextX, 0)
    .setSize(80, toolbar_height)
    .setRange(0, 300)
    .setValue(50);

  tresholdSlider.getCaptionLabel().setText("threshold").align(CENTER, BOTTOM);

  nextX += 80+10;


  tresholdSizeSlider = cp5.addSlider("tresholdSizeSliderChange")
    .setPosition(nextX, 0)
    .setSize(140, toolbar_height)
    .setRange(0, 10000)
    .setValue(200);

  tresholdSizeSlider.getCaptionLabel().setText("min detect size").align(CENTER, BOTTOM).setPaddingY(5);
  nextX += 140+20;

  autoPauseToggle = cp5.addToggle("toggleAutoPause")
    .setPosition(nextX, 0)
    .setSize(50, toolbar_height/2)
    .setValue(false);

  autoPauseToggle.getCaptionLabel().setText("Pause on detect").alignX(CENTER);
  nextX += 50+20;


  singleFrameButton = cp5.addButton("playSingleFrame")
    .setPosition(nextX, 0)
    .setSize(50, toolbar_height);

  singleFrameButton.getCaptionLabel().align(CENTER, CENTER).setText("single >");
  nextX += 50+10;


  nextX += 10;


  slowerButton = cp5.addButton("slowerSpeed")
    .setPosition(nextX, 0)
    .setSize(30, toolbar_height);

  slowerButton.getCaptionLabel().align(CENTER, CENTER).setSize(20).setText("<<");
  nextX += 30+5;


  speedButton = cp5.addButton("resetSpeed")
    .setPosition(nextX, 0)
    .setSize(40, toolbar_height);

  speedButton.getCaptionLabel().align(CENTER, CENTER).setSize(13).setText("x1");
  nextX += 40+5;

  fasterButton = cp5.addButton("fasterSpeed")
    .setPosition(nextX, 0)
    .setSize(30, toolbar_height);

  fasterButton.getCaptionLabel().align(CENTER, CENTER).setSize(20).setText(">>");
  nextX += 30+10;





  seekSlider = cp5.addSlider("seekSliderChange")
    .setPosition(0, v_h + toolbar_height)
    .setSize(width, seekbar_height)
    .setRange(0, movie.duration())
    .setValue(0);

  seekSlider
    .getCaptionLabel()
    .setText(str(movie.duration()));

  seekSlider
    .getValueLabel()
    .setSize(14)
    .align(ControlP5.LEFT, ControlP5.BOTTOM)
    .setPaddingX(30);

  seekSlider
    .getCaptionLabel()
    .setSize(14)
    .align(ControlP5.RIGHT, ControlP5.BOTTOM)
    .setPaddingX(30);
}


float distSq(float x1, float y1, float z1, float x2, float y2, float z2) {
  float d = (x2-x1)*(x2-x1) + (y2-y1)*(y2-y1) +(z2-z1)*(z2-z1);
  return d;
}

void draw() {
  background(10);

  image(movie, 0, toolbar_height);

  List<Point> points = new ArrayList();

  loadPixels();

  // loop through every pixel
  for (int x = 0; x < movie.width-2; x++ ) {
    for (int y = 0; y < movie.height; y++ ) {
      int loc = x + y * movie.width;

      color currentColor = movie.pixels[loc];
      float r1 = red(currentColor);
      float g1 = green(currentColor);
      float b1 = blue(currentColor);

      float r2 = 0;
      float g2 = 0;
      float b2 = 0;

      for (int i = 0; i < rolling_buffer_size; i++) {
        color c = prevs[i].pixels[loc];
        r2 += red(c);
        g2 += green(c);
        b2 += blue(c);
      }

      r2 /= rolling_buffer_size;
      g2 /= rolling_buffer_size;
      b2 /= rolling_buffer_size;

      float d = distSq(r1, g1, b1, r2, g2, b2);

      if (d > threshold*threshold) {
        points.add(new Point(x, y));
      }
    }
  }
  updatePixels();


  if (points.size() > thresholdSize) {

    BoundingBox bb = new BoundingBox(points);

    bb.minY += toolbar_height;
    bb.maxY += toolbar_height;

    fill(255, 0, 255, 20);
    strokeWeight(2.0);
    stroke(255, 0, 0);

    rect((float)bb.minX, (float)bb.minY, (float)bb.maxX, (float)bb.maxY);

    if (autoPause)
      setPlaying(false);
  }



  manualSlider = false;
  seekSlider.setValue(movie.time());

  if (isPlaying || _playSingleFrame)
    movie.play();
  else
    movie.pause();
}

// Read new frames from the movie.
void movieEvent(Movie movie) {
  if (resetPrev) {
    for (int i = 0; i < rolling_buffer_size; i++) {
      if (prevs[i] == null)
        return;
      prevs[i].copy(movie, 0, 0, movie.width, movie.height, 0, 0, prevs[i].width, prevs[i].height);
      prevs[i].updatePixels();
    }
    resetPrev = false;
  } else {
    int p = frameCount % rolling_buffer_size;
    prevs[p].copy(movie, 0, 0, movie.width, movie.height, 0, 0, prevs[p].width, prevs[p].height);
    prevs[p].updatePixels();
  }
  movie.read();
  _playSingleFrame = false;
}


// Automagically called when toggle is pressed
public void setPlaying(boolean state) {
  if (playToggle != null) {
    playToggle.setState(state);
    playToggle.getCaptionLabel().setText(state ? "pause" : "play");
  }

  isPlaying = state;
}


// Automagically called when toggle is pressed
public void playTogglePress(boolean state) {
  if (playToggle != null) {
    playToggle.getCaptionLabel().setText(state ? "pause" : "play");
    if (state)
      _playSingleFrame = true;
  }



  isPlaying = state;
}

void tresholdSliderChange(float val) {
  threshold = val;
}

void tresholdSizeSliderChange(float val) {
  thresholdSize = int(val);
}

void toggleAutoPause(boolean state) {
  autoPause = state;
}

void seekSliderChange(float val) {
  if (!manualSlider) {
    manualSlider = true;
    return;
  }


  if (movie != null) {
    resetPrev = true;
    movie.jump(int(val));
  }

  image(movie, 0, toolbar_height);
}


void playSingleFrame(int __) {
  _playSingleFrame = true;
}

void setSpeed(int speed) {
  if (speed >= (1 << 9))
    return;
  if (speed <= 1)
    return;

  playingSpeed = speed;

  movie.speed(playingSpeed/16.0);

  if (playingSpeed < 16)
    speedButton.getCaptionLabel().setText("x 1/" + str(16/playingSpeed));
  else
    speedButton.getCaptionLabel().setText("x " + str(playingSpeed/16));
}

void fasterSpeed(int __) {
  setSpeed(playingSpeed << 1);
}

void slowerSpeed(int __) {
  setSpeed(playingSpeed >> 1);
}

void resetSpeed(int __) {
  setSpeed(1 << 4);
}
