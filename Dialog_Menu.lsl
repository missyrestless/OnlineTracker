/////// Discord IM Online Tracker Dialog Menu \\\\\\
//                                                //
//   Provides dialog menus for the Discord IM     //
//   Online Tracker. Messaging with the main      //
//   script is done with llMessageLinked()        //
////////////////////////////////////////////////////
//
////////////////////////////////////////////////////
// Copyright (c) 2026 Truth & Beauty Lab          //
// License: GPLv3                                   //
// All rights reserved.                           //
//                                                //
// Author: Missy Restless missyrestless@gmail.com //
////////////////////////////////////////////////////
//
// MODIFICATION HISTORY
// --------------------
// 23-May-2026 - Created by Missy Restless
//
// VARIABLES
//
// Dialog Menu listener handle, channel, boolean
integer listenHandle;
integer dialogChannel;
integer discordChannel;
integer dmenuChannel;          
integer targetChannel;
integer pageNumber    = 1;
integer inDialogMenu  = FALSE;
integer inDiscordMenu = FALSE;
integer inTargetMenu  = FALSE;
integer isTracking    = TRUE;
integer particles     = TRUE;

// Need this for dialog menu message
float   CheckInterval = 120.0;                

// Linkset Data Keys
//
// Target Avatar UUID linkset data key
string  AV_UUID_LSD_KEY  = "avatar_uuid";
// Online check interval linkset data key
string  CHK_INT_LSD_KEY  = "check_interval";
// Discord Webhook linkset data key
string  DISCORD_LSD_KEY  = "discord_webhook";
// Owner only linkset data key
string  OWNER_O_LSD_KEY  = "owner_only";
// Bling on/off linkset data key
string  BLING_LSD_KEY    = "bling_state";
// Hover Text on/off linkset data key
string  HOVER_LSD_KEY    = "hover_text";
// Tint sides on/off linkset data key
string  TINT_LSD_KEY     = "tint_sides";
// Online texture linkset data key
string  ON_TXT_LSD_KEY   = "online_texture";
// Offline texture linkset data key
string  OFF_TXT_LSD_KEY  = "offline_texture";
// Online glow linkset data key
string  ON_GLOW_LSD_KEY  = "online_glow";
// Offline glow linkset data key
string  OFF_GLOW_LSD_KEY = "offline_glow";
// Online tint linkset data key
string  ON_TINT_LSD_KEY  = "online_tint";
// Offline tint linkset data key
string  OFF_TINT_LSD_KEY = "offline_tint";
// Texture sides linkset data key
string  TEXTURE_LSD_KEY  = "texture_sides";
// Custom profile texture linkset data key
string  PRO_TXT_LSD_KEY  = "custom_profile";
//
// Dialog Menu & listener for Webhook URL management
float   LISTEN_TTL      = 60.0;                
integer menuListen      = -1;
integer inputListen     = -1;

// Common color vectors reference
// ------------------------------
vector NAVY     = <0.000, 0.122, 0.247>;
vector BLUE     = <0.000, 0.455, 0.851>;
vector AQUA     = <0.498, 0.859, 1.000>;
vector TEAL     = <0.224, 0.800, 0.800>;
vector OLIVE    = <0.239, 0.600, 0.439>;
vector GREEN    = <0.180, 0.800, 0.251>;
vector LIME     = <0.004, 1.000, 0.439>;
vector YELLOW   = <1.000, 0.863, 0.000>;
vector ORANGE   = <1.000, 0.522, 0.106>;
vector RED      = <1.000, 0.255, 0.212>;
vector MAROON   = <0.522, 0.078, 0.294>;
vector FUCHSIA  = <0.941, 0.071, 0.745>;
vector PURPLE   = <0.694, 0.051, 0.788>;
vector WHITE    = <1.000, 1.000, 1.000>;
vector SILVER   = <0.867, 0.867, 0.867>;
vector GRAY     = <0.667, 0.667, 0.667>;
vector BLACK    = <0.067, 0.067, 0.067>;

vector offlineTint = RED;
vector onlineTint  = GREEN;

list color_menu = ["NAVY", "BLUE", "AQUA", "TEAL", "OLIVE", "GREEN", "LIME", "YELLOW", "ORANGE",
                   "RED", "MAROON", "FUCHSIA", "PURPLE", "WHITE", "SILVER", "GRAY", "BLACK"];
// color_vectors list must exactly match the order and number of color_menu list
list color_vectors = [NAVY, BLUE, AQUA, TEAL, OLIVE, GREEN, LIME, YELLOW, ORANGE,
                      RED, MAROON, FUCHSIA, PURPLE, WHITE, SILVER, GRAY, BLACK];

// Glow status selection menu entries
list glow_menu = ["Glow OFF", "0.05", "0.1", "0.15", "0.2", "0.25", "0.3", "0.35",
                  "Main Menu", "Settings", "0.4", "0.45", "0.5", "0.55", "0.6",
                  "0.65", "0.7", "0.75", "0.8", "0.85", "0.9", "0.95", "1.0"];

