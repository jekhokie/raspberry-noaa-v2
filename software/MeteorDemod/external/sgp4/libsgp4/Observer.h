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


#ifndef OBSERVER_H_
#define OBSERVER_H_

#include "CoordGeodetic.h"
#include "Eci.h"

class DateTime;
struct CoordTopocentric;

/**
 * @brief Stores an observers location in Eci coordinates.
 */
class Observer
{
public:
    /**
     * Constructor
     * @param[in] latitude observers latitude in degrees
     * @param[in] longitude observers longitude in degrees
     * @param[in] altitude observers altitude in kilometers
     */
    Observer(const double latitude,
            const double longitude,
            const double altitude)
        : m_geo(latitude, longitude, altitude)
        , m_eci(DateTime(), m_geo)
    {
    }

    /**
     * Constructor
     * @param[in] geo the observers position
     */
    Observer(const CoordGeodetic &geo)
        : m_geo(geo)
        , m_eci(DateTime(), geo)
    {
    }

    /**
     * Set the observers location
     * @param[in] geo the observers position
     */
    void SetLocation(const CoordGeodetic& geo)
    {
        m_geo = geo;
        m_eci.Update(m_eci.GetDateTime(), m_geo);
    }

    /**
     * Get the observers location
     * @returns the observers position
     */
    CoordGeodetic GetLocation() const
    {
        return m_geo;
    }

    /**
     * Get the look angle for the observers position to the object
     * @param[in] eci the object to find the look angle to
     * @returns the lookup angle
     */
    CoordTopocentric GetLookAngle(const Eci &eci);

private:
    /**
     * @param[in] dt the date to update the observers position for
     */
    void Update(const DateTime &dt)
    {
        if (m_eci != dt)
        {
            m_eci.Update(dt, m_geo);
        }
    }

    /** the observers position */
    CoordGeodetic m_geo;
    /** the observers Eci for a particular time */
    Eci m_eci;
};

#endif

