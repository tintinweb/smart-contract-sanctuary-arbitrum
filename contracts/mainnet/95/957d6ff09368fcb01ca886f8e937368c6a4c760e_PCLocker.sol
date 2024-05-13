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
pragma solidity =0.8.8;

interface IProfile {
    struct SProfile{
        address sponsor;
        uint sPercent;
        uint nextSPercent;
        uint updatedAt;
        uint ifs;
        uint bonusBooster;
    }

    function updateSponsor(
        address account_,
        address sponsor_
    )
        external;

    function profileOf(
        address account_
    )
        external
        view
        returns(SProfile memory);

    function getSponsorPart(
        address account_,
        uint amount_
    )
        external
        view
        returns(address sponsor, uint sAmount);

    function setSPercent(
        uint sPercent_
    )
        external;

    function setDefaultSPercentConfig(
        uint sPercent_
    )
        external;

    function setMinSPercentConfig(
        uint sPercent_
    )
        external;

    function updateFsOf(
        address account_,
        uint fs_
    )
        external;

    function updateBoosterOf(
        address account_,
        uint booster_
    )
        external;

    function fsOf(
        address account_
    )
        external
        view
        returns(uint);

    function boosterOf(
        address account_
    )
        external
        view
        returns(uint);
}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.8;

import "./LPercentage.sol";