// Check status interval selection menu entries
list freq_menu = ["Main Menu", "Settings", "60", "90", "120", "150", "180", "240",
                  "300", "360", "420", "480", "540", "600", "1200", "1800", "3600"];

// Frame style and textures
string  profilePic     = "";
string  ProfileTexture = "";
integer UseRGB         = FALSE;
integer TintSides      = FALSE;
string  OnlineTexture  = "Mosaic-Online";
string  OfflineTexture = "Mosaic-Offline";
string  onlineGlow     = "0.2";
string  offlineGlow    = "0.0";

integer HoverText      = FALSE;
integer online_glow;
integer online_tint;
// Should online status be sent to owner as an Instant Message
integer IMowner = TRUE;
// Should online status messages be restricted to owner
integer ownerOnly = TRUE;
// Should online status be broadcast to a Discord channel
integer DiscordRelay      = FALSE;
string  Discord_URL       = "";
string  TargetDisplayName = "";
string pageMenuName;

// Keys
key owner       = NULL_KEY;
key TargetUuid  = NULL_KEY;

//
// END VARIABLES
//
// GENERAL FUNCTIONS
//
stopListener() {
    llListenRemove(listenHandle);
    inDialogMenu = FALSE;
}

integer num_Textures(string prefix) {
    integer num_textures = 0;
    integer count = llGetInventoryNumber(INVENTORY_TEXTURE);

    integer i;
    integer position;
    string texture_name;
    for (i = 0; i < count; ++i) {
        texture_name = llGetInventoryName(INVENTORY_TEXTURE, i);
        position = llSubStringIndex(texture_name, prefix);
        if (position != -1) {
            num_textures += 1;
        }
    }
    return num_textures;
}

list get_Textures(string prefix) {
    list texture_list = [];
    integer count = llGetInventoryNumber(INVENTORY_TEXTURE);

    // Populate list (Dialogs only show up to 12 buttons at once)
    integer i;
    integer position;
    string texture_name;
    for (i = 0; i < count; ++i) {
        texture_name = llGetInventoryName(INVENTORY_TEXTURE, i);
        position = llSubStringIndex(texture_name, prefix);
        if (position != -1) {
            texture_list += [texture_name];
        }
    }
    return texture_list;
}

list arrange(list l) {
    list outl = [];
    integer n = llGetListLength(l);
    do {
        if (n < 3) return outl + l;
        n = n - 3;
        outl = outl + llList2List(l, -3, -1);
        if (n == 0) return outl;
        l = llList2List(l, 0, -4);
    } while (TRUE);
    return [];
}

