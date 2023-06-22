/**
 *Submitted for verification at Arbiscan on 2023-06-22
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;

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

interface ISwapRouter {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        //uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    function exactInputSingle(ExactInputSingleParams calldata params) external returns (uint256);
}

struct Target {
    address targetAddress;
    uint256 sourceAmount;
}

contract DCABot {
    address owner;
    address proposedNewOwner;

    bool isInitialized = false;
    address uniswapAddress;
    bool enableBuys = true;

    uint256 buyCooldown = 1000*60*60*24; 
    uint256 timeOfLastBuy = 0;

    address sourceTokenAddress;
    Target[] sourceAmountsPerTarget;

    event NewOwnerProposed(address _proposer, address _proposedAddress);
    event OwnerChanged(address _from, address _to);

    event Initialized();
    event BuyEnabledFlagChanged(bool _newValue);
    event SettingsUpdated();

    event ETHWithdrawn(address _to, uint256 _amount);
    event ERC20Withdrawn(address _tokenAddress, address _to, uint256 _amount);

    event ETHReceived(address _from, uint256 _amount);
    event ERC20Received(address _from, address _tokenAddress, uint256 _amount);

    event TokenPurchased(address _source, address _target, uint256 _sourceAmount, uint256 _targetAmount);

    modifier isOwner() {
        require(msg.sender == owner, "Sender is not the owner.");
        _;
    }

    modifier allowBuy() {
        require(isInitialized, "Bot has not been initialized.");
        require(enableBuys, "Buying has been disabled");

        uint256 timeSinceLastBuy = block.timestamp - timeOfLastBuy;
        require(timeSinceLastBuy >= buyCooldown, "Not enough time has passed since the last buy.");

        _;
    }
    
    constructor() {
        owner = msg.sender;
    }

    receive() external payable {
        emit ETHReceived(msg.sender, msg.value);
    }

    function withdrawETH() isOwner public {
        uint256 balance = address(this).balance;
        require(balance > 0, "No ETH to transfer.");

        (bool success,) = owner.call{value: balance}("");
        require(success, "ETH transfer failed.");

        emit ETHWithdrawn(owner, balance);
    }

    function withdrawERC20(address _tokenAddress) isOwner public {
        IERC20 token = IERC20(_tokenAddress);

        uint256 balance = token.balanceOf(address(this));
        require(balance > 0, "This token has no balance.");

        bool success = token.transfer(owner, balance);
        require(success, "Token transfer failed.");

        emit ERC20Withdrawn(owner, _tokenAddress, balance);
    }

    function updateOwner(address _address) isOwner public {
        proposedNewOwner = payable(_address);

        emit NewOwnerProposed(msg.sender, _address);
    }

    function confirmOwner() public {
        require(msg.sender == proposedNewOwner, "You are not the proposed new owner.");
        
        address _oldOwner = owner;
        owner = proposedNewOwner;
        proposedNewOwner = address(0);

        emit OwnerChanged(_oldOwner, owner);
    }

    function updateSettings(address _sourceToken, address _uniswapAddress, address[] memory _targetTokens, uint256[] memory _sourceAmountsPerTarget, uint256 _buyCooldown) isOwner public {
        require(_targetTokens.length == _sourceAmountsPerTarget.length, "Invalid target arrays.");

        delete sourceAmountsPerTarget;

        for (uint256 i = 0; i < _targetTokens.length; i++) {
            sourceAmountsPerTarget.push(Target({
                targetAddress: _targetTokens[i],
                sourceAmount: _sourceAmountsPerTarget[i]
            }));
        }

        sourceTokenAddress = _sourceToken;
        uniswapAddress = _uniswapAddress;
        buyCooldown = _buyCooldown;

        if (!isInitialized) isInitialized = true;
    }

    function performRecurringBuy(uint24 _poolFee) public {
        for (uint256 i = 0; i < sourceAmountsPerTarget.length; i++) {
            performBuy(
                sourceTokenAddress,
                sourceAmountsPerTarget[i].targetAddress,
                sourceAmountsPerTarget[i].sourceAmount,
                //_deadline,
                _poolFee
            );
        }
    }

    function performBuy(address _sourceAddress, address _targetAddress, uint256 _sourceAmount, uint24 _poolFee) private returns (uint256 amount) {
        IERC20 sourceToken = IERC20(_sourceAddress);

        uint256 sourceTokenBalance = sourceToken.balanceOf(address(this));
        require(sourceTokenBalance >= _sourceAmount, "Not enough input tokens for swap.");

        bool approved = sourceToken.approve(uniswapAddress, _sourceAmount);
        require(approved, "Failed to approve token for swap.");

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
            tokenIn: _sourceAddress,
            tokenOut: _targetAddress,
            fee: _poolFee,
            recipient: owner,
            amountIn: _sourceAmount,
            amountOutMinimum: 0,
            sqrtPriceLimitX96: 0
        });

        uint256 amountOut = ISwapRouter(uniswapAddress).exactInputSingle(params);

        emit TokenPurchased(_sourceAddress, _targetAddress, _sourceAmount, amountOut);

        return amountOut;
    }

    function getOwner() public view returns (address) {
        return owner;
    }

    function getProposedOwner() public view returns (address) {
        return proposedNewOwner;
    }
}