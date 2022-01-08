#ifndef CORRELATION_H
#define CORRELATION_H

#include <stdint.h>
#include <functional>

class Correlation
{
public:
    struct CorellationResult {
        uint32_t corr;
        uint32_t pos;
    };

    enum PhaseShift {
        PhaseShift_0 = 0,
        PhaseShift_1,
        PhaseShift_2,
        PhaseShift_3,
        PhaseShift_4,
        PhaseShift_5,
        PhaseShift_6,
        PhaseShift_7
    };

public:
    typedef std::function<uint32_t(CorellationResult &, PhaseShift)>CorrelationCallback;

public:
    Correlation();

    void correlate(const uint8_t *softBits, int64_t size, CorrelationCallback callback);
    uint8_t rotateIQ(uint8_t data, PhaseShift phaseShift);

private:
    void initKernels();
    uint32_t hardCorrelate(uint8_t dataByte, uint8_t wordByte);

private:
    uint8_t mRotateIqTable[256];
    uint8_t mRotateIqTableInverted[256];
    uint8_t mKernelUW0[64];
    uint8_t mKernelUW1[64];
    uint8_t mKernelUW2[64];
    uint8_t mKernelUW3[64];
    uint8_t mKernelUW4[64];
    uint8_t mKernelUW5[64];
    uint8_t mKernelUW6[64];
    uint8_t mKernelUW7[64];

private:
    static constexpr uint64_t UW0 = 0xFCA2B63DB00D9794;
    static constexpr uint64_t UW1 = 0x56FBD394DAA4C1C2;
    static constexpr uint64_t UW2 = 0x035D49C24FF2686B;
    static constexpr uint64_t UW3 = 0xA9042C6B255B3E3D;
    static constexpr uint64_t UW4 = 0xFC51793E700E6B68;
    static constexpr uint64_t UW5 = 0xA9F7E368E558C2C1;
    static constexpr uint64_t UW6 = 0x03AE86C18FF19497;
    static constexpr uint64_t UW7 = 0x56081C971AA73D3E;

    static constexpr uint8_t CORRELATION_LIMIT = 54;

public:
    static void rotateSoftIqInPlace(uint8_t *data, uint32_t length, PhaseShift phaseShift);

    static int countBits(uint32_t i)
    {
        i = i - ((i >> 1) & 0x55555555);
        i = (i & 0x33333333) + ((i >> 2) & 0x33333333);
        return (((i + (i >> 4)) & 0x0F0F0F0F) * 0x01010101) >> 24;
    }
};

#endif // CORRELATION_H