displayDialogMenu(string menu) {
    listenHandle = llListen(dialogChannel, "", owner, "");
    list texture_menu = [];
    list tint_menu = color_menu;
    string menuMessage;

    pageMenuName = menu;
    if (menu == "frame") {
        menuMessage = "\nOn Frame = Select online frame texture\nOff Frame = Select offline frame texture";
        menuMessage = menuMessage + "\nUse Colors = Color frame rather than texture";
        menuMessage += "\n\nSelect an option";
        llDialog(owner, menuMessage, arrange(["On Frame", "Off Frame", "Use Colors", "Main Menu", "Close"]), dialogChannel);
    } else if (menu == "onFrame") {
        texture_menu = get_Textures("Online");
        if (texture_menu) {
            texture_menu += ["Main Menu", "Close"];
            menuMessage = "\nCurrent online texture is " + OnlineTexture + "\n\nSelect an online texture";
            ShowMenu(menuMessage, texture_menu);
        }
    } else if (menu == "offFrame") {
        texture_menu = get_Textures("Offline");
        if (texture_menu) {
            texture_menu += ["Main Menu", "Close"];
            menuMessage = "\nCurrent offline texture is " + OfflineTexture + "\n\nSelect an offline texture";
            ShowMenu(menuMessage, texture_menu);
        }
    } else if (menu == "customPic") {
        texture_menu = get_Textures("Profile");
        if (texture_menu) {
            texture_menu += ["Default", "Main Menu", "Close"];
            if (ProfileTexture == "") {
                menuMessage = "\nCurrent profile pic texture is Avatar profile pic\n\nSelect a custom profile pic texture";
            } else {
                menuMessage = "\nCurrent profile pic texture is " + ProfileTexture + "\n\nSelect a custom profile pic texture";
            }
            ShowMenu(menuMessage, texture_menu);
        }
    } else if (menu == "frequency") {
        menuMessage = "\nCurrent online status check interval:\n\t" + FormatFloat(CheckInterval) + " seconds";
        menuMessage += "\n\nSelect online status check interval";
        ShowMenu(menuMessage, freq_menu);
    } else if (menu == "glow") {
        menuMessage = "\nOn Glow = Select online glow status\nOff Glow = Select offline glow status";
        menuMessage += "\n\nSelect an option";
        llDialog(owner, menuMessage, arrange(["On Glow", "Off Glow", "Settings", "Main Menu", "Close"]), dialogChannel);
    } else if (menu == "onGlow") {
        online_glow = TRUE;
        menuMessage = "\nCurrent online glow status is " + onlineGlow + "\n\nSelect online glow";
        ShowMenu(menuMessage, glow_menu);
    } else if (menu == "offGlow") {
        online_glow = FALSE;
        menuMessage = "\nCurrent offline glow status is " + offlineGlow + "\n\nSelect offline glow";
        ShowMenu(menuMessage, glow_menu);
    } else if (menu == "tint") {
        menuMessage = "\nOn Tint = Select online tint color\nOff Tint = Select offline tint color";
        menuMessage += "\n\nSelect an option";
        llDialog(owner, menuMessage, arrange(["On Tint", "Off Tint", "Main Menu", "Close"]), dialogChannel);
    } else if (menu == "onTint") {
        online_tint = TRUE;
        tint_menu += ["Main Menu", "Close"];
        integer vIndex = llListFindList(color_vectors, [onlineTint]);
        if (vIndex != -1) {
            string cn = llList2String(color_menu, vIndex);
            menuMessage = "\nCurrent online tint color is " + cn + "\n\nSelect an online tint";
        } else {
            menuMessage = "\nSelect an online tint";
        }
        ShowMenu(menuMessage, tint_menu);
    } else if (menu == "offTint") {
        online_tint = FALSE;
        tint_menu += ["Main Menu", "Close"];
        menuMessage = "\nCurrent offline tint color is " + (string)offlineTint + "\n\nSelect an offline tint";
        ShowMenu(menuMessage, tint_menu);
    } else if (menu == "settings") {
        menuMessage = "\nEnable, disable, and configure appearance and behavior of the Online Tracker";
        menuMessage += "\n\nCurrent online status check interval:\n\t" + FormatFloat(CheckInterval) + " seconds";
        string mode = "All Access";
        if (ownerOnly) {
            mode = "Owner Only";
        }
        menuMessage += "\nAccess mode is set to " + mode;
        if (mode == "Owner Only") {
            mode = "All Access";
        } else {
            mode = "Owner Only";
        }
        menuMessage += "\n\nShow Conf = Display current configuration values";
        menuMessage += "\n\nSelect an option";
        list sett_menu = ["Main Menu", "Show Conf", "Glow", "Interval", mode];
        if (num_Textures("Profile") > 0) {
            sett_menu += ["Custom Pic"];
        }
        if (HoverText) {
            sett_menu += ["Hover OFF"];
        } else {
            sett_menu += ["Hover ON"];
        }
        if (TintSides) {
            sett_menu += ["Tint OFF", "Tint Color"];
        } else {
            sett_menu += ["Tint ON"];
        }
        if (UseRGB) {
            sett_menu += ["Texture ON"];
        } else {
            sett_menu += ["Color ON"];
        }
        if (particles) {
            sett_menu += ["Bling OFF"];
        } else {
            sett_menu += ["Bling ON"];
        }
        if (!UseRGB) {
            sett_menu += ["Pick Frame"];
        }
        sett_menu += ["Close"];
        ShowMenu(menuMessage, sett_menu);
    } else if (menu == "stop") {
        llDialog(owner, "Do you wish to proceed with shutdown of the online tracker?", arrange(["YES", "NO"]), dialogChannel);
    } else {
        list main_menu = ["Discord", "Say Status", "Target AVI", "Settings"];
        if (isTracking) {
            main_menu += ["Stop", "Close"];
        } else {
            main_menu += ["Start", "Close"];
        }
        string discord_status;
        if (DiscordRelay) {
            discord_status = "Enabled";
            discord_status = "Enabled. Click the Discord button to change your Webhook URL\n";
        } else {
            discord_status = "Disabled. Click the Discord button to enter your Webhook URL\n";
        }
        menuMessage = "\nTracking " + TargetDisplayName + ". Click the Target AVI button to configure tracked Avatar";
        menuMessage = menuMessage + "\n\nDiscord messages are " + discord_status;
        menuMessage += "\n\nSelect an option";
        ShowMenu(menuMessage, main_menu);
    }
    inDialogMenu = TRUE;
    llSetTimerEvent(60);
}

