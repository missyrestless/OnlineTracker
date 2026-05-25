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
// Contributors: allie (allieee.lykin)            //
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
// 21-May-2026 - Add dialog menu for owner configuration with touch
// 22-May-2026 - Add menu pagination for dialog menus with > 12 buttons
// 23-May-2026 - Use linkset datastore to store target UUID and Webhook URL
//               Example linkset datastore code contributed by allie (allieee.lykin)
// 24-May-2026 - Split dialog menus out into separate script, use llMessageLinked()
//
// VARIABLES
//
string version = "1.1.0";
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

integer particles     = TRUE;
integer particles_on  = FALSE;
integer randParticle  = 0;

// Linkset Data Keys
// Must match the definitions in Dialog_Menu.lsl
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
// Texture sides linkset data key
string  TEXTURE_LSD_KEY  = "texture_sides";
// Custom profile texture linkset data key
string  PRO_TXT_LSD_KEY  = "custom_profile";
//
// Linked Message Numbers
//
// Send to dialog menu
integer SND_LM_TARGET_UUID = 10;
integer SND_LM_TARGET_NAME = 11;
integer SND_LM_CK_INTERVAL = 12;
integer SND_LM_OWNER_ONLY  = 13;
integer SND_LM_BLING       = 14;
integer SND_LM_HOVER_TEXT  = 15;
integer SND_LM_TINT_SIDES  = 16;
integer SND_LM_ONLINE_TXT  = 17;
integer SND_LM_OFFLINE_TXT = 18;
integer SND_LM_ON_GLOW     = 19;
integer SND_LM_OFF_GLOW    = 20;
integer SND_LM_SETSIDE_TXT = 21;
integer SND_LM_PROFILE_TXT = 22;

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

vector GREEN       = <0.180, 0.800, 0.251>;
vector RED         = <1.000, 0.255, 0.212>;
vector WHITE       = <1.000, 1.000, 1.000>;
vector OFFLINE_COL = RED;
vector ONLINE_COL  = GREEN;

// Frame style and textures
string  ProfileTexture = "";
integer UseRGB         = FALSE;
integer TintSides      = FALSE;
string  OnlineTexture  = "Mosaic-Online";
string  OfflineTexture = "Mosaic-Offline";
float   onlineGlow     = 0.2;
float   offlineGlow    = 0.0;

integer IsOnline       = -1; // Indicates uninitialized online status
integer GetDisplayName = TRUE;
integer HoverText      = FALSE;
integer online_tint;
// Should online status be sent to owner as an Instant Message
integer IMowner = TRUE;
// Should online status messages be restricted to owner
integer ownerOnly = TRUE;
// Should online status be broadcast to a Discord channel
integer DiscordRelay = FALSE;
string  Discord_URL  = "";
key owner = NULL_KEY;
key display_name_query;
key name_query;

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

SetProfileTexture() {
    if (ProfileTexture == "") {
        profileRequestID = llHTTPRequest("https://world.secondlife.com/resident/" +
                                        (string)TargetUuid,[HTTP_METHOD,"GET"],"");
    } else {
        llSetTexture(ProfileTexture, 0);
    }
}

