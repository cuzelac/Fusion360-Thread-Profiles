## Extensibility

### Future inputs

- `--tpi N`: accept threads-per-inch and convert to pitch in mm (`25.4 / N`).
- Angle synonyms: `--angle metric` → 60.0; `--angle whitworth` → 55.0.
- Multiple designations in one invocation via CSV or repeated flags.
- Support reading measured pairs (internal minor + external major) to emit both genders.

### Units

- Potential `--unit in` support by converting inputs to mm internally, but always emit `mm`.

### Configuration

- Config file (YAML) for defaults: offsets, digits, names, sort order.
- Environment variables for CI/use in scripts.

### Code organization

- Separate modules/classes:
  - Argument parsing and app wiring
  - Calculations
  - XML model/serializer
  - Merger
  - Logging facade
- Avoid global state; inject logger and config objects.


