#ifndef MATRIX4X4_H
#define MATRIX4X4_H

#include <array>
#include <cmath>
#include <algorithm>

struct Matrix4x4
{
    Matrix4x4() {
        std::fill(mElements.begin(), mElements.end(), 0);
        mElements[0] = 1;
        mElements[5] = 1;
        mElements[10] = 1;
        mElements[15] = 1;
    }

    Matrix4x4(double m11, double m12, double m13, double m14, double m21, double m22, double m23, double m24, double m31, double m32, double m33, double m34, double m41, double m42, double m43, double m44)
        : mElements({m11, m12, m13, m14,
                  m21, m22, m23, m24,
                  m31, m32, m33, m34,
                  m41, m42, m43, m44}) {

    }

    Matrix4x4(const Matrix4x4 &m)
        : mElements(m.mElements) {
    }

    static Matrix4x4 CreateRotationX(double angle) {
        Matrix4x4 matrix = Matrix4x4();
        matrix.mElements[5] = std::cos(-angle);
        matrix.mElements[6] = -std::sin(-angle);
        matrix.mElements[9] = std::sin(-angle);
        matrix.mElements[10] = std::cos(-angle);
        return matrix;
    }

    static Matrix4x4 CreateRotationY(double angle) {
        Matrix4x4 matrix = Matrix4x4();
        matrix.mElements[0] = std::cos(-angle);
        matrix.mElements[2] = std::sin(-angle);
        matrix.mElements[8] = -std::sin(-angle);
        matrix.mElements[10] = std::cos(-angle);
        return matrix;
    }

    static Matrix4x4 CreateRotationZ(double angle) {
        Matrix4x4 matrix = Matrix4x4();
        matrix.mElements[0] = std::cos(-angle);
        matrix.mElements[1] = -std::sin(-angle);
        matrix.mElements[4] = std::sin(-angle);
        matrix.mElements[5] = std::cos(-angle);
        return matrix;
    }

    Matrix4x4& operator+=(const Matrix4x4& rhs)
    {
        for(unsigned int i = 0; i < 16; i++)
        {
            mElements[i] += rhs.mElements[i];
        }
        return *this;
    }

    Matrix4x4& operator-=(const Matrix4x4& rhs)
    {
        for(unsigned int i = 0; i < 16; i++)
        {
            mElements[i] -= rhs.mElements[i];
        }
        return *this;
    }

    Matrix4x4& operator*=(const Matrix4x4& rhs)
    {
        Matrix4x4 newMatrix;
        double temp_0= mElements[0] * rhs.mElements[0] + mElements[1] * rhs.mElements[4] + mElements[2] * rhs.mElements[8] + mElements[3] * rhs.mElements[12];
        double temp_1= mElements[0] * rhs.mElements[1] + mElements[1] * rhs.mElements[5] + mElements[2] * rhs.mElements[9] + mElements[3] * rhs.mElements[13];
        double temp_2= mElements[0] * rhs.mElements[2] + mElements[1] * rhs.mElements[6] + mElements[2] * rhs.mElements[10] + mElements[3] * rhs.mElements[14];
        double temp_3= mElements[0] * rhs.mElements[3] + mElements[1] * rhs.mElements[7] + mElements[2] * rhs.mElements[11] + mElements[3] * rhs.mElements[15];

        double temp_4= mElements[4] * rhs.mElements[0] + mElements[5] * rhs.mElements[4] + mElements[6] * rhs.mElements[8] + mElements[7] * rhs.mElements[12];
        double temp_5= mElements[4] * rhs.mElements[1] + mElements[5] * rhs.mElements[5] + mElements[6] * rhs.mElements[9] + mElements[7] * rhs.mElements[13];
        double temp_6= mElements[4] * rhs.mElements[2] + mElements[5] * rhs.mElements[6] + mElements[6] * rhs.mElements[10] + mElements[7] * rhs.mElements[14];
        double temp_7= mElements[4] * rhs.mElements[3] + mElements[5] * rhs.mElements[7] + mElements[6] * rhs.mElements[11] + mElements[7] * rhs.mElements[15];

        double temp_8= mElements[8] * rhs.mElements[0] + mElements[9] * rhs.mElements[4] + mElements[10] * rhs.mElements[8] + mElements[11] * rhs.mElements[12];
        double temp_9= mElements[8] * rhs.mElements[1] + mElements[9] * rhs.mElements[5] + mElements[10] * rhs.mElements[9] + mElements[11] * rhs.mElements[13];
        double temp_10 = mElements[8] * rhs.mElements[2] + mElements[9] * rhs.mElements[6] + mElements[10] * rhs.mElements[10] + mElements[11] * rhs.mElements[14];
        double temp_11 = mElements[8] * rhs.mElements[3] + mElements[9] * rhs.mElements[7] + mElements[10] * rhs.mElements[11] + mElements[11] * rhs.mElements[15];

        double temp_12 = mElements[12] * rhs.mElements[0] + mElements[13] * rhs.mElements[4] + mElements[14] * rhs.mElements[8] + mElements[15] * rhs.mElements[12];
        double temp_13 = mElements[12] * rhs.mElements[1] + mElements[13] * rhs.mElements[5] + mElements[14] * rhs.mElements[9] + mElements[15] * rhs.mElements[13];
        double temp_14 = mElements[12] * rhs.mElements[2] + mElements[13] * rhs.mElements[6] + mElements[14] * rhs.mElements[10] + mElements[15] * rhs.mElements[14];
        double temp_15 = mElements[12] * rhs.mElements[3] + mElements[13] * rhs.mElements[7] + mElements[14] * rhs.mElements[11] + mElements[15] * rhs.mElements[15];


        mElements[0] =  temp_0;
        mElements[1] =  temp_1;
        mElements[2] =  temp_2;
        mElements[3] =  temp_3;

        mElements[4] =  temp_4;
        mElements[5] =  temp_5;
        mElements[6] =  temp_6;
        mElements[7] =  temp_7;

        mElements[8] =  temp_8;
        mElements[9] =  temp_9;
        mElements[10] = temp_10;
        mElements[11] = temp_11;

        mElements[12] = temp_12;
        mElements[13] = temp_13;
        mElements[14] = temp_14;
        mElements[15] = temp_15;

        return  *this;
    }

    Matrix4x4 operator * (const Matrix4x4& m)
    {
        Matrix4x4 matrix(*this);
        matrix *= m;
        return matrix;
    }

    std::array<double, 16> mElements;
};

Matrix4x4 operator+(const Matrix4x4& lhs, const Matrix4x4& rhs);
Matrix4x4 operator-(const Matrix4x4& lhs, const Matrix4x4& rhs);
Matrix4x4 operator*(const Matrix4x4& lhs, const Matrix4x4& rhs);
//Matrix4x4 operator*(const Matrix4x4& lhs, const double rhs);

#endif // MATRIX4X4_H
