// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {IL2UnicornRule} from "../interfaces/IL2UnicornRule.sol";

contract L2UnicornRule is IL2UnicornRule, Ownable {

    uint256 public modNumber;

    constructor() {
        modNumber = 1000000;
    }

    function setModNumber() external onlyOwner {
        modNumber = modNumber;
    }

    function getHatchRuleNone() public pure returns (HatchRule memory) {
        return HatchRule(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
    }

    /**
    * @param level_ Level
    */
    function getHatchRuleByLevel(uint8 level_) public pure returns (HatchRule memory) {
        //startRandomNumE0,endRandomNumE0,startRandomNumE1,endRandomNumE1,startTokenId,endTokenId,tokenIdTotalSupply,awardAmount
        if (level_ == 0) {
            return HatchRule(0, 0, 615668, 0, 578668, 0, 728988, 1000000000000, 1299999999999, 300000000000, 0);
        } else if (level_ == 1) {
            return HatchRule(1, 615669, 965668, 578669, 778668, 0, 0, 100000000000, 129999999999, 30000000000, 50);
        } else if (level_ == 2) {
            return HatchRule(2, 965669, 995668, 778669, 978668, 0, 0, 10000000000, 19999999999, 10000000000, 200);
        } else if (level_ == 3) {
            return HatchRule(3, 995669, 998668, 978669, 998668, 0, 0, 1000000000, 3999999999, 3000000000, 500);
        } else if (level_ == 4) {
            return HatchRule(4, 998669, 999668, 998669, 999668, 728989, 928988, 100000000, 399999999, 300000000, 1000);
        } else if (level_ == 5) {
            return HatchRule(5, 999669, 999868, 999669, 999868, 928989, 988988, 10000000, 39999999, 30000000, 5000);
        } else if (level_ == 6) {
            return HatchRule(6, 999869, 999968, 999869, 999968, 988989, 998988, 1000000, 3999999, 3000000, 10000);
        } else if (level_ == 7) {
            return HatchRule(7, 999969, 999988, 999969, 999988, 998989, 999988, 100000, 399999, 300000, 50000);
        } else if (level_ == 8) {
            return HatchRule(8, 999989, 999998, 999989, 999998, 999989, 999998, 10000, 39999, 30000, 100000);
        } else if (level_ == 9) {
            return HatchRule(9, 999999, 999999, 999999, 999999, 999999, 999999, 1000, 3999, 3000, 1000000);
        } else {
            return getHatchRuleNone();
        }
    }

    /**
    * @param randomNum_ Random number
    * @param eSeries_ E series
    */
    function getHatchRuleByESeriesRandomNum(uint8 eSeries_, uint256 randomNum_) external pure returns (HatchRule memory) {
        for (uint8 level_ = 0; level_ <= 9;) {
            HatchRule memory hatchRule = getHatchRuleByLevel(level_);
            if (randomNum_ >= hatchRule.startRandomNumE0 && randomNum_ <= hatchRule.endRandomNumE0 && eSeries_ == 0) {
                return hatchRule;
            } else if (randomNum_ >= hatchRule.startRandomNumE1 && randomNum_ <= hatchRule.endRandomNumE1 && eSeries_ == 1) {
                return hatchRule;
            } else if (randomNum_ >= hatchRule.startRandomNumE2 && randomNum_ <= hatchRule.endRandomNumE2 && eSeries_ == 2) {
                return hatchRule;
            }
            unchecked{++level_;}
        }
        return getHatchRuleNone();
    }

    /**
    * @param tokenId_ TokenId
    */
    function getHatchRuleByTokenId(uint256 tokenId_) external pure returns (HatchRule memory) {
        for (uint8 level_ = 0; level_ <= 9;) {
            HatchRule memory hatchRule = getHatchRuleByLevel(level_);
            if (tokenId_ >= hatchRule.startTokenId && tokenId_ <= hatchRule.endTokenId) {
                return hatchRule;
            }
            unchecked{++level_;}
        }
        return getHatchRuleNone();
    }

    /**
    * @param evolveTokenIdLevel_ Evolve tokenId level
    * @param randomNum_ Random number
    */
    function getHatchRuleByEvolveTokenIdLevelRandomNum(uint8 evolveTokenIdLevel_, uint256 randomNum_) public pure returns (HatchRule memory) {
        for (uint8 nextLevelIndex_ = 0; nextLevelIndex_ <= 9;) {
            EvolveRule memory evolveRule = getEvolveRuleByEvolveTokenIdLevelNextLevelIndex(evolveTokenIdLevel_, nextLevelIndex_);
            if (randomNum_ >= evolveRule.startRandomNum && randomNum_ <= evolveRule.endRandomNum) {
                return getHatchRuleByLevel(evolveRule.level);
            }
            unchecked{++nextLevelIndex_;}
        }
        return getHatchRuleNone();
    }

    /**
    * @param evolveTokenIdLevel_ Evolve tokenId level
    * @param nextLevelIndex_ Next level index
    */
    function getEvolveRuleByEvolveTokenIdLevelNextLevelIndex(uint8 evolveTokenIdLevel_, uint8 nextLevelIndex_) public pure returns (EvolveRule memory) {
        if (evolveTokenIdLevel_ == 1) {
            if (nextLevelIndex_ == 0) {
                return EvolveRule(0, 0, 808668);
            } else if (nextLevelIndex_ == 1) {
                return EvolveRule(1, 808669, 908668);
            } else if (nextLevelIndex_ == 2) {
                return EvolveRule(2, 908669, 988668);
            } else if (nextLevelIndex_ == 3) {
                return EvolveRule(3, 988669, 998668);
            } else if (nextLevelIndex_ == 4) {
                return EvolveRule(4, 998669, 999668);
            } else if (nextLevelIndex_ == 5) {
                return EvolveRule(5, 999669, 999868);
            } else if (nextLevelIndex_ == 6) {
                return EvolveRule(6, 999869, 999968);
            } else if (nextLevelIndex_ == 7) {
                return EvolveRule(7, 999969, 999988);
            } else if (nextLevelIndex_ == 8) {
                return EvolveRule(8, 999989, 999998);
            } else if (nextLevelIndex_ == 9) {
                return EvolveRule(9, 999999, 999999);
            }
        } else if (evolveTokenIdLevel_ == 2) {
            if (nextLevelIndex_ == 0) {
                return EvolveRule(0, 0, 619668);
            } else if (nextLevelIndex_ == 1) {
                return EvolveRule(1, 619669, 719668);
            } else if (nextLevelIndex_ == 2) {
                return EvolveRule(2, 719669, 819668);
            } else if (nextLevelIndex_ == 3) {
                return EvolveRule(3, 819669, 979668);
            } else if (nextLevelIndex_ == 4) {
                return EvolveRule(4, 979669, 999668);
            } else if (nextLevelIndex_ == 5) {
                return EvolveRule(5, 999669, 999868);
            } else if (nextLevelIndex_ == 6) {
                return EvolveRule(6, 999869, 999968);
            } else if (nextLevelIndex_ == 7) {
                return EvolveRule(7, 999969, 999988);
            } else if (nextLevelIndex_ == 8) {
                return EvolveRule(8, 999989, 999998);
            } else if (nextLevelIndex_ == 9) {
                return EvolveRule(9, 999999, 999999);
            }
        } else if (evolveTokenIdLevel_ == 3) {
            if (nextLevelIndex_ == 0) {
                return EvolveRule(0, 0, 490868);
            } else if (nextLevelIndex_ == 1) {
                return EvolveRule(1, 490869, 590868);
            } else if (nextLevelIndex_ == 2) {
                return EvolveRule(2, 590869, 690868);
            } else if (nextLevelIndex_ == 3) {
                return EvolveRule(3, 690869, 790868);
            } else if (nextLevelIndex_ == 4) {
                return EvolveRule(4, 790869, 990868);
            } else if (nextLevelIndex_ == 5) {
                return EvolveRule(5, 990869, 999868);
            } else if (nextLevelIndex_ == 6) {
                return EvolveRule(6, 999869, 999968);
            } else if (nextLevelIndex_ == 7) {
                return EvolveRule(7, 999969, 999988);
            } else if (nextLevelIndex_ == 8) {
                return EvolveRule(8, 999989, 999998);
            } else if (nextLevelIndex_ == 9) {
                return EvolveRule(9, 999999, 999999);
            }
        } else if (evolveTokenIdLevel_ == 4) {
            if (nextLevelIndex_ == 0) {
                return EvolveRule(0, 0, 512968);
            } else if (nextLevelIndex_ == 1) {
                return EvolveRule(1, 512969, 612968);
            } else if (nextLevelIndex_ == 2) {
                return EvolveRule(2, 612969, 712968);
            } else if (nextLevelIndex_ == 3) {
                return EvolveRule(3, 712969, 812968);
            } else if (nextLevelIndex_ == 4) {
                return EvolveRule(4, 812969, 912968);
            } else if (nextLevelIndex_ == 5) {
                return EvolveRule(5, 912969, 992968);
            } else if (nextLevelIndex_ == 6) {
                return EvolveRule(6, 992969, 999968);
            } else if (nextLevelIndex_ == 7) {
                return EvolveRule(7, 999969, 999988);
            } else if (nextLevelIndex_ == 8) {
                return EvolveRule(8, 999989, 999998);
            } else if (nextLevelIndex_ == 9) {
                return EvolveRule(9, 999999, 999999);
            }
        } else if (evolveTokenIdLevel_ == 5) {
            if (nextLevelIndex_ == 0) {
                return EvolveRule(0, 0, 288988);
            } else if (nextLevelIndex_ == 1) {
                return EvolveRule(1, 288989, 388988);
            } else if (nextLevelIndex_ == 2) {
                return EvolveRule(2, 388989, 488988);
            } else if (nextLevelIndex_ == 3) {
                return EvolveRule(3, 488989, 588988);
            } else if (nextLevelIndex_ == 4) {
                return EvolveRule(4, 588989, 688988);
            } else if (nextLevelIndex_ == 5) {
                return EvolveRule(5, 688989, 788988);
            } else if (nextLevelIndex_ == 6) {
                return EvolveRule(6, 788989, 988988);
            } else if (nextLevelIndex_ == 7) {
                return EvolveRule(7, 988989, 999988);
            } else if (nextLevelIndex_ == 8) {
                return EvolveRule(8, 999989, 999998);
            } else if (nextLevelIndex_ == 9) {
                return EvolveRule(9, 999999, 999999);
            }
        } else if (evolveTokenIdLevel_ == 6) {
            if (nextLevelIndex_ == 0) {
                return EvolveRule(0, 0, 313998);
            } else if (nextLevelIndex_ == 1) {
                return EvolveRule(1, 313999, 413998);
            } else if (nextLevelIndex_ == 2) {
                return EvolveRule(2, 413999, 513998);
            } else if (nextLevelIndex_ == 3) {
                return EvolveRule(3, 513999, 613998);
            } else if (nextLevelIndex_ == 4) {
                return EvolveRule(4, 613999, 713998);
            } else if (nextLevelIndex_ == 5) {
                return EvolveRule(5, 713999, 813998);
            } else if (nextLevelIndex_ == 6) {
                return EvolveRule(6, 813999, 913998);
            } else if (nextLevelIndex_ == 7) {
                return EvolveRule(7, 913999, 989998);
            } else if (nextLevelIndex_ == 8) {
                return EvolveRule(8, 989999, 999998);
            } else if (nextLevelIndex_ == 9) {
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
        uint256 startRandomNumE2;
        uint256 endRandomNumE2;
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

    function modNumber() external view returns (uint256);

    function getHatchRuleNone() external pure returns (HatchRule memory);

    function getHatchRuleByLevel(uint8 level_) external pure returns (HatchRule memory);

    function getHatchRuleByESeriesRandomNum(uint8 eSeries_, uint256 randomNum_) external pure returns (HatchRule memory);

    function getHatchRuleByTokenId(uint256 tokenId) external pure returns (HatchRule memory);

    function getHatchRuleByEvolveTokenIdLevelRandomNum(uint8 evolveTokenIdLevel_, uint256 randomNum_) external pure returns (HatchRule memory);

    function getEvolveRuleByEvolveTokenIdLevelNextLevelIndex(uint8 evolveTokenIdLevel_, uint8 nextLevelIndex_) external pure returns (EvolveRule memory);

}