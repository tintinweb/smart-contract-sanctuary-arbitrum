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

// SPDX-License-Identifier: PolyForm-Noncommercial-1.0.0
pragma solidity 0.8.17;

import "./BaseModule.sol";
import "../../interface/IIdentity.sol";
import "../../utils/ECDSA.sol";
import "../../utils/Math.sol";

contract ArbRelayerModule is BaseModule {
    using ECDSA for bytes32;

    mapping(address => uint256) internal _nonces;

    event Executed(
        address indexed identity,
        bool indexed success,
        bytes result,
        bytes32 txHash
    );

    event Refunded(
        address indexed identity,
        address indexed receiver,
        address token,
        uint256 amount
    );

    constructor(address lockManager) BaseModule(lockManager) {}

    function getNonce(address identity) external view returns (uint256) {
        return _nonces[identity];
    }

    function execute(
        address identity,
        bytes calldata data,
        uint256 gasPrice,
        uint256 gasLimit,
        address refundTo,
        bytes calldata sig
    ) external returns (bool) {
        bytes32 txHash = _getTxHash(
            identity,
            data,
            gasPrice,
            gasLimit,
            address(0),
            refundTo
        );

        address signer = txHash.toEthSignedMessageHash().recover(sig);

        require(signer == IIdentity(identity).owner(), "ARM: invalid signer");

        _nonces[identity]++;

        (bool success, bytes memory result) = address(this).call(data);

        emit Executed(identity, success, result, txHash);

        if (gasPrice > 0) {
            _refund(identity, refundTo, gasPrice, gasLimit, address(0));
        }

        return success;
    }

    function executeThroughIdentity(
        address identity,
        address to,
        uint256 value,
        bytes memory data
    )
        external
        onlySelf
        onlyWhenIdentityUnlocked(identity)
        returns (bytes memory)
    {
        return _executeThroughIdentity(identity, to, value, data);
    }

    function _getTxHash(
        address identity,
        bytes memory data,
        uint256 gasPrice,
        uint256 gasLimit,
        address gasToken,
        address refundTo
    ) internal view returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    bytes1(0x19),
                    bytes1(0x0),
                    block.chainid,
                    address(this),
                    address(identity),
                    _nonces[identity],
                    data,
                    gasPrice,
                    gasLimit,
                    gasToken,
                    refundTo
                )
            );
    }

    function _refund(
        address identity,
        address to,
        uint256 gasPrice,
        uint256 gasLimit,
        address gasToken
    ) internal {
        require(
            gasToken == address(0),
            "ARM: gas token must be the zero address"
        );

        to = to == address(0) ? msg.sender : to;

        uint256 refundAmount = gasLimit * gasPrice;

        _executeThroughIdentity(identity, to, refundAmount, "");

        emit Refunded(identity, to, gasToken, refundAmount);
    }

    function _executeThroughIdentity(
        address identity,
        address to,
        uint256 value,
        bytes memory data
    ) internal returns (bytes memory) {
        return IIdentity(identity).execute(to, value, data);
    }
}

// SPDX-License-Identifier: PolyForm-Noncommercial-1.0.0
pragma solidity 0.8.17;

import "../../interface/ILockManager.sol";
import "../../utils/Address.sol";

contract BaseModule {
    using Address for address;

    ILockManager internal immutable _lockManager;

    constructor(address lockManager) {
        require(
            lockManager.isContract(),
            "BM: lock manager must be an existing contract address"
        );

        _lockManager = ILockManager(lockManager);
    }

    modifier onlySelf() {
        require(_isSelf(msg.sender), "BM: caller must be myself");
        _;
    }

    modifier onlyWhenIdentityUnlocked(address identity) {
        require(!_isIdentityLocked(identity), "BM: identity must be unlocked");
        _;
    }

    function _isSelf(address addr) internal view returns (bool) {
        return addr == address(this);
    }

    function _isIdentityLocked(address identity) internal view returns (bool) {
        return _lockManager.isIdentityLocked(identity);
    }

    function ping() external view onlySelf {}
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.17;

library Address {
    function isContract(address addr) internal view returns (bool) {
        uint256 size;

        assembly {
            size := extcodesize(addr)
        }

        return size > 0;
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.17;

library ECDSA {
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        // ref. https://ethereum.github.io/yellowpaper/paper.pdf (301) (302)
        require(
            uint256(s) <=
                0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0,
            "ECDSA: invalid s value in signature"
        );
        require(v == 27 || v == 28, "ECDSA: invalid v value in signature");

        address signer = ecrecover(hash, v, r, s);

        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }

    function recover(bytes32 hash, bytes memory sig)
        internal
        pure
        returns (address)
    {
        require(sig.length == 65, "ECDSA: invalid signature length");

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            r := mload(add(sig, 0x20))
            s := mload(add(sig, 0x40))
            v := byte(0, mload(add(sig, 0x60)))
        }

        return recover(hash, v, r, s);
    }

    function recover(
        bytes32 hash,
        bytes memory sig,
        uint256 index
    ) internal pure returns (address) {
        require(sig.length % 65 == 0, "ECDSA: invalid signature length");
        require(index < sig.length / 65, "ECDSA: invalid signature index");

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            r := mload(add(add(sig, 0x20), mul(0x41, index)))
            s := mload(add(add(sig, 0x40), mul(0x41, index)))
            v := byte(0, mload(add(add(sig, 0x60), mul(0x41, index))))
        }

        return recover(hash, v, r, s);
    }

    function toEthSignedMessageHash(bytes32 hash)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
            );
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.17;

library Math {
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b + (a % b == 0 ? 0 : 1);
    }
}