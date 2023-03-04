// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import '@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol';

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.14;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import '@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol';


/**
 * @notice Main storage structs
 */
struct AppStorage { 
    //Contracts
    address tricrypto;
    address crvTricrypto; 
    address mimPool;
    address crv2Pool;
    address yTriPool;
    address fraxPool;
    address executor;

    //ERC20s
    address USDT;
    address WBTC;
    address USDC;
    address MIM;
    address WETH;
    address FRAX;
    address ETH;

    //Token infrastructure
    address oz20;
    OZLERC20 oz;

    //System config
    uint protocolFee;
    uint defaultSlippage;
    mapping(address => bool) tokenDatabase;
    mapping(address => address) tokenL1ToTokenL2;

    //Internal accounting vars
    uint totalVolume;
    uint ozelIndex;
    uint feesVault;
    uint failedFees;
    mapping(address => uint) usersPayments;
    mapping(address => uint) accountPayments;
    mapping(address => address) accountToUser;
    mapping(address => bool) isAuthorized;

    //Curve swaps config
    TradeOps mimSwap;
    TradeOps usdcSwap;
    TradeOps fraxSwap;
    TradeOps[] swaps;

    //Mutex locks
    mapping(uint => uint) bitLocks;

    //Stabilizing mechanism (for ozelIndex)
    uint invariant;
    uint invariant2;
    uint indexRegulator;
    uint invariantRegulator;
    bool indexFlag;
    uint stabilizer;
    uint invariantRegulatorLimit;
    uint regulatorCounter;

    //Revenue vars
    ISwapRouter swapRouter;
    AggregatorV3Interface priceFeed;
    address revenueToken;
    uint24 poolFee;
    uint[] revenueAmounts;

    //Misc vars
    bool isEnabled;
    bool l1Check;
    bytes checkForRevenueSelec;
    address nullAddress;

    /*///////////////////////////////////////////////////////////////
                            v1.1 Upgrade
    //////////////////////////////////////////////////////////////*/

    mapping(address => AccData) userToData;
    mapping(bytes4 => bool) authorizedSelectors;

    /*///////////////////////////////////////////////////////////////
                                v1.2
    //////////////////////////////////////////////////////////////*/

    address[] tokenDatabaseArray;
}

/// @dev Reference for oz20Facet storage
struct OZLERC20 {
    mapping(address => mapping(address => uint256)) allowances;
    string  name;
    string  symbol;
}

/// @dev Reference for swaps and the addition/removal of account tokens
struct TradeOps {
    int128 tokenIn;
    int128 tokenOut;
    address baseToken;
    address token;  
    address pool;
}

/// @dev Reference for the details of each account
struct AccountConfig { 
    address user;
    address token;
    uint16 slippage; 
    string name;
}

