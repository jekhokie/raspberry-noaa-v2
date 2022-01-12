#ifndef DEINTERLEAVER_H
#define DEINTERLEAVER_H

#include <stdint.h>

class DeInterleaver
{
private:
    DeInterleaver();

public:
    static void deInterleave(uint8_t *data, uint64_t len, uint64_t *outLen);

private:
    static bool findSync(uint8_t *data, uint64_t len, uint32_t step, uint32_t depth, uint64_t *off, uint8_t *sync);
    static void deInterleaveBlock(uint8_t *src , uint8_t *dst, uint64_t len);
    static void resyncStream(uint8_t *data, uint64_t len, uint64_t *outLen);
    static uint8_t byteAt(uint8_t *data);
};

#endif // DEINTERLEAVER_H
