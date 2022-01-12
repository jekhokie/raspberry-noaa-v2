#include "packetparser.h"
const int PacketParser::PACKET_FULL_MARK = 2047;

PacketParser::PacketParser()
    : MeteorImage()
    , mLastFrame(0)
    , mPacketOff(0)
    , mPartialPacket(false)
    , mFirstTimeStamp(0)
    , mLastTimeStamp(0)
    , mFirstTime(true)
{

}

void PacketParser::parseFrame(const uint8_t *frame, int len)
{
    int n;

    uint16_t w = (frame[0] << 8) | frame[1];
    int ver = w >> 14;
    int ssid = (w >> 6) & 0xff;
    int fid = w & 0x3f;

    int frameCount = (frame[2] << 16) | (frame[3] << 8) | frame[4];

    w = (frame[8] << 8) | frame[9];
    uint8_t hdr_mark = w >> 11;
    uint16_t hdr_off = w & 0x7ff;

    if (ver == 0 || fid == 0) return;  // Empty packet

    int data_len = len - 10;
    if (frameCount == mLastFrame + 1) {
        if (mPartialPacket) {
            if (hdr_off == PACKET_FULL_MARK) {
                hdr_off = len - 10;
                std::move(frame + 10, frame + 10 + hdr_off, mPacketBuffer.begin() + mPacketOff);
                mPacketOff += hdr_off;
            } else {
                std::move(frame + 10, frame + 10 + hdr_off, mPacketBuffer.begin() + mPacketOff);
                n = parsePartial(mPacketBuffer.data(), mPacketOff + hdr_off);
            }
        }
    } else {
        if (hdr_off == PACKET_FULL_MARK) {
            return;
        }
        mPartialPacket = false;
        mPacketOff = 0;
    }
    mLastFrame = frameCount;

    data_len -= hdr_off;
    int off = hdr_off;
    while (data_len > 0) {
        n = parsePartial(frame + 10 + off, data_len);
        if (mPartialPacket) {
            mPacketOff = data_len;
            std::move(frame + 10 + off, frame + 10 + off + mPacketOff, mPacketBuffer.begin());
            break;
        } else {
            off += n;
            data_len -= n;
        }
    }
}

int PacketParser::parsePartial(const uint8_t *packet, int len)
{
    if (len < 6) {
        mPartialPacket = true;
        return 0;
      }

      int len_pck = (packet[4] << 8) | packet[5];
      if (len_pck >= len - 6) {
        mPartialPacket = true;
        return 0;
      }

      parseAPD(packet, len_pck + 1);

      mPartialPacket = false;
      return len_pck + 6 + 1;
}

void PacketParser::parseAPD(const uint8_t *packet, int len)
{
    uint16_t w = (packet[0] << 8) | packet[1];
    int sec = (w >> 11) & 1;
    int apd = w & 0x7ff;

    int pck_cnt = ((packet[2] << 8) | packet[3]) & 0x3fff;
    int len_pck = (packet[4] << 8) | packet[5];

    int ms = (packet[8] << 24) | (packet[9] << 16) | (packet[10] << 8) | packet[11];

    if (apd == 70) {
        parse70(packet + 14, len - 14);
    } else {
        actAPD(packet + 14, len - 14, apd, pck_cnt);
    }
}

void PacketParser::actAPD(const uint8_t *packet, int len, int apd, int pck_cnt)
{
    int mcu_id = packet[0];
    int scan_hdr = (packet[1] << 8) | packet[2];
    int seg_hdr = (packet[3] << 8) | packet[4];
    int q = packet[5];

    decMCUs(packet + 6, len - 6, apd, pck_cnt, mcu_id, q);
}

void PacketParser::parse70(const uint8_t *packet, int len)
{
    static int prevY;
    static TimeSpan prevtimeStamp(0);

    if(len < 11) {
        return;
    }

    int h = packet[8];
    int m = packet[9];
    int s = packet[10];
    int ms = packet[11] * 4;

    mLastTimeStamp = TimeSpan(0, h, m , s, ms * 1000);
    mLastHeightAtTimeStamp = getLastY();
    if (mFirstTime) {
        mFirstTime = false;
        mFirstTimeStamp = mLastTimeStamp;
        mFirstHeightAtTimeStamp = getLastY();
    } else {
        int lines = mLastHeightAtTimeStamp - prevY;
        TimeSpan elapsedTime = mLastTimeStamp - prevtimeStamp;

        //std::cout << "Lines between timestamp : " << lines << " Time elapsed " << elapsedTime << " PixelTime:" << TimeSpan(elapsedTime.Ticks() / lines) << std::endl;
    }

    prevY = getLastY();
    prevtimeStamp = mLastTimeStamp;

    //std::cout << "LastHeight: " << mLastHeightAtTimeStamp << " " << mLastTimeStamp << std::endl;

    //std::cout << "Onboard time: " << h << ":" << m << ":" << s << "." << ms;
}

