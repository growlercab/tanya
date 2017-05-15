/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

/**
 * Data Encryption Standard.
 *
 * Copyright: Eugene Wissner 2017.
 * License: $(LINK2 https://www.mozilla.org/en-US/MPL/2.0/,
 *                  Mozilla Public License, v. 2.0).
 * Authors: $(LINK2 mailto:info@caraus.de, Eugene Wissner)
 */
module tanya.crypto.des;

import core.stdc.stdlib;
import core.stdc.string;
import std.algorithm.mutation;
import std.range;
import tanya.container.vector;
import tanya.crypto.symmetric;

version (unittest)
{
    import std.algorithm.comparison;
    import tanya.memory;
}

/**
 * Data Encryption Standard.
 *
 * Params:
 *  L = Number of keys.
 */
final class DES(uint L = 1) : BlockCipher
    if (L == 1 || L == 3)
{
    mixin FixedBlockLength!8;
    mixin KeyLength!(singleKeyLength * L, singleKeyLength * L);

    // 56 bits used, but must supply 64 (8 are ignored)
    private enum singleKeyLength = 8;

    private enum expansionBlockLength = 6;
    private enum pc1KeyLength = 7;
    private enum subkeyLength = 6;

    private Vector!ubyte key_;

    /**
     * Params:
     *  key = Key.
     *
     * Precondition: $(D_INLINECODE key.length == this.keyLength).
     */
    this(ref const Vector!ubyte key)
    in
    {
        assert(key.length == this.keyLength);
    }
    body
    {
        this.key = key;
    }

    /// Ditto.
    this()
    {
    }

    /**
     * Resets the key.
     *
     * Params:
     *  key = Key.
     *
     * Precondition: $(D_INLINECODE key.length == this.keyLength).
     */
    @property void key(ref const Vector!ubyte key)
    in
    {
        assert(key.length == this.keyLength);
    }
    body
    {
        this.key_ = key;
    }

    /**
     * Encrypts a block.
     *
     * Params:
     *  plain  = Plain text, input.
     *  cipher = Cipher text, output.
     *
     * Precondition: $(D_INLINECODE plain.length == blockLength && cipher.length == blockLength).
     */
    void encrypt(ref const Vector!ubyte plain, ref Vector!ubyte cipher)
    {
        operate!(Direction.encryption, L)(plain.get(), cipher.get());
    }

    /**
     * Decrypts a block.
     *
     * Params:
     *  cipher = Cipher text, input.
     *  plain  = Plain text, output.
     *
     * Precondition: $(D_INLINECODE plain.length == blockLength && cipher.length == blockLength).
     */
    void decrypt(ref const Vector!ubyte cipher, ref Vector!ubyte plain)
    {
        operate!(Direction.decryption, L)(cipher.get(), plain.get());
    }

    // Initial permutation table.
    private const ubyte[64] ipTable = [ 58, 50, 42, 34, 26, 18, 10, 2,
                                        60, 52, 44, 36, 28, 20, 12, 4,
                                        62, 54, 46, 38, 30, 22, 14, 6,
                                        64, 56, 48, 40, 32, 24, 16, 8,
                                        57, 49, 41, 33, 25, 17, 9,  1,
                                        59, 51, 43, 35, 27, 19, 11, 3,
                                        61, 53, 45, 37, 29, 21, 13, 5,
                                        63, 55, 47, 39, 31, 23, 15, 7 ];

    // Final permutation table.
    private const ubyte[64] fpTable = [ 40, 8, 48, 16, 56, 24, 64, 32,
                                        39, 7, 47, 15, 55, 23, 63, 31,
                                        38, 6, 46, 14, 54, 22, 62, 30,
                                        37, 5, 45, 13, 53, 21, 61, 29,
                                        36, 4, 44, 12, 52, 20, 60, 28,
                                        35, 3, 43, 11, 51, 19, 59, 27,
                                        34, 2, 42, 10, 50, 18, 58, 26,
                                        33, 1, 41, 9,  49, 17, 57, 25 ];

    // Key permutation table 1.
    private const ubyte[64] pc1Table = [ 57, 49, 41, 33, 25, 17, 9, 1,
                                         58, 50, 42, 34, 26, 18, 10, 2,
                                         59, 51, 43, 35, 27, 19, 11, 3,
                                         60, 52, 44, 36, 63, 55, 47, 39,
                                         31, 23, 15, 7,  62, 54, 46, 38,
                                         30, 22, 14, 6,  61, 53, 45, 37,
                                         29, 21, 13, 5,  28, 20, 12, 4 ];

    // Key permutation table 2.
    private const ubyte[48] pc2Table = [ 14, 17, 11, 24, 1,  5,  3,  28,
                                         15, 6,  21, 10, 23, 19, 12, 4,
                                         26, 8,  16, 7,  27, 20, 13, 2,
                                         41, 52, 31, 37, 47, 55, 30, 40,
                                         51, 45, 33, 48, 44, 49, 39, 56,
                                         34, 53, 46, 42, 50, 36, 29, 32 ];

    // Expansion table.
    private const ubyte[48] expansionTable = [ 32, 1,  2,  3,  4,  5,  4,  5,
                                               6,  7,  8,  9,  8,  9,  10, 11,
                                               12, 13, 12, 13, 14, 15, 16, 17,
                                               16, 17, 18, 19, 20, 21, 20, 21,
                                               22, 23, 24, 25, 24, 25, 26, 27,
                                               28, 29, 28, 29, 30, 31, 32, 1 ];

    // Final input block permutation.
    private const ubyte[32] pTable = [ 16, 7,  20, 21, 29, 12, 28, 17,
                                       1,  15, 23, 26, 5,  18, 31, 10,
                                       2,  8,  24, 14, 32, 27, 3,  9,
                                       19, 13, 30, 6,  22, 11, 4, 25 ];

    // The S-boxes.
    private const ubyte[64][8] sBox = [[
                                         14, 0,  4,  15, 13, 7,  1,  4,  2, 14,  15, 2, 11, 13, 8,  1,
                                         3,  10, 10, 6,  6,  12, 12, 11, 5,  9,  9,  5, 0,  3,  7,  8,
                                         4,  15, 1,  12, 14, 8,  8,  2,  13, 4,  6,  9, 2,  1,  11, 7,
                                         15, 5,  12, 11, 9,  3,  7,  14, 3,  10, 10, 0, 5,  6,  0,  13,
                                       ], [
                                         15, 3,  1,  13, 8,  4,  14, 7,  6,  15, 11, 2,  3,  8,  4,  14,
                                         9,  12, 7,  0,  2,  1,  13, 10, 12, 6,  0,  9,  5,  11, 10, 5,
                                         0,  13, 14, 8,  7,  10, 11, 1,  10, 3,  4,  15, 13, 4,  1,  2,
                                         5,  11, 8,  6,  12, 7,  6,  12, 9,  0,  3,  5,  2,  14, 15, 9,
                                       ], [
                                         10, 13, 0,  7,  9,  0,  14, 9,  6,  3,  3,  4,  15, 6,  5,  10,
                                         1,  2,  13, 8,  12, 5,  7,  14, 11, 12, 4,  11, 2,  15, 8,  1,
                                         13, 1,  6,  10, 4,  13, 9,  0,  8,  6,  15, 9,  3,  8,  0,  7,
                                         11, 4,  1,  15, 2,  14, 12, 3,  5,  11, 10, 5,  14, 2,  7,  12,
                                       ], [
                                         7,  13, 13, 8,  14, 11, 3,  5,  0,  6,  6,  15, 9,  0,  10, 3,
                                         1,  4,  2,  7,  8,  2,  5,  12, 11, 1,  12, 10, 4,  14, 15, 9,
                                         10, 3,  6,  15, 9,  0,  0,  6,  12, 10, 11, 1,  7,  13, 13, 8,
                                         15, 9,  1,  4,  3,  5,  14, 11, 5,  12, 2,  7,  8,  2,  4,  14,
                                       ], [
                                         2,  14, 12, 11, 4,  2,  1,  12, 7,  4,  10, 7,  11, 13, 6,  1,
                                         8,  5,  5,  0,  3,  15, 15, 10, 13, 3,  0,  9,  14, 8,  9,  6,
                                         4,  11, 2,  8,  1,  12, 11, 7,  10, 1,  13, 14, 7,  2,  8,  13,
                                         15, 6,  9,  15, 12, 0,  5,  9,  6,  10, 3,  4,  0,  5,  14, 3,
                                       ], [
                                         12, 10, 1,  15, 10, 4,  15, 2,  9,  7,  2,  12, 6,  9,  8,  5,
                                         0,  6,  13, 1,  3,  13, 4,  14, 14, 0,  7,  11, 5,  3,  11, 8,
                                         9,  4,  14, 3,  15, 2,  5,  12, 2,  9,  8,  5,  12, 15, 3,  10,
                                         7,  11, 0,  14, 4,  1,  10, 7,  1,  6,  13, 0,  11, 8,  6,  13,
                                       ], [
                                         4,  13, 11, 0,  2,  11, 14, 7,  15, 4,  0,  9,  8,  1,  13, 10,
                                         3,  14, 12, 3,  9,  5,  7,  12, 5,  2,  10, 15, 6,  8,  1,  6,
                                         1,  6,  4,  11, 11, 13, 13, 8,  12, 1,  3,  4,  7,  10, 14, 7,
                                         10, 9,  15, 5,  6,  0,  8,  15, 0,  14, 5,  2,  9,  3,  2,  12,
                                       ], [
                                         13, 1,  2,  15, 8,  13, 4,  8,  6,  10, 15, 3,  11, 7,  1,  4,
                                         10, 12, 9,  5,  3,  6,  14, 11, 5,  0,  0,  14, 12, 9,  7,  2,
                                         7,  2,  11, 1,  4,  14, 1,  7,  9,  4,  12, 10, 14, 8,  2,  13,
                                         0,  15, 6,  12, 10, 9,  13, 0,  15, 3,  3,  5,  5,  6,  8,  11,
                                       ]];

    /**
     * Performs the left rotation operation on the key.
     *
     * Params:
     *  key = The key to rotate.
     */
    private void rotateLeft(ref ubyte[7] key) const
    {
        immutable carryLeft = (key[0] & 0x80) >> 3;

        key[0] = cast(ubyte) ((key[0] << 1) | ((key[1] & 0x80) >> 7));
        key[1] = cast(ubyte) ((key[1] << 1) | ((key[2] & 0x80) >> 7));
        key[2] = cast(ubyte) ((key[2] << 1) | ((key[3] & 0x80) >> 7));

        immutable carryRight = (key[3] & 0x08) >> 3;
        key[3] = cast(ubyte) ((((key[3] << 1) | ((key[4] & 0x80) >> 7)) & ~0x10) | carryLeft);

        key[4] = cast(ubyte) ((key[4] << 1) | ((key[5] & 0x80) >> 7));
        key[5] = cast(ubyte) ((key[5] << 1) | ((key[6] & 0x80) >> 7));
        key[6] = cast(ubyte) ((key[6] << 1) | carryRight);
    }

    /**
     * Performs the right rotation operation on the key.
     *
     * Params:
     *  key = The key to rotate.
     */
    private void rotateRight(ref ubyte[7] key) const
    {
        immutable carryRight = (key[6] & 0x01) << 3;

        key[6] = cast(ubyte) ((key[6] >> 1) | ((key[5] & 0x01) << 7));
        key[5] = cast(ubyte) ((key[5] >> 1) | ((key[4] & 0x01) << 7));
        key[4] = cast(ubyte) ((key[4] >> 1) | ((key[3] & 0x01) << 7));

        immutable carryLeft = (key[3] & 0x10) << 3;
        key[3] = cast(ubyte) ((((key[3] >> 1) | ((key[2] & 0x01) << 7)) & ~0x08) | carryRight);

        key[2] = cast(ubyte) ((key[2] >> 1) | ((key[1] & 0x01) << 7));
        key[1] = cast(ubyte) ((key[1] >> 1) | ((key[0] & 0x01) << 7));
        key[0] = cast(ubyte) ((key[0] >> 1) | carryLeft);
    }

    // This does not return a 1 for a 1 bit; it just returns non-zero
    private ubyte getBit(const ubyte[] array, const size_t bit)
    {
        return array[bit / 8] & (0x80 >> (bit % 8));
    }

    /*
     * Implement the initial and final permutation functions.
     * This assumes that the permutation tables are defined as one-based
     * rather than 0-based arrays, since they're given that way in the
     * specification.
     */
    private void permute(ubyte[] target, const ubyte[] src, const ubyte[] permuteTable)
    in
    {
        assert(target.length < uint.max / 8);
    }
    body
    {
        for (int i = 0; i < target.length * 8; ++i)
        {
            if (getBit(src, permuteTable[i] - 1))
            {
                target[i / 8] |= (0x80 >> (i % 8)); // Set bit.
            }
            else
            {
                target[i / 8] &= ~(0x80 >> (i % 8)); // Clear bit.
            }
        }
    }

    private void blockOperate(Direction D)(const ubyte[] plaintext,
                                           ubyte[] ciphertext,
                                           const ubyte[] key)
    in
    {
        assert(plaintext.length == blockLength);
        assert(ciphertext.length == 8);
        assert(key.length == 8);
    }
    body
    {
        // Holding areas; result flows from plaintext, down through these,
        // finally into ciphertext. This could be made more memory efficient
        // by reusing these.
        ubyte[blockLength_] ip_block;
        ubyte[expansionBlockLength] expansionBlock;
        ubyte[blockLength_ / 2] substitution_block;
        ubyte[blockLength_ / 2] pbox_target;
        ubyte[blockLength_ / 2] recomb_box;

        ubyte[pc1KeyLength] pc1key;
        ubyte[subkeyLength] subkey;

        // Initial permutation
        permute(ip_block, plaintext, this.ipTable);

        // Key schedule computation
        permute(pc1key, key, this.pc1Table);
        for (ushort round = 0; round < 16; ++round)
        {
            // "Feistel function" on the first half of the block in 'ip_block'

            // "Expansion". This permutation only looks at the first
            // four bytes (32 bits of ip_block); 16 of these are repeated
            // in "expansion_table".
            permute(expansionBlock, ip_block[4 .. $], this.expansionTable);

            // "Key mixing"
            // rotate both halves of the initial key
            static if (D == Direction.encryption)
            {
                rotateLeft(pc1key);
                if (!(round <= 1 || round == 8 || round == 15))
                {
                    // Rotate twice except in rounds 1, 2, 9 & 16
                    rotateLeft(pc1key);
                }
            }

            permute(subkey, pc1key, this.pc2Table);

            static if (D == Direction.decryption)
            {
                rotateRight(pc1key);
                if (!(round >= 14 || round == 7 || round == 0))
                {
                    // Rotate twice except in rounds 1, 2, 9 & 16
                    rotateRight(pc1key);
                }
            }

            xor(expansionBlock, subkey);

            // Substitution; "copy" from updated expansion block to ciphertext block
            memset(substitution_block.ptr, 0, blockLength / 2);
            substitution_block[0] = cast(ubyte)
                (this.sBox[0][(expansionBlock[0] & 0xFC) >> 2] << 4);
            substitution_block[0] |=
                this.sBox[1][(expansionBlock[0] & 0x03) << 4 |
                (expansionBlock[1] & 0xF0) >> 4];
            substitution_block[1] = cast(ubyte)
                (this.sBox[2][(expansionBlock[1] & 0x0F) << 2 |
                (expansionBlock[2] & 0xC0) >> 6 ] << 4);
            substitution_block[1] |=
                this.sBox[3][(expansionBlock[2] & 0x3F)];
            substitution_block[2] = cast(ubyte)
                (this.sBox[4][(expansionBlock[3] & 0xFC) >> 2 ] << 4);
            substitution_block[2] |=
                this.sBox[5][(expansionBlock[3] & 0x03) << 4 |
                (expansionBlock[4] & 0xF0) >> 4 ];
            substitution_block[3] = cast(ubyte)
                (this.sBox[6][(expansionBlock[4] & 0x0F) << 2 |
                (expansionBlock[5] & 0xC0) >> 6] << 4);
            substitution_block[3] |=
                this.sBox[7][(expansionBlock[5] & 0x3F)];

            // Permutation
            permute(pbox_target, substitution_block, this.pTable);

            // Recombination. XOR the pbox with left half and then switch sides.
            memcpy(recomb_box.ptr, ip_block.ptr, blockLength / 2);
            memcpy(ip_block.ptr, ip_block.ptr + 4 , blockLength / 2);
            xor(recomb_box, pbox_target);
            memcpy(ip_block.ptr + 4, recomb_box.ptr, blockLength / 2);
        }

        // Swap one last time
        memcpy(recomb_box.ptr, ip_block.ptr, blockLength / 2);
        memcpy(ip_block.ptr, ip_block.ptr + 4, blockLength / 2);
        memcpy(ip_block.ptr + 4, recomb_box.ptr, blockLength / 2);

        // Final permutation (undo initial permutation)
        permute(ciphertext, ip_block, this.fpTable);
    }

    private void operate(Direction D,
                         ushort L = 1)
                        (const ubyte[] input,
                         ubyte[] output)
        if (L == 1 || L == 3)
    in
    {
        assert(input.length % blockLength == 0);
    }
    body
    {
        ubyte[blockLength_] inputBlock;

        input.copy(inputBlock[]);
        static if (D == Direction.encryption)
        {
            blockOperate!D(inputBlock, output, this.key_[0 .. blockLength].get());
            static if (L == 3)
            {
                output.copy(inputBlock[]);
                blockOperate!(Direction.decryption)(inputBlock,
                                                    output,
                                                    this.key_[singleKeyLength .. singleKeyLength + blockLength].get());
                output.copy(inputBlock[]);
                blockOperate!D(inputBlock,
                               output,
                               this.key_[singleKeyLength * 2 .. singleKeyLength * 2 + blockLength].get());
            }
        }

        static if (D == Direction.decryption)
        {
            static if (L == 3)
            {
                blockOperate!D(inputBlock,
                               output,
                               this.key_[singleKeyLength * 2 .. singleKeyLength * 2 + blockLength].get());
                output.copy(inputBlock[]);
                blockOperate!(Direction.encryption)(inputBlock, output,
                                                    this.key_[singleKeyLength .. singleKeyLength + blockLength].get());
                output.copy(inputBlock[]);
                blockOperate!D(inputBlock, output, this.key_[0 .. blockLength].get());
            }
            else
            {
                blockOperate!D(inputBlock, output[0 .. blockLength], this.key_[0 .. blockLength].get());
            }
        }
    }
}

