# TWRA Function Map

This document maps all functions in the TWRA addon, showing where they are defined and where they are referenced throughout the codebase.

## 1. Sync Files

### 1.1 sync/ChunkManager.lua

- `TWRA:chunkManager:Initialize()` - Line 6
  - Referenced in:
    - sync/SyncHandlers.lua:296
    - sync/Sync.lua:954

- `TWRA:chunkManager:ChunkContent()` - Line 29
  - Referenced in:
    - sync/Sync.lua:967 (in local transferId = )
    - sync/Sync.lua:983 (in structureTransferId = )

- `TWRA:chunkManager:SendChunkedMessage()` - Line 121
  - Referenced in:
    - sync/Sync.lua:518
    - sync/Sync.lua:546
    - sync/Sync.lua:746 (in return )
    - sync/Sync.lua:818 (in return )

- `TWRA:chunkManager:HandleChunkHeader()` - Line 131
  - Referenced in:
    - sync/SyncHandlers.lua:274
    - sync/Sync.lua:1456 (in local success = )

- `TWRA:chunkManager:HandleChunkData()` - Line 189
  - Referenced in:
    - sync/SyncHandlers.lua:299 (in local isComplete = )
    - sync/Sync.lua:1470 (in local chunkSuccess = )

- `TWRA:chunkManager:ProcessChunks()` - Line 367
  - Referenced in:
    - sync/SyncHandlers.lua:312
    - sync/SyncHandlers.lua:345 (in local success = )

- `TWRA:chunkManager:RetrieveChunkData()` - Line 434
  - Referenced in:
    - sync/SyncHandlers.lua:432 (in local actualData = )
    - sync/SyncHandlers.lua:610 (in local actualData = )

- `TWRA:chunkManager:CleanupOldTransfers()` - Line 553
  - Referenced in:

- `TWRA:chunkManager:RemoveStoredChunkData()` - Line 584
  - Referenced in:

- `TWRA:chunkManager:ListStoredTransfers()` - Line 598
  - Referenced in:

- `TWRA:chunkManager:IsTransferComplete()` - Line 624
  - Referenced in:

- `TWRA:chunkManager:GetTransferProgress()` - Line 635
  - Referenced in:

- `TWRA:chunkManager:CancelTransfer()` - Line 649
  - Referenced in:

### 1.2 sync/Sync.lua

- `TWRA:RegisterSyncEvents()` - Line 28
  - Referenced in:

- `TWRA:CheckAndActivateLiveSync()` - Line 77
  - Referenced in:

- `TWRA:ActivateLiveSync()` - Line 90
  - Referenced in:
    - ui/Options.lua:271 (in if )
    - ui/Options.lua:272
    - sync/Sync.lua:83
    - sync/Sync.lua:465

- `TWRA:DeactivateLiveSync()` - Line 126
  - Referenced in:
    - ui/Options.lua:280
    - ui/Options.lua:281

- `TWRA:SendAddonMessage()` - Line 147
  - Referenced in:
    - sync/SyncHandlers.lua:1069
    - sync/SyncHandlers.lua:1340
    - sync/SyncHandlers.lua:1349
    - sync/Sync.lua:260
    - sync/Sync.lua:302 (in local success = )
    - sync/Sync.lua:348 (in return )
    - sync/Sync.lua:526 (in return )
    - sync/Sync.lua:554 (in return )
    - sync/Sync.lua:628
    - sync/Sync.lua:1019 (in local success = )
    - sync/Sync.lua:1038 (in local success = )
    - sync/Sync.lua:1072 (in local success = )
    - sync/Sync.lua:1085 (in local success = )
    - sync/Sync.lua:1204
    - sync/Sync.lua:1583 (in if )
    - sync/Sync.lua:1584
    - sync/Sync.lua:1585
    - sync/Sync.lua:1614 (in if )
    - sync/Sync.lua:1615
    - sync/Sync.lua:1616

- `TWRA:CreateSectionMessage()` - Line 172
  - Referenced in:
    - sync/Sync.lua:347 (in local message = )

- `TWRA:CreateBulkSectionMessage()` - Line 176
  - Referenced in:

- `TWRA:CreateBulkStructureMessage()` - Line 180
  - Referenced in:

- `TWRA:CreateVersionMessage()` - Line 184
  - Referenced in:
    - sync/SyncHandlers.lua:1339 (in local versionMessage = )
    - sync/SyncHandlers.lua:1348 (in local versionMessage = )
    - sync/SyncHandlers.lua:1353 (in function )

- `TWRA:CreateMissingSectionsRequestMessage()` - Line 188
  - Referenced in:

- `TWRA:CreateBulkSyncRequestMessage()` - Line 193
  - Referenced in:
    - sync/Sync.lua:299 (in local message = )

- `TWRA:CreateBulkSyncAckMessage()` - Line 203
  - Referenced in:
    - sync/SyncHandlers.lua:1068 (in local ackMessage = )

- `TWRA:CompareTimestamps()` - Line 212
  - Referenced in:
    - sync/SyncHandlers.lua:552 (in local timestampDiff = )
    - sync/SyncHandlers.lua:876 (in local comparisonResult = )
    - sync/SyncHandlers.lua:1000 (in local comparison = )

- `TWRA:RequestStructureSync()` - Line 229
  - Referenced in:

- `TWRA:RequestBulkSync()` - Line 269
  - Referenced in:
    - core/Core.lua:783 (in if )
    - core/Core.lua:784
    - sync/SyncHandlers.lua:916 (in if )
    - sync/SyncHandlers.lua:917
    - sync/SyncHandlers.lua:1428 (in if )
    - sync/SyncHandlers.lua:1430

- `TWRA:BroadcastSectionChange()` - Line 327
  - Referenced in:
    - sync/Sync.lua:681 (in local success = )

- `TWRA:OnChatMsgAddon()` - Line 351
  - Referenced in:
    - TWRA.lua:415 (in function )
    - sync/Sync.lua:499

- `TWRA:ToggleMessageMonitoring()` - Line 385
  - Referenced in:
    - core/Debug.lua:819 (in if )
    - core/Debug.lua:820

- `TWRA:ShowSyncStatus()` - Line 396
  - Referenced in:
    - core/Debug.lua:774 (in if )
    - core/Debug.lua:775

- `TWRA:InitializeSync()` - Line 427
  - Referenced in:
    - TWRA.lua:276 (in if )
    - TWRA.lua:278
    - sync/Sync.lua:42
    - sync/Sync.lua:58

- `TWRA:CHAT_MSG_ADDON()` - Line 498
  - Referenced in:

- `TWRA:SendStructureResponse()` - Line 502
  - Referenced in:

- `TWRA:SendSectionResponse()` - Line 530
  - Referenced in:
    - sync/Sync.lua:589 (in if )
    - sync/Sync.lua:591

- `TWRA:QueueSectionResponse()` - Line 558
  - Referenced in:

- `TWRA:AnnounceDataImport()` - Line 608
  - Referenced in:

- `TWRA:RegisterSectionChangeHandler()` - Line 633
  - Referenced in:
    - sync/Sync.lua:74
    - sync/Sync.lua:437 (in if )
    - sync/Sync.lua:439
    - sync/Sync.lua:444
    - sync/Sync.lua:493

- `TWRA:GetCompressedStructure()` - Line 697
  - Referenced in:
    - sync/Sync.lua:504 (in local structureData = )
    - sync/Sync.lua:722 (in local structureData = )
    - sync/Sync.lua:907 (in local structureData = )
    - sync/Sync.lua:1156 (in local structureData = )

- `TWRA:SendStructureData()` - Line 706
  - Referenced in:

- `TWRA:SendSectionData()` - Line 759
  - Referenced in:

- `TWRA:SendAllSections()` - Line 831
  - Referenced in:
    - core/Base64.lua:479 (in if )
    - core/Base64.lua:487
    - ui/Frame.lua:119 (in --     )
    - sync/SyncHandlers.lua:1098 (in local success = )

- `TWRA:SerializeData()` - Line 1109
  - Referenced in:

- `TWRA:DeserializeData()` - Line 1131
  - Referenced in:

- `TWRA:SendStructureDataInChunks()` - Line 1152
  - Referenced in:

- `TWRA:SendSectionDataInChunks()` - Line 1168
  - Referenced in:

- `TWRA:SendDataInChunks()` - Line 1184
  - Referenced in:
    - sync/Sync.lua:1163
    - sync/Sync.lua:1179

- `TWRA:TestChunkedSectionProcessing()` - Line 1219
  - Referenced in:

- `TWRA:TestCrossClientChunkProcessing()` - Line 1338
  - Referenced in:

- `TWRA:TestChunkSync()` - Line 1534
  - Referenced in:
    - sync/Sync.lua:1671

- `TWRA:TestChunkCompletion()` - Line 1647
  - Referenced in:
    - sync/Sync.lua:1631
    - sync/Sync.lua:1642
    - sync/Sync.lua:1744
    - sync/Sync.lua:1747

- `TWRA:EnhanceChunkManagerForTests()` - Line 1723
  - Referenced in:

### 1.3 sync/SyncHandlers.lua

- `TWRA:InitializeHandlerMap()` - Line 13
  - Referenced in:
    - sync/Sync.lua:480 (in if )
    - sync/Sync.lua:481

- `TWRA:HandleAddonMessage()` - Line 32
  - Referenced in:
    - TWRA.lua:425 (in if )
    - TWRA.lua:426
    - core/Core.lua:261
    - sync/Sync.lua:377 (in if )
    - sync/Sync.lua:379

- `TWRA:ExtractDataPortion()` - Line 229
  - Referenced in:
    - sync/SyncHandlers.lua:183
    - sync/SyncHandlers.lua:188

- `TWRA:HandleChunkHeaderCommand()` - Line 257
  - Referenced in:
    - sync/SyncHandlers.lua:97

- `TWRA:HandleChunkDataCommand()` - Line 284
  - Referenced in:
    - sync/SyncHandlers.lua:140

- `TWRA:ProcessCompleteChunkTransfer()` - Line 328
  - Referenced in:

- `TWRA:HandleBulkSectionCommand()` - Line 372
  - Referenced in:
    - sync/SyncHandlers.lua:182 (in if )
    - sync/SyncHandlers.lua:183

- `TWRA:DebugTableKeys()` - Line 506
  - Referenced in:
    - sync/SyncHandlers.lua:437
    - sync/SyncHandlers.lua:615

- `TWRA:HandleBulkStructureCommand()` - Line 527
  - Referenced in:
    - sync/SyncHandlers.lua:187 (in if )
    - sync/SyncHandlers.lua:188

- `TWRA:HandleSectionCommand()` - Line 831
  - Referenced in:
    - sync/SyncHandlers.lua:177 (in if )
    - sync/SyncHandlers.lua:178
    - sync/Sync.lua:415

- `TWRA:HandleBulkSyncRequestCommand()` - Line 937
  - Referenced in:
    - sync/SyncHandlers.lua:155
    - sync/SyncHandlers.lua:158
    - sync/SyncHandlers.lua:207 (in if )
    - sync/SyncHandlers.lua:209

- `TWRA:HandleBulkSyncAckCommand()` - Line 1132
  - Referenced in:
    - sync/SyncHandlers.lua:167
    - sync/SyncHandlers.lua:213 (in if )
    - sync/SyncHandlers.lua:215

- `TWRA:HandleVersionCommand()` - Line 1215
  - Referenced in:
    - sync/SyncHandlers.lua:192 (in if )
    - sync/SyncHandlers.lua:193

- `TWRA:CheckVersionCompatibility()` - Line 1322
  - Referenced in:
    - core/Core.lua:461 (in if )
    - core/Core.lua:462
    - core/Core.lua:777 (in if )
    - core/Core.lua:778

- `TWRA:SendVersionResponse()` - Line 1344
  - Referenced in:
    - sync/SyncHandlers.lua:1281

- `TWRA:CreateVersionMessage()` - Line 1353
  - Referenced in:
    - sync/SyncHandlers.lua:1339 (in local versionMessage = )
    - sync/SyncHandlers.lua:1348 (in local versionMessage = )
    - sync/Sync.lua:184 (in function )

- `TWRA:RequestMissingSections()` - Line 1358
  - Referenced in:
    - sync/SyncHandlers.lua:819

## 2. Core Files

### 2.1 TWRA.lua

- `TWRA:NavigateToSection()` - Line 12
  - Referenced in:
    - core/Compression.lua:770 (in if )
    - core/Compression.lua:771
    - Example.lua:381
    - Example.lua:679
    - Example.lua:698
    - Example.lua:720
    - Example.lua:748
    - TWRA.lua:292
    - core/Core.lua:486
    - core/Core.lua:605
    - core/DataUtility.lua:482 (in if )
    - core/DataUtility.lua:484
    - core/DataUtility.lua:507 (in if self.navigation and )
    - core/DataUtility.lua:509
    - ui/Frame.lua:416
    - ui/Minimap.lua:773
    - features/AutoNavigate.lua:243
    - sync/SyncHandlers.lua:747 (in if )
    - sync/SyncHandlers.lua:750
    - sync/SyncHandlers.lua:787 (in if )
    - sync/SyncHandlers.lua:788
    - sync/SyncHandlers.lua:881

- `TWRA:Initialize()` - Line 106
  - Referenced in:
    - TWRA.lua:885
    - sync/ChunkManager.lua:38
    - sync/ChunkManager.lua:135
    - sync/ChunkManager.lua:193

- `TWRA:LoadSavedAssignments()` - Line 297
  - Referenced in:

- `TWRA:OnChatMsgAddon()` - Line 415
  - Referenced in:
    - sync/Sync.lua:351 (in function )
    - sync/Sync.lua:499

- `TWRA:TruncateString()` - Line 432
  - Referenced in:
    - TWRA.lua:422

- `TWRA:CleanAssignmentData()` - Line 438
  - Referenced in:

