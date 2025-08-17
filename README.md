# Creating Custom Threads From a Thread Gauge in Fusion 360

Due to my questionable life choices, I print a lot of non-standard nuts and bolts. I bought a cheap thread gauge and had a hard time figuring out how to turn those measurements in to Fusion 360 thread profiles.

It's actually really easy, but the information is all over the place.

This README collects what I've learned.

## Managing custom threads

I recommend using the [ThreadKeeper plugin](https://apps.autodesk.com/FUSION/en/Detail/Index?id=1725038115223093226&appLang=en&os=Win64). It makes it easy to manage your custom threads in a separate directory and syncs your custom threads when F360 wipes out its threads directory during most (all?) updates.

This repo is my entire personal threadkeeper directory.

### Workflow and tweaking custom threads

When you use Threadkeeper manage your custom threads, you can edit the thread files live and then click `Utilities > THREADKEEPER > Force Sync` to update the Fusion 360 directory.

It gives a message that you may need to restart F360 for the changes to take effect, but I haven't had to do that in a long time.

If your changes don't show up, you may have malformed XML. As far as I can tell, Fusion 360 silently ignores files that contain malformed XML.

If you make changes to an existing thread profile, those changes will not be reflected in the design until you edit the feature in the timeline. For example, if you change the thread profile for a nut that's already in a design, you'll have to double-click on the applicable "Thread" feature in the timeline and then click "ok"

## Using the thread gauge

* My thread gauge: https://amazon.com/gp/product/B071H8GP18/ 
* Discussion on using that gauge: https://www.model-engineer.co.uk/forums/postings.asp?th=57757

What do the markings mean?
* Measurements with "G"
    * 13G means "13 gang" aka 13 TPI
    * 14G 7/16 means 13 TPI for a 7/16" thread
* No units means pitch in mm
* Note the angle of the thread
    * Whitworth is 55-deg
    * Metric is 60-deg

## Figuring out parameters

* Thread angle applies to a whole .xml file
* If you have TPI, convert it to pitch in mm
    * `25.4 * 1/TPI = pitch in mm`
    * You can find a table of common values here: https://www.newmantools.com/tech/pitchconversions.htm
* What's the gender of the thread?
    * Screws are 'external'
    * nuts are 'internal'
* Given the pitch and major diameter, calculate the minor & pitch diameter
    * Helpful reminder of terms: https://www.mwcomponents.com/basic-screw-and-thread-terms
    * Internal Threads (nuts)
        * Measure minor diameter with calipers
        * Calculate major diameter: `major_diameter = (1.083 * pitch) + minor_diameter`
            * https://www.calculatoratoz.com/en/major-diameter-of-internal-thread-given-pitch-and-minor-diameter-of-internal-thread-calculator/Calc-15809
        * Calculate pitch diameter: `pitch_diameter = major_diameter - (0.650 * pitch)`
            * https://www.calculatoratoz.com/en/pitch-diameter-of-internal-thread-given-pitch-calculator/Calc-15713
        * Note that for internal threads, the TapDrill should be equal to the MinorDia
    * External Threads (screws)
        * Measure major diameter with calipers
        * Calculate pitch diameter: `pitch_diameter = major_diameter - (0.650 * pitch)`
            * https://www.calculatoratoz.com/en/pitch-diameter-of-external-thread-given-pitch-calculator/Calc-15728
        * Calculate minor diameter: `minor_diameter = major_diameter - (1.227 * pitch)`
            * https://www.calculatoratoz.com/en/minor-diameter-of-external-thread-given-pitch-and-major-diameter-of-internal-thread-calculator/Calc-15811

### `bin/generate-threads` CLI Tool

I've created a professional command-line tool that automates thread profile generation. It handles all the calculations and generates properly formatted XML files that can be used directly with Fusion 360.

#### Installation

The tool is written in Ruby and requires no external dependencies. Make sure you have Ruby installed on your system.

#### Basic Usage

Generate a simple thread profile:
```bash
ruby -I lib bin/generate-threads --angle 60 --pitch 1.25 --diameter 10 --external
```

Generate an internal thread with custom offsets:
```bash
ruby -I lib bin/generate-threads --angle 60 --pitch 1.5 --diameter 12 --internal --offsets 0.0,0.1,0.2
```

Use TPI instead of pitch:
```bash
ruby -I lib bin/generate-threads --angle 55 --tpi 20 --diameter 8 --external
```

#### Command Line Options

- `--angle ANGLE`: Thread angle in degrees (60° for metric, 55° for Whitworth)
- `--pitch PITCH`: Pitch in mm (mutually exclusive with --tpi)
- `--tpi TPI`: Threads per inch (mutually exclusive with --pitch)
- `--diameter DIA`: Nominal diameter in mm
- `--internal` or `--external`: Thread gender
- `--offsets LIST`: Comma-separated offsets in mm (default: 0.0,0.1,0.2,0.3,0.4)
- `--xml PATH`: Output XML file path (optional)
- `--name NAME`: Custom name for the thread profile
- `--dry-run`: Preview output without writing files

#### Example Output

The tool generates XML like this:
```xml
<ThreadType>
  <Name>Generated Threads</Name>
  <Unit>mm</Unit>
  <Angle>60.0</Angle>
  <ThreadSize>
    <Size>10.00</Size>
    <Designation>
      <ThreadDesignation>10.00x1.25</ThreadDesignation>
      <Pitch>1.25</Pitch>
      <Thread>
        <Gender>external</Gender>
        <Class>O.0</Class>
        <MajorDia>10.00</MajorDia>
        <PitchDia>9.19</PitchDia>
        <MinorDia>8.47</MinorDia>
      </Thread>
    </Designation>
  </ThreadSize>
</ThreadType>
```

This XML can be saved directly to your ThreadKeeper directory and will work with Fusion 360.