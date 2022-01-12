#ifndef DBFILEREADER_H
#define DBFILEREADER_H

#include <string>
#include <iostream>
#include <fstream>
#include "databuffer.h"

namespace GIS {

class DbFileReader
{
public:
    struct Header {
        Header() {

        }

        Header(const DataBuffer &buffer);

        static size_t size() {
            return 32;
        }

        uint8_t type;
        uint8_t lastUpdated[3];    //YYMMDD
        uint32_t numberOfRecords;
        uint16_t headerSize;
        uint16_t recordSize;
        uint8_t _reserved[20];

        friend std::ostream &operator << (std::ostream &os, const Header &header) {
            os << "DBFile type: " << static_cast<int>(header.type) << " NumberOfRecords: " << header.numberOfRecords;
            return os;
        }
    };

    struct Field {

        Field() {

        }

        Field(const DataBuffer &buffer);

        static size_t size() {
            return 32;
        }

        char fieldName[11];
        char fieldtype;
        uint32_t fieldAddress;
        uint8_t fieldLength;
        uint8_t fieldCount;
        uint8_t _reserved[2];
        uint8_t workAreaID;
        uint8_t _reserved2[2];
        uint8_t setFieldsFlag;
        uint8_t _reserved3[8];

        friend std::ostream &operator << (std::ostream &os, const Field &field) {
            os << std::string(field.fieldName, 11) << "\t\t" << field.fieldtype << "\t" << static_cast<int>(field.fieldLength) << "\t" << static_cast<int>(field.fieldCount);
            return os;
        }

    };

    enum struct FieldType {
        Character = 'C',
        Date      = 'D',
        Float     = 'F',
        Numeric   = 'N',
        Logical   = 'L'
    };

public:
    DbFileReader(const std::string &filePath);
    ~DbFileReader();

    DbFileReader(const DbFileReader&) = delete;
    DbFileReader &operator = (const DbFileReader&) = delete;

public:
    bool load();
    void test();
    std::vector<std::string> getFieldValues(uint32_t record) const;

public:
    uint32_t getRecordCount() const {
        return mFileHeader.numberOfRecords;
    }
    const std::vector<Field> &getFieldAttributes() const {
        return mFields;
    }

private:
    std::string trim(const std::string &str) const {
        size_t pos = str.length();
        for (std::string::const_reverse_iterator rit=str.rbegin(); rit!=str.rend(); ++rit, --pos) {
            if(*rit != ' ')
                break;
        }

        if(pos > 0 && pos != str.length()) {
            return str.substr(0, pos);
        }
        return str;
    }

private:
    std::string mFilePath;
    mutable std::ifstream mBinaryData;
    Header mFileHeader;
    bool mIsLoaded;
    uint16_t mLargestRecordSize;
    std::vector<Field> mFields;
    mutable std::vector<char> mRecordBuffer;
};

} //namespace

#endif // DBFILEREADER_H
