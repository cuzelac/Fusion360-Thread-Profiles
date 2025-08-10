## Validation and errors

### Argument validation

- `--angle`: required; numeric; any value accepted.
- `--pitch` or `--tpi`: exactly one required; numeric; `> 0`.
- `--diameter`: required; numeric; `> 0`.
- Exactly one of `--internal` or `--external` must be provided.
- `--offsets`: optional; comma-separated numeric list; all `>= 0`.
- `--xml PATH`: optional; file path. If exists, will be merged into; if not, a new file is created.
- `--name`/`--custom-name`: allowed only when creating a new file (no existing `--xml` file). Treat as invalid when merging.

### Runtime validation

- For `--xml PATH` that exists, ensure file is readable; root is `<ThreadType>`.
- Angle in file matches `--angle` (after one-decimal-place normalization).
- Unit in file must be `mm`; otherwise, treat as validation/data error.

### Error classes (Ruby)

- `ConfigurationError < StandardError`: invalid CLI arguments or missing requirements.
- `AngleMismatchError < StandardError`: when `--angle` disagrees with file `<Angle>`.
- `XmlParseError < StandardError`: failed to parse or invalid structure.
- `IoError < StandardError`: read/write failures.

### Exit codes

- `64`: usage/configuration error
- `65`: validation/data error (e.g., negative numbers; unsupported unit in existing XML; invalid use of `--name`/`--custom-name` while merging; both or neither of `--pitch`/`--tpi`)
- `66`: XML parse/structure error
- `67`: angle mismatch
- `74`: I/O error

### Messages

- Errors log at ERROR level with actionable context: which flag/file/value failed and expected ranges.


