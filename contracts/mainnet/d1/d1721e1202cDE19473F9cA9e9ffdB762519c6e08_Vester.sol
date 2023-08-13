/**
 *Submitted for verification at Arbiscan on 2023-08-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

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

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

interface IHXTO {
    function mint(address to, uint256 amount) external;
    function burn(address from, uint256 amount) external;
    function transferFrom(address from, address to, uint256 amount) external;
    function transfer(address to, uint256 amount) external;
    function balanceOf(address account) external view returns(uint256);
}

contract Vester is Ownable {
    struct Vesting {
        uint256 payout; 
        uint256 vestingPeriod; 
        uint256 lastBlock;
    }

    mapping( address => Vesting ) public vestingInfo; 

    bool isActive = false;

    uint256 public defaultVestingPeriod = 90 days;

    IHXTO public immutable esHxto;
    IHXTO public immutable hxto;

    /// @notice Vesting HXTO amounts + Campaign reward pool HXTO amounts
    uint256 public totalReservedAmount;
    mapping(address => bool) public isActiveCampaign;

    // Precision
    uint256 public constant BASE_PRECISION = 10000;
    uint256 public VEST_BPS = 5000; 

    event SetVestingPeriod(uint256);
    event SetVestBasisPoints(uint256);
    event SetActiveCampaign(address, bool);
    event Vest(address, uint256);
    event Redeem(address, uint256);
    event Withdraw(address, uint256);

    constructor(IHXTO _esHxto, IHXTO _hxto){
        esHxto = _esHxto;
        hxto = _hxto;
    }

    function setVestingPeriod(uint256 _vestingPeriod) external onlyOwner {
        require(_vestingPeriod != 0, "Vester: Vesting duration can not be zero");

        defaultVestingPeriod = _vestingPeriod;

        emit SetVestingPeriod(_vestingPeriod);
    }

    function setVestBasisPoints(uint256 _bps) external onlyOwner {
        require(_bps != 0, "Vester: Basis point can not be zero");

        VEST_BPS = _bps;

        emit SetVestBasisPoints(_bps);
    }

    function setActiveCampaign(address _campaign, bool _isActive) external onlyOwner {
        require(_campaign != address(0), "Vester: Campaign can not be zero address");

        isActiveCampaign[_campaign] = _isActive;

        emit SetActiveCampaign(_campaign, _isActive);
    }

    function setIsActive(bool _isActive) external onlyOwner {
        isActive = _isActive;
    }

    // to help users who accidentally send their tokens to this contract
    function withdrawToken(address _token, address _account, uint256 _amount) external onlyOwner {
        IERC20(_token).transfer(_account, _amount);
    }

    function vest(uint256 amount) external {
        require(isActive, "Vester: Vester is not active");
        require(amount != 0, "Vester: Vesting amount can not be zero");

        uint256 hxtoAmount = amount * VEST_BPS / BASE_PRECISION;

        vestingInfo[ msg.sender ] = Vesting({ 
            payout: vestingInfo[ msg.sender ].payout + ( amount + hxtoAmount ),
            vestingPeriod: defaultVestingPeriod,
            lastBlock: block.timestamp
        });

        // esHXTO amounts + HXTO amounts will be reserved for redeem
        totalReservedAmount += (amount + hxtoAmount);

        esHxto.transferFrom(msg.sender, address(this), amount);
        hxto.transferFrom(msg.sender, address(this), hxtoAmount);

        esHxto.burn(address(this), amount);

        emit Vest(msg.sender, amount);
    }

    function redeem() external {
        Vesting memory userVestInfo = vestingInfo[msg.sender];

        uint percentVested = percentVestedFor(msg.sender); 

        if ( percentVested >= 10000 ) { 
            // fully vested
            delete vestingInfo[ msg.sender ];

            hxto.transfer( msg.sender, userVestInfo.payout );

            totalReservedAmount -= userVestInfo.payout;

            emit Redeem(msg.sender, userVestInfo.payout);
        } else { 
            // partially vested 
            uint256 payout = userVestInfo.payout * percentVested / 10000;
            
            vestingInfo[ msg.sender ] = Vesting({
                payout: userVestInfo.payout - payout,
                vestingPeriod: userVestInfo.vestingPeriod - (block.timestamp - userVestInfo.lastBlock),
                lastBlock: block.timestamp
            });

            hxto.transfer( msg.sender, payout );

            totalReservedAmount -= payout;

            emit Redeem(msg.sender, payout);
        }
    }

    ///  @notice calculate how far into vesting a depositor is
    ///  @param _depositor address
    ///  @return percentVested_ uint
    function percentVestedFor( address _depositor ) public view returns ( uint percentVested_ ) {
        Vesting memory userVestInfo = vestingInfo[ _depositor ];

        uint blocksSinceLast = block.timestamp - userVestInfo.lastBlock;

        uint vesting = userVestInfo.vestingPeriod;

        if ( vesting > 0 ) {
            percentVested_ = blocksSinceLast * 10000 / vesting;
        } else {
            percentVested_ = 0;
        }
    }

    /// @notice calculate amount of payout token available for claim by account
    /// @param account address
    /// @return pendingPayout_ uint 
    function claimable(address account) external view returns (uint256){
        Vesting memory userVestInfo = vestingInfo[account];

        uint percentVested = percentVestedFor(account); 

        if ( percentVested >= 10000 ) { 
            return userVestInfo.payout;
        } else { 
            return userVestInfo.payout * percentVested / 10000;
        }
    }

    function withdraw(uint256 amount) external {
        require(isActiveCampaign[msg.sender], "Vester: Sender must be active campaign");

        uint256 hxtoBalance = hxto.balanceOf(address(this));

        require((hxtoBalance - amount) >= totalReservedAmount, "Vester: Insufficient reserve");

        hxto.transfer(msg.sender, amount);

        emit Withdraw(msg.sender, amount);
    }
}