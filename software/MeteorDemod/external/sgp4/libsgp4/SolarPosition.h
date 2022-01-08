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


#ifndef SOLARPOSITION_H_
#define SOLARPOSITION_H_

#include "DateTime.h"
#include "Eci.h"

/**
 * @brief Find the position of the sun
 */
class SolarPosition
{
public:
    SolarPosition()
    {
    }

    Eci FindPosition(const DateTime& dt);

private:
    double Delta_ET(double year) const;
};

#endif
