#include "pll.h"
#include <cmath>

namespace DSP {

float PLL::TAN_LOOKUP_TABLE[256];

PLL::PLL(float bandWidth, float lockLimit, float unlockLimit)
    : mBandWidth(bandWidth)
    , mLockLimit(lockLimit)
    , mUnlockLimit(unlockLimit)
    , mNcoPhase(0)
    , mNcoFreqency(PLL_INIT_FREQ)
    , mDamping(PLL_DAMP)
    , mMovingAvg(1)
    , mIsLocked(false)
{
    for (int i = 0; i < 256; i++) {
        TAN_LOOKUP_TABLE[i] = tanhf((i-128.0f));
    }

    recomputeCoeffs(PLL_DAMP, mBandWidth);

}

PLL::complex PLL::mix(const complex &sample)
{
    using namespace std::complex_literals;

    complex ncoOut;
    complex retval;

    ncoOut = std::exp(complex(-1.0if * mNcoPhase));
    retval = sample * ncoOut;
    mNcoPhase += mNcoFreqency;

    return retval;
}

float PLL::delta(const PLL::complex &sample, const PLL::complex &cosamp)
{
    float error;

    error = (lutTanh(std::real(sample)) * std::imag(sample)) - (lutTanh(std::imag(cosamp)) * std::real(cosamp));

    return error / 50.0f;
}

void PLL::recomputeCoeffs(float damping, float bw)
{
    float denom;

    denom = 1.0f + 2.0f * damping * bw + bw * bw;
    mAlpha = (4 * damping * bw) / denom;
    mBeta = (4 * bw * bw) / denom;
}

void PLL::correctPhase(float err)
{
    err = floatClamp(err, 1.0f);
    mNcoPhase = std::fmod(mNcoPhase + mAlpha * err, static_cast<float>(2.0 * M_PI));
    mNcoFreqency = mNcoFreqency + mBeta * err;

    mMovingAvg = (mMovingAvg * (AVG_WINSIZE-1) + std::fabs(err)) / AVG_WINSIZE;

    // Detect whether the PLL is locked, and decrease the BW if it is
    if (!mIsLocked && mMovingAvg < mLockLimit) {
        recomputeCoeffs(mDamping, mBandWidth / 10.0f);
        mIsLocked = true;
    } else if (mIsLocked && mMovingAvg > mUnlockLimit) {
        recomputeCoeffs(mDamping, mBandWidth);
        mIsLocked = false;
    }


    // Limit frequency to a sensible range
    if (mNcoFreqency <= -FREQ_MAX) {
        mNcoFreqency = -FREQ_MAX/2;
    } else if (mNcoFreqency >= FREQ_MAX) {
        mNcoFreqency = FREQ_MAX/2;
    }
}

} //namespace DSP
