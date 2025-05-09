# TWRA Function Map

This document maps all functions in the TWRA addon, showing where they are defined and where they are referenced throughout the codebase.

## 1. Core Files

### 1.1 TWRA.lua

- `TWRA:NavigateToSection()` - Line 12
  - Referenced in:
    - core/Base64.lua:455 (in if )
    - core/Base64.lua:457
    - core/Base64.lua:502 (in if )
    - core/Base64.lua:504
    - core/Base64.lua:853 (in if )
    - core/Base64.lua:855
    - core/Base64.lua:906 (in if )
    - core/Base64.lua:908
    - core/Compression.lua:770 (in if )
    - core/Compression.lua:771
    - Example.lua:381
    - Example.lua:506
    - TWRA.lua:339
    - core/Core.lua:449
    - core/Core.lua:598
    - core/DataUtility.lua:513 (in if )
    - core/DataUtility.lua:515
    - ui/Frame.lua:385
    - ui/Minimap.lua:770
    - features/AutoNavigate.lua:243
    - sync/SyncHandlers.lua:167
    - sync/SyncHandlers.lua:380 (in if )
    - sync/SyncHandlers.lua:384
    - sync/SyncHandlers.lua:415 (in if )
    - sync/SyncHandlers.lua:416

- `TWRA:Initialize()` - Line 152
  - Referenced in:
    - TWRA.lua:827

- `TWRA:OnChatMsgAddon()` - Line 352
  - Referenced in:
    - sync/Sync.lua:354 (in function )
    - sync/Sync.lua:498

- `TWRA:TruncateString()` - Line 369
  - Referenced in:
    - TWRA.lua:359

- `TWRA:CleanAssignmentData()` - Line 375
  - Referenced in:

