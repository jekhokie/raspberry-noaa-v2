#!/usr/bin/env python3
# -*- coding: utf-8 -*-

#
# SPDX-License-Identifier: GPL-3.0
#
# GNU Radio Python Flow Graph
# Title: Airspy R2 NOAA APT Receiver V1.0.0
# Author: Mihajlo
# Description: APT to WAV recorder for Raspberry-Noaa -V2
# GNU Radio version: 3.8.2.0

from gnuradio import analog
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


class rtlsdr_noaa_apt_rx(gr.top_block):

    def __init__(self):
        gr.top_block.__init__(self, "Airspy R2 NOAA APT Receiver V1.0.0")

        ###############################################################
        # Variables - added for Raspberry-Noaa-V2 manually after export
        ###############################################################

        # get some variables in place for inputs
        #
        # Arguments:
        #   1. Full path and name of stream file (including file extension)
        #   2. Gain to be used
        #   3. Frequency (in Mhz)
        #   4. Frequency offset (PPM)
        #   5. SDR Device ID from settings.yml (for RTL-SDR source block)
        #   6. Bias-T (0/1 for RTL-SDR)

        stream_name = sys.argv[1]
        gain = float(sys.argv[2])
        import decimal
        freq = int(decimal.Decimal(sys.argv[3].strip("M"))*decimal.Decimal(1000000))
        freq_offset = int(sys.argv[4])
        sdr_dev_id = sys.argv[5]
        bias_t_string = sys.argv[6]
        bias_t = "1"
        if not bias_t_string:
           bias_t = "0"

        ##################################################
        # Variables
        ##################################################
        self.trans = trans = 25000
        self.samp_rate = samp_rate = 2500000
        self.recfile = recfile = stream_name
        self.fcd_freq = fcd_freq = freq
        self.cutoff = cutoff = 75000
        self.centre_freq = centre_freq = 0

        ###############################################################
        # Blocks - note the fcd_freq, freq_offset rtl device, bias-t and gain are carried
        #          in from settings.yml using the 'variables' block above.
        #          NOTE: If you edit and replace this .py in gnucomposer
        #          these will be overwritten with hard-coded values and
        #          need to be manually reintroduced to make the script take
        #          settings from your own settings.yml.
        ################################################################

        self.rational_resampler_xxx_0 = filter.rational_resampler_fff(
                interpolation=441,
                decimation=4000,
                taps=None,
                fractional_bw=None)
        self.osmosdr_source_0 = osmosdr.source(
            args="numchan=" + str(1) + " " + "airspy=0,pack=1,linearity,bias=" + bias_t + ""
        )
        self.osmosdr_source_0.set_time_unknown_pps(osmosdr.time_spec_t())
        self.osmosdr_source_0.set_sample_rate(2500000)
        self.osmosdr_source_0.set_center_freq(fcd_freq, 0)
        self.osmosdr_source_0.set_freq_corr(freq_offset, 0)
        self.osmosdr_source_0.set_dc_offset_mode(0, 0)
        self.osmosdr_source_0.set_iq_balance_mode(0, 0)
        self.osmosdr_source_0.set_gain_mode(False, 0)
        self.osmosdr_source_0.set_gain(gain, 0)
        self.osmosdr_source_0.set_if_gain(0, 0)
        self.osmosdr_source_0.set_bb_gain(0, 0)
        self.osmosdr_source_0.set_antenna('', 0)
        self.osmosdr_source_0.set_bandwidth(0, 0)
        self.low_pass_filter_0 = filter.fir_filter_ccf(
            25,
            firdes.low_pass(
                1,
                samp_rate,
                cutoff,
                trans,
                firdes.WIN_HAMMING,
                6.76))
        self.gr_wavfile_sink_0_0_0_0 = blocks.wavfile_sink(recfile, 1, 11025, 16)
        self.blocks_multiply_const_vxx_0 = blocks.multiply_const_ff(0.7)
        self.blks2_wfm_rcv_0 = analog.wfm_rcv(
        	quad_rate=100000,
        	audio_decimation=1,
        )

        ##################################################
        # Connections
        ##################################################
        self.connect((self.blks2_wfm_rcv_0, 0), (self.rational_resampler_xxx_0, 0))
        self.connect((self.blocks_multiply_const_vxx_0, 0), (self.gr_wavfile_sink_0_0_0_0, 0))
        self.connect((self.low_pass_filter_0, 0), (self.blks2_wfm_rcv_0, 0))
        self.connect((self.osmosdr_source_0, 0), (self.low_pass_filter_0, 0))
        self.connect((self.rational_resampler_xxx_0, 0), (self.blocks_multiply_const_vxx_0, 0))

    def get_trans(self):
        return self.trans

    def set_trans(self, trans):
        self.trans = trans
        self.low_pass_filter_0.set_taps(firdes.low_pass(1, self.samp_rate, self.cutoff, self.trans, firdes.WIN_HAMMING, 6.76))

    def get_samp_rate(self):
        return self.samp_rate

    def set_samp_rate(self, samp_rate):
        self.samp_rate = samp_rate
        self.low_pass_filter_0.set_taps(firdes.low_pass(1, self.samp_rate, self.cutoff, self.trans, firdes.WIN_HAMMING, 6.76))

    def get_recfile(self):
        return self.recfile

    def set_recfile(self, recfile):
        self.recfile = recfile
        self.gr_wavfile_sink_0_0_0_0.open(self.recfile)

    def get_fcd_freq(self):
        return self.fcd_freq

    def set_fcd_freq(self, fcd_freq):
        self.fcd_freq = fcd_freq
        self.osmosdr_source_0.set_center_freq(self.fcd_freq, 0)

    def get_cutoff(self):
        return self.cutoff

    def set_cutoff(self, cutoff):
        self.cutoff = cutoff
        self.low_pass_filter_0.set_taps(firdes.low_pass(1, self.samp_rate, self.cutoff, self.trans, firdes.WIN_HAMMING, 6.76))

def main(top_block_cls=rtlsdr_noaa_apt_rx, options=None):
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
