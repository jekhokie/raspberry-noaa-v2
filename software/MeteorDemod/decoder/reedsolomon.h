#ifndef REEDSOLOMON_H
#define REEDSOLOMON_H

#include <stdint.h>

//Ported from https://github.com/artlav/meteor_decoder/blob/master/alib/ecc.pas

class ReedSolomon
{
public:
    ReedSolomon();
    ~ReedSolomon();

    void deinterleave(const uint8_t *data, int pos, int n);
    void interleave(uint8_t *output, int pos, int n);
    int decode(int pad);


private:
    uint8_t mWorkBuffer[255];

};

#endif // REEDSOLOMON_H
