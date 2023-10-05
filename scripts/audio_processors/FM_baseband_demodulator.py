#!/usr/bin/env python3
# -*- coding: utf-8 -*-

#
# SPDX-License-Identifier: GPL-3.0
#
# GNU Radio Python Flow Graph
# Title: FM Baseband Demodulator
# Author: Mihajlo
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


class FM_baseband_demodulator(gr.top_block):

    def __init__(self):
        gr.top_block.__init__(self, "FM Baseband Demodulator")

        ##################################################
        # Variables
        ##################################################
        self.input_baseband = input_baseband = sys.argv[1]
        self.output_baseband = output_baseband = sys.argv[2]

        ##################################################
        # Blocks
        ##################################################
        self.low_pass_filter_0 = filter.fir_filter_ccf(
            1,
            firdes.low_pass(
                1,
                110250,
                50000,
                25000,
                firdes.WIN_HAMMING,
                6.76))
        self.gr_wavfile_sink_0_0_0_0 = blocks.wavfile_sink(output_baseband, 1, 11025, 16)
        self.blocks_wavfile_source_0 = blocks.wavfile_source(input_baseband, False)
        self.blocks_multiply_const_vxx_0 = blocks.multiply_const_ff(0.7)
        self.blocks_float_to_complex_0 = blocks.float_to_complex(1)
        self.blks2_wfm_rcv_0 = analog.wfm_rcv(
        	quad_rate=110250,
        	audio_decimation=10,
        )
        ##################################################
        # Connections
        ##################################################
        self.connect((self.blks2_wfm_rcv_0, 0), (self.blocks_multiply_const_vxx_0, 0))
        self.connect((self.blocks_float_to_complex_0, 0), (self.low_pass_filter_0, 0))
        self.connect((self.blocks_multiply_const_vxx_0, 0), (self.gr_wavfile_sink_0_0_0_0, 0))
        self.connect((self.blocks_wavfile_source_0, 0), (self.blocks_float_to_complex_0, 0))
        self.connect((self.blocks_wavfile_source_0, 1), (self.blocks_float_to_complex_0, 1))
        self.connect((self.low_pass_filter_0, 0), (self.blks2_wfm_rcv_0, 0))

    def get_output_baseband(self):
        return self.output_baseband

    def set_output_baseband(self, output_baseband):
        self.output_baseband = output_baseband
        self.gr_wavfile_sink_0_0_0_0.open(self.output_baseband)

    def get_input_baseband(self):
        return self.input_baseband

    def set_input_baseband(self, input_baseband):
        self.input_baseband = input_baseband

def main(top_block_cls=FM_baseband_demodulator, options=None):
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
