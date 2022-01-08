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


#ifndef DATETIME_H_
#define DATETIME_H_

#include <iomanip>
#include <iostream>
#include <sstream>
#include <chrono>
#include <algorithm>
#include <cassert>
#include "TimeSpan.h"
#include "Util.h"

namespace
{
    static int daysInMonth[2][13] = {
        //  1   2   3   4   5   6   7   8   9   10  11  12
        {0, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31},
        {0, 31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31}
    };
    static int cumulDaysInMonth[2][13] = {
        //  1  2   3   4   5    6    7    8    9    10   11   12
        {0, 0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334},
        {0, 0, 31, 60, 91, 121, 152, 182, 213, 244, 274, 305, 335}
    };
}

/**
 * @brief Represents an instance in time.
 */
class DateTime
{
public:
    /**
     * Default contructor
     * Initialise to 0001/01/01 00:00:00.000000
     */
    DateTime()
    {
        Initialise(1, 1, 1, 0, 0, 0, 0);
    }

    /**
     * Constructor
     * @param[in] ticks raw tick value
     */
    DateTime(int64_t ticks)
        : m_encoded(ticks)
    {
    }

    /**
     * Constructor
     * @param[in] year the year
     * @param[in] doy the day of the year
     */
    DateTime(unsigned int year, double doy)
    {
        m_encoded = TimeSpan(
                static_cast<int64_t>(AbsoluteDays(year, doy) * TicksPerDay)).Ticks();
    }

    /**
     * Constructor
     * @param[in] year the year
     * @param[in] month the month
     * @param[in] day the day
     */
    DateTime(int year, int month, int day)
    {
        Initialise(year, month, day, 0, 0, 0, 0);
    }

    /**
     * Constructor
     * @param[in] year the year
     * @param[in] month the month
     * @param[in] day the day
     * @param[in] hour the hour
     * @param[in] minute the minute
     * @param[in] second the second
     */
    DateTime(int year, int month, int day, int hour, int minute, int second)
    {
        Initialise(year, month, day, hour, minute, second, 0);
    }

    /**
     * Constructor
     * @param[in] year the year
     * @param[in] month the month
     * @param[in] day the day
     * @param[in] hour the hour
     * @param[in] minute the minute
     * @param[in] second the second
     * @param[in] microsecond the microsecond
     */
    void Initialise(int year,
            int month,
            int day,
            int hour,
            int minute,
            int second,
            int microsecond)
    {
        if (!IsValidYearMonthDay(year, month, day) ||
                hour < 0 || hour > 23 ||
                minute < 0 || minute > 59 ||
                second < 0 || second > 59 ||
                microsecond < 0 || microsecond > 999999)
        {
            assert(false && "Invalid date");
        }
        m_encoded = TimeSpan(
                AbsoluteDays(year, month, day),
                hour,
                minute,
                second,
                microsecond).Ticks();
    }

    /**
     * Return the current time
     * @param[in] microseconds whether to set the microsecond component
     * @returns a DateTime object set to the current date and time
     */
    static DateTime Now(bool useMicroseconds = false)
    {
        using namespace std::chrono;
        if (useMicroseconds)
        {
            return DateTime(UnixEpoch +
                    duration_cast<microseconds>(system_clock::now()
                    .time_since_epoch()).count() * TicksPerMicrosecond);
        }
        else
        {
            return DateTime(UnixEpoch +
                duration_cast<seconds>(system_clock::now()
                    .time_since_epoch()).count() * TicksPerSecond);
        }
    }

    /**
     * Find whether a year is a leap year
     * @param[in] year the year to check
     * @returns whether the year is a leap year
     */
    static bool IsLeapYear(int year)
    {
        if (!IsValidYear(year))
        {
            assert(false && "Invalid year");
        }

        return (((year % 4) == 0 && (year % 100) != 0) || (year % 400) == 0);
    }

