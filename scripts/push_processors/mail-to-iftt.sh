#!/bin/bash
#
# Purpose: Send email to external service with each output image attached as a separate email.
# Subject line and body contain details. 
#
# 
#   1. edit ~/.msmtprc to configure your email service.
#   2. Setup handling services (for example IFTTT.COM to forward images to Facebook page)
# 


# import common lib and settings
. "$HOME/.noaa-v2.conf"
. "$NOAA_HOME/scripts/common.sh"

# input params
ATTACHMENT=$1
ANNOTATION=$2


log "Emailing to IFTTT facebook forwarder" "INFO"
# Send to email / facebook page: needs some filtration for bad images in due course 
# eg i notice that when M2 fails typically the IR images is bigger on disk than the base image.


# this is a catchall - if the attachment exists then it is sent - it will catch all the NOAAs
  if [ -f "${ATTACHMENT}" ]; then 
    mpack -s ${ANNOTATION} ${ATTACHMENT}-122-rectified.jpg ${EMAILIFTTT}
  fi

# the METEOR email calls do not use a list of enhancements - these are looped here. 
# Could be moved to a model like NOAA which would flatten this script.A 

  if [ -f "${ATTACHMENT}-122-rectified.jpg" ]; then 
    mpack -s ${ANNOTATION} ${ATTACHMENT}-122-rectified.jpg ${EMAILIFTTT}
  fi
  if [ -f "${ATTACHMENT}-ir-122-rectified.jpg" ]; then 
    mpack -s ${ANNOTATION}-IR ${ATTACHMENT}-ir-122-rectified.jpg ${EMAILIFTTT}
  fi
  if [ -f "${ATTACHMENT}-col-122-rectified.jpg" ]; then 
    mpack -s ${ANNOTATION}-col ${ATTACHMENT}-col-122-rectified.jpg ${EMAILIFTTT}
  fi
