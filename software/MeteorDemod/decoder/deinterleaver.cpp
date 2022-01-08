#include "deinterleaver.h"
#include <string.h>
#include <vector>
#include <iostream>
#include <iomanip>

static const int INTER_BRANCHES = 36;
static const int INTER_DELAY = 2048;
static const int INTER_BASE_LEN = INTER_BRANCHES * INTER_DELAY;

DeInterleaver::DeInterleaver()
{

}


bool DeInterleaver::findSync(uint8_t *data, uint64_t len, uint32_t step, uint32_t depth, uint64_t *off, uint8_t *sync)
{
    bool result = false;
    *off = 0;
    for (uint64_t i = 0; i < len - step * depth; i++) {
        *sync = byteAt(&data[i]);
        result = true;

        for(uint64_t j = 1; j <= depth; j++) {
            if(*sync != byteAt(&data[i + j * step])) {
                result = false;
                break;
            }
        }

        if(result) {
            *off = i;
            break;
        }
    }

    return result;
}

void DeInterleaver::deInterleave(uint8_t *data, uint64_t len, uint64_t *outLen)
{
    std::vector<uint8_t> src(len);

    resyncStream(data, len, outLen);

    memcpy(src.data(), data, *outLen);
    memset(data, 0, *outLen);

    deInterleaveBlock(src.data(), data, *outLen);
}

void DeInterleaver::deInterleaveBlock(uint8_t *src, uint8_t *dst, uint64_t len)
{
    uint64_t pos;
    for(uint64_t i = 0; i < len; i++) {
        pos = i + (INTER_BRANCHES - 1) * INTER_DELAY - (i % INTER_BRANCHES) * INTER_BASE_LEN;
        //Offset it by half a message, to capture both leading and trailing fuzz
        pos += (INTER_BRANCHES / 2) * INTER_BASE_LEN;
        if(pos >= 0 && pos < len) {
            dst[pos] = src[i];
        }
    }
}

//80k stream: 00100111 36 bits 36 bits 00100111 36 bits 36 bits 00100111 ...
void DeInterleaver::resyncStream(uint8_t *data, uint64_t len, uint64_t *outLen)
{
    std::vector<uint8_t> src(data, data + len);
    uint64_t off;
    uint64_t pos = 0;
    bool ok;
    uint8_t sync;
    *outLen = 0;

    while(pos < len - 80 * 4) {
        if(!findSync(&src.data()[pos], 80 * 5, 80, 4, &off, &sync)) {
            pos += 80 * 3;
            continue;
        }

        std::cout << std::fixed << std::setprecision(2) << ((float)pos / len) * 100 << "% Found sync at " << pos << "\t\t\t\r" << std::flush;

        pos += off;

        while(pos < len - 80) {
            //Look ahead to prevent it losing sync on weak signal
            ok = false;
            for(int i = 0; i < 128; i++) {
                if(pos + i * 80 < len - 80) {
                    if(byteAt(&src.data()[pos + i * 80]) == sync) {
                        ok = true;
                        break;
                    }
                }
            }

            if(!ok) {
                break;
            }

            memcpy(&data[*outLen], &src.data()[pos + 8], 72);
            pos += 80;
            *outLen += 72;
        }

        std::cout << std::fixed << std::setprecision(2) << ((float)pos / len) * 100 << "% Sync lost at " << pos << "\t\t\t\r" << std::flush;
    }

    std::cout << std::endl;
}

uint8_t DeInterleaver::byteAt(uint8_t *data)
{
    uint8_t result = 0;

    for(int i = 0; i < 8; i++) {
        result = result | (data[i] < 128 ? 0 : 1) << i;
    }

    return result;
}

