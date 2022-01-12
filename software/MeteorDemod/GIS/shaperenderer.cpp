#include "shaperenderer.h"
#include <vector>
#include "pixelgeolocationcalculator.h"


GIS::ShapeRenderer::ShapeRenderer(const std::string shapeFile, const cv::Scalar &color, int earthRadius, int altitude)
    : ShapeReader(shapeFile)
    , mColor(color)
    , mEarthRadius(earthRadius)
    , mAltitude(altitude)
    , mThicknes(5)
    , mPointRadius(10)
    , mFontScale(2)
{

}

void GIS::ShapeRenderer::addNumericFilter(const std::string name, int value)
{
    mfilter.insert(std::make_pair(name, value));
}

void GIS::ShapeRenderer::setTextFieldName(const std::string &name)
{
    mTextFieldName = name;
}

void GIS::ShapeRenderer::drawShapeMercator(cv::Mat &src, float xStart, float yStart)
{
    if(!load()) {
        return;
    }

    if(getShapeType() == ShapeReader::ShapeType::stPolyline) {
        ShapeReader::RecordIterator *recordIterator = getRecordIterator();

        if(recordIterator) {
            for(recordIterator->begin(); *recordIterator != recordIterator->end(); ++(*recordIterator)) {
                ShapeReader::PolyLineIterator *polyLineIterator = getPolyLineIterator(*recordIterator);

                if(polyLineIterator) {
                    std::vector<cv::Point> polyLines;
                    for(polyLineIterator->begin(); *polyLineIterator != polyLineIterator->end(); ++(*polyLineIterator)) {
                        //std::cout << polyLineIterator->point.x << " " << polyLineIterator->point.y << std::endl;

                        PixelGeolocationCalculator::CartesianCoordinateF coordinate = PixelGeolocationCalculator::coordinateToMercatorProjection(polyLineIterator->point.y, polyLineIterator->point.x, mEarthRadius + mAltitude);

                        coordinate.x += -xStart;
                        coordinate.y += -yStart;

                        polyLines.push_back(cv::Point2d(coordinate.x, coordinate.y));
                    }

                    if(polyLines.size() > 1) {
                        cv::polylines(src, polyLines, false, mColor, mThicknes);
                    }

                    delete polyLineIterator;
                }
            }

            delete recordIterator;
        }
    } else if(getShapeType() == ShapeReader::ShapeType::stPoint) {
        ShapeReader::RecordIterator *recordIterator = getRecordIterator();

        if(mfilter.size() == 0) {
            if(recordIterator) {
                for(recordIterator->begin(); *recordIterator != recordIterator->end(); ++(*recordIterator)) {
                    ShapeReader::Point point(*recordIterator);

                    PixelGeolocationCalculator::CartesianCoordinateF coordinate = PixelGeolocationCalculator::coordinateToMercatorProjection(point.y, point.x, mEarthRadius + mAltitude);
                    coordinate.x += -xStart;
                    coordinate.y += -yStart;

                    cv::circle(src, cv::Point2d(coordinate.x, coordinate.y), mPointRadius, mColor, cv::FILLED);
                    cv::circle(src, cv::Point2d(coordinate.x, coordinate.y), mPointRadius, cv::Scalar(0,0,0), 1);
                }
            }
        } else {
            const DbFileReader &dbFilereader = getDbFilereader();
            const std::vector<DbFileReader::Field> fieldAttributes = dbFilereader.getFieldAttributes();

            if(recordIterator && hasDbFile()) {
                uint32_t i = 0;
                for(recordIterator->begin(); *recordIterator != recordIterator->end(); ++(*recordIterator), ++i) {
                    ShapeReader::Point point(*recordIterator);
                    std::vector<std::string> fieldValues = dbFilereader.getFieldValues(i);

                    PixelGeolocationCalculator::CartesianCoordinateF coordinate = PixelGeolocationCalculator::coordinateToMercatorProjection(point.y, point.x, mEarthRadius + mAltitude);
                    coordinate.x += -xStart;
                    coordinate.y += -yStart;

                    bool drawName = false;
                    size_t namePos = 0;

                    for(size_t n = 0; n < fieldAttributes.size(); n++) {
                        if(mfilter.count(fieldAttributes[n].fieldName) == 1) {
                            int population = 0;
                            try {
                                population = std::stoi(fieldValues[n]);
                            } catch (...) {
                                continue;
                            }

                            if(population >= mfilter[fieldAttributes[n].fieldName]) {
                                cv::circle(src, cv::Point2d(coordinate.x, coordinate.y), mPointRadius, mColor, cv::FILLED);
                                cv::circle(src, cv::Point2d(coordinate.x, coordinate.y), mPointRadius, cv::Scalar(0,0,0), 1);

                                drawName = true;
                            }
                        }

                        if(std::string(fieldAttributes[n].fieldName) == mTextFieldName) {
                            namePos = n;
                        }
                    }

                    if(drawName) {
                        int baseLine;
                        cv::Size size = cv::getTextSize(fieldValues[namePos], cv::FONT_ITALIC, mFontScale, mThicknes, &baseLine);
                        cv::putText(src, fieldValues[namePos], cv::Point2d(coordinate.x - (size.width/2), coordinate.y - size.height + baseLine), cv::FONT_ITALIC, mFontScale, cv::Scalar(0,0,0), mThicknes+1, cv::LINE_AA);
                        cv::putText(src, fieldValues[namePos], cv::Point2d(coordinate.x - (size.width/2), coordinate.y - size.height + baseLine), cv::FONT_ITALIC, mFontScale, mColor, mThicknes, cv::LINE_AA);
                    }
                }
            }
        }
    }
}

