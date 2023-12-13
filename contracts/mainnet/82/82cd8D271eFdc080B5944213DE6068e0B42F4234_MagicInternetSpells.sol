// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.20;

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
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
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
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/ReentrancyGuard.sol)

pragma solidity ^0.8.20;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant NOT_ENTERED = 1;
    uint256 private constant ENTERED = 2;

    uint256 private _status;

    /**
     * @dev Unauthorized reentrant call.
     */
    error ReentrancyGuardReentrantCall();

    constructor() {
        _status = NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be NOT_ENTERED
        if (_status == ENTERED) {
            revert ReentrancyGuardReentrantCall();
        }

        // Any calls to nonReentrant after this point will fail
        _status = ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == ENTERED;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

library TransferHelper {
    /// @notice Transfers tokens from the targeted address to the given destination
    /// @notice Errors with 'STF' if transfer fails
    /// @param token The contract address of the token to be transferred
    /// @param from The originating address from which the tokens will be transferred
    /// @param to The destination address of the transfer
    /// @param value The amount to be transferred
    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'STF');
    }

    /// @notice Transfers tokens from msg.sender to a recipient
    /// @dev Errors with ST if transfer fails
    /// @param token The contract address of the token which will be transferred
    /// @param to The recipient of the transfer
    /// @param value The value of the transfer
    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'ST');
    }

    /// @notice Approves the stipulated contract to spend the given allowance in the given token
    /// @dev Errors with 'SA' if transfer fails
    /// @param token The contract address of the token to be approved
    /// @param to The target of the approval
    /// @param value The amount of the given token the target will be allowed to spend
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.approve.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'SA');
    }

    /// @notice Transfers ETH to the recipient address
    /// @dev Fails with `STE`
    /// @param to The destination of the transfer
    /// @param value The value to be transferred
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'STE');
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

