#include <cmath>

#include "meteorimage.h"
#include <iostream>
#include <sstream>
#include "bitio.h"
#include <opencv2/imgcodecs.hpp>

const uint MCU_PER_PACKET = 14;
const uint MCU_PER_LINE = 196;

const std::array<uint8_t, 64> STANDARD_QUANTIZATION_TABLE {
  16, 11, 10, 16, 24, 40, 51, 61, 12, 12, 14, 19, 26, 58, 60, 55, 14, 13, 16,
      24, 40, 57, 69, 56, 14, 17, 22, 29, 51, 87, 80, 62, 18, 22, 37, 56, 68,
      109, 103, 77, 24, 35, 55, 64, 81, 104, 113, 92, 49, 64, 78, 87, 103, 121,
      120, 101, 72, 92, 95, 98, 112, 100, 103, 99
};

const std::array<uint8_t, 64> ZIGZAG {
  0, 1, 5, 6, 14, 15, 27, 28, 2, 4, 7, 13, 16, 26, 29, 42, 3, 8, 12, 17, 25, 30,
      41, 43, 9, 11, 18, 24, 31, 40, 44, 53, 10, 19, 23, 32, 39, 45, 52, 54, 20,
      22, 33, 38, 46, 51, 55, 60, 21, 34, 37, 47, 50, 56, 59, 61, 35, 36, 48,
      49, 57, 58, 62, 63
};

const std::array<uint8_t, 178> T_AC_0 {
  0, 2, 1, 3, 3, 2, 4, 3, 5, 5, 4, 4, 0, 0, 1, 125, 1, 2, 3, 0, 4, 17, 5, 18,
      33, 49, 65, 6, 19, 81, 97, 7, 34, 113, 20, 50, 129, 145, 161, 8, 35, 66,
      177, 193, 21, 82, 209, 240, 36, 51, 98, 114, 130, 9, 10, 22, 23, 24, 25,
      26, 37, 38, 39, 40, 41, 42, 52, 53, 54, 55, 56, 57, 58, 67, 68, 69, 70,
      71, 72, 73, 74, 83, 84, 85, 86, 87, 88, 89, 90, 99, 100, 101, 102, 103,
      104, 105, 106, 115, 116, 117, 118, 119, 120, 121, 122, 131, 132, 133, 134,
      135, 136, 137, 138, 146, 147, 148, 149, 150, 151, 152, 153, 154, 162, 163,
      164, 165, 166, 167, 168, 169, 170, 178, 179, 180, 181, 182, 183, 184, 185,
      186, 194, 195, 196, 197, 198, 199, 200, 201, 202, 210, 211, 212, 213, 214,
      215, 216, 217, 218, 225, 226, 227, 228, 229, 230, 231, 232, 233, 234, 241,
      242, 243, 244, 245, 246, 247, 248, 249, 250
};

const std::array<int, 12> DC_CAT_OFF { 2, 3, 3, 3, 3, 3, 4, 5, 6, 7, 8, 9 };


MeteorImage::MeteorImage()
    : mIsChannel64Available(false)
    , mIsChannel65Available(false)
    , mIsChannel66Available(false)
    , mIsChannel68Available(false)
    , mLastMCU(-1)
    , mCurY(0)
    , mLastY(-1)
    , mFirstPacket(0)
    , mPrevPacket(0)
{
    initHuffmanTable();
    initCos();
}

void MeteorImage::initCos() {
  for (int y = 0; y < 8; y++) {
    for (int x = 0; x < 8; x++) {
      mCosine[y][x] = cos(M_PI / 16 * (2 * y + 1) * x);
    }
  }
  for (int x = 0; x < 8; x++) {
    if (x == 0)
      mAlpha[x] = 1 / sqrt(2);
    else
      mAlpha[x] = 1;
  }

  //for (auto x : cosine_) for (auto y: x) std::cout << std::dec << y << ' ';
}

void MeteorImage::initHuffmanTable()
{
    std::array<uint8_t, 65536> v {};
    std::array<uint16_t, 17> min_code {}, maj_code {};

  int p = 16;
  for (int k = 1; k < 17; k++) {
    for (int i = 0; i < T_AC_0[k - 1]; i++) {
      v[(k << 8) + i] = T_AC_0[p];
      p++;
    }
  }

  uint32_t code = 0;
  for (int k = 1; k < 17; k++) {
    min_code[k] = code;
    code += T_AC_0[k - 1];
    maj_code[k] = code - (uint32_t)(code != 0);
    code *= 2;
    if (T_AC_0[k - 1] == 0) {
      min_code[k] = 0xffff;
      maj_code[k] = 0;
    }
  }

  int n = 0;
  for (int k = 1; k < 17; k++) {
    uint16_t min_val = min_code[k];
    uint16_t max_val = maj_code[k];
    for (int i = 0; i < (1 << k); i++) {
      if (i <= max_val && i >= min_val) {
        uint16_t size_val = v[(k << 8) + i - min_val];
        int run = size_val >> 4;
        int size = size_val & 0xf;
        mAcTable[n].run = run;
        mAcTable[n].size = size;
        mAcTable[n].len = k;
        mAcTable[n].mask = (1 << k) - 1;
        mAcTable[n].code = i;
        n++;
      }
    }
  }

  for (int i = 0; i < 65536; i++) {
    mAcLookup[i] = getAcReal(i);
  }
  for (int i = 0; i < 65536; i++) {
    mDcLookup[i] = getDcReal(i);
  }
}

