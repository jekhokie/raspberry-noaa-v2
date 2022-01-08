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


#ifndef TLE_H_
#define TLE_H_

#include "Util.h"
#include "DateTime.h"
#include "TleException.h"

/**
 * @brief Processes a two-line element set used to convey OrbitalElements.
 *
 * Used to extract the various raw fields from a two-line element set.
 */
class Tle
{
public:
    /**
     * @details Initialise given the two lines of a tle
     * @param[in] line_one Tle line one
     * @param[in] line_two Tle line two
     */
    Tle(const std::string& line_one,
            const std::string& line_two)
        : line_one_(line_one)
        , line_two_(line_two)
    {
        Initialize();
    }

    /**
     * @details Initialise given the satellite name and the two lines of a tle
     * @param[in] name Satellite name
     * @param[in] line_one Tle line one
     * @param[in] line_two Tle line two
     */
    Tle(const std::string& name,
            const std::string& line_one,
            const std::string& line_two)
        : name_(name)
        , line_one_(line_one)
        , line_two_(line_two)
    {
        Initialize();
    }

    /**
     * Copy constructor
     * @param[in] tle Tle object to copy from
     */
    Tle(const Tle& tle)
    {
        name_ = tle.name_;
        line_one_ = tle.line_one_;
        line_two_ = tle.line_two_;

        norad_number_ = tle.norad_number_;
        int_designator_ = tle.int_designator_;
        epoch_ = tle.epoch_;
        mean_motion_dt2_ = tle.mean_motion_dt2_;
        mean_motion_ddt6_ = tle.mean_motion_ddt6_;
        bstar_ = tle.bstar_;
        inclination_ = tle.inclination_;
        right_ascending_node_ = tle.right_ascending_node_;
        eccentricity_ = tle.eccentricity_;
        argument_perigee_ = tle.argument_perigee_;
        mean_anomaly_ = tle.mean_anomaly_;
        mean_motion_ = tle.mean_motion_;
        orbit_number_ = tle.orbit_number_;
    }

    /**
     * Get the satellite name
     * @returns the satellite name
     */
    std::string Name() const
    {
        return name_;
    }

    /**
     * Get the first line of the tle
     * @returns the first line of the tle
     */
    std::string Line1() const
    {
        return line_one_;
    }

    /**
     * Get the second line of the tle
     * @returns the second line of the tle
     */
    std::string Line2() const
    {
        return line_two_;
    }

    /**
     * Get the norad number
     * @returns the norad number
     */
    unsigned int NoradNumber() const
    {
        return norad_number_;
    }

    /**
     * Get the international designator
     * @returns the international designator
     */
    std::string IntDesignator() const
    {
        return int_designator_;
    }

    /**
     * Get the tle epoch
     * @returns the tle epoch
     */
    DateTime Epoch() const
    {
        return epoch_;
    }

    /**
     * Get the first time derivative of the mean motion divided by two
     * @returns the first time derivative of the mean motion divided by two
     */
    double MeanMotionDt2() const
    {
        return mean_motion_dt2_;
    }

    /**
     * Get the second time derivative of mean motion divided by six
     * @returns the second time derivative of mean motion divided by six
     */
    double MeanMotionDdt6() const
    {
        return mean_motion_ddt6_;
    }

    /**
     * Get the BSTAR drag term
     * @returns the BSTAR drag term
     */
    double BStar() const
    {
        return bstar_;
    }

    /**
     * Get the inclination
     * @param in_degrees Whether to return the value in degrees or radians
     * @returns the inclination
     */
    double Inclination(bool in_degrees) const
    {
        if (in_degrees)
        {
            return inclination_;
        }
        else
        {
            return Util::DegreesToRadians(inclination_);
        }
    }

    /**
     * Get the right ascension of the ascending node
     * @param in_degrees Whether to return the value in degrees or radians
     * @returns the right ascension of the ascending node
     */
    double RightAscendingNode(const bool in_degrees) const
    {
        if (in_degrees)
        {
            return right_ascending_node_;
        }
        else
        {
            return Util::DegreesToRadians(right_ascending_node_);
        }
    }

