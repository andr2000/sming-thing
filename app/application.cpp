#include <user_config.h>
#include <SmingCore/SmingCore.h>

#include "autoconf.h"

void init(void)
{
	Serial.begin(SERIAL_BAUD_RATE); // 115200 by default
	Serial.systemDebugOutput(true); // Debug output to serial

	Serial.printf("I am " CONFIG_THING_NAME ", revision " VERSION "\n");
	Serial.printf("Current ROM slot %d\n", rboot_get_current_rom());
	Serial.println();
}
