#include "correlation.h"

Correlation::Correlation()
{
    //init rotation table
    for(int i = 0; i < 255; i++) {
        mRotateIqTable[i] = (((i & 0x55) ^ 0x55) << 1) | ((i & 0xAA) >> 1);
        mRotateIqTableInverted[i] = (((i & 0x55)) << 1) | ((i & 0xAA) >> 1);
    }

    initKernels();
}

void Correlation::correlate(const uint8_t *softBits, int64_t size, CorrelationCallback callback)
{
    CorellationResult resultUW0;
    CorellationResult resultUW1;
    CorellationResult resultUW2;
    CorellationResult resultUW3;
    CorellationResult resultUW4;
    CorellationResult resultUW5;
    CorellationResult resultUW6;
    CorellationResult resultUW7;

    resultUW0.pos = 0;
    resultUW0.corr = 0;
    resultUW1.pos = 0;
    resultUW1.corr = 0;
    resultUW2.pos = 0;
    resultUW2.corr = 0;
    resultUW3.pos = 0;
    resultUW3.corr = 0;
    resultUW4.pos = 0;
    resultUW4.corr = 0;
    resultUW5.pos = 0;
    resultUW5.corr = 0;
    resultUW6.pos = 0;
    resultUW6.corr = 0;
    resultUW7.pos = 0;
    resultUW7.corr = 0;

    for (uint32_t i = 0; i < size - 64; i++) {
        uint32_t c0 = 0;
        uint32_t c1 = 0;
        uint32_t c2 = 0;
        uint32_t c3 = 0;
        uint32_t c4 = 0;
        uint32_t c5 = 0;
        uint32_t c6 = 0;
        uint32_t c7 = 0;

        for (int k = 0; k < 64; k++) {
            c0 += hardCorrelate(softBits[i+k], mKernelUW0[k]);
            c1 += hardCorrelate(softBits[i+k], mKernelUW1[k]);
            c2 += hardCorrelate(softBits[i+k], mKernelUW2[k]);
            c3 += hardCorrelate(softBits[i+k], mKernelUW3[k]);
            c4 += hardCorrelate(softBits[i+k], mKernelUW4[k]);
            c5 += hardCorrelate(softBits[i+k], mKernelUW5[k]);
            c6 += hardCorrelate(softBits[i+k], mKernelUW6[k]);
            c7 += hardCorrelate(softBits[i+k], mKernelUW7[k]);
        }

        resultUW0.pos = c0 > resultUW0.corr ? i : resultUW0.pos;
        resultUW0.corr = c0 > resultUW0.corr ? c0 : resultUW0.corr;

        resultUW1.pos = c1 > resultUW1.corr ? i : resultUW1.pos;
        resultUW1.corr = c1 > resultUW1.corr ? c1 : resultUW1.corr;

        resultUW2.pos = c2 > resultUW2.corr ? i : resultUW2.pos;
        resultUW2.corr = c2 > resultUW2.corr ? c2 : resultUW2.corr;

        resultUW3.pos = c3 > resultUW3.corr ? i : resultUW3.pos;
        resultUW3.corr = c3 > resultUW3.corr ? c3 : resultUW3.corr;

        resultUW4.pos = c4 > resultUW4.corr ? i : resultUW4.pos;
        resultUW4.corr = c4 > resultUW4.corr ? c4 : resultUW4.corr;

        resultUW5.pos = c5 > resultUW5.corr ? i : resultUW5.pos;
        resultUW5.corr = c5 > resultUW5.corr ? c5 : resultUW5.corr;

        resultUW6.pos = c6 > resultUW6.corr ? i : resultUW6.pos;
        resultUW6.corr = c6 > resultUW6.corr ? c6 : resultUW6.corr;

        resultUW7.pos = c7 > resultUW7.corr ? i : resultUW7.pos;
        resultUW7.corr = c7 > resultUW7.corr ? c7 : resultUW7.corr;

        if(resultUW0.corr >= CORRELATION_LIMIT) {
            i += callback(resultUW0, PhaseShift_0);

            resultUW0.pos = 0;
            resultUW0.corr = 0;

            continue;
        }

        if(resultUW1.corr >= CORRELATION_LIMIT) {
            i += callback(resultUW1, PhaseShift_1);

            resultUW1.pos = 0;
            resultUW1.corr = 0;

            continue;
        }

        if(resultUW2.corr >= CORRELATION_LIMIT) {
            i += callback(resultUW2, PhaseShift_2);

            resultUW2.pos = 0;
            resultUW2.corr = 0;

            continue;
        }

        if(resultUW3.corr >= CORRELATION_LIMIT) {
            i += callback(resultUW3, PhaseShift_3);

            resultUW3.pos = 0;
            resultUW3.corr = 0;

            continue;
        }

        if(resultUW4.corr >= CORRELATION_LIMIT) {
            i += callback(resultUW4, PhaseShift_4);

            resultUW4.pos = 0;
            resultUW4.corr = 0;

            continue;
        }

        if(resultUW5.corr >= CORRELATION_LIMIT) {
            i += callback(resultUW5, PhaseShift_5);

            resultUW5.pos = 0;
            resultUW5.corr = 0;

            continue;
        }

        if(resultUW6.corr >= CORRELATION_LIMIT) {
            i += callback(resultUW6, PhaseShift_6);

            resultUW6.pos = 0;
            resultUW6.corr = 0;

            continue;
        }

        if(resultUW7.corr >= CORRELATION_LIMIT) {
            i += callback(resultUW7, PhaseShift_7);

            resultUW7.pos = 0;
            resultUW7.corr = 0;

            continue;
        }
    }
}

