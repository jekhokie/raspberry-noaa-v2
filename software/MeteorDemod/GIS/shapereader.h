#ifndef SHAPEREADER_H
#define SHAPEREADER_H

#include <string>
#include <iostream>
#include <vector>
#include <iterator>
#include "databuffer.h"
#include "dbfilereader.h"

namespace GIS {

class ShapeReader
{
public:
    enum ShapeType
    {
        stUndefined = -1,
        stNull = 0,
        stPoint = 1,
        stPolyline = 3,
        stPolygon = 5,
        stMultiPoint = 8,
        stPointZ = 11,
        stPolyLineZ = 13,
        stPolygonZ = 15,
        stMultiPointZ = 18,
        stPointM = 21,
        stPolyLineM = 23,
        stPolygonM = 25,
        stMultiPointM = 28,
        stMultiPatch = 31
    };

    struct ShapeHeader {

        ShapeHeader() {

        }

        ShapeHeader(const DataBuffer &buffer) {
            size_t index = 0;
            buffer.valueAtIndex(index, headerCode, BigEndian);
            index+=20;
            buffer.valueAtIndex(index, fileLength, BigEndian);
            buffer.valueAtIndex(index, version, BigEndian);
            buffer.valueAtIndex(index, shapeFileType, LittleEndian);
            buffer.valueAtIndex(index, minX, LittleEndian);
            buffer.valueAtIndex(index, minY, LittleEndian);
            buffer.valueAtIndex(index, maxX, LittleEndian);
            buffer.valueAtIndex(index, maxY, LittleEndian);
            buffer.valueAtIndex(index, minZ, LittleEndian);
            buffer.valueAtIndex(index, maxZ, LittleEndian);
            buffer.valueAtIndex(index, minM, LittleEndian);
            buffer.valueAtIndex(index, maxM, LittleEndian);

        }

        int32_t headerCode;    //bigendian
        int32_t _unused;       //bigendian
        int32_t _unused2;      //bigendian
        int32_t _unused3;      //bigendian
        int32_t _unused4;      //bigendian
        int32_t _unused5;      //bigendian
        int32_t fileLength;    //bigendian
        int32_t version;
        int32_t shapeFileType;
        double minX;
        double minY;
        double maxX;
        double maxY;
        double minZ;
        double maxZ;
        double minM;
        double maxM;
    };

    struct RecordHeader {
        RecordHeader()
            : recordNumber(0)
            , recordLength(0)
            , shapeType(0) {

        }

        RecordHeader(const DataBuffer &buffer) {
            size_t index = 0;
            buffer.valueAtIndex(index, recordNumber, BigEndian);
            buffer.valueAtIndex(index, recordLength, BigEndian);
            buffer.valueAtIndex(index, shapeType, LittleEndian);
        }

        int32_t recordNumber;  //bigendian
        int32_t recordLength;  //bigendian
        int32_t shapeType;
    };

    struct Point;   //Forward declaration

    class RecordIterator {
        friend struct Point;
    public:
        RecordIterator(std::ifstream &inputStream)
            : mInputStream (inputStream){

        }

        RecordHeader operator*() const {
            return recordHeader;
        }

        RecordIterator &operator++(){
            mRecordPosition += recordHeader.recordLength * sizeof (int16_t) - sizeof(int32_t) + 12;
            mInputStream.seekg(mRecordPosition);

            DataBuffer recordHeaderBuffer(12);
            mInputStream.read(reinterpret_cast<char*>(recordHeaderBuffer.buffer()), recordHeaderBuffer.size());
            recordHeader = RecordHeader(recordHeaderBuffer);
            return *this;
        }

        RecordIterator begin() {
            mRecordPosition = 100;
            mInputStream.seekg(mRecordPosition);
            DataBuffer recordHeaderBuffer(12);
            mInputStream.read(reinterpret_cast<char*>(recordHeaderBuffer.buffer()), recordHeaderBuffer.size());
            recordHeader = RecordHeader(recordHeaderBuffer);
            return *this;
        }

        RecordIterator end() {
            return RecordIterator(mInputStream);
        }

        bool operator!=(const RecordIterator &rhs) const {
            return recordHeader.recordNumber != rhs.recordHeader.recordNumber;
        }

