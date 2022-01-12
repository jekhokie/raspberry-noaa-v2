#ifndef METEORIMAGE_H
#define METEORIMAGE_H

#include <array>
#include <vector>
#include <opencv2/core.hpp>
#include <opencv2/imgproc.hpp>
#include "threatimage.h"

//Based on: https://github.com/artlav/meteor_decoder/blob/master/met_jpg.pas


#ifdef __GNUC__
#define PACK( __Declaration__ ) __Declaration__ __attribute__((__packed__))
#endif

#ifdef _MSC_VER
#define PACK( __Declaration__ ) __pragma( pack(push, 1) ) __Declaration__ __pragma( pack(pop))
#endif

union Pixel {
     PACK(struct {
         uint8_t b;
         uint8_t g;
         uint8_t r;
         uint8_t a;
     });
     uint32_t pixel;
};

struct ac_table_rec {
  int run;
  int size;
  int len;
  uint32_t mask;
  uint32_t code;
};

class MeteorImage
{
public:
    enum ChannelIDs {
        APID_68 = 68,   //R
        APID_66 = 66,   //B
        APID_65 = 65,   //G
        APID_64 = 64    //R
    };

public:
    MeteorImage();
    virtual ~MeteorImage();

    cv::Mat getRGBImage(ChannelIDs redAPID, ChannelIDs greenAPID, ChannelIDs blueAPID, bool fillBlackLines = true);
    cv::Mat getChannelImage(ChannelIDs APID, bool fillBlackLines = true);

public:
    bool isChannel64Available() const {
        return mIsChannel64Available;
    }
    bool isChannel65Available() const {
        return mIsChannel65Available;
    }
    bool isChannel66Available() const {
        return mIsChannel66Available;
    }
    bool isChannel68Available() const {
        return mIsChannel68Available;
    }

protected:
    void decMCUs(const uint8_t *packet, int len, int apd, int pck_cnt, int mcu_id, uint8_t q);

    int getLastY() const {
        return mLastY;
    }

    int getCurrentY() const {
        return mCurY;
    }

private:
    void initHuffmanTable();
    void initCos();
    int getDcReal(uint16_t word);
    int getAcReal(uint16_t word);
    bool progressImage(int apd, int mcuID, int pckCnt);
    void fillDqtByQ(std::array<int, 64> &dqt, int q);
    int mapRange(int cat, int vl);
    void filtIdct8x8(std::array<float, 64> &res, std::array<float, 64> &inp);
    void fillPix(std::array<float, 64> &imgDct, int apd, int mcu_id, int m);

private:
    bool mIsChannel64Available;
    bool mIsChannel65Available;
    bool mIsChannel66Available;
    bool mIsChannel68Available;

    std::vector<Pixel> mFullImage;
    int mLastMCU, mCurY, mLastY, mFirstPacket, mPrevPacket;
    std::array<int, 65536> mAcLookup {}, mDcLookup {};
    std::array<ac_table_rec, 162> mAcTable {};
    std::array<std::array<float, 8>, 8> mCosine {};
    std::array<float, 8> mAlpha;
};

#endif // METEORIMAGE_H
