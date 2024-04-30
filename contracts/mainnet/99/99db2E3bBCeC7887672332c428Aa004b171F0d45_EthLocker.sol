// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import './IAssetLocker.sol';
import 'contracts/fee/IFeeSettings.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

/// @title used to block asset for any time
abstract contract AssetLockerBase is IAssetLocker, ReentrancyGuard {
    /// @notice total created positions count
    uint256 _positionsCount;
    /// @notice tax system contract
    IFeeSettings immutable _feeSettings;

    /// @notice constructor
    /// @param feeSettingsAddress tax system contract
    constructor(address feeSettingsAddress) {
        _feeSettings = IFeeSettings(feeSettingsAddress);
    }

    /// @notice allows only existing positions
    modifier OnlyExistingPosition(uint256 positionId) {
        require(_positionExists(positionId), 'position is not exists');
        _;
    }

    /// @notice total created positions count
    function positionsCount() external view returns (uint256) {
        return _positionsCount;
    }

    /// @notice returns tax system contract address
    function feeSettings() external view returns (address) {
        return address(_feeSettings);
    }

    /// @notice returns true, if position is locked
    /// @param id id of position
    /// @return bool true if locked
    function isLocked(uint256 id) external view returns (bool) {
        return _isLocked(id);
    }

    function _isLocked(uint256 id) internal view virtual returns (bool) {
        uint256 time = this.unlockTime(id);
        return time == 0 || time > block.timestamp;
    }

    /// @notice returns true if asset locked permanently
    /// @param id id of  position
    function isPermanentLock(uint256 id) external view returns (bool) {
        return this.unlockTime(id) == 0;
    }

    /// @notice withdraws the position
    /// @param id id of position
    function withdraw(uint256 id) external nonReentrant {
        require(!this.withdrawed(id), 'already withdrawed');
        require(!this.isPermanentLock(id), 'locked permanently');
        require(!this.isLocked(id), 'still locked');
        require(this.withdrawer(id) == msg.sender, 'only for withdrawer');
        _withdraw(id);
        _setWithdrawed(id);
        emit OnWithdraw(id);
    }

    /// @dev internal withdraw algorithm, asset speciffic
    /// @param id id of position
    function _withdraw(uint256 id) internal virtual;

    /// @dev internal sets position as withdrawed to prevent re-withdrawal
    /// @param id id of position
    function _setWithdrawed(uint256 id) internal virtual;

    /// @dev returns new position ID
    function _newPositionId() internal returns (uint256) {
        return ++_positionsCount;
    }

    /// @dev returns true, if position is exists
    function _positionExists(uint256 positionId) internal view returns (bool) {
        return positionId > 0 && positionId <= _positionsCount;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

/// @title ethereum lock data
struct EthLockData {
    /// @notice the address with withdraw right for position
    address withdrawer;
    /// @notice position unlock pime
    uint256 unlockTime;
    /// @notice if true, than position is withdrawed
    bool withdrawed;
    /// @notice count of ethereum, without decimals, that can be withdrawed
    uint256 count;
    /// @notice paid locking fee
    /// @dev all fee calculations is for withdrawer
    uint256 fee;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import '../AssetLockerBase.sol';
import './IEthLocker.sol';

contract EthLocker is AssetLockerBase, IEthLocker {
    mapping(uint256 => EthLockData) _positions;

    constructor(
        address feeSettingsAddress
    ) AssetLockerBase(feeSettingsAddress) {}

    function position(
        uint256 id
    ) external view OnlyExistingPosition(id) returns (EthLockData memory) {
        return _positions[id];
    }

    function withdrawer(
        uint256 id
    ) external view OnlyExistingPosition(id) returns (address) {
        return _positions[id].withdrawer;
    }

    function unlockTime(
        uint256 id
    ) external view OnlyExistingPosition(id) returns (uint256) {
        return _positions[id].unlockTime;
    }

    function withdrawed(
        uint256 id
    ) external view OnlyExistingPosition(id) returns (bool) {
        return _positions[id].withdrawed;
    }

    function _setWithdrawed(uint256 id) internal override {
        _positions[id].withdrawed = true;
    }

    function lockTimeFor(
        uint256 unlockTime_,
        address withdrawer_
    ) external payable {
        _lock(unlockTime_, withdrawer_);
    }

    function lockTime(uint256 unlockTime_) external payable {
        _lock(unlockTime_, msg.sender);
    }

    function lockSecondsFor(
        uint256 seconds_,
        address withdrawer_
    ) external payable {
        _lock(block.timestamp + seconds_, withdrawer_);
    }

    function lockSeconds(uint256 seconds_) external payable {
        _lock(block.timestamp + seconds_, msg.sender);
    }

    function _lock(uint256 unlockTime_, address withdrawer_) private {
        require(unlockTime_ > 0, 'time can not be 0');
        require(withdrawer_ != address(0), 'withdrawer can not be 0');
        require(msg.value > 0, 'nothing to lock');
        uint256 id = _newPositionId();
        EthLockData storage data = _positions[id];
        data.unlockTime = unlockTime_;
        data.withdrawer = withdrawer_;
        data.fee = _feeSettings.feeForCount(withdrawer_, msg.value);

        // fee transfer
        if (data.fee > 0) {
            (bool sentCount, ) = _feeSettings.feeAddress().call{
                value: data.fee
            }('');
            require(sentCount, 'ethereum is not sent');
        }

        data.count = msg.value - data.fee;
        emit OnLockPosition(id);
    }

    function _withdraw(uint256 id) internal override {
        EthLockData memory data = _positions[id];
        (bool sentCount, ) = msg.sender.call{ value: data.count }('');
        require(sentCount, 'ethereum is not sent');
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import '../IAssetLocker.sol';
import './EthLockData.sol';

/// @title eth locker algorithm
interface IEthLocker is IAssetLocker {
    /// @notice returns the locked position data
    /// @param id id of position
    /// @return EthLockData the locked position data
    function position(uint256 id) external view returns (EthLockData memory);

    /// @notice locks the ethereum, that can be withdrawed by certait address
    /// @param unlockTime unlock time
    /// @param withdrawer the address with withdraw right for position
    function lockTimeFor(
        uint256 unlockTime,
        address withdrawer
    ) external payable;

    /// @notice locks the ethereum, that can be withdraw by caller address
    /// @param unlockTime unlock time or 0 if permanent lock
    function lockTime(uint256 unlockTime) external payable;

    /// @notice locks the ethereum, that can be withdrawed by certait address
    /// @param seconds_ lock seconds
    /// @param withdrawer the address with withdraw right for position
    function lockSecondsFor(
        uint256 seconds_,
        address withdrawer
    ) external payable;

    /// @notice locks the ethereum, that can be withdrawed
    /// @param seconds_ lock seconds
    function lockSeconds(uint256 seconds_) external payable;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

/// @title used to block asset for any time
interface IAssetLocker {
    /// @notice new position locked
    /// @param id id of new locked position
    event OnLockPosition(uint256 id);
    /// @notice position withdrawed
    /// @param id id of new locked position
    event OnWithdraw(uint256 id);

    /// @notice total created positions count
    function positionsCount() external view returns (uint256);

    /// @notice returns tax system contract address
    function feeSettings() external view returns (address);

    /// @notice the address with withdraw right for position
    /// @param id id of position
    /// @return address the address with withdraw right for position
    function withdrawer(uint256 id) external view returns (address);

    /// @notice time when the position will be unlocked (only full unlock)
    /// @param id id of position
    /// @return uint256 linux epoh time, when unlock or 0 if lock permanently
    function unlockTime(uint256 id) external view returns (uint256);

    /// @notice  returns true, if position is locked
    /// @param id id of position
    /// @return bool true if locked
    function isLocked(uint256 id) external view returns (bool);

    /// @notice if true than position is already withdrawed
    /// @param id id of position
    /// @return bool true if position is withdrawed
    function withdrawed(uint256 id) external view returns (bool);

    /// @notice withdraws the position
    /// @param id id of position
    function withdraw(uint256 id) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

/// @title the fee settings of GigaSwap system interface
interface IFeeSettings {
    /// @notice address to pay fee
    function feeAddress() external view returns (address);

    /// @notice fee in 1/decimals for dividing values
    function feePercent() external view returns (uint256);

    /// @notice account fee share
    /// @dev used only if asset is dividing
    /// @dev fee in 1/feeDecimals for dividing values
    /// @param account the account, that can be hold GigaSwap token
    /// @return uint256 asset fee share in 1/feeDecimals
    function feePercentFor(address account) external view returns (uint256);

    /// @notice account fee for certain asset count
    /// @dev used only if asset is dividing
    /// @param account the account, that can be hold GigaSwap token
    /// @param count asset count for calculate fee
    /// @return uint256 asset fee count
    function feeForCount(
        address account,
        uint256 count
    ) external view returns (uint256);

    /// @notice decimals for fee shares
    function feeDecimals() external view returns (uint256);

    /// @notice fix fee value
    /// @dev used only if asset is not dividing
    function feeEth() external view returns (uint256);

    /// @notice fee in 1/decimals for dividing values
    function feeEthFor(address account) external view returns (uint256);

    /// @notice if account balance is greather than or equal this value, than this account has no fee
    function zeroFeeShare() external view returns (uint256);
}