        bool operator==(const RecordIterator &rhs) const {
            return recordHeader.recordNumber == rhs.recordHeader.recordNumber;
        }

        RecordHeader recordHeader;
        int mRecordPosition;
    protected:
        std::ifstream &mInputStream;
    };

    struct Point
    {
        Point()
            : x(0)
            , y(0) {

        }

        Point(const DataBuffer &buffer) {
            size_t index = 0;
            buffer.valueAtIndex(index, x, LittleEndian);
            buffer.valueAtIndex(index, y, LittleEndian);
        }

        Point(std::istream &inputStream, int recordPosition ) {
            size_t index = 0;
            DataBuffer pointBuffer(16);
            inputStream.seekg(recordPosition);
            inputStream.read(reinterpret_cast<char*>(pointBuffer.buffer()), pointBuffer.size());
            pointBuffer.valueAtIndex(index, x, LittleEndian);
            pointBuffer.valueAtIndex(index, y, LittleEndian);
        }

        Point(const RecordIterator &recordIterator) {
            size_t index = 0;
            DataBuffer pointBuffer(16);
            recordIterator.mInputStream.seekg(recordIterator.mRecordPosition+12);   //Recordpos + Recordheader
            recordIterator.mInputStream.read(reinterpret_cast<char*>(pointBuffer.buffer()), pointBuffer.size());
            pointBuffer.valueAtIndex(index, x, LittleEndian);
            pointBuffer.valueAtIndex(index, y, LittleEndian);
        }

        double x;
        double y;
    };

    struct PolyLineHeader
    {
        PolyLineHeader()
            : numberOfparts (0)
            , numberOfpoints(0) {

        }

        PolyLineHeader(const DataBuffer &buffer) {
            size_t index = 0;
            buffer.valueAtIndex(index, box[0], LittleEndian);
            buffer.valueAtIndex(index, box[1], LittleEndian);
            buffer.valueAtIndex(index, box[2], LittleEndian);
            buffer.valueAtIndex(index, box[3], LittleEndian);
            buffer.valueAtIndex(index, numberOfparts, LittleEndian);
            buffer.valueAtIndex(index, numberOfpoints, LittleEndian);
        }

        double box[4];
        int32_t numberOfparts;
        int32_t numberOfpoints;
    };

    struct MultiPointHeader
    {
        MultiPointHeader()
            : numberOfpoints (0) {

        }

        MultiPointHeader(const DataBuffer &buffer) {
            size_t index = 0;
            buffer.valueAtIndex(index, box[0], LittleEndian);
            buffer.valueAtIndex(index, box[1], LittleEndian);
            buffer.valueAtIndex(index, box[2], LittleEndian);
            buffer.valueAtIndex(index, box[3], LittleEndian);
            buffer.valueAtIndex(index, numberOfpoints, LittleEndian);
        }

        double box[4];
        int32_t numberOfpoints;
    };

    class PolyLineIterator {
    public:
        PolyLineIterator(std::ifstream &inputStream, int recordPosition)
            : mInputStream (inputStream)
            , mRecordPosition(recordPosition)
            , mNumberOfPoint (0){

        }

        Point operator*() const {
            return point;
        }

        PolyLineIterator &operator++() {
            if(mNumberOfPoint < mPolyLineHeader.numberOfpoints) {
                DataBuffer pointBuffer(16);
                mInputStream.read(reinterpret_cast<char*>(pointBuffer.buffer()), pointBuffer.size());
                point = Point(pointBuffer);
                mNumberOfPoint++;
                return *this;
            } else {
                mNumberOfPoint = 0;
                point = Point();
                return *this;
            }
        }

        PolyLineIterator begin() {
            int filePosition = mRecordPosition + 12;   //Recordpos + Recordheader
            mInputStream.seekg(filePosition);
            filePosition += 40;
            DataBuffer polyLineHeaderBuffer(40);
            mInputStream.read(reinterpret_cast<char*>(polyLineHeaderBuffer.buffer()), polyLineHeaderBuffer.size());
            mPolyLineHeader = PolyLineHeader(polyLineHeaderBuffer);

            filePosition += 4 * mPolyLineHeader.numberOfparts;
            mInputStream.seekg(filePosition);
            DataBuffer pointBuffer(16);
            mInputStream.read(reinterpret_cast<char*>(pointBuffer.buffer()), pointBuffer.size());
            point = Point(pointBuffer);
            mNumberOfPoint = 1;

            return *this;
        }

