Thank you for purchasing the Discord IM Online Tracker!

FEATURES
────────

The Discord IM Online Tracker is a sculpted & scripted prim with the following features

- Can track the online status of any Avatar, not just your friends
- Can be configured to display the online status in any or all of the following ways:
    - Send an IM to the owner
    - Post a message to a Discord Channel
    - Display as hover text over the object
    - Send a message to the owner in local chat
- Elapsed time between login/logout is displayed as well as the login/logout times
- The tracked Avatar need not be in the same region, grid-wide tracking is performed
- The online status of the configured Avatar is indicated by the object's border color, red or green
- The online status messages contain a clickable link to the Avatar's profile
- The frequency of Online status updates can be configured [Default: every 2 minutes]
- The owner can touch the object to force a status update and toggle hover text display
- Optimized low lag script and only a single prim
- Open Source, GPL Version 3 licensed script, view the source on Github at https://github.com/missyrestless/OnlineTracker

CONTENTS
────────

After unpacking the product box, find the Discord IM Online Tracker folder in your inventory.
This folder will contain the following:

- "Discord IM Online Tracker (rez me)" object
- "Target_Config" notecard
- "Features and Setup Instructions - README" notecard

Permissions:
    Discord IM Online Tracker (rez me) object is Copy/Modify/No Transfer
    Discord IM Online Tracker script is Copy/No Modify/No Transfer
    Target_Config notecard is Copy/Modify/Transfer

SETUP STEPS
───────────

1. Rez a copy of the "Discord IM Online Tracker (rez me)" object:

   Drag and Drop the "Discord IM Online Tracker (rez me)" object from your inventory to an in-world location.

   The online tracker initially begins to track the owner's online status.
   To configure an Avatar to track proceed to setup step 2.

2. Edit the "Target_Config" notecard:

   Right click the "Target_Config" notecard in your inventory and select "Open"
   Replace "target-avatar-uuid" with the UUID of the Avatar you wish to track
     The UUID of an Avatar is displayed in their Profile as the Key just under their Name
     Copy and Paste the Key from the Avatar Profile into the Target_Config notecard
   Save the modified notecard and close the Edit window

3. Drag and Drop the "Target_Config" notecard onto the rezzed Discord IM Online Tracker object

You can repeat this process for as many Avatars as you wish to track, one Avatar per rezzed tracker object.

Each rezzed online tracker object will rename itself with the tracked Avatar display name in its object name.

CHANGING THE TRACKED AVATAR
───────────────────────────

To change the tracked Avatar of an existing and already configured Discord IM Online Tracker, edit the object and change the TARGET_UUID setting in the Target_Config notecard.

1. Edit the Discord IM Online Tracker object

   - Right click the Discord IM Online Tracker object and select "Edit"
   - Click the Contents tab in the Edit window

2. Edit the Target_Config notecard

   - Right click the Target_Config notecard in the Contents tab and select "Open"
   - Replace the existing setting of the TARGET_UUID with the new tracked Avatar UUID (Key)

3. Save the Target_Config notecard and close the Edit window

The Discord IM Online Tracker will detect the change and reset, tracking the new Avatar's online status

DEFAULT CONTENTS OF Target_Config NOTECARD
──────────────────────────────────────────

# Only the tracked Avatar UUID is required, all other configuration settings are optional
TARGET_UUID = target-avatar-uuid
END_SETTINGS
#
# Optional settings, uncomment & move above END_SETTINGS to enable
#
# Set to a Discord channel Webhook URL to send online status to Discord [Default: disabled]
# DISCORD_URL = https://discord.com/api/webhooks/xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
#
# Messages will appear to be from this user [Default: Discord IM Online Tracker]
# DISCORD_USER = Discord IM Online Tracker
#
# Enable or disable Instant Message notification to the owner [Default: TRUE]
# IM_OWNER = TRUE
#
# Enable or disable display of hover text [Default: FALSE]
# HOVER_TEXT = FALSE
#
# Override the displayed target name [Default: use display name]
# TARGET_NAME = Target Avatar Name
#
# Time in seconds between online status checks [Default: 120.0]
# CHECK_INTERVAL = 120.0

