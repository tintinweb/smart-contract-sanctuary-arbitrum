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

import {IL2MagicCubeRule} from "../interfaces/IL2MagicCubeRule.sol";

contract L2MagicCubeRule is IL2MagicCubeRule, Ownable {

    uint256 public modNumber;

    constructor() {
        modNumber = 10000000;
    }

    function setModNumber() external onlyOwner {
        modNumber = modNumber;
    }

    function getTokenIdRuleNone() public pure returns (TokenIdRule memory) {
        return TokenIdRule(0, 0, 0, 0);
    }

    /**
    * @param level_ Magic Cube Level
    */
    function getTokenIdRuleByLevel(uint8 level_) public pure returns (TokenIdRule memory) {
        //level,startTokenId,endTokenId,tokenIdTotalSupply
        if (level_ == 0) {
            return TokenIdRule(0, 1000000000, 3999999999, 3000000000);
        } else if (level_ == 1) {
            return TokenIdRule(1, 100000000, 399999999, 300000000);
        } else if (level_ == 2) {
            return TokenIdRule(2, 10000000, 39999999, 30000000);
        } else if (level_ == 3) {
            return TokenIdRule(3, 1000000, 3999999, 3000000);
        } else if (level_ == 4) {
            return TokenIdRule(4, 100000, 399999, 300000);
        } else if (level_ == 5) {
            return TokenIdRule(5, 10000, 39999, 30000);
        } else if (level_ == 6) {
            return TokenIdRule(6, 1000, 3999, 3000);
        } else {
            return getTokenIdRuleNone();
        }
    }

    /**
    * @param unicornLevel_ Unicorn Level
    * @param randomNum_ Random number
    */
    function getTokenIdRuleByUnicornLevelRandomNum(uint8 unicornLevel_, uint256 randomNum_) public pure returns (TokenIdRule memory) {
        for (uint8 level_ = 0; level_ <= 6;) {
            MergeRule memory mergeRule = getMergeRuleByUnicornLevelLevel(unicornLevel_, level_);
            if (randomNum_ >= mergeRule.startRandomNum && randomNum_ <= mergeRule.endRandomNum) {
                return getTokenIdRuleByLevel(mergeRule.level);
            }
            unchecked{++level_;}
        }
        return getTokenIdRuleNone();
    }

    /**
    * @param unicornLevel_ Unicorn Level
    * @param level_ Magic Cube Level
    */
    function getMergeRuleByUnicornLevelLevel(uint8 unicornLevel_, uint8 level_) public pure returns (MergeRule memory) {
        if (unicornLevel_ == 1) {
            if (level_ == 0) {
                return MergeRule(0, 0, 8375888);
            } else if (level_ == 1) {
                return MergeRule(1, 8375889, 9375888);
            } else if (level_ == 2) {
                return MergeRule(2, 9375889, 9975888);
            } else if (level_ == 3) {
                return MergeRule(3, 9975889, 9999888);
            } else if (level_ == 4) {
                return MergeRule(4, 9999889, 9999988);
            } else if (level_ == 5) {
                return MergeRule(5, 9999989, 9999998);
            } else if (level_ == 6) {
                return MergeRule(6, 9999999, 9999999);
            }
        } else if (unicornLevel_ == 2) {
            if (level_ == 0) {
                return MergeRule(0, 0, 6149888);
            } else if (level_ == 1) {
                return MergeRule(1, 6149889, 7149888);
            } else if (level_ == 2) {
                return MergeRule(2, 7149889, 9899888);
            } else if (level_ == 3) {
                return MergeRule(3, 9899889, 9999888);
            } else if (level_ == 4) {
                return MergeRule(4, 9999889, 9999988);
            } else if (level_ == 5) {
                return MergeRule(5, 9999989, 9999998);
            } else if (level_ == 6) {
                return MergeRule(6, 9999999, 9999999);
            }
        } else if (unicornLevel_ == 3) {
            if (level_ == 0) {
                return MergeRule(0, 0, 7193988);
            } else if (level_ == 1) {
                return MergeRule(1, 7193989, 8193988);
            } else if (level_ == 2) {
                return MergeRule(2, 8193989, 9193988);
            } else if (level_ == 3) {
                return MergeRule(3, 9193989, 9993988);
            } else if (level_ == 4) {
                return MergeRule(4, 9993989, 9999988);
            } else if (level_ == 5) {
                return MergeRule(5, 9999989, 9999998);
            } else if (level_ == 6) {
                return MergeRule(6, 9999999, 9999999);
            }
        } else if (unicornLevel_ == 4) {
            if (level_ == 0) {
                return MergeRule(0, 0, 6376988);
            } else if (level_ == 1) {
                return MergeRule(1, 6376989, 7376988);
            } else if (level_ == 2) {
                return MergeRule(2, 7376989, 8376988);
            } else if (level_ == 3) {
                return MergeRule(3, 8376989, 9976988);
            } else if (level_ == 4) {
                return MergeRule(4, 9976989, 9999988);
            } else if (level_ == 5) {
                return MergeRule(5, 9999989, 9999998);
            } else if (level_ == 6) {
                return MergeRule(6, 9999999, 9999999);
            }
        } else if (unicornLevel_ == 5) {
            if (level_ == 0) {
                return MergeRule(0, 0, 6193998);
            } else if (level_ == 1) {
                return MergeRule(1, 6193999, 7193998);
            } else if (level_ == 2) {
                return MergeRule(2, 7193999, 8193998);
            } else if (level_ == 3) {
                return MergeRule(3, 8193999, 9193998);
            } else if (level_ == 4) {
                return MergeRule(4, 9193999, 9993998);
            } else if (level_ == 5) {
                return MergeRule(5, 9993999, 9999998);
            } else if (level_ == 6) {
                return MergeRule(6, 9999999, 9999999);
            }
        } else if (unicornLevel_ == 6) {
            if (level_ == 0) {
                return MergeRule(0, 0, 5469998);
            } else if (level_ == 1) {
                return MergeRule(1, 5469999, 6469998);
            } else if (level_ == 2) {
                return MergeRule(2, 6469999, 7469998);
            } else if (level_ == 3) {
                return MergeRule(3, 7469999, 8469998);
            } else if (level_ == 4) {
                return MergeRule(4, 8469999, 9969998);
            } else if (level_ == 5) {
                return MergeRule(5, 9969999, 9999998);
            } else if (level_ == 6) {
                return MergeRule(6, 9999999, 9999999);
            }
        }
        return MergeRule(0, 0, 0);
    }

    /**
    * @param unicornLevel_ Unicorn Level
    */
    /*function getMergeRuleByUnicornLevel(uint8 unicornLevel_) public pure returns (MergeRule[] memory mergeRules) {
        if (unicornLevel_ >= 1 && unicornLevel_ <= 6) {
            mergeRules = new MergeRule[](6);
            if (unicornLevel_ == 1) {
                mergeRules[0] = MergeRule(0, 0, 8375888);
                mergeRules[1] = MergeRule(1, 8375889, 9375888);
                mergeRules[2] = MergeRule(2, 9375889, 9975888);
                mergeRules[3] = MergeRule(3, 9975889, 9999888);
                mergeRules[4] = MergeRule(4, 9999889, 9999988);
                mergeRules[5] = MergeRule(5, 9999989, 9999998);
                mergeRules[6] = MergeRule(6, 9999999, 9999999);
            } else if (unicornLevel_ == 2) {
                mergeRules[0] = MergeRule(0, 0, 6149888);
                mergeRules[1] = MergeRule(1, 6149889, 7149888);
                mergeRules[2] = MergeRule(2, 7149889, 9899888);
                mergeRules[3] = MergeRule(3, 9899889, 9999888);
                mergeRules[4] = MergeRule(4, 9999889, 9999988);
                mergeRules[5] = MergeRule(5, 9999989, 9999998);
                mergeRules[6] = MergeRule(6, 9999999, 9999999);
            } else if (unicornLevel_ == 3) {
                mergeRules[0] = MergeRule(0, 0, 7193988);
                mergeRules[1] = MergeRule(1, 7193989, 8193988);
                mergeRules[2] = MergeRule(2, 8193989, 9193988);
                mergeRules[3] = MergeRule(3, 9193989, 9993988);
                mergeRules[4] = MergeRule(4, 9993989, 9999988);
                mergeRules[5] = MergeRule(5, 9999989, 9999998);
                mergeRules[6] = MergeRule(6, 9999999, 9999999);
            } else if (unicornLevel_ == 4) {
                mergeRules[0] = MergeRule(0, 0, 6376988);
                mergeRules[1] = MergeRule(1, 6376989, 7376988);
                mergeRules[2] = MergeRule(2, 7376989, 8376988);
                mergeRules[3] = MergeRule(3, 8376989, 9976988);
                mergeRules[4] = MergeRule(4, 9976989, 9999988);
                mergeRules[5] = MergeRule(5, 9999989, 9999998);
                mergeRules[6] = MergeRule(6, 9999999, 9999999);
            } else if (unicornLevel_ == 5) {
                mergeRules[0] = MergeRule(0, 0, 6193998);
                mergeRules[1] = MergeRule(1, 6193999, 7193998);
                mergeRules[2] = MergeRule(2, 7193999, 8193998);
                mergeRules[3] = MergeRule(3, 8193999, 9193998);
                mergeRules[4] = MergeRule(4, 9193999, 9993998);
                mergeRules[5] = MergeRule(5, 9993999, 9999998);
                mergeRules[6] = MergeRule(6, 9999999, 9999999);
            } else if (unicornLevel_ == 6) {
                mergeRules[0] = MergeRule(0, 0, 5469998);
                mergeRules[1] = MergeRule(1, 5469999, 6469998);
                mergeRules[2] = MergeRule(2, 6469999, 7469998);
                mergeRules[3] = MergeRule(3, 7469999, 8469998);
                mergeRules[4] = MergeRule(4, 8469999, 9969998);
                mergeRules[5] = MergeRule(5, 9969999, 9999998);
                mergeRules[6] = MergeRule(6, 9999999, 9999999);
            }
        } else {
            mergeRules = new MergeRule[](0);
        }
        return mergeRules;
    }*/

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IL2MagicCubeRule {

    struct TokenIdRule {
        uint8 level;
        uint256 startTokenId;
        uint256 endTokenId;
        uint256 tokenIdTotalSupply;
    }

    struct MergeRule {
        uint8 level;
        uint256 startRandomNum;
        uint256 endRandomNum;
    }

    function modNumber() external view returns (uint256);

    function getTokenIdRuleByLevel(uint8 level_) external pure returns (TokenIdRule memory);

    function getTokenIdRuleByUnicornLevelRandomNum(uint8 unicornLevel_, uint256 randomNum_) external pure returns (TokenIdRule memory);

    function getMergeRuleByUnicornLevelLevel(uint8 unicornLevel_, uint8 level_) external pure returns (MergeRule memory);

}