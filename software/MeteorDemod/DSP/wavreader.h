#ifndef WAVREADER_H
#define WAVREADER_H

#include <stdint.h>
#include <iostream>
#include <fstream>
#include "iqsource.h"

#ifdef __GNUC__
#define PACK( __Declaration__ ) __Declaration__ __attribute__((__packed__))
#endif

#ifdef _MSC_VER
#define PACK( __Declaration__ ) __pragma( pack(push, 1) ) __Declaration__ __pragma( pack(pop))
#endif


class Wavreader: public DSP::IQSoruce
{
private:
    PACK(struct WavHeader
    {
        uint32_t riffHeader;
        uint32_t chunkSize;
        uint32_t filetype;
        char fmtHeader[4];
        uint32_t subchunkSize;
        uint16_t audioFormat;
        uint16_t numChannels;
        uint32_t sampleRate;
        uint32_t byteRate;
        uint16_t blockAlign;
        uint16_t bitsPerSample;
        uint32_t dataHeader;
        uint32_t subChunk2Size;
    });

public:
    Wavreader();

    bool openFile(std::string file);

    uint32_t read(complex *data, uint32_t len) override;

private:
     std::ifstream mWavStream;
};

#endif // WAVREADER_H
