// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
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

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

pragma solidity 0.8.19;

interface IQPN is IERC20Metadata {
    function mint(address to_, uint256 amount_) external;

    function burnFrom(address account_, uint256 amount_) external;

    function burn(uint256 amount_) external;

    function uniswapV2Pair() external view returns (address);
}

pragma solidity 0.8.19;

interface IUniswapV2Router02 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity);

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
}

pragma solidity >=0.5.0;

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint value
    ) external returns (bool);

    function withdraw(uint) external;
}

/*
    

Telegram: https://t.me/QuantumProsperNetwork
Twitter: https://twitter.com/QuantumPN
*/

pragma solidity 0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interface/IQPN.sol";
import "./interface/IWETH.sol";
import "./interface/IUniswapV2Router02.sol";

/// @title   QPNTreasury
/// @notice  QPN TREASURY
contract QPNTreasury is Ownable {
    /// STATE VARIABLS ///

    /// @notice Address of UniswapV2Router
    IUniswapV2Router02 public immutable uniswapV2Router;
    /// @notice QPN address
    address public immutable QPN;
    /// @notice WETH address
    address public immutable WETH;
    /// @notice QPN/ETH LP
    address public immutable uniswapV2Pair;

    /// @notice Distributor
    address public distributor;

    /// @notice 0.0001 ETHER
    uint256 public constant BACKING = 0.0001 ether;

    /// @notice Time to wait before removing liquidity again
    uint256 public constant TIME_TO_WAIT = 1 days;

    /// @notice Max percent of liqudity that can be removed at one time
    uint256 public constant MAX_REMOVAL = 10;

    /// @notice Timestamp of last liquidity removal
    uint256 public lastRemoval;

    /// CONSTRUCTOR ///

    /// @param _QPN  Address of QPN
    /// @param _WETH  Address of WETH
    constructor(address _QPN, address _WETH) {
        QPN = _QPN;
        WETH = _WETH;
        uniswapV2Pair = IQPN(QPN).uniswapV2Pair();

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );

        uniswapV2Router = _uniswapV2Router;
    }

    /// RECEIVE ///

    /// @notice Allow to receive ETH
    receive() external payable {}

    /// MINTER FUNCTION ///

    /// @notice         Distributor mints QPN
    /// @param _to      Address where to mint QPN
    /// @param _amount  Amount of QPN to mint
    function mintQPN(address _to, uint256 _amount) external {
        require(msg.sender == distributor, "msg.sender is not distributor");
        IQPN(QPN).mint(_to, _amount);
    }

    /// VIEW FUNCTION ///

    /// @notice         Returns amount of excess reserves
    /// @return value_  Excess reserves
    function excessReserves() external view returns (uint256 value_) {
        uint256 _balance = IERC20(WETH).balanceOf(address(this));
        uint256 _value = (_balance * 1e9) / BACKING;
        if (IERC20(QPN).totalSupply() > _value) return 0;
        return (_value - IERC20(QPN).totalSupply());
    }

    /// MUTATIVE FUNCTIONS ///

    /// @notice         Redeem QPN for backing
    /// @param _amount  Amount of QPN to redeem
    function redeemQPN(uint256 _amount) external {
        IQPN(QPN).burnFrom(msg.sender, _amount);
        IERC20(WETH).transfer(msg.sender, (_amount * BACKING) / 1e9);
    }

    /// @notice Wrap any ETH in conract
    function wrapETH() external {
        uint256 ethBalance_ = address(this).balance;
        if (ethBalance_ > 0) IWETH(WETH).deposit{value: ethBalance_}();
    }

    /// OWNER FUNCTIONS ///

    /// @notice              Set QPN distributor
    /// @param _distributor  Address of QPN distributor
    function setDistributor(address _distributor) external onlyOwner {
        require(distributor == address(0), "distributor already set");
        distributor = _distributor;
    }

    /// @notice         Remove liquidity and add to backing
    /// @param _amount  Amount of liquidity to remove
    function removeLiquidity(uint256 _amount) external onlyOwner {
        uint256 balance = IERC20(uniswapV2Pair).balanceOf(address(this));
        require(
            _amount <= (balance * MAX_REMOVAL) / 100,
            "Removing more than 10% of liquidity"
        );
        require(
            block.timestamp > lastRemoval + TIME_TO_WAIT,
            "Removed before 1 day lock"
        );
        lastRemoval = block.timestamp;

        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), _amount);

        uniswapV2Router.removeLiquidityETHSupportingFeeOnTransferTokens(
            QPN,
            _amount,
            0,
            0,
            address(this),
            block.timestamp
        );

        _burnQPN();
    }

    /// @notice         Withdraw stuck token from treasury
    /// @param _amount  Amount of token to remove
    /// @param _token   Address of token to remove
    function withdrawStuckToken(
        uint256 _amount,
        address _token
    ) external onlyOwner {
        require(_token != WETH, "Can not withdraw WETH");
        require(_token != uniswapV2Pair, "Can not withdraw LP");
        IERC20(_token).transfer(msg.sender, _amount);
    }

    /// INTERNAL FUNCTION ///

    /// @notice Burn QPN from Treasury to increase backing
    /// @dev    Invoked in `removeLiquidity()`
    function _burnQPN() internal {
        uint256 balance = IERC20(QPN).balanceOf(address(this));
        IQPN(QPN).burn(balance);
    }
}