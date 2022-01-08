#include "bitio.h"

BitIOConst::BitIOConst(const uint8_t *bytes)
    : mpBytes(bytes)
    , mPos(0)
{

}

uint32_t BitIOConst::peekBits(int n)
{
    uint32_t result = 0;
    for (int i = 0; i < n; i++) {
        int p = mPos + i;
        int bit = (mpBytes[p >> 3] >> (7 - (p & 7))) & 1;
        result = (result << 1) | bit;
    }
    return result;
}

void BitIOConst::advanceBits(int n)
{
    mPos += n;
}

uint32_t BitIOConst::fetchBits(int n)
{
    uint32_t result = peekBits(n);
    advanceBits(n);
    return result;
}

BitIO::BitIO(uint8_t *bytes, int len)
    : mpBytes(bytes)
    , mPos(0)
    , mLength(len)
    , mCurrent(0)
    , mCurrentLength(0) {

}

BitIO::~BitIO()
{

}

void BitIO::writeBitlistReversed(uint8_t *list, int len)
{
    list = list + len - 1;

    uint8_t *pBytes = mpBytes;
    int byteIndex = mPos;

    uint16_t b;

    if (mCurrentLength != 0) {
        int closeLen = 8 - mCurrentLength;
        if (closeLen >= len) {
            closeLen = len;
        }

        b = mCurrent;

        for (int i = 0; i < closeLen; i++) {
            b |= list[0];
            b = b << 1;
            list--;
        }

        len -= closeLen;

        if ((mCurrentLength + closeLen) == 8) {
            b = b >> 1;
            pBytes[byteIndex] = b;
            byteIndex++;
        } else {
            mCurrent = b;
            mCurrentLength += closeLen;
        }
    }

    int fullBytes = len / 8;

    for (int i = 0; i < fullBytes; i++) {
        pBytes[byteIndex] =
            (*(list - 0) << 7) | (*(list - 1) << 6) | (*(list - 2) << 5) |
            (*(list - 3) << 4) | (*(list - 4) << 3) | (*(list - 5) << 2) |
            (*(list - 6) << 1) | (*(list - 7));
        byteIndex++;
        list -= 8;
    }

    len -= 8 * fullBytes;

    b = 0;
    for (int i = 0; i < len; i++) {
        b |= list[0];
        b = b << 1;
        list--;
    }

    mCurrent = b;
    mPos = byteIndex;
    mCurrentLength = len;
}
