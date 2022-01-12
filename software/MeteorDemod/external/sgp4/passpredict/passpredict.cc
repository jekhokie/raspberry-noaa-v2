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


#include <Observer.h>
#include <SGP4.h>
#include <Util.h>
#include <CoordTopocentric.h>
#include <CoordGeodetic.h>

#include <cmath>
#include <iostream>
#include <list>

struct PassDetails
{
    DateTime aos;
    DateTime los;
    double max_elevation;
};

double FindMaxElevation(
        const CoordGeodetic& user_geo,
        SGP4& sgp4,
        const DateTime& aos,
        const DateTime& los)
{
    Observer obs(user_geo);

    bool running;

    double time_step = (los - aos).TotalSeconds() / 9.0;
    DateTime current_time(aos); //! current time
    DateTime time1(aos); //! start time of search period
    DateTime time2(los); //! end time of search period
    double max_elevation; //! max elevation

    running = true;

    do
    {
        running = true;
        max_elevation = -99999999999999.0;
        while (running && current_time < time2)
        {
            /*
             * find position
             */
            Eci eci = sgp4.FindPosition(current_time);
            CoordTopocentric topo = obs.GetLookAngle(eci);

            if (topo.elevation > max_elevation)
            {
                /*
                 * still going up
                 */
                max_elevation = topo.elevation;
                /*
                 * move time along
                 */
                current_time = current_time.AddSeconds(time_step);
                if (current_time > time2)
                {
                    /*
                     * dont go past end time
                     */
                    current_time = time2;
                }
            }
            else
            {
                /*
                 * stop
                 */
                running = false;
            }
        }

        /*
         * make start time to 2 time steps back
         */
        time1 = current_time.AddSeconds(-2.0 * time_step);
        /*
         * make end time to current time
         */
        time2 = current_time;
        /*
         * current time to start time
         */
        current_time = time1;
        /*
         * recalculate time step
         */
        time_step = (time2 - time1).TotalSeconds() / 9.0;
    }
    while (time_step > 1.0);

    return max_elevation;
}

DateTime FindCrossingPoint(
        const CoordGeodetic& user_geo,
        SGP4& sgp4,
        const DateTime& initial_time1,
        const DateTime& initial_time2,
        bool finding_aos)
{
    Observer obs(user_geo);

    bool running;
    int cnt;

    DateTime time1(initial_time1);
    DateTime time2(initial_time2);
    DateTime middle_time;

    running = true;
    cnt = 0;
    while (running && cnt++ < 16)
    {
        middle_time = time1.AddSeconds((time2 - time1).TotalSeconds() / 2.0);
        /*
         * calculate satellite position
         */
        Eci eci = sgp4.FindPosition(middle_time);
        CoordTopocentric topo = obs.GetLookAngle(eci);

        if (topo.elevation > 0.0)
        {
            /*
             * satellite above horizon
             */
            if (finding_aos)
            {
                time2 = middle_time;
            }
            else
            {
                time1 = middle_time;
            }
        }
        else
        {
            if (finding_aos)
            {
                time1 = middle_time;
            }
            else
            {
                time2 = middle_time;
            }
        }

        if ((time2 - time1).TotalSeconds() < 1.0)
        {
            /*
             * two times are within a second, stop
             */
            running = false;
            /*
             * remove microseconds
             */
            int us = middle_time.Microsecond();
            middle_time = middle_time.AddMicroseconds(-us);
            /*
             * step back into the pass by 1 second
             */
            middle_time = middle_time.AddSeconds(finding_aos ? 1 : -1);
        }
    }

    /*
     * go back/forward 1second until below the horizon
     */
    running = true;
    cnt = 0;
    while (running && cnt++ < 6)
    {
        Eci eci = sgp4.FindPosition(middle_time);
        CoordTopocentric topo = obs.GetLookAngle(eci);
        if (topo.elevation > 0)
        {
            middle_time = middle_time.AddSeconds(finding_aos ? -1 : 1);
        }
        else
        {
            running = false;
        }
    }

    return middle_time;
}