    /**
     * Checks whether the given year is valid
     * @param[in] year the year to check
     * @returns whether the year is valid
     */
    static bool IsValidYear(int year)
    {
        bool valid = true;
        if (year < 1 || year > 9999)
        {
            valid = false;
        }
        return valid;
    }

    /**
     * Check whether the year/month is valid
     * @param[in] year the year to check
     * @param[in] month the month to check
     * @returns whether the year/month is valid
     */
    static bool IsValidYearMonth(int year, int month)
    {
        bool valid = true;
        if (IsValidYear(year))
        {
            if (month < 1 || month > 12)
            {
                valid = false;
            }
        }
        else 
        {
            valid = false;
        }
        return valid;
    }
    
    /**
     * Check whether the year/month/day is valid
     * @param[in] year the year to check
     * @param[in] month the month to check
     * @param[in] day the day to check
     * @returns whether the year/month/day is valid
     */
    static bool IsValidYearMonthDay(int year, int month, int day)
    {
        bool valid = true;
        if (IsValidYearMonth(year, month))
        {
            if (day < 1 || day > DaysInMonth(year, month))
            {
                valid = false;
            }
        }
        else
        {
            valid = false;
        }
        return valid;
    }

    /**
     * Find the number of days in a month given the year/month
     * @param[in] year the year
     * @param[in] month the month
     * @returns the days in the given month
     */
    static int DaysInMonth(int year, int month)
    {
        if (!IsValidYearMonth(year, month))
        {
            assert(false && "Invalid year and month");
        }
        
        const int* daysInMonthPtr;

        if (IsLeapYear(year))
        {
            daysInMonthPtr = daysInMonth[1];
        }
        else
        {
            daysInMonthPtr = daysInMonth[0];
        }

        return daysInMonthPtr[month];
    }

    /**
     * Find the day of the year given the year/month/day
     * @param[in] year the year
     * @param[in] month the month
     * @param[in] day the day
     * @returns the day of the year
     */
    int DayOfYear(int year, int month, int day) const
    {
        if (!IsValidYearMonthDay(year, month, day))
        {
            assert(false && "Invalid year, month and day");
        }

        int daysThisYear = day;

        if (IsLeapYear(year))
        {
            daysThisYear += cumulDaysInMonth[1][month];
        }
        else
        {
            daysThisYear += cumulDaysInMonth[0][month];
        }

        return daysThisYear;
    }

    /**
     *
     */
    double AbsoluteDays(unsigned int year, double doy) const
    {
        int64_t previousYear = year - 1;

        /*
         * + days in previous years ignoring leap days
         * + Julian leap days before this year
         * - minus prior century years
         * + plus prior years divisible by 400 days
         */
        int64_t daysSoFar = 365 * previousYear
            + previousYear / 4LL
            - previousYear / 100LL
            + previousYear / 400LL;

        return static_cast<double>(daysSoFar) + doy - 1.0;
    }

    int AbsoluteDays(int year, int month, int day) const
    {
        int previousYear = year - 1;

        /*
         * days this year (0 - ...)
         * + days in previous years ignoring leap days
         * + Julian leap days before this year
         * - minus prior century years
         * + plus prior years divisible by 400 days
         */
        int result = DayOfYear(year, month, day) - 1
            + 365 * previousYear
            + previousYear / 4
            - previousYear / 100
            + previousYear / 400;

        return result;
    }

    TimeSpan TimeOfDay() const
    {
        return TimeSpan(Ticks() % TicksPerDay);
    }

    int DayOfWeek() const
    {
        /*
         * The fixed day 1 (January 1, 1 Gregorian) is Monday.
         * 0 Sunday
         * 1 Monday
         * 2 Tuesday
         * 3 Wednesday
         * 4 Thursday
         * 5 Friday
         * 6 Saturday
         */
        return static_cast<int>(((m_encoded / TicksPerDay) + 1LL) % 7LL);
    }

    bool Equals(const DateTime& dt) const
    {
        return (m_encoded == dt.m_encoded);
    }

