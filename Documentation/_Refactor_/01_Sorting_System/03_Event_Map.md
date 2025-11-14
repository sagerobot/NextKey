# Refactor Event Map: 01_Sorting_System

## 1. Module Type: Service (On-Demand Logic Provider)

The Sorting System is classified as a **Service Module**. Its primary purpose is to provide data and functionality to other modules when they request it. It is a passive provider of logic, not an active announcer of state changes.

## 2. Communication Pattern: Direct API Calls

Based on its role as a service, the primary method of interaction with this module will be through **direct, one-way API calls**.

-   **Consumer -> Service:** A consumer (e.g., `ui/organizer.lua`) will directly call the public methods of the service (e.g., `NextKey.Sorting:GetAlgorithmsForContext(...)`).
-   **Service -> Consumer:** The service will **return** a value to the consumer. It will **not** initiate communication with the consumer.

This creates a healthy, one-way dependency. The UI knows about the Sorting Service, but the Sorting Service has zero knowledge of any UI or feature modules.

## 3. `AceEvent-3.0` Usage: Intentional Non-Use

The `AceEvent-3.0` pub/sub system is a powerful tool for decoupling modules that need to react to state changes without being directly linked. However, it is not the appropriate tool for this module's primary function.

-   **Events Fired:** The Sorting System **will not** fire any events. Its state (the registry of algorithms) is expected to be static after the addon's load process. It has no state changes to announce.
-   **Events Listened For:** The Sorting System **will not** listen for any events. It is self-contained and does not need to react to changes in other parts of the addon.

## 4. Rationale

This design choice is intentional. Using direct API calls for a service module is a cleaner, more readable, and more efficient pattern than forcing it into a pub/sub model.

-   **Clarity:** A direct call like `NextKey.Sorting:GetAlgorithmsForContext(...)` is self-documenting. It's clear what is being requested and from where.
-   **Simplicity:** It avoids the overhead of creating, sending, and registering for messages that are not necessary for this type of on-demand data retrieval.
-   **Performance:** For synchronous, on-demand requests, a direct function call is more performant than the message-passing alternative.

This approach aligns with the overall architectural goal of using the right tool for the job: `AceEvent-3.0` for decoupling features, and clean, one-way APIs for foundational services.
