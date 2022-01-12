#include "DSP/meteordemodulator.h"
#include "DSP/wavreader.h"
#include "correlation.h"
#include "packetparser.h"
#include "reedsolomon.h"
#include "viterbi.h"
#include "deinterleaver.h"
#include "pixelgeolocationcalculator.h"

#include <iostream>
#include <fstream>
#include <ctime>
#include <opencv2/imgcodecs.hpp>
#include "spreadimage.h"

#include "GIS/shapereader.h"
#include "GIS/shaperenderer.h"
#include "tlereader.h"
#include "settings.h"

struct ImageForSpread {
    ImageForSpread(cv::Mat img, std::string fileNamebase)
        : image(img)
        , fileNameBase(fileNamebase) {
    }

    cv::Mat image;
    std::string fileNameBase;
};

void saveImage(const std::string fileName, const cv::Mat &image);
void writeSymbolToFile(std::ostream &stream, const Wavreader::complex &sample);
int mean(int cur, int prev);
void differentialDecode(int8_t *data, int64_t len);
int8_t clamp(float x);


static uint16_t intSqrtTable[32768];

static const uint8_t PRAND[] = {
    0xff, 0x48, 0x0e, 0xc0, 0x9a, 0x0d, 0x70, 0xbc, 0x8e, 0x2c, 0x93, 0xad, 0xa7,
    0xb7, 0x46, 0xce, 0x5a, 0x97, 0x7d, 0xcc, 0x32, 0xa2, 0xbf, 0x3e, 0x0a,
    0x10, 0xf1, 0x88, 0x94, 0xcd, 0xea, 0xb1, 0xfe, 0x90, 0x1d, 0x81, 0x34,
    0x1a, 0xe1, 0x79, 0x1c, 0x59, 0x27, 0x5b, 0x4f, 0x6e, 0x8d, 0x9c, 0xb5,
    0x2e, 0xfb, 0x98, 0x65, 0x45, 0x7e, 0x7c, 0x14, 0x21, 0xe3, 0x11, 0x29,
    0x9b, 0xd5, 0x63, 0xfd, 0x20, 0x3b, 0x02, 0x68, 0x35, 0xc2, 0xf2, 0x38,
    0xb2, 0x4e, 0xb6, 0x9e, 0xdd, 0x1b, 0x39, 0x6a, 0x5d, 0xf7, 0x30, 0xca,
    0x8a, 0xfc, 0xf8, 0x28, 0x43, 0xc6, 0x22, 0x53, 0x37, 0xaa, 0xc7, 0xfa,
    0x40, 0x76, 0x04, 0xd0, 0x6b, 0x85, 0xe4, 0x71, 0x64, 0x9d, 0x6d, 0x3d,
    0xba, 0x36, 0x72, 0xd4, 0xbb, 0xee, 0x61, 0x95, 0x15, 0xf9, 0xf0, 0x50,
    0x87, 0x8c, 0x44, 0xa6, 0x6f, 0x55, 0x8f, 0xf4, 0x80, 0xec, 0x09, 0xa0,
    0xd7, 0x0b, 0xc8, 0xe2, 0xc9, 0x3a, 0xda, 0x7b, 0x74, 0x6c, 0xe5, 0xa9,
    0x77, 0xdc, 0xc3, 0x2a, 0x2b, 0xf3, 0xe0, 0xa1, 0x0f, 0x18, 0x89, 0x4c,
    0xde, 0xab, 0x1f, 0xe9, 0x01, 0xd8, 0x13, 0x41, 0xae, 0x17, 0x91, 0xc5,
    0x92, 0x75, 0xb4, 0xf6, 0xe8, 0xd9, 0xcb, 0x52, 0xef, 0xb9, 0x86, 0x54,
    0x57, 0xe7, 0xc1, 0x42, 0x1e, 0x31, 0x12, 0x99, 0xbd, 0x56, 0x3f, 0xd2,
    0x03, 0xb0, 0x26, 0x83, 0x5c, 0x2f, 0x23, 0x8b, 0x24, 0xeb, 0x69, 0xed,
    0xd1, 0xb3, 0x96, 0xa5, 0xdf, 0x73, 0x0c, 0xa8, 0xaf, 0xcf, 0x82, 0x84,
    0x3c, 0x62, 0x25, 0x33, 0x7a, 0xac, 0x7f, 0xa4, 0x07, 0x60, 0x4d, 0x06,
    0xb8, 0x5e, 0x47, 0x16, 0x49, 0xd6, 0xd3, 0xdb, 0xa3, 0x67, 0x2d, 0x4b,
    0xbe, 0xe6, 0x19, 0x51, 0x5f, 0x9f, 0x05, 0x08, 0x78, 0xc4, 0x4a, 0x66,
    0xf5, 0x58
};

