## Angle handling

### Rules

- The thread angle applies to the entire XML file.
- Supported angles: `55.0` (Whitworth) and `60.0` (Metric).
- When creating a new document, set `<Angle>` to `--angle`.
- When appending to an existing document via `--input-xml`, the provided `--angle` must exactly match the file's `<Angle>` value. If not, exit with code `67`.

### Rationale

Fusion 360 expects the `Angle` to be consistent within a `ThreadType`. Mixing angles in one file leads to incorrect geometry; the examples in the repository show separate files for 55° and 60°.

### Validation

- Reject non-numeric or unsupported angles.
- Normalize input to one decimal place when comparing (e.g., `55` equals `55.0`).


