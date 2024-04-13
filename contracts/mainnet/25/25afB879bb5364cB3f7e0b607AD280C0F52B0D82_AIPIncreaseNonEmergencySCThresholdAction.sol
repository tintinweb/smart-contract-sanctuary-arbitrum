// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.16;

import "../../governance/SetSCThresholdAndUpdateConstitutionAction.sol";
import "../../../interfaces/IArbitrumDAOConstitution.sol";

///@notice increase the non-emergency Security Council Threshold from 7 to 9 and update constitution accordingly.
/// For discussion / rationale, see https://forum.arbitrum.foundation/t/rfc-constitutional-aip-security-council-improvement-proposal/20541
/// Old constitution hash comes from election propoosal, see https://forum.arbitrum.foundation/t/aip-changes-to-the-constitution-and-the-security-council-election-process/20856/13
contract AIPIncreaseNonEmergencySCThresholdAction is SetSCThresholdAndUpdateConstitutionAction {
    constructor()
        SetSCThresholdAndUpdateConstitutionAction(
            IGnosisSafe(0xADd68bCb0f66878aB9D37a447C7b9067C5dfa941), // non emergency security council
            7, // old threshold
            9, // new threshold
            IArbitrumDAOConstitution(address(0x1D62fFeB72e4c360CcBbacf7c965153b00260417)), // DAO constitution
            bytes32(0xe794b7d0466ffd4a33321ea14c307b2de987c3229cf858727052a6f4b8a19cc1), //  constitution hash: election change, no threshold increase. https://github.com/ArbitrumFoundation/docs/tree/0837520dccc12e56a25f62de90ff9e3869196d05
            bytes32(0x7cc34e90dde73cfe0b4a041e79b5638e99f0d9547001e42b466c32a18ed6789d) // constitution hash: election change abd threshold increase.  https://github.com/ArbitrumFoundation/docs/pull/762/commits/88a6d38e15f1691c2ce7d31fe7c21e8fd52ac126
        ) 
    {}
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.16;

interface IArbitrumDAOConstitution {
    function constitutionHash() external view returns (bytes32);
    function setConstitutionHash(bytes32 _constitutionHash) external;
    function owner() external view returns (address);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.16;

import "../../security-council-mgmt/interfaces/IGnosisSafe.sol";
import "../../interfaces/IArbitrumDAOConstitution.sol";
import "./ConstitutionActionLib.sol";

interface _IGnosisSafe {
    function changeThreshold(uint256 _threshold) external;
}

///@notice Set the minimum signing threshold for a security council gnosis safe. Assumes that the safe has the UpgradeExecutor added as a module.
/// Also conditionally updates constitution dependent on its current hash.
contract SetSCThresholdAndUpdateConstitutionAction {
    IGnosisSafe public immutable gnosisSafe;
    uint256 public immutable oldThreshold;
    uint256 public immutable newThreshold;
    IArbitrumDAOConstitution public immutable constitution;
    bytes32 public immutable oldConstitutionHash;
    bytes32 public immutable newConstitutionHash;

    event ActionPerformed(uint256 newThreshold, bytes32 newConstitutionHash);

    constructor(
        IGnosisSafe _gnosisSafe,
        uint256 _oldThreshold,
        uint256 _newThreshold,
        IArbitrumDAOConstitution _constitution,
        bytes32 _oldConstitutionHash,
        bytes32 _newConstitutionHash
    ) {
        gnosisSafe = _gnosisSafe;
        oldThreshold = _oldThreshold;
        newThreshold = _newThreshold;
        constitution = _constitution;
        oldConstitutionHash = _oldConstitutionHash;
        newConstitutionHash = _newConstitutionHash;
    }

    function perform() external {
        require(
            constitution.constitutionHash() == oldConstitutionHash, "WRONG_OLD_CONSTITUTION_HASH"
        );
        constitution.setConstitutionHash(newConstitutionHash);
        require(constitution.constitutionHash() == newConstitutionHash, "NEW_CONSTITUTION_HASH_SET");
        // sanity check old threshold
        require(
            gnosisSafe.getThreshold() == oldThreshold, "SetSCThresholdAction: WRONG_OLD_THRESHOLD"
        );

        gnosisSafe.execTransactionFromModule({
            to: address(gnosisSafe),
            value: 0,
            data: abi.encodeWithSelector(_IGnosisSafe.changeThreshold.selector, newThreshold),
            operation: OpEnum.Operation.Call
        });
        // sanity check new threshold was set
        require(
            gnosisSafe.getThreshold() == newThreshold, "SetSCThresholdAction: NEW_THRESHOLD_NOT_SET"
        );
        emit ActionPerformed(newThreshold, constitution.constitutionHash());
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.16;

import "../../interfaces/IArbitrumDAOConstitution.sol";

library ConstitutionActionLib {
    error ConstitutionHashNotSet();
    error UnhandledConstitutionHash();
    error ConstitutionHashLengthMismatch();

    /// @notice Update dao constitution hash
    /// @param constitution DAO constitution contract
    /// @param _newConstitutionHash new constitution hash
    function updateConstitutionHash(
        IArbitrumDAOConstitution constitution,
        bytes32 _newConstitutionHash
    ) internal {
        constitution.setConstitutionHash(_newConstitutionHash);
        if (constitution.constitutionHash() != _newConstitutionHash) {
            revert ConstitutionHashNotSet();
        }
    }

    /// @notice checks actual constitution hash for presence in _oldConstitutionHashes and sets constitution hash to the hash in the corresponding index in _newConstitutionHashes if found
    /// @param _constitution DAO constitution contract
    /// @param _oldConstitutionHashes hashes to check against the current constitution
    /// @param _newConstitutionHashes hashes to set at corresponding index if hash in oldConstitutionHashes is found (on the first match)
    function conditonallyUpdateConstitutionHash(
        IArbitrumDAOConstitution _constitution,
        bytes32[] memory _oldConstitutionHashes,
        bytes32[] memory _newConstitutionHashes
    ) internal returns (bytes32) {
        bytes32 constitutionHash = _constitution.constitutionHash();
        if (_oldConstitutionHashes.length != _newConstitutionHashes.length) {
            revert ConstitutionHashLengthMismatch();
        }

        for (uint256 i = 0; i < _oldConstitutionHashes.length; i++) {
            if (_oldConstitutionHashes[i] == constitutionHash) {
                bytes32 newConstitutionHash = _newConstitutionHashes[i];
                updateConstitutionHash(_constitution, newConstitutionHash);
                return newConstitutionHash;
            }
        }
        revert UnhandledConstitutionHash();
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.16;

abstract contract OpEnum {
    enum Operation {
        Call,
        DelegateCall
    }
}

interface IGnosisSafe {
    function getOwners() external view returns (address[] memory);
    function getThreshold() external view returns (uint256);
    function isOwner(address owner) external view returns (bool);
    function isModuleEnabled(address module) external view returns (bool);
    function addOwnerWithThreshold(address owner, uint256 threshold) external;
    function removeOwner(address prevOwner, address owner, uint256 threshold) external;
    function execTransactionFromModule(
        address to,
        uint256 value,
        bytes memory data,
        OpEnum.Operation operation
    ) external returns (bool success);
}