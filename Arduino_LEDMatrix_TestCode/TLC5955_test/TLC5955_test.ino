/*
   TLC5955 Control Library
   Used to control the TI TLC5955 LED driver chip
   Zack Phillips - zkphil@berkeley.edu
   Product Page: http://www.ti.com/product/tlc5955
   Copyright (c) 2018, Zachary F. Phillips
   All rights reserved.
   Redistribution and use in source and binary forms, with or without
   modification, are permitted provided that the following conditions are met:
   Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
   Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
   Neither the name of the <organization> nor the
      names of its contributors may be used to endorse or promote products
      derived from this software without specific prior written permission.
   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
   ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
   WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
   DISCLAIMED. IN NO EVENT SHALL Z. PHILLIPS BE LIABLE FOR ANY
   DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
   (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
   LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
   ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
   (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
   SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#include "TLC5955.h"
#include "SPI.h"


// Pin set-up
#define GSCLK 24
#define LAT 29
#define SPI_CLK 13
#define SPI_MOSI 11

#define num_modes 4
#define ALL_BRIGHT 1
#define ALL_LEDS_ITERATE_COLORS 2 // code to iterate through each color and show each color on all LEDs at once
#define ITERATE_LEDS_ITERATE_COLORS 3 // code to update each led on each driver one by one, color by color
#define ALL_DIM 4



int mode = ALL_BRIGHT;
int delay_amnt = 50;


const uint8_t TLC5955::chip_count = 2;          // Change to reflect number of TLC chips
float TLC5955::max_current_amps = 10;      // Maximum current output, amps
bool TLC5955::enforce_max_current = false;   // Whether to enforce max current limit

// Define dot correction, pin rgb order, and grayscale data arrays in program memory
uint8_t TLC5955::_dc_data[TLC5955::chip_count][TLC5955::LEDS_PER_CHIP][TLC5955::COLOR_CHANNEL_COUNT];
uint8_t TLC5955::_rgb_order[TLC5955::chip_count][TLC5955::LEDS_PER_CHIP][TLC5955::COLOR_CHANNEL_COUNT];
uint16_t TLC5955::_grayscale_data[TLC5955::chip_count][TLC5955::LEDS_PER_CHIP][TLC5955::COLOR_CHANNEL_COUNT];

// Create TLC5955 object
TLC5955 tlc;

int led_lookup[16] = 
  { 7, // 1 on PCB
    3, // 2 on PCB
    11, // 3 on PCB
    15, // 4 on PCB
    6, // 5 on PCB
    2, // 6
    10, // 7
    14, // 8
    1, // 9
    5, // 10
    13, // 11
    9, // 12
    4, // 13
    0, // 14
    12, // 15
    8, // 16
  };

  
void setup() {
  Serial.begin(9600);

  
  // Set pins (non-serial) to output mode
  pinMode(GSCLK, OUTPUT);
  pinMode(LAT, OUTPUT);

  // Adjust PWM timer for maximum GSCLK frequency
  analogWrite(GSCLK, 127);
  
  // The library does not ininiate SPI for you, so as to prevent issues with other SPI libraries
  SPI.begin();
//  SPI.setClockDivider(SPI_CLOCK_DIV2);
  tlc.init(LAT, SPI_MOSI, SPI_CLK, GSCLK);

  // We must set dot correction values, so set them all to the brightest adjustment
  tlc.set_all_dc_data(127);

  // Set Max Current Values (see TLC5955 datasheet)
  tlc.set_max_current(0, 0, 0); // Go up to 7

  // Set Function Control Data Latch values. See the TLC5955 Datasheet for the purpose of this latch.
  // Order: DSPRPT, TMGRST, RFRESH, ESPWM, LSDVLT
  tlc.set_function_data(true, true, false, true, true);

//  // set all brightness levels to max (127)
  int currentR = 127;
  int currentB = 127;
  int currentG = 127;
//  tlc.set_brightness_current(currentR, currentB, currentG);
  tlc.set_brightness_current(30);

  // Update Control Register
  tlc.update_control();

  // Provide LED pin order (R,G,B)
  tlc.set_rgb_pin_order(0, 1, 2);
//
//  Serial.print("Enter starting mode: ");
//  while(Serial.available() == 0) {}
//  if (Serial.available() > 0)
//    mode = Serial.parseInt();
//  Serial.println();
//  switch (mode) {
//    case ALL_DIM:
//      Serial.println("Mode selected: ALL_DIM");
//      break;
//    case ALL_BRIGHT:
//      Serial.println("Mode selected: ALL_BRIGHT");
//      break;
//    case ALL_LEDS_ITERATE_COLORS:
//      Serial.println("Mode selected: ALL_LEDS_ITERATE_COLORS");
//      break;
//    case ITERATE_LEDS_ITERATE_COLORS:
//      Serial.println("Mode selected: ITERATE_LEDS_ITERATE_COLORS");
//      break;
//    default:
//      Serial.print("Mode selected: ");
//      Serial.println(mode);
//      break;
//  }
//  

}

void loop() {
//  if (Serial.available()) {
//    mode = Serial.parseInt();
//    switch (mode) {
//      case ALL_DIM:
//        Serial.println("Mode selected: ALL_DIM");
//        break;
//      case ALL_BRIGHT:
//        Serial.println("Mode selected: ALL_BRIGHT");
//        break;
//      case ALL_LEDS_ITERATE_COLORS:
//        Serial.println("Mode selected: ALL_LEDS_ITERATE_COLORS");
//        break;
//      case ITERATE_LEDS_ITERATE_COLORS:
//        Serial.println("Mode selected: ITERATE_LEDS_ITERATE_COLORS");
//        break;
//      default:
//        Serial.print("Mode selected: ");
//        Serial.println(mode);
//        break;
//    }
//  }
  
  for (int mode = 1; mode < num_modes+1; mode++) {
    
    int overall_brightness = 65535;
    switch (mode) {
      case ALL_DIM:
        tlc.set_all(100);
        tlc.update();
        delay(delay_amnt*20);
        break;
      case ALL_BRIGHT:
        tlc.set_all(65535);
        tlc.update();
        delay(delay_amnt*20);
        break;
      case ALL_LEDS_ITERATE_COLORS:
        // code to iterate through each color and show each color on all LEDs at once
        for (int color_channel = 0; color_channel < 3; color_channel++) {
          // wait for keypress before changing to next color
          //    while(Serial.available() == 0) {
          //    }
          //    int mydata = Serial.read();
          
          tlc.set_all_rgb(0,0,0);
          for (int led = 0; led < 16; led++) {
            switch (color_channel) {
              case 0:
                tlc.set_all_rgb(overall_brightness,0,0);
                break;
              case 1:
                tlc.set_all_rgb(0,overall_brightness,0);
                break;
              case 2:
                tlc.set_all_rgb(0,0,overall_brightness);
                break;
              default:
                tlc.set_all_rgb(0,0,0);
                break;
            }
          }
          tlc.update();
          delay(delay_amnt*10);
        }
        break;
      case ITERATE_LEDS_ITERATE_COLORS:  
        // code to update each led on each driver one by one, color by color
        for (int color_channel = 0; color_channel < 3; color_channel++) {
          for (int led = 0; led < 16; led++) {
  //          Serial.print("Color channel: ");
  //          Serial.println(color_channel);
  //          Serial.print("LED: ");
  //          Serial.println(led);
  //          Serial.println();
            tlc.set_all_rgb(0,0,0);
            tlc.set_single_rgb(led_lookup[led],color_channel,128*200);
            tlc.set_single_rgb(led_lookup[led]+16,color_channel,128*200);
            tlc.update();
            delay(delay_amnt);
          }
        }
        break;
      default:
        tlc.set_all(0);
        tlc.update();
        delay(delay_amnt);
        break;
    }
  }
}
