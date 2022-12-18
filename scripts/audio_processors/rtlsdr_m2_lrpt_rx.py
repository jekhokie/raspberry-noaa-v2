#!/usr/bin/env python3
# -*- coding: utf-8 -*-
##################################################
# GNU Radio Python Flow Graph
# Title: Meteor QPSK LRPT
# Author: otti
# Generated: Mon Apr 27 12:59:47 2020
##################################################

from datetime import datetime
from gnuradio import analog
from gnuradio import blocks
from gnuradio import digital
from gnuradio import eng_notation
from gnuradio import filter
from gnuradio import gr
from gnuradio.eng_option import eng_option
from gnuradio.filter import firdes
from optparse import OptionParser
import osmosdr
import time
import sys

class top_block(gr.top_block):
  def __init__(self):
    gr.top_block.__init__(self, "Meteor QPSK LRPT")

    # get some variables in place for inputs
    #
    # Arguments:
    #   1. Full path and name of stream file (including file extension)
    #   2. Gain to be used
    #   3. Frequency offset (PPM)
    #   4. SDR Device ID from settings.yml (for RTL-SDR source block)
    #   5. Bias-T (0/1 for RTL-SDR)


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
    self.samp_rate_airspy = samp_rate_airspy = 1250000
    self.decim = decim = 8
    self.symb_rate = symb_rate = 72000
    self.samp_rate = samp_rate = samp_rate_airspy/decim
    self.sps = sps = (samp_rate*1.0)/(symb_rate*1.0)
    self.pll_alpha = pll_alpha = 0.006
    self.freq = freq = 137100000
    self.clock_alpha = clock_alpha = 0.002
    self.bitstream_name = bitstream_name = stream_name

    ##############################################################################################################################################
    # Blocks -- *** NOTE HOW THE VARIABLES ARE CARRIED IN FROM settings.yml - this has to be re-done every time you export the .py from gnuradio
    ###############################################################################################################################################

    self.rtlsdr_source_0 = osmosdr.source( args='numchan=' + str(1) + ' ' + 'rtl=' + str(sdr_dev_id) + ',bias=' + bias_t + '' )
    self.rtlsdr_source_0.set_sample_rate(samp_rate_airspy)
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

    self.root_raised_cosine_filter_0 = filter.fir_filter_ccf(1, firdes.root_raised_cosine(
        1, samp_rate, symb_rate, 0.6, 361))
    self.rational_resampler_xxx_0 = filter.rational_resampler_ccc(
        interpolation=1,
        decimation=decim,
        taps=None,
        fractional_bw=None,
    )
    self.digital_costas_loop_cc_0 = digital.costas_loop_cc(pll_alpha, 4, False)
    self.digital_constellation_soft_decoder_cf_1 = digital.constellation_soft_decoder_cf(digital.constellation_calcdist(([-1-1j, -1+1j, 1+1j, 1-1j]), ([0, 1, 3, 2]), 4, 1).base())
    self.digital_clock_recovery_mm_xx_0 = digital.clock_recovery_mm_cc(sps, clock_alpha**2/4.0, 0.5, clock_alpha, 0.005)
    self.blocks_float_to_char_0 = blocks.float_to_char(1, 127)
    self.blocks_file_sink_0 = blocks.file_sink(gr.sizeof_char*1, bitstream_name, False)
    self.blocks_file_sink_0.set_unbuffered(False)
    self.analog_rail_ff_0 = analog.rail_ff(-1, 1)
    self.analog_agc_xx_0 = analog.agc_cc(1000e-4, 0.5, 1.0)
    self.analog_agc_xx_0.set_max_gain(4000)

    ##################################################
    # Connections
    ##################################################
    self.connect((self.analog_agc_xx_0, 0), (self.root_raised_cosine_filter_0, 0))
    self.connect((self.analog_rail_ff_0, 0), (self.blocks_float_to_char_0, 0))
    self.connect((self.blocks_float_to_char_0, 0), (self.blocks_file_sink_0, 0))
    self.connect((self.digital_clock_recovery_mm_xx_0, 0), (self.digital_constellation_soft_decoder_cf_1, 0))
    self.connect((self.digital_constellation_soft_decoder_cf_1, 0), (self.analog_rail_ff_0, 0))
    self.connect((self.digital_costas_loop_cc_0, 0), (self.digital_clock_recovery_mm_xx_0, 0))
    self.connect((self.rational_resampler_xxx_0, 0), (self.analog_agc_xx_0, 0))
    self.connect((self.root_raised_cosine_filter_0, 0), (self.digital_costas_loop_cc_0, 0))
    self.connect((self.rtlsdr_source_0, 0), (self.rational_resampler_xxx_0, 0))

  def get_samp_rate_airspy(self):
    return self.samp_rate_airspy

  def set_samp_rate_airspy(self, samp_rate_airspy):
    self.samp_rate_airspy = samp_rate_airspy
    self.set_samp_rate(self.samp_rate_airspy/self.decim)
    self.rtlsdr_source_0.set_sample_rate(self.samp_rate_airspy)

  def get_decim(self):
    return self.decim

  def set_decim(self, decim):
    self.decim = decim
    self.set_samp_rate(self.samp_rate_airspy/self.decim)

  def get_symb_rate(self):
    return self.symb_rate

  def set_symb_rate(self, symb_rate):
    self.symb_rate = symb_rate
    self.set_sps((self.samp_rate*1.0)/(self.symb_rate*1.0))
    self.root_raised_cosine_filter_0.set_taps(firdes.root_raised_cosine(1, self.samp_rate, self.symb_rate, 0.6, 361))

  def get_samp_rate(self):
    return self.samp_rate

  def set_samp_rate(self, samp_rate):
    self.samp_rate = samp_rate
    self.set_sps((self.samp_rate*1.0)/(self.symb_rate*1.0))
    self.root_raised_cosine_filter_0.set_taps(firdes.root_raised_cosine(1, self.samp_rate, self.symb_rate, 0.6, 361))

  def get_sps(self):
    return self.sps

  def set_sps(self, sps):
    self.sps = sps
    self.digital_clock_recovery_mm_xx_0.set_omega(self.sps)

  def get_pll_alpha(self):
    return self.pll_alpha

  def set_pll_alpha(self, pll_alpha):
    self.pll_alpha = pll_alpha
    self.digital_costas_loop_cc_0.set_loop_bandwidth(self.pll_alpha)

  def get_freq(self):
    return self.freq

  def set_freq(self, freq):
    self.freq = freq
    self.rtlsdr_source_0.set_center_freq(self.freq, 0)

  def get_clock_alpha(self):
    return self.clock_alpha

  def set_clock_alpha(self, clock_alpha):
    self.clock_alpha = clock_alpha
    self.digital_clock_recovery_mm_xx_0.set_gain_omega(self.clock_alpha**2/4.0)
    self.digital_clock_recovery_mm_xx_0.set_gain_mu(self.clock_alpha)

  def get_bitstream_name(self):
    return self.bitstream_name

  def set_bitstream_name(self, bitstream_name):
    self.bitstream_name = bitstream_name
    self.blocks_file_sink_0.open(self.bitstream_name)

def main(top_block_cls=top_block, options=None):
  tb = top_block_cls()
  tb.start()
  tb.wait()

if __name__ == '__main__':
  main()
