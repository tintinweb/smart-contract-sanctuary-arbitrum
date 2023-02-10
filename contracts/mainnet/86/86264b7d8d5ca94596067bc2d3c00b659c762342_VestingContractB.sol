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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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

/**
 * https://arcadeum.io
 * https://arcadeum.gitbook.io/arcadeum
 * https://twitter.com/arcadeum_io
 * https://discord.gg/qBbJ2hNPf8
 */

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.13;

import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";
import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IERC20BackwardsCompatible.sol";

contract VestingContractB is Ownable, ReentrancyGuard {
    address public immutable ARC;
    IERC20 public immutable arc;

    mapping (address => uint256) public ethAmount;
    mapping (address => mapping (uint256 => bool)) public claims;
    mapping (address => uint256) public claimedTokens;
    uint256 public ethTotal = 100 ether;
    uint256 public start;

    constructor (address _ARC) {
        ARC = _ARC;
        arc = IERC20(_ARC);

        ethAmount[0xf73305245afE0cBb1E64B0E0941CFF5eB6dA0194] = 5 ether;
        ethAmount[0x42b6229E536c01aEb20922D3DeC5af1c0a8585c9] = 5 ether;
        ethAmount[0x2DFe63c5c02805d94Fa1e5204e30ba82d76174a3] = 5 ether;
        ethAmount[0x7b5EdceC8DE439290c3D314411393b8174e93F98] = 5 ether;
        ethAmount[0xf5F14b4C229770Ac5FD948a32eCFD3Ba6Abb6Ff4] = 5 ether;
        ethAmount[0x9a1EaBb4cFe6fC4b624B2b84D917B1453c5fe8bb] = 5 ether;
        ethAmount[0x6a1617a5E98d7540557044f3C88BE6c4266f1e15] = 5 ether;
        ethAmount[0x3e1f15E9994387E4FE3E45B34076c8d25Cd7D2a4] = 5 ether;
        ethAmount[0x950D2d8761b70E1E4F3ECeBAc9bE1dBBCeA75d43] = 5 ether;
        ethAmount[0xaB650fbC2AB9A71045A7DEd344ae5E8803ee3E1b] = 5 ether;
        ethAmount[0x4D05651cB4E0834Ddfe0987e998baC151263D2E3] = 2.6 ether;
        ethAmount[0xC0e2278ACEc087B57E1030e929CD04cf6A168F82] = 2.6 ether;
        ethAmount[0xBa42828d289d964AcF7d3Bc67c35F19C8d53A5fa] = 2.6 ether;
        ethAmount[0xdCc3CC686f0835837B83DdA591fb84F8817A7b0A] = 2.6 ether;
        ethAmount[0xb7048f1C846a3b49d126166bB7699ac31fd97382] = 2.6 ether;
        ethAmount[0xd3896A9005998C54D6F3BD997286FDcA7030Ac37] = 2.6 ether;
        ethAmount[0x4b65dd7D001070099d5c8f1Fa1e2937FceD480aC] = 2.6 ether;
        ethAmount[0x3c843dD872C95253a76A50300528c295D74ADac9] = 2.6 ether;
        ethAmount[0x6676E2110335c9698AAAf2190563F127a658ed77] = 2.6 ether;
        ethAmount[0xA332CD3c6b686e20a2a1CF2a13Cb67b895e01A5b] = 2.6 ether;
        ethAmount[0x784941B0cA053Aab18E119a646E7F4761530CbAc] = 2.6 ether;
        ethAmount[0x65e1906Ce38A55CB48860a2407a0C017C09aBD42] = 2.6 ether;
        ethAmount[0xD85A6DFB505a76d272cAF51af79F55d929469D68] = 2.6 ether;
        ethAmount[0xFF82f712B12d428659AFB4c8739cc8bec4a1B55b] = 2.6 ether;
        ethAmount[0x12E9a397d23B7EA5B4C00376BF923CFb31f22458] = 2.6 ether;
        ethAmount[0x7b9eBe4f789E53bB12c314ca4f144092FEeE152b] = 2.4 ether;
        ethAmount[0x51c64cAFA40f49f442461D325E3B182B3eF17Cae] = 2.4 ether;
        ethAmount[0x19F4762e5688E46711204f766F2D1F65A560c993] = 2.4 ether;
        ethAmount[0x37eFE342918b4FCA9c9d286C74B5CAE968740418] = 2.4 ether;
        ethAmount[0x82F8f2cFFD0A68D08B4d5d4da01d55B7069A3106] = 2.4 ether;
        start = block.timestamp;
    }

    function getTokensPerAccount(address _account) public view returns (uint256) {
        if (ethAmount[_account] == 0) {
            return 0;
        }
        return (20000000 * (10**18)) * ethAmount[_account] / ethTotal;
    }

    function getClaimsByAccount(address _account) external view returns (uint256) {
        return claimedTokens[_account];
    }

    function claim() external nonReentrant {
        uint256 _tokens;
        if ((block.timestamp >= start) && (!claims[msg.sender][0])) {
            _tokens += getTokensPerAccount(msg.sender) * 3100 / 10000;
            claimedTokens[msg.sender] += _tokens;
            claims[msg.sender][0] = true;
        }
        if ((block.timestamp >= start + (86400 * 7)) && (!claims[msg.sender][1])) {
            _tokens += getTokensPerAccount(msg.sender) * 2300 / 10000;
            claimedTokens[msg.sender] += _tokens;
            claims[msg.sender][1] = true;
        }
        if ((block.timestamp >= start + (86400 * 14)) && (!claims[msg.sender][2])) {
            _tokens += getTokensPerAccount(msg.sender) * 2300 / 10000;
            claimedTokens[msg.sender] += _tokens;
            claims[msg.sender][2] = true;
        }
        if ((block.timestamp >= start + (86400 * 21)) && (!claims[msg.sender][3])) {
            _tokens += getTokensPerAccount(msg.sender) * 2300 / 10000;
            claimedTokens[msg.sender] += _tokens;
            claims[msg.sender][3] = true;
        }
        if (_tokens > 0) {
            arc.transfer(msg.sender, _tokens);
        }
    }

    function emergencyWithdrawToken(address _token, uint256 _amount) external nonReentrant onlyOwner {
        IERC20BackwardsCompatible(_token).transfer(msg.sender, _amount);
    }

    function emergencyWithdrawETH(uint256 _amount) external nonReentrant onlyOwner {
        payable(msg.sender).call{value: _amount}("");
    }

    receive() external payable {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity >=0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20BackwardsCompatible {
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
    function transfer(address to, uint256 amount) external;

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
    function approve(address spender, uint256 amount) external;

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
    ) external;
}