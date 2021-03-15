-e enh Enhancement option. Only one -e option should be specified. Enhancements available are:

ZA NOAA general purpose meteorological IR enhancement option. Increases contrast
by saturating the very low and very high temperature regions where there is typically
very little information. This enhancement option is temperature normalised.

MB NOAA cold cloud top enhancement option. Useful for showing where the strongest
rainfall is occurring in thunderstorms. This enhancement option is temperature
normalised.

MD The NOAA MD enhancement is a modification of the popular, general use MB
enhancement scheme. It is intended for warm season use, and provides improved
enhancement within the gray "step wedges" that depict "warm top" convection.
An additional improvement is better delineation of warm low clouds (30C to 7C).
The middle cloud range is somewhat broader than the MB, and enhancement of
details is minimised. Otherwise, it is the same as the MB enhancement. This
enhancement option is temperature normalised.

BD NOAA hurricane enhancement option. Highlights certain temperatures in the eye
and eye wall of the storm system which are known to be related to the intensity of
the hurricane. This enhancement option is temperature normalised.

CC NOAA CC enhancement curve. This enhancement option is temperature normalised.

EC NOAA EC enhancement curve. This enhancement option is temperature normalised.

HE The NOAA HE enhancement is used principally by weather offices in the western
United States. It provides good enhancement of a wide variety of cloud types, but
is somewhat complex, and may be difficult to use at first. It enhances low and
middle level clouds common along the Pacific Coast of North America in two separate
gray shade ranges. The freezing level is easily determined, an advantage for
aviation users concerned with icing. Step wedge regions display very cold
infrared cloud top temperatures associated with thunderstorms and frontal systems
in 5 degree increments down to -60 C. Two additional "repeat gray" segments
define cloud top temperatures colder than -60C. This enhancement option is temperature
normalised.

HF The NOAA HF enhancement is the most current of the "H" series of enhancements,
and is used principally by weather offices in the western United States. It
provides good enhancement of low and middle level clouds common along the
Pacific Coast of North America. Step wedge regions display very cold infrared
cloud top temperatures associated with thunderstorms and frontal systems in 5
degree increments down to -60 C. Two additional "repeat gray" segments define
cloud top temperatures colder than -60C. This enhancement option is temperature
normalised.

JF The NOAA JF enhancement is a hybrid enhancement scheme used to highlight
both sea surface temperatures, and cold cloud tops associated with thunderstorms
and other weather systems. It is somewhat simpler to interpret than the later JJ
enhancement. The coldest portion of the enhancement (less than -33C) is nearly
identical to the general-use MB enhancement. Maximum enhancement is provided
at the warm end (25 to 10C) to depict sea surface temperatures and warm
low clouds in tropical and sub-tropical areas. This enhancement option is temperature
normalised.

JJ The NOAA JJ enhancement is used to highlight both sea surface temperatures, and
cold cloud tops associated with thunderstorms and other weather systems. Maximum
enhancement is provided at the warm end (23 to 0C) to depict sea surface
temperatures and low clouds. The presence of a freezing level break point is
important for aviation users interested in icing conditions. Multiple, steep, ramp
enhancement ranges provide considerable detail within cold cloud tops such as
thunderstorms, but it is difficult to determine the actual temperatures with any
accuracy. This enhancement option is temperature normalised.

LC The NOAA LC curve is used on images from the 3.9 micron shortwave infrared
channel (CH2) of GOES. It provides maximum enhancement in the temperature
range where fog and low clouds typically occur (36C to -9C). Another enhanced
thermal range is from -10C to -29C, the region of precipitation generation in midlatitude
weather systems. Since CH2 is sensitive to "hot spots," a steep, reverse
ramp is found at the warm end (68C to 50C) to show any observable fires as white.
There is no enhancement at the very cold end (-30 to -67C), due to the instrument
noise normally present at these temperatures. This enhancement option is temperature
normalised.

TA NOAA TA enhancement curve. This enhancement option is temperature normalised.

WV The modified NOAA WV curve is used for the 6.7 micron water vapor channel
(CH3) on GOES. The only temperature range that is enhanced is between -5C and
-90C. Temperatures colder than -90C are shown as white, and temperatures
warmer than -5C are displayed as black. This enhancement option is temperature
normalised. (See also WV-old).

