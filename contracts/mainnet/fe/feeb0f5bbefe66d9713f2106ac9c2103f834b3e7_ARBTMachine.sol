/**
 *Submitted for verification at Arbiscan on 2023-08-02
*/

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;


interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}

interface IWETH9 is IERC20 {
    /// @notice Deposit ether to get wrapped ether
    function deposit() external payable;

    /// @notice Withdraw wrapped ether to get ether
    function withdraw(uint256) external;
}

interface IARBT is IERC20 {
    function mint(address account, uint256 amount) external;
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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

interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}

interface IV3SwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @dev Setting `amountIn` to 0 will cause the contract to look up its own balance,
    /// and swap the entire amount, enabling contracts to send tokens before calling this function.
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @dev Setting `amountIn` to 0 will cause the contract to look up its own balance,
    /// and swap the entire amount, enabling contracts to send tokens before calling this function.
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// that may remain in the router after the swap.
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// that may remain in the router after the swap.
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

contract ARBTMachine is Ownable {
    struct Pledge {
        uint256 amount;
        uint8 status;
        uint256 index;
    }

    uint256 public index = 5000;

    mapping(address => uint256[]) private _index;
    mapping(uint256 => Pledge) private _pledges;
    mapping(uint256 => address) private _indexToAddress;

    address public arb;
    address public arbt;
    address public dao;
    address public dividend;
    address public minter;
    address public ku;
    address private weth = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
    address private router = 0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45;


    event UserMint(address account, uint256 pledgeAmount, uint256 index);



    constructor() {
        arb = 0x912CE59144191C1204E64559FE8253a0e49E6548;
        dao = 0x31c96D24aA757125aD6897583115b74f334651da;
        dividend = 0x31c96D24aA757125aD6897583115b74f334651da;
        minter = 0x31c96D24aA757125aD6897583115b74f334651da;
        ku = 0x757f4E983E41BE33Ab8EA356A3c074C24b7f1418;
    }

    receive() external payable {}

    function setArbt(address arbt_) public onlyOwner {
        arbt = arbt_;
    }


    function setAddress(address account, uint8 type_) public onlyOwner {
        require(account != address(0), "Wrong address");
        if (type_ == 1) {
            dao = account;
        } else if (type_ == 2) {
            dividend = account;
        } else if (type_ == 3) {
            minter = account;
        } else {
            ku = account;
        }
    }

    function changeStatus(uint256[] memory indexes_) public onlyOwner {
        for (uint256 i = 0; i < indexes_.length; i++) {
            if (_pledges[indexes_[i]].status == 0) {
                _pledges[indexes_[i]].status = 1;
            }
        }
    }


    function mint(uint256 amount, uint256 amountMint) public {
        require(amount > 0 && amountMint > 0, "Wrong amount");
        uint256 amountDao = amount * 5 / 100;
        IERC20(arb).transferFrom(_msgSender(), dao, amountDao);
        IERC20(arb).transferFrom(_msgSender(), dividend, amountDao);
        IERC20(arb).transferFrom(_msgSender(), address(this), amount - amountDao - amountDao);

        IARBT(arbt).mint(minter, amountMint);
        index++;
        _pledges[index] = Pledge(amount * 30 / 100, 0, index);
        _index[_msgSender()].push(index);
        _indexToAddress[index] = _msgSender();

        uint256 ethAmount = amount * 60 / 100;
        IERC20(arb).approve(router, ethAmount);
        IV3SwapRouter.ExactInputSingleParams memory params = IV3SwapRouter.ExactInputSingleParams({
        tokenIn : arb,
        tokenOut : weth,
        fee : 3000,
        recipient : address(this),
        amountIn : ethAmount,
        amountOutMinimum : 0,
        sqrtPriceLimitX96 : 0
        });
        IV3SwapRouter(router).exactInputSingle(params);
        uint256 wethBalance = IWETH9(weth).balanceOf(address(this));
        if (wethBalance > 0) {
            IWETH9(weth).withdraw(wethBalance);
            ku.call{value : wethBalance}("");
        }
        emit UserMint(_msgSender(), amount * 30 / 100, index);
    }

    function pledgeOf(address account) public view returns (Pledge[] memory){
        Pledge[] memory asks = new Pledge[](_index[account].length);
        for (uint256 i = 0; i < _index[account].length; i++) {
            uint256 indexThis = _index[account][i];
            asks[i] = _pledges[indexThis];
        }
        return asks;
    }

    function unPledge(uint256 index_) public {
        require(_indexToAddress[index_] == _msgSender(), "Wrong index");
        require(_pledges[index_].status == 1, "Wrong index");
        IERC20(arb).transfer(_msgSender(), _pledges[index_].amount);
        _pledges[index_].status = 2;
    }


    function initPledge(address[] memory accounts, uint256[] memory amounts, uint256[] memory chainIndex) public onlyOwner {
        for (uint i = 0; i < accounts.length; i++) {
            initOne(accounts[i],amounts[i],chainIndex[i]);
        }
    }

    function initOne(address account, uint256 amount, uint256 chainIndex) public onlyOwner {
        require(_indexToAddress[chainIndex] == address(0),"Wrong index");
        _pledges[chainIndex] = Pledge(amount, 0, chainIndex);
        _index[account].push(chainIndex);
        _indexToAddress[chainIndex] = account;
    }
}