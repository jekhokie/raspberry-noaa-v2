#ifndef PLL_H
#define PLL_H

#include <complex>

namespace DSP {

class PLL
{
public:
    typedef std::complex<float> complex;

public:
    PLL(float bandWidth, float lockLimit = 0.77f, float unlockLimit = 0.82f);

    complex mix(const complex &sample);

    float delta(const complex &sample, const complex &cosamp);
    void recomputeCoeffs(float damping, float bw);
    void correctPhase(float err);

    void setLockLimit(float limit) {
        mLockLimit = limit;
    }
    void setUnlockLimit(float limit) {
        mUnlockLimit = limit;
    }

public:
    bool isLocked() const {
        return mIsLocked;
    }

    float getMovingAverage() const {
        return mMovingAvg;
    }

    float getPhase() const {
        return mNcoPhase;
    }

    float getFrequency() const {
        return mNcoFreqency;
    }

private:
    float mBandWidth;
    float mLockLimit;
    float mUnlockLimit;
    float mNcoPhase;
    float mNcoFreqency;
    float mAlpha;
    float mBeta;
    float mDamping;
    float mMovingAvg;
    bool mIsLocked;

private:
    static float TAN_LOOKUP_TABLE[256];

    static constexpr float PLL_DAMP = static_cast<float>(1.0/M_SQRT2);
    static constexpr float  PLL_INIT_FREQ = 0.001f;
    static constexpr float  FREQ_MAX = 0.8f;
    static constexpr uint32_t AVG_WINSIZE = 2500;

private:
    static float lutTanh(float value) {
        if (value > 127) {
            return 1;
        }
        if (value < -128) {
            return -1;
        }

        return TAN_LOOKUP_TABLE[static_cast<int>(value)+128];
    }

    static float floatClamp(float x, float maxAbs) {
        if (x > maxAbs) {
            return maxAbs;
        } else if (x < -maxAbs) {
            return -maxAbs;
        }
        return x;
    }
};

} //namespace DSP

#endif // PLL_H
