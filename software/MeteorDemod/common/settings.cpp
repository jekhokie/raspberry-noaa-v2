#include "settings.h"
#include "version.h"
#include <sstream>
#include <fstream>
#include <ctime>
#include <regex>

#if defined(_MSC_VER)
#include <Shlwapi.h>
#pragma comment(lib, "shlwapi.lib")
#else
#include <unistd.h>
#include <sys/types.h>
#include <pwd.h>
#endif

Settings &Settings::getInstance()
{
    static Settings instance;
    return instance;
}

Settings::Settings()
{
    mSettingsList.push_back(SettingsData("--help",  "-h", "Print help"));
    mSettingsList.push_back(SettingsData("--tle",   "-t", "TLE file required for pass calculation"));
    mSettingsList.push_back(SettingsData("--input", "-i", "Input S file containing softbits"));
    mSettingsList.push_back(SettingsData("--output","-o", "Output folder where generated files will be placed"));
    mSettingsList.push_back(SettingsData("--date",  "-d", "Specify pass date, format should be dd-mm-yyyy"));
    mSettingsList.push_back(SettingsData("--format",  "-f", "Output image format (bmp, jpg)"));
    mSettingsList.push_back(SettingsData("--symbolrate",  "-s", "Set symbol rate for demodulator"));
    mSettingsList.push_back(SettingsData("--mode",  "-m", "Set demodulator mode to qpsk or oqpsk"));
    mSettingsList.push_back(SettingsData("--diff",  "-diff", "Use differential decoding (Maybe required for newer satellites)"));
    mSettingsList.push_back(SettingsData("--int",  "-int", "Deinterleave (Maybe required for newer satellites)"));
}

void Settings::parseArgs(int argc, char **argv)
{
    for(int i = 1; i < (argc-1); i+=2) {
        mArgs.insert(std::make_pair(argv[i], argv[i+1]));
    }
}

