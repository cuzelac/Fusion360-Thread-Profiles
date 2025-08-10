## Overview of specifications for `generate-threads`

This document links to all domain and technical specifications for the CLI that generates Fusion 360 thread definitions.

### Spec index

| Domain | File | Summary |
|---|---|---|
| CLI | [specs/cli.md](specs/cli.md) | Command name, options, usage, examples, exit codes |
| Calculations | [specs/calculations.md](specs/calculations.md) | Formulas, offsets/classes, fixed two-decimal rounding |
| XML Schema | [specs/xml-schema.md](specs/xml-schema.md) | Structure of Fusion 360 thread XML and mapping from computed values |
| Angle Handling | [specs/angle-handling.md](specs/angle-handling.md) | Angle applies to entire file; any numeric angle; enforcement rules |
| Logging | [specs/logging.md](specs/logging.md) | Ruby Logger configuration, verbosity flags, separation of concerns |
| File I/O & Merge | [specs/file-io-and-merge.md](specs/file-io-and-merge.md) | `--xml` semantics; idempotent merge; mm-only enforcement |
| Validation & Errors | [specs/validation-and-errors.md](specs/validation-and-errors.md) | Input validation (two-decimal rounding; mm-only), error classes, exit codes |
| Testing | [specs/testing.md](specs/testing.md) | Test plan for calculations and XML generation/merge |
| Extensibility | [specs/extensibility.md](specs/extensibility.md) | Future options (TPI input), config, and structure to grow |


