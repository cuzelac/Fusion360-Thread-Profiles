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

- `--angle ANGLE` (Float): 55.0 or 60.0 only. Applies to the entire XML file.
- `--pitch PITCH_IN_MM` (Float > 0)
- `--diameter DIAMETER_IN_MM` (Float > 0)
- `--internal` or `--external`

Semantics of `--diameter`:
- Internal: `diameter` is the measured minor diameter.
- External: `diameter` is the measured major diameter.

### Optional options

- `--input-xml PATH` Append/merge into existing XML. Angle must match file.
- `--output PATH` Write XML to file instead of STDOUT. When used with `--input-xml`, this is the modified output path (default: overwrite input in-place if not provided).
- `--offsets LIST` Comma-separated offsets in mm to produce classes; default: `0.0,0.1,0.2,0.3,0.4`.
- `--digits N` Decimal places for numeric output; default: `2`.
- `--name STRING` Root `<Name>`; default: `Generated Threads`.
- `--custom-name STRING` Root `<CustomName>`; default: same as `--name`.
- `--sort-order N` Root `<SortOrder>`; default: `3`.
- `--unit UNIT` Only `mm` is supported; default: `mm`.
- `--verbose` Increase log verbosity (INFO → DEBUG). Can be repeated.
- `--quiet` Reduce log verbosity (INFO → WARN). One level per flag.
- `--dry-run` Do not write files; print actions and resulting XML to STDOUT.

### Output behavior

- Without `--input-xml`: generate a new `<ThreadType>` document with a single size/designation and associated class entries.
- With `--input-xml`: merge the computed designation into the document (see File I/O & Merge spec). The `--angle` option must equal the file's `<Angle>`.
- STDOUT outputs only the final XML. Logs go to STDERR.

### Examples

Generate a new Whitworth (55°) internal thread definition to STDOUT:

```sh
generate-threads --angle 55 --pitch 1.814 --diameter 18.524 --internal
```

Append a metric (60°) external thread to an existing XML, updating/adding classes, and write in-place:

```sh
generate-threads --angle 60 --pitch 0.8 --diameter 4.0 --external \
  --input-xml manual_metric.xml
```

Generate with custom offsets and precision to a new file:

```sh
generate-threads --angle 60 --pitch 0.9 --diameter 9.45 --external \
  --offsets 0.0,0.1,0.2,0.3,0.4 --digits 2 --output 3DPrintedMetricCustom.xml
```

### Exit codes

- `0`: Success
- `64`: Usage error (missing/invalid flags; both or neither of internal/external)
- `65`: Data error (validation failed: out-of-range, non-positive values)
- `66`: Cannot open/parse input XML
- `67`: Angle mismatch between `--angle` and XML `<Angle>`
- `74`: I/O error writing output


