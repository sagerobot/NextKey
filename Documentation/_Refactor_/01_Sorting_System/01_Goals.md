# Refactor Goals: 01_Sorting_System

## 1. Objective

To create a centralized, independent, and extensible sorting service module. This module will manage all sorting algorithms for the addon, removing duplicated logic from individual UI components and establishing a single source of truth for sorting functionality.

## 2. Core Principles

- **Decoupling:** The Sorting System must be a standalone service. It shall have no direct dependencies on any UI or other feature-specific modules. Its purpose is to serve logic, not to be aware of its consumers.
- **Centralization:** All sorting-related logic will be consolidated into this module. Existing sorting code within the Main Window or Organizer features will be removed and replaced with calls to this new service.
- **Extensibility ("Pluggable"):** The system must be designed to allow for the easy addition of new sorting algorithms without requiring modification of the core sorting service or its consumers.

## 3. Key Requirements

- **Algorithm Registry:** The module must maintain a registry of all available sorting algorithms.
- **Metadata Support:** Each registered algorithm must be accompanied by a metadata table that defines its applicability. This metadata will be used for filtering.
- **Contextual Filtering:** The module must provide an interface for consumers (e.g., UI modules) to request a list of sorting algorithms that are valid for a specific context (e.g., `view: "organizer"`, `groupSize: 5`).
- **Standardized Interface:** The module will expose a clear and consistent API for registering algorithms and retrieving them.
