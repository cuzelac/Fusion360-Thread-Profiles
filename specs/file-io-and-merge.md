## File I/O and merge behavior

### Inputs

- `--input-xml PATH`: optional. If present, merge new definitions into this file.
- `--output PATH`: optional. If present, write the resulting XML to this path. Defaults:
  - With `--input-xml`: overwrite input in-place when `--output` is omitted.
  - Without `--input-xml`: write to STDOUT when `--output` is omitted.

### Reading and validation

- Parse XML with REXML.
- Validate root is `<ThreadType>`.
- Validate `<Unit>` is `mm` (or set it when creating new files).
- Read `<Angle>` and ensure it matches `--angle` (see Angle Handling); otherwise error.

### Grouping and merge keys

- Group by `<ThreadSize>` `<Size>` equal to nominal size (rounded string).
- Within a size, group by `<Designation>` `<Pitch>` value.
- Within a designation, group by `<Thread>` entries with composite key `(Gender, Class)`.

### Merge algorithm (idempotent)

1. Compute values for each offset/class per Calculations spec.
2. Find or create `<ThreadSize>` with `<Size>` equal to nominal size.
3. Within that size, find or create `<Designation>` with matching `<Pitch>`.
   - Set `<ThreadDesignation>` and `<CTD>` to the designation string (`<nominal_size>x<pitch>`).
4. For each `(Gender, Class)`:
   - If an exact match exists, update numeric child nodes to computed values.
   - Else, append a new `<Thread>` element with computed values.
5. Preserve unrelated nodes, comments, and existing order as much as feasible. New nodes append at the end of their respective parent.

### Writing

- Pretty-print XML with a stable indentation (e.g., 2–4 spaces).
- Ensure newline at EOF.
- When `--dry-run` is set, do not write; print the resulting XML to STDOUT.