std::list<struct PassDetails> GeneratePassList(
        const CoordGeodetic& user_geo,
        SGP4& sgp4,
        const DateTime& start_time,
        const DateTime& end_time,
        const int time_step)
{
    std::list<struct PassDetails> pass_list;

    Observer obs(user_geo);

    DateTime aos_time;
    DateTime los_time;

    bool found_aos = false;

    DateTime previous_time(start_time);
    DateTime current_time(start_time);

    while (current_time < end_time)
    {
        bool end_of_pass = false;

        /*
         * calculate satellite position
         */
        Eci eci = sgp4.FindPosition(current_time);
        CoordTopocentric topo = obs.GetLookAngle(eci);

        if (!found_aos && topo.elevation > 0.0)
        {
            /*
             * aos hasnt occured yet, but the satellite is now above horizon
             * this must have occured within the last time_step
             */
            if (start_time == current_time)
            {
                /*
                 * satellite was already above the horizon at the start,
                 * so use the start time
                 */
                aos_time = start_time;
            }
            else
            {
                /*
                 * find the point at which the satellite crossed the horizon
                 */
                aos_time = FindCrossingPoint(
                        user_geo,
                        sgp4,
                        previous_time,
                        current_time,
                        true);
            }
            found_aos = true;
        }
        else if (found_aos && topo.elevation < 0.0)
        {
            found_aos = false;
            /*
             * end of pass, so move along more than time_step
             */
            end_of_pass = true;
            /*
             * already have the aos, but now the satellite is below the horizon,
             * so find the los
             */
            los_time = FindCrossingPoint(
                    user_geo,
                    sgp4,
                    previous_time,
                    current_time,
                    false);

            struct PassDetails pd;
            pd.aos = aos_time;
            pd.los = los_time;
            pd.max_elevation = FindMaxElevation(
                    user_geo,
                    sgp4,
                    aos_time,
                    los_time);

            pass_list.push_back(pd);
        }

        /*
         * save current time
         */
        previous_time = current_time;

        if (end_of_pass)
        {
            /*
             * at the end of the pass move the time along by 30mins
             */
            current_time = current_time + TimeSpan(0, 30, 0);
        }
        else
        {
            /*
             * move the time along by the time step value
             */
            current_time = current_time + TimeSpan(0, 0, time_step);
        }

        if (current_time > end_time)
        {
            /*
             * dont go past end time
             */
            current_time = end_time;
        }
    };

    if (found_aos)
    {
        /*
         * satellite still above horizon at end of search period, so use end
         * time as los
         */
        struct PassDetails pd;
        pd.aos = aos_time;
        pd.los = end_time;
        pd.max_elevation = FindMaxElevation(user_geo, sgp4, aos_time, end_time);
            
        pass_list.push_back(pd);
    }

    return pass_list;
}

int main()
{
    CoordGeodetic geo(51.507406923983446, -0.12773752212524414, 0.05);
    Tle tle("GALILEO-PFM (GSAT0101)  ",
        "1 37846U 11060A   12293.53312491  .00000049  00000-0  00000-0 0  1435",
        "2 37846  54.7963 119.5777 0000994 319.0618  40.9779  1.70474628  6204");
    SGP4 sgp4(tle);

    std::cout << tle << std::endl;

    /*
     * generate 7 day schedule
     */
    DateTime start_date = DateTime::Now(true);
    DateTime end_date(start_date.AddDays(7.0));

    std::list<struct PassDetails> pass_list;

    std::cout << "Start time: " << start_date << std::endl;
    std::cout << "End time  : " << end_date << std::endl << std::endl;

    /*
     * generate passes
     */
    pass_list = GeneratePassList(geo, sgp4, start_date, end_date, 180);

    if (pass_list.begin() == pass_list.end())
    {
        std::cout << "No passes found" << std::endl;
    }
    else
    {
        std::stringstream ss;

        ss << std::right << std::setprecision(1) << std::fixed;

        std::list<struct PassDetails>::const_iterator itr = pass_list.begin();
        do
        {
            ss  << "AOS: " << itr->aos
                << ", LOS: " << itr->los
                << ", Max El: " << std::setw(4) << Util::RadiansToDegrees(itr->max_elevation)
                << ", Duration: " << (itr->los - itr->aos)
                << std::endl;
        }
        while (++itr != pass_list.end());

        std::cout << ss.str();
    }

    return 0;
}
