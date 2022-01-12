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


#include "SGP4.h"

#include "Util.h"
#include "Vector.h"
#include "SatelliteException.h"
#include "DecayedException.h"

#include <cmath>
#include <iomanip>
#include <cstring>

void SGP4::SetTle(const Tle& tle)
{
    /*
     * extract and format tle data
     */
    elements_ = OrbitalElements(tle);

    Initialise();
}

void SGP4::Initialise()
{
    /*
     * reset all constants etc
     */
    Reset();

    /*
     * error checks
     */
    if (elements_.Eccentricity() < 0.0 || elements_.Eccentricity() > 0.999)
    {
        throw SatelliteException("Eccentricity out of range");
    }

    if (elements_.Inclination() < 0.0 || elements_.Inclination() > kPI)
    {
        throw SatelliteException("Inclination out of range");
    }

    RecomputeConstants(elements_.Inclination(),
                       common_consts_.sinio,
                       common_consts_.cosio,
                       common_consts_.x3thm1,
                       common_consts_.x1mth2,
                       common_consts_.x7thm1,
                       common_consts_.xlcof,
                       common_consts_.aycof);

    const double theta2 = common_consts_.cosio * common_consts_.cosio;
    const double eosq = elements_.Eccentricity() * elements_.Eccentricity();
    const double betao2 = 1.0 - eosq;
    const double betao = sqrt(betao2);

    if (elements_.Period() >= 225.0)
    {
        use_deep_space_ = true;
    }
    else
    {
        use_deep_space_ = false;
        use_simple_model_ = false;
        /*
         * for perigee less than 220 kilometers, the simple_model flag is set
         * and the equations are truncated to linear variation in sqrt a and
         * quadratic variation in mean anomly. also, the c3 term, the
         * delta omega term and the delta m term are dropped
         */
        if (elements_.Perigee() < 220.0)
        {
            use_simple_model_ = true;
        }
    }

    /*
     * for perigee below 156km, the values of
     * s4 and qoms2t are altered
     */
    double s4 = kS;
    double qoms24 = kQOMS2T;
    if (elements_.Perigee() < 156.0)
    {
        s4 = elements_.Perigee() - 78.0;
        if (elements_.Perigee() < 98.0) 
        {
            s4 = 20.0;
        }
        qoms24 = pow((120.0 - s4) * kAE / kXKMPER, 4.0);
        s4 = s4 / kXKMPER + kAE;
    }

    /*
     * generate constants
     */
    const double pinvsq = 1.0
        / (elements_.RecoveredSemiMajorAxis()
                * elements_.RecoveredSemiMajorAxis()
                * betao2 * betao2);
    const double tsi = 1.0 / (elements_.RecoveredSemiMajorAxis() - s4);
    common_consts_.eta = elements_.RecoveredSemiMajorAxis()
        * elements_.Eccentricity() * tsi;
    const double etasq = common_consts_.eta * common_consts_.eta;
    const double eeta = elements_.Eccentricity() * common_consts_.eta;
    const double psisq = fabs(1.0 - etasq);
    const double coef = qoms24 * pow(tsi, 4.0);
    const double coef1 = coef / pow(psisq, 3.5);
    const double c2 = coef1 * elements_.RecoveredMeanMotion()
        * (elements_.RecoveredSemiMajorAxis()
        * (1.0 + 1.5 * etasq + eeta * (4.0 + etasq))
        + 0.75 * kCK2 * tsi / psisq * common_consts_.x3thm1
        * (8.0 + 3.0 * etasq * (8.0 + etasq)));
    common_consts_.c1 = elements_.BStar() * c2;
    common_consts_.c4 = 2.0 * elements_.RecoveredMeanMotion()
        * coef1 * elements_.RecoveredSemiMajorAxis() * betao2
        * (common_consts_.eta * (2.0 + 0.5 * etasq) + elements_.Eccentricity()
        * (0.5 + 2.0 * etasq)
        - 2.0 * kCK2 * tsi / (elements_.RecoveredSemiMajorAxis() * psisq)
        * (-3.0 * common_consts_.x3thm1 * (1.0 - 2.0 * eeta + etasq
        * (1.5 - 0.5 * eeta))
        + 0.75 * common_consts_.x1mth2 * (2.0 * etasq - eeta *
            (1.0 + etasq)) * cos(2.0 * elements_.ArgumentPerigee())));
    const double theta4 = theta2 * theta2;
    const double temp1 = 3.0 * kCK2 * pinvsq * elements_.RecoveredMeanMotion();
    const double temp2 = temp1 * kCK2 * pinvsq;
    const double temp3 = 1.25 * kCK4 * pinvsq * pinvsq * elements_.RecoveredMeanMotion();
    common_consts_.xmdot = elements_.RecoveredMeanMotion() + 0.5 * temp1 * betao *
            common_consts_.x3thm1 + 0.0625 * temp2 * betao *
            (13.0 - 78.0 * theta2 + 137.0 * theta4);
    const double x1m5th = 1.0 - 5.0 * theta2;
    common_consts_.omgdot = -0.5 * temp1 * x1m5th +
            0.0625 * temp2 * (7.0 - 114.0 * theta2 + 395.0 * theta4) +
            temp3 * (3.0 - 36.0 * theta2 + 49.0 * theta4);
    const double xhdot1 = -temp1 * common_consts_.cosio;
    common_consts_.xnodot = xhdot1 + (0.5 * temp2 * (4.0 - 19.0 * theta2) + 2.0 * temp3 *
            (3.0 - 7.0 * theta2)) * common_consts_.cosio;
    common_consts_.xnodcf = 3.5 * betao2 * xhdot1 * common_consts_.c1;
    common_consts_.t2cof = 1.5 * common_consts_.c1;

    if (use_deep_space_)
    {
        deepspace_consts_.gsto = elements_.Epoch().ToGreenwichSiderealTime();

        DeepSpaceInitialise(eosq,
                            common_consts_.sinio,
                            common_consts_.cosio,
                            betao,
                            theta2,
                            betao2,
                            common_consts_.xmdot,
                            common_consts_.omgdot,
                            common_consts_.xnodot);
    }
    else
    {
        double c3 = 0.0;
        if (elements_.Eccentricity() > 1.0e-4)
        {
            c3 = coef * tsi * kA3OVK2 * elements_.RecoveredMeanMotion() * kAE *
                    common_consts_.sinio / elements_.Eccentricity();
        }

        nearspace_consts_.c5 = 2.0 * coef1 * elements_.RecoveredSemiMajorAxis() * betao2 * (1.0 + 2.75 *
                (etasq + eeta) + eeta * etasq);
        nearspace_consts_.omgcof = elements_.BStar() * c3 * cos(elements_.ArgumentPerigee());

        nearspace_consts_.xmcof = 0.0;
        if (elements_.Eccentricity() > 1.0e-4)
        {
            nearspace_consts_.xmcof = -kTWOTHIRD * coef * elements_.BStar() * kAE / eeta;
        }

        nearspace_consts_.delmo = pow(1.0 + common_consts_.eta * (cos(elements_.MeanAnomoly())), 3.0);
        nearspace_consts_.sinmo = sin(elements_.MeanAnomoly());

        if (!use_simple_model_)
        {
            const double c1sq = common_consts_.c1 * common_consts_.c1;
            nearspace_consts_.d2 = 4.0 * elements_.RecoveredSemiMajorAxis() * tsi * c1sq;
            const double temp = nearspace_consts_.d2 * tsi * common_consts_.c1 / 3.0;
            nearspace_consts_.d3 = (17.0 * elements_.RecoveredSemiMajorAxis() + s4) * temp;
            nearspace_consts_.d4 = 0.5 * temp * elements_.RecoveredSemiMajorAxis() *
                    tsi * (221.0 * elements_.RecoveredSemiMajorAxis() + 31.0 * s4) * common_consts_.c1;
            nearspace_consts_.t3cof = nearspace_consts_.d2 + 2.0 * c1sq;
            nearspace_consts_.t4cof = 0.25 * (3.0 * nearspace_consts_.d3 + common_consts_.c1 *
                    (12.0 * nearspace_consts_.d2 + 10.0 * c1sq));
            nearspace_consts_.t5cof = 0.2 * (3.0 * nearspace_consts_.d4 + 12.0 * common_consts_.c1 *
                    nearspace_consts_.d3 + 6.0 * nearspace_consts_.d2 * nearspace_consts_.d2 + 15.0 *
                    c1sq * (2.0 * nearspace_consts_.d2 + c1sq));
        }
    }
}