/* Test vectors for DES. Source:
   "Validating the Correctness of Hardware
   Implementations of the NBS Data Encryption Standard"
   NBS Special Publication 500-20, 1980. Appendix B */
// Initial and reverse Permutation and Expansion tests. Encrypt.
private unittest
{
    ubyte[8][64] desTestVectors1 = [
        [0x95, 0xf8, 0xa5, 0xe5, 0xdd, 0x31, 0xd9, 0x00],
        [0xdd, 0x7f, 0x12, 0x1c, 0xa5, 0x01, 0x56, 0x19],
        [0x2e, 0x86, 0x53, 0x10, 0x4f, 0x38, 0x34, 0xea],
        [0x4b, 0xd3, 0x88, 0xff, 0x6c, 0xd8, 0x1d, 0x4f],
        [0x20, 0xb9, 0xe7, 0x67, 0xb2, 0xfb, 0x14, 0x56],
        [0x55, 0x57, 0x93, 0x80, 0xd7, 0x71, 0x38, 0xef],
        [0x6c, 0xc5, 0xde, 0xfa, 0xaf, 0x04, 0x51, 0x2f],
        [0x0d, 0x9f, 0x27, 0x9b, 0xa5, 0xd8, 0x72, 0x60],
        [0xd9, 0x03, 0x1b, 0x02, 0x71, 0xbd, 0x5a, 0x0a],
        [0x42, 0x42, 0x50, 0xb3, 0x7c, 0x3d, 0xd9, 0x51],
        [0xb8, 0x06, 0x1b, 0x7e, 0xcd, 0x9a, 0x21, 0xe5],
        [0xf1, 0x5d, 0x0f, 0x28, 0x6b, 0x65, 0xbd, 0x28],
        [0xad, 0xd0, 0xcc, 0x8d, 0x6e, 0x5d, 0xeb, 0xa1],
        [0xe6, 0xd5, 0xf8, 0x27, 0x52, 0xad, 0x63, 0xd1],
        [0xec, 0xbf, 0xe3, 0xbd, 0x3f, 0x59, 0x1a, 0x5e],
        [0xf3, 0x56, 0x83, 0x43, 0x79, 0xd1, 0x65, 0xcd],
        [0x2b, 0x9f, 0x98, 0x2f, 0x20, 0x03, 0x7f, 0xa9],
        [0x88, 0x9d, 0xe0, 0x68, 0xa1, 0x6f, 0x0b, 0xe6],
        [0xe1, 0x9e, 0x27, 0x5d, 0x84, 0x6a, 0x12, 0x98],
        [0x32, 0x9a, 0x8e, 0xd5, 0x23, 0xd7, 0x1a, 0xec],
        [0xe7, 0xfc, 0xe2, 0x25, 0x57, 0xd2, 0x3c, 0x97],
        [0x12, 0xa9, 0xf5, 0x81, 0x7f, 0xf2, 0xd6, 0x5d],
        [0xa4, 0x84, 0xc3, 0xad, 0x38, 0xdc, 0x9c, 0x19],
        [0xfb, 0xe0, 0x0a, 0x8a, 0x1e, 0xf8, 0xad, 0x72],
        [0x75, 0x0d, 0x07, 0x94, 0x07, 0x52, 0x13, 0x63],
        [0x64, 0xfe, 0xed, 0x9c, 0x72, 0x4c, 0x2f, 0xaf],
        [0xf0, 0x2b, 0x26, 0x3b, 0x32, 0x8e, 0x2b, 0x60],
        [0x9d, 0x64, 0x55, 0x5a, 0x9a, 0x10, 0xb8, 0x52],
        [0xd1, 0x06, 0xff, 0x0b, 0xed, 0x52, 0x55, 0xd7],
        [0xe1, 0x65, 0x2c, 0x6b, 0x13, 0x8c, 0x64, 0xa5],
        [0xe4, 0x28, 0x58, 0x11, 0x86, 0xec, 0x8f, 0x46],
        [0xae, 0xb5, 0xf5, 0xed, 0xe2, 0x2d, 0x1a, 0x36],
        [0xe9, 0x43, 0xd7, 0x56, 0x8a, 0xec, 0x0c, 0x5c],
        [0xdf, 0x98, 0xc8, 0x27, 0x6f, 0x54, 0xb0, 0x4b],
        [0xb1, 0x60, 0xe4, 0x68, 0x0f, 0x6c, 0x69, 0x6f],
        [0xfa, 0x07, 0x52, 0xb0, 0x7d, 0x9c, 0x4a, 0xb8],
        [0xca, 0x3a, 0x2b, 0x03, 0x6d, 0xbc, 0x85, 0x02],
        [0x5e, 0x09, 0x05, 0x51, 0x7b, 0xb5, 0x9b, 0xcf],
        [0x81, 0x4e, 0xeb, 0x3b, 0x91, 0xd9, 0x07, 0x26],
        [0x4d, 0x49, 0xdb, 0x15, 0x32, 0x91, 0x9c, 0x9f],
        [0x25, 0xeb, 0x5f, 0xc3, 0xf8, 0xcf, 0x06, 0x21],
        [0xab, 0x6a, 0x20, 0xc0, 0x62, 0x0d, 0x1c, 0x6f],
        [0x79, 0xe9, 0x0d, 0xbc, 0x98, 0xf9, 0x2c, 0xca],
        [0x86, 0x6e, 0xce, 0xdd, 0x80, 0x72, 0xbb, 0x0e],
        [0x8b, 0x54, 0x53, 0x6f, 0x2f, 0x3e, 0x64, 0xa8],
        [0xea, 0x51, 0xd3, 0x97, 0x55, 0x95, 0xb8, 0x6b],
        [0xca, 0xff, 0xc6, 0xac, 0x45, 0x42, 0xde, 0x31],
        [0x8d, 0xd4, 0x5a, 0x2d, 0xdf, 0x90, 0x79, 0x6c],
        [0x10, 0x29, 0xd5, 0x5e, 0x88, 0x0e, 0xc2, 0xd0],
        [0x5d, 0x86, 0xcb, 0x23, 0x63, 0x9d, 0xbe, 0xa9],
        [0x1d, 0x1c, 0xa8, 0x53, 0xae, 0x7c, 0x0c, 0x5f],
        [0xce, 0x33, 0x23, 0x29, 0x24, 0x8f, 0x32, 0x28],
        [0x84, 0x05, 0xd1, 0xab, 0xe2, 0x4f, 0xb9, 0x42],
        [0xe6, 0x43, 0xd7, 0x80, 0x90, 0xca, 0x42, 0x07],
        [0x48, 0x22, 0x1b, 0x99, 0x37, 0x74, 0x8a, 0x23],
        [0xdd, 0x7c, 0x0b, 0xbd, 0x61, 0xfa, 0xfd, 0x54],
        [0x2f, 0xbc, 0x29, 0x1a, 0x57, 0x0d, 0xb5, 0xc4],
        [0xe0, 0x7c, 0x30, 0xd7, 0xe4, 0xe2, 0x6e, 0x12],
        [0x09, 0x53, 0xe2, 0x25, 0x8e, 0x8e, 0x90, 0xa1],
        [0x5b, 0x71, 0x1b, 0xc4, 0xce, 0xeb, 0xf2, 0xee],
        [0xcc, 0x08, 0x3f, 0x1e, 0x6d, 0x9e, 0x85, 0xf6],
        [0xd2, 0xfd, 0x88, 0x67, 0xd5, 0x0d, 0x2d, 0xfe],
        [0x06, 0xe7, 0xea, 0x22, 0xce, 0x92, 0x70, 0x8f],
        [0x16, 0x6b, 0x40, 0xb4, 0x4a, 0xba, 0x4b, 0xd6],
    ];

    auto key = Vector!ubyte(cast(ubyte[8]) [0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01]);
    auto des = defaultAllocator.make!(DES!1)(key);

    auto plain = Vector!ubyte(cast(ubyte[8]) [0x80, 0, 0, 0, 0, 0, 0, 0]);
    auto cipher = Vector!ubyte(8);

    foreach (ubyte i; 0 .. 64)
    {
        if (i != 0)
        {
            plain[i / 8] = cast(ubyte) (i % 8 ? plain[i / 8] >> 0x01 : 0x80);
            if (i % 8 == 0)
            {
                plain[i / 8 - 1] = cast(ubyte) 0;
            }
        }
        // Initial Permutation and Expansion test.
        des.encrypt(plain, cipher);
        assert(equal(cipher[], desTestVectors1[i][]));

        // Inverse Permutation and Expansion test.
        des.encrypt(cipher, cipher);
        assert(cipher == plain);
    }
}

