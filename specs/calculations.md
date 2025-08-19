## Calculations specification

### Inputs

- `pitch` (mm) > 0 (either provided directly or derived from TPI)
- `tpi` (threads per inch) > 0 (optional; mutually exclusive with pitch)
- `gender`: `internal` or `external`
- `diameter` (mm) > 0
  - For `internal`, `diameter` is the measured minor diameter.
  - For `external`, `diameter` is the measured major diameter.

### Formulas (from README and validated in tests)
### Converting TPI to pitch

- If `tpi` is provided, convert to pitch in mm: `pitch_mm = 25.4 / tpi`.
- After conversion, proceed with the same formulas as above.


Let `p = pitch`.

Internal (nuts):
- `minor_dia = diameter + offset` (offset default 0.0)
- `major_dia = 1.083 * p + minor_dia`
- `pitch_dia = major_dia - (0.650 * p)`
- `tap_drill = minor_dia`

External (screws):
- `major_dia = diameter - offset`
- `pitch_dia = major_dia - (0.650 * p)`
- `minor_dia = major_dia - (1.227 * p)`

### Offsets and classes

- Offsets are in millimeters and represent fit/clearance adjustments.
- Default offsets: `[0.0, 0.1, 0.2, 0.3, 0.4]`.
- For each offset, compute a separate `<Thread>` node with `Class` label `O.N` where `N` is the offset to one decimal place (e.g., `O.0`, `O.1`).
- Offset application:
  - Internal: increases minor diameter (looser fit) and propagates to major/pitch via formulas above.
  - External: decreases major diameter (looser fit) and propagates to pitch/minor via formulas above.

### Rounding and formatting

- Decimal places: always `2`.
- Round each computed value to two decimal places before serialization.
- The `Class` string must be formatted as `O.x` with one decimal place.

### Thread designation and size

- Nominal size (used for `<Size>` and the first number in `<ThreadDesignation>`):
  - Internal: use computed `major_dia` at offset `0.0`.
  - External: use the input `diameter` (major) at offset `0.0`.
- Thread designation string: `"<nominal_size>x<pitch>"` using rounded values.
- `<CTD>` is identical to `<ThreadDesignation>`.


