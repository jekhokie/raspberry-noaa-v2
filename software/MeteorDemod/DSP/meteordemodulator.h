#ifndef METEORDEMODULATOR_H
#define METEORDEMODULATOR_H

#include <functional>
#include "iqsource.h"
#include "pll.h"
#include "filter.h"
#include "agc.h"

namespace DSP {

class MeteorDemodulator
{
public:
    typedef std::function<void(const PLL::complex&, float progress)> MeteorDecoderCallback_t;

    enum Mode {
        QPSK,
        OQPSK
    };

public:
    MeteorDemodulator(Mode mode, float symbolRate, bool waitForLock = true, float costasBw = 100.0f, uint16_t rrcFilterOrder = 64, uint16_t interploationFacor = 4, float rrcFilterAlpha = 0.6f);
    ~MeteorDemodulator();

    MeteorDemodulator &operator=(const MeteorDemodulator &) = delete;
    MeteorDemodulator(const MeteorDemodulator &) = delete;
    MeteorDemodulator &operator=(MeteorDemodulator &&) = delete;
    MeteorDemodulator(MeteorDemodulator &&) = delete;

    void process(IQSoruce &source, MeteorDecoderCallback_t callback);

private:
    void interpolator(FilterBase &filter, PLL::complex *inSamples, int inSamplesCount, int factor, PLL::complex *outSamples);

private:
    Mode mMode;
    float mSymbolRate;
    bool mWaitForLock;
    float mCostasBw;
    uint16_t rrcFilterOrder;
    uint16_t mInterploationFacor;
    float rrcAlpha;
    Agc mAgc;
    PLL::complex *samples;
    PLL::complex *interpolatedSamples;

private:
    static constexpr uint32_t CHUNK_SIZE = 8192;
};

} // namespace DSP

#endif // METEORDEMODULATOR_H
