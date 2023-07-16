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
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IFuel.sol";
import "./interfaces/IUniswapV2Router.sol";

contract FuelPresale is Ownable, ReentrancyGuard {
    // ====== EVENTS ====== //

    event BoughtPresale(uint256 ethAmount, uint256 tokensAmount);
    event AddedLiquidity(uint256 ethAmount, uint256 tokensAmount);

    // ====== STORAGE ====== //

    uint256 public immutable startPresaleTime;
    uint256 public immutable startPublicTime;
    uint256 public immutable endTime;

    uint256 public immutable whitelistPresaleDuration = 1 days;
    uint256 public immutable overallPresaleDuration = 2 days;
    uint256 public immutable claimDelayAfterPresale = 1 hours;

    mapping(address => uint256) public ethSpent;
    mapping(address => uint256) public tokensToClaim;
    uint256 public softCap = 20 ether;
    uint256 public hardCap = 200 ether;
    uint256 public maxPerWallet = 10 ether;
    uint256 public presalePrice = 2250 * 1e18;
    uint256 public whitelistHardCap = 40 ether;
    uint256 public whitelistMaxPerWallet = 0.5 ether;
    uint256 public whitelistPresalePrice = 2770 * 1e18;
    mapping(address => bool) public isWhitelisted;

    uint256 public totalEthRaised = 0;
    uint256 public totalTokensSold = 0;

    uint256 public unclaimedTokens = 0;

    IFuel public immutable fuel;
    IUniswapV2Router02 public router;

    address public treasury;

    bool public liquidityAdded = false;

    // ====== CONSTRUCTOR ====== //

    constructor(uint256 _startTime, IFuel _fuel, IUniswapV2Router02 _router) {
        startPresaleTime = _startTime;
        startPublicTime = _startTime + whitelistPresaleDuration;
        endTime = _startTime + overallPresaleDuration;
        fuel = _fuel;
        router = _router;
    }

    // ====== PUBLIC FUNCTIONS ====== //

    function buyPresale() external payable {
        require(block.timestamp >= startPresaleTime && block.timestamp <= endTime, "Not active");
        require(msg.sender == tx.origin, "No contracts");
        require(msg.value > 0, "Zero amount");
        uint256 tokensPerEth = presalePrice;
        if (block.timestamp < startPublicTime) {
            // whitelist presale
            require(isWhitelisted[msg.sender], "Not whitelisted");
            require(ethSpent[msg.sender] + msg.value <= whitelistMaxPerWallet, "Over wallet limit");
            require(totalEthRaised + msg.value <= whitelistHardCap, "Amount over limit");
            tokensPerEth = whitelistPresalePrice;
        } else {
            // public presale
            require(ethSpent[msg.sender] + msg.value <= maxPerWallet, "Over wallet limit");
            require(totalEthRaised + msg.value <= hardCap, "Amount over limit");
        }

        uint256 tokensSold = (msg.value * tokensPerEth) / 1e18;

        ethSpent[msg.sender] += msg.value;
        tokensToClaim[msg.sender] += tokensSold;

        totalEthRaised += msg.value;
        totalTokensSold += tokensSold;
        unclaimedTokens += tokensSold;

        emit BoughtPresale(msg.value, tokensSold);
    }

    function claim() external {
        require(block.timestamp > endTime + claimDelayAfterPresale, "Not claimable");
        require(totalEthRaised >= softCap, "SoftCap was NOT reached");
        require(tokensToClaim[msg.sender] > 0, "No amount claimable");

        uint256 tokensAmount = tokensToClaim[msg.sender];

        unclaimedTokens -= tokensAmount;
        tokensToClaim[msg.sender] = 0;
        fuel.transferUnderlying(msg.sender, tokensAmount);
    }

    function refund() external {
        require(block.timestamp > endTime + claimDelayAfterPresale, "Presale not ended yet");
        require(totalEthRaised < softCap, "SoftCap was reached, no refund possible");
        require(ethSpent[msg.sender] > 0, "No ETH spent");

        uint256 refundEth = ethSpent[msg.sender];

        ethSpent[msg.sender] = 0;
        payable(msg.sender).transfer(refundEth);
    }

    // ====== ONLY OWNER ====== //

    function setHardCap(uint256 _hardCap) external onlyOwner {
        hardCap = _hardCap;
    }

    function setRouter(IUniswapV2Router02 _router) external onlyOwner {
        router = _router;
    }

    function setIsWhitelisted(address[] calldata wallets) external onlyOwner {
        for (uint256 i = 0; i < wallets.length; i++) {
            isWhitelisted[wallets[i]] = true;
        }
    }

    function addLiquidity() external nonReentrant onlyOwner {
        require(block.timestamp > endTime, "Not finished");
        require(!liquidityAdded, "Already added");
        require(totalEthRaised >= softCap, "SoftCap was NOT reached");

        fuel.approve(address(router), uint256(2 ** 256 - 1));
        uint256 totalAmount = address(this).balance;
        payable(owner()).transfer((totalAmount * 20) / 100);

        uint256 ethAmount = totalAmount - ((totalAmount * 20) / 100);
        uint256 tokenAmount = (((ethAmount * presalePrice) / 1e18) * 80) / 100;
        router.addLiquidityETH{value: ethAmount}(address(fuel), tokenAmount, 1, 1, msg.sender, type(uint256).max);
        emit AddedLiquidity(ethAmount, tokenAmount);
        liquidityAdded = true;

        uint256 totalBurnedTokens = fuel.balanceOf(address(this)) - totalTokensSold;
        fuel.burn(totalBurnedTokens);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IFuel {
    function getBlockNumber() external returns (uint256);

    function mint(address to, uint256 amount) external returns (bool);

    function burn(uint256 amount) external;

    function balanceOf(address account) external returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferUnderlying(address to, uint256 amount) external returns (bool);

    function tokensToFragmentAtCurrentScalingFactor(uint256 value) external view returns (uint256);

    function fragmentToTokenAtCurrentScalingFactor(uint256 value) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IUniswapV2Router02 {
    function WETH() external pure returns (address);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);

    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);
}