/// @title Callback for IUniswapV3PoolActions#flash
/// @notice Any contract that calls IUniswapV3PoolActions#flash must implement this interface
interface IUniswapV3FlashCallback {
    /// @notice Called to `msg.sender` after transferring to the recipient from IUniswapV3Pool#flash.
    /// @dev In the implementation you must repay the pool the tokens sent by flash plus the computed fee amounts.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// @param fee0 The fee amount in token0 due to the pool by the end of the flash
    /// @param fee1 The fee amount in token1 due to the pool by the end of the flash
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#flash call
    function uniswapV3FlashCallback(
        uint256 fee0,
        uint256 fee1,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;


/// @title The interface for a Uniswap V3 Pool
/// @notice A Uniswap pool facilitates swapping and automated market making between any two assets that strictly conform
/// to the ERC20 specification
/// @dev The pool interface is broken up into many smaller pieces
interface IUniswapV3Pool {
    /// @notice Receive token0 and/or token1 and pay it back, plus a fee, in the callback
    /// @dev The caller of this method receives a callback in the form of IUniswapV3FlashCallback#uniswapV3FlashCallback
    /// @dev Can be used to donate underlying tokens pro-rata to currently in-range liquidity providers by calling
    /// with 0 amount{0,1} and sending the donation amount(s) from the callback
    /// @param recipient The address which will receive the token0 and token1 amounts
    /// @param amount0 The amount of token0 to send
    /// @param amount1 The amount of token1 to send
    /// @param data Any data to be passed through to the callback
    function flash(
        address recipient,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
import {IUniswapV3FlashCallback} from "./interfaces/uniswap/IUniswapV3FlashCallback.sol";
import {IUniswapV3Pool} from "./interfaces/uniswap/IUniswapV3Pool.sol";
import {PoolAddress} from "./Utils/PoolAddress.sol";
import {SafeMath} from "./Utils/SafeMath.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
pragma solidity ^0.8.20;

interface IMIFREN {
    function getTokenId() external view returns (uint256);
    function getmiXP(uint256 tokenId) external view returns (uint256);
    function getmiHP(uint256 tokenId) external view returns (uint256); // Add this line
    function ownerOf(uint256 tokenId) external view returns (address);
    function setmiXP(uint256 tokenId, uint256 _miXP) external;
    function setmiHP(uint256 tokenId, uint256 _miHP) external;
    function transfer(address to, uint256 amount) external returns (bool);
    function isCauldronInRange(address fren) external returns (bool);
    function withdraw(uint256 amount) external;
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function getFrenId(address _fren) external returns (uint256);

    function getIdFren(uint256 _id) external returns (address);
    function setTimeStamp(address fren, uint256 _lastSpellTimeStamp) external;

    function getSpellTimeStamp(address fren) external returns (uint256);
}

interface IWETH9 is IERC20 {
    /// @notice Deposit ether to get wrapped ether
    function deposit() external payable;

    /// @notice Withdraw wrapped ether to get ether
    function withdraw(uint256) external;
}

interface IMiCauldron {
    event PositionDeposited(uint256 indexed tokenId, address indexed from, address indexed to);
    struct StakedPosition {
        uint256 tokenId;
        uint128 liquidity;
        uint256 stakedAt;
        uint256 lastRewardTime;
    }

    function withdrawPosition(uint256 tokenId) external;
    function pendingRewards(address user) external view returns (uint256 rewards);
    function claimRewards() external;
    function drinkHealPotion() external;
    function drinkProtectPotion() external;
    function decreaseLiquidity(uint128 liquidity) external returns (uint amount0, uint amount1);
    function _getStakedPositionID(address fren) external returns (uint256 tokenId);
    function swapETH_Half(uint value, bool isWETH) external payable returns (uint amountOut);
    function brewManaFromETH()
        external
        payable
        returns (uint _tokenId, uint128 liquidity, uint amount0, uint amount1, uint refund0, uint refund1);
    function isCauldronInRange(address fren) external view returns (bool);

    function _rebalancePosition(address fren, address refund) external returns (uint _refund0, uint _refund1);
    function increasePosition(
        address fren,
        uint _amountMana,
        uint _amountWETH
    ) external returns (uint tokenId, uint128 liquidity, uint amount0, uint amount1, uint refund0, uint refund1);
}

contract MagicInternetSpells {
    IMIFREN public nftContract;
    IMIFREN public miMana;
    address public auth;
    mapping(address => bool) public isAuth;
    mapping(address => uint256) public lastSpellTimestamp;

    constructor(address _nftContract, address _mimana) {
        nftContract = IMIFREN(_nftContract);
        miMana = IMIFREN(_mimana);
    }

    event SpellResult(address indexed sender, address indexed target, bool success, uint256 amount);
    modifier onlyAuth() {
        require(msg.sender == auth || isAuth[msg.sender], "Caller is not the authorized");
        _;
    }

    function setIsAuth(address fren, bool isAuthorized) external onlyAuth {
        isAuth[fren] = isAuthorized;
    }

    function gibXP(address fren, uint256 amount) internal {
        uint256 tokenId = nftContract.getFrenId(fren);
        uint256 currXP = nftContract.getmiXP(tokenId);
        currXP += amount;

        nftContract.setmiXP(tokenId, currXP);
    }

    function takeHP(address fren, uint256 amount) internal {
        uint256 tokenId = nftContract.getFrenId(fren);
        uint256 currHP = nftContract.getmiHP(tokenId);
        currHP -= amount;

        nftContract.setmiHP(tokenId, currHP);
    }

    uint256 public initialHpFactor = 1; // Default value, can be updated
    uint256 public hpFactor = 10; // Default value, can be updated
    uint256 public amountOfmiManaToKill = 3333000000000000000000; // Default value, can be updated

    function setHpFactor(uint256 _newHpFactor) external onlyAuth {
        require(_newHpFactor > 0, "hpFactor must be greater than zero");
        hpFactor = _newHpFactor;
    }

    function setMiManaToKill(uint256 _newMiMana) external onlyAuth {
        require(_newMiMana > 0, "_newMiMana must be greater than zero");
        amountOfmiManaToKill = _newMiMana;
    }

    function castSpell(address to, uint256 amount) public {
        // Ensure the sender has not cast a spell in the past 5 minutes
        require(
            block.timestamp - lastSpellTimestamp[msg.sender] >= 5 minutes,
            "You can cast only one spell in each 5 minutes."
        );

        // Ensure the target hasn't been spelled in the past 15 minutes
        require(
            block.timestamp - lastSpellTimestamp[to] >= 15 minutes,
            "The target has been spelled in the last 15 minutes."
        );

        // Update the last spell timestamp for the sender
        lastSpellTimestamp[msg.sender] = block.timestamp;

        // Transfer mana cost from the sender to this contract
        miMana.transferFrom(msg.sender, address(this), amount);

        // Calculate HP deduction based on target's experience points
        //uint256 targetXP = nftContract.getmiXP(nftContract.getFrenId(to));
        uint256 hpToDeduct;

        // Calculate HP deduction using the formula amount / targetXP * hpFactor
        hpToDeduct = (amount * hpFactor) / amountOfmiManaToKill;

        // Randomly determine if the spell succeeds (50% chance)
        bool spellSuccess = (uint256(blockhash(block.number - 1)) % 2 == 0);

        if (spellSuccess) {
            // Spell succeeded
            gibXP(msg.sender, amount);
            takeHP(to, hpToDeduct);
        }

        // Emit the SpellResult event
        emit SpellResult(msg.sender, to, spellSuccess, amount);

        // Update the last spell timestamp for the target
        lastSpellTimestamp[to] = block.timestamp;
    }

    function getTokensOrderedByXP() external view returns (uint256[] memory, address[] memory, uint256[] memory) {
        uint256[] memory tokenIds = new uint256[](nftContract.getTokenId());
        address[] memory owners = new address[](tokenIds.length);
        uint256[] memory miHPs = new uint256[](tokenIds.length); // Add this line
        uint256[] memory miXPs = new uint256[](tokenIds.length); // Add this line

        // Copy all token IDs to the array
        for (uint256 i = 0; i < tokenIds.length; i++) {
            tokenIds[i] = i;
            owners[i] = nftContract.ownerOf(i);
            miHPs[i] = nftContract.getmiHP(i); // Add this line
            miXPs[i] = nftContract.getmiXP(i); // Add this line
        }

        // Bubble sort the token IDs based on XP points
        for (uint256 i = 0; i < tokenIds.length - 1; i++) {
            for (uint256 j = 0; j < tokenIds.length - i - 1; j++) {
                if (nftContract.getmiXP(tokenIds[j]) < nftContract.getmiXP(tokenIds[j + 1])) {
                    // Swap token IDs
                    (tokenIds[j], tokenIds[j + 1]) = (tokenIds[j + 1], tokenIds[j]);
                    // Swap owners accordingly
                    (owners[j], owners[j + 1]) = (owners[j + 1], owners[j]);
                    // Swap miHPs accordingly
                    (miHPs[j], miHPs[j + 1]) = (miHPs[j + 1], miHPs[j]);
                    (miXPs[j], miXPs[j + 1]) = (miXPs[j + 1], miXPs[j]);
                }
            }
        }

        return (tokenIds, owners, miHPs); // Update this line
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

/// @title Provides functions for deriving a pool address from the factory, tokens, and the fee
library PoolAddress {
    bytes32 internal constant POOL_INIT_CODE_HASH = 0xe34f199b19b2b4f47f68442619d555527d244f78a3297ea89325f843f87b8b54;

    /// @notice The identifying key of the pool
    struct PoolKey {
        address token0;
        address token1;
        uint24 fee;
    }

    /// @notice Deterministically computes the pool address given the factory and PoolKey
    /// @param factory The Uniswap V3 factory contract address
    /// @param key The PoolKey
    /// @return pool The contract address of the V3 pool
    function computeAddress(address factory, PoolKey memory key) internal pure returns (address pool) {
        require(key.token0 < key.token1);
        pool = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex'ff',
                            factory,
                            keccak256(abi.encode(key.token0, key.token1, key.fee)),
                            POOL_INIT_CODE_HASH
                        )
                    )
                )
            )
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
   
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }
}