// Key Permutation test. Encrypt.
// Test of right-shifts. Decrypt.
private unittest
{
    ubyte[8][56] desTestVectors2 = [
        [0x95, 0xa8, 0xd7, 0x28, 0x13, 0xda, 0xa9, 0x4d],
        [0x0e, 0xec, 0x14, 0x87, 0xdd, 0x8c, 0x26, 0xd5],
        [0x7a, 0xd1, 0x6f, 0xfb, 0x79, 0xc4, 0x59, 0x26],
        [0xd3, 0x74, 0x62, 0x94, 0xca, 0x6a, 0x6c, 0xf3],
        [0x80, 0x9f, 0x5f, 0x87, 0x3c, 0x1f, 0xd7, 0x61],
        [0xc0, 0x2f, 0xaf, 0xfe, 0xc9, 0x89, 0xd1, 0xfc],
        [0x46, 0x15, 0xaa, 0x1d, 0x33, 0xe7, 0x2f, 0x10],
        [0x20, 0x55, 0x12, 0x33, 0x50, 0xc0, 0x08, 0x58],
        [0xdf, 0x3b, 0x99, 0xd6, 0x57, 0x73, 0x97, 0xc8],
        [0x31, 0xfe, 0x17, 0x36, 0x9b, 0x52, 0x88, 0xc9],
        [0xdf, 0xdd, 0x3c, 0xc6, 0x4d, 0xae, 0x16, 0x42],
        [0x17, 0x8c, 0x83, 0xce, 0x2b, 0x39, 0x9d, 0x94],
        [0x50, 0xf6, 0x36, 0x32, 0x4a, 0x9b, 0x7f, 0x80],
        [0xa8, 0x46, 0x8e, 0xe3, 0xbc, 0x18, 0xf0, 0x6d],
        [0xa2, 0xdc, 0x9e, 0x92, 0xfd, 0x3c, 0xde, 0x92],
        [0xca, 0xc0, 0x9f, 0x79, 0x7d, 0x03, 0x12, 0x87],
        [0x90, 0xba, 0x68, 0x0b, 0x22, 0xae, 0xb5, 0x25],
        [0xce, 0x7a, 0x24, 0xf3, 0x50, 0xe2, 0x80, 0xb6],
        [0x88, 0x2b, 0xff, 0x0a, 0xa0, 0x1a, 0x0b, 0x87],
        [0x25, 0x61, 0x02, 0x88, 0x92, 0x45, 0x11, 0xc2],
        [0xc7, 0x15, 0x16, 0xc2, 0x9c, 0x75, 0xd1, 0x70],
        [0x51, 0x99, 0xc2, 0x9a, 0x52, 0xc9, 0xf0, 0x59],
        [0xc2, 0x2f, 0x0a, 0x29, 0x4a, 0x71, 0xf2, 0x9f],
        [0xee, 0x37, 0x14, 0x83, 0x71, 0x4c, 0x02, 0xea],
        [0xa8, 0x1f, 0xbd, 0x44, 0x8f, 0x9e, 0x52, 0x2f],
        [0x4f, 0x64, 0x4c, 0x92, 0xe1, 0x92, 0xdf, 0xed],
        [0x1a, 0xfa, 0x9a, 0x66, 0xa6, 0xdf, 0x92, 0xae],
        [0xb3, 0xc1, 0xcc, 0x71, 0x5c, 0xb8, 0x79, 0xd8],
        [0x19, 0xd0, 0x32, 0xe6, 0x4a, 0xb0, 0xbd, 0x8b],
        [0x3c, 0xfa, 0xa7, 0xa7, 0xdc, 0x87, 0x20, 0xdc],
        [0xb7, 0x26, 0x5f, 0x7f, 0x44, 0x7a, 0xc6, 0xf3],
        [0x9d, 0xb7, 0x3b, 0x3c, 0x0d, 0x16, 0x3f, 0x54],
        [0x81, 0x81, 0xb6, 0x5b, 0xab, 0xf4, 0xa9, 0x75],
        [0x93, 0xc9, 0xb6, 0x40, 0x42, 0xea, 0xa2, 0x40],
        [0x55, 0x70, 0x53, 0x08, 0x29, 0x70, 0x55, 0x92],
        [0x86, 0x38, 0x80, 0x9e, 0x87, 0x87, 0x87, 0xa0],
        [0x41, 0xb9, 0xa7, 0x9a, 0xf7, 0x9a, 0xc2, 0x08],
        [0x7a, 0x9b, 0xe4, 0x2f, 0x20, 0x09, 0xa8, 0x92],
        [0x29, 0x03, 0x8d, 0x56, 0xba, 0x6d, 0x27, 0x45],
        [0x54, 0x95, 0xc6, 0xab, 0xf1, 0xe5, 0xdf, 0x51],
        [0xae, 0x13, 0xdb, 0xd5, 0x61, 0x48, 0x89, 0x33],
        [0x02, 0x4d, 0x1f, 0xfa, 0x89, 0x04, 0xe3, 0x89],
        [0xd1, 0x39, 0x97, 0x12, 0xf9, 0x9b, 0xf0, 0x2e],
        [0x14, 0xc1, 0xd7, 0xc1, 0xcf, 0xfe, 0xc7, 0x9e],
        [0x1d, 0xe5, 0x27, 0x9d, 0xae, 0x3b, 0xed, 0x6f],
        [0xe9, 0x41, 0xa3, 0x3f, 0x85, 0x50, 0x13, 0x03],
        [0xda, 0x99, 0xdb, 0xbc, 0x9a, 0x03, 0xf3, 0x79],
        [0xb7, 0xfc, 0x92, 0xf9, 0x1d, 0x8e, 0x92, 0xe9],
        [0xae, 0x8e, 0x5c, 0xaa, 0x3c, 0xa0, 0x4e, 0x85],
        [0x9c, 0xc6, 0x2d, 0xf4, 0x3b, 0x6e, 0xed, 0x74],
        [0xd8, 0x63, 0xdb, 0xb5, 0xc5, 0x9a, 0x91, 0xa0],
        [0xa1, 0xab, 0x21, 0x90, 0x54, 0x5b, 0x91, 0xd7],
        [0x08, 0x75, 0x04, 0x1e, 0x64, 0xc5, 0x70, 0xf7],
        [0x5a, 0x59, 0x45, 0x28, 0xbe, 0xbe, 0xf1, 0xcc],
        [0xfc, 0xdb, 0x32, 0x91, 0xde, 0x21, 0xf0, 0xc0],
        [0x86, 0x9e, 0xfd, 0x7f, 0x9f, 0x26, 0x5a, 0x09],
    ];

    auto key = Vector!ubyte(8);
    auto cipher = Vector!ubyte(8);
    auto plain = const Vector!ubyte(8);

    foreach (ubyte i; 0 .. 56)
    {
        key[i / 7] = cast(ubyte) (i % 7 ? key[i / 7] >> 1 : 0x80);
        if (i % 7 == 0 && i != 0)
        {
            key[i / 7 - 1] = cast(ubyte) 0x01;
        }
        auto des = defaultAllocator.make!(DES!1)(key);
        auto testVector = const Vector!ubyte(desTestVectors2[i]);

        // Initial Permutation and Expansion test.
        des.encrypt(plain, cipher);
        assert(cipher == testVector);

        // Test of right-shifts in Decryption.
        des.decrypt(testVector, cipher);
        assert(cipher == plain);

        defaultAllocator.dispose(des);
    }
}

