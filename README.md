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

### `scripts/f360-thread-calculator.rb`

I wrote this to take input and calculate parameters. I don't recommend using it yet, as input is messy, but it's tested and you're welcome to poke around with it if you know Ruby. I'll be cleaning it up over time and will update here when it's generally usable.