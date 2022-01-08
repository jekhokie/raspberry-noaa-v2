#ifndef TLEREADER_H
#define TLEREADER_H

#include <string>
#include <map>
#include <ostream>

class TleReader
{
public:
    struct TLE {
        std::string satellite;
        std::string line1;
        std::string line2;
    };

    friend std::ostream& operator << (std::ostream &o, const TLE &tle) {
        return o << tle.satellite << std::endl << tle.line1 << std::endl << tle.line2;
    }

public:
    TleReader(const std::string &filePath);

    void processFile();

    bool getTLE(const std::string &sateliteName, TLE &tle);

private:
    std::string trim(const std::string& s)
    {
        size_t end = s.find_last_not_of(" \r");
        return (end == std::string::npos) ? "" : s.substr(0, end + 1);
    }

private:
    std::string mFilePath;
    std::map<std::string, TLE> mTleList;

};

#endif // TLEREADER_H
