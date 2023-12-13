/**
 *Submitted for verification at Arbiscan.io on 2023-12-11
*/

// Sources flattened with hardhat v2.13.0 https://hardhat.org

// File contracts/chance/pokerBaccarat/PokerCard.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract PokerCard {
    // uint8 rank 2-14
    // uint8 suit 0-3
    function getPoker(uint8 number) public pure returns (uint8 /* rank */, uint8 /* suit */) {
        require(number >= 8 && number <= 59, "getPoker error");
        return (number / 4, number % 4);
    }
}


// File contracts/chance/pokerBaccarat/PokerRecognizer.sol

// 
pragma solidity ^0.8.0;
contract PokerRecognizer is PokerCard {
    // 0: high card
    // 1: one pair
    // 2: two pair
    // 3: three of a kind
    // 4: straight
    // 5: flush
    // 6: full house
    // 7: four of a kind
    // 8: straight flush
    // 9: royal flush
    struct Recognizer {
        uint8[7] flush; // 2-14,,0
        uint8[7] rankCard7; // 2-14
        uint8[5] rankCard5; // 2-14
        uint8 level; // 0-9
    }

    function shuffle(
        uint256 currentRound,
        uint256 randomWord
    )
        external
        pure
        returns (
            uint8[2] memory holeOfBanker,
            uint8[2] memory holeOfPlayer,
            uint8[5] memory community,
            Recognizer memory bankerRecognizer,
            Recognizer memory playerRecognizer
        )
    {
        uint8[52] memory pokerList = [
            8,
            9,
            10,
            11,
            12,
            13,
            14,
            15,
            16,
            17,
            18,
            19,
            20,
            21,
            22,
            23,
            24,
            25,
            26,
            27,
            28,
            29,
            30,
            31,
            32,
            33,
            34,
            35,
            36,
            37,
            38,
            39,
            40,
            41,
            42,
            43,
            44,
            45,
            46,
            47,
            48,
            49,
            50,
            51,
            52,
            53,
            54,
            55,
            56,
            57,
            58,
            59
        ];
        for (uint8 i = 0; i < 52; ++i) {
            uint8 index = uint8(uint256(keccak256(abi.encodePacked(randomWord, i, currentRound))) % 52);
            (pokerList[i], pokerList[index]) = (pokerList[index], pokerList[i]);
        }
        holeOfBanker = [pokerList[1], pokerList[3]];
        holeOfPlayer = [pokerList[0], pokerList[2]];
        community = [pokerList[5], pokerList[6], pokerList[7], pokerList[9], pokerList[11]];
        bankerRecognizer = generatePokerRecognizer(holeOfBanker, community);
        playerRecognizer = generatePokerRecognizer(holeOfPlayer, community);
    }

    function generatePokerRecognizer(
        uint8[2] memory hole,
        uint8[5] memory community
    ) public pure returns (Recognizer memory recognizer) {
        uint8[7] memory rankList;
        uint8[7] memory suitList;
        (rankList, suitList) = mergeAndSort(hole, community);

        // Process 5,8,9
        recognizer = findFlush(rankList, suitList);
        if (recognizer.level == 5) {
            recognizer = findStraightFlush(recognizer);
            return recognizer;
        }

        // fix rankCount
        uint8[15] memory rankCount;
        for (uint8 i = 0; i < 7; ++i) {
            ++rankCount[recognizer.rankCard7[i]];
        }

        // Process 6,7
        recognizer = findFourOfAKindAndFullHouse(recognizer, rankCount);
        if (recognizer.level > 5) {
            return recognizer;
        }

        // Process 4
        recognizer = findStraight(recognizer, rankCount);
        if (recognizer.level == 4) {
            return recognizer;
        }

        // Process 0,1,2,3
        recognizer = findOthers(recognizer, rankCount);
    }

    function findFlush(
        uint8[7] memory rankList,
        uint8[7] memory suitList
    ) private pure returns (Recognizer memory recognizer) {
        uint8[4] memory suitCount;
        recognizer.rankCard7 = rankList;
        for (uint8 i = 0; i < 7; ++i) {
            ++suitCount[suitList[i]];
        }

        for (uint8 i = 0; i < 4; ++i) {
            if (suitCount[i] >= 5) {
                recognizer.level = 5;
                uint8 k;
                for (uint8 j = 0; j < 7; ++j) {
                    if (suitList[j] == i) {
                        recognizer.flush[k] = rankList[j];
                        if (k < 5) {
                            recognizer.rankCard5[k] = rankList[j];
                        }
                        ++k;
                    }
                }
                break;
            }
        }
    }

    function findStraightFlush(Recognizer memory recognizer_) private pure returns (Recognizer memory recognizer) {
        recognizer = recognizer_;
        uint8 count;
        uint8[15] memory rankCount;
        for (uint8 i = 0; i < 7; ++i) {
            ++rankCount[recognizer.flush[i]];
        }
        for (uint8 i = 14; i > 1; --i) {
            if (rankCount[i] != 0) {
                ++count;
            } else {
                count = 0;
            }
            if (count == 5) {
                recognizer.rankCard5[4] = i;
                recognizer.rankCard5[3] = i + 1;
                recognizer.rankCard5[2] = i + 2;
                recognizer.rankCard5[1] = i + 3;
                recognizer.rankCard5[0] = i + 4;
                if (recognizer.rankCard5[0] == 14) {
                    recognizer.level = 9;
                } else {
                    recognizer.level = 8;
                }
                return recognizer;
            }
        }

        // find 5432A
        if (rankCount[5] == 1 && rankCount[4] == 1 && rankCount[3] == 1 && rankCount[2] == 1 && rankCount[14] == 1) {
            recognizer.level = 8;
            recognizer.rankCard5 = [5, 4, 3, 2, 14];
        }
    }

    function findFourOfAKindAndFullHouse(
        Recognizer memory recognizer_,
        uint8[15] memory rankCount
    ) private pure returns (Recognizer memory recognizer) {
        recognizer = recognizer_;
        // find four of a kind
        for (uint8 i = 14; i > 1; --i) {
            if (rankCount[i] == 4) {
                recognizer.rankCard5[0] = i;
                recognizer.rankCard5[1] = i;
                recognizer.rankCard5[2] = i;
                recognizer.rankCard5[3] = i;
                for (uint8 j = 0; j < 7; ++j) {
                    if (recognizer.rankCard7[j] != i) {
                        recognizer.rankCard5[4] = recognizer.rankCard7[j];
                        recognizer.level = 7;
                        return recognizer;
                    }
                }
            }
        }

        // find full house
        uint8[2] memory tmp;
        for (uint8 i = 14; i > 1; --i) {
            if (rankCount[i] == 3) {
                if (tmp[0] == 0) {
                    tmp[0] = i;
                } else if (tmp[1] == 0) {
                    tmp[1] = i;
                    break;
                }
            }

            if (rankCount[i] == 2 && tmp[1] == 0) {
                tmp[1] = i;
            }
        }

        if (tmp[0] > 0 && tmp[1] > 0) {
            recognizer.rankCard5[0] = tmp[0];
            recognizer.rankCard5[1] = tmp[0];
            recognizer.rankCard5[2] = tmp[0];
            recognizer.rankCard5[3] = tmp[1];
            recognizer.rankCard5[4] = tmp[1];
            recognizer.level = 6;
            return recognizer;
        }
    }

    function findStraight(
        Recognizer memory recognizer_,
        uint8[15] memory rankCount
    ) private pure returns (Recognizer memory recognizer) {
        recognizer = recognizer_;
        uint8 count;
        for (uint8 i = 14; i > 1; --i) {
            if (rankCount[i] != 0) {
                ++count;
            } else {
                count = 0;
            }
            if (count == 5) {
                recognizer.rankCard5[4] = i;
                recognizer.rankCard5[3] = i + 1;
                recognizer.rankCard5[2] = i + 2;
                recognizer.rankCard5[1] = i + 3;
                recognizer.rankCard5[0] = i + 4;
                recognizer.level = 4;
                return recognizer;
            }
        }

        // find 5432A
        if (rankCount[5] != 0 && rankCount[4] != 0 && rankCount[3] != 0 && rankCount[2] != 0 && rankCount[14] != 0) {
            recognizer.level = 4;
            recognizer.rankCard5 = [5, 4, 3, 2, 14];
        }
    }

    function findOthers(
        Recognizer memory recognizer_,
        uint8[15] memory rankCount
    ) private pure returns (Recognizer memory recognizer) {
        recognizer = recognizer_;
        // find three of a kind
        for (uint8 i = 14; i > 1; --i) {
            if (rankCount[i] == 3) {
                recognizer.rankCard5[0] = i;
                recognizer.rankCard5[1] = i;
                recognizer.rankCard5[2] = i;
                for (uint8 j = 0; j < 7; ++j) {
                    if (recognizer.rankCard7[j] != i) {
                        if (recognizer.rankCard5[3] == 0) {
                            recognizer.rankCard5[3] = recognizer.rankCard7[j];
                        } else {
                            recognizer.rankCard5[4] = recognizer.rankCard7[j];
                            recognizer.level = 3;
                            return recognizer;
                        }
                    }
                }
            }
        }

        // find two pair
        uint8[2] memory tmp;
        for (uint8 i = 14; i > 1; --i) {
            if (rankCount[i] == 2) {
                if (tmp[0] == 0) {
                    tmp[0] = i;
                    recognizer.rankCard5[0] = i;
                    recognizer.rankCard5[1] = i;
                } else {
                    tmp[1] = i;
                    recognizer.rankCard5[2] = i;
                    recognizer.rankCard5[3] = i;
                    for (uint8 j = 0; j < 7; ++j) {
                        if (recognizer.rankCard7[j] != tmp[0] && recognizer.rankCard7[j] != tmp[1]) {
                            recognizer.rankCard5[4] = recognizer.rankCard7[j];
                            recognizer.level = 2;
                            return recognizer;
                        }
                    }
                }
            }
        }

        if (tmp[0] != 0) {
            // find one pair
            for (uint8 j = 0; j < 7; ++j) {
                if (recognizer.rankCard7[j] != tmp[0]) {
                    if (recognizer.rankCard5[2] == 0) {
                        recognizer.rankCard5[2] = recognizer.rankCard7[j];
                    } else if (recognizer.rankCard5[3] == 0) {
                        recognizer.rankCard5[3] = recognizer.rankCard7[j];
                    } else if (recognizer.rankCard5[4] == 0) {
                        recognizer.rankCard5[4] = recognizer.rankCard7[j];
                        recognizer.level = 1;
                        return recognizer;
                    }
                }
            }
        } else {
            // find high card
            for (uint8 j = 0; j < 5; ++j) {
                recognizer.rankCard5[j] = recognizer.rankCard7[j];
            }
            // default recognizer.level is 0
        }
    }

    function mergeAndSort(
        uint8[2] memory hole,
        uint8[5] memory community
    ) private pure returns (uint8[7] memory rankList, uint8[7] memory suitList) {
        uint8[7] memory sortedCards;
        sortedCards[0] = hole[0];
        sortedCards[1] = hole[1];
        sortedCards[2] = community[0];
        sortedCards[3] = community[1];
        sortedCards[4] = community[2];
        sortedCards[5] = community[3];
        sortedCards[6] = community[4];

        // Sorting the merged array in descending order
        for (uint256 i = 0; i < 7; ++i) {
            for (uint256 j = i + 1; j < 7; ++j) {
                if (sortedCards[i] < sortedCards[j]) {
                    (sortedCards[i], sortedCards[j]) = (sortedCards[j], sortedCards[i]);
                }
            }
            (rankList[i], suitList[i]) = getPoker(sortedCards[i]);
        }
    }
}