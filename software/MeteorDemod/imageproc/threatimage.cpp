#include "threatimage.h"
#include <iostream>
#include "settings.h"

std::map<std::string, ThreatImage::WatermarkPosition> ThreatImage::WatermarkPositionLookup {
    {"top_left", WatermarkPosition::TOP_LEFT},
    {"top_center", WatermarkPosition::TOP_CENTER},
    {"top_right", WatermarkPosition::TOP_RIGHT},
    {"bottom_left", WatermarkPosition::BOTTOM_LEFT},
    {"bottom_center", WatermarkPosition::BOTTOM_CENTER},
    {"bottom_right", WatermarkPosition::BOTTOM_RIGHT},
};

void ThreatImage::fillBlackLines(cv::Mat &bitmap, int minimumHeight, int maximumHeight)
{
    int start = 0;
    int end;
    bool found = false;

    for (int x = 0; x < bitmap.size().width; x += SCAN_WIDTH)
    {
        for (int y = 0; y < bitmap.size().height; y++)
        {
            const cv::Vec3b &pixel = bitmap.at<cv::Vec3b>(y, x + 4);

            if (!found && (pixel[0] == 0 || pixel[1] == 0 || pixel[2] == 0))   //Check 4th one, first column on image is black
            {
                found = true;
                start = y;
            }

            if (found && pixel[0] != 0 && pixel[1] != 0 && pixel[2] != 0)   //Check 4th one, first column on image is black
            {
                found = false;
                end = y;
                if ((end - start) >= minimumHeight && (end - start) <= maximumHeight)
                {
                    int blankHeight = end - start;
                    if (start - ((blankHeight/2) + 1) > 0 && bitmap.size().height > (end + (blankHeight/2 + 1)))
                    {
                        fill(bitmap, x, start, end);
                    }
                }
            }
        }
    }
}

cv::Mat ThreatImage::irToTemperature(const cv::Mat &irImage, const cv::Mat ref)
{
    if(ref.cols != 256) {
        return cv::Mat();
    }

    cv::Mat thermalImage = cv::Mat::zeros(irImage.size(), irImage.type());

    for (int x = 0; x < irImage.cols; x++) {
        for (int y = 0; y < irImage.rows; y++) {
            uint8_t temp = irImage.at<cv::Vec3b>(y, x)[0];
            thermalImage.at<cv::Vec3b>(y, x) = ref.at<cv::Vec3b>(0,temp);
        }
    }
    return thermalImage;
}

cv::Mat ThreatImage::gamma(const cv::Mat &image, double gamma)
{
    cv::Mat newImage = image.clone();
    cv::Mat lookUpTable(1, 256, CV_8U);
    uchar* p = lookUpTable.ptr();

       for( int i = 0; i < 256; ++i) {
           p[i] = cv::saturate_cast<uchar>(std::pow(i / 255.0, gamma) * 255.0);
       }

       LUT(image, lookUpTable, newImage);

       return  newImage;
}

void ThreatImage::drawWatermark(cv::Mat image, const std::string &date)
{
    int x = 0;
    int y = 0;
    Settings &settings = Settings::getInstance();

    std::string watermarkText = settings.getWaterMarkText();

    WatermarkPosition position = TOP_CENTER;
    auto itr = WatermarkPositionLookup.find(settings.getWaterMarkPlace());
    if( itr != WatermarkPositionLookup.end()) {
        position = itr->second;
    }

    replaceAll(watermarkText, "%date%", date);
    replaceAll(watermarkText, "\\n", "\n");

    size_t lineCount = std::count(watermarkText.begin(), watermarkText.end(), '\n') + 1;

    int n = 1;
    std::string line;
    std::istringstream istream(watermarkText);
    while (getline(istream, line, '\n')) {
        int baseLine;
        cv::Size textSize = cv::getTextSize(line, cv::FONT_ITALIC, settings.getWaterMarkSize(), 10, &baseLine);
        int textHeight = baseLine + textSize.height;
        int margin = textSize.height;

        switch (position) {
        case TOP_LEFT:
            x = margin;
            y = n * (textHeight + baseLine);
            break;
        case TOP_CENTER:
            x = (image.size().width - textSize.width) / 2;
            y = n * (textHeight + baseLine);
            break;
        case TOP_RIGHT:
            x = image.size().width - textSize.width - margin;
            y = n * (textHeight + baseLine);
            break;
        case BOTTOM_LEFT:
            x = margin;
            y = image.size().height - (lineCount * (textHeight + baseLine)) + (n * (textHeight + baseLine)) - margin;
            break;
        case BOTTOM_CENTER:
            x = (image.size().width - textSize.width) / 2;
            y = image.size().height - (lineCount * (textHeight + baseLine)) + (n * (textHeight + baseLine)) - margin;
            break;
        case BOTTOM_RIGHT:
            x = image.size().width - textSize.width - textHeight - margin;
            y = image.size().height - (lineCount * (textHeight + baseLine)) + (n * (textHeight + baseLine)) - margin;
            break;
        }

        cv::putText(image, line, cv::Point2d(x, y), cv::FONT_HERSHEY_COMPLEX, settings.getWaterMarkSize(), cv::Scalar(0,0,0), 10+1, cv::LINE_AA);
        cv::putText(image, line, cv::Point2d(x, y), cv::FONT_HERSHEY_COMPLEX, settings.getWaterMarkSize(), cv::Scalar(settings.getWaterMarkColor().B, settings.getWaterMarkColor().G, settings.getWaterMarkColor().R), 10, cv::LINE_AA);

        n++;
    }
}

bool ThreatImage::isNightPass(const cv::Mat &image, float treshold)
{
    if(image.size().width > 0 && image.size().height > 0) {
        cv::Scalar result = cv::mean(image);

        if(result[0] < treshold && result[1] < treshold && result[2] < treshold) {
            std::cout << "Night pass mean calculation, CH1:" << result[0] << " CH2:" << result[1] << " CH3:" << result[2] << std::endl;
            return true;
        }
    }
    return false;
}

void ThreatImage::fill(cv::Mat &image, int x, int start, int end)
{
    int blankHeight = end - start;

    for (int i = 0; i < SCAN_WIDTH; i++)
    {
        for (int y = start, z = 0; z < (blankHeight / 2) + 1; y++, z++)
        {
            const cv::Vec3b &color1 = image.at<cv::Vec3b>(start - z - 1, x + i);
            const cv::Vec3b &color2 = image.at<cv::Vec3b>(end + z + 1, x + i);

            float alpha = static_cast<float>(z) / blankHeight;
            image.at<cv::Vec3b>(y, x + i) = blend(color2, color1, alpha);
            image.at<cv::Vec3b>(end - z, x + i) = blend(color1, color2, alpha);
        }
    }
}

cv::Vec3b ThreatImage::blend(const cv::Vec3b &color, const cv::Vec3b &backColor, float amount)
{
    uint8_t r = static_cast<uint8_t>((color[2] * amount) + backColor[2] * (1 - amount));
    uint8_t g = static_cast<uint8_t>((color[1] * amount) + backColor[1] * (1 - amount));
    uint8_t b = static_cast<uint8_t>((color[0] * amount) + backColor[0] * (1 - amount));
    return cv::Vec3b(b, g, r);
}

void ThreatImage::replaceAll(std::string &str, const std::string &from, const std::string &to)
{
    size_t start_pos = 0;
    while((start_pos = str.find(from, start_pos)) != std::string::npos) {
        str.replace(start_pos, from.length(), to);
        start_pos += to.length();
    }
}
