# LFG MatchMaker

**An easy to use LFG/LFM chat-monitoring tool to easier find dungeon groups of your chosing and elimintate the need to manually read through the chat for ages to find a group.**


## How it works

LFG MatchMaker will interpret messages in "LookingForGroup" channel and categorize messages into LFG or LFM and into dungeons mentioned.

The addon is configured to match various pronunciations (and mispronunciations) of dungeon names and will find matches for multiple dungeons in a single message.

It is simple to use, and no configuration is required to start using it.

**It does not require any other players to install the same addon.**


## Getting started

A button to open LFG Matchmaker is available both on the bottom of the quest log window and on the minimap.

Additionally it can be opened by using any of the following slash commands:

* /lfgmm
* /lfgmatchmaker
* /matchmaker


## Searching

When search is activated, a notification will be shown when a message matching the dungeon(s) you have selected is announced.

The message that was mached is presented and you have the option to ignore the message and continue the search, or request an invite (LFG) or invite the player (LFM).

Buttons to issue a /who request for the player and to whisper the player is also shown for an easy way to gather more information before making a decision.

Any role limitations on the message will have to be interpreted manually, as the addon does not provide any role-check functionality.


## Broadcast

When searching for dungeon matches you can opt-in to also broadcast a fully customizable message at intervals to the "LookingForGroup" channel.

Due to limitations of the API, messages can only be sent to the channel by the click of a button.

Therefore a dialog window with a button to re-broadcast the message will be shown at subsequent intervals to the first broadcast.


## List

A list of all recent announcements can be viewed and filtered on LFG/LFM as well as which dungeon matches to show.

There is also an "Unknown" filter for messages that could not be categorized.

Annoucements will only be listed once per player, and will be updated with the most recent message posted by that player.


## Chat channel

LFG MatchMaker only listens to the "LookingForGroup" channel.

There are no hidden messages or channels, only interpretation of what is being announced in "LookingForGroup" channel.
