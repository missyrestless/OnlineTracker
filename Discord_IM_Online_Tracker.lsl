/////////// Discord IM Online Tracker \\\\\\\\\\\\\\
//                                                //
//   Sends an IM to the owner and/or posts a      //
//   message to Discord when the configured       //
//   Avatar logs on or logs off of Second Life    //
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
// 13-May-2026 - Created by Missy Restless
// 15-May-2026 - Add support for sending online status messages to a Discord channel
// 16-May-2026 - Add setup instructions and prep for Marketplace
// 17-May-2026 - Use embeds objects for Discord postings
// 18-May-2026 - Format date/time, display last login/logoff in Discord messages
// 19-May-2026 - Add support for customizing prim textures/colors/glow and pic
// 21-May-2026 - Add dialog menu for owner configuration with long touch
// 22-May-2026 - Add menu pagination for dialog menus with > 12 buttons
//
// VARIABLES
//
// UUID of the avatar to track
key TargetUuid = NULL_KEY;
// Name of the avatar to track
string TargetName = "";
string TargetDisplayName = "";
// How often to check in seconds (60s minimum recommended)
float CheckInterval = 120.0;
// ---------------------
string onlineStatus = "Unknown";
string objectDescription;
// Default fallback if not set in configuration notecard or owner
key Default_Uuid = "094743dc-cb00-483f-9c35-99232e3a71f1";

// Key for touch agent data requests
key touchDataRequestID = NULL_KEY;
// Key for user touch
key detectedKey        = NULL_KEY;
// Key for timer agent data requests
key agentDataRequestID = NULL_KEY;
// Keys for HTTP requests
key discordRequestID = NULL_KEY;
key profileRequestID = NULL_KEY;

// Dialog Menu listener handle, channel, boolean
integer listenHandle;
integer dialogChannel;
integer pageNumber    = 1;
integer inDialogMenu  = FALSE;
integer inDiscordMenu = FALSE;
integer isTracking    = TRUE;
integer particles     = TRUE;
integer particles_on  = FALSE;
integer randParticle  = 0;

// Dialog Menu listener for Webhook URL management
string  LSD_KEY       = "discord_webhook";   // linkset data key
integer MENU_CHAN     = -91827364;          
integer INPUT_CHAN    = -91827365;          
float   LISTEN_TTL    = 60.0;                
integer menuListen   = -1;
integer inputListen  = -1;

// Used to calculate time between login/logout
integer lastLogoff = 0;
integer lastLogin = 0;
string  lastLoginStr = "";
string  lastLogoffStr = "";

// Built-in white texture UUID
string WHT_UUID = "5748decc-f629-461c-9a36-a35a221fe21f";
string D_COL;
// Discord uses integer representation of hex color values
string D_RED   = "16711680";
string D_GRN   = "65280";
string D_BLU   = "8900331";

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

vector OFFLINE_COL = RED;
vector ONLINE_COL  = GREEN;

list color_menu = ["NAVY", "BLUE", "AQUA", "TEAL", "OLIVE", "GREEN", "LIME", "YELLOW", "ORANGE",
                   "RED", "MAROON", "FUCHSIA", "PURPLE", "WHITE", "SILVER", "GRAY", "BLACK"];
// color_vectors list must exactly match the order and number of color_menu list
list color_vectors = [NAVY, BLUE, AQUA, TEAL, OLIVE, GREEN, LIME, YELLOW, ORANGE,
                      RED, MAROON, FUCHSIA, PURPLE, WHITE, SILVER, GRAY, BLACK];

// Glow status selection menu entries
list glow_menu = ["Glow Off", "0.05", "0.1", "0.15", "0.2", "0.25", "0.3",
                  "0.35", "0.4", "0.45", "0.5", "0.55", "0.6", "0.65",
                  "0.7", "0.75", "0.8", "0.85", "0.9", "0.95", "1.0"];

// Frame style and textures
string  profilePic     = "";
integer UseRGB         = FALSE;
integer TintSides      = FALSE;
string  OnlineTexture  = "Mosaic-Online";
string  OfflineTexture = "Mosaic-Offline";
float   onlineGlow     = 0.2;
float   offlineGlow    = 0.0;

integer IsOnline       = -1; // Indicates uninitialized online status
integer GetDisplayName = TRUE;
integer HoverText      = FALSE;
integer online_glow;
integer online_tint;
integer NotecardLine;
// Should online status be sent to owner as an Instant Message
integer IMowner = TRUE;
// Should online status messages be restricted to owner
integer ownerOnly = TRUE;
// Should online status be broadcast to a Discord channel
integer DiscordRelay = FALSE;
string  Discord_URL  = "";
// The name of the configuration notecard
string CONFIG_CARD = "Target_Config";
key D_QueryID;
key owner = NULL_KEY;
key display_name_query;
key name_query;

string pageMenuName;
string profileURL;
string webprofURL;
//
// END VARIABLES
//
// GENERAL FUNCTIONS
//
// Set the sides to the online status texture/color
SetSideTextures() {
    integer    i;
    integer    faces = llGetNumberOfSides();
    vector     col;

    // The prim must be configured with face 0 as the profile pic
    if (onlineStatus == "ONLINE") {
        col = ONLINE_COL;
        llSetPrimitiveParams([PRIM_FULLBRIGHT, 0, TRUE]);
    } else {
        col = OFFLINE_COL;
        llSetPrimitiveParams([PRIM_FULLBRIGHT, 0, FALSE]);
    }
    // Sides and back
    for (i = 1; i < faces; i++) {
        if (UseRGB) {
            llSetTexture(WHT_UUID, i);
            llSetColor(col, i);
            if (col == OFFLINE_COL) {
                llSetPrimitiveParams([PRIM_GLOW, i, offlineGlow]);
            } else {
                llSetPrimitiveParams([PRIM_GLOW, i, onlineGlow]);
            }
        } else {
            if (col == OFFLINE_COL) {
                llSetTexture(OfflineTexture, i);
                llSetPrimitiveParams([PRIM_GLOW, i, offlineGlow]);
            } else {
                llSetTexture(OnlineTexture, i);
                llSetPrimitiveParams([PRIM_GLOW, i, onlineGlow]);
            }
            if (TintSides) {
                llSetColor(col, i);
            }
        }
    }
}

