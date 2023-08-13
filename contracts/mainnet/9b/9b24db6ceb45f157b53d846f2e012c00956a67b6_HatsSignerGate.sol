// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

// import { Test, console2 } from "forge-std/Test.sol"; // remove after testing
import { HatsSignerGateBase, IGnosisSafe, Enum } from "./HatsSignerGateBase.sol";
import "./HSGLib.sol";

contract HatsSignerGate is HatsSignerGateBase {
    uint256 public signersHatId;

    /// @notice Initializes a new instance of HatsSignerGate
    /// @dev Can only be called once
    /// @param initializeParams ABI-encoded bytes with initialization parameters
    function setUp(bytes calldata initializeParams) public payable override initializer {
        (
            uint256 _ownerHatId,
            uint256 _signersHatId,
            address _safe,
            address _hats,
            uint256 _minThreshold,
            uint256 _targetThreshold,
            uint256 _maxSigners,
            string memory _version,
        ) = abi.decode(
            initializeParams, (uint256, uint256, address, address, uint256, uint256, uint256, string, uint256)
        );

        _setUp(_ownerHatId, _safe, _hats, _minThreshold, _targetThreshold, _maxSigners, _version);

        signersHatId = _signersHatId;
    }

    /// @notice Function to become an owner on the safe if you are wearing the signers hat
    /// @dev Reverts if `maxSigners` has been reached, the caller is either invalid or has already claimed. Swaps caller with existing invalid owner if relevant.
    function claimSigner() public virtual {
        uint256 maxSigs = maxSigners; // save SLOADs
        address[] memory owners = safe.getOwners();
        uint256 currentSignerCount = _countValidSigners(owners);

        if (currentSignerCount >= maxSigs) {
            revert MaxSignersReached();
        }

        if (safe.isOwner(msg.sender)) {
            revert SignerAlreadyClaimed(msg.sender);
        }

        if (!isValidSigner(msg.sender)) {
            revert NotSignerHatWearer(msg.sender);
        }

        /*
        We check the safe owner count in case there are existing owners who are no longer valid signers.
        If we're already at maxSigners, we'll replace one of the invalid owners by swapping the signer.
        Otherwise, we'll simply add the new signer.
        */
        uint256 ownerCount = owners.length;
        if (ownerCount >= maxSigs) {
            bool swapped = _swapSigner(owners, ownerCount, msg.sender);
            if (!swapped) {
                // if there are no invalid owners, we can't add a new signer, so we revert
                revert NoInvalidSignersToReplace();
            }
        } else {
            _grantSigner(owners, currentSignerCount, msg.sender);
        }
    }

    /// @notice Checks if `_account` is a valid signer, ie is wearing the signer hat
    /// @dev Must be implemented by all flavors of HatsSignerGate
    /// @param _account The address to check
    /// @return valid Whether `_account` is a valid signer
    function isValidSigner(address _account) public view override returns (bool valid) {
        valid = HATS.isWearerOfHat(_account, signersHatId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

// import { Test, console2 } from "forge-std/Test.sol"; // remove after testing
import "./HSGLib.sol";
import { HatsOwnedInitializable } from "hats-auth/HatsOwnedInitializable.sol";
import { BaseGuard } from "zodiac/guard/BaseGuard.sol";
import { IAvatar } from "zodiac/interfaces/IAvatar.sol";
import { StorageAccessible } from "@gnosis.pm/safe-contracts/contracts/common/StorageAccessible.sol";
import { IGnosisSafe, Enum } from "./Interfaces/IGnosisSafe.sol";
import { SignatureDecoder } from "@gnosis.pm/safe-contracts/contracts/common/SignatureDecoder.sol";

abstract contract HatsSignerGateBase is BaseGuard, SignatureDecoder, HatsOwnedInitializable {
    /// @notice The multisig to which this contract is attached
    IGnosisSafe public safe;

    /// @notice The minimum signature threshold for the `safe`
    uint256 public minThreshold;

    /// @notice The highest level signature threshold for the `safe`
    uint256 public targetThreshold;

    /// @notice The maximum number of signers allowed for the `safe`
    uint256 public maxSigners;

    /// @notice The version of HatsSignerGate used in this contract
    string public version;

    /// @dev Temporary record of the existing owners on the `safe` when a transaction is submitted
    bytes32 internal _existingOwnersHash;

    /// @dev A simple re-entrency guard
    uint256 internal _guardEntries;

    /// @dev The head pointer used in the GnosisSafe owners linked list, as well as the module linked list
    address internal constant SENTINEL_OWNERS = address(0x1);

    /// @dev The storage slot used by GnosisSafe to store the guard address
    ///      keccak256("guard_manager.guard.address")
    bytes32 internal constant GUARD_STORAGE_SLOT = 0x4a204f620c8c5ccdca3fd54d003badd85ba500436a431f0cbda4f558c93c34c8;

    /// @dev Makes the singleton unusable by setting its owner to the 1-address
    constructor() payable initializer {
        _HatsOwned_init(1, address(0x1));
    }

    /// @notice Initializes a new instance
    /// @dev Can only be called once
    /// @param initializeParams ABI-encoded bytes with initialization parameters
    function setUp(bytes calldata initializeParams) public payable virtual initializer { }

    /// @notice Internal function to initialize a new instance
    /// @param _ownerHatId The hat id of the hat that owns this instance of HatsSignerGate
    /// @param _safe The multisig to which this instance of HatsSignerGate is attached
    /// @param _hats The Hats Protocol address
    /// @param _minThreshold The minimum threshold for the `_safe`
    /// @param _targetThreshold The maxium threshold for the `_safe`
    /// @param _maxSigners The maximum number of signers allowed on the `_safe`
    /// @param _version The current version of HatsSignerGate
    function _setUp(
        uint256 _ownerHatId,
        address _safe,
        address _hats,
        uint256 _minThreshold,
        uint256 _targetThreshold,
        uint256 _maxSigners,
        string memory _version
    ) internal {
        _HatsOwned_init(_ownerHatId, _hats);
        maxSigners = _maxSigners;
        safe = IGnosisSafe(_safe);

        _setTargetThreshold(_targetThreshold);
        _setMinThreshold(_minThreshold);
        version = _version;
    }

    /// @notice Checks if `_account` is a valid signer
    /// @dev Must be implemented by all flavors of HatsSignerGate
    /// @param _account The address to check
    /// @return valid Whether `_account` is a valid signer
    function isValidSigner(address _account) public view virtual returns (bool valid) { }

    /// @notice Sets a new target threshold, and changes `safe`'s threshold if appropriate
    /// @dev Only callable by a wearer of the owner hat. Reverts if `_targetThreshold` is greater than `maxSigners`.
    /// @param _targetThreshold The new target threshold to set
    function setTargetThreshold(uint256 _targetThreshold) public onlyOwner {
        if (_targetThreshold != targetThreshold) {
            _setTargetThreshold(_targetThreshold);

            uint256 signerCount = validSignerCount();
            if (signerCount > 1) _setSafeThreshold(_targetThreshold, signerCount);

            emit HSGLib.TargetThresholdSet(_targetThreshold);
        }
    }

    /// @notice Internal function to set the target threshold
    /// @dev Reverts if `_targetThreshold` is greater than `maxSigners` or lower than `minThreshold`
    /// @param _targetThreshold The new target threshold to set
    function _setTargetThreshold(uint256 _targetThreshold) internal {
        // target threshold cannot be lower than min threshold
        if (_targetThreshold < minThreshold) {
            revert InvalidTargetThreshold();
        }
        // target threshold cannot be greater than max signers
        if (_targetThreshold > maxSigners) {
            revert InvalidTargetThreshold();
        }

        targetThreshold = _targetThreshold;
    }

    /// @notice Internal function to set the threshold for the `safe`
    /// @dev Forwards the threshold-setting call to `safe.ExecTransactionFromModule`
    /// @param _threshold The threshold to set on the `safe`
    /// @param _signerCount The number of valid signers on the `safe`; should be calculated from `validSignerCount()`
    function _setSafeThreshold(uint256 _threshold, uint256 _signerCount) internal {
        uint256 newThreshold = _threshold;

        // ensure that txs can't execute if fewer signers than target threshold
        if (_signerCount <= _threshold) {
            newThreshold = _signerCount;
        }
        if (newThreshold != safe.getThreshold()) {
            bytes memory data = abi.encodeWithSignature("changeThreshold(uint256)", newThreshold);

            bool success = safe.execTransactionFromModule(
                address(safe), // to
                0, // value
                data, // data
                Enum.Operation.Call // operation
            );

            if (!success) {
                revert FailedExecChangeThreshold();
            }
        }
    }

    /// @notice Sets a new minimum threshold
    /// @dev Only callable by a wearer of the owner hat. Reverts if `_minThreshold` is greater than `maxSigners` or `targetThreshold`
    /// @param _minThreshold The new minimum threshold
    function setMinThreshold(uint256 _minThreshold) public onlyOwner {
        _setMinThreshold(_minThreshold);
        emit HSGLib.MinThresholdSet(_minThreshold);
    }

    /// @notice Internal function to set a new minimum threshold
    /// @dev Only callable by a wearer of the owner hat. Reverts if `_minThreshold` is greater than `maxSigners` or `targetThreshold`
    /// @param _minThreshold The new minimum threshold
    function _setMinThreshold(uint256 _minThreshold) internal {
        if (_minThreshold > maxSigners || _minThreshold > targetThreshold) {
            revert InvalidMinThreshold();
        }

        minThreshold = _minThreshold;
    }

    /// @notice Tallies the number of existing `safe` owners that wear a signer hat and updates the `safe` threshold if necessary
    /// @dev Does NOT remove invalid `safe` owners
    function reconcileSignerCount() public {
        uint256 signerCount = validSignerCount();

        if (signerCount > maxSigners) {
            revert MaxSignersReached();
        }

        uint256 currentThreshold = safe.getThreshold();
        uint256 newThreshold;
        uint256 target = targetThreshold; // save SLOADs

        if (signerCount <= target && signerCount != currentThreshold) {
            newThreshold = signerCount;
        } else if (signerCount > target && currentThreshold < target) {
            newThreshold = target;
        }
        if (newThreshold > 0) {
            bytes memory data = abi.encodeWithSignature("changeThreshold(uint256)", newThreshold);

            bool success = safe.execTransactionFromModule(
                address(safe), // to
                0, // value
                data, // data
                Enum.Operation.Call // operation
            );

            if (!success) {
                revert FailedExecChangeThreshold();
            }
        }
    }

    /// @notice Tallies the number of existing `safe` owners that wear a signer hat
    /// @return signerCount The number of valid signers on the `safe`
    function validSignerCount() public view returns (uint256 signerCount) {
        signerCount = _countValidSigners(safe.getOwners());
    }

    /// @notice Internal function to count the number of valid signers in an array of addresses
    /// @param owners The addresses to check for validity
    /// @return signerCount The number of valid signers in `owners`
    function _countValidSigners(address[] memory owners) internal view returns (uint256 signerCount) {
        uint256 length = owners.length;
        // count the existing safe owners that wear the signer hat
        for (uint256 i; i < length;) {
            if (isValidSigner(owners[i])) {
                // shouldn't overflow given reasonable owners array length
                unchecked {
                    ++signerCount;
                }
            }
            // shouldn't overflow given reasonable owners array length
            unchecked {
                ++i;
            }
        }
    }

    /// @notice Internal function that adds `_signer` as an owner on `safe`, updating the threshold if appropriate
    /// @dev Unsafe. Does not check if `_signer` is a valid signer
    /// @param _owners Array of owners on the `safe`
    /// @param _currentSignerCount The current number of signers
    /// @param _signer The address to add as a new `safe` owner
    function _grantSigner(address[] memory _owners, uint256 _currentSignerCount, address _signer) internal {
        uint256 newSignerCount = _currentSignerCount;

        uint256 currentThreshold = safe.getThreshold(); // view function
        uint256 newThreshold = currentThreshold;

        bytes memory addOwnerData;

        // if the only owner is a non-signer (ie this module set as an owner on initialization), replace it with _signer
        if (_owners.length == 1 && _owners[0] == address(this)) {
            // prevOwner will always be the sentinel when owners.length == 1

            // set up the swapOwner call
            addOwnerData = abi.encodeWithSignature(
                "swapOwner(address,address,address)",
                SENTINEL_OWNERS, // prevOwner
                address(this), // oldOwner
                _signer // newOwner
            );
            unchecked {
                // shouldn't overflow given MaxSignersReached check higher in call stack
                ++newSignerCount;
            }
        } else {
            // otherwise, add the claimer as a new owner

            unchecked {
                // shouldn't overflow given MaxSignersReached check higher in call stack
                ++newSignerCount;
            }

            // ensure that txs can't execute if fewer signers than target threshold
            if (newSignerCount <= targetThreshold) {
                newThreshold = newSignerCount;
            }

            // set up the addOwner call
            addOwnerData = abi.encodeWithSignature("addOwnerWithThreshold(address,uint256)", _signer, newThreshold);
        }

        // execute the call
        bool success = safe.execTransactionFromModule(
            address(safe), // to
            0, // value
            addOwnerData, // data
            Enum.Operation.Call // operation
        );

        if (!success) {
            revert FailedExecAddSigner();
        }
    }

    /// @notice Internal function that adds `_signer` as an owner on `safe` by swapping with an existing (invalid) owner
    /// @dev Unsafe. Does not check if `_signer` is a valid signer.
    /// @param _owners Array of owners on the `safe`
    /// @param _ownerCount The number of owners on the `safe` (length of `_owners` array)
    /// @param _signer The address to add as a new `safe` owner
    /// @return success Whether an invalid signer was found and successfully replaced with `_signer`
    function _swapSigner(address[] memory _owners, uint256 _ownerCount, address _signer)
        internal
        returns (bool success)
    {
        address ownerToCheck;
        bytes memory data;

        for (uint256 i; i < _ownerCount;) {
            ownerToCheck = _owners[i];

            if (!isValidSigner(ownerToCheck)) {
                // prep the swap
                data = abi.encodeWithSignature(
                    "swapOwner(address,address,address)",
                    _findPrevOwner(_owners, ownerToCheck), // prevOwner
                    ownerToCheck, // oldOwner
                    _signer // newOwner
                );

                // execute the swap, reverting if it fails for some reason
                success = safe.execTransactionFromModule(
                    address(safe), // to
                    0, // value
                    data, // data
                    Enum.Operation.Call // operation
                );

                if (!success) {
                    revert FailedExecRemoveSigner();
                }

                break;
            }
            unchecked {
                ++i;
            }
        }
    }

    /// @notice Removes an invalid signer from the `safe`, updating the threshold if appropriate
    /// @param _signer The address to remove if not a valid signer
    function removeSigner(address _signer) public virtual {
        if (isValidSigner(_signer)) {
            revert StillWearsSignerHat(_signer);
        }

        _removeSigner(_signer);
    }

    /// @notice Internal function to remove a signer from the `safe`, updating the threshold if appropriate
    /// @dev Unsafe. Does not check for signer validity before removal
    /// @param _signer The address to remove
    function _removeSigner(address _signer) internal {
        bytes memory removeOwnerData;
        address[] memory owners = safe.getOwners();
        uint256 validSigners = _countValidSigners(owners);
        // uint256 newSignerCount;

        if (validSigners < 2 && owners.length == 1) {
            // signerCount could be 0 after reconcileSignerCount
            // make address(this) the only owner
            removeOwnerData = abi.encodeWithSignature(
                "swapOwner(address,address,address)",
                SENTINEL_OWNERS, // prevOwner
                _signer, // oldOwner
                address(this) // newOwner
            );

            // newSignerCount is already 0
        } else {
            uint256 currentThreshold = safe.getThreshold();
            uint256 newThreshold = currentThreshold;
            // uint256 validSignerCount = _countValidSigners(owners);

            // ensure that txs can't execute if fewer signers than target threshold
            if (validSigners <= targetThreshold) {
                newThreshold = validSigners;
            }

            removeOwnerData = abi.encodeWithSignature(
                "removeOwner(address,address,uint256)", _findPrevOwner(owners, _signer), _signer, newThreshold
            );
        }

        bool success = safe.execTransactionFromModule(
            address(safe), // to
            0, // value
            removeOwnerData, // data
            Enum.Operation.Call // operation
        );

        if (!success) {
            revert FailedExecRemoveSigner();
        }
    }

    /// @notice Internal function to find the previous owner of an `_owner` in an array of `_owners`, ie the pointer to the owner to remove from the `safe` owners linked list
    /// @param _owners An array of addresses
    /// @param _owner The address after the one to find
    /// @return prevOwner The owner previous to `_owner` in the `safe` linked list
    function _findPrevOwner(address[] memory _owners, address _owner) internal pure returns (address prevOwner) {
        prevOwner = SENTINEL_OWNERS;

        for (uint256 i; i < _owners.length;) {
            if (_owners[i] == _owner) {
                if (i == 0) break;
                prevOwner = _owners[i - 1];
            }
            // shouldn't overflow given reasonable _owners array length
            unchecked {
                ++i;
            }
        }
    }

    // solhint-disallow-next-line payable-fallback
    fallback() external {
        // We don't revert on fallback to avoid issues in case of a Safe upgrade
        // E.g. The expected check method might change and then the Safe would be locked.
    }

    /// @notice Pre-flight check on a `safe` transaction to ensure that it s signers are valid, called from within `safe.execTransactionFromModule()`
    /// @dev Overrides All params mirror params for `safe.execTransactionFromModule()`
    function checkTransaction(
        address to,
        uint256 value,
        bytes calldata data,
        Enum.Operation operation,
        uint256 safeTxGas,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address payable refundReceiver,
        bytes memory signatures,
        address // msgSender
    ) external override {
        if (msg.sender != address(safe)) revert NotCalledFromSafe();
        // get the safe owners
        address[] memory owners = safe.getOwners();
        {
            // scope to avoid stack too deep errors
            uint256 safeOwnerCount = owners.length;
            // uint256 validSignerCount = _countValidSigners(safe.getOwners());
            // ensure that safe threshold is correct
            reconcileSignerCount();

            if (safeOwnerCount < minThreshold) {
                revert BelowMinThreshold(minThreshold, safeOwnerCount);
            }
        }
        // get the tx hash; view function
        bytes32 txHash = safe.getTransactionHash(
            // Transaction info
            to,
            value,
            data,
            operation,
            safeTxGas,
            // Payment info
            baseGas,
            gasPrice,
            gasToken,
            refundReceiver,
            // Signature info
            // We subtract 1 since nonce was just incremented in the parent function call
            safe.nonce() - 1 // view function
        );
        uint256 threshold = safe.getThreshold();
        uint256 validSigCount = countValidSignatures(txHash, signatures, threshold);

        // revert if there aren't enough valid signatures
        if (validSigCount < threshold || validSigCount < minThreshold) {
            revert InvalidSigners();
        }

        // record existing owners for post-flight check
        _existingOwnersHash = keccak256(abi.encode(owners));

        unchecked {
            ++_guardEntries;
        }
        // revert if re-entry is detected
        if (_guardEntries > 1) revert NoReentryAllowed();
    }

    /**
     * @notice Post-flight check to prevent `safe` signers from performing any of the following actions:
     *         1. removing this contract guard
     *         2. changing any modules
     *         3. changing the threshold
     *         4. changing the owners
     *     CAUTION: If the safe has any authority over the signersHat(s) — i.e. wears their admin hat(s) or is an eligibility or toggle module —
     *     then in some cases protections (3) and (4) may not hold. Proceed with caution if considering granting such authority to the safe.
     * @dev Modified from https://github.com/gnosis/zodiac-guard-mod/blob/988ebc7b71e352f121a0be5f6ae37e79e47a4541/contracts/ModGuard.sol#L86
     */
    function checkAfterExecution(bytes32, bool) external override {
        if (msg.sender != address(safe)) revert NotCalledFromSafe();
        // prevent signers from disabling this guard
        if (
            abi.decode(StorageAccessible(address(safe)).getStorageAt(uint256(GUARD_STORAGE_SLOT), 1), (address))
                != address(this)
        ) {
            revert CannotDisableThisGuard(address(this));
        }
        // prevent signers from changing the threshold
        if (safe.getThreshold() != _getCorrectThreshold()) {
            revert SignersCannotChangeThreshold();
        }
        // prevent signers from changing the owners
        address[] memory owners = safe.getOwners();
        if (keccak256(abi.encode(owners)) != _existingOwnersHash) {
            revert SignersCannotChangeOwners();
        }
        // prevent signers from removing this module or adding any other modules
        /// @dev SENTINEL_OWNERS and SENTINEL_MODULES are both address(0x1)
        (address[] memory modulesWith1, address next) = safe.getModulesPaginated(SENTINEL_OWNERS, 1);
        // ensure that there is only one module...
        if (
            // if the length is 0, we know this module has been removed
            // forgefmt: disable-next-line
            modulesWith1.length == 0
            /* per Safe ModuleManager.sol#137, "If all entries fit into a single page, the next pointer will be 0x1", ie SENTINEL_OWNERS.
            Therefore, if `next` is not SENTINEL_OWNERS, we know another module has been added. */
            || next != SENTINEL_OWNERS
        ) {
            revert SignersCannotChangeModules();
        } // ...and that the only module is this contract
        else if (modulesWith1[0] != address(this)) {
            revert SignersCannotChangeModules();
        }
        // leave checked to catch underflows triggered by re-entry attempts
        --_guardEntries;
    }

    /// @notice Internal function to calculate the threshold that `safe` should have, given the correct `signerCount`, `minThreshold`, and `targetThreshold`
    /// @return _threshold The correct threshold
    function _getCorrectThreshold() internal view returns (uint256 _threshold) {
        uint256 count = validSignerCount();
        uint256 min = minThreshold;
        uint256 max = targetThreshold;
        if (count < min) _threshold = min;
        else if (count > max) _threshold = max;
        else _threshold = count;
    }

    /// @notice Counts the number of hats-valid signatures within a set of `signatures`
    /// @dev modified from https://github.com/safe-global/safe-contracts/blob/c36bcab46578a442862d043e12a83fec41143dec/contracts/GnosisSafe.sol#L240
    /// @param dataHash The signed data
    /// @param signatures The set of signatures to check
    /// @return validSigCount The number of hats-valid signatures
    function countValidSignatures(bytes32 dataHash, bytes memory signatures, uint256 sigCount)
        public
        view
        returns (uint256 validSigCount)
    {
        // There cannot be an owner with address 0.
        address currentOwner;
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 i;

        for (i; i < sigCount;) {
            (v, r, s) = signatureSplit(signatures, i);
            if (v == 0) {
                // If v is 0 then it is a contract signature
                // When handling contract signatures the address of the contract is encoded into r
                currentOwner = address(uint160(uint256(r)));
            } else if (v == 1) {
                // If v is 1 then it is an approved hash
                // When handling approved hashes the address of the approver is encoded into r
                currentOwner = address(uint160(uint256(r)));
            } else if (v > 30) {
                // If v > 30 then default va (27,28) has been adjusted for eth_sign flow
                // To support eth_sign and similar we adjust v and hash the messageHash with the Ethereum message prefix before applying ecrecover
                currentOwner =
                    ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", dataHash)), v - 4, r, s);
            } else {
                // Default is the ecrecover flow with the provided data hash
                // Use ecrecover with the messageHash for EOA signatures
                currentOwner = ecrecover(dataHash, v, r, s);
            }

            if (isValidSigner(currentOwner)) {
                // shouldn't overflow given reasonable sigCount
                unchecked {
                    ++validSigCount;
                }
            }
            // shouldn't overflow given reasonable sigCount
            unchecked {
                ++i;
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

library HSGLib {
    /// @notice Emitted when a new target signature threshold for the `safe` is set
    event TargetThresholdSet(uint256 threshold);

    /// @notice Emitted when a new minimum signature threshold for the `safe` is set
    event MinThresholdSet(uint256 threshold);

    /// @notice Emitted when new approved signer hats are added
    event SignerHatsAdded(uint256[] newSignerHats);
}

/// @notice Signers are not allowed to disable the HatsSignerGate guard
error CannotDisableThisGuard(address guard);

/// @notice Only the wearer of the owner Hat can make changes to this contract
error NotOwnerHatWearer(address user);

/// @notice Only wearers of a valid signer hat can become signers
error NotSignerHatWearer(address user);

/// @notice Valid signers must wear the signer hat at time of execution
error InvalidSigners();

/// @notice This contract can only be set once as a zodiac guard on `safe`
error GuardAlreadySet();

/// @notice Can't remove a signer if they're still wearing the signer hat
error StillWearsSignerHat(address signer);

/// @notice Can never have more signers than designated by `maxSigners`
error MaxSignersReached();

/// @notice Emitted when a valid signer attempts `claimSigner` but there are already `maxSigners` signers
/// @dev This will only occur if `signerCount` is out of sync with the current number of valid signers, which can be resolved by calling `reconcileSignerCount`
error NoInvalidSignersToReplace();

/// @notice Target threshold must be lower than `maxSigners`
error InvalidTargetThreshold();

/// @notice Min threshold cannot be higher than `maxSigners` or `targetThreshold`
error InvalidMinThreshold();

/// @notice Signers already on the `safe` cannot claim twice
error SignerAlreadyClaimed(address signer);

/// @notice Emitted when a call to change the threshold fails
error FailedExecChangeThreshold();

/// @notice Emitted when a call to add a signer fails
error FailedExecAddSigner();

/// @notice Emitted when a call to remove a signer fails
error FailedExecRemoveSigner();

/// @notice Emitted when a call to enable a module fails
error FailedExecEnableModule();

/// @notice Cannot exececute a tx if `safeOnwerCount` < `minThreshold`
error BelowMinThreshold(uint256 minThreshold, uint256 safeOwnerCount);

/// @notice Can only claim signer with a valid signer hat
error InvalidSignerHat(uint256 hatId);

/// @notice Signers are not allowed to change the threshold
error SignersCannotChangeThreshold();

/// @notice Signers are not allowed to add new modules
error SignersCannotChangeModules();

/// @notice Signers are not allowed to change owners
error SignersCannotChangeOwners();

/// @notice Emmitted when a call to `checkTransaction` or `checkAfterExecution` is not made from the `safe`
/// @dev Together with `guardEntries`, protects against arbitrary reentrancy attacks by the signers
error NotCalledFromSafe();

/// @notice Emmitted when attempting to reenter `checkTransaction`
/// @dev The Safe will catch this error and re-throw with its own error message (`GS013`)
error NoReentryAllowed();

// SPDX-License-Identifier: CC0
pragma solidity >=0.8.13;

import "./HatsOwnedCommon.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/// @notice Single owner authorization mixin using Hats Protocol
/// @dev For inheretence into contracts deployed as proxies. Forked from solmate (https://github.com/transmissions11/solmate/blob/main/src/auth/Owned.sol).
/// @author Hats Protocol
abstract contract HatsOwnedInitializable is HatsOwnedCommon, Initializable {
    /*//////////////////////////////////////////////////////////////
                               INITIALIZATION
    //////////////////////////////////////////////////////////////*/

    function _HatsOwned_init(uint256 _ownerHat, address _hatsContract)
        internal
        onlyInitializing
    {
        ownerHat = _ownerHat;
        HATS = IHats(_hatsContract);

        emit OwnerHatUpdated(_ownerHat, _hatsContract);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

import "@gnosis.pm/safe-contracts/contracts/common/Enum.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "../interfaces/IGuard.sol";

abstract contract BaseGuard is IERC165 {
    function supportsInterface(bytes4 interfaceId)
        external
        pure
        override
        returns (bool)
    {
        return
            interfaceId == type(IGuard).interfaceId || // 0xe6d7a83a
            interfaceId == type(IERC165).interfaceId; // 0x01ffc9a7
    }

    /// @dev Module transactions only use the first four parameters: to, value, data, and operation.
    /// Module.sol hardcodes the remaining parameters as 0 since they are not used for module transactions.
    /// @notice This interface is used to maintain compatibilty with Gnosis Safe transaction guards.
    function checkTransaction(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation,
        uint256 safeTxGas,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address payable refundReceiver,
        bytes memory signatures,
        address msgSender
    ) external virtual;

    function checkAfterExecution(bytes32 txHash, bool success) external virtual;
}

// SPDX-License-Identifier: LGPL-3.0-only

/// @title Zodiac Avatar - A contract that manages modules that can execute transactions via this contract.
pragma solidity >=0.7.0 <0.9.0;

import "@gnosis.pm/safe-contracts/contracts/common/Enum.sol";

interface IAvatar {
    event EnabledModule(address module);
    event DisabledModule(address module);
    event ExecutionFromModuleSuccess(address indexed module);
    event ExecutionFromModuleFailure(address indexed module);

    /// @dev Enables a module on the avatar.
    /// @notice Can only be called by the avatar.
    /// @notice Modules should be stored as a linked list.
    /// @notice Must emit EnabledModule(address module) if successful.
    /// @param module Module to be enabled.
    function enableModule(address module) external;

    /// @dev Disables a module on the avatar.
    /// @notice Can only be called by the avatar.
    /// @notice Must emit DisabledModule(address module) if successful.
    /// @param prevModule Address that pointed to the module to be removed in the linked list
    /// @param module Module to be removed.
    function disableModule(address prevModule, address module) external;

    /// @dev Allows a Module to execute a transaction.
    /// @notice Can only be called by an enabled module.
    /// @notice Must emit ExecutionFromModuleSuccess(address module) if successful.
    /// @notice Must emit ExecutionFromModuleFailure(address module) if unsuccessful.
    /// @param to Destination address of module transaction.
    /// @param value Ether value of module transaction.
    /// @param data Data payload of module transaction.
    /// @param operation Operation type of module transaction: 0 == call, 1 == delegate call.
    function execTransactionFromModule(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation
    ) external returns (bool success);

    /// @dev Allows a Module to execute a transaction and return data
    /// @notice Can only be called by an enabled module.
    /// @notice Must emit ExecutionFromModuleSuccess(address module) if successful.
    /// @notice Must emit ExecutionFromModuleFailure(address module) if unsuccessful.
    /// @param to Destination address of module transaction.
    /// @param value Ether value of module transaction.
    /// @param data Data payload of module transaction.
    /// @param operation Operation type of module transaction: 0 == call, 1 == delegate call.
    function execTransactionFromModuleReturnData(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation
    ) external returns (bool success, bytes memory returnData);

    /// @dev Returns if an module is enabled
    /// @return True if the module is enabled
    function isModuleEnabled(address module) external view returns (bool);

    /// @dev Returns array of modules.
    /// @param start Start of the page.
    /// @param pageSize Maximum number of modules that should be returned.
    /// @return array Array of modules.
    /// @return next Start of the next page.
    function getModulesPaginated(address start, uint256 pageSize)
        external
        view
        returns (address[] memory array, address next);
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

/// @title StorageAccessible - generic base contract that allows callers to access all internal storage.
/// @notice See https://github.com/gnosis/util-contracts/blob/bb5fe5fb5df6d8400998094fb1b32a178a47c3a1/contracts/StorageAccessible.sol
contract StorageAccessible {
    /**
     * @dev Reads `length` bytes of storage in the currents contract
     * @param offset - the offset in the current contract's storage in words to start reading from
     * @param length - the number of words (32 bytes) of data to read
     * @return the bytes that were read.
     */
    function getStorageAt(uint256 offset, uint256 length) public view returns (bytes memory) {
        bytes memory result = new bytes(length * 32);
        for (uint256 index = 0; index < length; index++) {
            // solhint-disable-next-line no-inline-assembly
            assembly {
                let word := sload(add(offset, index))
                mstore(add(add(result, 0x20), mul(index, 0x20)), word)
            }
        }
        return result;
    }

    /**
     * @dev Performs a delegatecall on a targetContract in the context of self.
     * Internally reverts execution to avoid side effects (making it static).
     *
     * This method reverts with data equal to `abi.encode(bool(success), bytes(response))`.
     * Specifically, the `returndata` after a call to this method will be:
     * `success:bool || response.length:uint256 || response:bytes`.
     *
     * @param targetContract Address of the contract containing the code to execute.
     * @param calldataPayload Calldata that should be sent to the target contract (encoded method name and arguments).
     */
    function simulateAndRevert(address targetContract, bytes memory calldataPayload) external {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let success := delegatecall(gas(), targetContract, add(calldataPayload, 0x20), mload(calldataPayload), 0, 0)

            mstore(0x00, success)
            mstore(0x20, returndatasize())
            returndatacopy(0x40, 0, returndatasize())
            revert(0, add(returndatasize(), 0x40))
        }
    }
}

// SPDX-License-Identifier: CC0
pragma solidity ^0.8.4;

import { Enum } from "@gnosis.pm/safe-contracts/contracts/common/Enum.sol";

interface IGnosisSafe {
    function addOwnerWithThreshold(address owner, uint256 _threshold) external;

    function swapOwner(address prevOwner, address oldOwner, address newOwner) external;

    function removeOwner(address prevOwner, address owner, uint256 _threshold) external;

    function changeThreshold(uint256 _threshold) external;

    function nonce() external returns (uint256);

    function getThreshold() external returns (uint256);

    function approvedHashes(address approver, bytes32 hash) external returns (uint256);

    function domainSeparator() external view returns (bytes32);

    function getOwners() external view returns (address[] memory);

    function setGuard(address guard) external;

    function execTransactionFromModule(address to, uint256 value, bytes memory data, Enum.Operation operation)
        external
        returns (bool success);

    function getTransactionHash(
        address to,
        uint256 value,
        bytes calldata data,
        Enum.Operation operation,
        uint256 safeTxGas,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address refundReceiver,
        uint256 _nonce
    ) external view returns (bytes32);

    function isOwner(address owner) external returns (bool);

    function getModulesPaginated(address start, uint256 pageSize)
        external
        view
        returns (address[] memory array, address next);
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

/// @title SignatureDecoder - Decodes signatures that a encoded as bytes
/// @author Richard Meissner - <[email protected]>
contract SignatureDecoder {
    /// @dev divides bytes signature into `uint8 v, bytes32 r, bytes32 s`.
    /// @notice Make sure to perform a bounds check for @param pos, to avoid out of bounds access on @param signatures
    /// @param pos which signature to read. A prior bounds check of this parameter should be performed, to avoid out of bounds access
    /// @param signatures concatenated rsv signatures
    function signatureSplit(bytes memory signatures, uint256 pos)
        internal
        pure
        returns (
            uint8 v,
            bytes32 r,
            bytes32 s
        )
    {
        // The signature format is a compact form of:
        //   {bytes32 r}{bytes32 s}{uint8 v}
        // Compact means, uint8 is not padded to 32 bytes.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let signaturePos := mul(0x41, pos)
            r := mload(add(signatures, add(signaturePos, 0x20)))
            s := mload(add(signatures, add(signaturePos, 0x40)))
            // Here we are loading the last 32 bytes, including 31 bytes
            // of 's'. There is no 'mload8' to do this.
            //
            // 'byte' is not working due to the Solidity parser, so lets
            // use the second best option, 'and'
            v := and(mload(add(signatures, add(signaturePos, 0x41))), 0xff)
        }
    }
}

// SPDX-License-Identifier: CC0
pragma solidity >=0.8.13;

import "hats-protocol/Interfaces/IHats.sol";

/// @notice Single owner authorization mixin using Hats Protocol
/// @dev Common logic across initializable and standard versions
/// @author Hats Protocol
abstract contract HatsOwnedCommon {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnerHatUpdated(
        uint256 indexed ownerHat,
        address indexed hatsAddress
    );

    /*//////////////////////////////////////////////////////////////
                            OWNERSHIP STORAGE
    //////////////////////////////////////////////////////////////*/

    IHats internal HATS;
    uint256 public ownerHat;

    modifier onlyOwner() virtual {
        require(HATS.isWearerOfHat(msg.sender, ownerHat), "UNAUTHORIZED");

        _;
    }

    /*//////////////////////////////////////////////////////////////
                             OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

    function setOwnerHat(uint256 _ownerHat, address _hatsContract)
        public
        virtual
        onlyOwner
    {
        uint256 changes;

        if (ownerHat != _ownerHat) {
            ownerHat = _ownerHat;
            // max of 2, so will never overflow
            unchecked {
                ++changes;
            }
        }

        IHats hats = IHats(_hatsContract);

        if (HATS != hats) {
            HATS = hats;
            // max of 2, so will never overflow
            unchecked {
                ++changes;
            }
        }

        require(changes > 0, "NO CHANGES");

        emit OwnerHatUpdated(_ownerHat, _hatsContract);
    }

    /*//////////////////////////////////////////////////////////////
                            VIEW FUNCTIONs
    //////////////////////////////////////////////////////////////*/

    function getHatsContract() public view returns (address) {
        return address(HATS);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized != type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initialized`
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initializing`
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

/// @title Enum - Collection of enums
/// @author Richard Meissner - <[email protected]>
contract Enum {
    enum Operation {Call, DelegateCall}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

import "@gnosis.pm/safe-contracts/contracts/common/Enum.sol";

interface IGuard {
    function checkTransaction(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation,
        uint256 safeTxGas,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address payable refundReceiver,
        bytes memory signatures,
        address msgSender
    ) external;

    function checkAfterExecution(bytes32 txHash, bool success) external;
}

// SPDX-License-Identifier: AGPL-3.0
// Copyright (C) 2023 Haberdasher Labs
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

pragma solidity >=0.8.13;

import "./IHatsIdUtilities.sol";
import "./HatsErrors.sol";
import "./HatsEvents.sol";

interface IHats is IHatsIdUtilities, HatsErrors, HatsEvents {
    function mintTopHat(address _target, string memory _details, string memory _imageURI)
        external
        returns (uint256 topHatId);

    function createHat(
        uint256 _admin,
        string calldata _details,
        uint32 _maxSupply,
        address _eligibility,
        address _toggle,
        bool _mutable,
        string calldata _imageURI
    ) external returns (uint256 newHatId);

    function batchCreateHats(
        uint256[] calldata _admins,
        string[] calldata _details,
        uint32[] calldata _maxSupplies,
        address[] memory _eligibilityModules,
        address[] memory _toggleModules,
        bool[] calldata _mutables,
        string[] calldata _imageURIs
    ) external returns (bool success);

    function getNextId(uint256 _admin) external view returns (uint256 nextId);

    function mintHat(uint256 _hatId, address _wearer) external returns (bool success);

    function batchMintHats(uint256[] calldata _hatIds, address[] calldata _wearers) external returns (bool success);

    function setHatStatus(uint256 _hatId, bool _newStatus) external returns (bool toggled);

    function checkHatStatus(uint256 _hatId) external returns (bool toggled);

    function setHatWearerStatus(uint256 _hatId, address _wearer, bool _eligible, bool _standing)
        external
        returns (bool updated);

    function checkHatWearerStatus(uint256 _hatId, address _wearer) external returns (bool updated);

    function renounceHat(uint256 _hatId) external;

    function transferHat(uint256 _hatId, address _from, address _to) external;

    /*//////////////////////////////////////////////////////////////
                              HATS ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function makeHatImmutable(uint256 _hatId) external;

    function changeHatDetails(uint256 _hatId, string memory _newDetails) external;

    function changeHatEligibility(uint256 _hatId, address _newEligibility) external;

    function changeHatToggle(uint256 _hatId, address _newToggle) external;

    function changeHatImageURI(uint256 _hatId, string memory _newImageURI) external;

    function changeHatMaxSupply(uint256 _hatId, uint32 _newMaxSupply) external;

    function requestLinkTopHatToTree(uint32 _topHatId, uint256 _newAdminHat) external;

    function approveLinkTopHatToTree(uint32 _topHatId, uint256 _newAdminHat) external;

    function unlinkTopHatFromTree(uint32 _topHatId) external;

    function relinkTopHatWithinTree(uint32 _topHatDomain, uint256 _newAdminHat) external;

    /*//////////////////////////////////////////////////////////////
                              VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function viewHat(uint256 _hatId)
        external
        view
        returns (
            string memory details,
            uint32 maxSupply,
            uint32 supply,
            address eligibility,
            address toggle,
            string memory imageURI,
            uint16 lastHatId,
            bool mutable_,
            bool active
        );

    function isWearerOfHat(address _user, uint256 _hatId) external view returns (bool isWearer);

    function isAdminOfHat(address _user, uint256 _hatId) external view returns (bool isAdmin);

    function isInGoodStanding(address _wearer, uint256 _hatId) external view returns (bool standing);

    function isEligible(address _wearer, uint256 _hatId) external view returns (bool eligible);

    function hatSupply(uint256 _hatId) external view returns (uint32 supply);

    function getImageURIForHat(uint256 _hatId) external view returns (string memory _uri);

    function balanceOf(address wearer, uint256 hatId) external view returns (uint256 balance);

    function uri(uint256 id) external view returns (string memory _uri);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0
// Copyright (C) 2023 Haberdasher Labs
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

pragma solidity >=0.8.13;

interface IHatsIdUtilities {
    function buildHatId(uint256 _admin, uint16 _newHat) external pure returns (uint256 id);

    function getHatLevel(uint256 _hatId) external view returns (uint32 level);

    function getLocalHatLevel(uint256 _hatId) external pure returns (uint32 level);

    function isTopHat(uint256 _hatId) external view returns (bool _topHat);

    function isLocalTopHat(uint256 _hatId) external pure returns (bool _localTopHat);

    function getAdminAtLevel(uint256 _hatId, uint32 _level) external view returns (uint256 admin);

    function getAdminAtLocalLevel(uint256 _hatId, uint32 _level) external pure returns (uint256 admin);

    function getTopHatDomain(uint256 _hatId) external view returns (uint32 domain);

    function getTippyTopHatDomain(uint32 _topHatDomain) external view returns (uint32 domain);

    function noCircularLinkage(uint32 _topHatDomain, uint256 _linkedAdmin) external view returns (bool notCircular);

    function sameTippyTopHatDomain(uint32 _topHatDomain, uint256 _newAdminHat)
        external
        view
        returns (bool sameDomain);
}

// SPDX-License-Identifier: AGPL-3.0
// Copyright (C) 2023 Haberdasher Labs
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

pragma solidity >=0.8.13;

interface HatsErrors {
    /// @notice Emitted when `user` is attempting to perform an action on `hatId` but is not wearing one of `hatId`'s admin hats
    /// @dev Can be equivalent to `NotHatWearer(buildHatId(hatId))`, such as when emitted by `approveLinkTopHatToTree` or `relinkTopHatToTree`
    error NotAdmin(address user, uint256 hatId);

    /// @notice Emitted when attempting to perform an action as or for an account that is not a wearer of a given hat
    error NotHatWearer();

    /// @notice Emitted when attempting to perform an action that requires being either an admin or wearer of a given hat
    error NotAdminOrWearer();

    /// @notice Emitted when attempting to mint `hatId` but `hatId`'s maxSupply has been reached
    error AllHatsWorn(uint256 hatId);

    /// @notice Emitted when attempting to create a hat with a level 14 hat as its admin
    error MaxLevelsReached();

    /// @notice Emitted when attempting to mint `hatId` to a `wearer` who is already wearing the hat
    error AlreadyWearingHat(address wearer, uint256 hatId);

    /// @notice Emitted when attempting to mint a non-existant hat
    error HatDoesNotExist(uint256 hatId);

    /// @notice Emitted when attempting to mint or transfer a hat to an ineligible wearer
    error NotEligible();

    /// @notice Emitted when attempting to check or set a hat's status from an account that is not that hat's toggle module
    error NotHatsToggle();

    /// @notice Emitted when attempting to check or set a hat wearer's status from an account that is not that hat's eligibility module
    error NotHatsEligibility();

    /// @notice Emitted when array arguments to a batch function have mismatching lengths
    error BatchArrayLengthMismatch();

    /// @notice Emitted when attempting to mutate or transfer an immutable hat
    error Immutable();

    /// @notice Emitted when attempting to change a hat's maxSupply to a value lower than its current supply
    error NewMaxSupplyTooLow();

    /// @notice Emitted when attempting to link a tophat to a new admin for which the tophat serves as an admin
    error CircularLinkage();

    /// @notice Emitted when attempting to link or relink a tophat to a separate tree
    error CrossTreeLinkage();

    /// @notice Emitted when attempting to link a tophat without a request
    error LinkageNotRequested();

    /// @notice Emmited when attempted to change a hat's eligibility or toggle module to the zero address
    error ZeroAddress();
}

// SPDX-License-Identifier: AGPL-3.0
// Copyright (C) 2023 Haberdasher Labs
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

pragma solidity >=0.8.13;

interface HatsEvents {
    /// @notice Emitted when a new hat is created
    /// @param id The id for the new hat
    /// @param details A description of the Hat
    /// @param maxSupply The total instances of the Hat that can be worn at once
    /// @param eligibility The address that can report on the Hat wearer's status
    /// @param toggle The address that can deactivate the Hat
    /// @param mutable_ Whether the hat's properties are changeable after creation
    /// @param imageURI The image uri for this hat and the fallback for its
    event HatCreated(
        uint256 id,
        string details,
        uint32 maxSupply,
        address eligibility,
        address toggle,
        bool mutable_,
        string imageURI
    );

    /// @notice Emitted when a hat wearer's standing is updated
    /// @dev Eligibility is excluded since the source of truth for eligibility is the eligibility module and may change without a transaction
    /// @param hatId The id of the wearer's hat
    /// @param wearer The wearer's address
    /// @param wearerStanding Whether the wearer is in good standing for the hat
    event WearerStandingChanged(uint256 hatId, address wearer, bool wearerStanding);

    /// @notice Emitted when a hat's status is updated
    /// @param hatId The id of the hat
    /// @param newStatus Whether the hat is active
    event HatStatusChanged(uint256 hatId, bool newStatus);

    /// @notice Emitted when a hat's details are updated
    /// @param hatId The id of the hat
    /// @param newDetails The updated details
    event HatDetailsChanged(uint256 hatId, string newDetails);

    /// @notice Emitted when a hat's eligibility module is updated
    /// @param hatId The id of the hat
    /// @param newEligibility The updated eligibiliy module
    event HatEligibilityChanged(uint256 hatId, address newEligibility);

    /// @notice Emitted when a hat's toggle module is updated
    /// @param hatId The id of the hat
    /// @param newToggle The updated toggle module
    event HatToggleChanged(uint256 hatId, address newToggle);

    /// @notice Emitted when a hat's mutability is updated
    /// @param hatId The id of the hat
    event HatMutabilityChanged(uint256 hatId);

    /// @notice Emitted when a hat's maximum supply is updated
    /// @param hatId The id of the hat
    /// @param newMaxSupply The updated max supply
    event HatMaxSupplyChanged(uint256 hatId, uint32 newMaxSupply);

    /// @notice Emitted when a hat's image URI is updated
    /// @param hatId The id of the hat
    /// @param newImageURI The updated image URI
    event HatImageURIChanged(uint256 hatId, string newImageURI);

    /// @notice Emitted when a tophat linkage is requested by its admin
    /// @param domain The domain of the tree tophat to link
    /// @param newAdmin The tophat's would-be admin in the parent tree
    event TopHatLinkRequested(uint32 domain, uint256 newAdmin);

    /// @notice Emitted when a tophat is linked to a another tree
    /// @param domain The domain of the newly-linked tophat
    /// @param newAdmin The tophat's new admin in the parent tree
    event TopHatLinked(uint32 domain, uint256 newAdmin);
}