void GIS::ShapeRenderer::drawShapeEquidistant(cv::Mat &src, float xStart, float yStart, float xCenter, float yCenter)
{
    if(!load()) {
        return;
    }

    if(getShapeType() == ShapeReader::ShapeType::stPolyline) {
        ShapeReader::RecordIterator *recordIterator = getRecordIterator();

        if(recordIterator) {
            for(recordIterator->begin(); *recordIterator != recordIterator->end(); ++(*recordIterator)) {
                ShapeReader::PolyLineIterator *polyLineIterator = getPolyLineIterator(*recordIterator);

                if(polyLineIterator) {
                    std::vector<cv::Point> polyLines;
                    for(polyLineIterator->begin(); *polyLineIterator != polyLineIterator->end(); ++(*polyLineIterator)) {
                        //std::cout << polyLineIterator->point.x << " " << polyLineIterator->point.y << std::endl;

                        PixelGeolocationCalculator::CartesianCoordinateF coordinate = PixelGeolocationCalculator::coordinateToAzimuthalEquidistantProjection(polyLineIterator->point.y, polyLineIterator->point.x, xCenter, yCenter, mEarthRadius + mAltitude);

                        coordinate.x += -xStart;
                        coordinate.y += -yStart;

                        if(equidistantCheck(polyLineIterator->point.y, polyLineIterator->point.x, xCenter, yCenter)) {
                            polyLines.push_back(cv::Point2d(coordinate.x, coordinate.y));
                        }
                    }

                    if(polyLines.size() > 1) {
                        cv::polylines(src, polyLines, false, mColor, mThicknes);
                    }

                    delete polyLineIterator;
                }
            }

            delete recordIterator;
        }
    } else if(getShapeType() == ShapeReader::ShapeType::stPoint) {
        ShapeReader::RecordIterator *recordIterator = getRecordIterator();

        if(mfilter.size() == 0) {
            if(recordIterator) {
                for(recordIterator->begin(); *recordIterator != recordIterator->end(); ++(*recordIterator)) {
                    ShapeReader::Point point(*recordIterator);

                    PixelGeolocationCalculator::CartesianCoordinateF coordinate = PixelGeolocationCalculator::coordinateToAzimuthalEquidistantProjection(point.y, point.x, xCenter, yCenter, mEarthRadius + mAltitude);
                    coordinate.x += -xStart;
                    coordinate.y += -yStart;

                    if(equidistantCheck(point.y, point.x, xCenter, yCenter) == false) {
                        continue;
                    }

                    cv::circle(src, cv::Point2d(coordinate.x, coordinate.y), mPointRadius, mColor, cv::FILLED);
                    cv::circle(src, cv::Point2d(coordinate.x, coordinate.y), mPointRadius, cv::Scalar(0,0,0), 1);
                }
            }
        } else {
            const DbFileReader &dbFilereader = getDbFilereader();
            const std::vector<DbFileReader::Field> fieldAttributes = dbFilereader.getFieldAttributes();

            if(recordIterator && hasDbFile()) {
                uint32_t i = 0;
                for(recordIterator->begin(); *recordIterator != recordIterator->end(); ++(*recordIterator), ++i) {
                    ShapeReader::Point point(*recordIterator);
                    std::vector<std::string> fieldValues = dbFilereader.getFieldValues(i);

                    PixelGeolocationCalculator::CartesianCoordinateF coordinate = PixelGeolocationCalculator::coordinateToAzimuthalEquidistantProjection(point.y, point.x, xCenter, yCenter, mEarthRadius + mAltitude);
                    coordinate.x += -xStart;
                    coordinate.y += -yStart;

                    if(equidistantCheck(point.y, point.x, xCenter, yCenter) == false) {
                        continue;
                    }

                    bool drawName = false;
                    size_t namePos = 0;

                    for(size_t n = 0; n < fieldAttributes.size(); n++) {
                        if(mfilter.count(fieldAttributes[n].fieldName) == 1) {
                            int population = 0;
                            try {
                                population = std::stoi(fieldValues[n]);
                            } catch (...) {
                                continue;
                            }

                            if(population >= mfilter[fieldAttributes[n].fieldName]) {
                                cv::circle(src, cv::Point2d(coordinate.x, coordinate.y), mPointRadius, mColor, cv::FILLED);
                                cv::circle(src, cv::Point2d(coordinate.x, coordinate.y), mPointRadius, cv::Scalar(0,0,0), 1);

                                drawName = true;
                            }
                        }

                        if(std::string(fieldAttributes[n].fieldName) == mTextFieldName) {
                            namePos = n;
                        }
                    }

                    if(drawName) {
                        int baseLine;
                        cv::Size size = cv::getTextSize(fieldValues[namePos], cv::FONT_ITALIC, mFontScale, mThicknes, &baseLine);
                        cv::putText(src, fieldValues[namePos], cv::Point2d(coordinate.x - (size.width/2), coordinate.y - size.height + baseLine), cv::FONT_ITALIC, mFontScale, cv::Scalar(0,0,0), mThicknes+1, cv::LINE_AA);
                        cv::putText(src, fieldValues[namePos], cv::Point2d(coordinate.x - (size.width/2), coordinate.y - size.height + baseLine), cv::FONT_ITALIC, mFontScale, mColor, mThicknes, cv::LINE_AA);
                    }
                }
            }
        }
    }
}

bool GIS::ShapeRenderer::equidistantCheck(float x, float y, float centerLongitude, float centerLatitude)
{
    int minLongitude = static_cast<int>(centerLongitude - 90);
    int maxLongitude = static_cast<int>(centerLongitude + 90);
    int minLatitude = static_cast<int>(centerLatitude - 45);
    int maxLatitude = static_cast<int>(centerLatitude + 45);

    //Normalize
    minLongitude = (minLongitude + 540) % 360 - 180;
    maxLongitude = (maxLongitude + 540) % 360 - 180;

    if(minLatitude < -90)
    {
        minLatitude = ((minLatitude + 270) % 180 - 90) * -1;
    }
    if(maxLatitude > 90)
    {
        maxLatitude = ((maxLatitude + 270) % 180 - 90) * -1;
    }



    if (x < minLongitude || x > maxLongitude || y < minLatitude || y > maxLatitude)
    {
        return false;
    }
    else
    {
        return true;
    }
}
