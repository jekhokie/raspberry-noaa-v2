#!/usr/bin/env python3
# -*- coding: utf-8 -*-

#
# SPDX-License-Identifier: GPL-3.0
#
# GNU Radio Python Flow Graph
# Title: Meteor QPSK LRPT
# Author: otti & Mihajlo
# GNU Radio version: 3.8.2.0

from gnuradio import blocks
from gnuradio import filter
from gnuradio.filter import firdes
from gnuradio import gr
import sys
import signal
from argparse import ArgumentParser
from gnuradio.eng_arg import eng_float, intx
from gnuradio import eng_notation
import osmosdr
import time


class rtlsdr_m2_lrpt_rx(gr.top_block):

    def __init__(self):
        gr.top_block.__init__(self, "Meteor QPSK LRPT")

        ###############################################################
        # Variables - added for Raspberry-Noaa-V2 manually after export
        ###############################################################

        # get some variables in place for inputs
        #
        # Arguments:
        #   1. Full path and name of stream file (including file extension)
        #   2. Gain to be used
        #   3. Meteor Frequency (MHz)
        #   4. Frequency offset (PPM)
        #   5. SDR Device ID from settings.yml (for RTL-SDR source block)
        #   6. Bias-T (0/1 for RTL-SDR)

        stream_name = sys.argv[1]
        gain = float(sys.argv[2])
        freq = int(float(sys.argv[3])*1e6)
        freq_offset = int(sys.argv[4])
        sdr_dev_id = sys.argv[5]
        bias_t_string = sys.argv[6]
        bias_t = "1"
        if not bias_t_string:
          bias_t = "0"

        ##################################################
        # Variables
        ##################################################
        self.samp_rate_rtlsdr = samp_rate_rtlsdr = 1250000
        self.freq = freq
        self.decim = decim = 10
        output_baseband = stream_name

        ##################################################
        # Blocks
        ##################################################
        self.rtlsdr_source_0 = osmosdr.source( args='numchan=' + str(1) + ' ' + 'rtl=' + str(sdr_dev_id) + ',bias=' + bias_t + '' )
        self.rtlsdr_source_0.set_time_unknown_pps(osmosdr.time_spec_t())
        self.rtlsdr_source_0.set_sample_rate(samp_rate_rtlsdr)
        self.rtlsdr_source_0.set_center_freq(freq, 0)
        self.rtlsdr_source_0.set_freq_corr(freq_offset, 0)
        self.rtlsdr_source_0.set_dc_offset_mode(0, 0)
        self.rtlsdr_source_0.set_iq_balance_mode(0, 0)
        # determine if gain is specified or if auto-gain should be used 
        if (gain == 0): 
          self.rtlsdr_source_0.set_gain_mode(True, 0) 
        else:   
          self.rtlsdr_source_0.set_gain_mode(False, 0) 
          self.rtlsdr_source_0.set_gain(gain, 0)
        self.rtlsdr_source_0.set_if_gain(0, 0)
        self.rtlsdr_source_0.set_bb_gain(0, 0)
        self.rtlsdr_source_0.set_antenna('', 0)
        self.rtlsdr_source_0.set_bandwidth(1500000, 0)
        self.rational_resampler_xxx_0 = filter.rational_resampler_ccc(
                interpolation=1,
                decimation=decim,
                taps=None,
                fractional_bw=0.4)
        self.blocks_wavfile_sink_0 = blocks.wavfile_sink(output_baseband, 2, int(samp_rate_rtlsdr/decim), 8)
        self.blocks_complex_to_float_0 = blocks.complex_to_float(1)

        ##################################################
        # Connections
        ##################################################
        self.connect((self.blocks_complex_to_float_0, 1), (self.blocks_wavfile_sink_0, 1))
        self.connect((self.blocks_complex_to_float_0, 0), (self.blocks_wavfile_sink_0, 0))
        self.connect((self.rational_resampler_xxx_0, 0), (self.blocks_complex_to_float_0, 0))
        self.connect((self.rtlsdr_source_0, 0), (self.rational_resampler_xxx_0, 0))

    def get_samp_rate_rtlsdr(self):
        return self.samp_rate_rtlsdr

    def set_samp_rate_rtlsdr(self, samp_rate_rtlsdr):
        self.samp_rate_rtlsdr = samp_rate_rtlsdr
        self.rtlsdr_source_0.set_sample_rate(self.samp_rate_rtlsdr)

    def get_freq(self):
        return self.freq

    def set_freq(self, freq):
        self.freq = freq
        self.rtlsdr_source_0.set_center_freq(self.freq, 0)

    def get_decim(self):
        return self.decim

    def set_decim(self, decim):
        self.decim = decim

def main(top_block_cls=rtlsdr_m2_lrpt_rx, options=None):
    tb = top_block_cls()

    def sig_handler(sig=None, frame=None):
        tb.stop()
        tb.wait()

        sys.exit(0)

    signal.signal(signal.SIGINT, sig_handler)
    signal.signal(signal.SIGTERM, sig_handler)

    tb.start()

    tb.wait()


if __name__ == '__main__':
    main()
