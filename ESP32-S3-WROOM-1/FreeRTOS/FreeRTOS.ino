#include <Arduino.h>
#include <FreeRTOS.h>
#include <task.h>


#define POT_PIN 34
#define LED_BUILTIN 38

static uint32_t angle;

static void tas_pot_servo(void){
    angle = analogRead(POT_PIN) * 180/4096;
}

static void task_led(void){
    while(1){
        digitalWrite(LED_BUILTIN, HIGH);
        vTaskDelay(1000);
        digitalWrite(LED_BUILTIN, LOW);
        vTaskDelay(1000);
    }
}

static void task_display(void){
    while(1){
        Serial.print("Angle: ");
        Serial.println(angle);
        vTaskDelay(1000);
    }
}

static void task_uart(void){
    while(1){
        Serial.println("UART Task");
        vTaskDelay(1000);
    }
}

void setup()
{
    init();
    Serial.begin(115200);
    pinMode(POT_PIN, INPUT);
    pinMode(LED_BUILTIN, OUTPUT);

    xTaskCreate(task_led,      "LED",      128, NULL, 1, NULL);
    xTaskCreate(task_display,  "Display",  128, NULL, 1, NULL);
    xTaskCreate(tas_pot_servo, "PotServo", 128, NULL, 1, NULL);
    xTaskCreate(task_uart,     "UART",     128, NULL, 1, NULL);

    vTaskStartScheduler();
}

void loop()
{
}