// Data permutation test. Encrypt.
private unittest
{
    ubyte[8][2][32] desTestVectors3 = [
        [[0x10, 0x46, 0x91, 0x34, 0x89, 0x98, 0x01, 0x31], [0x88, 0xd5, 0x5e, 0x54, 0xf5, 0x4c, 0x97, 0xb4]],
        [[0x10, 0x07, 0x10, 0x34, 0x89, 0x98, 0x80, 0x20], [0x0c, 0x0c, 0xc0, 0x0c, 0x83, 0xea, 0x48, 0xfd]],
        [[0x10, 0x07, 0x10, 0x34, 0xc8, 0x98, 0x01, 0x20], [0x83, 0xbc, 0x8e, 0xf3, 0xa6, 0x57, 0x01, 0x83]],
        [[0x10, 0x46, 0x10, 0x34, 0x89, 0x98, 0x80, 0x20], [0xdf, 0x72, 0x5d, 0xca, 0xd9, 0x4e, 0xa2, 0xe9]],
        [[0x10, 0x86, 0x91, 0x15, 0x19, 0x19, 0x01, 0x01], [0xe6, 0x52, 0xb5, 0x3b, 0x55, 0x0b, 0xe8, 0xb0]],
        [[0x10, 0x86, 0x91, 0x15, 0x19, 0x58, 0x01, 0x01], [0xaf, 0x52, 0x71, 0x20, 0xc4, 0x85, 0xcb, 0xb0]],
        [[0x51, 0x07, 0xb0, 0x15, 0x19, 0x58, 0x01, 0x01], [0x0f, 0x04, 0xce, 0x39, 0x3d, 0xb9, 0x26, 0xd5]],
        [[0x10, 0x07, 0xb0, 0x15, 0x19, 0x19, 0x01, 0x01], [0xc9, 0xf0, 0x0f, 0xfc, 0x74, 0x07, 0x90, 0x67]],
        [[0x31, 0x07, 0x91, 0x54, 0x98, 0x08, 0x01, 0x01], [0x7c, 0xfd, 0x82, 0xa5, 0x93, 0x25, 0x2b, 0x4e]],
        [[0x31, 0x07, 0x91, 0x94, 0x98, 0x08, 0x01, 0x01], [0xcb, 0x49, 0xa2, 0xf9, 0xe9, 0x13, 0x63, 0xe3]],
        [[0x10, 0x07, 0x91, 0x15, 0xb9, 0x08, 0x01, 0x40], [0x00, 0xb5, 0x88, 0xbe, 0x70, 0xd2, 0x3f, 0x56]],
        [[0x31, 0x07, 0x91, 0x15, 0x98, 0x08, 0x01, 0x40], [0x40, 0x6a, 0x9a, 0x6a, 0xb4, 0x33, 0x99, 0xae]],
        [[0x10, 0x07, 0xd0, 0x15, 0x89, 0x98, 0x01, 0x01], [0x6c, 0xb7, 0x73, 0x61, 0x1d, 0xca, 0x9a, 0xda]],
        [[0x91, 0x07, 0x91, 0x15, 0x89, 0x98, 0x01, 0x01], [0x67, 0xfd, 0x21, 0xc1, 0x7d, 0xbb, 0x5d, 0x70]],
        [[0x91, 0x07, 0xd0, 0x15, 0x89, 0x19, 0x01, 0x01], [0x95, 0x92, 0xcb, 0x41, 0x10, 0x43, 0x07, 0x87]],
        [[0x10, 0x07, 0xd0, 0x15, 0x98, 0x98, 0x01, 0x20], [0xa6, 0xb7, 0xff, 0x68, 0xa3, 0x18, 0xdd, 0xd3]],
        [[0x10, 0x07, 0x94, 0x04, 0x98, 0x19, 0x01, 0x01], [0x4d, 0x10, 0x21, 0x96, 0xc9, 0x14, 0xca, 0x16]],
        [[0x01, 0x07, 0x91, 0x04, 0x91, 0x19, 0x04, 0x01], [0x2d, 0xfa, 0x9f, 0x45, 0x73, 0x59, 0x49, 0x65]],
        [[0x01, 0x07, 0x91, 0x04, 0x91, 0x19, 0x01, 0x01], [0xb4, 0x66, 0x04, 0x81, 0x6c, 0x0e, 0x07, 0x74]],
        [[0x01, 0x07, 0x94, 0x04, 0x91, 0x19, 0x04, 0x01], [0x6e, 0x7e, 0x62, 0x21, 0xa4, 0xf3, 0x4e, 0x87]],
        [[0x19, 0x07, 0x92, 0x10, 0x98, 0x1a, 0x01, 0x01], [0xaa, 0x85, 0xe7, 0x46, 0x43, 0x23, 0x31, 0x99]],
        [[0x10, 0x07, 0x91, 0x19, 0x98, 0x19, 0x08, 0x01], [0x2e, 0x5a, 0x19, 0xdb, 0x4d, 0x19, 0x62, 0xd6]],
        [[0x10, 0x07, 0x91, 0x19, 0x98, 0x1a, 0x08, 0x01], [0x23, 0xa8, 0x66, 0xa8, 0x09, 0xd3, 0x08, 0x94]],
        [[0x10, 0x07, 0x92, 0x10, 0x98, 0x19, 0x01, 0x01], [0xd8, 0x12, 0xd9, 0x61, 0xf0, 0x17, 0xd3, 0x20]],
        [[0x10, 0x07, 0x91, 0x15, 0x98, 0x19, 0x01, 0x0b], [0x05, 0x56, 0x05, 0x81, 0x6e, 0x58, 0x60, 0x8f]],
        [[0x10, 0x04, 0x80, 0x15, 0x98, 0x19, 0x01, 0x01], [0xab, 0xd8, 0x8e, 0x8b, 0x1b, 0x77, 0x16, 0xf1]],
        [[0x10, 0x04, 0x80, 0x15, 0x98, 0x19, 0x01, 0x02], [0x53, 0x7a, 0xc9, 0x5b, 0xe6, 0x9d, 0xa1, 0xe1]],
        [[0x10, 0x04, 0x80, 0x15, 0x98, 0x19, 0x01, 0x08], [0xae, 0xd0, 0xf6, 0xae, 0x3c, 0x25, 0xcd, 0xd8]],
        [[0x10, 0x02, 0x91, 0x14, 0x98, 0x10, 0x01, 0x04], [0xb3, 0xe3, 0x5a, 0x5e, 0xe5, 0x3e, 0x7b, 0x8d]],
        [[0x10, 0x02, 0x91, 0x15, 0x98, 0x19, 0x01, 0x04], [0x61, 0xc7, 0x9c, 0x71, 0x92, 0x1a, 0x2e, 0xf8]],
        [[0x10, 0x02, 0x91, 0x15, 0x98, 0x10, 0x02, 0x01], [0xe2, 0xf5, 0x72, 0x8f, 0x09, 0x95, 0x01, 0x3c]],
        [[0x10, 0x02, 0x91, 0x16, 0x98, 0x10, 0x01, 0x01], [0x1a, 0xea, 0xc3, 0x9a, 0x61, 0xf0, 0xa4, 0x64]],
    ];

    // Data permutation test.
    auto des = defaultAllocator.make!(DES!1);
    foreach (i; desTestVectors3)
    {
        auto cipher = Vector!ubyte(8);
        const plain = Vector!ubyte(8);
        auto key = Vector!ubyte(i[0]);
        des.key = key;

        des.encrypt(plain, cipher);
        assert(equal(cipher[], i[1][]));

    }
    defaultAllocator.dispose(des);
}

