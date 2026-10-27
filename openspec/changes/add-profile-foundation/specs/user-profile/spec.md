# user-profile

## Purpose

Defines what a Track Field Network user profile is: the fields stored on the user record,
which of those fields only the server may write, where profile media lives, and who may
read or change each part. Every later social capability — follow graph, posts, messaging —
builds on this contract.

## ADDED Requirements

### Requirement: Profile fields on the user record

The system SHALL store a user's public profile on the user record: a handle, a display bio,
a cover image reference, external links, a private-account flag, and three engagement
counters. Every field SHALL be optional, so records written before this capability existed
remain readable without migration.

#### Scenario: Reading a profile written before this capability

- **WHEN** a client reads a user record created before profile fields existed
- **THEN** the read succeeds
- **AND** absent profile fields resolve to their documented defaults rather than erroring
- **AND** the three counters resolve to `0`

#### Scenario: Reading a profile after backfill

- **WHEN** a client reads a user record that the backfill has processed
- **THEN** the three counters are present and equal to `0`
- **AND** a handle is present

#### Scenario: Profile is publicly readable

- **WHEN** any client, signed in or not, reads another user's record
- **THEN** the profile fields are returned
- **AND** no authentication is required

### Requirement: Server-owned fields reject client writes

The system SHALL reject any client write to a field that only the server may own: the three
engagement counters, the user's role, and the disabled flag. This SHALL hold even when the
client is the owner of the record. Privileged processes acting with administrative
credentials SHALL remain able to write these fields.

#### Scenario: Owner attempts to forge a counter

- **WHEN** a signed-in user updates their own record and includes a changed counter value
- **THEN** the write is rejected

#### Scenario: Owner attempts to escalate their role

- **WHEN** a signed-in user updates their own record and sets their role to an elevated value
- **THEN** the write is rejected

#### Scenario: Owner attempts to clear their disabled flag

- **WHEN** a user whose account has been disabled updates their own record to remove that flag
- **THEN** the write is rejected

#### Scenario: Owner edits their own profile

- **WHEN** a signed-in user updates only their own bio, cover reference, links, or handle
- **THEN** the write succeeds

#### Scenario: Administrative process writes a counter

- **WHEN** a process acting with administrative credentials writes a counter
- **THEN** the write succeeds

### Requirement: Profile cover media

The system SHALL accept a cover image uploaded by the owning user into a per-user media
location, and SHALL make stored covers publicly readable. The system SHALL reject uploads
that exceed the configured size limit or that are not images.

#### Scenario: Owner uploads a cover image

- **WHEN** a signed-in user uploads an image within the size limit to their own cover location
- **THEN** the upload succeeds
- **AND** the resulting cover is readable by any client

#### Scenario: User uploads to another user's location

- **WHEN** a signed-in user attempts to upload to a cover location belonging to another user
- **THEN** the upload is rejected

#### Scenario: Oversized or non-image upload

- **WHEN** a user uploads a file that exceeds the size limit or is not an image
- **THEN** the upload is rejected

### Requirement: Handles are present but not yet unique

The backfill SHALL derive a handle for every existing user and store it on the user record
in both its original and a case-insensitive form. This capability SHALL NOT guarantee that
handles are globally unique; uniqueness is introduced separately by the handle registry.

#### Scenario: Backfill derives a handle

- **WHEN** the backfill processes a user record with no handle
- **THEN** a handle derived from the user's display name is stored
- **AND** a lowercase form of that handle is stored alongside it

#### Scenario: Backfill is run a second time

- **WHEN** the backfill processes a user record that already has a handle and counters
- **THEN** the record is left unchanged

#### Scenario: Two users derive the same handle

- **WHEN** the backfill derives the same handle for two different users
- **THEN** both records are written
- **AND** the collision is reported for later resolution rather than failing the backfill

### Requirement: Administrators can see profile state

The system SHALL show administrators each user's handle and engagement counters alongside
existing user information, as read-only values.

#### Scenario: Administrator views the user list

- **WHEN** an administrator opens the user list
- **THEN** each row shows that user's handle and follower and following counts

#### Scenario: Administrator views a user with no handle

- **WHEN** an administrator views a user record the backfill has not processed
- **THEN** the row renders with an empty handle and zero counts rather than failing

### Requirement: Mention placeholder reserved

Profile write paths SHALL persist an empty mention collection so that mention support can be
added later without migrating existing records. No behavior SHALL depend on this field yet.

#### Scenario: Profile is written

- **WHEN** a profile write path stores a user record
- **THEN** an empty mention collection is present on the stored record
