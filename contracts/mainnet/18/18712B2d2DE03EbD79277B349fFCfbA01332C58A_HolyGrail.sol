// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import {SafeOwnable} from "./libraries/SafeOwnable.sol";

interface IPresale {
    function START_TIME() external view returns (uint256);

    function END_TIME() external view returns (uint256);

    function GRAIL() external view returns (address);

    function XGRAIL() external view returns (address);

    function LP_TOKEN() external view returns (address);

    function hasStarted() external view returns (bool);

    function isSaleActive() external view returns (bool);

    function totalRaised() external view returns (uint256);

    function totalAllocation() external view returns (uint256);

    function MIN_TOTAL_RAISED_FOR_MAX_GRAIL() external view returns (uint256);

    function getExpectedClaimAmounts(address account) external view returns (uint256 grailAmount, uint256 xGrailAmount);

    function buy(uint256 amount, address referralAddress) external;

    function claim() external;
}

interface IXGrailToken {
    function maxRedeemDuration() external view returns (uint256);

    function redeem(uint256 xGrailAmount, uint256 duration) external;

    function finalizeRedeem(uint256 redeemIndex) external;
}

/// @notice Snipes GRAIL and xGRAIL presale with USDC
/// @dev Only works on Arbitrum One
contract HolyGrail is SafeOwnable {
    address public constant PRESALE = 0x66eC1EE6c3AD04d7629Ce4a6d5d19ba99c365d29;
    address public constant USDC = 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8;

    address public immutable grail;
    address public immutable xgrail;

    constructor(address owner) SafeOwnable(owner) {
        grail = IPresale(PRESALE).GRAIL();
        xgrail = IPresale(PRESALE).XGRAIL();
    }

    function timestamp() public view returns (uint256) {
        return block.timestamp;
    }

    function startTime() public view returns (uint256) {
        return IPresale(PRESALE).START_TIME();
    }

    function endTime() public view returns (uint256) {
        return IPresale(PRESALE).END_TIME();
    }

    function startIn() public view returns (uint256) {
        return IPresale(PRESALE).START_TIME() - timestamp();
    }

    function endIn() public view returns (uint256) {
        return IPresale(PRESALE).END_TIME() - timestamp();
    }

    function shouldSnipe() public view returns (bool) {
        uint256 roof = IPresale(PRESALE).MIN_TOTAL_RAISED_FOR_MAX_GRAIL();
        return IPresale(PRESALE).hasStarted() && IPresale(PRESALE).totalRaised() < roof;
    }

    function buyAll(address _for) external {
        IERC20Metadata(USDC).transferFrom(_for, address(this), IERC20Metadata(USDC).allowance(_for, address(this)));
        uint256 _balance = IERC20Metadata(USDC).balanceOf(address(this));

        IERC20Metadata(USDC).approve(PRESALE, _balance);
        IPresale(PRESALE).buy(_balance, address(0));

        (uint256 grailClaimable, uint256 xgrailClaimable) = IPresale(PRESALE).getExpectedClaimAmounts(address(this));
        require(grailClaimable >= ((_balance * 1E18) / 10 ** IERC20Metadata(USDC).decimals()) / 35, "missed grail");
        require(xgrailClaimable >= ((_balance * 1E18) / 10 ** IERC20Metadata(USDC).decimals()) / 65, "missed xgrail");
    }

    function claimAll(address _for) external onlyOwner {
        IPresale(PRESALE).claim();
        IERC20Metadata(grail).transfer(_for, IERC20Metadata(grail).balanceOf(address(this)));
    }

    function redeemAll() external onlyOwner {
        IXGrailToken(xgrail).redeem(
            IERC20Metadata(xgrail).balanceOf(address(this)),
            IXGrailToken(xgrail).maxRedeemDuration()
        );
    }

    function finalizeRedeemAll(address _for, uint256 _index) external onlyOwner {
        IXGrailToken(xgrail).finalizeRedeem(_index);
        IERC20Metadata(grail).transfer(_for, IERC20Metadata(grail).balanceOf(address(this)));
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

/* solhint-disable reason-string */

contract SafeOwnable {
    /* ▁▂▃▄▅▆▇█▉▊▋▌▍▎▏ STATE VARIABLES  ▏▎▍▌▋▊▉█▇▆▅▄▃▂▁ */

    address private _owner;
    address private _pendingOwner;

    /* ▁▂▃▄▅▆▇█▉▊▋▌▍▎▏ EVENTS  ▏▎▍▌▋▊▉█▇▆▅▄▃▂▁ */

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /* ▁▂▃▄▅▆▇█▉▊▋▌▍▎▏ CONSTRUCTOR  ▏▎▍▌▋▊▉█▇▆▅▄▃▂▁ */

    /// @notice ownership is assigned to `owner_` on construction
    constructor(address owner_) {
        _owner = owner_;
        emit OwnershipTransferred(address(0), _owner);
    }

    /* ▁▂▃▄▅▆▇█▉▊▋▌▍▎▏ MODIFIERS  ▏▎▍▌▋▊▉█▇▆▅▄▃▂▁ */

    /// @notice Only allows the `owner` to execute the function
    modifier onlyOwner() {
        require(msg.sender == _owner, "SafeOwnable::onlyOwner: caller is not the owner");
        _;
    }

    /* ▁▂▃▄▅▆▇█▉▊▋▌▍▎▏ VIEWS  ▏▎▍▌▋▊▉█▇▆▅▄▃▂▁ */

    /// @dev Returns the address of the current owner
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /// @dev Returns the address of the pending owner
    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }

    /* ▁▂▃▄▅▆▇█▉▊▋▌▍▎▏ EXTERNALS  ▏▎▍▌▋▊▉█▇▆▅▄▃▂▁ */

    /// @notice Transfers ownership to `newOwner`, either directly or pending claim by the new owner
    /// @dev Can only be invoked by the current `owner`
    /// @param newOwner Address of the new owner
    /// @param direct True if the new owner should be set immediately. False if the new owner needs to claim first
    function transferOwnership(address newOwner, bool direct) public virtual onlyOwner {
        if (direct) {
            // Checks
            require(newOwner != address(0), "SafeOwnable::transferOwnership: zero address");

            // Effects
            emit OwnershipTransferred(_owner, newOwner);
            _owner = newOwner;
            _pendingOwner = address(0);
        } else {
            // Effects
            _pendingOwner = newOwner;
        }
    }

    /// @notice Called by the pending owner to claim ownership
    function claimOwnership() public virtual {
        // Checks
        require(msg.sender == _pendingOwner, "SafeOwnable::claimOwnership: caller not pending owner");

        // Effects
        emit OwnershipTransferred(_owner, _pendingOwner);
        _owner = _pendingOwner;
        _pendingOwner = address(0);
    }

    /// @notice Irreversibly removes the contract owner. It will not be possible to call `onlyOwner` functions anymore
    /// @dev Can only be called by the current `owner`. It will also void any pending ownership changes
    function renounceOwnership() public virtual onlyOwner {
        // Effects
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
        _pendingOwner = address(0);
    }
}