SetDefaultTextures() { // Set the sides to their default textures
    llSetTexture(WHT_UUID, ALL_SIDES);
    if (TintSides) {
        // Set face 0 color to white
        llSetColor(WHITE, 0);
    } else {
        // Set all faces color to white
        llSetColor(WHITE, ALL_SIDES);
    }
}

integer IsVector(string s) {
    // Split the string into components using common delimiters
    list split = llParseString2List(s, [" "], ["<", ">", ","]);

    // Valid vectors must have at least 7 parts: <, x, ,, y, ,, z, >
    if(llGetListLength(split) != 7) return FALSE;

    // Flip the sign of the Z component. If the string is valid, the
    // resulting vector will NOT match the original. If it's invalid,
    // both will fail to ZERO_VECTOR and thus match.
    return !((string)((vector)s) == (string)((vector)((string)llListInsertList(split, ["-"], 5))));
}

profile_timer_init() {
    if (HoverText) {
        llSetText(TargetDisplayName + "\nChecking status...", WHITE, 1.0); // Initial hover text
    } else {
        // Clear any previously set hover text
        llSetText("", ZERO_VECTOR, 0.0);
    }
    llSetObjectName(TargetDisplayName + " Online Tracker");
    objectDescription = TargetDisplayName + " is " + onlineStatus;
    llSetObjectDesc(objectDescription);
    if (profilePic == "") {
        profileRequestID = llHTTPRequest("https://world.secondlife.com/resident/" +
                                        (string)TargetUuid,[HTTP_METHOD,"GET"],"");
    } else {
        llSetTexture(profilePic, 0);
    }
    // Start monitoring immediately
    llSetTimerEvent(CheckInterval);
    // Do an initial check immediately
    agentDataRequestID = llRequestAgentData(TargetUuid, DATA_ONLINE);
    llOwnerSay("[Online Tracker] Ready. Long press to configure.");
}

init_target() {
    SetDefaultTextures();
    if ((TargetUuid == NULL_KEY) || (TargetUuid == "target-avatar-uuid")) {
        if (owner) {
            TargetUuid = owner;
        } else {
            TargetUuid = Default_Uuid;
        }
    }
    // Check if Target UUID is a valid key
    if (TargetUuid) {
        llOwnerSay("Discord IM Online Tracker initialization in progress");
    } else {
        llOwnerSay("ERROR: Invalid Target Avatar UUID " + (string)TargetUuid);
    }
    profileURL = "secondlife:///app/agent/" + (string)TargetUuid + "/about";
    name_query = llRequestUsername(TargetUuid);
    if (GetDisplayName) {
        display_name_query = llRequestDisplayName(TargetUuid);
    } else {
        llOwnerSay("Tracking " + profileURL + " online status");
        profile_timer_init();
    }
}

string mInt2mStr(string monthInt) {
    list months=["","January","February","March", "April","May","June", "July",
                    "August","September", "October","November","December"];
    return llList2String(months, (integer)monthInt);
}

string ConvertToAmPm(string time24) {
    // Expected input format: "HH:MM" (e.g., "15:30")
    integer hours = (integer)llGetSubString(time24, 0, 1);
    string minutes = llGetSubString(time24, 2, -1); // Includes the leading ":"

    string suffix = " AM";
    if (hours >= 12) {
        suffix = " PM";
    }

    integer h12 = hours % 12;
    if (h12 == 0) h12 = 12; // Handle midnight and noon

    return (string)h12 + minutes + suffix;
}

// Convert Unix Time to SLT, identifying whether it is currently PST or PDT (i.e. Daylight Saving aware)
string Unix2SLT(integer insecs) {
    string str = Convert(insecs - (3600 * 8) );   // PST is 8 hours behind GMT
    if (llGetSubString(str, -3, -1) == "PDT")     // if the result indicates Daylight Saving Time ...
        str = Convert(insecs - (3600 * 7) );      // ... Recompute at 1 hour later
    if (llGetSubString(str, -3, -1) == "PDT") {
        str = llReplaceSubString(str, "PDT", "SLT", -1);
    } else {
        str = llReplaceSubString(str, "PST", "SLT", -1);
    }
    return str;
}

// This leap year test is correct for all years from 1901 to 2099 and hence is quite adequate for Unix Time computations
integer LeapYear(integer year) {
    return !(year & 3);
}

integer DaysPerMonth(integer year, integer month) {
    if (month == 2)      return 28 + LeapYear(year);
    return 30 + ( (month + (month > 7) ) & 1);           // Odd months up to July, and even months after July, have 31 days
}

string Convert(integer insecs) {
    integer w; integer month; integer daysinyear;
    integer mins = insecs / 60;
    integer secs = insecs % 60;
    integer hours = mins / 60;
    mins = mins % 60;
    integer days = hours / 24;
    hours = hours % 24;
    integer DayOfWeek = (days + 4) % 7;    // 0=Sun thru 6=Sat

    integer years = 1970 +  4 * (days / 1461);
    days = days % 1461;                  // number of days into a 4-year cycle

    @loop;
    daysinyear = 365 + LeapYear(years);
    if (days >= daysinyear)
    {
        days -= daysinyear;
        ++years;
        jump loop;
    }
    ++days;

    for (w = month = 0; days > w; )
    {
        days -= w;
        w = DaysPerMonth(years, ++month);
    }
    string str =  ((string) years + "-" +
        llGetSubString("0" + (string) month, -2, -1) + "-" +
        llGetSubString("0" + (string) days, -2, -1) + " " +
        llGetSubString ("0" + (string) hours, -2, -1) + ":" +
        llGetSubString ("0" + (string) mins, -2, -1) );

    integer LastSunday = days - DayOfWeek;
    string PST_PDT = " PST";                  // start by assuming Pacific Standard Time
    // Up to 2006, PDT is from the first Sunday in April to the last Sunday in October
    // After 2006, PDT is from the 2nd Sunday in March to the first Sunday in November
    if (years > 2006 && month == 3  && LastSunday >  7)     PST_PDT = " PDT";
    if (month > 3)                                          PST_PDT = " PDT";
    if (month > 10)                                         PST_PDT = " PST";
    if (years < 2007 && month == 10 && LastSunday > 24)     PST_PDT = " PST";
    string yearPart = llGetSubString(str, 0, 3);
    string monthPart = llGetSubString(str, 5, 6);
    string dayPart = llGetSubString(str, 8, 9);
    string timePart = llGetSubString(str, -5, -1);
    list weekdays = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"];
    return (llList2String(weekdays, DayOfWeek) + ", " +
                          mInt2mStr(monthPart) + " " +
                          dayPart + ", " + yearPart + ", " +
                          ConvertToAmPm(timePart) + PST_PDT);
}

