#include "wavreader.h"


Wavreader::Wavreader()
{

}

bool Wavreader::openFile(std::string file)
{
    struct WavHeader wavHeader;
    bool success = true;

    mWavStream.open(file, std::ifstream::binary);

    do {
        if(!mWavStream.is_open()) {
            success = false;
            break;
        }

        mWavStream.read(reinterpret_cast<char*>(&wavHeader), sizeof(wavHeader));

        if(wavHeader.riffHeader != 0x46464952) {
            success = false;
            break;
        }

        if(wavHeader.filetype != 0x45564157) {
            success = false;
            break;
        }

        if(wavHeader.dataHeader != 0x61746164) {
            success = false;
            break;
        }

        mSampleRate = wavHeader.sampleRate;
        mBitsPerSample = wavHeader.bitsPerSample;
        mTotalSamples = wavHeader.subChunk2Size / wavHeader.numChannels / (wavHeader.bitsPerSample / 8);

    } while(false);

    return success;
}

uint32_t Wavreader::read(complex *data, uint32_t len)
{
    uint8_t buffer8bit[2];
    int16_t buffer16bit[2];
    uint32_t samplesCount = 0;

    if(!mWavStream.is_open()) {
        return 0;
    }

    do {
        if(mBitsPerSample == 8) {
            mWavStream.read(reinterpret_cast<char*>(buffer8bit), sizeof(buffer8bit));
            if(mWavStream.gcount() != sizeof(buffer8bit)) {
                break;
            }

            data[samplesCount] = complex(static_cast<float>(buffer8bit[0]), static_cast<float>(buffer8bit[1]));
        } else if(mBitsPerSample == 16) {
            mWavStream.read(reinterpret_cast<char*>(buffer16bit), sizeof(buffer16bit));
            if(mWavStream.gcount() != sizeof(buffer16bit)) {
                break;
            }

            data[samplesCount] = complex(static_cast<float>(buffer16bit[0]), static_cast<float>(buffer16bit[1]));
        } else {
            break;
        }

        samplesCount++;
        mReadedSamples++;

        if(samplesCount == len) {
            break;
        }

    } while(true);

    return samplesCount;
}
