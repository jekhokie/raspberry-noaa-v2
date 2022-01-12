#ifndef PACKETPARSER_H
#define PACKETPARSER_H

#include <stdint.h>
#include <array>
#include "meteorimage.h"
#include "TimeSpan.h"

//Ported from https://github.com/artlav/meteor_decoder/blob/master/met_packet.pas

class PacketParser : public MeteorImage
{
public:
    PacketParser();

    void parseFrame(const uint8_t *frame, int len);

public:
    const TimeSpan getFirstTimeStamp() const {
        int64_t pixelTime = (mLastTimeStamp - mFirstTimeStamp).Ticks() / (mLastHeightAtTimeStamp - mFirstHeightAtTimeStamp);
        TimeSpan missingTime (pixelTime * mFirstHeightAtTimeStamp);

        return mFirstTimeStamp.Subtract(missingTime);
    }

    TimeSpan getLastTimeStamp() const {
        int64_t pixelTime = (mLastTimeStamp - mFirstTimeStamp).Ticks() / (mLastHeightAtTimeStamp - mFirstHeightAtTimeStamp);
        int missingPixelsTime = ((getLastY() + 8) - mLastHeightAtTimeStamp);
        TimeSpan missingTime (pixelTime * missingPixelsTime);

        return mLastTimeStamp.Add(missingTime);
    }

private:
    int parsePartial(const uint8_t *packet, int len);
    void parseAPD(const uint8_t *packet, int len);
    void actAPD(const uint8_t *packet, int len, int apd, int pck_cnt);
    void parse70(const uint8_t *packet, int len);

private:
    std::array<uint8_t, 2048> mPacketBuffer;
    int mLastFrame;
    int mPacketOff;
    bool mPartialPacket;
    TimeSpan mFirstTimeStamp;
    TimeSpan mLastTimeStamp;
    int mFirstHeightAtTimeStamp;
    int mLastHeightAtTimeStamp;
    bool mFirstTime;

private:
    static const int PACKET_FULL_MARK;
};

#endif // PACKETPARSER_H
