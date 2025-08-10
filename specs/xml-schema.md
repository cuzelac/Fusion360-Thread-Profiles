## Fusion 360 Thread XML schema mapping

### Root element

```xml
<ThreadType>
  <Name>...</Name>
  <CustomName>...</CustomName>
  <Unit>mm</Unit>
  <Angle>55.0|60.0</Angle>
  <SortOrder>3</SortOrder>
  ...
</ThreadType>
```

- `Unit` is always `mm` in this tool.
- `Angle` is a file-wide setting. Appends must match existing angle.

### ThreadSize grouping

Threads are grouped under `<ThreadSize>` elements by nominal size (the first number in the designation).

```xml
<ThreadSize>
  <Size>9.45</Size>
  <Designation>
    <ThreadDesignation>9.45x0.9</ThreadDesignation>
    <CTD>9.45x0.9</CTD>
    <Pitch>0.9</Pitch>
    <Thread> ... class/gender values ... </Thread>
    <Thread> ... additional classes ... </Thread>
  </Designation>
  <Designation>
    <ThreadDesignation>9.45x0.85</ThreadDesignation>
    <CTD>9.45x0.85</CTD>
    <Pitch>0.85</Pitch>
    <Thread> ... </Thread>
  </Designation>
</ThreadSize>
```

### Mapping from computed values

For each unique tuple `(nominal_size, pitch)` create or update one `<Designation>` containing one or more `<Thread>` entries (each representing a class and gender combination).

- `<Size>`: nominal size
- `<ThreadDesignation>`: `"<nominal_size>x<pitch>"` (rounded strings)
- `<CTD>`: identical to `<ThreadDesignation>`
- `<Pitch>`: pitch value
- `<Thread>` children (one per offset):
  - `<Gender>`: `internal` or `external`
  - `<Class>`: class label like `O.0`, `O.1`, ...
  - `<MajorDia>`, `<PitchDia>`, `<MinorDia>`: computed per calculations spec
  - `<TapDrill>`: present for `internal` only; equals `<MinorDia>`

### Serialization

- Use pretty-printing with consistent two- or four-space indentation.
- Write numeric values with configured decimal places (`--digits`).
- Preserve existing unrelated nodes/comments when merging.


