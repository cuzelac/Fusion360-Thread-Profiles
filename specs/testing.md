## Testing specification

### Framework

- Use Minitest (fits repo conventions).

### Unit tests: calculations

- Given known inputs, assert outputs match formulas with rounding:
  - Internal: major, pitch, minor (via offset), tap drill equals minor.
  - External: pitch, minor; offsets applied correctly.
- Test `--digits` rounding behavior (0, 1, 2, etc.).
- Test multiple offsets list and per-class outputs.

### Unit tests: XML generation

- New document generation:
  - Root nodes are set (Name, CustomName, Unit, Angle, SortOrder).
  - One `<ThreadSize>` created with `<Size>` equal to nominal size.
  - `<Designation>` contains expected `<ThreadDesignation>`, `<CTD>`, `<Pitch>`.
  - `<Thread>` entries for each class/gender with correct values.

### Merge tests

- Appending to existing XML where size/pitch block exists:
  - Update existing `(Gender, Class)` entries.
  - Append missing classes without duplicating existing ones.
- Appending where size exists but pitch new: creates new `<Designation>` under existing `<ThreadSize>`.
- Appending where neither exists: creates both `<ThreadSize>` and `<Designation>`.
- Idempotency: running the same command twice yields identical XML.

### Error path tests

- Missing required flags → exit 64.
- Both `--internal` and `--external` set or neither set → exit 64.
- Negative or zero `pitch`/`diameter` → exit 65.
- Input XML unreadable/malformed → exit 66.
- Angle mismatch → exit 67.
- Write failure (e.g., to unwritable path) → exit 74.