DISCORD SETUP
─────────────

What is Discord?
────────────────

Discord is a chat platform very popular among gamers. Using Discord is free, and everyone can set up a "Discord server" for free as well! In this server, you can create channels. The Discord IM Online Tracker can be configured to post status messages to a Discord channel. For more information see https://en.wikipedia.org/wiki/Discord_(software) and https://discord.com/blog/starting-your-first-discord-server

Getting started
───────────────

In order to be able to communicate from SL to Discord, you need to create a "Webhook". To do this this, you need your own Discord server or a server you co-administer. For testing purposes, we highly recommend to make a new server (it's free!), or at least create a new channel on your existing server.

The Webhook is best created in the Discord web application;  NOT on the mobile app! Please refer to the video - https://www.youtube.com/watch?v=AKOIPxqHYI8 - to see how/where to get the Webhook. Be aware that the way the interface looks might have changed since then.

In the channel list, you will find a small cogwheel icon, that gets you to the channel configuration. Click it, chose "Integrations" and click on "Create Webhook". The name of the Webhook is irrelevant (and won't show up anywhere). All you need is the Webhook URL, which looks like this:

https://discord.com/api/webhooks/aaaaaalotofgibberishandnumbersandsuch

The Webhook might also look like this:

https://discordapp.com/api/webhooks/aaaaaalotofgibberishandnumbersandsuch

Or like this:

https://ptb.discord.com/api/webhooks/aaaaaalotofgibberishandnumbersandsuch

All three versions work fine - just use whichever Discord gives you.

Configuration
─────────────

Once the Webhook is created, you need to configure the online tracker. A configuration notecard is provided. In case it is missing, create a new one with the name "Target_Config".

The notecard contains variable/argument pairs, separated by equal signs " = ". Everything the online tracker does not recognize, gets ignored.

The "Target_Config" notecard contains two variables pertaining to Discord:

# Set to a Discord channel Webhook URL to send online status to Discord [Default: disabled]
DISCORD_URL = https://discord.com/api/webhooks/xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
# Messages will appear to be from this user [Default: Discord IM Online Tracker]
DISCORD_USER = Discord IM Online Tracker

"DISCORD_URL" is simply the setting where you input your Webhook URL from Discord (see above). 

Make sure the Webhook exists and is created for the proper channel. You can change it anytime, if you want to have it transmit to a different channel on your server.

To enable online status messages to be posted to your Discord channel, all that is required is configuring the DISCORD_URL setting in the Target_Config notecard with your Discord channel Webhook URL. Note that only lines above the END_SETTINGS line in the notecard get read - the DISCORD_URL setting must be placed above this line.

Data processing & privacy
─────────────────────────

This product communicates directly from Second Life to Discord. It establishes a direct transmission from the object in Second Life to the Discord servers. At no single point does the communication get stored, relayed, routed, redirected, or otherwise processed by us, or any entity under our control. We can't, for obvious reasons, vouch for the operators of Second Life or Discord. Please refer to their respective privacy policies.

Linden Lab's rules & regulations
────────────────────────────────
The Lab has repeatedly refined resident's rights in various documents. As a user of this product (or any product of broadly similar nature), you are obliged to adhere to the regulations in those documents.

Second Life Terms of Service: https://www.lindenlab.com/tos
Second Life Community Standards: https://www.lindenlab.com/legal/community-standards
Linden Lab use of personal data: https://wiki.secondlife.com/wiki/Linden_Lab_Official:Using_Personal_Data

In order to use this product you need to abide to the requirements laid out in those documents (and any documents the Lab might add during your usage of this product).


Suggestions, Bug Reports, Feature Requests
──────────────────────────────────────────

Please let us know if you run into issues with this product or have any suggestions. Also let us know if you like it. We are open to feature requests. Email missyrestless@gmail.com or send an IM or notecard to Missy Restless in-world.
