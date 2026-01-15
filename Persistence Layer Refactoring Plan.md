# Persistence Layer Refactoring Plan

This document outlines the resources and components that must be modified to change the persistence layer of the application (e.g., switching from local JSON files to a database, cloud storage, or changing the file format).

User Review Required
NOTE

This is an analysis of impact. No actual code changes are proposed in this document, but these are the files that would need change.

Proposed Changes
The modifications are grouped by their role in the application architecture.

Business Logic & Orchestration
The central controller managing state and triggering save/load operations.

[MODIFY] 
circuit_provider.dart
Reason: Currently contains hardcoded calls to 
FileOps
 and jsonEncode/jsonDecode.
Changes Needed: Replace direct file operations with calls to the new persistence service interface.
Abstraction Layer
The interface defining how data is stored/retrieved.

[MODIFY] 
file_ops.dart
Reason: Defines the abstract 
FileOps
 interface.
Changes Needed: If keeping a file-based approach but changing the mechanism, modify this interface. If moving to a DB, this might be replaced or wrapped.
Platform Implementations
Platform-specific handling of storage.

[MODIFY] 
file_ops_io.dart
 (Desktop/Mobile)
[MODIFY] 
file_ops_web.dart
 (Web)
Reason: Implements the actual dart:io or dart:html calls.
Changes Needed: Update these to support the new storage location, API (e.g. File System Access API), or encryption.
Data Models (Serialization)
Defines the schema for stored data.

[MODIFY] 
saved_circuit.dart
[MODIFY] 
logic_component.dart
[MODIFY] 
integrated_circuit.dart
[MODIFY] 
connection.dart
Reason: These classes control 
toJson
 and fromJson.
Changes Needed: If the data structure or format changes (e.g. SQL columns, ProtoBuf), these serialization methods must be updated.
Verification Plan
Any changes to persistence must be rigorously tested.

Automated Tests
Unit tests for serialization/deserialization of all models.
Mock tests for the PersistenceService to ensure 
CircuitProvider
 calls it correctly.
Manual Verification
Save/Load Cycle: Create a complex circuit, save, restart app, load. Verify all connections and states are restored.
Platform Check: Verify behavior on both Web (browser storage/download) and Desktop (local filesystem).
