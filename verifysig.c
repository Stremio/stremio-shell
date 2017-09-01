#include <verifysig.h>

EVP_PKEY* pkey = NULL;

void init_public_key() {
    OpenSSL_add_all_digests();
    
    BIO* bio = BIO_new_mem_buf(key, (int)sizeof(key));
    assert(bio != NULL);

    pkey = PEM_read_bio_PUBKEY(bio, NULL, NULL, NULL);
    assert(pkey != NULL);

    BIO_free(bio);
}

int verify_sig(const byte* msg, size_t mlen, const byte* sig, size_t slen)
{
    /* Returned to caller */
    int result = -1;
    
    if(!msg || !mlen || !sig || !slen || !pkey) {
        return -1;
    }
    
    EVP_MD_CTX* ctx = NULL;
    
    do
    {
        ctx = EVP_MD_CTX_create();
        if(ctx == NULL) {
            printf("EVP_MD_CTX_create failed, error 0x%lx\n", ERR_get_error());
            break;
        }
        
        const EVP_MD* md = EVP_get_digestbyname(hn);
        if(md == NULL) {
            printf("EVP_get_digestbyname failed, error 0x%lx\n", ERR_get_error());
            break;
        }
        
        int rc = EVP_DigestInit_ex(ctx, md, NULL);
        if(rc != 1) {
            printf("EVP_DigestInit_ex failed, error 0x%lx\n", ERR_get_error());
            break;
        }
        
        rc = EVP_DigestVerifyInit(ctx, NULL, md, NULL, pkey);
        if(rc != 1) {
            printf("EVP_DigestVerifyInit failed, error 0x%lx\n", ERR_get_error());
            break;
        }
        
        rc = EVP_DigestVerifyUpdate(ctx, msg, mlen);
        if(rc != 1) {
            printf("EVP_DigestVerifyUpdate failed, error 0x%lx\n", ERR_get_error());
            break;
        }
        
        /* Clear any errors for the call below */
        ERR_clear_error();
        
        rc = EVP_DigestVerifyFinal(ctx, sig, slen);
        if(rc != 1) {
            printf("EVP_DigestVerifyFinal failed, error 0x%lx\n", ERR_get_error());
            break;
        }
        
        result = 0;
        
    } while(0);
    
    if(ctx) {
        EVP_MD_CTX_destroy(ctx);
        ctx = NULL;
    }
    
    return !!result;
}