GetDatastoreValues() {
    //
    // Retrieve any configuration values stored in the linkset datastore
    //
    // Target UUID
    string linksetValue = llLinksetDataRead(AV_UUID_LSD_KEY);
    if ((key)linksetValue) {
        TargetUuid = (key)linksetValue;
    } else {
        if ((TargetUuid == NULL_KEY) || (TargetUuid == "target-avatar-uuid")) {
            if (owner) {
                TargetUuid = owner;
            } else {
                TargetUuid = Default_Uuid;
            }
        }
    }
    llMessageLinked(LINK_THIS, SND_LM_TARGET_UUID, "", TargetUuid);
    // Check if Target UUID is a valid key
    if (TargetUuid) {
        llOwnerSay("Discord IM Online Tracker initialization in progress");
    } else {
        llOwnerSay("ERROR: Invalid Target Avatar UUID " + (string)TargetUuid);
    }

    // Discord Webhook URL
    linksetValue = llLinksetDataRead(DISCORD_LSD_KEY);
    if (IsValidURL(linksetValue)) {
        Discord_URL = linksetValue;
        DiscordRelay = TRUE;
    }

    // Online check interval
    linksetValue = llLinksetDataRead(CHK_INT_LSD_KEY);
    // Check if value is a valid integer or float
    if ((string)((integer)linksetValue) == linksetValue) {
        CheckInterval = (float)linksetValue;
    } else if ((string)((float)linksetValue) == linksetValue) {
        CheckInterval = (float)linksetValue;
    }
    llMessageLinked(LINK_THIS, SND_LM_CK_INTERVAL, (string)CheckInterval, "");

    // Owner Only enable/disable
    linksetValue = llLinksetDataRead(OWNER_O_LSD_KEY);
    if ((linksetValue == "0") || (linksetValue == "1")) {
        ownerOnly = (integer)linksetValue;
    }
    llMessageLinked(LINK_THIS, SND_LM_OWNER_ONLY, (string)ownerOnly, "");

    // Particle display enable/disable
    linksetValue = llLinksetDataRead(BLING_LSD_KEY);
    if ((linksetValue == "0") || (linksetValue == "1")) {
        particles = (integer)linksetValue;
    }
    llMessageLinked(LINK_THIS, SND_LM_BLING, (string)particles, "");

    // Hover Text enable/disable
    linksetValue = llLinksetDataRead(HOVER_LSD_KEY);
    if ((linksetValue == "0") || (linksetValue == "1")) {
        HoverText = (integer)linksetValue;
    }
    llMessageLinked(LINK_THIS, SND_LM_HOVER_TEXT, (string)HoverText, "");

    // Tint enable/disable
    linksetValue = llLinksetDataRead(TINT_LSD_KEY);
    if ((linksetValue == "0") || (linksetValue == "1")) {
        TintSides = (integer)linksetValue;
    }
    llMessageLinked(LINK_THIS, SND_LM_TINT_SIDES, (string)TintSides, "");

    // Online texture
    linksetValue = llLinksetDataRead(ON_TXT_LSD_KEY);
    if ((linksetValue != "") && (llGetInventoryType(linksetValue) == INVENTORY_TEXTURE)) {
        OnlineTexture = linksetValue;
    }
    llMessageLinked(LINK_THIS, SND_LM_ONLINE_TXT, OnlineTexture, "");

    // Offline texture
    linksetValue = llLinksetDataRead(OFF_TXT_LSD_KEY);
    if ((linksetValue != "") && (llGetInventoryType(linksetValue) == INVENTORY_TEXTURE)) {
        OfflineTexture = linksetValue;
    }
    llMessageLinked(LINK_THIS, SND_LM_OFFLINE_TXT, OfflineTexture, "");

    // Custom profile texture
    linksetValue = llLinksetDataRead(PRO_TXT_LSD_KEY);
    if ((linksetValue != "") && (llGetInventoryType(linksetValue) == INVENTORY_TEXTURE)) {
        ProfileTexture = linksetValue;
    }
    llMessageLinked(LINK_THIS, SND_LM_PROFILE_TXT, ProfileTexture, "");

    // Online glow
    linksetValue = llLinksetDataRead(ON_GLOW_LSD_KEY);
    if (linksetValue != "") {
        onlineGlow = (float)linksetValue;
    }
    llMessageLinked(LINK_THIS, SND_LM_ON_GLOW, (string)onlineGlow, "");

    // Offline glow
    linksetValue = llLinksetDataRead(OFF_GLOW_LSD_KEY);
    if (linksetValue != "") {
        offlineGlow = (float)linksetValue;
    }
    llMessageLinked(LINK_THIS, SND_LM_OFF_GLOW, (string)offlineGlow, "");

    // Texture or RGB enable/disable
    linksetValue = llLinksetDataRead(TEXTURE_LSD_KEY);
    if ((linksetValue == "0") || (linksetValue == "1")) {
        UseRGB = (integer)linksetValue;
        UseRGB = !UseRGB;
    }
    llMessageLinked(LINK_THIS, SND_LM_SETSIDE_TXT, (string)UseRGB, "");
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
    SetProfileTexture();
    // Start monitoring immediately
    llSetTimerEvent(CheckInterval);
    // Do an initial check immediately
    agentDataRequestID = llRequestAgentData(TargetUuid, DATA_ONLINE);
    llOwnerSay("[Online Tracker] Ready. Touch to configure.");
}

