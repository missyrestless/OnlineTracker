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
//
// UUID of the avatar to track
key TargetUuid = NULL_KEY;
// Name of the avatar to track
string TargetName = "";
string TargetDisplayName = "";
// How often to check in seconds (60s minimum recommended)
float CheckInterval = 120.0; 
// ---------------------
// Default fallback if not set in configuration notecard or owner
key Default_Uuid = "094743dc-cb00-483f-9c35-99232e3a71f1";

// Key for agent data requests
key agentDataRequestID = NULL_KEY;
// Keys for HTTP requests
key discordRequestID = NULL_KEY;
key profileRequestID = NULL_KEY;

// Used to calculate time between login/logout
integer lastLogoff = 0;
integer lastLogin = 0;
string  lastLoginStr = "";
string  lastLogoffStr = "";

integer IsOnline = FALSE; // Assume offline initially
integer GetDisplayName = TRUE;
integer HoverText = FALSE;
integer NotecardLine;
// Should online status be sent to owner as an Instant Message
integer IMowner = TRUE;
// Should online status be broadcast to a Discord channel
integer DiscordRelay = FALSE;
string Discord_URL = "";
// The name of the configuration notecard
string CONFIG_CARD = "Target_Config";
key D_QueryID;
key owner = NULL_KEY;
key display_name_query;
key name_query;

// Built-in white texture UUID
string WHT_UUID = "5748decc-f629-461c-9a36-a35a221fe21f";
string D_COL;
string D_RED = "16711680";
string D_GRN = "65280";
vector RED = <1,0,0>;
vector GRN = <0,1,0>;

string profileURL;
string webprofURL;

GetProfilePic(key id) //Run the HTTP Request then set the texture
{
    string URL_RESIDENT = "https://world.secondlife.com/resident/";
    profileRequestID = llHTTPRequest(URL_RESIDENT + (string)id,[HTTP_METHOD,"GET"],"");
}

SetSideTextures(vector col) // Set the sides to the online status texture
{
    integer    i;
    integer    faces = llGetNumberOfSides();
    for (i = 0; i < faces; i++) {
        if (i == 0) {
            llSetColor(<1.0, 1.0, 1.0>, i);
            if (col == RED) {
                llSetPrimitiveParams([PRIM_FULLBRIGHT, i, FALSE]);
            } else {
                llSetPrimitiveParams([PRIM_FULLBRIGHT, i, TRUE]);
            }
        } else {
            llSetTexture(WHT_UUID, i);
            llSetColor(col, i);
            llSetPrimitiveParams([PRIM_GLOW, i, 0.1]);
        }
    }
}

SetDefaultTextures() // Set the sides to their default textures
{
    // Color the root prim red
    llSetTexture(WHT_UUID, ALL_SIDES);
    llSetColor(RED, ALL_SIDES);
}