Eci SGP4::FindPosition(const DateTime& dt) const
{
    return FindPosition((dt - elements_.Epoch()).TotalMinutes());
}

Eci SGP4::FindPosition(double tsince) const
{
    if (use_deep_space_)
    {
        return FindPositionSDP4(tsince);
    }
    else
    {
        return FindPositionSGP4(tsince);
    }
}

Eci SGP4::FindPositionSDP4(double tsince) const
{
    /*
     * the final values
     */
    double e;
    double a;
    double omega;
    double xl;
    double xnode;
    double xinc;

    /*
     * update for secular gravity and atmospheric drag
     */
    double xmdf = elements_.MeanAnomoly()
        + common_consts_.xmdot * tsince;
    double omgadf = elements_.ArgumentPerigee()
        + common_consts_.omgdot * tsince;
    const double xnoddf = elements_.AscendingNode()
        + common_consts_.xnodot * tsince;

    const double tsq = tsince * tsince;
    xnode = xnoddf + common_consts_.xnodcf * tsq;
    double tempa = 1.0 - common_consts_.c1 * tsince;
    double tempe = elements_.BStar() * common_consts_.c4 * tsince;
    double templ = common_consts_.t2cof * tsq;

    double xn = elements_.RecoveredMeanMotion();
    double em = elements_.Eccentricity();
    xinc = elements_.Inclination();

    DeepSpaceSecular(tsince,
                     elements_,
                     common_consts_,
                     deepspace_consts_,
                     integrator_params_,
                     xmdf,
                     omgadf,
                     xnode,
                     em,
                     xinc,
                     xn);

    if (xn <= 0.0)
    {
        throw SatelliteException("Error: (xn <= 0.0)");
    }

    a = pow(kXKE / xn, kTWOTHIRD) * tempa * tempa;
    e = em - tempe;
    double xmam = xmdf + elements_.RecoveredMeanMotion() * templ;

    DeepSpacePeriodics(tsince,
                       deepspace_consts_,
                       e,
                       xinc,
                       omgadf,
                       xnode,
                       xmam);

    /*
     * keeping xinc positive important unless you need to display xinc
     * and dislike negative inclinations
     */
    if (xinc < 0.0)
    {
        xinc = -xinc;
        xnode += kPI;
        omgadf -= kPI;
    }

    xl = xmam + omgadf + xnode;
    omega = omgadf;

    /*
     * fix tolerance for error recognition
     */
    if (e <= -0.001)
    {
        throw SatelliteException("Error: (e <= -0.001)");
    }
    else if (e < 1.0e-6)
    {
        e = 1.0e-6;
    }
    else if (e > (1.0 - 1.0e-6))
    {
        e = 1.0 - 1.0e-6;
    }

    /*
     * re-compute the perturbed values
     */
    double perturbed_sinio;
    double perturbed_cosio;
    double perturbed_x3thm1;
    double perturbed_x1mth2;
    double perturbed_x7thm1;
    double perturbed_xlcof;
    double perturbed_aycof;
    RecomputeConstants(xinc,
                       perturbed_sinio,
                       perturbed_cosio,
                       perturbed_x3thm1,
                       perturbed_x1mth2,
                       perturbed_x7thm1,
                       perturbed_xlcof,
                       perturbed_aycof);

    /*
     * using calculated values, find position and velocity
     */
    return CalculateFinalPositionVelocity(elements_.Epoch().AddMinutes(tsince),
                                          e,
                                          a,
                                          omega,
                                          xl,
                                          xnode,
                                          xinc,
                                          perturbed_xlcof,
                                          perturbed_aycof,
                                          perturbed_x3thm1,
                                          perturbed_x1mth2,
                                          perturbed_x7thm1,
                                          perturbed_cosio,
                                          perturbed_sinio);
}

void SGP4::RecomputeConstants(const double xinc,
                              double& sinio,
                              double& cosio,
                              double& x3thm1,
                              double& x1mth2,
                              double& x7thm1,
                              double& xlcof,
                              double& aycof)
{
    sinio = sin(xinc);
    cosio = cos(xinc);

    const double theta2 = cosio * cosio;

    x3thm1 = 3.0 * theta2 - 1.0;
    x1mth2 = 1.0 - theta2;
    x7thm1 = 7.0 * theta2 - 1.0;

    if (fabs(cosio + 1.0) > 1.5e-12)
    {
        xlcof = 0.125 * kA3OVK2 * sinio * (3.0 + 5.0 * cosio) / (1.0 + cosio);
    }
    else
    {
        xlcof = 0.125 * kA3OVK2 * sinio * (3.0 + 5.0 * cosio) / 1.5e-12;
    }

    aycof = 0.25 * kA3OVK2 * sinio;
}

