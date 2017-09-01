#ifndef VERIFYSIG_H
#define VERIFYSIG_H

#include <openssl/evp.h>
#include <openssl/err.h>
#include <openssl/rsa.h>
#include <openssl/pem.h>

#include <stdlib.h>
#include <assert.h>

#include "publickey.h"

typedef unsigned char byte;
const char hn[] = "sha256";

void init_public_key();

/* Returns 0 for success, non-0 otherwise */
int verify_sig(const byte* msg, size_t mlen, const byte* sig, size_t slen);

#endif