void Correlation::initKernels()
{
    for (int i = 0; i < 64; i++) {
        mKernelUW0[i] = (UW0 >> (64-i-1)) & 1 ? 0xFF : 0x00;
        mKernelUW1[i] = (UW1 >> (64-i-1)) & 1 ? 0xFF : 0x00;
        mKernelUW2[i] = (UW2 >> (64-i-1)) & 1 ? 0xFF : 0x00;
        mKernelUW3[i] = (UW3 >> (64-i-1)) & 1 ? 0xFF : 0x00;
        mKernelUW4[i] = (UW4 >> (64-i-1)) & 1 ? 0xFF : 0x00;
        mKernelUW5[i] = (UW5 >> (64-i-1)) & 1 ? 0xFF : 0x00;
        mKernelUW6[i] = (UW6 >> (64-i-1)) & 1 ? 0xFF : 0x00;
        mKernelUW7[i] = (UW7 >> (64-i-1)) & 1 ? 0xFF : 0x00;
    }
}

uint32_t Correlation::hardCorrelate(uint8_t dataByte, uint8_t wordByte) {
  //1 if (a        > 127 and       b == 255) or (a        < 127 and       b == 0) else 0
  return (dataByte >= 127 & wordByte == 0) | (dataByte < 127 & wordByte == 255);
}

uint8_t Correlation::rotateIQ(uint8_t data, PhaseShift phaseShift)
{
    uint8_t result = data;
    uint8_t shift = phaseShift;

    if(shift > 3) {
        shift -= 4;
        result = mRotateIqTableInverted[data];
    }

    if(shift == 1 || shift == 3) {
        result = mRotateIqTable[result];
    }

    if(shift == 1 || shift == 2) {
        result ^= 0xFF;
    }

    return result;
}

void Correlation::rotateSoftIqInPlace(uint8_t *data, uint32_t length, PhaseShift phaseShift)
{
    uint8_t b;

    switch (phaseShift) {
        case 0:
            for (uint32_t i = 0; i < length; i++) {
                data[i] = -data[i];
                data[i] = data[i] ^ 0x7F;
            }
            break;
        case 1:
            for (uint32_t i = 0; i < length; i+=2) {
                b = data[i];
                data[i] = -data[i + 1];
                data[i+1] = b;

                data[i+1] = data[i+1] ^ 0x7F;
                data[i] = data[i] ^ 0x7F;
            }
            break;
        case 2:
            for (uint32_t i = 0; i < length; i++) {
                data[i] = data[i] ^ 0x7F;

                data[i+1] = data[i+1] ^ 0x7F;
                data[i] = data[i] ^ 0x7F;
            }
            break;
        case 3:
            for (uint32_t i = 0; i < length; i+=2) {
                b = data[i];
                data[i] = -data[i + 1];
                data[i+1] = b;

                data[i+1] = data[i+1] ^ 0x7F;
                data[i] = data[i] ^ 0x7F;
            }
            break;
        case 4:
            for (uint32_t i = 0; i < length; i+=2) {
                b = data[i];
                data[i] = -data[i + 1];
                data[i+1] = -b;

                data[i+1] = data[i+1] ^ 0x7F;
                data[i] = data[i] ^ 0x7F;
            }
            break;
        case 5:
            for (uint32_t i = 0; i < length; i+=2) {
                data[i] = -data[i];

                data[i+1] = data[i+1] ^ 0x7F;
                data[i] = data[i] ^ 0x7F;
            }
            break;
        case 6:
            for (uint32_t i = 0; i < length; i+=2) {
                b = data[i];
                data[i] = data[i + 1];
                data[i+1] = b;

                data[i+1] = data[i+1] ^ 0x7F;
                data[i] = data[i] ^ 0x7F;
            }
            break;
        case 7:
            for (uint32_t i = 0; i < length; i+=2) {
                data[i+1] = -data[i+1];

                data[i+1] = data[i+1] ^ 0x7F;
                data[i] = data[i] ^ 0x7F;
            }
            break;
    }
}