int MeteorImage::getDcReal(uint16_t word) {
  switch (word >> 14) {
    case 0:
      return 0;
    default:
      switch (word >> 13) {
        case 2:
          return 1;
        case 3:
          return 2;
        case 4:
          return 3;
        case 5:
          return 4;
        case 6:
          return 5;
        default:
          if ((word >> 12) == 0x00e) return 6;
          if ((word >> 11) == 0x01e) return 7;
          if ((word >> 10) == 0x03e) return 8;
          if ((word >> 9) == 0x07e) return 9;
          if ((word >> 8) == 0x0fe) return 10;
          if ((word >> 7) == 0x1fe) return 11;
      }
  }
  return -1;
}

int MeteorImage::getAcReal(uint16_t word) {
  for (int i = 0; i < 162; i++) {
    if (((word >> (16 - mAcTable[i].len)) & mAcTable[i].mask) ==
        mAcTable[i].code) {
      return i;
    }
  }
  return -1;
}

MeteorImage::~MeteorImage()
{

}

cv::Mat MeteorImage::getChannelImage(ChannelIDs APID, bool fillBlackLines) {
    if (mFullImage.size() == 0) {
        return cv::Mat();
    }

    const int width = 8 * MCU_PER_LINE;
    const int height = mCurY + 8;

    cv::Mat image = cv::Mat(height, width, CV_8UC3);

    for(int y=0; y < image.rows; y++)
    {
        for(int x=0; x < image.cols; x++)
        {
            uint off = x + y * MCU_PER_LINE * 8;

            cv::Vec3b &color = image.at<cv::Vec3b>(y,x);

            image.at<cv::Vec3b>(cv::Point(x,y)) = color;

            switch (APID) {
            case APID_68:
                color[0] = mFullImage[off].r;
                color[1] = mFullImage[off].r;
                color[2] = mFullImage[off].r;
                break;
            case APID_66:
                color[0] = mFullImage[off].r;
                color[1] = mFullImage[off].r;
                color[2] = mFullImage[off].r;
                break;
            case APID_65:
                color[0] = mFullImage[off].g;
                color[1] = mFullImage[off].g;
                color[2] = mFullImage[off].g;
                break;
            case APID_64:
                color[0] = mFullImage[off].b;
                color[1] = mFullImage[off].b;
                color[2] = mFullImage[off].b;
                break;
            }

            image.at<cv::Vec3b>(cv::Point(x,y)) = color;
        }
    }


    if(fillBlackLines) {
        ThreatImage::fillBlackLines(image, 8, 64);
    }

    return image;
}

cv::Mat MeteorImage::getRGBImage(ChannelIDs redAPID, ChannelIDs greenAPID, ChannelIDs blueAPID, bool fillBlackLines) {
  if (mFullImage.size() == 0) {
      return cv::Mat();
  }

  int width = 8 * MCU_PER_LINE;
  int height = mCurY + 8;
  cv::Mat image = cv::Mat(height, width, CV_8UC3);
  cv::Vec3b color;

  for(int y=0;y<image.rows;y++)
  {
      for(int x=0;x<image.cols;x++)
      {
          uint off = x + y * MCU_PER_LINE * 8;

          color[0] = (blueAPID  == APID_66 || blueAPID  == APID_68) ? mFullImage[off].r : (blueAPID  == APID_65) ? mFullImage[off].g : mFullImage[off].b;
          color[1] = (greenAPID == APID_66 || greenAPID == APID_68) ? mFullImage[off].r : (greenAPID == APID_65) ? mFullImage[off].g : mFullImage[off].b;
          color[2] = (redAPID   == APID_66 || redAPID   == APID_68) ? mFullImage[off].r : (redAPID   == APID_65) ? mFullImage[off].g : mFullImage[off].b;
          image.at<cv::Vec3b>(cv::Point(x,y)) = color;
      }
  }


  if(fillBlackLines) {
    ThreatImage::fillBlackLines(image, 8, 64);
  }

  return image;
}

bool MeteorImage::progressImage(int apd, int mcu_id, int pck_cnt) {
  if (apd == 0 || apd == 70) return false;

  if (mLastMCU == -1) {
    if (mcu_id != 0) return false;
    mPrevPacket = pck_cnt;
    mFirstPacket = pck_cnt;
    if (apd == 65) mFirstPacket -= 14;
    if (apd == 66) mFirstPacket -= 28;
    if (apd == 68) mFirstPacket -= 28;
    mLastMCU = 0;
    mCurY = -1;
  }

  if (pck_cnt < mPrevPacket) mFirstPacket -= 16384;
  mPrevPacket = pck_cnt;

  mCurY = 8 * ((pck_cnt - mFirstPacket) / (14 + 14 + 14 + 1));
  if (mCurY > mLastY) {
      mFullImage.resize(MCU_PER_LINE * 8 * (mCurY + 8));
  }
  mLastY = mCurY;

  return true;
}

