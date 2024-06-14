// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IVRFV2PlusWrapper {
    /**
     * @return the request ID of the most recent VRF V2 request made by this wrapper. This should only
   * be relied option within the same transaction that the request was made.
   */
    function lastRequestId() external view returns (uint256);

    /**
     * @notice Calculates the price of a VRF request with the given callbackGasLimit at the current
   * @notice block.
   *
   * @dev This function relies on the transaction gas price which is not automatically set during
   * @dev simulation. To estimate the price at a specific gas price, use the estimatePrice function.
   *
   * @param _callbackGasLimit is the gas limit used to estimate the price.
   * @param _numWords is the number of words to request.
   */
    function calculateRequestPrice(uint32 _callbackGasLimit, uint32 _numWords) external view returns (uint256);

    /**
     * @notice Calculates the price of a VRF request in native with the given callbackGasLimit at the current
   * @notice block.
   *
   * @dev This function relies on the transaction gas price which is not automatically set during
   * @dev simulation. To estimate the price at a specific gas price, use the estimatePrice function.
   *
   * @param _callbackGasLimit is the gas limit used to estimate the price.
   * @param _numWords is the number of words to request.
   */
    function calculateRequestPriceNative(uint32 _callbackGasLimit, uint32 _numWords) external view returns (uint256);

    /**
     * @notice Estimates the price of a VRF request with a specific gas limit and gas price.
   *
   * @dev This is a convenience function that can be called in simulation to better understand
   * @dev pricing.
   *
   * @param _callbackGasLimit is the gas limit used to estimate the price.
   * @param _numWords is the number of words to request.
   * @param _requestGasPriceWei is the gas price in wei used for the estimation.
   */
    function estimateRequestPrice(
        uint32 _callbackGasLimit,
        uint32 _numWords,
        uint256 _requestGasPriceWei
    ) external view returns (uint256);

    /**
     * @notice Estimates the price of a VRF request in native with a specific gas limit and gas price.
   *
   * @dev This is a convenience function that can be called in simulation to better understand
   * @dev pricing.
   *
   * @param _callbackGasLimit is the gas limit used to estimate the price.
   * @param _numWords is the number of words to request.
   * @param _requestGasPriceWei is the gas price in wei used for the estimation.
   */
    function estimateRequestPriceNative(
        uint32 _callbackGasLimit,
        uint32 _numWords,
        uint256 _requestGasPriceWei
    ) external view returns (uint256);

    /**
     * @notice Requests randomness from the VRF V2 wrapper, paying in native token.
   *
   * @param _callbackGasLimit is the gas limit for the request.
   * @param _requestConfirmations number of request confirmations to wait before serving a request.
   * @param _numWords is the number of words to request.
   */
    function requestRandomWordsInNative(
        uint32 _callbackGasLimit,
        uint16 _requestConfirmations,
        uint32 _numWords,
        bytes calldata extraArgs
    ) external payable returns (uint256 requestId);

    function link() external view returns (address);
    function linkNativeFeed() external view returns (address);
    function owner() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// solhint-disable-next-line interface-starts-with-i
interface LinkTokenInterface {
    function allowance(address owner, address spender) external view returns (uint256 remaining);

    function approve(address spender, uint256 value) external returns (bool success);

    function balanceOf(address owner) external view returns (uint256 balance);

    function decimals() external view returns (uint8 decimalPlaces);

    function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);

    function increaseApproval(address spender, uint256 subtractedValue) external;

    function name() external view returns (string memory tokenName);

    function symbol() external view returns (string memory tokenSymbol);

    function totalSupply() external view returns (uint256 totalTokensIssued);

    function transfer(address to, uint256 value) external returns (bool success);

    function transferAndCall(address to, uint256 value, bytes calldata data) external returns (bool success);

    function transferFrom(address from, address to, uint256 value) external returns (bool success);
}

// SPDX-License-Identifier: BSD-3-Clause

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import { IDiamondCut } from "./interfaces/IDiamondCut.sol";
import "./Storage.sol";

/**
 * @title Diamond
 * @author Venus
 * @notice This contract contains functions related to facets
 */