void Settings::parseIni(const std::string &path)
{
    std::ifstream ifStream(path);
    if(!ifStream.is_open()) {
        std::cout << "Unable to open settings.ini at: '" << path << "' Program will use default settings." << std::endl;
    } else {
        mIniParser.parse(ifStream);
    }
    //mIniParser.generate(std::cout);

    ini::extract(mIniParser.sections["Program"]["AzimuthalEquidistantProjection"], mEquidistantProjection, true);
    ini::extract(mIniParser.sections["Program"]["MercatorProjection"], mMercatorProjection, true);
    ini::extract(mIniParser.sections["Program"]["SpreadImage"], mSpreadImage, true);
    ini::extract(mIniParser.sections["Program"]["JpgQuality"], mJpegQuality, 90);
    ini::extract(mIniParser.sections["Program"]["AlfaM2"], mAlfaM2, 110.8f);
    ini::extract(mIniParser.sections["Program"]["DeltaM2"], DeltaM2, -3.2f);
    ini::extract(mIniParser.sections["Program"]["NightPassTreshold"], mNightPassTreshold, 10.0f);

    ini::extract(mIniParser.sections["Demodulator"]["CostasBandwidth"], mCostasBw, 50);
    ini::extract(mIniParser.sections["Demodulator"]["RRCFilterOrder"], mRRCFilterOrder, 64);
    ini::extract(mIniParser.sections["Demodulator"]["InterpolationFactor"], mInterploationFacor, 4);
    ini::extract(mIniParser.sections["Demodulator"]["WaitForLock"], mWaitForLock, true);

    ini::extract(mIniParser.sections["Treatment"]["FillBlackLines"], mFillBackLines, true);

    ini::extract(mIniParser.sections["Watermark"]["Place"], mWaterMarkPlace);
    ini::extract(mIniParser.sections["Watermark"]["Color"], mWaterMarkColor, HTMLColor(0xAD880C));
    ini::extract(mIniParser.sections["Watermark"]["Size"], mWaterMarkSize, 5);
    ini::extract(mIniParser.sections["Watermark"]["Text"], mWaterMarkText);

    ini::extract(mIniParser.sections["ReceiverLocation"]["Draw"], mDrawreceiver, false);
    ini::extract(mIniParser.sections["ReceiverLocation"]["Latitude"], mReceiverLatitude, 0.0f);
    ini::extract(mIniParser.sections["ReceiverLocation"]["Longitude"], mReceiverLongitude, 0.0f);
    ini::extract(mIniParser.sections["ReceiverLocation"]["Color"], mReceiverColor, HTMLColor(0xCC3030));
    ini::extract(mIniParser.sections["ReceiverLocation"]["Size"], mReceiverSize, 5);
    ini::extract(mIniParser.sections["ReceiverLocation"]["Thickness"], mReceiverThickness, 5);
    ini::extract(mIniParser.sections["ReceiverLocation"]["MarkType"], mReceiverMarkType);

    ini::extract(mIniParser.sections["ShapeFileGraticules"]["FileName"], mShapeGraticulesFile);
    ini::extract(mIniParser.sections["ShapeFileGraticules"]["Color"], mShapeGraticulesColor, HTMLColor(0xC8C8C8));
    ini::extract(mIniParser.sections["ShapeFileGraticules"]["Thickness"], mShapeGraticulesThickness, 5);

    ini::extract(mIniParser.sections["ShapeFileCoastLines"]["FileName"], mShapeCoastLinesFile);
    ini::extract(mIniParser.sections["ShapeFileCoastLines"]["Color"], mShapeCoastLinesColor, HTMLColor(0x808000));
    ini::extract(mIniParser.sections["ShapeFileCoastLines"]["Thickness"], mShapeCoastLinesThickness, 5);

    ini::extract(mIniParser.sections["ShapeFileBoundaryLines"]["FileName"], mShapeBoundaryLinesFile);
    ini::extract(mIniParser.sections["ShapeFileBoundaryLines"]["Color"], mShapeBoundaryLinesColor, HTMLColor(0xC8C8C8));
    ini::extract(mIniParser.sections["ShapeFileBoundaryLines"]["Thickness"], mShapeBoundaryLinesThickness, 5);

    ini::extract(mIniParser.sections["ShapeFilePopulatedPlaces"]["FileName"], mShapePopulatedPlacesFile);
    ini::extract(mIniParser.sections["ShapeFilePopulatedPlaces"]["Color"], mShapePopulatedPlacesColor, HTMLColor(0x5A42F5));
    ini::extract(mIniParser.sections["ShapeFilePopulatedPlaces"]["Thickness"], mShapePopulatedPlacesThickness, 5);
    ini::extract(mIniParser.sections["ShapeFilePopulatedPlaces"]["FontScale"], mShapePopulatedPlacesFontScale, 2);
    ini::extract(mIniParser.sections["ShapeFilePopulatedPlaces"]["PointRadius"], mShapePopulatedPlacesPointradius, 10);
    ini::extract(mIniParser.sections["ShapeFilePopulatedPlaces"]["FilterColumnName"], mShapePopulatedPlacesFilterColumnName, std::string("ADM0CAP"));
    ini::extract(mIniParser.sections["ShapeFilePopulatedPlaces"]["NumericFilter"], mShapePopulatedPlacesNumbericFilter, 1);
    ini::extract(mIniParser.sections["ShapeFilePopulatedPlaces"]["TextColumnName"], mShapePopulatedPlacesTextColumnName, std::string("NAME"));
}

std::string Settings::getHelp() const
{
    std::list<SettingsData>::const_iterator it;
    std::stringstream ss;

    ss << "MeteorDemod Version " << VERSION_MAJOR << "." << VERSION_MINOR << "." << VERSION_FIX << std::endl;
    for(it = mSettingsList.begin(); it != mSettingsList.end(); ++it) {
        ss << (*it).argNameShort << "\t" << (*it).argName << "\t" << (*it).helpText << std::endl;
    }

    return ss.str();
}