WV-old The original NOAA WV curve is used for the 6.7 micron water vapor channel
(CH3) on GOES. The only temperature range that is enhanced is between -10C
and -60C. This is the most important range because it shows middle and upper
tropospheric moisture patterns that relate to significant features such as: jet
streams, upper troughs, dry slots, and deformation zones. Temperatures colder
than -60C are shown as white, and temperatures warmer than -10C are displayed
as black. The latter condition is very rare, and occurs mainly in the subtropics.
This enhancement option is temperature normalised. (See also WV).
NO NOAA colour IR contrast enhancement option. Greatly increases contrast in the
darker land/sea regions and colours the cold cloud tops. Allows fine detail in land
and sea to be seen and provides a very readable indication of cloud top temperatures.
This enhancement option is temperature normalised.

MCIR Colours the NOAA sensor 4 IR image using a map to colour the sea blue and land
green. High clouds appear white, lower clouds gray or land/sea coloured, clouds
generally appear lighter, but distinguishing between land/sea and low cloud may
be difficult. Darker colours indicate warmer regions.

MSA[:SeaToLand[:LandToCloud[:ColdRegion]]]
Multispectral analysis. Uses a NOAA channel 2-4 image and determines which
regions are most likely to be cloud, land, or sea based on an analysis of the two
images. Produces a vivid false-coloured image as a result. This enhancement
takes up to three options separated from the enhancement name by colons. The
first option is the sea to land adjustment. The default value is 50 with the valid
range being 0 to 100. This should be decreased if land appears blue, and increased
if water appears green. The second option is the land to cloud adjustment. The
default value is 50 with the valid range being 0 to 100. This should be decreased
if cloud appears green and increased if land appears gray or white. The final
option should be 0 to indicate warm or summertime analysis or 1 to indicate there
are large cold regions. Note that perfect colouring is difficult to obtain, especially
with low illumination angles. This enhancement does not use a palette nor is it
temperature normalised.

MSA-precip[:SeaToLand[:LandToCloud[:ColdRegion]]]
Same as MSA multispectral analysis, but high cold cloud tops are coloured the
same as the NO enhancement to give an approximate indication of the probability
and intensity of precipitation.

MSA-anaglyph[:SeaToLand[:LandToCloud[:ColdRegion]]]
Same as MSA multispectral analysis, but creates a 3-D anaglyph image (must be
viewed with red/blue glasses). Operational only if the software has been
upgraded.

HVC Creates a false colour image from NOAA APT images based on temperature using
the HVC colour model. Uses the temperature derived from the sensor 4 image to
select the hue and the brightness from the histogram equalised other image to
select the value and chroma. The HVC colour model attempts to ensure that different
colours at the same value will appear to the eye to be the same brightness
and the spacing between colours representing each degree will appear to the eye to
be similar. Bright areas are completely unsaturated in this model. The palette
used can be changed using the -P option.

HVCT Similar to HVC (below), but with blue water and with colours more indicative of
land temperatures. The palette used can be changed using the -P option.
sea Creates a false colour image from NOAA APT images based on sea surface temperature.
Uses the sea surface temperature derived from just the sensor 4 image to
colour the image. Land appears black and cold high cloud will also appear black.
The sea surface temperature may be incorrect due to the presence of low cloud, or
of thin or small clouds in the pixel evaluated, or from noise in the signal. The
palette used can be changed using the -P option.

therm Produces a false colour image from NOAA APT images based on temperature.
Provides a good way of visualising cloud temperatures. The palette used can be
changed using the -P option.

veg Requires the rarely available NOAA APT sensor 1 and 2 images (seen during the
test phase after satellite launch). A vegetative index is built up and this is used so
that land will be coloured green, water dark blue, and clouds white. No palette is
used for this enhancement and the output is not temperature normalised.
anaglyph[:plane] Creates a false 3-D anaglyph (must be viewed with red/blue glasses) of the visible
image (or the far-IR image if no visible image is available) by estimating cloud
height. The optional plane value can be an integer between 0 (in) and 16 (out) to
specify the location of the ground plane. Operational only if the software has been
upgraded.

canaglyph[:plane]
Creates a false colour 3-D anaglyph (must be viewed with red/blue glasses) of the
visible image (or the far-IR image if no visible image is available) by estimating
cloud height. The optional plane value can be an integer between 0 (in) and 16
(out) to specify the location of the ground plane. Operational only if the software
has been upgraded.

class Unsupervised classification of NOAA APT images using an iterative optimisation
clustering algorithm. Uses an initial 27 cluster centres spaced equally along the
two-dimensional diagonal. The classification is used to tint the histogram
equalised channel A image.

histeq Histogram equalisation is performed.

contrast Contrast enhancement is is performed as per -H setting. Using this enhancement
with -H set to histeq will produce the same results as using the histeq enhancement.

invert Creates a grayscale negative, setting black to white and white to black.
bw Creates a black and white image, setting darker pixels to black and lighter pixels
to white.