    int Compare(const DateTime& dt) const
    {
        int ret = 0;

        if (m_encoded < dt.m_encoded)
        {
            return -1;
        }
        else if (m_encoded > dt.m_encoded)
        {
            return 1;
        }

        return ret;
    }

    DateTime AddYears(const int years) const
    {
        return AddMonths(years * 12);
    }

    DateTime AddMonths(const int months) const
    {
        int year;
        int month;
        int day;
        FromTicks(year, month, day);
        month += months % 12;
        year += months / 12;

        if (month < 1)
        {
            month += 12;
            --year;
        }
        else if (month > 12)
        {
            month -= 12;
            ++year;
        }

        int maxday = DaysInMonth(year, month);
        day = std::min(day, maxday);

        return DateTime(year, month, day).Add(TimeOfDay());
    }

    /**
     * Add a TimeSpan to this DateTime
     * @param[in] t the TimeSpan to add
     * @returns a DateTime which has the given TimeSpan added
     */
    DateTime Add(const TimeSpan& t) const
    {
        return AddTicks(t.Ticks());
    }

    DateTime AddDays(const double days) const
    {
        return AddMicroseconds(days * 86400000000.0);
    }

    DateTime AddHours(const double hours) const
    {
        return AddMicroseconds(hours * 3600000000.0);
    }

    DateTime AddMinutes(const double minutes) const
    {
        return AddMicroseconds(minutes * 60000000.0);
    }

    DateTime AddSeconds(const double seconds) const
    {
        return AddMicroseconds(seconds * 1000000.0);
    }

    DateTime AddMicroseconds(const double microseconds) const
    {
        int64_t ticks = static_cast<int64_t>(microseconds * TicksPerMicrosecond);
        return AddTicks(ticks);
    }

    DateTime AddTicks(int64_t ticks) const
    {
        return DateTime(m_encoded + ticks);
    }

    /**
     * Get the number of ticks
     * @returns the number of ticks
     */
    int64_t Ticks() const
    {
        return m_encoded;
    }

    void FromTicks(int& year, int& month, int& day) const
    {
        int totalDays = static_cast<int>(m_encoded / TicksPerDay);
        
        /*
         * number of 400 year cycles
         */
        int num400 = totalDays / 146097;
        totalDays -= num400 * 146097;
        /*
         * number of 100 year cycles
         */
        int num100 = totalDays / 36524;
        if (num100 == 4)
        {
            /*
             * last day of the last leap century
             */
            num100 = 3;
        }
        totalDays -= num100 * 36524;
        /*
         * number of 4 year cycles
         */
        int num4 = totalDays / 1461;
        totalDays -= num4 * 1461;
        /*
         * number of years
         */
        int num1 = totalDays / 365;
        if (num1 == 4)
        {
            /*
             * last day of the last leap olympiad
             */
            num1 = 3;
        }
        totalDays -= num1 * 365;

        /*
         * find year
         */
        year = (num400 * 400) + (num100 * 100) + (num4 * 4) + num1 + 1;
        
        /*
         * convert day of year to month/day
         */
        const int* daysInMonthPtr;
        if (IsLeapYear(year))
        {
            daysInMonthPtr = daysInMonth[1];
        }
        else
        {
            daysInMonthPtr = daysInMonth[0];
        }

        month = 1;
        while (totalDays >= daysInMonthPtr[month] && month <= 12)
        {
            totalDays -= daysInMonthPtr[month++];
        }

        day = totalDays + 1;
    }

    int Year() const
    {
        int year;
        int month;
        int day;
        FromTicks(year, month, day);
        return year;
    }

    int Month() const
    {
        int year;
        int month;
        int day;
        FromTicks(year, month, day);
        return month;
    }

    int Day() const
    {
        int year;
        int month;
        int day;
        FromTicks(year, month, day);
        return day;
    }

    /**
     * Hour component
     * @returns the hour component
     */
    int Hour() const
    {
        return static_cast<int>(m_encoded % TicksPerDay / TicksPerHour);
    }

