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


#ifndef ORBITALELEMENTS_H_
#define ORBITALELEMENTS_H_

#include "Util.h"
#include "DateTime.h"

class Tle;

/**
 * @brief The extracted orbital elements used by the SGP4 propagator.
 */
class OrbitalElements
{
public:
    OrbitalElements(const Tle& tle);

    /*
     * XMO
     */
    double MeanAnomoly() const
    {
        return mean_anomoly_;
    }

    /*
     * XNODEO
     */
    double AscendingNode() const
    {
        return ascending_node_;
    }

    /*
     * OMEGAO
     */
    double ArgumentPerigee() const
    {
        return argument_perigee_;
    }

    /*
     * EO
     */
    double Eccentricity() const
    {
        return eccentricity_;
    }

    /*
     * XINCL
     */
    double Inclination() const
    {
        return inclination_;
    }

    /*
     * XNO
     */
    double MeanMotion() const
    {
        return mean_motion_;
    }

    /*
     * BSTAR
     */
    double BStar() const
    {
        return bstar_;
    }

    /*
     * AODP
     */
    double RecoveredSemiMajorAxis() const
    {
        return recovered_semi_major_axis_;
    }

    /*
     * XNODP
     */
    double RecoveredMeanMotion() const
    {
        return recovered_mean_motion_;
    }

    /*
     * PERIGE
     */
    double Perigee() const
    {
        return perigee_;
    }

    /*
     * Period in minutes
     */
    double Period() const
    {
        return period_;
    }

    /*
     * EPOCH
     */
    DateTime Epoch() const
    {
        return epoch_;
    }

private:
    double mean_anomoly_;
    double ascending_node_;
    double argument_perigee_;
    double eccentricity_;
    double inclination_;
    double mean_motion_;
    double bstar_;
    double recovered_semi_major_axis_;
    double recovered_mean_motion_;
    double perigee_;
    double period_;
    DateTime epoch_;
};

#endif
