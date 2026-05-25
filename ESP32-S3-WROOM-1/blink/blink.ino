/**
 * The onboard WS2812B RGB LED is connected to GPIO38. 
 * Since this is serial RGB LED, a compatible library 
 * to drive it is the Adafruit Neopixel library.
 */

#include <Arduino.h>
#include <Adafruit_NeoPixel.h>

#define RGB_LED_PIN 38
#define RGB_BRIGHTNESS 50
Adafruit_NeoPixel grbLed(1, RGB_LED_PIN, NEO_GRB + NEO_KHZ800);

void setup()
{
    Serial.begin(115200);
    while (!Serial) delay(10);
    Serial.println("Setup complete");
    grbLed.begin();
    grbLed.setBrightness(RGB_BRIGHTNESS);
}

void loop()
{   
    delay(1000);
    grbLed.setPixelColor(0, grbLed.Color(0, 255, 0)); // Red
    grbLed.show();
    delay(1000);
    grbLed.setPixelColor(0, grbLed.Color(255, 0, 0)); // Green
    grbLed.show();
    delay(1000);
    grbLed.setPixelColor(0, grbLed.Color(0, 0, 255)); // Blue
    grbLed.show();
}