# Creating Custom Threads From a Thread Gauge in Fusion 360

## Using the thread gauge

My thread gauge: https://smile.amazon.com/gp/product/B071H8GP18/
Discussion on using that gauge: https://www.model-engineer.co.uk/forums/postings.asp?th=57757

* Measurements with "G"
    * 13G means "13 gang" aka 13 TPI
    * 14G 7/16 means 13 TPI for a 7/16" thread
* No units means TPI
* Note the angle of the thread
    * Whitworth is 55-deg
    * Metric is 60-deg

## Figuring out parameters

* Convert TPI to pitch in mm
    * https://www.newmantools.com/tech/pitchconversions.htm
* What's the gender of the thread?
    * Screws are 'external'
    * nuts are 'internal'
* Given the pitch and major diameter, calculate the minor & pitch diameter
    * Measure major diameter with calipers
    * Helpful reminder of terms: https://www.mwcomponents.com/basic-screw-and-thread-terms
    * External Threads (screws)
        * Calculate pitch diameter: https://www.calculatoratoz.com/en/pitch-diameter-of-external-thread-given-pitch-calculator/Calc-15728
        * Calculate minor diameter: https://www.calculatoratoz.com/en/minor-diameter-of-external-thread-given-pitch-and-major-diameter-of-internal-thread-calculator/Calc-15811
    * Internal Threads (nuts)
        * Calculate pitch diameter: https://www.calculatoratoz.com/en/pitch-diameter-of-internal-thread-given-pitch-calculator/Calc-15713
        * Calculate minor diameter: https://www.calculatoratoz.com/en/minor-diameter-of-internal-thread-given-pitch-and-major-diameter-of-internal-thread-calculator/Calc-15805
* Note that for internal threads, the TapDrill should be equal to the MinorDia