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


#include "DateTime.h"

#if 0

bool jd_dmy(int JD, int c_year, int c_month, int c_day)
{
    // For the Gregorian calendar:
    int a = JD + 32044;
    int b = (4 * a + 3) / 146097;
    int c = a - (b * 146097) / 4;

    //  Then, for both calendars:
    int d = (4 * c + 3) / 1461;
    int e = c - (1461 * d) / 4;
    int m = (5 * e + 2) / 153;

    int day   = e - (153 * m + 2) / 5 + 1;
    int month = m + 3 - 12 * (m / 10);
    int year  = b * 100 + d - 4800 + m / 10;

    if (c_year != year || c_month != month || c_day != day)
    {
        std::cout << year << " " << month << " " << day << std::endl;
        return false;
    }
    else
    {
        return true;
    }
}


int main()
{
    for (int year = 1; year <= 9999; year++)
    {
        for (int month = 1; month <= 12; month++)
        {
            for (int day = 1; day <= DateTime::DaysInMonth(year, month); day++)
            {
                int hour = 23;
                int minute = 59;
                int second = 59;
                int microsecond = 999999;

                DateTime dt(year, month, day, hour, minute, second, microsecond);

                if (dt.Year() != year ||
                        dt.Month() != month ||
                        dt.Day() != day ||
                        dt.Hour() != hour ||
                        dt.Minute() != minute ||
                        dt.Second() != second ||
                        dt.Microsecond() != microsecond)
                {
                    std::cout << "failed" << std::endl;
                    std::cout << "Y " << dt.Year() << " " << year << std::endl;
                    std::cout << "M " << dt.Month() << " " << month << std::endl;
                    std::cout << "D " << dt.Day() << " " << day << std::endl;
                    std::cout << "H " << dt.Hour() << " " << hour << std::endl;
                    std::cout << "M " << dt.Minute() << " " << minute << std::endl;
                    std::cout << "S " << dt.Second() << " " << second << std::endl;
                    std::cout << "F " << dt.Microsecond() << " " << microsecond << std::endl;
                    return 0;
                }
                
                if (!jd_dmy(dt.Julian() + 0.5, year, month, day))
                {
                    std::cout << "julian" << std::endl;
                    return 0;
                }
            }
        }
    }
    
    for (int hour = 1; hour < 24; hour++)
    {
        std::cout << hour << std::endl;
        for (int minute = 0; minute < 60; minute++)
        {
            for (int second = 0; second < 60; second++)
            {
                for (int microsecond = 0; microsecond < 1000000; microsecond += 10000)
                {
                    int year = 1000;
                    int month = 10;
                    int day = 23;

                    DateTime dt(year, month, day, hour, minute, second, microsecond);

                    if (dt.Year() != year ||
                            dt.Month() != month ||
                            dt.Day() != day ||
                            dt.Hour() != hour ||
                            dt.Minute() != minute ||
                            dt.Second() != second ||
                            dt.Microsecond() != microsecond)
                    {
                        std::cout << "failed" << std::endl;
                        std::cout << "Y " << dt.Year() << " " << year << std::endl;
                        std::cout << "M " << dt.Month() << " " << month << std::endl;
                        std::cout << "D " << dt.Day() << " " << day << std::endl;
                        std::cout << "H " << dt.Hour() << " " << hour << std::endl;
                        std::cout << "M " << dt.Minute() << " " << minute << std::endl;
                        std::cout << "S " << dt.Second() << " " << second << std::endl;
                        std::cout << "F " << dt.Microsecond() << " " << microsecond << std::endl;
                        return 0;
                    }
                }
            }
        }
    }
    
    jd_dmy(1721425.5, 0, 0, 0);

    DateTime d1(1000, 1, 1);
    DateTime d2(2000, 1, 1);
    DateTime d3(4000, 1, 1);
    DateTime d4(6000, 1, 1);
    DateTime d5(8000, 1, 1);

    std::cout << std::setprecision(20);
    std::cout << d1.Julian() << std::endl;
    std::cout << d2.Julian() << std::endl;
    std::cout << d3.Julian() << std::endl;
    std::cout << d4.Julian() << std::endl;
    std::cout << d5.Julian() << std::endl;
    
    return 0;
}

#endif
