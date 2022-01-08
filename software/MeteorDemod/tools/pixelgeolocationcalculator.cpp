#include "pixelgeolocationcalculator.h"
#include <fstream>

PixelGeolocationCalculator::PixelGeolocationCalculator(const TleReader::TLE &tle, const DateTime &passStart, const TimeSpan &passLength, double alfa, double delta, int earthRadius, int satelliteAltitude)
    : mTle(tle.satellite, tle.line1, tle.line2)
    , mSgp4(mTle)
    , mPassStart(passStart)
    , mPassLength(passLength)
    , mAlfa(alfa)
    , mDelta(delta)
    , mEarthradius(earthRadius)
    , mSatelliteAltitude(satelliteAltitude)
{

}

void PixelGeolocationCalculator::calcPixelCoordinates()
{
    double angle;
    CoordGeodetic satOnGroundPrev;
    CoordGeodetic satOnGround;

    std::vector<Eci> passList;

    DateTime passEnd = DateTime(mPassStart).Add(mPassLength);

    for(DateTime currentTime = mPassStart; currentTime <= passEnd; currentTime = currentTime.AddMicroseconds(PIXELTIME_MS * 10 * 1000))
    {
        passList.push_back(mSgp4.FindPosition(currentTime));
    }

    std::vector<Eci>::const_iterator it = passList.begin();
    std::vector<Eci>::const_iterator prevIt = passList.begin();
    ++it;

    DateTime currentTime = mPassStart;
    for (unsigned int i = 0 ; it != passList.end(); prevIt = it,  ++it, i++)
    {
        satOnGroundPrev = Eci(currentTime, prevIt->Position(), prevIt->Velocity()).ToGeodetic();
        satOnGround = Eci(currentTime, it->Position(), it->Velocity()).ToGeodetic();
        currentTime = currentTime.AddMicroseconds(PIXELTIME_MS * 10 * 1000);

        angle = calculateBearingAngle(satOnGround, satOnGroundPrev);
        angle = degreeToRadian(90) - angle;

        for (int n = 79; n > -79; n--)
        {
            CoordGeodetic coordinate (los_to_earth(satOnGround, degreeToRadian((((mAlfa) / 79.0)) * n), 0, angle));
            mCoordinates.push_back(coordinate);
        }
    }

    calculateCartesionCoordinates();
}

void PixelGeolocationCalculator::save(const std::string &path)
{
    std::ofstream file(path);

    if(!file) {
        return;
    }

    std::vector<CoordGeodetic>::const_iterator it;
    int i = 0;
    int n = 0;

    for (it = mCoordinates.begin(); it != mCoordinates.end(); ++it, n++) {
        file << (n * 10) << " " << (i * 10) << " " << std::setprecision (15) << radioanToDegree(it->latitude) << " " << radioanToDegree(it->longitude) <<  std::endl;

        if(n == 157) {
            n = -1;
            i++;
        }
    }

    file.close();
}

void PixelGeolocationCalculator::load(const std::string &path)
{
    std::ifstream gcpReader(path);

    if(!gcpReader) {
        std::cout << "Open GCP file failed";
        return;
    }

    mCoordinates.clear();

    int i, n;
    double longitude, latitude;
    while (gcpReader >> i >> n >> latitude >> longitude)
    {
        mCoordinates.push_back(CoordGeodetic(latitude, longitude, 0, false));
    }

    calculateCartesionCoordinates();
}

void PixelGeolocationCalculator::calculateCartesionCoordinates()
{
    double radius = mEarthradius + mSatelliteAltitude;

    mMercatorCartesianCoordinates.clear();
    mEquidistantCartesianCoordinates.clear();

    mMercatorCartesianCoordinates.resize(mCoordinates.size());
    mEquidistantCartesianCoordinates.resize(mCoordinates.size());

    mCenterCoordinate.latitude = mCoordinates[mCoordinates.size() / 2 + 79].latitude;
    mCenterCoordinate.longitude = mCoordinates[mCoordinates.size() / 2 + 79].longitude;

    for (unsigned int i = 0; i < mMercatorCartesianCoordinates.size(); i++) {

        //Azimuthal Equidistant Projection
        mEquidistantCartesianCoordinates[i] = coordinateToAzimuthalEquidistantProjection(mCoordinates[i], mCenterCoordinate, radius);

        //Mercator Projection
        mMercatorCartesianCoordinates[i] = coordinateToMercatorProjection(mCoordinates[i], radius);
    }
}

Vector PixelGeolocationCalculator::locationToVector(const CoordGeodetic &location)
{
    double cosLat = cos(location.latitude);
    double sinLat = sin(location.latitude);
    double cosLon = cos(location.longitude);
    double sinLon = sin(location.longitude);

    double radA = 6378.137;
    double f = 1.0 / 298.257223563;  //Flattening factor WGS84 Model
    double radB = radA * (1 - f);

    double N = pow(radA, 2) / sqrt(pow(radA, 2) * pow(cosLat, 2) + pow(radB, 2) * pow(sinLat, 2));

    double x = (N + location.altitude) * cosLat * cosLon;
    double y = (N + location.altitude) * cosLat * sinLon;
    double z = ((pow(radB, 2) / pow(radA, 2)) * N + location.altitude) * sinLat;

    return Vector(x,y, z);
}

