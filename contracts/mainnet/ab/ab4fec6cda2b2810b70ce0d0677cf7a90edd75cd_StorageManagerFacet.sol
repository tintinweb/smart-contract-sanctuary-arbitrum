/**
 * Read from & Write to core storage
 */
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import {AccessControlled} from "../../AccessControl.sol";
import {IERC20} from "src/interfaces/IERC20.sol";
import {ITokenBridge} from "src/interfaces/IBridgeProvider.sol";
import {IDataProvider} from "src/interfaces/IDataProvider.sol";
import "../../storage/core/Core.sol";
import "../../types/Main.sol";

contract StorageManagerFacet is AccessControlled {
    // ==============
    //     READ
    // ==============
    /**
     * Get all supported tokens
     * @return supportedTokens
     */
    function getSupportedTokens()
        external
        view
        returns (bytes32[] memory supportedTokens)
    {
        supportedTokens = CoreStorageLib.retreive().allSupportedTokens;
    }

    /**
     * Get Token struct data of a Solana token
     * @param solToken - Address of the solana token
     * @return tokenData - Data of the token
     */
    function getTokenData(
        bytes32 solToken
    ) external view returns (Token memory tokenData) {
        tokenData = CoreStorageLib.retreive().tokens[solToken];
    }

    /**
     * Get source token of solana token
     */
    function getSourceToken(
        bytes32 destToken
    ) external view returns (address srcToken) {
        srcToken = CoreStorageLib.retreive().tokens[destToken].localAddress;
    }

    /**
     * Get data provider
     */
    function getDataProvider()
        external
        view
        returns (IDataProvider dataProvider)
    {
        dataProvider = IDataProvider(CoreStorageLib.retreive().dataProvider);
    }

    /**
     * Get a token's bridge provider
     */
    function getTokenBridgeProvider(
        bytes32 token
    ) external view returns (ITokenBridge bridgeProvider) {
        bridgeProvider = CoreStorageLib.retreive().tokens[token].bridgeProvider;
        require(
            address(bridgeProvider) != address(0),
            "Unsupported Bridge Provider"
        );
    }

    /**
     *  Get the solana program address (in bytes32)
     */
    function getSolanaProgram() external view returns (bytes32 solanaProgram) {
        solanaProgram = CoreStorageLib.retreive().solanaProgram;
    }

    /**
     * Get a user's nonce
     */
    function getUserNonce(address user) external view returns (uint256 nonce) {
        nonce = CoreStorageLib.retreive().nonces[user];
    }

    function getPayloadBridgeProvider()
        external
        view
        returns (IPayloadBridge bridgeProvider)
    {
        bridgeProvider = CoreStorageLib.retreive().plainBridgeProvider;
    }

    // ==============
    //     WRITE
    // ==============
    /**
     * Add a token's bridge selector
     * @param token - The token's address
     * @param bridgeProvider - The bridge provider
     */
    function addToken(
        address token,
        bytes32 solToken,
        ITokenBridge bridgeProvider
    ) external onlyOwner {
        CoreStorage storage coreStorage = CoreStorageLib.retreive();

        require(
            address(coreStorage.tokens[solToken].bridgeProvider) == address(0),
            "Bridge Provider Already Added. Use updateTokenBridge"
        );

        coreStorage.tokens[solToken] = Token({
            solAddress: solToken,
            localAddress: token,
            bridgeProvider: bridgeProvider
        });
        coreStorage.allSupportedTokens.push(solToken);
    }

    // /**
    //  * Update a token's bridge selector
    //  * @param token - The token's address
    //  * @param bridgeProvider - The bridge provider config
    //  */
    // function updateToken(
    //     bytes32 token,
    //     ITokenBridge bridgeProvider
    // ) external onlyOwner {
    //     CoreStorage storage coreStorage = CoreStorageLib.retreive();

    //     require(
    //         address(coreStorage.tokens[token]) != address(0),
    //         "Bridge Provider Already Added. Use updateTokenBridge"
    //     );

    //     coreStorage.tokenBridgeProviders[token] = bridgeProvider;
    // }

    function setPayloadBridgeProvider(
        IPayloadBridge bridgeProvider
    ) external onlyOwner {
        CoreStorageLib.retreive().plainBridgeProvider = bridgeProvider;
    }

    function setHxroSolanaProgram(bytes32 solanaProgram) external onlyOwner {
        CoreStorageLib.retreive().solanaProgram = solanaProgram;
    }

    function setDataProvider(IDataProvider newDataProvider) external onlyOwner {
        CoreStorageLib.retreive().dataProvider = newDataProvider;
    }
}

/**
 * A base contract to inherit from which provides some modifiers,
 * using storage from the storage libs.
 *
 * Since libs are not capable of defining modiifers.
 */
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import {LibDiamond} from "./libraries/LibDiamond.sol";

