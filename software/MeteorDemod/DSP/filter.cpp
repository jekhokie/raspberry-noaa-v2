#include "filter.h"
#include <cmath>

namespace DSP {

FilterBase::FilterBase(int taps)
    : mTaps (taps)
{

}

FilterBase::complex FilterBase::process(const FilterBase::complex &in)
{
    complex out = 0.0f;

    mMemory.push_front(in);
    mMemory.pop_back();

    std::list<complex>::const_reverse_iterator it = mMemory.crbegin();

    for(int i = mTaps - 1; i >=0; --i, ++it) {
        out += (*it) * mCoeffs[i];
    }
    return out;
}

RRCFilter::RRCFilter(unsigned order, unsigned factor, float osf, float alpha)
    :FilterBase(order * 2 + 1)
{
    for (uint16_t i=0; i < mTaps; i++) {
        mCoeffs.emplace_back(computeCoeffs(i, mTaps, osf * factor, alpha));
    }

    mMemory.resize(mTaps, 0);
}

float RRCFilter::computeCoeffs(int stageNo, uint16_t taps, float osf, float alpha)
{
    float coeff;
    float t;
    float interm;
    int order;

    order = (taps - 1)/2;

    if (order == stageNo) {
        return 1 - alpha + 4 * alpha / M_PI;
    }

    t = std::abs(order - stageNo) / osf;
    coeff = std::sin(M_PI * t * (1 - alpha)) + 4 * alpha * t * std::cos(M_PI * t * (1 + alpha));
    interm = M_PI * t * (1 - (4 * alpha * t) * (4 * alpha * t));

    return coeff / interm;
}

} //namespace DSP