// S-Box test. Encrypt.
private unittest
{
    ubyte[8][3][19] desTestVectors4 = [
        [[0x7c, 0xa1, 0x10, 0x45, 0x4a, 0x1a, 0x6e, 0x57], [0x01, 0xa1, 0xd6, 0xd0, 0x39, 0x77, 0x67, 0x42],
        [0x69, 0x0f, 0x5b, 0x0d, 0x9a, 0x26, 0x93, 0x9b]],
        [[0x01, 0x31, 0xd9, 0x61, 0x9d, 0xc1, 0x37, 0x6e], [0x5c, 0xd5, 0x4c, 0xa8, 0x3d, 0xef, 0x57, 0xda],
        [0x7a, 0x38, 0x9d, 0x10, 0x35, 0x4b, 0xd2, 0x71]],
        [[0x07, 0xa1, 0x13, 0x3e, 0x4a, 0x0b, 0x26, 0x86], [0x02, 0x48, 0xd4, 0x38, 0x06, 0xf6, 0x71, 0x72],
        [0x86, 0x8e, 0xbb, 0x51, 0xca, 0xb4, 0x59, 0x9a]],
        [[0x38, 0x49, 0x67, 0x4c, 0x26, 0x02, 0x31, 0x9e], [0x51, 0x45, 0x4b, 0x58, 0x2d, 0xdf, 0x44, 0x0a],
        [0x71, 0x78, 0x87, 0x6e, 0x01, 0xf1, 0x9b, 0x2a]],
        [[0x04, 0xb9, 0x15, 0xba, 0x43, 0xfe, 0xb5, 0xb6], [0x42, 0xfd, 0x44, 0x30, 0x59, 0x57, 0x7f, 0xa2],
        [0xaf, 0x37, 0xfb, 0x42, 0x1f, 0x8c, 0x40, 0x95]],
        [[0x01, 0x13, 0xb9, 0x70, 0xfd, 0x34, 0xf2, 0xce], [0x05, 0x9b, 0x5e, 0x08, 0x51, 0xcf, 0x14, 0x3a],
        [0x86, 0xa5, 0x60, 0xf1, 0x0e, 0xc6, 0xd8, 0x5b]],
        [[0x01, 0x70, 0xf1, 0x75, 0x46, 0x8f, 0xb5, 0xe6], [0x07, 0x56, 0xd8, 0xe0, 0x77, 0x47, 0x61, 0xd2],
        [0x0c, 0xd3, 0xda, 0x02, 0x00, 0x21, 0xdc, 0x09]],
        [[0x43, 0x29, 0x7f, 0xad, 0x38, 0xe3, 0x73, 0xfe], [0x76, 0x25, 0x14, 0xb8, 0x29, 0xbf, 0x48, 0x6a],
        [0xea, 0x67, 0x6b, 0x2c, 0xb7, 0xdb, 0x2b, 0x7a]],
        [[0x07, 0xa7, 0x13, 0x70, 0x45, 0xda, 0x2a, 0x16], [0x3b, 0xdd, 0x11, 0x90, 0x49, 0x37, 0x28, 0x02],
        [0xdf, 0xd6, 0x4a, 0x81, 0x5c, 0xaf, 0x1a, 0x0f]],
        [[0x04, 0x68, 0x91, 0x04, 0xc2, 0xfd, 0x3b, 0x2f], [0x26, 0x95, 0x5f, 0x68, 0x35, 0xaf, 0x60, 0x9a],
        [0x5c, 0x51, 0x3c, 0x9c, 0x48, 0x86, 0xc0, 0x88]],
        [[0x37, 0xd0, 0x6b, 0xb5, 0x16, 0xcb, 0x75, 0x46], [0x16, 0x4d, 0x5e, 0x40, 0x4f, 0x27, 0x52, 0x32],
        [0x0a, 0x2a, 0xee, 0xae, 0x3f, 0xf4, 0xab, 0x77]],
        [[0x1f, 0x08, 0x26, 0x0d, 0x1a, 0xc2, 0x46, 0x5e], [0x6b, 0x05, 0x6e, 0x18, 0x75, 0x9f, 0x5c, 0xca],
        [0xef, 0x1b, 0xf0, 0x3e, 0x5d, 0xfa, 0x57, 0x5a]],
        [[0x58, 0x40, 0x23, 0x64, 0x1a, 0xba, 0x61, 0x76], [0x00, 0x4b, 0xd6, 0xef, 0x09, 0x17, 0x60, 0x62],
        [0x88, 0xbf, 0x0d, 0xb6, 0xd7, 0x0d, 0xee, 0x56]],
        [[0x02, 0x58, 0x16, 0x16, 0x46, 0x29, 0xb0, 0x07], [0x48, 0x0d, 0x39, 0x00, 0x6e, 0xe7, 0x62, 0xf2],
        [0xa1, 0xf9, 0x91, 0x55, 0x41, 0x02, 0x0b, 0x56]],
        [[0x49, 0x79, 0x3e, 0xbc, 0x79, 0xb3, 0x25, 0x8f], [0x43, 0x75, 0x40, 0xc8, 0x69, 0x8f, 0x3c, 0xfa],
        [0x6f, 0xbf, 0x1c, 0xaf, 0xcf, 0xfd, 0x05, 0x56]],
        [[0x4f, 0xb0, 0x5e, 0x15, 0x15, 0xab, 0x73, 0xa7], [0x07, 0x2d, 0x43, 0xa0, 0x77, 0x07, 0x52, 0x92],
        [0x2f, 0x22, 0xe4, 0x9b, 0xab, 0x7c, 0xa1, 0xac]],
        [[0x49, 0xe9, 0x5d, 0x6d, 0x4c, 0xa2, 0x29, 0xbf], [0x02, 0xfe, 0x55, 0x77, 0x81, 0x17, 0xf1, 0x2a],
        [0x5a, 0x6b, 0x61, 0x2c, 0xc2, 0x6c, 0xce, 0x4a]],
        [[0x01, 0x83, 0x10, 0xdc, 0x40, 0x9b, 0x26, 0xd6], [0x1d, 0x9d, 0x5c, 0x50, 0x18, 0xf7, 0x28, 0xc2],
        [0x5f, 0x4c, 0x03, 0x8e, 0xd1, 0x2b, 0x2e, 0x41]],
        [[0x1c, 0x58, 0x7f, 0x1c, 0x13, 0x92, 0x4f, 0xef], [0x30, 0x55, 0x32, 0x28, 0x6d, 0x6f, 0x29, 0x5a],
        [0x63, 0xfa, 0xc0, 0xd0, 0x34, 0xd9, 0xf7, 0x93]],
    ];

    // S-Box test.
    auto des = defaultAllocator.make!(DES!1);
    foreach (i; desTestVectors4)
    {
        auto cipher = Vector!ubyte(8);
        auto plain = Vector!ubyte(8);
        auto key = Vector!ubyte(i[0]);
        des.key = key;
        auto testVector = const Vector!ubyte(i[1]);

        des.encrypt(testVector, cipher);
        assert(equal(cipher[], i[2][]));

    }
    defaultAllocator.dispose(des);
}

