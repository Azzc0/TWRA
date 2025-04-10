# TWRA Sync Testing Plan

## Phase 3 Tests: Navigation Synchronization

### Test 1: Timestamp Comparison Logic
**Objective**: Verify that clients properly compare timestamps and request newer data when needed.

**Steps**:
1. Set up two clients with different data timestamps
   - Client A: Import data with timestamp 1000
   - Client B: Import data with timestamp 2000
2. Have Client A navigate to a section
3. Have Client B navigate to a section

**Expected Results**:
- Client A should request newer data from Client B when receiving section change
- Client A should not navigate immediately but wait for data sync
- Client B should ignore section changes from Client A (older timestamp)

### Test 2: Data Request/Response Flow
**Objective**: Verify the complete flow from section change to data request to data response.

**Steps**:
1. Set up two clients with different data versions
2. Navigate to a section on the client with newer data
3. Monitor the message flow between clients

**Expected Results**:
- Section change broadcast sent from newer client
- Data request sent from older client
- Data response sent from newer client
- Older client updates its data and navigates to the correct section

## Phase 4 Tests: Data Synchronization

### Test 3: Import Broadcasting
**Objective**: Verify that manual imports are properly broadcast to group members.

**Steps**:
1. Form a group with multiple clients
2. Import new data on one client
3. Monitor all clients for data updates

**Expected Results**:
- Import announcement broadcast sent
- Other clients request the data
- Data successfully shared and imported on all clients

### Test 4: Large Data Handling
**Objective**: Test synchronization with larger datasets to identify any limitations.

**Steps**:
1. Create a large dataset with multiple sections
2. Import on one client and test sync to other clients

**Expected Results**:
- Data successfully transfers regardless of size
- No message truncation or corruption

### Test 5: Edge Cases
**Objective**: Verify proper handling of edge cases.

**Scenarios to Test**:
- Group members joining during sync
- Group members leaving during sync
- Simultaneous imports from different clients
- Network disruptions during sync

## Testing Tools
- Use `/syncmon` to monitor all addon communication
- Record logs for later analysis
- Test in different group sizes (2-person party, 5-person party, raid)
