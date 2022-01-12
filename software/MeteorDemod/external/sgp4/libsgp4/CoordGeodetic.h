/*
 * Copyright 2013 Daniel Warner <contact@danrw.com>
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */


#ifndef COORDGEODETIC_H_
#define COORDGEODETIC_H_

#include "Util.h"

#include <string>
#include <sstream>
#include <iomanip>

/**
 * @brief Stores a geodetic location (latitude, longitude, altitude).
 *
 * Internally the values are stored in radians and kilometres.
 */
struct CoordGeodetic
{
public:
    /**
     * Default constructor
     */
    CoordGeodetic()
        : latitude(0.0),
        longitude(0.0),
        altitude(0.0)
    {
    }

    /**
     * Constructor
     * @param[in] lat the latitude (degrees by default)
     * @param[in] lon the longitude (degrees by default)
     * @param[in] alt the altitude in kilometers
     * @param[in] is_radians whether the latitude/longitude is in radians
     */
    CoordGeodetic(
            double lat,
            double lon,
            double alt,
            bool is_radians = false)
    {
        if (is_radians)
        {
            latitude = lat;
            longitude = lon;
        }
        else
        {
            latitude = Util::DegreesToRadians(lat);
            longitude = Util::DegreesToRadians(lon);
        }
        altitude = alt;
    }

    /**
     * Copy constructor
     * @param[in] geo object to copy from
     */
    CoordGeodetic(const CoordGeodetic& geo)
    {
        latitude = geo.latitude;
        longitude = geo.longitude;
        altitude = geo.altitude;
    }

    /**
     * Assignment operator
     * @param[in] geo object to copy from
     */
    CoordGeodetic& operator=(const CoordGeodetic& geo)
    {
        if (this != &geo)
        {
            latitude = geo.latitude;
            longitude = geo.longitude;
            altitude = geo.altitude;
        }
        return *this;
    }

    /**
     * Dump this object to a string
     * @returns string
     */
    std::string ToString() const
    {
        std::stringstream ss;
        ss << std::right << std::fixed << std::setprecision(3);
        ss << "Lat: " << std::setw(8) << Util::RadiansToDegrees(latitude);
        ss << ", Lon: " << std::setw(8) << Util::RadiansToDegrees(longitude);
        ss << ", Alt: " << std::setw(10) << altitude;
        return ss.str();
    }

    /** latitude in radians (-PI >= latitude < PI) */
    double latitude;
    /** latitude in radians (-PI/2 >= latitude <= PI/2) */
    double longitude;
    /** altitude in kilometers */
    double altitude;
};

/**
 * Dump a Coordgeodetic to a stream
 * @param[in,out] strm stream to output to
 * @param[in] g the CoordGeodetic to print
 */
inline std::ostream& operator<<(std::ostream& strm, const CoordGeodetic& g)
{
    return strm << g.ToString();
}

#endif