std::string Settings::getInputFilePath() const
{
    if(mArgs.count("-i")) {
        return mArgs.at("-i");
    }
    if(mArgs.count("--input")) {
        return mArgs.at("--input");
    }
    return std::string();
}

std::string Settings::getTlePath() const
{
    if(mArgs.count("-t")) {
        return mArgs.at("-t");
    }
    if(mArgs.count("--tle")) {
        return mArgs.at("--tle");
    }
    return std::string();
}

std::string Settings::getResourcesPath() const
{
#if defined(_MSC_VER)
    CHAR path[MAX_PATH];

	GetModuleFileNameA(nullptr, path, MAX_PATH);
	PathRemoveFileSpecA(path);

    return std::string(path) + "\\resources\\";
#else
    struct passwd *pw = getpwuid(getuid());
    return std::string(pw->pw_dir) + "/.config/meteordemod/";
#endif
}

std::string Settings::getOutputPath() const
{
    if(mArgs.count("-o")) {
        return mArgs.at("-o");
    }
    if(mArgs.count("--output")) {
        return mArgs.at("--output");
    }
    return std::string("./");
}

std::string Settings::getOutputFormat() const
{
    std::string imgFormat;

    imgFormat =  std::string("bmp");

    if(mArgs.count("-f")) {
        imgFormat = mArgs.at("-f");
    }
    if(mArgs.count("--format")) {
        imgFormat =  mArgs.at("--format");
    }

    //Todo: validate format

    return imgFormat;
}

DateTime Settings::getPassDate() const
{
    int year, month, day;
    std::string dateTimeStr;
    DateTime dateTime(0);

    if(mArgs.count("-d")) {
        dateTimeStr = mArgs.at("-d");
    }
    if(mArgs.count("--date")) {
        dateTimeStr =  mArgs.at("--date");
    }

    const time_t now = time(nullptr);
    tm today;
    #if defined(_MSC_VER)
        gmtime_s(&today, &now);
    #else
        gmtime_r(&now, &today);
    #endif

    dateTime.Initialise(1900 + today.tm_year, today.tm_mon + 1, today.tm_mday, today.tm_hour, today.tm_min, today.tm_sec, 0);

    if(dateTimeStr.empty()) {
        return dateTime;
    }

    try {
        std::regex dateTimeRegex("\\d{2}-\\d{2}-\\d{4}");

        if(std::regex_search(dateTimeStr, dateTimeRegex)) {
            std::replace( dateTimeStr.begin(), dateTimeStr.end(), '-', ' ');
            std::istringstream( dateTimeStr ) >> day >> month >> year;
            dateTime.Initialise(year, month, day, today.tm_hour, today.tm_min, today.tm_sec, 0);
        } else {
            std::cout << "Invalid given Date format, using today's date" << std::endl;
        }
    } catch (...) {
        std::cout << "Extracting date parameter failed, regex might not be supported on your system. GCC version >=4.9.2 is required. Using default Date" << std::endl;
    }

    return dateTime;
}

float Settings::getSymbolRate() const
{
    float symbolRate = 72000.0f;

    if(mArgs.count("-s")) {
        symbolRate = atof(mArgs.at("-s").c_str());
    }
    if(mArgs.count("--symbolrate")) {
        symbolRate =  atof(mArgs.at("--symbolrate").c_str());
    }

    return symbolRate;
}

std::string Settings::getDemodulatorMode() const
{
    std::string modeStr = std::string("qpsk");

    if(mArgs.count("-m")) {
        modeStr = mArgs.at("-m");
    }
    if(mArgs.count("--mode")) {
        modeStr =  mArgs.at("--mode");
    }

    return modeStr;
}

bool Settings::differentialDecode() const
{
    bool result = false;

    if(mArgs.count("--diff")) {
        std::istringstream(mArgs.at("--diff")) >> result;
    }

    return result;
}

bool Settings::deInterleave() const
{
    bool result = false;

    if(mArgs.count("--int")) {
        std::istringstream(mArgs.at("--int")) >> result;
    }

    return result;
}
