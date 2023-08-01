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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ISKAL is IERC20 {
    /* */

    function changeFarmAddress(address _address) external;

    function changeControlCenter(address _address) external;

    function changeTransferFeeExclusionStatus(
        address target,
        bool value
    ) external;

    function killswitch() external;

    function controlledMint(uint256 _amount) external;

    event SwapAndLiquify(
        uint256 sklPart,
        uint256 sklForEthPart,
        uint256 ethPart,
        uint256 liquidity
    );

    event TradingHalted(uint256 timestamp);
    event TradingResumed(uint256 timestamp);
    event TransferFeeExclusionStatusUpdated(address target, bool value);
    /* */
} 

interface IsSKAL is IERC20 {
    function enter(uint256 _amount) external;

    function leave(uint256 _amount) external;

    function enterFor(uint256 _amount, address _to) external;

    function killswitch() external;

    function setCompoundingEnabled(bool _enabled) external;

    function setMaxTxAndWalletBPS(uint256 _pid, uint256 bps) external;

    function rescueToken(address _token, uint256 _amount) external;

    function rescueETH(uint256 _amount) external;

    function excludeFromDividends(address account, bool excluded) external;

    function upgradeDividend(address payable newDividendTracker) external;

    function impactFeeStatus(bool _value) external;

    function setImpactFeeReceiver(address _feeReceiver) external;

    function SKLToSSKL(
        uint256 _sklAmount,
        bool _impactFeeOn
    )
        external
        view
        returns (uint256 sklAmount, uint256 swapFee, uint256 impactFee);

    function sSKLToSKL(
        uint256 _sSKLAmount,
        bool _impactFeeOn
    )
        external
        view
        returns (uint256 sklAmount, uint256 swapFee, uint256 impactFee);

    event TradingHalted(uint256 timestamp);
    event TradingResumed(uint256 timestamp);
}

interface ISKALReferral {
    /**
     * @dev Record referral.
     */
    function recordReferral(address user, address referrer) external;

    /**
     * @dev Record referral commission.
     */
    function recordReferralCommission(
        address referrer,
        uint256 commission
    ) external;

    /**
     * @dev Get the referrer address that referred the user.
     */
    function getReferrer(address user) external view returns (address);

    function getOutstandingCommission(
        address _referrer
    ) external view returns (uint256 amount);

    function debitOutstandingCommission(
        address _referrer,
        uint256 _debit
    ) external;

    function debitAndGetSSKL(address _referrer, uint256 _debit) external;

    function getTotalComission(
        address _referrer
    ) external view returns (uint256);

    function updateOperator(address _newPayer) external;

    function updateVesting(address _newVesting) external;
}

