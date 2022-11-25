// SPDX-License-Identifier: GPLv2
pragma solidity ^0.8.1;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./interfaces/IPixelMushrohmAuthority.sol";
import "./interfaces/IPixelMushrohmERC721.sol";
import "./interfaces/IPixelMushrohmStaking.sol";
import "./types/PixelMushrohmAccessControlled.sol";

contract PixelMushrohmStaking is IPixelMushrohmStaking, PixelMushrohmAccessControlled, ReentrancyGuard {
    /* ========== DEPENDENCIES ========== */

    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    /* ========== STATE VARIABLES ========== */

    uint256 public constant WEEK = 7 days;
    /// @dev unix timestamp
    uint256 public lastRewardTimestamp;
    uint256 public totalMushrohmsStaked;

    IPixelMushrohmERC721 public pixelMushrohm;

    /// @dev 9 decimals
    mapping(uint256 => StakedTokenData) public stakedTokenData;

    address private _paymentToken;
    uint256 private _stakingPrice;
    uint256 private _levelUpPrice;

    /* ========== MODIFIERS ========== */

    modifier onlyPixelMushrohm() {
        require(msg.sender == address(pixelMushrohm), "Staking: !pixelMushrohm");
        _;
    }

    modifier onlyPixelMushrohmOwner(uint256 _tokenId) {
        require(pixelMushrohm.ownerOf(_tokenId) == msg.sender, "Staking: only owner can stake");
        _;
    }

    modifier staked(uint256 _tokenId, bool expectedStaked) {
        require(isStaked(_tokenId) == expectedStaked, "Staking: wrong staked status");
        _;
    }

    modifier updateTotalMushrohmsStaked(bool isStaking) {
        lastRewardTimestamp = block.timestamp;
        if (isStaking) {
            totalMushrohmsStaked = totalMushrohmsStaked.add(1);
        } else {
            totalMushrohmsStaked = totalMushrohmsStaked.sub(1);
        }
        _;
    }

    /* ======== CONSTRUCTOR ======== */

    constructor(address _authority) PixelMushrohmAccessControlled(IPixelMushrohmAuthority(_authority)) {}

    /* ======== ADMIN FUNCTIONS ======== */

    function setPixelMushrohm(address _pixelMushrohm) external override onlyOwner {
        pixelMushrohm = IPixelMushrohmERC721(_pixelMushrohm);
        emit PixelMushrohmSet(_pixelMushrohm);
    }

    function setPaymentToken(address _tokenAddr) external override onlyOwner {
        _paymentToken = _tokenAddr;
    }

    function setStakingPrice(uint256 _price) external override onlyOwner {
        _stakingPrice = _price;
    }

    function setLevelUpPrice(uint256 _price) external override onlyOwner {
        _levelUpPrice = _price;
    }

    function inPlaceSporePowerUpdate(uint256 _tokenId) external override onlyPixelMushrohm {
        if (isStaked(_tokenId)) {
            require(address(pixelMushrohm) != address(0), "PixelMushrohm: Invalid pixelMushrohm address");
            pixelMushrohm.updateSporePower(_tokenId, sporePowerEarned(_tokenId));
            stakedTokenData[_tokenId].timestampStake = block.timestamp;
        }
    }

    function withdraw(address _tokenAddr) external override onlyVault {
        require(_tokenAddr != address(0), "PixelMushrohm: Invalid token address");
        uint256 tokenBalance = IERC20(_tokenAddr).balanceOf(address(this));
        require(tokenBalance > 0, "PixelMushrohm: No token balance");
        IERC20(_tokenAddr).transfer(msg.sender, tokenBalance);
    }

    /* ======== MUTABLE FUNCTIONS ======== */

    function stake(uint256 _tokenId)
        external
        override
        whenNotPaused
        nonReentrant
        onlyPixelMushrohmOwner(_tokenId)
        staked(_tokenId, false)
        updateTotalMushrohmsStaked(true)
    {
        require(address(pixelMushrohm) != address(0), "PixelMushrohm: Invalid pixelMushrohm address");
        require(
            !pixelMushrohm.isLevelMaxed(_tokenId) || !pixelMushrohm.isSporePowerMaxed(_tokenId),
            "PixelMushrohm: Cannot stake maxed out token"
        );

        if (_paymentToken != address(0) && _stakingPrice != 0) {
            IERC20(_paymentToken).safeTransferFrom(msg.sender, address(this), _stakingPrice);
        }

        stakedTokenData[_tokenId].timestampStake = block.timestamp;
        stakedTokenData[_tokenId].timestampLevel = block.timestamp;
        emit Staked(_tokenId);
    }

    function unstake(uint256 _tokenId)
        external
        override
        whenNotPaused
        nonReentrant
        onlyPixelMushrohmOwner(_tokenId)
        staked(_tokenId, true)
        updateTotalMushrohmsStaked(false)
    {
        pixelMushrohm.updateSporePower(_tokenId, sporePowerEarned(_tokenId));
        pixelMushrohm.updateLevelPower(_tokenId, levelPowerEarned(_tokenId));
        stakedTokenData[_tokenId].timestampStake = 0;
        stakedTokenData[_tokenId].timestampLevel = 0;
        emit Unstaked(_tokenId);
    }

    function levelUp(uint256 _tokenId) external override whenNotPaused nonReentrant onlyPixelMushrohmOwner(_tokenId) {
        require(address(pixelMushrohm) != address(0), "PixelMushrohm: Invalid pixelMushrohm address");
        require(isEligibleForLevelUp(_tokenId), "PixelMushrohm: Not eligible for a level up");

        if (_paymentToken != address(0) && _levelUpPrice != 0) {
            IERC20(_paymentToken).safeTransferFrom(msg.sender, address(this), _levelUpPrice);
        }

        pixelMushrohm.updateLevel(_tokenId);
        if (stakedTokenData[_tokenId].timestampLevel != 0) {
            stakedTokenData[_tokenId].timestampLevel = block.timestamp;
        }
    }

    /* ======== VIEW FUNCTIONS ======== */

    function getPaymentToken() public view override returns (address) {
        return _paymentToken;
    }

    function getStakingPrice() public view override returns (uint256) {
        return _stakingPrice;
    }

    function getLevelUpPrice() public view override returns (uint256) {
        return _levelUpPrice;
    }

    function sporePowerEarned(uint256 _tokenId) public view override returns (uint256) {
        require(address(pixelMushrohm) != address(0), "PixelMushrohm: Invalid pixelMushrohm address");
        if (stakedTokenData[_tokenId].timestampStake == 0 || pixelMushrohm.isSporePowerMaxed(_tokenId)) return 0;
        uint256 timeDelta = block.timestamp.sub(stakedTokenData[_tokenId].timestampStake);
        return
            (
                (
                    pixelMushrohm.getSporePowerPerWeek(_tokenId).mul(timeDelta).mul(
                        pixelMushrohm
                            .getLevelMultiplier(_tokenId)
                            .add(pixelMushrohm.getAdditionalMultiplier(_tokenId))
                            .add(1e9)
                    )
                ).div(1e9)
            ).div(WEEK);
    }

    function levelPowerEarned(uint256 _tokenId) public view override returns (uint256) {
        require(address(pixelMushrohm) != address(0), "PixelMushrohm: Invalid pixelMushrohm address");
        if (stakedTokenData[_tokenId].timestampLevel == 0 || pixelMushrohm.isLevelPowerMaxed(_tokenId)) return 0;
        if (pixelMushrohm.getLevel(_tokenId) >= pixelMushrohm.getMaxLevel()) return 0;
        uint256 timeDelta = block.timestamp.sub(stakedTokenData[_tokenId].timestampLevel);
        return (levelPerWeek(_tokenId).mul(timeDelta).div(WEEK));
    }

    function levelPerWeek(uint256 _tokenId) public view override returns (uint256) {
        require(address(pixelMushrohm) != address(0), "PixelMushrohm: Invalid pixelMushrohm address");
        return pixelMushrohm.getSporePowerPerWeek(_tokenId).div(pixelMushrohm.getMaxSporePowerLevel());
    }

    function isStaked(uint256 _tokenId) public view override returns (bool) {
        return stakedTokenData[_tokenId].timestampStake > 0;
    }

    function isEligibleForLevelUp(uint256 _tokenId) public view override returns (bool) {
        require(address(pixelMushrohm) != address(0), "PixelMushrohm: Invalid pixelMushrohm address");
        require(pixelMushrohm.getLevel(_tokenId) < pixelMushrohm.getMaxLevel(), "PixelMushrohm: Already max level");
        return pixelMushrohm.getLevelPower(_tokenId) >= pixelMushrohm.getLevelCost();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: GPLv2
pragma solidity ^0.8.1;

interface IPixelMushrohmAuthority {
    /* ========== EVENTS ========== */

    event OwnerPushed(address indexed from, address indexed to, bool _effectiveImmediately);
    event PolicyPushed(address indexed from, address indexed to, bool _effectiveImmediately);
    event VaultPushed(address indexed from, address indexed to, bool _effectiveImmediately);

    event OwnerPulled(address indexed from, address indexed to);
    event PolicyPulled(address indexed from, address indexed to);
    event VaultPulled(address indexed from, address indexed to);

    event Paused(address by);
    event Unpaused(address by);

    /* ========== VIEW ========== */

    function owner() external view returns (address);

    function policy() external view returns (address);

    function vault() external view returns (address);

    function paused() external view returns (bool);
}

// SPDX-License-Identifier: GPLv2
pragma solidity ^0.8.1;

import "@openzeppelin/contracts/interfaces/IERC721Enumerable.sol";

interface IPixelMushrohmERC721 is IERC721Enumerable {
    /* ========== EVENTS ========== */

    event PixelMushrohmMint(address to, uint256 tokenId);
    event RedeemSporePower(uint256 tokenId, uint256 amount);
    event SporePowerCost(uint256 sporePowerCost);
    event MaxSporePowerLevel(uint256 maxSporePowerLevel);
    event LevelCost(uint256 levelCost);
    event MaxLevel(uint256 maxLevel);
    event BaseLevelMultiplier(uint256 levelMultiplier);
    event AdditionalMultiplier(uint256 tokenId, uint256 multiplier);
    event FirstGenLevelMintLevel(uint256 level);
    event StakingSet(address staking);
    event RedeemerAdded(address redeemer);
    event RedeemerRemoved(address redeemer);
    event MultiplierAdded(address multiplier);
    event MultiplierRemoved(address multiplier);
    event BridgeSet(address bridge);

    /* ========== ENUMS ========== */

    enum MintType {
        APELIEN_AIRDROP,
        NOOSH_AIRDROP,
        PILOT_AIRDROP,
        R3L0C_AIRDROP,
        MEMETIC_AIRDROP,
        BRIDGE,
        STANDARD
    }

    /* ========== STRUCTS ========== */

    struct TokenData {
        uint256 sporePower;
        uint256 sporePowerPerWeek;
        uint256 level;
        uint256 levelPower;
        uint256 additionalMultiplier;
    }

    /* ======== ADMIN FUNCTIONS ======== */

    function setStaking(address _staking) external;

    function addRedeemer(address _redeemer) external;

    function removeRedeemer(address _redeemer) external;

    function addMultiplier(address _multiplier) external;

    function removeMultiplier(address _multiplier) external;

    function setBridge(address _bridge) external;

    function setMaxSporePowerLevel(uint256 _max) external;

    function setMaxLevel(uint256 _max) external;

    function setBaseLevelMultiplier(uint256 _multiplier) external;

    function setFirstGenLevelMintLevel(uint256 _level) external;

    function setSporePowerPerWeek(uint256 _sporePowerPerWeek, uint256[] calldata _tokenIds) external;

    function setBaseURI(string memory _baseURItoSet) external;

    function setPrerevealURI(string memory _prerevealURI) external;

    function setMintToken(address _tokenAddr) external;

    function setMintTokenPrice(uint256 _price) external;

    function setMaxMintPerWallet(uint256 _maxPerWallet) external;

    function setMerkleRoot(bytes32 _merkleRoot) external;

    function toggleReveal() external;

    function withdraw(address _tokenAddr) external;

    function manualBridgeMint(address _to, uint256 _tokenId) external;

    function airdrop(
        MintType _mintType,
        address[] calldata _to,
        uint256[] calldata _amount
    ) external;

    /* ======== MUTABLE FUNCTIONS ======== */

    function whitelistMint(uint256 _amount, bytes32[] calldata _merkleProof) external;

    function bridgeMint(address _to, uint256 _tokenId) external;

    function firstGenLevelMint(uint256 _tokenId) external;

    function updateSporePower(uint256 _tokenId, uint256 _sporePowerEarned) external;

    function updateLevelPower(uint256 _tokenId, uint256 _levelPowerEarned) external;

    function updateLevel(uint256 _tokenId) external;

    function redeemSporePower(uint256 _tokenId, uint256 _amount) external;

    function setAdditionalMultiplier(uint256 _tokenId, uint256 _multiplier) external;

    /* ======== VIEW FUNCTIONS ======== */

    function exists(uint256 _tokenId) external view returns (bool);

    function getMintToken() external view returns (address);

    function getMintTokenPrice() external view returns (uint256);

    function getMaxMintPerWallet() external view returns (uint256);

    function getSporePower(uint256 _tokenId) external view returns (uint256);

    function getSporePowerLevel(uint256 _tokenId) external view returns (uint256);

    function averageSporePower() external view returns (uint256);

    function getSporePowerCost() external view returns (uint256);

    function getMaxSporePowerLevel() external view returns (uint256);

    function getSporePowerPerWeek(uint256 _tokenId) external view returns (uint256);

    function getLevel(uint256 _tokenId) external view returns (uint256);

    function getLevelPower(uint256 _tokenId) external view returns (uint256);

    function getLevelCost() external view returns (uint256);

    function getMaxLevel() external view returns (uint256);

    function getBaseLevelMultiplier() external view returns (uint256);

    function getLevelMultiplier(uint256 _tokenId) external view returns (uint256);

    function getAdditionalMultiplier(uint256 _tokenId) external view returns (uint256);

    function getTokenURIsForOwner(address _owner) external view returns (string[] memory);

    function isEligibleForLevelMint(uint256 _tokenId) external view returns (bool);

    function getNumTokensMinted(address _owner) external view returns (uint256);

    function isSporePowerMaxed(uint256 _tokenId) external view returns (bool);

    function isLevelPowerMaxed(uint256 _tokenId) external view returns (bool);

    function isLevelMaxed(uint256 _tokenId) external view returns (bool);

    function hasUserHitMaxMint(address _user) external view returns (bool);
}

// SPDX-License-Identifier: GPLv2
pragma solidity ^0.8.1;

interface IPixelMushrohmStaking {
    /* ========== EVENTS ========== */

    event Staked(uint256 tokenId);
    event Unstaked(uint256 tokenId);
    event PixelMushrohmSet(address pixelMushrohm);

    /* ========== STRUCTS ========== */

    struct StakedTokenData {
        uint256 timestampStake;
        uint256 timestampLevel;
    }

    /* ======== ADMIN FUNCTIONS ======== */

    function setPixelMushrohm(address _pixelMushrohm) external;

    function setPaymentToken(address _tokenAddr) external;

    function setStakingPrice(uint256 _price) external;

    function setLevelUpPrice(uint256 _price) external;

    function inPlaceSporePowerUpdate(uint256 _tokenId) external;

    function withdraw(address _tokenAddr) external;

    /* ======== MUTABLE FUNCTIONS ======== */

    function stake(uint256 _tokenId) external;

    function unstake(uint256 _tokenId) external;

    function levelUp(uint256 _tokenId) external;

    /* ======== VIEW FUNCTIONS ======== */

    function getPaymentToken() external view returns (address);

    function getStakingPrice() external view returns (uint256);

    function getLevelUpPrice() external view returns (uint256);

    function sporePowerEarned(uint256 _tokenId) external view returns (uint256);

    function levelPowerEarned(uint256 _tokenId) external view returns (uint256);

    function levelPerWeek(uint256 _tokenId) external view returns (uint256);

    function isStaked(uint256 _tokenId) external view returns (bool);

    function isEligibleForLevelUp(uint256 _tokenId) external view returns (bool);
}

// SPDX-License-Identifier: GPLv2
pragma solidity ^0.8.1;

import "../interfaces/IPixelMushrohmAuthority.sol";

abstract contract PixelMushrohmAccessControlled {
    /* ========== EVENTS ========== */

    event AuthorityUpdated(IPixelMushrohmAuthority indexed authority);

    string UNAUTHORIZED = "UNAUTHORIZED"; // save gas
    string PAUSED = "PAUSED";
    string UNPAUSED = "UNPAUSED";

    /* ========== STATE VARIABLES ========== */

    IPixelMushrohmAuthority public authority;

    /* ========== Constructor ========== */

    constructor(IPixelMushrohmAuthority _authority) {
        authority = _authority;
        emit AuthorityUpdated(_authority);
    }

    /* ========== MODIFIERS ========== */

    modifier onlyOwner() {
        require(msg.sender == authority.owner(), UNAUTHORIZED);
        _;
    }

    modifier onlyPolicy() {
        require(msg.sender == authority.policy(), UNAUTHORIZED);
        _;
    }

    modifier onlyVault() {
        require(msg.sender == authority.vault(), UNAUTHORIZED);
        _;
    }

    modifier whenNotPaused() {
        require(!authority.paused(), PAUSED);
        _;
    }

    modifier whenPaused() {
        require(authority.paused(), UNPAUSED);
        _;
    }

    /* ========== OWNER ONLY ========== */

    function setAuthority(IPixelMushrohmAuthority _newAuthority) external onlyOwner {
        authority = _newAuthority;
        emit AuthorityUpdated(_newAuthority);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/extensions/IERC721Enumerable.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
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
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
    function setApprovalForAll(address operator, bool _approved) external;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

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