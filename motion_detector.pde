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

boolean isPlaying = false;

boolean manualSlider = false;

boolean autoPause = false;

Toggle playToggle;
Toggle autoPauseToggle;
Slider seekSlider;
Slider tresholdSlider;
Slider tresholdSizeSlider;


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
    .setValue(threshold);

  tresholdSlider.getCaptionLabel().setText("threshold");  
  
  nextX += 80+10;

  
  tresholdSlider = cp5.addSlider("tresholdSizeSliderChange")
    .setPosition(nextX, 0)
    .setSize(80, toolbar_height)
    .setRange(0, 300)
    .setValue(threshold);

  tresholdSlider.getCaptionLabel().setText("min detect size");

  nextX += 80+10;


  // add a seek slider
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
    
    
  autoPauseToggle = cp5.addToggle("toggleAutoPause")
     .setPosition(nextX, 0)
     .setSize(50, toolbar_height/2)
     .setValue(false)
     .setMode(ControlP5.SWITCH);
     
     
  autoPauseToggle.getCaptionLabel().setText("Pause on detection");
     
  nextX += 50+10;
     
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
  for (int x = 0; x < movie.width; x++ ) {
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
    if (bb.minX < bb.maxY && bb.minY < bb.maxY)
      rect((float)bb.minX, (float)bb.minY, (float)bb.maxX, (float)bb.maxY);
      
    if (autoPause)
      playTogglePress(false);
  }



  manualSlider = false;
  seekSlider.setValue(movie.time());

  if (isPlaying)
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
}

// Called when any control is pressed
public void controlEvent(ControlEvent theEvent) {
  //println(theEvent.getController().getName());
}

// Automagically called when toggle is pressed
public void playTogglePress(boolean state) {
  if (playToggle != null)
    playToggle.getCaptionLabel().setText(state ? "pause" : "play");

  isPlaying = state;
}

void tresholdSliderChange(float val) {
  threshold = val;
}

void tresholdSizeSliderChange(float val) {
  thresholdSize = int(val);
}

void toggleAutoPause(boolean state){
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
