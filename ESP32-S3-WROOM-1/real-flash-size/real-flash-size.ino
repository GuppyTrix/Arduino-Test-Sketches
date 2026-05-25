#include <rp2040_pio.h>

#include <FreeRTOS.h>
#include <Arduino.h>

static String getUploadFlashSizeSetting()
{
#ifdef ARDUINO_FQBN
    const char *flashSizeKey = "FlashSize=";
    const char *flashSizeStart = strstr(ARDUINO_FQBN, flashSizeKey);
    if (!flashSizeStart)
    {
        return "unknown";
    }

    flashSizeStart += strlen(flashSizeKey);
    const char *flashSizeEnd = strchr(flashSizeStart, ',');
    if (!flashSizeEnd)
    {
        return String(flashSizeStart);
    }

    return String(flashSizeStart).substring(0, flashSizeEnd - flashSizeStart);
#else
    return "unknown";
#endif
}

void setup()
{    
    Serial.begin(115200);
    while (!Serial) delay(10);

    const uint32_t flashChipBytes = ESP.getFlashChipSize();
    const String uploadFlashSize = getUploadFlashSizeSetting();

    Serial.println("================================");
    Serial.println("      Flash size report");
    Serial.println("================================");

    printf("Upload flash size setting: %s\n", uploadFlashSize.c_str());
    printf("Detected flash chip size: %u bytes (%u MB)\n", flashChipBytes, flashChipBytes / (1024 * 1024));
}

void loop()
{
    Serial.println("Looping...");
    delay(5000);
}