library LLocker {
    struct SLock {
        uint startedAt;
        uint amount;
        uint duration;
    }

    function getLockId(
        address account_,
        address poolOwner_
    )
        internal
        pure
        returns(bytes32)
    {
        return keccak256(abi.encode(account_, poolOwner_));
    }

    function restDuration(
        SLock memory lockData_
    )
        internal
        view
        returns(uint)
    {
        if (lockData_.startedAt > block.timestamp) {
            return lockData_.duration + lockData_.startedAt - block.timestamp;
        }
        uint pastTime = block.timestamp - lockData_.startedAt;
        if (pastTime < lockData_.duration) {
            return lockData_.duration - pastTime;
        } else {
            return 0;
        }
    }

    function prolong(
        SLock storage lockData_,
        uint amount_,
        uint duration_
    )
        internal
    {
        if (lockData_.amount == 0) {
            require(amount_ > 0 && duration_ > 0, "amount_ = 0 or duration_ = 0");
        } else {
            require(amount_ > 0 || duration_ > 0, "amount_ = 0 and duration_ = 0");
        }

        lockData_.amount += amount_;

        uint rd = restDuration(lockData_);
        if (rd == 0) {
            lockData_.duration = duration_;
            lockData_.startedAt = block.timestamp;
            return;
        }

        lockData_.duration += duration_;
    }

    function isUnlocked(
        SLock memory lockData_,
        uint fs_,
        bool isPoolOwner_
    )
        internal
        view
        returns(bool)
    {
        uint mFactor = isPoolOwner_ ? 2 * LPercentage.DEMI - fs_ : fs_;
        uint duration = lockData_.duration * mFactor / LPercentage.DEMI;
        uint elapsedTime = block.timestamp - lockData_.startedAt;
        return elapsedTime >= duration;
    }

    function calDuration(
        SLock memory lockData_,
        uint fs_,
        bool isPoolOwner_
    )
        internal
        pure
        returns(uint)
    {
        uint mFactor = isPoolOwner_ ? 2 * LPercentage.DEMI - fs_ : fs_;
        uint duration = lockData_.duration * mFactor / LPercentage.DEMI;
        return duration;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.8;

library LPercentage {
    uint constant public DEMI = 10000;
    uint constant public DEMIE2 = DEMI * DEMI;
    uint constant public DEMIE3 = DEMIE2 * DEMI;

    function validatePercent(
        uint percent_
    )
        internal
        pure
    {
        // 100% == DEMI == 10000
        require(percent_ <= DEMI, "invalid percent");
    }

    function getPercentA(
        uint value,
        uint percent
    )
        internal
        pure
        returns(uint)
    {
        return value * percent / DEMI;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.8;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Cashier {
    event SetCleanTo(
        address indexed cleanTo
    );

    event Clean(
        uint amount
    );

    uint private _lastestBalance;

    IERC20 private _token;

    address private _cleanTo;

    bool private _isCleanEnabled;

    function _initCashier(
        address token_,
        address cleanTo_
    )
        internal
    {
        _token = IERC20(token_);
        _setCleanTo(cleanTo_);
    }

    function _setCleanTo(
        address cleanTo_
    )
        internal
    {
        _cleanTo = cleanTo_;
        _isCleanEnabled = cleanTo_ != address(this);
        emit SetCleanTo(cleanTo_);
    }

    function _updateBalance()
        internal
    {
        _lastestBalance = _token.balanceOf(address(this));
    }

    function _cashIn()
        internal
        returns(uint)
    {
        uint incBalance = currentBalance() - _lastestBalance;
        _updateBalance();
        return incBalance;
    }

    function _cashOut(
        address to_,
        uint amount_
    )
        internal
    {
        try _token.transfer(to_, amount_) returns (bool success) {
        } catch {
        }
        _updateBalance();
    }

    // todo
    // check all clean calls logic
    // lockers
    // earnings
    // voting
    // distributors
    // vester
    /*
        cleanTo

        eLocker : eP2pDistributor
        dLocker : 0xDEAD

        eEarning : eP2pDistributor
        dEarning : 0xDEAD

        eVoting : eP2pDistributor
        dVoting : 0xDEAD

        distributors: revert all

        eVester : eP2pDistributor
        dVester : 0xDEAD

    */

    function clean()
        public
        virtual
    {
        require(_isCleanEnabled, "unable to clean");
        uint currentBal = currentBalance();
        if (currentBal > _lastestBalance) {
            uint amount = currentBal - _lastestBalance;
            _token.transfer(_cleanTo, amount);
            emit Clean(amount);
        }
        _updateBalance();
    }

    function cleanTo()
        external
        view
        returns(address)
    {
        return _cleanTo;
    }

    function currentBalance()
        public
        view
        returns(uint)
    {
        return _token.balanceOf(address(this));
    }

    function lastestBalance()
        public
        view
        returns(uint)
    {
        return _lastestBalance;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.8;
pragma abicoder v2;

contract Initializable {
  bool private _isNotInitializable;
  address private _deployerOrigin;

  constructor()
  {
    _deployerOrigin = tx.origin;
  }

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(!_isNotInitializable, "isNotInitializable");
    require(tx.origin == _deployerOrigin || _deployerOrigin == address(0x0), "initializer access denied");
    _;
    _isNotInitializable = true;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.8;

interface IAccessControl {
    function addAdmins(
        address[] memory accounts_
    )
        external;

    function removeAdmins(
        address[] memory accounts_
    )
        external;

    /*
        view
    */

    function isOwner(
        address account_
    )
        external
        returns(bool);

    function isAdmin(
        address account_
    )
        external
        view
        returns(bool);
}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.8;
pragma abicoder v2;

import "./Cashier.sol";

import "../lib/LLocker.sol";
import "../interfaces/IProfile.sol";

import "./UseAccessControl.sol";

contract Locker is Cashier, UseAccessControl {
    using LLocker for *;

    event UpdateLockData(
        address indexed account,
        address indexed poolOwner,
        LLocker.SLock lockData
    );

    event Withdraw(
        address indexed account,
        address indexed poolOwner,
        address dest,
        uint amount
    );

    event SelfWithdrawn(
        address indexed account
    );

    event UpdatePenaltyAddress(
        address penaltyAddress
    );

    mapping(bytes32 => LLocker.SLock) internal _lockData;
    IProfile private _profileC;

    address private _penaltyAddress;

    function initLocker(
        address accessControl_,
        address token_,
        address profileCAddr_,
        address penaltyAddress_,
        address cleanTo_
    )
        public
        initializer
    {
        _initCashier(token_, cleanTo_);
        initUseAccessControl(accessControl_);
        _profileC = IProfile(profileCAddr_);

        _updatePenaltyAddress(penaltyAddress_);
    }

    function lock(
        address account_,
        address poolOwner_,
        uint duration_
    )
        external
        onlyAdmin
    {
        bytes32 lockId = LLocker.getLockId(account_, poolOwner_);
        uint amount = _cashIn();
        LLocker.prolong(_lockData[lockId], amount, duration_);
        emit UpdateLockData(account_, poolOwner_, _lockData[lockId]);
    }

    // default by admin (controller)
    function withdraw(
        address account_,
        address poolOwner_,
        address dest_,
        uint amount_,
        bool isForced_
    )
        external
        onlyApprovedAdmin(account_)
    {
        _withdraw(account_, poolOwner_, dest_, amount_, isForced_);
    }

    function _withdraw(
        address account_,
        address poolOwner_,
        address dest_,
        uint amount_,
        bool isForced_
    )
        internal
    {
        bytes32 lockId = LLocker.getLockId(account_, poolOwner_);
        LLocker.SLock storage lockData = _lockData[lockId];
        bool isPoolOwner = account_ == poolOwner_;
        uint fs = _profileC.fsOf(poolOwner_);
        if (!isForced_) {
            require(LLocker.isUnlocked(lockData, fs, isPoolOwner), "not unlocked");
        }
        uint duration = LLocker.calDuration(lockData, fs, isPoolOwner);
        uint pastTime = block.timestamp - lockData.startedAt;
        if (pastTime > duration) {
            pastTime = duration;
        }

        lockData.amount -= amount_;
        if (lockData.amount == 0) {
            lockData.duration = 0;
            lockData.startedAt = block.timestamp;
        }
        uint total = amount_;
        uint receivedA = duration == 0 ? total : total * pastTime / duration;
        _cashOut(dest_, receivedA);
        if (total != receivedA) {
            _cashOut(_penaltyAddress, total - receivedA);
        }

        emit Withdraw(account_, poolOwner_, dest_, amount_);
        emit UpdateLockData(account_, poolOwner_, _lockData[lockId]);
    }

    function _updatePenaltyAddress(
        address penaltyAddress_
    )
        internal
    {
        _penaltyAddress = penaltyAddress_;
        emit UpdatePenaltyAddress(penaltyAddress_);
    }

    function updatePenaltyAddress(
        address penaltyAddress_
    )
        external
        onlyOwner
    {
        _updatePenaltyAddress(penaltyAddress_);
    }

    function penaltyAddress()
        external
        view
        returns(address)
    {
        return _penaltyAddress;
    }

    function getLockId(
        address account_,
        address poolOwner_
    )
        external
        pure
        returns(bytes32)
    {
        return LLocker.getLockId(account_, poolOwner_);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.8;
pragma abicoder v2;

import "./Locker.sol";

contract PCLocker is Locker {
    mapping(bytes32 => uint) private _mintedPower;
    function incMintedPower(
        address account_,
        address poolOwner_,
        uint amount_
    )
        external
        onlyAdmin
    {
        bytes32 lockId = LLocker.getLockId(account_, poolOwner_);
        _mintedPower[lockId] += amount_;
    }

    function decMintedPower(
        address account_,
        address poolOwner_,
        uint amount_
    )
        external
        onlyAdmin
    {
        bytes32 lockId = LLocker.getLockId(account_, poolOwner_);
        _mintedPower[lockId] -= amount_;
    }    

    function getLockDataById(
        bytes32 lockId_
    )
        external
        view
        returns(LLocker.SLock memory)
    {
        return _lockData[lockId_];
    }

    function getLockData(
        address account_,
        address poolOwner_
    )
        external
        view
        returns(LLocker.SLock memory)
    {
        bytes32 lockId = LLocker.getLockId(account_, poolOwner_);
        return _lockData[lockId];
    }

    function getMintedPower(
        address account_,
        address poolOwner_
    )
        external
        view
        returns(uint)
    {
        bytes32 lockId = LLocker.getLockId(account_, poolOwner_);
        return _mintedPower[lockId];
    }    
}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.8;
pragma abicoder v2;

import "./Initializable.sol";

import "./interfaces/IAccessControl.sol";


// interface IBlast {
//   // Note: the full interface for IBlast can be found below
//   function configureClaimableGas() external;
//   function configureGovernor(address governor) external;
// }
// interface IBlastPoints {
//   function configurePointsOperator(address operator) external;
// }

// // https://docs.blast.io/building/guides/gas-fees
// // added constant: BLAST_GOV
// contract BlastClaimableGas {
//   IBlast public constant BLAST = IBlast(0x4300000000000000000000000000000000000002);
//   // todo
//   // replace gov address
//   address constant private BLAST_GOV = address(0x6d9cD20Ba0Dc1CCE0C645a6b5759f5ad1bD2704F);

//   function initClaimableGas() internal {
//     BLAST.configureClaimableGas();
//     // This sets the contract's governor. This call must come last because after
//     // the governor is set, this contract will lose the ability to configure itself.
//     BLAST.configureGovernor(BLAST_GOV);
//     IBlastPoints(0x2536FE9ab3F511540F2f9e2eC2A805005C3Dd800).configurePointsOperator(0x6d9cD20Ba0Dc1CCE0C645a6b5759f5ad1bD2704F);
//   }
// }

// contract UseAccessControl is Initializable, BlastClaimableGas {
contract UseAccessControl is Initializable {
    event ApproveAdmin(
        address indexed account,
        address indexed admin
    );

    event RevokeAdmin(
        address indexed account,
        address indexed admin
    );

    modifier onlyOwner() {
        require(_accessControl.isOwner(msg.sender), "onlyOwner");
        _;
    }

    modifier onlyAdmin() {
        require(_accessControl.isAdmin(msg.sender), "onlyAdmin");
        _;
    }

    modifier onlyApprovedAdmin(
        address account_
    )
    {
        address admin = msg.sender;
        require(_accessControl.isAdmin(admin), "onlyAdmin");
        require(_isApprovedAdmin[account_][admin], "onlyApprovedAdmin");
        _;
    }

    IAccessControl internal _accessControl;

    mapping(address => mapping(address => bool)) private _isApprovedAdmin;

    function initUseAccessControl(
        address accessControl_
    )
        public
        initializer
    {
        _accessControl = IAccessControl(accessControl_);
        // initClaimableGas();
    }

    function approveAdmin(
        address admin_
    )
        external
    {
        address account = msg.sender;
        require(_accessControl.isAdmin(admin_), "onlyAdmin");
        require(!_isApprovedAdmin[account][admin_], "onlyNotApprovedAdmin");
        _isApprovedAdmin[account][admin_] = true;
        emit ApproveAdmin(account, admin_);
    }

    function revokeAdmin(
        address admin_
    )
        external
    {
        address account = msg.sender;
        // require(_accessControl.isAdmin(admin_), "onlyAdmin");
        require(_isApprovedAdmin[account][admin_], "onlyApprovedAdmin");
        _isApprovedAdmin[account][admin_] = false;
        emit RevokeAdmin(account, admin_);
    }

    function isApprovedAdmin(
        address account_,
        address admin_
    )
        external
        view
        returns(bool)
    {
        return _isApprovedAdmin[account_][admin_];
    }
}