contract SkalableReferral is Ownable,ISKALReferral {
    mapping(address => address) public referrers; // referred address => referrer address
    mapping(address => uint256) public countReferrals; // referrer address => referrals count
    mapping(address => uint256) public totalReferralCommissions; // referrer address => total referral commissions
    mapping(address => uint256) public outstandingCommissions;
    // mapping(address => address[])public referrals; //referrer address => referred addresses
    address public sSKL;
    address public skl;
    event ReferralRecorded(address indexed user, address indexed referrer);
    event ReferralCommissionRecorded(
        address indexed referrer,
        uint256 commission
    );
    event OperatorUpdated(address indexed operator, bool indexed status);
    event BulkRecord(ReferralObject[] objectArray);
    struct ReferralObject {
        address referrer;
        address user;
    }
    address public payer;
    address public vestingContract;
    //added control center for updating payer address function, which wasnt present before, removes the need for Ownable contract
   

    constructor(address _sklToken, address _sSKLToken)Ownable() {
      
        sSKL = _sSKLToken;
        skl = _sklToken;
        IERC20(skl).approve(sSKL, type(uint256).max);
    }

    //this is the function that will be called from offchain, takes an object array {address,address} as parameter
    function bulkRecordReferralFromOffchain(
        ReferralObject[] memory _objectArray
    ) public {
        require(msg.sender == payer, "Only payer can record referrers");
        for (uint256 i = 0; i < _objectArray.length; i++) {
            optimizedRecord(_objectArray[i].user, _objectArray[i].referrer);
        }
        emit BulkRecord(_objectArray);
    }

    function optimizedRecord(address _user, address _referrer) private {
        if (referrers[_user] == address(0)) {
            referrers[_user] = _referrer;
            countReferrals[_referrer]++;
        }
    }

    function recordReferral(address _user, address _referrer) public override {
        require(msg.sender == payer, "Only payer can record referrers");
        if (referrers[_user] == address(0)) {
            referrers[_user] = _referrer;
            countReferrals[_referrer]++;
            emit ReferralRecorded(_user, _referrer);
        }
    }

    function recordReferralCommission(
        address _referrer,
        uint256 _commission
    ) public override {
        require(
            msg.sender == vestingContract,
            "SKalable:Only vesting contract(farm) can record commission"
        );
        totalReferralCommissions[_referrer] += _commission;
        outstandingCommissions[_referrer] += _commission;
        emit ReferralCommissionRecorded(_referrer, _commission);
    }

    function getOutstandingCommission(
        address _referrer
    ) public view override returns (uint256 amount) {
        amount = outstandingCommissions[_referrer];
    }

    function getTotalComission(
        address _referrer
    ) public view override returns (uint256) {
        return totalReferralCommissions[_referrer];
    }

    //this function was exclusive to payer, but I removed the requirement so the person who is owed the comission can also claim it for themselves
    //payment not yet implemented
    function debitOutstandingCommission(
        address _referrer,
        uint256 _debit
    ) external override {
        require(
            msg.sender == _referrer || msg.sender == payer,
            "SKalable:Only referrer and payer"
        );
        require(
            getOutstandingCommission(_referrer) >= _debit,
            "SKalable:Insufficent outstanding balance"
        );
        outstandingCommissions[_referrer] -= _debit;
        ISKAL(skl).controlledMint(_debit);
        IERC20(skl).transfer(_referrer, _debit);
        //MINT
    }

    function debitAllOutstandingComissions() external {
        address user = _msgSender();
        uint amountToClaim = getOutstandingCommission(user);
        if (amountToClaim > 0) {
            outstandingCommissions[user] -= amountToClaim;
            ISKAL(skl).controlledMint(amountToClaim);
            IERC20(skl).transfer(user, amountToClaim);
        }
    }

    function debitAndGetSSKL(
        address _referrer,
        uint256 _debit
    ) external override {
        require(
            msg.sender == _referrer || msg.sender == payer,
            "SKalable:Only referrer and payer"
        );
        require(
            getOutstandingCommission(_referrer) >= _debit,
            "SKalable:Insufficent outstanding balance"
        );
        outstandingCommissions[_referrer] -= _debit;
        ISKAL(skl).controlledMint(_debit);
        IsSKAL(sSKL).enterFor(_debit, _referrer);
    }

    function debitAllOutstandingComissionsAndGetsSKL() external {
        address user = _msgSender();
        uint amountToClaim = getOutstandingCommission(user);
        if (amountToClaim > 0) {
            outstandingCommissions[user] -= amountToClaim;
            ISKAL(skl).controlledMint(amountToClaim);
            IsSKAL(sSKL).enterFor(amountToClaim, user);
        }
    }

    function getTotalReferrals(
        address _referrer
    ) public view returns (uint256) {
        return countReferrals[_referrer];
    }

    // Get the referrer address that referred the user
    function getReferrer(address _user) public view override returns (address) {
        return referrers[_user];
    }

    //this is the wallet that will be used to sign the transaction needed to execute the recordReferral() functions
    function updateOperator(address _newPayer) external override onlyOwner{
     
        payer = _newPayer;
    }

    //this is the wallet that records all comissions
    function updateVesting(address _newVesting) external override onlyOwner{
    
        vestingContract = _newVesting;
    }
}