ShowConf() {
    string confMsg = "Current Discord IM Online Tracker configuration";
    confMsg += "\n\nTarget UUID = " + (string)TargetUuid;
    confMsg += "\nTarget Display Name = " + TargetDisplayName;
    confMsg += "\nDiscord Webhook URL = " + Discord_URL;
    confMsg += "\nOnline check interval = " + FormatFloat(CheckInterval) + " seconds";
    confMsg += "\nOwner Only enable/disable = " + (string)ownerOnly;
    confMsg += "\nParticle display enable/disable = " + (string)particles;
    confMsg += "\nHover Text enable/disable = " + (string)HoverText;
    confMsg += "\nTint enable/disable = " + (string)TintSides;
    if (UseRGB) {
        confMsg += "\nTexture or RGB frame = RGB";
    } else {
        confMsg += "\nTexture or RGB frame = Texture";
    }
    confMsg += "\nOnline texture = " + OnlineTexture;
    confMsg += "\nOffline texture = " + OfflineTexture;
    confMsg += "\nOnline tint = " + (string)onlineTint;
    confMsg += "\nOffline tint = " + (string)offlineTint;
    confMsg += "\nOnline glow = " + stripTrailingZeros(onlineGlow);
    confMsg += "\nOffline glow = " + stripTrailingZeros(offlineGlow);
    if (ProfileTexture == "") {
        confMsg += "\nCustom profile texture = NONE";
    } else {
        confMsg += "\nCustom profile texture = " + ProfileTexture;
    }
    llOwnerSay(confMsg);
}

// Show the specific menu page
// Pass in the full menu list
ShowMenu(string msg, list fm) {
    integer list_length = llGetListLength(fm);
    if (list_length > 12) {
        integer totalPages = (list_length / 10) + (list_length % 10 != 0);

        // Safety check: bound page numbers
        if (pageNumber < 1) pageNumber = 1;
        if (pageNumber > totalPages) pageNumber = totalPages;

        // Calculate slice indices
        integer start = (pageNumber - 1) * 10;
        integer end = start + 9;

        // Grab the 10 (or fewer) items for this page
        list displayList = llList2List(fm, start, end);

        // Add navigation buttons to the bottom of the list
        if (totalPages > 1) {
            if (pageNumber > 1) displayList += ["<<< Back"];
            if (pageNumber < totalPages) displayList += ["Next >>>"];
        }

        // Send the dialog page
        llDialog(owner, msg + " (Page " + (string)pageNumber + " of " +
                (string)totalPages + "):", arrange(displayList), dialogChannel);
    } else {
        // Send the dialog
        llDialog(owner, msg, arrange(fm), dialogChannel);
    }
}

// Truncates floating point representation to a single decimal digit
string FormatFloat(float num) {
    string ret;
    integer scale;

    scale = (integer)(num * 10);
    ret = (string)scale;
    integer length = llStringLength(ret);

    // Safety check for strings that are too short
    if (length < 2) return ret;

    // Split the string: everything up to the last char + "." + the last char
    return llGetSubString(ret, 0, length - 2) + "." + llGetSubString(ret, -1, -1);
}

string stripTrailingZeros(string str) {
    // Only proceed if there is a decimal point to avoid mangling whole numbers like "100"
    if (llSubStringIndex(str, ".") != -1) {
        while (llGetSubString(str, -1, -1) == "0") {
            str = llDeleteSubString(str, -1, -1);
        }
        // Optional: Remove the trailing decimal point if it's now the last character
        if (llGetSubString(str, -1, -1) == ".") {
            str = llDeleteSubString(str, -1, -1);
        }
    }
    return str;
}

// Writes the provided key/value pair to the prim's linkset datastore
// Sends a link message to the Online Tracker script with the stored value if successful
integer linksetDataWrite(key id, string lsdKey, string value, integer link, string cfg) {
    string val = llStringTrim(value, STRING_TRIM);
    integer returnCode = llLinksetDataWrite(lsdKey, val);
    if (returnCode == LINKSETDATA_OK) {
        llMessageLinked(LINK_THIS, link, val, "");
        llRegionSayTo(id, 0, "[Online Tracker] " + cfg + " saved.");
    } else if (returnCode == LINKSETDATA_NOUPDATE) {
        llMessageLinked(LINK_THIS, link, val, "");
        llRegionSayTo(id, 0, "[Online Tracker] " + cfg + " already stored and is identical.");
    } else {
        llRegionSayTo(id, 0, "[Online Tracker] " + cfg + " save failed (code " + (string)returnCode + ").");
    }
    return returnCode;
}
//
// END GENERAL FUNCTIONS
//
// DISCORD WEBHOOK MANAGEMENT FUNCTIONS
//
showDiscordMenu() {
    if (menuListen != -1) llListenRemove(menuListen);
    menuListen = llListen(dmenuChannel, "", owner, "");
    inDiscordMenu = TRUE;
    llSetTimerEvent(LISTEN_TTL);

    string dcMsg = "\n[Discord Webhook Setup]\nClick 'Webhook' to enter your Discord webhook URL";
    dcMsg += "\n'Test' = Send a test message to your Discord channel";
    dcMsg += "\n'Clear' = Clear the existing Webhook URL from this script's memory";
    dcMsg += "\n'Check' = Displays the stored Webhook URL in the owner's chat window";
    dcMsg += "\n\nChoose an option:";
    llDialog(owner, dcMsg,
        arrange(["Webhook", "Test", "Clear", "Check", "Close"]),
        dmenuChannel);
}

