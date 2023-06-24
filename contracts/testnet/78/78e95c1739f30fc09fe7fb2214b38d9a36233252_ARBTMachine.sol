/**
 *Submitted for verification at Arbiscan on 2023-06-23
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

    function mint(address account, uint256 amount) external;

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

interface ISwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

contract ARBTMachine is Ownable {
    struct Pledge {
        uint256 amount;
        int8 status;
    }

    uint256 public index;

    mapping(address => uint256[]) private _index;
    mapping(uint256 => Pledge) private _pledges;
    mapping(uint256 => address) private _indexToAddress;

    address public arb;
    address public arbt;
    address public dao;
    address public dividend;
    address private weth;
    address private router = 0xE592427A0AEce92De3Edee1F18E0157C05861564;


    event UserMint(address account, uint256 pledgeAmount, uint256 index);

    // arb main 0x912CE59144191C1204E64559FE8253a0e49E6548
    // weth main 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1



    constructor() {
        arbt = 0x83B8334f2068F6FC45788Ec78761735d60888ebc;
        arb = 0x4036Bb10E1E5453c2eBA13333b38948Ea1bE4A65;
        dao = 0x31c96D24aA757125aD6897583115b74f334651da;
        dividend = 0x31c96D24aA757125aD6897583115b74f334651da;
        weth = 0xB43a684A135CC9bD31cCaC13530Fdc847ef8E34C;
    }

    receive() external payable {}

    function setArbt(address arbt_) public onlyOwner {
        arbt = arbt_;
    }


    function withdrawEth(address payable account, uint256 amount) public onlyOwner {
        account.transfer(amount);
    }

    function withdrawArbt(address account, uint256 amount) public onlyOwner {
        IERC20(arbt).transfer(account, amount);
    }

    function changeStatus(uint256[] memory indexes_) public onlyOwner {
        for (uint256 i = 0; i < indexes_.length; i++) {
            _pledges[indexes_[i]].status = 1;
        }
    }


    function mint(uint256 amount, uint256 amountMint) public {
        require(amount > 0 && amountMint > 0, "Wrong amount");
        uint256 amountDao = amount * 5 / 100;
        IERC20(arb).transferFrom(_msgSender(), dao, amountDao);
        IERC20(arb).transferFrom(_msgSender(), dividend, amountDao);
        IERC20(arb).transferFrom(_msgSender(), address(this), amount - amountDao - amountDao);

        IERC20(arbt).mint(address(this), amountMint);
        _pledges[++index] = Pledge(amount * 30 / 100, 0);
        _index[_msgSender()].push(index);
        _indexToAddress[index] = _msgSender();

        uint256 ethAmount = amount * 60 / 100;
        IERC20(weth).approve(router, ethAmount);
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams(
            arb,
            weth,
            3000,
            address(this),
            block.timestamp,
            ethAmount,
            0,
            0
        );
        try ISwapRouter(router).exactInputSingle(params){} catch{}
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
        Pledge memory p = _pledges[index_];
        require(p.status == 1, "Wrong index");
        IERC20(arb).transfer(_msgSender(), p.amount);
        p.status = 2;
    }

}