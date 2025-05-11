# TWRA Function Map

This document maps all functions in the TWRA addon, showing where they are defined and where they are referenced throughout the codebase.

## 1. UI Files

### 1.1 ui/Frame.lua

- `TWRA:IsExampleData()` - Line 5
  - Referenced in:
    - Example.lua:524 (in function )
    - Example.lua:525 (in self:Debug("error", ")
    - TWRA.lua:495 (in function )
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
    - core/Core.lua:475
    - core/Core.lua:486
    - core/Core.lua:548 (in if )
    - core/Core.lua:549
    - ui/Minimap.lua:343 (in if not TWRA.mainFrame and )
    - ui/Minimap.lua:344
    - ui/Minimap.lua:369 (in if )
    - ui/Minimap.lua:370
    - ui/Minimap.lua:531 (in if )
    - ui/Minimap.lua:532

- `TWRA:LoadInitialContent()` - Line 493
  - Referenced in:
    - core/Core.lua:556 (in if )
    - core/Core.lua:557
    - core/Core.lua:572 (in if )
    - core/Core.lua:573

- `TWRA:ShowMainView()` - Line 538
  - Referenced in:
    - core/Base64.lua:443 (in if )
    - core/Base64.lua:445
    - core/Base64.lua:789 (in if )
    - core/Base64.lua:791
    - Example.lua:468
    - core/Core.lua:504
    - ui/Frame.lua:119
    - ui/Minimap.lua:383 (in if )
    - ui/Minimap.lua:384
    - ui/Minimap.lua:544 (in if )
    - ui/Minimap.lua:545
    - ui/Options.lua:886 (in if )
    - ui/Options.lua:887

- `TWRA:FilterAndDisplayHandler()` - Line 634
  - Referenced in:
    - Example.lua:429 (in if )
    - Example.lua:430
    - TWRA.lua:137 (in if )
    - TWRA.lua:138
    - TWRA.lua:959 (in if )
    - TWRA.lua:960
    - core/DataProcessing.lua:380 (in self.currentView == "main" and )
    - core/DataProcessing.lua:381
    - core/DataProcessing.lua:1075 (in self.currentView == "main" and )
    - core/DataProcessing.lua:1076
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
    - TWRA.lua:920
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
    - sync/SyncHandlers.lua:427 (in if )
    - sync/SyncHandlers.lua:428
    - sync/SyncHandlers.lua:633 (in if )
    - sync/SyncHandlers.lua:634
    - sync/SyncHandlers.lua:651 (in if )
    - sync/SyncHandlers.lua:652
    - sync/SyncHandlers.lua:1029 (in if )
    - sync/SyncHandlers.lua:1030

- `TWRA:CreateRow()` - Line 1235
  - Referenced in:
    - ui/Frame.lua:1407 (in self.rowFrames[i] = )

- `TWRA:CreateRows()` - Line 1395
  - Referenced in:
    - ui/Frame.lua:894

- `TWRA:ClearRows()` - Line 1413
  - Referenced in:
    - TWRA.lua:921
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

### 1.2 ui/Minimap.lua

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

### 1.3 ui/OSD.lua

- `TWRA:InitOSD()` - Line 6
  - Referenced in:
    - TWRA.lua:308 (in if )
    - core/Core.lua:300 (in if )
    - core/Core.lua:302
    - ui/OSD.lua:1446
    - ui/OSD.lua:1461
    - ui/Options.lua:60 (in if )
    - ui/Options.lua:61

- `TWRA:GetOSDFrame()` - Line 100
  - Referenced in:
    - ui/OSD.lua:1299 (in local frame = )
    - ui/OSD.lua:1358 (in local frame = )
    - ui/OSD.lua:1388 (in local frame = )

- `TWRA:UpdateOSDSettings()` - Line 315
  - Referenced in:
    - ui/Options.lua:731 (in if )
    - ui/Options.lua:732
    - ui/Options.lua:778 (in if )
    - ui/Options.lua:779
    - ui/Options.lua:790 (in if )
    - ui/Options.lua:791

- `TWRA:CreateRowBaseElements()` - Line 341
  - Referenced in:
    - ui/OSD.lua:427
    - ui/OSD.lua:963 (in local roleIcon, roleFontString = )

- `TWRA:CreateAssignmentRow()` - Line 425
  - Referenced in:
    - ui/OSD.lua:897 (in local rowWidth = )

- `TWRA:AddTargetDisplay()` - Line 722
  - Referenced in:
    - ui/OSD.lua:564 (in rowWidth = rowWidth + )
    - ui/OSD.lua:569 (in rowWidth = rowWidth + )

- `TWRA:GetIconInfo()` - Line 756
  - Referenced in:
    - ui/OSD.lua:576 (in local iconInfo = )
    - ui/OSD.lua:726 (in local iconInfo = )

- `TWRA:GetRoleIcon()` - Line 760
  - Referenced in:
    - ui/OSD.lua:346 (in local iconPath = )

- `TWRA:CreateContent()` - Line 787
  - Referenced in:
    - ui/OSD.lua:292
    - ui/OSD.lua:1327

- `TWRA:CreateDefaultContent()` - Line 934
  - Referenced in:
    - ui/OSD.lua:819 (in return )
    - ui/OSD.lua:826 (in return )
    - ui/OSD.lua:845 (in return )

- `TWRA:CreateWarnings()` - Line 988
  - Referenced in:
    - ui/OSD.lua:300
    - ui/OSD.lua:1333

- `TWRA:UpdateOSDContent()` - Line 1295
  - Referenced in:
    - core/Utils.lua:232 (in if )
    - core/Utils.lua:239
    - TWRA.lua:968
    - core/DataProcessing.lua:353 (in if )
    - core/DataProcessing.lua:354
    - core/DataProcessing.lua:387
    - core/DataProcessing.lua:1082
    - core/DataUtility.lua:127
    - ui/OSD.lua:40
    - ui/OSD.lua:49
    - ui/OSD.lua:73
    - ui/OSD.lua:90
    - ui/Options.lua:374
    - ui/Options.lua:674 (in if self.OSD and self.OSD.isVisible and )
    - ui/Options.lua:679
    - ui/Options.lua:881 (in if self.OSD and self.OSD.isVisible and )
    - ui/Options.lua:882

- `TWRA:ShowOSDPermanent()` - Line 1350
  - Referenced in:
    - ui/Minimap.lua:262 (in if )
    - ui/Minimap.lua:263
    - ui/OSD.lua:1452
    - ui/OSD.lua:1465

- `TWRA:ShowOSD()` - Line 1380
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

- `TWRA:HideOSD()` - Line 1421
  - Referenced in:
    - Example.lua:511
    - ui/OSD.lua:149
    - ui/OSD.lua:234
    - ui/OSD.lua:334
    - ui/OSD.lua:1407
    - ui/OSD.lua:1450
    - ui/OSD.lua:1476

- `TWRA:ToggleOSD()` - Line 1443
  - Referenced in:
    - core/Core.lua:447 (in if )
    - core/Core.lua:448 (in local visible = )
    - ui/OSD.lua:1478
    - ui/Options.lua:361 (in local isVisible = )

- `TWRA:TestOSDVisual()` - Line 1458
  - Referenced in:
    - ui/OSD.lua:1474

- `TWRA:ShouldShowOSD()` - Line 1482
  - Referenced in:
    - ui/OSD.lua:52 (in if )

- `TWRA:ResetOSDPosition()` - Line 1502
  - Referenced in:
    - ui/Options.lua:785 (in if )
    - ui/Options.lua:786

### 1.4 ui/Options.lua

- `TWRA:InitOptions()` - Line 5
  - Referenced in:
    - core/Core.lua:202 (in if )
    - core/Core.lua:204

- `TWRA:UpdateSliderState()` - Line 71
  - Referenced in:

- `TWRA:CreateCheckbox()` - Line 89
  - Referenced in:
    - ui/Options.lua:183 (in local liveSync, liveSyncText = )
    - ui/Options.lua:188 (in local tankSyncCheckbox, tankSyncText = )
    - ui/Options.lua:209 (in local autoNavigate, autoNavigateText = )
    - ui/Options.lua:295
    - ui/Options.lua:316 (in local showOnNavOSD, showOnNavOSDText = )
    - ui/Options.lua:321 (in local lockOSD, lockOSDText = )

- `TWRA:CreateOptionsInMainFrame()` - Line 106
  - Referenced in:
    - TWRA.lua:908

- `TWRA:RestartAutoNavigateTimer()` - Line 913
  - Referenced in:

- `TWRA:ApplyInitialSettings()` - Line 940
  - Referenced in:
    - ui/Options.lua:65

- `TWRA:DirectImport()` - Line 1007
  - Referenced in:
    - ui/Options.lua:806 (in local success = )

### 1.5 ui/UIUtils.lua

- `TWRA:UI:ApplyClassColoring()` - Line 5
  - Referenced in:
    - ui/Frame.lua:1357
    - ui/OSD.lua:500
    - ui/OSD.lua:667

- `TWRA:UI:CreateIconWithTooltip()` - Line 51
  - Referenced in:
    - ui/Options.lua:193
    - ui/Options.lua:214 (in local autoNavIcon, autoNavIconFrame = )
    - ui/Options.lua:262 (in local groupIcon, groupIconFrame = )
    - ui/Options.lua:300 (in local notesIcon, notesIconFrame = )

## 2. Core Files

### 2.1 TWRA.lua

- `TWRA:NavigateToSection()` - Line 12
  - Referenced in:
    - core/Base64.lua:455 (in -- if )
    - core/Base64.lua:457 (in --     )
    - core/Base64.lua:502 (in -- if )
    - core/Base64.lua:504 (in --     )
    - core/Base64.lua:801 (in -- if )
    - core/Base64.lua:803 (in --     )
    - core/Base64.lua:854 (in if )
    - core/Base64.lua:856
    - core/Compression.lua:770 (in if )
    - core/Compression.lua:771
    - Example.lua:381
    - Example.lua:506
    - TWRA.lua:331
    - core/Core.lua:468
    - core/Core.lua:619
    - core/DataUtility.lua:533 (in --     if )
    - core/DataUtility.lua:535 (in --         )
    - core/DataUtility.lua:538
    - ui/Frame.lua:385
    - ui/Minimap.lua:770
    - features/AutoNavigate.lua:243
    - sync/SyncHandlers.lua:167
    - sync/SyncHandlers.lua:624 (in if )
    - sync/SyncHandlers.lua:628
    - sync/SyncHandlers.lua:659 (in if )
    - sync/SyncHandlers.lua:660

- `TWRA:Initialize()` - Line 152
  - Referenced in:
    - TWRA.lua:901
    - sync/ChunkManager.lua:30

- `TWRA:LoadSavedAssignments()` - Line 336
  - Referenced in:

- `TWRA:OnChatMsgAddon()` - Line 415
  - Referenced in:
    - sync/Sync.lua:354 (in function )
    - sync/Sync.lua:498

- `TWRA:TruncateString()` - Line 432
  - Referenced in:
    - TWRA.lua:422

- `TWRA:CleanAssignmentData()` - Line 438
  - Referenced in:

- `TWRA:IsExampleData()` - Line 495
  - Referenced in:
    - Example.lua:524 (in function )
    - Example.lua:525 (in self:Debug("error", ")
    - ui/Frame.lua:5 (in function )
    - ui/Frame.lua:6 (in self:Debug("error", " )

- `TWRA:AnnounceAssignments()` - Line 511
  - Referenced in:
    - ui/Frame.lua:133

- `TWRA:SendAnnouncementMessages()` - Line 693
  - Referenced in:
    - TWRA.lua:690

- `TWRA:GetAnnouncementChannels()` - Line 781
  - Referenced in:
    - TWRA.lua:700 (in local channelInfo = )

- `TWRA:ShowOptionsView()` - Line 903
  - Referenced in:
    - core/Core.lua:478
    - ui/Frame.lua:116
    - ui/Minimap.lua:350 (in if )
    - ui/Minimap.lua:351
    - ui/Minimap.lua:357 (in if )
    - ui/Minimap.lua:358

- `TWRA:OnGroupChanged()` - Line 948
  - Referenced in:
    - core/Core.lua:769 (in function )
    - core/Core.lua:816
    - core/Core.lua:821

### 2.2 core/Base64.lua

- `TWRA:CompressAssignmentsData()` - Line 87
  - Referenced in:
    - core/Base64.lua:712 (in local compressedData = )

- `TWRA:DecompressAssignmentsData()` - Line 131
  - Referenced in:
    - core/Base64.lua:528 (in local decompressedData = )
    - core/Compression.lua:651 (in function )
    - core/Compression.lua:717 (in local decompressedData = )

- `TWRA:PrepareDataForSync()` - Line 179
  - Referenced in:
    - core/Base64.lua:711 (in local syncReadyData = )

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
    - ui/Options.lua:1034 (in local decodedString = )

- `TWRA:TableToLuaString()` - Line 886
  - Referenced in:
    - core/Base64.lua:898 (in result = result .. )
    - core/Base64.lua:916 (in result = result .. )

- `TWRA:EncodeBase64()` - Line 933
  - Referenced in:
    - core/Base64.lua:125 (in local base64String = )
    - core/Compression.lua:141 (in local encodedData = )
    - core/Compression.lua:159 (in local encodedData = )
    - core/Compression.lua:257 (in compressed = )

### 2.3 core/Compression.lua

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
    - sync/Sync.lua:782 (in if )
    - sync/Sync.lua:784 (in sectionData = )

- `TWRA:DecompressStructureData()` - Line 263
  - Referenced in:
    - sync/SyncHandlers.lua:539 (in return )

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
    - TWRA.lua:393 (in elseif )
    - TWRA.lua:394
    - core/DataProcessing.lua:411 (in if )
    - core/DataProcessing.lua:413 (in return )
    - core/DataUtility.lua:448 (in if )
    - core/DataUtility.lua:449
    - ui/Options.lua:855 (in elseif )
    - ui/Options.lua:857
    - ui/Options.lua:1132 (in if )
    - ui/Options.lua:1134
    - ui/Options.lua:1160 (in if )
    - ui/Options.lua:1161

- `TWRA:DecompressAssignmentsData()` - Line 651
  - Referenced in:
    - core/Base64.lua:131 (in function )
    - core/Base64.lua:528 (in local decompressedData = )
    - core/Compression.lua:717 (in local decompressedData = )

- `TWRA:ProcessCompressedData()` - Line 708
  - Referenced in:

### 2.4 core/Core.lua

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

- `TWRA:ToggleMainFrame()` - Line 536
  - Referenced in:
    - Example.lua:462
    - TWRA.lua:897
    - core/Core.lua:510

- `TWRA:NavigateHandler()` - Line 596
  - Referenced in:
    - core/Core.lua:459
    - core/Core.lua:463
    - ui/Frame.lua:164
    - ui/Frame.lua:176
    - ui/Minimap.lua:419 (in if )
    - ui/Minimap.lua:420
    - ui/Minimap.lua:436 (in if )
    - ui/Minimap.lua:437

- `TWRA:RebuildNavigation()` - Line 622
  - Referenced in:
    - core/Base64.lua:449 (in -- if )
    - core/Base64.lua:451 (in --     )
    - core/Base64.lua:490 (in if )
    - core/Base64.lua:492
    - core/Base64.lua:795 (in -- if )
    - core/Base64.lua:797 (in --     )
    - core/Base64.lua:842 (in if )
    - core/Base64.lua:844
    - core/Compression.lua:750 (in if )
    - core/Compression.lua:751
    - Example.lua:305 (in if )
    - Example.lua:307
    - TWRA.lua:355 (in if )
    - TWRA.lua:356
    - core/Core.lua:211
    - core/Core.lua:746 (in return )
    - core/DataUtility.lua:483 (in if )
    - core/DataUtility.lua:485
    - ui/Frame.lua:453
    - sync/SyncHandlers.lua:577 (in if )
    - sync/SyncHandlers.lua:578

- `TWRA:SaveCurrentSection()` - Line 685
  - Referenced in:
    - Example.lua:410

- `TWRA:EnsureUIUtils()` - Line 708
  - Referenced in:
    - core/Core.lua:717

- `TWRA:ResetUI()` - Line 719
  - Referenced in:
    - core/Core.lua:214

- `TWRA:BuildNavigationFromNewFormat()` - Line 743
  - Referenced in:

- `TWRA:RegisterAddonMessaging()` - Line 749
  - Referenced in:
    - core/Core.lua:153

- `TWRA:OnGroupChanged()` - Line 769
  - Referenced in:
    - TWRA.lua:948 (in function )
    - core/Core.lua:816
    - core/Core.lua:821

- `TWRA:OnRaidRosterUpdate()` - Line 814
  - Referenced in:
    - core/Core.lua:266 (in if )
    - core/Core.lua:267

- `TWRA:OnPartyMembersChanged()` - Line 819
  - Referenced in:
    - core/Core.lua:271 (in if )
    - core/Core.lua:272

### 2.5 core/DataProcessing.lua

- `TWRA:EnsureCompleteRows()` - Line 3
  - Referenced in:
    - core/Base64.lua:697 (in result = )
    - core/DataUtility.lua:393 (in if )
    - core/DataUtility.lua:394 (in data = )

- `TWRA:ProcessPlayerInfo()` - Line 56
  - Referenced in:
    - core/Base64.lua:547 (in if )
    - core/Base64.lua:548
    - core/Base64.lua:720 (in if )
    - core/Base64.lua:733
    - core/Compression.lua:760 (in elseif )
    - core/Compression.lua:761
    - Example.lua:396 (in if )
    - Example.lua:398
    - core/DataProcessing.lua:770 (in if )
    - core/DataProcessing.lua:774
    - core/DataProcessing.lua:778
    - core/DataUtility.lua:517 (in if )
    - core/DataUtility.lua:519
    - ui/Options.lua:874 (in if )
    - ui/Options.lua:877 (in pcall(function() )
    - ui/Options.lua:1176 (in if )
    - ui/Options.lua:1178 (in pcall(function() )

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
    - core/DataProcessing.lua:1066

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
    - core/Base64.lua:848 (in if )
    - core/Base64.lua:849
    - core/Compression.lua:758 (in if )
    - core/Compression.lua:759
    - TWRA.lua:954

- `TWRA:StoreCompressedData()` - Line 397
  - Referenced in:
    - core/Base64.lua:544
    - core/Base64.lua:714
    - TWRA.lua:391 (in if )
    - TWRA.lua:392
    - ui/Options.lua:852 (in if )
    - ui/Options.lua:854
    - ui/Options.lua:1135 (in elseif )
    - ui/Options.lua:1137
    - ui/Options.lua:1162 (in elseif )
    - ui/Options.lua:1163

- `TWRA:ClearDataForStructureResponse()` - Line 433
  - Referenced in:

- `TWRA:BuildSkeletonFromStructure()` - Line 462
  - Referenced in:
    - sync/SyncHandlers.lua:559 (in if )
    - sync/SyncHandlers.lua:561 (in hasBuiltSkeleton = )

- `TWRA:ProcessSectionData()` - Line 523
  - Referenced in:
    - TWRA.lua:86 (in if )
    - TWRA.lua:88
    - sync/SyncHandlers.lua:399 (in if )
    - sync/SyncHandlers.lua:401
    - sync/SyncHandlers.lua:424
    - sync/SyncHandlers.lua:621
    - sync/SyncHandlers.lua:745
    - sync/SyncHandlers.lua:1026

- `TWRA:GenerateOSDInfoForSection()` - Line 809
  - Referenced in:
    - core/DataProcessing.lua:186 (in playerInfo["OSD Assignments"] = )
    - core/DataProcessing.lua:327 (in playerInfo["OSD Group Assignments"] = )

- `TWRA:GetAllGroupRowsForSection()` - Line 973
  - Referenced in:
    - core/Compression.lua:228 (in if )
    - core/Compression.lua:229
    - core/DataProcessing.lua:259
    - core/DataProcessing.lua:1174
    - core/DataUtility.lua:587 (in metadata["Group Rows"] = )
    - ui/Options.lua:826

- `TWRA:UpdateGroupInfo()` - Line 1045
  - Referenced in:
    - core/DataProcessing.lua:1124

- `TWRA:MonitorGroupChanges()` - Line 1090
  - Referenced in:
    - core/DataProcessing.lua:1157

- `TWRA:InitializeGroupMonitoring()` - Line 1155
  - Referenced in:
    - core/Core.lua:145 (in if )
    - core/Core.lua:147

- `TWRA:EnsureGroupRowsIdentified()` - Line 1160
  - Referenced in:
    - core/DataUtility.lua:406 (in if )
    - core/DataUtility.lua:415

- `TWRA:IsCellRelevantForPlayer()` - Line 1184
  - Referenced in:
    - core/DataProcessing.lua:885 (in elseif )

- `TWRA:IsCellRelevantForPlayerGroup()` - Line 1215
  - Referenced in:
    - core/DataProcessing.lua:864 (in if )

### 2.6 core/DataUtility.lua

- `TWRA:ConvertSpecialCharacters()` - Line 30
  - Referenced in:
    - core/DataUtility.lua:56 (in return )
    - core/DataUtility.lua:64 (in k = )
    - core/DataUtility.lua:70 (in result[k] = )

- `TWRA:FixSpecialCharacters()` - Line 53
  - Referenced in:
    - core/Base64.lua:705 (in if )
    - core/Base64.lua:706 (in result = )
    - core/DataUtility.lua:68 (in result[k] = )

- `TWRA:GetCurrentSectionData()` - Line 78
  - Referenced in:
    - TWRA.lua:526 (in local sectionData = )
    - core/DataUtility.lua:113 (in local sectionData = )
    - features/AutoTanks.lua:60 (in local sectionData = )

- `TWRA:DisplayCurrentSection()` - Line 112
  - Referenced in:
    - TWRA.lua:140 (in elseif )
    - TWRA.lua:141
    - TWRA.lua:962 (in elseif )
    - TWRA.lua:963
    - ui/Options.lua:1204 (in if )
    - ui/Options.lua:1215
    - ui/Options.lua:1237

- `TWRA:FindTankRoleColumns()` - Line 133
  - Referenced in:
    - core/DataProcessing.lua:828 (in tankColumns = )

- `TWRA:NormalizeMetadataKeys()` - Line 187
  - Referenced in:
    - core/DataUtility.lua:226 (in local normalizedMetadata = )
    - core/DataUtility.lua:296 (in section["Section Metadata"] = )

- `TWRA:ClearData()` - Line 209
  - Referenced in:
    - core/Base64.lua:770 (in if )
    - core/Base64.lua:771
    - Example.lua:274 (in if )
    - Example.lua:275
    - core/DataUtility.lua:385 (in if not )

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
    - core/Base64.lua:778 (in if )
    - core/Base64.lua:780
    - core/DataUtility.lua:335

- `TWRA:ProcessImportedData()` - Line 544
  - Referenced in:
    - core/Base64.lua:700 (in if )
    - core/Base64.lua:701 (in result = )
    - ui/Options.lua:845 (in if )
    - ui/Options.lua:847 (in TWRA_Assignments.data = )

- `TWRA:CaptureSpecialRows()` - Line 554
  - Referenced in:
    - core/DataUtility.lua:400 (in if )
    - core/DataUtility.lua:401 (in data = )

### 2.7 core/Debug.lua

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
    - TWRA.lua:311 (in if )
    - core/Core.lua:111 (in if )
    - core/Core.lua:112

- `TWRA:Error()` - Line 196
  - Referenced in:
    - core/Debug.lua:719
    - core/Core.lua:206
    - core/Core.lua:562

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
    - core/Base64.lua:450 (in --     )
    - core/Base64.lua:456 (in --     )
    - core/Base64.lua:462
    - core/Base64.lua:469
    - core/Base64.lua:475
    - core/Base64.lua:478
    - core/Base64.lua:481
    - core/Base64.lua:487
    - core/Base64.lua:491
    - core/Base64.lua:498
    - core/Base64.lua:503 (in --     )
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
    - core/Base64.lua:710
    - core/Base64.lua:716
    - core/Base64.lua:721
    - core/Base64.lua:734
    - core/Base64.lua:746
    - core/Base64.lua:758
    - core/Base64.lua:769
    - core/Base64.lua:785
    - core/Base64.lua:790
    - core/Base64.lua:796 (in --     )
    - core/Base64.lua:802 (in --     )
    - core/Base64.lua:808
    - core/Base64.lua:815
    - core/Base64.lua:821
    - core/Base64.lua:824
    - core/Base64.lua:827
    - core/Base64.lua:831
    - core/Base64.lua:839
    - core/Base64.lua:843
    - core/Base64.lua:850
    - core/Base64.lua:855
    - core/Base64.lua:862
    - core/Base64.lua:866
    - core/Base64.lua:873
    - core/Base64.lua:880
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
    - TWRA.lua:312
    - TWRA.lua:316
    - TWRA.lua:329
    - TWRA.lua:337
    - TWRA.lua:350
    - TWRA.lua:357
    - TWRA.lua:359
    - TWRA.lua:390
    - TWRA.lua:396
    - TWRA.lua:402
    - TWRA.lua:422
    - TWRA.lua:428
    - TWRA.lua:439
    - TWRA.lua:462
    - TWRA.lua:470
    - TWRA.lua:473
    - TWRA.lua:487
    - TWRA.lua:496
    - TWRA.lua:519
    - TWRA.lua:523
    - TWRA.lua:528
    - TWRA.lua:544
    - TWRA.lua:564
    - TWRA.lua:567
    - TWRA.lua:666
    - TWRA.lua:682
    - TWRA.lua:686
    - TWRA.lua:695
    - TWRA.lua:703
    - TWRA.lua:727
    - TWRA.lua:729
    - TWRA.lua:738
    - TWRA.lua:744
    - TWRA.lua:754
    - TWRA.lua:772
    - TWRA.lua:825
    - TWRA.lua:832
    - TWRA.lua:945
    - TWRA.lua:949
    - TWRA.lua:961
    - TWRA.lua:964
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
    - core/Core.lua:449
    - core/Core.lua:458
    - core/Core.lua:462
    - core/Core.lua:467
    - core/Core.lua:479
    - core/Core.lua:484
    - core/Core.lua:488
    - core/Core.lua:490
    - core/Core.lua:496
    - core/Core.lua:498
    - core/Core.lua:506
    - core/Core.lua:539
    - core/Core.lua:559
    - core/Core.lua:568
    - core/Core.lua:575
    - core/Core.lua:588
    - core/Core.lua:599
    - core/Core.lua:623
    - core/Core.lua:637
    - core/Core.lua:643
    - core/Core.lua:665
    - core/Core.lua:668
    - core/Core.lua:675
    - core/Core.lua:679
    - core/Core.lua:697
    - core/Core.lua:714
    - core/Core.lua:720
    - core/Core.lua:740
    - core/Core.lua:745
    - core/Core.lua:753
    - core/Core.lua:760
    - core/Core.lua:762
    - core/Core.lua:766
    - core/Core.lua:770
    - core/Core.lua:781
    - core/Core.lua:787
    - core/Core.lua:794
    - core/Core.lua:797
    - core/Core.lua:800
    - core/Core.lua:805
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
    - core/DataProcessing.lua:924
    - core/DataProcessing.lua:960
    - core/DataProcessing.lua:969
    - core/DataProcessing.lua:978
    - core/DataProcessing.lua:982
    - core/DataProcessing.lua:988
    - core/DataProcessing.lua:991
    - core/DataProcessing.lua:1015
    - core/DataProcessing.lua:1026
    - core/DataProcessing.lua:1033
    - core/DataProcessing.lua:1038
    - core/DataProcessing.lua:1046
    - core/DataProcessing.lua:1060
    - core/DataProcessing.lua:1062
    - core/DataProcessing.lua:1077
    - core/DataProcessing.lua:1083
    - core/DataProcessing.lua:1091
    - core/DataProcessing.lua:1116
    - core/DataProcessing.lua:1145
    - core/DataProcessing.lua:1151
    - core/DataProcessing.lua:1156
    - core/DataProcessing.lua:1162
    - core/DataProcessing.lua:1166
    - core/DataProcessing.lua:1176
    - core/DataProcessing.lua:1197
    - core/DataProcessing.lua:1205
    - core/DataProcessing.lua:1256
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
    - core/DataUtility.lua:376
    - core/DataUtility.lua:381
    - core/DataUtility.lua:384
    - core/DataUtility.lua:386
    - core/DataUtility.lua:388
    - core/DataUtility.lua:395
    - core/DataUtility.lua:399
    - core/DataUtility.lua:402
    - core/DataUtility.lua:416
    - core/DataUtility.lua:447
    - core/DataUtility.lua:450
    - core/DataUtility.lua:452
    - core/DataUtility.lua:454
    - core/DataUtility.lua:456
    - core/DataUtility.lua:471 (in --         )
    - core/DataUtility.lua:476 (in --     )
    - core/DataUtility.lua:484
    - core/DataUtility.lua:494
    - core/DataUtility.lua:504
    - core/DataUtility.lua:510
    - core/DataUtility.lua:516
    - core/DataUtility.lua:523
    - core/DataUtility.lua:525
    - core/DataUtility.lua:528
    - core/DataUtility.lua:534 (in --         )
    - core/DataUtility.lua:556
    - core/DataUtility.lua:560
    - core/DataUtility.lua:569
    - core/DataUtility.lua:588
    - core/DataUtility.lua:591
    - core/DataUtility.lua:616
    - core/DataUtility.lua:634
    - core/DataUtility.lua:655
    - core/DataUtility.lua:668
    - core/DataUtility.lua:672
    - core/DataUtility.lua:685
    - core/DataUtility.lua:690
    - core/DataUtility.lua:703
    - core/DataUtility.lua:730
    - core/DataUtility.lua:733
    - core/DataUtility.lua:741
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
    - ui/OSD.lua:191
    - ui/OSD.lua:194
    - ui/OSD.lua:211
    - ui/OSD.lua:217
    - ui/OSD.lua:221
    - ui/OSD.lua:233
    - ui/OSD.lua:239
    - ui/OSD.lua:244
    - ui/OSD.lua:246
    - ui/OSD.lua:248
    - ui/OSD.lua:255
    - ui/OSD.lua:279
    - ui/OSD.lua:311
    - ui/OSD.lua:317
    - ui/OSD.lua:337
    - ui/OSD.lua:377
    - ui/OSD.lua:390
    - ui/OSD.lua:394
    - ui/OSD.lua:788
    - ui/OSD.lua:818
    - ui/OSD.lua:825
    - ui/OSD.lua:844
    - ui/OSD.lua:862
    - ui/OSD.lua:887
    - ui/OSD.lua:900
    - ui/OSD.lua:905
    - ui/OSD.lua:918
    - ui/OSD.lua:923
    - ui/OSD.lua:931
    - ui/OSD.lua:935
    - ui/OSD.lua:984
    - ui/OSD.lua:989
    - ui/OSD.lua:1024
    - ui/OSD.lua:1030
    - ui/OSD.lua:1086
    - ui/OSD.lua:1089
    - ui/OSD.lua:1290
    - ui/OSD.lua:1296
    - ui/OSD.lua:1301
    - ui/OSD.lua:1312
    - ui/OSD.lua:1346
    - ui/OSD.lua:1353
    - ui/OSD.lua:1360
    - ui/OSD.lua:1376
    - ui/OSD.lua:1383
    - ui/OSD.lua:1390
    - ui/OSD.lua:1410
    - ui/OSD.lua:1412
    - ui/OSD.lua:1437
    - ui/OSD.lua:1524
    - ui/Options.lua:67
    - ui/Options.lua:381
    - ui/Options.lua:563
    - ui/Options.lua:577
    - ui/Options.lua:592
    - ui/Options.lua:598
    - ui/Options.lua:603
    - ui/Options.lua:671
    - ui/Options.lua:702
    - ui/Options.lua:728
    - ui/Options.lua:799
    - ui/Options.lua:803
    - ui/Options.lua:816
    - ui/Options.lua:835
    - ui/Options.lua:840
    - ui/Options.lua:846
    - ui/Options.lua:853
    - ui/Options.lua:856
    - ui/Options.lua:870
    - ui/Options.lua:875
    - ui/Options.lua:891
    - ui/Options.lua:907
    - ui/Options.lua:932
    - ui/Options.lua:936
    - ui/Options.lua:941
    - ui/Options.lua:946
    - ui/Options.lua:955
    - ui/Options.lua:963
    - ui/Options.lua:965
    - ui/Options.lua:968
    - ui/Options.lua:976
    - ui/Options.lua:982
    - ui/Options.lua:984
    - ui/Options.lua:987
    - ui/Options.lua:992
    - ui/Options.lua:998
    - ui/Options.lua:1000
    - ui/Options.lua:1003
    - ui/Options.lua:1008
    - ui/Options.lua:1021
    - ui/Options.lua:1031
    - ui/Options.lua:1037
    - ui/Options.lua:1044
    - ui/Options.lua:1055
    - ui/Options.lua:1065
    - ui/Options.lua:1071
    - ui/Options.lua:1076
    - ui/Options.lua:1081
    - ui/Options.lua:1107
    - ui/Options.lua:1125
    - ui/Options.lua:1128
    - ui/Options.lua:1133
    - ui/Options.lua:1136
    - ui/Options.lua:1146
    - ui/Options.lua:1150
    - ui/Options.lua:1171
    - ui/Options.lua:1177
    - ui/Options.lua:1185
    - ui/Options.lua:1193
    - ui/Options.lua:1201
    - ui/Options.lua:1205
    - ui/Options.lua:1221
    - ui/Options.lua:1227
    - ui/Options.lua:1235
    - ui/Options.lua:1241
    - ui/Options.lua:1246
    - ui/Options.lua:1249
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
    - features/AutoNavigate.lua:493
    - features/AutoNavigate.lua:500
    - features/AutoNavigate.lua:511
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
    - sync/SyncHandlers.lua:213
    - sync/SyncHandlers.lua:223
    - sync/SyncHandlers.lua:227
    - sync/SyncHandlers.lua:255
    - sync/SyncHandlers.lua:271
    - sync/SyncHandlers.lua:281
    - sync/SyncHandlers.lua:286
    - sync/SyncHandlers.lua:303
    - sync/SyncHandlers.lua:319
    - sync/SyncHandlers.lua:328
    - sync/SyncHandlers.lua:333
    - sync/SyncHandlers.lua:343
    - sync/SyncHandlers.lua:346
    - sync/SyncHandlers.lua:356
    - sync/SyncHandlers.lua:367
    - sync/SyncHandlers.lua:374
    - sync/SyncHandlers.lua:380
    - sync/SyncHandlers.lua:388
    - sync/SyncHandlers.lua:400
    - sync/SyncHandlers.lua:418
    - sync/SyncHandlers.lua:436
    - sync/SyncHandlers.lua:441
    - sync/SyncHandlers.lua:446
    - sync/SyncHandlers.lua:456
    - sync/SyncHandlers.lua:464
    - sync/SyncHandlers.lua:478
    - sync/SyncHandlers.lua:482
    - sync/SyncHandlers.lua:489
    - sync/SyncHandlers.lua:506
    - sync/SyncHandlers.lua:515
    - sync/SyncHandlers.lua:543
    - sync/SyncHandlers.lua:550
    - sync/SyncHandlers.lua:560
    - sync/SyncHandlers.lua:563
    - sync/SyncHandlers.lua:565
    - sync/SyncHandlers.lua:568
    - sync/SyncHandlers.lua:576
    - sync/SyncHandlers.lua:579
    - sync/SyncHandlers.lua:581
    - sync/SyncHandlers.lua:585
    - sync/SyncHandlers.lua:596
    - sync/SyncHandlers.lua:604
    - sync/SyncHandlers.lua:611
    - sync/SyncHandlers.lua:613
    - sync/SyncHandlers.lua:618
    - sync/SyncHandlers.lua:627
    - sync/SyncHandlers.lua:630
    - sync/SyncHandlers.lua:636
    - sync/SyncHandlers.lua:643
    - sync/SyncHandlers.lua:645
    - sync/SyncHandlers.lua:653
    - sync/SyncHandlers.lua:655
    - sync/SyncHandlers.lua:661
    - sync/SyncHandlers.lua:678
    - sync/SyncHandlers.lua:681
    - sync/SyncHandlers.lua:684
    - sync/SyncHandlers.lua:692
    - sync/SyncHandlers.lua:702
    - sync/SyncHandlers.lua:709
    - sync/SyncHandlers.lua:713
    - sync/SyncHandlers.lua:722
    - sync/SyncHandlers.lua:725
    - sync/SyncHandlers.lua:727
    - sync/SyncHandlers.lua:739
    - sync/SyncHandlers.lua:752
    - sync/SyncHandlers.lua:756
    - sync/SyncHandlers.lua:762
    - sync/SyncHandlers.lua:771
    - sync/SyncHandlers.lua:790
    - sync/SyncHandlers.lua:800
    - sync/SyncHandlers.lua:816
    - sync/SyncHandlers.lua:824
    - sync/SyncHandlers.lua:828
    - sync/SyncHandlers.lua:851
    - sync/SyncHandlers.lua:861
    - sync/SyncHandlers.lua:863
    - sync/SyncHandlers.lua:870
    - sync/SyncHandlers.lua:874
    - sync/SyncHandlers.lua:881
    - sync/SyncHandlers.lua:890
    - sync/SyncHandlers.lua:898
    - sync/SyncHandlers.lua:929
    - sync/SyncHandlers.lua:936
    - sync/SyncHandlers.lua:947
    - sync/SyncHandlers.lua:952
    - sync/SyncHandlers.lua:960
    - sync/SyncHandlers.lua:972
    - sync/SyncHandlers.lua:976
    - sync/SyncHandlers.lua:985
    - sync/SyncHandlers.lua:1006
    - sync/SyncHandlers.lua:1020
    - sync/SyncHandlers.lua:1032
    - sync/SyncHandlers.lua:1039
    - sync/SyncHandlers.lua:1041
    - sync/SyncHandlers.lua:1048
    - sync/SyncHandlers.lua:1054
    - sync/SyncHandlers.lua:1071
    - sync/SyncHandlers.lua:1091
    - sync/SyncHandlers.lua:1103
    - sync/SyncHandlers.lua:1116
    - sync/SyncHandlers.lua:1132
    - sync/SyncHandlers.lua:1138
    - sync/SyncHandlers.lua:1163
    - sync/SyncHandlers.lua:1174
    - sync/SyncHandlers.lua:1181
    - sync/SyncHandlers.lua:1187
    - sync/SyncHandlers.lua:1198
    - sync/SyncHandlers.lua:1218
    - sync/SyncHandlers.lua:1225
    - sync/SyncHandlers.lua:1233
    - sync/SyncHandlers.lua:1235
    - sync/SyncHandlers.lua:1240
    - sync/SyncHandlers.lua:1250
    - sync/SyncHandlers.lua:1255
    - sync/SyncHandlers.lua:1261
    - sync/SyncHandlers.lua:1266
    - sync/SyncHandlers.lua:1287
    - sync/SyncHandlers.lua:1292
    - sync/SyncHandlers.lua:1300
    - sync/ChunkManager.lua:16
    - sync/ChunkManager.lua:23
    - sync/ChunkManager.lua:29
    - sync/ChunkManager.lua:38
    - sync/ChunkManager.lua:46
    - sync/ChunkManager.lua:66
    - sync/ChunkManager.lua:76
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
    - sync/Sync.lua:505
    - sync/Sync.lua:514
    - sync/Sync.lua:520
    - sync/Sync.lua:533
    - sync/Sync.lua:542
    - sync/Sync.lua:548
    - sync/Sync.lua:560
    - sync/Sync.lua:571
    - sync/Sync.lua:585
    - sync/Sync.lua:589
    - sync/Sync.lua:592
    - sync/Sync.lua:610
    - sync/Sync.lua:624
    - sync/Sync.lua:633
    - sync/Sync.lua:634
    - sync/Sync.lua:638
    - sync/Sync.lua:648
    - sync/Sync.lua:654
    - sync/Sync.lua:662
    - sync/Sync.lua:666
    - sync/Sync.lua:674
    - sync/Sync.lua:678
    - sync/Sync.lua:685
    - sync/Sync.lua:687
    - sync/Sync.lua:693
    - sync/Sync.lua:707
    - sync/Sync.lua:711
    - sync/Sync.lua:724
    - sync/Sync.lua:737
    - sync/Sync.lua:743
    - sync/Sync.lua:748
    - sync/Sync.lua:754
    - sync/Sync.lua:760
    - sync/Sync.lua:764
    - sync/Sync.lua:783
    - sync/Sync.lua:791
    - sync/Sync.lua:796
    - sync/Sync.lua:809
    - sync/Sync.lua:815
    - sync/Sync.lua:820
    - sync/Sync.lua:826
    - sync/Sync.lua:832
    - sync/Sync.lua:836
    - sync/Sync.lua:842
    - sync/Sync.lua:860
    - sync/Sync.lua:878
    - sync/Sync.lua:882
    - sync/Sync.lua:893
    - sync/Sync.lua:932
    - sync/Sync.lua:956
    - sync/Sync.lua:974
    - sync/Sync.lua:982
    - sync/Sync.lua:991
    - sync/Sync.lua:996
    - sync/Sync.lua:1001
    - sync/Sync.lua:1008
    - sync/Sync.lua:1010
    - sync/Sync.lua:1023
    - sync/Sync.lua:1031
    - sync/Sync.lua:1081
    - sync/Sync.lua:1086
    - sync/Sync.lua:1097
    - sync/Sync.lua:1102
    - sync/Sync.lua:1118
    - sync/Sync.lua:1137

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
    - TWRA.lua:858

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
    - TWRA.lua:863

- `TWRA:ListDebugCategories()` - Line 442
  - Referenced in:
    - core/Debug.lua:755
    - TWRA.lua:855
    - TWRA.lua:866

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

### 2.8 core/Events.lua

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
    - sync/Sync.lua:644

- `TWRA:TriggerEvent()` - Line 40
  - Referenced in:
    - core/Utils.lua:216 (in if )
    - core/Utils.lua:217
    - TWRA.lua:127 (in local listenersCount = )
    - TWRA.lua:131
    - core/DataUtility.lua:480
    - ui/Frame.lua:903 (in if )
    - ui/Frame.lua:904

### 2.9 core/ItemLink.lua

- `TWRA:Items:GetLinkByName()` - Line 5
  - Referenced in:

- `TWRA:Items:ProcessText()` - Line 21
  - Referenced in:
    - TWRA.lua:745 (in processedText = )
    - ui/Frame.lua:1101 (in processedText = )
    - ui/Frame.lua:1162 (in announcementText = )
    - ui/OSD.lua:1088 (in processedText = )
    - ui/OSD.lua:1142 (in announcementText = )
    - ui/OSD.lua:1197 (in processedText = )
    - ui/OSD.lua:1247 (in announcementText = )

- `TWRA:Items:ProcessConsumables()` - Line 61
  - Referenced in:
    - TWRA.lua:749 (in processedText = )

- `TWRA:Items:EnhancedProcessText()` - Line 96
  - Referenced in:
    - ui/Frame.lua:1159 (in announcementText = )
    - ui/OSD.lua:1085 (in processedText = )
    - ui/OSD.lua:1140 (in announcementText = )
    - ui/OSD.lua:1195 (in processedText = )
    - ui/OSD.lua:1245 (in announcementText = )

### 2.10 core/Utils.lua

- `TWRA:ScheduleTimer()` - Line 4
  - Referenced in:
    - core/Debug.lua:653 (in if )
    - core/Debug.lua:654
    - core/Base64.lua:471
    - core/Base64.lua:817
    - TWRA.lua:770
    - core/Core.lua:784
    - core/DataProcessing.lua:1135
    - core/DataProcessing.lua:1139
    - ui/Frame.lua:1192
    - ui/Minimap.lua:158
    - ui/OSD.lua:230 (in TWRA.OSD.autoHideTimer = )
    - ui/OSD.lua:1162
    - ui/OSD.lua:1255
    - ui/OSD.lua:1406 (in self.OSD.autoHideTimer = )
    - ui/Options.lua:1218
    - ui/Options.lua:1232
    - ui/Options.lua:1238
    - features/AutoNavigate.lua:114
    - features/AutoNavigate.lua:129
    - features/AutoNavigate.lua:141
    - sync/SyncHandlers.lua:649
    - sync/SyncHandlers.lua:815 (in self.SYNC.missingSectionsTimeout = )
    - sync/SyncHandlers.lua:939
    - sync/SyncHandlers.lua:1083
    - sync/SyncHandlers.lua:1215 (in timer = )
    - sync/SyncHandlers.lua:1239
    - sync/SyncHandlers.lua:1248
    - sync/SyncHandlers.lua:1291
    - sync/ChunkManager.lua:59
    - sync/Sync.lua:40
    - sync/Sync.lua:55
    - sync/Sync.lua:313 (in self.SYNC.bulkSyncRequestTimeout = )
    - sync/Sync.lua:489
    - sync/Sync.lua:582
    - sync/Sync.lua:1021
    - sync/Sync.lua:1130

- `TWRA:CancelTimer()` - Line 35
  - Referenced in:
    - ui/OSD.lua:205
    - ui/OSD.lua:1369
    - ui/OSD.lua:1399
    - ui/OSD.lua:1424
    - ui/Options.lua:925
    - sync/SyncHandlers.lua:696
    - sync/SyncHandlers.lua:807
    - sync/SyncHandlers.lua:964
    - sync/SyncHandlers.lua:1202
    - sync/SyncHandlers.lua:1272
    - sync/SyncHandlers.lua:1304
    - sync/Sync.lua:310

- `TWRA:SplitString()` - Line 41
  - Referenced in:

- `TWRA:ConvertOptionValues()` - Line 69
  - Referenced in:
    - ui/Frame.lua:1211

- `TWRA:UpdatePlayerTable()` - Line 104
  - Referenced in:
    - TWRA.lua:953
    - core/Core.lua:63 (in return )
    - core/Core.lua:307 (in if )
    - core/Core.lua:309
    - core/Core.lua:809 (in if )
    - core/Core.lua:810

- `TWRA:GetTableSize()` - Line 249
  - Referenced in:
    - core/Utils.lua:244
    - core/Core.lua:312 (in local playerCount = )
    - features/AutoNavigate.lua:469
    - sync/SyncHandlers.lua:27

## 3. Feature Files

### 3.1 features/AutoNavigate.lua

- `TWRA:CheckSuperWoWSupport()` - Line 13
  - Referenced in:
    - features/AutoNavigate.lua:48 (in if not )
    - features/AutoNavigate.lua:159 (in local hasSupport = )
    - features/AutoNavigate.lua:492 (in if not )

- `TWRA:CheckSkullMarkedMob()` - Line 36
  - Referenced in:
    - TWRA.lua:296 (in if )
    - TWRA.lua:298

- `TWRA:RegisterAutoNavigateEvents()` - Line 102
  - Referenced in:
    - features/AutoNavigate.lua:526

- `TWRA:InitializeAutoNavigate()` - Line 150
  - Referenced in:
    - TWRA.lua:303 (in if )
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
    - TWRA.lua:890 (in if )
    - TWRA.lua:891
    - core/Core.lua:383 (in if )
    - core/Core.lua:384

- `TWRA:GetCurrentTargetGuid()` - Line 490
  - Referenced in:
    - TWRA.lua:883 (in if )
    - TWRA.lua:884
    - core/Core.lua:375 (in if )
    - core/Core.lua:376

### 3.2 features/AutoTanks.lua

- `TWRA:InitializeTankSync()` - Line 2
  - Referenced in:
    - ui/Options.lua:580 (in if isChecked and )
    - ui/Options.lua:581
    - sync/Sync.lua:466 (in if self.SYNC.tankSync and )
    - sync/Sync.lua:468

- `TWRA:IsORA2Available()` - Line 29
  - Referenced in:
    - ui/Options.lua:981 (in if )
    - features/AutoTanks.lua:20 (in if )
    - features/AutoTanks.lua:52 (in if not )

- `TWRA:UpdateTanks()` - Line 33
  - Referenced in:
    - ui/Frame.lua:146
    - features/AutoTanks.lua:15
    - features/AutoTanks.lua:22

## 4. Sync Files

### 4.1 sync/ChunkManager.lua

- `TWRA:chunkManager:Initialize()` - Line 6
  - Referenced in:

- `TWRA:chunkManager:SendChunkedMessage()` - Line 21
  - Referenced in:
    - sync/Sync.lua:517
    - sync/Sync.lua:545
    - sync/Sync.lua:746 (in return )
    - sync/Sync.lua:818 (in return )
    - sync/Sync.lua:951 (in success = )
    - sync/Sync.lua:994 (in local success = )

### 4.2 sync/Sync.lua

- `TWRA:RegisterSyncEvents()` - Line 28
  - Referenced in:

- `TWRA:CheckAndActivateLiveSync()` - Line 77
  - Referenced in:

- `TWRA:ActivateLiveSync()` - Line 90
  - Referenced in:
    - ui/Options.lua:961 (in if )
    - ui/Options.lua:962
    - sync/Sync.lua:83
    - sync/Sync.lua:463

- `TWRA:DeactivateLiveSync()` - Line 126
  - Referenced in:
    - ui/Options.lua:970
    - ui/Options.lua:971

- `TWRA:SendAddonMessage()` - Line 147
  - Referenced in:
    - sync/SyncHandlers.lua:858 (in local success = )
    - sync/SyncHandlers.lua:935
    - sync/SyncHandlers.lua:1197
    - sync/ChunkManager.lua:45
    - sync/ChunkManager.lua:72
    - sync/Sync.lua:263
    - sync/Sync.lua:305 (in local success = )
    - sync/Sync.lua:351 (in return )
    - sync/Sync.lua:525 (in return )
    - sync/Sync.lua:553 (in return )
    - sync/Sync.lua:627
    - sync/Sync.lua:961 (in success = )
    - sync/Sync.lua:1006 (in local success = )
    - sync/Sync.lua:1132

- `TWRA:CreateSectionMessage()` - Line 172
  - Referenced in:
    - sync/Sync.lua:350 (in local message = )

- `TWRA:CreateBulkSectionMessage()` - Line 176
  - Referenced in:
    - sync/Sync.lua:903 (in local message = )

- `TWRA:CreateBulkStructureMessage()` - Line 180
  - Referenced in:
    - sync/Sync.lua:987 (in local structureMessage = )

- `TWRA:CreateVersionMessage()` - Line 184
  - Referenced in:

- `TWRA:CreateMissingSectionsRequestMessage()` - Line 188
  - Referenced in:
    - sync/SyncHandlers.lua:795 (in local message = )
    - sync/SyncHandlers.lua:857 (in local message = )

- `TWRA:CreateMissingSectionsAckMessage()` - Line 193
  - Referenced in:
    - sync/SyncHandlers.lua:934 (in local ackMessage = )

- `TWRA:CreateMissingSectionResponseMessage()` - Line 197
  - Referenced in:
    - sync/SyncHandlers.lua:1085 (in local message = )

- `TWRA:CreateBulkSyncRequestMessage()` - Line 201
  - Referenced in:
    - sync/Sync.lua:302 (in local message = )

- `TWRA:CreateBulkSyncAckMessage()` - Line 206
  - Referenced in:
    - sync/SyncHandlers.lua:1196 (in local ackMessage = )

- `TWRA:CompareTimestamps()` - Line 215
  - Referenced in:
    - sync/SyncHandlers.lua:162 (in local comparisonResult = )
    - sync/SyncHandlers.lua:502 (in local timestampDiff = )

- `TWRA:RequestStructureSync()` - Line 232
  - Referenced in:

- `TWRA:RequestBulkSync()` - Line 272
  - Referenced in:
    - TWRA.lua:74 (in if )
    - TWRA.lua:76
    - core/Core.lua:791 (in if )
    - core/Core.lua:792

- `TWRA:BroadcastSectionChange()` - Line 330
  - Referenced in:
    - sync/Sync.lua:681 (in local success = )

- `TWRA:OnChatMsgAddon()` - Line 354
  - Referenced in:
    - TWRA.lua:415 (in function )
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
    - TWRA.lua:315 (in if )
    - TWRA.lua:317
    - sync/Sync.lua:42
    - sync/Sync.lua:58

- `TWRA:CHAT_MSG_ADDON()` - Line 497
  - Referenced in:

- `TWRA:SendStructureResponse()` - Line 501
  - Referenced in:

- `TWRA:SendSectionResponse()` - Line 529
  - Referenced in:
    - sync/Sync.lua:588 (in if )
    - sync/Sync.lua:590

- `TWRA:QueueSectionResponse()` - Line 557
  - Referenced in:

- `TWRA:AnnounceDataImport()` - Line 607
  - Referenced in:

- `TWRA:RegisterSectionChangeHandler()` - Line 632
  - Referenced in:
    - sync/Sync.lua:74
    - sync/Sync.lua:435 (in if )
    - sync/Sync.lua:437
    - sync/Sync.lua:442
    - sync/Sync.lua:492

- `TWRA:GetCompressedStructure()` - Line 697
  - Referenced in:
    - sync/Sync.lua:503 (in local structureData = )
    - sync/Sync.lua:722 (in local structureData = )
    - sync/Sync.lua:980 (in local structureData = )
    - sync/Sync.lua:1084 (in local structureData = )

- `TWRA:SendStructureData()` - Line 706
  - Referenced in:

- `TWRA:SendSectionData()` - Line 759
  - Referenced in:

- `TWRA:SendAllSections()` - Line 831
  - Referenced in:
    - core/Base64.lua:468 (in if )
    - core/Base64.lua:472
    - core/Base64.lua:814 (in if )
    - core/Base64.lua:818
    - ui/Frame.lua:98
    - ui/Options.lua:1229 (in if )
    - ui/Options.lua:1243
    - sync/SyncHandlers.lua:1226 (in local success = )

- `TWRA:SerializeData()` - Line 1037
  - Referenced in:

- `TWRA:DeserializeData()` - Line 1059
  - Referenced in:

- `TWRA:SendStructureDataInChunks()` - Line 1080
  - Referenced in:

- `TWRA:SendSectionDataInChunks()` - Line 1096
  - Referenced in:

- `TWRA:SendDataInChunks()` - Line 1112
  - Referenced in:
    - sync/Sync.lua:1091
    - sync/Sync.lua:1107

### 4.3 sync/SyncHandlers.lua

- `TWRA:InitializeHandlerMap()` - Line 12
  - Referenced in:

- `TWRA:HandleAddonMessage()` - Line 30
  - Referenced in:
    - TWRA.lua:425 (in if )
    - TWRA.lua:426
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

- `TWRA:HandleBulkStructureCommand()` - Line 477
  - Referenced in:
    - sync/SyncHandlers.lua:67 (in if )
    - sync/SyncHandlers.lua:68

- `TWRA:HandleStructureResponseCommand()` - Line 691
  - Referenced in:
    - sync/Sync.lua:421

- `TWRA:RequestMissingSectionsWhisper()` - Line 751
  - Referenced in:
    - sync/SyncHandlers.lua:685

- `TWRA:RequestMissingSectionsGroup()` - Line 823
  - Referenced in:
    - sync/SyncHandlers.lua:817

- `TWRA:HandleMissingSectionsRequestCommand()` - Line 869
  - Referenced in:
    - sync/SyncHandlers.lua:77 (in if )
    - sync/SyncHandlers.lua:78

- `TWRA:HandleMissingSectionsAckCommand()` - Line 946
  - Referenced in:
    - sync/SyncHandlers.lua:82 (in if )
    - sync/SyncHandlers.lua:83

- `TWRA:HandleMissingSectionResponseCommand()` - Line 971
  - Referenced in:
    - sync/SyncHandlers.lua:87 (in if )
    - sync/SyncHandlers.lua:88

- `TWRA:SendMissingSections()` - Line 1047
  - Referenced in:
    - sync/SyncHandlers.lua:891 (in return )
    - sync/SyncHandlers.lua:940

- `TWRA:HandleBulkSyncRequestCommand()` - Line 1102
  - Referenced in:
    - sync/SyncHandlers.lua:92 (in if )
    - sync/SyncHandlers.lua:93

- `TWRA:HandleBulkSyncAckCommand()` - Line 1260
  - Referenced in:
    - sync/SyncHandlers.lua:97 (in if )
    - sync/SyncHandlers.lua:98

## 5. Duplicate Functions

- `TWRA:DecompressAssignmentsData()` is defined in multiple locations:
  - core/Base64.lua:131
  - core/Compression.lua:651

- `TWRA:OnGroupChanged()` is defined in multiple locations:
  - TWRA.lua:948
  - core/Core.lua:769

- `TWRA:IsExampleData()` is defined in multiple locations:
  - Example.lua:524
  - TWRA.lua:495
  - ui/Frame.lua:5

- `TWRA:OnChatMsgAddon()` is defined in multiple locations:
  - TWRA.lua:415
  - sync/Sync.lua:354

