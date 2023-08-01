/**
 *Submitted for verification at Arbiscan on 2023-07-26
*/

// SPDX-License-Identifier: GPL-2.0-or-later 

pragma solidity ^0.8.9;


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)
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

// https://docs.synthetix.io/contracts/Owned
contract Owned {
    address public owner;
    address public nominatedOwner;

    constructor (address _owner) {
        require(_owner != address(0), "Owner address cannot be 0");
        owner = _owner;
        emit OwnerChanged(address(0), _owner);
    }

    function nominateNewOwner(address _owner) external onlyOwner {
        nominatedOwner = _owner;
        emit OwnerNominated(_owner);
    }

    function acceptOwnership() external {
        require(msg.sender == nominatedOwner, "You must be nominated before you can accept ownership");
        emit OwnerChanged(owner, nominatedOwner);
        owner = nominatedOwner;
        nominatedOwner = address(0);
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Only the contract owner may perform this action");
        _;
    }

    event OwnerNominated(address newOwner);
    event OwnerChanged(address oldOwner, address newOwner);
}

contract Distributor is Owned {
    
    address public token;
    address public vault;
    uint256 public rate;
    uint256 public lastUpdateTime;
    uint256 public pendingRate;
    uint256 public timelock;

    event Distributed(address indexed caller, uint256 amount);
    event RateUpdated(uint256 newRate);

    constructor(address owner_, address token_, address vault_, uint256 startTime, uint256 initialRate) Owned(owner_) {
        token = token_;
        vault = vault_;
        lastUpdateTime = startTime;
        rate = initialRate;
    }

    function distribute() public { 
        require(block.timestamp > lastUpdateTime);
        uint256 delta = block.timestamp - lastUpdateTime;
        uint256 amount = rate * delta;
        lastUpdateTime = block.timestamp;
        safeDistribute(vault, amount);
    }

    function setRate(uint256 _rate) external onlyOwner {
        distribute();
        rate = _rate;
        emit RateUpdated(_rate);
    }

    function safeDistribute(address _to, uint256 _amount) internal {
        uint256 rewardsBal = IERC20(token).balanceOf(address(this));
        if (_amount > rewardsBal) {
            IERC20(token).transfer(_to, rewardsBal);
            emit Distributed(msg.sender, rewardsBal);
        } else {
            IERC20(token).transfer(_to, _amount);
            emit Distributed(msg.sender, _amount);
        }
    }
}