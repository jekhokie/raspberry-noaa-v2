#!/usr/bin/python3

import sys
import re
from math import atan,sin,cos,sqrt,tan,acos,ceil
from PIL import Image

EARTH_RADIUS = 6371.0
SAT_HEIGHT = 822.5
SAT_ORBIT_RADIUS = EARTH_RADIUS + SAT_HEIGHT
SWATH_KM = 2800.0
THETA_C = SWATH_KM / EARTH_RADIUS

# Note: theta_s is the satellite viewing angle, theta_c is the angle between the projection of the satellite on the
# Earth's surface and the point the satellite is looking at, measured at the center of the Earth

# Compute the satellite angle of view given the center angle


def theta_s(theta_c):
    return atan(EARTH_RADIUS * sin(theta_c)/(SAT_HEIGHT+EARTH_RADIUS*(1-cos(theta_c))))

# Compute the inverse of the function above


def theta_c(theta_s):
    delta_sqrt = sqrt(EARTH_RADIUS**2 + tan(theta_s)**2 *
                      (EARTH_RADIUS**2-SAT_ORBIT_RADIUS**2))
    return acos((tan(theta_s)**2*SAT_ORBIT_RADIUS+delta_sqrt)/(EARTH_RADIUS*(tan(theta_s)**2+1)))

# The nightmare fuel that is the correction factor function.
# It is the reciprocal of d/d(theta_c) of theta_s(theta_c) a.k.a.
# the derivative of the inverse of theta_s(theta_c)


def correction_factor(theta_c):
    norm_factor = EARTH_RADIUS/SAT_HEIGHT
    tan_derivative_recip = (
        1+(EARTH_RADIUS*sin(theta_c)/(SAT_HEIGHT+EARTH_RADIUS*(1-cos(theta_c))))**2)
    arg_derivative_recip = (SAT_HEIGHT+EARTH_RADIUS*(1-cos(theta_c)))**2/(EARTH_RADIUS*cos(
        theta_c)*(SAT_HEIGHT+EARTH_RADIUS*(1-cos(theta_c)))-EARTH_RADIUS**2*sin(theta_c)**2)

    return norm_factor * tan_derivative_recip * arg_derivative_recip

# Radians position given the absolute x pixel position, assuming that the sensor samples the Earth
# surface with a constant angular step


def theta_center(img_size, x):
    ts = theta_s(THETA_C/2.0) * (abs(x-img_size/2.0) / (img_size/2.0))
    return theta_c(ts)


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: {} <input file>".format(sys.argv[0]))
        sys.exit(1)

    out_fname = re.sub("\..*$", "-rectified", sys.argv[1])

    img = Image.open(sys.argv[1])
    print("Opened {}x{} image".format(img.size[0], img.size[1]))

    # Precompute the correction factors
    corr = []
    for i in range(img.size[0]):
        corr.append(correction_factor(theta_center(img.size[0], i)))

    # Estimate the width of the rectified image
    rectified_width = ceil(sum(corr))
    rectified_img = Image.new(img.mode, (rectified_width, img.size[1]))

    # Get the pixel 2d arrays from both the source image and the target image
    orig_pixels = img.load()
    rectified_pixels = rectified_img.load()

    for row in range(img.size[1]):
        if row % 20 == 0:
            print("Row {}".format(row))

        # First pass: stretch from the center towards the right side of the image
        start_px = orig_pixels[img.size[0]/2, row]
        cur_col = int(rectified_width/2)
        target_col = cur_col

        for col in range(int(img.size[0]/2), img.size[0]):
            target_col += corr[col]
            end_px = orig_pixels[col, row]
            delta = int(target_col) - cur_col

            # Linearly interpolate
            for i in range(delta):
                interp_r = int((start_px[0]*(delta-i) + end_px[0]*i) / delta)
                interp_g = int((start_px[1]*(delta-i) + end_px[1]*i) / delta)
                interp_b = int((start_px[2]*(delta-i) + end_px[2]*i) / delta)

                rectified_pixels[cur_col, row] = (interp_r, interp_g, interp_b)
                cur_col += 1

            start_px = end_px

        # First pass: stretch from the center towards the left side of the image
        start_px = orig_pixels[img.size[0]/2, row]
        cur_col = int(rectified_width/2)
        target_col = cur_col

        for col in range(int(img.size[0]/2)-1, -1, -1):
            target_col -= corr[col]
            end_px = orig_pixels[col, row]
            delta = cur_col - int(target_col)

            # Linearly interpolate
            for i in range(delta):
                interp_r = int((start_px[0]*(delta-i) + end_px[0]*i) / delta)
                interp_g = int((start_px[1]*(delta-i) + end_px[1]*i) / delta)
                interp_b = int((start_px[2]*(delta-i) + end_px[2]*i) / delta)

                rectified_pixels[cur_col, row] = (interp_r, interp_g, interp_b)
                cur_col -= 1

            start_px = end_px

    print("Writing rectified image to {}".format(out_fname + ".jpg"))
    rectified_img.save(out_fname + ".jpg", "JPEG", quality=90)
