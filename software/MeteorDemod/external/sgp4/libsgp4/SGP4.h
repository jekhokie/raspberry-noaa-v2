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


#ifndef SGP4_H_
#define SGP4_H_

#include "Tle.h"
#include "OrbitalElements.h"
#include "Eci.h"
#include "SatelliteException.h"
#include "DecayedException.h"

/**
 * @mainpage
 *
 * This documents the SGP4 tracking library.
 */

/**
 * @brief The simplified perturbations model 4 propagater.
 */
class SGP4
{
public:
    SGP4(const Tle& tle)
        : elements_(tle)
    {
        Initialise();
    }

    void SetTle(const Tle& tle);
    Eci FindPosition(double tsince) const;
    Eci FindPosition(const DateTime& date) const;

private:
    struct CommonConstants
    {
        double cosio;
        double sinio;
        double eta;
        double t2cof;
        double x1mth2;
        double x3thm1;
        double x7thm1;
        double aycof;
        double xlcof;
        double xnodcf;
        double c1;
        double c4;
        double omgdot; // secular rate of omega (radians/sec)
        double xnodot; // secular rate of xnode (radians/sec)
        double xmdot;  // secular rate of xmo   (radians/sec)
    };

    struct NearSpaceConstants
    {
        double c5;
        double omgcof;
        double xmcof;
        double delmo;
        double sinmo;
        double d2;
        double d3;
        double d4;
        double t3cof;
        double t4cof;
        double t5cof;
    };

    struct DeepSpaceConstants
    {
        double gsto;
        double zmol;
        double zmos;

        /*
         * lunar / solar constants for epoch
         * applied during DeepSpaceSecular()
         */
        double sse;
        double ssi;
        double ssl;
        double ssg;
        double ssh;
        /*
         * lunar / solar constants
         * used during DeepSpaceCalculateLunarSolarTerms()
         */
        double se2;
        double si2;
        double sl2;
        double sgh2;
        double sh2;
        double se3;
        double si3;
        double sl3;
        double sgh3;
        double sh3;
        double sl4;
        double sgh4;
        double ee2;
        double e3;
        double xi2;
        double xi3;
        double xl2;
        double xl3;
        double xl4;
        double xgh2;
        double xgh3;
        double xgh4;
        double xh2;
        double xh3;
        /*
         * used during DeepSpaceCalcDotTerms()
         */
        double d2201;
        double d2211;
        double d3210;
        double d3222;
        double d4410;
        double d4422;
        double d5220;
        double d5232;
        double d5421;
        double d5433;
        double del1;
        double del2;
        double del3;
        /*
         * integrator constants
         */
        double xfact;
        double xlamo;

        enum TOrbitShape
        {
            NONE,
            RESONANCE,
            SYNCHRONOUS
        } shape;
    };

    struct IntegratorParams
    {
        /*
         * integrator values
         */
        double xli;
        double xni;
        double atime;
    };
    
    void Initialise();
    static void RecomputeConstants(const double xinc,
                                   double& sinio,
                                   double& cosio,
                                   double& x3thm1,
                                   double& x1mth2,
                                   double& x7thm1,
                                   double& xlcof,
                                   double& aycof);
    Eci FindPositionSDP4(const double tsince) const;
    Eci FindPositionSGP4(double tsince) const;
    static Eci CalculateFinalPositionVelocity(
            const DateTime& date,
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
            const double sinio);
    /**
     * Deep space initialisation
     */
    void DeepSpaceInitialise(
            const double eosq,
            const double sinio,
            const double cosio,
            const double betao,
            const double theta2,
            const double betao2,
            const double xmdot,
            const double omgdot,
            const double xnodot);
    /**
     * Calculate lunar / solar periodics and apply
     */
    static void DeepSpacePeriodics(
            const double tsince,
            const DeepSpaceConstants& ds_constants,
            double& em,
            double& xinc,
            double& omgasm,
            double& xnodes,
            double& xll);
    /**
     * Deep space secular effects
     */
    static void DeepSpaceSecular(
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
            double& xn);

    /**
     * Reset
     */
    void Reset();

    /*
     * the constants used
     */
    struct CommonConstants common_consts_;
    struct NearSpaceConstants nearspace_consts_;
    struct DeepSpaceConstants deepspace_consts_;
    mutable struct IntegratorParams integrator_params_;

    /*
     * the orbit data
     */
    OrbitalElements elements_;

    /*
     * flags
     */
    bool use_simple_model_;
    bool use_deep_space_;
};

#endif
