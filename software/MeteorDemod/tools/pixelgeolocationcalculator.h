#ifndef PIXELGEOLOCATIONCALCULATOR_H
#define PIXELGEOLOCATIONCALCULATOR_H
#include <string>
#include <math.h>
#include <list>
#include <vector>
#include <SGP4.h>
#include <CoordGeodetic.h>
#include "matrix.h"
#include "vector.h"
#include "tlereader.h"

class PixelGeolocationCalculator
{
public:
    template<typename T>
    struct CartesianCoordinateT {
        T x;
        T y;
    };

    template<typename T>
    friend std::ostream& operator << (std::ostream &o, const CartesianCoordinateT<T> &coord) {
        return o << "x: " << coord.x << "\ty: " << coord.y;
    }

    typedef CartesianCoordinateT<int> CartesianCoordinate;
    typedef CartesianCoordinateT<float> CartesianCoordinateF;
    typedef CartesianCoordinateT<double> CartesianCoordinateD;

private:
    PixelGeolocationCalculator();

public:
    PixelGeolocationCalculator(const TleReader::TLE &tle, const DateTime &passStart, const TimeSpan &passLength, double alfa, double delta, int earthRadius = 6378, int satelliteAltitude = 825);

    void calcPixelCoordinates();

    void save(const std::string &path);
    void load(const std::string &path);

public:

    int getGeorefMaxImageHeight() const {
        return (mEquidistantCartesianCoordinates.size() / 158) * 10;
    }

    const CartesianCoordinateF &getTopLeftEquidistant() const {
        return mEquidistantCartesianCoordinates[0];
    }

    const CartesianCoordinateF &getTopRightEquidistant() const {
        return mEquidistantCartesianCoordinates[157];
    }

    const CartesianCoordinateF &getBottomLeftEquidistant() const {
        return mEquidistantCartesianCoordinates[mEquidistantCartesianCoordinates.size() - 158];
    }

    const CartesianCoordinateF &getBottomRightEquidistant() const {
        return mEquidistantCartesianCoordinates[mEquidistantCartesianCoordinates.size() - 1];
    }

    const CartesianCoordinateF &getEquidistantAt(unsigned int x, unsigned int y) const {
        return mEquidistantCartesianCoordinates[((x / 10)) + ((y / 10) * 158)];
    }

    const CartesianCoordinateF &getTopLeftMercator() const {
        return mMercatorCartesianCoordinates[0];
    }

    const CartesianCoordinateF &getTopRightMercator() const {
        return mMercatorCartesianCoordinates[157];
    }

    const CartesianCoordinateF &getBottomLeftMercator() const {
        return mMercatorCartesianCoordinates[mMercatorCartesianCoordinates.size() - 158];
    }

    const CartesianCoordinateF &getBottomRightMercator() const {
        return mMercatorCartesianCoordinates[mMercatorCartesianCoordinates.size() - 1];
    }

    const CoordGeodetic &getCenterCoordinate() const {
        return mCenterCoordinate;
    }

    const CartesianCoordinateF &getMercatorAt(unsigned int x, unsigned int y) const {
        return mMercatorCartesianCoordinates[((x / 10)) + ((y / 10) * 158)];
    }

public:
    static CartesianCoordinateF coordinateToMercatorProjection(double latitude, double longitude, double radius) {
        return coordinateToMercatorProjection(CoordGeodetic(latitude, longitude, 0), radius);
    }

    static CartesianCoordinateF coordinateToAzimuthalEquidistantProjection(double latitude, double longitude, double centerLatitude, double centerLongitude, double radius) {
        return coordinateToAzimuthalEquidistantProjection(CoordGeodetic(latitude, longitude, 0), CoordGeodetic(centerLatitude, centerLongitude, 0), radius);
    }

    static CartesianCoordinateF coordinateToMercatorProjection(const CoordGeodetic &coordinate, double radius) {
        CartesianCoordinateF cartesianCoordinate;
        CoordGeodetic correctedCoordinate = coordinate;

        if (coordinate.latitude > degreeToRadian(85.05113))
        {
            correctedCoordinate.latitude = degreeToRadian(85.05113);
        }
        else if (coordinate.latitude < degreeToRadian(-85.05113))
        {
            correctedCoordinate.latitude = degreeToRadian(-85.05113);
        }

        cartesianCoordinate.x = radius * (M_PI + correctedCoordinate.longitude);
        cartesianCoordinate.y = radius * (M_PI - log(tan(M_PI / 4.0 + (correctedCoordinate.latitude) / 2.0)));
        return  cartesianCoordinate;
    }

    static CartesianCoordinateF coordinateToAzimuthalEquidistantProjection(const CoordGeodetic &coordinate, const CoordGeodetic &centerCoordinate, double radius) {
        CartesianCoordinateF cartesianCoordinate;
        cartesianCoordinate.x = radius * (cos(coordinate.latitude) * sin(coordinate.longitude - centerCoordinate.longitude));
        cartesianCoordinate.y = -radius * (cos(centerCoordinate.latitude) * sin(coordinate.latitude) - sin(centerCoordinate.latitude) * cos(coordinate.latitude) * cos(coordinate.longitude - centerCoordinate.longitude));
        return cartesianCoordinate;
    }

private:
    void calculateCartesionCoordinates();
    Vector locationToVector(const CoordGeodetic &location);
    CoordGeodetic vectorToLocation(const Vector &vector);
    CoordGeodetic los_to_earth(const CoordGeodetic &position, double roll, double pitch, double yaw);
    CoordGeodetic los_to_earth(const Vector &position, double roll, double pitch, double yaw);
    double calculateBearingAngle(const CoordGeodetic &start, const CoordGeodetic &end);
    Matrix4x4 lookAt(const Vector3 &position, const Vector3 &target, const Vector3 &up);

    static double degreeToRadian(double degree)
    {
        return (M_PI * degree / 180.0);
    }

    static double radioanToDegree(double radian)
    {
        return radian * (180.0 / M_PI);
    }

private:
    Tle mTle;
    SGP4 mSgp4;
    DateTime mPassStart;
    TimeSpan mPassLength;
    double mAlfa, mDelta;
    int mEarthradius;
    int mSatelliteAltitude;
    std::vector<CoordGeodetic> mCoordinates;
    std::vector<CartesianCoordinateF> mMercatorCartesianCoordinates;
    std::vector<CartesianCoordinateF> mEquidistantCartesianCoordinates;
    CoordGeodetic mCenterCoordinate;


    static constexpr double PIXELTIME_MINUTES = 0.02564876089324618736383442265795;  //Just a rough calculation for every 10 pixel in minutes
    static constexpr double PIXELTIME_MS = 154.0;
};

#endif // PIXELGEOLOCATIONCALCULATOR_H
