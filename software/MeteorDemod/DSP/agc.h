#ifndef AGC_H
#define AGC_H

#include <complex>

namespace DSP {

class Agc
{
public:
    typedef std::complex<float> complex;

public:
    Agc();

    complex process(complex sample);

public:
    float getGain() const {
        return mGain;
    }

private:
    uint32_t mWindowSize;
    float mAvg;
    float mGain;
    float mTargetAmplitude;
    complex mBias;

private:
    static constexpr uint32_t AGC_WINSIZE = 1024*64;
    static constexpr uint32_t AGC_TARGET = 180;
    static constexpr uint32_t AGC_MAX_GAIN = 20;
    static constexpr uint32_t AGC_BIAS_WINSIZE = 256*1024;
};

} //namespace DSP

#endif // AGC_H
