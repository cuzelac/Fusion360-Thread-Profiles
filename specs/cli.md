## CLI specification: `generate-threads`

### Overview

`generate-threads` is a Ruby CLI that computes Fusion 360 thread definitions and emits or appends valid XML in the Fusion 360 ThreadType schema.

The thread angle applies to the entire XML file. Appending to an existing XML requires the angle to match.

### Entrypoint and execution

- Executable: `bin/generate-threads`
- Shebang: `#!/usr/bin/env ruby`
- Guard main: `if __FILE__ == $PROGRAM_NAME`
- Args: `OptionParser` (no interactive prompts).
- Logging: Ruby `Logger` to STDERR; XML output to STDOUT or a file.

### Required options

Exactly one of `--internal` or `--external` is required.

- `--angle ANGLE` (Float): Any numeric angle is allowed. Applies to the entire XML file.
- `--pitch PITCH_IN_MM` (Float > 0) or `--tpi THREADS_PER_INCH` (Float > 0). Exactly one of these must be provided. When `--tpi` is given, the tool converts to pitch in mm internally using `25.4 / TPI`.
- `--diameter DIAMETER_IN_MM` (Float > 0)
- `--internal` or `--external`

Semantics of `--diameter`:
- Internal: `diameter` is the measured minor diameter.
- External: `diameter` is the measured major diameter.

### Optional options

- `--xml PATH` If the path exists, merge the generated entries into that file and overwrite it in-place. If it does not exist, create a new XML file at that path. If omitted, write the resulting XML to STDOUT.
- `--offsets LIST` Comma-separated offsets in mm to produce classes; default: `0.0,0.1,0.2,0.3,0.4`.
- `--name STRING` Root `<Name>` when creating a new file only; ignored/invalid when merging into an existing file.
- `--custom-name STRING` Root `<CustomName>` when creating a new file only; ignored/invalid when merging into an existing file.
- `--sort-order N` Root `<SortOrder>` when creating a new file; default: `3`.
- `--verbose` Increase log verbosity (INFO → DEBUG). Can be repeated.
- `--quiet` Reduce log verbosity (INFO → WARN). One level per flag.
- `--dry-run` Do not write files; print actions and resulting XML to STDOUT.

### Output behavior

- Without `--xml`: generate a new `<ThreadType>` document and write to STDOUT.
- With `--xml PATH`:
  - If the file exists: merge the computed designation(s) into the document (see File I/O & Merge spec). The `--angle` must equal the file's `<Angle>`, and the file must use `<Unit>mm</Unit>`.
  - If the file does not exist: create a new document at that path using provided root metadata (`--name`, `--custom-name`, `--sort-order`).
- Always emit `<Unit>mm</Unit>` and `<Pitch>` values. If `--tpi` is used, the pitch is calculated as `25.4 / TPI` before emission. Logs go to STDERR.

### Examples

Generate a new internal thread definition (any angle) to STDOUT:

```sh
generate-threads --angle 55 --pitch 1.814 --diameter 18.524 --internal
```

Append an external thread to an existing XML using TPI input, updating/adding classes, and write in-place:

```sh
generate-threads --angle 60 --tpi 31.75 --diameter 4.0 --external \
  --xml manual_metric.xml
```

Generate with custom offsets to a new file:

```sh
generate-threads --angle 60 --pitch 0.9 --diameter 9.45 --external \
  --offsets 0.0,0.1,0.2,0.3,0.4 --xml 3DPrintedMetricCustom.xml
```

### Exit codes

- `0`: Success
- `64`: Usage error (missing/invalid flags; both or neither of internal/external)
- `65`: Data error (validation failed: out-of-range, non-positive values)
- `66`: Cannot open/parse XML
- `67`: Angle mismatch between `--angle` and XML `<Angle>` when merging
- `74`: I/O error writing output


