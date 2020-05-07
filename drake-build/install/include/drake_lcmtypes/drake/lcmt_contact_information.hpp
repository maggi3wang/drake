/** THIS IS AN AUTOMATICALLY GENERATED FILE.  DO NOT MODIFY
 * BY HAND!!
 *
 * Generated by lcm-gen
 **/

#ifndef __drake_lcmt_contact_information_hpp__
#define __drake_lcmt_contact_information_hpp__

#include "lcm/lcm_coretypes.h"

#include <string>
#include <vector>

namespace drake
{

class lcmt_contact_information
{
    public:
        /// The timestamp in microseconds.
        int64_t    timestamp;

        std::string body_name;

        int32_t    num_contact_points;

        int32_t    num_basis_per_contact_point;

        /// Offsets to individual contact points that are expressed in body frame.
        std::vector< std::vector< double > > contact_points;

        /// Expressed in body frame
        double     normal[3];

        double     mu;

        /**
         * Velocity gain used to stabilize contact velocity.
         * The actual constrained acceleration will be -Kd * xd, where xd is the
         * measured body velocity.
         */
        double     Kd;

        /// Weight of the cost term if using SOFT constraint.
        double     weight;

        /// Constraint type, defined in lcmt_constrained_values.
        int8_t     acceleration_constraint_type;

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
         * Returns "lcmt_contact_information"
         */
        inline static const char* getTypeName();

