// SPDX-License-Identifier: PolyForm-Noncommercial-1.0.0
pragma solidity 0.8.17;

import "../interface/IIdentity.sol";
import "../interface/ILockManager.sol";
import "../utils/SafeCast.sol";

contract LockManager is ILockManager {
    using SafeCast for uint256;

    uint256 internal immutable _lockPeriod;

    struct Lock {
        address locker;
        uint64 expireAt;
    }

    mapping(address => Lock) internal _locks;

    modifier onlyModule(address identity) {
        require(
            IIdentity(identity).isModuleEnabled(msg.sender),
            "LM: caller must be an enabled module"
        );
        _;
    }

    modifier onlyLocker(address identity) {
        require(
            msg.sender == _locks[identity].locker,
            "LM: caller must be the locker"
        );
        _;
    }

    modifier onlyWhenIdentityLocked(address identity) {
        require(_isIdentityLocked(identity), "LM: identity must be locked");
        _;
    }

    modifier onlyWhenIdentityUnlocked(address identity) {
        require(!_isIdentityLocked(identity), "LM: identity must be unlocked");
        _;
    }

    constructor(uint256 lockPeriod) {
        _lockPeriod = lockPeriod;
    }

    function isIdentityLocked(address identity)
        external
        view
        override
        returns (bool)
    {
        return _isIdentityLocked(identity);
    }

    function getIdentityLockExpireAt(address identity)
        external
        view
        override
        returns (uint64)
    {
        return _locks[identity].expireAt;
    }

    function lockIdentity(address identity)
        external
        override
        onlyModule(identity)
        onlyWhenIdentityUnlocked(identity)
    {
        uint64 expireAt = (block.timestamp + _lockPeriod).toUint64();

        _setLock(identity, msg.sender, expireAt);

        emit IdentityLocked(identity, msg.sender, expireAt);
    }

    function unlockIdentity(address identity)
        external
        override
        onlyModule(identity)
        onlyLocker(identity)
        onlyWhenIdentityLocked(identity)
    {
        _setLock(identity, address(0), 0);

        emit IdentityUnlocked(identity);
    }

    function _isIdentityLocked(address identity) internal view returns (bool) {
        return block.timestamp.toUint64() < _locks[identity].expireAt;
    }

    function _setLock(
        address identity,
        address locker,
        uint64 expireAt
    ) internal {
        _locks[identity] = Lock(locker, expireAt);
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.17;

interface IIdentity {
    event OwnershipTransferred(
        address indexed oldOwner,
        address indexed newOwner
    );

    event ModuleManagerSwitched(
        address indexed oldModuleManager,
        address indexed newModuleManager
    );

    event Executed(
        address indexed module,
        address indexed to,
        uint256 value,
        bytes data
    );

    function owner() external view returns (address);

    function setOwner(address newOwner) external;

    function moduleManager() external view returns (address);

    function setModuleManager(address newModuleManager) external;

    function isModuleEnabled(address module) external view returns (bool);

    function getDelegate(bytes4 methodID) external view returns (address);

    function execute(
        address to,
        uint256 value,
        bytes calldata data
    ) external returns (bytes memory);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.17;

interface ILockManager {
    event IdentityLocked(
        address indexed identity,
        address indexed locker,
        uint64 expireAt
    );

    event IdentityUnlocked(address indexed identity);

    function isIdentityLocked(address identity) external view returns (bool);

    function getIdentityLockExpireAt(address identity)
        external
        view
        returns (uint64);

    function lockIdentity(address identity) external;

    function unlockIdentity(address identity) external;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.17;

library SafeCast {
    function toUint128(uint256 v) internal pure returns (uint128) {
        require(v <= type(uint128).max, "SC: v must fit in 128 bits");

        return uint128(v);
    }

    function toUint64(uint256 v) internal pure returns (uint64) {
        require(v <= type(uint64).max, "SC: v must fit in 64 bits");

        return uint64(v);
    }
}