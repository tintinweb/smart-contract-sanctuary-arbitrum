// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { EnumerableSet } from '../../data/EnumerableSet.sol';

library AccessControlStorage {
    struct RoleData {
        EnumerableSet.AddressSet members;
        bytes32 adminRole;
    }

    struct Layout {
        mapping(bytes32 => RoleData) roles;
    }

    bytes32 internal constant DEFAULT_ADMIN_ROLE = 0x00;

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.AccessControl');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IAccessControlInternal } from './IAccessControlInternal.sol';

/**
 * @title AccessControl interface
 */
interface IAccessControl is IAccessControlInternal {
    /*
     * @notice query whether role is assigned to account
     * @param role role to query
     * @param account account to query
     * @return whether role is assigned to account
     */
    function hasRole(
        bytes32 role,
        address account
    ) external view returns (bool);

    /*
     * @notice query admin role for given role
     * @param role role to query
     * @return admin role
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /*
     * @notice assign role to given account
     * @param role role to assign
     * @param account recipient of role assignment
     */
    function grantRole(bytes32 role, address account) external;

    /*
     * @notice unassign role from given account
     * @param role role to unassign
     * @parm account
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @notice relinquish role
     * @param role role to relinquish
     */
    function renounceRole(bytes32 role) external;

    /**
     * @notice Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(
        bytes32 role,
        uint256 index
    ) external view returns (address);

    /**
     * @notice Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Partial AccessControl interface needed by internal functions
 */
interface IAccessControlInternal {
    event RoleAdminChanged(
        bytes32 indexed role,
        bytes32 indexed previousAdminRole,
        bytes32 indexed newAdminRole
    );

    event RoleGranted(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    event RoleRevoked(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title Set implementation with enumeration functions
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts (MIT license)
 */
library EnumerableSet {
    error EnumerableSet__IndexOutOfBounds();

    struct Set {
        bytes32[] _values;
        // 1-indexed to allow 0 to signify nonexistence
        mapping(bytes32 => uint256) _indexes;
    }

    struct Bytes32Set {
        Set _inner;
    }

    struct AddressSet {
        Set _inner;
    }

    struct UintSet {
        Set _inner;
    }

    function at(
        Bytes32Set storage set,
        uint256 index
    ) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    function at(
        AddressSet storage set,
        uint256 index
    ) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    function at(
        UintSet storage set,
        uint256 index
    ) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    function contains(
        Bytes32Set storage set,
        bytes32 value
    ) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    function contains(
        AddressSet storage set,
        address value
    ) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    function contains(
        UintSet storage set,
        uint256 value
    ) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    function indexOf(
        Bytes32Set storage set,
        bytes32 value
    ) internal view returns (uint256) {
        return _indexOf(set._inner, value);
    }

    function indexOf(
        AddressSet storage set,
        address value
    ) internal view returns (uint256) {
        return _indexOf(set._inner, bytes32(uint256(uint160(value))));
    }

    function indexOf(
        UintSet storage set,
        uint256 value
    ) internal view returns (uint256) {
        return _indexOf(set._inner, bytes32(value));
    }

    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function add(
        Bytes32Set storage set,
        bytes32 value
    ) internal returns (bool) {
        return _add(set._inner, value);
    }

    function add(
        AddressSet storage set,
        address value
    ) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    function remove(
        Bytes32Set storage set,
        bytes32 value
    ) internal returns (bool) {
        return _remove(set._inner, value);
    }

    function remove(
        AddressSet storage set,
        address value
    ) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    function remove(
        UintSet storage set,
        uint256 value
    ) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    function toArray(
        Bytes32Set storage set
    ) internal view returns (bytes32[] memory) {
        return set._inner._values;
    }

    function toArray(
        AddressSet storage set
    ) internal view returns (address[] memory) {
        bytes32[] storage values = set._inner._values;
        address[] storage array;

        assembly {
            array.slot := values.slot
        }

        return array;
    }

    function toArray(
        UintSet storage set
    ) internal view returns (uint256[] memory) {
        bytes32[] storage values = set._inner._values;
        uint256[] storage array;

        assembly {
            array.slot := values.slot
        }

        return array;
    }

    function _at(
        Set storage set,
        uint256 index
    ) private view returns (bytes32) {
        if (index >= set._values.length)
            revert EnumerableSet__IndexOutOfBounds();
        return set._values[index];
    }

    function _contains(
        Set storage set,
        bytes32 value
    ) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    function _indexOf(
        Set storage set,
        bytes32 value
    ) private view returns (uint256) {
        unchecked {
            return set._indexes[value] - 1;
        }
    }

    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    function _add(
        Set storage set,
        bytes32 value
    ) private returns (bool status) {
        if (!_contains(set, value)) {
            set._values.push(value);
            set._indexes[value] = set._values.length;
            status = true;
        }
    }

    function _remove(
        Set storage set,
        bytes32 value
    ) private returns (bool status) {
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            unchecked {
                bytes32 last = set._values[set._values.length - 1];

                // move last value to now-vacant index

                set._values[valueIndex - 1] = last;
                set._indexes[last] = valueIndex;
            }
            // clear last index

            set._values.pop();
            delete set._indexes[value];

            status = true;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import { IPaymentModule } from "./IPaymentModule.sol";

interface ICrossPaymentModule {
    struct CrossPaymentSignatureInput {
        address payer;
        uint256 sourceChainId;
        uint256 paymentIndex;
        bytes signature;
    }

    struct ProcessCrossPaymentOutput {
        bytes32 platformId;
        uint32[] services;
        uint32[] serviceAmounts;
        address spender;
        uint256 destinationChainId;
        address payer;
        uint256 sourceChainId;
        uint256 paymentIndex;
    }

    function updateSignerAddress(address newSignerAddress) external;
    function processCrossPayment(
        IPaymentModule.ProcessPaymentInput memory paymentInput,
        address spender,
        uint256 destinationChainId
    ) external payable returns (uint256);
    function spendCrossPaymentSignature(address spender, ProcessCrossPaymentOutput memory output, bytes memory signature) external;
    function getSignerAddress() external view returns (address);
    function getCrossPaymentOutputByIndex(uint256 paymentIndex) external view returns (ProcessCrossPaymentOutput memory);
    function prefixedMessage(bytes32 hash) external pure returns (bytes32);
    function getHashedMessage(ProcessCrossPaymentOutput memory output) external pure returns (bytes32);
    function recoverSigner(bytes32 message, bytes memory signature) external pure returns (address);
    function checkSignature(ProcessCrossPaymentOutput memory output, bytes memory signature) external view;
    function getChainID() external view returns (uint256);

    /** EVENTS */
    event CrossPaymentProcessed(uint256 indexed previousBlock, uint256 indexed paymentIndex);
    event CrossPaymentSignatureSpent(uint256 indexed previousBlock, uint256 indexed sourceChainId, uint256 indexed paymentIndex);
    event SignerAddressUpdated(address indexed oldSigner, address indexed newSigner);

    /** ERRORS */
    error ProcessCrossPaymentError(string errorMessage);
    error CheckSignatureError(string errorMessage);
    error ProcessCrossPaymentSignatureError(string errorMessage);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

interface IPaymentModule {
    enum PaymentMethod {
        NATIVE,
        USD,
        ALTCOIN
    }

    enum PaymentType {
        NATIVE,
        GIFT,
        CROSSCHAIN
    }

    struct AcceptedToken {
        string name;
        PaymentMethod tokenType;
        address token;
        address router;
        bool isV2Router;
        uint256 slippageTolerance;
    }

    struct ProcessPaymentInput {
        bytes32 platformId;
        uint32[] services;
        uint32[] serviceAmounts;
        address referrer;
        address user;
        address tokenAddress;
    }

    struct ProcessPaymentOutput {
        ProcessPaymentInput processPaymentInput;
        uint256 usdPrice;
        uint256 paymentAmount;
        uint256 burnedAmount;
        uint256 treasuryShare;
        uint256 referrerShare;
    }

    struct ProcessCrossPaymentOutput {
        bytes32 platformId;
        uint32[] services;
        uint32[] serviceAmounts;
        address payer;
        address spender;
        uint256 sourceChainId;
        uint256 destinationChainId;
    }

    // solhint-disable-next-line func-name-mixedcase
    function PAYMENT_PROCESSOR_ROLE() external pure returns (bytes32);
    function adminWithdraw(address tokenAddress, uint256 amount, address treasury) external;
    function setUsdToken(address newUsdToken) external;
    function setRouterAddress(address newRouter) external;
    function addAcceptedToken(AcceptedToken memory acceptedToken) external;
    function removeAcceptedToken(address tokenAddress) external;
    function updateAcceptedToken(AcceptedToken memory acceptedToken) external;
    function setV3PoolFeeForTokenNative(address token, uint24 poolFee) external;
    function getUsdToken() external view returns (address);
    function processPayment(ProcessPaymentInput memory params) external payable returns (uint256);
    function getPaymentByIndex(uint256 paymentIndex) external view returns (ProcessPaymentOutput memory);
    function getQuoteTokenPrice(address token0, address token1) external view returns (uint256 price);
    function getV3PoolFeeForTokenWithNative(address token) external view returns (uint24);
    function isV2Router() external view returns (bool);
    function getRouterAddress() external view returns (address);
    function getAcceptedTokenByAddress(address tokenAddress) external view returns (AcceptedToken memory);
    function getAcceptedTokens() external view returns (address[] memory);

    /** EVENTS */
    event TokenBurned(uint256 indexed tokenBurnedLastBlock, address indexed tokenAddress, uint256 amount);
    event PaymentProcessed(uint256 indexed previousBlock, uint256 indexed paymentIndex);
    event TreasuryAddressUpdated(address indexed oldTreasury, address indexed newTreasury);

    /** ERRORS */
    error ProcessPaymentError(string errorMessage);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

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
    function diamondCut(FacetCut[] calldata _diamondCut, address _init, bytes calldata _calldata) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

interface IDiamondProxy {
    function implementation() external view returns (address);

    function setImplementation(address _implementation) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import { AccessControlStorage } from "@solidstate/contracts/access/access_control/AccessControlStorage.sol";
import { IAccessControl } from "@solidstate/contracts/access/access_control/IAccessControl.sol";
import { IERC20, IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import { ILaunchPadCommon } from "../interfaces/ILaunchPadCommon.sol";
import { ILaunchPadFactoryAdmin } from "../interfaces/ILaunchPadFactoryAdmin.sol";
import { ILaunchPadProject } from "../interfaces/ILaunchPadProject.sol";
import { ILaunchPadProjectAdmin } from "../interfaces/ILaunchPadProjectAdmin.sol";
import { LibLaunchPadFactoryStorage } from "../libraries/LibLaunchPadFactoryStorage.sol";
import { LibLaunchPadProjectStorage } from "../libraries/LibLaunchPadProjectStorage.sol";
import { IDiamondCut } from "../../common/diamonds/interfaces/IDiamondCut.sol";
import { ITokenLauncherFactory } from "../../token-launcher/interfaces/ITokenLauncherFactory.sol";
import { ITokenLauncherLiquidityPoolFactory } from "../../token-launcher/interfaces/ITokenLauncherLiquidityPoolFactory.sol";
import { ITokenFiErc20 } from "../../token-launcher/interfaces/ITokenFiErc20.sol";
import { IDiamondProxy } from "../../common/diamonds/interfaces/IDiamondProxy.sol";

contract LaunchPadFactoryAdminFacet is ILaunchPadFactoryAdmin {
    function removeLaunchpad(address launchpad) external override onlyAdmin {
        LibLaunchPadFactoryStorage.DiamondStorage storage ds = LibLaunchPadFactoryStorage.diamondStorage();
        require(ds.isLaunchPad[launchpad], "LaunchPadFactory: LaunchPad does not exist");
        address owner = ds.launchPadOwner[launchpad];
        // remove launchpad from owner
        for (uint256 i = 0; i < ds.launchPadsByOwner[owner].length; i++) {
            if (ds.launchPadsByOwner[owner][i] == launchpad) {
                ds.launchPadsByOwner[owner][i] = ds.launchPadsByOwner[owner][ds.launchPadsByOwner[owner].length - 1];
                ds.launchPadsByOwner[owner].pop();
                break;
            }
        }
        address[] memory investors = ILaunchPadProject(launchpad).getAllInvestors();
        // remove launchpad from investors
        for (uint256 i = 0; i < investors.length; i++) {
            for (uint256 j = 0; j < ds.launchPadsByInvestor[investors[i]].length; j++) {
                if (ds.launchPadsByInvestor[investors[i]][j] == launchpad) {
                    ds.launchPadsByInvestor[investors[i]][j] = ds.launchPadsByInvestor[investors[i]][ds.launchPadsByInvestor[investors[i]].length - 1];
                    ds.launchPadsByInvestor[investors[i]].pop();
                    break;
                }
            }
        }
        // remove launchpad
        for (uint256 i = 0; i < ds.launchPads.length; i++) {
            if (ds.launchPads[i] == launchpad) {
                ds.launchPads[i] = ds.launchPads[ds.launchPads.length - 1];
                ds.launchPads.pop();
                break;
            }
        }
        ds.launchPadOwner[launchpad] = address(0);
        ds.isLaunchPad[launchpad] = false;
        emit LibLaunchPadFactoryStorage.LaunchpadRemoved(launchpad, owner);
    }

    function upgradeLaunchPadProjectFacets(
        address launchPad,
        IDiamondCut.FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) external onlyAdmin {
        IDiamondCut(launchPad).diamondCut(_diamondCut, _init, _calldata);
    }

    function updateMaxTokenCreationDeadline(uint256 newMaxTokenCreationDeadline) external override onlyAdmin {
        LibLaunchPadFactoryStorage.DiamondStorage storage ds = LibLaunchPadFactoryStorage.diamondStorage();
        uint256 oldMaxTokenCreationDeadline = ds.maxTokenCreationDeadline;
        ds.maxTokenCreationDeadline = newMaxTokenCreationDeadline;
        emit LibLaunchPadFactoryStorage.MaxTokenCreationDeadlineUpdated(oldMaxTokenCreationDeadline, newMaxTokenCreationDeadline);
    }

    function updateSignerAddress(address newSignerAddress) external override onlyAdmin {
        LibLaunchPadFactoryStorage.DiamondStorage storage ds = LibLaunchPadFactoryStorage.diamondStorage();
        address oldSignerAddress = ds.signerAddress;
        ds.signerAddress = newSignerAddress;
        emit LibLaunchPadFactoryStorage.SignerAddressUpdated(oldSignerAddress, newSignerAddress);
    }

    function updateLaunchpadImplementation(address newLaunchpadImplementation) external override onlyAdmin {
        LibLaunchPadFactoryStorage.DiamondStorage storage ds = LibLaunchPadFactoryStorage.diamondStorage();
        ds.launchPadImplementation = newLaunchpadImplementation;
    }

    function setLaunchpadImplementation(address launchPad) external override {
        require(
            IAccessControl(address(this)).hasRole(AccessControlStorage.DEFAULT_ADMIN_ROLE, msg.sender) ||
                IAccessControl(launchPad).hasRole(LibLaunchPadProjectStorage.LAUNCHPAD_OWNER_ROLE, msg.sender),
            "LaunchPadFactory: Only admin or project owner can call this function"
        );

        LibLaunchPadFactoryStorage.DiamondStorage storage ds = LibLaunchPadFactoryStorage.diamondStorage();

        address _implementation = IDiamondProxy(launchPad).implementation();
        require(_implementation != ds.launchPadImplementation, "LaunchPadFactory: Implementation is already set");

        IDiamondProxy(launchPad).setImplementation(ds.launchPadImplementation);
    }

    function createTokenAfterICO(address launchPad) external payable override onlyLaunchPadOwner(launchPad) {
        require(
            ILaunchPadProject(launchPad).getLaunchPadInfo().tokenAddress == address(0),
            "LaunchPadFactory:createTokenAfterICO: Token address is already set"
        );

        LibLaunchPadFactoryStorage.DiamondStorage storage ds = LibLaunchPadFactoryStorage.diamondStorage();
        require(ds.launchPadOwner[launchPad] != address(0), "LaunchPadFactory:createTokenAfterICO: LaunchPad does not exist");

        CreateErc20Input memory createErc20Input = ds.tokenInfoByLaunchPadAddress[launchPad];

        // create a TokenFiErc20 token by using TokenLauncherFactory
        // payment would be ignored because launchpad factory has a discount NFT
        address tokenAddress = ITokenLauncherFactory(address(this)).createErc20{ value: msg.value }(
            ITokenLauncherFactory.CreateErc20Input({
                tokenInfo: ITokenFiErc20.TokenInfo({
                    name: createErc20Input.name,
                    symbol: createErc20Input.symbol,
                    logo: createErc20Input.logo,
                    decimals: createErc20Input.decimals,
                    initialSupply: ILaunchPadProject(launchPad).totalTokensSold() + createErc20Input.treasuryReserved,
                    maxSupply: createErc20Input.maxSupply,
                    treasury: address(this),
                    owner: address(this),
                    fees: ITokenFiErc20.Fees({
                        transferFee: ITokenFiErc20.FeeDetails({ percentage: 0, onlyOnSwaps: false }),
                        burn: ITokenFiErc20.FeeDetails({ percentage: 0, onlyOnSwaps: false }),
                        reflection: ITokenFiErc20.FeeDetails({ percentage: 0, onlyOnSwaps: false }),
                        buyback: ITokenFiErc20.FeeDetails({ percentage: 0, onlyOnSwaps: false })
                    }),
                    buybackDetails: ITokenFiErc20.BuybackDetails({
                        pairToken: address(0),
                        router: address(0),
                        liquidityBasisPoints: 0,
                        priceImpactBasisPoints: 0
                    })
                }),
                referrer: address(0),
                paymentToken: address(0)
            })
        );

        ILaunchPadProjectAdmin(launchPad).setTokenAddress(tokenAddress);
        ITokenFiErc20(tokenAddress).addExemptAddress(launchPad);
        ITokenFiErc20(tokenAddress).updateTreasury(createErc20Input.owner);
        IAccessControl(tokenAddress).grantRole(AccessControlStorage.DEFAULT_ADMIN_ROLE, createErc20Input.owner);
        IAccessControl(tokenAddress).renounceRole(AccessControlStorage.DEFAULT_ADMIN_ROLE);

        // Transfer the totalTokensSold() amount to the launchpad
        IERC20(tokenAddress).transfer(launchPad, ILaunchPadProject(launchPad).totalTokensSold());
        // Transfer the treasury amount to the treasury
        if (createErc20Input.treasuryReserved > 0) {
            IERC20(tokenAddress).transfer(createErc20Input.owner, createErc20Input.treasuryReserved);
        }
    }

    function setExistingTokenAfterICO(address launchPad, address tokenAddress, uint256 amount) external override onlyLaunchPadOwner(launchPad) {
        LibLaunchPadFactoryStorage.DiamondStorage storage ds = LibLaunchPadFactoryStorage.diamondStorage();
        require(ds.launchPadOwner[launchPad] != address(0), "LaunchPadFactory:setExistingTokenAfterICO: LaunchPad does not exist");
        require(
            ILaunchPadProject(launchPad).getLaunchPadInfo().tokenAddress == address(0),
            "LaunchPadFactory:setExistingTokenAfterICO: Token address is already set"
        );

        ILaunchPadProjectAdmin(launchPad).setTokenAddress(tokenAddress);

        // Transfer tokens from the user to this
        uint256 initialBalance = IERC20(tokenAddress).balanceOf(launchPad);
        IERC20(tokenAddress).transferFrom(msg.sender, launchPad, amount);
        uint256 receivedTokens = IERC20(tokenAddress).balanceOf(launchPad) - initialBalance;
        require(
            receivedTokens >= ILaunchPadProject(launchPad).totalTokensSold(),
            "LaunchPadFactory:setExistingTokenAfterICO: Token has tax, please exempt launchpad address"
        );
    }

    function setExistingTokenAfterTransfer(address launchPad, address tokenAddress) external override onlyLaunchPadOwner(launchPad) {
        LibLaunchPadFactoryStorage.DiamondStorage storage ds = LibLaunchPadFactoryStorage.diamondStorage();
        require(ds.launchPadOwner[launchPad] != address(0), "LaunchPadFactory:setExistingTokenAfterTransfer: LaunchPad does not exist");
        require(
            ILaunchPadProject(launchPad).getLaunchPadInfo().tokenAddress == address(0),
            "LaunchPadFactory:setExistingTokenAfterTransfer: Token address is already set"
        );
        ILaunchPadProjectAdmin(launchPad).setTokenAddress(tokenAddress);

        // Check if the launchpad has received at least the total tokens sold
        uint256 currentBalance = IERC20(tokenAddress).balanceOf(launchPad);
        require(
            currentBalance >= ILaunchPadProject(launchPad).totalTokensSold(),
            "LaunchPadFactory:setExistingTokenAfterTransfer: Launchpad has not received tokens yet"
        );
    }

    function createLaunchpadV2LiquidityPool(address launchPad) external payable override onlyLaunchPadOwner(launchPad) {
        LibLaunchPadFactoryStorage.DiamondStorage storage ds = LibLaunchPadFactoryStorage.diamondStorage();
        require(ds.launchPadOwner[launchPad] != address(0), "LaunchPadFactory:createLaunchpadV2LiquidityPool: LaunchPad does not exist");

        ILaunchPadCommon.LaunchPadInfo memory launchPadInfo = ILaunchPadProject(launchPad).getLaunchPadInfo();
        require(block.timestamp > launchPadInfo.startTimestamp + launchPadInfo.duration, "Sale is still ongoing");
        require(
            ILaunchPadProject(launchPad).getLaunchPadInfo().tokenAddress != address(0),
            "LaunchPadFactory:createLaunchpadV2LiquidityPool: Token address is 0 - token does not exist"
        );
        require(launchPadInfo.idoInfo.enabled == true, "LaunchPad:createLaunchpadV2LiquidityPool: IDO is not enabled");

        uint256 tokenDecimals = IERC20Metadata(launchPadInfo.tokenAddress).decimals();
        ITokenLauncherLiquidityPoolFactory.CreateV2LpTlInput memory createV2Input = ITokenLauncherLiquidityPoolFactory.CreateV2LpTlInput({
            createV2LpInput: ITokenLauncherLiquidityPoolFactory.CreateV2LpInput({
                owner: launchPadInfo.owner,
                treasury: launchPadInfo.owner,
                liquidityPoolDetails: ITokenLauncherLiquidityPoolFactory.LiquidityPoolDetails({
                    sourceToken: launchPadInfo.tokenAddress,
                    pairedToken: launchPadInfo.idoInfo.pairToken,
                    amountSourceToken: launchPadInfo.idoInfo.amountToList,
                    amountPairedToken: (launchPadInfo.idoInfo.price * launchPadInfo.idoInfo.amountToList) / (10 ** tokenDecimals),
                    routerAddress: launchPadInfo.idoInfo.dexRouter
                }),
                lockLPDetails: ITokenLauncherLiquidityPoolFactory.LockLPDetails({
                    lockLPTokenPercentage: 0,
                    unlockTimestamp: 0,
                    beneficiary: launchPadInfo.owner,
                    isVesting: false
                })
            }),
            buybackDetails: ITokenFiErc20.BuybackDetails({
                pairToken: launchPadInfo.idoInfo.pairToken,
                router: launchPadInfo.idoInfo.dexRouter,
                liquidityBasisPoints: 0,
                priceImpactBasisPoints: 0
            })
        });

        ITokenLauncherLiquidityPoolFactory(address(this)).createTokenLauncherV2LiquidityPool{ value: msg.value }(createV2Input);
    }

    function updateLaunchPadOwner(address launchPadAddress, address newOwner) external override onlyLaunchPadOwner(launchPadAddress) {
        LibLaunchPadFactoryStorage.DiamondStorage storage ds = LibLaunchPadFactoryStorage.diamondStorage();

        address owner = ds.launchPadOwner[launchPadAddress];
        require(owner != newOwner, "LaunchPadStore: Same owner");
        require(newOwner != address(0), "LaunchPadStore: New owner cannot be 0");
        address[] storage launchPads = ds.launchPadsByOwner[owner];

        bool _launchPadExists = false;
        for (uint256 i = 0; i < ds.launchPadsByOwner[owner].length; i++) {
            if (ds.launchPadsByOwner[owner][i] == launchPadAddress) {
                ds.launchPadsByOwner[owner][i] = ds.launchPadsByOwner[owner][launchPads.length - 1];
                ds.launchPadsByOwner[owner].pop();
                _launchPadExists = true;
                break;
            }
        }
        require(_launchPadExists == true, "LaunchPadStore: LaunchPad does not exist");

        ds.launchPadsByOwner[newOwner].push(launchPadAddress);
        ds.launchPadOwner[launchPadAddress] = newOwner;
        emit LibLaunchPadFactoryStorage.LaunchPadOwnerUpdated(ds.currentBlockLaunchPadOwnerUpdated, owner, newOwner);
        ds.currentBlockLaunchPadOwnerUpdated = block.number;
    }

    function updateLaunchPadMaxDurationIncrement(uint256 newMaxDurationIncrement) external override onlyAdmin {
        LibLaunchPadFactoryStorage.DiamondStorage storage ds = LibLaunchPadFactoryStorage.diamondStorage();
        ds.maxDurationIncrement = newMaxDurationIncrement;
    }

    modifier onlyAdmin() {
        require(
            IAccessControl(address(this)).hasRole(AccessControlStorage.DEFAULT_ADMIN_ROLE, msg.sender),
            "LaunchPadFactory: Only admin can call this function"
        );
        _;
    }

    modifier onlyLaunchPadOwner(address launchPad) {
        require(
            IAccessControl(launchPad).hasRole(LibLaunchPadProjectStorage.LAUNCHPAD_OWNER_ROLE, msg.sender),
            "LaunchPadFactory: Only project owner can call this function"
        );
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

interface ILaunchPadCommon {
    enum LaunchPadType {
        FlokiPadCreatedBefore,
        FlokiPadCreatedAfter
    }

    struct IdoInfo {
        bool enabled;
        address dexRouter;
        address pairToken;
        uint256 price;
        uint256 amountToList;
    }

    struct RefundInfo {
        uint256 penaltyFeePercent;
        uint256 expireDuration;
    }

    struct FundTarget {
        uint256 softCap;
        uint256 hardCap;
    }

    struct ReleaseSchedule {
        uint256 timestamp;
        uint256 percent;
    }

    struct ReleaseScheduleV2 {
        uint256 timestamp;
        uint256 percent;
        bool isVesting;
    }

    struct CreateErc20Input {
        string name;
        string symbol;
        string logo;
        uint8 decimals;
        uint256 maxSupply;
        address owner;
        uint256 treasuryReserved;
    }

    struct LaunchPadInfo {
        address owner;
        address tokenAddress;
        address paymentTokenAddress;
        uint256 price;
        FundTarget fundTarget;
        uint256 maxInvestPerWallet;
        uint256 startTimestamp;
        uint256 duration;
        uint256 tokenCreationDeadline;
        RefundInfo refundInfo;
        IdoInfo idoInfo;
    }

    struct CreateLaunchPadInput {
        LaunchPadType launchPadType;
        LaunchPadInfo launchPadInfo;
        ReleaseScheduleV2[] releaseSchedule;
        CreateErc20Input createErc20Input;
        address referrer;
        bool isSuperchargerEnabled;
        uint256 feePercentage;
        address paymentTokenAddress;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import { ILaunchPadCommon } from "./ILaunchPadCommon.sol";
import { ICrossPaymentModule } from "../../common/admin/interfaces/ICrossPaymentModule.sol";

interface ILaunchPadFactory {
    struct StoreLaunchPadInput {
        ILaunchPadCommon.LaunchPadType launchPadType;
        address launchPadAddress;
        address owner;
        address referrer;
    }

    function addInvestorToLaunchPad(address investor) external;
    function createLaunchPad(ILaunchPadCommon.CreateLaunchPadInput memory input) external payable;
    function createLaunchPadWithPaymentSignature(
        ILaunchPadCommon.CreateLaunchPadInput memory storeInput,
        ICrossPaymentModule.CrossPaymentSignatureInput memory crossPaymentSignatureInput
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import { ILaunchPadCommon } from "./ILaunchPadCommon.sol";
import { IDiamondCut } from "../../common/diamonds/interfaces/IDiamondCut.sol";

interface ILaunchPadFactoryAdmin is ILaunchPadCommon {
    function removeLaunchpad(address launchpad) external;

    function upgradeLaunchPadProjectFacets(address launchPad, IDiamondCut.FacetCut[] memory _diamondCut, address _init, bytes memory _calldata) external;

    function updateMaxTokenCreationDeadline(uint256 newMaxTokenCreationDeadline) external;

    function updateSignerAddress(address newSignerAddress) external;

    function updateLaunchpadImplementation(address newLaunchpadImplementation) external;

    function setLaunchpadImplementation(address launchPad) external;

    function createTokenAfterICO(address launchPadAddress) external payable;

    function setExistingTokenAfterICO(address launchPad, address tokenAddress, uint256 amount) external;

    function setExistingTokenAfterTransfer(address launchPad, address tokenAddress) external;

    function createLaunchpadV2LiquidityPool(address launchPadAddress) external payable;

    function updateLaunchPadOwner(address tokenAddress, address newOwner) external;

    function updateLaunchPadMaxDurationIncrement(uint256 newMaxDurationIncrement) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import { ILaunchPadCommon } from "./ILaunchPadCommon.sol";

interface ILaunchPadProject {
    struct PurchasedInfo {
        uint256 purchasedTokenAmount;
        uint256 claimedTokenAmount;
        uint256 paidTokenAmount;
    }

    struct BuyTokenInput {
        uint256 tokenAmount;
        uint256 tier;
        uint256 nonce;
        uint256 deadline;
        bytes signature;
    }

    function buyTokens(uint256 tokenAmount) external payable;

    function buyTokensWithSupercharger(BuyTokenInput memory input) external payable;

    function checkSignature(address wallet, uint256 tier, uint256 nonce, uint256 deadline, bytes memory signature) external view;

    function claimTokens() external;

    function getAllInvestors() external view returns (address[] memory);

    function getCurrentTier() external view returns (uint256);

    function getFeeShare() external view returns (uint256);

    function getHardCapPerTier(uint256 tier) external view returns (uint256);

    function getInvestorAddressByIndex(uint256 index) external view returns (address);

    function getInvestorsLength() external view returns (uint256);

    function getLaunchPadAddress() external view returns (address);

    function getLaunchPadInfo() external view returns (ILaunchPadCommon.LaunchPadInfo memory);

    function getMaxInvestPerWalletPerTier(uint256 tier) external view returns (uint256);

    function getNextNonce(address user) external view returns (uint256);

    function getProjectOwnerRole() external view returns (bytes32);

    function getPurchasedInfoByUser(address user) external view returns (PurchasedInfo memory);

    function getReleasedTokensPercentage() external view returns (uint256);

    function getReleaseSchedule() external view returns (ILaunchPadCommon.ReleaseScheduleV2[] memory);

    function getTokensAvailableToBeClaimed(address user) external view returns (uint256);

    function getTokenCreationDeadline() external view returns (uint256);

    function getTotalRaised() external view returns (uint256);

    function isSuperchargerEnabled() external view returns (bool);

    function recoverSigner(bytes32 message, bytes memory signature) external view returns (address);

    function refund(uint256 tokenAmount) external;

    function refundOnSoftCapFailure() external;

    function refundOnTokenCreationExpired(uint256 tokenAmount) external;

    function tokenDecimals() external view returns (uint256);

    function totalTokensClaimed() external view returns (uint256);

    function totalTokensSold() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import { ILaunchPadCommon } from "./ILaunchPadCommon.sol";

interface ILaunchPadProjectAdmin {
    function setSupercharger(bool isSuperchargerEnabled) external;

    function updateStartTimestamp(uint256 newStartTimestamp) external;

    function extendDuration(uint256 durationIncrease) external;

    function updateReleaseSchedule(ILaunchPadCommon.ReleaseScheduleV2[] memory releaseSchedule) external;

    function setTokenAddress(address tokenAddress) external;

    function withdrawFees() external;

    function withdrawTokens(address tokenAddress) external;

    function withdrawTokensToRecipient(address tokenAddress, address recipient) external;

    /** ERRORS */
    error UPDATE_RELEASE_SCHEDULE_ERROR(string errorMessage);
    error UPDATE_START_TIMESTAMP_ERROR(string errorMessage);
    error EXTEND_DURATION_ERROR(string errorMessage);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import { ILaunchPadCommon } from "../interfaces/ILaunchPadCommon.sol";
import { ILaunchPadFactory } from "../interfaces/ILaunchPadFactory.sol";
import { ILaunchPadProject } from "../interfaces/ILaunchPadProject.sol";
import { ILaunchPadProjectAdmin } from "../interfaces/ILaunchPadProjectAdmin.sol";

library LibLaunchPadFactoryStorage {
    bytes32 internal constant DIAMOND_STORAGE_POSITION = keccak256("tokenfi.launchpad.factory.diamond.storage");

    struct DiamondStorage {
        address[] launchPads;
        mapping(address => address[]) launchPadsByOwner;
        mapping(address => address[]) launchPadsByInvestor;
        mapping(address => address) launchPadOwner;
        mapping(address => bool) isLaunchPad;
        mapping(address => ILaunchPadCommon.CreateErc20Input) tokenInfoByLaunchPadAddress;
        uint256 currentBlockLaunchPadCreated;
        uint256 currentBlockLaunchPadOwnerUpdated;
        address _tokenLauncherERC20; // deprecated (available on Diamond itself)
        address _tokenLauncherStore; // deprecated (available on Diamond itself)
        address _tokenLauncherBuybackHandler; // deprecated (available on Diamond itself)
        address launchPadProjectFacet;
        address accessControlFacet;
        address pausableFacet;
        address loupeFacet;
        address proxyFacet;
        address launchPadProjectDiamondInit;
        address _tokenfiToken; // deprecated (available on LaunchPadPaymentStorage)
        address _usdToken; // deprecated (available on LaunchPadPaymentStorage)
        address _router; // deprecated (available on LaunchPadPaymentStorage)
        address _treasury; // deprecated (available on LaunchPadPaymentStorage)
        address signerAddress;
        uint256 maxTokenCreationDeadline;
        uint256[] _superChargerMultiplierByTier; // deprecated (cause of wrong updates by v1)
        uint256[] _superChargerHeadstartByTier; // deprecated (cause of wrong updates by v1)
        uint256[] _superChargerTokensPercByTier; // deprecated (cause of wrong updates by v1)
        uint256 maxDurationIncrement;
        address launchPadProjectAdminFacet;
        address launchPadImplementation;
        uint256[] superChargerMultiplierByTier;
        uint256[] superChargerHeadstartByTier;
        uint256[] superChargerTokensPercByTier;
    }

    event LaunchPadCreated(uint256 indexed previousBlock, ILaunchPadFactory.StoreLaunchPadInput launchPad);
    event LaunchPadOwnerUpdated(uint256 indexed previousBlock, address owner, address newOwner);
    event MaxTokenCreationDeadlineUpdated(uint256 indexed previousMaxTokenCreationDeadline, uint256 newMaxTokenCreationDeadline);
    event LaunchpadRemoved(address indexed launchPadAddress, address indexed owner);
    event SignerAddressUpdated(address indexed previousSignerAddress, address indexed newSignerAddress);

    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            ds.slot := position
        }
    }

    function getLaunchPadProjectSelectors() internal pure returns (bytes4[] memory) {
        bytes4[] memory functionSelectors = new bytes4[](29);
        functionSelectors[0] = ILaunchPadProject.buyTokens.selector;
        functionSelectors[1] = ILaunchPadProject.buyTokensWithSupercharger.selector;
        functionSelectors[2] = ILaunchPadProject.checkSignature.selector;
        functionSelectors[3] = ILaunchPadProject.claimTokens.selector;
        functionSelectors[4] = ILaunchPadProject.getAllInvestors.selector;
        functionSelectors[5] = ILaunchPadProject.getCurrentTier.selector;
        functionSelectors[6] = ILaunchPadProject.getFeeShare.selector;
        functionSelectors[7] = ILaunchPadProject.getHardCapPerTier.selector;
        functionSelectors[8] = ILaunchPadProject.getInvestorAddressByIndex.selector;
        functionSelectors[9] = ILaunchPadProject.getInvestorsLength.selector;
        functionSelectors[10] = ILaunchPadProject.getLaunchPadAddress.selector;
        functionSelectors[11] = ILaunchPadProject.getLaunchPadInfo.selector;
        functionSelectors[12] = ILaunchPadProject.getMaxInvestPerWalletPerTier.selector;
        functionSelectors[13] = ILaunchPadProject.getNextNonce.selector;
        functionSelectors[14] = ILaunchPadProject.getProjectOwnerRole.selector;
        functionSelectors[15] = ILaunchPadProject.getPurchasedInfoByUser.selector;
        functionSelectors[16] = ILaunchPadProject.getReleasedTokensPercentage.selector;
        functionSelectors[17] = ILaunchPadProject.getReleaseSchedule.selector;
        functionSelectors[18] = ILaunchPadProject.getTokensAvailableToBeClaimed.selector;
        functionSelectors[19] = ILaunchPadProject.getTokenCreationDeadline.selector;
        functionSelectors[20] = ILaunchPadProject.getTotalRaised.selector;
        functionSelectors[21] = ILaunchPadProject.isSuperchargerEnabled.selector;
        functionSelectors[22] = ILaunchPadProject.recoverSigner.selector;
        functionSelectors[23] = ILaunchPadProject.refund.selector;
        functionSelectors[24] = ILaunchPadProject.refundOnSoftCapFailure.selector;
        functionSelectors[25] = ILaunchPadProject.refundOnTokenCreationExpired.selector;
        functionSelectors[26] = ILaunchPadProject.tokenDecimals.selector;
        functionSelectors[27] = ILaunchPadProject.totalTokensClaimed.selector;
        functionSelectors[28] = ILaunchPadProject.totalTokensSold.selector;

        return functionSelectors;
    }

    function getLaunchPadProjectAdminSelectors() internal pure returns (bytes4[] memory) {
        bytes4[] memory functionSelectors = new bytes4[](9);
        functionSelectors[0] = ILaunchPadProjectAdmin.setSupercharger.selector;
        functionSelectors[1] = ILaunchPadProjectAdmin.setTokenAddress.selector;
        functionSelectors[2] = ILaunchPadProjectAdmin.withdrawFees.selector;
        functionSelectors[3] = ILaunchPadProjectAdmin.withdrawTokens.selector;
        functionSelectors[4] = ILaunchPadProjectAdmin.withdrawTokensToRecipient.selector;
        functionSelectors[5] = ILaunchPadProjectAdmin.updateStartTimestamp.selector;
        functionSelectors[6] = ILaunchPadProjectAdmin.extendDuration.selector;
        functionSelectors[7] = ILaunchPadProjectAdmin.updateReleaseSchedule.selector;

        return functionSelectors;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import { ILaunchPadCommon } from "../interfaces/ILaunchPadProject.sol";
import { ILaunchPadProject } from "../interfaces/ILaunchPadProject.sol";

/// @notice storage for LaunchPads created by users

library LibLaunchPadProjectStorage {
    bytes32 internal constant DIAMOND_STORAGE_POSITION = keccak256("tokenfi.launchpad.project.diamond.storage");
    bytes32 internal constant LAUNCHPAD_OWNER_ROLE = keccak256("LAUNCHPAD_OWNER_ROLE");
    bytes32 internal constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    struct DiamondStorage {
        ILaunchPadCommon.LaunchPadInfo launchPadInfo;
        address launchPadFactory;
        uint256 totalTokensSold;
        uint256 totalTokensClaimed;
        uint256 feePercentage; // in basis points 1e4
        bool feeShareCollected;
        bool isSuperchargerEnabled;
        ILaunchPadCommon.ReleaseSchedule[] releaseSchedule;
        ILaunchPadCommon.ReleaseScheduleV2[] releaseScheduleV2;
        mapping(address => ILaunchPadProject.PurchasedInfo) purchasedInfoByUser;
        address[] investors;
        mapping(address => uint256[]) buyTokenNonces;
    }

    event TokensPurchased(address indexed buyer, uint256 amount);
    event TokensRefunded(address indexed buyer, uint256 amount);

    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            ds.slot := position
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import { ICrossPaymentModule } from "../../common/admin/interfaces/ICrossPaymentModule.sol";

interface ITokenFiErc1155 {
    struct TokenInfo {
        string name;
        string symbol;
        string collectionLogo;
        string baseURI;
        bool isPublicMintEnabled;
        bool isAdminMintEnabled;
        address owner;
    }

    struct CreateTokenInput {
        uint256 tokenId;
        uint256 maxSupply;
        uint256 publicMintUsdPrice;
        uint8 decimals;
        string uri;
    }

    function adminMint(address account, uint256 id, uint256 amount) external;
    function setTokenInfo(TokenInfo memory _newTokenInfo) external;
    function createToken(CreateTokenInput memory input) external;
    function setTokenPublicMintPrice(uint256 _tokenId, uint256 _price) external;
    function setTokenUri(uint256 _tokenId, string memory _uri) external;
    function mint(address account, uint256 id, uint256 amount, address paymentToken, address referrer) external payable;
    function mintWithPaymentSignature(
        address account,
        uint256 id,
        uint256 amount,
        ICrossPaymentModule.CrossPaymentSignatureInput memory crossPaymentSignatureInput
    ) external;
    function tokenInfo() external view returns (TokenInfo memory);
    function maxSupply(uint256 tokenId) external view returns (uint256);
    function decimals(uint256 tokenId) external view returns (uint256);
    function paymentServiceIndexByTokenId(uint256 tokenId) external view returns (uint256);
    function exists(uint256 id) external view returns (bool);
    function getExistingTokenIds() external view returns (uint256[] memory);
    function paymentModule() external view returns (address);

    event TokenInfoUpdated(TokenInfo indexed oldTokenInfo, TokenInfo indexed newTokenInfo);
    event MintPaymentProccessed(address indexed user, uint256 indexed paymentId);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

interface ITokenFiErc20 {
    struct FeeDetails {
        uint256 percentage;
        bool onlyOnSwaps;
    }

    struct Fees {
        FeeDetails transferFee;
        FeeDetails burn;
        FeeDetails reflection;
        FeeDetails buyback;
    }

    struct BuybackDetails {
        address pairToken;
        address router;
        uint256 liquidityBasisPoints;
        uint256 priceImpactBasisPoints;
    }

    struct TokenInfo {
        string name;
        string symbol;
        string logo;
        uint8 decimals;
        uint256 initialSupply;
        uint256 maxSupply;
        address treasury;
        address owner;
        Fees fees;
        BuybackDetails buybackDetails;
    }

    struct TotalReflection {
        uint256 tTotal;
        uint256 rTotal;
        uint256 tFeeTotal;
    }

    struct ReflectionInfo {
        TotalReflection totalReflection;
        mapping(address => uint256) rOwned;
        mapping(address => uint256) tOwned;
        mapping(address => bool) isExcludedFromReflectionRewards;
        address[] excluded;
    }

    /** ONLY ROLES */
    function mint(address to, uint256 amount) external;
    function updateTokenLauncher(address _newTokenLauncher) external;
    function updateTreasury(address _newTreasury) external;
    function setName(string memory name) external;
    function setSymbol(string memory symbol) external;
    function setDecimals(uint8 decimals) external;
    function updateFees(Fees memory _fees) external;
    function setBuybackDetails(BuybackDetails memory _buybackDetails) external;
    function setBuybackHandler(address _newBuybackHandler) external;
    function addExchangePool(address pool) external;
    function removeExchangePool(address pool) external;
    function addExemptAddress(address account) external;
    function removeExemptAddress(address account) external;

    /** VIEW */
    function fees() external view returns (Fees memory);
    function tokenInfo() external view returns (TokenInfo memory);
    function buybackHandler() external view returns (address);
    function isExchangePool(address pool) external view returns (bool);
    function isExemptedFromTax(address account) external view returns (bool);
    function isReflectionToken() external view returns (bool);

    /** REFLECTION Implemetation */
    function reflect(uint256 tAmount) external;
    function excludeAccount(address account) external;
    function includeAccount(address account) external;
    function isExcludedFromReflectionRewards(address account) external view returns (bool);
    function totalReflection() external view returns (TotalReflection memory);
    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) external view returns (uint256);
    function tokenFromReflection(uint256 rAmount) external view returns (uint256);
    function totalFees() external view returns (uint256);

    event ExemptedAdded(address indexed account);
    event ExemptedRemoved(address indexed account);
    event ExchangePoolAdded(address indexed pool);
    event ExchangePoolRemoved(address indexed pool);
    event TokenLauncherUpdated(address indexed oldTokenLauncher, address indexed newTokenLauncher);
    event TransferTax(address indexed account, address indexed receiver, uint256 amount, string indexed taxType);
    event BuybackHandlerUpdated(address indexed oldBuybackHandler, address indexed newBuybackHandler);
    event BuybackDetailsUpdated(address indexed router, address indexed pairToken, uint256 liquidityBasisPoints, uint256 priceImpactBasisPoints);
    event TreasuryUpdated(address indexed oldTreasury, address indexed newTreasury);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import { ICrossPaymentModule } from "../../common/admin/interfaces/ICrossPaymentModule.sol";

interface ITokenFiErc721 {
    enum PaymentServices {
        TOKEN_MINT
    }

    struct TokenInfo {
        string name;
        string symbol;
        string collectionLogo;
        string baseURI;
        uint256 maxSupply;
        bool isPublicMintEnabled;
        bool isAdminMintEnabled;
        address owner;
    }

    function adminMint(address _to) external;
    function adminMintBatch(address _to, uint256 _amount) external;
    function setTokenInfo(TokenInfo memory _newTokenInfo) external;
    function setTokenUri(uint256 tokenId, string memory uri) external;
    function mint(address _to, address paymentToken, address referrer) external payable;
    function mintWithPaymentSignature(address _to, ICrossPaymentModule.CrossPaymentSignatureInput memory crossPaymentSignatureInput) external;
    function mintBatch(address _to, uint256 _amount, address paymentToken, address referrer) external payable;
    function mintBatchWithPaymentSignature(
        address _to,
        uint256 _amount,
        ICrossPaymentModule.CrossPaymentSignatureInput memory crossPaymentSignatureInput
    ) external;
    function tokenInfo() external view returns (TokenInfo memory);
    function paymentModule() external view returns (address);

    event TokenInfoUpdated(TokenInfo indexed oldTokenInfo, TokenInfo indexed newTokenInfo);
    event MintPaymentProccessed(address indexed user, uint256 indexed paymentId);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

interface ITokenLauncherCommon {
    enum TokenType {
        ERC20,
        ERC721,
        ERC1155
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import { ITokenLauncherCommon } from "./ITokenLauncherCommon.sol";
import { ITokenFiErc20 } from "./ITokenFiErc20.sol";
import { ITokenFiErc721 } from "./ITokenFiErc721.sol";
import { ITokenFiErc1155 } from "./ITokenFiErc1155.sol";
import { ICrossPaymentModule } from "../../common/admin/interfaces/ICrossPaymentModule.sol";

interface ITokenLauncherFactory is ITokenLauncherCommon {
    struct CreateErc20Input {
        ITokenFiErc20.TokenInfo tokenInfo;
        address referrer;
        address paymentToken;
    }

    struct PublicErc721MintPaymentInfo {
        uint256 usdPrice;
        address treasury;
        uint256 burnBasisPoints;
        uint256 referrerBasisPoints;
    }

    struct CreateErc721Input {
        ITokenFiErc721.TokenInfo tokenInfo;
        PublicErc721MintPaymentInfo publicMintPaymentInfo;
        address referrer;
        address paymentToken;
    }

    struct PublicErc1155MintPaymentInfo {
        address treasury;
        uint256 burnBasisPoints;
        uint256 referrerBasisPoints;
    }

    struct CreateErc1155Input {
        ITokenFiErc1155.TokenInfo tokenInfo;
        PublicErc1155MintPaymentInfo publicMintPaymentInfo;
        ITokenFiErc1155.CreateTokenInput[] initialTokens;
        address referrer;
        address paymentToken;
    }

    struct StoreTokenInput {
        address tokenAddress;
        address owner;
        address referrer;
        uint256 paymentIndex;
        TokenType tokenType;
    }

    function createErc20(CreateErc20Input memory input) external payable returns (address tokenAddress);
    function createErc20WithPaymentSignature(
        CreateErc20Input memory input,
        ICrossPaymentModule.CrossPaymentSignatureInput memory crossPaymentSignatureInput
    ) external returns (address tokenAddress);
    function createErc721(CreateErc721Input memory input) external payable returns (address tokenAddress);
    function createErc721WithPaymentSignature(
        CreateErc721Input memory input,
        ICrossPaymentModule.CrossPaymentSignatureInput memory crossPaymentSignatureInput
    ) external returns (address tokenAddress);
    function createErc1155(CreateErc1155Input memory input) external payable returns (address tokenAddress);
    function createErc1155WithPaymentSignature(
        CreateErc1155Input memory input,
        ICrossPaymentModule.CrossPaymentSignatureInput memory crossPaymentSignatureInput
    ) external returns (address tokenAddress);

    /** EVNETS */
    event TokenCreated(uint256 indexed currentBlockTokenCreated, StoreTokenInput input);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import { ITokenFiErc20 } from "./ITokenFiErc20.sol";

interface ITokenLauncherLiquidityPoolFactory {
    struct LiquidityPoolDetails {
        address sourceToken;
        address pairedToken;
        uint256 amountSourceToken;
        uint256 amountPairedToken;
        address routerAddress;
    }

    struct LockLPDetails {
        uint256 lockLPTokenPercentage;
        uint256 unlockTimestamp;
        address beneficiary;
        bool isVesting;
    }

    struct CreateV2LpInput {
        address owner;
        address treasury;
        LiquidityPoolDetails liquidityPoolDetails;
        LockLPDetails lockLPDetails;
    }

    struct CreateV2LpTlInput {
        CreateV2LpInput createV2LpInput;
        ITokenFiErc20.BuybackDetails buybackDetails;
    }

    struct CreateV2Output {
        address liquidityPoolToken;
        uint256 liquidity;
    }

    struct RegisterLiquidityPoolInput {
        address tokenAddress;
        address liquidityPoolToken;
    }

    function createTokenLauncherV2LiquidityPool(ITokenLauncherLiquidityPoolFactory.CreateV2LpTlInput memory input) external payable;
    function createV2LiquidityPool(CreateV2LpInput memory input) external payable;
    function registerLiquidityPool(RegisterLiquidityPoolInput memory input) external;
    function getLiquidityPoolTokensByToken(address token) external view returns (address[] memory);

    event TokenLiquidityCreated(address indexed owner, LiquidityPoolDetails liquidityPoolDetails);
    event VaultFactoryUpdated(address indexed oldVaultFactory, address indexed newVaultFactory);
    event LiquidityPoolRegistered(uint256 indexed previousBlock, address indexed lpToken, address indexed sourceToken);
}