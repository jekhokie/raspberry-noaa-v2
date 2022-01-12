#ifndef DATABUFFER_H
#define DATABUFFER_H

#include <vector>
#include <stdint.h>
#include <stddef.h>
#include <string.h>

template<size_t N>
void byteswap_array(uint8_t (&bytes)[N]) {
  // Optimize this with a platform-specific API as desired.
  for (uint8_t *p = bytes, *end = bytes + N - 1; p < end; ++p, --end) {
    uint8_t tmp = *p;
    *p = *end;
    *end = tmp;
  }
}

template<typename T>
T byteswap(T value) {
  byteswap_array(*reinterpret_cast<uint8_t (*)[sizeof(value)]>(&value));
  return value;
}

enum Endianness {
    BigEndian,
    LittleEndian
};

class DataBuffer {
public:
    DataBuffer(size_t size)
        : mBuffer(size) {
    }
    virtual ~DataBuffer() {}

public:
    template <typename T>
    bool valueAtIndex(size_t &index, T &result, Endianness endiannes) const {
        if(mBuffer.size() < (index + sizeof(T))) {
            return false;
        }

        const T *p = reinterpret_cast<const T*>(&(mBuffer[index]));

        if(endiannes == BigEndian) {
            result = byteswap(*p);
        } else {
            result = *p;
        }

        index += sizeof(T);

        return true;
    }

    template <typename T, size_t N>
    bool valueAtIndex(size_t &index, T (&result)[N], Endianness endiannes) const {
        if(mBuffer.size() < (index + N)) {
            return false;
        }

        memcpy(result, &mBuffer[index], N);

        if(endiannes == BigEndian) {
            byteswap(result);
        }

        index += N;

        return true;
    }

public:
    size_t size() const {
        return  mBuffer.size();
    }

    uint8_t *buffer() {
        return mBuffer.data();
    }

    const uint8_t *constBuffer() const {
        return mBuffer.data();
    }

protected:
    std::vector<uint8_t> mBuffer;
};

#endif // DATABUFFER_H