Eci SGP4::FindPositionSGP4(double tsince) const
{
    /*
     * the final values
     */
    double e;
    double a;
    double omega;
    double xl;
    double xnode;
    const double xinc = elements_.Inclination();

    /*
     * update for secular gravity and atmospheric drag
     */
    const double xmdf = elements_.MeanAnomoly()
        + common_consts_.xmdot * tsince;
    const double omgadf = elements_.ArgumentPerigee()
        + common_consts_.omgdot * tsince;
    const double xnoddf = elements_.AscendingNode()
        + common_consts_.xnodot * tsince;

    omega = omgadf;
    double xmp = xmdf;

    const double tsq = tsince * tsince;
    xnode = xnoddf + common_consts_.xnodcf * tsq;
    double tempa = 1.0 - common_consts_.c1 * tsince;
    double tempe = elements_.BStar() * common_consts_.c4 * tsince;
    double templ = common_consts_.t2cof * tsq;

    if (!use_simple_model_)
    {
        const double delomg = nearspace_consts_.omgcof * tsince;
        const double delm = nearspace_consts_.xmcof
            * (pow(1.0 + common_consts_.eta * cos(xmdf), 3.0)
                    - nearspace_consts_.delmo);
        const double temp = delomg + delm;

        xmp += temp;
        omega -= temp;

        const double tcube = tsq * tsince;
        const double tfour = tsince * tcube;

        tempa = tempa - nearspace_consts_.d2 * tsq - nearspace_consts_.d3
            * tcube - nearspace_consts_.d4 * tfour;
        tempe += elements_.BStar() * nearspace_consts_.c5
            * (sin(xmp) - nearspace_consts_.sinmo);
        templ += nearspace_consts_.t3cof * tcube + tfour
            * (nearspace_consts_.t4cof + tsince * nearspace_consts_.t5cof);
    }

    a = elements_.RecoveredSemiMajorAxis() * tempa * tempa;
    e = elements_.Eccentricity() - tempe;
    xl = xmp + omega + xnode + elements_.RecoveredMeanMotion() * templ;

    /*
     * fix tolerance for error recognition
     */
    if (e <= -0.001)
    {
        throw SatelliteException("Error: (e <= -0.001)");
    }
    else if (e < 1.0e-6)
    {
        e = 1.0e-6;
    }
    else if (e > (1.0 - 1.0e-6))
    {
        e = 1.0 - 1.0e-6;
    }

    /*
     * using calculated values, find position and velocity
     * we can pass in constants from Initialise() as these dont change
     */
    return CalculateFinalPositionVelocity(elements_.Epoch().AddMinutes(tsince),
                                          e,
                                          a,
                                          omega,
                                          xl,
                                          xnode,
                                          xinc,
                                          common_consts_.xlcof,
                                          common_consts_.aycof,
                                          common_consts_.x3thm1,
                                          common_consts_.x1mth2,
                                          common_consts_.x7thm1,
                                          common_consts_.cosio,
                                          common_consts_.sinio);
}

Eci SGP4::CalculateFinalPositionVelocity(
        const DateTime& dt,
        const double e,
        const double a,
        const double omega,
        const double xl,
        const double xnode,
        const double xinc,
        const double xlcof,
        const double aycof,
        const double x3thm1,
        const double x1mth2,
        const double x7thm1,
        const double cosio,
        const double sinio)
{
    const double beta2 = 1.0 - e * e;
    const double xn = kXKE / pow(a, 1.5);
    /*
     * long period periodics
     */
    const double axn = e * cos(omega);
    const double temp11 = 1.0 / (a * beta2);
    const double xll = temp11 * xlcof * axn;
    const double aynl = temp11 * aycof;
    const double xlt = xl + xll;
    const double ayn = e * sin(omega) + aynl;
    const double elsq = axn * axn + ayn * ayn;

    if (elsq >= 1.0)
    {
        throw SatelliteException("Error: (elsq >= 1.0)");
    }

    /*
     * solve keplers equation
     * - solve using Newton-Raphson root solving
     * - here capu is almost the mean anomoly
     * - initialise the eccentric anomaly term epw
     * - The fmod saves reduction of angle to +/-2pi in sin/cos() and prevents
     * convergence problems.
     */
    const double capu = fmod(xlt - xnode, kTWOPI);
    double epw = capu;

    double sinepw = 0.0;
    double cosepw = 0.0;
    double ecose = 0.0;
    double esine = 0.0;

    /*
     * sensibility check for N-R correction
     */
    const double max_newton_naphson = 1.25 * fabs(sqrt(elsq));

    bool kepler_running = true;

    for (int i = 0; i < 10 && kepler_running; i++)
    {
        sinepw = sin(epw);
        cosepw = cos(epw);
        ecose = axn * cosepw + ayn * sinepw;
        esine = axn * sinepw - ayn * cosepw;

        double f = capu - epw + esine;

        if (fabs(f) < 1.0e-12)
        {
            kepler_running = false;
        }
        else
        {
            /*
             * 1st order Newton-Raphson correction
             */
            const double fdot = 1.0 - ecose;
            double delta_epw = f / fdot;

            /*
             * 2nd order Newton-Raphson correction.
             * f / (fdot - 0.5 * d2f * f/fdot)
             */
            if (i == 0)
            {
                if (delta_epw > max_newton_naphson)
                {
                    delta_epw = max_newton_naphson;
                }
                else if (delta_epw < -max_newton_naphson)
                {
                    delta_epw = -max_newton_naphson;
                }
            }
            else
            {
                delta_epw = f / (fdot + 0.5 * esine * delta_epw);
            }

            /*
             * Newton-Raphson correction of -F/DF
             */
            epw += delta_epw;
        }
    }
    /*
     * short period preliminary quantities
     */
    const double temp21 = 1.0 - elsq;
    const double pl = a * temp21;

    if (pl < 0.0)
    {
        throw SatelliteException("Error: (pl < 0.0)");
    }

    const double r = a * (1.0 - ecose);
    const double temp31 = 1.0 / r;
    const double rdot = kXKE * sqrt(a) * esine * temp31;
    const double rfdot = kXKE * sqrt(pl) * temp31;
    const double temp32 = a * temp31;
    const double betal = sqrt(temp21);
    const double temp33 = 1.0 / (1.0 + betal);
    const double cosu = temp32 * (cosepw - axn + ayn * esine * temp33);
    const double sinu = temp32 * (sinepw - ayn - axn * esine * temp33);
    const double u = atan2(sinu, cosu);
    const double sin2u = 2.0 * sinu * cosu;
    const double cos2u = 2.0 * cosu * cosu - 1.0;

    /*
     * update for short periodics
     */
    const double temp41 = 1.0 / pl;
    const double temp42 = kCK2 * temp41;
    const double temp43 = temp42 * temp41;

    const double rk = r * (1.0 - 1.5 * temp43 * betal * x3thm1)
        + 0.5 * temp42 * x1mth2 * cos2u;
    const double uk = u - 0.25 * temp43 * x7thm1 * sin2u;
    const double xnodek = xnode + 1.5 * temp43 * cosio * sin2u;
    const double xinck = xinc + 1.5 * temp43 * cosio * sinio * cos2u;
    const double rdotk = rdot - xn * temp42 * x1mth2 * sin2u;
    const double rfdotk = rfdot + xn * temp42 * (x1mth2 * cos2u + 1.5 * x3thm1);

    /*
     * orientation vectors
     */
    const double sinuk = sin(uk);
    const double cosuk = cos(uk);
    const double sinik = sin(xinck);
    const double cosik = cos(xinck);
    const double sinnok = sin(xnodek);
    const double cosnok = cos(xnodek);
    const double xmx = -sinnok * cosik;
    const double xmy = cosnok * cosik;
    const double ux = xmx * sinuk + cosnok * cosuk;
    const double uy = xmy * sinuk + sinnok * cosuk;
    const double uz = sinik * sinuk;
    const double vx = xmx * cosuk - cosnok * sinuk;
    const double vy = xmy * cosuk - sinnok * sinuk;
    const double vz = sinik * cosuk;
    /*
     * position and velocity
     */
    const double x = rk * ux * kXKMPER;
    const double y = rk * uy * kXKMPER;
    const double z = rk * uz * kXKMPER;
    Vector position(x, y, z);
    const double xdot = (rdotk * ux + rfdotk * vx) * kXKMPER / 60.0;
    const double ydot = (rdotk * uy + rfdotk * vy) * kXKMPER / 60.0;
    const double zdot = (rdotk * uz + rfdotk * vz) * kXKMPER / 60.0;
    Vector velocity(xdot, ydot, zdot);

    if (rk < 1.0)
    {
        throw DecayedException(
                dt,
                position,
                velocity);
    }

    return Eci(dt, position, velocity);
}

