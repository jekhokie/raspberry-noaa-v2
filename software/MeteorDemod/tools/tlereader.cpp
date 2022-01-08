#include "tlereader.h"
#include <fstream>
#include <iostream>

TleReader::TleReader(const std::string &filePath)
    : mFilePath(filePath)
{

}

void TleReader::processFile()
{
    std::ifstream fileReader;
    fileReader.open(mFilePath);
    TLE tle;
    std::string emptyLine;

    do {
        if(!fileReader.is_open()) {
            std::cout << "TLE file ( "<< mFilePath << " ) open failed" << std::endl;
            break;
        }

        while(true) {
            if(!std::getline(fileReader, tle.satellite)) {
                break;
            }

            if(!std::getline(fileReader, tle.line1)) {
                break;
            }

            if(!std::getline(fileReader, tle.line2)) {
                break;
            }

            tle.satellite = trim(tle.satellite);
            tle.line1 = trim(tle.line1);
            tle.line2 = trim(tle.line2);

            mTleList.insert(std::make_pair(tle.satellite, tle));
        }

        fileReader.close();

    } while (false);
}

bool TleReader::getTLE(const std::string &sateliteName, TLE &tle)
{
    if(mTleList.find(sateliteName) != mTleList.end()) {
        tle = mTleList[sateliteName];
        return true;
    }
    return false;
}
