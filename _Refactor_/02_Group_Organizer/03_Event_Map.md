# Refactor Event Map: 02_Group_Organizer

## 1. Module Type: Feature (Stateful, Decoupled Component)

The Group Organizer is classified as a **Feature Module**. Its purpose is to provide a user-facing feature that has its own internal state, UI, and core logic. It is an active component that needs to communicate changes to other parts of the system without being tightly coupled to them.

## 2. Communication Pattern: `AceEvent-3.0` (Publish/Subscribe)

Based on its role as a feature, the primary method of communication between the Group Organizer's core logic and its UI (and any other potential features) will be the **`AceEvent-3.0` Publish/Subscribe system**.

-   **Publisher:** The core logic module (`core/organizer/state.lua`) will act as the publisher. It will announce changes to its state.
-   **Subscriber:** The UI module (`ui/organizer/rosterBoard.lua`) will act as a subscriber. It will listen for state change announcements and react accordingly.

This enforces the one-way data flow that is central to the addon's refactored architecture.

## 3. Events Published by this Module

---

### `ORGANIZER_ROSTER_UPDATED`

-   **Fired By:** `core/organizer/state.lua`
-   **When:** Fired any time the group roster's data is modified (e.g., players added/removed, data updated, list re-sorted).
-   **Payload:**
    -   `arg1` (table): The complete, authoritative table representing the new state of the group roster.
-   **Purpose:** To inform any interested module that the roster has changed and provide the new data, enabling UI updates or other reactions without requiring the consumer to fetch the data itself.

---

## 4. Events Listened For by this Module

The core logic of the Group Organizer may listen for events from other systems in the future, but for the scope of this specific UI/core decoupling refactor, it does not need to listen for any new events. The UI will listen for the event defined above.