- `TWRA:IsExampleData()` - Line 495
  - Referenced in:
    - Example.lua:817 (in function )
    - Example.lua:818 (in self:Debug("error", ")
    - ui/Frame.lua:5 (in function )
    - ui/Frame.lua:6 (in self:Debug("error", " )

- `TWRA:AnnounceAssignments()` - Line 511
  - Referenced in:
    - ui/Frame.lua:164

- `TWRA:SendAnnouncementMessages()` - Line 711
  - Referenced in:
    - TWRA.lua:708

- `TWRA:GetAnnouncementChannels()` - Line 821
  - Referenced in:
    - TWRA.lua:718 (in local channelInfo = )

- `TWRA:ShowOptionsView()` - Line 887
  - Referenced in:
    - core/Core.lua:496
    - ui/Frame.lua:137
    - ui/Minimap.lua:374 (in if )
    - ui/Minimap.lua:375
    - ui/Minimap.lua:381 (in if )
    - ui/Minimap.lua:382

- `TWRA:OnGroupChanged()` - Line 987
  - Referenced in:
    - core/Core.lua:755 (in function )
    - core/Core.lua:808
    - core/Core.lua:813

- `TWRA:DisplayCurrentSection()` - Line 1027
  - Referenced in:
    - TWRA.lua:1012 (in elseif )
    - TWRA.lua:1014
    - core/DataUtility.lua:112 (in function )

- `TWRA:OnUnload()` - Line 1070
  - Referenced in:
    - TWRA.lua:411

### 2.2 core/AbilityLinks.lua

- `TWRA:InitializeAbilityDatabase()` - Line 89
  - Referenced in:
    - core/AbilityLinks.lua:112

### 2.3 core/Base64.lua

- `TWRA:CompressAssignmentsData()` - Line 88
  - Referenced in:
    - core/Base64.lua:731 (in local compressedData = )

- `TWRA:DecompressAssignmentsData()` - Line 132
  - Referenced in:
    - core/Base64.lua:533 (in local decompressedData = )
    - core/Compression.lua:651 (in function )
    - core/Compression.lua:717 (in local decompressedData = )

- `TWRA:PrepareDataForSync()` - Line 180
  - Referenced in:
    - core/Base64.lua:730 (in local syncReadyData = )

- `TWRA:ExpandAbbreviations()` - Line 231
  - Referenced in:
    - core/Base64.lua:713 (in result = )

- `TWRA:DecodeBase64Raw()` - Line 357
  - Referenced in:
    - core/Base64.lua:150 (in compressedString = )
    - core/Compression.lua:287 (in return )
    - core/Compression.lua:292 (in return )
    - core/Compression.lua:296 (in return )
    - core/Compression.lua:430 (in local decodedString = )
    - core/Compression.lua:678 (in local binaryData = )

- `TWRA:HandleImportedData()` - Line 438
  - Referenced in:
    - core/Base64.lua:566
    - core/Base64.lua:769

- `TWRA:DecodeBase64()` - Line 524
  - Referenced in:
    - ui/options/Options-Import.lua:77 (in if )
    - ui/options/Options-Import.lua:94 (in local decodedString = )

- `TWRA:TableToLuaString()` - Line 775
  - Referenced in:
    - core/Base64.lua:787 (in result = result .. )
    - core/Base64.lua:805 (in result = result .. )

- `TWRA:EncodeBase64()` - Line 822
  - Referenced in:
    - core/Base64.lua:126 (in local base64String = )
    - core/Compression.lua:141 (in local encodedData = )
    - core/Compression.lua:159 (in local encodedData = )
    - core/Compression.lua:257 (in compressed = )

### 2.4 core/Compression.lua

- `TWRA:InitializeCompression()` - Line 5
  - Referenced in:
    - core/Compression.lua:82 (in if not )
    - core/Compression.lua:172 (in if not )
    - core/Compression.lua:316 (in if not )
    - core/Compression.lua:438 (in if not )
    - core/Compression.lua:672 (in if not )
    - core/Core.lua:94 (in if )
    - core/Core.lua:95 (in if )
    - core/DataProcessing.lua:450 (in if )
    - core/DataProcessing.lua:451

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
    - sync/SyncHandlers.lua:671 (in return )
    - sync/SyncHandlers.lua:1373 (in return )

- `TWRA:DecompressSectionData()` - Line 405
  - Referenced in:
    - core/DataProcessing.lua:647 (in if )
    - core/DataProcessing.lua:648 (in return )
    - sync/Sync.lua:1300
    - sync/Sync.lua:1323
    - sync/Sync.lua:1496
    - sync/Sync.lua:1519

- `TWRA:FillMissingIndices()` - Line 486
  - Referenced in:
    - core/Compression.lua:483 (in return )
    - core/Compression.lua:495 (in inputTable[key] = )

- `TWRA:StoreSegmentedData()` - Line 592
  - Referenced in:
    - core/Compression.lua:746
    - TWRA.lua:354 (in elseif )
    - TWRA.lua:355
    - core/DataProcessing.lua:455 (in if )
    - core/DataProcessing.lua:457 (in return )
    - core/DataUtility.lua:439 (in if )
    - core/DataUtility.lua:440
    - ui/options/Options-Import.lua:297 (in elseif )
    - ui/options/Options-Import.lua:299

- `TWRA:DecompressAssignmentsData()` - Line 651
  - Referenced in:
    - core/Base64.lua:132 (in function )
    - core/Base64.lua:533 (in local decompressedData = )
    - core/Compression.lua:717 (in local decompressedData = )

- `TWRA:ProcessCompressedData()` - Line 708
  - Referenced in:

### 2.5 core/Core.lua

- `TWRA:OnLoad()` - Line 4
  - Referenced in:
    - core/Core.lua:332 (in frame:SetScript("OnLoad", function() )
    - features/AutoNavigate.lua:107
    - sync/Sync.lua:33

- `TWRA:OnEvent()` - Line 203
  - Referenced in:
    - core/Core.lua:329
    - features/AutoNavigate.lua:123
    - sync/Sync.lua:49

- `TWRA:ToggleMainFrame()` - Line 522
  - Referenced in:
    - Bindings.xml:4 (in if TWRA and )
    - Bindings.xml:8 (in if TWRA and )
    - Example.lua:707
    - core/Core.lua:501

- `TWRA:NavigateHandler()` - Line 582
  - Referenced in:
    - Bindings.xml:16 (in if TWRA and )
    - Bindings.xml:20 (in if TWRA and )
    - core/Core.lua:477
    - core/Core.lua:481
    - ui/Frame.lua:195
    - ui/Frame.lua:207
    - ui/Minimap.lua:432 (in if )
    - ui/Minimap.lua:433
    - ui/Minimap.lua:444 (in if )
    - ui/Minimap.lua:445

- `TWRA:RebuildNavigation()` - Line 608
  - Referenced in:
    - core/Base64.lua:458 (in if )
    - core/Base64.lua:460
    - core/Base64.lua:509 (in if )
    - core/Base64.lua:511
    - core/Compression.lua:750 (in if )
    - core/Compression.lua:751
    - Example.lua:305 (in if )
    - Example.lua:307
    - Example.lua:588 (in if )
    - Example.lua:590
    - TWRA.lua:316 (in if )
    - TWRA.lua:317
    - TWRA.lua:397 (in if )
    - TWRA.lua:398
    - core/Core.lua:215
    - core/Core.lua:732 (in return )
    - core/DataUtility.lua:474 (in if )
    - core/DataUtility.lua:476
    - ui/Frame.lua:528
    - ui/options/Options-Import.lua:248 (in if )
    - ui/options/Options-Import.lua:250
    - sync/SyncHandlers.lua:709 (in if )
    - sync/SyncHandlers.lua:710

- `TWRA:SaveCurrentSection()` - Line 671
  - Referenced in:
    - Example.lua:410

- `TWRA:EnsureUIUtils()` - Line 694
  - Referenced in:
    - core/Core.lua:703

- `TWRA:ResetUI()` - Line 705
  - Referenced in:
    - core/Core.lua:218

- `TWRA:BuildNavigationFromNewFormat()` - Line 729
  - Referenced in:

- `TWRA:RegisterAddonMessaging()` - Line 735
  - Referenced in:
    - core/Core.lua:157

- `TWRA:OnGroupChanged()` - Line 755
  - Referenced in:
    - TWRA.lua:987 (in function )
    - core/Core.lua:808
    - core/Core.lua:813

- `TWRA:OnRaidRosterUpdate()` - Line 806
  - Referenced in:
    - core/Core.lua:270 (in if )
    - core/Core.lua:271

- `TWRA:OnPartyMembersChanged()` - Line 811
  - Referenced in:
    - core/Core.lua:275 (in if )
    - core/Core.lua:276

- `TWRA:InitializeLinkHooks()` - Line 816
  - Referenced in:

- `TWRA:HexToRGB()` - Line 825
  - Referenced in:

### 2.6 core/DataProcessing.lua

- `TWRA:EnsureCompleteRows()` - Line 3
  - Referenced in:
    - core/Base64.lua:716 (in result = )
    - core/DataUtility.lua:392 (in if )
    - core/DataUtility.lua:393 (in data = )

- `TWRA:ProcessPlayerInfo()` - Line 100
  - Referenced in:
    - core/Base64.lua:556 (in if )
    - core/Base64.lua:557
    - core/Compression.lua:760 (in elseif )
    - core/Compression.lua:761
    - Example.lua:396 (in if )
    - Example.lua:398
    - Example.lua:602 (in if )
    - Example.lua:604
    - core/DataProcessing.lua:825 (in if )
    - core/DataProcessing.lua:829
    - core/DataProcessing.lua:833
    - core/DataUtility.lua:459 (in if )
    - core/DataUtility.lua:461
    - ui/options/Options-Import.lua:316 (in if )
    - ui/options/Options-Import.lua:319 (in pcall(function() )

- `TWRA:ProcessStaticPlayerInfo()` - Line 117
  - Referenced in:
    - core/DataProcessing.lua:108

- `TWRA:ProcessStaticPlayerInfoForSection()` - Line 170
  - Referenced in:
    - core/DataProcessing.lua:153
    - core/DataProcessing.lua:160

- `TWRA:ProcessDynamicPlayerInfo()` - Line 236
  - Referenced in:
    - core/DataProcessing.lua:111
    - core/DataProcessing.lua:415
    - core/DataProcessing.lua:1121

- `TWRA:ProcessDynamicPlayerInfoForSection()` - Line 284
  - Referenced in:
    - core/DataProcessing.lua:267
    - core/DataProcessing.lua:274

- `TWRA:UpdateOSDWithPlayerInfo()` - Line 376
  - Referenced in:
    - TWRA.lua:1022

- `TWRA:RefreshPlayerInfo()` - Line 406
  - Referenced in:
    - core/Base64.lua:515 (in if )
    - core/Base64.lua:516
    - core/Compression.lua:758 (in if )
    - core/Compression.lua:759
    - TWRA.lua:999
    - core/Core.lua:757

- `TWRA:StoreCompressedData()` - Line 441
  - Referenced in:
    - core/Base64.lua:549
    - core/Base64.lua:733
    - TWRA.lua:352 (in if )
    - TWRA.lua:353
    - ui/options/Options-Import.lua:294 (in if )
    - ui/options/Options-Import.lua:296

- `TWRA:ClearDataForStructureResponse()` - Line 477
  - Referenced in:

- `TWRA:BuildSkeletonFromStructure()` - Line 506
  - Referenced in:
    - sync/SyncHandlers.lua:691 (in if )
    - sync/SyncHandlers.lua:693 (in hasBuiltSkeleton = )

- `TWRA:ProcessSectionData()` - Line 567
  - Referenced in:
    - sync/SyncHandlers.lua:744
    - sync/ChunkManager.lua:329 (in if )
    - sync/ChunkManager.lua:333
    - sync/Sync.lua:1259 (in if )
    - sync/Sync.lua:1260
    - sync/Sync.lua:1309 (in if )
    - sync/Sync.lua:1310
    - sync/Sync.lua:1439 (in if )
    - sync/Sync.lua:1440
    - sync/Sync.lua:1505 (in if )
    - sync/Sync.lua:1506

- `TWRA:GenerateOSDInfoForSection()` - Line 864
  - Referenced in:
    - core/DataProcessing.lua:230 (in playerInfo["OSD Assignments"] = )
    - core/DataProcessing.lua:371 (in playerInfo["OSD Group Assignments"] = )

- `TWRA:GetAllGroupRowsForSection()` - Line 1028
  - Referenced in:
    - core/Compression.lua:228 (in if )
    - core/Compression.lua:229
    - core/DataProcessing.lua:303
    - core/DataProcessing.lua:1229
    - core/DataUtility.lua:595 (in metadata["Group Rows"] = )
    - ui/options/Options-Import.lua:268

- `TWRA:UpdateGroupInfo()` - Line 1100
  - Referenced in:
    - core/DataProcessing.lua:1179

- `TWRA:MonitorGroupChanges()` - Line 1145
  - Referenced in:
    - core/DataProcessing.lua:1212

- `TWRA:InitializeGroupMonitoring()` - Line 1210
  - Referenced in:
    - core/Core.lua:149 (in if )
    - core/Core.lua:151

- `TWRA:EnsureGroupRowsIdentified()` - Line 1215
  - Referenced in:
    - core/DataUtility.lua:405 (in if )
    - core/DataUtility.lua:414

- `TWRA:IsCellRelevantForPlayer()` - Line 1239
  - Referenced in:
    - core/DataProcessing.lua:940 (in elseif )

- `TWRA:IsCellRelevantForPlayerGroup()` - Line 1270
  - Referenced in:
    - core/DataProcessing.lua:919 (in if )

- `TWRA:ProcessImportedData()` - Line 1323
  - Referenced in:
    - core/Base64.lua:719 (in if )
    - core/Base64.lua:720 (in result = )
    - core/DataUtility.lua:517 (in function )
    - ui/options/Options-Import.lua:287 (in if )
    - ui/options/Options-Import.lua:289 (in TWRA_Assignments.data = )

### 2.7 core/DataUtility.lua

- `TWRA:ConvertSpecialCharacters()` - Line 30
  - Referenced in:
    - core/DataUtility.lua:56 (in return )
    - core/DataUtility.lua:64 (in k = )
    - core/DataUtility.lua:70 (in result[k] = )

- `TWRA:FixSpecialCharacters()` - Line 53
  - Referenced in:
    - core/Base64.lua:724 (in if )
    - core/Base64.lua:725 (in result = )
    - core/DataProcessing.lua:1370 (in section["Section Name"] = )
    - core/DataProcessing.lua:1377 (in section["Section Header"][i] = )
    - core/DataProcessing.lua:1388 (in row[colIndex] = )
    - core/DataUtility.lua:68 (in result[k] = )

- `TWRA:GetCurrentSectionData()` - Line 78
  - Referenced in:
    - TWRA.lua:526 (in local sectionData = )
    - core/DataUtility.lua:113 (in local sectionData = )
    - features/AutoTanks.lua:60 (in local sectionData = )

- `TWRA:DisplayCurrentSection()` - Line 112
  - Referenced in:
    - TWRA.lua:1012 (in elseif )
    - TWRA.lua:1014
    - TWRA.lua:1027 (in function )

- `TWRA:FindTankRoleColumns()` - Line 133
  - Referenced in:
    - core/Base64.lua:303 (in if )
    - core/Base64.lua:304 (in local tankCols = )
    - core/DataProcessing.lua:883 (in tankColumns = )
    - core/DataProcessing.lua:1343 (in if )
    - core/DataProcessing.lua:1344 (in local tankColumns = )
    - core/DataUtility.lua:540 (in if )
    - core/DataUtility.lua:541 (in local tankColumns = )
    - features/AutoTanks.lua:82 (in if )
    - features/AutoTanks.lua:84 (in tankColumns = )

- `TWRA:NormalizeMetadataKeys()` - Line 187
  - Referenced in:
    - core/DataUtility.lua:226 (in local normalizedMetadata = )
    - core/DataUtility.lua:296 (in section["Section Metadata"] = )

- `TWRA:ClearData()` - Line 209
  - Referenced in:
    - Example.lua:274 (in if )
    - Example.lua:275
    - Example.lua:542 (in if )
    - Example.lua:543
    - core/DataUtility.lua:385 (in if not )

- `TWRA:DeepCopy()` - Line 352
  - Referenced in:
    - core/DataProcessing.lua:738 (in preservedMetadata = )
    - core/DataUtility.lua:229 (in metadataToPreserve[sectionName] = )
    - core/DataUtility.lua:247 (in playerInfoToPreserve[sectionName] = )
    - core/DataUtility.lua:304 (in section["Section Metadata"][key] = )
    - core/DataUtility.lua:318 (in section["Section Player Info"][key] = )
    - core/DataUtility.lua:358 (in copy[orig_key] = )

- `TWRA:SaveAssignments()` - Line 367
  - Referenced in:
    - core/Base64.lua:447 (in if )
    - core/Base64.lua:449
    - Example.lua:507 (in success = )
    - core/DataUtility.lua:335

- `TWRA:ProcessImportedData()` - Line 517
  - Referenced in:
    - core/Base64.lua:719 (in if )
    - core/Base64.lua:720 (in result = )
    - core/DataProcessing.lua:1323 (in function )
    - ui/options/Options-Import.lua:287 (in if )
    - ui/options/Options-Import.lua:289 (in TWRA_Assignments.data = )

- `TWRA:CaptureSpecialRows()` - Line 562
  - Referenced in:
    - core/DataUtility.lua:399 (in if )
    - core/DataUtility.lua:400 (in data = )

### 2.8 core/Debug.lua

- `TWRA:InitDebug()` - Line 61
  - Referenced in:
    - core/Debug.lua:367
    - core/Debug.lua:408
    - core/Debug.lua:448
    - core/Debug.lua:468
    - core/Debug.lua:507
    - core/Debug.lua:549
    - core/Debug.lua:569
    - core/Debug.lua:647
    - TWRA.lua:272 (in if )
    - core/Core.lua:115 (in if )
    - core/Core.lua:116

- `TWRA:Error()` - Line 200
  - Referenced in:
    - core/Debug.lua:723
    - core/Core.lua:210
    - core/Core.lua:548

- `TWRA:Debug()` - Line 204
  - Referenced in:
    - Bindings.lua:115
    - Bindings.lua:130
    - Bindings.lua:132
    - Bindings.lua:147
    - Bindings.lua:151
    - Bindings.lua:186
    - Bindings.lua:211
    - Bindings.lua:219
    - Bindings.lua:231
    - Bindings.lua:259
    - Bindings.lua:272
    - Bindings.lua:277
    - Bindings.lua:298
    - Bindings.lua:321
    - core/Debug.lua:194
    - core/Debug.lua:201
    - core/Debug.lua:324
    - core/Debug.lua:346
    - core/Debug.lua:353
    - core/Debug.lua:801
    - core/Debug.lua:808
    - core/Debug.lua:815
    - core/Debug.lua:822
    - core/Debug.lua:902
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
    - core/Base64.lua:90
    - core/Base64.lua:94
    - core/Base64.lua:100
    - core/Base64.lua:107
    - core/Base64.lua:118
    - core/Base64.lua:121
    - core/Base64.lua:133
    - core/Base64.lua:135
    - core/Base64.lua:141
    - core/Base64.lua:145
    - core/Base64.lua:153
    - core/Base64.lua:160
    - core/Base64.lua:167
    - core/Base64.lua:173
    - core/Base64.lua:182
    - core/Base64.lua:186
    - core/Base64.lua:227
    - core/Base64.lua:233
    - core/Base64.lua:238
    - core/Base64.lua:242
    - core/Base64.lua:249
    - core/Base64.lua:256
    - core/Base64.lua:269
    - core/Base64.lua:277
    - core/Base64.lua:281
    - core/Base64.lua:293
    - core/Base64.lua:305
    - core/Base64.lua:312
    - core/Base64.lua:324
    - core/Base64.lua:336
    - core/Base64.lua:347
    - core/Base64.lua:359
    - core/Base64.lua:371
    - core/Base64.lua:403
    - core/Base64.lua:431
    - core/Base64.lua:440
    - core/Base64.lua:454
    - core/Base64.lua:459
    - core/Base64.lua:462
    - core/Base64.lua:467
    - core/Base64.lua:473
    - core/Base64.lua:480
    - core/Base64.lua:491
    - core/Base64.lua:494
    - core/Base64.lua:499
    - core/Base64.lua:506
    - core/Base64.lua:510
    - core/Base64.lua:517
    - core/Base64.lua:526
    - core/Base64.lua:532
    - core/Base64.lua:536
    - core/Base64.lua:558
    - core/Base64.lua:580
    - core/Base64.lua:584
    - core/Base64.lua:598
    - core/Base64.lua:617
    - core/Base64.lua:645
    - core/Base64.lua:652
    - core/Base64.lua:657
    - core/Base64.lua:661
    - core/Base64.lua:666
    - core/Base64.lua:673
    - core/Base64.lua:682
    - core/Base64.lua:691
    - core/Base64.lua:697
    - core/Base64.lua:703
    - core/Base64.lua:707
    - core/Base64.lua:712
    - core/Base64.lua:729
    - core/Base64.lua:735
    - core/Base64.lua:740
    - core/Base64.lua:744
    - core/Base64.lua:751
    - core/Base64.lua:757
    - core/Base64.lua:764
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
    - Example.lua:452
    - Example.lua:455
    - Example.lua:458
    - Example.lua:469
    - Example.lua:475
    - Example.lua:490
    - Example.lua:531
    - Example.lua:539
    - Example.lua:544
    - Example.lua:556
    - Example.lua:563
    - Example.lua:589
    - Example.lua:592
    - Example.lua:598
    - Example.lua:603
    - Example.lua:606
    - Example.lua:616
    - Example.lua:629
    - Example.lua:634
    - Example.lua:646
    - Example.lua:665
    - Example.lua:697
    - Example.lua:708
    - Example.lua:714
    - Example.lua:719
    - Example.lua:731
    - Example.lua:738
    - Example.lua:740
    - Example.lua:747
    - Example.lua:757
    - Example.lua:768
    - Example.lua:790
    - Example.lua:793
    - Example.lua:812
    - Example.lua:818
    - TWRA.lua:14
    - TWRA.lua:17
    - TWRA.lua:22
    - TWRA.lua:28
    - TWRA.lua:40
    - TWRA.lua:49
    - TWRA.lua:56
    - TWRA.lua:63
    - TWRA.lua:79
    - TWRA.lua:85
    - TWRA.lua:100
    - TWRA.lua:273
    - TWRA.lua:277
    - TWRA.lua:290
    - TWRA.lua:298
    - TWRA.lua:311
    - TWRA.lua:318
    - TWRA.lua:320
    - TWRA.lua:351
    - TWRA.lua:357
    - TWRA.lua:367
    - TWRA.lua:371
    - TWRA.lua:374
    - TWRA.lua:388
    - TWRA.lua:399
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
    - TWRA.lua:581
    - TWRA.lua:589
    - TWRA.lua:593
    - TWRA.lua:674
    - TWRA.lua:685
    - TWRA.lua:700
    - TWRA.lua:704
    - TWRA.lua:713
    - TWRA.lua:721
    - TWRA.lua:745
    - TWRA.lua:747
    - TWRA.lua:756
    - TWRA.lua:765
    - TWRA.lua:769
    - TWRA.lua:776
    - TWRA.lua:782
    - TWRA.lua:794
    - TWRA.lua:795
    - TWRA.lua:812
    - TWRA.lua:865
    - TWRA.lua:872
    - TWRA.lua:943
    - TWRA.lua:984
    - TWRA.lua:993
    - TWRA.lua:1010
    - TWRA.lua:1013
    - TWRA.lua:1021
    - TWRA.lua:1032
    - TWRA.lua:1039
    - TWRA.lua:1042
    - TWRA.lua:1062
    - TWRA.lua:1071
    - TWRA.lua:1109
    - core/Core.lua:9
    - core/Core.lua:38
    - core/Core.lua:60
    - core/Core.lua:72
    - core/Core.lua:80
    - core/Core.lua:88
    - core/Core.lua:91
    - core/Core.lua:96
    - core/Core.lua:98
    - core/Core.lua:101
    - core/Core.lua:121
    - core/Core.lua:123
    - core/Core.lua:129
    - core/Core.lua:132
    - core/Core.lua:145
    - core/Core.lua:150
    - core/Core.lua:153
    - core/Core.lua:159
    - core/Core.lua:161
    - core/Core.lua:180
    - core/Core.lua:194
    - core/Core.lua:198
    - core/Core.lua:207
    - core/Core.lua:214
    - core/Core.lua:219
    - core/Core.lua:257
    - core/Core.lua:265
    - core/Core.lua:290
    - core/Core.lua:298
    - core/Core.lua:301
    - core/Core.lua:305
    - core/Core.lua:311
    - core/Core.lua:318
    - core/Core.lua:323
    - core/Core.lua:325
    - core/Core.lua:338
    - core/Core.lua:476
    - core/Core.lua:480
    - core/Core.lua:485
    - core/Core.lua:497
    - core/Core.lua:525
    - core/Core.lua:545
    - core/Core.lua:554
    - core/Core.lua:561
    - core/Core.lua:574
    - core/Core.lua:585
    - core/Core.lua:609
    - core/Core.lua:623
    - core/Core.lua:629
    - core/Core.lua:651
    - core/Core.lua:654
    - core/Core.lua:661
    - core/Core.lua:665
    - core/Core.lua:683
    - core/Core.lua:700
    - core/Core.lua:706
    - core/Core.lua:726
    - core/Core.lua:731
    - core/Core.lua:739
    - core/Core.lua:746
    - core/Core.lua:748
    - core/Core.lua:752
    - core/Core.lua:756
    - core/Core.lua:768
    - core/Core.lua:774
    - core/Core.lua:786
    - core/Core.lua:789
    - core/Core.lua:792
    - core/Core.lua:797
    - core/Core.lua:817
    - core/DataProcessing.lua:49
    - core/DataProcessing.lua:60
    - core/DataProcessing.lua:73
    - core/DataProcessing.lua:77
    - core/DataProcessing.lua:89
    - core/DataProcessing.lua:93
    - core/DataProcessing.lua:102
    - core/DataProcessing.lua:104
    - core/DataProcessing.lua:119
    - core/DataProcessing.lua:121
    - core/DataProcessing.lua:138
    - core/DataProcessing.lua:144
    - core/DataProcessing.lua:166
    - core/DataProcessing.lua:207
    - core/DataProcessing.lua:226
    - core/DataProcessing.lua:238
    - core/DataProcessing.lua:240
    - core/DataProcessing.lua:254
    - core/DataProcessing.lua:258
    - core/DataProcessing.lua:280
    - core/DataProcessing.lua:296
    - core/DataProcessing.lua:314
    - core/DataProcessing.lua:330
    - core/DataProcessing.lua:346
    - core/DataProcessing.lua:367
    - core/DataProcessing.lua:379
    - core/DataProcessing.lua:385
    - core/DataProcessing.lua:394
    - core/DataProcessing.lua:401
    - core/DataProcessing.lua:408
    - core/DataProcessing.lua:410
    - core/DataProcessing.lua:426
    - core/DataProcessing.lua:432
    - core/DataProcessing.lua:443
    - core/DataProcessing.lua:447
    - core/DataProcessing.lua:456
    - core/DataProcessing.lua:466
    - core/DataProcessing.lua:470
    - core/DataProcessing.lua:478
    - core/DataProcessing.lua:502
    - core/DataProcessing.lua:508
    - core/DataProcessing.lua:512
    - core/DataProcessing.lua:527
    - core/DataProcessing.lua:557
    - core/DataProcessing.lua:559
    - core/DataProcessing.lua:561
    - core/DataProcessing.lua:575
    - core/DataProcessing.lua:579
    - core/DataProcessing.lua:598
    - core/DataProcessing.lua:603
    - core/DataProcessing.lua:607
    - core/DataProcessing.lua:611
    - core/DataProcessing.lua:618
    - core/DataProcessing.lua:626
    - core/DataProcessing.lua:650
    - core/DataProcessing.lua:657
    - core/DataProcessing.lua:662
    - core/DataProcessing.lua:665
    - core/DataProcessing.lua:669
    - core/DataProcessing.lua:677
    - core/DataProcessing.lua:688
    - core/DataProcessing.lua:695
    - core/DataProcessing.lua:728
    - core/DataProcessing.lua:739
    - core/DataProcessing.lua:758
    - core/DataProcessing.lua:766
    - core/DataProcessing.lua:774
    - core/DataProcessing.lua:779
    - core/DataProcessing.lua:781
    - core/DataProcessing.lua:783
    - core/DataProcessing.lua:790
    - core/DataProcessing.lua:797
    - core/DataProcessing.lua:799
    - core/DataProcessing.lua:804
    - core/DataProcessing.lua:809
    - core/DataProcessing.lua:814
    - core/DataProcessing.lua:828
    - core/DataProcessing.lua:832
    - core/DataProcessing.lua:852
    - core/DataProcessing.lua:857
    - core/DataProcessing.lua:887
    - core/DataProcessing.lua:897
    - core/DataProcessing.lua:900
    - core/DataProcessing.lua:926
    - core/DataProcessing.lua:938
    - core/DataProcessing.lua:948
    - core/DataProcessing.lua:962
    - core/DataProcessing.lua:979
    - core/DataProcessing.lua:1015
    - core/DataProcessing.lua:1024
    - core/DataProcessing.lua:1033
    - core/DataProcessing.lua:1037
    - core/DataProcessing.lua:1043
    - core/DataProcessing.lua:1046
    - core/DataProcessing.lua:1070
    - core/DataProcessing.lua:1081
    - core/DataProcessing.lua:1088
    - core/DataProcessing.lua:1093
    - core/DataProcessing.lua:1101
    - core/DataProcessing.lua:1115
    - core/DataProcessing.lua:1117
    - core/DataProcessing.lua:1132
    - core/DataProcessing.lua:1138
    - core/DataProcessing.lua:1146
    - core/DataProcessing.lua:1171
    - core/DataProcessing.lua:1200
    - core/DataProcessing.lua:1206
    - core/DataProcessing.lua:1211
    - core/DataProcessing.lua:1217
    - core/DataProcessing.lua:1221
    - core/DataProcessing.lua:1231
    - core/DataProcessing.lua:1252
    - core/DataProcessing.lua:1260
    - core/DataProcessing.lua:1311
    - core/DataProcessing.lua:1325
    - core/DataProcessing.lua:1329
    - core/DataProcessing.lua:1336
    - core/DataProcessing.lua:1345
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
    - core/DataUtility.lua:394
    - core/DataUtility.lua:398
    - core/DataUtility.lua:401
    - core/DataUtility.lua:415
    - core/DataUtility.lua:438
    - core/DataUtility.lua:441
    - core/DataUtility.lua:443
    - core/DataUtility.lua:445
    - core/DataUtility.lua:447
    - core/DataUtility.lua:452
    - core/DataUtility.lua:458
    - core/DataUtility.lua:465
    - core/DataUtility.lua:467
    - core/DataUtility.lua:470
    - core/DataUtility.lua:475
    - core/DataUtility.lua:483
    - core/DataUtility.lua:491
    - core/DataUtility.lua:502
    - core/DataUtility.lua:508
    - core/DataUtility.lua:537
    - core/DataUtility.lua:542
    - core/DataUtility.lua:547
    - core/DataUtility.lua:552
    - core/DataUtility.lua:564
    - core/DataUtility.lua:568
    - core/DataUtility.lua:577
    - core/DataUtility.lua:596
    - core/DataUtility.lua:599
    - core/DataUtility.lua:624
    - core/DataUtility.lua:642
    - core/DataUtility.lua:663
    - core/DataUtility.lua:676
    - core/DataUtility.lua:680
    - core/DataUtility.lua:693
    - core/DataUtility.lua:698
    - core/DataUtility.lua:711
    - core/DataUtility.lua:738
    - core/DataUtility.lua:741
    - core/DataUtility.lua:749
    - ui/UIUtils.lua:8
    - ui/UIUtils.lua:43
    - ui/Frame.lua:6
    - ui/Frame.lua:50
    - ui/Frame.lua:103
    - ui/Frame.lua:133
    - ui/Frame.lua:136
    - ui/Frame.lua:139
    - ui/Frame.lua:143
    - ui/Frame.lua:527
    - ui/Frame.lua:541
    - ui/Frame.lua:550
    - ui/Frame.lua:553
    - ui/Frame.lua:564
    - ui/Frame.lua:569
    - ui/Frame.lua:573
    - ui/Frame.lua:581
    - ui/Frame.lua:587
    - ui/Frame.lua:591
    - ui/Frame.lua:609
    - ui/Frame.lua:652
    - ui/Frame.lua:671
    - ui/Frame.lua:680
    - ui/Frame.lua:684
    - ui/Frame.lua:690
    - ui/Frame.lua:698
    - ui/Frame.lua:703
    - ui/Frame.lua:706
    - ui/Frame.lua:730
    - ui/Frame.lua:737
    - ui/Frame.lua:775
    - ui/Frame.lua:778
    - ui/Frame.lua:791
    - ui/Frame.lua:793
    - ui/Frame.lua:795
    - ui/Frame.lua:801
    - ui/Frame.lua:807
    - ui/Frame.lua:813
    - ui/Frame.lua:858
    - ui/Frame.lua:883
    - ui/Frame.lua:896
    - ui/Frame.lua:906
    - ui/Frame.lua:913
    - ui/Frame.lua:940
    - ui/Frame.lua:942
    - ui/Frame.lua:951
    - ui/Frame.lua:954
    - ui/Frame.lua:978
    - ui/Frame.lua:982
    - ui/Frame.lua:987
    - ui/Frame.lua:1002
    - ui/Frame.lua:1006
    - ui/Frame.lua:1014
    - ui/Frame.lua:1023
    - ui/Frame.lua:1043
    - ui/Frame.lua:1056
    - ui/Frame.lua:1061
    - ui/Frame.lua:1065
    - ui/Frame.lua:1069
    - ui/Frame.lua:1073
    - ui/Frame.lua:1121
    - ui/Frame.lua:1126
    - ui/Frame.lua:1176
    - ui/Frame.lua:1260
    - ui/Frame.lua:1321
    - ui/Frame.lua:1326
    - ui/Frame.lua:1333
    - ui/Frame.lua:1338
    - ui/Frame.lua:1389
    - ui/Frame.lua:1395
    - ui/Frame.lua:1406
    - ui/Frame.lua:1580
    - ui/Frame.lua:1593
    - ui/Frame.lua:1606
    - ui/Frame.lua:1613
    - ui/Frame.lua:1628
    - ui/Frame.lua:1662
    - ui/Frame.lua:1674
    - ui/Frame.lua:1680
    - ui/Frame.lua:1697
    - ui/Frame.lua:1706
    - ui/Frame.lua:1712
    - ui/Frame.lua:1743
    - ui/Frame.lua:1764
    - ui/Frame.lua:1766
    - ui/Frame.lua:1772
    - ui/Frame.lua:1814
    - ui/Frame.lua:1836
    - ui/Frame.lua:1883
    - ui/Frame.lua:2074
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
    - ui/Minimap.lua:339
    - ui/Minimap.lua:346
    - ui/Minimap.lua:352
    - ui/Minimap.lua:360
    - ui/Minimap.lua:388
    - ui/Minimap.lua:423
    - ui/Minimap.lua:430
    - ui/Minimap.lua:442
    - ui/Minimap.lua:530
    - ui/Minimap.lua:558
    - ui/Minimap.lua:607
    - ui/Minimap.lua:772
    - ui/OSD.lua:9
    - ui/OSD.lua:29
    - ui/OSD.lua:33
    - ui/OSD.lua:37
    - ui/OSD.lua:43
    - ui/OSD.lua:63
    - ui/OSD.lua:67
    - ui/OSD.lua:75
    - ui/OSD.lua:85
    - ui/OSD.lua:89
    - ui/OSD.lua:100
    - ui/OSD.lua:106
    - ui/OSD.lua:110
    - ui/OSD.lua:121
    - ui/OSD.lua:128
    - ui/OSD.lua:198
    - ui/OSD.lua:201
    - ui/OSD.lua:218
    - ui/OSD.lua:224
    - ui/OSD.lua:228
    - ui/OSD.lua:240
    - ui/OSD.lua:246
    - ui/OSD.lua:251
    - ui/OSD.lua:253
    - ui/OSD.lua:255
    - ui/OSD.lua:262
    - ui/OSD.lua:368
    - ui/OSD.lua:374
    - ui/OSD.lua:394
    - ui/OSD.lua:434
    - ui/OSD.lua:447
    - ui/OSD.lua:451
    - ui/OSD.lua:845
    - ui/OSD.lua:875
    - ui/OSD.lua:882
    - ui/OSD.lua:901
    - ui/OSD.lua:919
    - ui/OSD.lua:944
    - ui/OSD.lua:957
    - ui/OSD.lua:962
    - ui/OSD.lua:975
    - ui/OSD.lua:980
    - ui/OSD.lua:988
    - ui/OSD.lua:992
    - ui/OSD.lua:1041
    - ui/OSD.lua:1046
    - ui/OSD.lua:1081
    - ui/OSD.lua:1087
    - ui/OSD.lua:1126
    - ui/OSD.lua:1132
    - ui/OSD.lua:1137
    - ui/OSD.lua:1148
    - ui/OSD.lua:1182
    - ui/OSD.lua:1189
    - ui/OSD.lua:1195
    - ui/OSD.lua:1202
    - ui/OSD.lua:1221
    - ui/OSD.lua:1228
    - ui/OSD.lua:1235
    - ui/OSD.lua:1241
    - ui/OSD.lua:1248
    - ui/OSD.lua:1268
    - ui/OSD.lua:1281
    - ui/OSD.lua:1302
    - ui/OSD.lua:1308
    - ui/OSD.lua:1329
    - ui/OSD.lua:1371
    - ui/OSD.lua:1416
    - ui/OSD.lua:1443
    - ui/OSD.lua:1446
    - ui/OSD.lua:1449
    - ui/OSD.lua:1559
    - ui/OSD.lua:1562
    - ui/OSD.lua:1565
    - ui/Options.lua:70
    - ui/Options.lua:110
    - ui/Options.lua:118
    - ui/Options.lua:120
    - ui/Options.lua:126
    - ui/Options.lua:128
    - ui/Options.lua:134
    - ui/Options.lua:136
    - ui/Options.lua:242
    - ui/Options.lua:246
    - ui/Options.lua:251
    - ui/Options.lua:256
    - ui/Options.lua:265
    - ui/Options.lua:273
    - ui/Options.lua:275
    - ui/Options.lua:278
    - ui/Options.lua:286
    - ui/Options.lua:292
    - ui/Options.lua:294
    - ui/Options.lua:297
    - ui/Options.lua:302
    - ui/Options.lua:308
    - ui/Options.lua:310
    - ui/Options.lua:313
    - ui/Options.lua:328
    - ui/Options.lua:334
    - ui/Options.lua:336
    - ui/Options.lua:339
    - ui/options/Options-General.lua:6
    - ui/options/Options-General.lua:20
    - ui/options/Options-General.lua:331 (in --         )
    - ui/options/Options-General.lua:337 (in --         )
    - ui/options/Options-General.lua:366 (in --         )
    - ui/options/Options-General.lua:371 (in --         )
    - ui/options/Options-General.lua:400 (in --         )
    - ui/options/Options-General.lua:406 (in --         )
    - ui/options/Options-General.lua:435 (in --         )
    - ui/options/Options-General.lua:441 (in --         )
    - ui/options/Options-General.lua:490
    - ui/options/Options-General.lua:507
    - ui/options/Options-General.lua:529
    - ui/options/Options-General.lua:544
    - ui/options/Options-General.lua:550
    - ui/options/Options-General.lua:555
    - ui/options/Options-OSD.lua:6
    - ui/options/Options-OSD.lua:20
    - ui/options/Options-OSD.lua:115
    - ui/options/Options-OSD.lua:200
    - ui/options/Options-OSD.lua:231
    - ui/options/Options-OSD.lua:257
    - ui/options/Options-Import.lua:6
    - ui/options/Options-Import.lua:22
    - ui/options/Options-Import.lua:26
    - ui/options/Options-Import.lua:30
    - ui/options/Options-Import.lua:41
    - ui/options/Options-Import.lua:46
    - ui/options/Options-Import.lua:53
    - ui/options/Options-Import.lua:59
    - ui/options/Options-Import.lua:73
    - ui/options/Options-Import.lua:81
    - ui/options/Options-Import.lua:88
    - ui/options/Options-Import.lua:93
    - ui/options/Options-Import.lua:97
    - ui/options/Options-Import.lua:101 (in -- )
    - ui/options/Options-Import.lua:104
    - ui/options/Options-Import.lua:108 (in --     )
    - ui/options/Options-Import.lua:114 (in --     )
    - ui/options/Options-Import.lua:119 (in -- )
    - ui/options/Options-Import.lua:122 (in --     )
    - ui/options/Options-Import.lua:128
    - ui/options/Options-Import.lua:133
    - ui/options/Options-Import.lua:137
    - ui/options/Options-Import.lua:150
    - ui/options/Options-Import.lua:154
    - ui/options/Options-Import.lua:161
    - ui/options/Options-Import.lua:233
    - ui/options/Options-Import.lua:237
    - ui/options/Options-Import.lua:249
    - ui/options/Options-Import.lua:252
    - ui/options/Options-Import.lua:258
    - ui/options/Options-Import.lua:277
    - ui/options/Options-Import.lua:282
    - ui/options/Options-Import.lua:288
    - ui/options/Options-Import.lua:295
    - ui/options/Options-Import.lua:298
    - ui/options/Options-Import.lua:312
    - ui/options/Options-Import.lua:317
    - ui/options/Options-Import.lua:329
    - ui/options/Options-Import.lua:335
    - ui/options/Options-Import.lua:342
    - ui/options/Options-Import.lua:346
    - ui/options/Options-Import.lua:374
    - ui/options/Options-Import.lua:389
    - ui/options/Options-Import.lua:399
    - ui/options/Options-Import.lua:407
    - ui/EncounterMap.lua:8
    - ui/EncounterMap.lua:42
    - ui/EncounterMap.lua:151
    - ui/EncounterMap.lua:156
    - ui/EncounterMap.lua:161
    - ui/EncounterMap.lua:166
    - ui/EncounterMap.lua:201
    - ui/EncounterMap.lua:360
    - ui/EncounterMap.lua:366
    - ui/EncounterMap.lua:386
    - ui/EncounterMap.lua:421
    - ui/EncounterMap.lua:427
    - ui/EncounterMap.lua:433
    - ui/EncounterMap.lua:441
    - ui/EncounterMap.lua:455
    - ui/EncounterMap.lua:485
    - ui/EncounterMap.lua:565
    - ui/EncounterMap.lua:571
    - ui/EncounterMap.lua:577
    - ui/EncounterMap.lua:587
    - ui/EncounterMap.lua:595
    - ui/EncounterMap.lua:601
    - ui/EncounterMap.lua:610
    - ui/EncounterMap.lua:618
    - ui/EncounterMap.lua:646
    - ui/EncounterMap.lua:653
    - ui/EncounterMap.lua:712
    - ui/EncounterMap.lua:751
    - ui/EncounterMap.lua:798
    - ui/EncounterMap.lua:802
    - ui/EncounterMap.lua:808
    - ui/EncounterMap.lua:814
    - ui/EncounterMap.lua:838
    - ui/EncounterMap.lua:849
    - ui/EncounterMap.lua:857
    - ui/EncounterMap.lua:867
    - ui/EncounterMap.lua:878
    - ui/EncounterMap.lua:882
    - ui/EncounterMap.lua:891
    - ui/EncounterMap.lua:936
    - ui/EncounterMap.lua:941
    - ui/EncounterMap.lua:953
    - ui/EncounterMap.lua:960
    - ui/EncounterMap.lua:966
    - ui/EncounterMap.lua:973
    - ui/EncounterMap.lua:980
    - ui/EncounterMap.lua:992
    - ui/EncounterMap.lua:999
    - ui/EncounterMap.lua:1022
    - ui/EncounterMap.lua:1024
    - ui/EncounterMap.lua:1038
    - ui/EncounterMap.lua:1048
    - ui/EncounterMap.lua:1059
    - ui/EncounterMap.lua:1078
    - ui/EncounterMap.lua:1085
    - ui/EncounterMap.lua:1092
    - ui/EncounterMap.lua:1107
    - ui/EncounterMap.lua:1119
    - ui/EncounterMap.lua:1134
    - ui/EncounterMap.lua:1137
    - ui/EncounterMap.lua:1165
    - ui/EncounterMap.lua:1174
    - features/AutoTanks.lua:16
    - features/AutoTanks.lua:23
    - features/AutoTanks.lua:26
    - features/AutoTanks.lua:42
    - features/AutoTanks.lua:53
    - features/AutoTanks.lua:57
    - features/AutoTanks.lua:62
    - features/AutoTanks.lua:76 (in -- )
    - features/AutoTanks.lua:77 (in -- )
    - features/AutoTanks.lua:83
    - features/AutoTanks.lua:85
    - features/AutoTanks.lua:87
    - features/AutoTanks.lua:106
    - features/AutoTanks.lua:108
    - features/AutoTanks.lua:118
    - features/AutoTanks.lua:136
    - features/AutoTanks.lua:138
    - features/AutoTanks.lua:141
    - features/AutoTanks.lua:159
    - features/AutoTanks.lua:165 (in -- )
    - features/AutoTanks.lua:170 (in -- )
    - features/AutoTanks.lua:183
    - features/AutoTanks.lua:187
    - features/AutoTanks.lua:196
    - features/AutoTanks.lua:202
    - features/AutoTanks.lua:213
    - features/AutoTanks.lua:218
    - features/AutoTanks.lua:223
    - features/AutoTanks.lua:231
    - features/AutoTanks.lua:237
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
    - core/Linking.lua:134
    - core/Linking.lua:140
    - core/Linking.lua:161
    - core/Linking.lua:167
    - core/Linking.lua:174
    - core/Linking.lua:180
    - core/Linking.lua:185
    - core/Linking.lua:196
    - core/Linking.lua:203
    - core/Linking.lua:210
    - core/Linking.lua:222
    - core/Linking.lua:240
    - core/Linking.lua:247
    - core/Linking.lua:294
    - core/Linking.lua:339
    - core/Linking.lua:369
    - core/Linking.lua:420
    - core/Linking.lua:427
    - core/Linking.lua:444
    - core/AbilityLinks.lua:100
    - core/AbilityLinks.lua:104
    - sync/SyncHandlers.lua:29
    - sync/SyncHandlers.lua:34
    - sync/SyncHandlers.lua:38
    - sync/SyncHandlers.lua:53
    - sync/SyncHandlers.lua:59
    - sync/SyncHandlers.lua:62
    - sync/SyncHandlers.lua:63
    - sync/SyncHandlers.lua:70
    - sync/SyncHandlers.lua:148
    - sync/SyncHandlers.lua:154
    - sync/SyncHandlers.lua:157
    - sync/SyncHandlers.lua:165
    - sync/SyncHandlers.lua:169
    - sync/SyncHandlers.lua:208
    - sync/SyncHandlers.lua:214
    - sync/SyncHandlers.lua:221
    - sync/SyncHandlers.lua:224
    - sync/SyncHandlers.lua:258
    - sync/SyncHandlers.lua:259
    - sync/SyncHandlers.lua:269
    - sync/SyncHandlers.lua:276
    - sync/SyncHandlers.lua:285
    - sync/SyncHandlers.lua:289
    - sync/SyncHandlers.lua:295
    - sync/SyncHandlers.lua:302
    - sync/SyncHandlers.lua:306
    - sync/SyncHandlers.lua:307
    - sync/SyncHandlers.lua:311
    - sync/SyncHandlers.lua:317
    - sync/SyncHandlers.lua:319
    - sync/SyncHandlers.lua:323
    - sync/SyncHandlers.lua:330
    - sync/SyncHandlers.lua:334
    - sync/SyncHandlers.lua:344
    - sync/SyncHandlers.lua:347
    - sync/SyncHandlers.lua:349
    - sync/SyncHandlers.lua:352
    - sync/SyncHandlers.lua:364
    - sync/SyncHandlers.lua:373
    - sync/SyncHandlers.lua:377
    - sync/SyncHandlers.lua:384
    - sync/SyncHandlers.lua:398
    - sync/SyncHandlers.lua:410
    - sync/SyncHandlers.lua:413
    - sync/SyncHandlers.lua:417
    - sync/SyncHandlers.lua:421
    - sync/SyncHandlers.lua:427
    - sync/SyncHandlers.lua:436
    - sync/SyncHandlers.lua:437
    - sync/SyncHandlers.lua:447
    - sync/SyncHandlers.lua:452
    - sync/SyncHandlers.lua:459
    - sync/SyncHandlers.lua:468
    - sync/SyncHandlers.lua:470
    - sync/SyncHandlers.lua:485
    - sync/SyncHandlers.lua:490
    - sync/SyncHandlers.lua:499
    - sync/SyncHandlers.lua:528
    - sync/SyncHandlers.lua:532
    - sync/SyncHandlers.lua:539
    - sync/SyncHandlers.lua:556
    - sync/SyncHandlers.lua:565
    - sync/SyncHandlers.lua:576
    - sync/SyncHandlers.lua:588
    - sync/SyncHandlers.lua:591
    - sync/SyncHandlers.lua:595
    - sync/SyncHandlers.lua:599
    - sync/SyncHandlers.lua:605
    - sync/SyncHandlers.lua:614
    - sync/SyncHandlers.lua:615
    - sync/SyncHandlers.lua:625
    - sync/SyncHandlers.lua:630
    - sync/SyncHandlers.lua:637
    - sync/SyncHandlers.lua:646
    - sync/SyncHandlers.lua:648
    - sync/SyncHandlers.lua:675
    - sync/SyncHandlers.lua:682
    - sync/SyncHandlers.lua:692
    - sync/SyncHandlers.lua:695
    - sync/SyncHandlers.lua:697
    - sync/SyncHandlers.lua:700
    - sync/SyncHandlers.lua:708
    - sync/SyncHandlers.lua:711
    - sync/SyncHandlers.lua:713
    - sync/SyncHandlers.lua:722
    - sync/SyncHandlers.lua:733
    - sync/SyncHandlers.lua:735
    - sync/SyncHandlers.lua:741
    - sync/SyncHandlers.lua:749
    - sync/SyncHandlers.lua:755
    - sync/SyncHandlers.lua:758
    - sync/SyncHandlers.lua:764
    - sync/SyncHandlers.lua:771
    - sync/SyncHandlers.lua:773
    - sync/SyncHandlers.lua:781
    - sync/SyncHandlers.lua:783
    - sync/SyncHandlers.lua:789
    - sync/SyncHandlers.lua:794
    - sync/SyncHandlers.lua:812
    - sync/SyncHandlers.lua:815
    - sync/SyncHandlers.lua:818
    - sync/SyncHandlers.lua:824
    - sync/SyncHandlers.lua:833
    - sync/SyncHandlers.lua:838
    - sync/SyncHandlers.lua:844
    - sync/SyncHandlers.lua:853
    - sync/SyncHandlers.lua:858
    - sync/SyncHandlers.lua:866
    - sync/SyncHandlers.lua:872
    - sync/SyncHandlers.lua:880
    - sync/SyncHandlers.lua:885
    - sync/SyncHandlers.lua:890
    - sync/SyncHandlers.lua:913
    - sync/SyncHandlers.lua:921
    - sync/SyncHandlers.lua:925
    - sync/SyncHandlers.lua:931
    - sync/SyncHandlers.lua:940
    - sync/SyncHandlers.lua:946
    - sync/SyncHandlers.lua:950
    - sync/SyncHandlers.lua:963
    - sync/SyncHandlers.lua:979
    - sync/SyncHandlers.lua:985
    - sync/SyncHandlers.lua:997
    - sync/SyncHandlers.lua:1004
    - sync/SyncHandlers.lua:1009
    - sync/SyncHandlers.lua:1014
    - sync/SyncHandlers.lua:1035
    - sync/SyncHandlers.lua:1046
    - sync/SyncHandlers.lua:1053
    - sync/SyncHandlers.lua:1059
    - sync/SyncHandlers.lua:1070
    - sync/SyncHandlers.lua:1090
    - sync/SyncHandlers.lua:1097
    - sync/SyncHandlers.lua:1105
    - sync/SyncHandlers.lua:1107
    - sync/SyncHandlers.lua:1112
    - sync/SyncHandlers.lua:1122
    - sync/SyncHandlers.lua:1127
    - sync/SyncHandlers.lua:1149
    - sync/SyncHandlers.lua:1157
    - sync/SyncHandlers.lua:1162
    - sync/SyncHandlers.lua:1183
    - sync/SyncHandlers.lua:1188
    - sync/SyncHandlers.lua:1196
    - sync/SyncHandlers.lua:1216
    - sync/SyncHandlers.lua:1219
    - sync/SyncHandlers.lua:1279
    - sync/SyncHandlers.lua:1283
    - sync/SyncHandlers.lua:1290
    - sync/SyncHandlers.lua:1295
    - sync/SyncHandlers.lua:1297
    - sync/SyncHandlers.lua:1323
    - sync/SyncHandlers.lua:1333
    - sync/SyncHandlers.lua:1341
    - sync/SyncHandlers.lua:1350
    - sync/SyncHandlers.lua:1361
    - sync/SyncHandlers.lua:1384
    - sync/SyncHandlers.lua:1393
    - sync/SyncHandlers.lua:1397
    - sync/SyncHandlers.lua:1403
    - sync/SyncHandlers.lua:1414
    - sync/SyncHandlers.lua:1425
    - sync/SyncHandlers.lua:1429
    - sync/SyncHandlers.lua:1433
    - sync/SyncHandlers.lua:1437
    - sync/ChunkManager.lua:18
    - sync/ChunkManager.lua:19
    - sync/ChunkManager.lua:31
    - sync/ChunkManager.lua:32
    - sync/ChunkManager.lua:45
    - sync/ChunkManager.lua:46
    - sync/ChunkManager.lua:57
    - sync/ChunkManager.lua:58
    - sync/ChunkManager.lua:63
    - sync/ChunkManager.lua:64
    - sync/ChunkManager.lua:81
    - sync/ChunkManager.lua:82
    - sync/ChunkManager.lua:83
    - sync/ChunkManager.lua:108
    - sync/ChunkManager.lua:110
    - sync/ChunkManager.lua:112
    - sync/ChunkManager.lua:115
    - sync/ChunkManager.lua:116
    - sync/ChunkManager.lua:122
    - sync/ChunkManager.lua:123
    - sync/ChunkManager.lua:134
    - sync/ChunkManager.lua:139
    - sync/ChunkManager.lua:140
    - sync/ChunkManager.lua:146
    - sync/ChunkManager.lua:147
    - sync/ChunkManager.lua:166
    - sync/ChunkManager.lua:168
    - sync/ChunkManager.lua:179
    - sync/ChunkManager.lua:180
    - sync/ChunkManager.lua:192
    - sync/ChunkManager.lua:198
    - sync/ChunkManager.lua:199
    - sync/ChunkManager.lua:206
    - sync/ChunkManager.lua:207
    - sync/ChunkManager.lua:213
    - sync/ChunkManager.lua:214
    - sync/ChunkManager.lua:222
    - sync/ChunkManager.lua:223
    - sync/ChunkManager.lua:238
    - sync/ChunkManager.lua:240
    - sync/ChunkManager.lua:244
    - sync/ChunkManager.lua:260
    - sync/ChunkManager.lua:280
    - sync/ChunkManager.lua:282
    - sync/ChunkManager.lua:288
    - sync/ChunkManager.lua:289
    - sync/ChunkManager.lua:295
    - sync/ChunkManager.lua:296
    - sync/ChunkManager.lua:297
    - sync/ChunkManager.lua:309
    - sync/ChunkManager.lua:310
    - sync/ChunkManager.lua:318
    - sync/ChunkManager.lua:319
    - sync/ChunkManager.lua:324
    - sync/ChunkManager.lua:325
    - sync/ChunkManager.lua:330
    - sync/ChunkManager.lua:331
    - sync/ChunkManager.lua:340
    - sync/ChunkManager.lua:342
    - sync/ChunkManager.lua:346
    - sync/ChunkManager.lua:351
    - sync/ChunkManager.lua:353
    - sync/ChunkManager.lua:356
    - sync/ChunkManager.lua:360
    - sync/ChunkManager.lua:374
    - sync/ChunkManager.lua:382
    - sync/ChunkManager.lua:391
    - sync/ChunkManager.lua:399
    - sync/ChunkManager.lua:416
    - sync/ChunkManager.lua:417
    - sync/ChunkManager.lua:440
    - sync/ChunkManager.lua:444
    - sync/ChunkManager.lua:446
    - sync/ChunkManager.lua:451
    - sync/ChunkManager.lua:452
    - sync/ChunkManager.lua:456
    - sync/ChunkManager.lua:467
    - sync/ChunkManager.lua:475
    - sync/ChunkManager.lua:477
    - sync/ChunkManager.lua:483
    - sync/ChunkManager.lua:493
    - sync/ChunkManager.lua:510
    - sync/ChunkManager.lua:511
    - sync/ChunkManager.lua:521
    - sync/ChunkManager.lua:522
    - sync/ChunkManager.lua:533
    - sync/ChunkManager.lua:538
    - sync/ChunkManager.lua:539
    - sync/ChunkManager.lua:541
    - sync/ChunkManager.lua:546
    - sync/ChunkManager.lua:567
    - sync/ChunkManager.lua:575
    - sync/ChunkManager.lua:576
    - sync/ChunkManager.lua:590
    - sync/ChunkManager.lua:613
    - sync/ChunkManager.lua:617
    - sync/ChunkManager.lua:656
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
    - sync/Sync.lua:233
    - sync/Sync.lua:242
    - sync/Sync.lua:248
    - sync/Sync.lua:261
    - sync/Sync.lua:264
    - sync/Sync.lua:270
    - sync/Sync.lua:275
    - sync/Sync.lua:284
    - sync/Sync.lua:290
    - sync/Sync.lua:311
    - sync/Sync.lua:319
    - sync/Sync.lua:321
    - sync/Sync.lua:340
    - sync/Sync.lua:344
    - sync/Sync.lua:381
    - sync/Sync.lua:428
    - sync/Sync.lua:433
    - sync/Sync.lua:438
    - sync/Sync.lua:443
    - sync/Sync.lua:446
    - sync/Sync.lua:449
    - sync/Sync.lua:458
    - sync/Sync.lua:464
    - sync/Sync.lua:469
    - sync/Sync.lua:473
    - sync/Sync.lua:476
    - sync/Sync.lua:487
    - sync/Sync.lua:492
    - sync/Sync.lua:506
    - sync/Sync.lua:515
    - sync/Sync.lua:521
    - sync/Sync.lua:534
    - sync/Sync.lua:543
    - sync/Sync.lua:549
    - sync/Sync.lua:561
    - sync/Sync.lua:572
    - sync/Sync.lua:586
    - sync/Sync.lua:590
    - sync/Sync.lua:593
    - sync/Sync.lua:611
    - sync/Sync.lua:625
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
    - sync/Sync.lua:901
    - sync/Sync.lua:909
    - sync/Sync.lua:917
    - sync/Sync.lua:919
    - sync/Sync.lua:928
    - sync/Sync.lua:938
    - sync/Sync.lua:940
    - sync/Sync.lua:947
    - sync/Sync.lua:951
    - sync/Sync.lua:955
    - sync/Sync.lua:957
    - sync/Sync.lua:964
    - sync/Sync.lua:970
    - sync/Sync.lua:974
    - sync/Sync.lua:981
    - sync/Sync.lua:986
    - sync/Sync.lua:988
    - sync/Sync.lua:994
    - sync/Sync.lua:1008
    - sync/Sync.lua:1024
    - sync/Sync.lua:1027
    - sync/Sync.lua:1031
    - sync/Sync.lua:1042
    - sync/Sync.lua:1045
    - sync/Sync.lua:1052
    - sync/Sync.lua:1057
    - sync/Sync.lua:1064
    - sync/Sync.lua:1075
    - sync/Sync.lua:1077
    - sync/Sync.lua:1088
    - sync/Sync.lua:1090
    - sync/Sync.lua:1153
    - sync/Sync.lua:1158
    - sync/Sync.lua:1169
    - sync/Sync.lua:1174
    - sync/Sync.lua:1190
    - sync/Sync.lua:1209
    - sync/Sync.lua:1220
    - sync/Sync.lua:1256
    - sync/Sync.lua:1264
    - sync/Sync.lua:1269
    - sync/Sync.lua:1271
    - sync/Sync.lua:1275
    - sync/Sync.lua:1296
    - sync/Sync.lua:1314
    - sync/Sync.lua:1319
    - sync/Sync.lua:1332
    - sync/Sync.lua:1339
    - sync/Sync.lua:1360
    - sync/Sync.lua:1371
    - sync/Sync.lua:1389
    - sync/Sync.lua:1403
    - sync/Sync.lua:1407
    - sync/Sync.lua:1412
    - sync/Sync.lua:1434
    - sync/Sync.lua:1437
    - sync/Sync.lua:1444
    - sync/Sync.lua:1449
    - sync/Sync.lua:1451
    - sync/Sync.lua:1455
    - sync/Sync.lua:1457
    - sync/Sync.lua:1461
    - sync/Sync.lua:1464
    - sync/Sync.lua:1468
    - sync/Sync.lua:1471
    - sync/Sync.lua:1477
    - sync/Sync.lua:1482
    - sync/Sync.lua:1492
    - sync/Sync.lua:1510
    - sync/Sync.lua:1515
    - sync/Sync.lua:1528
    - sync/Sync.lua:1535
    - sync/Sync.lua:1536
    - sync/Sync.lua:1544
    - sync/Sync.lua:1545
    - sync/Sync.lua:1563
    - sync/Sync.lua:1564
    - sync/Sync.lua:1565
    - sync/Sync.lua:1566
    - sync/Sync.lua:1567
    - sync/Sync.lua:1568
    - sync/Sync.lua:1578
    - sync/Sync.lua:1579
    - sync/Sync.lua:1580
    - sync/Sync.lua:1584
    - sync/Sync.lua:1586
    - sync/Sync.lua:1587
    - sync/Sync.lua:1589
    - sync/Sync.lua:1591
    - sync/Sync.lua:1592
    - sync/Sync.lua:1612
    - sync/Sync.lua:1615
    - sync/Sync.lua:1618
    - sync/Sync.lua:1622
    - sync/Sync.lua:1624
    - sync/Sync.lua:1629
    - sync/Sync.lua:1630
    - sync/Sync.lua:1631
    - sync/Sync.lua:1639
    - sync/Sync.lua:1640
    - sync/Sync.lua:1648
    - sync/Sync.lua:1652
    - sync/Sync.lua:1664
    - sync/Sync.lua:1670
    - sync/Sync.lua:1675
    - sync/Sync.lua:1676
    - sync/Sync.lua:1677
    - sync/Sync.lua:1681
    - sync/Sync.lua:1690
    - sync/Sync.lua:1694
    - sync/Sync.lua:1700
    - sync/Sync.lua:1701
    - sync/Sync.lua:1702
    - sync/Sync.lua:1706
    - sync/Sync.lua:1709
    - sync/Sync.lua:1713
    - sync/Sync.lua:1718
    - sync/Sync.lua:1725
    - sync/Sync.lua:1743
    - sync/Sync.lua:1744
    - sync/Sync.lua:1754

- `TWRA:ProcessEarlyErrors()` - Line 289
  - Referenced in:
    - core/Debug.lua:654
    - core/Debug.lua:659 (in if )
    - core/Debug.lua:660

- `TWRA:ToggleDebug()` - Line 365
  - Referenced in:
    - core/Debug.lua:244
    - core/Debug.lua:708
    - core/Debug.lua:710

- `TWRA:ToggleDebugCategory()` - Line 406
  - Referenced in:
    - core/Debug.lua:763
    - core/Debug.lua:771
    - core/Debug.lua:779
    - core/Debug.lua:782
    - core/Debug.lua:828
    - core/Debug.lua:833
    - core/Debug.lua:835
    - core/Debug.lua:837

- `TWRA:ListDebugCategories()` - Line 446
  - Referenced in:
    - core/Debug.lua:759

- `TWRA:EnableFullDebug()` - Line 466
  - Referenced in:
    - core/Debug.lua:712

- `TWRA:ToggleDetailedLogging()` - Line 505
  - Referenced in:
    - core/Debug.lua:595
    - core/Debug.lua:732
    - core/Debug.lua:734
    - core/Debug.lua:737

- `TWRA:ToggleTimestamps()` - Line 547
  - Referenced in:
    - core/Debug.lua:743
    - core/Debug.lua:745

- `TWRA:SetDebugLevel()` - Line 567
  - Referenced in:
    - core/Debug.lua:721

- `TWRA:ShowDebugStats()` - Line 599
  - Referenced in:
    - core/Debug.lua:714

- `TWRA:HandleDebugCommand()` - Line 676
  - Referenced in:
    - core/Core.lua:357 (in if )
    - core/Core.lua:358

- `TWRA:InitializeDebug()` - Line 843
  - Referenced in:

### 2.9 core/Events.lua

- `TWRA:RegisterEvent()` - Line 12
  - Referenced in:
    - ui/Minimap.lua:109 (in if )
    - ui/Minimap.lua:112
    - ui/Minimap.lua:152 (in if )
    - ui/Minimap.lua:153
    - ui/Minimap.lua:555 (in if )
    - ui/Minimap.lua:556
    - ui/OSD.lua:28 (in if )
    - ui/OSD.lua:32
    - ui/OSD.lua:84
    - ui/OSD.lua:105
    - ui/EncounterMap.lua:784
    - ui/EncounterMap.lua:1179
    - features/AutoTanks.lua:13
    - sync/Sync.lua:644

- `TWRA:TriggerEvent()` - Line 40
  - Referenced in:
    - core/Utils.lua:216 (in if )
    - core/Utils.lua:217
    - TWRA.lua:94 (in if )
    - TWRA.lua:96
    - TWRA.lua:1061 (in if )
    - TWRA.lua:1063
    - ui/Frame.lua:1010 (in if )
    - ui/Frame.lua:1011

### 2.10 core/LinkClickHandler.lua

- `TWRA:TestTooltip()` - Line 5
  - Referenced in:

- `TWRA:ShowAbilityTooltip()` - Line 61
  - Referenced in:
    - core/LinkClickHandler.lua:189

### 2.11 core/Linking.lua

- `TWRA:SafeHelpers.Find()` - Line 10
  - Referenced in:
    - core/Linking.lua:166 (in if )
    - core/Linking.lua:246 (in if )
    - core/Linking.lua:252 (in if not )

- `TWRA:SafeHelpers.SplitByChar()` - Line 38
  - Referenced in:

- `TWRA:SafeHelpers.ExtractNameAndID()` - Line 58
  - Referenced in:
    - core/AbilityLinks.lua:96 (in local name, id = )

- `TWRA:SafeHelpers.ExtractLinkParts()` - Line 95
  - Referenced in:

- `TWRA:SafeHelpers.CountTableElements()` - Line 118
  - Referenced in:
    - core/Linking.lua:356 (in if )
    - core/Linking.lua:365 (in elseif )

- `TWRA:InitializeLinks()` - Line 128
  - Referenced in:
    - core/Linking.lua:208
    - core/Linking.lua:442

- `TWRA:Links:CreateLink()` - Line 138
  - Referenced in:

- `TWRA:Links:ProcessAllLinks()` - Line 156
  - Referenced in:
    - TWRA.lua:766 (in processedText = )
    - ui/OSD.lua:1442 (in processedText = )
    - ui/OSD.lua:1504 (in announcementText = )
    - ui/OSD.lua:1558 (in processedText = )
    - ui/OSD.lua:1617 (in announcementText = )

- `TWRA:Links:HandleLinkClick()` - Line 190
  - Referenced in:

- `TWRA:Links:DisableLinkHook()` - Line 201
  - Referenced in:

- `TWRA:Items:GetLinkByName()` - Line 216
  - Referenced in:

- `TWRA:Items:ProcessText()` - Line 234
  - Referenced in:
    - TWRA.lua:783 (in processedText = )
    - ui/Frame.lua:1208 (in processedText = )
    - ui/Frame.lua:1269 (in announcementText = )
    - ui/Frame.lua:2047 (in message = )
    - ui/OSD.lua:1448 (in processedText = )
    - ui/OSD.lua:1508 (in announcementText = )
    - ui/OSD.lua:1564 (in processedText = )
    - ui/OSD.lua:1621 (in announcementText = )
    - core/Linking.lua:179 (in result = )

- `TWRA:Items:ProcessConsumables()` - Line 289
  - Referenced in:
    - TWRA.lua:787 (in processedText = )
    - core/Linking.lua:184 (in result = )

- `TWRA:Abilities:DisplayAbilityTooltip()` - Line 332
  - Referenced in:

- `TWRA:Abilities:HandleLink()` - Line 384
  - Referenced in:

### 2.12 core/Utils.lua

- `TWRA:ScheduleTimer()` - Line 4
  - Referenced in:
    - core/Debug.lua:657 (in if )
    - core/Debug.lua:658
    - core/Base64.lua:482
    - Example.lua:744
    - TWRA.lua:810
    - core/Core.lua:771
    - core/DataProcessing.lua:1190
    - core/DataProcessing.lua:1194
    - ui/Frame.lua:1299
    - ui/Frame.lua:1415
    - ui/Minimap.lua:158
    - ui/OSD.lua:237 (in TWRA.OSD.autoHideTimer = )
    - ui/OSD.lua:1264 (in self.OSD.autoHideTimer = )
    - ui/OSD.lua:1275 (in self.encounterMap.hideTimer = )
    - ui/OSD.lua:1526
    - ui/OSD.lua:1629
    - ui/options/Options-Import.lua:333
    - ui/options/Options-Import.lua:415
    - ui/EncounterMap.lua:165 (in TWRA.encounterMap.hideTimer = )
    - ui/EncounterMap.lua:1082 (in self.encounterMap.hideTimer = )
    - ui/EncounterMap.lua:1181
    - features/AutoNavigate.lua:114
    - features/AutoNavigate.lua:129
    - features/AutoNavigate.lua:141
    - sync/SyncHandlers.lua:777
    - sync/SyncHandlers.lua:920
    - sync/SyncHandlers.lua:1087 (in timer = )
    - sync/SyncHandlers.lua:1111
    - sync/SyncHandlers.lua:1120
    - sync/SyncHandlers.lua:1187
    - sync/ChunkManager.lua:332
    - sync/Sync.lua:40
    - sync/Sync.lua:55
    - sync/Sync.lua:310 (in self.SYNC.bulkSyncRequestTimeout = )
    - sync/Sync.lua:490
    - sync/Sync.lua:583
    - sync/Sync.lua:1102
    - sync/Sync.lua:1202
    - sync/Sync.lua:1611

- `TWRA:CancelTimer()` - Line 35
  - Referenced in:
    - ui/OSD.lua:212
    - ui/OSD.lua:1211
    - ui/OSD.lua:1257
    - ui/OSD.lua:1293
    - ui/Options.lua:235
    - ui/EncounterMap.lua:154
    - ui/EncounterMap.lua:1011
    - ui/EncounterMap.lua:1076
    - ui/EncounterMap.lua:1112
    - sync/SyncHandlers.lua:1074
    - sync/SyncHandlers.lua:1168
    - sync/SyncHandlers.lua:1200
    - sync/Sync.lua:307

- `TWRA:SplitString()` - Line 41
  - Referenced in:

- `TWRA:ConvertOptionValues()` - Line 69
  - Referenced in:
    - ui/Frame.lua:1318

- `TWRA:UpdatePlayerTable()` - Line 104
  - Referenced in:
    - TWRA.lua:996
    - core/Core.lua:67 (in return )
    - core/Core.lua:317 (in if )
    - core/Core.lua:319
    - core/Core.lua:801 (in if )
    - core/Core.lua:802

- `TWRA:GetTableSize()` - Line 249
  - Referenced in:
    - core/Debug.lua:903
    - core/Utils.lua:244
    - core/Core.lua:322 (in local playerCount = )
    - features/AutoNavigate.lua:469
    - sync/SyncHandlers.lua:29
    - sync/SyncHandlers.lua:1414
    - sync/SyncHandlers.lua:1421 (in local validMissingCount = )

## 3. Feature Files

### 3.1 features/AutoNavigate.lua

- `TWRA:CheckSuperWoWSupport()` - Line 13
  - Referenced in:
    - features/AutoNavigate.lua:48 (in if not )
    - features/AutoNavigate.lua:159 (in local hasSupport = )
    - features/AutoNavigate.lua:492 (in if not )

- `TWRA:CheckSkullMarkedMob()` - Line 36
  - Referenced in:
    - TWRA.lua:257 (in if )
    - TWRA.lua:259

- `TWRA:RegisterAutoNavigateEvents()` - Line 102
  - Referenced in:
    - features/AutoNavigate.lua:526

- `TWRA:InitializeAutoNavigate()` - Line 150
  - Referenced in:
    - TWRA.lua:264 (in if )
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
    - core/Debug.lua:766 (in if )
    - core/Debug.lua:767

- `TWRA:ExtractGuidFromString()` - Line 411
  - Referenced in:
    - features/AutoNavigate.lua:396 (in local extractedGuid = )
    - features/AutoNavigate.lua:454 (in local extractedGuid = )

- `TWRA:ListAllGuids()` - Line 421
  - Referenced in:

- `TWRA:GetCurrentTargetGuid()` - Line 490
  - Referenced in:
    - core/Core.lua:434 (in if )
    - core/Core.lua:435

### 3.2 features/AutoTanks.lua

- `TWRA:InitializeTankSync()` - Line 2
  - Referenced in:
    - ui/Options.lua:322
    - ui/Options.lua:323
    - ui/options/Options-General.lua:510 (in if )
    - ui/options/Options-General.lua:511
    - sync/Sync.lua:468 (in if self.SYNC.tankSync and )
    - sync/Sync.lua:470

- `TWRA:IsORA2Available()` - Line 31
  - Referenced in:
    - ui/Options.lua:291 (in if )
    - features/AutoTanks.lua:164 (in if not )

- `TWRA:IsPfUIAvailable()` - Line 35
  - Referenced in:
    - ui/Options.lua:307 (in if )

- `TWRA:UpdateTanks()` - Line 39
  - Referenced in:
    - ui/Frame.lua:177
    - ui/options/Options-General.lua:514
    - features/AutoTanks.lua:17
    - features/AutoTanks.lua:24

- `TWRA:UpdateORA2Tanks()` - Line 162
  - Referenced in:
    - features/AutoTanks.lua:151

- `TWRA:UpdatePfUITanks()` - Line 193
  - Referenced in:
    - features/AutoTanks.lua:156

## 4. UI Files

### 4.1 ui/EncounterMap.lua

- `TWRA:InitEncounterMap()` - Line 5
  - Referenced in:
    - core/Core.lua:310 (in if )
    - core/Core.lua:312
    - ui/EncounterMap.lua:1128

- `TWRA:GetEncounterMapFrame()` - Line 46
  - Referenced in:
    - ui/EncounterMap.lua:397 (in local mainFrame = )
    - ui/EncounterMap.lua:616 (in local frame = )
    - ui/EncounterMap.lua:651 (in local frame = )
    - ui/EncounterMap.lua:997 (in local frame = )

- `TWRA:UpdateEncounterMapSettings()` - Line 364
  - Referenced in:

- `TWRA:CreateTextureFrame()` - Line 390
  - Referenced in:
    - ui/EncounterMap.lua:453 (in local textureFrame = )
    - ui/EncounterMap.lua:624
    - ui/EncounterMap.lua:634
    - ui/EncounterMap.lua:640

- `TWRA:LoadCurrentImage()` - Line 425
  - Referenced in:
    - ui/EncounterMap.lua:580
    - ui/EncounterMap.lua:604
    - ui/EncounterMap.lua:684 (in local success = )

- `TWRA:UpdateTextureAspectRatio()` - Line 496
  - Referenced in:
    - ui/EncounterMap.lua:307
    - ui/EncounterMap.lua:318
    - ui/EncounterMap.lua:491

- `TWRA:NavigateToPreviousImage()` - Line 563
  - Referenced in:
    - ui/EncounterMap.lua:766

- `TWRA:NavigateToNextImage()` - Line 585
  - Referenced in:
    - ui/EncounterMap.lua:773

- `TWRA:PreloadMapTextures()` - Line 609
  - Referenced in:
    - ui/EncounterMap.lua:1182

- `TWRA:UpdateEncounterMapContent()` - Line 650
  - Referenced in:
    - ui/EncounterMap.lua:803
    - ui/EncounterMap.lua:1004
    - ui/EncounterMap.lua:1175

- `TWRA:UpdateEncounterMapNavigation()` - Line 719
  - Referenced in:
    - ui/EncounterMap.lua:488
    - ui/EncounterMap.lua:693

- `TWRA:RegisterEncounterMapEvents()` - Line 782
  - Referenced in:
    - ui/EncounterMap.lua:39

- `TWRA:GetEncounterMapPath()` - Line 818
  - Referenced in:
    - ui/EncounterMap.lua:681 (in local mapPath = )

- `TWRA:HasEncounterMapImage()` - Line 895
  - Referenced in:
    - ui/EncounterMap.lua:792 (in local hasImage = currentSection and )
    - ui/EncounterMap.lua:991 (in if not currentSection or not )
    - ui/EncounterMap.lua:1037 (in if not currentSection or not )
    - ui/EncounterMap.lua:1058 (in if not currentSection or not )

- `TWRA:SectionHasEncounterMapImage()` - Line 928
  - Referenced in:
    - TWRA.lua:1037 (in if )
    - ui/Frame.lua:677 (in if )
    - ui/Frame.lua:999 (in if )
    - ui/OSD.lua:60 (in if )
    - ui/OSD.lua:287 (in if )

- `TWRA:ShowEncounterMap()` - Line 977
  - Referenced in:
    - ui/OSD.lua:1272
    - ui/EncounterMap.lua:809
    - ui/EncounterMap.lua:1042 (in return )
    - ui/EncounterMap.lua:1069 (in local result = )

- `TWRA:ShowEncounterMapPermanent()` - Line 1030
  - Referenced in:
    - ui/OSD.lua:1225
    - ui/EncounterMap.lua:1136
    - ui/EncounterMap.lua:1193

- `TWRA:ShowEncounterMapTemp()` - Line 1045
  - Referenced in:
    - ui/Frame.lua:504 (in if )
    - ui/Frame.lua:505
    - ui/OSD.lua:305 (in if )
    - ui/OSD.lua:306

- `TWRA:HideEncounterMap()` - Line 1097
  - Referenced in:
    - ui/Frame.lua:513 (in if )
    - ui/Frame.lua:514
    - ui/OSD.lua:315 (in if )
    - ui/OSD.lua:316
    - ui/OSD.lua:1276
    - ui/OSD.lua:1313
    - ui/EncounterMap.lua:109
    - ui/EncounterMap.lua:167
    - ui/EncounterMap.lua:383
    - ui/EncounterMap.lua:799
    - ui/EncounterMap.lua:1086
    - ui/EncounterMap.lua:1133
    - ui/EncounterMap.lua:1191

- `TWRA:ToggleEncounterMap()` - Line 1125
  - Referenced in:
    - ui/Frame.lua:520 (in if )
    - ui/Frame.lua:521
    - ui/OSD.lua:322 (in if )
    - ui/OSD.lua:323
    - ui/EncounterMap.lua:1189

- `TWRA:ResetEncounterMapPosition()` - Line 1143
  - Referenced in:
    - ui/EncounterMap.lua:1195

- `TWRA:OnSectionChanged()` - Line 1171
  - Referenced in:

### 4.2 ui/Frame.lua

- `TWRA:IsExampleData()` - Line 5
  - Referenced in:
    - Example.lua:817 (in function )
    - Example.lua:818 (in self:Debug("error", ")
    - TWRA.lua:495 (in function )
    - ui/Frame.lua:6 (in self:Debug("error", " )

- `TWRA:CloseDropdownMenu()` - Line 12
  - Referenced in:
    - ui/Frame.lua:118 (in --     )
    - ui/Frame.lua:163
    - ui/Frame.lua:176
    - ui/Frame.lua:194
    - ui/Frame.lua:206

- `TWRA:SafeToString()` - Line 23
  - Referenced in:
    - core/Linking.lua:148 (in linkType = )
    - core/Linking.lua:149 (in linkData = )
    - core/Linking.lua:150 (in displayText = )
    - core/Linking.lua:162 (in return )
    - core/Linking.lua:222
    - core/Linking.lua:231
    - core/Linking.lua:241 (in return )
    - core/Linking.lua:258 (in return "[" .. )
    - core/Linking.lua:267 (in return "[" .. )
    - core/Linking.lua:295 (in return )
    - core/Linking.lua:339
    - core/Linking.lua:427

- `TWRA:CreateMainFrame()` - Line 35
  - Referenced in:
    - Example.lua:527
    - Example.lua:597
    - core/Core.lua:287 (in if not TWRA.mainFrame and )
    - core/Core.lua:288
    - core/Core.lua:493
    - core/Core.lua:534 (in if )
    - core/Core.lua:535
    - ui/Minimap.lua:367 (in if not TWRA.mainFrame and )
    - ui/Minimap.lua:368
    - ui/Minimap.lua:393 (in if )
    - ui/Minimap.lua:394
    - ui/Minimap.lua:534 (in if )
    - ui/Minimap.lua:535

- `TWRA:LoadInitialContent()` - Line 568
  - Referenced in:
    - core/Core.lua:542 (in if )
    - core/Core.lua:543
    - core/Core.lua:558 (in if )
    - core/Core.lua:559

- `TWRA:ShowMainView()` - Line 613
  - Referenced in:
    - core/Base64.lua:466 (in if )
    - core/Base64.lua:468
    - Example.lua:532
    - Example.lua:713
    - ui/Frame.lua:140
    - ui/Minimap.lua:407 (in if )
    - ui/Minimap.lua:408
    - ui/Minimap.lua:547 (in if )
    - ui/Minimap.lua:548
    - ui/options/Options-Import.lua:328 (in if )
    - ui/options/Options-Import.lua:330
    - ui/options/Options-Import.lua:336 (in if )
    - ui/options/Options-Import.lua:337

- `TWRA:FilterAndDisplayHandler()` - Line 728
  - Referenced in:
    - Example.lua:429 (in if )
    - Example.lua:430
    - Example.lua:664 (in if )
    - Example.lua:666
    - Example.lua:789 (in if )
    - Example.lua:791
    - TWRA.lua:89 (in if )
    - TWRA.lua:90
    - TWRA.lua:1009 (in if )
    - TWRA.lua:1011
    - TWRA.lua:1052
    - core/DataProcessing.lua:424 (in self.currentView == "main" and )
    - core/DataProcessing.lua:425
    - core/DataProcessing.lua:1130 (in self.currentView == "main" and )
    - core/DataProcessing.lua:1131
    - core/DataUtility.lua:119
    - ui/Frame.lua:607
    - ui/Frame.lua:693
    - ui/Frame.lua:699
    - ui/Frame.lua:1339

- `TWRA:CreateFootersNewFormat()` - Line 1017
  - Referenced in:
    - ui/Frame.lua:994

- `TWRA:ClearFooters()` - Line 1125
  - Referenced in:
    - TWRA.lua:955
    - ui/Frame.lua:595
    - ui/Frame.lua:658
    - ui/Frame.lua:761
    - ui/Frame.lua:1019
    - ui/Frame.lua:1654

- `TWRA:CreateFooterElement()` - Line 1175
  - Referenced in:
    - ui/Frame.lua:1098 (in local footer = )
    - ui/Frame.lua:1106 (in local footer = )

- `TWRA:RefreshAssignmentTable()` - Line 1320
  - Referenced in:
    - core/Utils.lua:223 (in if )
    - core/Utils.lua:225
    - Example.lua:435 (in if )
    - Example.lua:436
    - Example.lua:670 (in if )
    - Example.lua:671
    - Example.lua:736 (in if )
    - Example.lua:737
    - Example.lua:797 (in if )
    - Example.lua:798
    - sync/SyncHandlers.lua:761 (in if )
    - sync/SyncHandlers.lua:762
    - sync/SyncHandlers.lua:779 (in if )
    - sync/SyncHandlers.lua:780

- `TWRA:CreateRow()` - Line 1342
  - Referenced in:
    - ui/Frame.lua:1590 (in self.rowFrames[i] = )

- `TWRA:CreateRows()` - Line 1578
  - Referenced in:
    - ui/Frame.lua:988

- `TWRA:ClearRows()` - Line 1596
  - Referenced in:
    - TWRA.lua:956
    - ui/Frame.lua:594
    - ui/Frame.lua:657
    - ui/Frame.lua:760

- `TWRA:ApplyRowHighlights()` - Line 1659
  - Referenced in:
    - ui/Frame.lua:991

- `TWRA:CreateHeaderCell()` - Line 1775
  - Referenced in:
    - ui/Frame.lua:1468 (in cell = )
    - ui/Frame.lua:1486 (in cell = )
    - ui/Frame.lua:1498 (in cell = )

- `TWRA:CalculateColumnWidths()` - Line 1820
  - Referenced in:
    - ui/Frame.lua:959 (in self.dynamicColumnWidths = )

- `TWRA:CreateRowMouseoverHighlight()` - Line 1897
  - Referenced in:
    - ui/Frame.lua:1363 (in local mouseoverHighlight = )

- `TWRA:FormatRowAnnouncement()` - Line 1910
  - Referenced in:
    - ui/Frame.lua:1392 (in local message = )

- `TWRA:ResetFramePosition()` - Line 2054
  - Referenced in:
    - core/Core.lua:445 (in if )
    - core/Core.lua:446

### 4.3 ui/Minimap.lua

- `TWRA:DestroyMinimapButton()` - Line 12
  - Referenced in:

- `TWRA:InitializeMinimapButton()` - Line 68
  - Referenced in:
    - ui/Minimap.lua:178

- `TWRA:CreateMinimapButton()` - Line 191
  - Referenced in:
    - core/Core.lua:162
    - core/Core.lua:266
    - core/Core.lua:297 (in if not TWRA.minimapButton and )
    - core/Core.lua:299
    - ui/Minimap.lua:100 (in local success = )

- `TWRA:CreateMinimapDropdown()` - Line 611
  - Referenced in:
    - ui/Minimap.lua:254

### 4.4 ui/OSD.lua

- `TWRA:InitOSD()` - Line 6
  - Referenced in:
    - TWRA.lua:269 (in if )
    - core/Core.lua:304 (in if )
    - core/Core.lua:306
    - ui/OSD.lua:1322
    - ui/OSD.lua:1347
    - ui/Options.lua:60 (in if )
    - ui/Options.lua:61

- `TWRA:GetOSDFrame()` - Line 132
  - Referenced in:
    - ui/OSD.lua:1135 (in local frame = )
    - ui/OSD.lua:1200 (in local frame = )
    - ui/OSD.lua:1246 (in local frame = )

- `TWRA:UpdateOSDSettings()` - Line 372
  - Referenced in:
    - ui/options/Options-OSD.lua:260 (in if )
    - ui/options/Options-OSD.lua:261
    - ui/options/Options-OSD.lua:307 (in if )
    - ui/options/Options-OSD.lua:308
    - ui/options/Options-OSD.lua:319 (in if )
    - ui/options/Options-OSD.lua:320

- `TWRA:CreateRowBaseElements()` - Line 398
  - Referenced in:
    - ui/OSD.lua:484
    - ui/OSD.lua:1020 (in local roleIcon, roleFontString = )

- `TWRA:CreateAssignmentRow()` - Line 482
  - Referenced in:
    - ui/OSD.lua:954 (in local rowWidth = )

- `TWRA:AddTargetDisplay()` - Line 779
  - Referenced in:
    - ui/OSD.lua:621 (in rowWidth = rowWidth + )
    - ui/OSD.lua:626 (in rowWidth = rowWidth + )

- `TWRA:GetIconInfo()` - Line 813
  - Referenced in:
    - ui/OSD.lua:633 (in local iconInfo = )
    - ui/OSD.lua:783 (in local iconInfo = )

- `TWRA:GetRoleIcon()` - Line 817
  - Referenced in:
    - ui/OSD.lua:403 (in local iconPath = )

- `TWRA:CreateContent()` - Line 844
  - Referenced in:
    - ui/OSD.lua:345
    - ui/OSD.lua:1163

- `TWRA:CreateDefaultContent()` - Line 991
  - Referenced in:
    - ui/OSD.lua:876 (in return )
    - ui/OSD.lua:883 (in return )
    - ui/OSD.lua:902 (in return )

- `TWRA:CreateWarnings()` - Line 1045
  - Referenced in:
    - ui/OSD.lua:353
    - ui/OSD.lua:1169

- `TWRA:UpdateOSDContent()` - Line 1131
  - Referenced in:
    - core/Utils.lua:232 (in if )
    - core/Utils.lua:239
    - core/DataProcessing.lua:397 (in if )
    - core/DataProcessing.lua:398
    - core/DataProcessing.lua:431
    - core/DataProcessing.lua:1137
    - core/DataUtility.lua:127
    - ui/OSD.lua:47
    - ui/OSD.lua:56
    - ui/OSD.lua:99
    - ui/OSD.lua:122
    - ui/options/Options-OSD.lua:108
    - ui/options/Options-OSD.lua:203 (in if self.OSD and self.OSD.isVisible and )
    - ui/options/Options-OSD.lua:208
    - ui/options/Options-Import.lua:323 (in if self.OSD and self.OSD.isVisible and )
    - ui/options/Options-Import.lua:324

- `TWRA:ShowOSDPermanent()` - Line 1186
  - Referenced in:
    - Bindings.xml:25
    - ui/Minimap.lua:353 (in if )
    - ui/Minimap.lua:354
    - ui/OSD.lua:1338
    - ui/OSD.lua:1351

- `TWRA:ShowOSD()` - Line 1232
  - Referenced in:
    - ui/Minimap.lua:263 (in if )
    - ui/Minimap.lua:265
    - ui/Minimap.lua:328 (in if )
    - ui/Minimap.lua:329
    - ui/Minimap.lua:355 (in elseif )
    - ui/Minimap.lua:356
    - ui/Minimap.lua:436 (in if )
    - ui/Minimap.lua:437
    - ui/Minimap.lua:448 (in if )
    - ui/Minimap.lua:449
    - ui/Minimap.lua:790 (in if not miniButton.osdWasShown and )
    - ui/Minimap.lua:791
    - ui/OSD.lua:78

- `TWRA:HideOSD()` - Line 1290
  - Referenced in:
    - Bindings.xml:27
    - Example.lua:732
    - core/Core.lua:390 (in if )
    - core/Core.lua:391
    - ui/Minimap.lua:347 (in if )
    - ui/Minimap.lua:348
    - ui/OSD.lua:168
    - ui/OSD.lua:241
    - ui/OSD.lua:391
    - ui/OSD.lua:1265
    - ui/OSD.lua:1336
    - ui/OSD.lua:1362

- `TWRA:ToggleOSD()` - Line 1319
  - Referenced in:
    - Bindings.xml:31 (in if TWRA and )
    - core/Core.lua:414 (in if )
    - core/Core.lua:415 (in local visible = )
    - ui/OSD.lua:1364
    - ui/options/Options-OSD.lua:95 (in local isVisible = )

- `TWRA:TestOSDVisual()` - Line 1344
  - Referenced in:
    - ui/OSD.lua:1360

- `TWRA:ShouldShowOSD()` - Line 1368
  - Referenced in:
    - ui/OSD.lua:72 (in if )

- `TWRA:ResetOSDPosition()` - Line 1394
  - Referenced in:
    - core/Core.lua:372 (in if )
    - core/Core.lua:373
    - ui/options/Options-OSD.lua:314 (in if )
    - ui/options/Options-OSD.lua:315

- `TWRA:CreateWarningRow()` - Line 1422
  - Referenced in:
    - ui/OSD.lua:1107 (in local rowHeight = )

- `TWRA:CreateNoteRow()` - Line 1538
  - Referenced in:
    - ui/OSD.lua:1114 (in local rowHeight = )

### 4.5 ui/Options.lua

- `TWRA:InitOptions()` - Line 5
  - Referenced in:
    - core/Core.lua:206 (in if )
    - core/Core.lua:208

- `TWRA:UpdateSliderState()` - Line 74
  - Referenced in:

- `TWRA:CreateCheckbox()` - Line 92
  - Referenced in:
    - ui/options/Options-General.lua:240 (in local liveSync, liveSyncText = )
    - ui/options/Options-General.lua:251 (in local oRA2TankSync, oRA2TankSyncText = )
    - ui/options/Options-General.lua:256 (in local pfUITankSync, pfUITankSyncText = )
    - ui/options/Options-General.lua:277 (in local autoNavigate, autoNavigateText = )
    - ui/options/Options-OSD.lua:29
    - ui/options/Options-OSD.lua:50 (in local showOnNavOSD, showOnNavOSDText = )
    - ui/options/Options-OSD.lua:55 (in local lockOSD, lockOSDText = )

- `TWRA:LoadOptionsComponents()` - Line 109
  - Referenced in:
    - ui/Options.lua:68

- `TWRA:CreateOptionsInMainFrame()` - Line 140
  - Referenced in:
    - TWRA.lua:894

- `TWRA:RestartAutoNavigateTimer()` - Line 223
  - Referenced in:

- `TWRA:ApplyInitialSettings()` - Line 250
  - Referenced in:
    - ui/Options.lua:65

### 4.6 ui/UIUtils.lua

- `TWRA:UI:ApplyClassColoring()` - Line 5
  - Referenced in:
    - ui/Frame.lua:1535
    - ui/OSD.lua:557
    - ui/OSD.lua:724

- `TWRA:UI:CreateIconWithTooltip()` - Line 51
  - Referenced in:
    - ui/options/Options-General.lua:224 (in local channelIcon, channelIconFrame = )
    - ui/options/Options-General.lua:261
    - ui/options/Options-General.lua:282 (in local autoNavIcon, autoNavIconFrame = )
    - ui/options/Options-OSD.lua:34 (in local notesIcon, notesIconFrame = )

### 4.7 ui/options/Options-General.lua

- `TWRA:LoadOptionsGeneral()` - Line 5
  - Referenced in:
    - ui/Options.lua:116 (in if )
    - ui/Options.lua:117

- `TWRA:CreateOptionsGeneralColumn()` - Line 19
  - Referenced in:
    - ui/Options.lua:215
    - ui/options/Options-General.lua:15 (in create = function(column) return )

### 4.8 ui/options/Options-Import.lua

- `TWRA:LoadOptionsImport()` - Line 5
  - Referenced in:
    - ui/Options.lua:132 (in if )
    - ui/Options.lua:133

- `TWRA:DirectImport()` - Line 19
  - Referenced in:
    - ui/options/Options-Import.lua:240 (in local success = )

- `TWRA:CreateOptionsImportColumn()` - Line 160
  - Referenced in:
    - ui/Options.lua:217
    - ui/options/Options-Import.lua:15 (in create = function(column) return )

### 4.9 ui/options/Options-OSD.lua

- `TWRA:LoadOptionsOSD()` - Line 5
  - Referenced in:
    - ui/Options.lua:124 (in if )
    - ui/Options.lua:125

- `TWRA:CreateOptionsOSDColumn()` - Line 19
  - Referenced in:
    - ui/Options.lua:216
    - ui/options/Options-OSD.lua:15 (in create = function(column) return )

## 5. Duplicate Functions

- `TWRA:OnGroupChanged()` is defined in multiple locations:
  - TWRA.lua:987
  - core/Core.lua:755

- `TWRA:OnChatMsgAddon()` is defined in multiple locations:
  - TWRA.lua:415
  - sync/Sync.lua:351

- `TWRA:IsExampleData()` is defined in multiple locations:
  - Example.lua:817
  - TWRA.lua:495
  - ui/Frame.lua:5

- `TWRA:DecompressAssignmentsData()` is defined in multiple locations:
  - core/Base64.lua:132
  - core/Compression.lua:651

- `TWRA:CreateVersionMessage()` is defined in multiple locations:
  - sync/SyncHandlers.lua:1353
  - sync/Sync.lua:184

- `TWRA:ProcessImportedData()` is defined in multiple locations:
  - core/DataProcessing.lua:1323
  - core/DataUtility.lua:517

- `TWRA:DisplayCurrentSection()` is defined in multiple locations:
  - TWRA.lua:1027
  - core/DataUtility.lua:112