/// @dev Reference to L2 Accounts
struct AccData {
    address[] accounts;
    mapping(bytes32 => bytes32) acc_userToName;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.14;


import './AppStorage.sol';


/**
 * @notice Access control methods implemented on bitmaps
 */
abstract contract Bits {

    AppStorage s;

    /**
     * @dev Queries if bit at index_ in bitmap_ is higher than 0
     */
    function _getBit(uint bitmap_, uint index_) internal view returns(bool) {
        uint bit = s.bitLocks[bitmap_] & (1 << index_);
        return bit > 0;
    }

    /**
     * @dev Flips bit at index_ from bitmap_
     */
    function _toggleBit(uint bitmap_, uint index_) internal {
        s.bitLocks[bitmap_] ^= (1 << index_);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.14;


import '../libraries/AddressAliasHelper.sol';
import '../libraries/LibCommon.sol';
import '../Errors.sol';
import './Bits.sol';


/**
 * @title Modifiers for the L2 contracts
 */
abstract contract ModifiersARB is Bits {

    /**
     * @dev Protector against reentrancy using bitmaps and bitwise operations
     * @param index_ Index of the bit to be flipped 
     */
    modifier noReentrancy(uint index_) { 
        if (!(_getBit(0, index_))) revert NoReentrance();
        _toggleBit(0, index_);
        _;
        _toggleBit(0, index_);
    }

    /**
     * @dev Access control using bitmaps and bitwise operations
     * @param index_ Index of the bit to be flipped 
     */
    modifier isAuthorized(uint index_) {
        if (_getBit(1, index_)) revert NotAuthorized(msg.sender);
        _;
        _toggleBit(1, index_);
    }

    /**
     * @dev Allows/disallows redeemptions of OZL for AUM 
     */
    modifier onlyWhenEnabled() {
        if (!(s.isEnabled)) revert NotEnabled();
        _;
    }

    /**
     * @dev Checks that the sender can call exchangeToAccountToken
     */
    modifier onlyAuthorized() {
        address l1Address = AddressAliasHelper.undoL1ToL2Alias(msg.sender);
        if (!s.isAuthorized[l1Address]) revert NotAuthorized(msg.sender);
        _;
    }

    /**
     * @dev Does primery checks on the details of an account
     * @param data_ Details of account/proxy
     * @return address Owner of the Account
     * @return address Token of the Account
     * @return uint256 Slippage of the Account
     */
    function _filter(bytes memory data_) internal view returns(address, address, uint) {
        (address user, address token, uint16 slippage) = LibCommon.extract(data_);

        if (user == address(0) || token == address(0)) revert CantBeZero('address'); 
        if (slippage <= 0) revert CantBeZero('slippage');

        if (!s.tokenDatabase[token] && _l1TokenCheck(token)) {
            revert TokenNotInDatabase(token);
        } else if (!s.tokenDatabase[token]) {
            token = s.tokenL1ToTokenL2[token];
        }

        return (user, token, uint(slippage));
    }

    /**
     * @dev Checks if an L1 address exists in the database
     * @param token_ L1 address
     * @return bool Returns false if token_ exists
     */
    function _l1TokenCheck(address token_) internal view returns(bool) {
        if (s.l1Check) {
            if (s.tokenL1ToTokenL2[token_] == s.nullAddress) return true;
            return false;
        } else {
            return true;
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.14;


import { ModifiersARB } from '../../Modifiers.sol';
import '../../../interfaces/arbitrum/IOZLFacetV1_2.sol';
import '../../../libraries/LibDiamond.sol';
import '../../../libraries/LibCommon.sol';
import '../../../Errors.sol';


/**
 * @title Upgraded OZLFacet for account methods
 * @notice It adds the ability to add/remove tokens from the token database array,
 * which is used in the front end. 
 */
contract OZLFacetV1_2 is IOZLFacetV1_2, ModifiersARB {

    event NewToken(address token);
    event TokenRemoved(address token);

    //@inheritdoc IOZLFacetV1_2
    function addTokenToDatabase(
        TradeOps calldata newSwap_, 
        LibDiamond.Token calldata token_
    ) external { 
        LibDiamond.enforceIsContractOwner();
        address l2Address = token_.l2Address;
        address l1Address = token_.l1Address;

        if (s.tokenDatabase[l2Address]) revert TokenAlreadyInDatabase(l2Address);
        if (!s.l1Check && l1Address != s.nullAddress) revert L1TokenDisabled(l1Address);

        s.tokenDatabase[l2Address] = true;
        s.tokenL1ToTokenL2[l1Address] = l2Address;
        s.swaps.push(newSwap_);
        s.tokenDatabaseArray.push(l2Address);

        emit NewToken(l2Address);
    }

    //@inheritdoc IOZLFacetV1_2
    function removeTokenFromDatabase(
        TradeOps calldata swapToRemove_, 
        LibDiamond.Token calldata token_
    ) external {
        LibDiamond.enforceIsContractOwner();
        address l2Address = token_.l2Address;
        if(!s.tokenDatabase[l2Address] && _l1TokenCheck(l2Address)) revert TokenNotInDatabase(l2Address);

        s.tokenDatabase[l2Address] = false;
        s.tokenL1ToTokenL2[token_.l1Address] = s.nullAddress;
        LibCommon.remove(s.swaps, swapToRemove_);
        _removeFromArr(l2Address);

        emit TokenRemoved(l2Address);
    }

    /// @dev Removes a specific address from the tokenDatabase array
    function _removeFromArr(address l2Address_) private {
        for (uint i=0; i < s.tokenDatabaseArray.length; i++) {
            if (s.tokenDatabaseArray[i] == l2Address_) {
                s.tokenDatabaseArray[i];
                s.tokenDatabaseArray[i] = s.tokenDatabaseArray[s.tokenDatabaseArray.length - 1];
                delete s.tokenDatabaseArray[s.tokenDatabaseArray.length - 1];
                s.tokenDatabaseArray.pop();
            }
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.14; 


/// @dev Thrown when comparisson has a zero value
/// @param nonZeroValue Type of the zero value
error CantBeZero(string nonZeroValue);

/// @dev When a low-level call fails
/// @param errorMsg Custom error message
error CallFailed(string errorMsg); 

/// @dev Thrown when the queried token is not in the database
/// @param token Address of queried token
error TokenNotInDatabase(address token);

/// @dev For when the queried token is in the database
/// @param token Address of queried token
error TokenAlreadyInDatabase(address token);

/// @dev Thrown when an user is not in the database
/// @param user Address of the queried user
error UserNotInDatabase(address user);

/// @dev Thrown when the call is done by a non-account/proxy
error NotAccount();

/// @dev Thrown when a custom condition is not fulfilled
/// @param errorMsg Custom error message
error ConditionNotMet(string errorMsg);

/// @dev Thrown when an unahoritzed user makes the call
/// @param unauthorizedUser Address of the msg.sender
error NotAuthorized(address unauthorizedUser);

/// @dev When reentrance occurs
error NoReentrance();

/// @dev When a particular action hasn't been enabled yet
error NotEnabled();

/// @dev Thrown when the account name is too long
error NameTooLong();

/// @dev Thrown when the queried Gelato task is invalid
/// @param taskId Gelato task
error InvalidTask(bytes32 taskId);

/// @dev Thrown if an attempt to add a L1 token is done after it's been disabled
/// @param l1Token L1 token address
error L1TokenDisabled(address l1Token);

/// @dev Thrown when a Gelato's task ID doesn't exist
error NoTaskId();

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

interface IDiamondCut {
    enum FacetCutAction {Add, Replace, Remove}
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.14;


import { TradeOps } from '../../arbitrum/AppStorage.sol';
import '../../libraries/LibDiamond.sol';


interface IOZLFacetV1_2 {

    /**
     * @dev Adds a new token to be swapped into to the token database
     * @param newSwap_ Swap Curve config -as infra- that will allow swapping into the new token
     * @param token_ L1 & L2 addresses of the token to add
     */
    function addTokenToDatabase(
        TradeOps calldata newSwap_, 
        LibDiamond.Token calldata token_
    ) external;


    /**
     * @dev Removes a token from the token database
     * @param swapToRemove_ Remove the swap Curve config that allows swapping into
     * the soon-to-be-removed token.
     * @param token_ L1 & L2 addresses of the token to add
     */
    function removeTokenFromDatabase(
        TradeOps calldata swapToRemove_, 
        LibDiamond.Token calldata token_
    ) external;
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.14;


library AddressAliasHelper {
    uint160 internal constant OFFSET = uint160(0x1111000000000000000000000000000000001111);

    /// @notice Utility function that converts the address in the L1 that submitted a tx to
    /// the inbox to the msg.sender viewed in the L2
    /// @param l1Address the address in the L1 that triggered the tx to L2
    /// @return l2Address L2 address as viewed in msg.sender
    function applyL1ToL2Alias(address l1Address) internal pure returns (address l2Address) {
        unchecked {
            l2Address = address(uint160(l1Address) + OFFSET);
        }
    }

    /// @notice Utility function that converts the msg.sender viewed in the L2 to the
    /// address in the L1 that submitted a tx to the inbox
    /// @param l2Address L2 address as viewed in msg.sender
    /// @return l1Address the address in the L1 that triggered the tx to L2
    function undoL1ToL2Alias(address l2Address) internal pure returns (address l1Address) {
        unchecked {
            l1Address = address(uint160(l2Address) - OFFSET);
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.14;


import { TradeOps } from '../arbitrum/AppStorage.sol';


/**
 * @notice Library of common methods using in both L1 and L2 contracts
 */
library LibCommon {

    /**
     * @notice L1 removal method
     * @dev Removes a token from the token database
     * @param tokensDB_ Array of addresses where the removal will occur
     * @param toRemove_ Token to remove
     */
    function remove(address[] storage tokensDB_, address toRemove_) internal {
        uint index;
        for (uint i=0; i < tokensDB_.length;) {
            if (tokensDB_[i] == toRemove_)  {
                index = i;
                break;
            }
            unchecked { ++i; }
        }
        for (uint i=index; i < tokensDB_.length - 1;){
            tokensDB_[i] = tokensDB_[i+1];
            unchecked { ++i; }
        }
        delete tokensDB_[tokensDB_.length-1];
        tokensDB_.pop();
    }

    /**
     * @notice Overloaded L2 removal method
     * @dev Removes a token and its swap config from the token database
     * @param swaps_ Array of structs where the removal will occur
     * @param swapToRemove_ Config struct to be removed
     */
    function remove(
        TradeOps[] storage swaps_, 
        TradeOps memory swapToRemove_
    ) internal {
        uint index;
        for (uint i=0; i < swaps_.length;) {
            if (swaps_[i].token == swapToRemove_.token)  {
                index = i;
                break;
            }
            unchecked { ++i; }
        }
        for (uint i=index; i < swaps_.length - 1;){
            swaps_[i] = swaps_[i+1];
            unchecked { ++i; }
        }
        delete swaps_[swaps_.length-1];
        swaps_.pop();
    }

    /**
     * @dev Extracts the details of an Account
     * @param data_ Bytes array containing the details
     * @return user Owner of the Account
     * @return token Token of the Account
     * @return slippage Slippage of the Account
     */
    function extract(bytes memory data_) internal pure returns(
        address user, 
        address token, 
        uint16 slippage
    ) {
        assembly {
            user := shr(96, mload(add(data_, 32)))
            token := shr(96, mload(add(data_, 52)))
            slippage := and(0xfff, mload(add(mload(data_), data_)))
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/
import { IDiamondCut } from "../interfaces/arbitrum/IDiamondCut.sol";
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';


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

    struct Facets {
        bytes4[][] selectors;
        address[] addresses;
    }

    struct Token {
        address l1Address;
        address l2Address;
    }

    struct VarsAndAddresses { 
        address[] contracts;
        address[] erc20s;
        Token[] tokensDb;
        address ETH;
        uint[] appVars;
        uint[] revenueAmounts;
        string[] ozlVars;
    }


    struct DiamondStorage {
        // maps function selector to the facet address and
        // the position of the selector in the facetFunctionSelectors.selectors array
        mapping(bytes4 => FacetAddressAndPosition) selectorToFacetAndPosition;
        // // maps facet addresses to function selectors
        mapping(address => FacetFunctionSelectors) facetFunctionSelectors;
        // facet addresses
        address[] facetAddresses;
        // Used to query if a contract implements an interface.
        // Used to implement ERC-165.
        mapping(bytes4 => bool) supportedInterfaces;
        // owner of the contract
        address contractOwner; 
        //facets that don't check revenue
        address[] nonRevenueFacets;
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
        require(msg.sender == diamondStorage().contractOwner, "LibDiamond: Must be contract owner");
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
                replaceFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else if (action == IDiamondCut.FacetCutAction.Remove) {
                removeFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
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
            require(oldFacetAddress != _facetAddress, "LibDiamondCut: Can't replace function with same function");
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


    function addFunction(DiamondStorage storage ds, bytes4 _selector, uint96 _selectorPosition, address _facetAddress) internal {
        ds.selectorToFacetAndPosition[_selector].functionSelectorPosition = _selectorPosition;
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.push(_selector);
        ds.selectorToFacetAndPosition[_selector].facetAddress = _facetAddress;
    }

    function removeFunction(DiamondStorage storage ds, address _facetAddress, bytes4 _selector) internal {        
        require(_facetAddress != address(0), "LibDiamondCut: Can't remove function that doesn't exist");
        // an immutable function is a function defined directly in a diamond
        require(_facetAddress != address(this), "LibDiamondCut: Can't remove immutable function");
        // replace selector with last selector, then delete last selector
        uint256 selectorPosition = ds.selectorToFacetAndPosition[_selector].functionSelectorPosition;
        uint256 lastSelectorPosition = ds.facetFunctionSelectors[_facetAddress].functionSelectors.length - 1;
        // if not the same then replace _selector with lastSelector
        if (selectorPosition != lastSelectorPosition) {
            bytes4 lastSelector = ds.facetFunctionSelectors[_facetAddress].functionSelectors[lastSelectorPosition];
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
            require(_calldata.length == 0, "LibDiamondCut: _init is address(0) but_calldata is not empty");
        } else {
            require(_calldata.length > 0, "LibDiamondCut: _calldata is empty but _init is not address(0)");
            if (_init != address(this)) {
                enforceHasContractCode(_init, "LibDiamondCut: _init address has no code");
            }
            (bool success, bytes memory error) = _init.delegatecall(_calldata);
            if (!success) {
                if (error.length > 0) {
                    // bubble up the error
                    revert(string(error));
                } else {
                    revert("LibDiamondCut: _init function reverted");
                }
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

    /*///////////////////////////////////////////////////////////////
                               Custom methods
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Determines which facet to call depending on the selector
     * @param data_ Calldata of function to call
     * @return bytes Return data
     */
    function callFacet(bytes memory data_) internal returns(bytes memory) {
        DiamondStorage storage ds = diamondStorage();
        address facet = ds.selectorToFacetAndPosition[bytes4(data_)].facetAddress;
        (bool success, bytes memory data) = facet.delegatecall(data_);
        require(success, 'LibDiamond: callFacet() failed');
        return data;
    }

    /**
     * @dev Sets the facets that don't call for a revenue check (the owner's)
     * @param nonRevenueFacets_ Facets that don't call for revenue check
     */
    function setNonRevenueFacets(address[] memory nonRevenueFacets_) internal {
        DiamondStorage storage ds = diamondStorage();
        uint length = nonRevenueFacets_.length;
        for (uint i=0; i < length;) {
            ds.nonRevenueFacets.push(nonRevenueFacets_[i]);
            unchecked { ++i; }
        }
    }
}