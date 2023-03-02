// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.13;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

interface IRouterV2 {
    function addLiquidity(
        address tokenA,
        address tokenB,
        bool stable,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity);

    function addLiquidityETH(
        address token,
        bool stable,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);

    function factory() external view returns (address);

    function wETH() external view returns (address);
}

contract CustoPresale is Ownable {
    struct UserInfo {
        uint256 amount;
        bool claimed;
    }

    mapping(address => bool) public whitelist;
    mapping(address => bool) public ogWhitelist;
    mapping(address => UserInfo) public userInfo;

    uint256 public constant WL_MAX_AMOUNT = 0.25 ether;
    uint256 public constant OG_MAX_AMOUNT = 0.5 ether;
    uint256 public constant HARD_CAP = 75 ether;
    uint256 public constant RATE = 400000; // 1 ETH = 400,000 tokens

    uint256 public raised;
    uint256 public startTime;
    uint256 public duration;
    bool public isFinalized;
    bool public isOpenClaim;

    IERC20 public custo;
    IRouterV2 public router;

    event Claim(address indexed user, uint256 amount);
    event Buy(address indexed user, uint256 amount);
    event Finalize();
    event OpenClaim();

    constructor(address _custo, address _router) {
        custo = IERC20(_custo);
        router = IRouterV2(_router);
    }

    modifier onlyWhitelisted() {
        require(whitelist[msg.sender] || ogWhitelist[msg.sender], 'Not whitelisted');
        _;
    }

    function buy() external payable onlyWhitelisted {
        require(block.timestamp >= startTime, 'Presale is not started');
        require(block.timestamp <= startTime + duration, 'Presale is ended');
        require(raised < HARD_CAP, 'Hard cap is reached');

        uint256 max = whitelist[msg.sender] ? WL_MAX_AMOUNT : OG_MAX_AMOUNT;
        UserInfo storage user = userInfo[msg.sender];
        uint256 amount = msg.value;

        if (amount + user.amount > max) {
            amount = max - user.amount;
        }

        if (raised + amount > HARD_CAP) {
            amount = HARD_CAP - raised;
        }

        require(amount > 0, 'Invalid amount');

        raised += amount;
        user.amount += amount;

        if (msg.value > amount) {
            payable(msg.sender).transfer(msg.value - amount);
        }

        emit Buy(msg.sender, amount);
    }

    function claim() external {
        require(isOpenClaim, 'Claim is not opened');
        UserInfo storage user = userInfo[msg.sender];
        require(user.amount > 0, 'Invalid amount');
        require(!user.claimed, 'Already claimed');

        user.claimed = true;

        uint256 totalToken = user.amount * RATE;

        custo.transfer(msg.sender, totalToken);

        emit Claim(msg.sender, totalToken);
    }

    function finalize() external onlyOwner {
        require(!isFinalized, 'Already finalized');
        require(block.timestamp >= startTime + duration || raised == HARD_CAP, 'Presale not ended');

        uint256 totalToken = raised * RATE;

        custo.transferFrom(msg.sender, address(this), totalToken * 2);
        custo.approve(address(router), totalToken);

        router.addLiquidityETH{value : raised}(
            address(custo),
            false, // unstable,
            totalToken,
            0,
            0,
            msg.sender,
            block.timestamp
        );

        isFinalized = true;

        emit Finalize();
    }

    function addWL(address[] memory _addresses) external onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            if (!ogWhitelist[_addresses[i]] && !whitelist[_addresses[i]]) {
                whitelist[_addresses[i]] = true;
            }
        }
    }

    function addOGWL(address[] memory _addresses) external onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            if (!ogWhitelist[_addresses[i]] && !whitelist[_addresses[i]]) {
                ogWhitelist[_addresses[i]] = true;
            }
        }
    }

    function removeWL(address[] memory _addresses) external onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            whitelist[_addresses[i]] = false;
        }
    }

    function settings(uint256 _startTime, uint256 _duration) external onlyOwner {
        startTime = _startTime;
        duration = _duration;
    }

    function openClaim() external onlyOwner {
        require(isFinalized, 'Not finalized');
        isOpenClaim = true;
        emit OpenClaim();
    }

    function safu() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    receive() external payable {}
}

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