- `TWRA:IsExampleData()` - Line 432
  - Referenced in:
    - Example.lua:524 (in function )
    - Example.lua:525 (in self:Debug("error", ")
    - ui/Frame.lua:5 (in function )
    - ui/Frame.lua:6 (in self:Debug("error", " )

- `TWRA:AnnounceAssignments()` - Line 448
  - Referenced in:
    - ui/Frame.lua:133

- `TWRA:SendAnnouncementMessages()` - Line 633
  - Referenced in:
    - TWRA.lua:630

- `TWRA:GetAnnouncementChannels()` - Line 721
  - Referenced in:
    - TWRA.lua:640 (in local channelInfo = )

- `TWRA:ShowOptionsView()` - Line 829
  - Referenced in:
    - core/Core.lua:459
    - ui/Frame.lua:116
    - ui/Minimap.lua:350 (in if )
    - ui/Minimap.lua:351
    - ui/Minimap.lua:357 (in if )
    - ui/Minimap.lua:358

- `TWRA:OnGroupChanged()` - Line 874
  - Referenced in:
    - core/Core.lua:748 (in function )
    - core/Core.lua:795
    - core/Core.lua:800

### 1.2 core/Base64.lua

- `TWRA:CompressAssignmentsData()` - Line 87
  - Referenced in:
    - core/Base64.lua:764 (in local compressedData = )

- `TWRA:DecompressAssignmentsData()` - Line 131
  - Referenced in:
    - core/Base64.lua:528 (in local decompressedData = )
    - core/Compression.lua:651 (in function )
    - core/Compression.lua:717 (in local decompressedData = )

- `TWRA:PrepareDataForSync()` - Line 179
  - Referenced in:
    - core/Base64.lua:763 (in local syncReadyData = )

- `TWRA:ExpandAbbreviations()` - Line 230
  - Referenced in:
    - core/Base64.lua:694 (in result = )

- `TWRA:DecodeBase64Raw()` - Line 342
  - Referenced in:
    - core/Base64.lua:149 (in compressedString = )
    - core/Compression.lua:287 (in return )
    - core/Compression.lua:292 (in return )
    - core/Compression.lua:296 (in return )
    - core/Compression.lua:430 (in local decodedString = )
    - core/Compression.lua:678 (in local binaryData = )

- `TWRA:HandleImportedData()` - Line 423
  - Referenced in:
    - core/Base64.lua:553

- `TWRA:DecodeBase64()` - Line 509
  - Referenced in:
    - ui/Options.lua:1088 (in local decodedString = )

- `TWRA:TableToLuaString()` - Line 938
  - Referenced in:
    - core/Base64.lua:950 (in result = result .. )
    - core/Base64.lua:968 (in result = result .. )

- `TWRA:EncodeBase64()` - Line 985
  - Referenced in:
    - core/Base64.lua:125 (in local base64String = )
    - core/Compression.lua:141 (in local encodedData = )
    - core/Compression.lua:159 (in local encodedData = )
    - core/Compression.lua:257 (in compressed = )

### 1.3 core/Compression.lua

- `TWRA:InitializeCompression()` - Line 5
  - Referenced in:
    - core/Compression.lua:82 (in if not )
    - core/Compression.lua:172 (in if not )
    - core/Compression.lua:316 (in if not )
    - core/Compression.lua:438 (in if not )
    - core/Compression.lua:672 (in if not )
    - core/Core.lua:90 (in if )
    - core/Core.lua:91 (in if )
    - core/DataProcessing.lua:406 (in if )
    - core/DataProcessing.lua:407

- `TWRA:SerializeTable()` - Line 28
  - Referenced in:
    - core/Compression.lua:57 (in result = result .. )
    - core/Compression.lua:242 (in local serialized = )

- `TWRA:CompressStructureData()` - Line 79
  - Referenced in:
    - core/Compression.lua:610 (in local structureData = )

- `TWRA:CompressSectionData()` - Line 169
  - Referenced in:
    - core/Compression.lua:632 (in local sectionData = )
    - sync/Sync.lua:809 (in if )
    - sync/Sync.lua:811 (in sectionData = )

- `TWRA:DecompressStructureData()` - Line 263
  - Referenced in:
    - sync/SyncHandlers.lua:295 (in return )

- `TWRA:DecompressSectionData()` - Line 405
  - Referenced in:
    - core/DataProcessing.lua:603 (in if )
    - core/DataProcessing.lua:604 (in return )

- `TWRA:FillMissingIndices()` - Line 486
  - Referenced in:
    - core/Compression.lua:483 (in return )
    - core/Compression.lua:495 (in inputTable[key] = )

- `TWRA:StoreSegmentedData()` - Line 592
  - Referenced in:
    - core/Compression.lua:746
    - core/DataProcessing.lua:411 (in if )
    - core/DataProcessing.lua:413 (in return )
    - core/DataUtility.lua:448 (in if )
    - core/DataUtility.lua:449
    - ui/Options.lua:904 (in elseif )
    - ui/Options.lua:906
    - ui/Options.lua:1185 (in if )
    - ui/Options.lua:1187
    - ui/Options.lua:1213 (in if )
    - ui/Options.lua:1214

- `TWRA:DecompressAssignmentsData()` - Line 651
  - Referenced in:
    - core/Base64.lua:131 (in function )
    - core/Base64.lua:528 (in local decompressedData = )
    - core/Compression.lua:717 (in local decompressedData = )

- `TWRA:ProcessCompressedData()` - Line 708
  - Referenced in:

### 1.4 core/Core.lua

- `TWRA:OnLoad()` - Line 4
  - Referenced in:
    - core/Core.lua:322 (in frame:SetScript("OnLoad", function() )
    - features/AutoNavigate.lua:107
    - sync/Sync.lua:33

- `TWRA:OnEvent()` - Line 199
  - Referenced in:
    - core/Core.lua:319
    - features/AutoNavigate.lua:123
    - sync/Sync.lua:49

- `TWRA:ToggleMainFrame()` - Line 515
  - Referenced in:
    - Example.lua:462
    - TWRA.lua:823
    - core/Core.lua:491

- `TWRA:NavigateHandler()` - Line 575
  - Referenced in:
    - core/Core.lua:440
    - core/Core.lua:444
    - ui/Frame.lua:164
    - ui/Frame.lua:176
    - ui/Minimap.lua:419 (in if )
    - ui/Minimap.lua:420
    - ui/Minimap.lua:436 (in if )
    - ui/Minimap.lua:437

- `TWRA:RebuildNavigation()` - Line 601
  - Referenced in:
    - core/Base64.lua:449 (in if )
    - core/Base64.lua:451
    - core/Base64.lua:490 (in if )
    - core/Base64.lua:492
    - core/Base64.lua:847 (in if )
    - core/Base64.lua:849
    - core/Base64.lua:894 (in if )
    - core/Base64.lua:896
    - core/Compression.lua:750 (in if )
    - core/Compression.lua:751
    - Example.lua:305 (in if )
    - Example.lua:307
    - core/Core.lua:211
    - core/Core.lua:725 (in return )
    - core/DataUtility.lua:483 (in if )
    - core/DataUtility.lua:485
    - ui/Frame.lua:453
    - sync/SyncHandlers.lua:333 (in if )
    - sync/SyncHandlers.lua:334

- `TWRA:SaveCurrentSection()` - Line 664
  - Referenced in:
    - Example.lua:410

- `TWRA:EnsureUIUtils()` - Line 687
  - Referenced in:
    - core/Core.lua:696

- `TWRA:ResetUI()` - Line 698
  - Referenced in:
    - core/Core.lua:214

- `TWRA:BuildNavigationFromNewFormat()` - Line 722
  - Referenced in:

- `TWRA:RegisterAddonMessaging()` - Line 728
  - Referenced in:
    - core/Core.lua:153

- `TWRA:OnGroupChanged()` - Line 748
  - Referenced in:
    - TWRA.lua:874 (in function )
    - core/Core.lua:795
    - core/Core.lua:800

- `TWRA:OnRaidRosterUpdate()` - Line 793
  - Referenced in:
    - core/Core.lua:266 (in if )
    - core/Core.lua:267

- `TWRA:OnPartyMembersChanged()` - Line 798
  - Referenced in:
    - core/Core.lua:271 (in if )
    - core/Core.lua:272

### 1.5 core/DataProcessing.lua

- `TWRA:EnsureCompleteRows()` - Line 3
  - Referenced in:
    - core/Base64.lua:749 (in result = )
    - core/DataUtility.lua:392 (in if )
    - core/DataUtility.lua:393 (in data = )

- `TWRA:ProcessPlayerInfo()` - Line 56
  - Referenced in:
    - core/Base64.lua:547 (in if )
    - core/Base64.lua:548
    - core/Base64.lua:772 (in if )
    - core/Base64.lua:785
    - core/Compression.lua:760 (in elseif )
    - core/Compression.lua:761
    - Example.lua:396 (in if )
    - Example.lua:398
    - core/DataProcessing.lua:770 (in if )
    - core/DataProcessing.lua:774
    - core/DataProcessing.lua:778
    - core/DataUtility.lua:497 (in if )
    - core/DataUtility.lua:499
    - ui/Options.lua:923 (in if )
    - ui/Options.lua:926 (in pcall(function() )
    - ui/Options.lua:1229 (in if )
    - ui/Options.lua:1231 (in pcall(function() )

- `TWRA:ProcessStaticPlayerInfo()` - Line 73
  - Referenced in:
    - core/DataProcessing.lua:64

- `TWRA:ProcessStaticPlayerInfoForSection()` - Line 126
  - Referenced in:
    - core/DataProcessing.lua:109
    - core/DataProcessing.lua:116

- `TWRA:ProcessDynamicPlayerInfo()` - Line 192
  - Referenced in:
    - core/DataProcessing.lua:67
    - core/DataProcessing.lua:371
    - core/DataProcessing.lua:1059

- `TWRA:ProcessDynamicPlayerInfoForSection()` - Line 240
  - Referenced in:
    - core/DataProcessing.lua:223
    - core/DataProcessing.lua:230

- `TWRA:UpdateOSDWithPlayerInfo()` - Line 332
  - Referenced in:

- `TWRA:RefreshPlayerInfo()` - Line 362
  - Referenced in:
    - core/Base64.lua:496 (in if )
    - core/Base64.lua:497
    - core/Base64.lua:900 (in if )
    - core/Base64.lua:901
    - core/Compression.lua:758 (in if )
    - core/Compression.lua:759
    - TWRA.lua:880

- `TWRA:StoreCompressedData()` - Line 397
  - Referenced in:
    - core/Base64.lua:544
    - core/Base64.lua:766
    - ui/Options.lua:901 (in if )
    - ui/Options.lua:903
    - ui/Options.lua:1188 (in elseif )
    - ui/Options.lua:1190
    - ui/Options.lua:1215 (in elseif )
    - ui/Options.lua:1216

- `TWRA:ClearDataForStructureResponse()` - Line 433
  - Referenced in:

- `TWRA:BuildSkeletonFromStructure()` - Line 462
  - Referenced in:
    - sync/SyncHandlers.lua:315 (in if )
    - sync/SyncHandlers.lua:317 (in hasBuiltSkeleton = )

- `TWRA:ProcessSectionData()` - Line 523
  - Referenced in:
    - TWRA.lua:86 (in if )
    - TWRA.lua:88
    - sync/SyncHandlers.lua:377
    - sync/SyncHandlers.lua:501
    - sync/SyncHandlers.lua:782

- `TWRA:GenerateOSDInfoForSection()` - Line 809
  - Referenced in:
    - core/DataProcessing.lua:186 (in playerInfo["OSD Assignments"] = )
    - core/DataProcessing.lua:327 (in playerInfo["OSD Group Assignments"] = )

- `TWRA:GetAllGroupRowsForSection()` - Line 966
  - Referenced in:
    - core/Compression.lua:228 (in if )
    - core/Compression.lua:229
    - core/DataProcessing.lua:259
    - core/DataProcessing.lua:1167
    - core/DataUtility.lua:566 (in metadata["Group Rows"] = )
    - ui/Options.lua:875

- `TWRA:UpdateGroupInfo()` - Line 1038
  - Referenced in:
    - core/DataProcessing.lua:1117

- `TWRA:MonitorGroupChanges()` - Line 1083
  - Referenced in:
    - core/DataProcessing.lua:1150

- `TWRA:InitializeGroupMonitoring()` - Line 1148
  - Referenced in:
    - core/Core.lua:145 (in if )
    - core/Core.lua:147

- `TWRA:EnsureGroupRowsIdentified()` - Line 1153
  - Referenced in:
    - core/DataUtility.lua:405 (in if )
    - core/DataUtility.lua:414

- `TWRA:IsCellRelevantForPlayer()` - Line 1177
  - Referenced in:
    - core/DataProcessing.lua:885 (in elseif )

- `TWRA:IsCellRelevantForPlayerGroup()` - Line 1208
  - Referenced in:
    - core/DataProcessing.lua:864 (in if )

### 1.6 core/DataUtility.lua

- `TWRA:ConvertSpecialCharacters()` - Line 30
  - Referenced in:
    - core/DataUtility.lua:56 (in return )
    - core/DataUtility.lua:64 (in k = )
    - core/DataUtility.lua:70 (in result[k] = )

- `TWRA:FixSpecialCharacters()` - Line 53
  - Referenced in:
    - core/Base64.lua:757 (in if )
    - core/Base64.lua:758 (in result = )
    - core/DataUtility.lua:68 (in result[k] = )

- `TWRA:GetCurrentSectionData()` - Line 78
  - Referenced in:
    - TWRA.lua:463 (in local sectionData = )
    - core/DataUtility.lua:113 (in local sectionData = )
    - features/AutoTanks.lua:60 (in local sectionData = )

- `TWRA:DisplayCurrentSection()` - Line 112
  - Referenced in:
    - TWRA.lua:140 (in elseif )
    - TWRA.lua:141
    - TWRA.lua:888 (in elseif )
    - TWRA.lua:889
    - ui/Options.lua:1257 (in if )
    - ui/Options.lua:1268
    - ui/Options.lua:1290

- `TWRA:FindTankRoleColumns()` - Line 133
  - Referenced in:
    - core/DataProcessing.lua:828 (in tankColumns = )

- `TWRA:NormalizeMetadataKeys()` - Line 187
  - Referenced in:
    - core/DataUtility.lua:226 (in local normalizedMetadata = )
    - core/DataUtility.lua:296 (in section["Section Metadata"] = )

- `TWRA:ClearData()` - Line 209
  - Referenced in:
    - core/Base64.lua:822 (in if )
    - core/Base64.lua:823
    - Example.lua:274 (in if )
    - Example.lua:275
    - core/DataUtility.lua:381 (in if not )

- `TWRA:DeepCopy()` - Line 352
  - Referenced in:
    - core/DataProcessing.lua:693 (in preservedMetadata = )
    - core/DataUtility.lua:229 (in metadataToPreserve[sectionName] = )
    - core/DataUtility.lua:247 (in playerInfoToPreserve[sectionName] = )
    - core/DataUtility.lua:304 (in section["Section Metadata"][key] = )
    - core/DataUtility.lua:318 (in section["Section Player Info"][key] = )
    - core/DataUtility.lua:358 (in copy[orig_key] = )

- `TWRA:SaveAssignments()` - Line 367
  - Referenced in:
    - core/Base64.lua:432 (in if )
    - core/Base64.lua:434
    - core/Base64.lua:830 (in if )
    - core/Base64.lua:832
    - core/DataUtility.lua:335

- `TWRA:ProcessImportedData()` - Line 523
  - Referenced in:
    - core/Base64.lua:752 (in if )
    - core/Base64.lua:753 (in result = )
    - ui/Options.lua:894 (in if )
    - ui/Options.lua:896 (in TWRA_Assignments.data = )

- `TWRA:CaptureSpecialRows()` - Line 533
  - Referenced in:
    - core/DataUtility.lua:399 (in if )
    - core/DataUtility.lua:400 (in data = )

### 1.7 core/Debug.lua

- `TWRA:InitDebug()` - Line 59
  - Referenced in:
    - core/Debug.lua:363
    - core/Debug.lua:404
    - core/Debug.lua:444
    - core/Debug.lua:464
    - core/Debug.lua:503
    - core/Debug.lua:545
    - core/Debug.lua:565
    - core/Debug.lua:643
    - TWRA.lua:319 (in if )
    - core/Core.lua:111 (in if )
    - core/Core.lua:112

- `TWRA:Error()` - Line 196
  - Referenced in:
    - core/Debug.lua:719
    - core/Core.lua:206
    - core/Core.lua:541

- `TWRA:Debug()` - Line 200
  - Referenced in:
    - core/Debug.lua:190
    - core/Debug.lua:197
    - core/Debug.lua:320
    - core/Debug.lua:342
    - core/Debug.lua:349
    - core/Debug.lua:797
    - core/Debug.lua:804
    - core/Debug.lua:811
    - core/Debug.lua:818
    - core/Utils.lua:45
    - core/Utils.lua:64
    - core/Utils.lua:213
    - core/Utils.lua:224
    - core/Utils.lua:238
    - core/Utils.lua:244
    - core/Events.lua:14
    - core/Events.lua:32
    - core/Events.lua:52
    - core/Events.lua:67
    - core/Base64.lua:89
    - core/Base64.lua:93
    - core/Base64.lua:99
    - core/Base64.lua:106
    - core/Base64.lua:117
    - core/Base64.lua:120
    - core/Base64.lua:132
    - core/Base64.lua:134
    - core/Base64.lua:140
    - core/Base64.lua:144
    - core/Base64.lua:152
    - core/Base64.lua:159
    - core/Base64.lua:166
    - core/Base64.lua:172
    - core/Base64.lua:181
    - core/Base64.lua:185
    - core/Base64.lua:226
    - core/Base64.lua:232
    - core/Base64.lua:237
    - core/Base64.lua:241
    - core/Base64.lua:248
    - core/Base64.lua:255
    - core/Base64.lua:268
    - core/Base64.lua:276
    - core/Base64.lua:280
    - core/Base64.lua:292
    - core/Base64.lua:297
    - core/Base64.lua:309
    - core/Base64.lua:321
    - core/Base64.lua:332
    - core/Base64.lua:344
    - core/Base64.lua:356
    - core/Base64.lua:388
    - core/Base64.lua:416
    - core/Base64.lua:425
    - core/Base64.lua:439
    - core/Base64.lua:444
    - core/Base64.lua:450
    - core/Base64.lua:456
    - core/Base64.lua:462
    - core/Base64.lua:469
    - core/Base64.lua:475
    - core/Base64.lua:478
    - core/Base64.lua:481
    - core/Base64.lua:487
    - core/Base64.lua:491
    - core/Base64.lua:498
    - core/Base64.lua:503
    - core/Base64.lua:511
    - core/Base64.lua:523
    - core/Base64.lua:527
    - core/Base64.lua:531
    - core/Base64.lua:549
    - core/Base64.lua:567
    - core/Base64.lua:571
    - core/Base64.lua:585
    - core/Base64.lua:604
    - core/Base64.lua:632
    - core/Base64.lua:639
    - core/Base64.lua:644
    - core/Base64.lua:648
    - core/Base64.lua:653
    - core/Base64.lua:660
    - core/Base64.lua:669
    - core/Base64.lua:678
    - core/Base64.lua:684
    - core/Base64.lua:688
    - core/Base64.lua:693
    - core/Base64.lua:697
    - core/Base64.lua:725
    - core/Base64.lua:729
    - core/Base64.lua:733
    - core/Base64.lua:741
    - core/Base64.lua:762
    - core/Base64.lua:768
    - core/Base64.lua:773
    - core/Base64.lua:786
    - core/Base64.lua:798
    - core/Base64.lua:810
    - core/Base64.lua:821
    - core/Base64.lua:837
    - core/Base64.lua:842
    - core/Base64.lua:848
    - core/Base64.lua:854
    - core/Base64.lua:860
    - core/Base64.lua:867
    - core/Base64.lua:873
    - core/Base64.lua:876
    - core/Base64.lua:879
    - core/Base64.lua:883
    - core/Base64.lua:891
    - core/Base64.lua:895
    - core/Base64.lua:902
    - core/Base64.lua:907
    - core/Base64.lua:914
    - core/Base64.lua:918
    - core/Base64.lua:925
    - core/Base64.lua:932
    - core/Compression.lua:10
    - core/Compression.lua:24
    - core/Compression.lua:83
    - core/Compression.lua:90
    - core/Compression.lua:114
    - core/Compression.lua:128
    - core/Compression.lua:136
    - core/Compression.lua:138
    - core/Compression.lua:143
    - core/Compression.lua:155
    - core/Compression.lua:161
    - core/Compression.lua:180
    - core/Compression.lua:206
    - core/Compression.lua:208
    - core/Compression.lua:225
    - core/Compression.lua:230
    - core/Compression.lua:233
    - core/Compression.lua:241
    - core/Compression.lua:245
    - core/Compression.lua:252
    - core/Compression.lua:264
    - core/Compression.lua:267
    - core/Compression.lua:275
    - core/Compression.lua:278
    - core/Compression.lua:285
    - core/Compression.lua:290
    - core/Compression.lua:295
    - core/Compression.lua:301
    - core/Compression.lua:305
    - core/Compression.lua:309
    - core/Compression.lua:317
    - core/Compression.lua:325
    - core/Compression.lua:331
    - core/Compression.lua:334
    - core/Compression.lua:341
    - core/Compression.lua:346
    - core/Compression.lua:351
    - core/Compression.lua:352
    - core/Compression.lua:379
    - core/Compression.lua:384
    - core/Compression.lua:385
    - core/Compression.lua:390
    - core/Compression.lua:400
    - core/Compression.lua:407
    - core/Compression.lua:412
    - core/Compression.lua:416
    - core/Compression.lua:421
    - core/Compression.lua:425
    - core/Compression.lua:432
    - core/Compression.lua:439
    - core/Compression.lua:447
    - core/Compression.lua:452
    - core/Compression.lua:459
    - core/Compression.lua:465
    - core/Compression.lua:470
    - core/Compression.lua:478
    - core/Compression.lua:556
    - core/Compression.lua:601
    - core/Compression.lua:605
    - core/Compression.lua:612
    - core/Compression.lua:636
    - core/Compression.lua:638
    - core/Compression.lua:646
    - core/Compression.lua:652
    - core/Compression.lua:654
    - core/Compression.lua:664
    - core/Compression.lua:681
    - core/Compression.lua:689
    - core/Compression.lua:697
    - core/Compression.lua:701
    - core/Compression.lua:709
    - core/Compression.lua:714
    - core/Compression.lua:720
    - core/Compression.lua:724
    - core/Compression.lua:731
    - core/Compression.lua:745
    - core/Compression.lua:749
    - core/Compression.lua:753
    - core/Compression.lua:757
    - core/Compression.lua:763
    - core/Compression.lua:768
    - core/Compression.lua:773
    - core/Compression.lua:779
    - core/Compression.lua:786
    - Example.lua:271
    - Example.lua:284
    - Example.lua:291
    - Example.lua:306
    - Example.lua:314
    - Example.lua:319
    - Example.lua:391
    - Example.lua:397
    - Example.lua:402
    - Example.lua:431
    - Example.lua:444
    - Example.lua:456
    - Example.lua:463
    - Example.lua:469
    - Example.lua:495
    - Example.lua:505
    - Example.lua:512
    - Example.lua:525
    - TWRA.lua:14
    - TWRA.lua:21
    - TWRA.lua:29
    - TWRA.lua:34
    - TWRA.lua:40
    - TWRA.lua:47
    - TWRA.lua:58
    - TWRA.lua:60
    - TWRA.lua:66
    - TWRA.lua:75
    - TWRA.lua:78
    - TWRA.lua:87
    - TWRA.lua:139
    - TWRA.lua:142
    - TWRA.lua:148
    - TWRA.lua:320
    - TWRA.lua:324
    - TWRA.lua:337
    - TWRA.lua:359
    - TWRA.lua:365
    - TWRA.lua:376
    - TWRA.lua:399
    - TWRA.lua:407
    - TWRA.lua:410
    - TWRA.lua:424
    - TWRA.lua:433
    - TWRA.lua:456
    - TWRA.lua:460
    - TWRA.lua:465
    - TWRA.lua:481
    - TWRA.lua:501
    - TWRA.lua:504
    - TWRA.lua:606
    - TWRA.lua:622
    - TWRA.lua:626
    - TWRA.lua:635
    - TWRA.lua:643
    - TWRA.lua:667
    - TWRA.lua:669
    - TWRA.lua:678
    - TWRA.lua:684
    - TWRA.lua:694
    - TWRA.lua:712
    - TWRA.lua:765
    - TWRA.lua:772
    - TWRA.lua:871
    - TWRA.lua:875
    - TWRA.lua:887
    - TWRA.lua:890
    - core/Core.lua:9
    - core/Core.lua:34
    - core/Core.lua:56
    - core/Core.lua:68
    - core/Core.lua:76
    - core/Core.lua:84
    - core/Core.lua:87
    - core/Core.lua:92
    - core/Core.lua:94
    - core/Core.lua:97
    - core/Core.lua:117
    - core/Core.lua:119
    - core/Core.lua:125
    - core/Core.lua:128
    - core/Core.lua:141
    - core/Core.lua:146
    - core/Core.lua:149
    - core/Core.lua:155
    - core/Core.lua:157
    - core/Core.lua:176
    - core/Core.lua:190
    - core/Core.lua:194
    - core/Core.lua:203
    - core/Core.lua:210
    - core/Core.lua:215
    - core/Core.lua:253
    - core/Core.lua:261
    - core/Core.lua:286
    - core/Core.lua:294
    - core/Core.lua:297
    - core/Core.lua:301
    - core/Core.lua:308
    - core/Core.lua:313
    - core/Core.lua:315
    - core/Core.lua:328
    - core/Core.lua:430
    - core/Core.lua:439
    - core/Core.lua:443
    - core/Core.lua:448
    - core/Core.lua:460
    - core/Core.lua:465
    - core/Core.lua:469
    - core/Core.lua:471
    - core/Core.lua:477
    - core/Core.lua:479
    - core/Core.lua:487
    - core/Core.lua:518
    - core/Core.lua:538
    - core/Core.lua:547
    - core/Core.lua:554
    - core/Core.lua:567
    - core/Core.lua:578
    - core/Core.lua:602
    - core/Core.lua:616
    - core/Core.lua:622
    - core/Core.lua:644
    - core/Core.lua:647
    - core/Core.lua:654
    - core/Core.lua:658
    - core/Core.lua:676
    - core/Core.lua:693
    - core/Core.lua:699
    - core/Core.lua:719
    - core/Core.lua:724
    - core/Core.lua:732
    - core/Core.lua:739
    - core/Core.lua:741
    - core/Core.lua:745
    - core/Core.lua:749
    - core/Core.lua:760
    - core/Core.lua:766
    - core/Core.lua:773
    - core/Core.lua:776
    - core/Core.lua:779
    - core/Core.lua:784
    - core/DataProcessing.lua:43
    - core/DataProcessing.lua:49
    - core/DataProcessing.lua:58
    - core/DataProcessing.lua:60
    - core/DataProcessing.lua:75
    - core/DataProcessing.lua:77
    - core/DataProcessing.lua:94
    - core/DataProcessing.lua:100
    - core/DataProcessing.lua:122
    - core/DataProcessing.lua:163
    - core/DataProcessing.lua:182
    - core/DataProcessing.lua:194
    - core/DataProcessing.lua:196
    - core/DataProcessing.lua:210
    - core/DataProcessing.lua:214
    - core/DataProcessing.lua:236
    - core/DataProcessing.lua:252
    - core/DataProcessing.lua:270
    - core/DataProcessing.lua:286
    - core/DataProcessing.lua:302
    - core/DataProcessing.lua:323
    - core/DataProcessing.lua:335
    - core/DataProcessing.lua:341
    - core/DataProcessing.lua:350
    - core/DataProcessing.lua:357
    - core/DataProcessing.lua:364
    - core/DataProcessing.lua:366
    - core/DataProcessing.lua:382
    - core/DataProcessing.lua:388
    - core/DataProcessing.lua:399
    - core/DataProcessing.lua:403
    - core/DataProcessing.lua:412
    - core/DataProcessing.lua:422
    - core/DataProcessing.lua:426
    - core/DataProcessing.lua:434
    - core/DataProcessing.lua:458
    - core/DataProcessing.lua:464
    - core/DataProcessing.lua:468
    - core/DataProcessing.lua:483
    - core/DataProcessing.lua:513
    - core/DataProcessing.lua:515
    - core/DataProcessing.lua:517
    - core/DataProcessing.lua:531
    - core/DataProcessing.lua:535
    - core/DataProcessing.lua:554
    - core/DataProcessing.lua:559
    - core/DataProcessing.lua:563
    - core/DataProcessing.lua:567
    - core/DataProcessing.lua:574
    - core/DataProcessing.lua:578
    - core/DataProcessing.lua:582
    - core/DataProcessing.lua:589
    - core/DataProcessing.lua:592
    - core/DataProcessing.lua:606
    - core/DataProcessing.lua:613
    - core/DataProcessing.lua:618
    - core/DataProcessing.lua:621
    - core/DataProcessing.lua:625
    - core/DataProcessing.lua:633
    - core/DataProcessing.lua:644
    - core/DataProcessing.lua:651
    - core/DataProcessing.lua:683
    - core/DataProcessing.lua:694
    - core/DataProcessing.lua:713
    - core/DataProcessing.lua:721
    - core/DataProcessing.lua:729
    - core/DataProcessing.lua:734
    - core/DataProcessing.lua:736
    - core/DataProcessing.lua:738
    - core/DataProcessing.lua:745
    - core/DataProcessing.lua:752
    - core/DataProcessing.lua:754
    - core/DataProcessing.lua:759
    - core/DataProcessing.lua:773
    - core/DataProcessing.lua:777
    - core/DataProcessing.lua:797
    - core/DataProcessing.lua:802
    - core/DataProcessing.lua:832
    - core/DataProcessing.lua:842
    - core/DataProcessing.lua:845
    - core/DataProcessing.lua:871
    - core/DataProcessing.lua:883
    - core/DataProcessing.lua:893
    - core/DataProcessing.lua:907
    - core/DataProcessing.lua:953
    - core/DataProcessing.lua:962
    - core/DataProcessing.lua:971
    - core/DataProcessing.lua:975
    - core/DataProcessing.lua:981
    - core/DataProcessing.lua:984
    - core/DataProcessing.lua:1008
    - core/DataProcessing.lua:1019
    - core/DataProcessing.lua:1026
    - core/DataProcessing.lua:1031
    - core/DataProcessing.lua:1039
    - core/DataProcessing.lua:1053
    - core/DataProcessing.lua:1055
    - core/DataProcessing.lua:1070
    - core/DataProcessing.lua:1076
    - core/DataProcessing.lua:1084
    - core/DataProcessing.lua:1109
    - core/DataProcessing.lua:1138
    - core/DataProcessing.lua:1144
    - core/DataProcessing.lua:1149
    - core/DataProcessing.lua:1155
    - core/DataProcessing.lua:1159
    - core/DataProcessing.lua:1169
    - core/DataProcessing.lua:1190
    - core/DataProcessing.lua:1198
    - core/DataProcessing.lua:1249
    - core/DataUtility.lua:81
    - core/DataUtility.lua:98
    - core/DataUtility.lua:109
    - core/DataUtility.lua:115
    - core/DataUtility.lua:154
    - core/DataUtility.lua:173
    - core/DataUtility.lua:181
    - core/DataUtility.lua:210
    - core/DataUtility.lua:241
    - core/DataUtility.lua:259
    - core/DataUtility.lua:277
    - core/DataUtility.lua:305
    - core/DataUtility.lua:321
    - core/DataUtility.lua:329
    - core/DataUtility.lua:348
    - core/DataUtility.lua:369
    - core/DataUtility.lua:377
    - core/DataUtility.lua:380
    - core/DataUtility.lua:382
    - core/DataUtility.lua:384
    - core/DataUtility.lua:389
    - core/DataUtility.lua:394
    - core/DataUtility.lua:398
    - core/DataUtility.lua:401
    - core/DataUtility.lua:415
    - core/DataUtility.lua:447
    - core/DataUtility.lua:450
    - core/DataUtility.lua:452
    - core/DataUtility.lua:454
    - core/DataUtility.lua:456
    - core/DataUtility.lua:471
    - core/DataUtility.lua:476
    - core/DataUtility.lua:484
    - core/DataUtility.lua:490
    - core/DataUtility.lua:496
    - core/DataUtility.lua:503
    - core/DataUtility.lua:505
    - core/DataUtility.lua:508
    - core/DataUtility.lua:514
    - core/DataUtility.lua:535
    - core/DataUtility.lua:539
    - core/DataUtility.lua:548
    - core/DataUtility.lua:567
    - core/DataUtility.lua:570
    - core/DataUtility.lua:595
    - core/DataUtility.lua:613
    - core/DataUtility.lua:631
    - core/DataUtility.lua:657
    - core/DataUtility.lua:660
    - core/DataUtility.lua:668
    - ui/UIUtils.lua:8
    - ui/UIUtils.lua:43
    - ui/Frame.lua:6
    - ui/Frame.lua:21 (in --         )
    - ui/Frame.lua:31 (in --                 )
    - ui/Frame.lua:37 (in --     )
    - ui/Frame.lua:112
    - ui/Frame.lua:115
    - ui/Frame.lua:118
    - ui/Frame.lua:122
    - ui/Frame.lua:452
    - ui/Frame.lua:466
    - ui/Frame.lua:475
    - ui/Frame.lua:478
    - ui/Frame.lua:489
    - ui/Frame.lua:494
    - ui/Frame.lua:498
    - ui/Frame.lua:506
    - ui/Frame.lua:512
    - ui/Frame.lua:516
    - ui/Frame.lua:534
    - ui/Frame.lua:572
    - ui/Frame.lua:591
    - ui/Frame.lua:596
    - ui/Frame.lua:604
    - ui/Frame.lua:609
    - ui/Frame.lua:612
    - ui/Frame.lua:636
    - ui/Frame.lua:643
    - ui/Frame.lua:681
    - ui/Frame.lua:684
    - ui/Frame.lua:697
    - ui/Frame.lua:699
    - ui/Frame.lua:701
    - ui/Frame.lua:707
    - ui/Frame.lua:713
    - ui/Frame.lua:719
    - ui/Frame.lua:764
    - ui/Frame.lua:789
    - ui/Frame.lua:802
    - ui/Frame.lua:812
    - ui/Frame.lua:819
    - ui/Frame.lua:846
    - ui/Frame.lua:848
    - ui/Frame.lua:857
    - ui/Frame.lua:860
    - ui/Frame.lua:884
    - ui/Frame.lua:888
    - ui/Frame.lua:893
    - ui/Frame.lua:907
    - ui/Frame.lua:916
    - ui/Frame.lua:936
    - ui/Frame.lua:949
    - ui/Frame.lua:954
    - ui/Frame.lua:958
    - ui/Frame.lua:962
    - ui/Frame.lua:966
    - ui/Frame.lua:1014
    - ui/Frame.lua:1019
    - ui/Frame.lua:1069
    - ui/Frame.lua:1153
    - ui/Frame.lua:1214
    - ui/Frame.lua:1219
    - ui/Frame.lua:1226
    - ui/Frame.lua:1231
    - ui/Frame.lua:1397
    - ui/Frame.lua:1410
    - ui/Frame.lua:1468
    - ui/Frame.lua:1474
    - ui/Frame.lua:1491
    - ui/Frame.lua:1500
    - ui/Frame.lua:1506
    - ui/Frame.lua:1537
    - ui/Frame.lua:1558
    - ui/Frame.lua:1560
    - ui/Frame.lua:1566
    - ui/Frame.lua:1608
    - ui/Frame.lua:1630
    - ui/Frame.lua:1677
    - ui/Minimap.lua:15
    - ui/Minimap.lua:64
    - ui/Minimap.lua:77
    - ui/Minimap.lua:84
    - ui/Minimap.lua:92
    - ui/Minimap.lua:99
    - ui/Minimap.lua:106
    - ui/Minimap.lua:110
    - ui/Minimap.lua:113
    - ui/Minimap.lua:136
    - ui/Minimap.lua:144
    - ui/Minimap.lua:161
    - ui/Minimap.lua:173
    - ui/Minimap.lua:177
    - ui/Minimap.lua:186
    - ui/Minimap.lua:192
    - ui/Minimap.lua:196
    - ui/Minimap.lua:201
    - ui/Minimap.lua:273
    - ui/Minimap.lua:281
    - ui/Minimap.lua:283
    - ui/Minimap.lua:288
    - ui/Minimap.lua:292
    - ui/Minimap.lua:336
    - ui/Minimap.lua:364
    - ui/Minimap.lua:399
    - ui/Minimap.lua:417
    - ui/Minimap.lua:434
    - ui/Minimap.lua:527
    - ui/Minimap.lua:555
    - ui/Minimap.lua:604
    - ui/Minimap.lua:769
    - ui/OSD.lua:9
    - ui/OSD.lua:28
    - ui/OSD.lua:32
    - ui/OSD.lua:36
    - ui/OSD.lua:55
    - ui/OSD.lua:65
    - ui/OSD.lua:74
    - ui/OSD.lua:80
    - ui/OSD.lua:89
    - ui/OSD.lua:96
    - ui/OSD.lua:156
    - ui/OSD.lua:159
    - ui/OSD.lua:176
    - ui/OSD.lua:182
    - ui/OSD.lua:186
    - ui/OSD.lua:198
    - ui/OSD.lua:204
    - ui/OSD.lua:209
    - ui/OSD.lua:211
    - ui/OSD.lua:213
    - ui/OSD.lua:220
    - ui/OSD.lua:244
    - ui/OSD.lua:276
    - ui/OSD.lua:282
    - ui/OSD.lua:302
    - ui/OSD.lua:342
    - ui/OSD.lua:355
    - ui/OSD.lua:359
    - ui/OSD.lua:753
    - ui/OSD.lua:783
    - ui/OSD.lua:790
    - ui/OSD.lua:809
    - ui/OSD.lua:827
    - ui/OSD.lua:852
    - ui/OSD.lua:865
    - ui/OSD.lua:870
    - ui/OSD.lua:883
    - ui/OSD.lua:888
    - ui/OSD.lua:896
    - ui/OSD.lua:900
    - ui/OSD.lua:949
    - ui/OSD.lua:954
    - ui/OSD.lua:989
    - ui/OSD.lua:995
    - ui/OSD.lua:1051
    - ui/OSD.lua:1054
    - ui/OSD.lua:1255
    - ui/OSD.lua:1261
    - ui/OSD.lua:1266
    - ui/OSD.lua:1277
    - ui/OSD.lua:1311
    - ui/OSD.lua:1318
    - ui/OSD.lua:1325
    - ui/OSD.lua:1341
    - ui/OSD.lua:1348
    - ui/OSD.lua:1355
    - ui/OSD.lua:1375
    - ui/OSD.lua:1377
    - ui/OSD.lua:1402
    - ui/OSD.lua:1489
    - ui/Options.lua:68
    - ui/Options.lua:396
    - ui/Options.lua:586
    - ui/Options.lua:600
    - ui/Options.lua:615
    - ui/Options.lua:621
    - ui/Options.lua:626
    - ui/Options.lua:720
    - ui/Options.lua:751
    - ui/Options.lua:777
    - ui/Options.lua:848
    - ui/Options.lua:852
    - ui/Options.lua:865
    - ui/Options.lua:884
    - ui/Options.lua:889
    - ui/Options.lua:895
    - ui/Options.lua:902
    - ui/Options.lua:905
    - ui/Options.lua:919
    - ui/Options.lua:924
    - ui/Options.lua:940
    - ui/Options.lua:956
    - ui/Options.lua:982
    - ui/Options.lua:986
    - ui/Options.lua:991
    - ui/Options.lua:996
    - ui/Options.lua:1005
    - ui/Options.lua:1013
    - ui/Options.lua:1015
    - ui/Options.lua:1018
    - ui/Options.lua:1026
    - ui/Options.lua:1032
    - ui/Options.lua:1034
    - ui/Options.lua:1037
    - ui/Options.lua:1042
    - ui/Options.lua:1052
    - ui/Options.lua:1054
    - ui/Options.lua:1057
    - ui/Options.lua:1062
    - ui/Options.lua:1075
    - ui/Options.lua:1085
    - ui/Options.lua:1091
    - ui/Options.lua:1096
    - ui/Options.lua:1107
    - ui/Options.lua:1117
    - ui/Options.lua:1123
    - ui/Options.lua:1138
    - ui/Options.lua:1144
    - ui/Options.lua:1148
    - ui/Options.lua:1160
    - ui/Options.lua:1178
    - ui/Options.lua:1181
    - ui/Options.lua:1186
    - ui/Options.lua:1189
    - ui/Options.lua:1199
    - ui/Options.lua:1203
    - ui/Options.lua:1224
    - ui/Options.lua:1230
    - ui/Options.lua:1238
    - ui/Options.lua:1246
    - ui/Options.lua:1254
    - ui/Options.lua:1258
    - ui/Options.lua:1274
    - ui/Options.lua:1280
    - ui/Options.lua:1288
    - ui/Options.lua:1294
    - ui/Options.lua:1299
    - ui/Options.lua:1302
    - features/AutoTanks.lua:14
    - features/AutoTanks.lua:21
    - features/AutoTanks.lua:24
    - features/AutoTanks.lua:36
    - features/AutoTanks.lua:47
    - features/AutoTanks.lua:53
    - features/AutoTanks.lua:57
    - features/AutoTanks.lua:62
    - features/AutoTanks.lua:71
    - features/AutoTanks.lua:75
    - features/AutoTanks.lua:83
    - features/AutoTanks.lua:101
    - features/AutoTanks.lua:103
    - features/AutoTanks.lua:106
    - features/AutoTanks.lua:116
    - features/AutoTanks.lua:119
    - features/AutoTanks.lua:132
    - features/AutoTanks.lua:136
    - features/AutoTanks.lua:139
    - features/AutoNavigate.lua:30
    - features/AutoNavigate.lua:37
    - features/AutoNavigate.lua:41
    - features/AutoNavigate.lua:45
    - features/AutoNavigate.lua:50
    - features/AutoNavigate.lua:59
    - features/AutoNavigate.lua:67
    - features/AutoNavigate.lua:69
    - features/AutoNavigate.lua:75
    - features/AutoNavigate.lua:79
    - features/AutoNavigate.lua:85
    - features/AutoNavigate.lua:88
    - features/AutoNavigate.lua:94
    - features/AutoNavigate.lua:103
    - features/AutoNavigate.lua:115
    - features/AutoNavigate.lua:132
    - features/AutoNavigate.lua:144
    - features/AutoNavigate.lua:151
    - features/AutoNavigate.lua:155
    - features/AutoNavigate.lua:161
    - features/AutoNavigate.lua:185
    - features/AutoNavigate.lua:193
    - features/AutoNavigate.lua:197
    - features/AutoNavigate.lua:205
    - features/AutoNavigate.lua:211
    - features/AutoNavigate.lua:220
    - features/AutoNavigate.lua:234
    - features/AutoNavigate.lua:240
    - features/AutoNavigate.lua:244
    - features/AutoNavigate.lua:247
    - features/AutoNavigate.lua:251
    - features/AutoNavigate.lua:272
    - features/AutoNavigate.lua:273
    - features/AutoNavigate.lua:274
    - features/AutoNavigate.lua:276
    - features/AutoNavigate.lua:285
    - features/AutoNavigate.lua:299
    - features/AutoNavigate.lua:306
    - features/AutoNavigate.lua:320
    - features/AutoNavigate.lua:332
    - features/AutoNavigate.lua:345
    - features/AutoNavigate.lua:350
    - features/AutoNavigate.lua:357
    - features/AutoNavigate.lua:367
    - features/AutoNavigate.lua:370
    - features/AutoNavigate.lua:372
    - features/AutoNavigate.lua:374
    - features/AutoNavigate.lua:381
    - features/AutoNavigate.lua:392
    - features/AutoNavigate.lua:397
    - features/AutoNavigate.lua:398
    - features/AutoNavigate.lua:406
    - features/AutoNavigate.lua:422
    - features/AutoNavigate.lua:426
    - features/AutoNavigate.lua:465
    - features/AutoNavigate.lua:469
    - features/AutoNavigate.lua:480
    - features/AutoNavigate.lua:483
    - features/AutoNavigate.lua:487
    - core/ItemLink.lua:10
    - core/ItemLink.lua:27
    - core/ItemLink.lua:107
    - sync/SyncHandlers.lua:27
    - sync/SyncHandlers.lua:47
    - sync/SyncHandlers.lua:102
    - sync/SyncHandlers.lua:131
    - sync/SyncHandlers.lua:139
    - sync/SyncHandlers.lua:144
    - sync/SyncHandlers.lua:152
    - sync/SyncHandlers.lua:158
    - sync/SyncHandlers.lua:166
    - sync/SyncHandlers.lua:171
    - sync/SyncHandlers.lua:176
    - sync/SyncHandlers.lua:181
    - sync/SyncHandlers.lua:187
    - sync/SyncHandlers.lua:191
    - sync/SyncHandlers.lua:198
    - sync/SyncHandlers.lua:219
    - sync/SyncHandlers.lua:224
    - sync/SyncHandlers.lua:234
    - sync/SyncHandlers.lua:238
    - sync/SyncHandlers.lua:245
    - sync/SyncHandlers.lua:262
    - sync/SyncHandlers.lua:271
    - sync/SyncHandlers.lua:299
    - sync/SyncHandlers.lua:306
    - sync/SyncHandlers.lua:316
    - sync/SyncHandlers.lua:319
    - sync/SyncHandlers.lua:321
    - sync/SyncHandlers.lua:324
    - sync/SyncHandlers.lua:332
    - sync/SyncHandlers.lua:335
    - sync/SyncHandlers.lua:337
    - sync/SyncHandlers.lua:341
    - sync/SyncHandlers.lua:352
    - sync/SyncHandlers.lua:360
    - sync/SyncHandlers.lua:367
    - sync/SyncHandlers.lua:369
    - sync/SyncHandlers.lua:374
    - sync/SyncHandlers.lua:383
    - sync/SyncHandlers.lua:386
    - sync/SyncHandlers.lua:392
    - sync/SyncHandlers.lua:399
    - sync/SyncHandlers.lua:401
    - sync/SyncHandlers.lua:409
    - sync/SyncHandlers.lua:411
    - sync/SyncHandlers.lua:417
    - sync/SyncHandlers.lua:434
    - sync/SyncHandlers.lua:437
    - sync/SyncHandlers.lua:440
    - sync/SyncHandlers.lua:448
    - sync/SyncHandlers.lua:458
    - sync/SyncHandlers.lua:465
    - sync/SyncHandlers.lua:469
    - sync/SyncHandlers.lua:478
    - sync/SyncHandlers.lua:481
    - sync/SyncHandlers.lua:483
    - sync/SyncHandlers.lua:495
    - sync/SyncHandlers.lua:508
    - sync/SyncHandlers.lua:512
    - sync/SyncHandlers.lua:518
    - sync/SyncHandlers.lua:527
    - sync/SyncHandlers.lua:546
    - sync/SyncHandlers.lua:556
    - sync/SyncHandlers.lua:572
    - sync/SyncHandlers.lua:580
    - sync/SyncHandlers.lua:584
    - sync/SyncHandlers.lua:607
    - sync/SyncHandlers.lua:617
    - sync/SyncHandlers.lua:619
    - sync/SyncHandlers.lua:626
    - sync/SyncHandlers.lua:630
    - sync/SyncHandlers.lua:637
    - sync/SyncHandlers.lua:646
    - sync/SyncHandlers.lua:654
    - sync/SyncHandlers.lua:685
    - sync/SyncHandlers.lua:692
    - sync/SyncHandlers.lua:703
    - sync/SyncHandlers.lua:708
    - sync/SyncHandlers.lua:716
    - sync/SyncHandlers.lua:728
    - sync/SyncHandlers.lua:732
    - sync/SyncHandlers.lua:741
    - sync/SyncHandlers.lua:762
    - sync/SyncHandlers.lua:776
    - sync/SyncHandlers.lua:788
    - sync/SyncHandlers.lua:795
    - sync/SyncHandlers.lua:797
    - sync/SyncHandlers.lua:804
    - sync/SyncHandlers.lua:810
    - sync/SyncHandlers.lua:827
    - sync/SyncHandlers.lua:847
    - sync/SyncHandlers.lua:859
    - sync/SyncHandlers.lua:872
    - sync/SyncHandlers.lua:888
    - sync/SyncHandlers.lua:894
    - sync/SyncHandlers.lua:919
    - sync/SyncHandlers.lua:930
    - sync/SyncHandlers.lua:937
    - sync/SyncHandlers.lua:943
    - sync/SyncHandlers.lua:954
    - sync/SyncHandlers.lua:974
    - sync/SyncHandlers.lua:981
    - sync/SyncHandlers.lua:989
    - sync/SyncHandlers.lua:991
    - sync/SyncHandlers.lua:996
    - sync/SyncHandlers.lua:1006
    - sync/SyncHandlers.lua:1011
    - sync/SyncHandlers.lua:1017
    - sync/SyncHandlers.lua:1022
    - sync/SyncHandlers.lua:1043
    - sync/SyncHandlers.lua:1048
    - sync/SyncHandlers.lua:1056
    - sync/ChunkManager.lua:16
    - sync/ChunkManager.lua:23
    - sync/ChunkManager.lua:32
    - sync/ChunkManager.lua:40
    - sync/ChunkManager.lua:60
    - sync/ChunkManager.lua:70
    - sync/Sync.lua:29
    - sync/Sync.lua:41
    - sync/Sync.lua:57
    - sync/Sync.lua:68
    - sync/Sync.lua:70
    - sync/Sync.lua:82
    - sync/Sync.lua:86
    - sync/Sync.lua:98
    - sync/Sync.lua:100
    - sync/Sync.lua:108
    - sync/Sync.lua:135
    - sync/Sync.lua:143
    - sync/Sync.lua:156
    - sync/Sync.lua:236
    - sync/Sync.lua:245
    - sync/Sync.lua:251
    - sync/Sync.lua:264
    - sync/Sync.lua:267
    - sync/Sync.lua:273
    - sync/Sync.lua:278
    - sync/Sync.lua:287
    - sync/Sync.lua:293
    - sync/Sync.lua:314
    - sync/Sync.lua:322
    - sync/Sync.lua:324
    - sync/Sync.lua:343
    - sync/Sync.lua:347
    - sync/Sync.lua:384
    - sync/Sync.lua:431
    - sync/Sync.lua:436
    - sync/Sync.lua:441
    - sync/Sync.lua:444
    - sync/Sync.lua:447
    - sync/Sync.lua:456
    - sync/Sync.lua:462
    - sync/Sync.lua:467
    - sync/Sync.lua:471
    - sync/Sync.lua:474
    - sync/Sync.lua:486
    - sync/Sync.lua:491
    - sync/Sync.lua:504
    - sync/Sync.lua:510
    - sync/Sync.lua:523
    - sync/Sync.lua:532
    - sync/Sync.lua:541
    - sync/Sync.lua:547
    - sync/Sync.lua:560
    - sync/Sync.lua:569
    - sync/Sync.lua:575
    - sync/Sync.lua:587
    - sync/Sync.lua:598
    - sync/Sync.lua:612
    - sync/Sync.lua:616
    - sync/Sync.lua:619
    - sync/Sync.lua:637
    - sync/Sync.lua:651
    - sync/Sync.lua:660
    - sync/Sync.lua:661
    - sync/Sync.lua:665
    - sync/Sync.lua:675
    - sync/Sync.lua:681
    - sync/Sync.lua:689
    - sync/Sync.lua:693
    - sync/Sync.lua:701
    - sync/Sync.lua:705
    - sync/Sync.lua:712
    - sync/Sync.lua:714
    - sync/Sync.lua:720
    - sync/Sync.lua:734
    - sync/Sync.lua:738
    - sync/Sync.lua:751
    - sync/Sync.lua:764
    - sync/Sync.lua:770
    - sync/Sync.lua:775
    - sync/Sync.lua:781
    - sync/Sync.lua:787
    - sync/Sync.lua:791
    - sync/Sync.lua:810
    - sync/Sync.lua:818
    - sync/Sync.lua:823
    - sync/Sync.lua:836
    - sync/Sync.lua:842
    - sync/Sync.lua:847
    - sync/Sync.lua:853
    - sync/Sync.lua:859
    - sync/Sync.lua:863
    - sync/Sync.lua:869
    - sync/Sync.lua:887
    - sync/Sync.lua:905
    - sync/Sync.lua:909
    - sync/Sync.lua:920
    - sync/Sync.lua:959
    - sync/Sync.lua:983
    - sync/Sync.lua:1001
    - sync/Sync.lua:1009
    - sync/Sync.lua:1018
    - sync/Sync.lua:1023
    - sync/Sync.lua:1028
    - sync/Sync.lua:1035
    - sync/Sync.lua:1037
    - sync/Sync.lua:1050
    - sync/Sync.lua:1058
    - sync/Sync.lua:1108
    - sync/Sync.lua:1113
    - sync/Sync.lua:1124
    - sync/Sync.lua:1129
    - sync/Sync.lua:1145
    - sync/Sync.lua:1164

- `TWRA:ProcessEarlyErrors()` - Line 285
  - Referenced in:
    - core/Debug.lua:650
    - core/Debug.lua:655 (in if )
    - core/Debug.lua:656

- `TWRA:ToggleDebug()` - Line 361
  - Referenced in:
    - core/Debug.lua:240
    - core/Debug.lua:704
    - core/Debug.lua:706
    - TWRA.lua:798

- `TWRA:ToggleDebugCategory()` - Line 402
  - Referenced in:
    - core/Debug.lua:759
    - core/Debug.lua:767
    - core/Debug.lua:775
    - core/Debug.lua:778
    - core/Debug.lua:824
    - core/Debug.lua:829
    - core/Debug.lua:831
    - core/Debug.lua:833
    - TWRA.lua:803

- `TWRA:ListDebugCategories()` - Line 442
  - Referenced in:
    - core/Debug.lua:755
    - TWRA.lua:795
    - TWRA.lua:806

- `TWRA:EnableFullDebug()` - Line 462
  - Referenced in:
    - core/Debug.lua:708

- `TWRA:ToggleDetailedLogging()` - Line 501
  - Referenced in:
    - core/Debug.lua:591
    - core/Debug.lua:728
    - core/Debug.lua:730
    - core/Debug.lua:733

- `TWRA:ToggleTimestamps()` - Line 543
  - Referenced in:
    - core/Debug.lua:739
    - core/Debug.lua:741

- `TWRA:SetDebugLevel()` - Line 563
  - Referenced in:
    - core/Debug.lua:717

- `TWRA:ShowDebugStats()` - Line 595
  - Referenced in:
    - core/Debug.lua:710

- `TWRA:HandleDebugCommand()` - Line 672
  - Referenced in:
    - core/Core.lua:364 (in if )
    - core/Core.lua:365

### 1.8 core/Events.lua

- `TWRA:RegisterEvent()` - Line 12
  - Referenced in:
    - ui/Frame.lua:20 (in --     if not )
    - ui/Frame.lua:26 (in --     )
    - ui/Minimap.lua:109 (in if )
    - ui/Minimap.lua:112
    - ui/Minimap.lua:152 (in if )
    - ui/Minimap.lua:153
    - ui/Minimap.lua:552 (in if )
    - ui/Minimap.lua:553
    - ui/OSD.lua:27 (in if )
    - ui/OSD.lua:31
    - ui/OSD.lua:64
    - ui/OSD.lua:79
    - features/AutoTanks.lua:11
    - sync/Sync.lua:671

- `TWRA:TriggerEvent()` - Line 40
  - Referenced in:
    - core/Utils.lua:216 (in if )
    - core/Utils.lua:217
    - TWRA.lua:127 (in local listenersCount = )
    - TWRA.lua:131
    - core/DataUtility.lua:480
    - ui/Frame.lua:903 (in if )
    - ui/Frame.lua:904

### 1.9 core/ItemLink.lua

- `TWRA:Items:GetLinkByName()` - Line 5
  - Referenced in:

- `TWRA:Items:ProcessText()` - Line 21
  - Referenced in:
    - TWRA.lua:685 (in processedText = )
    - ui/Frame.lua:1101 (in processedText = )
    - ui/Frame.lua:1162 (in announcementText = )
    - ui/OSD.lua:1053 (in processedText = )
    - ui/OSD.lua:1107 (in announcementText = )
    - ui/OSD.lua:1162 (in processedText = )
    - ui/OSD.lua:1212 (in announcementText = )

- `TWRA:Items:ProcessConsumables()` - Line 61
  - Referenced in:
    - TWRA.lua:689 (in processedText = )

- `TWRA:Items:EnhancedProcessText()` - Line 96
  - Referenced in:
    - ui/Frame.lua:1159 (in announcementText = )
    - ui/OSD.lua:1050 (in processedText = )
    - ui/OSD.lua:1105 (in announcementText = )
    - ui/OSD.lua:1160 (in processedText = )
    - ui/OSD.lua:1210 (in announcementText = )

### 1.10 core/Utils.lua

- `TWRA:ScheduleTimer()` - Line 4
  - Referenced in:
    - core/Debug.lua:653 (in if )
    - core/Debug.lua:654
    - core/Base64.lua:471
    - core/Base64.lua:869
    - TWRA.lua:710
    - core/Core.lua:763
    - core/DataProcessing.lua:1128
    - core/DataProcessing.lua:1132
    - ui/Frame.lua:1192
    - ui/Minimap.lua:158
    - ui/OSD.lua:195 (in TWRA.OSD.autoHideTimer = )
    - ui/OSD.lua:1127
    - ui/OSD.lua:1220
    - ui/OSD.lua:1371 (in self.OSD.autoHideTimer = )
    - ui/Options.lua:1271
    - ui/Options.lua:1285
    - ui/Options.lua:1291
    - features/AutoNavigate.lua:114
    - features/AutoNavigate.lua:129
    - features/AutoNavigate.lua:141
    - sync/SyncHandlers.lua:405
    - sync/SyncHandlers.lua:571 (in self.SYNC.missingSectionsTimeout = )
    - sync/SyncHandlers.lua:695
    - sync/SyncHandlers.lua:839
    - sync/SyncHandlers.lua:971 (in timer = )
    - sync/SyncHandlers.lua:995
    - sync/SyncHandlers.lua:1004
    - sync/SyncHandlers.lua:1047
    - sync/ChunkManager.lua:53
    - sync/Sync.lua:40
    - sync/Sync.lua:55
    - sync/Sync.lua:313 (in self.SYNC.bulkSyncRequestTimeout = )
    - sync/Sync.lua:489
    - sync/Sync.lua:609
    - sync/Sync.lua:1048
    - sync/Sync.lua:1157

- `TWRA:CancelTimer()` - Line 35
  - Referenced in:
    - ui/OSD.lua:170
    - ui/OSD.lua:1334
    - ui/OSD.lua:1364
    - ui/OSD.lua:1389
    - ui/Options.lua:975
    - sync/SyncHandlers.lua:452
    - sync/SyncHandlers.lua:563
    - sync/SyncHandlers.lua:720
    - sync/SyncHandlers.lua:958
    - sync/SyncHandlers.lua:1028
    - sync/SyncHandlers.lua:1060
    - sync/Sync.lua:310

- `TWRA:SplitString()` - Line 41
  - Referenced in:

- `TWRA:ConvertOptionValues()` - Line 69
  - Referenced in:
    - ui/Frame.lua:1211

- `TWRA:UpdatePlayerTable()` - Line 104
  - Referenced in:
    - TWRA.lua:879
    - core/Core.lua:63 (in return )
    - core/Core.lua:307 (in if )
    - core/Core.lua:309
    - core/Core.lua:788 (in if )
    - core/Core.lua:789

- `TWRA:GetTableSize()` - Line 249
  - Referenced in:
    - core/Utils.lua:244
    - core/Core.lua:312 (in local playerCount = )
    - features/AutoNavigate.lua:469
    - sync/SyncHandlers.lua:27

## 2. Sync Files

### 2.1 sync/ChunkManager.lua

- `TWRA:chunkManager:Initialize()` - Line 6
  - Referenced in:

- `TWRA:chunkManager:SendChunkedMessage()` - Line 21
  - Referenced in:
    - sync/Sync.lua:544
    - sync/Sync.lua:572
    - sync/Sync.lua:773 (in return )
    - sync/Sync.lua:845 (in return )
    - sync/Sync.lua:978 (in success = )
    - sync/Sync.lua:1021 (in local success = )

### 2.2 sync/Sync.lua

- `TWRA:RegisterSyncEvents()` - Line 28
  - Referenced in:

- `TWRA:CheckAndActivateLiveSync()` - Line 77
  - Referenced in:

- `TWRA:ActivateLiveSync()` - Line 90
  - Referenced in:
    - ui/Options.lua:1011 (in if )
    - ui/Options.lua:1012
    - sync/Sync.lua:83
    - sync/Sync.lua:463

- `TWRA:DeactivateLiveSync()` - Line 126
  - Referenced in:
    - ui/Options.lua:1020
    - ui/Options.lua:1021

- `TWRA:SendAddonMessage()` - Line 147
  - Referenced in:
    - sync/SyncHandlers.lua:614 (in local success = )
    - sync/SyncHandlers.lua:691
    - sync/SyncHandlers.lua:953
    - sync/ChunkManager.lua:39
    - sync/ChunkManager.lua:66
    - sync/Sync.lua:263
    - sync/Sync.lua:305 (in local success = )
    - sync/Sync.lua:351 (in return )
    - sync/Sync.lua:522
    - sync/Sync.lua:552 (in return )
    - sync/Sync.lua:580 (in return )
    - sync/Sync.lua:654
    - sync/Sync.lua:988 (in success = )
    - sync/Sync.lua:1033 (in local success = )
    - sync/Sync.lua:1159

- `TWRA:CreateSectionMessage()` - Line 172
  - Referenced in:
    - sync/Sync.lua:350 (in local message = )

- `TWRA:CreateBulkSectionMessage()` - Line 176
  - Referenced in:
    - sync/Sync.lua:930 (in local message = )

- `TWRA:CreateBulkStructureMessage()` - Line 180
  - Referenced in:
    - sync/Sync.lua:1014 (in local structureMessage = )

- `TWRA:CreateVersionMessage()` - Line 184
  - Referenced in:

- `TWRA:CreateMissingSectionsRequestMessage()` - Line 188
  - Referenced in:
    - sync/SyncHandlers.lua:551 (in local message = )
    - sync/SyncHandlers.lua:613 (in local message = )

- `TWRA:CreateMissingSectionsAckMessage()` - Line 193
  - Referenced in:
    - sync/SyncHandlers.lua:690 (in local ackMessage = )

- `TWRA:CreateMissingSectionResponseMessage()` - Line 197
  - Referenced in:
    - sync/SyncHandlers.lua:841 (in local message = )

- `TWRA:CreateBulkSyncRequestMessage()` - Line 201
  - Referenced in:
    - sync/Sync.lua:302 (in local message = )

- `TWRA:CreateBulkSyncAckMessage()` - Line 206
  - Referenced in:
    - sync/SyncHandlers.lua:952 (in local ackMessage = )

- `TWRA:CompareTimestamps()` - Line 215
  - Referenced in:
    - sync/SyncHandlers.lua:162 (in local comparisonResult = )
    - sync/SyncHandlers.lua:258 (in local timestampDiff = )

- `TWRA:RequestStructureSync()` - Line 232
  - Referenced in:

- `TWRA:RequestBulkSync()` - Line 272
  - Referenced in:
    - core/Core.lua:770 (in if )
    - core/Core.lua:771

- `TWRA:BroadcastSectionChange()` - Line 330
  - Referenced in:
    - sync/Sync.lua:708 (in local success = )

- `TWRA:OnChatMsgAddon()` - Line 354
  - Referenced in:
    - TWRA.lua:352 (in function )
    - sync/Sync.lua:498

- `TWRA:ToggleMessageMonitoring()` - Line 388
  - Referenced in:
    - core/Debug.lua:815 (in if )
    - core/Debug.lua:816
    - sync/Sync.lua:483

- `TWRA:ShowSyncStatus()` - Line 399
  - Referenced in:
    - core/Debug.lua:770 (in if )
    - core/Debug.lua:771

- `TWRA:InitializeSync()` - Line 430
  - Referenced in:
    - TWRA.lua:323 (in if )
    - TWRA.lua:325
    - sync/Sync.lua:42
    - sync/Sync.lua:58

- `TWRA:CHAT_MSG_ADDON()` - Line 497
  - Referenced in:

- `TWRA:RequestSectionSync()` - Line 501
  - Referenced in:
    - TWRA.lua:74 (in if )
    - TWRA.lua:76

- `TWRA:SendStructureResponse()` - Line 528
  - Referenced in:

- `TWRA:SendSectionResponse()` - Line 556
  - Referenced in:
    - sync/Sync.lua:615 (in if )
    - sync/Sync.lua:617

- `TWRA:QueueSectionResponse()` - Line 584
  - Referenced in:

- `TWRA:AnnounceDataImport()` - Line 634
  - Referenced in:

- `TWRA:RegisterSectionChangeHandler()` - Line 659
  - Referenced in:
    - sync/Sync.lua:74
    - sync/Sync.lua:435 (in if )
    - sync/Sync.lua:437
    - sync/Sync.lua:442
    - sync/Sync.lua:492

- `TWRA:GetCompressedStructure()` - Line 724
  - Referenced in:
    - sync/Sync.lua:530 (in local structureData = )
    - sync/Sync.lua:749 (in local structureData = )
    - sync/Sync.lua:1007 (in local structureData = )
    - sync/Sync.lua:1111 (in local structureData = )

- `TWRA:SendStructureData()` - Line 733
  - Referenced in:

- `TWRA:SendSectionData()` - Line 786
  - Referenced in:

- `TWRA:SendAllSections()` - Line 858
  - Referenced in:
    - core/Base64.lua:468 (in if )
    - core/Base64.lua:472
    - core/Base64.lua:866 (in if )
    - core/Base64.lua:870
    - ui/Frame.lua:98
    - ui/Options.lua:1282 (in if )
    - ui/Options.lua:1296
    - sync/SyncHandlers.lua:982 (in local success = )

- `TWRA:SerializeData()` - Line 1064
  - Referenced in:

- `TWRA:DeserializeData()` - Line 1086
  - Referenced in:

- `TWRA:SendStructureDataInChunks()` - Line 1107
  - Referenced in:

- `TWRA:SendSectionDataInChunks()` - Line 1123
  - Referenced in:

- `TWRA:SendDataInChunks()` - Line 1139
  - Referenced in:
    - sync/Sync.lua:1118
    - sync/Sync.lua:1134

### 2.3 sync/SyncHandlers.lua

- `TWRA:InitializeHandlerMap()` - Line 12
  - Referenced in:

- `TWRA:HandleAddonMessage()` - Line 30
  - Referenced in:
    - TWRA.lua:362 (in if )
    - TWRA.lua:363
    - core/Core.lua:257
    - sync/Sync.lua:380 (in if )
    - sync/Sync.lua:382

- `TWRA:ExtractDataPortion()` - Line 106
  - Referenced in:
    - sync/SyncHandlers.lua:63
    - sync/SyncHandlers.lua:68
    - sync/SyncHandlers.lua:88

- `TWRA:HandleSectionCommand()` - Line 129
  - Referenced in:
    - sync/SyncHandlers.lua:57 (in if )
    - sync/SyncHandlers.lua:58
    - sync/Sync.lua:418

- `TWRA:HandleBulkSectionCommand()` - Line 186
  - Referenced in:
    - sync/SyncHandlers.lua:62 (in if )
    - sync/SyncHandlers.lua:63

- `TWRA:HandleBulkStructureCommand()` - Line 233
  - Referenced in:
    - sync/SyncHandlers.lua:67 (in if )
    - sync/SyncHandlers.lua:68

- `TWRA:HandleStructureResponseCommand()` - Line 447
  - Referenced in:
    - sync/Sync.lua:421

- `TWRA:RequestMissingSectionsWhisper()` - Line 507
  - Referenced in:
    - sync/SyncHandlers.lua:441

- `TWRA:RequestMissingSectionsGroup()` - Line 579
  - Referenced in:
    - sync/SyncHandlers.lua:573

- `TWRA:HandleMissingSectionsRequestCommand()` - Line 625
  - Referenced in:
    - sync/SyncHandlers.lua:77 (in if )
    - sync/SyncHandlers.lua:78

- `TWRA:HandleMissingSectionsAckCommand()` - Line 702
  - Referenced in:
    - sync/SyncHandlers.lua:82 (in if )
    - sync/SyncHandlers.lua:83

- `TWRA:HandleMissingSectionResponseCommand()` - Line 727
  - Referenced in:
    - sync/SyncHandlers.lua:87 (in if )
    - sync/SyncHandlers.lua:88

- `TWRA:SendMissingSections()` - Line 803
  - Referenced in:
    - sync/SyncHandlers.lua:647 (in return )
    - sync/SyncHandlers.lua:696

- `TWRA:HandleBulkSyncRequestCommand()` - Line 858
  - Referenced in:
    - sync/SyncHandlers.lua:92 (in if )
    - sync/SyncHandlers.lua:93

- `TWRA:HandleBulkSyncAckCommand()` - Line 1016
  - Referenced in:
    - sync/SyncHandlers.lua:97 (in if )
    - sync/SyncHandlers.lua:98

## 3. Feature Files

### 3.1 features/AutoNavigate.lua

- `TWRA:CheckSuperWoWSupport()` - Line 13
  - Referenced in:
    - features/AutoNavigate.lua:48 (in if not )
    - features/AutoNavigate.lua:159 (in local hasSupport = )

- `TWRA:CheckSkullMarkedMob()` - Line 36
  - Referenced in:
    - TWRA.lua:304 (in if )
    - TWRA.lua:306

- `TWRA:RegisterAutoNavigateEvents()` - Line 102
  - Referenced in:
    - features/AutoNavigate.lua:490

- `TWRA:InitializeAutoNavigate()` - Line 150
  - Referenced in:
    - TWRA.lua:311 (in if )
    - features/AutoNavigate.lua:116
    - features/AutoNavigate.lua:133
    - features/AutoNavigate.lua:145

- `TWRA:ProcessMarkedMob()` - Line 202
  - Referenced in:
    - features/AutoNavigate.lua:97

- `TWRA:FindSectionByGuid()` - Line 255
  - Referenced in:
    - features/AutoNavigate.lua:215 (in local targetSection = )

- `TWRA:ToggleAutoNavigateDebug()` - Line 355
  - Referenced in:
    - core/Debug.lua:762 (in if )
    - core/Debug.lua:763

- `TWRA:ExtractGuidFromString()` - Line 411
  - Referenced in:
    - features/AutoNavigate.lua:396 (in local extractedGuid = )
    - features/AutoNavigate.lua:454 (in local extractedGuid = )

- `TWRA:ListAllGuids()` - Line 421
  - Referenced in:

### 3.2 features/AutoTanks.lua

- `TWRA:InitializeTankSync()` - Line 2
  - Referenced in:
    - ui/Options.lua:603 (in if isChecked and )
    - ui/Options.lua:604
    - sync/Sync.lua:466 (in if self.SYNC.tankSync and )
    - sync/Sync.lua:468

- `TWRA:IsORA2Available()` - Line 29
  - Referenced in:
    - ui/Options.lua:1031 (in if )
    - features/AutoTanks.lua:20 (in if )
    - features/AutoTanks.lua:52 (in if not )

- `TWRA:UpdateTanks()` - Line 33
  - Referenced in:
    - ui/Frame.lua:146
    - features/AutoTanks.lua:15
    - features/AutoTanks.lua:22

## 4. UI Files

### 4.1 ui/Frame.lua

- `TWRA:IsExampleData()` - Line 5
  - Referenced in:
    - Example.lua:524 (in function )
    - Example.lua:525 (in self:Debug("error", ")
    - TWRA.lua:432 (in function )
    - ui/Frame.lua:6 (in self:Debug("error", " )

- `TWRA:CloseDropdownMenu()` - Line 12
  - Referenced in:
    - ui/Frame.lua:97
    - ui/Frame.lua:132
    - ui/Frame.lua:145
    - ui/Frame.lua:163
    - ui/Frame.lua:175

- `TWRA:RegisterPlayerEvents()` - Line 18
  - Referenced in:

- `TWRA:CreateMainFrame()` - Line 41
  - Referenced in:
    - Example.lua:455
    - core/Core.lua:283 (in if not TWRA.mainFrame and )
    - core/Core.lua:284
    - core/Core.lua:456
    - core/Core.lua:467
    - core/Core.lua:527 (in if )
    - core/Core.lua:528
    - ui/Minimap.lua:343 (in if not TWRA.mainFrame and )
    - ui/Minimap.lua:344
    - ui/Minimap.lua:369 (in if )
    - ui/Minimap.lua:370
    - ui/Minimap.lua:531 (in if )
    - ui/Minimap.lua:532

- `TWRA:LoadInitialContent()` - Line 493
  - Referenced in:
    - core/Core.lua:535 (in if )
    - core/Core.lua:536
    - core/Core.lua:551 (in if )
    - core/Core.lua:552

- `TWRA:ShowMainView()` - Line 538
  - Referenced in:
    - core/Base64.lua:443 (in if )
    - core/Base64.lua:445
    - core/Base64.lua:841 (in if )
    - core/Base64.lua:843
    - Example.lua:468
    - core/Core.lua:485
    - ui/Frame.lua:119
    - ui/Minimap.lua:383 (in if )
    - ui/Minimap.lua:384
    - ui/Minimap.lua:544 (in if )
    - ui/Minimap.lua:545
    - ui/Options.lua:935 (in if )
    - ui/Options.lua:936

- `TWRA:FilterAndDisplayHandler()` - Line 634
  - Referenced in:
    - Example.lua:429 (in if )
    - Example.lua:430
    - TWRA.lua:137 (in if )
    - TWRA.lua:138
    - TWRA.lua:885 (in if )
    - TWRA.lua:886
    - core/DataProcessing.lua:380 (in self.currentView == "main" and )
    - core/DataProcessing.lua:381
    - core/DataProcessing.lua:1068 (in self.currentView == "main" and )
    - core/DataProcessing.lua:1069
    - core/DataUtility.lua:119
    - ui/Frame.lua:532
    - ui/Frame.lua:599
    - ui/Frame.lua:605
    - ui/Frame.lua:1232

- `TWRA:CreateFootersNewFormat()` - Line 910
  - Referenced in:
    - ui/Frame.lua:900

- `TWRA:ClearFooters()` - Line 1018
  - Referenced in:
    - TWRA.lua:846
    - ui/Frame.lua:520
    - ui/Frame.lua:578
    - ui/Frame.lua:667
    - ui/Frame.lua:912
    - ui/Frame.lua:1454

- `TWRA:CreateFooterElement()` - Line 1068
  - Referenced in:
    - ui/Frame.lua:991 (in local footer = )
    - ui/Frame.lua:999 (in local footer = )

- `TWRA:RefreshAssignmentTable()` - Line 1213
  - Referenced in:
    - core/Utils.lua:223 (in if )
    - core/Utils.lua:225
    - Example.lua:435 (in if )
    - Example.lua:436
    - ui/Frame.lua:30 (in --             if )
    - ui/Frame.lua:32 (in --                 )
    - sync/SyncHandlers.lua:389 (in if )
    - sync/SyncHandlers.lua:390
    - sync/SyncHandlers.lua:407 (in if )
    - sync/SyncHandlers.lua:408
    - sync/SyncHandlers.lua:785 (in if )
    - sync/SyncHandlers.lua:786

- `TWRA:CreateRow()` - Line 1235
  - Referenced in:
    - ui/Frame.lua:1407 (in self.rowFrames[i] = )

- `TWRA:CreateRows()` - Line 1395
  - Referenced in:
    - ui/Frame.lua:894

- `TWRA:ClearRows()` - Line 1413
  - Referenced in:
    - TWRA.lua:847
    - ui/Frame.lua:519
    - ui/Frame.lua:577
    - ui/Frame.lua:666

- `TWRA:ApplyRowHighlights()` - Line 1459
  - Referenced in:
    - ui/Frame.lua:897

- `TWRA:CreateHeaderCell()` - Line 1569
  - Referenced in:
    - ui/Frame.lua:1290 (in cell = )
    - ui/Frame.lua:1308 (in cell = )
    - ui/Frame.lua:1320 (in cell = )

- `TWRA:CalculateColumnWidths()` - Line 1614
  - Referenced in:
    - ui/Frame.lua:865 (in self.dynamicColumnWidths = )

### 4.2 ui/Minimap.lua

- `TWRA:DestroyMinimapButton()` - Line 12
  - Referenced in:

- `TWRA:InitializeMinimapButton()` - Line 68
  - Referenced in:
    - ui/Minimap.lua:178

- `TWRA:CreateMinimapButton()` - Line 191
  - Referenced in:
    - core/Core.lua:158
    - core/Core.lua:262
    - core/Core.lua:293 (in if not TWRA.minimapButton and )
    - core/Core.lua:295
    - ui/Minimap.lua:100 (in local success = )

- `TWRA:CreateMinimapDropdown()` - Line 608
  - Referenced in:
    - ui/Minimap.lua:254

### 4.3 ui/OSD.lua

- `TWRA:InitOSD()` - Line 6
  - Referenced in:
    - TWRA.lua:316 (in if )
    - core/Core.lua:300 (in if )
    - core/Core.lua:302
    - ui/OSD.lua:1411
    - ui/OSD.lua:1426
    - ui/Options.lua:61 (in if )
    - ui/Options.lua:62

- `TWRA:GetOSDFrame()` - Line 100
  - Referenced in:
    - ui/OSD.lua:1264 (in local frame = )
    - ui/OSD.lua:1323 (in local frame = )
    - ui/OSD.lua:1353 (in local frame = )

- `TWRA:UpdateOSDSettings()` - Line 280
  - Referenced in:
    - ui/Options.lua:780 (in if )
    - ui/Options.lua:781
    - ui/Options.lua:827 (in if )
    - ui/Options.lua:828
    - ui/Options.lua:839 (in if )
    - ui/Options.lua:840

- `TWRA:CreateRowBaseElements()` - Line 306
  - Referenced in:
    - ui/OSD.lua:392
    - ui/OSD.lua:928 (in local roleIcon, roleFontString = )

- `TWRA:CreateAssignmentRow()` - Line 390
  - Referenced in:
    - ui/OSD.lua:862 (in local rowWidth = )

- `TWRA:AddTargetDisplay()` - Line 687
  - Referenced in:
    - ui/OSD.lua:529 (in rowWidth = rowWidth + )
    - ui/OSD.lua:534 (in rowWidth = rowWidth + )

- `TWRA:GetIconInfo()` - Line 721
  - Referenced in:
    - ui/OSD.lua:541 (in local iconInfo = )
    - ui/OSD.lua:691 (in local iconInfo = )

- `TWRA:GetRoleIcon()` - Line 725
  - Referenced in:
    - ui/OSD.lua:311 (in local iconPath = )

- `TWRA:CreateContent()` - Line 752
  - Referenced in:
    - ui/OSD.lua:257
    - ui/OSD.lua:1292

- `TWRA:CreateDefaultContent()` - Line 899
  - Referenced in:
    - ui/OSD.lua:784 (in return )
    - ui/OSD.lua:791 (in return )
    - ui/OSD.lua:810 (in return )

- `TWRA:CreateWarnings()` - Line 953
  - Referenced in:
    - ui/OSD.lua:265
    - ui/OSD.lua:1298

- `TWRA:UpdateOSDContent()` - Line 1260
  - Referenced in:
    - core/Utils.lua:232 (in if )
    - core/Utils.lua:239
    - TWRA.lua:894
    - core/DataProcessing.lua:353 (in if )
    - core/DataProcessing.lua:354
    - core/DataProcessing.lua:387
    - core/DataProcessing.lua:1075
    - core/DataUtility.lua:127
    - ui/OSD.lua:40
    - ui/OSD.lua:49
    - ui/OSD.lua:73
    - ui/OSD.lua:90
    - ui/Options.lua:389
    - ui/Options.lua:723 (in if self.OSD and self.OSD.isVisible and )
    - ui/Options.lua:728
    - ui/Options.lua:930 (in if self.OSD and self.OSD.isVisible and )
    - ui/Options.lua:931

- `TWRA:ShowOSDPermanent()` - Line 1315
  - Referenced in:
    - ui/Minimap.lua:262 (in if )
    - ui/Minimap.lua:263
    - ui/OSD.lua:1417
    - ui/OSD.lua:1430

- `TWRA:ShowOSD()` - Line 1345
  - Referenced in:
    - ui/Minimap.lua:264 (in elseif )
    - ui/Minimap.lua:266
    - ui/Minimap.lua:325 (in if )
    - ui/Minimap.lua:326
    - ui/Minimap.lua:428 (in if )
    - ui/Minimap.lua:429
    - ui/Minimap.lua:445 (in if )
    - ui/Minimap.lua:446
    - ui/Minimap.lua:787 (in if not miniButton.osdWasShown and )
    - ui/Minimap.lua:788
    - ui/OSD.lua:58

- `TWRA:HideOSD()` - Line 1386
  - Referenced in:
    - Example.lua:511
    - ui/OSD.lua:199
    - ui/OSD.lua:299
    - ui/OSD.lua:1372
    - ui/OSD.lua:1415
    - ui/OSD.lua:1441

- `TWRA:ToggleOSD()` - Line 1408
  - Referenced in:
    - core/Core.lua:428 (in if )
    - core/Core.lua:429 (in local visible = )
    - ui/OSD.lua:1443
    - ui/Options.lua:376 (in local isVisible = )

- `TWRA:TestOSDVisual()` - Line 1423
  - Referenced in:
    - ui/OSD.lua:1439

- `TWRA:ShouldShowOSD()` - Line 1447
  - Referenced in:
    - ui/OSD.lua:52 (in if )

- `TWRA:ResetOSDPosition()` - Line 1467
  - Referenced in:
    - ui/Options.lua:834 (in if )
    - ui/Options.lua:835

### 4.4 ui/Options.lua

- `TWRA:InitOptions()` - Line 5
  - Referenced in:
    - core/Core.lua:202 (in if )
    - core/Core.lua:204

- `TWRA:UpdateSliderState()` - Line 72
  - Referenced in:
    - ui/Options.lua:631
    - ui/Options.lua:638
    - ui/Options.lua:646

- `TWRA:CreateCheckbox()` - Line 90
  - Referenced in:
    - ui/Options.lua:184 (in local liveSync, liveSyncText = )
    - ui/Options.lua:189 (in local tankSyncCheckbox, tankSyncText = )
    - ui/Options.lua:210 (in local autoNavigate, autoNavigateText = )
    - ui/Options.lua:310
    - ui/Options.lua:331 (in local showOnNavOSD, showOnNavOSDText = )
    - ui/Options.lua:336 (in local lockOSD, lockOSDText = )

- `TWRA:CreateOptionsInMainFrame()` - Line 107
  - Referenced in:
    - TWRA.lua:834

- `TWRA:RestartAutoNavigateTimer()` - Line 962
  - Referenced in:
    - ui/Options.lua:663
    - ui/Options.lua:664

- `TWRA:ApplyInitialSettings()` - Line 990
  - Referenced in:
    - ui/Options.lua:66

- `TWRA:DirectImport()` - Line 1061
  - Referenced in:
    - ui/Options.lua:855 (in local success = )

### 4.5 ui/UIUtils.lua

- `TWRA:UI:ApplyClassColoring()` - Line 5
  - Referenced in:
    - ui/Frame.lua:1357
    - ui/OSD.lua:465
    - ui/OSD.lua:632

- `TWRA:UI:CreateIconWithTooltip()` - Line 51
  - Referenced in:
    - ui/Options.lua:194
    - ui/Options.lua:215 (in local autoNavIcon, autoNavIconFrame = )
    - ui/Options.lua:277 (in local groupIcon, groupIconFrame = )
    - ui/Options.lua:315 (in local notesIcon, notesIconFrame = )

## 5. Duplicate Functions

- `TWRA:OnChatMsgAddon()` is defined in multiple locations:
  - TWRA.lua:352
  - sync/Sync.lua:354

- `TWRA:OnGroupChanged()` is defined in multiple locations:
  - TWRA.lua:874
  - core/Core.lua:748

- `TWRA:DecompressAssignmentsData()` is defined in multiple locations:
  - core/Base64.lua:131
  - core/Compression.lua:651

- `TWRA:IsExampleData()` is defined in multiple locations:
  - Example.lua:524
  - TWRA.lua:432
  - ui/Frame.lua:5