init_target() {
    SetDefaultTextures();
    GetDatastoreValues();
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
    string aviURL     = "https://my-secondlife-agni.akamaized.net/users/";
    string docURL     = "https://online.neoman.dev/";
    string repURL     = "https://marketplace.secondlife.com/p/Discord-IM-Online-Tracker/28289130";
    // Images
    string footerURL  = "https://raw.githubusercontent.com/missyrestless/OnlineTracker";
    footerURL        += "/refs/heads/main/images/stopwatch.png";
    string footerText = "Time of Second Life";
    if (ols == -1) {
        footerText += " message";
    } else if (ols) {
        footerText += " login";
    } else {
        footerText += " logout";
    }
    string userName = "Second Life Online Tracker " + version;

    // Create the JSON payload, backslashing quotes all over the place
    string json = "{ \"avatar_url\": \"" + aviURL + TargetName + "/thumb_sl_image.png\", " +
                    "\"username\": \"" + userName + "\"," +
                    "\"embeds\": [ { " +
                        "\"title\": \"" + dm + "  (click to view profile)\", " +
                        "\"url\": \"" + webprofURL + "\", " +
                        "\"description\": \"" + et + "\\n\\n🤔 [Online Tracker Documentation](" +
                            docURL + ")\\n👩 [Second Life Marketplace Listing](" + repURL + ")\", " +
                        "\"color\": \"" + D_COL + "\", " +
                        "\"timestamp\": \"" + time + "\", " +
                        "\"footer\": { \"text\": \"" + footerText + "\", " +
                            "\"icon_url\": \"" + footerURL + "\"" +
                        "}" +
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

integer IsValidURL(string url) {
    // Convert to lowercase for easier comparison
    string lower_url = llToLower(url);

    // Check if it starts with http:// or https://
    if (llSubStringIndex(lower_url, "http://") != 0 &&
        llSubStringIndex(lower_url, "https://") != 0) {
        return FALSE;
    }

    // Check for spaces, which are invalid in URLs
    if (llSubStringIndex(url, " ") != -1) {
        return FALSE;
    }

    // Basic length check (URLs must have at least a protocol and a domain)
    if (llStringLength(url) < 11) { // shortest possible: http://a.bc
        return FALSE;
    }

    return TRUE;
}
//
// END GENERAL FUNCTIONS
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
        owner         = llGetOwner();
        IsOnline      = -1; // Indicates uninitialized online status
        lastLogoff    = 0;
        lastLogin     = 0;
        lastLogoffStr = "";
        lastLoginStr  = "";

        init_target();
    }

    // Receive from dialog menu
    link_message(integer sender, integer num, string message, key id) {
        // RCV_LM_SEND_DC_MSG = 100  : Send message string to Discord as message (-1)
        integer RCV_LM_SEND_DC_MSG = 100;
        // RCV_LM_ONLINETOUCH = 101  : Request online status from a touch event
        integer RCV_LM_ONLINETOUCH = 101;
        // RCV_LM_SETSIDE_TXT = 110  : Set side textures
        integer RCV_LM_SETSIDE_TXT = 110;
        // RCV_LM_ONLINE_TXT  = 111  : Recieve online texture
        integer RCV_LM_ONLINE_TXT  = 111;
        // RCV_LM_OFFLINE_TXT = 112  : Recieve offline texture
        integer RCV_LM_OFFLINE_TXT = 112;
        // RCV_LM_OWNER_ONLY  = 113  : Recieve owner only setting
        integer RCV_LM_OWNER_ONLY  = 113;
        // RCV_LM_SET_TINT    = 114  : Tint enable/disable
        integer RCV_LM_SET_TINT    = 114;
        // RCV_LM_WEBHOOK_URL = 200  : Set webhook URL
        integer RCV_LM_WEBHOOK_URL = 200;
        // RCV_LM_TARGET_UUID = 201  : Set Target UUID
        integer RCV_LM_TARGET_UUID = 201;
        // RCV_LM_SET_CHK_VAR = 300  : Set Check Interval
        integer RCV_LM_SET_CHK_VAR = 300;
        // RCV_LM_SET_TIMER   = 301  : Set Timer Event
        integer RCV_LM_SET_TIMER   = 301;
        // RCV_LM_CLEAR_TIMER = 302  : Clear Timer Event
        integer RCV_LM_CLEAR_TIMER = 302;
        // RCV_LM_HOVER_TEXT  = 310  : Set or Clear Hover Text
        integer RCV_LM_HOVER_TEXT  = 310;
        // RCV_LM_BLING       = 311  : Enable or Disable particle display
        integer RCV_LM_BLING       = 311;
        // RCV_LM_ON_GLOW     = 312  : Set online glow status
        integer RCV_LM_ON_GLOW     = 312;
        // RCV_LM_OFF_GLOW    = 313  : Set offline glow status
        integer RCV_LM_OFF_GLOW    = 313;
        // RCV_LM_ON_TINT     = 314  : Set online tint color
        integer RCV_LM_ON_TINT     = 314;
        // RCV_LM_OFF_TINT    = 315  : Set offline tint color
        integer RCV_LM_OFF_TINT    = 315;
        // RCV_LM_PROFILE_TXT = 400  : Set custom profile pic
        integer RCV_LM_PROFILE_TXT = 400;

        if (num == RCV_LM_SEND_DC_MSG) {
            D_COL = D_BLU;
            sendToDiscord(llKey2Name(owner), message, -1, llGetTimestamp());
            llRegionSayTo(id, 0, "[Online Tracker] Test message sent.");
        } else if (num == RCV_LM_ONLINETOUCH) {
            if (id == TargetUuid) {
                touchDataRequestID = llRequestAgentData(TargetUuid, DATA_ONLINE);
                llRegionSayTo(id, 0, "[Online Tracker] Test request sent.");
            } else {
                llMessageLinked(LINK_THIS, SND_LM_TARGET_UUID, "", TargetUuid);
                llRegionSayTo(id, 0, "[Online Tracker] TargetUuid mismatch. Try again.");
            }
        } else if (num == RCV_LM_SET_TINT) {
            if (message == (string)TRUE) {
                SetSideTextures();
                TintSides = TRUE;
            } else if (message == (string)FALSE) {
                TintSides = FALSE;
                llSetColor(WHITE, ALL_SIDES);
            }
        } else if (num == RCV_LM_SETSIDE_TXT) {
            if (message == (string)TRUE) {
                UseRGB = FALSE;
            } else if (message == (string)FALSE) {
                UseRGB = TRUE;
            }
            SetSideTextures();
        } else if (num == RCV_LM_ONLINE_TXT) {
            OnlineTexture = message;
            if (!UseRGB) {
                SetSideTextures();
            }
        } else if (num == RCV_LM_OFFLINE_TXT) {
            OfflineTexture = message;
            if (!UseRGB) {
                SetSideTextures();
            }
        } else if (num == RCV_LM_PROFILE_TXT) {
            ProfileTexture = message;
            SetProfileTexture();
        } else if (num == RCV_LM_OWNER_ONLY) {
            ownerOnly = (integer)message;
        } else if (num == RCV_LM_WEBHOOK_URL) {
            Discord_URL = message;
            DiscordRelay = TRUE;
        } else if (num == RCV_LM_TARGET_UUID) {
            TargetUuid = (key)message;
            init_target();
        } else if (num == RCV_LM_SET_CHK_VAR) {
            CheckInterval = (float)message;
            llSetTimerEvent(CheckInterval);
        } else if (num == RCV_LM_SET_TIMER) {
            llSetTimerEvent(CheckInterval);
        } else if (num == RCV_LM_CLEAR_TIMER) {
            llSetTimerEvent(0);
        } else if (num == RCV_LM_HOVER_TEXT) {
            if (message == (string)FALSE) {
                HoverText = FALSE;
                llSetText("", ZERO_VECTOR, 0.0);
            } else if (message == (string)TRUE) {
                HoverText = TRUE;
                if (onlineStatus == "ONLINE") {
                    llSetText(TargetDisplayName + "\nStatus: " + onlineStatus, ONLINE_COL, 1.0);
                } else {
                    llSetText(TargetDisplayName + "\nStatus: " + onlineStatus, OFFLINE_COL, 1.0);
                }
            }
        } else if (num == RCV_LM_BLING) {
            if (message == (string)TRUE) {
                particles = TRUE;
                llSetTimerEvent(10);
                randParticle = (integer)llFrand(2.0);
                if (randParticle == 1) {
                    Bling();
                } else {
                    Hearts();
                }
                particles_on = TRUE;
            } else if (message == (string)FALSE) {
                particles = FALSE;
            }
        } else if (num == RCV_LM_ON_GLOW) {
            onlineGlow = (float)message;
            SetSideTextures();
        } else if (num == RCV_LM_OFF_GLOW) {
            offlineGlow = (float)message;
            SetSideTextures();
        } else if (num == RCV_LM_ON_TINT) {
            ONLINE_COL = (vector)message;
            SetSideTextures();
        } else if (num == RCV_LM_OFF_TINT) {
            OFFLINE_COL = (vector)message;
            SetSideTextures();
        }
    }

    timer() {
        llSetTimerEvent(CheckInterval);
        if (particles_on) {
            particles_on = FALSE;
            ParticlesOff();
        } else {
            // Periodically check status
            agentDataRequestID = llRequestAgentData(TargetUuid, DATA_ONLINE);
        }
    }

    touch_start(integer total_number) {
        // Check if the first person who touched is the owner
        detectedKey = llDetectedKey(0);
        if (detectedKey != owner) {
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
                            llSetTimerEvent(20);
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
        else if (display_name_query == queryid) {
            TargetDisplayName = data;
            llMessageLinked(LINK_THIS, SND_LM_TARGET_NAME, TargetDisplayName, "");
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