/* Source:
   "Recommendation for the Triple Date Encryption Algorithm (TDEA) Block
   Cipher"
   NIST Special Publication 800-67, 2012. Appendix B */
private unittest
{
    auto key = Vector!ubyte(cast(ubyte[24]) [
        0x01, 0x23, 0x45, 0x67, 0x89, 0xab, 0xcd, 0xef,
        0x23, 0x45, 0x67, 0x89, 0xab, 0xcd, 0xef, 0x01,
        0x45, 0x67, 0x89, 0xab, 0xcd, 0xef, 0x01, 0x23,
    ]);
    auto actual = Vector!ubyte(8);
    auto des = defaultAllocator.make!(DES!3)(key);

    {
        auto plaintext = const Vector!ubyte([ 'T', 'h', 'e', ' ', 'q', 'u', 'f', 'c' ]);
        auto ciphertext = const Vector!ubyte(cast(ubyte[8]) [
            0xa8, 0x26, 0xfd, 0x8c, 0xe5, 0x3b, 0x85, 0x5f
        ]);

        des.encrypt(plaintext, actual);
        assert(actual == ciphertext);

        des.decrypt(ciphertext, actual);
        assert(actual == plaintext);
    }
    {
        auto plaintext = const Vector!ubyte([ 'k', ' ', 'b', 'r', 'o', 'w', 'n', ' ' ]);
        auto ciphertext = const Vector!ubyte(cast(ubyte[8]) [
            0xcc, 0xe2, 0x1c, 0x81, 0x12, 0x25, 0x6f, 0xe6
        ]);

        des.encrypt(plaintext, actual);
        assert(actual == ciphertext);

        des.decrypt(ciphertext, actual);
        assert(actual == plaintext);
    }
    {
        auto plaintext = const Vector!ubyte([ 'f', 'o', 'x', ' ', 'j', 'u', 'm', 'p' ]);
        auto ciphertext = const Vector!ubyte(cast(ubyte[8]) [
            0x68, 0xd5, 0xc0, 0x5d, 0xd9, 0xb6, 0xb9, 0x00
        ]);

        des.encrypt(plaintext, actual);
        assert(actual == ciphertext);

        des.decrypt(ciphertext, actual);
        assert(actual == plaintext);
    }

    defaultAllocator.dispose(des);
}
