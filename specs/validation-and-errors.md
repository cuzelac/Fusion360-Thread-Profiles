## Validation and errors

### Argument validation

- `--angle`: required; numeric; allowed: `55`, `55.0`, `60`, `60.0`.
- `--pitch`: required; numeric; `> 0`.
- `--diameter`: required; numeric; `> 0`.
- Exactly one of `--internal` or `--external` must be provided.
- `--digits`: optional; integer; `>= 0`.
- `--offsets`: optional; comma-separated numeric list; all `>= 0`.
- `--unit`: only `mm` supported.

### Runtime validation

- For `--input-xml`, ensure file exists and is readable; root is `<ThreadType>`.
- Angle in file matches `--angle` (after one-decimal-place normalization).

### Error classes (Ruby)

- `ConfigurationError < StandardError`: invalid CLI arguments or missing requirements.
- `AngleMismatchError < StandardError`: when `--angle` disagrees with file `<Angle>`.
- `XmlParseError < StandardError`: failed to parse or invalid structure.
- `IoError < StandardError`: read/write failures.

### Exit codes

- `64`: usage/configuration error
- `65`: validation/data error (e.g., negative numbers)
- `66`: XML parse/structure error
- `67`: angle mismatch
- `74`: I/O error

### Messages

- Errors log at ERROR level with actionable context: which flag/file/value failed and expected ranges.


