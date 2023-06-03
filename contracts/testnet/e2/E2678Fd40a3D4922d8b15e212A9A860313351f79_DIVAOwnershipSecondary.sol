// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.19;

import {UsingTellor} from "./UsingTellor.sol";
import {IDIVAOwnershipSecondary} from "./interfaces/IDIVAOwnershipSecondary.sol";

/**
 * @notice Ownership contract for secondary chain which uses the Tellor oracle protocol to sync
 * the main chain owner returned by `getCurrentOwner()` function in `DIVAOwnershipMain.sol`.
 * @dev `setOwner()` function pulls the latest value that remained undisputed for more than 12 hours.
 * - Reverts with `NoOracleSubmission` if there is no value inside the Tellor smart contract that remained
 *   undisputed for more than 12 hours.
 * - Reverts with `ValueTooOld` if the last reported undisputed value is older than 36 hours.
 * 
 * Tellor reporters can verify the validity of a reported value by simulating the return value
 * of `getCurrentOwner()` on the main chain as of a block with a timestamp shortly before the
 * time of reporting using an archive node.
 *  
 * As Tellor is a permissionless system that allows anyone to report outcomes, constant
 * monitoring of value submissions is required. Incentives built into the Tellor system encourage
 * Tellor watchers to dispute inaccurate reportings. The main chain owner has a
 * natural incentive to participate as a Tellor watcher and dispute any wrong submissions.
 * In the event that an invalid submission goes unnoticed and a bad actor takes over ownership
 * on a secondary chain, the potential harm is limited. Functions such as `updateFees`,
 * `updateSettlementPeriods`, `updateFallbackDataProvider`, and `updateTreasury` have an
 * activation delay and can be revoked as soon as the rightful owner regains control. The
 * revoke functions as well as `pauseReturnCollateral` do not implement a delay and changes will
 * take immediate effect if triggered by an unauthorized account. Former will require the rightful
 * owner to trigger the updates again after regaining control. Latter will delay the possibility
 * to redeem by a maximum of 8 days, but will not interrupt the settlement process, ensuring that
 * all outstanding pools will settle correctly. The pause can be immediately reversed once the
 * rightful owner regains control.
 */