contract Diamond is IDiamondCut, Storage {
    /// @notice Emitted when functions are added, replaced or removed to facets
    event DiamondCut(IDiamondCut.FacetCut[] _diamondCut);

    struct Facet {
        address facetAddress;
        bytes4[] functionSelectors;
    }

    constructor(address _owner) {
        owner = _owner;
    }

    /**
     * @notice To add function selectors to the facet's mapping
     * @dev Allows the contract owner to add function selectors
     * @param diamondCut_ IDiamondCut contains facets address, action and function selectors
     */
    function diamondCut(IDiamondCut.FacetCut[] memory diamondCut_) public {
        require(msg.sender == owner, "only owner can");
        libDiamondCut(diamondCut_);
    }

    /**
     * @notice Get all function selectors mapped to the facet address
     * @param facet Address of the facet
     * @return selectors Array of function selectors
     */
    function facetFunctionSelectors(address facet) external view returns (bytes4[] memory) {
        return _facetFunctionSelectors[facet].functionSelectors;
    }

    /**
     * @notice Get facet position in the _facetFunctionSelectors through facet address
     * @param facet Address of the facet
     * @return Position of the facet
     */
    function facetPosition(address facet) external view returns (uint256) {
        return _facetFunctionSelectors[facet].facetAddressPosition;
    }

    /**
     * @notice Get all facet addresses
     * @return facetAddresses Array of facet addresses
     */
    function facetAddresses() external view returns (address[] memory) {
        return _facetAddresses;
    }

    /**
     * @notice Get facet address and position through function selector
     * @param functionSelector function selector
     * @return FacetAddressAndPosition facet address and position
     */
    function facetAddress(
        bytes4 functionSelector
    ) external view returns (Storage.FacetAddressAndPosition memory) {
        return _selectorToFacetAndPosition[functionSelector];
    }

    /**
     * @notice Get all facets address and their function selector
     * @return facets_ Array of Facet
     */
    function facets() external view returns (Facet[] memory) {
        uint256 facetsLength = _facetAddresses.length;
        Facet[] memory facets_ = new Facet[](facetsLength);
        for (uint256 i; i < facetsLength; ++i) {
            address facet = _facetAddresses[i];
            facets_[i].facetAddress = facet;
            facets_[i].functionSelectors = _facetFunctionSelectors[facet].functionSelectors;
        }
        return facets_;
    }

    /**
     * @notice To add function selectors to the facets' mapping
     * @param diamondCut_ IDiamondCut contains facets address, action and function selectors
     */
    function libDiamondCut(IDiamondCut.FacetCut[] memory diamondCut_) internal {
        uint256 diamondCutLength = diamondCut_.length;
        for (uint256 facetIndex; facetIndex < diamondCutLength; ++facetIndex) {
            IDiamondCut.FacetCutAction action = diamondCut_[facetIndex].action;
            if (action == IDiamondCut.FacetCutAction.Add) {
                addFunctions(diamondCut_[facetIndex].facetAddress, diamondCut_[facetIndex].functionSelectors);
            } else if (action == IDiamondCut.FacetCutAction.Replace) {
                replaceFunctions(diamondCut_[facetIndex].facetAddress, diamondCut_[facetIndex].functionSelectors);
            } else if (action == IDiamondCut.FacetCutAction.Remove) {
                removeFunctions(diamondCut_[facetIndex].facetAddress, diamondCut_[facetIndex].functionSelectors);
            } else {
                revert("LibDiamondCut: Incorrect FacetCutAction");
            }
        }
        emit DiamondCut(diamondCut_);
    }

    /**
     * @notice Add function selectors to the facet's address mapping
     * @param facetAddress Address of the facet
     * @param functionSelectors Array of function selectors need to add in the mapping
     */
    function addFunctions(address facetAddress, bytes4[] memory functionSelectors) internal {
        require(functionSelectors.length != 0, "LibDiamondCut: No selectors in facet to cut");
        require(facetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
        uint96 selectorPosition = uint96(_facetFunctionSelectors[facetAddress].functionSelectors.length);
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(facetAddress);
        }
        uint256 functionSelectorsLength = functionSelectors.length;
        for (uint256 selectorIndex; selectorIndex < functionSelectorsLength; ++selectorIndex) {
            bytes4 selector = functionSelectors[selectorIndex];
            address oldFacetAddress = _selectorToFacetAndPosition[selector].facetAddress;
            require(oldFacetAddress == address(0), "LibDiamondCut: Can't add function that already exists");
            addFunction(selector, selectorPosition, facetAddress);
            ++selectorPosition;
        }
    }

    /**
     * @notice Replace facet's address mapping for function selectors i.e selectors already associate to any other existing facet
     * @param facetAddress Address of the facet
     * @param functionSelectors Array of function selectors need to replace in the mapping
     */
    function replaceFunctions(address facetAddress, bytes4[] memory functionSelectors) internal {
        require(functionSelectors.length != 0, "LibDiamondCut: No selectors in facet to cut");
        require(facetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
        uint96 selectorPosition = uint96(_facetFunctionSelectors[facetAddress].functionSelectors.length);
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(facetAddress);
        }
        uint256 functionSelectorsLength = functionSelectors.length;
        for (uint256 selectorIndex; selectorIndex < functionSelectorsLength; ++selectorIndex) {
            bytes4 selector = functionSelectors[selectorIndex];
            address oldFacetAddress = _selectorToFacetAndPosition[selector].facetAddress;
            require(oldFacetAddress != facetAddress, "LibDiamondCut: Can't replace function with same function");
            removeFunction(oldFacetAddress, selector);
            addFunction(selector, selectorPosition, facetAddress);
            ++selectorPosition;
        }
    }

    /**
     * @notice Remove function selectors to the facet's address mapping
     * @param facetAddress Address of the facet
     * @param functionSelectors Array of function selectors need to remove in the mapping
     */
    function removeFunctions(address facetAddress, bytes4[] memory functionSelectors) internal {
        uint256 functionSelectorsLength = functionSelectors.length;
        require(functionSelectorsLength != 0, "LibDiamondCut: No selectors in facet to cut");
        // if function does not exist then do nothing and revert
        require(facetAddress == address(0), "LibDiamondCut: Remove facet address must be address(0)");
        for (uint256 selectorIndex; selectorIndex < functionSelectorsLength; ++selectorIndex) {
            bytes4 selector = functionSelectors[selectorIndex];
            address oldFacetAddress = _selectorToFacetAndPosition[selector].facetAddress;
            removeFunction(oldFacetAddress, selector);
        }
    }

    /**
     * @notice Add new facet to the proxy
     * @param facetAddress Address of the facet
     */
    function addFacet(address facetAddress) internal {
        enforceHasContractCode(facetAddress, "Diamond: New facet has no code");
        _facetFunctionSelectors[facetAddress].facetAddressPosition = _facetAddresses.length;
        _facetAddresses.push(facetAddress);
    }

    /**
     * @notice Add function selector to the facet's address mapping
     * @param selector funciton selector need to be added
     * @param selectorPosition funciton selector position
     * @param facetAddress Address of the facet
     */
    function addFunction(bytes4 selector, uint96 selectorPosition, address facetAddress) internal {
        _selectorToFacetAndPosition[selector].functionSelectorPosition = selectorPosition;
        _facetFunctionSelectors[facetAddress].functionSelectors.push(selector);
        _selectorToFacetAndPosition[selector].facetAddress = facetAddress;
    }

    /**
     * @notice Remove function selector to the facet's address mapping
     * @param facetAddress Address of the facet
     * @param selector function selectors need to remove in the mapping
     */
    function removeFunction(address facetAddress, bytes4 selector) internal {
        require(facetAddress != address(0), "LibDiamondCut: Can't remove function that doesn't exist");

        // replace selector with last selector, then delete last selector
        uint256 selectorPosition = _selectorToFacetAndPosition[selector].functionSelectorPosition;
        uint256 lastSelectorPosition = _facetFunctionSelectors[facetAddress].functionSelectors.length - 1;
        // if not the same then replace selector with lastSelector
        if (selectorPosition != lastSelectorPosition) {
            bytes4 lastSelector = _facetFunctionSelectors[facetAddress].functionSelectors[lastSelectorPosition];
            _facetFunctionSelectors[facetAddress].functionSelectors[selectorPosition] = lastSelector;
            _selectorToFacetAndPosition[lastSelector].functionSelectorPosition = uint96(selectorPosition);
        }
        // delete the last selector
        _facetFunctionSelectors[facetAddress].functionSelectors.pop();
        delete _selectorToFacetAndPosition[selector];

        // if no more selectors for facet address then delete the facet address
        if (lastSelectorPosition == 0) {
            // replace facet address with last facet address and delete last facet address
            uint256 lastFacetAddressPosition = _facetAddresses.length - 1;
            uint256 facetAddressPosition = _facetFunctionSelectors[facetAddress].facetAddressPosition;
            if (facetAddressPosition != lastFacetAddressPosition) {
                address lastFacetAddress = _facetAddresses[lastFacetAddressPosition];
                _facetAddresses[facetAddressPosition] = lastFacetAddress;
                _facetFunctionSelectors[lastFacetAddress].facetAddressPosition = facetAddressPosition;
            }
            _facetAddresses.pop();
            delete _facetFunctionSelectors[facetAddress];
        }
    }

    /**
     * @dev Ensure that the given address has contract code deployed
     * @param _contract The address to check for contract code
     * @param _errorMessage The error message to display if the contract code is not deployed
     */
    function enforceHasContractCode(address _contract, string memory _errorMessage) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize != 0, _errorMessage);
    }

    // Find facet for function that is called and execute the
    // function if a facet is found and return any value.
    fallback() external payable {
        address facet = _selectorToFacetAndPosition[msg.sig].facetAddress;
        require(facet != address(0), "Diamond: Function does not exist");
        // Execute public function from facet using delegatecall and return any value.
        assembly {
            // copy function selector and any arguments
            calldatacopy(0, 0, calldatasize())
            // execute function call using the facet
            let result := delegatecall(gas(), facet, 0, calldatasize(), 0, 0)
            // get any return value
            returndatacopy(0, 0, returndatasize())
            // return any return value or error back to the caller
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    receive() external payable {}
}

// SPDX-License-Identifier: BSD-3-Clause

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

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
    function diamondCut(FacetCut[] calldata _diamondCut) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./chainlink/LinkTokenInterface.sol";
import "./chainlink/IVRFV2PlusWrapper.sol";

contract Storage {
    // facet
    struct FacetAddressAndPosition {
        address facetAddress;
        uint96 functionSelectorPosition; // position in _facetFunctionSelectors.functionSelectors array
    }

    struct FacetFunctionSelectors {
        bytes4[] functionSelectors;
        uint256 facetAddressPosition; // position of facetAddress in _facetAddresses array
    }

    mapping(bytes4 => FacetAddressAndPosition) internal _selectorToFacetAndPosition;
    // maps facet addresses to function selectors
    mapping(address => FacetFunctionSelectors) internal _facetFunctionSelectors;
    // facet addresses
    address[] internal _facetAddresses;

    // vrf
    LinkTokenInterface internal i_linkToken;
    IVRFV2PlusWrapper public i_vrfV2PlusWrapper;

    struct RequestStatus {
        uint256 requestPaid;
        bool fulfilled;
        uint256[] tiles;
        uint256[] tileCostsInAmount;
        uint256 paidInAmount;
        address paidAsset;
        uint256[] randomWords;
        uint256 gameId;
        address user;
        string userUid;
        uint256 blockNumber;
    }

    uint32 public callbackGasLimit;
    uint16 public requestConfirmations;
    mapping(uint256 => RequestStatus) public requests;

    // games

    enum TileType {
        CLOSED,
        OCCUPIED,
        NONE,
        TICKET,
        TREASURE
    }

    struct GameInfo {
        uint256 id;
        uint256 totalSpots;
        uint256 maxTilesOpenableAtOnce;
        uint256 leftSpots;
        uint256 numTreasure;
        uint256 numTicket;
        uint256 leftNumTreasure;
        uint256 leftNumTicket;
        bool isPlaying;
        uint256 ticketCostInUsd; // decimal 8
        uint256 startTime;
        uint256 treasureTile;
        uint256 distributedAllBlockNumber; // 보물과 LDT가 모두 나눠진 블록
        uint256[] ticketTiles;
    }

    struct SpotInfo {
        uint256 tile;
        bool isOpened;
        TileType tileType;
        uint256 tileCostInAmount;
        address asset;
        address user;
        string userUid;
        address referralUser;
        bool withReferral;
        bool twitterClaimed;
    }

    struct TimeWindow {
        uint256 dayOfWeek; // 1: Monday, 7: Sunday
        uint256 startHour; // 0 ~ 23
        uint256 endHour; // 0 ~ 23
    }

    uint256 public lastGameId;
    uint256 public minimumPotSizeInUsd; // decimal 8
    address public USDT;
    address public USDC;
    address public treasury;
    uint256 public minGameTime; // 보드판 최소 등장 주기
    uint256 public maxGameTime; // 진행시간
    mapping(address => bool) public assets;
    address[] public assetList;
    address public owner;
    address public uidOwner;
    mapping(string => mapping(uint256 => bool)) uidNonce; // user uid => nonce => bool
    mapping(address => mapping(uint256 => bool)) referralNonce; // user(sender, not referral user) => nonce => bool
    mapping(address => mapping(address => uint256)) public userTreasury; // user => asset => amount
    mapping(uint256 => mapping(address => uint256)) public winnerPrizes; // game => asset => amount

    mapping(uint256 => GameInfo) public gameInfos; // game => game info
    mapping(uint256 => mapping(uint256 => SpotInfo)) public spotInfos; // game => spot => spot info
    mapping(address => mapping(address => uint256)) public userClaimableAmounts; // user => token => amount
    mapping(uint256 => mapping(address => mapping(address => uint256))) public pendingPots; // 아직 처리되지 않은 pot, game => user => asset => amount
    mapping(address => uint256) public pots; // 처리된 pot, asset => amount
    TimeWindow public timeWindow;
}