    /**
     * Minute component
     * @returns the minute component
     */
    int Minute() const
    {
        return static_cast<int>(m_encoded % TicksPerHour / TicksPerMinute);
    }

    /**
     * Second component
     * @returns the Second component
     */
    int Second() const
    {
        return static_cast<int>(m_encoded % TicksPerMinute / TicksPerSecond);
    }

    /**
     * Microsecond component
     * @returns the microsecond component
     */
    int Microsecond() const
    {
        return static_cast<int>(m_encoded % TicksPerSecond / TicksPerMicrosecond);
    }

    /**
     * Convert to a julian date
     * @returns the julian date
     */
    double ToJulian() const
    {
        TimeSpan ts = TimeSpan(Ticks());
        return ts.TotalDays() + 1721425.5;
    }

    /**
     * Convert to greenwich sidereal time
     * @returns the greenwich sidereal time
     */
    double ToGreenwichSiderealTime() const
    {
        // julian date of previous midnight
        double jd0 = floor(ToJulian() + 0.5) - 0.5;
        // julian centuries since epoch
        double t   = (jd0 - 2451545.0) / 36525.0;
        double jdf = ToJulian() - jd0;

        double gt  = 24110.54841 + t * (8640184.812866 + t * (0.093104 - t * 6.2E-6));
        gt  += jdf * 1.00273790935 * 86400.0;

        // 360.0 / 86400.0 = 1.0 / 240.0
        return Util::WrapTwoPI(Util::DegreesToRadians(gt / 240.0));
    }

    /**
     * Return the modified julian date since the j2000 epoch
     * January 1, 2000, at 12:00 TT
     * @returns the modified julian date
     */
    double ToJ2000() const
    {
        return ToJulian() - 2415020.0;
    }

    /**
     * Convert to local mean sidereal time (GMST plus the observer's longitude)
     * @param[in] lon observers longitude
     * @returns the local mean sidereal time
     */
    double ToLocalMeanSiderealTime(const double lon) const
    {
        return Util::WrapTwoPI(ToGreenwichSiderealTime() + lon);
    }

    std::string ToString() const
    {
        std::stringstream ss;
        int year;
        int month;
        int day;
        FromTicks(year, month, day);
        ss << std::right << std::setfill('0');
        ss << std::setw(4) << year << "-";
        ss << std::setw(2) << month << "-";
        ss << std::setw(2) << day << " ";
        ss << std::setw(2) << Hour() << ":";
        ss << std::setw(2) << Minute() << ":";
        ss << std::setw(2) << Second() << ".";
        ss << std::setw(6) << Microsecond() << " UTC";
        return ss.str();
    }

private:
    int64_t m_encoded;
};

inline std::ostream& operator<<(std::ostream& strm, const DateTime& dt)
{
    return strm << dt.ToString();
}

inline DateTime operator+(const DateTime& dt, TimeSpan ts)
{
    return DateTime(dt.Ticks() + ts.Ticks());
}

inline DateTime operator-(const DateTime& dt, const TimeSpan& ts)
{
    return DateTime(dt.Ticks() - ts.Ticks());
}

inline TimeSpan operator-(const DateTime& dt1, const DateTime& dt2)
{
    return TimeSpan(dt1.Ticks() - dt2.Ticks());
}

inline bool operator==(const DateTime& dt1, const DateTime& dt2)
{
    return dt1.Equals(dt2);
}

inline bool operator>(const DateTime& dt1, const DateTime& dt2)
{
    return (dt1.Compare(dt2) > 0);
}

inline bool operator>=(const DateTime& dt1, const DateTime& dt2)
{
    return (dt1.Compare(dt2) >= 0);
}

inline bool operator!=(const DateTime& dt1, const DateTime& dt2)
{
    return !dt1.Equals(dt2);
}

inline bool operator<(const DateTime& dt1, const DateTime& dt2)
{
    return (dt1.Compare(dt2) < 0);
}

inline bool operator<=(const DateTime& dt1, const DateTime& dt2)
{
    return (dt1.Compare(dt2) <= 0);
}

#endif