static inline double EvaluateCubicPolynomial(
        const double x,
        const double constant,
        const double linear,
        const double squared,
        const double cubed)
{
    return constant + x * linear + x * x * squared + x * x * x * cubed;
}

void SGP4::DeepSpaceInitialise(
        const double eosq,
        const double sinio,
        const double cosio,
        const double betao,
        const double theta2,
        const double betao2,
        const double xmdot,
        const double omgdot,
        const double xnodot)
{
    double se = 0.0;
    double si = 0.0;
    double sl = 0.0;
    double sgh = 0.0;
    double shdq = 0.0;

    double bfact = 0.0;

    static const double ZNS = 1.19459E-5;
    static const double C1SS = 2.9864797E-6;
    static const double ZES = 0.01675;
    static const double ZNL = 1.5835218E-4;
    static const double C1L = 4.7968065E-7;
    static const double ZEL = 0.05490;
    static const double ZCOSIS = 0.91744867;
    static const double ZSINI = 0.39785416;
    static const double ZSINGS = -0.98088458;
    static const double ZCOSGS = 0.1945905;
    static const double Q22 = 1.7891679E-6;
    static const double Q31 = 2.1460748E-6;
    static const double Q33 = 2.2123015E-7;
    static const double ROOT22 = 1.7891679E-6;
    static const double ROOT32 = 3.7393792E-7;
    static const double ROOT44 = 7.3636953E-9;
    static const double ROOT52 = 1.1428639E-7;
    static const double ROOT54 = 2.1765803E-9;

    const double aqnv = 1.0 / elements_.RecoveredSemiMajorAxis();
    const double xpidot = omgdot + xnodot;
    const double sinq = sin(elements_.AscendingNode());
    const double cosq = cos(elements_.AscendingNode());
    const double sing = sin(elements_.ArgumentPerigee());
    const double cosg = cos(elements_.ArgumentPerigee());

    /*
     * initialize lunar / solar terms
     */
    const double jday = elements_.Epoch().ToJ2000();

    const double xnodce = Util::WrapTwoPI(4.5236020 - 9.2422029e-4 * jday);
    const double stem = sin(xnodce);
    const double ctem = cos(xnodce);
    const double zcosil = 0.91375164 - 0.03568096 * ctem;
    const double zsinil = sqrt(1.0 - zcosil * zcosil);
    const double zsinhl = 0.089683511 * stem / zsinil;
    const double zcoshl = sqrt(1.0 - zsinhl * zsinhl);
    const double c = 4.7199672 + 0.22997150 * jday;
    const double gam = 5.8351514 + 0.0019443680 * jday;
    deepspace_consts_.zmol = Util::WrapTwoPI(c - gam);
    double zx = 0.39785416 * stem / zsinil;
    double zy = zcoshl * ctem + 0.91744867 * zsinhl * stem;
    zx = atan2(zx, zy);
    zx = gam + zx - xnodce;

    const double zcosgl = cos(zx);
    const double zsingl = sin(zx);
    deepspace_consts_.zmos = Util::WrapTwoPI(6.2565837 + 0.017201977 * jday);

    /*
     * do solar terms
     */
    double zcosg = ZCOSGS;
    double zsing = ZSINGS;
    double zcosi = ZCOSIS;
    double zsini = ZSINI;
    double zcosh = cosq;
    double zsinh = sinq;
    double cc = C1SS;
    double zn = ZNS;
    double ze = ZES;
    const double xnoi = 1.0 / elements_.RecoveredMeanMotion();

    for (int cnt = 0; cnt < 2; cnt++)
    {
        /*
         * solar terms are done a second time after lunar terms are done
         */
        const double a1 = zcosg * zcosh + zsing * zcosi * zsinh;
        const double a3 = -zsing * zcosh + zcosg * zcosi * zsinh;
        const double a7 = -zcosg * zsinh + zsing * zcosi * zcosh;
        const double a8 = zsing * zsini;
        const double a9 = zsing * zsinh + zcosg * zcosi*zcosh;
        const double a10 = zcosg * zsini;
        const double a2 = cosio * a7 + sinio * a8;
        const double a4 = cosio * a9 + sinio * a10;
        const double a5 = -sinio * a7 + cosio * a8;
        const double a6 = -sinio * a9 + cosio * a10;
        const double x1 = a1 * cosg + a2 * sing;
        const double x2 = a3 * cosg + a4 * sing;
        const double x3 = -a1 * sing + a2 * cosg;
        const double x4 = -a3 * sing + a4 * cosg;
        const double x5 = a5 * sing;
        const double x6 = a6 * sing;
        const double x7 = a5 * cosg;
        const double x8 = a6 * cosg;
        const double z31 = 12.0 * x1 * x1 - 3. * x3 * x3;
        const double z32 = 24.0 * x1 * x2 - 6. * x3 * x4;
        const double z33 = 12.0 * x2 * x2 - 3. * x4 * x4;
        double z1 = 3.0 * (a1 * a1 + a2 * a2) + z31 * eosq;
        double z2 = 6.0 * (a1 * a3 + a2 * a4) + z32 * eosq;
        double z3 = 3.0 * (a3 * a3 + a4 * a4) + z33 * eosq;

        const double z11 = -6.0 * a1 * a5
            + eosq * (-24. * x1 * x7 - 6. * x3 * x5);
        const double z12 = -6.0 * (a1 * a6 + a3 * a5) 
            + eosq * (-24. * (x2 * x7 + x1 * x8) - 6. * (x3 * x6 + x4 * x5));
        const double z13 = -6.0 * a3 * a6
            + eosq * (-24. * x2 * x8 - 6. * x4 * x6);
        const double z21 = 6.0 * a2 * a5
            + eosq * (24. * x1 * x5 - 6. * x3 * x7);
        const double z22 = 6.0 * (a4 * a5 + a2 * a6)
            + eosq * (24. * (x2 * x5 + x1 * x6) - 6. * (x4 * x7 + x3 * x8));
        const double z23 = 6.0 * a4 * a6
            + eosq * (24. * x2 * x6 - 6. * x4 * x8);

        z1 = z1 + z1 + betao2 * z31;
        z2 = z2 + z2 + betao2 * z32;
        z3 = z3 + z3 + betao2 * z33;

        const double s3 = cc * xnoi;
        const double s2 = -0.5 * s3 / betao;
        const double s4 = s3 * betao;
        const double s1 = -15.0 * elements_.Eccentricity() * s4;
        const double s5 = x1 * x3 + x2 * x4;
        const double s6 = x2 * x3 + x1 * x4;
        const double s7 = x2 * x4 - x1 * x3;

        se = s1 * zn * s5;
        si = s2 * zn * (z11 + z13);
        sl = -zn * s3 * (z1 + z3 - 14.0 - 6.0 * eosq);
        sgh = s4 * zn * (z31 + z33 - 6.0);

        /*
         * replaced
         * sh = -zn * s2 * (z21 + z23
         * with
         * shdq = (-zn * s2 * (z21 + z23)) / sinio
         */
        if (elements_.Inclination() < 5.2359877e-2
                || elements_.Inclination() > kPI - 5.2359877e-2)
        {
            shdq = 0.0;
        }
        else
        {
            shdq = (-zn * s2 * (z21 + z23)) / sinio;
        }

        deepspace_consts_.ee2 = 2.0 * s1 * s6;
        deepspace_consts_.e3 = 2.0 * s1 * s7;
        deepspace_consts_.xi2 = 2.0 * s2 * z12;
        deepspace_consts_.xi3 = 2.0 * s2 * (z13 - z11);
        deepspace_consts_.xl2 = -2.0 * s3 * z2;
        deepspace_consts_.xl3 = -2.0 * s3 * (z3 - z1);
        deepspace_consts_.xl4 = -2.0 * s3 * (-21.0 - 9.0 * eosq) * ze;
        deepspace_consts_.xgh2 = 2.0 * s4 * z32;
        deepspace_consts_.xgh3 = 2.0 * s4 * (z33 - z31);
        deepspace_consts_.xgh4 = -18.0 * s4 * ze;
        deepspace_consts_.xh2 = -2.0 * s2 * z22;
        deepspace_consts_.xh3 = -2.0 * s2 * (z23 - z21);

        if (cnt == 1)
        {
            break;
        }
        /*
         * do lunar terms
         */
        deepspace_consts_.sse = se;
        deepspace_consts_.ssi = si;
        deepspace_consts_.ssl = sl;
        deepspace_consts_.ssh = shdq;
        deepspace_consts_.ssg = sgh - cosio * deepspace_consts_.ssh;
        deepspace_consts_.se2 = deepspace_consts_.ee2;
        deepspace_consts_.si2 = deepspace_consts_.xi2;
        deepspace_consts_.sl2 = deepspace_consts_.xl2;
        deepspace_consts_.sgh2 = deepspace_consts_.xgh2;
        deepspace_consts_.sh2 = deepspace_consts_.xh2;
        deepspace_consts_.se3 = deepspace_consts_.e3;
        deepspace_consts_.si3 = deepspace_consts_.xi3;
        deepspace_consts_.sl3 = deepspace_consts_.xl3;
        deepspace_consts_.sgh3 = deepspace_consts_.xgh3;
        deepspace_consts_.sh3 = deepspace_consts_.xh3;
        deepspace_consts_.sl4 = deepspace_consts_.xl4;
        deepspace_consts_.sgh4 = deepspace_consts_.xgh4;
        zcosg = zcosgl;
        zsing = zsingl;
        zcosi = zcosil;
        zsini = zsinil;
        zcosh = zcoshl * cosq + zsinhl * sinq;
        zsinh = sinq * zcoshl - cosq * zsinhl;
        zn = ZNL;
        cc = C1L;
        ze = ZEL;
    }

    deepspace_consts_.sse += se;
    deepspace_consts_.ssi += si;
    deepspace_consts_.ssl += sl;
    deepspace_consts_.ssg += sgh - cosio * shdq;
    deepspace_consts_.ssh += shdq;

    deepspace_consts_.shape = DeepSpaceConstants::NONE;

    if (elements_.RecoveredMeanMotion() < 0.0052359877
            && elements_.RecoveredMeanMotion() > 0.0034906585)
    {
        /*
         * 24h synchronous resonance terms initialisation
         */
        deepspace_consts_.shape = DeepSpaceConstants::SYNCHRONOUS;

        const double g200 = 1.0 + eosq * (-2.5 + 0.8125 * eosq);
        const double g310 = 1.0 + 2.0 * eosq;
        const double g300 = 1.0 + eosq * (-6.0 + 6.60937 * eosq);
        const double f220 = 0.75 * (1.0 + cosio) * (1.0 + cosio);
        const double f311 = 0.9375 * sinio * sinio * (1.0 + 3.0 * cosio)
            - 0.75 * (1.0 + cosio);
        double f330 = 1.0 + cosio;
        f330 = 1.875 * f330 * f330 * f330;
        deepspace_consts_.del1 = 3.0 * elements_.RecoveredMeanMotion()
            * elements_.RecoveredMeanMotion()
            * aqnv * aqnv;
        deepspace_consts_.del2 = 2.0 * deepspace_consts_.del1
            * f220 * g200 * Q22;
        deepspace_consts_.del3 = 3.0 * deepspace_consts_.del1
            * f330 * g300 * Q33 * aqnv;
        deepspace_consts_.del1 = deepspace_consts_.del1
            * f311 * g310 * Q31 * aqnv;

        deepspace_consts_.xlamo = Util::WrapTwoPI(elements_.MeanAnomoly()
                + elements_.AscendingNode()
                + elements_.ArgumentPerigee()
                - deepspace_consts_.gsto);
        bfact = xmdot + xpidot - kTHDT
            + deepspace_consts_.ssl
            + deepspace_consts_.ssg
            + deepspace_consts_.ssh;
    }
    else if (elements_.RecoveredMeanMotion() < 8.26e-3
            || elements_.RecoveredMeanMotion() > 9.24e-3
            || elements_.Eccentricity() < 0.5)
    {
        // do nothing
    }
    else
    {
        /*
         * geopotential resonance initialisation for 12 hour orbits
         */
        deepspace_consts_.shape = DeepSpaceConstants::RESONANCE;

        double g211;
        double g310;
        double g322;
        double g410;
        double g422;
        double g520;

        double g201 = -0.306 - (elements_.Eccentricity() - 0.64) * 0.440;

        if (elements_.Eccentricity() <= 0.65)
        {
            g211 = EvaluateCubicPolynomial(elements_.Eccentricity(),
                    3.616, -13.247, 16.290, 0.0);
            g310 = EvaluateCubicPolynomial(elements_.Eccentricity(),
                    -19.302, 117.390, -228.419, 156.591);
            g322 = EvaluateCubicPolynomial(elements_.Eccentricity(),
                    -18.9068, 109.7927, -214.6334, 146.5816);
            g410 = EvaluateCubicPolynomial(elements_.Eccentricity(),
                    -41.122, 242.694, -471.094, 313.953);
            g422 = EvaluateCubicPolynomial(elements_.Eccentricity(),
                    -146.407, 841.880, -1629.014, 1083.435);
            g520 = EvaluateCubicPolynomial(elements_.Eccentricity(),
                    -532.114, 3017.977, -5740.032, 3708.276);
        }
        else
        {
            g211 = EvaluateCubicPolynomial(elements_.Eccentricity(),
                    -72.099, 331.819, -508.738, 266.724);
            g310 = EvaluateCubicPolynomial(elements_.Eccentricity(),
                    -346.844, 1582.851, -2415.925, 1246.113);
            g322 = EvaluateCubicPolynomial(elements_.Eccentricity(),
                    -342.585, 1554.908, -2366.899, 1215.972);
            g410 = EvaluateCubicPolynomial(elements_.Eccentricity(),
                    -1052.797, 4758.686, -7193.992, 3651.957);
            g422 = EvaluateCubicPolynomial(elements_.Eccentricity(),
                    -3581.69, 16178.11, -24462.77, 12422.52);

            if (elements_.Eccentricity() <= 0.715)
            {
                g520 = EvaluateCubicPolynomial(elements_.Eccentricity(),
                        1464.74, -4664.75, 3763.64, 0.0);
            }
            else
            {
                g520 = EvaluateCubicPolynomial(elements_.Eccentricity(),
                        -5149.66, 29936.92, -54087.36, 31324.56);
            }
        }

        double g533;
        double g521;
        double g532;

        if (elements_.Eccentricity() < 0.7)
        {
            g533 = EvaluateCubicPolynomial(elements_.Eccentricity(),
                    -919.2277, 4988.61, -9064.77, 5542.21);
            g521 = EvaluateCubicPolynomial(elements_.Eccentricity(),
                    -822.71072, 4568.6173, -8491.4146, 5337.524);
            g532 = EvaluateCubicPolynomial(elements_.Eccentricity(),
                    -853.666, 4690.25, -8624.77, 5341.4);
        }
        else
        {
            g533 = EvaluateCubicPolynomial(elements_.Eccentricity(),
                    -37995.78, 161616.52, -229838.2, 109377.94);
            g521 = EvaluateCubicPolynomial(elements_.Eccentricity(),
                    -51752.104, 218913.95, -309468.16, 146349.42);
            g532 = EvaluateCubicPolynomial(elements_.Eccentricity(),
                    -40023.88, 170470.89, -242699.48, 115605.82);
        }

        const double sini2 = sinio * sinio;
        const double f220 = 0.75 * (1.0 + 2.0 * cosio + theta2);
        const double f221 = 1.5 * sini2;
        const double f321 = 1.875 * sinio * (1.0 - 2.0 * cosio - 3.0 * theta2);
        const double f322 = -1.875 * sinio * (1.0 + 2.0 * cosio - 3.0 * theta2);
        const double f441 = 35.0 * sini2 * f220;
        const double f442 = 39.3750 * sini2 * sini2;
        const double f522 = 9.84375 * sinio
            * (sini2 * (1.0 - 2.0 * cosio - 5.0 * theta2)
                + 0.33333333 * (-2.0 + 4.0 * cosio + 6.0 * theta2));
        const double f523 = sinio
            * (4.92187512 * sini2 * (-2.0 - 4.0 * cosio + 10.0 * theta2)
                + 6.56250012 * (1.0 + 2.0 * cosio - 3.0 * theta2));
        const double f542 = 29.53125 * sinio * (2.0 - 8.0 * cosio + theta2 *
                (-12.0 + 8.0 * cosio + 10.0 * theta2));
        const double f543 = 29.53125 * sinio * (-2.0 - 8.0 * cosio + theta2 *
                (12.0 + 8.0 * cosio - 10.0 * theta2));

        const double xno2 = elements_.RecoveredMeanMotion()
            * elements_.RecoveredMeanMotion();
        const double ainv2 = aqnv * aqnv;

        double temp1 = 3.0 * xno2 * ainv2;
        double temp = temp1 * ROOT22;
        deepspace_consts_.d2201 = temp * f220 * g201;
        deepspace_consts_.d2211 = temp * f221 * g211;

        temp1 *= aqnv;
        temp = temp1 * ROOT32;
        deepspace_consts_.d3210 = temp * f321 * g310;
        deepspace_consts_.d3222 = temp * f322 * g322;

        temp1 *= aqnv;
        temp = 2.0 * temp1 * ROOT44;
        deepspace_consts_.d4410 = temp * f441 * g410;
        deepspace_consts_.d4422 = temp * f442 * g422;

        temp1 *= aqnv;
        temp = temp1 * ROOT52;
        deepspace_consts_.d5220 = temp * f522 * g520;
        deepspace_consts_.d5232 = temp * f523 * g532;

        temp = 2.0 * temp1 * ROOT54;
        deepspace_consts_.d5421 = temp * f542 * g521;
        deepspace_consts_.d5433 = temp * f543 * g533;

        deepspace_consts_.xlamo = Util::WrapTwoPI(
                elements_.MeanAnomoly()
                + elements_.AscendingNode()
                + elements_.AscendingNode()
                - deepspace_consts_.gsto
                - deepspace_consts_.gsto);
        bfact = xmdot
            + xnodot + xnodot
            - kTHDT - kTHDT
            + deepspace_consts_.ssl
            + deepspace_consts_.ssh
            + deepspace_consts_.ssh;
    }

    if (deepspace_consts_.shape != DeepSpaceConstants::NONE)
    {
        /*
         * initialise integrator
         */
        deepspace_consts_.xfact = bfact - elements_.RecoveredMeanMotion();
        integrator_params_.atime = 0.0;
        integrator_params_.xni = elements_.RecoveredMeanMotion();
        integrator_params_.xli = deepspace_consts_.xlamo;
    }
}

