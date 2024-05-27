// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import {IHinkal, Dimensions, CircomData} from "./types/IHinkal.sol";
import {IHinkalWrapper} from "./types/IHinkalWrapper.sol";

/**
 * @title HinkalWrapper
 * @notice This contract is used to wrap Hinkal.transact call and pass sender address to target contract
 */
contract HinkalWrapper is IHinkalWrapper {
    IHinkal internal immutable hinkal;
    address public sender;

    constructor(address _hinkal) {
        hinkal = IHinkal(_hinkal);
    }

    function transact(
        uint256[2] calldata a,
        uint256[2][2] calldata b,
        uint256[2] calldata c,
        Dimensions calldata dimensions,
        CircomData calldata circomData
    ) external {
        sender = msg.sender;
        hinkal.transactWithExternalAction(a, b, c, dimensions, circomData);
        sender = address(0);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.6;

import "./StealthAddressStructure.sol";

uint256 constant CIRCOM_P = 21888242871839275222246405745257275088548364400416034343698204186575808495617; // https://docs.circom.io/circom-language/basic-operators/

struct CircomData {
    uint256 rootHashHinkal;
    address[] erc20TokenAddresses;
    uint256[] tokenIds;
    int256[] amountChanges;
    uint256[][] inputNullifiers;
    uint256[][] outCommitments;
    bytes[][] encryptedOutputs;
    uint256[] flatFees;
    uint256 timeStamp;
    StealthAddressStructure stealthAddressStructure;
    uint256 rootHashAccessToken;
    uint256 calldataHash;
    uint16 publicSignalCount;
    address relay;
    address externalAddress;
    uint256 externalActionId;
    bytes externalActionMetadata;
    HookData hookData;
}

struct HookData {
    address preHookContract;
    address hookContract;
    bytes preHookMetadata;
    bytes postHookMetadata;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.6;

struct Dimensions {
    uint16 tokenNumber;
    uint16 nullifierAmount;
    uint16 outputAmount;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.6;

import "../types/Dimensions.sol";
import "../types/CircomData.sol";

interface IHinkal {
    event ExternalActionRegistered(address externalActionAddress);

    event ExternalActionRemoved(address externalActionAddress);

    struct ConstructorArgs {
        uint256 levels;
        address poseidon;
        address accessTokenAddress;
        address circomDataBuilderAddress;
        address erc20TokenRegistryAddress;
        address relayStoreAddress;
    }

    function transact(
        uint256[2] calldata a,
        uint256[2][2] calldata b,
        uint256[2] calldata c,
        Dimensions calldata dimensions,
        CircomData calldata circomData
    ) external payable;

    function transactWithExternalAction(
        uint256[2] calldata a,
        uint256[2][2] calldata b,
        uint256[2] calldata c,
        Dimensions calldata dimensions,
        CircomData calldata circomData
    ) external payable;

    function transactWithHook(
        uint256[2] calldata a,
        uint256[2][2] calldata b,
        uint256[2] calldata c,
        Dimensions calldata dimensions,
        CircomData calldata circomData
    ) external payable;

    function transactWithExternalActionAndHook(
        uint256[2] calldata a,
        uint256[2][2] calldata b,
        uint256[2] calldata c,
        Dimensions calldata dimensions,
        CircomData calldata circomData
    ) external payable;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

interface IHinkalWrapper {
    function sender() external view returns (address);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.6;

struct StealthAddressStructure {
    uint256 extraRandomization;
    uint256 stealthAddress;
    uint256 H0;
    uint256 H1;
}