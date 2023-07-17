# -*- coding: utf-8 -*-

#
# SPDX-License-Identifier: GPL-3.0
#
# GNU Radio Python Flow Graph
# Title: Hackrf Meteor QPSK LRPT
# Author: Mihajlo
# GNU Radio version: 3.10.6.0

from gnuradio import blocks
from gnuradio import filter
from gnuradio.filter import firdes
from gnuradio import gr
from gnuradio.fft import window
import sys
import signal
import osmosdr
import time

class hackrf_m2_lrpt_rx(gr.hier_block2):
    def __init__(self):
        gr.hier_block2.__init__(
            self, "Hackrf Meteor QPSK LRPT",
                gr.io_signature(0, 0, 0),
                gr.io_signature(0, 0, 0),
        )

        stream_name = sys.argv[1]
        gain = float(sys.argv[2])
        freq_offset = int(sys.argv[3])
        sdr_dev_id = sys.argv[4]
        bias_t_string = sys.argv[5]
        bias_t = "1"
        if not bias_t_string:
          bias_t = "0"

        ##################################################
        # Variables
        ##################################################
        self.samp_rate_hackrf = samp_rate_hackrf = 4e6
        self.freq = freq = 137100000
        self.decim = decim = 32
        output_baseband = stream_name

        ##################################################
        # Blocks
        ##################################################

        self.rational_resampler_xxx_0 = filter.rational_resampler_ccc(
                interpolation=1,
                decimation=decim,
                taps=[],
                fractional_bw=0)
        self.osmosdr_source_0 = osmosdr.source(args="numchan=" + str(1) + " " + "hackrf=0,bias=" + bias_t)
        self.osmosdr_source_0.set_time_unknown_pps(osmosdr.time_spec_t())
        self.osmosdr_source_0.set_sample_rate(samp_rate_hackrf)
        self.osmosdr_source_0.set_center_freq(freq, 0)
        self.osmosdr_source_0.set_freq_corr(freq_offset, 0)
        self.osmosdr_source_0.set_dc_offset_mode(0, 0)
        self.osmosdr_source_0.set_iq_balance_mode(0, 0)
        self.osmosdr_source_0.set_gain_mode(False, 0)
        self.osmosdr_source_0.set_gain(20, 0)
        self.osmosdr_source_0.set_if_gain(10, 0)
        self.osmosdr_source_0.set_bb_gain(20, 0)
        self.osmosdr_source_0.set_antenna('', 0)
        self.osmosdr_source_0.set_bandwidth(1500000, 0)
        self.blocks_wavfile_sink_0 = blocks.wavfile_sink(
            output_baseband,
            2,
            (int(samp_rate_hackrf/decim)),
            blocks.FORMAT_WAV,
            blocks.FORMAT_PCM_U8,
            False
            )
        self.blocks_complex_to_float_0 = blocks.complex_to_float(1)


        ##################################################
        # Connections
        ##################################################
        self.connect((self.blocks_complex_to_float_0, 1), (self.blocks_wavfile_sink_0, 1))
        self.connect((self.blocks_complex_to_float_0, 0), (self.blocks_wavfile_sink_0, 0))
        self.connect((self.osmosdr_source_0, 0), (self.rational_resampler_xxx_0, 0))
        self.connect((self.rational_resampler_xxx_0, 0), (self.blocks_complex_to_float_0, 0))


    def get_samp_rate_hackrf(self):
        return self.samp_rate_hackrf

    def set_samp_rate_hackrf(self, samp_rate_hackrf):
        self.samp_rate_hackrf = samp_rate_hackrf
        self.osmosdr_source_0.set_sample_rate(self.samp_rate_hackrf)

    def get_freq(self):
        return self.freq

    def set_freq(self, freq):
        self.freq = freq
        self.osmosdr_source_0.set_center_freq(self.freq, 0)

    def get_decim(self):
        return self.decim

    def set_decim(self, decim):
        self.decim = decim

