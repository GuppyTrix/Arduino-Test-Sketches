# General information about the Waveshare-ESP32-S3-DEV-KIT-N8R8

ESP32-S3-DEV-KIT-N8R8 – Uses ESP32-S3-WROOM-1 module with 8 MB Flash memory and 8 MB PSRAM.

> [!CAUTION]
> The following GPIO pins are not available for use as they are used internally by the board:
>
> - GPIO35 (SPID for flash memory)
> - GPIO36 (SPICLK_N for flash memory)
> - GPIO37 (SPICLK_P for flash memory)
>
> The following pins should not be used under regular circumstances only use if you know what you are doing:
>
> - GPIO0 (Boot mode selection)
> - GPIO 19 & 20 (USB D+ and D- lines)
> - GPIO38 (Drives the built-in RGB LED)
> - GPIO45 (Strapping pin)
> - GPIO46 (Strapping pin)
>
> This leaves us with 34 usable GPIO pins which is still a lot for most projects.
>
> When using WiFi, A10~A17 cannot be used leaving only 26 usable GPIO pins.

## Pinout and features

[waveshare website](https://www.circuitstate.com/pinouts/waveshare-esp32-s3-dev-kit-nxr8-wi-fi-development-board-pinout-diagram-arduino-reference/#google_vignette).

I have saved a ESP32-S3-DEV-KIT-N8R8 [pinout PDF](https://www.waveshare.com/w/upload/7/7b/ESP32-S3-DevKitC-1-pinout.pdf) which shows my board's pinout and the respective functions of each pin.
I have also saved a [pinout table](ESP32-S3-Consolidated-Pinout-Table.png) which was taken from the waveshare website

Key features include:

- GPIOs 22~25 are not available from the chip.
- TX0 and RX0 can be accessed as Serial0 in Arduino.
- USB-CDC can be accessed as Serial in Arduino.
- Both Serial and Serial0 can be used for programming.
- All GPIO pins support PWM and interrupts.
- Built-in RGB LED is connected to GPIO38.
- Arduino pin references are as per ESP32-S3_DevKitC-1 definition.
- All touch input pins can be used as T1~T14 in Arduino.
- Most peripheral functions can be assigned to any GPIO pins, thanks to the IO MUX.

## JTAG

JTAG (Joint Test Action Group) is a standard interface used for programming and debugging microcontrollers. ESP32-S3 supports JTAG programming and debugging. JTAG has four main signals and an optional reset line. You can use supported debuggers like the ESP-Prog to debug your ESP chips.

| Pin Name | GPIO | Function         |
| -------- | ---- | ---------------- |
| MTDI     | 41   | Test Data In     |
| MTCK     | 39   | Test Clock       |
| MTMS     | 42   | Test Mode Select |
| MTDO     | 40   | Test Data Out    |

## External Interrupts

ESP32-S3 supports external interrupts on all GPIO pins. The interrupt types can be level-triggered, edge-triggered, or state change

## I2C

There are two I2C peripherals inside the ESP32-S3. I2C is also called as Two Wire Interface (TWI). Similar to UART and SPI, I2C pins can also be mapped to any GPIO pin. There are two I2C interfaces defined for Arduino; Wire (I2C0) and Wire1 (I2C1) but only Wire has the pins defined. You need to manually set the pins for Wire1.

| Arduino Instance | I2C  | SDA | SCL |
| ---------------- | ---- | --- | --- |
| Wire             | I2C0 | 8   | 9   |
| Wire1            | I2C1 | –   | –   |

## PWM

ESP32-S3 supports up to 8 independent PWM (Pulse Width Modulation) channels with 14-bit precision. PWM outputs can be mapped to any GPIO pin that supports output mode.

## ADC

Analog to Digital Converters (ADC) are used to convert analog voltages to discrete digital values. There are two 12-bit SAR ADCs available in the ESP32-S3 with 20 input channels. Following is the list of ADC channels and their Arduino instances.

| Arduino Pin | ADC Channel | GPIO | Usable?     |
| ----------- | ----------- | ---- | ----------- |
| A0          | ADC1_0      | 1    | YES         |
| A1          | ADC1_1      | 2    | YES         |
| A2          | ADC1_2      | 3    | YES         |
| A3          | ADC1_3      | 4    | YES         |
| A4          | ADC1_4      | 5    | YES         |
| A5          | ADC1_5      | 6    | YES         |
| A6          | ADC1_6      | 7    | YES         |
| A7          | ADC1_7      | 8    | YES         |
| A8          | ADC1_8      | 9    | YES         |
| A9          | ADC1_9      | 10   | YES         |
| A10         | ADC2_0      | 11   | YES         |
| A11         | ADC2_1      | 12   | YES         |
| A12         | ADC2_2      | 13   | YES         |
| A13         | ADC2_3      | 14   | YES         |
| A14         | ADC2_4      | 15   | YES         |
| A15         | ADC2_5      | 16   | YES         |
| A16         | ADC2_6      | 17   | YES         |
| A17         | ADC2_7      | 18   | YES         |
| A18         | ADC2_8      | 19   | NO (USB D-) |
| A19         | ADC2_9      | 20   | NO (USB D+) |

> [!NOTE]
> All pins labeled ADC2_x cannot be used if you are using WiFi. This means A10~A17 cannot be used if you are using WiFi. A18-A19 cannot be used at all as they are used for USB D- and D+ lines.

## Strapping

Every ESP32-S3 chip has a bootloader inside the Read-Only-Memory (ROM) which is a program that monitors the state of the chip when you power it on. The pins monitored by the bootloader are called strapping pins. There are four strapping pins in the ESP32-S3. These strapping pins exhibit other behaviours during the booting process. So you should be careful not to interfere with the pins. Following is the list of strapping pins and their default states. It is recommended to not use these in normal situations.

| Strapping  Pin | Default Configuration | Bit Value |
| -------------- | --------------------- | --------- |
| GPIO0          | Weak  pull-up         | 1         |
| GPIO3          | Floating              | –         |
| GPIO45         | Weak  pull-down       | 0         |
| GPIO46         | Weak  pull-down       | 0         |

## USB

| GPIO   | USB |
| ------ | --- |
| GPIO20 | D-  |
| GPIO21 | D+  |

## UART

ESP32-S3 has three UARTs inside (asynchronous only) with hardware and software flow control. The UARTs are named UART0, UART1, and UART2

| Arduino Instance | UART  | RX pin | TX pin | CTS    | RTS    |
| ---------------- | ----- | ------ | ------ | ------ | ------ |
| Serial           | UART0 | GPIO20 | GPIO21 | GPIO22 | GPIO23 |
| Serial1          | UART1 | GPIO34 | GPIO35 | GPIO36 | GPIO37 |
| Serial2          | UART2 | GPIO16 | GPIO17 | GPIO18 | GPIO19 |

## SPI

There are four SPI peripheral blocks inside the ESP32-S3. SPI0 and SPI1 have special functions including communicating with the flash memory and therefore we can't use them. SPI2 (GP-SPI2) and SPI3 (GP-SPI3) are general-purpose SPI interfaces called FSPI and HSPI respectively. Similar to the UART, SPI functions can be mapped to any GPIO pin. Below we have the default pins and their respective Arduino instances.

| Arduino Instance | SPI  | COPI | CIPO | SCK | CS  |
| ---------------- | ---- | ---- | ---- | --- | --- |
| SPI2             | FSPI | –    | –    | –   | –   |
| SPI3             | HSPI | 11   | 13   | 12  | 10  |

## I2S

Inter-Integrated Sound (I2S) is a digital audio interface supported by the ESP32-S3. I2S pin functions can also be mapped to any GPIO pins.

## Touch Sensor

There are 14 capacitive touch channels in the ESP32-S3. Each touch channel can be used as a touch sensor or as a regular GPIO pin. The touch channels are mapped to specific GPIO pins, and they can be accessed in Arduino using the T1~T14 instances.

| Arduino Pin | Touch Channel | GPIO | Usable? |
| ----------- | ------------- | ---- | ------- |
| T1          | TOUCH1        | 1    | YES     |
| T2          | TOUCH2        | 2    | YES     |
| T3          | TOUCH3        | 3    | YES     |
| T4          | TOUCH4        | 4    | YES     |
| T5          | TOUCH5        | 5    | YES     |
| T6          | TOUCH6        | 6    | YES     |
| T7          | TOUCH7        | 7    | YES     |
| T8          | TOUCH8        | 8    | YES     |
| T9          | TOUCH9        | 9    | YES     |
| T10         | TOUCH10       | 10   | YES     |
| T11         | TOUCH11       | 11   | YES     |
| T12         | TOUCH12       | 12   | YES     |
| T13         | TOUCH13       | 13   | YES     |
| T14         | TOUCH14       | 14   | YES     |
