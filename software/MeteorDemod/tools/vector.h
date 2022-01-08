#ifndef VECTOR_H
#define VECTOR_H

#include <SGP4.h>

struct Vector3 : Vector {

    Vector3()
        : Vector() {
    }

    Vector3(const Vector v)
        : Vector(v) {
    }

    Vector &operator -= (const Vector& v) {
        x -= v.x;
        y -= v.y;
        z -= v.z;
        return *this;
    }

    Vector3 operator * (double factor) const {
        Vector3 r(*this);
        r.x *= factor;
        r.y *= factor;
        r.z *= factor;
        return r;
    }

    Vector3 &operator *= (double factor) {
        x *= factor;
        y *= factor;
        z *= factor;
        return *this;
    }

    Vector3 operator / (double factor) const {
        Vector3 r(*this);
        r.x /= factor;
        r.y /= factor;
        r.z /= factor;
        return r;
    }

    Vector3 &operator /= (double factor) {
        x /= factor;
        y /= factor;
        z /= factor;
        return *this;
    }

    Vector3 Cross(const Vector& v) const {
        Vector3 r;
        r.x = y * v.z - z * v.y;
        r.y = z * v.x - x * v.z;
        r.z = x * v.y - y * v.x;
        return r;
    }

    Vector3 &Normalize() {
        double m = Magnitude();
        if(m > 0) {
            return (*this) /= m;
        }
        return *this;
    }

    double DistanceSquared() const {
        return (x * x + y * y + z * z);
    }
};

#endif // VECTOR_H
