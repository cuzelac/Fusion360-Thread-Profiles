## Logging specification

### Library and streams

- Use Ruby's `Logger`.
- Direct logs to `STDERR`.
- XML and primary program output go to `STDOUT` or the output file.

### Levels and flags

- Default level: `INFO`.
- `--verbose` increases verbosity one step per flag (INFO → DEBUG).
- `--quiet` decreases verbosity one step per flag (INFO → WARN → ERROR).

### Messages

- INFO: high-level actions (parsing input, generating designation, merge operations).
- DEBUG: detailed calculations per offset, merge resolution (created/updated/skipped), timing as needed.
- WARN: non-fatal anomalies (duplicate entries skipped, numeric coercions with rounding).
- ERROR: fatal errors prior to exit.

### No global logger variable

- Avoid globals like `$logger`. Encapsulate the logger in application objects or pass it where needed.


