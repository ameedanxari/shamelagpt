# Manual Testing Guide for Chat Flow Issues

## Prerequisites
1. Build and run the app on simulator: `cd shamelagpt-ios && xcodebuild -scheme ShamelaGPT -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.6'`
2. Open Console.app on your Mac
3. Filter for "ShamelaGPT" process

## Test Scenario: Send a Message

### Steps:
1. Launch the app
2. Skip or complete welcome screen
3. Navigate to Chat tab (should be default)
4. Type a message: "What is Islam?"
5. Tap Send button
6. **Observe the behavior**

### Expected Behavior:
- Message appears immediately in chat (optimistic UI)
- Loading indicator shows briefly
- Assistant response appears
- Conversation appears in History tab
- Messages persist after app restart

### What to Look For:

#### In the App UI:
- [ ] Does the message appear after tapping Send?
- [ ] Does it stay visible or disappear?
- [ ] Does the chat screen stay open or close/navigate away?
- [ ] Is there a loading indicator?
- [ ] Does an assistant response appear?
- [ ] Does the conversation appear in History tab?

#### In Console Logs:

**Filter the Console.app with:** `subsystem:com.shamelagpt.ios category:Chat OR category:App OR category:Database`

Look for these key log entries in order:

1. **Message Send Initiated:**
```
[Chat] Sending message: 'What is Islam?...' in conversation: <UUID>
[Chat] Added optimistic user message to UI - Total messages now: 1
[Chat] Current messages array: ["temp-<UUID>: What is Islam?..."]
```

2. **Conversation Validation:**
```
[Chat] Conversation exists: <UUID>
```

3. **Message Sent Successfully:**
```
[Chat] Message sent successfully, thread ID: <thread_id>
```

4. **Messages Reloaded:**
```
[Chat] Loading messages for conversation: <UUID>
[Chat] Current message count before load: 1
[Database] Fetching messages by ID: <UUID>
[Chat] Fetched X messages from repository
[Chat] Has optimistic messages: true, isLoading: true
[Chat] Merged messages: X total (Y from DB, Z optimistic)
[Chat] Final messages array: [...]
[Chat] Message count after load: X
```

5. **History Update:**
```
[App] HistoryViewModel received X conversations from observer
[App] Conversation <UUID> has X messages - INCLUDED
[App] HistoryViewModel filtered to X conversations
```

### Critical Issues to Watch For:

#### Issue 1: Messages Array Becomes Empty
If you see logs like:
```
[Chat] Current message count before load: 1
[Chat] Fetched 0 messages from repository
[Chat] Message count after load: 0
```

**This means:** Messages aren't being saved to CoreData properly.

#### Issue 2: Conversation Filtered from History
If you see:
```
[App] Conversation <UUID> is empty, age: Xs - FILTERED (old)
```

**This means:** The conversation is being filtered out by HistoryViewModel.

#### Issue 3: Optimistic Message Not Merged
If you see:
```
[Chat] Skipping reload - preserving 1 messages, fetch returned 0
```

**This means:** Our merge logic is preventing the reload, but DB has no messages.

#### Issue 4: Conversation Validation Issues
If you see:
```
[App] validateCurrentConversation called - current ID: nil
[App] No current conversation ID, calling ensureConversationExists
```

**This means:** The conversation ID is being lost.

## Test Scenario: Check History

### Steps:
1. After sending a message (previous test)
2. Switch to History tab
3. **Observe the behavior**

### Expected Behavior:
- Conversation appears in the list
- Shows preview of last message
- Shows timestamp

### What to Look For in Console:

```
[App] HistoryViewModel received X conversations from observer
[App] Conversation <UUID> has X messages - INCLUDED
[App] HistoryViewModel filtered to X conversations
```

If the conversation doesn't appear, check for:
```
[App] Conversation <UUID> is empty, age: Xs - FILTERED (old)
```

## Test Scenario: App Restart

### Steps:
1. Send a message and verify it appears
2. Kill the app (swipe up from app switcher)
3. Relaunch the app
4. Navigate to Chat tab or History tab
5. **Check if the conversation and messages are still there**

### Expected Behavior:
- Previous conversation should load
- Messages should be visible
- Can continue the conversation

### What to Look For in Console:

```
[App] Ensuring conversation exists for chat tab
[Database] Fetching most recent empty conversation
[Database] No empty conversations found
[App] No empty conversation found, creating new one
```

**OR**

```
[App] Ensuring conversation exists for chat tab
[Database] Fetching most recent empty conversation
[Database] Found empty conversation: <UUID>
[App] Reusing existing empty conversation: <UUID>
```

Then:
```
[Chat] Loading messages for conversation: <UUID>
[Chat] Fetched X messages from repository
[Chat] Loaded X messages
```

## Collecting Logs for Analysis

### Option 1: Console.app (Real-time)
1. Open Console.app
2. Select your simulator device
3. Filter: `subsystem:com.shamelagpt.ios`
4. Perform the test
5. Right-click on logs → Save Selected Messages
6. Send the log file

### Option 2: Command Line
```bash
# Start logging before running the test
xcrun simctl spawn booted log stream --predicate 'subsystem == "com.shamelagpt.ios"' --level debug > shamelagpt_test_logs.txt

# Run your manual test in the simulator

# Stop logging with Ctrl+C
# Send shamelagpt_test_logs.txt
```

### Option 3: Xcode Console
1. Run the app from Xcode (Cmd+R)
2. Perform the test
3. Copy console output from Xcode's console pane
4. Send the text

## Quick Diagnostic Checklist

Run through this checklist and note any failures:

- [ ] App launches successfully
- [ ] Welcome screen appears (first launch)
- [ ] Chat tab is accessible
- [ ] Can type in the text field
- [ ] Send button becomes enabled when typing
- [ ] Send button tap is registered
- [ ] Message appears in chat view (even briefly)
- [ ] Message stays visible (doesn't disappear)
- [ ] Loading indicator appears
- [ ] Chat view stays open (doesn't navigate away)
- [ ] Assistant response appears
- [ ] Conversation appears in History tab
- [ ] Messages persist after switching tabs
- [ ] Messages persist after app restart

## What to Report

Please provide:
1. **Checklist results** (which items failed)
2. **Detailed description** of what you see happening
3. **Console logs** from one of the options above
4. **Screenshots or screen recording** if possible

This will help diagnose exactly where the flow is breaking!
