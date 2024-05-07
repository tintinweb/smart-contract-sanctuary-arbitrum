/**
 *Submitted for verification at Arbiscan.io on 2024-05-07
*/

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;


// Library by https://github.com/0x10f/solidity-perlin-noise

/**
 * @notice An implementation of Perlin Noise that uses 16 bit fixed point arithmetic.
 * @notice Updated solidity version from 0.5.0 to 0.8.12.
 */

library PerlinNoise {

    /**
     * @notice Computes the noise value for a 2D point.
     *
     * @param x the x coordinate.
     * @param y the y coordinate.
     *
     * @dev This function should be kept public. Inlining the bytecode for this function
     *      into other functions could explode its compiled size because of how `ftable`
     *      and `ptable` were written.
     */
    function noise2d(int256 x, int256 y) public pure returns (int256) {
        int256 temp = ptable(x >> 16 & 0xff /* Unit square X */);

        int256 a = ptable((temp >> 8  ) + (y >> 16 & 0xff /* Unit square Y */));
        int256 b = ptable((temp & 0xff) + (y >> 16 & 0xff                    ));

        x &= 0xffff; // Square relative X
        y &= 0xffff; // Square relative Y

        int256 u = fade(x);

        int256 c = lerp(u, grad2(a >> 8  , x, y        ), grad2(b >> 8  , x-0x10000, y        ));
        int256 d = lerp(u, grad2(a & 0xff, x, y-0x10000), grad2(b & 0xff, x-0x10000, y-0x10000));

        return lerp(fade(y), c, d);
    }

    /**
     * @notice Computes the noise value for a 3D point.
     *
     * @param x the x coordinate.
     * @param y the y coordinate.
     * @param z the z coordinate.
     *
     * @dev This function should be kept public. Inlining the bytecode for this function
     *      into other functions could explode its compiled size because of how `ftable`
     *      and `ptable` were written.
     */
    function noise3d(int256 x, int256 y, int256 z) public pure returns (int256) {
        int256[7] memory scratch = [
            x >> 16 & 0xff,  // Unit cube X
            y >> 16 & 0xff,  // Unit cube Y
            z >> 16 & 0xff,  // Unit cube Z
            0, 0, 0, 0
        ];

        x &= 0xffff; // Cube relative X
        y &= 0xffff; // Cube relative Y
        z &= 0xffff; // Cube relative Z

        // Temporary variables used for intermediate calculations.
        int256 u;
        int256 v;

        v = ptable(scratch[0]);

        u = ptable((v >> 8  ) + scratch[1]);
        v = ptable((v & 0xff) + scratch[1]);

        scratch[3] = ptable((u >> 8  ) + scratch[2]);
        scratch[4] = ptable((u & 0xff) + scratch[2]);
        scratch[5] = ptable((v >> 8  ) + scratch[2]);
        scratch[6] = ptable((v & 0xff) + scratch[2]);

        int256 a;
        int256 b;
        int256 c;

        u = fade(x);
        v = fade(y);

        a = lerp(u, grad3(scratch[3] >> 8, x, y        , z), grad3(scratch[5] >> 8, x-0x10000, y        , z));
        b = lerp(u, grad3(scratch[4] >> 8, x, y-0x10000, z), grad3(scratch[6] >> 8, x-0x10000, y-0x10000, z));
        c = lerp(v, a, b);

        a = lerp(u, grad3(scratch[3] & 0xff, x, y        , z-0x10000), grad3(scratch[5] & 0xff, x-0x10000, y        , z-0x10000));
        b = lerp(u, grad3(scratch[4] & 0xff, x, y-0x10000, z-0x10000), grad3(scratch[6] & 0xff, x-0x10000, y-0x10000, z-0x10000));

        return lerp(fade(z), c, lerp(v, a, b));
    }

    /**
     * @notice Computes the linear interpolation between two values, `a` and `b`, using fixed point arithmetic.
     *
     * @param t the time value of the equation.
     * @param a the lower point.
     * @param b the upper point.
     */
    function lerp(int256 t, int256 a, int256 b) internal pure returns (int256) {
        return a + (t * (b - a) >> 12);
    }

    /**
     * @notice Applies the fade function to a value.
     *
     * @param t the time value of the equation.
     *
     * @dev The polynomial for this function is: 6t^4-15t^4+10t^3.
     */
    function fade(int256 t) internal pure returns (int256) {
        int256 n = ftable(t >> 8);

        // Lerp between the two points grabbed from the fade table.
        (int256 lower, int256 upper) = (n >> 12, n & 0xfff);
        return lower + ((t & 0xff) * (upper - lower) >> 8);
    }

    /**
      * @notice Computes the gradient value for a 2D point.
      *
      * @param h the hash value to use for picking the vector.
      * @param x the x coordinate of the point.
      * @param y the y coordinate of the point.
      */
    function grad2(int256 h, int256 x, int256 y) internal pure returns (int256) {
        h &= 3;

        int256 u;
        if (h & 0x1 == 0) {
            u = x;
        } else {
            u = -x;
        }

        int256 v;
        if (h < 2) {
            v = y;
        } else {
            v = -y;
        }

        return u + v;
    }

    /**
     * @notice Computes the gradient value for a 3D point.
     *
     * @param h the hash value to use for picking the vector.
     * @param x the x coordinate of the point.
     * @param y the y coordinate of the point.
     * @param z the z coordinate of the point.
     */
    function grad3(int256 h, int256 x, int256 y, int256 z) internal pure returns (int256) {
        h &= 0xf;

        int256 u;
        if (h < 8) {
            u = x;
        } else {
            u = y;
        }

        int256 v;
        if (h < 4) {
            v = y;
        } else if (h == 12 || h == 14) {
            v = x;
        } else {
            v = z;
        }

        if ((h & 0x1) != 0) {
            u = -u;
        }

        if ((h & 0x2) != 0) {
            v = -v;
        }

        return u + v;
    }

    /**
     * @notice Gets a subsequent values in the permutation table at an index. The values are encoded
     *         into a single 24 bit integer with the  value at the specified index being the most
     *         significant 12 bits and the subsequent value being the least significant 12 bits.
     *
     * @param i the index in the permutation table.
     *
     * @dev The values from the table are mapped out into a binary tree for faster lookups.
     *      Looking up any value in the table in this implementation is is O(8), in
     *      the implementation of sequential if statements it is O(255).
     *
     * @dev The body of this function is autogenerated. Check out the 'gen-ptable' script.
     */
    function ptable(int256 i) internal pure returns (int256) {
        i &= 0xff;

        if (i <= 127) {
            if (i <= 63) {
                if (i <= 31) {
                    if (i <= 15) {
                        if (i <= 7) {
                            if (i <= 3) {
                                if (i <= 1) {
                                    if (i == 0) { return 38816; } else { return 41097; }
                                } else {
                                    if (i == 2) { return 35163; } else { return 23386; }
                                }
                            } else {
                                if (i <= 5) {
                                    if (i == 4) { return 23055; } else { return 3971; }
                                } else {
                                    if (i == 6) { return 33549; } else { return 3529; }
                                }
                            }
                        } else {
                            if (i <= 11) {
                                if (i <= 9) {
                                    if (i == 8) { return 51551; } else { return 24416; }
                                } else {
                                    if (i == 10) { return 24629; } else { return 13762; }
                                }
                            } else {
                                if (i <= 13) {
                                    if (i == 12) { return 49897; } else { return 59655; }
                                } else {
                                    if (i == 14) { return 2017; } else { return 57740; }
                                }
                            }
                        }
                    } else {
                        if (i <= 23) {
                            if (i <= 19) {
                                if (i <= 17) {
                                    if (i == 16) { return 35876; } else { return 9319; }
                                } else {
                                    if (i == 18) { return 26398; } else { return 7749; }
                                }
                            } else {
                                if (i <= 21) {
                                    if (i == 20) { return 17806; } else { return 36360; }
                                } else {
                                    if (i == 22) { return 2147; } else { return 25381; }
                                }
                            }
                        } else {
                            if (i <= 27) {
                                if (i <= 25) {
                                    if (i == 24) { return 9712; } else { return 61461; }
                                } else {
                                    if (i == 26) { return 5386; } else { return 2583; }
                                }
                            } else {
                                if (i <= 29) {
                                    if (i == 28) { return 6078; } else { return 48646; }
                                } else {
                                    if (i == 30) { return 1684; } else { return 38135; }
                                }
                            }
                        }
                    }
                } else {
                    if (i <= 47) {
                        if (i <= 39) {
                            if (i <= 35) {
                                if (i <= 33) {
                                    if (i == 32) { return 63352; } else { return 30954; }
                                } else {
                                    if (i == 34) { return 59979; } else { return 19200; }
                                }
                            } else {
                                if (i <= 37) {
                                    if (i == 36) { return 26; } else { return 6853; }
                                } else {
                                    if (i == 38) { return 50494; } else { return 15966; }
                                }
                            }
                        } else {
                            if (i <= 43) {
                                if (i <= 41) {
                                    if (i == 40) { return 24316; } else { return 64731; }
                                } else {
                                    if (i == 42) { return 56267; } else { return 52085; }
                                }
                            } else {
                                if (i <= 45) {
                                    if (i == 44) { return 29987; } else { return 8971; }
                                } else {
                                    if (i == 46) { return 2848; } else { return 8249; }
                                }
                            }
                        }
                    } else {
                        if (i <= 55) {
                            if (i <= 51) {
                                if (i <= 49) {
                                    if (i == 48) { return 14769; } else { return 45345; }
                                } else {
                                    if (i == 50) { return 8536; } else { return 22765; }
                                }
                            } else {
                                if (i <= 53) {
                                    if (i == 52) { return 60821; } else { return 38200; }
                                } else {
                                    if (i == 54) { return 14423; } else { return 22446; }
                                }
                            }
                        } else {
                            if (i <= 59) {
                                if (i <= 57) {
                                    if (i == 56) { return 44564; } else { return 5245; }
                                } else {
                                    if (i == 58) { return 32136; } else { return 34987; }
                                }
                            } else {
                                if (i <= 61) {
                                    if (i == 60) { return 43944; } else { return 43076; }
                                } else {
                                    if (i == 62) { return 17583; } else { return 44874; }
                                }
                            }
                        }
                    }
                }
            } else {
                if (i <= 95) {
                    if (i <= 79) {
                        if (i <= 71) {
                            if (i <= 67) {
                                if (i <= 65) {
                                    if (i == 64) { return 19109; } else { return 42311; }
                                } else {
                                    if (i == 66) { return 18310; } else { return 34443; }
                                }
                            } else {
                                if (i <= 69) {
                                    if (i == 68) { return 35632; } else { return 12315; }
                                } else {
                                    if (i == 70) { return 7078; } else { return 42573; }
                                }
                            }
                        } else {
                            if (i <= 75) {
                                if (i <= 73) {
                                    if (i == 72) { return 19858; } else { return 37534; }
                                } else {
                                    if (i == 74) { return 40679; } else { return 59219; }
                                }
                            } else {
                                if (i <= 77) {
                                    if (i == 76) { return 21359; } else { return 28645; }
                                } else {
                                    if (i == 78) { return 58746; } else { return 31292; }
                                }
                            }
                        }
                    } else {
                        if (i <= 87) {
                            if (i <= 83) {
                                if (i <= 81) {
                                    if (i == 80) { return 15571; } else { return 54149; }
                                } else {
                                    if (i == 82) { return 34278; } else { return 59100; }
                                }
                            } else {
                                if (i <= 85) {
                                    if (i == 84) { return 56425; } else { return 26972; }
                                } else {
                                    if (i == 86) { return 23593; } else { return 10551; }
                                }
                            }
                        } else {
                            if (i <= 91) {
                                if (i <= 89) {
                                    if (i == 88) { return 14126; } else { return 12021; }
                                } else {
                                    if (i == 90) { return 62760; } else { return 10484; }
                                }
                            } else {
                                if (i <= 93) {
                                    if (i == 92) { return 62566; } else { return 26255; }
                                } else {
                                    if (i == 94) { return 36662; } else { return 13889; }
                                }
                            }
                        }
                    }
                } else {
                    if (i <= 111) {
                        if (i <= 103) {
                            if (i <= 99) {
                                if (i <= 97) {
                                    if (i == 96) { return 16665; } else { return 6463; }
                                } else {
                                    if (i == 98) { return 16289; } else { return 41217; }
                                }
                            } else {
                                if (i <= 101) {
                                    if (i == 100) { return 472; } else { return 55376; }
                                } else {
                                    if (i == 102) { return 20553; } else { return 18897; }
                                }
                            }
                        } else {
                            if (i <= 107) {
                                if (i <= 105) {
                                    if (i == 104) { return 53580; } else { return 19588; }
                                } else {
                                    if (i == 106) { return 33979; } else { return 48080; }
                                }
                            } else {
                                if (i <= 109) {
                                    if (i == 108) { return 53337; } else { return 22802; }
                                } else {
                                    if (i == 110) { return 4777; } else { return 43464; }
                                }
                            }
                        }
                    } else {
                        if (i <= 119) {
                            if (i <= 115) {
                                if (i <= 113) {
                                    if (i == 112) { return 51396; } else { return 50311; }
                                } else {
                                    if (i == 114) { return 34690; } else { return 33396; }
                                }
                            } else {
                                if (i <= 117) {
                                    if (i == 116) { return 29884; } else { return 48287; }
                                } else {
                                    if (i == 118) { return 40790; } else { return 22180; }
                                }
                            }
                        } else {
                            if (i <= 123) {
                                if (i <= 121) {
                                    if (i == 120) { return 42084; } else { return 25709; }
                                } else {
                                    if (i == 122) { return 28102; } else { return 50861; }
                                }
                            } else {
                                if (i <= 125) {
                                    if (i == 124) { return 44474; } else { return 47619; }
                                } else {
                                    if (i == 126) { return 832; } else { return 16436; }
                                }
                            }
                        }
                    }
                }
            }
        } else {
            if (i <= 191) {
                if (i <= 159) {
                    if (i <= 143) {
                        if (i <= 135) {
                            if (i <= 131) {
                                if (i <= 129) {
                                    if (i == 128) { return 13529; } else { return 55778; }
                                } else {
                                    if (i == 130) { return 58106; } else { return 64124; }
                                }
                            } else {
                                if (i <= 133) {
                                    if (i == 132) { return 31867; } else { return 31493; }
                                } else {
                                    if (i == 134) { return 1482; } else { return 51750; }
                                }
                            }
                        } else {
                            if (i <= 139) {
                                if (i <= 137) {
                                    if (i == 136) { return 9875; } else { return 37750; }
                                } else {
                                    if (i == 138) { return 30334; } else { return 32511; }
                                }
                            } else {
                                if (i <= 141) {
                                    if (i == 140) { return 65362; } else { return 21077; }
                                } else {
                                    if (i == 142) { return 21972; } else { return 54479; }
                                }
                            }
                        }
                    } else {
                        if (i <= 151) {
                            if (i <= 147) {
                                if (i <= 145) {
                                    if (i == 144) { return 53198; } else { return 52795; }
                                } else {
                                    if (i == 146) { return 15331; } else { return 58159; }
                                }
                            } else {
                                if (i <= 149) {
                                    if (i == 148) { return 12048; } else { return 4154; }
                                } else {
                                    if (i == 150) { return 14865; } else { return 4534; }
                                }
                            }
                        } else {
                            if (i <= 155) {
                                if (i <= 153) {
                                    if (i == 152) { return 46781; } else { return 48412; }
                                } else {
                                    if (i == 154) { return 7210; } else { return 10975; }
                                }
                            } else {
                                if (i <= 157) {
                                    if (i == 156) { return 57271; } else { return 47018; }
                                } else {
                                    if (i == 158) { return 43733; } else { return 54647; }
                                }
                            }
                        }
                    }
                } else {
                    if (i <= 175) {
                        if (i <= 167) {
                            if (i <= 163) {
                                if (i <= 161) {
                                    if (i == 160) { return 30712; } else { return 63640; }
                                } else {
                                    if (i == 162) { return 38914; } else { return 556; }
                                }
                            } else {
                                if (i <= 165) {
                                    if (i == 164) { return 11418; } else { return 39587; }
                                } else {
                                    if (i == 166) { return 41798; } else { return 18141; }
                                }
                            }
                        } else {
                            if (i <= 171) {
                                if (i <= 169) {
                                    if (i == 168) { return 56729; } else { return 39269; }
                                } else {
                                    if (i == 170) { return 26011; } else { return 39847; }
                                }
                            } else {
                                if (i <= 173) {
                                    if (i == 172) { return 42795; } else { return 11180; }
                                } else {
                                    if (i == 174) { return 44041; } else { return 2433; }
                                }
                            }
                        }
                    } else {
                        if (i <= 183) {
                            if (i <= 179) {
                                if (i <= 177) {
                                    if (i == 176) { return 33046; } else { return 5671; }
                                } else {
                                    if (i == 178) { return 10237; } else { return 64787; }
                                }
                            } else {
                                if (i <= 181) {
                                    if (i == 180) { return 4962; } else { return 25196; }
                                } else {
                                    if (i == 182) { return 27758; } else { return 28239; }
                                }
                            }
                        } else {
                            if (i <= 187) {
                                if (i <= 185) {
                                    if (i == 184) { return 20337; } else { return 29152; }
                                } else {
                                    if (i == 186) { return 57576; } else { return 59570; }
                                }
                            } else {
                                if (i <= 189) {
                                    if (i == 188) { return 45753; } else { return 47472; }
                                } else {
                                    if (i == 190) { return 28776; } else { return 26842; }
                                }
                            }
                        }
                    }
                }
            } else {
                if (i <= 223) {
                    if (i <= 207) {
                        if (i <= 199) {
                            if (i <= 195) {
                                if (i <= 193) {
                                    if (i == 192) { return 56054; } else { return 63073; }
                                } else {
                                    if (i == 194) { return 25060; } else { return 58619; }
                                }
                            } else {
                                if (i <= 197) {
                                    if (i == 196) { return 64290; } else { return 8946; }
                                } else {
                                    if (i == 198) { return 62145; } else { return 49646; }
                                }
                            }
                        } else {
                            if (i <= 203) {
                                if (i <= 201) {
                                    if (i == 200) { return 61138; } else { return 53904; }
                                } else {
                                    if (i == 202) { return 36876; } else { return 3263; }
                                }
                            } else {
                                if (i <= 205) {
                                    if (i == 204) { return 49075; } else { return 45986; }
                                } else {
                                    if (i == 206) { return 41713; } else { return 61777; }
                                }
                            }
                        }
                    } else {
                        if (i <= 215) {
                            if (i <= 211) {
                                if (i <= 209) {
                                    if (i == 208) { return 20787; } else { return 13201; }
                                } else {
                                    if (i == 210) { return 37355; } else { return 60409; }
                                }
                            } else {
                                if (i <= 213) {
                                    if (i == 212) { return 63758; } else { return 3823; }
                                } else {
                                    if (i == 214) { return 61291; } else { return 27441; }
                                }
                            }
                        } else {
                            if (i <= 219) {
                                if (i <= 217) {
                                    if (i == 216) { return 12736; } else { return 49366; }
                                } else {
                                    if (i == 218) { return 54815; } else { return 8117; }
                                }
                            } else {
                                if (i <= 221) {
                                    if (i == 220) { return 46535; } else { return 51050; }
                                } else {
                                    if (i == 222) { return 27293; } else { return 40376; }
                                }
                            }
                        }
                    }
                } else {
                    if (i <= 239) {
                        if (i <= 231) {
                            if (i <= 227) {
                                if (i <= 225) {
                                    if (i == 224) { return 47188; } else { return 21708; }
                                } else {
                                    if (i == 226) { return 52400; } else { return 45171; }
                                }
                            } else {
                                if (i <= 229) {
                                    if (i == 228) { return 29561; } else { return 31026; }
                                } else {
                                    if (i == 230) { return 12845; } else { return 11647; }
                                }
                            }
                        } else {
                            if (i <= 235) {
                                if (i <= 233) {
                                    if (i == 232) { return 32516; } else { return 1174; }
                                } else {
                                    if (i == 234) { return 38654; } else { return 65162; }
                                }
                            } else {
                                if (i <= 237) {
                                    if (i == 236) { return 35564; } else { return 60621; }
                                } else {
                                    if (i == 238) { return 52573; } else { return 24030; }
                                }
                            }
                        }
                    } else {
                        if (i <= 247) {
                            if (i <= 243) {
                                if (i <= 241) {
                                    if (i == 240) { return 56946; } else { return 29251; }
                                } else {
                                    if (i == 242) { return 17181; } else { return 7448; }
                                }
                            } else {
                                if (i <= 245) {
                                    if (i == 244) { return 6216; } else { return 18675; }
                                } else {
                                    if (i == 246) { return 62349; } else { return 36224; }
                                }
                            }
                        } else {
                            if (i <= 251) {
                                if (i <= 249) {
                                    if (i == 248) { return 32963; } else { return 49998; }
                                } else {
                                    if (i == 250) { return 20034; } else { return 17111; }
                                }
                            } else {
                                if (i <= 253) {
                                    if (i == 252) { return 55101; } else { return 15772; }
                                } else {
                                    if (i == 254) { return 40116; } else { return 46231; }
                                }
                            }
                        }
                    }
                }
            }
        }

    }

    /**
     * @notice Gets subsequent values in the fade table at an index. The values are encoded
     *         into a single 16 bit integer with the value at the specified index being the most
     *         significant 8 bits and the subsequent value being the least significant 8 bits.
     *
     * @param i the index in the fade table.
     *
     * @dev The values from the table are mapped out into a binary tree for faster lookups.
     *      Looking up any value in the table in this implementation is is O(8), in
     *      the implementation of sequential if statements it is O(256).
     *
     * @dev The body of this function is autogenerated. Check out the 'gen-ftable' script.
     */
    function ftable(int256 i) internal pure returns (int256) {
        if (i <= 127) {
            if (i <= 63) {
                if (i <= 31) {
                    if (i <= 15) {
                        if (i <= 7) {
                            if (i <= 3) {
                                if (i <= 1) {
                                    if (i == 0) { return 0; } else { return 0; }
                                } else {
                                    if (i == 2) { return 0; } else { return 0; }
                                }
                            } else {
                                if (i <= 5) {
                                    if (i == 4) { return 0; } else { return 0; }
                                } else {
                                    if (i == 6) { return 0; } else { return 1; }
                                }
                            }
                        } else {
                            if (i <= 11) {
                                if (i <= 9) {
                                    if (i == 8) { return 4097; } else { return 4098; }
                                } else {
                                    if (i == 10) { return 8195; } else { return 12291; }
                                }
                            } else {
                                if (i <= 13) {
                                    if (i == 12) { return 12292; } else { return 16390; }
                                } else {
                                    if (i == 14) { return 24583; } else { return 28681; }
                                }
                            }
                        }
                    } else {
                        if (i <= 23) {
                            if (i <= 19) {
                                if (i <= 17) {
                                    if (i == 16) { return 36874; } else { return 40972; }
                                } else {
                                    if (i == 18) { return 49166; } else { return 57361; }
                                }
                            } else {
                                if (i <= 21) {
                                    if (i == 20) { return 69651; } else { return 77846; }
                                } else {
                                    if (i == 22) { return 90137; } else { return 102429; }
                                }
                            }
                        } else {
                            if (i <= 27) {
                                if (i <= 25) {
                                    if (i == 24) { return 118816; } else { return 131108; }
                                } else {
                                    if (i == 26) { return 147496; } else { return 163885; }
                                }
                            } else {
                                if (i <= 29) {
                                    if (i == 28) { return 184369; } else { return 200758; }
                                } else {
                                    if (i == 30) { return 221244; } else { return 245825; }
                                }
                            }
                        }
                    }
                } else {
                    if (i <= 47) {
                        if (i <= 39) {
                            if (i <= 35) {
                                if (i <= 33) {
                                    if (i == 32) { return 266311; } else { return 290893; }
                                } else {
                                    if (i == 34) { return 315476; } else { return 344155; }
                                }
                            } else {
                                if (i <= 37) {
                                    if (i == 36) { return 372834; } else { return 401513; }
                                } else {
                                    if (i == 38) { return 430193; } else { return 462969; }
                                }
                            }
                        } else {
                            if (i <= 43) {
                                if (i <= 41) {
                                    if (i == 40) { return 495746; } else { return 532619; }
                                } else {
                                    if (i == 42) { return 569492; } else { return 606366; }
                                }
                            } else {
                                if (i <= 45) {
                                    if (i == 44) { return 647335; } else { return 684210; }
                                } else {
                                    if (i == 46) { return 729276; } else { return 770247; }
                                }
                            }
                        }
                    } else {
                        if (i <= 55) {
                            if (i <= 51) {
                                if (i <= 49) {
                                    if (i == 48) { return 815315; } else { return 864478; }
                                } else {
                                    if (i == 50) { return 909546; } else { return 958711; }
                                }
                            } else {
                                if (i <= 53) {
                                    if (i == 52) { return 1011971; } else { return 1061137; }
                                } else {
                                    if (i == 54) { return 1118494; } else { return 1171756; }
                                }
                            }
                        } else {
                            if (i <= 59) {
                                if (i <= 57) {
                                    if (i == 56) { return 1229114; } else { return 1286473; }
                                } else {
                                    if (i == 58) { return 1347928; } else { return 1409383; }
                                }
                            } else {
                                if (i <= 61) {
                                    if (i == 60) { return 1470838; } else { return 1532294; }
                                } else {
                                    if (i == 62) { return 1597847; } else { return 1667496; }
                                }
                            }
                        }
                    }
                }
            } else {
                if (i <= 95) {
                    if (i <= 79) {
                        if (i <= 71) {
                            if (i <= 67) {
                                if (i <= 65) {
                                    if (i == 64) { return 1737145; } else { return 1806794; }
                                } else {
                                    if (i == 66) { return 1876444; } else { return 1950190; }
                                }
                            } else {
                                if (i <= 69) {
                                    if (i == 68) { return 2023936; } else { return 2097683; }
                                } else {
                                    if (i == 70) { return 2175526; } else { return 2253370; }
                                }
                            }
                        } else {
                            if (i <= 75) {
                                if (i <= 73) {
                                    if (i == 72) { return 2335309; } else { return 2413153; }
                                } else {
                                    if (i == 74) { return 2495094; } else { return 2581131; }
                                }
                            } else {
                                if (i <= 77) {
                                    if (i == 76) { return 2667168; } else { return 2753205; }
                                } else {
                                    if (i == 78) { return 2839243; } else { return 2929377; }
                                }
                            }
                        }
                    } else {
                        if (i <= 87) {
                            if (i <= 83) {
                                if (i <= 81) {
                                    if (i == 80) { return 3019511; } else { return 3109646; }
                                } else {
                                    if (i == 82) { return 3203877; } else { return 3298108; }
                                }
                            } else {
                                if (i <= 85) {
                                    if (i == 84) { return 3392339; } else { return 3486571; }
                                } else {
                                    if (i == 86) { return 3584899; } else { return 3683227; }
                                }
                            }
                        } else {
                            if (i <= 91) {
                                if (i <= 89) {
                                    if (i == 88) { return 3781556; } else { return 3883981; }
                                } else {
                                    if (i == 90) { return 3986406; } else { return 4088831; }
                                }
                            } else {
                                if (i <= 93) {
                                    if (i == 92) { return 4191257; } else { return 4297778; }
                                } else {
                                    if (i == 94) { return 4400204; } else { return 4506727; }
                                }
                            }
                        }
                    }
                } else {
                    if (i <= 111) {
                        if (i <= 103) {
                            if (i <= 99) {
                                if (i <= 97) {
                                    if (i == 96) { return 4617345; } else { return 4723868; }
                                } else {
                                    if (i == 98) { return 4834487; } else { return 4945106; }
                                }
                            } else {
                                if (i <= 101) {
                                    if (i == 100) { return 5055725; } else { return 5166345; }
                                } else {
                                    if (i == 102) { return 5281060; } else { return 5391680; }
                                }
                            }
                        } else {
                            if (i <= 107) {
                                if (i <= 105) {
                                    if (i == 104) { return 5506396; } else { return 5621112; }
                                } else {
                                    if (i == 106) { return 5735829; } else { return 5854641; }
                                }
                            } else {
                                if (i <= 109) {
                                    if (i == 108) { return 5969358; } else { return 6088171; }
                                } else {
                                    if (i == 110) { return 6206983; } else { return 6321700; }
                                }
                            }
                        }
                    } else {
                        if (i <= 119) {
                            if (i <= 115) {
                                if (i <= 113) {
                                    if (i == 112) { return 6440514; } else { return 6563423; }
                                } else {
                                    if (i == 114) { return 6682236; } else { return 6801050; }
                                }
                            } else {
                                if (i <= 117) {
                                    if (i == 116) { return 6923959; } else { return 7042773; }
                                } else {
                                    if (i == 118) { return 7165682; } else { return 7284496; }
                                }
                            }
                        } else {
                            if (i <= 123) {
                                if (i <= 121) {
                                    if (i == 120) { return 7407406; } else { return 7530316; }
                                } else {
                                    if (i == 122) { return 7653226; } else { return 7776136; }
                                }
                            } else {
                                if (i <= 125) {
                                    if (i == 124) { return 7899046; } else { return 8021956; }
                                } else {
                                    if (i == 126) { return 8144866; } else { return 8267776; }
                                }
                            }
                        }
                    }
                }
            }
        } else {
            if (i <= 191) {
                if (i <= 159) {
                    if (i <= 143) {
                        if (i <= 135) {
                            if (i <= 131) {
                                if (i <= 129) {
                                    if (i == 128) { return 8390685; } else { return 8509499; }
                                } else {
                                    if (i == 130) { return 8632409; } else { return 8755319; }
                                }
                            } else {
                                if (i <= 133) {
                                    if (i == 132) { return 8878229; } else { return 9001139; }
                                } else {
                                    if (i == 134) { return 9124049; } else { return 9246959; }
                                }
                            }
                        } else {
                            if (i <= 139) {
                                if (i <= 137) {
                                    if (i == 136) { return 9369869; } else { return 9492778; }
                                } else {
                                    if (i == 138) { return 9611592; } else { return 9734501; }
                                }
                            } else {
                                if (i <= 141) {
                                    if (i == 140) { return 9853315; } else { return 9976224; }
                                } else {
                                    if (i == 142) { return 10095037; } else { return 10213851; }
                                }
                            }
                        }
                    } else {
                        if (i <= 151) {
                            if (i <= 147) {
                                if (i <= 145) {
                                    if (i == 144) { return 10336760; } else { return 10455572; }
                                } else {
                                    if (i == 146) { return 10570289; } else { return 10689102; }
                                }
                            } else {
                                if (i <= 149) {
                                    if (i == 148) { return 10807914; } else { return 10922631; }
                                } else {
                                    if (i == 150) { return 11041443; } else { return 11156159; }
                                }
                            }
                        } else {
                            if (i <= 155) {
                                if (i <= 153) {
                                    if (i == 152) { return 11270875; } else { return 11385590; }
                                } else {
                                    if (i == 154) { return 11496210; } else { return 11610925; }
                                }
                            } else {
                                if (i <= 157) {
                                    if (i == 156) { return 11721544; } else { return 11832163; }
                                } else {
                                    if (i == 158) { return 11942782; } else { return 12053400; }
                                }
                            }
                        }
                    }
                } else {
                    if (i <= 175) {
                        if (i <= 167) {
                            if (i <= 163) {
                                if (i <= 161) {
                                    if (i == 160) { return 12159923; } else { return 12270541; }
                                } else {
                                    if (i == 162) { return 12377062; } else { return 12479488; }
                                }
                            } else {
                                if (i <= 165) {
                                    if (i == 164) { return 12586009; } else { return 12688434; }
                                } else {
                                    if (i == 166) { return 12790859; } else { return 12893284; }
                                }
                            }
                        } else {
                            if (i <= 171) {
                                if (i <= 169) {
                                    if (i == 168) { return 12995708; } else { return 13094036; }
                                } else {
                                    if (i == 170) { return 13192364; } else { return 13290691; }
                                }
                            } else {
                                if (i <= 173) {
                                    if (i == 172) { return 13384922; } else { return 13479153; }
                                } else {
                                    if (i == 174) { return 13573384; } else { return 13667614; }
                                }
                            }
                        }
                    } else {
                        if (i <= 183) {
                            if (i <= 179) {
                                if (i <= 177) {
                                    if (i == 176) { return 13757748; } else { return 13847882; }
                                } else {
                                    if (i == 178) { return 13938015; } else { return 14024052; }
                                }
                            } else {
                                if (i <= 181) {
                                    if (i == 180) { return 14110089; } else { return 14196126; }
                                } else {
                                    if (i == 182) { return 14282162; } else { return 14364101; }
                                }
                            }
                        } else {
                            if (i <= 187) {
                                if (i <= 185) {
                                    if (i == 184) { return 14441945; } else { return 14523884; }
                                } else {
                                    if (i == 186) { return 14601727; } else { return 14679569; }
                                }
                            } else {
                                if (i <= 189) {
                                    if (i == 188) { return 14753315; } else { return 14827061; }
                                } else {
                                    if (i == 190) { return 14900806; } else { return 14970456; }
                                }
                            }
                        }
                    }
                }
            } else {
                if (i <= 223) {
                    if (i <= 207) {
                        if (i <= 199) {
                            if (i <= 195) {
                                if (i <= 193) {
                                    if (i == 192) { return 15044200; } else { return 15109753; }
                                } else {
                                    if (i == 194) { return 15179401; } else { return 15244952; }
                                }
                            } else {
                                if (i <= 197) {
                                    if (i == 196) { return 15306407; } else { return 15367862; }
                                } else {
                                    if (i == 198) { return 15429317; } else { return 15490771; }
                                }
                            }
                        } else {
                            if (i <= 203) {
                                if (i <= 201) {
                                    if (i == 200) { return 15548129; } else { return 15605486; }
                                } else {
                                    if (i == 202) { return 15658748; } else { return 15716104; }
                                }
                            } else {
                                if (i <= 205) {
                                    if (i == 204) { return 15765269; } else { return 15818529; }
                                } else {
                                    if (i == 206) { return 15867692; } else { return 15912760; }
                                }
                            }
                        }
                    } else {
                        if (i <= 215) {
                            if (i <= 211) {
                                if (i <= 209) {
                                    if (i == 208) { return 15961923; } else { return 16006989; }
                                } else {
                                    if (i == 210) { return 16047960; } else { return 16093025; }
                                }
                            } else {
                                if (i <= 213) {
                                    if (i == 212) { return 16129899; } else { return 16170868; }
                                } else {
                                    if (i == 214) { return 16207741; } else { return 16244614; }
                                }
                            }
                        } else {
                            if (i <= 219) {
                                if (i <= 217) {
                                    if (i == 216) { return 16281486; } else { return 16314262; }
                                } else {
                                    if (i == 218) { return 16347037; } else { return 16375716; }
                                }
                            } else {
                                if (i <= 221) {
                                    if (i == 220) { return 16404395; } else { return 16433074; }
                                } else {
                                    if (i == 222) { return 16461752; } else { return 16486334; }
                                }
                            }
                        }
                    }
                } else {
                    if (i <= 239) {
                        if (i <= 231) {
                            if (i <= 227) {
                                if (i <= 225) {
                                    if (i == 224) { return 16510915; } else { return 16531401; }
                                } else {
                                    if (i == 226) { return 16555982; } else { return 16576466; }
                                }
                            } else {
                                if (i <= 229) {
                                    if (i == 228) { return 16592855; } else { return 16613339; }
                                } else {
                                    if (i == 230) { return 16629727; } else { return 16646114; }
                                }
                            }
                        } else {
                            if (i <= 235) {
                                if (i <= 233) {
                                    if (i == 232) { return 16658406; } else { return 16674793; }
                                } else {
                                    if (i == 234) { return 16687084; } else { return 16699374; }
                                }
                            } else {
                                if (i <= 237) {
                                    if (i == 236) { return 16707569; } else { return 16719859; }
                                } else {
                                    if (i == 238) { return 16728053; } else { return 16736246; }
                                }
                            }
                        }
                    } else {
                        if (i <= 247) {
                            if (i <= 243) {
                                if (i <= 241) {
                                    if (i == 240) { return 16740344; } else { return 16748537; }
                                } else {
                                    if (i == 242) { return 16752635; } else { return 16760828; }
                                }
                            } else {
                                if (i <= 245) {
                                    if (i == 244) { return 16764924; } else { return 16764925; }
                                } else {
                                    if (i == 246) { return 16769022; } else { return 16773118; }
                                }
                            }
                        } else {
                            if (i <= 251) {
                                if (i <= 249) {
                                    if (i == 248) { return 16773119; } else { return 16777215; }
                                } else {
                                    if (i == 250) { return 16777215; } else { return 16777215; }
                                }
                            } else {
                                if (i <= 253) {
                                    if (i == 252) { return 16777215; } else { return 16777215; }
                                } else {
                                    if (i == 254) { return 16777215; } else { return 16777215; }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}




library Trig {

/*---
Trigonometry - Implementation 1
---*/

// Implementation 1 requires wrapping inputs between 2 * PI and 4 * PI to avoid precision errors, but it is more accurate than Implementation 2.

/*
 * Implementation by Matt Solomon, found here: https://github.com/mds1/solidity-trigonometry
 *
 * Solidity library offering basic trigonometry functions where inputs and outputs are
 * integers. Inputs are specified in radians scaled by 1e18, and similarly outputs are scaled by 1e18.
 *
 * This implementation is based off the Solidity trigonometry library written by Lefteris Karapetsas
 * which can be found here: https://github.com/Sikorkaio/sikorka/blob/e75c91925c914beaedf4841c0336a806f2b5f66d/contracts/trigonometry.sol
 *
 * Compared to Lefteris' implementation, this version makes the following changes:
 *   - Uses a 32 bits instead of 16 bits for improved accuracy
 *   - Updated for Solidity 0.8.x
 *   - Various gas optimizations
 *   - Change inputs/outputs to standard trig format (scaled by 1e18) instead of requiring the
 *     integer format used by the algorithm
 *
 * Lefertis' implementation is based off Dave Dribin's trigint C library
 *     http://www.dribin.org/dave/trigint/
 *
 * Which in turn is based from a now deleted article which can be found in the Wayback Machine:
 *     http://web.archive.org/web/20120301144605/http://www.dattalo.com/technical/software/pic/picsine.html
 */

  // Table index into the trigonometric table
  uint256 constant INDEX_WIDTH        = 8;
  // Interpolation between successive entries in the table
  uint256 constant INTERP_WIDTH       = 16;
  uint256 constant INDEX_OFFSET       = 28 - INDEX_WIDTH;
  uint256 constant INTERP_OFFSET      = INDEX_OFFSET - INTERP_WIDTH;
  uint32  constant ANGLES_IN_CYCLE    = 1073741824;
  uint32  constant QUADRANT_HIGH_MASK = 536870912;
  uint32  constant QUADRANT_LOW_MASK  = 268435456;
  uint256 constant SINE_TABLE_SIZE    = 256;

  // Pi as an 18 decimal value, which is plenty of accuracy: "For JPL's highest accuracy calculations, which are for
  // interplanetary navigation, we use 3.141592653589793: https://www.jpl.nasa.gov/edu/news/2016/3/16/how-many-decimals-of-pi-do-we-really-need/
  uint256 constant PI          = 3141592653589793238;
  uint256 constant TWO_PI      = 2 * PI;
  uint256 constant PI_OVER_TWO = PI / 2;

  // The constant sine lookup table was generated by generate_trigonometry.py. We must use a constant
  // bytes array because constant arrays are not supported in Solidity. Each entry in the lookup
  // table is 4 bytes. Since we're using 32-bit parameters for the lookup table, we get a table size
  // of 2^(32/4) + 1 = 257, where the first and last entries are equivalent (hence the table size of
  // 256 defined above)
  uint8   constant entry_bytes = 4; // each entry in the lookup table is 4 bytes
  uint256 constant entry_mask  = ((1 << 8*entry_bytes) - 1); // mask used to cast bytes32 -> lookup table entry
  bytes   constant sin_table   = hex"00_00_00_00_00_c9_0f_88_01_92_1d_20_02_5b_26_d7_03_24_2a_bf_03_ed_26_e6_04_b6_19_5d_05_7f_00_35_06_47_d9_7c_07_10_a3_45_07_d9_5b_9e_08_a2_00_9a_09_6a_90_49_0a_33_08_bc_0a_fb_68_05_0b_c3_ac_35_0c_8b_d3_5e_0d_53_db_92_0e_1b_c2_e4_0e_e3_87_66_0f_ab_27_2b_10_72_a0_48_11_39_f0_cf_12_01_16_d5_12_c8_10_6e_13_8e_db_b1_14_55_76_b1_15_1b_df_85_15_e2_14_44_16_a8_13_05_17_6d_d9_de_18_33_66_e8_18_f8_b8_3c_19_bd_cb_f3_1a_82_a0_25_1b_47_32_ef_1c_0b_82_6a_1c_cf_8c_b3_1d_93_4f_e5_1e_56_ca_1e_1f_19_f9_7b_1f_dc_dc_1b_20_9f_70_1c_21_61_b3_9f_22_23_a4_c5_22_e5_41_af_23_a6_88_7e_24_67_77_57_25_28_0c_5d_25_e8_45_b6_26_a8_21_85_27_67_9d_f4_28_26_b9_28_28_e5_71_4a_29_a3_c4_85_2a_61_b1_01_2b_1f_34_eb_2b_dc_4e_6f_2c_98_fb_ba_2d_55_3a_fb_2e_11_0a_62_2e_cc_68_1e_2f_87_52_62_30_41_c7_60_30_fb_c5_4d_31_b5_4a_5d_32_6e_54_c7_33_26_e2_c2_33_de_f2_87_34_96_82_4f_35_4d_90_56_36_04_1a_d9_36_ba_20_13_37_6f_9e_46_38_24_93_b0_38_d8_fe_93_39_8c_dd_32_3a_40_2d_d1_3a_f2_ee_b7_3b_a5_1e_29_3c_56_ba_70_3d_07_c1_d5_3d_b8_32_a5_3e_68_0b_2c_3f_17_49_b7_3f_c5_ec_97_40_73_f2_1d_41_21_58_9a_41_ce_1e_64_42_7a_41_d0_43_25_c1_35_43_d0_9a_ec_44_7a_cd_50_45_24_56_bc_45_cd_35_8f_46_75_68_27_47_1c_ec_e6_47_c3_c2_2e_48_69_e6_64_49_0f_57_ee_49_b4_15_33_4a_58_1c_9d_4a_fb_6c_97_4b_9e_03_8f_4c_3f_df_f3_4c_e1_00_34_4d_81_62_c3_4e_21_06_17_4e_bf_e8_a4_4f_5e_08_e2_4f_fb_65_4c_50_97_fc_5e_51_33_cc_94_51_ce_d4_6e_52_69_12_6e_53_02_85_17_53_9b_2a_ef_54_33_02_7d_54_ca_0a_4a_55_60_40_e2_55_f5_a4_d2_56_8a_34_a9_57_1d_ee_f9_57_b0_d2_55_58_42_dd_54_58_d4_0e_8c_59_64_64_97_59_f3_de_12_5a_82_79_99_5b_10_35_ce_5b_9d_11_53_5c_29_0a_cc_5c_b4_20_df_5d_3e_52_36_5d_c7_9d_7b_5e_50_01_5d_5e_d7_7c_89_5f_5e_0d_b2_5f_e3_b3_8d_60_68_6c_ce_60_ec_38_2f_61_6f_14_6b_61_f1_00_3e_62_71_fa_68_62_f2_01_ac_63_71_14_cc_63_ef_32_8f_64_6c_59_bf_64_e8_89_25_65_63_bf_91_65_dd_fb_d2_66_57_3c_bb_66_cf_81_1f_67_46_c7_d7_67_bd_0f_bc_68_32_57_aa_68_a6_9e_80_69_19_e3_1f_69_8c_24_6b_69_fd_61_4a_6a_6d_98_a3_6a_dc_c9_64_6b_4a_f2_78_6b_b8_12_d0_6c_24_29_5f_6c_8f_35_1b_6c_f9_34_fb_6d_62_27_f9_6d_ca_0d_14_6e_30_e3_49_6e_96_a9_9c_6e_fb_5f_11_6f_5f_02_b1_6f_c1_93_84_70_23_10_99_70_83_78_fe_70_e2_cb_c5_71_41_08_04_71_9e_2c_d1_71_fa_39_48_72_55_2c_84_72_af_05_a6_73_07_c3_cf_73_5f_66_25_73_b5_eb_d0_74_0b_53_fa_74_5f_9d_d0_74_b2_c8_83_75_04_d3_44_75_55_bd_4b_75_a5_85_ce_75_f4_2c_0a_76_41_af_3c_76_8e_0e_a5_76_d9_49_88_77_23_5f_2c_77_6c_4e_da_77_b4_17_df_77_fa_b9_88_78_40_33_28_78_84_84_13_78_c7_ab_a1_79_09_a9_2c_79_4a_7c_11_79_8a_23_b0_79_c8_9f_6d_7a_05_ee_ac_7a_42_10_d8_7a_7d_05_5a_7a_b6_cb_a3_7a_ef_63_23_7b_26_cb_4e_7b_5d_03_9d_7b_92_0b_88_7b_c5_e2_8f_7b_f8_88_2f_7c_29_fb_ed_7c_5a_3d_4f_7c_89_4b_dd_7c_b7_27_23_7c_e3_ce_b1_7d_0f_42_17_7d_39_80_eb_7d_62_8a_c5_7d_8a_5f_3f_7d_b0_fd_f7_7d_d6_66_8e_7d_fa_98_a7_7e_1d_93_e9_7e_3f_57_fe_7e_5f_e4_92_7e_7f_39_56_7e_9d_55_fb_7e_ba_3a_38_7e_d5_e5_c5_7e_f0_58_5f_7f_09_91_c3_7f_21_91_b3_7f_38_57_f5_7f_4d_e4_50_7f_62_36_8e_7f_75_4e_7f_7f_87_2b_f2_7f_97_ce_bc_7f_a7_36_b3_7f_b5_63_b2_7f_c2_55_95_7f_ce_0c_3d_7f_d8_87_8d_7f_e1_c7_6a_7f_e9_cb_bf_7f_f0_94_77_7f_f6_21_81_7f_fa_72_d0_7f_fd_88_59_7f_ff_62_15_7f_ff_ff_ff";

  /**
   * @notice Return the sine of a value, specified in radians scaled by 1e18
   * @dev This algorithm for converting sine only uses integer values, and it works by dividing the
   * circle into 30 bit angles, i.e. there are 1,073,741,824 (2^30) angle units, instead of the
   * standard 360 degrees (2pi radians). From there, we get an output in range -2,147,483,647 to
   * 2,147,483,647, (which is the max value of an int32) which is then converted back to the standard
   * range of -1 to 1, again scaled by 1e18
   * @param _angle Angle to convert
   * @return Result scaled by 1e18
   */
  function sin(uint256 _angle) public pure returns (int256) {
    unchecked {
      // Convert angle from from arbitrary radian value (range of 0 to 2pi) to the algorithm's range
      // of 0 to 1,073,741,824
      _angle = ANGLES_IN_CYCLE * (_angle % TWO_PI) / TWO_PI;

      // Apply a mask on an integer to extract a certain number of bits, where angle is the integer
      // whose bits we want to get, the width is the width of the bits (in bits) we want to extract,
      // and the offset is the offset of the bits (in bits) we want to extract. The result is an
      // integer containing _width bits of _value starting at the offset bit
      uint256 interp = (_angle >> INTERP_OFFSET) & ((1 << INTERP_WIDTH) - 1);
      uint256 index  = (_angle >> INDEX_OFFSET)  & ((1 << INDEX_WIDTH)  - 1);

      // The lookup table only contains data for one quadrant (since sin is symmetric around both
      // axes), so here we figure out which quadrant we're in, then we lookup the values in the
      // table then modify values accordingly
      bool is_odd_quadrant      = (_angle & QUADRANT_LOW_MASK)  == 0;
      bool is_negative_quadrant = (_angle & QUADRANT_HIGH_MASK) != 0;

      if (!is_odd_quadrant) {
        index = SINE_TABLE_SIZE - 1 - index;
      }

      bytes memory table = sin_table;
      // We are looking for two consecutive indices in our lookup table
      // Since EVM is left aligned, to read n bytes of data from idx i, we must read from `i * data_len` + `n`
      // therefore, to read two entries of size entry_bytes `index * entry_bytes` + `entry_bytes * 2`
      uint256 offset1_2 = (index + 2) * entry_bytes;

      // This following snippet will function for any entry_bytes <= 15
      uint256 x1_2; assembly {
        // mload will grab one word worth of bytes (32), as that is the minimum size in EVM
        x1_2 := mload(add(table, offset1_2))
      }

      // We now read the last two numbers of size entry_bytes from x1_2
      // in example: entry_bytes = 4; x1_2 = 0x00...12345678abcdefgh
      // therefore: entry_mask = 0xFFFFFFFF

      // 0x00...12345678abcdefgh >> 8*4 = 0x00...12345678
      // 0x00...12345678 & 0xFFFFFFFF = 0x12345678
      uint256 x1 = x1_2 >> 8*entry_bytes & entry_mask;
      // 0x00...12345678abcdefgh & 0xFFFFFFFF = 0xabcdefgh
      uint256 x2 = x1_2 & entry_mask;

      // Approximate angle by interpolating in the table, accounting for the quadrant
      uint256 approximation = ((x2 - x1) * interp) >> INTERP_WIDTH;
      int256 sine = is_odd_quadrant ? int256(x1) + int256(approximation) : int256(x2) - int256(approximation);
      if (is_negative_quadrant) {
        sine *= -1;
      }

      // Bring result from the range of -2,147,483,647 through 2,147,483,647 to -1e18 through 1e18.
      // This can never overflow because sine is bounded by the above values
      return sine * 1e18 / 2_147_483_647;
    }
  }

  /**
   * @notice Return the cosine of a value, specified in radians scaled by 1e18
   * @dev This is identical to the sin() method, and just computes the value by delegating to the
   * sin() method using the identity cos(x) = sin(x + pi/2)
   * @dev Overflow when `angle + PI_OVER_TWO > type(uint256).max` is ok, results are still accurate
   * @param _angle Angle to convert
   * @return Result scaled by 1e18
   */
  function cos(uint256 _angle) public pure returns (int256) {
    unchecked {
      return sin(_angle + PI_OVER_TWO);
    }
  }

/*---
Trigonometry - Implementation 2
---*/

// Implementation 2 is less accurate than Implementation 1, but it allows for unbounded input in degrees. Output should be downscaled by 1e6. Sintable array loaded twice to avoid stack too deep errors.


  //Computes sine using degrees unit input.
  function dsin (int degrees) external pure returns (int) {
    int[360] memory sintable =
      [int(0),
      17452,
      34899,
      52336,
      69756,
      87156,
      104528,
      121869,
      139173,
      156434,
      173648,
      190809,
      207912,
      224951,
      241922,
      258819,
      275637,
      292372,
      309017,
      325568,
      342020,
      358368,
      374607,
      390731,
      406737,
      422618,
      438371,
      453990,
      469472,
      484810,
      500000,
      515038,
      529919,
      544639,
      559193,
      573576,
      587785,
      601815,
      615661,
      629320,
      642788,
      656059,
      669131,
      681998,
      694658,
      707107, 
      719340,
      731354,
      743145,
      754710,
      766044,
      777146,
      788011,
      798636,
      809017,
      819152,
      829038,
      838671,
      848048,
      857167,
      866025,
      874620,
      882948,
      891007,
      898794,
      906308,
      913545,
      920505,
      927184,
      933580,
      939693,
      945519,
      951057,
      956305,
      961262,
      965926,
      970296,
      974370,
      978148,
      981627,
      984808,
      987688,
      990268,
      992546,
      994522,
      996195,
      997564,
      998630,
      999391,
      999848,
      1000000,
      999848,
      999391,
      998630,
      997564,
      996195,
      994522,
      992546,
      990268,
      987688,
      984808,
      981627,
      978148,
      974370,
      970296,
      965926,
      961262,
      956305,
      951057,
      945519,
      939693,
      933580,
      927184,
      920505,
      913545,
      906308,
      898794,
      891007,
      882948,
      874620,
      866025,
      857167,
      848048,
      838671,
      829038,
      819152,
      809017,
      798636,
      788011,
      777146,
      766044,
      754710,
      743145,
      731354,
      719340,
      707107,
      694658,
      681998,
      669131,
      656059,
      642788,
      629320,
      615661,
      601815,
      587785,
      573576,
      559193,
      544639,
      529919,
      515038,
      500000,
      484810,
      469472,
      453990,
      438371,
      422618,
      406737,
      390731,
      374607,
      358368,
      342020,
      325568,
      309017,
      292372,
      275637,
      258819,
      241922,
      224951,
      207912,
      190809,
      173648,
      156434,
      139173,
      121869,
      104528,
      87156,
      69756,
      52336,
      34899,
      17452,
      0,
      -17452,
      -34899,
      -52336,
      -69756,
      -87156,
      -104528,
      -121869,
      -139173,
      -156434,
      -173648,
      -190809,
      -207912,
      -224951,
      -241922,
      -258819,
      -275637,
      -292372,
      -309017,
      -325568,
      -342020,
      -358368,
      -374607,
      -390731,
      -406737,
      -422618,
      -438371,
      -453990,
      -469472,
      -484810,
      -500000,
      -515038,
      -529919,
      -544639,
      -559193,
      -573576,
      -587785,
      -601815,
      -615661,
      -629320,
      -642788,
      -656059,
      -669131,
      -681998,
      -694658,
      -707107, 
      -719340,
      -731354,
      -743145,
      -754710,
      -766044,
      -777146,
      -788011,
      -798636,
      -809017,
      -819152,
      -829038,
      -838671,
      -848048,
      -857167,
      -866025,
      -874620,
      -882948,
      -891007,
      -898794,
      -906308,
      -913545,
      -920505,
      -927184,
      -933580,
      -939693,
      -945519,
      -951057,
      -956305,
      -961262,
      -965926,
      -970296,
      -974370,
      -978148,
      -981627,
      -984808,
      -987688,
      -990268,
      -992546,
      -994522,
      -996195,
      -997564,
      -998630,
      -999391,
      -999848,
      -1000000,
      -999848,
      -999391,
      -998630,
      -997564,
      -996195,
      -994522,
      -992546,
      -990268,
      -987688,
      -984808,
      -981627,
      -978148,
      -974370,
      -970296,
      -965926,
      -961262,
      -956305,
      -951057,
      -945519,
      -939693,
      -933580,
      -927184,
      -920505,
      -913545,
      -906308,
      -898794,
      -891007,
      -882948,
      -874620,
      -866025,
      -857167,
      -848048,
      -838671,
      -829038,
      -819152,
      -809017,
      -798636,
      -788011,
      -777146,
      -766044,
      -754710,
      -743145,
      -731354,
      -719340,
      -707107,
      -694658,
      -681998,
      -669131,
      -656059,
      -642788,
      -629320,
      -615661,
      -601815,
      -587785,
      -573576,
      -559193,
      -544639,
      -529919,
      -515038,
      -500000,
      -484810,
      -469472,
      -453990,
      -438371,
      -422618,
      -406737,
      -390731,
      -374607,
      -358368,
      -342020,
      -325568,
      -309017,
      -292372,
      -275637,
      -258819,
      -241922,
      -224951,
      -207912,
      -190809,
      -173648,
      -156434,
      -139173,
      -121869,
      -104528,
      -87156,
      -69756,
      -52336,
      -34899,
      -17452];
    if (degrees > -1) {
      return sintable[uint(degrees) % 360];
    }
    else {
      return sintable[uint(degrees * -1) % 360] * -1;
    }
  }

  //Computes cosine with degrees unit input.
  function dcos (int degrees) external pure returns (int) {
    int[360] memory sintable =
      [int(0),
      17452,
      34899,
      52336,
      69756,
      87156,
      104528,
      121869,
      139173,
      156434,
      173648,
      190809,
      207912,
      224951,
      241922,
      258819,
      275637,
      292372,
      309017,
      325568,
      342020,
      358368,
      374607,
      390731,
      406737,
      422618,
      438371,
      453990,
      469472,
      484810,
      500000,
      515038,
      529919,
      544639,
      559193,
      573576,
      587785,
      601815,
      615661,
      629320,
      642788,
      656059,
      669131,
      681998,
      694658,
      707107, 
      719340,
      731354,
      743145,
      754710,
      766044,
      777146,
      788011,
      798636,
      809017,
      819152,
      829038,
      838671,
      848048,
      857167,
      866025,
      874620,
      882948,
      891007,
      898794,
      906308,
      913545,
      920505,
      927184,
      933580,
      939693,
      945519,
      951057,
      956305,
      961262,
      965926,
      970296,
      974370,
      978148,
      981627,
      984808,
      987688,
      990268,
      992546,
      994522,
      996195,
      997564,
      998630,
      999391,
      999848,
      1000000,
      999848,
      999391,
      998630,
      997564,
      996195,
      994522,
      992546,
      990268,
      987688,
      984808,
      981627,
      978148,
      974370,
      970296,
      965926,
      961262,
      956305,
      951057,
      945519,
      939693,
      933580,
      927184,
      920505,
      913545,
      906308,
      898794,
      891007,
      882948,
      874620,
      866025,
      857167,
      848048,
      838671,
      829038,
      819152,
      809017,
      798636,
      788011,
      777146,
      766044,
      754710,
      743145,
      731354,
      719340,
      707107,
      694658,
      681998,
      669131,
      656059,
      642788,
      629320,
      615661,
      601815,
      587785,
      573576,
      559193,
      544639,
      529919,
      515038,
      500000,
      484810,
      469472,
      453990,
      438371,
      422618,
      406737,
      390731,
      374607,
      358368,
      342020,
      325568,
      309017,
      292372,
      275637,
      258819,
      241922,
      224951,
      207912,
      190809,
      173648,
      156434,
      139173,
      121869,
      104528,
      87156,
      69756,
      52336,
      34899,
      17452,
      0,
      -17452,
      -34899,
      -52336,
      -69756,
      -87156,
      -104528,
      -121869,
      -139173,
      -156434,
      -173648,
      -190809,
      -207912,
      -224951,
      -241922,
      -258819,
      -275637,
      -292372,
      -309017,
      -325568,
      -342020,
      -358368,
      -374607,
      -390731,
      -406737,
      -422618,
      -438371,
      -453990,
      -469472,
      -484810,
      -500000,
      -515038,
      -529919,
      -544639,
      -559193,
      -573576,
      -587785,
      -601815,
      -615661,
      -629320,
      -642788,
      -656059,
      -669131,
      -681998,
      -694658,
      -707107, 
      -719340,
      -731354,
      -743145,
      -754710,
      -766044,
      -777146,
      -788011,
      -798636,
      -809017,
      -819152,
      -829038,
      -838671,
      -848048,
      -857167,
      -866025,
      -874620,
      -882948,
      -891007,
      -898794,
      -906308,
      -913545,
      -920505,
      -927184,
      -933580,
      -939693,
      -945519,
      -951057,
      -956305,
      -961262,
      -965926,
      -970296,
      -974370,
      -978148,
      -981627,
      -984808,
      -987688,
      -990268,
      -992546,
      -994522,
      -996195,
      -997564,
      -998630,
      -999391,
      -999848,
      -1000000,
      -999848,
      -999391,
      -998630,
      -997564,
      -996195,
      -994522,
      -992546,
      -990268,
      -987688,
      -984808,
      -981627,
      -978148,
      -974370,
      -970296,
      -965926,
      -961262,
      -956305,
      -951057,
      -945519,
      -939693,
      -933580,
      -927184,
      -920505,
      -913545,
      -906308,
      -898794,
      -891007,
      -882948,
      -874620,
      -866025,
      -857167,
      -848048,
      -838671,
      -829038,
      -819152,
      -809017,
      -798636,
      -788011,
      -777146,
      -766044,
      -754710,
      -743145,
      -731354,
      -719340,
      -707107,
      -694658,
      -681998,
      -669131,
      -656059,
      -642788,
      -629320,
      -615661,
      -601815,
      -587785,
      -573576,
      -559193,
      -544639,
      -529919,
      -515038,
      -500000,
      -484810,
      -469472,
      -453990,
      -438371,
      -422618,
      -406737,
      -390731,
      -374607,
      -358368,
      -342020,
      -325568,
      -309017,
      -292372,
      -275637,
      -258819,
      -241922,
      -224951,
      -207912,
      -190809,
      -173648,
      -156434,
      -139173,
      -121869,
      -104528,
      -87156,
      -69756,
      -52336,
      -34899,
      -17452];
    if ((degrees + 90) > -1) {
      return sintable[uint(degrees + 90) % 360];
    }
    else {
      return sintable[uint((degrees + 90) * -1) % 360] * -1;
    }
  }
}




// ----------------------------------------------------------------------------
// BokkyPooBah's DateTime Library v1.01
//
// A gas-efficient Solidity date and time library
//
// https://github.com/bokkypoobah/BokkyPooBahsDateTimeLibrary
//
// Tested date range 1970/01/01 to 2345/12/31
//
// Conventions:
// Unit      | Range         | Notes
// :-------- |:-------------:|:-----
// timestamp | >= 0          | Unix timestamp, number of seconds since 1970/01/01 00:00:00 UTC
// year      | 1970 ... 2345 |
// month     | 1 ... 12      |
// day       | 1 ... 31      |
// hour      | 0 ... 23      |
// minute    | 0 ... 59      |
// second    | 0 ... 59      |
// dayOfWeek | 1 ... 7       | 1 = Monday, ..., 7 = Sunday
//
//
// Enjoy. (c) BokkyPooBah / Bok Consulting Pty Ltd 2018-2019. The MIT Licence.
// ----------------------------------------------------------------------------

library BokkyPooBahsDateTimeLibrary {

    uint constant SECONDS_PER_DAY = 24 * 60 * 60;
    uint constant SECONDS_PER_HOUR = 60 * 60;
    uint constant SECONDS_PER_MINUTE = 60;
    int constant OFFSET19700101 = 2440588;

    uint constant DOW_MON = 1;
    uint constant DOW_TUE = 2;
    uint constant DOW_WED = 3;
    uint constant DOW_THU = 4;
    uint constant DOW_FRI = 5;
    uint constant DOW_SAT = 6;
    uint constant DOW_SUN = 7;

    // ------------------------------------------------------------------------
    // Calculate the number of days from 1970/01/01 to year/month/day using
    // the date conversion algorithm from
    //   https://aa.usno.navy.mil/faq/JD_formula.html
    // and subtracting the offset 2440588 so that 1970/01/01 is day 0
    //
    // days = day
    //      - 32075
    //      + 1461 * (year + 4800 + (month - 14) / 12) / 4
    //      + 367 * (month - 2 - (month - 14) / 12 * 12) / 12
    //      - 3 * ((year + 4900 + (month - 14) / 12) / 100) / 4
    //      - offset
    // ------------------------------------------------------------------------
    function _daysFromDate(uint year, uint month, uint day) internal pure returns (uint _days) {
        require(year >= 1970);
        int _year = int(year);
        int _month = int(month);
        int _day = int(day);

        int __days = _day
          - 32075
          + 1461 * (_year + 4800 + (_month - 14) / 12) / 4
          + 367 * (_month - 2 - (_month - 14) / 12 * 12) / 12
          - 3 * ((_year + 4900 + (_month - 14) / 12) / 100) / 4
          - OFFSET19700101;

        _days = uint(__days);
    }

    // ------------------------------------------------------------------------
    // Calculate year/month/day from the number of days since 1970/01/01 using
    // the date conversion algorithm from
    //   http://aa.usno.navy.mil/faq/docs/JD_Formula.php
    // and adding the offset 2440588 so that 1970/01/01 is day 0
    //
    // int L = days + 68569 + offset
    // int N = 4 * L / 146097
    // L = L - (146097 * N + 3) / 4
    // year = 4000 * (L + 1) / 1461001
    // L = L - 1461 * year / 4 + 31
    // month = 80 * L / 2447
    // dd = L - 2447 * month / 80
    // L = month / 11
    // month = month + 2 - 12 * L
    // year = 100 * (N - 49) + year + L
    // ------------------------------------------------------------------------
    function _daysToDate(uint _days) internal pure returns (uint year, uint month, uint day) {
        int __days = int(_days);

        int L = __days + 68569 + OFFSET19700101;
        int N = 4 * L / 146097;
        L = L - (146097 * N + 3) / 4;
        int _year = 4000 * (L + 1) / 1461001;
        L = L - 1461 * _year / 4 + 31;
        int _month = 80 * L / 2447;
        int _day = L - 2447 * _month / 80;
        L = _month / 11;
        _month = _month + 2 - 12 * L;
        _year = 100 * (N - 49) + _year + L;

        year = uint(_year);
        month = uint(_month);
        day = uint(_day);
    }

    function timestampFromDate(uint year, uint month, uint day) internal pure returns (uint timestamp) {
        timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY;
    }
    function timestampFromDateTime(uint year, uint month, uint day, uint hour, uint minute, uint second) internal pure returns (uint timestamp) {
        timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + hour * SECONDS_PER_HOUR + minute * SECONDS_PER_MINUTE + second;
    }
    function timestampToDate(uint timestamp) internal pure returns (uint year, uint month, uint day) {
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function timestampToDateTime(uint timestamp) internal pure returns (uint year, uint month, uint day, uint hour, uint minute, uint second) {
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        uint secs = timestamp % SECONDS_PER_DAY;
        hour = secs / SECONDS_PER_HOUR;
        secs = secs % SECONDS_PER_HOUR;
        minute = secs / SECONDS_PER_MINUTE;
        second = secs % SECONDS_PER_MINUTE;
    }

    function isValidDate(uint year, uint month, uint day) internal pure returns (bool valid) {
        if (year >= 1970 && month > 0 && month <= 12) {
            uint daysInMonth = _getDaysInMonth(year, month);
            if (day > 0 && day <= daysInMonth) {
                valid = true;
            }
        }
    }
    function isValidDateTime(uint year, uint month, uint day, uint hour, uint minute, uint second) internal pure returns (bool valid) {
        if (isValidDate(year, month, day)) {
            if (hour < 24 && minute < 60 && second < 60) {
                valid = true;
            }
        }
    }
    function isLeapYear(uint timestamp) internal pure returns (bool leapYear) {
        (uint year,,) = _daysToDate(timestamp / SECONDS_PER_DAY);
        leapYear = _isLeapYear(year);
    }
    function _isLeapYear(uint year) internal pure returns (bool leapYear) {
        leapYear = ((year % 4 == 0) && (year % 100 != 0)) || (year % 400 == 0);
    }
    function isWeekDay(uint timestamp) internal pure returns (bool weekDay) {
        weekDay = getDayOfWeek(timestamp) <= DOW_FRI;
    }
    function isWeekEnd(uint timestamp) internal pure returns (bool weekEnd) {
        weekEnd = getDayOfWeek(timestamp) >= DOW_SAT;
    }
    function getDaysInMonth(uint timestamp) internal pure returns (uint daysInMonth) {
        (uint year, uint month,) = _daysToDate(timestamp / SECONDS_PER_DAY);
        daysInMonth = _getDaysInMonth(year, month);
    }
    function _getDaysInMonth(uint year, uint month) internal pure returns (uint daysInMonth) {
        if (month == 1 || month == 3 || month == 5 || month == 7 || month == 8 || month == 10 || month == 12) {
            daysInMonth = 31;
        } else if (month != 2) {
            daysInMonth = 30;
        } else {
            daysInMonth = _isLeapYear(year) ? 29 : 28;
        }
    }
    // 1 = Monday, 7 = Sunday
    function getDayOfWeek(uint timestamp) internal pure returns (uint dayOfWeek) {
        uint _days = timestamp / SECONDS_PER_DAY;
        dayOfWeek = (_days + 3) % 7 + 1;
    }

    function getYear(uint timestamp) internal pure returns (uint year) {
        (year,,) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function getMonth(uint timestamp) internal pure returns (uint month) {
        (,month,) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function getDay(uint timestamp) internal pure returns (uint day) {
        (,,day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function getHour(uint timestamp) internal pure returns (uint hour) {
        uint secs = timestamp % SECONDS_PER_DAY;
        hour = secs / SECONDS_PER_HOUR;
    }
    function getMinute(uint timestamp) internal pure returns (uint minute) {
        uint secs = timestamp % SECONDS_PER_HOUR;
        minute = secs / SECONDS_PER_MINUTE;
    }
    function getSecond(uint timestamp) internal pure returns (uint second) {
        second = timestamp % SECONDS_PER_MINUTE;
    }

    function addYears(uint timestamp, uint _years) internal pure returns (uint newTimestamp) {
        (uint year, uint month, uint day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        year += _years;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }
    function addMonths(uint timestamp, uint _months) internal pure returns (uint newTimestamp) {
        (uint year, uint month, uint day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        month += _months;
        year += (month - 1) / 12;
        month = (month - 1) % 12 + 1;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }
    function addDays(uint timestamp, uint _days) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _days * SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }
    function addHours(uint timestamp, uint _hours) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _hours * SECONDS_PER_HOUR;
        require(newTimestamp >= timestamp);
    }
    function addMinutes(uint timestamp, uint _minutes) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _minutes * SECONDS_PER_MINUTE;
        require(newTimestamp >= timestamp);
    }
    function addSeconds(uint timestamp, uint _seconds) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _seconds;
        require(newTimestamp >= timestamp);
    }

    function subYears(uint timestamp, uint _years) internal pure returns (uint newTimestamp) {
        (uint year, uint month, uint day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        year -= _years;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp <= timestamp);
    }
    function subMonths(uint timestamp, uint _months) internal pure returns (uint newTimestamp) {
        (uint year, uint month, uint day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        uint yearMonth = year * 12 + (month - 1) - _months;
        year = yearMonth / 12;
        month = yearMonth % 12 + 1;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp <= timestamp);
    }
    function subDays(uint timestamp, uint _days) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _days * SECONDS_PER_DAY;
        require(newTimestamp <= timestamp);
    }
    function subHours(uint timestamp, uint _hours) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _hours * SECONDS_PER_HOUR;
        require(newTimestamp <= timestamp);
    }
    function subMinutes(uint timestamp, uint _minutes) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _minutes * SECONDS_PER_MINUTE;
        require(newTimestamp <= timestamp);
    }
    function subSeconds(uint timestamp, uint _seconds) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _seconds;
        require(newTimestamp <= timestamp);
    }

    function diffYears(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _years) {
        require(fromTimestamp <= toTimestamp);
        (uint fromYear,,) = _daysToDate(fromTimestamp / SECONDS_PER_DAY);
        (uint toYear,,) = _daysToDate(toTimestamp / SECONDS_PER_DAY);
        _years = toYear - fromYear;
    }
    function diffMonths(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _months) {
        require(fromTimestamp <= toTimestamp);
        (uint fromYear, uint fromMonth,) = _daysToDate(fromTimestamp / SECONDS_PER_DAY);
        (uint toYear, uint toMonth,) = _daysToDate(toTimestamp / SECONDS_PER_DAY);
        _months = toYear * 12 + toMonth - fromYear * 12 - fromMonth;
    }
    function diffDays(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _days) {
        require(fromTimestamp <= toTimestamp);
        _days = (toTimestamp - fromTimestamp) / SECONDS_PER_DAY;
    }
    function diffHours(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _hours) {
        require(fromTimestamp <= toTimestamp);
        _hours = (toTimestamp - fromTimestamp) / SECONDS_PER_HOUR;
    }
    function diffMinutes(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _minutes) {
        require(fromTimestamp <= toTimestamp);
        _minutes = (toTimestamp - fromTimestamp) / SECONDS_PER_MINUTE;
    }
    function diffSeconds(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _seconds) {
        require(fromTimestamp <= toTimestamp);
        _seconds = toTimestamp - fromTimestamp;
    }
}


// OpenZeppelin Contracts (last updated v4.7.0) (utils/Base64.sol)

/**
 * @dev Provides a set of functions to operate with Base64 strings.
 *
 * _Available since v4.5._
 */
library Base64 {
    /**
     * @dev Base64 Encoding/Decoding Table
     */
    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /**
     * @dev Converts a `bytes` to its Bytes64 `string` representation.
     */
    function encode(bytes memory data) internal pure returns (string memory) {
        /**
         * Inspired by Brecht Devos (Brechtpd) implementation - MIT licence
         * https://github.com/Brechtpd/base64/blob/e78d9fd951e7b0977ddca77d92dc85183770daf4/base64.sol
         */
        if (data.length == 0) return "";

        // Loads the table into memory
        string memory table = _TABLE;

        // Encoding takes 3 bytes chunks of binary data from `bytes` data parameter
        // and split into 4 numbers of 6 bits.
        // The final Base64 length should be `bytes` data length multiplied by 4/3 rounded up
        // - `data.length + 2`  -> Round up
        // - `/ 3`              -> Number of 3-bytes chunks
        // - `4 *`              -> 4 characters for each chunk
        string memory result = new string(4 * ((data.length + 2) / 3));

        /// @solidity memory-safe-assembly
        assembly {
            // Prepare the lookup table (skip the first "length" byte)
            let tablePtr := add(table, 1)

            // Prepare result pointer, jump over length
            let resultPtr := add(result, 32)

            // Run over the input, 3 bytes at a time
            for {
                let dataPtr := data
                let endPtr := add(data, mload(data))
            } lt(dataPtr, endPtr) {

            } {
                // Advance 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // To write each character, shift the 3 bytes (18 bits) chunk
                // 4 times in blocks of 6 bits for each character (18, 12, 6, 0)
                // and apply logical AND with 0x3F which is the number of
                // the previous character in the ASCII table prior to the Base64 Table
                // The result is then added to the table to get the character to write,
                // and finally write it in the result pointer but with a left shift
                // of 256 (1 byte) - 8 (1 ASCII char) = 248 bits

                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance
            }

            // When data `bytes` is not exactly 3 bytes long
            // it is padded with `=` characters at the end
            switch mod(mload(data), 3)
            case 1 {
                mstore8(sub(resultPtr, 1), 0x3d)
                mstore8(sub(resultPtr, 2), 0x3d)
            }
            case 2 {
                mstore8(sub(resultPtr, 1), 0x3d)
            }
        }

        return result;
    }
}


interface IVeArtProxy {
    /// @dev Art configuration
    struct Config {
        // NFT metadata variables
        int256 _tokenId;
        int256 _balanceOf;
        int256 _lockedEnd;
        int256 _lockedAmount;
        // Line art variables
        int256 shape;
        uint256 palette;
        int256 maxLines;
        int256 dash;
        // Randomness variables
        int256 seed1;
        int256 seed2;
        int256 seed3;
    }

    /// @dev Individual line art path variables.
    struct lineConfig {
        bytes8 color;
        uint256 stroke;
        uint256 offset;
        uint256 offsetHalf;
        uint256 offsetDashSum;
        uint256 pathLength;
    }

    /// @dev Represents an (x,y) coordinate in a line.
    struct Point {
        int256 x;
        int256 y;
    }

    /// @notice Generate a SVG based on veNFT metadata
    /// @param _tokenId Unique veNFT identifier
    /// @return output SVG metadata as HTML tag
    function tokenURI(uint256 _tokenId) external view returns (string memory output);

    /// @notice Generate only the foreground <path> elements of the line art for an NFT (excluding SVG header), for flexibility purposes.
    /// @param _tokenId Unique veNFT identifier
    /// @return output Encoded output of generateShape()
    function lineArtPathsOnly(uint256 _tokenId) external view returns (bytes memory output);

    /// @notice Generate the master art config metadata for a veNFT
    /// @param _tokenId Unique veNFT identifier
    /// @return cfg Config struct
    function generateConfig(uint256 _tokenId) external view returns (Config memory cfg);

    /// @notice Generate the points for two stripe lines based on the config generated for a veNFT
    /// @param cfg Master art config metadata of a veNFT
    /// @param l Number of line drawn
    /// @return Line (x, y) coordinates of the drawn stripes
    function twoStripes(Config memory cfg, int256 l) external pure returns (Point[100] memory Line);

    /// @notice Generate the points for circles based on the config generated for a veNFT
    /// @param cfg Master art config metadata of a veNFT
    /// @param l Number of circles drawn
    /// @return Line (x, y) coordinates of the drawn circles
    function circles(Config memory cfg, int256 l) external pure returns (Point[100] memory Line);

    /// @notice Generate the points for interlocking circles based on the config generated for a veNFT
    /// @param cfg Master art config metadata of a veNFT
    /// @param l Number of interlocking circles drawn
    /// @return Line (x, y) coordinates of the drawn interlocking circles
    function interlockingCircles(Config memory cfg, int256 l) external pure returns (Point[100] memory Line);

    /// @notice Generate the points for corners based on the config generated for a veNFT
    /// @param cfg Master art config metadata of a veNFT
    /// @param l Number of corners drawn
    /// @return Line (x, y) coordinates of the drawn corners
    function corners(Config memory cfg, int256 l) external pure returns (Point[100] memory Line);

    /// @notice Generate the points for a curve based on the config generated for a veNFT
    /// @param cfg Master art config metadata of a veNFT
    /// @param l Number of curve drawn
    /// @return Line (x, y) coordinates of the drawn curve
    function curves(Config memory cfg, int256 l) external pure returns (Point[100] memory Line);

    /// @notice Generate the points for a spiral based on the config generated for a veNFT
    /// @param cfg Master art config metadata of a veNFT
    /// @param l Number of spiral drawn
    /// @return Line (x, y) coordinates of the drawn spiral
    function spiral(Config memory cfg, int256 l) external pure returns (Point[100] memory Line);

    /// @notice Generate the points for an explosion based on the config generated for a veNFT
    /// @param cfg Master art config metadata of a veNFT
    /// @param l Number of explosion drawn
    /// @return Line (x, y) coordinates of the drawn explosion
    function explosion(Config memory cfg, int256 l) external pure returns (Point[100] memory Line);

    /// @notice Generate the points for a wormhole based on the config generated for a veNFT
    /// @param cfg Master art config metadata of a veNFT
    /// @param l Number of wormhole drawn
    /// @return Line (x, y) coordinates of the drawn wormhole
    function wormhole(Config memory cfg, int256 l) external pure returns (Point[100] memory Line);
}


// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// OpenZeppelin Contracts (interfaces/IERC6372.sol)

interface IERC6372 {
    /**
     * @dev Clock used for flagging checkpoints. Can be overridden to implement timestamp based checkpoints (and voting).
     */
    function clock() external view returns (uint48);

    /**
     * @dev Description of the clock
     */
    // solhint-disable-next-line func-name-mixedcase
    function CLOCK_MODE() external view returns (string memory);
}

// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721.sol)

/// @title EIP-721 Metadata Update Extension
interface IERC4906 is IERC165, IERC721 {
    /// @dev This event emits when the metadata of a token is changed.
    /// So that the third-party platforms such as NFT market could
    /// timely update the images and related attributes of the NFT.
    event MetadataUpdate(uint256 _tokenId);

    /// @dev This event emits when the metadata of a range of tokens is changed.
    /// So that the third-party platforms such as NFT market could
    /// timely update the images and related attributes of the NFTs.
    event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);
}

/// Modified IVotes interface for tokenId based voting
interface IVotes {
    /**
     * @dev Emitted when an account changes their delegate.
     */
    event DelegateChanged(address indexed delegator, uint256 indexed fromDelegate, uint256 indexed toDelegate);

    /**
     * @dev Emitted when a token transfer or delegate change results in changes to a delegate's number of votes.
     */
    event DelegateVotesChanged(address indexed delegate, uint256 previousBalance, uint256 newBalance);

    /**
     * @dev Returns the amount of votes that `tokenId` had at a specific moment in the past.
     *      If the account passed in is not the owner, returns 0.
     */
    function getPastVotes(address account, uint256 tokenId, uint256 timepoint) external view returns (uint256);

    /**
     * @dev Returns the total supply of votes available at a specific moment in the past. If the `clock()` is
     * configured to use block numbers, this will return the value the end of the corresponding block.
     *
     * NOTE: This value is the sum of all available votes, which is not necessarily the sum of all delegated votes.
     * Votes that have not been delegated are still part of total supply, even though they would not participate in a
     * vote.
     */
    function getPastTotalSupply(uint256 timepoint) external view returns (uint256);

    /**
     * @dev Returns the delegate that `tokenId` has chosen. Can never be equal to the delegator's `tokenId`.
     *      Returns 0 if not delegated.
     */
    function delegates(uint256 tokenId) external view returns (uint256);

    /**
     * @dev Delegates votes from the sender to `delegatee`.
     */
    function delegate(uint256 delegator, uint256 delegatee) external;

    /**
     * @dev Delegates votes from `delegator` to `delegatee`. Signer must own `delegator`.
     */
    function delegateBySig(
        uint256 delegator,
        uint256 delegatee,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

interface IVotingEscrow is IVotes, IERC4906, IERC6372, IERC721Metadata {
    struct LockedBalance {
        int128 amount;
        uint256 end;
        bool isPermanent;
    }

    struct UserPoint {
        int128 bias;
        int128 slope; // # -dweight / dt
        uint256 ts;
        uint256 blk; // block
        uint256 permanent;
    }

    struct GlobalPoint {
        int128 bias;
        int128 slope; // # -dweight / dt
        uint256 ts;
        uint256 blk; // block
        uint256 permanentLockBalance;
    }

    /// @notice A checkpoint for recorded delegated voting weights at a certain timestamp
    struct Checkpoint {
        uint256 fromTimestamp;
        address owner;
        uint256 delegatedBalance;
        uint256 delegatee;
    }

    enum DepositType {
        DEPOSIT_FOR_TYPE,
        CREATE_LOCK_TYPE,
        INCREASE_LOCK_AMOUNT,
        INCREASE_UNLOCK_TIME
    }

    /// @dev Different types of veNFTs:
    /// NORMAL  - typical veNFT
    /// LOCKED  - veNFT which is locked into a MANAGED veNFT
    /// MANAGED - veNFT which can accept the deposit of NORMAL veNFTs
    enum EscrowType {
        NORMAL,
        LOCKED,
        MANAGED
    }

    error AlreadyVoted();
    error AmountTooBig();
    error ERC721ReceiverRejectedTokens();
    error ERC721TransferToNonERC721ReceiverImplementer();
    error InvalidNonce();
    error InvalidSignature();
    error InvalidSignatureS();
    error InvalidManagedNFTId();
    error LockDurationNotInFuture();
    error LockDurationTooLong();
    error LockExpired();
    error LockNotExpired();
    error NoLockFound();
    error NonExistentToken();
    error NotApprovedOrOwner();
    error NotDistributor();
    error NotEmergencyCouncilOrGovernor();
    error NotGovernor();
    error NotGovernorOrManager();
    error NotManagedNFT();
    error NotManagedOrNormalNFT();
    error NotLockedNFT();
    error NotNormalNFT();
    error NotPermanentLock();
    error NotOwner();
    error NotTeam();
    error NotVoter();
    error OwnershipChange();
    error PermanentLock();
    error SameAddress();
    error SameNFT();
    error SameState();
    error SplitNoOwner();
    error SplitNotAllowed();
    error SignatureExpired();
    error TooManyTokenIDs();
    error ZeroAddress();
    error ZeroAmount();
    error ZeroBalance();

    event Deposit(
        address indexed provider,
        uint256 indexed tokenId,
        DepositType indexed depositType,
        uint256 value,
        uint256 locktime,
        uint256 ts
    );
    event Withdraw(address indexed provider, uint256 indexed tokenId, uint256 value, uint256 ts);
    event LockPermanent(address indexed _owner, uint256 indexed _tokenId, uint256 amount, uint256 _ts);
    event UnlockPermanent(address indexed _owner, uint256 indexed _tokenId, uint256 amount, uint256 _ts);
    event Supply(uint256 prevSupply, uint256 supply);
    event Merge(
        address indexed _sender,
        uint256 indexed _from,
        uint256 indexed _to,
        uint256 _amountFrom,
        uint256 _amountTo,
        uint256 _amountFinal,
        uint256 _locktime,
        uint256 _ts
    );
    event Split(
        uint256 indexed _from,
        uint256 indexed _tokenId1,
        uint256 indexed _tokenId2,
        address _sender,
        uint256 _splitAmount1,
        uint256 _splitAmount2,
        uint256 _locktime,
        uint256 _ts
    );
    event CreateManaged(
        address indexed _to,
        uint256 indexed _mTokenId,
        address indexed _from,
        address _lockedManagedReward,
        address _freeManagedReward
    );
    event DepositManaged(
        address indexed _owner,
        uint256 indexed _tokenId,
        uint256 indexed _mTokenId,
        uint256 _weight,
        uint256 _ts
    );
    event WithdrawManaged(
        address indexed _owner,
        uint256 indexed _tokenId,
        uint256 indexed _mTokenId,
        uint256 _weight,
        uint256 _ts
    );
    event SetAllowedManager(address indexed _allowedManager);

    // State variables
    /// @notice Address of Meta-tx Forwarder
    function forwarder() external view returns (address);

    /// @notice Address of FactoryRegistry.sol
    function factoryRegistry() external view returns (address);

    /// @notice Address of token (PRFCT) used to create a veNFT
    function token() external view returns (address);

    /// @notice Address of RewardsDistributor.sol
    function distributor() external view returns (address);

    /// @notice Address of Voter.sol
    function voter() external view returns (address);

    /// @notice Address of Protocol Team multisig
    function team() external view returns (address);

    /// @notice Address of art proxy used for on-chain art generation
    function artProxy() external view returns (address);

    /// @dev address which can create managed NFTs
    function allowedManager() external view returns (address);

    /// @dev Current count of token
    function tokenId() external view returns (uint256);

    /*///////////////////////////////////////////////////////////////
                            MANAGED NFT STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @dev Mapping of token id to escrow type
    ///      Takes advantage of the fact default value is EscrowType.NORMAL
    function escrowType(uint256 tokenId) external view returns (EscrowType);

    /// @dev Mapping of token id to managed id
    function idToManaged(uint256 tokenId) external view returns (uint256 managedTokenId);

    /// @dev Mapping of user token id to managed token id to weight of token id
    function weights(uint256 tokenId, uint256 managedTokenId) external view returns (uint256 weight);

    /// @dev Mapping of managed id to deactivated state
    function deactivated(uint256 tokenId) external view returns (bool inactive);

    /// @dev Mapping from managed nft id to locked managed rewards
    ///      `token` denominated rewards (rebases/rewards) stored in locked managed rewards contract
    ///      to prevent co-mingling of assets
    function managedToLocked(uint256 tokenId) external view returns (address);

    /// @dev Mapping from managed nft id to free managed rewards contract
    ///      these rewards can be freely withdrawn by users
    function managedToFree(uint256 tokenId) external view returns (address);

    /*///////////////////////////////////////////////////////////////
                            MANAGED NFT LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Create managed NFT (a permanent lock) for use within ecosystem.
    /// @dev Throws if address already owns a managed NFT.
    /// @return _mTokenId managed token id.
    function createManagedLockFor(address _to) external returns (uint256 _mTokenId);

    /// @notice Delegates balance to managed nft
    ///         Note that NFTs deposited into a managed NFT will be re-locked
    ///         to the maximum lock time on withdrawal.
    ///         Permanent locks that are deposited will automatically unlock.
    /// @dev Managed nft will remain max-locked as long as there is at least one
    ///      deposit or withdrawal per week.
    ///      Throws if deposit nft is managed.
    ///      Throws if recipient nft is not managed.
    ///      Throws if deposit nft is already locked.
    ///      Throws if not called by voter.
    /// @param _tokenId tokenId of NFT being deposited
    /// @param _mTokenId tokenId of managed NFT that will receive the deposit
    function depositManaged(uint256 _tokenId, uint256 _mTokenId) external;

    /// @notice Retrieves locked rewards and withdraws balance from managed nft.
    ///         Note that the NFT withdrawn is re-locked to the maximum lock time.
    /// @dev Throws if NFT not locked.
    ///      Throws if not called by voter.
    /// @param _tokenId tokenId of NFT being deposited.
    function withdrawManaged(uint256 _tokenId) external;

    /// @notice Permit one address to call createManagedLockFor() that is not Voter.governor()
    function setAllowedManager(address _allowedManager) external;

    /// @notice Set Managed NFT state. Inactive NFTs cannot be deposited into.
    /// @param _mTokenId managed nft state to set
    /// @param _state true => inactive, false => active
    function setManagedState(uint256 _mTokenId, bool _state) external;

    /*///////////////////////////////////////////////////////////////
                             METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function version() external view returns (string memory);

    function decimals() external view returns (uint8);

    function setTeam(address _team) external;

    function setArtProxy(address _proxy) external;

    /// @inheritdoc IERC721Metadata
    function tokenURI(uint256 tokenId) external view returns (string memory);

    /*//////////////////////////////////////////////////////////////
                      ERC721 BALANCE/OWNER STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @dev Mapping from owner address to mapping of index to tokenId
    function ownerToNFTokenIdList(address _owner, uint256 _index) external view returns (uint256 _tokenId);

    /// @inheritdoc IERC721
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /// @inheritdoc IERC721
    function balanceOf(address owner) external view returns (uint256 balance);

    /*//////////////////////////////////////////////////////////////
                         ERC721 APPROVAL STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IERC721
    function getApproved(uint256 _tokenId) external view returns (address operator);

    /// @inheritdoc IERC721
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /// @notice Check whether spender is owner or an approved user for a given veNFT
    /// @param _spender .
    /// @param _tokenId .
    function isApprovedOrOwner(address _spender, uint256 _tokenId) external returns (bool);

    /*//////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IERC721
    function approve(address to, uint256 tokenId) external;

    /// @inheritdoc IERC721
    function setApprovalForAll(address operator, bool approved) external;

    /// @inheritdoc IERC721
    function transferFrom(address from, address to, uint256 tokenId) external;

    /// @inheritdoc IERC721
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /// @inheritdoc IERC721
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IERC165
    function supportsInterface(bytes4 _interfaceID) external view returns (bool);

    /*//////////////////////////////////////////////////////////////
                             ESCROW STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @notice Total count of epochs witnessed since contract creation
    function epoch() external view returns (uint256);

    /// @notice Total amount of token() deposited
    function supply() external view returns (uint256);

    /// @notice Aggregate permanent locked balances
    function permanentLockBalance() external view returns (uint256);

    function userPointEpoch(uint256 _tokenId) external view returns (uint256 _epoch);

    /// @notice time -> signed slope change
    function slopeChanges(uint256 _timestamp) external view returns (int128);

    /// @notice account -> can split
    function canSplit(address _account) external view returns (bool);

    /// @notice Global point history at a given index
    function pointHistory(uint256 _loc) external view returns (GlobalPoint memory);

    /// @notice Get the LockedBalance (amount, end) of a _tokenId
    /// @param _tokenId .
    /// @return LockedBalance of _tokenId
    function locked(uint256 _tokenId) external view returns (LockedBalance memory);

    /// @notice User -> UserPoint[userEpoch]
    function userPointHistory(uint256 _tokenId, uint256 _loc) external view returns (UserPoint memory);

    /*//////////////////////////////////////////////////////////////
                              ESCROW LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Record global data to checkpoint
    function checkpoint() external;

    /// @notice Deposit `_value` tokens for `_tokenId` and add to the lock
    /// @dev Anyone (even a smart contract) can deposit for someone else, but
    ///      cannot extend their locktime and deposit for a brand new user
    /// @param _tokenId lock NFT
    /// @param _value Amount to add to user's lock
    function depositFor(uint256 _tokenId, uint256 _value) external;

    /// @notice Deposit `_value` tokens for `msg.sender` and lock for `_lockDuration`
    /// @param _value Amount to deposit
    /// @param _lockDuration Number of seconds to lock tokens for (rounded down to nearest week)
    /// @return TokenId of created veNFT
    function createLock(uint256 _value, uint256 _lockDuration) external returns (uint256);

    /// @notice Deposit `_value` tokens for `_to` and lock for `_lockDuration`
    /// @param _value Amount to deposit
    /// @param _lockDuration Number of seconds to lock tokens for (rounded down to nearest week)
    /// @param _to Address to deposit
    /// @return TokenId of created veNFT
    function createLockFor(uint256 _value, uint256 _lockDuration, address _to) external returns (uint256);

    /// @notice Deposit `_value` additional tokens for `_tokenId` without modifying the unlock time
    /// @param _value Amount of tokens to deposit and add to the lock
    function increaseAmount(uint256 _tokenId, uint256 _value) external;

    /// @notice Extend the unlock time for `_tokenId`
    ///         Cannot extend lock time of permanent locks
    /// @param _lockDuration New number of seconds until tokens unlock
    function increaseUnlockTime(uint256 _tokenId, uint256 _lockDuration) external;

    /// @notice Withdraw all tokens for `_tokenId`
    /// @dev Only possible if the lock is both expired and not permanent
    ///      This will burn the veNFT. Any rebases or rewards that are unclaimed
    ///      will no longer be claimable. Claim all rebases and rewards prior to calling this.
    function withdraw(uint256 _tokenId) external;

    /// @notice Merges `_from` into `_to`.
    /// @dev Cannot merge `_from` locks that are permanent or have already voted this epoch.
    ///      Cannot merge `_to` locks that have already expired.
    ///      This will burn the veNFT. Any rebases or rewards that are unclaimed
    ///      will no longer be claimable. Claim all rebases and rewards prior to calling this.
    /// @param _from VeNFT to merge from.
    /// @param _to VeNFT to merge into.
    function merge(uint256 _from, uint256 _to) external;

    /// @notice Splits veNFT into two new veNFTS - one with oldLocked.amount - `_amount`, and the second with `_amount`
    /// @dev    This burns the tokenId of the target veNFT
    ///         Callable by approved or owner
    ///         If this is called by approved, approved will not have permissions to manipulate the newly created veNFTs
    ///         Returns the two new split veNFTs to owner
    ///         If `from` is permanent, will automatically dedelegate.
    ///         This will burn the veNFT. Any rebases or rewards that are unclaimed
    ///         will no longer be claimable. Claim all rebases and rewards prior to calling this.
    /// @param _from VeNFT to split.
    /// @param _amount Amount to split from veNFT.
    /// @return _tokenId1 Return tokenId of veNFT with oldLocked.amount - `_amount`.
    /// @return _tokenId2 Return tokenId of veNFT with `_amount`.
    function split(uint256 _from, uint256 _amount) external returns (uint256 _tokenId1, uint256 _tokenId2);

    /// @notice Toggle split for a specific address.
    /// @dev Toggle split for address(0) to enable or disable for all.
    /// @param _account Address to toggle split permissions
    /// @param _bool True to allow, false to disallow
    function toggleSplit(address _account, bool _bool) external;

    /// @notice Permanently lock a veNFT. Voting power will be equal to
    ///         `LockedBalance.amount` with no decay. Required to delegate.
    /// @dev Only callable by unlocked normal veNFTs.
    /// @param _tokenId tokenId to lock.
    function lockPermanent(uint256 _tokenId) external;

    /// @notice Unlock a permanently locked veNFT. Voting power will decay.
    ///         Will automatically dedelegate if delegated.
    /// @dev Only callable by permanently locked veNFTs.
    ///      Cannot unlock if already voted this epoch.
    /// @param _tokenId tokenId to unlock.
    function unlockPermanent(uint256 _tokenId) external;

    /*///////////////////////////////////////////////////////////////
                           GAUGE VOTING STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @notice Get the voting power for _tokenId at the current timestamp
    /// @dev Returns 0 if called in the same block as a transfer.
    /// @param _tokenId .
    /// @return Voting power
    function balanceOfNFT(uint256 _tokenId) external view returns (uint256);

    /// @notice Get the voting power for _tokenId at a given timestamp
    /// @param _tokenId .
    /// @param _t Timestamp to query voting power
    /// @return Voting power
    function balanceOfNFTAt(uint256 _tokenId, uint256 _t) external view returns (uint256);

    /// @notice Calculate total voting power at current timestamp
    /// @return Total voting power at current timestamp
    function totalSupply() external view returns (uint256);

    /// @notice Calculate total voting power at a given timestamp
    /// @param _t Timestamp to query total voting power
    /// @return Total voting power at given timestamp
    function totalSupplyAt(uint256 _t) external view returns (uint256);

    /*///////////////////////////////////////////////////////////////
                            GAUGE VOTING LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice See if a queried _tokenId has actively voted
    /// @param _tokenId .
    /// @return True if voted, else false
    function voted(uint256 _tokenId) external view returns (bool);

    /// @notice Set the global state voter and distributor
    /// @dev This is only called once, at setup
    function setVoterAndDistributor(address _voter, address _distributor) external;

    /// @notice Set `voted` for _tokenId to true or false
    /// @dev Only callable by voter
    /// @param _tokenId .
    /// @param _voted .
    function voting(uint256 _tokenId, bool _voted) external;

    /*///////////////////////////////////////////////////////////////
                            DAO VOTING STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @notice The number of checkpoints for each tokenId
    function numCheckpoints(uint256 tokenId) external view returns (uint48);

    /// @notice A record of states for signing / validating signatures
    function nonces(address account) external view returns (uint256);

    /// @inheritdoc IVotes
    function delegates(uint256 delegator) external view returns (uint256);

    /// @notice A record of delegated token checkpoints for each account, by index
    /// @param tokenId .
    /// @param index .
    /// @return Checkpoint
    function checkpoints(uint256 tokenId, uint48 index) external view returns (Checkpoint memory);

    /// @inheritdoc IVotes
    function getPastVotes(address account, uint256 tokenId, uint256 timestamp) external view returns (uint256);

    /// @inheritdoc IVotes
    function getPastTotalSupply(uint256 timestamp) external view returns (uint256);

    /*///////////////////////////////////////////////////////////////
                             DAO VOTING LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IVotes
    function delegate(uint256 delegator, uint256 delegatee) external;

    /// @inheritdoc IVotes
    function delegateBySig(
        uint256 delegator,
        uint256 delegatee,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /*//////////////////////////////////////////////////////////////
                              ERC6372 LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IERC6372
    function clock() external view returns (uint48);

    /// @inheritdoc IERC6372
    function CLOCK_MODE() external view returns (string memory);
}


/// @title Protocol ArtProxy
/// @author perfectswap.io
/// @notice Official art proxy to generate Protocol veNFT artwork
contract VeArtProxy is IVeArtProxy {

    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint256 private constant PI          = 3141592653589793238;
    uint256 private constant TWO_PI      = 2 * PI;
    uint256 private constant DASH = 50;
    uint256 private constant DASH_HALF = 25;

    IVotingEscrow public immutable ve;

    /// @dev art palette color codes used in drawing lines
    bytes8[5][10] palettes =
        [[bytes8('#E0A100'),'#CC9200','#A37500','#3C4150','#A3A3A3'], // yellow-gold
        [bytes8('#D40D0D'),'#A10808','#750606','#3C4150','#A3A3A3'], //red
        [bytes8('#03444C'),'#005F6B','#008C9E','#3C4150','#A3A3A3'], //teal
        [bytes8('#1A50F1'),'#1740BB','#102F8B','#3C4150','#A3A3A3'], //blue
        [bytes8('#C5BC8E'),'#696758','#45484b','#3C4150','#A3A3A3'], //silver
        [bytes8('#FD5821'),'#F23E02','#CA3402','#3C4150','#A3A3A3'], //amber
        [bytes8('#b48610'),'#123291','#cf3502','#3C4150','#A3A3A3'], //distinct
        [bytes8('#719E04'),'#8DB92E','#A9D54C','#3C4150','#A3A3A3'], //green
        [bytes8('#110E07'),'#110E07','#3A3935','#3C4150','#A3A3A3'], //black
        [bytes8('#CC1455'),'#A71145','#820D36','#3C4150','#A3A3A3']]; //pink

    bytes2[5] lineThickness =
        [bytes2('0'),
        '1',
        '1',
        '2',
        '2'];

    constructor(address _ve) {
        ve = IVotingEscrow(_ve);
    }

    /// @inheritdoc IVeArtProxy
    function tokenURI (uint256 _tokenId) external view returns (string memory output) {
        Config memory cfg = generateConfig(_tokenId);

        output = string(
            abi.encodePacked(
                '<svg width="350" height="350" viewBox="0 0 4000 4000" fill="none" xmlns="http://www.w3.org/2000/svg">',
                generateShape(cfg),
                '</svg>')
            );

        string memory readableBalance = tokenAmountToString(uint256(cfg._balanceOf));
        string memory readableAmount = tokenAmountToString(uint256(cfg._lockedAmount));

        uint256 year;
	    uint256 month;
	    uint256 day;
        (year, month, day) = BokkyPooBahsDateTimeLibrary.timestampToDate(uint256(cfg._lockedEnd));

        string memory attributes = string(abi.encodePacked(
	        '{ "trait_type": "Unlock Date", "value": "',
	            toString(year), '-', toString(month), '-', toString(day),
	            '"}, ',
	        '{ "trait_type": "Voting Power", "value": "',
	            readableBalance,
	            '"}, ',
	        '{ "trait_type": "Locked PRFCT", "value": "',
	            readableAmount, '"}'
        ));

        string memory json = Base64.encode(
		    bytes(
                string(
                    abi.encodePacked(
			            '{"name": "lock #',
                        toString(cfg._tokenId),
                        '", "background_color": "121a26", "description": "Perfect Swap is a next-generation AMM that combines the best of Curve, Solidly and Uniswap, designed to serve as a central liquidity hub. Protocol NFTs vote on token emissions and receive bribes and fees generated by the protocol.", "image": "data:image/svg+xml;base64,',
                        Base64.encode(bytes(output)), '", ',
                        '"attributes": [', attributes, ']',
			            '}'
                    )
                )
            )
        );

        output = string(abi.encodePacked("data:application/json;base64,", json));
    }

    /// @inheritdoc IVeArtProxy
    function lineArtPathsOnly (uint256 _tokenId) external view returns (bytes memory output) {
        Config memory cfg = generateConfig(_tokenId);
        output = abi.encodePacked(generateShape(cfg));
    }


    /// @inheritdoc IVeArtProxy
    function generateConfig (uint256 _tokenId) public view returns (Config memory cfg) {
        cfg._tokenId = int256(_tokenId);
        cfg._balanceOf = int256(ve.balanceOfNFTAt(_tokenId, block.timestamp));
        IVotingEscrow.LockedBalance memory _locked = ve.locked(_tokenId);
        cfg._lockedEnd = int256(_locked.end);
        cfg._lockedAmount = int256(_locked.amount);

        cfg.shape = seedGen(_tokenId) % 8;
        cfg.palette = getPalette(_tokenId);
        cfg.maxLines = getLineCount(uint256(cfg._balanceOf));
        
        cfg.seed1 = seedGen(_tokenId);
        cfg.seed2 = seedGen(_tokenId * 1e18);
        cfg.seed3 = seedGen(_tokenId * 2e18);
    }

    /// @dev Generates characteristics for each line in the line art.
    function generateLineConfig (Config memory cfg, int256 l) internal view returns (lineConfig memory linecfg) {
        uint256 x = uint256(l);
        linecfg.color = palettes[cfg.palette][uint256(keccak256(abi.encodePacked((l + 20) * (cfg._lockedEnd + cfg._tokenId)))) % 5];
        linecfg.stroke = uint256(keccak256(abi.encodePacked((l + 1) * (cfg._lockedEnd + cfg._tokenId)))) % 5;
        linecfg.offset = uint256(keccak256(abi.encodePacked((l + 1) * (cfg._lockedEnd + cfg._tokenId)))) % 50 / 2 * 2 * 5; // ensure value is even
        linecfg.offsetHalf = linecfg.offset / 2 * 5;
        linecfg.offsetDashSum = linecfg.offset + DASH + linecfg.offsetHalf + DASH_HALF;
        if ((uint256(cfg.seed2) / (1 + x)) % 6 != 0) {
            linecfg.pathLength = linecfg.offsetDashSum * (10 + (uint256(cfg.seed1 * cfg.seed3) / (1 + x * x)) % 15);
        }
    }
       
    /// @dev Selects and draws line art shape.
    function generateShape (Config memory cfg) internal view returns (bytes memory shape) {
        if (cfg.shape == 0) {
            shape = drawCircles(cfg);
        }
        else if (cfg.shape == 1) {
            shape = drawTwoStripes(cfg);
        }
        else if (cfg.shape == 2) {
            shape = drawInterlockingCircles(cfg);
        }
        else if (cfg.shape == 3) {
            shape = drawCorners(cfg);
        }
        else if (cfg.shape == 4) {
            shape = drawCurves(cfg);
        }
        else if (cfg.shape == 5) {
            shape = drawSpiral(cfg);
        }
        else if (cfg.shape == 6) {
            shape = drawExplosion(cfg);
        }
        else {
            shape = drawWormhole(cfg);
        }
    }
        
    /// @dev Calculates the number of digits before the "decimal point" in an NFT's vePRFCT balance.
    ///      Input expressed in 1e18 format.
    function numBalanceDigits (uint256 _balanceOf) internal pure returns (int256 digitCount) {
        uint256 convertedvePRFCTvalue = _balanceOf / 1e18;
        while (convertedvePRFCTvalue != 0) {
            convertedvePRFCTvalue /= 10;
            digitCount++;
        }
    }

    /// @dev Generates a pseudorandom seed based on a veNFT token ID.
    function seedGen (uint256 _tokenId) internal pure returns (int256 seed) {
        seed = 1 + int256(uint256(keccak256(abi.encodePacked(_tokenId))) % 999);
    }

    /// @dev Determines the number of lines in the SVG. NFTs with less than 10 vePRFCT balance have zero lines.
    function getLineCount (uint256 _balanceOf) internal pure returns (int256 lineCount) {
        int256 threshhold = 2;
        lineCount = 4 * numBalanceDigits(_balanceOf);
        if (numBalanceDigits(_balanceOf) < threshhold) {
            lineCount = 0;
        }
    }

    /// @dev Determines the color palette of the SVG.
    function getPalette (uint256 _tokenId) internal pure returns (uint256 palette) {
        palette = uint256(keccak256(abi.encodePacked(_tokenId))) % 10;
    }

/*---
Line Art Generation
---*/

    function drawTwoStripes (Config memory cfg) internal view returns (bytes memory shape) {
        for (int256 l = 0; l < cfg.maxLines; l++) {
            Point[100] memory Line = twoStripes(cfg, l);
            shape = abi.encodePacked(shape, curveToSVG(l, cfg, Line));
        }
    }

    /// @inheritdoc IVeArtProxy
    function twoStripes(Config memory cfg, int256 l) public pure returns (Point[100] memory Line) {
        int256 k = ((l % 2) * ((200 + cfg.seed3) + (l * 1250 / cfg.maxLines)) + ((l + 1) % 2) * ((2200 + cfg.seed2) + (l * 1250 / cfg.maxLines)));
        int256 i1 = cfg.seed1 % 2;
        int256 i2 = (cfg.seed1 + 1) % 2;
        int256 o1 = i1 * k;
        int256 o2 = i2 * k;

        for (int256 p = 0; p < 100; p++) {
            Line[uint256(p)] = Point({
                x: 41 * p * i2 + o1,
                y: 41 * p * i1 + o2
            });
        }
    }

    function drawCircles (Config memory cfg) internal view returns (bytes memory shape) { 
        for (int256 l = 0; l < cfg.maxLines; l++) {
            Point[100] memory Line = circles(cfg, l);
            shape = abi.encodePacked(shape, curveToSVG(l, cfg, Line));
        }
    }

    /// @inheritdoc IVeArtProxy
    function circles(Config memory cfg, int256 l) public pure returns (Point[100] memory Line) {
        int256 baseX = 500 + (cfg.seed1 % 100 * 30);
        int256 baseY = 500 + (cfg.seed2 % 100 * 30);
        int256 k  = (cfg.seed3 % 250) + 250 + 100 * (1 + l);
        int256 i = (l % 2) * 2 - 1;

        for (uint256 p = 0; p < 100; p++) {
            uint256 angle = 1e18 * TWO_PI * p / 99;
            Line[p] = Point({
                x: baseX +     k * Trig.sin(angle) / 1e18,
                y: baseY + i * k * Trig.cos(angle) / 1e18
            });
        }        
    }

    function drawInterlockingCircles (Config memory cfg) internal view returns (bytes memory shape) { 
        for (int256 l = 0; l < cfg.maxLines; l++) {
            Point[100] memory Line = interlockingCircles(cfg, l);
            shape = abi.encodePacked(shape, curveToSVG(l, cfg, Line));
        }
    }

    /// @inheritdoc IVeArtProxy
    function interlockingCircles(Config memory cfg, int256 l) public pure returns (Point[100] memory Line) {
        int256 baseX = (1500 + cfg.seed1) + (l * 100) * Trig.dcos(90 * l) / 1e6;
        int256 baseY = (1500 + cfg.seed2) + (l * 100) * Trig.dsin(90 * l) / 1e6;
        int256 k = (l + 1) * 100;

        for (uint256 p = 0; p < 100; p++) {
            uint256 angle = 1e18 * TWO_PI * p / 99;
            Line[p] = Point({
                x: baseX + k * Trig.cos(angle) / 1e18,                                   
                y: baseY + k * Trig.sin(angle) / 1e18
            });
        }
    }

    function drawCorners (Config memory cfg) internal view returns (bytes memory shape) { 
        for (int256 l = 0; l < cfg.maxLines; l++) {
            Point[100] memory Line = corners(cfg, l);
            shape = abi.encodePacked(shape, curveToSVG(l, cfg, Line));
        }
    }

    /// @inheritdoc IVeArtProxy
   function corners(Config memory cfg, int256 l) public pure returns (Point[100] memory Line) {
        int256 degrees1 = 360 * cfg.seed1 / 1000;
        int256 degrees2 = 360 * (cfg.seed1 + 500) / 1000;
        int256 baseX = 2000 + ((l % 2) * 1200 * Trig.dcos(degrees1) / 1e6) + (((l + 1) % 2) * (1200 * Trig.dcos(degrees2)) / 1e6);
        int256 baseY = 2000 + ((l % 2) * 1200 * Trig.dsin(degrees1) / 1e6) + (((l + 1) % 2) * (1200 * Trig.dsin(degrees2)) / 1e6);
        int256 k = 100 + (1 + l) * 4000 / cfg.maxLines / 4;

        for (int256 p = 0; p < 100; p++) {
            int256 angle3 = 360 * l / cfg.maxLines + (360 * p / 99);
            Line[uint256(p)] = Point({
                x: baseX +                     k * Trig.dcos(angle3) / 1e6,
                y: baseY + ((l % 2) * 2 - 1) * k * Trig.dsin(angle3) / 1e6
            });
        }
    }

    function drawCurves (Config memory cfg) internal view returns (bytes memory shape) { 
        for (int256 l = 0; l < cfg.maxLines; l++) {
            Point[100] memory Line = curves(cfg, l);
            shape = abi.encodePacked(shape, curveToSVG(l, cfg, Line));
        }
    }

    /// @inheritdoc IVeArtProxy
    function curves(Config memory cfg, int256 l) public pure returns (Point[100] memory Line) {
        int256 x = l * 65536 / 150;
        int256 z = cfg.seed1 * 65536;
        int256 k1 = (cfg.seed1 + 1) % 2;
        int256 k2 = cfg.seed1 % 2;
        int256 kA2 = -100 + 4200 * l / cfg.maxLines;
    
        for (int256 p = 0; p < 100; p++) {
            int256 _sin = Trig.sin(1e18 * TWO_PI * uint256(p) / 99);
            int256 noise = PerlinNoise.noise3d(x, p * 65536 / 2000, z);
            int256 a1 = (-100 + 4200 * p / 99) + _sin * noise * 1700 / 65536 / 1e18;
            int256 a2 = kA2                    + _sin * noise * 15000 / 65536 / 1e18;

            Line[uint256(p)] = Point({
                x: k1 * a1 + k2 * a2,
                y: k1 * a2 + k2 * a1
            });
        }
    }

    function drawSpiral (Config memory cfg) internal view returns (bytes memory shape) { 
        for (int256 l = 0; l < cfg.maxLines; l++) {
            Point[100] memory Line = spiral(cfg, l);
            shape = abi.encodePacked(shape, curveToSVG(l, cfg, Line));
        }
    }

    /// @inheritdoc IVeArtProxy
    function spiral(Config memory cfg, int256 l) public pure returns (Point[100] memory Line) {
        int256 baseX = 500 + (cfg.seed1 % 100 * 30);
        int256 baseY = 500 + (cfg.seed2 % 100 * 30);
        int256 degrees1 = 360 * l / cfg.maxLines;
        int256 cosine = Trig.dcos(degrees1);
        int256 sine = Trig.dsin(degrees1);

        for (int256 p = 0; p < 100; p++) {
            int256 degrees2 = degrees1 + 3 * p;            
            Line[uint256(p)] = Point({
                x: baseX + (325 * cosine / 1e6) + (40 * p) * Trig.dcos(degrees2) / 1e6,
                y: baseY + (325 * sine   / 1e6) + (40 * p) * Trig.dsin(degrees2) / 1e6
            });
        }
    }

    function drawExplosion (Config memory cfg) internal view returns (bytes memory shape) { 
        for (int256 l = 0; l < cfg.maxLines; l++) {
            Point[100] memory Line = explosion(cfg, l);
            shape = abi.encodePacked(shape, curveToSVG(l, cfg, Line));
        }
    }

    /// @inheritdoc IVeArtProxy
    function explosion(Config memory cfg, int256 l) public pure returns (Point[100] memory Line) {
        int256 baseX = 1000 + (cfg.seed1 % 100 * 20);
        int256 baseY = 1000 + (cfg.seed2 % 100 * 20);
        int256 degrees = 360 * l / cfg.maxLines;
        int256 k = 300 + (cfg.seed3 * (l + 1) ** 2) % 300;
        int256 cosine = Trig.dcos(degrees);
        int256 sine = Trig.dsin(degrees);        

        for (int256 p = 0; p < 100; p++) {
            Line[99 - uint256(p)] = Point({
                x: baseX + k * cosine / 1e6 + (4000 * p / 99) * cosine / 1e6,
                y: baseY + k * sine   / 1e6 + (4000 * p / 99) * sine   / 1e6
            });
        }
    }

    function drawWormhole(Config memory cfg) internal view returns (bytes memory shape) { 
        for (int256 l = 0; l < cfg.maxLines; l++) {
            Point[100] memory Line = wormhole(cfg, l);
            shape = abi.encodePacked(shape, curveToSVG(l, cfg, Line));
        }
    }

    /// @inheritdoc IVeArtProxy
    function wormhole(Config memory cfg, int256 l) public pure returns (Point[100] memory Line) {
        int256 baseX = 500 + (cfg.seed1 * 3);
        int256 baseY = 500 + (cfg.seed2 * 3);
        int256 degrees = 360 * l / cfg.maxLines;
        int256 cosine = Trig.dcos(degrees);
        int256 sine = Trig.dsin(degrees);
        int256 k1 = 3500 - cfg.seed1 * 3;
        int256 k2 = 3500 - cfg.seed2 * 3;
                
        for (int256 p = 0; p < 100; p++) {
            Line[uint256(p)] = Point({
                x: baseX * (99 - p) / 99 + 250 * cosine / 1e6 +  cosine * (5000 * p / 99) * (99 - p) / 99 / 1e6 + p * k1 / 99,
                y: baseY * (99 - p) / 99 + 250 * sine   / 1e6 +  sine   * (5000 * p / 99) * (99 - p) / 99 / 1e6 + p * k2 / 99
            });
        }
    }

/*---
SVG Formatting
---*/

    /// @dev Converts an array of Point structs into an animated SVG path.
    function curveToSVG (int256 l, Config memory cfg, Point[100] memory Line) internal view returns (bytes memory SVGLine) {
        string memory lineBulk;
        bool priorPointOutOfCanvas = false;
        for (uint256 i = 1; i < Line.length; i++) {
            (int256 x, int256 y) = (Line[i].x, Line[i].y);
            if (x > -200 && x < 4200 && y > -200 && y < 4200) {
                if (priorPointOutOfCanvas) {
                    lineBulk = string.concat(lineBulk, "M", toString(x), ",", toString(y));
                    priorPointOutOfCanvas = false;
                } else {
                    lineBulk = string.concat(lineBulk, "L", toString(x), ",", toString(y));
                    priorPointOutOfCanvas = false;
                }
            } else {
                priorPointOutOfCanvas = true;
            }
        }
 
        lineConfig memory linecfg = generateLineConfig(cfg, l);
        {
            SVGLine = abi.encodePacked(
                '<path d="M',
                toString(Line[0].x), ',',toString(Line[0].y),
                lineBulk, '"',
                ' style="stroke-dasharray: ',
                toString(linecfg.offset), ',',
                toString(DASH), ',',
                toString(linecfg.offsetHalf), ',',
                toString(DASH_HALF), ';',
                ' --offset: '
            );
        }
 
        {
            SVGLine = abi.encodePacked(
                SVGLine,
                toString(linecfg.offsetDashSum), ';',
                ' stroke: ',
                linecfg.color, ';',
                ' stroke-width:',
                lineThickness[linecfg.stroke], '%',';" pathLength="',
                toString(linecfg.pathLength), '">',
                '<animate attributeName="stroke-dashoffset" values="0;',
                toString(linecfg.offsetDashSum), '" ',
                'dur="4s" calcMode="linear" repeatCount="indefinite" /></path>'
            );
        }
    }

/*---
Utility
---*/

    /// @dev Converts token amount to string with one decimal place.
    function tokenAmountToString(uint256 value) internal pure returns (string memory) {
        uint256 leftOfDecimal = value / 10**18;
        uint256 residual = value % 10**18;
        // show one decimal place
        uint256 rightOfDecimal = residual / 10**17;
        string memory s;
        if (residual > 0) {
            s = string(abi.encodePacked(toString(leftOfDecimal), ".", toString(rightOfDecimal)));
         } else {
            s = toString(leftOfDecimal);
        }
        return s;
    }

/*---
OpenZeppelin Functions
---*/

    /**
     * @dev Converts a `int256` to its ASCII `string` decimal representation.
     */
    function toString(int256 value) internal pure returns (string memory) {
        return string(abi.encodePacked(value < 0 ? "-" : "", toString(abs(value))));
    }

    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }
}