    /**
     * Get the eccentricity
     * @returns the eccentricity
     */
    double Eccentricity() const
    {
        return eccentricity_;
    }

    /**
     * Get the argument of perigee
     * @param in_degrees Whether to return the value in degrees or radians
     * @returns the argument of perigee
     */
    double ArgumentPerigee(const bool in_degrees) const
    {
        if (in_degrees)
        {
            return argument_perigee_;
        }
        else
        {
            return Util::DegreesToRadians(argument_perigee_);
        }
    }

    /**
     * Get the mean anomaly
     * @param in_degrees Whether to return the value in degrees or radians
     * @returns the mean anomaly
     */
    double MeanAnomaly(const bool in_degrees) const
    {
        if (in_degrees)
        {
            return mean_anomaly_;
        }
        else
        {
            return Util::DegreesToRadians(mean_anomaly_);
        }
    }

    /**
     * Get the mean motion
     * @returns the mean motion (revolutions per day)
     */
    double MeanMotion() const
    {
        return mean_motion_;
    }

    /**
     * Get the orbit number
     * @returns the orbit number
     */
    unsigned int OrbitNumber() const
    {
        return orbit_number_;
    }

    /**
     * Get the expected tle line length
     * @returns the tle line length
     */
    static unsigned int LineLength()
    {
        return TLE_LEN_LINE_DATA;
    }
    
    /**
     * Dump this object to a string
     * @returns string
     */
    std::string ToString() const
    {
        std::stringstream ss;
        ss << std::right << std::fixed;
        ss << "Norad Number:         " << NoradNumber() << std::endl;
        ss << "Int. Designator:      " << IntDesignator() << std::endl;
        ss << "Epoch:                " << Epoch() << std::endl;
        ss << "Orbit Number:         " << OrbitNumber() << std::endl;
        ss << std::setprecision(8);
        ss << "Mean Motion Dt2:      ";
        ss << std::setw(12) << MeanMotionDt2() << std::endl;
        ss << "Mean Motion Ddt6:     ";
        ss << std::setw(12) << MeanMotionDdt6() << std::endl;
        ss << "Eccentricity:         ";
        ss << std::setw(12) << Eccentricity() << std::endl;
        ss << "BStar:                ";
        ss << std::setw(12) << BStar() << std::endl;
        ss << "Inclination:          ";
        ss << std::setw(12) << Inclination(true) << std::endl;
        ss << "Right Ascending Node: ";
        ss << std::setw(12) << RightAscendingNode(true) << std::endl;
        ss << "Argument Perigee:     ";
        ss << std::setw(12) << ArgumentPerigee(true) << std::endl;
        ss << "Mean Anomaly:         ";
        ss << std::setw(12) << MeanAnomaly(true) << std::endl;
        ss << "Mean Motion:          ";
        ss << std::setw(12) << MeanMotion() << std::endl;
        return ss.str();
    }

private:
    void Initialize();
    static bool IsValidLineLength(const std::string& str);
    void ExtractInteger(const std::string& str, unsigned int& val);
    void ExtractDouble(const std::string& str, int point_pos, double& val);
    void ExtractExponential(const std::string& str, double& val);

private:
    std::string name_;
    std::string line_one_;
    std::string line_two_;

    std::string int_designator_;
    DateTime epoch_;
    double mean_motion_dt2_;
    double mean_motion_ddt6_;
    double bstar_;
    double inclination_;
    double right_ascending_node_;
    double eccentricity_;
    double argument_perigee_;
    double mean_anomaly_;
    double mean_motion_;
    unsigned int norad_number_;
    unsigned int orbit_number_;

    static const unsigned int TLE_LEN_LINE_DATA = 69;
    static const unsigned int TLE_LEN_LINE_NAME = 22;
};


inline std::ostream& operator<<(std::ostream& strm, const Tle& t)
{
    return strm << t.ToString();
}

#endif