// Input number of seconds, return a string with Days, Hours, Minutes, Seconds
string getElapsedTime(integer secs) {
    string timeStr;
    integer days;
    integer hours;
    integer minutes;

    if (secs>=86400)
    {
        days=llFloor(secs/86400);
        secs=secs%86400;
        timeStr+=(string)days+" day";
        if (days>1)
        {
            timeStr+="s";
        }
        if(secs>0)
        {
            timeStr+=", ";
        }
    }
    if(secs>=3600)
    {
        hours=llFloor(secs/3600);
        secs=secs%3600;
        timeStr+=(string)hours+" hour";
        if(hours!=1)
        {
            timeStr+="s";
        }
        if(secs>0)
        {
            timeStr+=", ";
        }
    }
    if(secs>=60)
    {
        minutes=llFloor(secs/60);
        secs=secs%60;
        timeStr+=(string)minutes+" minute";
        if(minutes!=1)
        {
            timeStr+="s";
        }
        if(secs>0)
        {
            timeStr+=", ";
        }
    }
    if (secs>0)
    {
        timeStr+=(string)secs+" second";
        if(secs!=1)
        {
            timeStr+="s";
        }
    }
    return timeStr;
}

// Function to send the message to Discord
// dm is message to send, et is elapsed time since last login/logoff,
// ols is 0/1 logoff/login or -1 for message
//
// sendToDiscord("message to send", "elapsed time since last log", 0, 1, or -1);
sendToDiscord(string dm, string et, integer ols, string time) {
    // External URLs
    string aviURL = "https://my-secondlife-agni.akamaized.net/users/";
    string docURL = "https://online.neoman.dev/";
    string repURL = "https://marketplace.secondlife.com/p/Discord-IM-Online-Tracker/28289130";
    // Images
    string ftrURL = "https://raw.githubusercontent.com/missyrestless/OnlineTracker";
    ftrURL += "/refs/heads/main/images/stopwatch.png";
    string ftrTXT = "Time of Second Life";
    if (ols == -1) {
        ftrTXT += " message";
    } else if (ols) {
        ftrTXT += " login";
    } else {
        ftrTXT += " logout";
    }

    // Create the JSON payload, backslashing quotes all over the place
    string json = "{ \"avatar_url\": \"" + aviURL + TargetName + "/thumb_sl_image.png\", " +
                    "\"username\": \"Second Life Online Tracker\", \"embeds\": [ { " +
                    "\"title\": \"" + dm + "  (click to view profile)\", " +
                    "\"url\": \"" + webprofURL + "\", " +
                    "\"description\": \"" + et + "\\n\\n🤔 [Online Tracker Documentation](" +
                        docURL + ")\\n👩 [Second Life Marketplace Listing](" + repURL + ")\", " +
                    "\"color\": \"" + D_COL + "\", " +
                    "\"timestamp\": \"" + time + "\", " +
                    "\"footer\": { \"text\": \"" + ftrTXT + "\", " +
                        "\"icon_url\": \"" + ftrURL + "\" }" +
             " } ] }";

    // Make the HTTP request to the Discord Webhook, sending the JSON payload
    discordRequestID = llHTTPRequest(Discord_URL, [
        HTTP_METHOD, "POST",
        HTTP_MIMETYPE, "application/json",
        HTTP_VERIFY_CERT,      TRUE,
        HTTP_VERBOSE_THROTTLE, TRUE,
        HTTP_PRAGMA_NO_CACHE,  TRUE
    ], json);

    // Could have used LSL lists
    // list json    = [
    //     "avatar_url",  aviURL + TargetName + "/thumb_sl_image.png",
    //     "username", "Online Tracker",
    //     "embeds",
    //         llList2Json(JSON_ARRAY,
    //         [
    //         llList2Json(JSON_OBJECT,
    //             [
    //                 "title", TargetDisplayName,
    //                 "url", webprofURL,
    //                 "description",  dm,
    //                 "color", (integer)D_COL,
    //             ])
    //          ])
    // ];
    // Then convert the list to JSON and pass it in the request:
    //    llList2Json(JSON_OBJECT, json) );
    //
    // But straight up JSON is faster although less readable
}

