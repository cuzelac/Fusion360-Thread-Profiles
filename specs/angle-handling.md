## Angle handling

### Rules

- The thread angle applies to the entire XML file.
- Any numeric `--angle` value is allowed.
- When creating a new document, set `<Angle>` to `--angle`.
- When merging into an existing document via `--xml PATH` (that exists), the provided `--angle` must match the file's `<Angle>` value. If not, exit with code `67`.

### Rationale

Fusion 360 expects the `Angle` to be consistent within a `ThreadType`. Mixing angles in one file leads to incorrect geometry; the examples in the repository show separate files for 55° and 60°.

### Validation

- Reject non-numeric angles.
- Normalize input to one decimal place when comparing (e.g., `55` equals `55.0`).


