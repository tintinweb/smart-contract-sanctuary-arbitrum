/**
 *Submitted for verification at Arbiscan on 2023-06-26
*/

/**
 *Submitted for verification at Arbiscan on 2023-06-25
*/

// SPDX-License-Identifier: MIT

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
   struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    function exactInput(ExactInputParams calldata params) external returns (uint256);
}

struct Target {
    uint256 sourceAmount;
    address targetToken;
    bytes path;
}

contract DCABot {
    address owner;
    address proposedNewOwner;

    bool isInitialized = false;
    bool buysEnabled = true;

    address uniswapAddress;

    uint256 buyCooldown = 1000*60*60*24; 
    uint256 timeOfLastBuy = 0;

    address sourceTokenAddress;
    Target[] targets;

    event NewOwnerProposed(address _proposer, address _proposedAddress);
    event OwnerChanged(address _from, address _to);

    event Initialized();
    event BuyEnabledFlagChanged(bool _newValue);
    event SettingsUpdated();
    event LastBuyTimeReset();

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
        require(buysEnabled, "Buying has been disabled");
        require(isInBuyPeriod(), "Not enough time has passed since the last buy.");
        _;
    }

    constructor() {
        owner = msg.sender;
        timeOfLastBuy = block.timestamp;
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

    function updateSettings(address _sourceToken, address _uniswapAddress, uint256[] calldata _sourceAmountsPerTarget, address[] calldata _targetTokens, bytes[] calldata _paths, uint256 _buyCooldown) isOwner public {
        require(_sourceAmountsPerTarget.length == _targetTokens.length && _targetTokens.length == _paths.length, "Invalid input arrays.");

        delete targets;

        for (uint256 i = 0; i < _paths.length; i++) {
            targets.push(Target({
                sourceAmount: _sourceAmountsPerTarget[i],
                targetToken: _targetTokens[i],
                path: _paths[i]
            }));
        }

        sourceTokenAddress = _sourceToken;
        uniswapAddress = _uniswapAddress;
        buyCooldown = _buyCooldown;

        if (!isInitialized) {
            isInitialized = true;

            emit Initialized();
        }

        emit SettingsUpdated();
    }

    function performRecurringBuy() public {
        uint256 totalSourceAmount = 0;

        for (uint256 i = 0; i < targets.length; i++) {
            totalSourceAmount += targets[i].sourceAmount;
        }

        IERC20 sourceToken = IERC20(sourceTokenAddress);

        uint256 sourceTokenBalance = sourceToken.balanceOf(address(this));
        require(sourceTokenBalance >= totalSourceAmount, "Not enough input tokens for swap.");

        bool approved = sourceToken.approve(uniswapAddress, totalSourceAmount);
        require(approved, "Failed to approve token for swap.");

        for (uint256 i = 0; i < targets.length; i++) {
            performBuy(
                sourceTokenAddress,
                targets[i].sourceAmount,
                targets[i].targetToken,
                targets[i].path
            );
        }

        timeOfLastBuy = block.timestamp;
    }

    function performBuy(address _sourceAddress, uint256 _sourceAmount, address _targetAddress, bytes memory path) private returns (uint256) {
        ISwapRouter.ExactInputParams memory params = ISwapRouter.ExactInputParams({
            path: path,
            recipient: owner,
            deadline: block.timestamp,
            amountIn: _sourceAmount,
            amountOutMinimum: 0
        });

        uint256 amountOut = ISwapRouter(uniswapAddress).exactInput(params);

        emit TokenPurchased(_sourceAddress, _targetAddress, _sourceAmount, amountOut);

        return amountOut;
    }

    function setBuyEnabled(bool _newState) isOwner public {
        require(_newState != buysEnabled, "No buy state change requested.");

        buysEnabled = _newState;

        emit BuyEnabledFlagChanged(_newState);
    }

    function resetTimeOfLastBuy() isOwner public {
        require(timeOfLastBuy > 0, "Already reset.");

        timeOfLastBuy = 0;

        emit LastBuyTimeReset();
    }

    function getOwner() public view returns (address) {
        return owner;
    }

    function getProposedOwner() public view returns (address) {
        return proposedNewOwner;
    }

    function isInBuyPeriod() public view returns (bool) {
        if (!isInitialized) return false;

        return block.timestamp - timeOfLastBuy >= buyCooldown;
    }

    function getSingleHopBytes(address _source, uint24 _fee, address _target) public pure returns (bytes memory) {
        return abi.encodePacked(_source, _fee, _target);
    }

    function getTwoHopBytes(address _source, uint24 _firstFee, address _middle, uint24 _secondFee, address _target) public pure returns (bytes memory) {
        return abi.encodePacked(_source, _firstFee, _middle, _secondFee, _target);
    }
}