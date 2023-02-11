// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.18;
import "./shared/Structs.sol";

struct AppStorage {
    // Re-entrancy guard for functions that make external calls
    uint8 _status;
    uint256 latestRequestId;
    // Protocol addresses
    address sequencer;
    address proposedSequencer;
    address treasury;
    address[] beacons;
    // Reserve uint space for additional future config kv stores
    uint256[48] configUints;
    uint256[16] gasEstimates;
    // Client Deposits & Reserved Amounts
    mapping(address client => uint256 value) ethDeposit;
    mapping(address client => uint256 reserved) ethReserved;
    // Beacon Stores
    mapping(address beacon => uint256 index) beaconIndex;
    mapping(address beacon => Beacon data) beacon;
    // Request Stores
    mapping(uint256 id => bytes32 result) results;
    mapping(uint256 id => bytes32 dataHash) requestToHash; // The hash of the request data
    mapping(uint256 id => bytes10[2] vrfHashes) requestToVrfHashes; // The submitted hashes from beacons
    mapping(uint256 id => uint256 feePaid) requestToFeePaid;
    mapping(uint256 id => uint256 feeRefunded) requestToFeeRefunded;
    // Collateral
    mapping(address beacon => uint256 value) ethCollateral;
}

// SPDX-License-Identifier: BUSL-1.1
/// @title Randomizer Client Service
/// @author Dean van Dugteren (https://github.com/deanpress)
/// @notice Randomizer client contract management functions (deposits/withdrawals and fee estimates)

pragma solidity ^0.8.18;
import {LibDiamond} from "../libraries/LibDiamond.sol";
import "../AppStorage.sol";
import "../libraries/Constants.sol";
import "../libraries/Events.sol";
import "../shared/Utils.sol";
import "../libraries/LibBeacon.sol";
import "../libraries/LibNetwork.sol";

