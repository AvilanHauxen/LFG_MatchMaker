# LFG MatchMaker

**An easy to use LFG/LFM chat-monitoring tool to easier find dungeon groups of your chosing and elimintate the need to manually read through the chat for ages to find a group.**


## How it works

LFG MatchMaker will interpret messages in "LookingForGroup" channel and categorize messages into LFG or LFM and dungeons mentioned.

The addon will match dungeons on various pronunciations (and mispronunciations), in multiple languages, and will find matches for multiple dungeons in a single message.

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

The message that was matched is presented and you have the option to ignore the message and continue the search, request an invite (LFG) or invite the player (LFM).

Buttons to issue a /who request for the player and to whisper the player is also available for an easy way to gather more information before making a decision.

Any role limitations on the message will have to be interpreted manually, as the addon does not provide any role-check functionality.


## Broadcast

When searching for dungeon matches you can opt-in to also broadcast a fully customizable message at intervals to the "LookingForGroup" channel.

Due to limitations of the API, messages can only be sent to the channel by the click of a button.

Therefore a dialog window with a button to re-broadcast the message will be shown at subsequent intervals to the first broadcast.


## List

A list of all recent announcements can be viewed and filtered on group type (LFG/LFM) as well as which dungeon matches to show.

There is also an "Unknown" filter for messages where dungeon and/or group type could not be determined.

Annoucements will only be listed once per player, and will be updated with the most recent message posted by that player.

Though, messages that do not match any dungeons will not overwrite a previous message that did match a dungeon.

When an announcement has not been re-announced for over 30 minutes, the announcement will expire and be forgotten.


## Chat channels

LFG MatchMaker mainly listens to messages in the "LookingForGroup" channel.

There are no hidden messages or channels, only interpretation of messages being announced..

It is also possible to opt-in to include messages from General and/or Trade channel.

For these additional channels, only messages that match both dugeon and group type (LFG/LFM) will be listed to prevent a large amount of false positive matches.


## Identifiers

Dungeons and group type (LFG/LFM) are primarly identified in english, but support for localized identifiers can be enabled for the following languages:

* German
* French
* Spanish


## Improving identifiers

Any assistance in making the identifiers (in any language) as accurate as possible is appricated.

If you notice a message that is incorrectly identified please let me know by creating an issue on GitHub.