static uint8_t dataTodecode[16384];
static uint8_t viterbiResult[1024];
static uint8_t decodedPacket[1024];
static int rsResult[4];
static int decodedPacketCounter = 0;
static Correlation mCorrelation;
static Viterbi mViterbi;
static PacketParser mPacketParser;
static ReedSolomon mReedSolomon;
static Settings &mSettings = Settings::getInstance();

int main(int argc, char *argv[])
{
    if(argc < 5) {
        std::cout << "Invalid number of arguments, exiting..." << std::endl;
        std::cout << mSettings.getHelp() << std::endl;
        return  -1;
    }

    mSettings.parseArgs(argc, argv);
    mSettings.parseIni(mSettings.getResourcesPath() + "settings.ini");

    TleReader reader(mSettings.getTlePath());
    TleReader::TLE tle;
    reader.processFile();
    if(!reader.getTLE("METEOR-M 2", tle)) {
        std::cout << "TLE data not found in TLE file, exiting..." << std::endl;
        return -1;
    }

    do {
        std::string inputPath = mSettings.getInputFilePath();

        if(inputPath.substr(inputPath.find_last_of(".") + 1) == "wav") {
            std::cout << "Input is a .wav file, processing it..." << std::endl;

            const std::string outputPath = inputPath.substr(0, inputPath.find_last_of(".") + 1) + "s";
            std::ofstream  outputStream;
            outputStream.open(outputPath);

            if(!outputStream.is_open()) {
                std::cout << "Creating output .S file failed, exiting...";
                return -1;
            }

            Wavreader wavReader;
            if(!wavReader.openFile(inputPath)) {
                std::cout << "Opening .wav file failed, exiting...";
                return -1;
            }

            DSP::MeteorDemodulator::Mode mode = DSP::MeteorDemodulator::QPSK;
            if(mSettings.getDemodulatorMode() == "oqpsk") {
                mode = DSP::MeteorDemodulator::OQPSK;
            }


            DSP::MeteorDemodulator decoder(mode, mSettings.getSymbolRate(), mSettings.waitForlock(), mSettings.getCostasBandwidth(), mSettings.getRRCFilterOrder(), mSettings.getInterpolationFactor());
            decoder.process(wavReader, [&outputStream](const Wavreader::complex &sample, float) {
                writeSymbolToFile(outputStream, sample);
            });

            outputStream.flush();
            outputStream.close();
            inputPath = outputPath;
        }

        std::ifstream binaryData (inputPath, std::ifstream::binary);
        if(!binaryData) {
            std::cout << "Opening file '" << inputPath << "' failed!";
            break;
        }

        binaryData.seekg (0, binaryData.end);
        int64_t fileLength = binaryData.tellg();
        binaryData.seekg (0, binaryData.beg);

        uint8_t *softBits = new uint8_t[fileLength];
        if(!softBits) {
            std::cout << "Memory allocation failed" << std::endl;
            break;
        }

        binaryData.read (reinterpret_cast<char*>(softBits),fileLength);

        if(mSettings.deInterleave()) {
            std::cout << "Deinterleaving..." << std::endl;
            uint64_t outLen = 0;
            DeInterleaver::deInterleave(softBits, fileLength, &outLen);
            fileLength = outLen;
        }

        if(mSettings.differentialDecode()) {
            std::cout << "Dediffing..." << std::endl;
            differentialDecode(reinterpret_cast<int8_t*>(softBits), fileLength);
        }

        if(!binaryData) {
            std::cout << "Reading file failed" << std::endl;
            break;
        }

        mCorrelation.correlate(softBits, fileLength, [&softBits, fileLength](Correlation::CorellationResult correlationResult, Correlation::PhaseShift phaseShift) {
            bool packetOk;
            uint32_t processedBits = 0;
            do {
                if(fileLength - (correlationResult.pos + processedBits) < 16384) {
                    return processedBits;
                }

                memcpy(dataTodecode, &softBits[correlationResult.pos + processedBits], 16384);

                mCorrelation.rotateSoftIqInPlace(dataTodecode, 16384, phaseShift);

                mViterbi.decodeSoft(dataTodecode, viterbiResult, 16384);

                uint32_t last_sync_ = *reinterpret_cast<uint32_t *>(viterbiResult);

                if (Correlation::countBits(last_sync_ ^ 0xE20330E5) < Correlation::countBits(last_sync_ ^ 0x1DFCCF1A)) {
                    for (int j = 4; j < 1024; j++) {
                        viterbiResult[j] = viterbiResult[j] ^ 0xFF;
                    }
                    last_sync_ = last_sync_ ^ 0xFFFFFFFF;
                }

                for (int j = 0; j < 1024-4; j++) {
                    viterbiResult[j+4] = viterbiResult[j+4] ^ PRAND[j % 255];
                }

                for(int i = 0; i < 4; i++) {
                    mReedSolomon.deinterleave(viterbiResult + 4, i , 4);
                    rsResult[i] = mReedSolomon.decode(0);
                    mReedSolomon.interleave(decodedPacket, i, 4);
                }

                std::cout << "Pos:" << (correlationResult.pos + processedBits) << " | Phase:" << phaseShift << " | synch:" << std::hex << last_sync_ << " | RS: (" << std::dec << rsResult[0] << ", " << rsResult[1] << ", " << rsResult[2] << ", "  << rsResult[3] << ")"  << "\t\t\r" << std::flush;

                packetOk = (rsResult[0] != -1) && (rsResult[1] != -1) &&(rsResult[2] != -1) && (rsResult[3] != -1);

                if(packetOk) {
                    mPacketParser.parseFrame(decodedPacket, 892);
                    decodedPacketCounter++;
                    processedBits += 16384;
                }
            } while(packetOk);

            return (processedBits > 0) ? processedBits-1 : 0;
        });

        delete[] softBits;

        if(binaryData && binaryData.is_open()) {
            binaryData.close();
        }

    } while (false);

    std::cout << std::endl;
    std::cout << "Decoded packets:" << decodedPacketCounter << std::endl;

    if(decodedPacketCounter == 0) {
        std::cout << "No data received, exiting..." << std::endl;
        return 0;
    }

    DateTime passStart;
    DateTime passDate = mSettings.getPassDate();
    TimeSpan passFirstTime = mPacketParser.getFirstTimeStamp();
    TimeSpan passLength = mPacketParser.getLastTimeStamp() - passFirstTime;

    passStart.Initialise(passDate.Year(), passDate.Month(), passDate.Day(), passFirstTime.Hours()-3, passFirstTime.Minutes(), passFirstTime.Seconds(),passFirstTime.Microseconds());
    std::string fileNameDate = std::to_string(passStart.Year()) + "-" + std::to_string(passStart.Month()) + "-" + std::to_string(passStart.Day()) + "-" + std::to_string(passStart.Hour()) + "-" + std::to_string(passStart.Minute()) + "-" + std::to_string(passStart.Second());

    PixelGeolocationCalculator calc(tle, passStart, passLength, mSettings.getM2Alfa() / 2.0f, mSettings.getM2Delta());
    calc.calcPixelCoordinates();
    calc.save(mSettings.getOutputPath() + fileNameDate + ".gcp");

    std::list<ImageForSpread> imagesToSpread;

    if(mPacketParser.isChannel64Available() && mPacketParser.isChannel65Available() && mPacketParser.isChannel68Available()) {
        cv::Mat threatedImage1 = mPacketParser.getRGBImage(PacketParser::APID_65, PacketParser::APID_65, PacketParser::APID_64, mSettings.fillBackLines());
	cv::Mat irImage = mPacketParser.getChannelImage(PacketParser::APID_68, mSettings.fillBackLines());
	cv::Mat threatedImage2 = mPacketParser.getRGBImage(PacketParser::APID_64, PacketParser::APID_65, PacketParser::APID_68, mSettings.fillBackLines());

        if(!ThreatImage::isNightPass(threatedImage1, mSettings.getNightPassTreshold())) {
            imagesToSpread.push_back(ImageForSpread(threatedImage1, "221_"));
	    imagesToSpread.push_back(ImageForSpread(threatedImage2, "125_"));
	    saveImage(mSettings.getOutputPath() + fileNameDate + "_221.bmp", threatedImage1);
	    saveImage(mSettings.getOutputPath() + fileNameDate + "_125.bmp", threatedImage2);
        } else {
            std::cout << "Night pass, RGB image skipped, threshold set to: " << mSettings.getNightPassTreshold() << std::endl;
        }

        cv::Mat ch64 = mPacketParser.getChannelImage(PacketParser::APID_64, mSettings.fillBackLines());
	cv::Mat ch65 = mPacketParser.getChannelImage(PacketParser::APID_65, mSettings.fillBackLines());
	cv::Mat ch68 = mPacketParser.getChannelImage(PacketParser::APID_68, mSettings.fillBackLines());

	saveImage(mSettings.getOutputPath() + fileNameDate + "_64.bmp", ch64);
	saveImage(mSettings.getOutputPath() + fileNameDate + "_65.bmp", ch65);
	saveImage(mSettings.getOutputPath() + fileNameDate + "_68.bmp", ch68);

        cv::Mat thermalRef = cv::imread(mSettings.getResourcesPath() + "thermal_ref.bmp");
        cv::Mat thermalImage = ThreatImage::irToTemperature(irImage, thermalRef);
        imagesToSpread.push_back(ImageForSpread(thermalImage, "thermal_"));

        cv::bitwise_not(irImage, irImage);
        irImage = ThreatImage::gamma(irImage, 1.8);
        imagesToSpread.push_back(ImageForSpread(irImage, "IR_"));

    } else if(mPacketParser.isChannel64Available() && mPacketParser.isChannel65Available() && mPacketParser.isChannel66Available()) {
        cv::Mat threatedImage = mPacketParser.getRGBImage(PacketParser::APID_66, PacketParser::APID_65, PacketParser::APID_64, mSettings.fillBackLines());

        if(!ThreatImage::isNightPass(threatedImage, mSettings.getNightPassTreshold())) {
            imagesToSpread.push_back(ImageForSpread(threatedImage, "123_"));
            saveImage(mSettings.getOutputPath() + fileNameDate + "_123.bmp", threatedImage);
        } else {
            std::cout << "Night pass, RGB image skipped, threshold set to: " << mSettings.getNightPassTreshold() << std::endl;
        }

        mPacketParser.getChannelImage(PacketParser::APID_64, mSettings.fillBackLines());
        mPacketParser.getChannelImage(PacketParser::APID_65, mSettings.fillBackLines());
        mPacketParser.getChannelImage(PacketParser::APID_66, mSettings.fillBackLines());

        cv::Mat ch64 = mPacketParser.getChannelImage(PacketParser::APID_64, mSettings.fillBackLines());
        cv::Mat ch65 = mPacketParser.getChannelImage(PacketParser::APID_65, mSettings.fillBackLines());
        cv::Mat ch66 = mPacketParser.getChannelImage(PacketParser::APID_68, mSettings.fillBackLines());

        saveImage(mSettings.getOutputPath() + fileNameDate + "_64.bmp", ch64);
        saveImage(mSettings.getOutputPath() + fileNameDate + "_65.bmp", ch65);
        saveImage(mSettings.getOutputPath() + fileNameDate + "_66.bmp", ch66);
    } else if(mPacketParser.isChannel64Available() && mPacketParser.isChannel65Available()) {
        cv::Mat threatedImage = mPacketParser.getRGBImage(PacketParser::APID_65, PacketParser::APID_65, PacketParser::APID_64, mSettings.fillBackLines());

        if(!ThreatImage::isNightPass(threatedImage, mSettings.getNightPassTreshold())) {
            imagesToSpread.push_back(ImageForSpread(threatedImage, "221_"));
            saveImage(mSettings.getOutputPath() + fileNameDate + "_221.bmp", threatedImage);
        } else {
            std::cout << "Night pass, RGB image skipped, threshold set to: " << mSettings.getNightPassTreshold() << std::endl;
        }

        cv::Mat ch64 = mPacketParser.getChannelImage(PacketParser::APID_64, mSettings.fillBackLines());
        cv::Mat ch65 = mPacketParser.getChannelImage(PacketParser::APID_65, mSettings.fillBackLines());

        saveImage(mSettings.getOutputPath() + fileNameDate + "_64.bmp", ch64);
        saveImage(mSettings.getOutputPath() + fileNameDate + "_65.bmp", ch65);
    } else if(mPacketParser.isChannel68Available()) {
        cv::Mat ch68 = mPacketParser.getChannelImage(PacketParser::APID_68, mSettings.fillBackLines());

        saveImage(mSettings.getOutputPath() + fileNameDate + "_68.bmp", ch68);
    } else {
        std::cout << "No usable channel data found!" << std::endl;

        return 0;
    }

    SpreadImage spreadImage;
    std::ostringstream oss;
    oss << std::setfill('0') << std::setw(2) << passStart.Day() << "/" << std::setw(2) << passStart.Month() << "/" << passStart.Year() << " " << std::setw(2) << passStart.Hour() << ":" << std::setw(2) << passStart.Minute() << ":" << std::setw(2) << passStart.Second() << " UTC";
    std::string dateStr = oss.str();

    std::list<ImageForSpread>::const_iterator it;

    int c = 1;
    for(it = imagesToSpread.begin(); it != imagesToSpread.end(); ++it, c++) {
        std::string fileName = (*it).fileNameBase + fileNameDate + "." + mSettings.getOutputFormat();

        if(mSettings.spreadImage()) {
            cv::Mat strechedImg = spreadImage.stretch((*it).image);

            if(!strechedImg.empty()) {
                ThreatImage::drawWatermark(strechedImg, dateStr);
                saveImage(mSettings.getOutputPath() + std::string("spread_") + fileName, strechedImg);
            } else {
                std::cout << "Failed to strech image" << std::endl;
            }
        }

        if(mSettings.mercatorProjection()) {
            cv::Mat mercator = spreadImage.mercatorProjection((*it).image, calc, [c, &imagesToSpread](float percent) {
                std::cout << "Spreading mercator " << c << " of " << imagesToSpread.size() << " " << static_cast<int>(percent) << "%\t\t\r" << std::flush;
            });
            std::cout << std::endl;

            if(!mercator.empty()) {
                ThreatImage::drawWatermark(mercator, dateStr);
                saveImage(mSettings.getOutputPath() + std::string("mercator_") + fileName, mercator);
            } else {
                std::cout << "Failed to create mercator projection" << std::endl;
            }
        }

        if(mSettings.equadistantProjection()) {
            cv::Mat equidistant = spreadImage.equidistantProjection((*it).image, calc, [c, &imagesToSpread](float percent) {
                std::cout << "Spreading equidistant " << c << " of " << imagesToSpread.size() << " " << static_cast<int>(percent) << "%\t\t\r" << std::flush;
            });
            std::cout << std::endl;

            if(!equidistant.empty()) {
                ThreatImage::drawWatermark(equidistant, dateStr);
                saveImage(mSettings.getOutputPath() + std::string("equidistant_") + fileName, equidistant);
            } else {
                std::cout << "Failed to create equidistant projection" << std::endl;
            }
        }
    }
    return 0;
}

