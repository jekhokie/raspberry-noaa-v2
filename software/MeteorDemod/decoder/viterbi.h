#ifndef VITERBI_H
#define VITERBI_H

#include <stdint.h>
extern "C" {
#include "correct.h"
}

class Viterbi
{
public:
    Viterbi(int k = 7, uint8_t polynomA = 0x4F, uint8_t polynomB = 0x6D);
    ~Viterbi();

    size_t decodeSoft(const uint8_t *data, uint8_t *result,  size_t blockSize);

private:
    correct_convolutional_polynomial_t mPolynomials[2];
    correct_convolutional *mpConvolutional;
};

#endif // VITERBI_H