stopListener() {
    llListenRemove(listenHandle);
    inDialogMenu = FALSE;
    llSetTimerEvent(CheckInterval);
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

displayDialogMenu(string menu) {
    listenHandle = llListen(dialogChannel, "", owner, "");
    list texture_menu = [];
    list tint_menu = color_menu;
    string menuMessage;
    if (menu == "frame") {
        menuMessage = "\nOn Frame = Select online frame texture\nOff Frame = Select offline frame texture";
        menuMessage = menuMessage + "\nUse Colors = Color frame rather than texture";
        menuMessage += "\n\nSelect an option";
        llDialog(owner, menuMessage, ["On Frame", "Off Frame", "Use Colors", "Main Menu", "Close"], dialogChannel);
    } else if (menu == "onFrame") {
        texture_menu = get_Textures("Online");
        if (texture_menu) {
            texture_menu += ["Main Menu", "Close"];
            menuMessage = "\nCurrent online texture is " + OnlineTexture + "\n\nSelect an online texture";
            pageMenuName = "onFrame";
            ShowMenu(menuMessage, texture_menu);
        }
    } else if (menu == "offFrame") {
        texture_menu = get_Textures("Offline");
        if (texture_menu) {
            texture_menu += ["Main Menu", "Close"];
            menuMessage = "\nCurrent offline texture is " + OfflineTexture + "\n\nSelect an offline texture";
            pageMenuName = "offFrame";
            ShowMenu(menuMessage, texture_menu);
        }
    } else if (menu == "glow") {
        menuMessage = "\nOn Glow = Select online glow status\nOff Glow = Select offline glow status";
        menuMessage += "\n\nSelect an option";
        llDialog(owner, menuMessage, ["On Glow", "Off Glow", "Main Menu", "Close"], dialogChannel);
    } else if (menu == "onGlow") {
        online_glow = TRUE;
        glow_menu += ["Main Menu", "Close"];
        menuMessage = "\nCurrent online glow status is " + (string)onlineGlow + "\n\nSelect online glow";
        pageMenuName = "onGlow";
        ShowMenu(menuMessage, glow_menu);
    } else if (menu == "offGlow") {
        online_glow = FALSE;
        glow_menu += ["Main Menu", "Close"];
        menuMessage = "\nCurrent offline glow status is " + (string)offlineGlow + "\n\nSelect offline glow";
        pageMenuName = "offGlow";
        ShowMenu(menuMessage, glow_menu);
    } else if (menu == "tint") {
        menuMessage = "\nOn Tint = Select online tint color\nOff Tint = Select offline tint color";
        menuMessage += "\n\nSelect an option";
        llDialog(owner, menuMessage, ["On Tint", "Off Tint", "Main Menu", "Close"], dialogChannel);
    } else if (menu == "onTint") {
        online_tint = TRUE;
        tint_menu += ["Main Menu", "Close"];
        integer vIndex = llListFindList(color_vectors, [ONLINE_COL]);
        if (vIndex != -1) {
            string cn = llList2String(color_menu, vIndex);
            menuMessage = "\nCurrent online tint color is " + cn + "\n\nSelect an online tint";
        } else {
            menuMessage = "\nSelect an online tint";
        }
        pageMenuName = "onTint";
        ShowMenu(menuMessage, tint_menu);
    } else if (menu == "offTint") {
        online_tint = FALSE;
        tint_menu += ["Main Menu", "Close"];
        menuMessage = "\nCurrent offline tint color is " + (string)OFFLINE_COL + "\n\nSelect an offline tint";
        pageMenuName = "offTint";
        ShowMenu(menuMessage, tint_menu);
    } else if (menu == "stop") {
        llDialog(owner, "Do you wish to proceed with shutdown of the online tracker?", ["YES", "NO"], dialogChannel);
    } else {
        string show_hide;
        if (HoverText) {
            show_hide = "Hover OFF";
        } else {
            show_hide = "Hover ON";
        }
        string tint_sides;
        string tint_color = " ---- ";
        if (TintSides) {
            tint_sides = "Tint OFF";
            tint_color = "Tint Color";
        } else {
            tint_sides = "Tint ON";
        }
        string use_rgb;
        if (UseRGB) {
            use_rgb = "Texture ON";
        } else {
            use_rgb = "Color ON";
        }
        string tracking;
        if (isTracking) {
            tracking = "Stop";
        } else {
            tracking = "Start";
        }
        string run_status;
        if (isTracking) {
            run_status = "tracking " + TargetDisplayName;
        } else {
            run_status = "STOPPED";
        }
        string hov_status;
        if (HoverText) {
            hov_status = "Enabled";
        } else {
            hov_status = "Disabled";
        }
        string tnt_status;
        if (TintSides) {
            tnt_status = "Enabled";
        } else {
            tnt_status = "Disabled";
        }
        string bdr_status;
        if (UseRGB) {
            bdr_status = "Color";
        } else {
            bdr_status = "Texture";
        }
        string part_status;
        if (particles) {
            part_status = "OFF";
        } else {
            part_status = "ON";
        }
        menuMessage = "\nOnline Tracker is " + run_status + "\nHover Text is " + hov_status;
        menuMessage = menuMessage + "\nFrame Tinting is " + tnt_status;
        menuMessage = menuMessage + "\nFrame is " + bdr_status;
        menuMessage = menuMessage + "\nBling particles are " + part_status;
        part_status = "Bling " + part_status;
        menuMessage += "\n\nSelect an option";
        list main_menu = [tracking, show_hide, tint_sides, tint_color, use_rgb, part_status, "Discord", "Say Status"];
        if (UseRGB) {
            main_menu += ["Close"];
        } else {
            main_menu += ["Pick Frame", "Close"];
        }
        pageMenuName = "main";
        ShowMenu(menuMessage, main_menu);
    }
    inDialogMenu = TRUE;
    llSetTimerEvent(60);
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
                (string)totalPages + "):", displayList, dialogChannel);
    } else {
        // Send the dialog
        llDialog(owner, msg, fm, dialogChannel);
    }
}
//
// END GENERAL FUNCTIONS
//
// DISCORD WEBHOOK MANAGEMENT FUNCTIONS
//
sendDiscordContent(string msg) {
    string url = llLinksetDataRead(LSD_KEY);
    if (url == "") {
        llOwnerSay("[Online Tracker] No URL set. Long press the Discord IM Online Tracker and choose 'Discord' first.");
        return;
    }

    string escaped = msg;
    escaped = llDumpList2String(llParseStringKeepNulls(escaped, ["\\"], []), "\\\\");
    escaped = llDumpList2String(llParseStringKeepNulls(escaped, ["\""], []), "\\\"");
    escaped = llDumpList2String(llParseStringKeepNulls(escaped, ["\n"], []), "\\n");
    escaped = llDumpList2String(llParseStringKeepNulls(escaped, ["\r"], []), "\\r");
    escaped = llDumpList2String(llParseStringKeepNulls(escaped, ["\t"], []), "\\t");

    string body = "{\"content\":\"" + escaped + "\"}";

    llHTTPRequest(url,
        [ HTTP_METHOD,     "POST",
          HTTP_MIMETYPE,   "application/json",
          HTTP_VERIFY_CERT, TRUE,
          HTTP_BODY_MAXLENGTH, 16384 ],
        body);
}

