import processing.video.*;
import controlP5.*;
import uibooster.*;
import java.util.Optional;

ControlP5 cp5;
Movie movie;

final int toolbar_height = 40;
final int seekbar_height = 20;

final String movieFile = "MOV_0017.mp4";

final int v_w = 640;
final int v_h = 480;

boolean isPlaying = false;

boolean manualSlider = false;

Toggle playToggle;
Slider seekSlider;

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

  UiBooster booster = new UiBooster();
  Optional<File> file = Optional.ofNullable(booster.showFileSelection());

  if(!file.isPresent()){
    println("No file selected!");
    exit();
    return;
  }

  file.orElseThrow();

  nextX += 20;


  movie = new Movie(this, file.get().getPath());
  movie.loop();


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

}

void draw() {
  background(10);

  image(movie, 0, toolbar_height);

  manualSlider = false;
  seekSlider.setValue(movie.time());

  if (isPlaying)
    movie.play();
  else
    movie.pause();
}

// Read new frames from the movie.
void movieEvent(Movie movie) {
  movie.read();
}

// Called when any control is pressed
public void controlEvent(ControlEvent theEvent) {
  println(theEvent.getController().getName());
}

// Automagically called when toggle is pressed
public void playTogglePress(boolean state) {
  if (playToggle != null)
    playToggle.getCaptionLabel().setText(state ? "pause" : "play");

  isPlaying = state;
}

void seekSliderChange(float val){
  if(!manualSlider){
    manualSlider = true;
    return;
  }


  if(movie != null){
    movie.jump(int(val));
  }

  image(movie, 0, toolbar_height);
}