void MeteorImage::fillDqtByQ(std::array<int, 64> &dqt, int q) {
  float f;
  if (q > 20 && q < 50)
    f = 5000. / q;
  else
    f = 200. - 2 * q;

  for (int i = 0; i < 64; i++) {
    dqt[i] = (int) round(f / 100. * STANDARD_QUANTIZATION_TABLE[i]);
    if (dqt[i] < 1) dqt[i] = 1;
  }
}

int MeteorImage::mapRange(int cat, int vl) {
  int maxval = (1 << cat) - 1;
  bool sig = (vl >> (cat - 1)) != 0;
  if (sig)
    return vl;
  else
    return vl - maxval;
}

void MeteorImage::filtIdct8x8(std::array<float, 64> &res,
                          std::array<float, 64> &inp) {
  for (int y = 0; y < 8; y++) {
    for (int x = 0; x < 8; x++) {
      float s = 0;
      for (int u = 0; u < 8; u++) {
        float cxu = mAlpha[u] * mCosine[x][u];
        s += cxu * (inp[0 * 8 + u] * mAlpha[0] * mCosine[y][0] +
                    inp[1 * 8 + u] * mAlpha[1] * mCosine[y][1] +
                    inp[2 * 8 + u] * mAlpha[2] * mCosine[y][2] +
                    inp[3 * 8 + u] * mAlpha[3] * mCosine[y][3] +
                    inp[4 * 8 + u] * mAlpha[4] * mCosine[y][4] +
                    inp[5 * 8 + u] * mAlpha[5] * mCosine[y][5] +
                    inp[6 * 8 + u] * mAlpha[6] * mCosine[y][6] +
                    inp[7 * 8 + u] * mAlpha[7] * mCosine[y][7]);
      }
      res[y * 8 + x] = s / 4;
    }
  }
}

void MeteorImage::fillPix(std::array<float, 64> &img_dct, int apd, int mcu_id,
                      int m) {
  for (int i = 0; i < 64; i++) {
    int t = round(img_dct[i] + 128);
    if (t < 0) t = 0;
    if (t > 255) t = 255;
    int x = (mcu_id + m) * 8 + i % 8;
    int y = mCurY + i / 8;
    uint off = x + y * MCU_PER_LINE * 8;

    if (apd == APID_68 || apd == APID_66) {
        mFullImage[off].r = t;
    }
    if (apd == APID_65) {
        mFullImage[off].g = t;
    }
    if (apd == APID_64) {
        mFullImage[off].b = t;
    }
  }
}

void MeteorImage::decMCUs(const uint8_t *packet, int len, int apd, int pck_cnt,
                      int mcu_id, uint8_t q) {
  BitIOConst b(packet);

  if (!progressImage(apd, mcu_id, pck_cnt)) return;

  if(apd == APID_64) {
    mIsChannel64Available = true;
  }
  if(apd == APID_65) {
    mIsChannel65Available = true;
  }

  if(apd == APID_66) {
    mIsChannel66Available = true;
  }
  if(apd == APID_68) {
    mIsChannel68Available = true;
  }

  std::array<int, 64> dqt {}
  ;
  std::array<float, 64> zdct {}
  , dct {}
  , img_dct {}
  ;
  fillDqtByQ(dqt, q);

  float prev_dc = 0;
  int m = 0;
  while (m < MCU_PER_PACKET) {
    int dc_cat = mDcLookup[b.peekBits(16)];
    if (dc_cat == -1) {
      std::cerr << "Bad DC Huffman code!" << std::endl;
      return;
    }
    b.advanceBits(DC_CAT_OFF[dc_cat]);
    uint32_t n = b.fetchBits(dc_cat);

    zdct[0] = mapRange(dc_cat, n) + prev_dc;
    prev_dc = zdct[0];

    int k = 1;
    while (k < 64) {
      int ac = mAcLookup[b.peekBits(16)];
      if (ac == -1) {
        std::cerr << "Bad AC Huffman code!" << std::endl;
        return;
      }
      int ac_len = mAcTable[ac].len;
      int ac_size = mAcTable[ac].size;
      int ac_run = mAcTable[ac].run;
      b.advanceBits(ac_len);

      if (ac_run == 0 && ac_size == 0) {
        for (int i = k; i < 64; i++) {
          zdct[i] = 0;
        }
        break;
      }

      for (int i = 0; i < ac_run; i++) {
        zdct[k] = 0;
        k++;
      }

      if (ac_size != 0) {
        uint16_t n = b.fetchBits(ac_size);
        zdct[k] = mapRange(ac_size, n);
        k++;
      } else if (ac_run == 15) {
        zdct[k] = 0;
        k++;
      }
    }

    for (int i = 0; i < 64; i++) {
      dct[i] = zdct[ZIGZAG[i]] * dqt[i];
    }

    filtIdct8x8(img_dct, dct);
    fillPix(img_dct, apd, mcu_id, m);

    m++;
  }

}

