/** THIS IS AN AUTOMATICALLY GENERATED FILE.  DO NOT MODIFY
 * BY HAND!!
 *
 * Generated by lcm-gen
 **/

#ifndef __drake_lcmt_zmp_data_hpp__
#define __drake_lcmt_zmp_data_hpp__

#include "lcm/lcm_coretypes.h"


namespace drake
{

class lcmt_zmp_data
{
    public:
        /// The timestamp in milliseconds.
        int64_t    timestamp;

        double     A[4][4];

        double     B[4][2];

        double     C[2][4];

        double     D[2][2];

        double     x0[4][1];

        double     y0[2][1];

        double     u0[2][1];

        double     R[2][2];

        double     Qy[2][2];

        double     S[4][4];

        double     s1[4][1];

        double     s1dot[4][1];

        double     s2;

        double     s2dot;

    public:
        /**
         * Encode a message into binary form.
         *
         * @param buf The output buffer.
         * @param offset Encoding starts at thie byte offset into @p buf.
         * @param maxlen Maximum number of bytes to write.  This should generally be
         *  equal to getEncodedSize().
         * @return The number of bytes encoded, or <0 on error.
         */
        inline int encode(void *buf, int offset, int maxlen) const;

        /**
         * Check how many bytes are required to encode this message.
         */
        inline int getEncodedSize() const;

        /**
         * Decode a message from binary form into this instance.
         *
         * @param buf The buffer containing the encoded message.
         * @param offset The byte offset into @p buf where the encoded message starts.
         * @param maxlen The maximum number of bytes to read while decoding.
         * @return The number of bytes decoded, or <0 if an error occured.
         */
        inline int decode(const void *buf, int offset, int maxlen);

        /**
         * Retrieve the 64-bit fingerprint identifying the structure of the message.
         * Note that the fingerprint is the same for all instances of the same
         * message type, and is a fingerprint on the message type definition, not on
         * the message contents.
         */
        inline static int64_t getHash();

        /**
         * Returns "lcmt_zmp_data"
         */
        inline static const char* getTypeName();