/**
 * From DeepSpaceConstants, this uses:
 * zmos, se2, se3, si2, si3, sl2, sl3, sl4, sgh2, sgh3, sgh4, sh2, sh3
 * zmol, ee2,  e3, xi2, xi3, xl2, xl3, xl4, xgh2, xgh3, xgh4, xh2, xh3
 */
void SGP4::DeepSpacePeriodics(
        const double tsince,
        const DeepSpaceConstants& ds_constants,
        double& em,
        double& xinc,
        double& omgasm,
        double& xnodes,
        double& xll)
{
    static const double ZES = 0.01675;
    static const double ZNS = 1.19459E-5;
    static const double ZNL = 1.5835218E-4;
    static const double ZEL = 0.05490;

    // calculate solar terms for time tsince
    double zm = ds_constants.zmos + ZNS * tsince;
    double zf = zm + 2.0 * ZES * sin(zm);
    double sinzf = sin(zf);
    double f2 = 0.5 * sinzf * sinzf - 0.25;
    double f3 = -0.5 * sinzf * cos(zf);

    const double ses = ds_constants.se2 * f2
        + ds_constants.se3 * f3;
    const double sis = ds_constants.si2 * f2
        + ds_constants.si3 * f3;
    const double sls = ds_constants.sl2 * f2
        + ds_constants.sl3 * f3
        + ds_constants.sl4 * sinzf;
    const double sghs = ds_constants.sgh2 * f2
        + ds_constants.sgh3 * f3
        + ds_constants.sgh4 * sinzf;
    const double shs = ds_constants.sh2 * f2
        + ds_constants.sh3 * f3;

    // calculate lunar terms for time tsince
    zm = ds_constants.zmol + ZNL * tsince;
    zf = zm + 2.0 * ZEL * sin(zm);
    sinzf = sin(zf);
    f2 = 0.5 * sinzf * sinzf - 0.25;
    f3 = -0.5 * sinzf * cos(zf);

    const double sel = ds_constants.ee2 * f2
        + ds_constants.e3 * f3;
    const double sil = ds_constants.xi2 * f2
        + ds_constants.xi3 * f3;
    const double sll = ds_constants.xl2 * f2
        + ds_constants.xl3 * f3
        + ds_constants.xl4 * sinzf;
    const double sghl = ds_constants.xgh2 * f2
        + ds_constants.xgh3 * f3
        + ds_constants.xgh4 * sinzf;
    const double shl = ds_constants.xh2 * f2
        + ds_constants.xh3 * f3;

    // merge calculated values
    const double pe = ses + sel;
    const double pinc = sis + sil;
    const double pl = sls + sll;
    const double pgh = sghs + sghl;
    const double ph = shs + shl;

    xinc += pinc;
    em += pe;

    /* Spacetrack report #3 has sin/cos from before perturbations
     * added to xinc (oldxinc), but apparently report # 6 has then
     * from after they are added.
     * use for strn3
     * if (elements_.Inclination() >= 0.2)
     * use for gsfc
     * if (xinc >= 0.2)
     * (moved from start of function)
     */
    const double sinis = sin(xinc);
    const double cosis = cos(xinc);

    if (xinc >= 0.2)
    {
        // apply periodics directly
        omgasm += pgh - cosis * ph / sinis;
        xnodes += ph / sinis;
        xll += pl;
    }
    else
    {
        // apply periodics with lyddane modification
        const double sinok = sin(xnodes);
        const double cosok = cos(xnodes);
        double alfdp = sinis * sinok;
        double betdp = sinis * cosok;
        const double dalf = ph * cosok + pinc * cosis * sinok;
        const double dbet = -ph * sinok + pinc * cosis * cosok;
        alfdp += dalf;
        betdp += dbet;
        xnodes = Util::WrapTwoPI(xnodes);
        double xls = xll + omgasm + cosis * xnodes;
        double dls = pl + pgh - pinc * xnodes * sinis;
        xls += dls;
        const double oldxnodes = xnodes;
        xnodes = atan2(alfdp, betdp);
        /**
         * Get perturbed xnodes in to same quadrant as original.
         * RAAN is in the range of 0 to 360 degrees
         * atan2 is in the range of -180 to 180 degrees
         */
        if (fabs(oldxnodes - xnodes) > kPI)
        {
            if (xnodes < oldxnodes)
            {
                xnodes += kTWOPI;
            }
            else
            {
                xnodes -= kTWOPI;
            }
        }

        xll += pl;
        omgasm = xls - xll - cosis * xnodes;
    }
}