        PolyLineIterator end() {
            return PolyLineIterator(mInputStream, mRecordPosition);
        }

        bool operator!=(const PolyLineIterator &rhs) const {
            return mNumberOfPoint != rhs.mNumberOfPoint;
        }

        bool operator==(const PolyLineIterator &rhs) const {
            return mNumberOfPoint == rhs.mNumberOfPoint;
        }

        Point point;

    protected:
        std::ifstream &mInputStream;
        const int mRecordPosition;
        int mNumberOfPoint;
        PolyLineHeader mPolyLineHeader;
    };

    class MultiPointIterator {
    public:
        MultiPointIterator(std::ifstream &inputStream, int recordPosition)
            : mInputStream (inputStream)
            , mRecordPosition(recordPosition)
            , mNumberOfPoint (0){

        }

        Point operator*() const {
            return point;
        }

        MultiPointIterator &operator++() {
            if(mNumberOfPoint < mMultiPointHeader.numberOfpoints) {
                DataBuffer pointBuffer(16);
                mInputStream.read(reinterpret_cast<char*>(pointBuffer.buffer()), pointBuffer.size());
                point = Point(pointBuffer);
                mNumberOfPoint++;
                return *this;
            } else {
                mNumberOfPoint = 0;
                point = Point();
                return *this;
            }
        }

        MultiPointIterator begin() {
            mInputStream.seekg(mRecordPosition + 12);   //Recordpos + Recordheader
            DataBuffer multiPointHeaderBuffer(36);
            mInputStream.read(reinterpret_cast<char*>(multiPointHeaderBuffer.buffer()), multiPointHeaderBuffer.size());
            mMultiPointHeader = MultiPointHeader(multiPointHeaderBuffer);

            DataBuffer pointBuffer(16);
            mInputStream.read(reinterpret_cast<char*>(pointBuffer.buffer()), pointBuffer.size());
            point = Point(pointBuffer);
            mNumberOfPoint = 1;

            return *this;
        }

        MultiPointIterator end() {
            return MultiPointIterator(mInputStream, mRecordPosition);
        }

        bool operator!=(const MultiPointIterator &rhs) const {
            return mNumberOfPoint != rhs.mNumberOfPoint;
        }

        bool operator==(const MultiPointIterator &rhs) const {
            return mNumberOfPoint == rhs.mNumberOfPoint;
        }

        Point point;

    protected:
        std::ifstream &mInputStream;
        const int mRecordPosition;
        int mNumberOfPoint;
        MultiPointHeader mMultiPointHeader;
    };


public:
    ShapeReader(const std::string &shapeFile);
    ~ShapeReader();

    ShapeReader(const ShapeReader&) = delete;
    ShapeReader &operator = (const ShapeReader&) = delete;

public:

    bool load();

    ShapeType getShapeType() const {
        if(mLoaded) {
            return static_cast<ShapeType>(mShapeHeader.shapeFileType);
        } else {
            return stUndefined;
        }
    }

    RecordIterator *getRecordIterator() {
        if(mLoaded) {
            return new RecordIterator(mBinaryData);
        }
        return nullptr;
    }
    PolyLineIterator *getPolyLineIterator(const RecordIterator &recordIterator) {
        if(mLoaded) {
            return new PolyLineIterator(mBinaryData, recordIterator.mRecordPosition);
        }
        return nullptr;
    }

    MultiPointIterator *getMultiPointIterator(const RecordIterator &recordIterator) {
        if(mLoaded) {
            return new MultiPointIterator(mBinaryData, recordIterator.mRecordPosition);
        }
        return nullptr;
    }

    const DbFileReader &getDbFilereader() const {
        return mDbFileReader;
    }

    bool hasDbFile() const {
        return mHasDbFile;
    }

private:
    std::string mFilePath;
    std::ifstream mBinaryData;
    ShapeHeader mShapeHeader;
    bool mLoaded;
    DbFileReader mDbFileReader;
    bool mHasDbFile;
};

}//namespace GIS

#endif // SHAPEREADER_H
