#ifndef IQSOURCE_H
#define IQSOURCE_H

#include <complex>

namespace DSP {

class IQSoruce {
public:
    typedef std::complex<float> complex;
public:
    IQSoruce();
    virtual ~IQSoruce() {}

    virtual uint32_t read(complex *data, uint32_t len) = 0;


public: //getters
    uint32_t getSampleRate() const {
        return mSampleRate;
    }

    uint32_t getBitsPerSample() const {
        return mBitsPerSample;
    }

    uint32_t getTotalSamples() const {
        return mTotalSamples;
    }

    uint32_t getReadedSamples() const {
        return mReadedSamples;
    }

protected:
    uint16_t mBitsPerSample;
    uint32_t mSampleRate;
    uint32_t mTotalSamples;
    uint32_t mReadedSamples;
};

} //namespace DSP

#endif // IQSOURCE_H
