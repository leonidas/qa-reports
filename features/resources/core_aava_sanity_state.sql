INSERT INTO "meego_test_suites" VALUES(1,1,'','',NULL);
INSERT INTO "meego_test_sets" VALUES(1,1,'','','','Create Image',NULL);
INSERT INTO "meego_test_sets" VALUES(2,1,'','','','System startup',NULL);
INSERT INTO "meego_test_sets" VALUES(3,1,'','','','Home screen',NULL);
INSERT INTO "meego_test_sets" VALUES(4,1,'','','','Fennec browser',NULL);
INSERT INTO "meego_test_sets" VALUES(5,1,'','','','Dialer',NULL);
INSERT INTO "meego_test_sets" VALUES(6,1,'','','','SMS',NULL);
INSERT INTO "meego_test_sets" VALUES(7,1,'','','','Connectivity',NULL);
INSERT INTO "meego_test_sets" VALUES(8,1,'','','','Run time status/Settings/Control Panel',NULL);
INSERT INTO "meego_test_sets" VALUES(9,1,'','','','Virtual keyboard',NULL);
INSERT INTO "meego_test_sets" VALUES(10,1,'','','','Photo viewer',NULL);
INSERT INTO "meego_test_sets" VALUES(11,1,'','','','Audio',NULL);
INSERT INTO "meego_test_sets" VALUES(12,1,'','','','Video',NULL);
INSERT INTO "meego_test_sets" VALUES(13,1,'','','','Contacts',NULL);
INSERT INTO "meego_test_sets" VALUES(14,1,'','','','Security & Power',NULL);
INSERT INTO "meego_test_sets" VALUES(15,1,'','','','Touchscreen',NULL);
INSERT INTO "meego_test_sets" VALUES(16,1,'','','','Device Battery charging',NULL);
INSERT INTO "meego_test_sets" VALUES(17,1,'','','','Installation',NULL);
INSERT INTO "meego_test_cases" VALUES(1,1,'Create image with MIC2','','t','f',1,'','',NULL,1);
INSERT INTO "meego_test_cases" VALUES(2,2,'Image boot from SD card','','t','f',-1,'','5705- [REG] Unable to display home screen automatically unless tapping the screen',NULL,1);
INSERT INTO "meego_test_cases" VALUES(3,3,'Check if core applications* (Dialer, SMS, fennec browser, photo viewer, audio player, video player, contacts, email, Terminal) can be launched from app-launcher','','t','f',-1,'','[[5856]] [[3551]] [[3551]]',NULL,1);
INSERT INTO "meego_test_cases" VALUES(4,3,'Switch between different applications','','t','f',1,'','',NULL,1);
INSERT INTO "meego_test_cases" VALUES(5,3,'Check home screen theme and layout','','t','f',-1,'','[[3921]]',NULL,1);
INSERT INTO "meego_test_cases" VALUES(6,3,'Display orientation detection','','t','f',1,'','',NULL,1);
INSERT INTO "meego_test_cases" VALUES(7,4,'Open 2 tabs to surf 2 websites contains flash plugin','','t','f',1,'','',NULL,1);
INSERT INTO "meego_test_cases" VALUES(8,4,'Browsing website over 3G (WCDMA)','','t','f',0,'','Not support in meego 1.1 release.',NULL,1);
INSERT INTO "meego_test_cases" VALUES(9,4,'Browser gesture support','','t','f',1,'','[[4021]]',NULL,1);
INSERT INTO "meego_test_cases" VALUES(10,5,'Dial one outgoing call, accept by other party, terminate this call (phonesim, GSM & WCDMA) (GSM and WCDMA cannot be covered until real modem supported,Will use phonesim to test before real modem support)','','t','f',-1,'','Bug 5856- - Launching dialer fails',NULL,1);
INSERT INTO "meego_test_cases" VALUES(11,5,'Receive a call, accept the call, terminate this call (phonesim, GSM & WCDMA) (GSM and WCDMA cannot be covered until real modem supported,Will use phonesim to test before real modem support)','','t','f',0,'','SIM function is not implemented yet.',NULL,1);
INSERT INTO "meego_test_cases" VALUES(12,5,'Receive one call, reject this call without accepting the call(phonesim, GSM & WCDMA)(GSM and WCDMA cannot be covered until real modem supported,Will use phonesim to test before real modem support)','','t','f',0,'','SIM function is not implemented yet.',NULL,1);
INSERT INTO "meego_test_cases" VALUES(13,5,'Display PhoneBook','','t','f',-1,'','[[5856]]',NULL,1);
INSERT INTO "meego_test_cases" VALUES(14,5,'Check call history','','t','f',-1,'','[[5856]]',NULL,1);
INSERT INTO "meego_test_cases" VALUES(15,6,'Send SMS ( phonesim, 2G & 3G ) (2G and 3G cannot be covered until real modem supported,Will use phonesim to test before real modem support)','','t','f',1,'','SMS application can be launched and SMS can be composed, SIM function is not implemented to test send/receive message function.',NULL,1);
INSERT INTO "meego_test_cases" VALUES(16,6,'Receive SMS ( phonesim, 2G & 3G ) (2G and 3G cannot be covered until real modem supported,Will use phonesim to test before real modem support)','','t','f',0,'','SMS application can be launched and SMS can be composed . SIM function is not implemented to test send/receive function.',NULL,1);
INSERT INTO "meego_test_cases" VALUES(17,6,'Check message history (received, sent, draft)','','t','f',-1,'','[[3670]]',NULL,1);
INSERT INTO "meego_test_cases" VALUES(18,7,'Scan wifi, check wifi connection (open/wep/wpa) and disconnection','','t','f',-1,'','[[3291]]',NULL,1);
INSERT INTO "meego_test_cases" VALUES(19,7,'Browse website and download some files through wifi','','t','f',1,'','Mp3 file can be downloaced but can not be played',NULL,1);
INSERT INTO "meego_test_cases" VALUES(20,7,'Check if wifi On/Off works','','t','f',-1,'','[[Bug 811]]',NULL,1);
INSERT INTO "meego_test_cases" VALUES(21,7,'Check bluetooth connection (pairing and connect to bluetooth handset)','','t','f',-1,'','Sometimes Bluetooth settings displayed properly and could be paired, but most of the time it was not displayed properly. [[5790]]',NULL,1);
INSERT INTO "meego_test_cases" VALUES(22,7,'Connect device to computer with usb cable, check the usb mass storage device is detected by computer','','t','f',1,'','Device could be detected after running "insmod g_file_storage.ko file=/dev/mmcblk0p1".',NULL,1);
INSERT INTO "meego_test_cases" VALUES(23,7,'Check sshd connection: connect board using usb gadget','','t','f',-1,'','Blocked by[6360]]',NULL,1);
INSERT INTO "meego_test_cases" VALUES(24,8,'Check if runtime status are correct on tiny toolbar/runtime status panel','','t','f',-1,'','[[5301]]',NULL,1);
INSERT INTO "meego_test_cases" VALUES(25,8,'Check if volume could be adjusted','','t','f',0,'','',NULL,1);
INSERT INTO "meego_test_cases" VALUES(26,8,'Check if time/date could be updated','','t','f',0,'','',NULL,1);
INSERT INTO "meego_test_cases" VALUES(27,8,'Check if phone setting mode (offline, etc) could be updated','','t','f',0,'','',NULL,1);
INSERT INTO "meego_test_cases" VALUES(28,9,'Check if virtual keyboard can be launched automatically with apps which need input text field (fennec, SMS)','','t','f',1,'','VKB launched successful.',NULL,1);
INSERT INTO "meego_test_cases" VALUES(29,9,'Support text input','','t','f',-1,'','[[6017]]',NULL,1);
INSERT INTO "meego_test_cases" VALUES(30,10,'Check if the UI is correct (top bar, menu, button, etc.)','','t','f',1,'','',NULL,1);
INSERT INTO "meego_test_cases" VALUES(31,10,'Check if photo thumbnail index works','','t','f',1,'','After tapped "All Photos", "Albums" etc buttons, correspond picture thumnails can be displayed.',NULL,1);
INSERT INTO "meego_test_cases" VALUES(32,10,'Check if photo could be played','','t','f',1,'','',NULL,1);
INSERT INTO "meego_test_cases" VALUES(33,11,'Check if the UI is correct (top bar, menu, button, play queue etc.)','','t','f',-1,'','[[6558]]',NULL,1);
INSERT INTO "meego_test_cases" VALUES(34,11,'Check if music could be played (WAV, AAC & MP3 format ) on loudspeaker (play music by command line if audio player is not ready. aplay to play music file)','','t','f',-1,'','[[6782]]',NULL,1);
INSERT INTO "meego_test_cases" VALUES(35,12,'Check if the UI is correct (top bar, menu, button, play queue etc.)','','t','f',1,'','',NULL,1);
INSERT INTO "meego_test_cases" VALUES(36,12,'Check if video thumbnail index works','','t','f',0,'','Unable to copy video clips to device, for openssh-server installation was blocked by[6360]]',NULL,1);
INSERT INTO "meego_test_cases" VALUES(37,12,'Check if video could be played (MP4, WMV & 3GP-H264)','','t','f',-1,'','Unable to copy video clips to device, for openssh-server installation was blocked by[6360]]',NULL,1);
INSERT INTO "meego_test_cases" VALUES(38,13,'Check if it works with dialer, SMS','','t','f',1,'','',NULL,1);
INSERT INTO "meego_test_cases" VALUES(39,14,'Check PIN activation/deactivation (Need GUI support)','','t','f',0,'','',NULL,1);
INSERT INTO "meego_test_cases" VALUES(40,14,'PIN requested at boot','','t','f',0,'','',NULL,1);
INSERT INTO "meego_test_cases" VALUES(41,14,'Power Off / Power On','','t','f',-1,'','[[2090]]',NULL,1);
INSERT INTO "meego_test_cases" VALUES(42,15,'Use touch screen to operate the system','','t','f',-1,'','',NULL,1);
INSERT INTO "meego_test_cases" VALUES(43,16,'Charging with Normal USB charger','','t','f',1,'','',NULL,1);
INSERT INTO "meego_test_cases" VALUES(44,16,'Charging with USB(OTG) cable','','t','f',-1,'','[[2260]]',NULL,1);
INSERT INTO "meego_test_cases" VALUES(45,17,'Use zypper to install a package','','t','f',-1,'','[[2260]]',NULL,1);
INSERT INTO "meego_test_sessions" VALUES(1,'','Aava','','','Core Test Report: Aava Sanity 2010-10-19','Core','Sanity',NULL,'2010-10-18 21:04:24.512039','2010-10-18 21:04:33.574042','','','','','t','* Hardware: Aava');
