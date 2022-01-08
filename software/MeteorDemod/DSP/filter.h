#ifndef FILTER_H
#define FILTER_H

#include <complex>
#include <vector>
#include <list>

namespace DSP {

class FilterBase
{
public:
    typedef std::complex<float> complex;
public:
    FilterBase(int taps);
    virtual ~FilterBase() {}
    complex process(const complex &in);

protected:
    std::vector<float> mCoeffs;
    std::list<complex> mMemory;
    int mTaps;
};

class RRCFilter : public FilterBase {
public:
    RRCFilter(unsigned order, unsigned factor, float osf, float alpha);

private:
    float computeCoeffs(int stageNo, uint16_t taps, float osf, float alpha);
};

} //namespace DSP

#endif // FILTER_H