        // LCM support functions. Users should not call these
        inline int _encodeNoHash(void *buf, int offset, int maxlen) const;
        inline int _getEncodedSizeNoHash() const;
        inline int _decodeNoHash(const void *buf, int offset, int maxlen);
        inline static uint64_t _computeHash(const __lcm_hash_ptr *p);
};

int lcmt_zmp_data::encode(void *buf, int offset, int maxlen) const
{
    int pos = 0, tlen;
    int64_t hash = getHash();

    tlen = __int64_t_encode_array(buf, offset + pos, maxlen - pos, &hash, 1);
    if(tlen < 0) return tlen; else pos += tlen;

    tlen = this->_encodeNoHash(buf, offset + pos, maxlen - pos);
    if (tlen < 0) return tlen; else pos += tlen;

    return pos;
}

int lcmt_zmp_data::decode(const void *buf, int offset, int maxlen)
{
    int pos = 0, thislen;

    int64_t msg_hash;
    thislen = __int64_t_decode_array(buf, offset + pos, maxlen - pos, &msg_hash, 1);
    if (thislen < 0) return thislen; else pos += thislen;
    if (msg_hash != getHash()) return -1;

    thislen = this->_decodeNoHash(buf, offset + pos, maxlen - pos);
    if (thislen < 0) return thislen; else pos += thislen;

    return pos;
}

int lcmt_zmp_data::getEncodedSize() const
{
    return 8 + _getEncodedSizeNoHash();
}

int64_t lcmt_zmp_data::getHash()
{
    static int64_t hash = static_cast<int64_t>(_computeHash(NULL));
    return hash;
}

const char* lcmt_zmp_data::getTypeName()
{
    return "lcmt_zmp_data";
}

int lcmt_zmp_data::_encodeNoHash(void *buf, int offset, int maxlen) const
{
    int pos = 0, tlen;

    tlen = __int64_t_encode_array(buf, offset + pos, maxlen - pos, &this->timestamp, 1);
    if(tlen < 0) return tlen; else pos += tlen;

    for (int a0 = 0; a0 < 4; a0++) {
        tlen = __double_encode_array(buf, offset + pos, maxlen - pos, &this->A[a0][0], 4);
        if(tlen < 0) return tlen; else pos += tlen;
    }

    for (int a0 = 0; a0 < 4; a0++) {
        tlen = __double_encode_array(buf, offset + pos, maxlen - pos, &this->B[a0][0], 2);
        if(tlen < 0) return tlen; else pos += tlen;
    }

    for (int a0 = 0; a0 < 2; a0++) {
        tlen = __double_encode_array(buf, offset + pos, maxlen - pos, &this->C[a0][0], 4);
        if(tlen < 0) return tlen; else pos += tlen;
    }

    for (int a0 = 0; a0 < 2; a0++) {
        tlen = __double_encode_array(buf, offset + pos, maxlen - pos, &this->D[a0][0], 2);
        if(tlen < 0) return tlen; else pos += tlen;
    }

    for (int a0 = 0; a0 < 4; a0++) {
        tlen = __double_encode_array(buf, offset + pos, maxlen - pos, &this->x0[a0][0], 1);
        if(tlen < 0) return tlen; else pos += tlen;
    }

    for (int a0 = 0; a0 < 2; a0++) {
        tlen = __double_encode_array(buf, offset + pos, maxlen - pos, &this->y0[a0][0], 1);
        if(tlen < 0) return tlen; else pos += tlen;
    }

    for (int a0 = 0; a0 < 2; a0++) {
        tlen = __double_encode_array(buf, offset + pos, maxlen - pos, &this->u0[a0][0], 1);
        if(tlen < 0) return tlen; else pos += tlen;
    }

    for (int a0 = 0; a0 < 2; a0++) {
        tlen = __double_encode_array(buf, offset + pos, maxlen - pos, &this->R[a0][0], 2);
        if(tlen < 0) return tlen; else pos += tlen;
    }

    for (int a0 = 0; a0 < 2; a0++) {
        tlen = __double_encode_array(buf, offset + pos, maxlen - pos, &this->Qy[a0][0], 2);
        if(tlen < 0) return tlen; else pos += tlen;
    }

    for (int a0 = 0; a0 < 4; a0++) {
        tlen = __double_encode_array(buf, offset + pos, maxlen - pos, &this->S[a0][0], 4);
        if(tlen < 0) return tlen; else pos += tlen;
    }

    for (int a0 = 0; a0 < 4; a0++) {
        tlen = __double_encode_array(buf, offset + pos, maxlen - pos, &this->s1[a0][0], 1);
        if(tlen < 0) return tlen; else pos += tlen;
    }

    for (int a0 = 0; a0 < 4; a0++) {
        tlen = __double_encode_array(buf, offset + pos, maxlen - pos, &this->s1dot[a0][0], 1);
        if(tlen < 0) return tlen; else pos += tlen;
    }

    tlen = __double_encode_array(buf, offset + pos, maxlen - pos, &this->s2, 1);
    if(tlen < 0) return tlen; else pos += tlen;

    tlen = __double_encode_array(buf, offset + pos, maxlen - pos, &this->s2dot, 1);
    if(tlen < 0) return tlen; else pos += tlen;

    return pos;
}

int lcmt_zmp_data::_decodeNoHash(const void *buf, int offset, int maxlen)
{
    int pos = 0, tlen;

    tlen = __int64_t_decode_array(buf, offset + pos, maxlen - pos, &this->timestamp, 1);
    if(tlen < 0) return tlen; else pos += tlen;

    for (int a0 = 0; a0 < 4; a0++) {
        tlen = __double_decode_array(buf, offset + pos, maxlen - pos, &this->A[a0][0], 4);
        if(tlen < 0) return tlen; else pos += tlen;
    }

    for (int a0 = 0; a0 < 4; a0++) {
        tlen = __double_decode_array(buf, offset + pos, maxlen - pos, &this->B[a0][0], 2);
        if(tlen < 0) return tlen; else pos += tlen;
    }

    for (int a0 = 0; a0 < 2; a0++) {
        tlen = __double_decode_array(buf, offset + pos, maxlen - pos, &this->C[a0][0], 4);
        if(tlen < 0) return tlen; else pos += tlen;
    }

    for (int a0 = 0; a0 < 2; a0++) {
        tlen = __double_decode_array(buf, offset + pos, maxlen - pos, &this->D[a0][0], 2);
        if(tlen < 0) return tlen; else pos += tlen;
    }

    for (int a0 = 0; a0 < 4; a0++) {
        tlen = __double_decode_array(buf, offset + pos, maxlen - pos, &this->x0[a0][0], 1);
        if(tlen < 0) return tlen; else pos += tlen;
    }

    for (int a0 = 0; a0 < 2; a0++) {
        tlen = __double_decode_array(buf, offset + pos, maxlen - pos, &this->y0[a0][0], 1);
        if(tlen < 0) return tlen; else pos += tlen;
    }

    for (int a0 = 0; a0 < 2; a0++) {
        tlen = __double_decode_array(buf, offset + pos, maxlen - pos, &this->u0[a0][0], 1);
        if(tlen < 0) return tlen; else pos += tlen;
    }

    for (int a0 = 0; a0 < 2; a0++) {
        tlen = __double_decode_array(buf, offset + pos, maxlen - pos, &this->R[a0][0], 2);
        if(tlen < 0) return tlen; else pos += tlen;
    }

    for (int a0 = 0; a0 < 2; a0++) {
        tlen = __double_decode_array(buf, offset + pos, maxlen - pos, &this->Qy[a0][0], 2);
        if(tlen < 0) return tlen; else pos += tlen;
    }

    for (int a0 = 0; a0 < 4; a0++) {
        tlen = __double_decode_array(buf, offset + pos, maxlen - pos, &this->S[a0][0], 4);
        if(tlen < 0) return tlen; else pos += tlen;
    }

    for (int a0 = 0; a0 < 4; a0++) {
        tlen = __double_decode_array(buf, offset + pos, maxlen - pos, &this->s1[a0][0], 1);
        if(tlen < 0) return tlen; else pos += tlen;
    }

    for (int a0 = 0; a0 < 4; a0++) {
        tlen = __double_decode_array(buf, offset + pos, maxlen - pos, &this->s1dot[a0][0], 1);
        if(tlen < 0) return tlen; else pos += tlen;
    }

    tlen = __double_decode_array(buf, offset + pos, maxlen - pos, &this->s2, 1);
    if(tlen < 0) return tlen; else pos += tlen;

    tlen = __double_decode_array(buf, offset + pos, maxlen - pos, &this->s2dot, 1);
    if(tlen < 0) return tlen; else pos += tlen;

    return pos;
}

int lcmt_zmp_data::_getEncodedSizeNoHash() const
{
    int enc_size = 0;
    enc_size += __int64_t_encoded_array_size(NULL, 1);
    enc_size += 4 * __double_encoded_array_size(NULL, 4);
    enc_size += 4 * __double_encoded_array_size(NULL, 2);
    enc_size += 2 * __double_encoded_array_size(NULL, 4);
    enc_size += 2 * __double_encoded_array_size(NULL, 2);
    enc_size += 4 * __double_encoded_array_size(NULL, 1);
    enc_size += 2 * __double_encoded_array_size(NULL, 1);
    enc_size += 2 * __double_encoded_array_size(NULL, 1);
    enc_size += 2 * __double_encoded_array_size(NULL, 2);
    enc_size += 2 * __double_encoded_array_size(NULL, 2);
    enc_size += 4 * __double_encoded_array_size(NULL, 4);
    enc_size += 4 * __double_encoded_array_size(NULL, 1);
    enc_size += 4 * __double_encoded_array_size(NULL, 1);
    enc_size += __double_encoded_array_size(NULL, 1);
    enc_size += __double_encoded_array_size(NULL, 1);
    return enc_size;
}

uint64_t lcmt_zmp_data::_computeHash(const __lcm_hash_ptr *)
{
    uint64_t hash = 0x1e8955d5b19944bfLL;
    return (hash<<1) + ((hash>>63)&1);
}

}

#endif
