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


#include <CoordTopocentric.h>
#include <CoordGeodetic.h>
#include <Observer.h>
#include <SGP4.h>

#include <iostream>

int main()
{
    Observer obs(51.507406923983446, -0.12773752212524414, 0.05);
    Tle tle = Tle("UK-DMC 2                ",
        "1 35683U 09041C   12289.23158813  .00000484  00000-0  89219-4 0  5863",
        "2 35683  98.0221 185.3682 0001499 100.5295 259.6088 14.69819587172294");
    SGP4 sgp4(tle);

    std::cout << tle << std::endl;

    for (int i = 0; i < 10; ++i)
    {
        DateTime dt = tle.Epoch().AddMinutes(i * 10);
        /*
         * calculate satellite position
         */
        Eci eci = sgp4.FindPosition(dt);
        /*
         * get look angle for observer to satellite
         */
        CoordTopocentric topo = obs.GetLookAngle(eci);
        /*
         * convert satellite position to geodetic coordinates
         */
        CoordGeodetic geo = eci.ToGeodetic();

        std::cout << dt << " " << topo << " " << geo << std::endl;
    };

    return 0;
}
