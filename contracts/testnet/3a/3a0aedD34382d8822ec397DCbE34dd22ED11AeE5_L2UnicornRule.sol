// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {IL2UnicornRule} from "../interfaces/IL2UnicornRule.sol";

import {L2UnicornPeriphery} from "../libraries/L2UnicornPeriphery.sol";

contract L2UnicornRule is IL2UnicornRule {

    function getHatchRuleNone() public pure returns (HatchRule memory) {
        return HatchRule(0, 0, 0, 0, 0, 0, 0, 0, 0);
    }

    function getHatchRuleByLevel(uint8 level_) public pure returns (HatchRule memory) {
        //startRandomNumE0,endRandomNumE0,startRandomNumE1,endRandomNumE1,startTokenId,endTokenId,tokenIdTotalSupply,awardAmount
        if (level_ == 0) {
            return HatchRule(0, 0, 578668, 0, 728988, 1000000000000, 1299999999999, 300000000000, 0);
        } else if (level_ == 1) {
            return HatchRule(1, 578669, 778668, 0, 0, 100000000000, 129999999999, 30000000000, 50);
        } else if (level_ == 2) {
            return HatchRule(2, 778669, 978668, 0, 0, 10000000000, 19999999999, 10000000000, 200);
        } else if (level_ == 3) {
            return HatchRule(3, 978669, 998668, 0, 0, 1000000000, 3999999999, 3000000000, 500);
        } else if (level_ == 4) {
            return HatchRule(4, 998669, 999668, 728989, 928988, 100000000, 399999999, 300000000, 1000);
        } else if (level_ == 5) {
            return HatchRule(5, 999669, 999868, 928989, 988988, 10000000, 39999999, 30000000, 5000);
        } else if (level_ == 6) {
            return HatchRule(6, 999869, 999968, 988989, 998988, 1000000, 3999999, 3000000, 10000);
        } else if (level_ == 7) {
            return HatchRule(7, 999969, 999988, 998989, 999988, 100000, 399999, 300000, 50000);
        } else if (level_ == 8) {
            return HatchRule(8, 999989, 999998, 999989, 999998, 10000, 39999, 30000, 100000);
        } else if (level_ == 9) {
            return HatchRule(9, 999999, 999999, 999999, 999999, 0, 2999, 3000, 1000000);
        } else {
            return getHatchRuleNone();
        }
    }

    /**
    * @param randomNum Random Number
    * @param eSeries E Series
    */
    function getHatchRule(uint256 randomNum, uint256 eSeries) external pure returns (HatchRule memory) {
        for (uint8 level_ = 0; level_ < 9;) {
            HatchRule memory hatchRule = getHatchRuleByLevel(level_);
            if (randomNum >= hatchRule.startRandomNumE0 && randomNum <= hatchRule.endRandomNumE0 && eSeries == L2UnicornPeriphery.E_SERIES_0) {
                return hatchRule;
            } else if (randomNum >= hatchRule.startRandomNumE1 && randomNum <= hatchRule.endRandomNumE1 && eSeries == L2UnicornPeriphery.E_SERIES_1) {
                return hatchRule;
            }
            unchecked{++level_;}
        }
        return getHatchRuleNone();
    }

    /**
    * @param tokenId NFT TokenId
    */
    function getHatchRule(uint256 tokenId) external pure returns (HatchRule memory) {
        for (uint8 level_ = 0; level_ < 9;) {
            HatchRule memory hatchRule = getHatchRuleByLevel(level_);
            if (tokenId >= hatchRule.startTokenId && tokenId <= hatchRule.endTokenId) {
                return hatchRule;
            }
            unchecked{++level_;}
        }
        return getHatchRuleNone();
    }

    /**
    * @dev 进化
    * @param currentLevel_ Current Level
    * @param randomNum_ Random Number
    */
    function getHatchRuleOfEvolve(uint8 currentLevel_, uint256 randomNum_) public pure returns (HatchRule memory) {
        for (uint8 levelIndex_ = 0; levelIndex_ < 9;) {
            EvolveRule memory evolveRule = getEvolveRule(currentLevel_, levelIndex_);
            if (randomNum_ >= evolveRule.startRandomNum && randomNum_ <= evolveRule.endRandomNum) {
                return getHatchRuleByLevel(evolveRule.level);
            }
            unchecked{++levelIndex_;}
        }
        return getHatchRuleNone();
    }

    function getEvolveRule(uint8 currentLevel_, uint8 levelIndex_) public pure returns (EvolveRule memory) {
        if (currentLevel_ == 1) {
            if (levelIndex_ == 0) {
                return EvolveRule(0, 0, 808668);
            } else if (levelIndex_ == 1) {
                return EvolveRule(1, 808669, 908668);
            } else if (levelIndex_ == 2) {
                return EvolveRule(2, 908669, 988668);
            } else if (levelIndex_ == 3) {
                return EvolveRule(3, 988669, 998668);
            } else if (levelIndex_ == 4) {
                return EvolveRule(4, 998669, 999668);
            } else if (levelIndex_ == 5) {
                return EvolveRule(5, 999669, 999868);
            } else if (levelIndex_ == 6) {
                return EvolveRule(6, 999869, 999968);
            } else if (levelIndex_ == 7) {
                return EvolveRule(7, 999969, 999988);
            } else if (levelIndex_ == 8) {
                return EvolveRule(8, 999989, 999998);
            } else if (levelIndex_ == 9) {
                return EvolveRule(9, 999999, 999999);
            }
        } else if (currentLevel_ == 2) {
            if (levelIndex_ == 0) {
                return EvolveRule(0, 0, 619668);
            } else if (levelIndex_ == 1) {
                return EvolveRule(1, 619669, 719668);
            } else if (levelIndex_ == 2) {
                return EvolveRule(2, 719669, 819668);
            } else if (levelIndex_ == 3) {
                return EvolveRule(3, 819669, 979668);
            } else if (levelIndex_ == 4) {
                return EvolveRule(4, 979669, 999668);
            } else if (levelIndex_ == 5) {
                return EvolveRule(5, 999669, 999868);
            } else if (levelIndex_ == 6) {
                return EvolveRule(6, 999869, 999968);
            } else if (levelIndex_ == 7) {
                return EvolveRule(7, 999969, 999988);
            } else if (levelIndex_ == 8) {
                return EvolveRule(8, 999989, 999998);
            } else if (levelIndex_ == 9) {
                return EvolveRule(9, 999999, 999999);
            }
        } else if (currentLevel_ == 3) {
            if (levelIndex_ == 0) {
                return EvolveRule(0, 0, 490868);
            } else if (levelIndex_ == 1) {
                return EvolveRule(1, 490869, 590868);
            } else if (levelIndex_ == 2) {
                return EvolveRule(2, 590869, 690868);
            } else if (levelIndex_ == 3) {
                return EvolveRule(3, 690869, 790868);
            } else if (levelIndex_ == 4) {
                return EvolveRule(4, 790869, 990868);
            } else if (levelIndex_ == 5) {
                return EvolveRule(5, 990869, 999868);
            } else if (levelIndex_ == 6) {
                return EvolveRule(6, 999869, 999968);
            } else if (levelIndex_ == 7) {
                return EvolveRule(7, 999969, 999988);
            } else if (levelIndex_ == 8) {
                return EvolveRule(8, 999989, 999998);
            } else if (levelIndex_ == 9) {
                return EvolveRule(9, 999999, 999999);
            }
        } else if (currentLevel_ == 4) {
            if (levelIndex_ == 0) {
                return EvolveRule(0, 0, 512968);
            } else if (levelIndex_ == 1) {
                return EvolveRule(1, 512969, 612968);
            } else if (levelIndex_ == 2) {
                return EvolveRule(2, 612969, 712968);
            } else if (levelIndex_ == 3) {
                return EvolveRule(3, 712969, 812968);
            } else if (levelIndex_ == 4) {
                return EvolveRule(4, 812969, 912968);
            } else if (levelIndex_ == 5) {
                return EvolveRule(5, 912969, 992968);
            } else if (levelIndex_ == 6) {
                return EvolveRule(6, 992969, 999968);
            } else if (levelIndex_ == 7) {
                return EvolveRule(7, 999969, 999988);
            } else if (levelIndex_ == 8) {
                return EvolveRule(8, 999989, 999998);
            } else if (levelIndex_ == 9) {
                return EvolveRule(9, 999999, 999999);
            }
        } else if (currentLevel_ == 5) {
            if (levelIndex_ == 0) {
                return EvolveRule(0, 0, 288988);
            } else if (levelIndex_ == 1) {
                return EvolveRule(1, 288989, 388988);
            } else if (levelIndex_ == 2) {
                return EvolveRule(2, 388989, 488988);
            } else if (levelIndex_ == 3) {
                return EvolveRule(3, 488989, 588988);
            } else if (levelIndex_ == 4) {
                return EvolveRule(4, 588989, 688988);
            } else if (levelIndex_ == 5) {
                return EvolveRule(5, 688989, 788988);
            } else if (levelIndex_ == 6) {
                return EvolveRule(6, 788989, 988988);
            } else if (levelIndex_ == 7) {
                return EvolveRule(7, 988989, 999988);
            } else if (levelIndex_ == 8) {
                return EvolveRule(8, 999989, 999998);
            } else if (levelIndex_ == 9) {
                return EvolveRule(9, 999999, 999999);
            }
        } else if (currentLevel_ == 6) {
            if (levelIndex_ == 0) {
                return EvolveRule(0, 0, 313998);
            } else if (levelIndex_ == 1) {
                return EvolveRule(1, 313999, 413998);
            } else if (levelIndex_ == 2) {
                return EvolveRule(2, 413999, 513998);
            } else if (levelIndex_ == 3) {
                return EvolveRule(3, 513999, 613998);
            } else if (levelIndex_ == 4) {
                return EvolveRule(4, 613999, 713998);
            } else if (levelIndex_ == 5) {
                return EvolveRule(5, 713999, 813998);
            } else if (levelIndex_ == 6) {
                return EvolveRule(6, 813999, 913998);
            } else if (levelIndex_ == 7) {
                return EvolveRule(7, 913999, 989998);
            } else if (levelIndex_ == 8) {
                return EvolveRule(8, 989999, 999998);
            } else if (levelIndex_ == 9) {
                return EvolveRule(9, 999999, 999999);
            }
        }
        return EvolveRule(0, 0, 0);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IL2UnicornRule {

    struct HatchRule {
        uint8 level;
        uint256 startRandomNumE0;
        uint256 endRandomNumE0;
        uint256 startRandomNumE1;
        uint256 endRandomNumE1;
        uint256 startTokenId;
        uint256 endTokenId;
        uint256 tokenIdTotalSupply;
        uint256 awardAmount;
    }

    struct EvolveRule {
        uint8 level;
        uint256 startRandomNum;
        uint256 endRandomNum;
    }

    function getHatchRuleNone() external pure returns (HatchRule memory);

    function getHatchRuleByLevel(uint8 level_) external pure returns (HatchRule memory);

    function getHatchRule(uint256 randomNum, uint256 eSeries) external pure returns (HatchRule memory);

    function getHatchRule(uint256 tokenId) external pure returns (HatchRule memory);

    function getHatchRuleOfEvolve(uint8 currentLevel_, uint256 randomNum_) external pure returns (HatchRule memory);

    function getEvolveRule(uint8 currentLevel_, uint8 levelIndex_) external pure returns (EvolveRule memory);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

library L2UnicornPeriphery {

    uint8 public constant E_SERIES_0 = 0;

    uint8 public constant E_SERIES_1 = 1;

    uint256 public constant R_SERIAL_MOD_NUMBER = 1000000;

}