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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
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

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {IRewardsManager} from "../interfaces/IRewardsManager.sol";
import {IL2Unicorn} from "../interfaces/IL2Unicorn.sol";

abstract contract RewardsManager is IRewardsManager, Ownable {

    address public rewardsToken;

    uint256 public rewardsAmount;

    constructor(address rewardsToken_, uint256 rewardsAmount_) {
        rewardsToken = rewardsToken_;
        rewardsAmount = rewardsAmount_;
    }

    function setRewardsToken(address rewardsToken_) external onlyOwner {
        rewardsToken = rewardsToken_;
    }

    function setRewardsAmount(uint256 rewardsAmount_) external onlyOwner {
        rewardsAmount = rewardsAmount_;
    }

    function withdrawRewards(address recipient_, uint256 amount_) external onlyOwner {
        IERC20(rewardsToken).transfer(recipient_, amount_);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract L2NFTPeriphery {

    uint8 public immutable ZERO = 0;

    uint8 public immutable E_SERIES_0 = 0;

    uint8 public immutable E_SERIES_1 = 1;

    uint256 public immutable R_SERIAL_MOD_NUMBER = 1000000;

    struct L2UnicornRule {
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

    function getL2UnicornRuleNone() public pure returns (L2UnicornRule memory) {
        //startRandomNumE0,endRandomNumE0,startRandomNumE1,endRandomNumE1,startTokenId,endTokenId,tokenIdTotalSupply,awardAmount
        return L2UnicornRule(ZERO, ZERO, ZERO, ZERO, ZERO, ZERO, ZERO, ZERO, ZERO);
    }

    function getL2UnicornRuleByLevel(uint8 level_) public pure returns (L2UnicornRule memory) {
        //startRandomNumE0,endRandomNumE0,startRandomNumE1,endRandomNumE1,startTokenId,endTokenId,tokenIdTotalSupply,awardAmount
        if (level_ == ZERO) {
            return L2UnicornRule(ZERO, ZERO, 578668, ZERO, 728988, 1000000000000, 1299999999999, 300000000000, ZERO);
        } else if (level_ == 1) {
            return L2UnicornRule(1, 578669, 778668, ZERO, ZERO, 100000000000, 129999999999, 30000000000, 50);
        } else if (level_ == 2) {
            return L2UnicornRule(2, 778669, 978668, ZERO, ZERO, 10000000000, 19999999999, 10000000000, 200);
        } else if (level_ == 3) {
            return L2UnicornRule(3, 978669, 998668, ZERO, ZERO, 1000000000, 3999999999, 3000000000, 500);
        } else if (level_ == 4) {
            return L2UnicornRule(4, 998669, 999668, 728989, 928988, 100000000, 399999999, 300000000, 1000);
        } else if (level_ == 5) {
            return L2UnicornRule(5, 999669, 999868, 928989, 988988, 10000000, 39999999, 30000000, 5000);
        } else if (level_ == 6) {
            return L2UnicornRule(6, 999869, 999968, 988989, 998988, 1000000, 3999999, 3000000, 10000);
        } else if (level_ == 7) {
            return L2UnicornRule(7, 999969, 999988, 998989, 999988, 100000, 399999, 300000, 50000);
        } else if (level_ == 8) {
            return L2UnicornRule(8, 999989, 999998, 999989, 999998, 10000, 39999, 30000, 100000);
        } else if (level_ == 9) {
            return L2UnicornRule(9, 999999, 999999, 999999, 999999, ZERO, 2999, 3000, 1000000);
        } else {
            return getL2UnicornRuleNone();
        }
    }

    /**
    * @param randomNum Random Number
    * @param eSeries E Series
    */
    function getL2UnicornRuleByRandomNum(uint256 randomNum, uint256 eSeries) public pure returns (L2UnicornRule memory) {
        for (uint8 level_ = 0; level_ < 9;) {
            L2UnicornRule memory rule = getL2UnicornRuleByLevel(level_);
            if(randomNum >= rule.startRandomNumE0 && randomNum <= rule.endRandomNumE0 && eSeries == E_SERIES_0){
                return rule;
            }else if(randomNum >= rule.startRandomNumE1 && randomNum <= rule.endRandomNumE1 && eSeries == E_SERIES_1){
                return rule;
            }
            unchecked{++level_;}
        }
        return getL2UnicornRuleNone();
    }

    /**
    * @param tokenId NFT TokenId
    */
    function getL2UnicornRuleByTokenId(uint256 tokenId) public pure returns (L2UnicornRule memory) {
        for (uint8 level_ = 0; level_ < 9;) {
            L2UnicornRule memory rule = getL2UnicornRuleByLevel(level_);
            if(tokenId >= rule.startTokenId && tokenId <= rule.endTokenId){
                return rule;
            }
            unchecked{++level_;}
        }
        return getL2UnicornRuleNone();
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {RewardsManager} from "../abstract/RewardsManager.sol";
import {IL2Unicorn} from "../interfaces/IL2Unicorn.sol";

import {L2NFTPeriphery} from "./L2NFTPeriphery.sol";

contract L2NFTRewardsManager is RewardsManager, L2NFTPeriphery {

    address public l2Unicorn;


    constructor(address l2Unicorn_, address rewardsToken_) RewardsManager(rewardsToken_, 0) {
        l2Unicorn = l2Unicorn_;
    }

    function viewL2UnicornRule(uint256 tokenId) external pure returns (L2UnicornRule memory){
        return getL2UnicornRuleByTokenId(tokenId);
    }

    /**
    * @dev 分解
    */
    function resolveL2Unicorn(uint256[] calldata tokenIds) external {
        uint256 length = tokenIds.length;
        for (uint i_ = 0; i_ < length;) {
            IL2Unicorn(l2Unicorn).burn(tokenIds[i_]);
            L2UnicornRule memory rule = getL2UnicornRuleByTokenId(tokenIds[i_]);
            if (rule.awardAmount > 0) {
                IERC20(rewardsToken).transfer(_msgSender(), rule.awardAmount * 1e18);
            }
            unchecked{++i_;}
        }
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IL2Unicorn {

    function burn(uint256 tokenId) external;

    function minter() external view returns (address);

    function mintWithMinter(address to_, uint256 tokenId_) external;

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IRewardsManager {

    function rewardsToken() external returns (address);

    function setRewardsToken(address rewardsToken_) external;

    function rewardsAmount() external returns (uint256);

    function setRewardsAmount(uint256 rewardsAmount_) external;

    function withdrawRewards(address recipient_, uint256 amount_) external;

}