profile_timer_init() {
    if (HoverText) {
        llSetText(TargetDisplayName + "\nChecking status...", <1.0, 1.0, 1.0>, 1.0); // Initial hover text
    } else {
        // Clear any previously set hover text
        llSetText("", <0,0,0>, 0.0);
    }
    llSetObjectName(TargetDisplayName + " Online Tracker");
    llSetObjectDesc("Sends an IM or Discord message when " + TargetDisplayName + " logs on or off");
    GetProfilePic(TargetUuid);
    // Start monitoring immediately
    llSetTimerEvent(CheckInterval);
    // Do an initial check immediately
    agentDataRequestID = llRequestAgentData(TargetUuid, DATA_ONLINE);
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
string Unix2SLT(integer insecs)
{
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
integer LeapYear(integer year)
{
    return !(year & 3);
}

integer DaysPerMonth(integer year, integer month)
{
    if (month == 2)      return 28 + LeapYear(year);
    return 30 + ( (month + (month > 7) ) & 1);           // Odd months up to July, and even months after July, have 31 days
}

string Convert(integer insecs)
{
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
    string str =  ((string) years + "-" + llGetSubString ("0" + (string) month, -2, -1) + "-" + llGetSubString ("0" + (string) days, -2, -1) + " " +
	llGetSubString ("0" + (string) hours, -2, -1) + ":" + llGetSubString ("0" + (string) mins, -2, -1) );

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
string getElapsedTime(integer secs)
{
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
// dm is message to send, et is elapsed time since last login/logoff, ols is 0/1 logoff/login
// sendToDiscord("message to send", "elapsed time since last log", 0 or 1);
sendToDiscord(string dm, string et, integer ols, string time) {
    string aviURL = "https://my-secondlife-agni.akamaized.net/users/";
    string docURL = "https://online.neoman.dev/";
    string repURL = "https://github.com/missyrestless/OnlineTracker";
    // Images
    string otrURL = "https://raw.githubusercontent.com/missyrestless/OnlineTracker";
    // string icoURL = otrURL + "/refs/heads/main/images/online_icon.png";
    // string ftrURL = otrURL + "/refs/heads/main/images/online_tracker.png";
    string ftrURL = otrURL + "/refs/heads/main/images/stopwatch.png";
    string ftrTXT;
    if (ols) {
        ftrTXT = "Time of Second Life login";
    } else {
        ftrTXT = "Time of Second Life logout";
    }

    // Create the JSON payload, backslashing quotes all over the place
    string json = "{ \"avatar_url\": \"" + aviURL + TargetName + "/thumb_sl_image.png\", " +
                    "\"username\": \"Second Life Online Tracker\", \"embeds\": [ { " +
                    "\"title\": \"" + dm + "  (click to view profile)\", " +
                    "\"url\": \"" + webprofURL + "\", " +
                    "\"description\": \"" + et + "\\n\\n🤔 [Online Tracker Documentation](" +
                        docURL + ")\\n👩 [Online Tracker Github Repository](" + repURL + ")\", " +
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

default
{
    on_rez(integer param) {
        llResetScript();
    }

    state_entry()
    {
        owner = llGetOwner();
        lastLogoff = 0;
        lastLogin = 0;
        lastLogoffStr = "";
        lastLoginStr = "";
        if (llGetInventoryType(CONFIG_CARD) == INVENTORY_NOTECARD) {
            NotecardLine = 0;
            D_QueryID = llGetNotecardLine( CONFIG_CARD, NotecardLine );
        }
        else {
            llOwnerSay("Configuration notecard missing, using defaults.");
            init_target();
        }
    }

    timer()
    {
        // Periodically check status
        agentDataRequestID = llRequestAgentData(TargetUuid, DATA_ONLINE);
    }

    // Allows a touch to force an immediate update
    touch_start(integer num) {
        // Check if the first person who touched is the owner
        if (llDetectedKey(0) == owner) {
            if (HoverText) {
                // Clears the hover text, sets color to black, and makes it 100% transparent
                llSetText("", <0.0, 0.0, 0.0>, 0.0);
            }
            HoverText = !HoverText;
            agentDataRequestID = llRequestAgentData(TargetUuid, DATA_ONLINE);
        }
    }

    dataserver(key queryid, string data)
    {
        integer CurrentlyOnline;
        // Requested data contains the string "0" or "1" for DATA_ONLINE
        // Convert it to an integer and use the boolean as index
        // list index = [   0,       1,     2(0+2), 3(1+2)  ]
        list stat_cols = ["OFFLINE","ONLINE",RED,GRN];
        string status_pre = TargetDisplayName + " is now ";
        string status_msg = "";

        if (queryid == agentDataRequestID) {
            CurrentlyOnline = (integer)data;

            string elapsedTimeStr;
            string timeStamp = llGetTimestamp();
            string status_pre = TargetDisplayName + " is now ";
            string status_msg = "";
            // Set hover text status and color
            string stats = llList2String(stat_cols, CurrentlyOnline);   // boolean/index = 0   or 1
            vector color = llList2Vector(stat_cols, CurrentlyOnline+2); // boolean/index = 0+2 or 1+2
            SetSideTextures(color);

            // IM if status has changed
            if (CurrentlyOnline) {
                if (!IsOnline) {
                    status_pre = status_pre + "ONLINE. Click to view profile: ";
                    status_msg = status_pre + profileURL;
                    lastLogin = llGetUnixTime();
                    if (lastLogoff <= 0) {
                        // No record of last login
                        elapsedTimeStr = "unknown time";
                    } else {
                        elapsedTimeStr = getElapsedTime(lastLogin - lastLogoff);
                        status_msg = status_msg + "\n(Offline for " + elapsedTimeStr + ")";
                    }
                    if (!(DiscordRelay || IMowner)) {
                        llOwnerSay(status_msg);
                    } else {
                        if (IMowner) {
                            llInstantMessage(owner, status_msg);
                        }
                        if (DiscordRelay) {
                            status_msg = "**" + TargetDisplayName + "** is now **ONLINE**";
                            if (lastLoginStr != "") {
                                elapsedTimeStr = elapsedTimeStr + "\\nPrevious login: " + lastLoginStr;
                            }
                            D_COL = D_GRN;
                            sendToDiscord(status_msg, "Offline for " + elapsedTimeStr, 1, timeStamp);
                        }
                    }
                    lastLoginStr = Unix2SLT(llGetUnixTime());
                }
            }
            else {
                if (IsOnline) {
                    status_msg = status_pre + "OFFLINE.";
                    lastLogoff = llGetUnixTime();
                    if (lastLogin <= 0) {
                        // No record of last login
                        elapsedTimeStr = "unknown time";
                    } else {
                        elapsedTimeStr = getElapsedTime(lastLogoff - lastLogin);
                    }
                    if (!(DiscordRelay || IMowner)) {
                        llOwnerSay(status_msg);
                    } else {
                        if (IMowner) {
                            llInstantMessage(owner, status_msg);
                        }
                        if (DiscordRelay) {
                            status_msg = "**" + TargetDisplayName + "** is now **OFFLINE**";
                            if (lastLogoffStr != "") {
                                elapsedTimeStr = elapsedTimeStr + "\\nPrevious logoff: " + lastLogoffStr;
                            }
                            D_COL = D_RED;
                            sendToDiscord(status_msg, "Online for " + elapsedTimeStr, 0, timeStamp);
                        }
                    }
                    lastLogoffStr = Unix2SLT(llGetUnixTime());
                }
            }
            // Set hover text
            if (HoverText) {
              llSetText(TargetDisplayName + "\nStatus: " + stats, color, 1.0); // Update hover text and color
            }

            // Update status
            IsOnline = CurrentlyOnline;
        }
        else if (queryid == D_QueryID) {
            string name;
            string value;
            list temp;
            if ( data != EOF ) {
                if (data == "END_SETTINGS") {
                    init_target();
                    return;
                }
                if ( llGetSubString(data, 0, 0) != "#" &&
                     llStringTrim(data, STRING_TRIM) != "" ) {
                    temp = llParseString2List(data, ["="], []);
                    name = llStringTrim(llList2String(temp, 0), STRING_TRIM);
                    value = llStringTrim(llList2String(temp, 1), STRING_TRIM);
                    if ( value == "TRUE" ) value = "1";
                    if ( value == "FALSE" ) value = "0";
                    if ( name == "TARGET_UUID" ) {
                        TargetUuid = (key)value;
                    } else if ( name == "DISPLAY_NAME" ) {
                        TargetDisplayName = value;
                        GetDisplayName = FALSE;
                    } else if ( name == "CHECK_INTERVAL" ) {
                        CheckInterval = (float)value; 
                    } else if ( name == "HOVER_TEXT" ) {
                        HoverText = (integer)value; 
                    } else if ( name == "DISCORD_URL" ) {
                        Discord_URL = value;
                        DiscordRelay = TRUE;
                    } else if ( name == "IM_OWNER" ) {
                        IMowner = (integer)value; 
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

    changed(integer change)
    {
         if (change & (CHANGED_OWNER | CHANGED_INVENTORY)) {
             llResetScript();
         }
    }

    http_response(key req,integer status, list met, string body)
    {
        if (req == discordRequestID) {
            discordRequestID = NULL_KEY;
            if (status != 200 && status != 204) // Discord returns 204 No Content on success
            {
                llOwnerSay("Error sending to Discord. Status: " + (string)status);
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
