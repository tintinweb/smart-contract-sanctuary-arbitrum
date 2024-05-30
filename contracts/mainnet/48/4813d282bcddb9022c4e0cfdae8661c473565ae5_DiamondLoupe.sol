// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import { IDiamondLoupe } from "interfaces/IDiamondLoupe.sol";

import { LibStorage as s } from "../libraries/LibStorage.sol";

import "../Storage.sol";

/// @title DiamondLoupe
/// @author Angle Labs, Inc.
/// @dev Reference: EIP-2535 Diamonds
/// @dev Forked from https://github.com/mudgen/diamond-3/blob/master/contracts/facets/DiamondLoupeFacet.sol by mudgen
contract DiamondLoupe is IDiamondLoupe {
    /// @inheritdoc IDiamondLoupe
    function facets() external view override returns (Facet[] memory facets_) {
        DiamondStorage storage ds = s.diamondStorage();
        uint256 selectorCount = ds.selectors.length;
        facets_ = new Facet[](selectorCount);
        uint16[] memory numFacetSelectors = new uint16[](selectorCount);
        uint256 numFacets;

        for (uint256 selectorIndex; selectorIndex < selectorCount; selectorIndex++) {
            bytes4 selector = ds.selectors[selectorIndex];
            address facetAddress_ = ds.selectorInfo[selector].facetAddress;
            bool continueLoop = false;
            // Find the functionSelectors array for selector and add selector to it
            for (uint256 facetIndex; facetIndex < numFacets; facetIndex++) {
                if (facets_[facetIndex].facetAddress == facetAddress_) {
                    facets_[facetIndex].functionSelectors[numFacetSelectors[facetIndex]] = selector;
                    numFacetSelectors[facetIndex]++;
                    continueLoop = true;
                    break;
                }
            }
            // If functionSelectors array exists for selector then continue loop
            if (continueLoop) {
                continueLoop = false;
                continue;
            }

            // Create a new functionSelectors array for selector
            facets_[numFacets].facetAddress = facetAddress_;
            facets_[numFacets].functionSelectors = new bytes4[](selectorCount);
            facets_[numFacets].functionSelectors[0] = selector;
            numFacetSelectors[numFacets] = 1;
            numFacets++;
        }
        for (uint256 facetIndex; facetIndex < numFacets; facetIndex++) {
            uint256 numSelectors = numFacetSelectors[facetIndex];
            bytes4[] memory selectors = facets_[facetIndex].functionSelectors;
            // Set the number of selectors
            assembly {
                mstore(selectors, numSelectors)
            }
        }
        // Set the number of facets
        assembly {
            mstore(facets_, numFacets)
        }
    }

    /// @inheritdoc IDiamondLoupe
    function facetFunctionSelectors(
        address _facet
    ) external view override returns (bytes4[] memory _facetFunctionSelectors) {
        DiamondStorage storage ds = s.diamondStorage();
        uint256 selectorCount = ds.selectors.length;
        uint256 numSelectors;
        _facetFunctionSelectors = new bytes4[](selectorCount);

        for (uint256 selectorIndex; selectorIndex < selectorCount; selectorIndex++) {
            bytes4 selector = ds.selectors[selectorIndex];
            address facetAddress_ = ds.selectorInfo[selector].facetAddress;
            if (_facet == facetAddress_) {
                _facetFunctionSelectors[numSelectors] = selector;
                numSelectors++;
            }
        }
        // Set the number of selectors in the array
        assembly {
            mstore(_facetFunctionSelectors, numSelectors)
        }
    }

    /// @inheritdoc IDiamondLoupe
    function facetAddresses() external view override returns (address[] memory facetAddresses_) {
        DiamondStorage storage ds = s.diamondStorage();
        uint256 selectorCount = ds.selectors.length;
        // Create an array set to the maximum size possible
        facetAddresses_ = new address[](selectorCount);
        uint256 numFacets;
        // Loop through function selectors
        for (uint256 selectorIndex; selectorIndex < selectorCount; selectorIndex++) {
            bytes4 selector = ds.selectors[selectorIndex];
            address facetAddress_ = ds.selectorInfo[selector].facetAddress;
            bool continueLoop = false;
            // See if we have collected the address already and break out of loop if we have
            for (uint256 facetIndex; facetIndex < numFacets; facetIndex++) {
                if (facetAddress_ == facetAddresses_[facetIndex]) {
                    continueLoop = true;
                    break;
                }
            }
            // Continue loop if we already have the address
            if (continueLoop) {
                continueLoop = false;
                continue;
            }
            // Include address
            facetAddresses_[numFacets] = facetAddress_;
            numFacets++;
        }
        // Set the number of facet addresses in the array
        assembly {
            mstore(facetAddresses_, numFacets)
        }
    }

    /// @inheritdoc IDiamondLoupe
    function facetAddress(bytes4 _functionSelector) external view override returns (address facetAddress_) {
        DiamondStorage storage ds = s.diamondStorage();
        facetAddress_ = ds.selectorInfo[_functionSelector].facetAddress;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

import "../transmuter/Storage.sol";

/// @notice IDiamondLoupe
/// @author Angle Labs, Inc.
/// @dev Reference: EIP-2535 Diamonds
/// @dev Forked from https://github.com/mudgen/diamond-3/blob/master/contracts/interfaces/IDiamondLoupe.sol by mudgen

interface IDiamondLoupe {
    /// @notice Gets all facet addresses and their four byte function selectors.
    /// @return facets_ Facet
    function facets() external view returns (Facet[] memory facets_);

    /// @notice Gets all the function selectors supported by a specific facet.
    /// @param _facet The facet address.
    /// @return facetFunctionSelectors_
    function facetFunctionSelectors(address _facet) external view returns (bytes4[] memory facetFunctionSelectors_);

    /// @notice Get all the facet addresses used by a diamond.
    /// @return facetAddresses_
    function facetAddresses() external view returns (address[] memory facetAddresses_);

    /// @notice Gets the facet that supports the given selector.
    /// @dev If facet is not found return address(0).
    /// @param _functionSelector The function selector.
    /// @return facetAddress_ The facet address.
    function facetAddress(bytes4 _functionSelector) external view returns (address facetAddress_);
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