void SGP4::DeepSpaceSecular(
        const double tsince,
        const OrbitalElements& elements,
        const CommonConstants& c_constants,
        const DeepSpaceConstants& ds_constants,
        IntegratorParams& integ_params,
        double& xll,
        double& omgasm,
        double& xnodes,
        double& em,
        double& xinc,
        double& xn)
{
    static const double G22 = 5.7686396;
    static const double G32 = 0.95240898;
    static const double G44 = 1.8014998;
    static const double G52 = 1.0508330;
    static const double G54 = 4.4108898;
    static const double FASX2 = 0.13130908;
    static const double FASX4 = 2.8843198;
    static const double FASX6 = 0.37448087;

    static const double STEP = 720.0;
    static const double STEP2 = 259200.0;

    xll += ds_constants.ssl * tsince;
    omgasm += ds_constants.ssg * tsince;
    xnodes += ds_constants.ssh * tsince;
    em += ds_constants.sse * tsince;
    xinc += ds_constants.ssi * tsince;

    if (ds_constants.shape != DeepSpaceConstants::NONE)
    {
        double xndot = 0.0;
        double xnddt = 0.0;
        double xldot = 0.0;
        /*
         * 1st condition (if tsince is less than one time step from epoch)
         * 2nd condition (if atime and
         *     tsince are of opposite signs, so zero crossing required)
         * 3rd condition (if tsince is closer to zero than 
         *     atime, only integrate away from zero)
         */
        if (fabs(tsince) < STEP ||
            tsince * integ_params.atime <= 0.0 ||
            fabs(tsince) < fabs(integ_params.atime))
        {
            // restart back at the epoch
            integ_params.atime = 0.0;
            // TODO: check
            integ_params.xni = elements.RecoveredMeanMotion();
            // TODO: check
            integ_params.xli = ds_constants.xlamo;
        }

        bool running = true;
        while (running)
        {
            // always calculate dot terms ready for integration beginning
            // from the start of the range which is 'atime'
            if (ds_constants.shape == DeepSpaceConstants::SYNCHRONOUS)
            {
                xndot = ds_constants.del1 * sin(integ_params.xli - FASX2)
                    + ds_constants.del2 * sin(2.0 * (integ_params.xli - FASX4))
                    + ds_constants.del3 * sin(3.0 * (integ_params.xli - FASX6));
                xnddt = ds_constants.del1 * cos(integ_params.xli - FASX2)
                    + 2.0 * ds_constants.del2 * cos(2.0 * (integ_params.xli - FASX4))
                    + 3.0 * ds_constants.del3 * cos(3.0 * (integ_params.xli - FASX6));
            }
            else
            {
                // TODO: check
                const double xomi = elements.ArgumentPerigee() + c_constants.omgdot * integ_params.atime;
                const double x2omi = xomi + xomi;
                const double x2li = integ_params.xli + integ_params.xli;
                xndot = ds_constants.d2201 * sin(x2omi + integ_params.xli - G22)
                    + ds_constants.d2211 * sin(integ_params.xli - G22)
                    + ds_constants.d3210 * sin(xomi + integ_params.xli - G32)
                    + ds_constants.d3222 * sin(-xomi + integ_params.xli - G32)
                    + ds_constants.d4410 * sin(x2omi + x2li - G44)
                    + ds_constants.d4422 * sin(x2li - G44)
                    + ds_constants.d5220 * sin(xomi + integ_params.xli - G52)
                    + ds_constants.d5232 * sin(-xomi + integ_params.xli - G52)
                    + ds_constants.d5421 * sin(xomi + x2li - G54)
                    + ds_constants.d5433 * sin(-xomi + x2li - G54);
                xnddt = ds_constants.d2201 * cos(x2omi + integ_params.xli - G22)
                    + ds_constants.d2211 * cos(integ_params.xli - G22)
                    + ds_constants.d3210 * cos(xomi + integ_params.xli - G32)
                    + ds_constants.d3222 * cos(-xomi + integ_params.xli - G32)
                    + ds_constants.d5220 * cos(xomi + integ_params.xli - G52)
                    + ds_constants.d5232 * cos(-xomi + integ_params.xli - G52)
                    + 2.0 * (ds_constants.d4410 * cos(x2omi + x2li - G44)
                    + ds_constants.d4422 * cos(x2li - G44)
                    + ds_constants.d5421 * cos(xomi + x2li - G54)
                    + ds_constants.d5433 * cos(-xomi + x2li - G54));
            }
            xldot = integ_params.xni + ds_constants.xfact;
            xnddt *= xldot;

            double ft = tsince - integ_params.atime;
            if (fabs(ft) >= STEP)
            {
                const double delt = (ft >= 0.0 ? STEP : -STEP);
                // integrate by a full step ('delt'), updating the cached
                // values for the new 'atime'
                integ_params.xli = integ_params.xli + xldot * delt + xndot * STEP2;
                integ_params.xni = integ_params.xni + xndot * delt + xnddt * STEP2;
                integ_params.atime += delt;
            }
            else
            {
                // integrate by the difference 'ft' remaining
                xn = integ_params.xni + xndot * ft
                    + xnddt * ft * ft * 0.5;
                const double xl_temp = integ_params.xli + xldot * ft
                    + xndot * ft * ft * 0.5;

                const double theta = Util::WrapTwoPI(ds_constants.gsto + tsince * kTHDT);
                if (ds_constants.shape == DeepSpaceConstants::SYNCHRONOUS)
                {
                    xll = xl_temp + theta - xnodes - omgasm;
                }
                else
                {
                    xll = xl_temp + 2.0 * (theta - xnodes);
                }
                running = false;
            }
        }
    }
}

void SGP4::Reset()
{
    use_simple_model_ = false;
    use_deep_space_ = false;

    std::memset(&common_consts_, 0, sizeof(common_consts_));
    std::memset(&nearspace_consts_, 0, sizeof(nearspace_consts_));
    std::memset(&deepspace_consts_, 0, sizeof(deepspace_consts_));
    std::memset(&integrator_params_, 0, sizeof(integrator_params_));
}