        // LCM support functions. Users should not call these
        inline int _encodeNoHash(void *buf, int offset, int maxlen) const;
        inline int _getEncodedSizeNoHash() const;
        inline int _decodeNoHash(const void *buf, int offset, int maxlen);
        inline static uint64_t _computeHash(const __lcm_hash_ptr *p);
};

int lcmt_contact_information::encode(void *buf, int offset, int maxlen) const
{
    int pos = 0, tlen;
    int64_t hash = getHash();

    tlen = __int64_t_encode_array(buf, offset + pos, maxlen - pos, &hash, 1);
    if(tlen < 0) return tlen; else pos += tlen;

    tlen = this->_encodeNoHash(buf, offset + pos, maxlen - pos);
    if (tlen < 0) return tlen; else pos += tlen;

    return pos;
}

int lcmt_contact_information::decode(const void *buf, int offset, int maxlen)
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

int lcmt_contact_information::getEncodedSize() const
{
    return 8 + _getEncodedSizeNoHash();
}

int64_t lcmt_contact_information::getHash()
{
    static int64_t hash = static_cast<int64_t>(_computeHash(NULL));
    return hash;
}

const char* lcmt_contact_information::getTypeName()
{
    return "lcmt_contact_information";
}

int lcmt_contact_information::_encodeNoHash(void *buf, int offset, int maxlen) const
{
    int pos = 0, tlen;

    tlen = __int64_t_encode_array(buf, offset + pos, maxlen - pos, &this->timestamp, 1);
    if(tlen < 0) return tlen; else pos += tlen;

    char* body_name_cstr = const_cast<char*>(this->body_name.c_str());
    tlen = __string_encode_array(
        buf, offset + pos, maxlen - pos, &body_name_cstr, 1);
    if(tlen < 0) return tlen; else pos += tlen;

    tlen = __int32_t_encode_array(buf, offset + pos, maxlen - pos, &this->num_contact_points, 1);
    if(tlen < 0) return tlen; else pos += tlen;

    tlen = __int32_t_encode_array(buf, offset + pos, maxlen - pos, &this->num_basis_per_contact_point, 1);
    if(tlen < 0) return tlen; else pos += tlen;

    if(this->num_contact_points > 0) {
        for (int a0 = 0; a0 < 3; a0++) {
            tlen = __double_encode_array(buf, offset + pos, maxlen - pos, &this->contact_points[a0][0], this->num_contact_points);
            if(tlen < 0) return tlen; else pos += tlen;
        }
    }

    tlen = __double_encode_array(buf, offset + pos, maxlen - pos, &this->normal[0], 3);
    if(tlen < 0) return tlen; else pos += tlen;

    tlen = __double_encode_array(buf, offset + pos, maxlen - pos, &this->mu, 1);
    if(tlen < 0) return tlen; else pos += tlen;

    tlen = __double_encode_array(buf, offset + pos, maxlen - pos, &this->Kd, 1);
    if(tlen < 0) return tlen; else pos += tlen;

    tlen = __double_encode_array(buf, offset + pos, maxlen - pos, &this->weight, 1);
    if(tlen < 0) return tlen; else pos += tlen;

    tlen = __int8_t_encode_array(buf, offset + pos, maxlen - pos, &this->acceleration_constraint_type, 1);
    if(tlen < 0) return tlen; else pos += tlen;

    return pos;
}

int lcmt_contact_information::_decodeNoHash(const void *buf, int offset, int maxlen)
{
    int pos = 0, tlen;

    tlen = __int64_t_decode_array(buf, offset + pos, maxlen - pos, &this->timestamp, 1);
    if(tlen < 0) return tlen; else pos += tlen;

    int32_t __body_name_len__;
    tlen = __int32_t_decode_array(
        buf, offset + pos, maxlen - pos, &__body_name_len__, 1);
    if(tlen < 0) return tlen; else pos += tlen;
    if(__body_name_len__ > maxlen - pos) return -1;
    this->body_name.assign(
        static_cast<const char*>(buf) + offset + pos, __body_name_len__ - 1);
    pos += __body_name_len__;

    tlen = __int32_t_decode_array(buf, offset + pos, maxlen - pos, &this->num_contact_points, 1);
    if(tlen < 0) return tlen; else pos += tlen;

    tlen = __int32_t_decode_array(buf, offset + pos, maxlen - pos, &this->num_basis_per_contact_point, 1);
    if(tlen < 0) return tlen; else pos += tlen;

    try {
        this->contact_points.resize(3);
    } catch (...) {
        return -1;
    }
    for (int a0 = 0; a0 < 3; a0++) {
        if(this->num_contact_points) {
            this->contact_points[a0].resize(this->num_contact_points);
            tlen = __double_decode_array(buf, offset + pos, maxlen - pos, &this->contact_points[a0][0], this->num_contact_points);
            if(tlen < 0) return tlen; else pos += tlen;
        }
    }

    tlen = __double_decode_array(buf, offset + pos, maxlen - pos, &this->normal[0], 3);
    if(tlen < 0) return tlen; else pos += tlen;

    tlen = __double_decode_array(buf, offset + pos, maxlen - pos, &this->mu, 1);
    if(tlen < 0) return tlen; else pos += tlen;

    tlen = __double_decode_array(buf, offset + pos, maxlen - pos, &this->Kd, 1);
    if(tlen < 0) return tlen; else pos += tlen;

    tlen = __double_decode_array(buf, offset + pos, maxlen - pos, &this->weight, 1);
    if(tlen < 0) return tlen; else pos += tlen;

    tlen = __int8_t_decode_array(buf, offset + pos, maxlen - pos, &this->acceleration_constraint_type, 1);
    if(tlen < 0) return tlen; else pos += tlen;

    return pos;
}

int lcmt_contact_information::_getEncodedSizeNoHash() const
{
    int enc_size = 0;
    enc_size += __int64_t_encoded_array_size(NULL, 1);
    enc_size += this->body_name.size() + 4 + 1;
    enc_size += __int32_t_encoded_array_size(NULL, 1);
    enc_size += __int32_t_encoded_array_size(NULL, 1);
    enc_size += 3 * __double_encoded_array_size(NULL, this->num_contact_points);
    enc_size += __double_encoded_array_size(NULL, 3);
    enc_size += __double_encoded_array_size(NULL, 1);
    enc_size += __double_encoded_array_size(NULL, 1);
    enc_size += __double_encoded_array_size(NULL, 1);
    enc_size += __int8_t_encoded_array_size(NULL, 1);
    return enc_size;
}

uint64_t lcmt_contact_information::_computeHash(const __lcm_hash_ptr *)
{
    uint64_t hash = 0x01ad8a59d71adf51LL;
    return (hash<<1) + ((hash>>63)&1);
}

}

#endif