showDiscordMenu() {
    if (menuListen != -1) llListenRemove(menuListen);
    menuListen = llListen(MENU_CHAN, "", owner, "");
    inDiscordMenu = TRUE;
    llSetTimerEvent(LISTEN_TTL);

    string dcMsg = "\n[Discord Webhook Setup]\nClick 'Webhook' to enter your Discord webhook URL";
    dcMsg += "\n'Test' = Send a test message to your Discord channel";
    dcMsg += "\n'Clear' = Clear the existing Webhook URL from this script's memory";
    dcMsg += "\n'Check' = Displays the stored Webhook URL in the owner's chat window";
    dcMsg += "\n\nChoose an option:",
    llDialog(owner, dcMsg,
        ["Webhook", "Test", "Clear", "Check", "Close"],
        MENU_CHAN);
}
//
// END DISCORD WEBHOOK MANAGEMENT FUNCTIONS
//
// PARTICLE FUNCTIONS
//
ParticlesOff() {
    llParticleSystem([]);
}

Bling() {
    ParticlesOff();
    llParticleSystem([
        PSYS_PART_FLAGS, (0
                           | PSYS_PART_INTERP_COLOR_MASK
                           | PSYS_PART_EMISSIVE_MASK
                           | PSYS_PART_INTERP_SCALE_MASK
                           | PSYS_PART_FOLLOW_VELOCITY_MASK
                           | PSYS_PART_WIND_MASK
                         ),
        PSYS_SRC_PATTERN, PSYS_SRC_PATTERN_EXPLODE,

        // Color Parameters
        PSYS_PART_START_COLOR,     <1.0, 0.5, 0.0>, // Bright Orange
        PSYS_PART_END_COLOR,       <0.0, 0.0, 1.0>, // Fades to Blue

        // Transparency
        PSYS_PART_START_ALPHA,     1.0,
        PSYS_PART_END_ALPHA,       0.2,

        // Size
        PSYS_PART_START_SCALE,     <0.5, 0.5, 0.0>,
        PSYS_PART_END_SCALE,       <2.0, 2.0, 0.0>,

        // Timing & Speed
        PSYS_PART_MAX_AGE,         3.0,
        PSYS_SRC_BURST_RATE,       0.5,
        PSYS_SRC_BURST_PART_COUNT, 2,
        PSYS_SRC_BURST_SPEED_MIN,  1.0,
        PSYS_SRC_BURST_SPEED_MAX,  3.0
    ]);
}

Hearts() {
    ParticlesOff();
    llParticleSystem([
        PSYS_SRC_TEXTURE, "5b3f3df0-b20b-5dc4-b49e-377c5805a0e3",
        PSYS_PART_START_SCALE,     <0.1, 0.1, FALSE>,
        PSYS_PART_END_SCALE,       <0.4, 0.4, FALSE>,
        PSYS_PART_START_ALPHA,     1.0,
        PSYS_PART_END_ALPHA,       0.5,

        PSYS_SRC_BURST_PART_COUNT, 2,
        PSYS_SRC_BURST_RATE,       0.5,
        PSYS_PART_MAX_AGE,         2.0,
        PSYS_SRC_MAX_AGE,          0.0,

        PSYS_SRC_PATTERN,          2,
        PSYS_SRC_BURST_SPEED_MIN,  0.5,
        PSYS_SRC_BURST_SPEED_MAX,  2.0,
        PSYS_SRC_BURST_RADIUS,     0.000000,

        PSYS_SRC_ANGLE_BEGIN,      0.05*PI,
        PSYS_SRC_ANGLE_END,        0.05*PI,
        PSYS_SRC_OMEGA,            <0.0, 0.0, 0.0>,

        PSYS_SRC_ACCEL,            <0.0, 0.0, 0.0>,
        PSYS_SRC_TARGET_KEY,       (key)"",

        PSYS_PART_FLAGS, ( 0
                             | PSYS_PART_INTERP_COLOR_MASK
                             | PSYS_PART_INTERP_SCALE_MASK
                             | PSYS_PART_EMISSIVE_MASK
                             | PSYS_PART_FOLLOW_VELOCITY_MASK
                             | PSYS_PART_WIND_MASK
                         )
    ]);
}

