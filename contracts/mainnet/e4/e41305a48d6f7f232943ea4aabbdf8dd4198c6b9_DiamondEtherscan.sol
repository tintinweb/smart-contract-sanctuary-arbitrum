// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import { IDiamondEtherscan } from "interfaces/IDiamondEtherscan.sol";

import { LibDiamondEtherscan } from "../libraries/LibDiamondEtherscan.sol";
import { AccessControlModifiers } from "./AccessControlModifiers.sol";

/// @title DiamondEtherscan
/// @author Forked from:
/// https://github.com/zdenham/diamond-etherscan/blob/main/contracts/libraries/LibDiamondEtherscan.sol
contract DiamondEtherscan is IDiamondEtherscan, AccessControlModifiers {
    /// @inheritdoc IDiamondEtherscan
    function setDummyImplementation(address _implementation) external onlyGuardian {
        LibDiamondEtherscan.setDummyImplementation(_implementation);
    }

    /// @inheritdoc IDiamondEtherscan
    function implementation() external view returns (address) {
        return LibDiamondEtherscan.dummyImplementation();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

/// @title IDiamondEtherscan
/// @author Angle Labs, Inc.
interface IDiamondEtherscan {
    /// @notice Sets a dummy implementation with the same layout at the diamond proxy contract with all its facets
    function setDummyImplementation(address _implementation) external;

    /// @notice Address of the dummy implementation used to make the DiamondProxy contract interpretable by Etherscan
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import { LibStorage as s } from "./LibStorage.sol";

/// @title LibDiamondEtherscan
/// @notice Allow to verify a diamond proxy on Etherscan
/// @dev Forked from https://github.com/zdenham/diamond-etherscan/blob/main/contracts/libraries/LibDiamondEtherscan.sol
library LibDiamondEtherscan {
    event Upgraded(address indexed implementation);

    /// @notice Internal version of `setDummyImplementation`
    function setDummyImplementation(address implementationAddress) internal {
        s.implementationStorage().implementation = implementationAddress;
        emit Upgraded(implementationAddress);
    }

    /// @notice Internal version of `implementation`
    function dummyImplementation() internal view returns (address) {
        return s.implementationStorage().implementation;
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.19;

import { LibDiamond } from "../libraries/LibDiamond.sol";
import { LibStorage as s, TransmuterStorage } from "../libraries/LibStorage.sol";
import "../../utils/Errors.sol";
import "../../utils/Constants.sol";

/// @title AccessControlModifiers
/// @author Angle Labs, Inc.
contract AccessControlModifiers {
    /// @notice Checks whether the `msg.sender` has the governor role
    modifier onlyGovernor() {
        if (!LibDiamond.isGovernor(msg.sender)) revert NotGovernor();
        _;
    }

    /// @notice Checks whether the `msg.sender` has the guardian role
    modifier onlyGuardian() {
        if (!LibDiamond.isGovernorOrGuardian(msg.sender)) revert NotGovernorOrGuardian();
        _;
    }

    /// @notice Prevents a contract from calling itself, directly or indirectly
    /// @dev This implementation is an adaptation of the OpenZepellin `ReentrancyGuard` for the purpose of this
    /// Diamond Proxy system. The base implementation can be found here
    /// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol
    modifier nonReentrant() {
        TransmuterStorage storage ts = s.transmuterStorage();
        // Reentrant protection
        // On the first call, `ts.statusReentrant` will be `NOT_ENTERED`
        if (ts.statusReentrant == ENTERED) revert ReentrantCall();
        // Any calls to the `nonReentrant` modifier after this point will fail
        ts.statusReentrant = ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see https://eips.ethereum.org/EIPS/eip-2200)
        ts.statusReentrant = NOT_ENTERED;
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.19;

import "../../utils/Constants.sol";
import { DiamondStorage, ImplementationStorage, TransmuterStorage } from "../Storage.sol";

/// @title LibStorage
/// @author Angle Labs, Inc.
library LibStorage {
    /// @notice Returns the storage struct stored at the `DIAMOND_STORAGE_POSITION` slot
    /// @dev This struct handles the logic of the different facets used in the diamond proxy
    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    /// @notice Returns the storage struct stored at the `TRANSMUTER_STORAGE_POSITION` slot
    /// @dev This struct handles the particular logic of the Transmuter system
    function transmuterStorage() internal pure returns (TransmuterStorage storage ts) {
        bytes32 position = TRANSMUTER_STORAGE_POSITION;
        assembly {
            ts.slot := position
        }
    }

    /// @notice Returns the storage struct stored at the `IMPLEMENTATION_STORAGE_POSITION` slot
    /// @dev This struct handles the logic for making the contract easily usable on Etherscan
    function implementationStorage() internal pure returns (ImplementationStorage storage ims) {
        bytes32 position = IMPLEMENTATION_STORAGE_POSITION;
        assembly {
            ims.slot := position
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { LibStorage as s } from "./LibStorage.sol";

import "../../utils/Errors.sol";
import "../Storage.sol";

/// @title LibDiamond
/// @author Angle Labs, Inc.
/// @notice Helper library to deal with diamond proxies.
/// @dev Reference: EIP-2535 Diamonds
/// @dev Forked from https://github.com/mudgen/diamond-3/blob/master/contracts/libraries/LibDiamond.sol by mudgen
library LibDiamond {
    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);

    /*//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                                                  INTERNAL FUNCTIONS                                                
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////*/

    /// @notice Checks whether `admin` has the governor role
    function isGovernor(address admin) internal view returns (bool) {
        return s.diamondStorage().accessControlManager.isGovernor(admin);
    }

    /// @notice Checks whether `admin` has the guardian role
    function isGovernorOrGuardian(address admin) internal view returns (bool) {
        return s.diamondStorage().accessControlManager.isGovernorOrGuardian(admin);
    }

    /// @notice Internal function version of `diamondCut`
    function diamondCut(FacetCut[] memory _diamondCut, address _init, bytes memory _calldata) internal {
        uint256 diamondCutLength = _diamondCut.length;
        for (uint256 facetIndex; facetIndex < diamondCutLength; facetIndex++) {
            bytes4[] memory functionSelectors = _diamondCut[facetIndex].functionSelectors;
            address facetAddress = _diamondCut[facetIndex].facetAddress;

            if (functionSelectors.length == 0) {
                revert NoSelectorsProvidedForFacetForCut(facetAddress);
            }

            FacetCutAction action = _diamondCut[facetIndex].action;
            if (action == FacetCutAction.Add) {
                _addFunctions(facetAddress, functionSelectors);
            } else if (action == FacetCutAction.Replace) {
                _replaceFunctions(facetAddress, functionSelectors);
            } else if (action == FacetCutAction.Remove) {
                _removeFunctions(facetAddress, functionSelectors);
            }
        }

        emit DiamondCut(_diamondCut, _init, _calldata);
        _initializeDiamondCut(_init, _calldata);
    }

    /*//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                                                   PRIVATE FUNCTIONS                                                
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////*/

    /// @notice Does a delegate call on `_init` with `_calldata`
    function _initializeDiamondCut(address _init, bytes memory _calldata) private {
        if (_init == address(0)) {
            return;
        }
        _enforceHasContractCode(_init);
        (bool success, bytes memory error) = _init.delegatecall(_calldata);
        if (!success) {
            if (error.length > 0) {
                assembly {
                    let returndata_size := mload(error)
                    revert(add(32, error), returndata_size)
                }
            } else {
                revert InitializationFunctionReverted(_init, _calldata);
            }
        }
    }

    /// @notice Adds a new function to the diamond proxy
    /// @dev Reverts if selectors are already existing
    function _addFunctions(address _facetAddress, bytes4[] memory _functionSelectors) private {
        if (_facetAddress == address(0)) {
            revert CannotAddSelectorsToZeroAddress(_functionSelectors);
        }
        DiamondStorage storage ds = s.diamondStorage();
        uint16 selectorCount = uint16(ds.selectors.length);
        _enforceHasContractCode(_facetAddress);
        uint256 functionSelectorsLength = _functionSelectors.length;
        for (uint256 selectorIndex; selectorIndex < functionSelectorsLength; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorInfo[selector].facetAddress;
            if (oldFacetAddress != address(0)) {
                revert CannotAddFunctionToDiamondThatAlreadyExists(selector);
            }
            ds.selectorInfo[selector] = FacetInfo(_facetAddress, selectorCount);
            ds.selectors.push(selector);
            selectorCount++;
        }
    }

    /// @notice Upgrades a function in the diamond proxy
    /// @dev Reverts if selectors do not already exist
    function _replaceFunctions(address _facetAddress, bytes4[] memory _functionSelectors) private {
        DiamondStorage storage ds = s.diamondStorage();
        if (_facetAddress == address(0)) {
            revert CannotReplaceFunctionsFromFacetWithZeroAddress(_functionSelectors);
        }
        _enforceHasContractCode(_facetAddress);
        uint256 functionSelectorsLength = _functionSelectors.length;
        for (uint256 selectorIndex; selectorIndex < functionSelectorsLength; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorInfo[selector].facetAddress;
            // Can't replace immutable functions -- functions defined directly in the diamond in this case
            if (oldFacetAddress == address(this)) {
                revert CannotReplaceImmutableFunction(selector);
            }
            if (oldFacetAddress == _facetAddress) {
                revert CannotReplaceFunctionWithTheSameFunctionFromTheSameFacet(selector);
            }
            if (oldFacetAddress == address(0)) {
                revert CannotReplaceFunctionThatDoesNotExists(selector);
            }
            // Replace old facet address
            ds.selectorInfo[selector].facetAddress = _facetAddress;
        }
    }

    /// @notice Removes a function in the diamond proxy
    /// @dev Reverts if selectors do not already exist
    function _removeFunctions(address _facetAddress, bytes4[] memory _functionSelectors) private {
        DiamondStorage storage ds = s.diamondStorage();
        uint256 selectorCount = ds.selectors.length;
        if (_facetAddress != address(0)) {
            revert RemoveFacetAddressMustBeZeroAddress(_facetAddress);
        }
        uint256 functionSelectorsLength = _functionSelectors.length;
        for (uint256 selectorIndex; selectorIndex < functionSelectorsLength; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            FacetInfo memory oldFacetAddressAndSelectorPosition = ds.selectorInfo[selector];
            if (oldFacetAddressAndSelectorPosition.facetAddress == address(0)) {
                revert CannotRemoveFunctionThatDoesNotExist(selector);
            }

            // Can't remove immutable functions -- functions defined directly in the diamond
            if (oldFacetAddressAndSelectorPosition.facetAddress == address(this)) {
                revert CannotRemoveImmutableFunction(selector);
            }
            // Replace selector with last selector
            selectorCount--;
            if (oldFacetAddressAndSelectorPosition.selectorPosition != selectorCount) {
                bytes4 lastSelector = ds.selectors[selectorCount];
                ds.selectors[oldFacetAddressAndSelectorPosition.selectorPosition] = lastSelector;
                ds.selectorInfo[lastSelector].selectorPosition = oldFacetAddressAndSelectorPosition.selectorPosition;
            }
            // Delete last selector
            ds.selectors.pop();
            delete ds.selectorInfo[selector];
        }
    }

    /// @notice Checks that an address has a non void bytecode
    function _enforceHasContractCode(address _contract) private view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        if (contractSize == 0) {
            revert ContractHasNoCode();
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.19;

error AlreadyAdded();
error CannotAddFunctionToDiamondThatAlreadyExists(bytes4 _selector);
error CannotAddSelectorsToZeroAddress(bytes4[] _selectors);
error CannotRemoveFunctionThatDoesNotExist(bytes4 _selector);
error CannotRemoveImmutableFunction(bytes4 _selector);
error CannotReplaceFunctionsFromFacetWithZeroAddress(bytes4[] _selectors);
error CannotReplaceFunctionThatDoesNotExists(bytes4 _selector);
error CannotReplaceFunctionWithTheSameFunctionFromTheSameFacet(bytes4 _selector);
error CannotReplaceImmutableFunction(bytes4 _selector);
error ContractHasNoCode();
error FunctionNotFound(bytes4 _functionSelector);
error IncorrectFacetCutAction(uint8 _action);
error InitializationFunctionReverted(address _initializationContractAddress, bytes _calldata);
error InvalidChainlinkRate();
error InvalidLengths();
error InvalidNegativeFees();
error InvalidOracleType();
error InvalidParam();
error InvalidParams();
error InvalidRate();
error InvalidSwap();
error InvalidTokens();
error ManagerHasAssets();
error NoSelectorsProvidedForFacetForCut(address _facetAddress);
error NotAllowed();
error NotCollateral();
error NotGovernor();
error NotGovernorOrGuardian();
error NotTrusted();
error NotWhitelisted();
error OneInchSwapFailed();
error OracleUpdateFailed();
error Paused();
error ReentrantCall();
error RemoveFacetAddressMustBeZeroAddress(address _facetAddress);
error TooBigAmountIn();
error TooLate();
error TooSmallAmountOut();
error ZeroAddress();
error ZeroAmount();

// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.5.0;

import { ICbETH } from "interfaces/external/coinbase/ICbETH.sol";
import { ISfrxETH } from "interfaces/external/frax/ISfrxETH.sol";
import { IStETH } from "interfaces/external/lido/IStETH.sol";
import { IRETH } from "interfaces/external/rocketPool/IRETH.sol";

/*//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                                                 STORAGE SLOTS                                                  
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////*/

/// @dev Storage position of `DiamondStorage` structure
/// @dev Equals `keccak256("diamond.standard.diamond.storage") - 1`
bytes32 constant DIAMOND_STORAGE_POSITION = 0xc8fcad8db84d3cc18b4c41d551ea0ee66dd599cde068d998e57d5e09332c131b;

/// @dev Storage position of `TransmuterStorage` structure
/// @dev Equals `keccak256("diamond.standard.transmuter.storage") - 1`
bytes32 constant TRANSMUTER_STORAGE_POSITION = 0xc1f2f38dde3351ac0a64934139e816326caa800303a1235dc53707d0de05d8bd;

/// @dev Storage position of `ImplementationStorage` structure
/// @dev Equals `keccak256("eip1967.proxy.implementation") - 1`
bytes32 constant IMPLEMENTATION_STORAGE_POSITION = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

/*//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                                                     MATHS                                                      
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////*/

uint256 constant BASE_6 = 1e6;
uint256 constant BASE_8 = 1e8;
uint256 constant BASE_9 = 1e9;
uint256 constant BASE_12 = 1e12;
uint256 constant BPS = 1e14;
uint256 constant BASE_18 = 1e18;
uint256 constant HALF_BASE_27 = 1e27 / 2;
uint256 constant BASE_27 = 1e27;
uint256 constant BASE_36 = 1e36;
uint256 constant MAX_BURN_FEE = 999_000_000;
uint256 constant MAX_MINT_FEE = BASE_12 - 1;

/*//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                                                     REENTRANT                                                      
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////*/

// The values being non-zero value makes deployment a bit more expensive,
// but in exchange the refund on every call to nonReentrant will be lower in
// amount. Since refunds are capped to a percentage of the total
// transaction's gas, it is best to keep them low in cases like this one, to
// increase the likelihood of the full refund coming into effect.
uint8 constant NOT_ENTERED = 1;
uint8 constant ENTERED = 2;

/*//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                                               COMMON ADDRESSES                                                 
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////*/

address constant PERMIT_2 = 0x000000000022D473030F116dDEE9F6B43aC78BA3;
address constant ONE_INCH_ROUTER = 0x1111111254EEB25477B68fb85Ed929f73A960582;
address constant AGEUR = 0x1a7e4e63778B4f12a199C062f3eFdD288afCBce8;
ICbETH constant CBETH = ICbETH(0xBe9895146f7AF43049ca1c1AE358B0541Ea49704);
IRETH constant RETH = IRETH(0xae78736Cd615f374D3085123A210448E74Fc6393);
IStETH constant STETH = IStETH(0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84);
ISfrxETH constant SFRXETH = ISfrxETH(0xac3E018457B222d93114458476f3E3416Abbe38F);

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.19;

import { IERC20 } from "oz/token/ERC20/IERC20.sol";
import { IAccessControlManager } from "interfaces/IAccessControlManager.sol";
import { IAgToken } from "interfaces/IAgToken.sol";

/*//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                                                        ENUMS                                                      
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////*/

enum FacetCutAction {
    Add,
    Replace,
    Remove
}

enum ManagerType {
    EXTERNAL
}

enum ActionType {
    Mint,
    Burn,
    Redeem
}

enum TrustedType {
    Updater,
    Seller
}

enum QuoteType {
    MintExactInput,
    MintExactOutput,
    BurnExactInput,
    BurnExactOutput
}

enum OracleReadType {
    CHAINLINK_FEEDS,
    EXTERNAL,
    NO_ORACLE,
    STABLE,
    WSTETH,
    CBETH,
    RETH,
    SFRXETH,
    PYTH,
    MAX,
    MORPHO_ORACLE
}

enum OracleQuoteType {
    UNIT,
    TARGET
}

enum WhitelistType {
    BACKED
}

/*//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                                                    STRUCTS                                                     
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////*/

struct Permit2Details {
    address to; // Address that will receive the funds
    uint256 nonce; // Nonce of the transaction
    bytes signature; // Permit signature of the user
}

struct FacetCut {
    address facetAddress; // Facet contract address
    FacetCutAction action; // Can be add, remove or replace
    bytes4[] functionSelectors; // Ex. bytes4(keccak256("transfer(address,uint256)"))
}

struct Facet {
    address facetAddress; // Facet contract address
    bytes4[] functionSelectors; // Ex. bytes4(keccak256("transfer(address,uint256)"))
}

struct FacetInfo {
    address facetAddress; // Facet contract address
    uint16 selectorPosition; // Position in the list of all selectors
}

struct DiamondStorage {
    bytes4[] selectors; // List of all available selectors
    mapping(bytes4 => FacetInfo) selectorInfo; // Selector to (address, position in list)
    IAccessControlManager accessControlManager; // Contract handling access control
}

struct ImplementationStorage {
    address implementation; // Dummy implementation address for Etherscan usability
}

struct ManagerStorage {
    IERC20[] subCollaterals; // Subtokens handled by the manager or strategies
    bytes config; // Additional configuration data
}

struct Collateral {
    uint8 isManaged; // If the collateral is managed through external strategies
    uint8 isMintLive; // If minting from this asset is unpaused
    uint8 isBurnLive; // If burning to this asset is unpaused
    uint8 decimals; // IERC20Metadata(collateral).decimals()
    uint8 onlyWhitelisted; // If only whitelisted addresses can burn or redeem for this token
    uint216 normalizedStables; // Normalized amount of stablecoins issued from this collateral
    uint64[] xFeeMint; // Increasing exposures in [0,BASE_9[
    int64[] yFeeMint; // Mint fees at the exposures specified in `xFeeMint`
    uint64[] xFeeBurn; // Decreasing exposures in ]0,BASE_9]
    int64[] yFeeBurn; // Burn fees at the exposures specified in `xFeeBurn`
    bytes oracleConfig; // Data about the oracle used for the collateral
    bytes whitelistData; // For whitelisted collateral, data used to verify whitelists
    ManagerStorage managerData; // For managed collateral, data used to handle the strategies
    uint256 stablecoinCap; // Cap on the amount of stablecoins that can be issued from this collateral
}

struct TransmuterStorage {
    IAgToken agToken; // agToken handled by the system
    uint8 isRedemptionLive; // If redemption is unpaused
    uint8 statusReentrant; // If call is reentrant or not
    uint128 normalizedStables; // Normalized amount of stablecoins issued by the system
    uint128 normalizer; // To reconcile `normalizedStables` values with the actual amount
    address[] collateralList; // List of collateral assets supported by the system
    uint64[] xRedemptionCurve; // Increasing collateral ratios > 0
    int64[] yRedemptionCurve; // Value of the redemption fees at `xRedemptionCurve`
    mapping(address => Collateral) collaterals; // Maps a collateral asset to its parameters
    mapping(address => uint256) isTrusted; // If an address is trusted to update the normalizer value
    mapping(address => uint256) isSellerTrusted; // If an address is trusted to sell accruing reward tokens or to run keeper jobs on oracles
    mapping(WhitelistType => mapping(address => uint256)) isWhitelistedForType;
    // Whether an address is whitelisted for a specific whitelist type
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0;

/// @title ICbETH
/// @notice Interface for the `cbETH` contract
interface ICbETH {
    function exchangeRate() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0;

/// @title ISfrxETH
/// @notice Interface for the `sfrxETH` contract
interface ISfrxETH {
    function pricePerShare() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0;

/// @title IStETH
/// @notice Interface for the `StETH` contract
interface IStETH {
    function getPooledEthByShares(uint256 _sharesAmount) external view returns (uint256);

    function submit(address) external payable returns (uint256);

    function getSharesByPooledEth(uint256 _ethAmount) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0;

/// @title IRETH
/// @notice Interface for the `rETH` contract
interface IRETH {
    function getExchangeRate() external view returns (uint256);
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
    event Approval(address indexed owner, address indexed spender, uint256 value);

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
    function allowance(address owner, address spender) external view returns (uint256);

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
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0;

/// @title IAccessControlManager
/// @author Angle Labs, Inc.
interface IAccessControlManager {
    /// @notice Checks whether an address is governor of the Angle Protocol or not
    /// @param admin Address to check
    /// @return Whether the address has the `GOVERNOR_ROLE` or not
    function isGovernor(address admin) external view returns (bool);

    /// @notice Checks whether an address is governor or a guardian of the Angle Protocol or not
    /// @param admin Address to check
    /// @return Whether the address has the `GUARDIAN_ROLE` or not
    /// @dev Governance should make sure when adding a governor to also give this governor the guardian
    /// role by calling the `addGovernor` function
    function isGovernorOrGuardian(address admin) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0;

import { IERC20 } from "oz/token/ERC20/IERC20.sol";

/// @title IAgToken
/// @author Angle Labs, Inc.
/// @notice Interface for the stablecoins `AgToken` contracts
interface IAgToken is IERC20 {
    /*//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                                              MINTER ROLE ONLY FUNCTIONS                                            
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////*/

    /// @notice Lets a whitelisted contract mint agTokens
    /// @param account Address to mint to
    /// @param amount Amount to mint
    function mint(address account, uint256 amount) external;

    /// @notice Burns `amount` tokens from a `burner` address after being asked to by `sender`
    /// @param amount Amount of tokens to burn
    /// @param burner Address to burn from
    /// @param sender Address which requested the burn from `burner`
    /// @dev This method is to be called by a contract with the minter right after being requested
    /// to do so by a `sender` address willing to burn tokens from another `burner` address
    /// @dev The method checks the allowance between the `sender` and the `burner`
    function burnFrom(uint256 amount, address burner, address sender) external;

    /// @notice Burns `amount` tokens from a `burner` address
    /// @param amount Amount of tokens to burn
    /// @param burner Address to burn from
    /// @dev This method is to be called by a contract with a minter right on the AgToken after being
    /// requested to do so by an address willing to burn tokens from its address
    function burnSelf(uint256 amount, address burner) external;

    /*//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                                                TREASURY ONLY FUNCTIONS                                             
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////*/

    /// @notice Adds a minter in the contract
    /// @param minter Minter address to add
    /// @dev Zero address checks are performed directly in the `Treasury` contract
    function addMinter(address minter) external;

    /// @notice Removes a minter from the contract
    /// @param minter Minter address to remove
    /// @dev This function can also be called by a minter wishing to revoke itself
    function removeMinter(address minter) external;

    /// @notice Sets a new treasury contract
    /// @param _treasury New treasury address
    function setTreasury(address _treasury) external;

    /*//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                                                  EXTERNAL FUNCTIONS                                                
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////*/

    /// @notice Checks whether an address has the right to mint agTokens
    /// @param minter Address for which the minting right should be checked
    /// @return Whether the address has the right to mint agTokens or not
    function isMinter(address minter) external view returns (bool);

    /// @notice Amount of decimals of the stablecoin
    function decimals() external view returns (uint8);
}