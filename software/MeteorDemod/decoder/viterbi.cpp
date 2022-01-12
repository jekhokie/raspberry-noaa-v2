#include "viterbi.h"

Viterbi::Viterbi(int k, uint8_t polynomA, uint8_t polynomB)
    : mpConvolutional(nullptr)
{
    mPolynomials[0] = polynomA;
    mPolynomials[1] = polynomB;

    mpConvolutional = correct_convolutional_create(2, k, mPolynomials);
}

Viterbi::~Viterbi()
{
    if(mpConvolutional) {
        correct_convolutional_destroy(mpConvolutional);
    }
}

size_t Viterbi::decodeSoft(const uint8_t *data, uint8_t *result, size_t blockSize)
{
    return correct_convolutional_decode_soft(mpConvolutional, data, blockSize, result);
}