contract ClientFacet is Utils {
    /* Errors */

    /// @dev Error thrown when the client attempts to withdraw more than they have deposited
    /// @param amount The amount the client is trying to withdraw
    /// @param allowedAmount The amount the client is allowed to withdraw
    error WithdrawingTooMuch(uint256 amount, uint256 allowedAmount);

    /// @dev Error thrown when the request's callback gas limit is out of bounds
    /// @param inputLimit The callback gas limit input by the client
    /// @param minLimit The minimum allowed callback gas limit
    /// @param maxLimit The maximum allowed callback gas limit
    error CallbackGasLimitOOB(uint256 inputLimit, uint256 minLimit, uint256 maxLimit);

    /// @dev Error thrown when the request's min confirmations are out of bounds
    /// @param inputLimit The confirmations input by the client
    /// @param minLimit The minimum allowed confirmations
    /// @param maxLimit The maximum allowed confirmations
    error ConfirmationsOOB(uint256 inputLimit, uint256 minLimit, uint256 maxLimit);

    /// @dev Error thrown when the client attempts to make a request with an ETH deposit that is too low
    /// @param deposited The amount of ETH the client has deposited
    /// @param reserved The amount of ETH the client has reserved for requests
    /// @param requiredAmount The amount of ETH the client needs to deposit to fulfill a new request
    error EthDepositTooLow(uint256 deposited, uint256 reserved, uint256 requiredAmount);

    /* Events */

    /// @dev Event emitted when a client withdraws ETH to a specified address
    /// @param client The address of the client withdrawing ETH
    /// @param to The address the client is withdrawing ETH to
    /// @param amount The amount of ETH the client is withdrawing
    event ClientWithdrawTo(address indexed client, address indexed to, uint256 amount);

    /* Functions */

    /// @notice Gets the ETH balance and amount reserved of the client contract (used for paying for requests)
    /// @dev Reserved amounts are based on gas estimatations per request so clients can't make more requests than their deposit can fund
    /// @param _client The address of the client contract to check
    /// @return deposit The amount of ETH the client has deposited
    /// @return reserved The amount of ETH that Randomizer has reserved for requests
    function clientBalanceOf(address _client) external view returns (uint256 deposit, uint256 reserved) {
        return (s.ethDeposit[_client], s.ethReserved[_client]);
    }

    /// @notice Deposits ETH for the client contract
    /// @param _client The address of the client contract to deposit ETH to
    function clientDeposit(address _client) external payable {
        s.ethDeposit[_client] += msg.value;
        emit Events.ClientDepositEth(_client, msg.value);
    }

    /// @notice Withdraws client ETH to the specified receiver (_to)
    /// @dev Your contract MUST be able to call this function to withdraw previously deposited funds
    /// You can use this for refunding ETH if user paid for request.
    /// @param _to The address to withdraw ETH to
    /// @param _amount The amount of ETH to withdraw
    function clientWithdrawTo(address _to, uint256 _amount) external {
        // Check if the client is trying to withdraw more than they have deposited
        if (_amount > s.ethDeposit[msg.sender] - s.ethReserved[msg.sender])
            revert WithdrawingTooMuch(_amount, s.ethDeposit[msg.sender] - s.ethReserved[msg.sender]);

        // Decrease the client's deposit by the amount they are withdrawing
        s.ethDeposit[msg.sender] -= _amount;

        // Emit an event to log the withdrawal
        emit ClientWithdrawTo(msg.sender, _to, _amount);

        // Transfer the specified amount of ETH to the specified address
        _transferEth(_to, _amount);
    }

    /// @notice Gets fee estimate for full request fulfillment
    /// @param _callbackGasLimit The gas limit for the client's callback function
    /// @param _confirmations The number of blocks to wait for a result for finality
    /// @return esimateFee The estimated fee required for full request fulfillment
    function estimateFee(uint256 _callbackGasLimit, uint256 _confirmations)
        public
        view
        returns (uint256 esimateFee)
    {
        return
            ((s.gasEstimates[Constants.GKEY_TOTAL_SUBMIT] +
                _callbackGasLimit +
                ((s.gasEstimates[Constants.GKEY_GAS_PER_BEACON_SELECT] * (s.beacons.length - 1)) * 3)) *
                LibNetwork._maxGasPriceAfterConfirmations(_confirmations)) +
            (s.configUints[Constants.CKEY_BEACON_FEE] * 5);
    }

    /// @notice Gets fee estimate for full request fulfillment
    /// @param _callbackGasLimit The gas limit for the client's callback function
    /// @return esimateFee The estimated fee required for full request fulfillment
    function estimateFee(uint256 _callbackGasLimit) public view returns (uint256 esimateFee) {
        return
            ((s.gasEstimates[Constants.GKEY_TOTAL_SUBMIT] +
                _callbackGasLimit +
                ((s.gasEstimates[Constants.GKEY_GAS_PER_BEACON_SELECT] * (s.beacons.length - 1)) * 3)) *
                LibNetwork._gasPrice()) + (s.configUints[Constants.CKEY_BEACON_FEE] * 5);
    }

    /// @notice Gets fee estimate for full request fulfillment using confirmations and a manual gas price
    /// @param _callbackGasLimit The gas limit for the client's callback function
    /// @param _confirmations The number of blocks to wait for a result for finality
    /// @param _gasPrice The gas price used for request fulfillment
    /// @return esimateFee The estimated fee required for full request fulfillment
    /// @dev If your users pay for random requests, use this in your contract to calculate how much ETH a user should attach.
    function estimateFeeUsingConfirmationsAndGasPrice(
        uint256 _callbackGasLimit,
        uint256 _confirmations,
        uint256 _gasPrice
    ) external view returns (uint256) {
        return
            ((s.gasEstimates[Constants.GKEY_TOTAL_SUBMIT] +
                _callbackGasLimit +
                ((s.gasEstimates[Constants.GKEY_GAS_PER_BEACON_SELECT] * (s.beacons.length - 1)) * 3)) *
                LibNetwork._maxGasPriceAfterConfirmations(_gasPrice, _confirmations)) +
            (s.configUints[Constants.CKEY_BEACON_FEE] * 5);
    }

    /// @notice Gets fee estimate for full request fulfillment using a manual gas price
    /// @param _callbackGasLimit The gas limit for the client's callback function
    /// @param _gasPrice The gas price used for request fulfillment
    /// @return esimateFee The estimated fee required for full request fulfillment
    /// @dev If your users pay for random requests, use this in your contract to calculate how much ETH a user should attach.
    function estimateFeeUsingGasPrice(uint256 _callbackGasLimit, uint256 _gasPrice)
        external
        view
        returns (uint256)
    {
        return
            ((s.gasEstimates[Constants.GKEY_TOTAL_SUBMIT] +
                _callbackGasLimit +
                ((s.gasEstimates[Constants.GKEY_GAS_PER_BEACON_SELECT] * (s.beacons.length - 1)) * 3)) *
                _gasPrice) + (s.configUints[Constants.CKEY_BEACON_FEE] * 5);
    }

    /// @notice Requests a callback with a random value from the Randomizer protocol
    /// @param _callbackGasLimit The gas limit for the callback function of the request
    /// @return id The request ID
    function request(uint256 _callbackGasLimit) external returns (uint256 id) {
        return _request(_callbackGasLimit, s.configUints[Constants.CKEY_MIN_CONFIRMATIONS]);
    }

    function request(uint256 _callbackGasLimit, uint256 _confirmations) external returns (uint256 id) {
        if (
            _confirmations > s.configUints[Constants.CKEY_MAX_CONFIRMATIONS] ||
            _confirmations < s.configUints[Constants.CKEY_MIN_CONFIRMATIONS]
        )
            revert ConfirmationsOOB(
                _confirmations,
                s.configUints[Constants.CKEY_MIN_CONFIRMATIONS],
                s.configUints[Constants.CKEY_MAX_CONFIRMATIONS]
            );

        return _request(_callbackGasLimit, _confirmations);
    }

    function _request(uint256 _callbackGasLimit, uint256 _confirmations) private returns (uint256 id) {
        // Check if the callback gas limit is within the allowed range
        uint256 requestMinGasLimit = s.configUints[Constants.CKEY_REQUEST_MIN_GAS_LIMIT];
        uint256 requestMaxGasLimit = s.configUints[Constants.CKEY_REQUEST_MAX_GAS_LIMIT];
        if (_callbackGasLimit < requestMinGasLimit || _callbackGasLimit > requestMaxGasLimit)
            revert CallbackGasLimitOOB(_callbackGasLimit, requestMinGasLimit, requestMaxGasLimit);

        // Calculate the estimated fee for the request
        uint256 _estimateFee = estimateFee(_callbackGasLimit, _confirmations);

        // Check if the client has enough ETH deposited to cover the estimated fee
        if (
            s.ethDeposit[msg.sender] < s.ethReserved[msg.sender] ||
            _estimateFee > (s.ethDeposit[msg.sender] - s.ethReserved[msg.sender])
        ) revert EthDepositTooLow(s.ethDeposit[msg.sender], s.ethReserved[msg.sender], _estimateFee);

        // Increase the client's reserved ETH by the estimated fee
        s.ethReserved[msg.sender] += _estimateFee;

        // Increment the latest request ID and store it in the `id` variable
        s.latestRequestId++;
        id = s.latestRequestId;

        // Create a data structure to store the request data
        SRandomUintData memory data = SRandomUintData({
            ethReserved: _estimateFee,
            beaconFee: s.configUints[Constants.CKEY_BEACON_FEE],
            height: LibNetwork._blockNumber(),
            timestamp: block.timestamp,
            expirationBlocks: s.configUints[Constants.CKEY_EXPIRATION_BLOCKS],
            expirationSeconds: s.configUints[Constants.CKEY_EXPIRATION_SECONDS],
            callbackGasLimit: _callbackGasLimit,
            minConfirmations: _confirmations
        });

        // Generate the request using the request data
        _generateRequest(id, msg.sender, data);

        return id;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

interface IDiamondCut {
    enum FacetCutAction {
        Add,
        Replace,
        Remove
    }
    // Add=0, Replace=1, Remove=2

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external;

    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

library Constants {
    // Config keys for configUints
    uint256 constant CKEY_MIN_STAKE_ETH = 0;
    uint256 constant CKEY_EXPIRATION_BLOCKS = 1;
    uint256 constant CKEY_EXPIRATION_SECONDS = 2;
    uint256 constant CKEY_REQUEST_MIN_GAS_LIMIT = 3;
    uint256 constant CKEY_REQUEST_MAX_GAS_LIMIT = 4;
    uint256 constant CKEY_BEACON_FEE = 5;
    uint256 constant CKEY_MAX_STRIKES = 6;
    uint256 constant CKEY_MAX_CONSECUTIVE_SUBMISSIONS = 7;
    uint256 constant CKEY_MIN_CONFIRMATIONS = 8;
    uint256 constant CKEY_MAX_CONFIRMATIONS = 9;

    // Gas keys for estimateGas
    uint256 constant GKEY_OFFSET_SUBMIT = 0;
    uint256 constant GKEY_OFFSET_FINAL_SUBMIT = 1;
    uint256 constant GKEY_OFFSET_RENEW = 2;
    uint256 constant GKEY_TOTAL_SUBMIT = 3;
    uint256 constant GKEY_GAS_PER_BEACON_SELECT = 4;

    // Re-entrancy statuses
    uint8 constant STATUS_NOT_ENTERED = 1;
    uint8 constant STATUS_ENTERED = 2;

    // ChargeEth event types
    uint8 constant CHARGE_TYPE_CLIENT_TO_BEACON = 0;
    uint8 constant CHARGE_TYPE_BEACON_TO_CLIENT = 1;
    uint8 constant CHARGE_TYPE_BEACON_TO_BEACON = 2;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

// Events that are shared across Randomizer facets
import "../shared/Structs.sol";

library Events {
    /// @notice Emits when ETH is charged between accounts
    /// @param chargeType 0: client to beacon, 1: beacon to client, 2: beacon to beacon
    /// @param from address of the sender
    /// @param to address of the recipient
    /// @param amount amount of ETH charged
    event ChargeEth(address indexed from, address indexed to, uint256 amount, uint8 chargeType);
    /// @notice Emits when a client deposits ETH
    /// @param account address of the client
    /// @param amount amount of ETH deposited
    event ClientDepositEth(address indexed account, uint256 amount);
    /// @notice Emits when a beacon stakes ETH
    /// @param account address of the beacon
    /// @param amount amount of ETH deposited
    event BeaconDepositEth(address indexed account, uint256 amount);
    /// @notice Emits when a beacon is unregistered
    /// @param beacon address of the unregistered beacon
    /// @param kicked boolean indicating if the beacon was kicked or voluntarily unregistered
    /// @param strikes number of strikes the beacon had before being unregistered
    event UnregisterBeacon(address indexed beacon, bool indexed kicked, uint8 strikes);
    /// @notice Emits when a final beacon is selected for a request
    /// @param id request id
    /// @param beacon address of the beacon added
    /// @param seed seed used for the random value generation
    /// @param timestamp new timestamp of the request
    event RequestBeacon(uint256 indexed id, address indexed beacon, bytes32 seed, uint256 timestamp);
    /// @notice Emits an event with the final random value
    /// @param id request id
    /// @param result result value
    event Result(uint256 indexed id, bytes32 result);
    /// @notice Emits when ETH is withdrawn
    /// @param to address of the recipient
    /// @param amount amount of ETH withdrawn
    event WithdrawEth(address indexed to, uint256 amount);
    /// @notice Emits if a request is retried (has new beacons)
    /// @param id request id
    /// @param request SRequestEventData struct containing request data
    /// @param chargedBeacon address of the beacon that was charged
    /// @param renewer address of the renewer
    /// @param ethToClient amount of ETH returned to the client
    /// @param ethToRenewer amount of ETH returned to the caller
    event Retry(
        uint256 indexed id,
        SRequestEventData request,
        address indexed chargedBeacon,
        address indexed renewer,
        uint256 ethToClient,
        uint256 ethToRenewer
    );
    /// @notice Emits when the sequencer is transferred from one address to another
    /// @param previousSequencer address of the previous sequencer
    /// @param newSequencer address of the new sequencer
    event TransferSequencer(address indexed previousSequencer, address indexed newSequencer);
    /// @notice Emits when the treasury address is set
    /// @param previousTreasury address of the previous treasury
    /// @param newTreasury address of the new treasury
    event SetTreasury(address indexed previousTreasury, address indexed newTreasury);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

import "../AppStorage.sol";
import "../libraries/LibNetwork.sol";
import "../shared/Structs.sol";

interface IRandomReceiver {
    /// @notice Callback function that is called when a random value is generated
    /// @param _id request id
    /// @param value generated random value
    function randomizerCallback(uint256 _id, bytes32 value) external;
}

library LibBeacon {
    /// @notice Emits when the callback function fails
    /// @param client address of the client that requested the random value
    /// @param id request id
    /// @param result generated random value
    /// @param txData data of the callback transaction
    event CallbackFailed(address indexed client, uint256 indexed id, bytes32 result, bytes txData);

    /// @notice Hashes the request data for validation
    /// @param id request id
    /// @param accounts struct containing client and beacon addresses
    /// @param data struct containing request data
    /// @param seed seed for the random value generation
    /// @return bytes32 hash of the request data
    function _generateRequestHash(
        uint256 id,
        SAccounts memory accounts,
        SRandomUintData memory data,
        bytes32 seed
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    id,
                    seed,
                    accounts.client,
                    accounts.beacons,
                    data.ethReserved,
                    data.beaconFee,
                    [data.height, data.timestamp],
                    data.expirationBlocks,
                    data.expirationSeconds,
                    data.callbackGasLimit,
                    data.minConfirmations
                )
            );
    }

    /// @notice Calculates the fee charge for the request
    /// @param gasAtStart gas used at the start of the function call
    /// @param _beaconFee beacon fee
    /// @param offset gas offset
    /// @return uint256 fee to be charged
    function _getFeeCharge(
        uint256 gasAtStart,
        uint256 _beaconFee,
        uint256 offset
    ) internal view returns (uint256) {
        return _beaconFee + (LibNetwork._gasPrice() * (gasAtStart + offset - gasleft()));
    }

    /// @notice Unpacks the address and request data from calldata
    /// @param _accounts address array containing client and beacon addresses
    /// @param _data uint256 array containing request data
    /// @return SAccounts struct and SPackedSubmitData struct
    function _getAccountsAndPackedData(address[4] calldata _accounts, uint256[19] calldata _data)
        internal
        pure
        returns (SAccounts memory, SPackedSubmitData memory)
    {
        return (_resolveAddressCalldata(_accounts), _resolveUintVrfData(_data));
    }

    /// @notice Unpacks the address data from calldata
    /// @param _data address array containing client and beacon addresses
    /// @return SAccounts struct
    function _resolveAddressCalldata(address[4] calldata _data) internal pure returns (SAccounts memory) {
        return SAccounts(_data[0], [_data[1], _data[2], _data[3]]);
    }

    /// @notice Unpacks the packed request and VRF data from calldata
    /// @param _data uint256 array containing packed request data
    /// @return SPackedSubmitData struct
    function _resolveUintVrfData(uint256[19] calldata _data)
        internal
        pure
        returns (SPackedSubmitData memory)
    {
        return
            SPackedSubmitData(
                uint256(_data[0]),
                SRandomUintData(
                    _data[1],
                    _data[2],
                    _data[3],
                    _data[4],
                    _data[5],
                    _data[6],
                    _data[7],
                    _data[8]
                ),
                SFastVerifyData(
                    [_data[9], _data[10], _data[11], _data[12]],
                    [_data[13], _data[14]],
                    [_data[15], _data[16], _data[17], _data[18]]
                )
            );
    }

    /// @notice Unpacks the request data from calldata
    /// @param _data uint256 array containing request data
    /// @return SPackedUintData struct
    function _resolveUintData(uint256[9] calldata _data) internal pure returns (SPackedUintData memory) {
        return
            SPackedUintData(
                uint256(_data[0]),
                SRandomUintData(
                    _data[1],
                    _data[2],
                    _data[3],
                    _data[4],
                    _data[5],
                    _data[6],
                    _data[7],
                    _data[8]
                )
            );
    }

    /// @notice Calls the callback function on the client contract
    /// @param _to address of the client contract
    /// @param _gasLimit gas limit for the callback transaction
    /// @param _id request id
    /// @param _result generated random value
    function _callback(
        address _to,
        uint256 _gasLimit,
        uint256 _id,
        bytes32 _result
    ) internal {
        // Call the `randomizerCallback` function on the specified contract address with the given parameters
        (bool success, bytes memory callbackTxData) = _to.call{gas: _gasLimit}(
            abi.encodeWithSelector(IRandomReceiver.randomizerCallback.selector, _id, _result)
        );

        // If the call to `randomizerCallback` failed, emit a CallbackFailed event
        if (!success) emit CallbackFailed(_to, _id, _result, callbackTxData);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/
import {IDiamondCut} from "../interfaces/IDiamondCut.sol";

// Remember to add the loupe functions from DiamondLoupeFacet to the diamond.
// The loupe functions are required by the EIP2535 Diamonds standard

error InitializationFunctionReverted(address _initializationContractAddress, bytes _calldata);

library LibDiamond {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");

    struct FacetAddressAndPosition {
        address facetAddress;
        uint96 functionSelectorPosition; // position in facetFunctionSelectors.functionSelectors array
    }

    struct FacetFunctionSelectors {
        bytes4[] functionSelectors;
        uint256 facetAddressPosition; // position of facetAddress in facetAddresses array
    }

    struct DiamondStorage {
        // maps function selector to the facet address and
        // the position of the selector in the facetFunctionSelectors.selectors array
        mapping(bytes4 => FacetAddressAndPosition) selectorToFacetAndPosition;
        // maps facet addresses to function selectors
        mapping(address => FacetFunctionSelectors) facetFunctionSelectors;
        // facet addresses
        address[] facetAddresses;
        // Used to query if a contract implements an interface.
        // Used to implement ERC-165.
        mapping(bytes4 => bool) supportedInterfaces;
        // Owner of the contract
        address contractOwner;
        // Proposed owner of the contract
        address proposedOwner;
    }

    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event OwnershipProposed(address indexed previousOwner, address indexed newOwner);
    event ProposeOwnershipCanceled(address indexed proposedOwner, address indexed currentOwner);

    function setContractOwner(address _newOwner) internal {
        DiamondStorage storage ds = diamondStorage();
        address previousOwner = ds.contractOwner;
        ds.contractOwner = _newOwner;
        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    function setProposedContractOwner(address _proposedOwner) internal {
        DiamondStorage storage ds = diamondStorage();
        ds.proposedOwner = _proposedOwner;
        emit OwnershipProposed(ds.contractOwner, _proposedOwner);
    }

    function acceptProposedContractOwner() internal {
        DiamondStorage storage ds = diamondStorage();
        address previousOwner = ds.contractOwner;
        ds.contractOwner = ds.proposedOwner;
        ds.proposedOwner = address(0);
        emit OwnershipTransferred(previousOwner, ds.contractOwner);
    }

    function cancelProposedContractOwner() internal {
        DiamondStorage storage ds = diamondStorage();
        address previousProposedOwner = ds.proposedOwner;
        ds.proposedOwner = address(0);
        emit ProposeOwnershipCanceled(previousProposedOwner, ds.contractOwner);
    }

    function contractOwner() internal view returns (address contractOwner_) {
        contractOwner_ = diamondStorage().contractOwner;
    }

    function proposedOwner() internal view returns (address contractOwner_) {
        contractOwner_ = diamondStorage().proposedOwner;
    }

    function enforceIsContractOwner() internal view {
        require(msg.sender == diamondStorage().contractOwner, "Unauthorized: Must be contract owner");
    }

    function enforceIsProposedContractOwner() internal view {
        require(
            msg.sender == diamondStorage().proposedOwner,
            "Unauthorized: Must be proposed contract owner"
        );
    }

    function enforceIsCurrentOrProposedContractOwner() internal view {
        require(
            msg.sender == diamondStorage().contractOwner || msg.sender == diamondStorage().proposedOwner,
            "Unauthorized: Must be current or proposed contract owner"
        );
    }

    event DiamondCut(IDiamondCut.FacetCut[] _diamondCut, address _init, bytes _calldata);

    // Internal function version of diamondCut
    function diamondCut(
        IDiamondCut.FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) internal {
        for (uint256 facetIndex; facetIndex < _diamondCut.length; facetIndex++) {
            IDiamondCut.FacetCutAction action = _diamondCut[facetIndex].action;
            if (action == IDiamondCut.FacetCutAction.Add) {
                addFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else if (action == IDiamondCut.FacetCutAction.Replace) {
                replaceFunctions(
                    _diamondCut[facetIndex].facetAddress,
                    _diamondCut[facetIndex].functionSelectors
                );
            } else if (action == IDiamondCut.FacetCutAction.Remove) {
                removeFunctions(
                    _diamondCut[facetIndex].facetAddress,
                    _diamondCut[facetIndex].functionSelectors
                );
            } else {
                revert("LibDiamondCut: Incorrect FacetCutAction");
            }
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    function addFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        require(_facetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
        uint96 selectorPosition = uint96(ds.facetFunctionSelectors[_facetAddress].functionSelectors.length);
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            require(oldFacetAddress == address(0), "LibDiamondCut: Can't add function that already exists");
            addFunction(ds, selector, selectorPosition, _facetAddress);
            selectorPosition++;
        }
    }

    function replaceFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        require(_facetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
        uint96 selectorPosition = uint96(ds.facetFunctionSelectors[_facetAddress].functionSelectors.length);
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            require(
                oldFacetAddress != _facetAddress,
                "LibDiamondCut: Can't replace function with same function"
            );
            removeFunction(ds, oldFacetAddress, selector);
            addFunction(ds, selector, selectorPosition, _facetAddress);
            selectorPosition++;
        }
    }

    function removeFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        // if function does not exist then do nothing and return
        require(_facetAddress == address(0), "LibDiamondCut: Remove facet address must be address(0)");
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            removeFunction(ds, oldFacetAddress, selector);
        }
    }

    function addFacet(DiamondStorage storage ds, address _facetAddress) internal {
        enforceHasContractCode(_facetAddress, "LibDiamondCut: New facet has no code");
        ds.facetFunctionSelectors[_facetAddress].facetAddressPosition = ds.facetAddresses.length;
        ds.facetAddresses.push(_facetAddress);
    }

    function addFunction(
        DiamondStorage storage ds,
        bytes4 _selector,
        uint96 _selectorPosition,
        address _facetAddress
    ) internal {
        ds.selectorToFacetAndPosition[_selector].functionSelectorPosition = _selectorPosition;
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.push(_selector);
        ds.selectorToFacetAndPosition[_selector].facetAddress = _facetAddress;
    }

    function removeFunction(
        DiamondStorage storage ds,
        address _facetAddress,
        bytes4 _selector
    ) internal {
        require(_facetAddress != address(0), "LibDiamondCut: Can't remove function that doesn't exist");
        // an immutable function is a function defined directly in a diamond
        require(_facetAddress != address(this), "LibDiamondCut: Can't remove immutable function");
        // replace selector with last selector, then delete last selector
        uint256 selectorPosition = ds.selectorToFacetAndPosition[_selector].functionSelectorPosition;
        uint256 lastSelectorPosition = ds.facetFunctionSelectors[_facetAddress].functionSelectors.length - 1;
        // if not the same then replace _selector with lastSelector
        if (selectorPosition != lastSelectorPosition) {
            bytes4 lastSelector = ds.facetFunctionSelectors[_facetAddress].functionSelectors[
                lastSelectorPosition
            ];
            ds.facetFunctionSelectors[_facetAddress].functionSelectors[selectorPosition] = lastSelector;
            ds.selectorToFacetAndPosition[lastSelector].functionSelectorPosition = uint96(selectorPosition);
        }
        // delete the last selector
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.pop();
        delete ds.selectorToFacetAndPosition[_selector];

        // if no more selectors for facet address then delete the facet address
        if (lastSelectorPosition == 0) {
            // replace facet address with last facet address and delete last facet address
            uint256 lastFacetAddressPosition = ds.facetAddresses.length - 1;
            uint256 facetAddressPosition = ds.facetFunctionSelectors[_facetAddress].facetAddressPosition;
            if (facetAddressPosition != lastFacetAddressPosition) {
                address lastFacetAddress = ds.facetAddresses[lastFacetAddressPosition];
                ds.facetAddresses[facetAddressPosition] = lastFacetAddress;
                ds.facetFunctionSelectors[lastFacetAddress].facetAddressPosition = facetAddressPosition;
            }
            ds.facetAddresses.pop();
            delete ds.facetFunctionSelectors[_facetAddress].facetAddressPosition;
        }
    }

    function initializeDiamondCut(address _init, bytes memory _calldata) internal {
        if (_init == address(0)) {
            return;
        }
        enforceHasContractCode(_init, "LibDiamondCut: _init address has no code");
        (bool success, bytes memory error) = _init.delegatecall(_calldata);
        if (!success) {
            if (error.length > 0) {
                // bubble up error
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(error)
                    revert(add(32, error), returndata_size)
                }
            } else {
                revert InitializationFunctionReverted(_init, _calldata);
            }
        }
    }

    function enforceHasContractCode(address _contract, string memory _errorMessage) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize > 0, _errorMessage);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

interface ArbSys {
    function arbBlockNumber() external view returns (uint256);

    function arbBlockHash(uint256 arbBlockNum) external view returns (bytes32);
}

interface ArbGasInfo {
    function getMinimumGasPrice() external view returns (uint256);
}

library LibNetwork {
    function _seed(uint256 id) internal view returns (bytes32) {
        uint256 blockNum = _blockNumber();
        return
            keccak256(
                abi.encode(
                    address(this),
                    id,
                    block.prevrandao,
                    _blockHash(blockNum - 1),
                    blockNum,
                    block.timestamp,
                    block.chainid
                )
            );
    }

    function _maxGasPriceAfterConfirmations(uint256 _confirmations)
        internal
        view
        returns (uint256 maxGasPrice)
    {
        uint256 minPrice = ArbGasInfo(address(108)).getMinimumGasPrice();
        uint256 maxFee = minPrice + (minPrice / 4) + 1;
        maxGasPrice = tx.gasprice < maxFee ? tx.gasprice : maxFee;
        // maxFee can go up by 12.5% per confirmation, calculate the max fee for the number of confirmations
        if (_confirmations > 1) {
            uint256 i = 0;
            do {
                maxGasPrice += (maxGasPrice / 8) + 1;
                unchecked {
                    ++i;
                }
            } while (i < _confirmations);
        }
    }

    function _maxGasPriceAfterConfirmations(uint256 _price, uint256 _confirmations)
        internal
        pure
        returns (uint256 maxGasPrice)
    {
        maxGasPrice = _price + (_price / 4) + 1;
        // maxFee goes up by 12.5% per confirmation, calculate the max fee for the number of confirmations
        if (_confirmations > 1) {
            uint256 i = 0;
            do {
                maxGasPrice += (maxGasPrice / 8) + 1;
                unchecked {
                    ++i;
                }
            } while (i < _confirmations);
        }
    }

    function _gasPrice() internal view returns (uint256) {
        uint256 minPrice = ArbGasInfo(address(108)).getMinimumGasPrice();
        uint256 maxFee = minPrice + (minPrice / 4) + 1;
        return tx.gasprice < maxFee ? tx.gasprice : maxFee;
    }

    function _blockHash(uint256 blockNumber) internal view returns (bytes32) {
        return ArbSys(address(100)).arbBlockHash(blockNumber);
    }

    function _blockNumber() internal view returns (uint256) {
        return ArbSys(address(100)).arbBlockNumber();
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

struct SPackedSubmitData {
    uint256 id;
    SRandomUintData data;
    SFastVerifyData vrf;
}

// publicKey: [pubKey-x, pubKey-y]
// proof: [gamma-x, gamma-y, c, s]
// uPoint: [uPointX, uPointY]
// vComponents: [sHX, sHY, cGammaX, cGammaY]
struct SFastVerifyData {
    uint256[4] proof;
    uint256[2] uPoint;
    uint256[4] vComponents;
}

struct SPackedUintData {
    uint256 id;
    SRandomUintData data;
}

struct SRandomUintData {
    uint256 ethReserved;
    uint256 beaconFee;
    uint256 height;
    uint256 timestamp;
    uint256 expirationBlocks;
    uint256 expirationSeconds;
    uint256 callbackGasLimit;
    uint256 minConfirmations;
}

struct SRequestEventData {
    uint256 ethReserved;
    uint256 beaconFee;
    uint256 timestamp;
    uint256 expirationBlocks;
    uint256 expirationSeconds;
    uint256 callbackGasLimit;
    uint256 minConfirmations;
    address client;
    address[3] beacons;
    bytes32 seed;
}

struct SAccounts {
    address client;
    address[3] beacons;
}

struct Beacon {
    uint256[2] publicKey;
    bool registered;
    uint8 strikes;
    uint8 consecutiveSubmissions;
    uint64 pending;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

import "../AppStorage.sol";
import "../libraries/LibNetwork.sol";
import "../libraries/Constants.sol";
import "../libraries/LibBeacon.sol";
import "../libraries/Events.sol";
import {LibDiamond} from "../libraries/LibDiamond.sol";

contract Utils {
    AppStorage internal s;

    // Errors
    error BeaconNotFound();
    error NotEnoughBeaconsAvailable(uint256 availableBeacons, uint256 requiredBeacons);
    error ReentrancyGuard();
    error FailedToSendEth(address to, uint256 amount);
    error RequestDataMismatch(bytes32 givenHash, bytes32 expectedHash);
    error RequestNotFound(uint256 id);

    /// @notice Emits an event on a new request that contains all data needed for a beacon to process it
    /// @param request request data
    event Request(uint256 indexed id, SRequestEventData request);

    /// @dev Removes a beacon from the list of beacons
    function _removeBeacon(address _beacon) internal {
        uint256 index = s.beaconIndex[_beacon];
        if (index == 0) revert BeaconNotFound();
        uint256 lastBeaconIndex = s.beacons.length - 1;
        s.beacon[_beacon].registered = false;
        if (index == lastBeaconIndex) {
            s.beaconIndex[_beacon] = 0;
            s.beacons.pop();
            return;
        }
        s.beacons[index] = s.beacons[lastBeaconIndex];
        address newBeacon = s.beacons[lastBeaconIndex];
        s.beaconIndex[_beacon] = 0;
        // The replacing beacon gets assigned the replaced beacon's index
        s.beaconIndex[newBeacon] = index;
        s.beacons.pop();
    }

    function _requestBeacon(
        uint256 _id,
        uint256 _beaconPos,
        bytes32 _seed,
        SAccounts memory _accounts,
        SRandomUintData memory _data
    ) internal {
        if (s.beacons.length < 5) revert NotEnoughBeaconsAvailable(s.beacons.length, 5);
        _data.height = LibNetwork._blockNumber();
        _data.timestamp = block.timestamp;
        address randomBeacon = _selectOneBeacon(_seed, [_accounts.beacons[0], _accounts.beacons[1]]);
        s.beacon[randomBeacon].pending++;
        _accounts.beacons[_beaconPos] = randomBeacon;
        s.requestToHash[_id] = LibBeacon._generateRequestHash(_id, _accounts, _data, _seed);
        emit Events.RequestBeacon(_id, randomBeacon, _seed, _data.timestamp);
    }

    function _selectTwoBeacons(bytes32 _random) internal returns (address, address) {
        // Create a new array that contains only the items that are not in the exclude array
        address[] memory selectedItems = s.beacons;

        // Shuffle the selectedItems array using the Fisher-Yates shuffle algorithm
        uint256 i = 1;
        do {
            // Generate a random index j such that i <= j <= selectedItems.length - 1
            uint256 j = (uint256(keccak256(abi.encodePacked(_random, i))) % (selectedItems.length - i)) + i;
            // Swap the items at indices i and j
            address temp = selectedItems[i];
            selectedItems[i] = selectedItems[j];
            selectedItems[j] = temp;
            s.beacon[selectedItems[i]].pending++;
            unchecked {
                ++i;
            }
        } while (i < 3);
        // Return the first two items from the shuffled array
        return (selectedItems[1], selectedItems[2]);
    }

    function _selectOneBeacon(bytes32 _random, address[2] memory _exclude) internal view returns (address) {
        // Create a new array that contains only the items that are not in the exclude array
        (address[] memory selectedItems, uint256 count) = _beaconsWithoutExcluded(_exclude);

        // Generate a random index j such that j <= count
        uint256 j = uint256(_random) % count;

        return selectedItems[j];
    }

    /*
     * Below we have 3 _beaconsWithoutExcluded views that have identical logic, except they accept different length arrays for the input.
     * The only alternative is to have a dynamic array input, which would require a memory allocation, which is more expensive.
     */

    function _beaconsWithoutExcluded(address[2] memory _excluded)
        internal
        view
        returns (address[] memory, uint256 count)
    {
        uint256 beaconsLen = s.beacons.length;
        address[] memory selectedItems = new address[](beaconsLen - 2);

        uint256 i = 1;
        do {
            bool found = false;
            uint256 j = 0;
            while (j < _excluded.length) {
                if (s.beacons[i] == _excluded[j]) {
                    found = true;
                    break;
                }
                unchecked {
                    ++j;
                }
            }
            if (!found) {
                selectedItems[count] = s.beacons[i];
                unchecked {
                    ++count;
                }
            }
            unchecked {
                ++i;
            }
        } while (i < beaconsLen);

        return (selectedItems, count);
    }

    function _beaconsWithoutExcluded(address[3] memory _excluded)
        internal
        view
        returns (address[] memory, uint256 count)
    {
        uint256 beaconsLen = s.beacons.length;
        address[] memory selectedItems = new address[](beaconsLen - 3);

        uint256 i = 1;
        do {
            bool found = false;
            uint256 j = 0;
            while (j < _excluded.length) {
                if (s.beacons[i] == _excluded[j]) {
                    found = true;
                    break;
                }
                unchecked {
                    ++j;
                }
            }
            if (!found) {
                selectedItems[count] = s.beacons[i];
                unchecked {
                    ++count;
                }
            }
            unchecked {
                ++i;
            }
        } while (i < beaconsLen);

        return (selectedItems, count);
    }

    function _beaconsWithoutExcluded(address[5] memory _excluded, uint256 excludeLen)
        internal
        view
        returns (address[] memory, uint256 count)
    {
        uint256 beaconsLen = s.beacons.length;
        address[] memory selectedItems = new address[](beaconsLen - excludeLen);

        uint256 i = 1;
        do {
            bool found = false;
            uint256 j = 0;
            while (j < _excluded.length) {
                if (s.beacons[i] == _excluded[j]) {
                    found = true;
                    break;
                }
                unchecked {
                    ++j;
                }
            }
            if (!found) {
                selectedItems[count] = s.beacons[i];
                unchecked {
                    ++count;
                }
            }
            unchecked {
                ++i;
            }
        } while (i < beaconsLen);

        return (selectedItems, count);
    }

    function _processResult(
        uint256 id,
        address client,
        bytes10[3] memory hashes,
        uint256 callbackGasLimit,
        uint256 _ethReserved
    ) internal {
        bytes32 result = keccak256(abi.encodePacked(hashes[0], hashes[1], hashes[2]));

        // Callback to requesting contract
        LibBeacon._callback(client, callbackGasLimit, id, result);
        s.ethReserved[client] -= _ethReserved;

        s.results[id] = result;
        emit Events.Result(id, result);
    }

    function _finalSoftChargeClient(
        uint256 id,
        address client,
        uint256 fee,
        uint256 beaconFee
    ) internal {
        uint256 daoFee;
        uint256 seqFee;
        uint256 deposit = s.ethDeposit[client];
        if (deposit > 0) {
            if (deposit > fee) {
                // If this is the final charge for the request,
                // add fee for configured treasury and sequencer
                daoFee = deposit >= fee + beaconFee ? beaconFee : deposit - fee;
                _chargeClient(client, s.treasury, daoFee);
                // Only add sequencer fee if the deposit has enough subtracting sender and treasury fee
                if (deposit > fee + daoFee) {
                    seqFee = deposit >= fee + daoFee + beaconFee ? beaconFee : deposit - daoFee - fee;
                    _chargeClient(client, s.sequencer, seqFee);
                }
            } else {
                fee = deposit;
            }
            s.requestToFeePaid[id] += fee + seqFee + daoFee;
            _chargeClient(client, msg.sender, fee);
        }
    }

    function _softChargeClient(
        uint256 id,
        address client,
        uint256 fee
    ) internal {
        uint256 deposit = s.ethDeposit[client];
        if (deposit > 0) {
            if (deposit < fee) {
                fee = deposit;
            }
            s.requestToFeePaid[id] += fee;
            _chargeClient(client, msg.sender, fee);
        }
    }

    function _transferEth(address _to, uint256 _amount) internal {
        (bool sent, ) = _to.call{value: _amount}("");
        if (sent) {
            emit Events.WithdrawEth(_to, _amount);
        } else {
            revert FailedToSendEth(_to, _amount);
        }
    }

    function _chargeClient(
        address _from,
        address _to,
        uint256 _value
    ) private {
        s.ethDeposit[_from] -= _value;
        s.ethCollateral[_to] += _value;
        emit Events.ChargeEth(_from, _to, _value, Constants.CHARGE_TYPE_CLIENT_TO_BEACON);
    }

    function _validateRequestData(
        uint256 id,
        bytes32 seed,
        SAccounts memory accounts,
        SRandomUintData memory data
    ) internal view {
        bytes32 generatedHash = LibBeacon._generateRequestHash(id, accounts, data, seed);

        /* No need to require(requestToResult[packed.id] == bytes(0))
         * because requestToHash will already be bytes(0) if it's fulfilled
         * and wouldn't match the generated hash.
         * generatedHash can never be bytes(0) because packed.data.height must be greater than 0 */

        if (s.requestToHash[id] != generatedHash)
            revert RequestDataMismatch(generatedHash, s.requestToHash[id]);

        if (data.height == 0) revert RequestNotFound(id);
    }

    function _generateRequest(
        uint256 id,
        address client,
        SRandomUintData memory data
    ) internal {
        if (s.beacons.length < 5) revert NotEnoughBeaconsAvailable(s.beacons.length, 5);

        bytes32 seed = LibNetwork._seed(id);

        (address beaconOne, address beaconTwo) = _selectTwoBeacons(seed);
        address[3] memory selectedBeacons = [beaconOne, beaconTwo, address(0)];

        SAccounts memory accounts = SAccounts(client, selectedBeacons);

        bytes32 generatedHash = LibBeacon._generateRequestHash(id, accounts, data, seed);

        s.requestToHash[id] = generatedHash;

        // Emit event with new request data
        emit Request(
            id,
            SRequestEventData(
                data.ethReserved,
                data.beaconFee,
                block.timestamp,
                data.expirationBlocks,
                data.expirationSeconds,
                data.callbackGasLimit,
                data.minConfirmations,
                client,
                selectedBeacons,
                seed
            )
        );
    }
}