void saveImage(const std::string fileName, const cv::Mat &image)
{
    std::vector<int> compression_params;
    compression_params.push_back(cv::IMWRITE_JPEG_QUALITY);
    compression_params.push_back(mSettings.getJpegQuality());

    try {
        cv::imwrite(fileName, image, compression_params);
    } catch (const cv::Exception& ex) {
        std::cout << "Saving image " << fileName << " failed. error: " << ex.what() << std::endl;
    }
}

void writeSymbolToFile(std::ostream &stream, const Wavreader::complex &sample)
{
    int8_t outBuffer[2];

    outBuffer[0] = clamp(std::real(sample) / 2.0f);
    outBuffer[1] = clamp(std::imag(sample) / 2.0f);

    stream.write(reinterpret_cast<char*>(outBuffer), sizeof(outBuffer));
}

int mean(int cur, int prev)
{
    int v = cur * prev;
    int result = 0;

    if (v > 32767 || v < -32767) {
        return 0;
    }

    if (v >=0) {
        result = intSqrtTable[v];
    } else {
        result =-intSqrtTable[-v];
    }

    return result;
}

void differentialDecode(int8_t *data, int64_t len)
{
    int a;
    int b;
    int prevA;
    int prevB;

    if (len < 2) {
        return;
    }

    for(int i = 0; i < 32768; i++) {
        intSqrtTable[i] = round(sqrt(i));
    }

    prevA = data[0];
    prevB = data[1];
    data[0] = 0;
    data[1] = 0;
    for(int64_t i = 0; i < (len / 2); i++) {
        a = data[i * 2 + 0];
        b = data[i * 2 + 1];
        data[i*2+0] = mean(a, prevA);
        data[i*2+1] = mean(-b, prevB);
        prevA = a;
        prevB = b;
    }
}

// Clamp a real value to a int8_t
int8_t clamp(float x)
{
    if (x < -128.0) {
        return -128;
    }
    if (x > 127.0) {
        return 127;
    }
    if (x > 0 && x < 1) {
        return 1;
    }
    if (x > -1 && x < 0) {
        return -1;
    }
    return static_cast<int8_t>(x);
}