contract AccessControlled {
    /**
     * Only allow owner of the diamond to access
     */
    modifier onlyOwner() {
        require(msg.sender == LibDiamond.contractOwner(), "Only Owner");
        _;
    }

    /**
     * Only allow self to call
     */
    modifier onlySelf() {
        require(msg.sender == address(this), "Only Self");
        _;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

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
    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function decimals() external view returns (uint256);
}

/**
 * Interface for a bridge provider
 */
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "src/diamond/types/Main.sol";
import "./IERC20.sol";

interface ITokenBridge {
    function bridgeHxroPayloadWithTokens(
        bytes32 destToken,
        uint256 amount,
        address msgSender,
        bytes calldata hxroPayload
    ) external returns (BridgeResult memory);
}

interface IPayloadBridge {
    function bridgeHXROPayload(
        bytes calldata hxroPayload,
        address msgSender
    ) external returns (BridgeResult memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/**
 * Interface for a data provider adapters
 */
interface IDataProvider {
    function quoteSOLToETH(
        uint256 solAmount
    ) external view returns (uint256 ethAmount);

    function quoteSOLToToken(
        address pairToken,
        uint256 solAmount
    ) external view returns (uint256 tokenAmount);

    function quoteETHToToken(
        address pairToken,
        uint256 ethAmount
    ) external view returns (uint256 tokenAmount);
}

/**
 * Storage specific to the execution facet
 */
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import {IERC20} from "src/interfaces/IERC20.sol";
import {ITokenBridge, IPayloadBridge} from "src/interfaces/IBridgeProvider.sol";
import {IDataProvider} from "src/interfaces/IDataProvider.sol";

// Token data
struct Token {
    bytes32 solAddress;
    address localAddress;
    ITokenBridge bridgeProvider;
    
}

struct CoreStorage {
    /**
     * Address of the solana eHXRO program
     */
    bytes32 solanaProgram;
    /**
     * All supported tokens
     */
    bytes32[] allSupportedTokens;
    /**
     * Mapping supported tokens (SOL Address) => Token data
     */
    mapping(bytes32 supportedToken => Token tokenData) tokens;
    /**
     * The address of the bridge provider for bridging plain payload
     */
    IPayloadBridge plainBridgeProvider;
    /**
     * Map user address => nonce
     */
    mapping(address => uint256) nonces;
    /**
     * Chainlink oracle address
     */
    IDataProvider dataProvider;
}

/**
 * The lib to use to retreive the storage
 */
library CoreStorageLib {
    // ======================
    //       STORAGE
    // ======================
    // The namespace for the lib (the hash where its stored)
    bytes32 internal constant STORAGE_NAMESPACE =
        keccak256("diamond.hxro.storage.core.execution");

    // Function to retreive our storage
    function retreive() internal pure returns (CoreStorage storage s) {
        bytes32 position = STORAGE_NAMESPACE;
        assembly {
            s.slot := position
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "src/interfaces/IERC20.sol";
/**
 * Types for the eHXRO contracts
 */

struct InboundPayload {
    bytes32 solToken;
    uint256 amount;
    bytes messageHash;
}

enum Bridge {
    WORMHOLE,
    MAYAN_SWAP,
    VERY_REAL_BRIDGE
}

struct BridgeResult {
    Bridge id;
    bytes trackableHash;
}

error NotSigOwner();

error UnsupportedToken();

error InvalidNonce();

error BridgeFailed(bytes revertReason);

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/
import { IDiamond } from "../interfaces/IDiamond.sol";
import { IDiamondCut } from "../interfaces/IDiamondCut.sol";

// Remember to add the loupe functions from DiamondLoupeFacet to the diamond.
// The loupe functions are required by the EIP2535 Diamonds standard

error NoSelectorsGivenToAdd();
error NotContractOwner(address _user, address _contractOwner);
error NoSelectorsProvidedForFacetForCut(address _facetAddress);
error CannotAddSelectorsToZeroAddress(bytes4[] _selectors);
error NoBytecodeAtAddress(address _contractAddress, string _message);
error IncorrectFacetCutAction(uint8 _action);
error CannotAddFunctionToDiamondThatAlreadyExists(bytes4 _selector);
error CannotReplaceFunctionsFromFacetWithZeroAddress(bytes4[] _selectors);
error CannotReplaceImmutableFunction(bytes4 _selector);
error CannotReplaceFunctionWithTheSameFunctionFromTheSameFacet(bytes4 _selector);
error CannotReplaceFunctionThatDoesNotExists(bytes4 _selector);
error RemoveFacetAddressMustBeZeroAddress(address _facetAddress);
error CannotRemoveFunctionThatDoesNotExist(bytes4 _selector);
error CannotRemoveImmutableFunction(bytes4 _selector);
error InitializationFunctionReverted(address _initializationContractAddress, bytes _calldata);

library LibDiamond {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");

    struct FacetAddressAndSelectorPosition {
        address facetAddress;
        uint16 selectorPosition;
    }

    struct DiamondStorage {
        // function selector => facet address and selector position in selectors array
        mapping(bytes4 => FacetAddressAndSelectorPosition) facetAddressAndSelectorPosition;
        bytes4[] selectors;
        mapping(bytes4 => bool) supportedInterfaces;
        // owner of the contract
        address contractOwner;
    }

    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function setContractOwner(address _newOwner) internal {
        DiamondStorage storage ds = diamondStorage();
        address previousOwner = ds.contractOwner;
        ds.contractOwner = _newOwner;
        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    function contractOwner() internal view returns (address contractOwner_) {
        contractOwner_ = diamondStorage().contractOwner;
    }

    function enforceIsContractOwner() internal view {
        if(msg.sender != diamondStorage().contractOwner) {
            revert NotContractOwner(msg.sender, diamondStorage().contractOwner);
        }        
    }

    event DiamondCut(IDiamondCut.FacetCut[] _diamondCut, address _init, bytes _calldata);

    // Internal function version of diamondCut
    function diamondCut(
        IDiamondCut.FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) internal {
        for (uint256 facetIndex; facetIndex < _diamondCut.length; facetIndex++) {
            bytes4[] memory functionSelectors = _diamondCut[facetIndex].functionSelectors;
            address facetAddress = _diamondCut[facetIndex].facetAddress;
            if(functionSelectors.length == 0) {
                revert NoSelectorsProvidedForFacetForCut(facetAddress);
            }
            IDiamondCut.FacetCutAction action = _diamondCut[facetIndex].action;
            if (action == IDiamond.FacetCutAction.Add) {
                addFunctions(facetAddress, functionSelectors);
            } else if (action == IDiamond.FacetCutAction.Replace) {
                replaceFunctions(facetAddress, functionSelectors);
            } else if (action == IDiamond.FacetCutAction.Remove) {
                removeFunctions(facetAddress, functionSelectors);
            } else {
                revert IncorrectFacetCutAction(uint8(action));
            }
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    function addFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {        
        if(_facetAddress == address(0)) {
            revert CannotAddSelectorsToZeroAddress(_functionSelectors);
        }
        DiamondStorage storage ds = diamondStorage();
        uint16 selectorCount = uint16(ds.selectors.length);                
        enforceHasContractCode(_facetAddress, "LibDiamondCut: Add facet has no code");
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.facetAddressAndSelectorPosition[selector].facetAddress;
            if(oldFacetAddress != address(0)) {
                revert CannotAddFunctionToDiamondThatAlreadyExists(selector);
            }            
            ds.facetAddressAndSelectorPosition[selector] 
            = FacetAddressAndSelectorPosition(_facetAddress, selectorCount);
            ds.selectors.push(selector);
            selectorCount++;
        }
    }

    function replaceFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {        
        DiamondStorage storage ds = diamondStorage();
        if(_facetAddress == address(0)) {
            revert CannotReplaceFunctionsFromFacetWithZeroAddress(_functionSelectors);
        }
        enforceHasContractCode(_facetAddress, "LibDiamondCut: Replace facet has no code");
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.facetAddressAndSelectorPosition[selector].facetAddress;
            // can't replace immutable functions -- functions defined directly in the diamond in this case
            if(oldFacetAddress == address(this)) {
                revert CannotReplaceImmutableFunction(selector);
            }
            if(oldFacetAddress == _facetAddress) {
                revert CannotReplaceFunctionWithTheSameFunctionFromTheSameFacet(selector);
            }
            if(oldFacetAddress == address(0)) {
                revert CannotReplaceFunctionThatDoesNotExists(selector);
            }
            // replace old facet address
            ds.facetAddressAndSelectorPosition[selector].facetAddress = _facetAddress;
        }
    }

    function removeFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {        
        DiamondStorage storage ds = diamondStorage();
        uint256 selectorCount = ds.selectors.length;
        if(_facetAddress != address(0)) {
            revert RemoveFacetAddressMustBeZeroAddress(_facetAddress);
        }        
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            FacetAddressAndSelectorPosition memory oldFacetAddressAndSelectorPosition 
            = ds.facetAddressAndSelectorPosition[selector];
            if(oldFacetAddressAndSelectorPosition.facetAddress == address(0)) {
                revert CannotRemoveFunctionThatDoesNotExist(selector);
            }
            
            
            // can't remove immutable functions -- functions defined directly in the diamond
            if(oldFacetAddressAndSelectorPosition.facetAddress == address(this)) {
                revert CannotRemoveImmutableFunction(selector);
            }
            // replace selector with last selector
            selectorCount--;
            if (oldFacetAddressAndSelectorPosition.selectorPosition != selectorCount) {
                bytes4 lastSelector = ds.selectors[selectorCount];
                ds.selectors[oldFacetAddressAndSelectorPosition.selectorPosition] = lastSelector;
                ds.facetAddressAndSelectorPosition[lastSelector].selectorPosition = 
                oldFacetAddressAndSelectorPosition.selectorPosition;
            }
            // delete last selector
            ds.selectors.pop();
            delete ds.facetAddressAndSelectorPosition[selector];
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
        if(contractSize == 0) {
            revert NoBytecodeAtAddress(_contract, _errorMessage);
        }        
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

interface IDiamond {
    enum FacetCutAction {Add, Replace, Remove}
    // Add=0, Replace=1, Remove=2

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

import { IDiamond } from "./IDiamond.sol";

interface IDiamondCut is IDiamond {    

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
}