Sparkle() {
    ParticlesOff();
    llParticleSystem([
        PSYS_PART_START_SCALE,     <0.00, 0.20, 0>,
        PSYS_PART_END_SCALE,       <0.40, 0.00, 0>,
        PSYS_PART_START_COLOR,     <0.5, 1.0, 0.0>,
        PSYS_PART_END_COLOR,       <0.0, 0.0, 1.0>,
        PSYS_PART_START_ALPHA,     1.0,
        PSYS_PART_END_ALPHA,       0.2,
        PSYS_SRC_BURST_PART_COUNT, 2,
        PSYS_SRC_BURST_RATE,       0.05,
        PSYS_PART_MAX_AGE,         0.30,
        PSYS_SRC_MAX_AGE,          0.00,
        PSYS_SRC_PATTERN,          8,
        PSYS_SRC_BURST_SPEED_MIN,  00.10,
        PSYS_SRC_BURST_SPEED_MAX,  00.10,
        PSYS_SRC_BURST_RADIUS,     00.50,
        PSYS_SRC_ANGLE_BEGIN,      0.00 *PI,
        PSYS_SRC_ANGLE_END,        1.00 *PI,
        PSYS_SRC_OMEGA,            <00.00, 00.00, 00.00>,
        PSYS_SRC_ACCEL,            <00.00, 00.00, -00.10>,
        PSYS_PART_FLAGS, (integer) ( 0
                                      | PSYS_PART_INTERP_COLOR_MASK
                                      | PSYS_PART_INTERP_SCALE_MASK
                                      | PSYS_PART_EMISSIVE_MASK
                                   )
    ]);
}
//
// END PARTICLE FUNCTIONS
//
// STATES & EVENT HANDLERS
default {
    on_rez(integer param) {
        llResetScript();
    }

    state_entry() {
        owner = llGetOwner();
        IsOnline = -1; // Indicates uninitialized online status
        lastLogoff = 0;
        lastLogin = 0;
        lastLogoffStr = "";
        lastLoginStr = "";

        // Create random channel within range [-1000000000,-2000000000]
        dialogChannel = (integer)(llFrand(-1000000000.0) - 1000000000.0);

        if (llGetInventoryType(CONFIG_CARD) == INVENTORY_NOTECARD) {
            NotecardLine = 0;
            D_QueryID = llGetNotecardLine( CONFIG_CARD, NotecardLine );
        }
        else {
            llOwnerSay("Configuration notecard missing, using defaults.");
            init_target();
        }
    }

    listen(integer channel, string name, key id, string message) {
        // Ignore everybody but the owner
        if (id != owner) return;

        if (channel == MENU_CHAN) {
            if (message == "Webhook") {
                if (inputListen != -1) llListenRemove(inputListen);
                inputListen = llListen(INPUT_CHAN, "", id, "");
                inDiscordMenu = TRUE;
                llSetTimerEvent(LISTEN_TTL);

                llTextBox(id, "\nPaste your Discord webhook URL into box)", INPUT_CHAN);
            } else if (message == "Test") {
                D_COL = D_BLU;
                sendToDiscord(llKey2Name(owner), "Test message from Second Life **" +
                             TargetDisplayName + "** Online Tracker", -1, llGetTimestamp());
                llRegionSayTo(id, 0, "[Online Tracker] Test message sent.");
            } else if (message == "Clear") {
                llLinksetDataDelete(LSD_KEY);
                llRegionSayTo(id, 0, "[Online Tracker] Webhook cleared.");
            } else if (message == "Check") {
                llRegionSayTo(id, 0, "[Online Tracker] Url is: " + llLinksetDataRead(LSD_KEY));
            } else if (message == "Close") {
                displayDialogMenu("main");
                return; // Exit the listen event
            }
        } else if (channel == INPUT_CHAN) {
            string url = llStringTrim(message, STRING_TRIM);
            integer rc = llLinksetDataWrite(LSD_KEY, url);
            if (rc == LINKSETDATA_OK) {
                llRegionSayTo(id, 0, "[Online Tracker] Webhook saved.");
                Discord_URL = url;
                DiscordRelay = TRUE;
            } else {
                llRegionSayTo(id, 0, "[Online Tracker] Save failed (code " + (string)rc + ").");
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
                particles = TRUE;
                llSetTimerEvent(10);
                randParticle = (integer)llFrand(2.0);
                if (randParticle == 1) {
                    Bling();
                } else {
                    Hearts();
                }
                particles_on = TRUE;
            } else if (message == "Bling OFF") {
                particles = FALSE;
            } else if (message == "Discord") {
                showDiscordMenu();
                return;
            } else if (message == "Hover OFF") {
                HoverText = FALSE;
                llSetText("", ZERO_VECTOR, 0.0);
            } else if (message == "Hover ON") {
                HoverText = TRUE;
                if (onlineStatus == "ONLINE") {
                    llSetText(TargetDisplayName + "\nStatus: " + onlineStatus, ONLINE_COL, 1.0);
                } else {
                    llSetText(TargetDisplayName + "\nStatus: " + onlineStatus, OFFLINE_COL, 1.0);
                }
            } else if (message == "Say Status") {
                touchDataRequestID = llRequestAgentData(TargetUuid, DATA_ONLINE);
            } else if (message == "Start") {
                llSetTimerEvent(CheckInterval);
                isTracking = TRUE;
            } else if (message == "Stop") {
                displayDialogMenu("stop");
                return;
            } else if (message == "YES") {
                llSetTimerEvent(0);
                isTracking = FALSE;
            } else if (message == "Tint ON") {
                TintSides = TRUE;
                SetSideTextures();
            } else if (message == "Tint OFF") {
                TintSides = FALSE;
                llSetColor(WHITE, ALL_SIDES);
            } else if (message == "Texture ON") {
                UseRGB = FALSE;
                SetSideTextures();
            } else if ((message == "Color ON") || (message == "Use Colors")) {
                UseRGB = TRUE;
                SetSideTextures();
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
            } else if (message == "On Frame") {
                displayDialogMenu("onFrame");
                return;
            } else if (message == "Off Frame") {
                displayDialogMenu("offFrame");
                return;
            } else if (llGetSubString(message, -7, -1) == "-Online") {
                if (llGetInventoryType(message) == INVENTORY_TEXTURE) {
                    OnlineTexture = message;
                    SetSideTextures();
                    displayDialogMenu("frame");
                    return;
                }
            } else if (llGetSubString(message, -8, -1) == "-Offline") {
                if (llGetInventoryType(message) == INVENTORY_TEXTURE) {
                    OfflineTexture = message;
                    SetSideTextures();
                    displayDialogMenu("frame");
                    return;
                }
            } else if (llListFindList(glow_menu, [message]) != -1) {
                float glow_status;
                if (message == "Glow Off") {
                    glow_status = 0.0;
                } else {
                    glow_status = (float)message;
                }
                if (online_glow) {
                    if (onlineGlow != glow_status) {
                        onlineGlow = glow_status;
                        SetSideTextures();
                    }
                } else {
                    if (offlineGlow != glow_status) {
                        offlineGlow = glow_status;
                        SetSideTextures();
                    }
                }
                displayDialogMenu("glow");
                return;
            } else if (llListFindList(color_menu, [message]) != -1) {
                integer index = llListFindList(color_menu, [message]);
                vector cv = llList2Vector(color_vectors, index);
                if (online_tint) {
                    if (ONLINE_COL != cv) {
                        ONLINE_COL = cv;
                        SetSideTextures();
                    }
                } else {
                    if (OFFLINE_COL != cv) {
                        OFFLINE_COL = cv;
                        SetSideTextures();
                    }
                }
                displayDialogMenu("tint");
                return;
            } else if (message == "Close") {
                return; // Exit the listen event, letting the dialog stay closed
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
        } else if (inDialogMenu) {
            stopListener();
        } else {
            if (particles_on) {
                particles_on = FALSE;
                ParticlesOff();
            } else {
                // Periodically check status
                agentDataRequestID = llRequestAgentData(TargetUuid, DATA_ONLINE);
            }
        }
    }

    touch_start(integer total_number) {
        // Check if the first person who touched is the owner
        detectedKey = llDetectedKey(0);
        if (detectedKey == owner) {
            stopListener();
            pageNumber = 1; // Reset to page 1
            displayDialogMenu("main");
        } else {
            if (!ownerOnly) {
                touchDataRequestID = llRequestAgentData(TargetUuid, DATA_ONLINE);
            }
        }
    }

    dataserver(key queryid, string data) {
        integer CurrentlyOnline;
        // Requested data contains the string "0" or "1" for DATA_ONLINE
        // Convert it to an integer and use the boolean as index
        // list index = [   0,       1,     2(0+2), 3(1+2)  ]
        list stat_cols = ["OFFLINE","ONLINE",OFFLINE_COL,ONLINE_COL];
        string status_pre = TargetDisplayName + " is now ";
        string status_msg = "";

        if ((queryid == agentDataRequestID) || (queryid == touchDataRequestID)) {
            CurrentlyOnline = (integer)data;

            string elapsedTimeStr;
            string timeStamp = llGetTimestamp();
            string status_pre = TargetDisplayName + " is now ";
            string status_msg = "";
            // Set hover text status and color
            onlineStatus = llList2String(stat_cols, CurrentlyOnline);   // boolean/index = 0   or 1
            vector color = llList2Vector(stat_cols, CurrentlyOnline+2); // boolean/index = 0+2 or 1+2

            // Set the object description to the online status if it has changed
            objectDescription = TargetDisplayName + " is " + onlineStatus;
            if (llGetObjectDesc() != objectDescription) {
                llSetObjectDesc(objectDescription);
            }
            SetSideTextures();

            // Force an online status report the first time through when IsOnline is uninitialized
            if (IsOnline == -1) {
                if (CurrentlyOnline) {
                    IsOnline = FALSE;
                } else {
                    IsOnline = TRUE;
                }
            }

            // IM if status has changed
            if (CurrentlyOnline) {
                if ((!IsOnline) || (queryid == touchDataRequestID)) {
                    // Add a little pizzazz
                    if (particles) {
                        // Particles are enabled
                        if (!IsOnline) {
                            // User logged in
                            llSetTimerEvent(30);
                        } else {
                            // Somebody touched me
                            llSetTimerEvent(10);
                        }
                        Sparkle();
                        particles_on = TRUE;
                    }

                    status_pre = status_pre + "ONLINE. Click to view profile: ";
                    status_msg = status_pre + profileURL;
                    lastLogin = llGetUnixTime();
                    if (lastLogoff <= 0) {
                        // No record of last login
                        elapsedTimeStr = "unknown time";
                    } else {
                        elapsedTimeStr = getElapsedTime(lastLogin - lastLogoff);
                        if (lastLoginStr != "") {
                            elapsedTimeStr = elapsedTimeStr + "\nPrevious login: " + lastLoginStr;
                        }
                        status_msg = status_msg + "\nOffline for " + elapsedTimeStr;
                    }
                    if ((!(DiscordRelay || IMowner)) || (queryid == touchDataRequestID)) {
                        if (ownerOnly) {
                            llOwnerSay(status_msg);
                        } else {
                            // send a message to the chat window of the avatar touching
                            llRegionSayTo(detectedKey, 0, status_msg);
                        }
                    } else {
                        if (IMowner) {
                            llInstantMessage(owner, status_msg);
                        }
                        if (DiscordRelay) {
                            D_COL = D_GRN;
                            status_msg = "**" + TargetDisplayName + "** is now **ONLINE**";
                            // IM and llOwnerSay use \n for a newline, Discord needs \\n. Sheesh.
                            elapsedTimeStr = llReplaceSubString(elapsedTimeStr, "\nPrevious", "\\nPrevious", -1);
                            sendToDiscord(status_msg, "Offline for " + elapsedTimeStr, 1, timeStamp);
                        }
                    }
                    if (!IsOnline) {
                        lastLoginStr = Unix2SLT(llGetUnixTime());
                    }
                }
            } else {
                if ((IsOnline) || (queryid == touchDataRequestID)) {
                    // Add a little pizzazz
                    if (particles) {
                        // Particles are enabled
                        if (!IsOnline) {
                            // User logged in
                            llSetTimerEvent(30);
                        } else {
                            // Somebody touched me
                            llSetTimerEvent(10);
                        }
                        randParticle = (integer)llFrand(2.0);
                        if (randParticle == 1) {
                            Bling();
                        } else {
                            Hearts();
                        }
                        particles_on = TRUE;
                    }

                    status_msg = status_pre + "OFFLINE.";
                    lastLogoff = llGetUnixTime();
                    if (lastLogin <= 0) {
                        // No record of last login
                        elapsedTimeStr = "unknown time";
                    } else {
                        elapsedTimeStr = getElapsedTime(lastLogoff - lastLogin);
                        if (lastLogoffStr != "") {
                            elapsedTimeStr = elapsedTimeStr + "\nPrevious logoff: " + lastLogoffStr;
                        }
                    }
                    if ((!(DiscordRelay || IMowner)) || (queryid == touchDataRequestID)) {
                        if (ownerOnly) {
                            llOwnerSay(status_msg);
                        } else {
                            // send a message to the chat window of the avatar touching
                            llRegionSayTo(detectedKey, 0, status_msg);
                        }
                    } else {
                        if (IMowner) {
                            llInstantMessage(owner, status_msg);
                        }
                        if (DiscordRelay) {
                            D_COL = D_RED;
                            status_msg = "**" + TargetDisplayName + "** is now **OFFLINE**";
                            // IM and llOwnerSay use \n for a newline, Discord needs \\n. Sheesh.
                            elapsedTimeStr = llReplaceSubString(elapsedTimeStr, "\nPrevious", "\\nPrevious", -1);
                            sendToDiscord(status_msg, "Online for " + elapsedTimeStr, 0, timeStamp);
                        }
                    }
                    if (IsOnline) {
                        lastLogoffStr = Unix2SLT(llGetUnixTime());
                    }
                }
            }
            // Set hover text
            if (HoverText) {
              llSetText(TargetDisplayName + "\nStatus: " + onlineStatus, color, 1.0); // Update hover text and color
            }

            // Update status
            IsOnline = CurrentlyOnline;
        }
        else if (queryid == D_QueryID) {
            string name;
            string value;
            list temp;
            if (data != EOF) {
                if (data == "END_SETTINGS") {
                    init_target();
                    return;
                }
                if (llGetSubString(data, 0, 0) != "#" &&
                     llStringTrim(data, STRING_TRIM) != "") {
                    temp = llParseString2List(data, ["="], []);
                    name = llStringTrim(llList2String(temp, 0), STRING_TRIM);
                    value = llStringTrim(llList2String(temp, 1), STRING_TRIM);
                    if (value == "TRUE") value = "1";
                    if (value == "FALSE") value = "0";
                    if (name == "TARGET_UUID") {
                        TargetUuid = (key)value;
                    } else if (name == "CUSTOM_PROFILE") {
                        // Check if this is the name of a texture in the prim inventory or a valid UUID
                        if (llGetInventoryType(value) == INVENTORY_TEXTURE) {
                            profilePic = value;
                        } else {
                            // Is it a valid UUID ?
                            if ((key)value) {
                                profilePic = value;
                            }
                        }
                    } else if (name == "DISPLAY_NAME") {
                        TargetDisplayName = value;
                        GetDisplayName = FALSE;
                    } else if (name == "CHECK_INTERVAL") {
                        CheckInterval = (float)value;
                    } else if (name == "GLOW_ONLINE") {
                        onlineGlow = (float)value;
                    } else if (name == "GLOW_OFFLINE") {
                        offlineGlow = (float)value;
                    } else if (name == "HOVER_TEXT") {
                        HoverText = (integer)value;
                    } else if (name == "IM_OWNER") {
                        IMowner = (integer)value;
                    } else if (name == "OWNER_ONLY") {
                        ownerOnly = (integer)value;
                    } else if (name == "FRAME_STYLE") {
                        if (llToLower(value) == "rgb") {
                            UseRGB = TRUE;
                        } else {
                            UseRGB = FALSE;
                        }
                    } else if (name == "COL_ONLINE") {
                        if (IsVector(value)) {
                            ONLINE_COL = (vector)value;
                        }
                    } else if (name == "COL_OFFLINE") {
                        if (IsVector(value)) {
                            OFFLINE_COL = (vector)value;
                        }
                    } else if (name == "TEXTURE_TINT") {
                        TintSides = (integer)value;
                    } else if (name == "TEXTURE_ONLINE") {
                        // Check if this is the name of a texture in the prim inventory or a valid UUID
                        if (llGetInventoryType(value) == INVENTORY_TEXTURE) {
                            OnlineTexture = value;
                        } else {
                            // Is it a valid UUID ?
                            if ((key)value) {
                                OnlineTexture = value;
                            }
                        }
                    } else if (name == "TEXTURE_OFFLINE") {
                        // Check if this is the name of a texture in the prim inventory or a valid UUID
                        if (llGetInventoryType(value) == INVENTORY_TEXTURE) {
                            OfflineTexture = value;
                        } else {
                            // Is it a valid UUID ?
                            if ((key)value) {
                                OfflineTexture = value;
                            }
                        }
                    } else if (name == "PARTICLES") {
                        particles = (integer)value;
                    }
                }
                NotecardLine++;
                D_QueryID = llGetNotecardLine( CONFIG_CARD, NotecardLine );
            }
        }
        else if (display_name_query == queryid) {
            TargetDisplayName = data;
            llOwnerSay("Tracking " + profileURL + " online status");
            profile_timer_init();
        }
        else if ( name_query == queryid ) {
            TargetName = data;
            webprofURL = "https://my.secondlife.com/" + data;
        }
    }

    changed(integer change) {
         if (change & (CHANGED_OWNER | CHANGED_INVENTORY)) {
             llResetScript();
         }
    }

    http_response(key req, integer status, list meta, string body) {
        if (req == discordRequestID) {
            discordRequestID = NULL_KEY;
            if (status != 200 && status != 204) // Discord returns 204 No Content on success
            {
                llOwnerSay("[Online Tracker] HTTP " + (string)status + ": " + body);
            }
        }
        else if (req == profileRequestID) {
            string profile_key_prefix = "<meta name=\"imageid\" content=\"";
            string profile_img_prefix = "<img alt=\"profile image\" src=\"http://secondlife.com/app/image/";

            integer pre_ind = llSubStringIndex(body, profile_key_prefix);
            integer pre_len = llStringLength(profile_key_prefix);

            if (pre_ind == -1) {   // Second try
                pre_ind = llSubStringIndex(body, profile_img_prefix);
                pre_len = llStringLength(profile_img_prefix);
            }

            if (pre_ind == -1) {   // Still no match?
                SetDefaultTextures();
            }
            else {
                pre_ind += pre_len;
                key UUID=llGetSubString(body, pre_ind, pre_ind + 35);
                if (UUID == NULL_KEY) {
                    SetDefaultTextures();
                }
                else {
                    llSetTexture(UUID, 0);
                }
            }
            profileRequestID = NULL_KEY;
        }
    }
}
