# TWRA Sync System Issues & Solutions

## Current Issues

At times clients report that they do not have all the data they need. The RequestMissingSectionsWhisper function is not implmented and since whisper has been problematic we do not want to implement it; let's take another route. When a client is detecting that they are missing data they should be requesting it in the group channel (part/raid) rather than whispers. This is only a partially related symptom of an underlaying problem

At the core Client A (imports data) should be sending out all the information that's needed for the other clients when they've processed it and are ready to share. The only time someone should need to request data is if they were not available when the assignments were imported. In a good scenario anyone who's gotten information from client A has the complete picture and can share the full data.

This specific root issue we've been experiencing is of another nature though. When Client A iports their data the amount of sections that they are trying to share does not match the sections actually added. This does not seem to happen with all assignments (different sheets, IE some aprts of Naxxramas are fine, others have issues) which leads me to believe that there's something happening with the data that gets imported. From what I've been able to tell the data we need is added to the addon but there's something else behind the scenes happening, adding ghost sections that just are not visible at all.

[TWRA: data] [8912.29s] WARNING: 1 sections still missing after processing: 15
[TWRA: error] [8912.30s] Interface\AddOns\TWRA\sync\SyncHandlers.lua:834: attempt to call method RequestMissingSectionsWhisper' (a nil value) [TWRA: data] [8912.32s] WARNING: 1 sections still missing after processing: 15 [TWRA: error] [8912.33s] Interface\AddOns\TWRA\sync\SyncHandlers.lua:834: attempt to call method RequestMissingSectionsWhisper' (a nil value)

Last time we ran into this issue we imported assignments with 9 sections and we were still seeing that there should be more, 15 iirc but don't quote me on that. The importing clients needs to validate their data before they send it to the rest of the group.


## Problematic Scenario
Multiple clients have the complete picture of data after import and not just Client A has the complete picture. I am uncertain if we've got any measures in place to avoid multiple clients from trying to share their data when a data request is presented to the group.