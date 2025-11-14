# Refactor Goals: 02_Group_Organizer

## 1. Primary Goal: Decouple UI from Core Logic

The main objective is to refactor the Group Organizer to operate as a **Feature Module**. This means its internal components, specifically the UI and the core state management, must be fully decoupled from each other.

-   **From:** The UI (`ui/organizer/rosterBoard.lua`) directly calls functions in the core state module (`core/organizer/state.lua`) to pull data. This creates a tight, two-way dependency.
-   **To:** The UI will become a passive listener. The core logic will become an independent announcer of state. They will communicate exclusively through `AceEvent-3.0`, establishing a clean, one-way data flow.

## 2. Desired Outcome

-   **Core Logic as the "Single Source of Truth":** The `core/organizer/state.lua` module will be solely responsible for managing the roster data. It will not have any knowledge of the UI or any other module that might consume its data.
-   **UI as a "Dumb" Renderer:** The `ui/organizer/rosterBoard.lua` module will be responsible only for rendering the data it is given. It will not contain any logic for fetching or managing state. It will simply listen for state change announcements and redraw itself accordingly.
-   **Improved Modularity:** By breaking the direct link, both the core and UI components become more independent and easier to maintain or replace in the future.
-   **Adherence to Architecture:** This refactor will align the Group Organizer with the established architectural pattern for "Feature Modules" in the addon.
