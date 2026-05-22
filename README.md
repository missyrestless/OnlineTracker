# Discord IM Online Tracker

The `Discord IM Online Tracker` monitors the online status of any avatar in Second Life and sends notices of login/logoff to the owner of the object and/or a configured Discord channel.

See [https://online.neoman.dev](https://online.neoman.dev) for full documentation and How-To articles.

## Table of Contents

- [FEATURES](#features)
- [CONTENTS](#contents)
- [LICENSE](#license)
- [RELEASES](#releases)
- [SETUP STEPS](#setup-steps)
- [CONFIGURATION](#configuration)
- [CHANGING THE TRACKED AVATAR](#changing-the-tracked-avatar)
- [DISCORD SETUP](#discord-setup)
- [FEEDBACK](#feedback)

## FEATURES

The Discord IM Online Tracker is a sculpted & scripted prim with the following features

- Can track the online status of any Avatar, not just your friends
- Can be configured to display the online status in any or all of the following ways:
    - Send an IM to the owner
    - Post a message to a Discord Channel
    - Display as hover text over the object
    - Send a message to the owner in local chat
- The tracked Avatar need not be in the same region, grid-wide tracking is performed
- Elapsed time between login/logout is displayed as well as the login/logout times
- Previous login/logout times are displayed
- The online status of the configured Avatar is indicated by the object's border color, red or green
- The online status messages contain a clickable link to the Avatar's profile
- Online status notifications can be monitored when you are offline if Discord is configured
- The frequency of Online status updates can be configured [Default: every 2 minutes]
- The in-world object is a beveled frame displaying the tracked Avatar's profile pic and online status
- The beveled frame can be customized in several ways
    - A custom picture can be configured rather than the Avatar's profile pic
    - Custom textures or texture UUIDs can be provided to texture the bevels on the frame
    - Glow and color of the frame bevels can be customized
- Touch the object to receive a status update (configurable to owner only or all)
- Touch and hold for 2 seconds to open a configuration dialog menu (owner only)
- Mouse hover over the in-world object will display the online status in the object description
- Optimized low lag script and only a single prim
- Open Source, GPL Version 3 licensed script, view the source on [Github](https://github.com/missyrestless/OnlineTracker)

## CONTENTS

After unpacking the product box, find the Discord IM Online Tracker folder in your inventory. This folder will contain the following:

- "Discord IM Online Tracker (rez me)" object
- "Target_Config" notecard
- "Features and Setup Instructions - README" notecard

### Permissions

- Discord IM Online Tracker (rez me) object is Copy/Modify/No Transfer
- Discord IM Online Tracker script is Copy/No Modify/No Transfer
- Target_Config notecard is Copy/Modify/Transfer

## LICENSE

The `Discord_IM_Online_Tracker.lsl` script is released under the terms of the GNU General Public License version 3 (GPLv3). This is a strong copyleft free software license. Its primary terms guarantee users the freedom to run, study, share, and modify the software. In return, any publicly distributed modifications or derivative works must also be released under the same GPLv3 terms.

### Core Permissions

- Commercial and Private Use: You can use, modify, and privately use the software for any purpose, including commercial operations.
- Redistribution: You are permitted to share or sell the software, provided you pass on the exact same freedoms to recipients.

### Key Obligations

- Source Code Disclosure: If you distribute a compiled binary to the public, you must also provide the complete, corresponding source code.
- Notice Requirements: You must keep all original copyright notices intact and visibly display that the modified work is licensed under the GPLv3.
- Same License (Copyleft): Any additions, modifications, or derivatives must be made completely free and licensed under the same GPLv3 terms.

### Second Life and Open Source

Software theft and piracy is rampant in Second Life. For example, almost all of the commercial Animation Overriders (AO) available in Second Life are based on the GPL AO created years ago by Zhao but none of these commercial vendors make their source code available nor have they complied with the licensing terms of the GPL. They reap significant profits and do not contribute back to the open source community. It is basically the Wild Wild West out there with little or no enforcement of license terms and very little action from Linden Labs to curb this behavior.

The Truth &amp; Beauty Lab creates open source projects for Second Life and complies with open source licensing in all of its products and projects. We encourage others to do so as well. Open source thrives when there is an active community contributing to its development and adoption. In the absence of any effective enforcement mechanism, compliance and contribution to open source projects in Second Life must rely almost entirely on a community of cooperative and supportive individuals. Please join us in this effort.

## RELEASES

To create a Discord IM Online Tracker from release artifacts in this repository, download the `Discord_IM_Online_Tracker.lslo` optimized LSL script and `Target_Config` notecard from the latest release. Upload these to Second Life and copy them into a prim.

Edit the `Target_Config` notecard, replacing "target-avatar-uuid" with the UUID of the Avatar you wish to track.

Note that creating a custom scripted prim from release artifacts may not function as expected. The prim needs to be sculpted in the proper manner and prim faces numbered matching what the script expects. The Second Life Marketplace listing for this product includes a rezzable object already prepared in this manner. The DIY approach using release artifacts may require additional effort but is provided for those who wish to experiment and customize.

More detailed setup instructions can be found in the `Features_and_Setup_Instructions.txt` release artifact or this README.

## SETUP STEPS

### Rez a copy of the "Discord IM Online Tracker (rez me)" object:

Drag and Drop the "Discord IM Online Tracker (rez me)" object from your inventory to an in-world location.

The online tracker initially begins to track the owner's online status.

To configure an Avatar to track proceed to setup step 2.

### Edit the "Target_Config" notecard:

- Right click the "Target_Config" notecard in your inventory and select "Open"
- Replace "target-avatar-uuid" with the UUID of the Avatar you wish to track
  - The UUID of an Avatar is displayed in their Profile as the Key just under their Name
  - Copy and Paste the Key from the Avatar Profile into the Target_Config notecard
- Save the modified notecard and close the Edit window

### Drag and Drop the "Target_Config" notecard onto the rezzed Discord IM Online Tracker object

You can repeat this process for as many Avatars as you wish to track, one Avatar per rezzed tracker object.

Each rezzed online tracker object will rename itself with the tracked Avatar display name in its object name.

## CONFIGURATION

The rezzed `Discord IM Online Tracker` object can be configured and customized by editing
the `Target_Config` notecard in the object's inventory Contents. The only required setting
in this notecard is `TARGET_UUID` and the default settings for all other configuration
parameters should work well. However, if you wish to customize the object and its behavior
you can do so in a variety of ways:

- `CUSTOM_PROFILE` sets an alternate picture to use on the main face of the prim
    - Drag and drop a texture to use into the object's Contents and set to the texture name
    - Or set this to a valid texture UUID
    - If not set then the target avatar's profile pic is used
- `DISCORD_URL` sets the Discord channel Webhook URL
    - See the section [DISCORD SETUP](#discord-setup) below
    - If not set then no Discord messages are delivered, only IM to owner or local chat to owner
- `IM_OWNER` enable or disable IM notifications to owner
    - Set to `TRUE` to enable or `FALSE` to disable
    - If not set then the default behavior is IM notifications to owner are enabled
- `OWNER_ONLY` enable or disable restriction of notifications to owner
    - If `FALSE` non-owner users can click the object to get an online status message in local chat
    - If not set then the default behavior is restrict notifications to owner
- `HOVER_TEXT` enable or disable hover text display on startup
    - Set to `TRUE` to enable hover text on startup or `FALSE` to disable
    - Regardless of setting, hover text display can be toggled by clicking the object
    - If not set then the default behavior is hover text on startup is disabled
- `DISPLAY_NAME` sets the target avatar display name to use
    - Notification messages will refer to the target avatar by this name
    - If not set then the target avatar's display name is used
- `CHECK_INTERVAL` sets the interval, in seconds, between online status checks
    - Custom setting for this parameter should be a value greater than or equal to 60
    - If not set then the interval between checks is 120 seconds (2 minutes)
    - Note: the interval between status checks may take longer due to delays in the request
- `FRAME_STYLE` sets the frame style
    - The object is a beveled frame and the sides are textured and colored to indicate status
    - Currently two frame styles are supported, `RGB` and `Texture`, and can be configured with this setting
    - If not set then the default frame style is `Texture`. Set to `RGB` to use colors rather than textures.
- `TEXTURE_ONLINE` sets the online texture to use for `Texture` frame style
    - This setting can be the name of a texture in the object's inventory or a valid texture UUID
    - If not set then the `Online-Oak` texture is used to indicate online status
- `TEXTURE_OFFLINE` sets the offline texture to use for `Texture` frame style
    - This setting can be the name of a texture in the object's inventory or a valid texture UUID
    - If not set then the `Offline-Rosewood` texture is used to indicate offline status
- `TEXTURE_TINT` enable or disable tinting of side textures
    - Set to `TRUE` to enable tinting or `FALSE` to disable
    - If not set then tinting is enabled
- `COL_ONLINE` sets the color vector to use for tinting the sides to indicate online
    - This setting must be a valid color vector
    - If not set then `<0.180, 0.800, 0.251>` is used to indicate online status
- `COL_OFFLINE` sets the color vector to use for tinting the sides to indicate offline
    - This setting must be a valid color vector
    - If not set then `<1.000, 0.255, 0.212>` is used to indicate offline status
- `GLOW_ONLINE` sets the online glow status
    - The value should be a floating decimal between 0 and 1
    - If not set then the online glow status is set to `0.2`
- `GLOW_OFFLINE` sets the offline glow status
    - The value should be a floating decimal between 0 and 1
    - If not set then the offline glow status is set to `0.0`

### Default Target_Config notecard

The initial settings in the `Target_Config` notecard only set the `TARGET_UUID` to the dummy
value of `target-avatar-uuid`. All other settings use their default values as described above.
This dummy `TARGET_UUID` will result in the object tracking the online status of its owner.

Set `TARGET_UUID` to a valid avatar UUID to configure tracking. This is the only setting that is required.

Default `Target_Config` notecard:

```bash
TARGET_UUID = target-avatar-uuid
END_SETTINGS
```

### Configuration Dialog Menu

The owner of the rezzed `Discord IM Online Tracker` object can also configure and customize it by
left clicking and holding the mouse button down for a few seconds. When the mouse button is released
after a long click a dialog menu is displayed with buttons to configure the object's behavior and
appearance. These dialog menus can be used to:

- Enable or disable status display in Hover Text
- Enable or disable tinting of the frame border to further indicate online status
- Enable or disable frame border textures/colors
- Select frame border online and offline textures
- Select frame border online and offline tint color
- Select frame online and offline glow status
- Start or Stop tracking online status

## CHANGING THE TRACKED AVATAR

To change the tracked Avatar of an existing and already configured Discord IM Online Tracker, edit the object and change the TARGET_UUID setting in the Target_Config notecard.

### Edit the Discord IM Online Tracker object

   - Right click the Discord IM Online Tracker object and select "Edit"
   - Click the Contents tab in the Edit window

### Edit the Target_Config notecard

   - Right click the Target_Config notecard in the Contents tab and select "Open"
   - Replace the existing setting of the TARGET_UUID with the new tracked Avatar UUID (Key)

### Save the Target_Config notecard and close the Edit window

The Discord IM Online Tracker will detect the change and reset, tracking the new Avatar's online status

## DISCORD SETUP

### What is Discord?

Discord is a chat platform very popular among gamers. Using Discord is free, and everyone can set up a "Discord server" for free as well! In this server, you can create channels. The Discord IM Online Tracker can be configured to post status messages to a Discord channel. For more information see https://en.wikipedia.org/wiki/Discord_(software) and https://discord.com/blog/starting-your-first-discord-server

### Getting started

In order to be able to communicate from SL to Discord, you need to create a "Webhook". To do this this, you need your own Discord server or a server you co-administer. For testing purposes, we highly recommend to make a new server (it's free!), or at least create a new channel on your existing server.

The Webhook is best created in the Discord web application;  NOT on the mobile app! Please refer to the video - https://www.youtube.com/watch?v=AKOIPxqHYI8 - to see how/where to get the Webhook. Be aware that the way the interface looks might have changed since then.

In the channel list, you will find a small cogwheel icon, that gets you to the channel configuration. Click it, chose "Integrations" and click on "Create Webhook". The name of the Webhook is irrelevant (and won't show up anywhere). All you need is the Webhook URL, which looks like this:

```
https://discord.com/api/webhooks/aaaaaalotofgibberishandnumbersandsuch
```

The Webhook might also look like this:

```
https://discordapp.com/api/webhooks/aaaaaalotofgibberishandnumbersandsuch
```

Or like this:

```
https://ptb.discord.com/api/webhooks/aaaaaalotofgibberishandnumbersandsuch
```

All three versions work fine - just use whichever Discord gives you.

### Configuration

Once the Webhook is created, you need to configure the online tracker. A configuration notecard is provided. In case it is missing, create a new one with the name "Target_Config".

The notecard contains variable/argument pairs, separated by equal signs " = ". Everything the online tracker does not recognize, gets ignored.

The "Target_Config" notecard contains one variable pertaining to Discord:

```bash
# Set to a Discord channel Webhook URL to send online status to Discord [Default: disabled]
DISCORD_URL = https://discord.com/api/webhooks/xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

"DISCORD_URL" is simply the setting where you input your Webhook URL from Discord (see above). 

Make sure the Webhook exists and is created for the proper channel. You can change it anytime, if you want to have it transmit to a different channel on your server.

To enable online status messages to be posted to your Discord channel, all that is required is configuring the DISCORD_URL setting in the Target_Config notecard with your Discord channel Webhook URL. Note that only lines above the END_SETTINGS line in the notecard get read - the DISCORD_URL setting must be placed above this line.

### Data processing & privacy

This product communicates directly from Second Life to Discord. It establishes a direct transmission from the object in Second Life to the Discord servers. At no single point does the communication get stored, relayed, routed, redirected, or otherwise processed by us, or any entity under our control. We can't, for obvious reasons, vouch for the operators of Second Life or Discord. Please refer to their respective privacy policies.

#### Linden Lab's rules & regulations

The Lab has repeatedly refined resident's rights in various documents. As a user of this product (or any product of broadly similar nature), you are obliged to adhere to the regulations in those documents.

Second Life Terms of Service: https://www.lindenlab.com/tos

Second Life Community Standards: https://www.lindenlab.com/legal/community-standards

Linden Lab use of personal data: https://wiki.secondlife.com/wiki/Linden_Lab_Official:Using_Personal_Data

In order to use this product you need to abide to the requirements laid out in those documents (and any documents the Lab might add during your usage of this product).

## FEEDBACK

Please let us know if you run into issues with this product or have any suggestions. Also let us know if you like it. We are open to feature requests. Email missyrestless@gmail.com or send an IM or notecard to [Missy Restless](secondlife:///app/agent/3506213c-29c8-4aa1-a38f-e12f6d41b804/about) in-world.