contract DIVAOwnershipSecondary is UsingTellor, IDIVAOwnershipSecondary {

    address private _owner;
    address private immutable _OWNERSHIP_CONTRACT_MAIN_CHAIN;
    uint256 private immutable _MAIN_CHAIN_ID;
    uint256 private constant _MIN_UNDISPUTED_PERIOD = 12 hours;
    uint256 private constant _MAX_ALLOWED_AGE_OF_REPORTED_VALUE = 36 hours;

    constructor(
        address _initialOwner,
        address payable _tellorAddress,
        uint256 _mainChainId,
        address _ownershipContractMainChain
    ) payable UsingTellor(_tellorAddress) {
        if (_initialOwner == address(0)) {
            revert ZeroOwnerAddress();
        }
        if (_mainChainId == 0) {
            revert ZeroMainChainId();
        }
        if (_ownershipContractMainChain == address(0)) {
            revert ZeroOwnershipContractAddress();
        }
        // Zero address check for `_tellorAddress` is done inside `UsingTellor.sol`

        _owner = _initialOwner;
        _MAIN_CHAIN_ID = _mainChainId;
        _OWNERSHIP_CONTRACT_MAIN_CHAIN = _ownershipContractMainChain;
    }
    
    function setOwner() external override {
        
        // Get reported owner address from Tellor smart contract.
        // Only values that remained undisputed for at least 12 hours and are not older
        // than 36 hours are accepted.

        // Get queryId
        (, bytes32 _queryId) = getQueryDataAndId();

        // Retrieve the latest value (encoded owner address) that remained undisputed for at least
        // 12 hours as well as the reporting timestamp
        (bytes memory _valueRetrieved, uint256 _timestampRetrieved) = 
            getDataBefore(_queryId, block.timestamp - _MIN_UNDISPUTED_PERIOD);
        
        // Check that data exists
        if (_timestampRetrieved == 0) {
            revert NoOracleSubmission();
        }

        // Check that value is not older than 36 hours
        uint256 _maxAllowedTimestampRetrieved = block.timestamp - _MAX_ALLOWED_AGE_OF_REPORTED_VALUE;
        if (_timestampRetrieved < _maxAllowedTimestampRetrieved) {
            revert ValueTooOld(_timestampRetrieved, _maxAllowedTimestampRetrieved);
        }

        // Reported owner address is expected to match the address returned by `getCurrentOwner`
        // in `DIVAOwnershipMain.sol` as of the time of reporting (`_timestampRetrieved`).
        address _formattedOwner = abi.decode(_valueRetrieved, (address));

        // Update owner to the owner returned by the Tellor protocol
        _owner = _formattedOwner;

        // Log set owner on secondary chain
        emit OwnerSet(_formattedOwner);
    }

    function getCurrentOwner() external view override returns (address) {
        return _owner;
    }

    function getOwnershipContractMainChain() external view override returns (address) {
        return _OWNERSHIP_CONTRACT_MAIN_CHAIN;
    }

    function getMainChainId() external view override returns (uint256) {
        return _MAIN_CHAIN_ID;
    }

    function getQueryDataAndId()
        public
        view
        override
        returns (
            bytes memory queryData,
            bytes32 queryId
        )
    {
        // Construct Tellor queryData and queryId:
        // https://github.com/tellor-io/dataSpecs/blob/main/types/EVMCall.md
        queryData = 
                abi.encode(
                    "EVMCall",
                    abi.encode(
                        _MAIN_CHAIN_ID,
                        _OWNERSHIP_CONTRACT_MAIN_CHAIN,
                        abi.encodeWithSignature("getCurrentOwner()")
                    )
                );

        queryId = keccak256(queryData);        
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.19;

import {IDIVAOwnershipShared} from "../interfaces/IDIVAOwnershipShared.sol";

interface IDIVAOwnershipSecondary is IDIVAOwnershipShared {
    // Thrown in constructor if zero address is provided for initial owner.
    error ZeroOwnerAddress();

    // Thrown in constructor if zero is provided as the main chain Id.
    error ZeroMainChainId();

    // Thrown in constructor if zero address is provided for ownership contract
    // on main chain.
    error ZeroOwnershipContractAddress();
    
    // Thrown in `setOwner` if Tellor reporting timestamp is older than 36 hours
    error ValueTooOld(
        uint256 _timestampRetrieved,
        uint256 _maxAllowedTimestampRetrieved
    );

    // Thrown in `setOwner` if there is no value inside the Tellor smart contract
    // that remained undisputed for more than 12 hours
    error NoOracleSubmission();

    /**
     * @notice Emitted when owner is set on the secondary chain.
     * @param owner The owner address set on the secondary chain.
     */
    event OwnerSet(address indexed owner);

    /**
     * @notice Function to update the owner on the secondary chain based on the
     * value reported to the Tellor smart contract. The reported value has to
     * satisfy the following two conditions in order to be considered valid:
     *   1. Reported value hasn't been disputed for at least 12 hours
     *   2. Timestamp of reporting is not older than 36 hours
     * @dev Reverts if:
     * - there is no value inside the Tellor smart contract that remained
     *   undisputed for more than 12 hours.
     * - the last reported undisputed value is older than 36 hours.
     */
    function setOwner() external;

    /**
     * @notice Function to return the ownership contract address on the main chain.
     * @return The ownership contract address on the main chain.
     */
    function getOwnershipContractMainChain() external view returns (address);

    /**
     * @notice Function to return the main chain id.
     * @return The main chain id.
     */
    function getMainChainId() external view returns (uint256);

    /**
     * @notice Function to return the Tellor query data and Id which are required
     * for reporting values to Tellor protocol.
     * @dev The query data is an encoded string consisting of the query type
     * string "EVMCall", the main chain Id (1 for Ethereum), the address of
     * the ownership contract on main chain as well as the encoded function signature of the main
     * chain function `getCurrentOwner()` (`0xa18a186b`). The query Id is the `keccak256`
     * hash of the query Data. Refer to the Tellor specs
     * (https://github.com/tellor-io/dataSpecs/blob/main/types/EVMCall.md)
     * for details.
     * @return The query data as a `bytes` array and the query Id as a `bytes32` value.
     */
    function getQueryDataAndId() external view returns (bytes memory, bytes32);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.19;

interface IDIVAOwnershipShared {
    /**
     * @notice Function to return the current DIVA Protocol owner address.
     * @return Current owner address. On main chain, equal to the existing owner
     * during an on-going election cycle and equal to the new owner afterwards. On secondary
     * chain, equal to the address reported via Tellor oracle.
     */
    function getCurrentOwner() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface ITellor {
    /**
     * @dev Retrieves the latest value for the queryId before the specified timestamp
     * @param _queryId is the queryId to look up the value for
     * @param _timestamp before which to search for latest value
     * @return _ifRetrieve bool true if able to retrieve a non-zero value
     * @return _value the value retrieved
     * @return _timestampRetrieved the value's timestamp
     */
    function getDataBefore(bytes32 _queryId, uint256 _timestamp)
        external
        view
        returns (
            bool _ifRetrieve,
            bytes memory _value,
            uint256 _timestampRetrieved
        );
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {ITellor} from "./interfaces/ITellor.sol";

/**
 * @title UserContract
 * This contract allows for easy integration with the Tellor System
 * by helping smart contracts to read data from Tellor
 */
contract UsingTellor {
    ITellor public tellor;

    /*Constructor*/
    /**
     * @dev the constructor sets the oracle address in storage
     * @param _tellor is the Tellor Oracle address
     */
    constructor(address payable _tellor) {
        require(_tellor != address(0), "Zero Tellor address");
        tellor = ITellor(_tellor);
    }

    /*Getters*/
    /**
     * @dev Retrieves the latest value for the queryId before the specified timestamp
     * @param _queryId is the queryId to look up the value for
     * @param _timestamp before which to search for latest value
     * @return _value the value retrieved
     * @return _timestampRetrieved the value's timestamp
     */
    function getDataBefore(bytes32 _queryId, uint256 _timestamp)
        public
        view
        returns (bytes memory _value, uint256 _timestampRetrieved)
    {
        (, _value, _timestampRetrieved) = tellor.getDataBefore(
            _queryId,
            _timestamp
        );
    }
}