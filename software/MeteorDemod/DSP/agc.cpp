#include "agc.h"

namespace DSP {

Agc::Agc()
    : mWindowSize(AGC_WINSIZE)
    , mAvg(AGC_TARGET)
    , mGain(1)
    , mTargetAmplitude(AGC_TARGET)
    , mBias(0)
{

}

Agc::complex Agc::process(complex sample)
{
    float rho;

    mBias = (mBias * static_cast<float>(AGC_BIAS_WINSIZE - 1) + sample) / static_cast<float>(AGC_BIAS_WINSIZE);
    sample -= mBias;

    // Update the sample magnitude average
    rho = sqrtf(std::real(sample) * std::real(sample) + std::imag(sample) * std::imag(sample));
    mAvg = (mAvg * (mWindowSize - 1) + rho) / mWindowSize;

    mGain = mTargetAmplitude / mAvg;
    if (mGain > AGC_MAX_GAIN) {
        mGain = AGC_MAX_GAIN;
    }
    return sample * mGain;
}

} //namespace DSP
