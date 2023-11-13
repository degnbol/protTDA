bg white

set_color dred   = [226, 58, 52]
set_color dgreen = [ 95,177, 42]
set_color dblue  = [ 38,117,146]

color dred,   domain1
color dgreen, domain2
color dblue,  domain3

set cartoon_transparency, 0.5
# the two helices closest to the C-terminus, referred to as G and H helix in the lit.
set cartoon_transparency, 0.0, i. 100-154
ray
png horse1.png
# sperm whale evidence shows exclude the wobbly N-terminus tail
set cartoon_transparency, 0.0, i. 5-20
ray
png horse2.png
# has to i. to get everything
set cartoon_transparency, 0.0, i. 1-154
ray
png horse3.png

