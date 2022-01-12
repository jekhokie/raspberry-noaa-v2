#ifndef SPREADIMAGE_H
#define SPREADIMAGE_H

#include <functional>
#include <map>
#include <opencv2/core.hpp>
#include <opencv2/imgproc.hpp>
#include "pixelgeolocationcalculator.h"

class SpreadImage
{
public:
    typedef std::function<void(float)> ProgressCallback;

public:
    explicit SpreadImage(int earthRadius = 6378, int altitude = 825);
    cv::Mat stretch(const cv::Mat &image);

    cv::Mat mercatorProjection(const cv::Mat &image, const PixelGeolocationCalculator &geolocationCalculator, ProgressCallback progressCallback = nullptr);
    cv::Mat equidistantProjection(const cv::Mat &image, const PixelGeolocationCalculator &geolocationCalculator, ProgressCallback progressCallback = nullptr);

    cv::MarkerTypes stringToMarkerType(const std::string &markerType);

private:
    void affineTransform(const cv::Mat& src, cv::Mat& dst, const cv::Point2f source[], const cv::Point2f destination[], int originX, int originY);
    void projectiveTransform(const cv::Mat& src, cv::Mat& dst, const cv::Mat &transform);

private:
    int mEarthRadius;
    int mAltitude;                         // Meteor MN2 orbit altitude
    double mTheta;
    double mPhi;
    int mInc;
    int mHalfChord;
    int mLookUp[20000];
    double mScanAngle;
    static std::map<std::string, cv::MarkerTypes> MarkerLookup;

    static constexpr int SWATH = 2800;     // Meteor M2M swath width
};

#endif // SPREADIMAGE_H
