#include <user_config.h>
#include <SmingCore/SmingCore.h>

#include "autoconf.h"

#define ROM_0_URL "http://" CONFIG_RBOOT_OTA_HOST "/" CONFIG_SMING_RBOOT_ROM_0 ".bin"
#ifdef RBOOT_TWO_ROMS
#define ROM_1_URL "http://" CONFIG_RBOOT_OTA_HOST "/" CONFIG_SMING_RBOOT_ROM_1 ".bin"
#endif

rBootHttpUpdate* otaUpdater = 0;

void OtaUpdate_CallBack(rBootHttpUpdate& client, bool result)
{
	Serial.println("In callback...");
	if(result == true) {
		// success
		uint8 slot;
		slot = rboot_get_current_rom();
		if(slot == 0)
			slot = 1;
		else
			slot = 0;
		// set to boot new rom and then reboot
		Serial.printf("Firmware updated, rebooting to rom %d...\n", slot);
		rboot_set_current_rom(slot);
		System.restart();
	} else {
		// fail
		Serial.println("Firmware update failed!");
	}
}

void OtaUpdate()
{
	uint8 slot;
	rboot_config bootconf;

	Serial.println("Updating...");

	// need a clean object, otherwise if run before and failed will not run again
	if(otaUpdater)
		delete otaUpdater;
	otaUpdater = new rBootHttpUpdate();

	// select rom slot to flash
	bootconf = rboot_get_config();
	slot = bootconf.current_rom;
	if(slot == 0)
		slot = 1;
	else
		slot = 0;

#ifndef RBOOT_TWO_ROMS
	// flash rom to position indicated in the rBoot config rom table
	otaUpdater->addItem(bootconf.roms[slot], ROM_0_URL);
#else
	// flash appropriate rom
	if(slot == 0) {
		otaUpdater->addItem(bootconf.roms[slot], ROM_0_URL);
	} else {
		otaUpdater->addItem(bootconf.roms[slot], ROM_1_URL);
	}
#endif

	// request switch and reboot on success
	//otaUpdater->switchToRom(slot);
	// and/or set a callback (called on failure or success without switching requested)
	otaUpdater->setCallback(OtaUpdate_CallBack);

	// start update
	otaUpdater->start();
}

void Switch()
{
	uint8 before, after;
	before = rboot_get_current_rom();
	if(before == 0)
		after = 1;
	else
		after = 0;
	Serial.printf("Swapping from rom %d to rom %d.\n", before, after);
	rboot_set_current_rom(after);
	Serial.println("Restarting...\n");
	System.restart();
}

void ShowInfo()
{
	Serial.printf("\nSDK: v%s\n", system_get_sdk_version());
	Serial.printf("Free Heap: %d\n", system_get_free_heap_size());
	Serial.printf("CPU Frequency: %d MHz\n", system_get_cpu_freq());
	Serial.printf("System Chip ID: %x\n", system_get_chip_id());
	Serial.printf("SPI Flash ID: %x\n", spi_flash_get_id());
	//Serial.printf("SPI Flash Size: %d\n", (1 << ((spi_flash_get_id() >> 16) & 0xff)));

	rboot_config conf;
	conf = rboot_get_config();

	debugf("Count: %d", conf.count);
	debugf("ROM 0: %d", conf.roms[0]);
	debugf("ROM 1: %d", conf.roms[1]);
	debugf("ROM 2: %d", conf.roms[2]);
	debugf("GPIO ROM: %d", conf.gpio_rom);
}

void serialCallBack(Stream& stream, char arrivedChar, unsigned short availableCharsCount)
{
	int pos = stream.indexOf('\n');
	if(pos > -1) {
		char str[pos + 1];
		for(int i = 0; i < pos + 1; i++) {
			str[i] = stream.read();
			if(str[i] == '\r' || str[i] == '\n') {
				str[i] = '\0';
			}
		}

		if(!strcmp(str, "connect")) {
			// connect to wifi
			WifiStation.config(CONFIG_WIFI_SSID, CONFIG_WIFI_PWD);
			WifiStation.enable(true);
			WifiStation.connect();
		} else if(!strcmp(str, "ip")) {
			Serial.printf("ip: %s mac: %s\n", WifiStation.getIP().toString().c_str(), WifiStation.getMAC().c_str());
		} else if(!strcmp(str, "ota")) {
			OtaUpdate();
		} else if(!strcmp(str, "switch")) {
			Switch();
		} else if(!strcmp(str, "restart")) {
			System.restart();
		} else if(!strcmp(str, "info")) {
			ShowInfo();
		} else if(!strcmp(str, "help")) {
			Serial.println();
			Serial.println("available commands:");
			Serial.println("  help - display this message");
			Serial.println("  ip - show current ip address");
			Serial.println("  connect - connect to wifi");
			Serial.println("  restart - restart the esp8266");
			Serial.println("  switch - switch to the other rom and reboot");
			Serial.println("  ota - perform ota update, switch rom and reboot");
			Serial.println("  info - show esp8266 info");
			Serial.println();
		} else {
			Serial.println("unknown command");
		}
	}
}

void init(void)
{
	Serial.begin(SERIAL_BAUD_RATE); // 115200 by default
	Serial.systemDebugOutput(true); // Debug output to serial

	WifiAccessPoint.enable(false);

	Serial.printf("\nI am " CONFIG_THING_NAME ", revision " VERSION "\n");
	Serial.printf("Current ROM slot %d\n", rboot_get_current_rom());
	Serial.println();

	Serial.setCallback(serialCallBack);
}