CoordGeodetic PixelGeolocationCalculator::vectorToLocation(const Vector &vector)
{
    double a = 6378.137;
    double f = 1.0 / 298.257223563;  //Flattening factor WGS84 Model
    double b = a * (1 - f);

    double r = sqrt(pow(vector.x, 2) + pow(vector.y, 2) + pow(vector.z, 2));

    double lat = asin(vector.z / r);
    double lon = atan2(vector.y, vector.x);

    double e = sqrt((pow(a, 2) - pow(b, 2)) / pow(a, 2));
    double e2 = sqrt((pow(a, 2) - pow(b, 2)) / pow(b, 2));
    double p = sqrt(pow(vector.x, 2) + pow(vector.y, 2));
    double phi = atan2(vector.z * a, p * b);
    lat = atan2(vector.z + pow(e2, 2) * b * pow(sin(phi), 3), p - pow(e, 2) * a * pow(cos(phi), 3));

    return CoordGeodetic(lat, lon, 0, true);
}

CoordGeodetic PixelGeolocationCalculator::los_to_earth(const CoordGeodetic &position, double roll, double pitch, double yaw)
{
    Vector vector = locationToVector(position);
    return los_to_earth(vector, roll, pitch, yaw);
}

CoordGeodetic PixelGeolocationCalculator::los_to_earth(const Vector &position, double roll, double pitch, double yaw)
{
    double a = 6371.0087714;
    double b = 6371.0087714;
    double c = 6356.752314245;

    double x = position.x;
    double y = position.y;
    double z = position.z;

    Matrix4x4 matrix (
        1, 0, 0, position.x,
        0, 1, 0, position.y,
        0, 0, 1, position.z,
        0, 0, 0, 1);

    Vector lookVector(0, 0, 0);
    Matrix4x4 lookMatrix = lookAt(position, lookVector, Vector(0, 0, 1));
    Matrix4x4 rotateX = Matrix4x4::CreateRotationX(roll + degreeToRadian(mDelta));
    Matrix4x4 rotateY = Matrix4x4::CreateRotationY(pitch);
    Matrix4x4 rotateZ = Matrix4x4::CreateRotationZ(yaw);
    matrix = matrix * lookMatrix * rotateZ * rotateY * rotateX;

    Vector vector3(matrix.mElements[2], matrix.mElements[6], matrix.mElements[10]);

    double u = vector3.x;
    double v = vector3.y;
    double w = vector3.z;

    double value = -pow(a, 2) * pow(b, 2) * w * z - pow(a, 2) * pow(c, 2) * v * y - pow(b, 2) * pow(c, 2) * u * x;
    double radical = pow(a, 2) * pow(b, 2) * pow(w, 2) + pow(a, 2) * pow(c, 2) * pow(v, 2) - pow(a, 2) * pow(v, 2) * pow(z, 2) + 2 * pow(a, 2) * v * w * y * z - pow(a, 2) * pow(w, 2) * pow(y, 2) + pow(b, 2) * pow(c, 2) * pow(u, 2) - pow(b, 2) * pow(u, 2) * pow(z, 2) + 2 * pow(b, 2) * u * w * x * z - pow(b, 2) * pow(w, 2) * pow(x, 2) - pow(c, 2) * pow(u, 2) * pow(y, 2) + 2 * pow(c, 2) * u * v * x * y - pow(c, 2) * pow(v, 2) * pow(x, 2);
    double magnitude = pow(a, 2) * pow(b, 2) * pow(w, 2) + pow(a, 2) * pow(c, 2) * pow(v, 2) + pow(b, 2) * pow(c, 2) * pow(u, 2);

    /*double t = -(1 / (pow(c, 2) * (pow(u, 2) + pow(v, 2)) + pow(a, 2) * pow(w, 2))) *
       (pow(c, 2) * (u * x + v * y) + pow(a, 2) * w * z +
       0.5 * sqrt(4 * pow((pow(a, 2) * (u * x + v * y) + pow(a, 2) * w * z), 2) - 4 * (pow(a, 2) * (pow(u, 2) + pow(v, 2)) + pow(a, 2) * pow(w, 2)) * (pow(c, 2) * (-pow(a, 2) + pow(x, 2) + pow(y, 2)) + pow(a, 2) * pow(z, 2))));
    */

    if (radical < 0)
    {
        return CoordGeodetic(0, 0, 0);
    }

    double d = (value - a * b * c * sqrt(radical)) / magnitude;

    if (d < 0)
    {
        return CoordGeodetic(0, 0, 0);
    }

    x += d * u;
    y += d * v;
    z += d * w;

    return vectorToLocation(Vector(x, y, z));
}

//Todo: More precise calculation maybe required, example: https://github.com/airbreather/Gavaghan.Geodesy/blob/master/Source/Gavaghan.Geodesy/GeodeticCalculator.cs
double PixelGeolocationCalculator::calculateBearingAngle(const CoordGeodetic &start, const CoordGeodetic &end)
{
    double alpha = end.longitude - start.longitude;
    double y = sin(alpha) * cos(end.latitude);
    double x = cos(start.latitude) * sin(end.latitude) - sin(start.latitude) * cos(end.latitude) * cos(alpha);
    double theta = atan2(y, x);

    return theta;
}

Matrix4x4 PixelGeolocationCalculator::lookAt(const Vector3 &position, const Vector3 &target, const Vector3 &up)
{
    Vector3 k = Vector3(target) - position;
    double m = k.DistanceSquared();
    if (m < std::numeric_limits<double>::epsilon())
    {
        return Matrix4x4();
    }
    k = k * (1.0 / sqrt(m));

    Vector3 i = up.Cross(k);
    i.Normalize();

    Vector3 j = k.Cross(i);
    j.Normalize();

    return Matrix4x4(
        i.x, j.x, k.x, 0.0,
        i.y, j.y, k.y, 0.0,
        i.z, j.z, k.z, 0.0,
        0.0, 0.0, 0.0, 1.0
    );
}