showTargetMenu() {
    if (menuListen != -1) llListenRemove(menuListen);
    menuListen = llListen(dmenuChannel, "", owner, "");
    inTargetMenu = TRUE;
    llSetTimerEvent(LISTEN_TTL);

    string tgMsg = "\n[Online Tracker Setup]\nClick 'Input UUID' to enter the Avatar UUID to track";
    tgMsg += "\n'UUID Test' = Perform an online status check of your configured target Avatar";
    tgMsg += "\n'UUID Clear' = Clear the existing target Avatar UUID from this script's memory";
    tgMsg += "\n'UUID Check' = Displays the stored target Avatar UUID in the owner's chat window";
    tgMsg += "\n\nChoose an option:";
    llDialog(owner, tgMsg,
        arrange(["Input UUID", "UUID Test", "UUID Clear", "UUID Check", "Close"]),
        dmenuChannel);
}

// END DISCORD WEBHOOK MANAGEMENT FUNCTIONS
//
// STATES & EVENT HANDLERS

default {
    on_rez(integer param) {
        llResetScript();
    }

    state_entry() {
        owner         = llGetOwner();

        // Create random channel within range [-1000000000,-2000000000]
        dialogChannel  = (integer)(llFrand(-1000000000.0) - 1000000000.0);
        dmenuChannel   = (integer)(llFrand(-1000000000.0) - 1000000000.0);
        discordChannel = (integer)(llFrand(-1000000000.0) - 1000000000.0);
        targetChannel  = (integer)(llFrand(-1000000000.0) - 1000000000.0);
    }

    listen(integer channel, string name, key id, string message) {
        // Send to Online Tracker
        integer SND_LM_SEND_DC_MSG = 100;
        integer SND_LM_ONLINETOUCH = 101;
        integer SND_LM_SETSIDE_TXT = 110;
        integer SND_LM_ONLINE_TXT  = 111;
        integer SND_LM_OFFLINE_TXT = 112;
        integer SND_LM_OWNER_ONLY  = 113;
        integer SND_LM_SET_TINT    = 114;
        integer SND_LM_WEBHOOK_URL = 200;
        integer SND_LM_TARGET_UUID = 201;
        integer SND_LM_SET_CHK_VAR = 300;
        integer SND_LM_SET_TIMER   = 301;
        integer SND_LM_CLEAR_TIMER = 302;
        integer SND_LM_HOVER_TEXT  = 310;
        integer SND_LM_BLING       = 311;
        integer SND_LM_ON_GLOW     = 312;
        integer SND_LM_OFF_GLOW    = 313;
        integer SND_LM_ON_TINT     = 314;
        integer SND_LM_OFF_TINT    = 315;
        integer SND_LM_PROFILE_TXT = 400;

        // Return code from writes to linkset datastore
        integer rc;

        // Ignore everybody but the owner
        if (id != owner) return;

        if (channel == dmenuChannel) {
            if (message == "Webhook") {
                if (inputListen != -1) llListenRemove(inputListen);
                inputListen = llListen(discordChannel, "", id, "");
                inDiscordMenu = TRUE;
                llSetTimerEvent(LISTEN_TTL);

                llTextBox(id, "\nPaste your Discord webhook URL into the box)", discordChannel);
            } else if (message == "Test") {
                llMessageLinked(LINK_THIS, SND_LM_SEND_DC_MSG, "Test message from Second Life **" +
                                           TargetDisplayName + "** Online Tracker", id);
            } else if (message == "Clear") {
                llLinksetDataDelete(DISCORD_LSD_KEY);
                llRegionSayTo(id, 0, "[Online Tracker] Webhook cleared.");
            } else if (message == "Check") {
                llRegionSayTo(id, 0, "[Online Tracker] Url is: " + llLinksetDataRead(DISCORD_LSD_KEY));
            } else if (message == "Input UUID") {
                if (inputListen != -1) llListenRemove(inputListen);
                inputListen = llListen(targetChannel, "", id, "");
                inTargetMenu = TRUE;
                llSetTimerEvent(LISTEN_TTL);

                llTextBox(id, "\nPaste the target Avatar's UUID into the box)", targetChannel);
            } else if (message == "UUID Test") {
                llMessageLinked(LINK_THIS, SND_LM_ONLINETOUCH, "", TargetUuid);
            } else if (message == "UUID Clear") {
                llLinksetDataDelete(AV_UUID_LSD_KEY);
                llRegionSayTo(id, 0, "[Online Tracker] target Avatar UUID cleared.");
            } else if (message == "UUID Check") {
                llRegionSayTo(id, 0, "[Online Tracker] target Avatar UUID is: " + llLinksetDataRead(AV_UUID_LSD_KEY));
            } else if (message == "Close") {
                displayDialogMenu("main");
                return; // Exit the listen event
            }
        } else if (channel == discordChannel) {
            rc = linksetDataWrite(id, DISCORD_LSD_KEY, message, SND_LM_WEBHOOK_URL, "Webhook");
            if ((rc == LINKSETDATA_OK) || (rc == LINKSETDATA_NOUPDATE)) {
                Discord_URL = llStringTrim(message, STRING_TRIM);
                DiscordRelay = TRUE;
            }

            if (inputListen != -1) {
                llListenRemove(inputListen);
                inputListen = -1;
            }
        } else if (channel == targetChannel) {
            string uuid = llStringTrim(message, STRING_TRIM);
            if ((key)uuid) {
                rc = linksetDataWrite(id, AV_UUID_LSD_KEY, uuid, SND_LM_TARGET_UUID, "Target UUID");
                if ((rc == LINKSETDATA_OK) || (rc == LINKSETDATA_NOUPDATE)) {
                    TargetUuid = (key)uuid;
                    // Reset pic to default
                    linksetDataWrite(id, PRO_TXT_LSD_KEY, "", SND_LM_PROFILE_TXT, "Profile texture");
                    ProfileTexture = "";
                }
            } else {
                llRegionSayTo(id, 0, "[Online Tracker] " + uuid + " is not a valid UUID.");
            }

            if (inputListen != -1) {
                llListenRemove(inputListen);
                inputListen = -1;
            }
        } else {
            stopListener();
            // Handle pagination for multi page menus
            if (message == "<<< Back") {
                pageNumber--;
                displayDialogMenu(pageMenuName);
                return;
            } else if (message == "Next >>>") {
                pageNumber++;
                displayDialogMenu(pageMenuName);
                return;
            } else if (message == "Bling ON") {
                rc = linksetDataWrite(id, BLING_LSD_KEY, (string)TRUE, SND_LM_BLING, message);
                if ((rc == LINKSETDATA_OK) || (rc == LINKSETDATA_NOUPDATE)) {
                    particles = TRUE;
                }
                displayDialogMenu("settings");
                return;
            } else if (message == "Bling OFF") {
                rc = linksetDataWrite(id, BLING_LSD_KEY, (string)FALSE, SND_LM_BLING, message);
                if ((rc == LINKSETDATA_OK) || (rc == LINKSETDATA_NOUPDATE)) {
                    particles = FALSE;
                }
                displayDialogMenu("settings");
                return;
            } else if (message == "Discord") {
                showDiscordMenu();
                return;
            } else if (message == "Interval") {
                displayDialogMenu("frequency");
                return;
            } else if (message == "Hover OFF") {
                rc = linksetDataWrite(id, HOVER_LSD_KEY, (string)FALSE, SND_LM_HOVER_TEXT, message);
                if ((rc == LINKSETDATA_OK) || (rc == LINKSETDATA_NOUPDATE)) {
                    HoverText = FALSE;
                }
                displayDialogMenu("settings");
                return;
            } else if (message == "Hover ON") {
                rc = linksetDataWrite(id, HOVER_LSD_KEY, (string)TRUE, SND_LM_HOVER_TEXT, message);
                if ((rc == LINKSETDATA_OK) || (rc == LINKSETDATA_NOUPDATE)) {
                    HoverText = TRUE;
                }
                displayDialogMenu("settings");
                return;
            } else if (message == "Main Menu") {
                displayDialogMenu("main");
                return;
            } else if (message == "Close") {
                return; // Exit the listen event, letting the dialog stay closed
            } else if (message == "Say Status") {
                llMessageLinked(LINK_THIS, SND_LM_ONLINETOUCH, "", TargetUuid);
            } else if (message == "Settings") {
                displayDialogMenu("settings");
                return;
            } else if (message == "Start") {
                llMessageLinked(LINK_THIS, SND_LM_SET_TIMER, message, "");
                isTracking = TRUE;
            } else if (message == "Stop") {
                displayDialogMenu("stop");
                return;
            } else if (message == "Target AVI") {
                showTargetMenu();
                return;
            } else if (message == "YES") {
                llMessageLinked(LINK_THIS, SND_LM_CLEAR_TIMER, message, "");
                isTracking = FALSE;
            } else if (message == "Tint ON") {
                rc = linksetDataWrite(id, TINT_LSD_KEY, (string)TRUE, SND_LM_SET_TINT, message);
                if ((rc == LINKSETDATA_OK) || (rc == LINKSETDATA_NOUPDATE)) {
                    TintSides = TRUE;
                }
                displayDialogMenu("settings");
                return;
            } else if (message == "Tint OFF") {
                rc = linksetDataWrite(id, TINT_LSD_KEY, (string)FALSE, SND_LM_SET_TINT, message);
                if ((rc == LINKSETDATA_OK) || (rc == LINKSETDATA_NOUPDATE)) {
                    TintSides = FALSE;
                    llSetColor(WHITE, ALL_SIDES);
                }
                displayDialogMenu("settings");
                return;
            } else if (message == "Texture ON") {
                rc = linksetDataWrite(id, TEXTURE_LSD_KEY, (string)TRUE, SND_LM_SETSIDE_TXT, message);
                if ((rc == LINKSETDATA_OK) || (rc == LINKSETDATA_NOUPDATE)) {
                    UseRGB = FALSE;
                }
                displayDialogMenu("settings");
                return;
            } else if ((message == "Color ON") || (message == "Use Colors")) {
                rc = linksetDataWrite(id, TEXTURE_LSD_KEY, (string)FALSE, SND_LM_SETSIDE_TXT, message);
                if ((rc == LINKSETDATA_OK) || (rc == LINKSETDATA_NOUPDATE)) {
                    UseRGB = TRUE;
                }
                displayDialogMenu("settings");
                return;
            } else if (message == "Glow") {
                displayDialogMenu("glow");
                return;
            } else if (message == "On Glow") {
                displayDialogMenu("onGlow");
                return;
            } else if (message == "Off Glow") {
                displayDialogMenu("offGlow");
                return;
            } else if (message == "Tint Color") {
                displayDialogMenu("tint");
                return;
            } else if (message == "On Tint") {
                displayDialogMenu("onTint");
                return;
            } else if (message == "Off Tint") {
                displayDialogMenu("offTint");
                return;
            } else if (message == "Pick Frame") {
                displayDialogMenu("frame");
                return;
            } else if (message == "Show Conf") {
                ShowConf();
                displayDialogMenu("settings");
                return;
            } else if (message == "On Frame") {
                displayDialogMenu("onFrame");
                return;
            } else if (message == "Off Frame") {
                displayDialogMenu("offFrame");
                return;
            } else if (message == "Custom Pic") {
                displayDialogMenu("customPic");
                return;
            } else if (llGetSubString(message, -7, -1) == "-Online") {
                if (llGetInventoryType(message) == INVENTORY_TEXTURE) {
                    rc = linksetDataWrite(id, ON_TXT_LSD_KEY, message, SND_LM_ONLINE_TXT, "Online texture");
                    if ((rc == LINKSETDATA_OK) || (rc == LINKSETDATA_NOUPDATE)) {
                        OnlineTexture = message;
                    }
                    displayDialogMenu("frame");
                    return;
                }
            } else if (llGetSubString(message, -8, -1) == "-Offline") {
                if (llGetInventoryType(message) == INVENTORY_TEXTURE) {
                    rc = linksetDataWrite(id, OFF_TXT_LSD_KEY, message, SND_LM_OFFLINE_TXT, "Offline texture");
                    if ((rc == LINKSETDATA_OK) || (rc == LINKSETDATA_NOUPDATE)) {
                        OfflineTexture = message;
                    }
                    displayDialogMenu("frame");
                    return;
                }
            } else if (llGetSubString(message, -8, -1) == "-Profile") {
                if (llGetInventoryType(message) == INVENTORY_TEXTURE) {
                    rc = linksetDataWrite(id, PRO_TXT_LSD_KEY, message, SND_LM_PROFILE_TXT, "Profile texture");
                    if ((rc == LINKSETDATA_OK) || (rc == LINKSETDATA_NOUPDATE)) {
                        ProfileTexture = message;
                    }
                    displayDialogMenu("customPic");
                    return;
                }
            } else if (message == "Default") {
                rc = linksetDataWrite(id, PRO_TXT_LSD_KEY, "", SND_LM_PROFILE_TXT, "Profile texture");
                ProfileTexture = "";
                displayDialogMenu("customPic");
                return;
            } else if (llListFindList(freq_menu, [message]) != -1) {
                linksetDataWrite(id, CHK_INT_LSD_KEY, message, SND_LM_SET_CHK_VAR, "Check interval");
                displayDialogMenu("settings");
                return;
            } else if ((message == "Owner Only") || (message == "All Access")) {
                if (message == "Owner Only") {
                    ownerOnly = TRUE;
                } else {
                    ownerOnly = FALSE;
                }
                linksetDataWrite(id, OWNER_O_LSD_KEY, (string)ownerOnly, SND_LM_OWNER_ONLY, "Access mode");
                displayDialogMenu("settings");
                return;
            } else if (llListFindList(glow_menu, [message]) != -1) {
                string glow_status;
                if (message == "Glow OFF") {
                    glow_status = "0.0";
                } else {
                    glow_status = message;
                }
                if (online_glow) {
                    rc = linksetDataWrite(id, ON_GLOW_LSD_KEY, glow_status, SND_LM_ON_GLOW, "Online glow");
                    if ((rc == LINKSETDATA_OK) || (rc == LINKSETDATA_NOUPDATE)) {
                        onlineGlow = glow_status;
                    }
                } else {
                    rc = linksetDataWrite(id, OFF_GLOW_LSD_KEY, glow_status, SND_LM_OFF_GLOW, "Offline glow");
                    if ((rc == LINKSETDATA_OK) || (rc == LINKSETDATA_NOUPDATE)) {
                        offlineGlow = glow_status;
                    }
                }
                displayDialogMenu("glow");
                return;
            } else if (llListFindList(color_menu, [message]) != -1) {
                integer index = llListFindList(color_menu, [message]);
                vector cv = llList2Vector(color_vectors, index);
                if (online_tint) {
                    rc = linksetDataWrite(id, ON_TINT_LSD_KEY, (string)cv, SND_LM_ON_TINT, "Online tint");
                    if ((rc == LINKSETDATA_OK) || (rc == LINKSETDATA_NOUPDATE)) {
                        onlineTint = cv;
                    }
                } else {
                    rc = linksetDataWrite(id, OFF_TINT_LSD_KEY, (string)cv, SND_LM_OFF_TINT, "Offline tint");
                    if ((rc == LINKSETDATA_OK) || (rc == LINKSETDATA_NOUPDATE)) {
                        offlineTint = cv;
                    }
                }
                displayDialogMenu("tint");
                return;
            }
            // Re-send the dialog to keep the menu open
            displayDialogMenu("main");
        }
    }

    timer() {
        if (inDiscordMenu) {
            if (menuListen  != -1) { llListenRemove(menuListen);  menuListen  = -1; }
            if (inputListen != -1) { llListenRemove(inputListen); inputListen = -1; }
            llSetTimerEvent(0.0);
            inDiscordMenu = FALSE;
            stopListener();
        } else if (inTargetMenu) {
            if (menuListen  != -1) { llListenRemove(menuListen);  menuListen  = -1; }
            if (inputListen != -1) { llListenRemove(inputListen); inputListen = -1; }
            llSetTimerEvent(0.0);
            inTargetMenu = FALSE;
            stopListener();
        } else if (inDialogMenu) {
            stopListener();
        }
    }

    touch_start(integer total_number) {
        // Check if the first person who touched is the owner
        if (llDetectedKey(0) == owner) {
            stopListener();
            pageNumber = 1; // Reset to page 1
            displayDialogMenu("main");
        }
    }

    link_message(integer sender, integer num, string message, key id)
    {
        // Receive from Online Tracker
        integer RCV_LM_TARGET_UUID = 10;
        integer RCV_LM_TARGET_NAME = 11;
        integer RCV_LM_CK_INTERVAL = 12;
        integer RCV_LM_OWNER_ONLY  = 13;
        integer RCV_LM_BLING       = 14;
        integer RCV_LM_HOVER_TEXT  = 15;
        integer RCV_LM_TINT_SIDES  = 16;
        integer RCV_LM_ONLINE_TXT  = 17;
        integer RCV_LM_OFFLINE_TXT = 18;
        integer RCV_LM_ON_GLOW     = 19;
        integer RCV_LM_OFF_GLOW    = 20;
        integer RCV_LM_ON_TINT     = 21;
        integer RCV_LM_OFF_TINT    = 22;
        integer RCV_LM_SETSIDE_TXT = 23;
        integer RCV_LM_PROFILE_TXT = 24;

        if (num == RCV_LM_TARGET_UUID) {
            TargetUuid = id;
        } else if (num == RCV_LM_TARGET_NAME) {
            TargetDisplayName = message;
        } else if (num == RCV_LM_CK_INTERVAL) {
            CheckInterval = (float)message;
        } else if (num == RCV_LM_OWNER_ONLY) {
            ownerOnly = (integer)message;
        } else if (num == RCV_LM_BLING) {
            particles = (integer)message;
        } else if (num == RCV_LM_HOVER_TEXT) {
            HoverText = (integer)message;
        } else if (num == RCV_LM_TINT_SIDES) {
            TintSides = (integer)message;
        } else if (num == RCV_LM_ONLINE_TXT) {
            OnlineTexture = message;
        } else if (num == RCV_LM_OFFLINE_TXT) {
            OfflineTexture = message;
        } else if (num == RCV_LM_PROFILE_TXT) {
            ProfileTexture = message;
        } else if (num == RCV_LM_ON_GLOW) {
            onlineGlow = message;
        } else if (num == RCV_LM_OFF_GLOW) {
            offlineGlow = message;
        } else if (num == RCV_LM_ON_TINT) {
            onlineTint = (vector)message;
        } else if (num == RCV_LM_OFF_TINT) {
            offlineTint = (vector)message;
        } else if (num == RCV_LM_SETSIDE_TXT) {
            UseRGB = (integer)message;
        }
    }

    changed(integer change) {
         if (change & (CHANGED_OWNER | CHANGED_INVENTORY)) {
             llResetScript();
         }
    }
}
