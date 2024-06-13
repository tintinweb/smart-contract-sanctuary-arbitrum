// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

// Vendor
import { Diamond } from "./vendor/Diamond.sol";

// Routers
import { Routers } from "./routers/Routers.sol";

//                  ______                                   __                     __  __    ____
//                 /\  _  \                                 /\ \__                 /\ \/\ \  /'___\
//                 \ \ \L\ \  __  __     __   __  __    ____\ \ ,_\  __  __    ____\ \ \ \ \/\ \__/
//                  \ \  __ \/\ \/\ \  /'_ `\/\ \/\ \  /',__\\ \ \/ /\ \/\ \  /',__\\ \ \ \ \ \  _``\
//                   \ \ \/\ \ \ \_\ \/\ \L\ \ \ \_\ \/\__, `\\ \ \_\ \ \_\ \/\__, `\\ \ \_/ \ \ \L\ \
//                    \ \_\ \_\ \____/\ \____ \ \____/\/\____/ \ \__\\ \____/\/\____/ \ `\___/\ \____/
//                     \/_/\/_/\/___/  \/___L\ \/___/  \/___/   \/__/ \/___/  \/___/   `\/__/  \/___/
//                                       /\____/
//                                       \_/__/

/// @title AugustusV6
/// @notice The V6 implementation of the ParaSwap onchain aggregation protocol
contract AugustusV6 is Diamond, Routers {
    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        /// @dev Diamond
        address _owner,
        address _diamondCutFacet,
        /// @dev Direct Routers
        address _weth,
        address payable _balancerVault,
        uint256 _uniV3FactoryAndFF,
        uint256 _uniswapV3PoolInitCodeHash,
        uint256 _uniswapV2FactoryAndFF,
        uint256 _uniswapV2PoolInitCodeHash,
        address _rfq,
        /// @dev Fees
        address payable _feeVault,
        /// @dev Permit2
        address _permit2
    )
        Diamond(_owner, _diamondCutFacet)
        Routers(
            _weth,
            _uniV3FactoryAndFF,
            _uniswapV3PoolInitCodeHash,
            _uniswapV2FactoryAndFF,
            _uniswapV2PoolInitCodeHash,
            _balancerVault,
            _permit2,
            _rfq,
            _feeVault
        )
    { }

    /*//////////////////////////////////////////////////////////////
                                EXTERNAL
    //////////////////////////////////////////////////////////////*/

    /// @notice Reverts if the caller is one of the following:
    //         - an externally-owned account
    //         - a contract in construction
    //         - an address where a contract will be created
    //         - an address where a contract lived, but was destroyed
    receive() external payable override(Diamond) {
        address addr = msg.sender;
        // solhint-disable-next-line no-inline-assembly
        assembly ("memory-safe") {
            if iszero(extcodesize(addr)) { revert(0, 0) }
        }
    }
}

// SPDX-License-Identifier: MIT
/**
 * Vendored on October 12, 2023 from:
 * https://github.com/mudgen/diamond-3-hardhat/blob/main/contracts/Diamond.sol
 */
pragma solidity ^0.8.0;

/**
 * \
 * Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
 * EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
 *
 * Implementation of a diamond.
 * /*****************************************************************************
 */
import { LibDiamond } from "./libraries/LibDiamond.sol";
import { IDiamondCut } from "./interfaces/IDiamondCut.sol";

contract Diamond {
    error DiamondFunctionDoesNotExist();

    constructor(address _contractOwner, address _diamondCutFacet) payable {
        LibDiamond.setContractOwner(_contractOwner);

        // Add the diamondCut external function from the diamondCutFacet
        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](1);
        bytes4[] memory functionSelectors = new bytes4[](1);
        functionSelectors[0] = IDiamondCut.diamondCut.selector;
        cut[0] = IDiamondCut.FacetCut({
            facetAddress: _diamondCutFacet,
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: functionSelectors
        });
        LibDiamond.diamondCut(cut, address(0), "");
    }

    // Find facet for function that is called and execute the
    // function if a facet is found and return any value.
    fallback() external payable {
        LibDiamond.DiamondStorage storage ds;
        bytes32 position = LibDiamond.DIAMOND_STORAGE_POSITION;
        // get diamond storage
        assembly {
            ds.slot := position
        }
        // get facet from function selector
        address facet = ds.selectorToFacetAndPosition[msg.sig].facetAddress;
        // revert if function does not exist
        if (facet == address(0)) {
            revert DiamondFunctionDoesNotExist();
        }
        // Execute external function from facet using delegatecall and return any value.
        assembly {
            // copy function selector and any arguments
            calldatacopy(0, 0, calldatasize())
            // execute function call using the facet
            let result := delegatecall(gas(), facet, 0, calldatasize(), 0, 0)
            // get any return value
            returndatacopy(0, 0, returndatasize())
            // return any return value or error back to the caller
            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    receive() external payable virtual { }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

// DirectSwapExactAmountIn
import { BalancerV2SwapExactAmountIn } from "./swapExactAmountIn/direct/BalancerV2SwapExactAmountIn.sol";
import { CurveV1SwapExactAmountIn } from "./swapExactAmountIn/direct/CurveV1SwapExactAmountIn.sol";
import { CurveV2SwapExactAmountIn } from "./swapExactAmountIn/direct/CurveV2SwapExactAmountIn.sol";
import { UniswapV2SwapExactAmountIn } from "./swapExactAmountIn/direct/UniswapV2SwapExactAmountIn.sol";
import { UniswapV3SwapExactAmountIn } from "./swapExactAmountIn/direct/UniswapV3SwapExactAmountIn.sol";

// DirectSwapExactAmountOut
import { BalancerV2SwapExactAmountOut } from "./swapExactAmountOut/direct/BalancerV2SwapExactAmountOut.sol";
import { UniswapV2SwapExactAmountOut } from "./swapExactAmountOut/direct/UniswapV2SwapExactAmountOut.sol";
import { UniswapV3SwapExactAmountOut } from "./swapExactAmountOut/direct/UniswapV3SwapExactAmountOut.sol";

// Fees
import { AugustusFees } from "../fees/AugustusFees.sol";

// GenericSwapExactAmountIn
import { GenericSwapExactAmountIn } from "./swapExactAmountIn/GenericSwapExactAmountIn.sol";

// GenericSwapExactAmountOut
import { GenericSwapExactAmountOut } from "./swapExactAmountOut/GenericSwapExactAmountOut.sol";

// General
import { AugustusRFQRouter } from "./general/AugustusRFQRouter.sol";

// Utils
import { AugustusRFQUtils } from "../util/AugustusRFQUtils.sol";
import { BalancerV2Utils } from "../util/BalancerV2Utils.sol";
import { UniswapV2Utils } from "../util/UniswapV2Utils.sol";
import { UniswapV3Utils } from "../util/UniswapV3Utils.sol";
import { WETHUtils } from "../util/WETHUtils.sol";
import { Permit2Utils } from "../util/Permit2Utils.sol";

/// @title Routers
/// @notice A wrapper for all router contracts
contract Routers is
    AugustusFees,
    AugustusRFQRouter,
    BalancerV2SwapExactAmountOut,
    BalancerV2SwapExactAmountIn,
    CurveV1SwapExactAmountIn,
    CurveV2SwapExactAmountIn,
    GenericSwapExactAmountOut,
    GenericSwapExactAmountIn,
    UniswapV2SwapExactAmountOut,
    UniswapV2SwapExactAmountIn,
    UniswapV3SwapExactAmountOut,
    UniswapV3SwapExactAmountIn
{
    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        address _weth,
        uint256 _uniswapV3FactoryAndFF,
        uint256 _uniswapV3PoolInitCodeHash,
        uint256 _uniswapV2FactoryAndFF,
        uint256 _uniswapV2PoolInitCodeHash,
        address payable _balancerVault,
        address _permit2,
        address _rfq,
        address payable _feeVault
    )
        AugustusFees(_feeVault)
        AugustusRFQUtils(_rfq)
        BalancerV2Utils(_balancerVault)
        Permit2Utils(_permit2)
        UniswapV2Utils(_uniswapV2FactoryAndFF, _uniswapV2PoolInitCodeHash)
        UniswapV3Utils(_uniswapV3FactoryAndFF, _uniswapV3PoolInitCodeHash)
        WETHUtils(_weth)
    { }
}

// SPDX-License-Identifier: MIT
/**
 * Vendored on October 12, 2023 from:
 * https://github.com/mudgen/diamond-3-hardhat/blob/main/contracts/libraries/LibDiamond.sol
 */
pragma solidity ^0.8.0;

/**
 * \
 * Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
 * EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
 * /*****************************************************************************
 */
import { IDiamondCut } from "../interfaces/IDiamondCut.sol";

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
        require(msg.sender == diamondStorage().contractOwner, "LibDiamond: Must be contract owner");
    }

    event DiamondCut(IDiamondCut.FacetCut[] _diamondCut, address _init, bytes _calldata);

    // Internal function version of diamondCut
    function diamondCut(IDiamondCut.FacetCut[] memory _diamondCut, address _init, bytes memory _calldata) internal {
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

    function addFunction(
        DiamondStorage storage ds,
        bytes4 _selector,
        uint96 _selectorPosition,
        address _facetAddress
    )
        internal
    {
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

// SPDX-License-Identifier: MIT
/**
 * Vendored on October 12, 2023 from:
 * https://github.com/mudgen/diamond-3-hardhat/blob/main/contracts/interfaces/IDiamondCut.sol
 */
pragma solidity ^0.8.0;

/**
 * \
 * Author: Nick Mudge (https://twitter.com/mudgen)
 * EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
 * /*****************************************************************************
 */
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

    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

// Interfaces
import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";
import { IBalancerV2SwapExactAmountIn } from "../../../interfaces/IBalancerV2SwapExactAmountIn.sol";

// Libraries
import { ERC20Utils } from "../../../libraries/ERC20Utils.sol";

// Types
import { BalancerV2Data } from "../../../AugustusV6Types.sol";

// Utils
import { BalancerV2Utils } from "../../../util/BalancerV2Utils.sol";

/// @title BalancerV2SwapExactAmountIn
/// @notice A contract for executing direct swapExactAmountIn on Balancer V2
abstract contract BalancerV2SwapExactAmountIn is IBalancerV2SwapExactAmountIn, BalancerV2Utils {
    /*//////////////////////////////////////////////////////////////
                               LIBRARIES
    //////////////////////////////////////////////////////////////*/

    using ERC20Utils for IERC20;

    /*//////////////////////////////////////////////////////////////
                          SWAP EXACT AMOUNT IN
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IBalancerV2SwapExactAmountIn
    function swapExactAmountInOnBalancerV2(
        BalancerV2Data calldata balancerData,
        uint256 partnerAndFee,
        bytes calldata permit,
        bytes calldata data
    )
        external
        payable
        whenNotPaused
        returns (uint256 receivedAmount, uint256 paraswapShare, uint256 partnerShare)
    {
        // Dereference balancerData
        uint256 quotedAmountOut = balancerData.quotedAmount;
        uint256 beneficiaryAndApproveFlag = balancerData.beneficiaryAndApproveFlag;
        uint256 amountIn = balancerData.fromAmount;
        uint256 minAmountOut = balancerData.toAmount;

        // Decode params
        (IERC20 srcToken, IERC20 destToken, address payable beneficiary, bool approve) =
            _decodeBalancerV2Params(beneficiaryAndApproveFlag, data);

        // Check if toAmount is valid
        if (minAmountOut == 0) {
            revert InvalidToAmount();
        }

        // Check if beneficiary is valid
        if (beneficiary == address(0)) {
            beneficiary = payable(msg.sender);
        }

        // Check if srcToken is ETH
        if (srcToken.isETH(amountIn) == 0) {
            // Check the length of the permit field,
            // if < 257 and > 0 we should execute regular permit
            // and if it is >= 257 we execute permit2
            if (permit.length < 257) {
                // Permit if needed
                if (permit.length > 0) {
                    srcToken.permit(permit);
                }
                srcToken.safeTransferFrom(msg.sender, address(this), amountIn);
            } else {
                // Otherwise Permit2.permitTransferFrom
                permit2TransferFrom(permit, address(this), amountIn);
            }
            // Check if approve is needed
            if (approve) {
                // Approve BALANCER_VAULT to spend srcToken
                srcToken.approve(BALANCER_VAULT);
            }
        }

        // Execute swap
        _callBalancerV2(data);

        // Check balance after swap
        receivedAmount = destToken.getBalance(address(this));

        // Check if swap succeeded
        if (receivedAmount < minAmountOut) {
            revert InsufficientReturnAmount();
        }

        // Process fees and transfer destToken to beneficiary
        return processSwapExactAmountInFeesAndTransfer(
            beneficiary, destToken, partnerAndFee, receivedAmount, quotedAmountOut
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

// Interfaces
import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";
import { ICurveV1SwapExactAmountIn } from "../../../interfaces/ICurveV1SwapExactAmountIn.sol";

// Libraries
import { ERC20Utils } from "../../../libraries/ERC20Utils.sol";

// Types
import { CurveV1Data } from "../../../AugustusV6Types.sol";

// Utils
import { AugustusFees } from "../../../fees/AugustusFees.sol";
import { WETHUtils } from "../../../util/WETHUtils.sol";
import { Permit2Utils } from "../../../util/Permit2Utils.sol";
import { PauseUtils } from "../../../util/PauseUtils.sol";

/// @title CurveV1SwapExactAmountIn
/// @notice A contract for executing direct CurveV1 swaps
abstract contract CurveV1SwapExactAmountIn is
    ICurveV1SwapExactAmountIn,
    AugustusFees,
    WETHUtils,
    Permit2Utils,
    PauseUtils
{
    /*//////////////////////////////////////////////////////////////
                               LIBRARIES
    //////////////////////////////////////////////////////////////*/

    using ERC20Utils for IERC20;

    /*//////////////////////////////////////////////////////////////
                          SWAP EXACT AMOUNT IN
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc ICurveV1SwapExactAmountIn
    function swapExactAmountInOnCurveV1(
        CurveV1Data calldata curveV1Data,
        uint256 partnerAndFee,
        bytes calldata permit
    )
        external
        payable
        whenNotPaused
        returns (uint256 receivedAmount, uint256 paraswapShare, uint256 partnerShare)
    {
        // Dereference curveV1Data
        IERC20 srcToken = curveV1Data.srcToken;
        IERC20 destToken = curveV1Data.destToken;
        uint256 amountIn = curveV1Data.fromAmount;
        uint256 minAmountOut = curveV1Data.toAmount;
        uint256 quotedAmountOut = curveV1Data.quotedAmount;
        address payable beneficiary = curveV1Data.beneficiary;
        uint256 curveAssets = curveV1Data.curveAssets;
        uint256 curveData = curveV1Data.curveData;

        // Check if toAmount is valid
        if (minAmountOut == 0) {
            revert InvalidToAmount();
        }

        // Check if beneficiary is valid
        if (beneficiary == address(0)) {
            beneficiary = payable(msg.sender);
        }

        // Decode curveData
        // 160 bits for curve exchange address
        // 1 bit for approve flag
        // 2 bits for wrap flag
        // 2 bits for swap type flag

        address exchange;
        bool approveFlag;
        uint256 wrapFlag;
        uint256 swapType;

        // solhint-disable-next-line no-inline-assembly
        assembly ("memory-safe") {
            exchange := and(curveData, 0xffffffffffffffffffffffffffffffffffffffff)
            approveFlag := and(shr(160, curveData), 1)
            wrapFlag := and(shr(161, curveData), 3)
            swapType := and(shr(163, curveData), 3)
        }

        // Check if srcToken is ETH
        // Transfer srcToken to augustus if not ETH
        if (srcToken.isETH(amountIn) == 0) {
            // Check the length of the permit field,
            // if < 257 and > 0 we should execute regular permit
            // and if it is >= 257 we execute permit2
            if (permit.length < 257) {
                // Permit if needed
                if (permit.length > 0) {
                    srcToken.permit(permit);
                }
                srcToken.safeTransferFrom(msg.sender, address(this), amountIn);
            } else {
                // Otherwise Permit2.permitTransferFrom
                permit2TransferFrom(permit, address(this), amountIn);
            }
            // Check if approve flag is set
            if (approveFlag) {
                // Approve exchange
                srcToken.approve(exchange);
            }
        } else {
            // Check if approve flag is set
            if (approveFlag) {
                // Approve exchange
                IERC20(WETH).approve(exchange);
            }
        }

        // Execute swap
        _executeSwapOnCurveV1(exchange, wrapFlag, swapType, curveAssets, amountIn);

        // Check balance after swap and unwrap if needed
        if (wrapFlag == 2) {
            // Received amount is WETH balance
            receivedAmount = IERC20(WETH).getBalance(address(this));
            // Unwrap WETH
            WETH.withdraw(receivedAmount - 1);
            // Set receivedAmount to this contract's balance
            receivedAmount = address(this).balance;
        } else {
            // Received amount is destToken balance
            receivedAmount = destToken.getBalance(address(this));
        }

        // Check if swap succeeded
        if (receivedAmount < minAmountOut) {
            revert InsufficientReturnAmount();
        }

        // Process fees and transfer destToken to beneficiary
        return processSwapExactAmountInFeesAndTransfer(
            beneficiary, destToken, partnerAndFee, receivedAmount, quotedAmountOut
        );
    }

    /*//////////////////////////////////////////////////////////////
                                PRIVATE
    //////////////////////////////////////////////////////////////*/

    function _executeSwapOnCurveV1(
        address exchange,
        uint256 wrapFlag,
        uint256 swapType,
        uint256 curveAssets,
        uint256 fromAmount
    )
        private
    {
        // Load WETH address
        address weth = address(WETH);
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Load free memory pointer
            let ptr := mload(64)

            //-----------------------------------------------------------------------------------
            // Wrap ETH if needed
            //-----------------------------------------------------------------------------------

            // Check if wrap src flag is set
            if eq(wrapFlag, 1) {
                // Prepare call data for WETH.deposit()

                // Store function selector and
                mstore(ptr, 0xd0e30db000000000000000000000000000000000000000000000000000000000) // deposit()

                // Perform the external call with the prepared calldata
                // Check the outcome of the call and handle failure
                if iszero(call(gas(), weth, callvalue(), ptr, 4, 0, 0)) {
                    // The call failed; we retrieve the exact error message and revert with it
                    returndatacopy(0, 0, returndatasize()) // Copy the error message to the start of memory
                    revert(0, returndatasize()) // Revert with the error message
                }
            }

            //-----------------------------------------------------------------------------------
            // Execute swap
            //-----------------------------------------------------------------------------------

            // Prepare call data for external call

            // Check swap type
            switch swapType
            // 0x01 for EXCHANGE_UNDERLYING
            case 0x01 {
                // Store function selector for function exchange_underlying(int128,int128,uint256,uint256)
                mstore(ptr, 0xa6417ed600000000000000000000000000000000000000000000000000000000) // store selector
                mstore(add(ptr, 4), shr(128, curveAssets)) // store index i
                mstore(add(ptr, 36), and(curveAssets, 0xffffffffffffffffffffffffffffffff)) // store index j
                mstore(add(ptr, 68), fromAmount) // store fromAmount
                mstore(add(ptr, 100), 1) // store 1
                // Perform the external call with the prepared calldata
                // Check the outcome of the call and handle failure
                if iszero(call(gas(), exchange, 0, ptr, 132, 0, 0)) {
                    // The call failed; we retrieve the exact error message and revert with it
                    returndatacopy(0, 0, returndatasize()) // Copy the error message to the start of memory
                    revert(0, returndatasize()) // Revert with the error message
                }
            }
            // 0x00(default) for EXCHANGE
            default {
                // check send eth wrap flag
                switch eq(wrapFlag, 0x03)
                // if it is not set, store selector for function exchange(int128,int128,uint256,uint256)
                case 1 {
                    mstore(ptr, 0x3df0212400000000000000000000000000000000000000000000000000000000) // store selector
                    mstore(add(ptr, 4), shr(128, curveAssets)) // store index i
                    mstore(add(ptr, 36), and(curveAssets, 0xffffffffffffffffffffffffffffffff)) // store index j
                    mstore(add(ptr, 68), fromAmount) // store fromAmount
                    mstore(add(ptr, 100), 1) // store 1
                    // Perform the external call with the prepared calldata
                    // Check the outcome of the call and handle failure
                    if iszero(call(gas(), exchange, callvalue(), ptr, 132, 0, 0)) {
                        // The call failed; we retrieve the exact error message and revert with it
                        returndatacopy(0, 0, returndatasize()) // Copy the error message to the start of memory
                        revert(0, returndatasize()) // Revert with the error message
                    }
                }
                // if it is set, store selector for function exchange(int128,int128,uint256,uint256)
                default {
                    mstore(ptr, 0x3df0212400000000000000000000000000000000000000000000000000000000) // store selector
                    mstore(add(ptr, 4), shr(128, curveAssets)) // store index i
                    mstore(add(ptr, 36), and(curveAssets, 0xffffffffffffffffffffffffffffffff)) // store index j
                    mstore(add(ptr, 68), fromAmount) // store fromAmount
                    mstore(add(ptr, 100), 1) // store 1
                    // Perform the external call with the prepared calldata
                    // Check the outcome of the call and handle failure
                    if iszero(call(gas(), exchange, 0, ptr, 132, 0, 0)) {
                        // The call failed; we retrieve the exact error message and revert with it
                        returndatacopy(0, 0, returndatasize()) // Copy the error message to the start of memory
                        revert(0, returndatasize()) // Revert with the error message
                    }
                }
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

// Interfaces
import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";
import { ICurveV2SwapExactAmountIn } from "../../../interfaces/ICurveV2SwapExactAmountIn.sol";

// Libraries
import { ERC20Utils } from "../../../libraries/ERC20Utils.sol";

// Types
import { CurveV2Data } from "../../../AugustusV6Types.sol";

// Utils
import { AugustusFees } from "../../../fees/AugustusFees.sol";
import { WETHUtils } from "../../../util/WETHUtils.sol";
import { Permit2Utils } from "../../../util/Permit2Utils.sol";
import { PauseUtils } from "../../../util/PauseUtils.sol";

/// @title CurveV2SwapExactAmountIn
/// @notice A contract for executing direct CurveV2 swaps
abstract contract CurveV2SwapExactAmountIn is
    ICurveV2SwapExactAmountIn,
    AugustusFees,
    WETHUtils,
    Permit2Utils,
    PauseUtils
{
    /*//////////////////////////////////////////////////////////////
                               LIBRARIES
    //////////////////////////////////////////////////////////////*/

    using ERC20Utils for IERC20;

    /*//////////////////////////////////////////////////////////////
                          SWAP EXACT AMOUNT IN
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc ICurveV2SwapExactAmountIn
    function swapExactAmountInOnCurveV2(
        CurveV2Data calldata curveV2Data,
        uint256 partnerAndFee,
        bytes calldata permit
    )
        external
        payable
        whenNotPaused
        returns (uint256 receivedAmount, uint256 paraswapShare, uint256 partnerShare)
    {
        // Dereference curveData
        IERC20 srcToken = curveV2Data.srcToken;
        IERC20 destToken = curveV2Data.destToken;
        uint256 amountIn = curveV2Data.fromAmount;
        uint256 minAmountOut = curveV2Data.toAmount;
        uint256 quotedAmountOut = curveV2Data.quotedAmount;
        address payable beneficiary = curveV2Data.beneficiary;
        uint256 i = curveV2Data.i;
        uint256 j = curveV2Data.j;
        address poolAddress = curveV2Data.poolAddress;
        uint256 curveData = curveV2Data.curveData;

        // Check if toAmount is valid
        if (minAmountOut == 0) {
            revert InvalidToAmount();
        }

        // Check if beneficiary is valid
        if (beneficiary == address(0)) {
            beneficiary = payable(msg.sender);
        }

        // Decode curveData
        // 160 bits for curve exchange address
        // 1 bit for approve flag
        // 2 bits for wrap flag
        // 2 bits for swap type flag

        address exchange;
        bool approveFlag;
        uint256 wrapFlag;
        uint256 swapType;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            exchange := and(curveData, 0xffffffffffffffffffffffffffffffffffffffff)
            approveFlag := and(shr(160, curveData), 1)
            wrapFlag := and(shr(161, curveData), 3)
            swapType := and(shr(163, curveData), 3)
        }

        // Check if srcToken is ETH
        // Transfer srcToken to augustus if not ETH
        if (srcToken.isETH(amountIn) == 0) {
            // Check the length of the permit field,
            // if < 257 and > 0 we should execute regular permit
            // and if it is >= 257 we execute permit2
            if (permit.length < 257) {
                // Permit if needed
                if (permit.length > 0) {
                    srcToken.permit(permit);
                }
                srcToken.safeTransferFrom(msg.sender, address(this), amountIn);
            } else {
                // Otherwise Permit2.permitTransferFrom
                permit2TransferFrom(permit, address(this), amountIn);
            }
            // Check if approve flag is set
            if (approveFlag) {
                // Approve exchange
                srcToken.approve(exchange);
            }
        } else {
            // Check if approve flag is set
            if (approveFlag) {
                // Approve exchange
                IERC20(WETH).approve(exchange);
            }
        }

        // Execute swap
        _executeSwapOnCurveV2(exchange, wrapFlag, swapType, i, j, amountIn, poolAddress);

        // Check balance after swap and unwrap if needed
        if (wrapFlag == 2) {
            // Received amount is WETH balance
            receivedAmount = IERC20(WETH).getBalance(address(this));
            // Unwrap WETH
            WETH.withdraw(receivedAmount - 1);
            // Set receivedAmount to this contract's balance
            receivedAmount = address(this).balance;
        } else {
            // Received amount is destToken balance
            receivedAmount = destToken.getBalance(address(this));
        }

        // Check if swap succeeded
        if (receivedAmount < minAmountOut) {
            revert InsufficientReturnAmount();
        }

        // Process fees and transfer destToken to beneficiary
        return processSwapExactAmountInFeesAndTransfer(
            beneficiary, destToken, partnerAndFee, receivedAmount, quotedAmountOut
        );
    }

    /*//////////////////////////////////////////////////////////////
                                PRIVATE
    //////////////////////////////////////////////////////////////*/

    function _executeSwapOnCurveV2(
        address exchange,
        uint256 wrapFlag,
        uint256 swapType,
        uint256 i,
        uint256 j,
        uint256 fromAmount,
        address poolAddress
    )
        private
    {
        // Load WETH address
        address weth = address(WETH);
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Load free memory pointer
            let ptr := mload(64)

            //-----------------------------------------------------------------------------------
            // Wrap ETH if needed
            //-----------------------------------------------------------------------------------

            // Check if wrap src flag is set
            if eq(wrapFlag, 1) {
                // Prepare call data for WETH.deposit()

                // Store function selector and
                mstore(ptr, 0xd0e30db000000000000000000000000000000000000000000000000000000000) // deposit()

                // Perform the external call with the prepared calldata
                // Check the outcome of the call and handle failure
                if iszero(call(gas(), weth, callvalue(), ptr, 4, 0, 0)) {
                    // The call failed; we retrieve the exact error message and revert with it
                    returndatacopy(0, 0, returndatasize()) // Copy the error message to the start of memory
                    revert(0, returndatasize()) // Revert with the error message
                }
            }

            //-----------------------------------------------------------------------------------
            // Execute swap
            //-----------------------------------------------------------------------------------

            // Prepare call data for external call

            // Check swap type
            switch swapType
            // 0x01 for EXCHANGE_UNDERLYING
            case 0x01 {
                // Store function selector for function exchange_underlying(uint256,uint256,uint256,uint256)
                mstore(ptr, 0x65b2489b00000000000000000000000000000000000000000000000000000000) // store selector
                mstore(add(ptr, 4), i) // store index i
                mstore(add(ptr, 36), j) // store index j
                mstore(add(ptr, 68), fromAmount) // store fromAmount
                mstore(add(ptr, 100), 1) // store 1
                // Perform the external call with the prepared calldata
                // Check the outcome of the call and handle failure
                if iszero(call(gas(), exchange, 0, ptr, 132, 0, 0)) {
                    // The call failed; we retrieve the exact error message and revert with it
                    returndatacopy(0, 0, returndatasize()) // Copy the error message to the start of memory
                    revert(0, returndatasize()) // Revert with the error message
                }
            }
            // 0x02 for EXCHANGE_GENERIC_FACTORY_ZAP
            case 0x02 {
                // Store function selector for function exchange(address,uint256,uint256,uint256,uint256)
                mstore(ptr, 0x64a1455800000000000000000000000000000000000000000000000000000000)
                mstore(add(ptr, 4), poolAddress) // store poolAddress
                mstore(add(ptr, 36), i) // store index i
                mstore(add(ptr, 68), j) // store index j
                mstore(add(ptr, 100), fromAmount) // store fromAmount
                mstore(add(ptr, 132), 1) // store 1
                // Perform the external call with the prepared calldata
                // Check the outcome of the call and handle failure
                if iszero(call(gas(), exchange, 0, ptr, 164, 0, 0)) {
                    // The call failed; we retrieve the exact error message and revert with it
                    returndatacopy(0, 0, returndatasize()) // Copy the error message to the start of memory
                    revert(0, returndatasize()) // Revert with the error message
                }
            }
            // 0x00(default) for EXCHANGE
            default {
                // check send eth wrap flag
                switch eq(wrapFlag, 0x03)
                // if it is not set, store selector for function exchange(uint256,uint256,uint256,uint256,bool)
                case 1 {
                    mstore(ptr, 0x394747c500000000000000000000000000000000000000000000000000000000) // store selector
                    mstore(add(ptr, 4), i) // store index i
                    mstore(add(ptr, 36), j) // store index j
                    mstore(add(ptr, 68), fromAmount) // store fromAmount
                    mstore(add(ptr, 100), 1) // store 1
                    mstore(add(ptr, 132), 1) // store true
                    // Perform the external call with the prepared calldata
                    // Check the outcome of the call and handle failure
                    if iszero(call(gas(), exchange, callvalue(), ptr, 164, 0, 0)) {
                        // The call failed; we retrieve the exact error message and revert with it
                        returndatacopy(0, 0, returndatasize()) // Copy the error message to the start of memory
                        revert(0, returndatasize()) // Revert with the error message
                    }
                }
                // if it is set, store selector for function exchange(uint256,uint256,uint256,uint256)
                default {
                    mstore(ptr, 0x5b41b90800000000000000000000000000000000000000000000000000000000) // store selector
                    mstore(add(ptr, 4), i) // store index i
                    mstore(add(ptr, 36), j) // store index j
                    mstore(add(ptr, 68), fromAmount) // store fromAmount
                    mstore(add(ptr, 100), 1) // store 1
                    // Perform the external call with the prepared calldata
                    // Check the outcome of the call and handle failure
                    if iszero(call(gas(), exchange, 0, ptr, 132, 0, 0)) {
                        // The call failed; we retrieve the exact error message and revert with it
                        returndatacopy(0, 0, returndatasize()) // Copy the error message to the start of memory
                        revert(0, returndatasize()) // Revert with the error message
                    }
                }
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

// Interfaces
import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";
import { IUniswapV2SwapExactAmountIn } from "../../../interfaces/IUniswapV2SwapExactAmountIn.sol";

// Libraries
import { ERC20Utils } from "../../../libraries/ERC20Utils.sol";

// Types
import { UniswapV2Data } from "../../../AugustusV6Types.sol";

// Utils
import { UniswapV2Utils } from "../../../util/UniswapV2Utils.sol";

/// @title UniswapV2SwapExactAmountIn
/// @notice A contract for executing direct swapExactAmountIn on UniswapV2 pools
abstract contract UniswapV2SwapExactAmountIn is IUniswapV2SwapExactAmountIn, UniswapV2Utils {
    /*//////////////////////////////////////////////////////////////
                               LIBRARIES
    //////////////////////////////////////////////////////////////*/

    using ERC20Utils for IERC20;

    /*//////////////////////////////////////////////////////////////
                                   SWAP
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IUniswapV2SwapExactAmountIn
    function swapExactAmountInOnUniswapV2(
        UniswapV2Data calldata uniData,
        uint256 partnerAndFee,
        bytes calldata permit
    )
        external
        payable
        whenNotPaused
        returns (uint256 receivedAmount, uint256 paraswapShare, uint256 partnerShare)
    {
        // Dereference uniData
        IERC20 srcToken = uniData.srcToken;
        IERC20 destToken = uniData.destToken;
        uint256 amountIn = uniData.fromAmount;
        uint256 minAmountOut = uniData.toAmount;
        uint256 quotedAmountOut = uniData.quotedAmount;
        address payable beneficiary = uniData.beneficiary;
        bytes calldata pools = uniData.pools;

        // Initialize payer
        address payer = msg.sender;

        // Check if toAmount is valid
        if (minAmountOut == 0) {
            revert InvalidToAmount();
        }

        // Check if beneficiary is valid
        if (beneficiary == address(0)) {
            beneficiary = payable(msg.sender);
        }

        // Check if we need to wrap or permit
        if (srcToken.isETH(amountIn) == 0) {
            // Check the length of the permit field,
            // if < 257 and > 0 we should execute regular permit
            if (permit.length < 257) {
                // Permit if needed
                if (permit.length > 0) {
                    srcToken.permit(permit);
                }
            }
        } else {
            // If it is ETH. wrap it to WETH
            WETH.deposit{ value: amountIn }();
            // Set srcToken to WETH
            srcToken = WETH;
            // Set payer to this contract
            payer = address(this);
        }

        // Execute swap
        _callUniswapV2PoolsSwapExactIn(amountIn, srcToken, pools, payer, permit);

        // Check if destToken is ETH and unwrap
        if (address(destToken) == address(ERC20Utils.ETH)) {
            // Check balance of WETH
            receivedAmount = IERC20(WETH).getBalance(address(this));
            // Unwrap WETH
            WETH.withdraw(receivedAmount - 1);
            // Set receivedAmount to this contract's balance
            receivedAmount = address(this).balance;
        } else {
            // Othwerwise check balance of destToken
            receivedAmount = destToken.getBalance(address(this));
        }

        // Check if swap succeeded
        if (receivedAmount < minAmountOut) {
            revert InsufficientReturnAmount();
        }

        // Process fees and transfer destToken to beneficiary
        return processSwapExactAmountInFeesAndTransfer(
            beneficiary, destToken, partnerAndFee, receivedAmount, quotedAmountOut
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

// Interfaces
import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";
import { IUniswapV3SwapExactAmountIn } from "../../../interfaces/IUniswapV3SwapExactAmountIn.sol";

// Libraries
import { ERC20Utils } from "../../../libraries/ERC20Utils.sol";
import { SafeCastLib } from "@solady/utils/SafeCastLib.sol";

// Types
import { UniswapV3Data } from "../../../AugustusV6Types.sol";

// Utils
import { UniswapV3Utils } from "../../../util/UniswapV3Utils.sol";

/// @title UniswapV3SwapExactAmountIn
/// @notice A contract for executing direct swapExactAmountIn on Uniswap V3
abstract contract UniswapV3SwapExactAmountIn is IUniswapV3SwapExactAmountIn, UniswapV3Utils {
    /*//////////////////////////////////////////////////////////////
                               LIBRARIES
    //////////////////////////////////////////////////////////////*/

    using ERC20Utils for IERC20;
    using SafeCastLib for uint256;

    /*//////////////////////////////////////////////////////////////
                                   SWAP
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IUniswapV3SwapExactAmountIn
    function swapExactAmountInOnUniswapV3(
        UniswapV3Data calldata uniData,
        uint256 partnerAndFee,
        bytes calldata permit
    )
        external
        payable
        whenNotPaused
        returns (uint256 receivedAmount, uint256 paraswapShare, uint256 partnerShare)
    {
        // Dereference uniData
        IERC20 srcToken = uniData.srcToken;
        IERC20 destToken = uniData.destToken;
        uint256 amountIn = uniData.fromAmount;
        uint256 minAmountOut = uniData.toAmount;
        uint256 quotedAmountOut = uniData.quotedAmount;
        address payable beneficiary = uniData.beneficiary;
        bytes calldata pools = uniData.pools;

        // Check if toAmount is valid
        if (minAmountOut == 0) {
            revert InvalidToAmount();
        }

        // Check if beneficiary is valid
        if (beneficiary == address(0)) {
            beneficiary = payable(msg.sender);
        }

        // Address that will pay for the swap
        address fromAddress = msg.sender;

        // Check if we need to wrap or permit
        if (srcToken.isETH(amountIn) == 0) {
            // Check the length of the permit field,
            // if < 257 and > 0 we should execute regular permit
            if (permit.length < 257) {
                // Permit if needed
                if (permit.length > 0) {
                    srcToken.permit(permit);
                }
            }
        } else {
            // If it is ETH. wrap it to WETH
            WETH.deposit{ value: amountIn }();
            // Swap will be paid from this contract
            fromAddress = address(this);
        }

        // Execute swap
        receivedAmount = _callUniswapV3PoolsSwapExactAmountIn(amountIn.toInt256(), pools, fromAddress, permit);

        // Check if swap succeeded
        if (receivedAmount < minAmountOut) {
            revert InsufficientReturnAmount();
        }

        // Check if destToken is ETH and unwrap
        if (address(destToken) == address(ERC20Utils.ETH)) {
            // Unwrap WETH
            WETH.withdraw(receivedAmount);
        }

        // Process fees and transfer destToken to beneficiary
        return processSwapExactAmountInFeesAndTransferUniV3(
            beneficiary, destToken, partnerAndFee, receivedAmount, quotedAmountOut
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

// Interfaces
import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";
import { IBalancerV2SwapExactAmountOut } from "../../../interfaces/IBalancerV2SwapExactAmountOut.sol";

// Libraries
import { ERC20Utils } from "../../../libraries/ERC20Utils.sol";

// Types
import { BalancerV2Data } from "../../../AugustusV6Types.sol";

// Utils
import { BalancerV2Utils } from "../../../util/BalancerV2Utils.sol";

/// @title BalancerV2SwapExactAmountOut
/// @notice A contract for executing direct swapExactAmountOut on BalancerV2 pools
abstract contract BalancerV2SwapExactAmountOut is IBalancerV2SwapExactAmountOut, BalancerV2Utils {
    /*//////////////////////////////////////////////////////////////
                               LIBRARIES
    //////////////////////////////////////////////////////////////*/

    using ERC20Utils for IERC20;

    /*//////////////////////////////////////////////////////////////
                         SWAP EXACT AMOUNT OUT
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IBalancerV2SwapExactAmountOut
    function swapExactAmountOutOnBalancerV2(
        BalancerV2Data calldata balancerData,
        uint256 partnerAndFee,
        bytes calldata permit,
        bytes calldata data
    )
        external
        payable
        whenNotPaused
        returns (uint256 spentAmount, uint256 receivedAmount, uint256 paraswapShare, uint256 partnerShare)
    {
        // Dereference balancerData
        uint256 quotedAmountIn = balancerData.quotedAmount;
        uint256 beneficiaryAndApproveFlag = balancerData.beneficiaryAndApproveFlag;
        uint256 maxAmountIn = balancerData.fromAmount;
        uint256 amountOut = balancerData.toAmount;

        // Decode params
        (IERC20 srcToken, IERC20 destToken, address payable beneficiary, bool approve) =
            _decodeBalancerV2Params(beneficiaryAndApproveFlag, data);

        // Make sure srcToken and destToken are different
        if (srcToken == destToken) {
            revert ArbitrageNotSupported();
        }

        // Check if toAmount is valid
        if (amountOut == 0) {
            revert InvalidToAmount();
        }

        // Check if beneficiary is valid
        if (beneficiary == address(0)) {
            beneficiary = payable(msg.sender);
        }

        // Check contract balance
        uint256 balanceBefore = srcToken.getBalance(address(this));

        // Check if srcToken is ETH
        if (srcToken.isETH(maxAmountIn) == 0) {
            // Check the length of the permit field,
            // if < 257 and > 0 we should execute regular permit
            // and if it is >= 257 we execute permit2
            if (permit.length < 257) {
                // Permit if needed
                if (permit.length > 0) {
                    srcToken.permit(permit);
                }
                srcToken.safeTransferFrom(msg.sender, address(this), maxAmountIn);
            } else {
                // Otherwise Permit2.permitTransferFrom
                permit2TransferFrom(permit, address(this), maxAmountIn);
            }
            // Check if approve is needed
            if (approve) {
                // Approve BALANCER_VAULT to spend srcToken
                srcToken.approve(BALANCER_VAULT);
            }
        } else {
            // If srcToken is ETH, we have to deduct msg.value from balanceBefore
            balanceBefore = balanceBefore - msg.value;
        }

        // Execute swap
        _callBalancerV2(data);

        // Check balance of destToken
        receivedAmount = destToken.getBalance(address(this));

        // Check balance of srcToken, deducting the balance before the swap if it is greater than 1
        uint256 remainingAmount = srcToken.getBalance(address(this)) - (balanceBefore > 1 ? balanceBefore : 0);

        // Check if swap succeeded
        if (receivedAmount < amountOut) {
            revert InsufficientReturnAmount();
        }

        // Process fees and transfer destToken and srcToken to beneficiary
        return processSwapExactAmountOutFeesAndTransfer(
            beneficiary,
            srcToken,
            destToken,
            partnerAndFee,
            maxAmountIn,
            remainingAmount,
            receivedAmount,
            quotedAmountIn
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

// Interfaces
import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";
import { IUniswapV2SwapExactAmountOut } from "../../../interfaces/IUniswapV2SwapExactAmountOut.sol";

// Libraries
import { ERC20Utils } from "../../../libraries/ERC20Utils.sol";

// Types
import { UniswapV2Data } from "../../../AugustusV6Types.sol";

// Utils
import { UniswapV2Utils } from "../../../util/UniswapV2Utils.sol";

/// @title UniswapV2SwapExactAmountOut
/// @notice A contract for executing direct swapExactAmountOut on UniswapV2 pools
abstract contract UniswapV2SwapExactAmountOut is IUniswapV2SwapExactAmountOut, UniswapV2Utils {
    /*//////////////////////////////////////////////////////////////
                               LIBRARIES
    //////////////////////////////////////////////////////////////*/

    using ERC20Utils for IERC20;

    /*//////////////////////////////////////////////////////////////
                         SWAP EXACT AMOUNT OUT
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IUniswapV2SwapExactAmountOut
    function swapExactAmountOutOnUniswapV2(
        UniswapV2Data calldata uniData,
        uint256 partnerAndFee,
        bytes calldata permit
    )
        external
        payable
        whenNotPaused
        returns (uint256 spentAmount, uint256 receivedAmount, uint256 paraswapShare, uint256 partnerShare)
    {
        // Dereference uniData
        IERC20 srcToken = uniData.srcToken;
        IERC20 destToken = uniData.destToken;
        uint256 maxAmountIn = uniData.fromAmount;
        uint256 amountOut = uniData.toAmount;
        uint256 quotedAmountIn = uniData.quotedAmount;
        address payable beneficiary = uniData.beneficiary;
        bytes calldata pools = uniData.pools;

        // Check if toAmount is valid
        if (amountOut == 0) {
            revert InvalidToAmount();
        }

        // Check if beneficiary is valid
        if (beneficiary == address(0)) {
            beneficiary = payable(msg.sender);
        }

        // Init balanceBefore
        uint256 balanceBefore;

        // Check if srcToken is ETH
        bool isFromETH = srcToken.isETH(maxAmountIn) != 0;

        // Check if we need to wrap or permit
        if (isFromETH) {
            // Check WETH balance before
            balanceBefore = IERC20(WETH).getBalance(address(this));
            // If it is ETH. wrap it to WETH
            WETH.deposit{ value: maxAmountIn }();
            // Set srcToken to WETH
            srcToken = WETH;
        } else {
            // Check srcToken balance before
            balanceBefore = srcToken.getBalance(address(this));
            // Check the length of the permit field,
            // if < 257 and > 0 we should execute regular permit
            // and if it is >= 257 we execute permit2
            if (permit.length < 257) {
                // Permit if needed
                if (permit.length > 0) {
                    srcToken.permit(permit);
                }
                srcToken.safeTransferFrom(msg.sender, address(this), maxAmountIn);
            } else {
                // Otherwise Permit2.permitTransferFrom
                permit2TransferFrom(permit, address(this), maxAmountIn);
            }
        }

        // Make sure srcToken and destToken are different
        if (srcToken == destToken) {
            revert ArbitrageNotSupported();
        }

        // Execute swap
        _callUniswapV2PoolsSwapExactOut(amountOut, srcToken, pools);

        // Check if destToken is ETH and unwrap
        if (address(destToken) == address(ERC20Utils.ETH)) {
            // Make sure srcToken was not WETH
            if (srcToken == WETH) {
                revert ArbitrageNotSupported();
            }
            // Check balance of WETH
            receivedAmount = IERC20(WETH).getBalance(address(this));
            // Leave dust if receivedAmount > amountOut
            if (receivedAmount > amountOut) {
                --receivedAmount;
            }
            // Unwrap WETH
            WETH.withdraw(receivedAmount);
            // Set receivedAmount to this contract's balance
            receivedAmount = address(this).balance;
        } else {
            // Othwerwise check balance of destToken
            receivedAmount = destToken.getBalance(address(this));
        }

        // Check balance of srcToken
        uint256 remainingAmount = srcToken.getBalance(address(this));

        // Check if swap succeeded
        if (receivedAmount < amountOut) {
            revert InsufficientReturnAmount();
        }

        // Check if srcToken is ETH and unwrap if there is remaining amount
        if (isFromETH) {
            // Check native balance before
            uint256 nativeBalanceBefore = address(this).balance;
            // If balanceBefore is greater than 1, deduct it from remainingAmount
            remainingAmount = remainingAmount - (balanceBefore > 1 ? balanceBefore : 0);
            // Withdraw remaining WETH if any
            if (remainingAmount > 1) {
                WETH.withdraw(remainingAmount - 1);
            }
            srcToken = ERC20Utils.ETH;
            // If native balance before is greater than 1, deduct it from remainingAmount
            remainingAmount = address(this).balance - (nativeBalanceBefore > 1 ? nativeBalanceBefore : 0);
        } else {
            // Otherwise, if balanceBefore is greater than 1, deduct it from remainingAmount
            remainingAmount = remainingAmount - (balanceBefore > 1 ? balanceBefore : 0);
        }

        // Process fees and transfer destToken and srcToken to beneficiary
        return processSwapExactAmountOutFeesAndTransfer(
            beneficiary,
            srcToken,
            destToken,
            partnerAndFee,
            maxAmountIn,
            remainingAmount,
            receivedAmount,
            quotedAmountIn
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

// Interfaces
import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";
import { IUniswapV3SwapExactAmountOut } from "../../../interfaces/IUniswapV3SwapExactAmountOut.sol";

// Libraries
import { ERC20Utils } from "../../../libraries/ERC20Utils.sol";
import { SafeCastLib } from "@solady/utils/SafeCastLib.sol";

// Types
import { UniswapV3Data } from "../../../AugustusV6Types.sol";

// Utils
import { UniswapV3Utils } from "../../../util/UniswapV3Utils.sol";

/// @title UniswapV3SwapExactAmountOut
/// @notice A contract for executing direct swapExactAmountOut on UniswapV3 pools
abstract contract UniswapV3SwapExactAmountOut is IUniswapV3SwapExactAmountOut, UniswapV3Utils {
    /*//////////////////////////////////////////////////////////////
                               LIBRARIES
    //////////////////////////////////////////////////////////////*/

    using ERC20Utils for IERC20;
    using SafeCastLib for uint256;

    /*//////////////////////////////////////////////////////////////
                         SWAP EXACT AMOUNT OUT
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IUniswapV3SwapExactAmountOut
    function swapExactAmountOutOnUniswapV3(
        UniswapV3Data calldata uniData,
        uint256 partnerAndFee,
        bytes calldata permit
    )
        external
        payable
        whenNotPaused
        returns (uint256 spentAmount, uint256 receivedAmount, uint256 paraswapShare, uint256 partnerShare)
    {
        // Dereference uniData
        IERC20 srcToken = uniData.srcToken;
        IERC20 destToken = uniData.destToken;
        uint256 maxAmountIn = uniData.fromAmount;
        uint256 amountOut = uniData.toAmount;
        uint256 quotedAmountIn = uniData.quotedAmount;
        address payable beneficiary = uniData.beneficiary;
        bytes calldata pools = uniData.pools;

        // Check if toAmount is valid
        if (amountOut == 0) {
            revert InvalidToAmount();
        }

        // Check if beneficiary is valid
        if (beneficiary == address(0)) {
            beneficiary = payable(msg.sender);
        }

        // Address that will pay for the swap
        address fromAddress = msg.sender;

        // Check if srcToken is ETH
        bool isFromETH = srcToken.isETH(maxAmountIn) != 0;

        // If pools.length > 96, we are going to do a multi-pool swap
        bool isMultiplePools = pools.length > 96;

        // Init balance before variables
        uint256 senderBalanceBefore;
        uint256 balanceBefore;

        // Check if we need to wrap or permit
        if (isFromETH) {
            // Check WETH balance before
            balanceBefore = IERC20(WETH).getBalance(address(this));
            // If it is ETH. wrap it to WETH
            WETH.deposit{ value: maxAmountIn }();
            // Swap will be paid from this contract
            fromAddress = address(this);
            // Set srcToken to WETH
            srcToken = WETH;
        } else {
            // Check srcToken balance before
            balanceBefore = srcToken.getBalance(address(this));
            // Check the length of the permit field,
            // if < 257 and > 0 we should execute regular permit
            // and if it is >= 257 we execute permit2
            if (permit.length < 257) {
                // Permit if needed
                if (permit.length > 0) {
                    srcToken.permit(permit);
                }
                // if we're using multiple pools, we need to store the pre-swap balance of srcToken
                if (isMultiplePools) {
                    senderBalanceBefore = srcToken.getBalance(msg.sender);
                }
            } else {
                // Otherwise Permit2.permitTransferFrom
                permit2TransferFrom(permit, address(this), maxAmountIn);
                // Swap will be paid from this contract
                fromAddress = address(this);
            }
        }

        // Make sure srcToken and destToken are different
        if (srcToken == destToken) {
            revert ArbitrageNotSupported();
        }

        // Execute swap
        (spentAmount, receivedAmount) =
            _callUniswapV3PoolsSwapExactAmountOut((-amountOut.toInt256()), pools, fromAddress);

        // Check if swap succeeded
        if (receivedAmount < amountOut) {
            revert InsufficientReturnAmount();
        }

        // Check if destToken is ETH and unwrap
        if (address(destToken) == address(ERC20Utils.ETH)) {
            // Make sure srcToken was not WETH
            if (srcToken == WETH) {
                revert ArbitrageNotSupported();
            }
            // Unwrap WETH
            WETH.withdraw(receivedAmount);
        }

        // Iniiialize remainingAmount
        uint256 remainingAmount;

        // Check if payer is this contract
        if (fromAddress == address(this)) {
            // If srcTokenwas ETH, we need to withdraw remaining WETH if any
            if (isFromETH) {
                // Check native balance before
                uint256 nativeBalanceBefore = address(this).balance;
                // Check balance of WETH, If balanceBefore is greater than 1, deduct it from remainingAmount
                remainingAmount = IERC20(WETH).getBalance(address(this)) - (balanceBefore > 1 ? balanceBefore : 0);
                // Withdraw remaining WETH if any
                if (remainingAmount > 1) {
                    // Unwrap WETH
                    WETH.withdraw(remainingAmount - 1);
                    // If native balance before is greater than 1, deduct it from remainingAmount
                    remainingAmount = address(this).balance - (nativeBalanceBefore > 1 ? nativeBalanceBefore : 0);
                }
                // Set srcToken to ETH
                srcToken = ERC20Utils.ETH;
            } else {
                // If we have executed multi-pool swap, we need to fetch the remaining amount from balance
                if (isMultiplePools) {
                    // Calculate spent amount and remaining amount, If balanceBefore is greater than 1, deduct it from
                    // remainingAmount
                    remainingAmount = srcToken.getBalance(address(this)) - (balanceBefore > 1 ? balanceBefore : 0);
                } else {
                    // Otherwise, remaining amount is the difference between the spent amount and the remaining balance
                    remainingAmount = maxAmountIn - spentAmount;
                }
            }

            // Process fees using processSwapExactAmountOutFeesAndTransfer
            return processSwapExactAmountOutFeesAndTransfer(
                beneficiary,
                srcToken,
                destToken,
                partnerAndFee,
                maxAmountIn,
                remainingAmount,
                receivedAmount,
                quotedAmountIn
            );
        } else {
            // If we have executed multi-pool swap, we need to re-calculate the remaining amount and spent amount
            if (isMultiplePools) {
                // Calculate spent amount and remaining amount
                remainingAmount = srcToken.getBalance(msg.sender);
                spentAmount = senderBalanceBefore - remainingAmount;
            }
            // Process fees and transfer destToken and srcToken to feeVault or partner and
            // feeWallet if needed
            return processSwapExactAmountOutFeesAndTransferUniV3(
                beneficiary,
                srcToken,
                destToken,
                partnerAndFee,
                maxAmountIn,
                receivedAmount,
                spentAmount,
                quotedAmountIn
            );
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

// Interfaces
import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";
import { IAugustusFeeVault } from "../interfaces/IAugustusFeeVault.sol";
import { IAugustusFees } from "../interfaces/IAugustusFees.sol";

// Libraries
import { ERC20Utils } from "../libraries/ERC20Utils.sol";

// Storage
import { AugustusStorage } from "../storage/AugustusStorage.sol";

/// @title AugustusFees
/// @notice Contract for handling fees
contract AugustusFees is AugustusStorage, IAugustusFees {
    /*//////////////////////////////////////////////////////////////
                               LIBRARIES
    //////////////////////////////////////////////////////////////*/

    using ERC20Utils for IERC20;

    /*//////////////////////////////////////////////////////////////
                               CONSTANTS
    //////////////////////////////////////////////////////////////*/

    /// @dev Fee share constants
    uint256 public constant PARTNER_SHARE_PERCENT = 8500;
    uint256 public constant MAX_FEE_PERCENT = 200;
    uint256 public constant SURPLUS_PERCENT = 100;
    uint256 public constant PARASWAP_REFERRAL_SHARE = 5000;
    uint256 public constant PARTNER_REFERRAL_SHARE = 2500;
    uint256 public constant PARASWAP_SURPLUS_SHARE = 5000;
    uint256 public constant PARASWAP_SLIPPAGE_SHARE = 10_000;
    uint256 public constant MINIMUM_SURPLUS_EPSILON_AND_ONE_WEI = 11;

    /// @dev Masks for unpacking feeData
    uint256 private constant FEE_PERCENT_IN_BASIS_POINTS_MASK = 0x3FFF;
    uint256 private constant IS_USER_SURPLUS_MASK = 1 << 90;
    uint256 private constant IS_DIRECT_TRANSFER_MASK = 1 << 91;
    uint256 private constant IS_CAP_SURPLUS_MASK = 1 << 92;
    uint256 private constant IS_SKIP_BLACKLIST_MASK = 1 << 93;
    uint256 private constant IS_REFERRAL_MASK = 1 << 94;
    uint256 private constant IS_TAKE_SURPLUS_MASK = 1 << 95;

    /// @dev A contact that stores fees collected by the protocol
    IAugustusFeeVault public immutable FEE_VAULT; // solhint-disable-line var-name-mixedcase

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _feeVault) {
        FEE_VAULT = IAugustusFeeVault(_feeVault);
    }

    /*//////////////////////////////////////////////////////////////
                       SWAP EXACT AMOUNT IN FEES
    //////////////////////////////////////////////////////////////*/

    /// @notice Process swapExactAmountIn fees and transfer the received amount to the beneficiary
    /// @param destToken The received token from the swapExactAmountIn
    /// @param partnerAndFee Packed partner and fee data
    /// @param receivedAmount The amount of destToken received from the swapExactAmountIn
    /// @param quotedAmount The quoted expected amount of destToken
    /// @return returnAmount The amount of destToken transfered to the beneficiary
    /// @return paraswapFeeShare The share of the fees for Paraswap
    /// @return partnerFeeShare The share of the fees for the partner
    function processSwapExactAmountInFeesAndTransfer(
        address beneficiary,
        IERC20 destToken,
        uint256 partnerAndFee,
        uint256 receivedAmount,
        uint256 quotedAmount
    )
        internal
        returns (uint256 returnAmount, uint256 paraswapFeeShare, uint256 partnerFeeShare)
    {
        // initialize the surplus
        uint256 surplus;

        // parse partner and fee data
        (address payable partner, uint256 feeData) = parsePartnerAndFeeData(partnerAndFee);

        // calculate the surplus, we expect there to be 1 wei dust left which we should
        // not take into account when determining if there is surplus, we only take the
        // surplus if it is greater than MINIMUM_SURPLUS_EPSILON_AND_ONE_WEI
        if (receivedAmount > quotedAmount + MINIMUM_SURPLUS_EPSILON_AND_ONE_WEI) {
            surplus = receivedAmount - quotedAmount;
            // if the cap surplus flag is passed, we cap the surplus to 1% of the quoted amount
            if (feeData & IS_CAP_SURPLUS_MASK != 0) {
                uint256 cappedSurplus = (SURPLUS_PERCENT * quotedAmount) / 10_000;
                surplus = surplus > cappedSurplus ? cappedSurplus : surplus;
            }
        }

        // calculate remainingAmount
        uint256 remainingAmount = receivedAmount - surplus;

        // if partner address is not 0x0
        if (partner != address(0x0)) {
            // Check if skip blacklist flag is true
            bool skipBlacklist = feeData & IS_SKIP_BLACKLIST_MASK != 0;
            // Check if token is blacklisted
            bool isBlacklisted = blacklistedTokens[destToken];
            // If the token is blacklisted and the skipBlacklist flag is false,
            // send the received amount to the beneficiary, we won't process fees
            if (!skipBlacklist && isBlacklisted) {
                // transfer the received amount to the beneficiary, keeping 1 wei dust
                _transferAndLeaveDust(destToken, beneficiary, receivedAmount);
                return (receivedAmount - 1, 0, 0);
            }
            // Check if direct transfer flag is true
            bool isDirectTransfer = feeData & IS_DIRECT_TRANSFER_MASK != 0;
            // partner takes fixed fees feePercent is greater than 0
            uint256 feePercent = _getAdjustedFeePercent(feeData);
            if (feePercent > 0) {
                // fee base = min (receivedAmount, quotedAmount + surplus)
                uint256 feeBase = receivedAmount > quotedAmount + surplus ? quotedAmount + surplus : receivedAmount;
                // calculate fixed fees
                uint256 fee = (feeBase * feePercent) / 10_000;
                partnerFeeShare = (fee * PARTNER_SHARE_PERCENT) / 10_000;
                paraswapFeeShare = fee - partnerFeeShare;
                // distrubite fees from destToken
                returnAmount = _distributeFees(
                    receivedAmount,
                    destToken,
                    partner,
                    partnerFeeShare,
                    paraswapFeeShare,
                    skipBlacklist,
                    isBlacklisted,
                    isDirectTransfer
                );
                // transfer the return amount to the beneficiary, keeping 1 wei dust
                _transferAndLeaveDust(destToken, beneficiary, returnAmount);
                return (returnAmount - 1, paraswapFeeShare, partnerFeeShare);
            }
            // if slippage is postive and referral flag is true
            else if (feeData & IS_REFERRAL_MASK != 0) {
                if (surplus > 0) {
                    // the split is 50% for paraswap, 25% for the referrer and 25% for the user
                    paraswapFeeShare = (surplus * PARASWAP_REFERRAL_SHARE) / 10_000;
                    partnerFeeShare = (surplus * PARTNER_REFERRAL_SHARE) / 10_000;
                    // distribute fees from destToken
                    returnAmount = _distributeFees(
                        receivedAmount,
                        destToken,
                        partner,
                        partnerFeeShare,
                        paraswapFeeShare,
                        skipBlacklist,
                        isBlacklisted,
                        isDirectTransfer
                    );
                    // transfer the return amount to the beneficiary, keeping 1 wei dust
                    _transferAndLeaveDust(destToken, beneficiary, returnAmount);
                    return (returnAmount - 1, paraswapFeeShare, partnerFeeShare);
                }
            }
            // if slippage is positive and takeSurplus flag is true
            else if (feeData & IS_TAKE_SURPLUS_MASK != 0) {
                if (surplus > 0) {
                    // paraswap takes 50% of the surplus and partner takes the other 50%
                    paraswapFeeShare = (surplus * PARASWAP_SURPLUS_SHARE) / 10_000;
                    partnerFeeShare = surplus - paraswapFeeShare;
                    // If user surplus flag is true, transfer the partner share to the user instead of the partner
                    if (feeData & IS_USER_SURPLUS_MASK != 0) {
                        partnerFeeShare = 0;
                        // Transfer the paraswap share directly to the fee wallet
                        isDirectTransfer = true;
                    }
                    // distrubite fees from destToken, partner takes 50% of the surplus
                    // and paraswap takes the other 50%
                    returnAmount = _distributeFees(
                        receivedAmount,
                        destToken,
                        partner,
                        partnerFeeShare,
                        paraswapFeeShare,
                        skipBlacklist,
                        isBlacklisted,
                        isDirectTransfer
                    );
                    // transfer the return amount to the beneficiary, keeping 1 wei dust
                    _transferAndLeaveDust(destToken, beneficiary, returnAmount);
                    return (returnAmount - 1, paraswapFeeShare, partnerFeeShare);
                }
            }
        }

        // if slippage is positive and partner address is 0x0 or fee percent is 0
        // paraswap will take the surplus and transfer the rest to the beneficiary
        // if there is no positive slippage, transfer the received amount to the beneficiary
        if (surplus > 0) {
            // If the token is blacklisted, send the received amount to the beneficiary
            // we won't process fees
            if (blacklistedTokens[destToken]) {
                // transfer the received amount to the beneficiary, keeping 1 wei dust
                _transferAndLeaveDust(destToken, beneficiary, receivedAmount);
                return (receivedAmount - 1, 0, 0);
            }
            // transfer the remaining amount to the beneficiary, keeping 1 wei dust
            _transferAndLeaveDust(destToken, beneficiary, remainingAmount);
            // transfer the surplus to the fee wallet
            destToken.safeTransfer(feeWallet, surplus);
            return (remainingAmount - 1, surplus, 0);
        } else {
            // transfer the received amount to the beneficiary, keeping 1 wei dust
            _transferAndLeaveDust(destToken, beneficiary, receivedAmount);
            return (receivedAmount - 1, 0, 0);
        }
    }

    /// @notice Process swapExactAmountIn fees and transfer the received amount to the beneficiary
    /// @param destToken The received token from the swapExactAmountIn
    /// @param partnerAndFee Packed partner and fee data
    /// @param receivedAmount The amount of destToken received from the swapExactAmountIn
    /// @param quotedAmount The quoted expected amount of destToken
    /// @return returnAmount The amount of destToken transfered to the beneficiary
    /// @return paraswapFeeShare The share of the fees for Paraswap
    /// @return partnerFeeShare The share of the fees for the partner
    function processSwapExactAmountInFeesAndTransferUniV3(
        address beneficiary,
        IERC20 destToken,
        uint256 partnerAndFee,
        uint256 receivedAmount,
        uint256 quotedAmount
    )
        internal
        returns (uint256 returnAmount, uint256 paraswapFeeShare, uint256 partnerFeeShare)
    {
        // initialize the surplus
        uint256 surplus;

        // parse partner and fee data
        (address payable partner, uint256 feeData) = parsePartnerAndFeeData(partnerAndFee);

        // calculate the surplus, we do not take the surplus into account if it is less than
        // MINIMUM_SURPLUS_EPSILON_AND_ONE_WEI
        if (receivedAmount > quotedAmount + MINIMUM_SURPLUS_EPSILON_AND_ONE_WEI) {
            surplus = receivedAmount - quotedAmount;
            // if the cap surplus flag is passed, we cap the surplus to 1% of the quoted amount
            if (feeData & IS_CAP_SURPLUS_MASK != 0) {
                uint256 cappedSurplus = (SURPLUS_PERCENT * quotedAmount) / 10_000;
                surplus = surplus > cappedSurplus ? cappedSurplus : surplus;
            }
        }

        // calculate remainingAmount
        uint256 remainingAmount = receivedAmount - surplus;

        // if partner address is not 0x0
        if (partner != address(0x0)) {
            // Check if skip blacklist flag is true
            bool skipBlacklist = feeData & IS_SKIP_BLACKLIST_MASK != 0;
            // Check if token is blacklisted
            bool isBlacklisted = blacklistedTokens[destToken];
            // If the token is blacklisted and the skipBlacklist flag is false,
            // send the received amount to the beneficiary, we won't process fees
            if (!skipBlacklist && isBlacklisted) {
                // transfer the received amount to the beneficiary
                destToken.safeTransfer(beneficiary, receivedAmount);
                return (receivedAmount, 0, 0);
            }
            // Check if direct transfer flag is true
            bool isDirectTransfer = feeData & IS_DIRECT_TRANSFER_MASK != 0;
            // partner takes fixed fees feePercent is greater than 0
            uint256 feePercent = _getAdjustedFeePercent(feeData);
            if (feePercent > 0) {
                // fee base = min (receivedAmount, quotedAmount + surplus)
                uint256 feeBase = receivedAmount > quotedAmount + surplus ? quotedAmount + surplus : receivedAmount;
                // calculate fixed fees
                uint256 fee = (feeBase * feePercent) / 10_000;
                partnerFeeShare = (fee * PARTNER_SHARE_PERCENT) / 10_000;
                paraswapFeeShare = fee - partnerFeeShare;
                // distrubite fees from destToken
                returnAmount = _distributeFees(
                    receivedAmount,
                    destToken,
                    partner,
                    partnerFeeShare,
                    paraswapFeeShare,
                    skipBlacklist,
                    isBlacklisted,
                    isDirectTransfer
                );
                // transfer the return amount to the beneficiary
                destToken.safeTransfer(beneficiary, returnAmount);
                return (returnAmount, paraswapFeeShare, partnerFeeShare);
            }
            // if slippage is postive and referral flag is true
            else if (feeData & IS_REFERRAL_MASK != 0) {
                if (surplus > 0) {
                    // the split is 50% for paraswap, 25% for the referrer and 25% for the user
                    paraswapFeeShare = (surplus * PARASWAP_REFERRAL_SHARE) / 10_000;
                    partnerFeeShare = (surplus * PARTNER_REFERRAL_SHARE) / 10_000;
                    // distribute fees from destToken
                    returnAmount = _distributeFees(
                        receivedAmount,
                        destToken,
                        partner,
                        partnerFeeShare,
                        paraswapFeeShare,
                        skipBlacklist,
                        isBlacklisted,
                        isDirectTransfer
                    );
                    // transfer the return amount to the beneficiary
                    destToken.safeTransfer(beneficiary, returnAmount);
                    return (returnAmount, paraswapFeeShare, partnerFeeShare);
                }
            }
            // if slippage is positive and takeSurplus flag is true
            else if (feeData & IS_TAKE_SURPLUS_MASK != 0) {
                if (surplus > 0) {
                    // paraswap takes 50% of the surplus and partner takes the other 50%
                    paraswapFeeShare = (surplus * PARASWAP_SURPLUS_SHARE) / 10_000;
                    partnerFeeShare = surplus - paraswapFeeShare;
                    // If user surplus flag is true, transfer the partner share to the user instead of the partner
                    if (feeData & IS_USER_SURPLUS_MASK != 0) {
                        partnerFeeShare = 0;
                        // Transfer the paraswap share directly to the fee wallet
                        isDirectTransfer = true;
                    }
                    // distrubite fees from destToken, partner takes 50% of the surplus
                    // and paraswap takes the other 50%
                    returnAmount = _distributeFees(
                        receivedAmount,
                        destToken,
                        partner,
                        partnerFeeShare,
                        paraswapFeeShare,
                        skipBlacklist,
                        isBlacklisted,
                        isDirectTransfer
                    );
                    // transfer the return amount to the beneficiary,
                    destToken.safeTransfer(beneficiary, returnAmount);
                    return (returnAmount, paraswapFeeShare, partnerFeeShare);
                }
            }
        }

        // if slippage is positive and partner address is 0x0 or fee percent is 0
        // paraswap will take the surplus and transfer the rest to the beneficiary
        // if there is no positive slippage, transfer the received amount to the beneficiary
        if (surplus > 0) {
            // If the token is blacklisted, send the received amount to the beneficiary
            // we won't process fees
            if (blacklistedTokens[destToken]) {
                // transfer the received amount to the beneficiary
                destToken.safeTransfer(beneficiary, receivedAmount);
                return (receivedAmount, 0, 0);
            }
            // transfer the remaining amount to the beneficiary
            destToken.safeTransfer(beneficiary, remainingAmount);
            // transfer the surplus to the fee wallet
            destToken.safeTransfer(feeWallet, surplus);
            return (remainingAmount, surplus, 0);
        } else {
            // transfer the received amount to the beneficiary
            destToken.safeTransfer(beneficiary, receivedAmount);
            return (receivedAmount, 0, 0);
        }
    }

    /*//////////////////////////////////////////////////////////////
                       SWAP EXACT AMOUNT OUT FEES
    //////////////////////////////////////////////////////////////*/

    /// @notice Process swapExactAmountOut fees and transfer the received amount and remaining amount to the
    /// beneficiary
    /// @param srcToken The token used to swapExactAmountOut
    /// @param destToken The token received from the swapExactAmountOut
    /// @param partnerAndFee Packed partner and fee data
    /// @param maxAmountIn The amount of srcToken passed to the swapExactAmountOut
    /// @param receivedAmount The amount of destToken received from the swapExactAmountOut
    /// @param quotedAmount The quoted expected amount of srcToken to be used to swapExactAmountOut
    /// @return spentAmount The amount of srcToken used to swapExactAmountOut
    /// @return outAmount The amount of destToken transfered to the beneficiary
    /// @return paraswapFeeShare The share of the fees for Paraswap
    /// @return partnerFeeShare The share of the fees for the partner
    function processSwapExactAmountOutFeesAndTransfer(
        address beneficiary,
        IERC20 srcToken,
        IERC20 destToken,
        uint256 partnerAndFee,
        uint256 maxAmountIn,
        uint256 remainingAmount,
        uint256 receivedAmount,
        uint256 quotedAmount
    )
        internal
        returns (uint256 spentAmount, uint256 outAmount, uint256 paraswapFeeShare, uint256 partnerFeeShare)
    {
        // calculate the amount used to swapExactAmountOut
        spentAmount = maxAmountIn - (remainingAmount > 0 ? remainingAmount - 1 : remainingAmount);

        // initialize the surplus
        uint256 surplus;

        // initialize the return amount
        uint256 returnAmount;

        // parse partner and fee data
        (address payable partner, uint256 feeData) = parsePartnerAndFeeData(partnerAndFee);

        // check if the quotedAmount is bigger than the maxAmountIn
        if (quotedAmount > maxAmountIn) {
            revert InvalidQuotedAmount();
        }

        // calculate the surplus, we do not take the surplus into account if it is less than
        // MINIMUM_SURPLUS_EPSILON_AND_ONE_WEI
        if (quotedAmount > spentAmount + MINIMUM_SURPLUS_EPSILON_AND_ONE_WEI) {
            surplus = quotedAmount - spentAmount;
            // if the cap surplus flag is passed, we cap the surplus to 1% of the quoted amount
            if (feeData & IS_CAP_SURPLUS_MASK != 0) {
                uint256 cappedSurplus = (SURPLUS_PERCENT * quotedAmount) / 10_000;
                surplus = surplus > cappedSurplus ? cappedSurplus : surplus;
            }
        }

        // if partner address is not 0x0
        if (partner != address(0x0)) {
            // Check if skip blacklist flag is true
            bool skipBlacklist = feeData & IS_SKIP_BLACKLIST_MASK != 0;
            // Check if token is blacklisted
            bool isBlacklisted = blacklistedTokens[srcToken];
            // If the token is blacklisted and the skipBlacklist flag is false,
            // send the remaining amount to the msg.sender, we won't process fees
            if (!skipBlacklist && isBlacklisted) {
                // transfer the remaining amount to msg.sender
                returnAmount = _transferIfGreaterThanOne(srcToken, msg.sender, remainingAmount);
                // transfer the received amount of destToken to the beneficiary
                destToken.safeTransfer(beneficiary, --receivedAmount);
                return (maxAmountIn - returnAmount, receivedAmount, 0, 0);
            }
            // Check if direct transfer flag is true
            bool isDirectTransfer = feeData & IS_DIRECT_TRANSFER_MASK != 0;
            // partner takes fixed fees feePercent is greater than 0
            uint256 feePercent = _getAdjustedFeePercent(feeData);
            if (feePercent > 0) {
                // fee base = min (spentAmount, quotedAmount)
                uint256 feeBase = spentAmount < quotedAmount ? spentAmount : quotedAmount;
                // calculate fixed fees
                uint256 fee = (feeBase * feePercent) / 10_000;
                partnerFeeShare = (fee * PARTNER_SHARE_PERCENT) / 10_000;
                paraswapFeeShare = fee - partnerFeeShare;
                // distrubite fees from srcToken
                returnAmount = _distributeFees(
                    remainingAmount,
                    srcToken,
                    partner,
                    partnerFeeShare,
                    paraswapFeeShare,
                    skipBlacklist,
                    isBlacklisted,
                    isDirectTransfer
                );
                // transfer the rest to msg.sender
                returnAmount = _transferIfGreaterThanOne(srcToken, msg.sender, returnAmount);
                // transfer the received amount of destToken to the beneficiary
                destToken.safeTransfer(beneficiary, --receivedAmount);
                return (maxAmountIn - returnAmount, receivedAmount, paraswapFeeShare, partnerFeeShare);
            }
            // if slippage is postive and referral flag is true
            if (feeData & IS_REFERRAL_MASK != 0) {
                if (surplus > 0) {
                    // the split is 50% for paraswap, 25% for the referrer and 25% for the user
                    paraswapFeeShare = (surplus * PARASWAP_REFERRAL_SHARE) / 10_000;
                    partnerFeeShare = (surplus * PARTNER_REFERRAL_SHARE) / 10_000;
                    // distribute fees from srcToken
                    returnAmount = _distributeFees(
                        remainingAmount,
                        srcToken,
                        partner,
                        partnerFeeShare,
                        paraswapFeeShare,
                        skipBlacklist,
                        isBlacklisted,
                        isDirectTransfer
                    );
                    // transfer the rest to msg.sender
                    returnAmount = _transferIfGreaterThanOne(srcToken, msg.sender, returnAmount);
                    // transfer the received amount of destToken to the beneficiary
                    destToken.safeTransfer(beneficiary, --receivedAmount);
                    return (maxAmountIn - returnAmount, receivedAmount, paraswapFeeShare, partnerFeeShare);
                }
            }
            // if slippage is positive and takeSurplus flag is true
            else if (feeData & IS_TAKE_SURPLUS_MASK != 0) {
                if (surplus > 0) {
                    // paraswap takes 50% of the surplus and partner takes the other 50%
                    paraswapFeeShare = (surplus * PARASWAP_SURPLUS_SHARE) / 10_000;
                    partnerFeeShare = surplus - paraswapFeeShare;
                    // If user surplus flag is true, transfer the partner share to the user instead of the partner
                    if (feeData & IS_USER_SURPLUS_MASK != 0) {
                        partnerFeeShare = 0;
                        // Transfer the paraswap share directly to the fee wallet
                        isDirectTransfer = true;
                    }
                    // distrubite fees from srcToken, partner takes 50% of the surplus
                    // and paraswap takes the other 50%
                    returnAmount = _distributeFees(
                        remainingAmount,
                        srcToken,
                        partner,
                        partnerFeeShare,
                        paraswapFeeShare,
                        skipBlacklist,
                        isBlacklisted,
                        isDirectTransfer
                    );
                    // transfer the rest to msg.sender
                    returnAmount = _transferIfGreaterThanOne(srcToken, msg.sender, returnAmount);
                    // transfer the received amount of destToken to the beneficiary
                    destToken.safeTransfer(beneficiary, --receivedAmount);
                    return (maxAmountIn - returnAmount, receivedAmount, paraswapFeeShare, partnerFeeShare);
                }
            }
        }

        // transfer the received amount of destToken to the beneficiary
        destToken.safeTransfer(beneficiary, --receivedAmount);

        // if slippage is positive and partner address is 0x0 or fee percent is 0
        // paraswap will take the surplus, and transfer the rest to msg.sender
        // if there is no positive slippage, transfer the remaining amount to msg.sender
        if (surplus > 0) {
            // If the token is blacklisted, send the remaining amount to the msg.sender
            // we won't process fees
            if (blacklistedTokens[srcToken]) {
                // transfer the remaining amount to msg.sender
                returnAmount = _transferIfGreaterThanOne(srcToken, msg.sender, remainingAmount);
                return (maxAmountIn - returnAmount, receivedAmount, 0, 0);
            }
            // transfer the surplus to the fee wallet
            srcToken.safeTransfer(feeWallet, surplus);
            // transfer the remaining amount to msg.sender
            returnAmount = _transferIfGreaterThanOne(srcToken, msg.sender, remainingAmount - surplus);
            return (maxAmountIn - returnAmount, receivedAmount, surplus, 0);
        } else {
            // transfer the remaining amount to msg.sender
            returnAmount = _transferIfGreaterThanOne(srcToken, msg.sender, remainingAmount);
            return (maxAmountIn - returnAmount, receivedAmount, 0, 0);
        }
    }

    /// @notice Process swapExactAmountOut fees for UniV3 swapExactAmountOut, doing a transferFrom user to the fee
    /// vault or partner and feeWallet
    /// @param beneficiary The user's address
    /// @param srcToken The token used to swapExactAmountOut
    /// @param destToken The token received from the swapExactAmountOut
    /// @param partnerAndFee Packed partner and fee data
    /// @param maxAmountIn The amount of srcToken passed to the swapExactAmountOut
    /// @param receivedAmount The amount of destToken received from the swapExactAmountOut
    /// @param spentAmount The amount of srcToken used to swapExactAmountOut
    /// @param quotedAmount The quoted expected amount of srcToken to be used to swapExactAmountOut
    /// @return totalSpentAmount The total amount of srcToken used to swapExactAmountOut
    /// @return returnAmount The amount of destToken transfered to the beneficiary
    /// @return paraswapFeeShare The share of the fees for Paraswap
    /// @return partnerFeeShare The share of the fees for the partner
    function processSwapExactAmountOutFeesAndTransferUniV3(
        address beneficiary,
        IERC20 srcToken,
        IERC20 destToken,
        uint256 partnerAndFee,
        uint256 maxAmountIn,
        uint256 receivedAmount,
        uint256 spentAmount,
        uint256 quotedAmount
    )
        internal
        returns (uint256 totalSpentAmount, uint256 returnAmount, uint256 paraswapFeeShare, uint256 partnerFeeShare)
    {
        // initialize the surplus
        uint256 surplus;

        // calculate remaining amount
        uint256 remainingAmount = maxAmountIn - spentAmount;

        // parse partner and fee data
        (address payable partner, uint256 feeData) = parsePartnerAndFeeData(partnerAndFee);

        // check if the quotedAmount is bigger than the fromAmount
        if (quotedAmount > maxAmountIn) {
            revert InvalidQuotedAmount();
        }

        // calculate the surplus, we do not take the surplus into account if it is less than
        // MINIMUM_SURPLUS_EPSILON_AND_ONE_WEI
        if (quotedAmount > spentAmount + MINIMUM_SURPLUS_EPSILON_AND_ONE_WEI) {
            surplus = quotedAmount - spentAmount;
            // if the cap surplus flag is passed, we cap the surplus to 1% of the quoted amount
            if (feeData & IS_CAP_SURPLUS_MASK != 0) {
                uint256 cappedSurplus = (SURPLUS_PERCENT * quotedAmount) / 10_000;
                surplus = surplus > cappedSurplus ? cappedSurplus : surplus;
            }
        }

        // if partner address is not 0x0
        if (partner != address(0x0)) {
            // Check if skip blacklist flag is true
            bool skipBlacklist = feeData & IS_SKIP_BLACKLIST_MASK != 0;
            // Check if token is blacklisted
            bool isBlacklisted = blacklistedTokens[srcToken];
            // If the token is blacklisted and the skipBlacklist flag is false,
            // we won't process fees
            if (!skipBlacklist && isBlacklisted) {
                // transfer the received amount of destToken to the beneficiary
                destToken.safeTransfer(beneficiary, receivedAmount);
                return (spentAmount, receivedAmount, 0, 0);
            }
            // Check if direct transfer flag is true
            bool isDirectTransfer = feeData & IS_DIRECT_TRANSFER_MASK != 0;
            // partner takes fixed fees feePercent is greater than 0
            uint256 feePercent = _getAdjustedFeePercent(feeData);
            if (feePercent > 0) {
                // fee base = min (spentAmount, quotedAmount)
                uint256 feeBase = spentAmount < quotedAmount ? spentAmount : quotedAmount;
                // calculate fixed fees
                uint256 fee = (feeBase * feePercent) / 10_000;
                partnerFeeShare = (fee * PARTNER_SHARE_PERCENT) / 10_000;
                paraswapFeeShare = fee - partnerFeeShare;
                // distrubite fees from srcToken
                totalSpentAmount = _distributeFeesUniV3(
                    remainingAmount,
                    msg.sender,
                    srcToken,
                    partner,
                    partnerFeeShare,
                    paraswapFeeShare,
                    skipBlacklist,
                    isBlacklisted,
                    isDirectTransfer
                ) + spentAmount;
                // transfer the received amount of destToken to the beneficiary
                destToken.safeTransfer(beneficiary, receivedAmount);
                return (totalSpentAmount, receivedAmount, paraswapFeeShare, partnerFeeShare);
            }
            // if slippage is postive and referral flag is true
            else if (feeData & IS_REFERRAL_MASK != 0) {
                if (surplus > 0) {
                    // the split is 50% for paraswap, 25% for the referrer and 25% for the user
                    paraswapFeeShare = (surplus * PARASWAP_REFERRAL_SHARE) / 10_000;
                    partnerFeeShare = (surplus * PARTNER_REFERRAL_SHARE) / 10_000;
                    // distribute fees from srcToken
                    totalSpentAmount = _distributeFeesUniV3(
                        remainingAmount,
                        msg.sender,
                        srcToken,
                        partner,
                        partnerFeeShare,
                        paraswapFeeShare,
                        skipBlacklist,
                        isBlacklisted,
                        isDirectTransfer
                    ) + spentAmount;
                    // transfer the received amount of destToken to the beneficiary
                    destToken.safeTransfer(beneficiary, receivedAmount);
                    return (totalSpentAmount, receivedAmount, paraswapFeeShare, partnerFeeShare);
                }
            }
            // if slippage is positive and takeSurplus flag is true
            else if (feeData & IS_TAKE_SURPLUS_MASK != 0) {
                if (surplus > 0) {
                    // paraswap takes 50% of the surplus and partner takes the other 50%
                    paraswapFeeShare = (surplus * PARASWAP_SURPLUS_SHARE) / 10_000;
                    partnerFeeShare = surplus - paraswapFeeShare;
                    // If user surplus flag is true, transfer the partner share to the user instead of the partner
                    if (feeData & IS_USER_SURPLUS_MASK != 0) {
                        partnerFeeShare = 0;
                        // Transfer the paraswap share directly to the fee wallet
                        isDirectTransfer = true;
                    }
                    //  partner takes 50% of the surplus and paraswap takes the other 50%
                    // distrubite fees from srcToken
                    totalSpentAmount = _distributeFeesUniV3(
                        remainingAmount,
                        msg.sender,
                        srcToken,
                        partner,
                        partnerFeeShare,
                        paraswapFeeShare,
                        skipBlacklist,
                        isBlacklisted,
                        isDirectTransfer
                    ) + spentAmount;
                    // transfer the received amount of destToken to the beneficiary
                    destToken.safeTransfer(beneficiary, receivedAmount);
                    return (totalSpentAmount, receivedAmount, paraswapFeeShare, partnerFeeShare);
                }
            }
        }

        // transfer the received amount of destToken to the beneficiary
        destToken.safeTransfer(beneficiary, receivedAmount);

        // if slippage is positive and partner address is 0x0 or fee percent is 0
        // paraswap will take the surplus
        if (surplus > 0) {
            // If the token is blacklisted, we won't process fees
            if (blacklistedTokens[srcToken]) {
                return (spentAmount, receivedAmount, 0, 0);
            }
            // transfer the surplus to the fee wallet
            srcToken.safeTransferFrom(msg.sender, feeWallet, surplus);
        }
        return (spentAmount + surplus, receivedAmount, surplus, 0);
    }

    /*//////////////////////////////////////////////////////////////
                                 PUBLIC
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IAugustusFees
    function parsePartnerAndFeeData(uint256 partnerAndFee)
        public
        pure
        returns (address payable partner, uint256 feeData)
    {
        // solhint-disable-next-line no-inline-assembly
        assembly ("memory-safe") {
            partner := shr(96, partnerAndFee)
            feeData := and(partnerAndFee, 0xFFFFFFFFFFFFFFFFFFFFFFFF)
        }
    }

    /*//////////////////////////////////////////////////////////////
                                PRIVATE
    //////////////////////////////////////////////////////////////*/

    /// @notice Distribute fees to the partner and paraswap
    /// @param currentBalance The current balance of the token before distributing the fees
    /// @param token The token to distribute the fees for
    /// @param partner The partner address
    /// @param partnerShare The partner share
    /// @param paraswapShare The paraswap share
    /// @param skipBlacklist Whether to skip the blacklist and transfer the fees directly to the partner
    /// @param isBlacklisted Whether the token is blacklisted
    /// @param directTransfer Whether to transfer the fees directly to the partner instead of the fee vault
    /// @return newBalance The new balance of the token after distributing the fees
    function _distributeFees(
        uint256 currentBalance,
        IERC20 token,
        address payable partner,
        uint256 partnerShare,
        uint256 paraswapShare,
        bool skipBlacklist,
        bool isBlacklisted,
        bool directTransfer
    )
        private
        returns (uint256 newBalance)
    {
        uint256 totalFees = partnerShare + paraswapShare;
        if (totalFees == 0) {
            return currentBalance;
        } else {
            if (skipBlacklist && isBlacklisted) {
                // totalFees should be just the partner share, paraswap does not take fees
                // on blacklisted tokens, the rest of the fees are sent to sender based on
                // newBalance = currentBalance - totalFees
                totalFees = partnerShare;
                // revert if the balance is not enough to pay the fees
                if (totalFees > currentBalance) {
                    revert InsufficientBalanceToPayFees();
                }
                if (partnerShare > 0) {
                    token.safeTransfer(partner, partnerShare);
                }
            } else {
                // revert if the balance is not enough to pay the fees
                if (totalFees > currentBalance) {
                    revert InsufficientBalanceToPayFees();
                }
                if (directTransfer) {
                    // transfer the fees directly to the partner and paraswap
                    if (paraswapShare > 0) {
                        token.safeTransfer(feeWallet, paraswapShare);
                    }
                    if (partnerShare > 0) {
                        token.safeTransfer(partner, partnerShare);
                    }
                } else {
                    // transfer the fees to the fee vault
                    token.safeTransfer(address(FEE_VAULT), totalFees);
                    // Setup fee registration data
                    address[] memory feeAddresses = new address[](2);
                    uint256[] memory feeAmounts = new uint256[](2);
                    feeAddresses[0] = partner;
                    feeAmounts[0] = partnerShare;
                    feeAddresses[1] = feeWalletDelegate;
                    feeAmounts[1] = paraswapShare;
                    IAugustusFeeVault.FeeRegistration memory feeData =
                        IAugustusFeeVault.FeeRegistration({ token: token, addresses: feeAddresses, fees: feeAmounts });
                    // Register the fees
                    FEE_VAULT.registerFees(feeData);
                }
            }
        }
        newBalance = currentBalance - totalFees;
    }

    /// @notice Distribute fees for UniV3
    /// @param currentBalance The current balance of the token before distributing the fees
    /// @param payer The user's address
    /// @param token The token to distribute the fees for
    /// @param partner The partner address
    /// @param partnerShare The partner share
    /// @param paraswapShare The paraswap share
    /// @param skipBlacklist Whether to skip the blacklist and transfer the fees directly to the partner
    /// @param isBlacklisted Whether the token is blacklisted
    /// @param directTransfer Whether to transfer the fees directly to the partner instead of the fee vault
    /// @return totalFees The total fees distributed
    function _distributeFeesUniV3(
        uint256 currentBalance,
        address payer,
        IERC20 token,
        address payable partner,
        uint256 partnerShare,
        uint256 paraswapShare,
        bool skipBlacklist,
        bool isBlacklisted,
        bool directTransfer
    )
        private
        returns (uint256 totalFees)
    {
        totalFees = partnerShare + paraswapShare;
        if (totalFees != 0) {
            if (skipBlacklist && isBlacklisted) {
                // totalFees should be just the partner share, paraswap does not take fees
                // on blacklisted tokens, the rest of the fees will remain on the payer's address
                totalFees = partnerShare;
                // revert if the balance is not enough to pay the fees
                if (totalFees > currentBalance) {
                    revert InsufficientBalanceToPayFees();
                }
                // transfer the fees to the partner
                if (partnerShare > 0) {
                    // transfer the fees to the partner
                    token.safeTransferFrom(payer, partner, partnerShare);
                }
            } else {
                // revert if the balance is not enough to pay the fees
                if (totalFees > currentBalance) {
                    revert InsufficientBalanceToPayFees();
                }
                if (directTransfer) {
                    // transfer the fees directly to the partner and paraswap
                    if (paraswapShare > 0) {
                        token.safeTransferFrom(payer, feeWallet, paraswapShare);
                    }
                    if (partnerShare > 0) {
                        token.safeTransferFrom(payer, partner, partnerShare);
                    }
                } else {
                    // transfer the fees to the fee vault
                    token.safeTransferFrom(payer, address(FEE_VAULT), totalFees);
                    // Setup fee registration data
                    address[] memory feeAddresses = new address[](2);
                    uint256[] memory feeAmounts = new uint256[](2);
                    feeAddresses[0] = partner;
                    feeAmounts[0] = partnerShare;
                    feeAddresses[1] = feeWalletDelegate;
                    feeAmounts[1] = paraswapShare;
                    IAugustusFeeVault.FeeRegistration memory feeData =
                        IAugustusFeeVault.FeeRegistration({ token: token, addresses: feeAddresses, fees: feeAmounts });
                    // Register the fees
                    FEE_VAULT.registerFees(feeData);
                }
            }
            // othwerwise do not transfer the fees
        }
        return totalFees;
    }

    /// @notice Get the adjusted fee percent by masking feePercent with FEE_PERCENT_IN_BASIS_POINTS_MASK,
    /// if the fee percent is bigger than MAX_FEE_PERCENT, then set it to MAX_FEE_PERCENT
    /// @param feePercent The fee percent
    /// @return adjustedFeePercent The adjusted fee percent
    function _getAdjustedFeePercent(uint256 feePercent) private pure returns (uint256) {
        // solhint-disable-next-line no-inline-assembly
        assembly ("memory-safe") {
            feePercent := and(feePercent, FEE_PERCENT_IN_BASIS_POINTS_MASK)
            // if feePercent is bigger than MAX_FEE_PERCENT, then set it to MAX_FEE_PERCENT
            if gt(feePercent, MAX_FEE_PERCENT) { feePercent := MAX_FEE_PERCENT }
        }
        return feePercent;
    }

    /// @notice Transfers amount to recipient if the amount is bigger than 1, leaving 1 wei dust on the contract
    /// @param token The token to transfer
    /// @param recipient The address to transfer to
    /// @param amount The amount to transfer
    function _transferIfGreaterThanOne(
        IERC20 token,
        address recipient,
        uint256 amount
    )
        private
        returns (uint256 amountOut)
    {
        if (amount > 1) {
            unchecked {
                --amount;
            }
            token.safeTransfer(recipient, amount);
            return amount;
        }
        return 0;
    }

    /// @notice Transfer amount to beneficiary, leaving 1 wei dust on the contract
    /// @param token The token to transfer
    /// @param beneficiary The address to transfer to
    /// @param amount The amount to transfer
    function _transferAndLeaveDust(IERC20 token, address beneficiary, uint256 amount) private {
        unchecked {
            --amount;
        }
        token.safeTransfer(beneficiary, amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

// Contracts
import { GenericUtils } from "../../util/GenericUtils.sol";

// Interfaces
import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";
import { IGenericSwapExactAmountIn } from "../../interfaces/IGenericSwapExactAmountIn.sol";

// Libraries
import { ERC20Utils } from "../../libraries/ERC20Utils.sol";

// Types
import { GenericData } from "../../AugustusV6Types.sol";

/// @title GenericSwapExactAmountIn
/// @notice Router for executing generic swaps with exact amount in through an executor
abstract contract GenericSwapExactAmountIn is IGenericSwapExactAmountIn, GenericUtils {
    /*//////////////////////////////////////////////////////////////
                               LIBRARIES
    //////////////////////////////////////////////////////////////*/

    using ERC20Utils for IERC20;

    /*//////////////////////////////////////////////////////////////
                          SWAP EXACT AMOUNT IN
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IGenericSwapExactAmountIn
    function swapExactAmountIn(
        address executor,
        GenericData calldata swapData,
        uint256 partnerAndFee,
        bytes calldata permit,
        bytes calldata executorData
    )
        external
        payable
        whenNotPaused
        returns (uint256 receivedAmount, uint256 paraswapShare, uint256 partnerShare)
    {
        // Dereference swapData
        IERC20 destToken = swapData.destToken;
        IERC20 srcToken = swapData.srcToken;
        uint256 amountIn = swapData.fromAmount;
        uint256 minAmountOut = swapData.toAmount;
        uint256 quotedAmountOut = swapData.quotedAmount;
        address payable beneficiary = swapData.beneficiary;

        // Check if beneficiary is valid
        if (beneficiary == address(0)) {
            beneficiary = payable(msg.sender);
        }

        // Check if toAmount is valid
        if (minAmountOut == 0) {
            revert InvalidToAmount();
        }

        // Check if srcToken is ETH
        if (srcToken.isETH(amountIn) == 0) {
            // Check the length of the permit field,
            // if < 257 and > 0 we should execute regular permit
            // and if it is >= 257 we execute permit2
            if (permit.length < 257) {
                // Permit if needed
                if (permit.length > 0) {
                    srcToken.permit(permit);
                }
                srcToken.safeTransferFrom(msg.sender, executor, amountIn);
            } else {
                // Otherwise Permit2.permitTransferFrom
                permit2TransferFrom(permit, executor, amountIn);
            }
        }

        // Execute swap
        _callSwapExactAmountInExecutor(executor, executorData, amountIn);

        // Check balance after swap
        receivedAmount = destToken.getBalance(address(this));

        // Check if swap succeeded
        if (receivedAmount < minAmountOut) {
            revert InsufficientReturnAmount();
        }

        // Process fees and transfer destToken to beneficiary
        return processSwapExactAmountInFeesAndTransfer(
            beneficiary, destToken, partnerAndFee, receivedAmount, quotedAmountOut
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

// Interfaces
import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";
import { IGenericSwapExactAmountOut } from "../../interfaces/IGenericSwapExactAmountOut.sol";

// Libraries
import { ERC20Utils } from "../../libraries/ERC20Utils.sol";

// Types
import { GenericData } from "../../AugustusV6Types.sol";

// Utils
import { GenericUtils } from "../../util/GenericUtils.sol";

/// @title GenericSwapExactAmountOut
/// @notice Router for executing generic swaps with exact amount out through an executor
abstract contract GenericSwapExactAmountOut is IGenericSwapExactAmountOut, GenericUtils {
    /*//////////////////////////////////////////////////////////////
                               LIBRARIES
    //////////////////////////////////////////////////////////////*/

    using ERC20Utils for IERC20;

    /*//////////////////////////////////////////////////////////////
                         SWAP EXACT AMOUNT OUT
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IGenericSwapExactAmountOut
    function swapExactAmountOut(
        address executor,
        GenericData calldata swapData,
        uint256 partnerAndFee,
        bytes calldata permit,
        bytes calldata executorData
    )
        external
        payable
        whenNotPaused
        returns (uint256 spentAmount, uint256 receivedAmount, uint256 paraswapShare, uint256 partnerShare)
    {
        // Dereference swapData
        IERC20 destToken = swapData.destToken;
        IERC20 srcToken = swapData.srcToken;
        uint256 maxAmountIn = swapData.fromAmount;
        uint256 amountOut = swapData.toAmount;
        uint256 quotedAmountIn = swapData.quotedAmount;
        address payable beneficiary = swapData.beneficiary;

        // Make sure srcToken and destToken are different
        if (srcToken == destToken) {
            revert ArbitrageNotSupported();
        }

        // Check if beneficiary is valid
        if (beneficiary == address(0)) {
            beneficiary = payable(msg.sender);
        }

        // Check if toAmount is valid
        if (amountOut == 0) {
            revert InvalidToAmount();
        }

        // Check contract balance
        uint256 balanceBefore = srcToken.getBalance(address(this));

        // Check if srcToken is ETH
        // Transfer srcToken to executor if not ETH
        if (srcToken.isETH(maxAmountIn) == 0) {
            // Check the length of the permit field,
            // if < 257 and > 0 we should execute regular permit
            // and if it is >= 257 we execute permit2
            if (permit.length < 257) {
                // Permit if needed
                if (permit.length > 0) {
                    srcToken.permit(permit);
                }
                srcToken.safeTransferFrom(msg.sender, executor, maxAmountIn);
            } else {
                // Otherwise Permit2.permitTransferFrom
                permit2TransferFrom(permit, executor, maxAmountIn);
            }
        } else {
            // If srcToken is ETH, we have to deduct msg.value from balanceBefore
            balanceBefore = balanceBefore - msg.value;
        }

        // Execute swap
        _callSwapExactAmountOutExecutor(executor, executorData, maxAmountIn, amountOut);

        // Check balance of destToken
        receivedAmount = destToken.getBalance(address(this));

        // Check balance of srcToken, deducting the balance before the swap if it is greater than 1
        uint256 remainingAmount = srcToken.getBalance(address(this)) - (balanceBefore > 1 ? balanceBefore : 0);

        // Check if swap succeeded
        if (receivedAmount < amountOut) {
            revert InsufficientReturnAmount();
        }

        // Process fees and transfer destToken and srcToken to beneficiary
        return processSwapExactAmountOutFeesAndTransfer(
            beneficiary,
            srcToken,
            destToken,
            partnerAndFee,
            maxAmountIn,
            remainingAmount,
            receivedAmount,
            quotedAmountIn
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

// Interfaces
import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";
import { IAugustusRFQRouter } from "../../interfaces/IAugustusRFQRouter.sol";

// Libraries
import { ERC20Utils } from "../../libraries/ERC20Utils.sol";

// Types
import { AugustusRFQData, OrderInfo } from "../../AugustusV6Types.sol";

// Utils
import { AugustusRFQUtils } from "../../util/AugustusRFQUtils.sol";
import { WETHUtils } from "../../util/WETHUtils.sol";
import { PauseUtils } from "../../util/PauseUtils.sol";
import { Permit2Utils } from "../../util/Permit2Utils.sol";
import { AugustusFees } from "../../fees/AugustusFees.sol";

/// @title AugustusRFQRouter
/// @notice A contract for executing direct AugustusRFQ swaps
abstract contract AugustusRFQRouter is
    IAugustusRFQRouter,
    AugustusRFQUtils,
    AugustusFees,
    WETHUtils,
    Permit2Utils,
    PauseUtils
{
    /*//////////////////////////////////////////////////////////////
                               LIBRARIES
    //////////////////////////////////////////////////////////////*/

    using ERC20Utils for IERC20;

    /*//////////////////////////////////////////////////////////////
                             TRY BATCH FILL
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IAugustusRFQRouter
    // solhint-disable-next-line code-complexity
    function swapOnAugustusRFQTryBatchFill(
        AugustusRFQData calldata data,
        OrderInfo[] calldata orders,
        bytes calldata permit
    )
        external
        payable
        whenNotPaused
        returns (uint256 spentAmount, uint256 receivedAmount)
    {
        // Dereference data
        address payable beneficiary = data.beneficiary;
        uint256 ordersLength = orders.length;
        uint256 fromAmount = data.fromAmount;
        uint256 toAmount = data.toAmount;
        uint8 wrapApproveDirection = data.wrapApproveDirection;

        // Decode wrapApproveDirection
        // First 2 bits are for wrap
        // Next 1 bit is for approve
        // Last 1 bit is for direction

        uint8 wrap;
        bool approve;
        bool direction;

        // solhint-disable-next-line no-inline-assembly
        assembly ("memory-safe") {
            wrap := and(3, wrapApproveDirection)
            approve := and(shr(2, wrapApproveDirection), 1)
            direction := and(shr(3, wrapApproveDirection), 1)
        }

        // Check if beneficiary is valid
        if (beneficiary == address(0)) {
            beneficiary = payable(msg.sender);
        }

        // Check if toAmount is valid
        if (toAmount == 0) {
            revert InvalidToAmount();
        }

        // Check if ordersLength is valid
        if (ordersLength == 0) {
            revert InvalidOrdersLength();
        }

        // Check if msg.sender is authorized to be the taker for all orders
        for (uint256 i = 0; i < ordersLength; ++i) {
            _checkAuthorization(orders[i].order.nonceAndMeta);
        }

        // Dereference srcToken and destToken
        IERC20 srcToken = IERC20(orders[0].order.takerAsset);
        IERC20 destToken = IERC20(orders[0].order.makerAsset);

        // Check if we need to wrap or permit
        if (wrap != 1) {
            // If msg.value is not 0, revert
            if (msg.value > 0) {
                revert IncorrectEthAmount();
            }

            // Check the length of the permit field,
            // if < 257 and > 0 we should execute regular permit
            // and if it is >= 257 we execute permit2
            if (permit.length < 257) {
                // Permit if needed
                if (permit.length > 0) {
                    srcToken.permit(permit);
                }
                srcToken.safeTransferFrom(msg.sender, address(this), fromAmount);
            } else {
                // Otherwise Permit2.permitTransferFrom
                permit2TransferFrom(permit, address(this), fromAmount);
            }
        } else {
            // Check if msg.value is equal to fromAmount
            if (fromAmount != msg.value) {
                revert IncorrectEthAmount();
            }
            // If it is ETH. wrap it to WETH
            WETH.deposit{ value: fromAmount }();
        }

        if (approve) {
            // Approve srcToken to AugustusRFQ
            srcToken.approve(address(AUGUSTUS_RFQ));
        }

        // Check if we need to execute a swapExactAmountIn or a swapExactAmountOut
        if (!direction) {
            // swapExactAmountIn
            // Unwrap WETH if needed
            if (wrap == 2) {
                // Execute tryBatchFillOrderTakerAmount
                AUGUSTUS_RFQ.tryBatchFillOrderTakerAmount(orders, fromAmount, address(this));
                // Check received amount
                receivedAmount = IERC20(WETH).getBalance(address(this));
                // Check if swap succeeded
                if (receivedAmount < toAmount) {
                    revert InsufficientReturnAmount();
                }
                // Unwrap WETH
                WETH.withdraw(--receivedAmount);
                // Transfer ETH to beneficiary
                ERC20Utils.ETH.safeTransfer(beneficiary, receivedAmount);
            } else {
                // Check balance of beneficiary before swap
                uint256 beforeBalance = destToken.getBalance(beneficiary);
                // Execute tryBatchFillOrderTakerAmount
                AUGUSTUS_RFQ.tryBatchFillOrderTakerAmount(orders, fromAmount, beneficiary);
                // set receivedAmount to afterBalance - beforeBalance
                receivedAmount = destToken.getBalance(beneficiary) - beforeBalance;
                // Check if swap succeeded
                if (receivedAmount < toAmount) {
                    revert InsufficientReturnAmount();
                }
            }

            // Return spentAmount and receivedAmount
            return (fromAmount, receivedAmount);
        } else {
            // swapExactAmountOut
            // Unwrap WETH if needed
            if (wrap == 2) {
                // Execute tryBatchFillOrderMakerAmount
                AUGUSTUS_RFQ.tryBatchFillOrderMakerAmount(orders, toAmount, address(this));
                // Check remaining WETH balance
                receivedAmount = IERC20(WETH).getBalance(address(this));
                // Unwrap WETH
                WETH.withdraw(--receivedAmount);
                // Transfer ETH to beneficiary
                ERC20Utils.ETH.safeTransfer(beneficiary, receivedAmount);
                // Set toAmount to receivedAmount
                toAmount = receivedAmount;
            } else {
                // Execute tryBatchFillOrderMakerAmount
                AUGUSTUS_RFQ.tryBatchFillOrderMakerAmount(orders, toAmount, beneficiary);
            }

            // Check remaining amount
            uint256 remainingAmount = srcToken.getBalance(address(this));

            // Send remaining srcToken to msg.sender
            if (remainingAmount > 1) {
                // If srcToken was ETH
                if (wrap == 1) {
                    // Unwrap WETH
                    WETH.withdraw(--remainingAmount);
                    // Transfer ETH to msg.sender
                    ERC20Utils.ETH.safeTransfer(msg.sender, remainingAmount);
                } else {
                    // Transfer remaining srcToken to msg.sender
                    srcToken.safeTransfer(msg.sender, --remainingAmount);
                }
            }

            // Return spentAmount and receivedAmount
            return (fromAmount - remainingAmount, toAmount);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

// Interfaces
import { IAugustusRFQ } from "../interfaces/IAugustusRFQ.sol";
import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";

// Libraries
import { ERC20Utils } from "../libraries/ERC20Utils.sol";

/// @title AugustusRFQUtils
/// @notice A contract containing common utilities for AugustusRFQ swaps
contract AugustusRFQUtils {
    /*//////////////////////////////////////////////////////////////
                               LIBRARIES
    //////////////////////////////////////////////////////////////*/

    using ERC20Utils for IERC20;

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    /// @dev Emitted when the msg.sender is not authorized to be the taker
    error UnauthorizedUser();

    /// @dev Emitted when the orders length is 0
    error InvalidOrdersLength();

    /*//////////////////////////////////////////////////////////////
                               CONSTANTS
    //////////////////////////////////////////////////////////////*/

    /// @dev AugustusRFQ address
    IAugustusRFQ public immutable AUGUSTUS_RFQ; // solhint-disable-line var-name-mixedcase

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _augustusRFQ) {
        AUGUSTUS_RFQ = IAugustusRFQ(_augustusRFQ);
    }

    /*//////////////////////////////////////////////////////////////
                                 INTERNAL
    //////////////////////////////////////////////////////////////*/

    /// @dev Check if the msg.sender is authorized to be the taker
    function _checkAuthorization(uint256 nonceAndMeta) internal view {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Parse nonceAndMeta
            if xor(and(nonceAndMeta, 0xffffffffffffffffffffffffffffffffffffffff), 0) {
                // If the taker is not 0, we check if the msg.sender is authorized
                if xor(and(nonceAndMeta, 0xffffffffffffffffffffffffffffffffffffffff), caller()) {
                    // The taker does not match the originalSender, revert
                    mstore(0, 0x02a43f8b00000000000000000000000000000000000000000000000000000000) // function
                        // selector for error UnauthorizedUser();
                    revert(0, 4)
                }
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

// Contracts
import { AugustusFees } from "../fees/AugustusFees.sol";

// Interfaces
import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";

// Utils
import { Permit2Utils } from "./Permit2Utils.sol";
import { PauseUtils } from "./PauseUtils.sol";

/// @title BalancerV2Utils
/// @notice A contract containing common utilities for BalancerV2 swaps
abstract contract BalancerV2Utils is AugustusFees, Permit2Utils, PauseUtils {
    /*//////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/

    /// @dev Emitted when the passed selector is invalid
    error InvalidSelector();

    /*//////////////////////////////////////////////////////////////
                               CONSTANTS
    //////////////////////////////////////////////////////////////*/

    /// @dev BalancerV2 vault address
    address payable public immutable BALANCER_VAULT; // solhint-disable-line var-name-mixedcase

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address payable _balancerVault) {
        BALANCER_VAULT = _balancerVault;
    }

    /*//////////////////////////////////////////////////////////////
                                 INTERNAL
    //////////////////////////////////////////////////////////////*/

    /// @dev Decode srcToken, destToken from balancerData, beneficiary and approve flag from beneficiaryAndApproveFlag
    function _decodeBalancerV2Params(
        uint256 beneficiaryAndApproveFlag,
        bytes calldata balancerData
    )
        internal
        pure
        returns (IERC20 srcToken, IERC20 destToken, address payable beneficiary, bool approve)
    {
        // solhint-disable-next-line no-inline-assembly
        assembly ("memory-safe") {
            // Parse beneficiaryAndApproveFlag
            beneficiary := and(beneficiaryAndApproveFlag, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
            approve := shr(255, beneficiaryAndApproveFlag)
            // Load calldata without selector
            let callDataWithoutSelector := add(4, balancerData.offset)
            // Check selector
            switch calldataload(balancerData.offset)
            // If the selector is for swap(tuple singleSwap,tuple funds,uint256 limit,uint256 deadline)
            case 0x52bbbe2900000000000000000000000000000000000000000000000000000000 {
                // Load srcToken from singleSswap.assetIn
                srcToken := calldataload(add(callDataWithoutSelector, 288))
                // Load destToken from singleSswap.assetOut
                destToken := calldataload(add(callDataWithoutSelector, 320))
            }
            // If the selector is for batchSwap(uint8 kind,tuple[] swaps,address[] assets,tuple funds,int256[]
            // limits,uint256 deadline)
            case 0x945bcec900000000000000000000000000000000000000000000000000000000 {
                // Load assetOffset from balancerData
                let assetsOffset := calldataload(add(callDataWithoutSelector, 64))
                // Load assetCount at assetOffset
                let assetsCount := calldataload(add(callDataWithoutSelector, assetsOffset))
                // Get swapExactAmountIn type from first 32 bytes of balancerData
                let swapType := calldataload(callDataWithoutSelector)
                // Set fromAmount, srcToken, toAmount and destToken based on swapType
                switch eq(swapType, 1)
                case 1 {
                    // Load srcToken as the last asset in balancerData.assets
                    srcToken := calldataload(add(callDataWithoutSelector, add(assetsOffset, mul(assetsCount, 32))))
                    // Load destToken as the first asset in balancerData.assets
                    destToken := calldataload(add(callDataWithoutSelector, add(assetsOffset, 32)))
                }
                default {
                    // Load srcToken as the first asset in balancerData.assets
                    srcToken := calldataload(add(callDataWithoutSelector, add(assetsOffset, 32)))
                    // Load destToken as the last asset in balancerData.assets
                    destToken := calldataload(add(callDataWithoutSelector, add(assetsOffset, mul(assetsCount, 32))))
                }
            }
            default {
                // If the selector is invalid, revert
                mstore(0, 0x7352d91c00000000000000000000000000000000000000000000000000000000) // store the
                    // selector for error InvalidSelector();
                revert(0, 4)
            }
            // Balancer users 0x0 as ETH address so we need to convert it
            if eq(srcToken, 0) { srcToken := 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE }
            if eq(destToken, 0) { destToken := 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE }
        }
        return (srcToken, destToken, beneficiary, approve);
    }

    /// @dev Call balancerVault with data
    function _callBalancerV2(bytes calldata balancerData) internal {
        address payable targetAddress = BALANCER_VAULT;
        // solhint-disable-next-line no-inline-assembly
        assembly ("memory-safe") {
            // Load free memory pointer
            let ptr := mload(64)
            // Copy the balancerData to memory
            calldatacopy(ptr, balancerData.offset, balancerData.length)
            // Execute the call on balancerVault
            if iszero(call(gas(), targetAddress, callvalue(), ptr, balancerData.length, 0, 0)) {
                returndatacopy(ptr, 0, returndatasize()) // copy the revert data to memory
                revert(ptr, returndatasize()) // revert with the revert data
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

// Contracts
import { AugustusFees } from "../fees/AugustusFees.sol";

// Interfaces
import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";

// Utils
import { WETHUtils } from "./WETHUtils.sol";
import { Permit2Utils } from "./Permit2Utils.sol";
import { PauseUtils } from "./PauseUtils.sol";

/// @title UniswapV2Utils
/// @notice A contract containing common utilities for UniswapV2 swaps
abstract contract UniswapV2Utils is AugustusFees, WETHUtils, Permit2Utils, PauseUtils {
    /*//////////////////////////////////////////////////////////////
                               CONSTANTS
    //////////////////////////////////////////////////////////////*/

    /// @dev Used to caluclate pool address
    uint256 public immutable UNISWAP_V2_POOL_INIT_CODE_HASH;

    /// @dev Right padded FF + UniswapV2Factory address
    uint256 public immutable UNISWAP_V2_FACTORY_AND_FF;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(uint256 _uniswapV2FactoryAndFF, uint256 _uniswapV2PoolInitCodeHash) {
        UNISWAP_V2_FACTORY_AND_FF = _uniswapV2FactoryAndFF;
        UNISWAP_V2_POOL_INIT_CODE_HASH = _uniswapV2PoolInitCodeHash;
    }

    /*//////////////////////////////////////////////////////////////
                               INTERNAL
    //////////////////////////////////////////////////////////////*/

    /// @dev Loops through UniswapV2 pools in backword direction and swaps exact amount out
    function _callUniswapV2PoolsSwapExactOut(uint256 amountOut, IERC20 srcToken, bytes calldata pools) internal {
        uint256 uniswapV2FactoryAndFF = UNISWAP_V2_FACTORY_AND_FF;
        uint256 uniswapV2PoolInitCodeHash = UNISWAP_V2_POOL_INIT_CODE_HASH;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            function calculatePoolAddress(
                poolMemoryPtr, poolCalldataPtr, _uniswapV2FactoryAndFF, _uniswapV2PoolInitCodeHash
            ) {
                // Calculate the pool address
                // We can do this by first calling the keccak256 function on the passed pool values and then
                // calculating keccak256(abi.encodePacked(hex'ff', address(factory_address),
                // keccak256(abi.encodePacked(token0, token1)), POOL_INIT_CODE_HASH));
                // The first 20 bytes of the computed address are the pool address

                // Store 0xff + factory address (right padded)
                mstore(poolMemoryPtr, _uniswapV2FactoryAndFF)

                // Store pools offset + 21 bytes (UNISWAP_V2_FACTORY_AND_FF SIZE)
                let token0ptr := add(poolMemoryPtr, 21)

                // Copy pool data (skip last bit) to free memory pointer + 21 bytes (UNISWAP_V2_FACTORY_AND_FF SIZE)
                calldatacopy(token0ptr, poolCalldataPtr, 40)

                // Calculate keccak256(abi.encode(address(token0), address(token1))
                mstore(token0ptr, keccak256(token0ptr, 40))

                // Store POOL_INIT_CODE_HASH
                mstore(add(token0ptr, 32), _uniswapV2PoolInitCodeHash)

                // Calculate address(keccak256(abi.encodePacked(hex'ff', address(factory_address),
                // keccak256(abi.encode(token0, token1), POOL_INIT_CODE_HASH)));
                mstore(poolMemoryPtr, and(keccak256(poolMemoryPtr, 85), 0xffffffffffffffffffffffffffffffffffffffff)) // 21
                    // + 32 + 32
            }

            // Calculate pool count
            let poolCount := div(pools.length, 64)

            // Initilize memory pointers
            let amounts := mload(64) // pointer for amounts array
            let poolAddresses := add(amounts, add(mul(poolCount, 32), 32)) // pointer for pools array
            let emptyPtr := add(poolAddresses, mul(poolCount, 32)) // pointer for empty memory

            // Initialize fromAmount
            let fromAmount := 0

            // Set the final amount in the amounts array to amountOut
            mstore(add(amounts, mul(poolCount, 0x20)), amountOut)

            //---------------------------------//
            // Calculate Pool Addresses and Amounts
            //---------------------------------//

            // Calculate pool addresses
            for { let i := 0 } lt(i, poolCount) { i := add(i, 1) } {
                calculatePoolAddress(
                    add(poolAddresses, mul(i, 32)),
                    add(pools.offset, mul(i, 64)),
                    uniswapV2FactoryAndFF,
                    uniswapV2PoolInitCodeHash
                )
            }

            // Rerverse loop through pools and calculate amounts
            for { let i := poolCount } gt(i, 0) { i := sub(i, 1) } {
                // Use previous pool data to calculate amount in
                let indexSub1 := sub(i, 1)

                // Get pool address
                let poolAddress := mload(add(poolAddresses, mul(indexSub1, 32)))

                // Get direction
                let direction := and(1, calldataload(add(add(pools.offset, mul(indexSub1, 64)), 32)))

                // Get amount
                let amount := mload(add(amounts, mul(i, 32)))

                //---------------------------------//
                // Calculate Amount In
                //---------------------------------//

                //---------------------------------//
                // Get Reserves
                //---------------------------------//

                // Store the selector
                mstore(emptyPtr, 0x0902f1ac00000000000000000000000000000000000000000000000000000000) // 'getReserves()'
                // selector

                // Perform the external 'getReserves' call - outputs directly to ptr
                if iszero(staticcall(gas(), poolAddress, emptyPtr, 4, emptyPtr, 64)) {
                    returndatacopy(0, 0, returndatasize()) // Copy the error message to the start of memory
                    revert(0, returndatasize()) // Revert with the error message
                }

                // If direction is true, getReserves returns (reserve0, reserve1)
                // If direction is false, getReserves returns (reserve1, reserve0) -> swap the values

                // Load the reserve0 value returned by the 'getReserves' call.
                let reserve1 := mload(emptyPtr)

                // Load the reserve1 value returned by the 'getReserves' call.
                let reserve0 := mload(add(emptyPtr, 32))

                // Check if direction is true
                if direction {
                    // swap reserve0 and reserve1
                    let temp := reserve0
                    reserve0 := reserve1
                    reserve1 := temp
                }

                //---------------------------------//

                // Calculate numerator = reserve0 * amountOut * 10000
                let numerator := mul(mul(reserve0, amount), 10000)

                // Calculate denominator = (reserve1 - amountOut) * 9970
                let denominator := mul(sub(reserve1, amount), 9970)

                // Calculate amountIn = numerator / denominator + 1
                fromAmount := add(div(numerator, denominator), 1)

                // Store amountIn for the previous pool
                mstore(add(amounts, mul(indexSub1, 32)), fromAmount)
            }

            //---------------------------------//

            // Initialize variables
            let poolAddress := 0
            let nextPoolAddress := 0

            //---------------------------------//
            // Loop Swap Through Pools
            //---------------------------------//

            // Loop for each pool
            for { let i := 0 } lt(i, poolCount) { i := add(i, 1) } {
                // Check if it is the first pool
                if iszero(poolAddress) {
                    // If it is the first pool, we need to transfer amount of srcToken to poolAddress
                    // Load first pool address
                    poolAddress := mload(poolAddresses)

                    //---------------------------------//
                    // Transfer amount of srcToken to poolAddress
                    //---------------------------------//

                    // Transfer fromAmount of srcToken to poolAddress
                    mstore(emptyPtr, 0xa9059cbb00000000000000000000000000000000000000000000000000000000) // store the
                        // selector
                        // (function transfer(address recipient, uint256 amount))
                    mstore(add(emptyPtr, 4), poolAddress) // store the recipient
                    mstore(add(emptyPtr, 36), fromAmount) // store the amount
                    pop(call(gas(), srcToken, 0, emptyPtr, 68, 0, 32)) // call transfer

                    //---------------------------------//
                }

                // Adjust toAddress depending on if it is the last pool in the array
                let toAddress := address()

                // Check if it is not the last pool
                if lt(add(i, 1), poolCount) {
                    // Load next pool address
                    nextPoolAddress := mload(add(poolAddresses, mul(add(i, 1), 32)))

                    // Adjust toAddress to next pool address
                    toAddress := nextPoolAddress
                }

                // Check direction
                let direction := and(1, calldataload(add(add(pools.offset, mul(i, 64)), 32)))

                // if direction is 1, amount0out is 0 and amount1out is amount[i+1]
                // if direction is 0, amount0out is amount[i+1] and amount1out is 0

                // Load amount[i+1]
                let amount := mload(add(amounts, mul(add(i, 1), 32)))

                // Initialize amount0Out and amount1Out
                let amount0Out := amount
                let amount1Out := 0

                // Check if direction is true
                if direction {
                    // swap amount0Out and amount1Out
                    let temp := amount0Out
                    amount0Out := amount1Out
                    amount1Out := temp
                }

                //---------------------------------//
                // Perform Swap
                //---------------------------------//

                // Load the 'swap' selector, amount0Out, amount1Out, toAddress and data("") into memory.
                mstore(emptyPtr, 0x022c0d9f00000000000000000000000000000000000000000000000000000000)
                // 'swap()' selector
                mstore(add(emptyPtr, 4), amount0Out) // amount0Out
                mstore(add(emptyPtr, 36), amount1Out) // amount1Out
                mstore(add(emptyPtr, 68), toAddress) // toAddress
                mstore(add(emptyPtr, 100), 0x80) // data length
                mstore(add(emptyPtr, 132), 0) // data

                // Perform the external 'swap' call
                if iszero(call(gas(), poolAddress, 0, emptyPtr, 164, 0, 64)) {
                    // The call failed; we retrieve the exact error message and revert with it
                    returndatacopy(0, 0, returndatasize()) // Copy the error message to the start of memory
                    revert(0, returndatasize()) // Revert with the error message
                }

                //---------------------------------//

                // Set poolAddress to nextPoolAddress
                poolAddress := nextPoolAddress
            }

            //---------------------------------//
        }
    }

    /// @dev Loops through UniswapV2 pools and swaps exact amount in
    function _callUniswapV2PoolsSwapExactIn(
        uint256 fromAmount,
        IERC20 srcToken,
        bytes calldata pools,
        address payer,
        bytes calldata permit2
    )
        internal
    {
        uint256 uniswapV2FactoryAndFF = UNISWAP_V2_FACTORY_AND_FF;
        uint256 uniswapV2PoolInitCodeHash = UNISWAP_V2_POOL_INIT_CODE_HASH;
        address permit2Address = PERMIT2;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            //---------------------------------//
            // Loop Swap Through Pools
            //---------------------------------//

            // Calculate pool count
            let poolCount := div(pools.length, 64)

            // Initialize variables
            let p := 0
            let poolAddress := 0
            let nextPoolAddress := 0
            let direction := 0

            // Loop for each pool
            for { let i := 0 } lt(i, poolCount) { i := add(i, 1) } {
                // Check if it is the first pool
                if iszero(p) {
                    //---------------------------------//
                    // Calculate Pool Address
                    //---------------------------------//

                    // Calculate the pool address
                    // We can do this by first calling the keccak256 function on the passed pool values and then
                    // calculating keccak256(abi.encodePacked(hex'ff', address(factory_address),
                    // keccak256(abi.encodePacked(token0,token1)), POOL_INIT_CODE_HASH));
                    // The first 20 bytes of the computed address are the pool address

                    // Get free memory pointer
                    let ptr := mload(64)

                    // Store 0xff + factory address (right padded)
                    mstore(ptr, uniswapV2FactoryAndFF)

                    // Store pools offset + 21 bytes (UNISWAP_V2_FACTORY_AND_FF SIZE)
                    let token0ptr := add(ptr, 21)

                    // Copy pool data (skip last bit) to free memory pointer + 21 bytes (UNISWAP_V2_FACTORY_AND_FF
                    // SIZE)
                    calldatacopy(token0ptr, pools.offset, 40)

                    // Calculate keccak256(abi.encodePacked(address(token0), address(token1))
                    mstore(token0ptr, keccak256(token0ptr, 40))

                    // Store POOL_INIT_CODE_HASH
                    mstore(add(token0ptr, 32), uniswapV2PoolInitCodeHash)

                    // Calculate keccak256(abi.encodePacked(hex'ff', address(factory_address),
                    // keccak256(abi.encode(token0,
                    // token1, fee)), POOL_INIT_CODE_HASH));
                    mstore(ptr, keccak256(ptr, 85)) // 21 + 32 + 32

                    // Load pool
                    p := mload(ptr)

                    // Get the first 20 bytes of the computed address
                    poolAddress := and(p, 0xffffffffffffffffffffffffffffffffffffffff)

                    //---------------------------------//

                    //---------------------------------//
                    // Transfer fromAmount of srcToken to poolAddress
                    //---------------------------------//

                    switch eq(payer, address())
                    // if payer is this contract, transfer fromAmount of srcToken to poolAddress
                    case 1 {
                        // Transfer fromAmount of srcToken to poolAddress
                        mstore(ptr, 0xa9059cbb00000000000000000000000000000000000000000000000000000000) // store the
                            // selector
                            // (function transfer(address recipient, uint256 amount))
                        mstore(add(ptr, 4), poolAddress) // store the recipient
                        mstore(add(ptr, 36), fromAmount) // store the amount
                        pop(call(gas(), srcToken, 0, ptr, 68, 0, 32)) // call transfer
                    }
                    // othwerwise transferFrom fromAmount of srcToken to poolAddress from payer
                    default {
                        switch gt(permit2.length, 256)
                        case 0 {
                            // Transfer fromAmount of srcToken to poolAddress
                            mstore(ptr, 0x23b872dd00000000000000000000000000000000000000000000000000000000) // store
                                // the selector
                            // (function transferFrom(address sender, address recipient,
                            // uint256 amount))
                            mstore(add(ptr, 4), payer) // store the sender
                            mstore(add(ptr, 36), poolAddress) // store the recipient
                            mstore(add(ptr, 68), fromAmount) // store the amount
                            pop(call(gas(), srcToken, 0, ptr, 100, 0, 32)) // call transferFrom
                        }
                        default {
                            // Otherwise Permit2.permitTransferFrom
                            // Store function selector
                            mstore(ptr, 0x30f28b7a00000000000000000000000000000000000000000000000000000000)
                            // permitTransferFrom()
                            calldatacopy(add(ptr, 4), permit2.offset, permit2.length) // Copy data to memory
                            mstore(add(ptr, 132), poolAddress) // Store recipient
                            mstore(add(ptr, 164), fromAmount) // Store amount
                            mstore(add(ptr, 196), payer) // Store payer
                            // Call permit2.permitTransferFrom and revert if call failed
                            if iszero(call(gas(), permit2Address, 0, ptr, add(permit2.length, 4), 0, 0)) {
                                mstore(0, 0x6b836e6b00000000000000000000000000000000000000000000000000000000) // Store
                                    // error selector
                                    // error Permit2Failed()
                                revert(0, 4)
                            }
                        }
                    }

                    //---------------------------------//
                }

                // Direction is the first bit of the pool data
                direction := and(1, calldataload(add(add(pools.offset, mul(i, 64)), 32)))

                //---------------------------------//
                // Calculate Amount Out
                //---------------------------------//

                //---------------------------------//
                // Get Reserves
                //---------------------------------//

                // Get free memory pointer
                let ptr := mload(64)

                // Store the selector
                mstore(ptr, 0x0902f1ac00000000000000000000000000000000000000000000000000000000) // 'getReserves()'
                // selector

                // Perform the external 'getReserves' call - outputs directly to ptr
                if iszero(staticcall(gas(), poolAddress, ptr, 4, ptr, 64)) {
                    returndatacopy(0, 0, returndatasize()) // Copy the error message to the start of memory
                    revert(0, returndatasize()) // Revert with the error message
                }

                // If direction is true, getReserves returns (reserve0, reserve1)
                // If direction is false, getReserves returns (reserve1, reserve0) -> swap the values

                // Load the reserve0 value returned by the 'getReserves' call.
                let reserve1 := mload(ptr)

                // Load the reserve1 value returned by the 'getReserves' call.
                let reserve0 := mload(add(ptr, 32))

                // Check if direction is true
                if direction {
                    // swap reserve0 and reserve1
                    let temp := reserve0
                    reserve0 := reserve1
                    reserve1 := temp
                }

                //---------------------------------//

                // Calculate amount based on fee
                let amountWithFee := mul(fromAmount, 9970)

                // Calculate numerator = amountWithFee * reserve1
                let numerator := mul(amountWithFee, reserve1)

                // Calculate denominator = reserve0 * 10000 + amountWithFee
                let denominator := add(mul(reserve0, 10000), amountWithFee)

                // Calculate amountOut = numerator / denominator
                let amountOut := div(numerator, denominator)

                fromAmount := amountOut

                // if direction is true, amount0Out is 0 and amount1Out is fromAmount,
                // otherwise amount0Out is fromAmount and amount1Out is 0

                let amount0Out := fromAmount
                let amount1Out := 0

                // swap amount0Out and amount1Out if direction is false
                if direction {
                    amount0Out := 0
                    amount1Out := fromAmount
                }

                //---------------------------------//

                // Adjust toAddress depending on if it is the last pool in the array
                let toAddress := address()

                // Check if it is not the last pool
                if lt(add(i, 1), poolCount) {
                    //---------------------------------//
                    // Calculate Next Pool Address
                    //---------------------------------//

                    // Store 0xff + factory address (right padded)
                    mstore(ptr, uniswapV2FactoryAndFF)

                    // Store pools offset + 21 bytes (UNISWAP_V2_FACTORY_AND_FF SIZE)
                    let token0ptr := add(ptr, 21)

                    // Copy next pool data to free memory pointer + 21 bytes (UNISWAP_V2_FACTORY_AND_FF SIZE)
                    calldatacopy(token0ptr, add(pools.offset, mul(add(i, 1), 64)), 40)

                    // Calculate keccak256(abi.encodePacked(address(token0), address(token1))
                    mstore(token0ptr, keccak256(token0ptr, 40))

                    // Store POOL_INIT_CODE_HASH
                    mstore(add(token0ptr, 32), uniswapV2PoolInitCodeHash)

                    // Calculate keccak256(abi.encodePacked(hex'ff', address(factory_address),
                    // keccak256(abi.encode(token0,
                    // token1), POOL_INIT_CODE_HASH));
                    mstore(ptr, keccak256(ptr, 85)) // 21 + 32 + 32

                    // Load pool
                    p := mload(ptr)

                    // Get the first 20 bytes of the computed address
                    nextPoolAddress := and(p, 0xffffffffffffffffffffffffffffffffffffffff)

                    // Adjust toAddress to next pool address
                    toAddress := nextPoolAddress

                    //---------------------------------//
                }

                //---------------------------------//
                // Perform Swap
                //---------------------------------//

                // Load the 'swap' selector, amount0Out, amount1Out, toAddress and data("") into memory.
                mstore(ptr, 0x022c0d9f00000000000000000000000000000000000000000000000000000000)
                // 'swap()' selector
                mstore(add(ptr, 4), amount0Out) // amount0Out
                mstore(add(ptr, 36), amount1Out) // amount1Out
                mstore(add(ptr, 68), toAddress) // toAddress
                mstore(add(ptr, 100), 0x80) // data length
                mstore(add(ptr, 132), 0) // data

                // Perform the external 'swap' call
                if iszero(call(gas(), poolAddress, 0, ptr, 164, 0, 64)) {
                    // The call failed; we retrieve the exact error message and revert with it
                    returndatacopy(0, 0, returndatasize()) // Copy the error message to the start of memory
                    revert(0, returndatasize()) // Revert with the error message
                }

                //---------------------------------//

                // Set poolAddress to nextPoolAddress
                poolAddress := nextPoolAddress
            }

            //---------------------------------//
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

// Contracts
import { AugustusFees } from "../fees/AugustusFees.sol";

// Interfaces
import { IUniswapV3SwapCallback } from "../interfaces/IUniswapV3SwapCallback.sol";

// Libraries
import { SafeCastLib } from "@solady/utils/SafeCastLib.sol";

// Utils
import { WETHUtils } from "./WETHUtils.sol";
import { Permit2Utils } from "./Permit2Utils.sol";
import { PauseUtils } from "./PauseUtils.sol";

/// @title UniswapV3Utils
/// @notice A contract containing common utilities for UniswapV3 swaps
abstract contract UniswapV3Utils is IUniswapV3SwapCallback, AugustusFees, WETHUtils, Permit2Utils, PauseUtils {
    /*//////////////////////////////////////////////////////////////
                               LIBRARIES
    //////////////////////////////////////////////////////////////*/

    using SafeCastLib for int256;

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    /// @notice Error emitted if the caller is not a Uniswap V3 pool
    error InvalidCaller();
    /// @notice Error emitted if the transfer of tokens to the pool inside the callback failed
    error CallbackTransferFailed();

    /*//////////////////////////////////////////////////////////////
                               CONSTANTS
    //////////////////////////////////////////////////////////////*/

    /// @dev Used to caluclate pool address
    uint256 public immutable UNISWAP_V3_POOL_INIT_CODE_HASH;

    /// @dev Right padded FF + UniswapV3Factory address
    uint256 public immutable UNISWAP_V3_FACTORY_AND_FF;

    /*//////////////////////////////////////////////////////////////
                               CONSTANTS
    //////////////////////////////////////////////////////////////*/

    uint256 private constant UNISWAP_V3_MIN_SQRT = 4_295_128_740;
    uint256 private constant UNISWAP_V3_MAX_SQRT = 1_461_446_703_485_210_103_287_273_052_203_988_822_378_723_970_341;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(uint256 _uniswapV3FactoryAndFF, uint256 _uniswapV3PoolInitCodeHash) {
        UNISWAP_V3_FACTORY_AND_FF = _uniswapV3FactoryAndFF;
        UNISWAP_V3_POOL_INIT_CODE_HASH = _uniswapV3PoolInitCodeHash;
    }

    /*//////////////////////////////////////////////////////////////
                                EXTERNAL
    //////////////////////////////////////////////////////////////*/

    // @inheritdoc IUniswapV3SwapCallback
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    )
        external
        whenNotPaused
    {
        // Initialize variables
        uint256 uniswapV3FactoryAndFF = UNISWAP_V3_FACTORY_AND_FF;
        uint256 uniswapV3PoolInitCodeHash = UNISWAP_V3_POOL_INIT_CODE_HASH;
        address permit2Address = PERMIT2;
        address poolAddress;

        // 160 (single pool data) + 352 (permit2 length)
        bool isPermit2 = data.length == 512;

        // Check if the caller is a UniswapV3Pool deployed by the canonical UniswapV3Factory
        //solhint-disable-next-line no-inline-assembly
        assembly {
            // Pool address
            poolAddress := caller()

            // Get free memory pointer
            let ptr := mload(64)

            // We need make sure the caller is a UniswapV3Pool deployed by the canonical UniswapV3Factory
            // 1. Prepare data for calculating the pool address
            // Store ff+factory address, Load token0, token1, fee from bytes calldata and store pool init code hash

            // Store 0xff + factory address (right padded)
            mstore(ptr, uniswapV3FactoryAndFF)

            // Store data offset + 21 bytes (UNISWAP_V3_FACTORY_AND_FF SIZE)
            let token0Offset := add(ptr, 21)

            // Copy token0, token1, fee to free memory pointer + 21 bytes (UNISWAP_V3_FACTORY_AND_FF SIZE) + 1 byte
            // (direction)
            calldatacopy(add(token0Offset, 1), add(data.offset, 65), 95)

            // 2. Calculate the pool address
            // We can do this by first calling the keccak256 function on the fetched values and then
            // calculating keccak256(abi.encodePacked(hex'ff', address(factory_address),
            // keccak256(abi.encode(token0,
            // token1, fee)), POOL_INIT_CODE_HASH));
            // The first 20 bytes of the computed address are the pool address

            // Calculate keccak256(abi.encode(address(token0), address(token1), fee))
            mstore(token0Offset, keccak256(token0Offset, 96))
            // Store POOL_INIT_CODE_HASH
            mstore(add(token0Offset, 32), uniswapV3PoolInitCodeHash)
            // Calculate keccak256(abi.encodePacked(hex'ff', address(factory_address), keccak256(abi.encode(token0,
            // token1, fee)), POOL_INIT_CODE_HASH));
            mstore(ptr, keccak256(ptr, 85)) // 21 + 32 + 32

            // Get the first 20 bytes of the computed address
            let computedAddress := and(mload(ptr), 0xffffffffffffffffffffffffffffffffffffffff)

            // Check if the caller matches the computed address (and revert if not)
            if xor(poolAddress, computedAddress) {
                mstore(0, 0x48f5c3ed00000000000000000000000000000000000000000000000000000000) // store the selector
                    // (error InvalidCaller())
                revert(0, 4) // revert with error selector
            }
        }

        // Check if data length is greater than 160 bytes (1 pool)
        // If the data length is greater than 160 bytes, we know that we are executing a multi-hop swapExactAmountOut
        // by recursively calling swapExactAmountOut on the next pool, until we reach the last pool in the data and
        // then we will transfer the tokens to the pool
        if (data.length > 160 && !isPermit2) {
            // Initialize recursive variables
            address payer;
            // solhint-disable-next-line no-inline-assembly
            assembly {
                // Copy payer address from calldata
                payer := calldataload(164)
            }
            // Recursive call swapExactAmountOut
            _callUniswapV3PoolsSwapExactAmountOut(amount0Delta > 0 ? -amount0Delta : -amount1Delta, data, payer);
        } else {
            // solhint-disable-next-line no-inline-assembly
            assembly {
                // Token to send to the pool
                let token
                // Amount to send to the pool
                let amount

                // Get free memory pointer
                let ptr := mload(64)

                // If the caller is the computed address, then we can safely assume that the caller is a UniswapV3Pool
                // deployed by the canonical UniswapV3Factory

                // 3. Transfer amount to the pool

                // Check if amount0Delta or amount1Delta is positive and which token we need to send to the pool
                if sgt(amount0Delta, 0) {
                    // If amount0Delta is positive, we need to send amount0Delta token0 to the pool
                    token := and(calldataload(add(data.offset, 64)), 0xffffffffffffffffffffffffffffffffffffffff)
                    amount := amount0Delta
                }
                if sgt(amount1Delta, 0) {
                    // If amount1Delta is positive, we need to send amount1Delta token1 to the pool
                    token := calldataload(add(data.offset, 96))
                    amount := amount1Delta
                }

                // Based on the data passed to the callback, we know the fromAddress that will pay for the
                // swap, if it is this contract, we will execute the transfer() function,
                // otherwise, we will execute transferFrom()

                // Check if fromAddress is this contract
                let fromAddress := calldataload(164)

                switch eq(fromAddress, address())
                // If fromAddress is this contract, execute transfer()
                case 1 {
                    // Prepare external call data
                    mstore(ptr, 0xa9059cbb00000000000000000000000000000000000000000000000000000000) // store the
                        // selector
                        // (function transfer(address recipient, uint256 amount))
                    mstore(add(ptr, 4), poolAddress) // store the recipient
                    mstore(add(ptr, 36), amount) // store the amount
                    let success := call(gas(), token, 0, ptr, 68, 0, 32) // call transfer
                    if success {
                        switch returndatasize()
                        // check the return data size
                        case 0 { success := gt(extcodesize(token), 0) }
                        default { success := and(gt(returndatasize(), 31), eq(mload(0), 1)) }
                    }

                    if iszero(success) {
                        mstore(0, 0x1bbb4abe00000000000000000000000000000000000000000000000000000000) // store the
                            // selector
                            // (error CallbackTransferFailed())
                        revert(0, 4) // revert with error selector
                    }
                }
                // If fromAddress is not this contract, execute transferFrom() or permitTransferFrom()
                default {
                    switch isPermit2
                    // If permit2 is not present, execute transferFrom()
                    case 0 {
                        mstore(ptr, 0x23b872dd00000000000000000000000000000000000000000000000000000000) // store the
                            // selector
                            // (function transferFrom(address sender, address recipient,
                            // uint256 amount))
                        mstore(add(ptr, 4), fromAddress) // store the sender
                        mstore(add(ptr, 36), poolAddress) // store the recipient
                        mstore(add(ptr, 68), amount) // store the amount
                        let success := call(gas(), token, 0, ptr, 100, 0, 32) // call transferFrom
                        if success {
                            switch returndatasize()
                            // check the return data size
                            case 0 { success := gt(extcodesize(token), 0) }
                            default { success := and(gt(returndatasize(), 31), eq(mload(0), 1)) }
                        }
                        if iszero(success) {
                            mstore(0, 0x1bbb4abe00000000000000000000000000000000000000000000000000000000) // store the
                                // selector
                                // (error CallbackTransferFailed())
                            revert(0, 4) // revert with error selector
                        }
                    }
                    // If permit2 is present, execute permitTransferFrom()
                    default {
                        // Otherwise Permit2.permitTransferFrom
                        // Store function selector
                        mstore(ptr, 0x30f28b7a00000000000000000000000000000000000000000000000000000000)
                        // permitTransferFrom()
                        calldatacopy(add(ptr, 4), 292, 352) // Copy data to memory
                        mstore(add(ptr, 132), poolAddress) // Store pool address as recipient
                        mstore(add(ptr, 164), amount) // Store amount as amount
                        mstore(add(ptr, 196), fromAddress) // Store payer
                        // Call permit2.permitTransferFrom and revert if call failed
                        if iszero(call(gas(), permit2Address, 0, ptr, 356, 0, 0)) {
                            mstore(0, 0x6b836e6b00000000000000000000000000000000000000000000000000000000) // Store
                                // error selector
                                // error Permit2Failed()
                            revert(0, 4)
                        }
                    }
                }
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                               INTERNAL
    //////////////////////////////////////////////////////////////*/

    /// @dev Loops through pools and performs swaps
    function _callUniswapV3PoolsSwapExactAmountIn(
        int256 fromAmount,
        bytes calldata pools,
        address fromAddress,
        bytes calldata permit2
    )
        internal
        returns (uint256 receivedAmount)
    {
        uint256 uniswapV3FactoryAndFF = UNISWAP_V3_FACTORY_AND_FF;
        uint256 uniswapV3PoolInitCodeHash = UNISWAP_V3_POOL_INIT_CODE_HASH;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            //---------------------------------//
            // Loop Swap Through Pools
            //---------------------------------//

            // Calculate pool count
            let poolCount := div(pools.length, 96)

            // Initialize variables
            let p := 0
            let poolAddress := 0
            let nextPoolAddress := 0
            let direction := 0
            let isPermit2 := gt(permit2.length, 256)

            // Get free memory pointer
            let ptr := mload(64)

            // Loop through pools
            for { let i := 0 } lt(i, poolCount) { i := add(i, 1) } {
                // Check if it is the first pool
                if iszero(p) {
                    //---------------------------------//
                    // Calculate Pool Address
                    //---------------------------------//

                    // Calculate the pool address
                    // We can do this by first calling the keccak256 function on the passed pool values and then
                    // calculating keccak256(abi.encodePacked(hex'ff', address(factory_address),
                    // keccak256(abi.encode(token0,
                    // token1, fee)), POOL_INIT_CODE_HASH));
                    // The first 20 bytes of the computed address are the pool address

                    // Store 0xff + factory address (right padded)
                    mstore(ptr, uniswapV3FactoryAndFF)

                    // Store pools offset + 21 bytes (UNISWAP_V3_FACTORY_AND_FF SIZE)
                    let token0ptr := add(ptr, 21)

                    // Copy pool data (skip first byte) to free memory pointer + 21 bytes (UNISWAP_V3_FACTORY_AND_FF
                    // SIZE)
                    calldatacopy(add(token0ptr, 1), add(pools.offset, 1), 95)

                    // Calculate keccak256(abi.encode(address(token0), address(token1), fee))
                    mstore(token0ptr, keccak256(token0ptr, 96))

                    // Store POOL_INIT_CODE_HASH
                    mstore(add(token0ptr, 32), uniswapV3PoolInitCodeHash)

                    // Calculate keccak256(abi.encodePacked(hex'ff', address(factory_address),
                    // keccak256(abi.encode(token0,
                    // token1, fee)), POOL_INIT_CODE_HASH));
                    mstore(ptr, keccak256(ptr, 85)) // 21 + 32 + 32

                    // Load pool
                    p := mload(ptr)

                    // Get the first 20 bytes of the computed address
                    poolAddress := and(p, 0xffffffffffffffffffffffffffffffffffffffff)

                    //---------------------------------//
                }

                // Direction is the first bit of the pool data
                direction := shr(255, calldataload(add(pools.offset, mul(i, 96))))

                // Check if it is not the last pool
                if lt(add(i, 1), poolCount) {
                    //---------------------------------//
                    // Calculate Next Pool Address
                    //---------------------------------//

                    // Store 0xff + factory address (right padded)
                    mstore(ptr, uniswapV3FactoryAndFF)

                    // Store pools offset + 21 bytes (UNISWAP_V3_FACTORY_AND_FF SIZE)
                    let token0ptr := add(ptr, 21)

                    // Copy next pool data to free memory pointer + 21 bytes (UNISWAP_V3_FACTORY_AND_FF SIZE)
                    calldatacopy(add(token0ptr, 1), add(add(pools.offset, 1), mul(add(i, 1), 96)), 95)

                    // Calculate keccak256(abi.encode(address(token0), address(token1), fee))
                    mstore(token0ptr, keccak256(token0ptr, 96))

                    // Store POOL_INIT_CODE_HASH
                    mstore(add(token0ptr, 32), uniswapV3PoolInitCodeHash)

                    // Calculate keccak256(abi.encodePacked(hex'ff', address(factory_address),
                    // keccak256(abi.encode(token0,
                    // token1, fee)), POOL_INIT_CODE_HASH));
                    mstore(ptr, keccak256(ptr, 85)) // 21 + 32 + 32

                    // Load pool
                    p := mload(ptr)

                    // Get the first 20 bytes of the computed address
                    nextPoolAddress := and(p, 0xffffffffffffffffffffffffffffffffffffffff)

                    //---------------------------------//
                }

                // Adjust fromAddress and fromAmount if it's not the first pool
                if gt(i, 0) { fromAddress := address() }

                //---------------------------------//
                // Perform Swap
                //---------------------------------//

                //---------------------------------//
                // Return based on direction
                //---------------------------------//

                // Initialize data length
                let dataLength := 0xa0

                // Initialize total data length
                let totalDataLength := 356

                // If permit2 is present include permit2 data length in total data length
                if eq(isPermit2, 1) {
                    totalDataLength := add(totalDataLength, permit2.length)
                    dataLength := add(dataLength, permit2.length)
                }

                // Return amount0 or amount1 depending on direction
                switch direction
                case 0 {
                    // Prepare external call data
                    // Store swap selector (0x128acb08)
                    mstore(ptr, 0x128acb0800000000000000000000000000000000000000000000000000000000)
                    // Store toAddress
                    mstore(add(ptr, 4), address())
                    // Store direction
                    mstore(add(ptr, 36), 0)
                    // Store fromAmount
                    mstore(add(ptr, 68), fromAmount)
                    // Store sqrtPriceLimitX96
                    mstore(add(ptr, 100), UNISWAP_V3_MAX_SQRT)
                    // Store data offset
                    mstore(add(ptr, 132), 0xa0)
                    /// Store data length
                    mstore(add(ptr, 164), dataLength)
                    // Store fromAddress
                    mstore(add(ptr, 228), fromAddress)
                    // Store token0, token1, fee
                    calldatacopy(add(ptr, 260), add(pools.offset, mul(i, 96)), 96)
                    // If permit2 is present, store permit2 data
                    if eq(isPermit2, 1) {
                        // Store permit2 data
                        calldatacopy(add(ptr, 356), permit2.offset, permit2.length)
                    }
                    // Perform the external 'swap' call
                    if iszero(call(gas(), poolAddress, 0, ptr, totalDataLength, ptr, 32)) {
                        // store return value directly to free memory pointer
                        // The call failed; we retrieve the exact error message and revert with it
                        returndatacopy(0, 0, returndatasize()) // Copy the error message to the start of memory
                        revert(0, returndatasize()) // Revert with the error message
                    }
                    // If direction is 0, return amount0
                    fromAmount := mload(ptr)
                }
                default {
                    // Prepare external call data
                    // Store swap selector (0x128acb08)
                    mstore(ptr, 0x128acb0800000000000000000000000000000000000000000000000000000000)
                    // Store toAddress
                    mstore(add(ptr, 4), address())
                    // Store direction
                    mstore(add(ptr, 36), 1)
                    // Store fromAmount
                    mstore(add(ptr, 68), fromAmount)
                    // Store sqrtPriceLimitX96
                    mstore(add(ptr, 100), UNISWAP_V3_MIN_SQRT)
                    // Store data offset
                    mstore(add(ptr, 132), 0xa0)
                    /// Store data length
                    mstore(add(ptr, 164), dataLength)
                    // Store fromAddress
                    mstore(add(ptr, 228), fromAddress)
                    // Store token0, token1, fee
                    calldatacopy(add(ptr, 260), add(pools.offset, mul(i, 96)), 96)
                    // If permit2 is present, store permit2 data
                    if eq(isPermit2, 1) {
                        // Store permit2 data
                        calldatacopy(add(ptr, 356), permit2.offset, permit2.length)
                    }
                    // Perform the external 'swap' call
                    if iszero(call(gas(), poolAddress, 0, ptr, totalDataLength, ptr, 64)) {
                        // store return value directly to free memory pointer
                        // The call failed; we retrieve the exact error message and revert with it
                        returndatacopy(0, 0, returndatasize()) // Copy the error message to the start of memory
                        revert(0, returndatasize()) // Revert with the error message
                    }

                    // If direction is 1, return amount1
                    fromAmount := mload(add(ptr, 32))
                }
                //---------------------------------//

                //---------------------------------//

                // The next pool address was already calculated so we can set it as the current pool address for the
                // next iteration of the loop
                poolAddress := nextPoolAddress

                // fromAmount = -fromAmount
                fromAmount := sub(0, fromAmount)
            }

            //---------------------------------//
        }
        return fromAmount.toUint256();
    }

    /// @dev Recursively loops through pools and performs swaps
    function _callUniswapV3PoolsSwapExactAmountOut(
        int256 fromAmount,
        bytes calldata pools,
        address fromAddress
    )
        internal
        returns (uint256 spentAmount, uint256 receivedAmount)
    {
        uint256 uniswapV3FactoryAndFF = UNISWAP_V3_FACTORY_AND_FF;
        uint256 uniswapV3PoolInitCodeHash = UNISWAP_V3_POOL_INIT_CODE_HASH;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            //---------------------------------//
            // Adjust data received from recursive call
            //---------------------------------//

            // Initialize variables
            let poolsStartOffset := pools.offset
            let poolsLength := pools.length
            let previousPoolAddress := 0

            // Check if pools length is not divisible by 96
            if gt(mod(pools.length, 96), 0) {
                // Check if pools length is greater than 128 bytes (1 pool)
                if gt(pools.length, 160) {
                    // Get the previous pool address from the first 20 bytes of pool data
                    previousPoolAddress := and(calldataload(pools.offset), 0xffffffffffffffffffffffffffffffffffffffff)
                    // Relculate the offset to skip data
                    poolsStartOffset := add(pools.offset, 160)
                    // Recalculate the length to skip data
                    poolsLength := sub(pools.length, 160)
                }
            }

            // Get free memory pointer
            let ptr := mload(64)

            //---------------------------------//
            // Calculate Pool Address
            //---------------------------------//

            // Calculate the pool address
            // We can do this by first calling the keccak256 function on the passed pool values and then
            // calculating keccak256(abi.encodePacked(hex'ff', address(factory_address),
            // keccak256(abi.encode(token0,
            // token1, fee)), POOL_INIT_CODE_HASH));
            // The first 20 bytes of the computed address are the pool address

            // Store 0xff + factory address (right padded)
            mstore(ptr, uniswapV3FactoryAndFF)

            // Store pools offset + 21 bytes (UNISWAP_V3_FACTORY_AND_FF SIZE)
            let token0ptr := add(ptr, 21)

            // Copy pool data (skip first byte) to free memory pointer + 21 bytes (UNISWAP_V3_FACTORY_AND_FF
            // SIZE)
            calldatacopy(add(token0ptr, 1), add(poolsStartOffset, 1), 95)

            // Calculate keccak256(abi.encode(address(token0), address(token1), fee))
            mstore(token0ptr, keccak256(token0ptr, 96))

            // Store POOL_INIT_CODE_HASH
            mstore(add(token0ptr, 32), uniswapV3PoolInitCodeHash)

            // Calculate keccak256(abi.encodePacked(hex'ff', address(factory_address),
            // keccak256(abi.encode(token0,
            // token1, fee)), POOL_INIT_CODE_HASH));
            mstore(ptr, keccak256(ptr, 85)) // 21 + 32 + 32

            // Load pool
            let p := mload(ptr)

            // Get the first 20 bytes of the computed address
            let poolAddress := and(p, 0xffffffffffffffffffffffffffffffffffffffff)

            //---------------------------------//

            //---------------------------------//
            // Adjust toAddress
            //---------------------------------//

            let toAddress := address()

            // If it's not the first entry to recursion, we use the pool address from the previous pool as
            // the toAddress
            if xor(previousPoolAddress, 0) { toAddress := previousPoolAddress }

            //---------------------------------//

            // Direction is the first bit of the pool data
            let direction := shr(255, calldataload(poolsStartOffset))

            //---------------------------------//
            // Perform Swap
            //---------------------------------//

            //---------------------------------//
            // Return based on direction
            //---------------------------------//

            // Return amount0 or amount1 depending on direction
            switch direction
            case 0 {
                // Prepare external call data
                // Store swap selector (0x128acb08)
                mstore(ptr, 0x128acb0800000000000000000000000000000000000000000000000000000000)
                // Store toAddress
                mstore(add(ptr, 4), toAddress)
                // Store direction
                mstore(add(ptr, 36), 0)
                // Store fromAmount
                mstore(add(ptr, 68), fromAmount)
                // Store sqrtPriceLimitX96
                mstore(add(ptr, 100), UNISWAP_V3_MAX_SQRT)
                // Store data offset
                mstore(add(ptr, 132), 0xa0)
                /// Store data length
                mstore(add(ptr, 164), add(64, poolsLength))
                // Store poolAddress
                mstore(add(ptr, 196), poolAddress)
                // Store fromAddress
                mstore(add(ptr, 228), fromAddress)
                // Store token0, token1, fee
                calldatacopy(add(ptr, 260), poolsStartOffset, poolsLength)

                // Perform the external 'swap' call
                if iszero(call(gas(), poolAddress, 0, ptr, add(poolsLength, 260), ptr, 64)) {
                    // store return value directly to free memory pointer
                    // The call failed; we retrieve the exact error message and revert with it
                    returndatacopy(0, 0, returndatasize()) // Copy the error message to the start of memory
                    revert(0, returndatasize()) // Revert with the error message
                }
                // If direction is 0, return amount0 as fromAmount
                fromAmount := mload(ptr)
                // return amount1 as spentAmount
                spentAmount := mload(add(ptr, 32))
            }
            default {
                // Prepare external call data
                // Store swap selector (0x128acb08)
                mstore(ptr, 0x128acb0800000000000000000000000000000000000000000000000000000000)
                // Store toAddress
                mstore(add(ptr, 4), toAddress)
                // Store direction
                mstore(add(ptr, 36), 1)
                // Store fromAmount
                mstore(add(ptr, 68), fromAmount)
                // Store sqrtPriceLimitX96
                mstore(add(ptr, 100), UNISWAP_V3_MIN_SQRT)
                // Store data offset
                mstore(add(ptr, 132), 0xa0)
                /// Store data length
                mstore(add(ptr, 164), add(64, poolsLength))
                // Store poolAddress
                mstore(add(ptr, 196), poolAddress)
                // Store fromAddress
                mstore(add(ptr, 228), fromAddress)
                // Store token0, token1, fee
                calldatacopy(add(ptr, 260), poolsStartOffset, poolsLength)

                // Perform the external 'swap' call
                if iszero(call(gas(), poolAddress, 0, ptr, add(poolsLength, 260), ptr, 64)) {
                    // store return value directly to free memory pointer
                    // The call failed; we retrieve the exact error message and revert with it
                    returndatacopy(0, 0, returndatasize()) // Copy the error message to the start of memory
                    revert(0, returndatasize()) // Revert with the error message
                }

                // If direction is 1, return amount1 as fromAmount
                fromAmount := mload(add(ptr, 32))
                // return amount0 as spentAmount
                spentAmount := mload(ptr)
            }
            //---------------------------------//

            //---------------------------------//

            // fromAmount = -fromAmount
            fromAmount := sub(0, fromAmount)
        }
        return (spentAmount, fromAmount.toUint256());
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

// Interfaces
import { IWETH } from "../interfaces/IWETH.sol";

/// @title WETHUtils
/// @notice A contract containing common utilities for WETH
abstract contract WETHUtils {
    /*//////////////////////////////////////////////////////////////
                                CONSTANTS
    //////////////////////////////////////////////////////////////*/

    /// @dev WETH address
    IWETH public immutable WETH;

    /*//////////////////////////////////////////////////////////////
                                CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _weth) {
        WETH = IWETH(_weth);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

/// @title Permit2Utils
/// @notice A contract containing common utilities for Permit2
abstract contract Permit2Utils {
    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    error Permit2Failed();

    /*//////////////////////////////////////////////////////////////
                                CONSTANTS
    //////////////////////////////////////////////////////////////*/

    /// @dev Permit2 address
    address public immutable PERMIT2; // solhint-disable-line var-name-mixedcase

    /*//////////////////////////////////////////////////////////////
                                CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _permit2) {
        PERMIT2 = _permit2;
    }

    /*//////////////////////////////////////////////////////////////
                                INTERNAL
    //////////////////////////////////////////////////////////////*/

    /// @dev Parses data and executes permit2.permitTransferFrom, reverts if it fails
    function permit2TransferFrom(bytes calldata data, address recipient, uint256 amount) internal {
        address targetAddress = PERMIT2;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Get free memory pointer
            let ptr := mload(64)
            // Store function selector
            mstore(ptr, 0x30f28b7a00000000000000000000000000000000000000000000000000000000) // permitTransferFrom()
            // Copy data to memory
            calldatacopy(add(ptr, 4), data.offset, data.length)
            // Store recipient
            mstore(add(ptr, 132), recipient)
            // Store amount
            mstore(add(ptr, 164), amount)
            // Store owner
            mstore(add(ptr, 196), caller())
            // Call permit2.permitTransferFrom and revert if call failed
            if iszero(call(gas(), targetAddress, 0, ptr, add(data.length, 4), 0, 0)) {
                mstore(0, 0x6b836e6b00000000000000000000000000000000000000000000000000000000) // Store error selector
                    // error Permit2Failed()
                revert(0, 4)
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.20;

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
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
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
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

// Interfaces
import { IErrors } from "./IErrors.sol";

// Types
import { BalancerV2Data } from "../AugustusV6Types.sol";

/// @title IBalancerV2SwapExactAmountIn
/// @notice Interface for executing swapExactAmountIn directly on Balancer V2 pools
interface IBalancerV2SwapExactAmountIn is IErrors {
    /*//////////////////////////////////////////////////////////////
                          SWAP EXACT AMOUNT IN
    //////////////////////////////////////////////////////////////*/

    /// @notice Executes a swapExactAmountIn on Balancer V2 pools
    /// @param balancerData Struct containing data for the swap
    /// @param partnerAndFee packed partner address and fee percentage, the first 12 bytes is the feeData and the last
    /// 20 bytes is the partner address
    /// @param permit Permit data for the swap
    /// @param data The calldata to execute
    /// the first 20 bytes are the beneficiary address and the left most bit is the approve flag
    /// @return receivedAmount The amount of destToken received after fees
    /// @return paraswapShare The share of the fees for Paraswap
    /// @return partnerShare The share of the fees for the partner
    function swapExactAmountInOnBalancerV2(
        BalancerV2Data calldata balancerData,
        uint256 partnerAndFee,
        bytes calldata permit,
        bytes calldata data
    )
        external
        payable
        returns (uint256 receivedAmount, uint256 paraswapShare, uint256 partnerShare);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

// Interfaces
import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";

/// @title ERC20Utils
/// @notice Optimized functions for ERC20 tokens
library ERC20Utils {
    /*//////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/

    error IncorrectEthAmount();
    error PermitFailed();
    error TransferFromFailed();
    error TransferFailed();
    error ApprovalFailed();

    /*//////////////////////////////////////////////////////////////
                               CONSTANTS
    //////////////////////////////////////////////////////////////*/

    IERC20 internal constant ETH = IERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    /*//////////////////////////////////////////////////////////////
                                APPROVE
    //////////////////////////////////////////////////////////////*/

    /// @dev Vendored from Solady by @vectorized - SafeTransferLib.approveWithRetry
    /// https://github.com/Vectorized/solady/src/utils/SafeTransferLib.sol#L325
    /// Instead of approving a specific amount, this function approves for uint256(-1) (type(uint256).max).
    function approve(IERC20 token, address to) internal {
        // solhint-disable-next-line no-inline-assembly
        assembly ("memory-safe") {
            mstore(0x14, to) // Store the `to` argument.
            mstore(0x34, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) // Store the `amount`
                // argument (type(uint256).max).
            mstore(0x00, 0x095ea7b3000000000000000000000000) // `approve(address,uint256)`.
            // Perform the approval, retrying upon failure.
            if iszero(
                and( // The arguments of `and` are evaluated from right to left.
                    or(eq(mload(0x00), 1), iszero(returndatasize())), // Returned 1 or nothing.
                    call(gas(), token, 0, 0x10, 0x44, 0x00, 0x20)
                )
            ) {
                mstore(0x34, 0) // Store 0 for the `amount`.
                mstore(0x00, 0x095ea7b3000000000000000000000000) // `approve(address,uint256)`.
                pop(call(gas(), token, 0, 0x10, 0x44, codesize(), 0x00)) // Reset the approval.
                mstore(0x34, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) // Store
                    // type(uint256).max for the `amount`.
                // Retry the approval, reverting upon failure.
                if iszero(
                    and(
                        or(eq(mload(0x00), 1), iszero(returndatasize())), // Returned 1 or nothing.
                        call(gas(), token, 0, 0x10, 0x44, 0x00, 0x20)
                    )
                ) {
                    mstore(0, 0x8164f84200000000000000000000000000000000000000000000000000000000)
                    // store the selector (error ApprovalFailed())
                    revert(0, 4) // revert with error selector
                }
            }
            mstore(0x34, 0) // Restore the part of the free memory pointer that was overwritten.
        }
    }

    /*//////////////////////////////////////////////////////////////
                                PERMIT
    //////////////////////////////////////////////////////////////*/

    /// @dev Executes an ERC20 permit and reverts if invalid length is provided
    function permit(IERC20 token, bytes calldata data) internal {
        // solhint-disable-next-line no-inline-assembly
        assembly ("memory-safe") {
            // check the permit length
            switch data.length
            // 32 * 7 = 224 EIP2612 Permit
            case 224 {
                let x := mload(64) // get the free memory pointer
                mstore(x, 0xd505accf00000000000000000000000000000000000000000000000000000000) // store the selector
                    // function permit(address owner, address spender, uint256
                    // amount, uint256 deadline, uint8 v, bytes32 r, bytes32 s)
                calldatacopy(add(x, 4), data.offset, 224) // store the args
                pop(call(gas(), token, 0, x, 228, 0, 32)) // call ERC20 permit, skip checking return data
            }
            // 32 * 8 = 256 DAI-Style Permit
            case 256 {
                let x := mload(64) // get the free memory pointer
                mstore(x, 0x8fcbaf0c00000000000000000000000000000000000000000000000000000000) // store the selector
                    // function permit(address holder, address spender, uint256
                    // nonce, uint256 expiry, bool allowed, uint8 v, bytes32 r, bytes32 s)
                calldatacopy(add(x, 4), data.offset, 256) // store the args
                pop(call(gas(), token, 0, x, 260, 0, 32)) // call ERC20 permit, skip checking return data
            }
            default {
                mstore(0, 0xb78cb0dd00000000000000000000000000000000000000000000000000000000) // store the selector
                    // (error PermitFailed())
                revert(0, 4)
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                                 ETH
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns 1 if the token is ETH, 0 if not ETH
    function isETH(IERC20 token, uint256 amount) internal view returns (uint256 fromETH) {
        // solhint-disable-next-line no-inline-assembly
        assembly ("memory-safe") {
            // If token is ETH
            if eq(token, 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
                // if msg.value is not equal to fromAmount, then revert
                if xor(amount, callvalue()) {
                    mstore(0, 0x8b6ebb4d00000000000000000000000000000000000000000000000000000000) // store the selector
                        // (error IncorrectEthAmount())
                    revert(0, 4) // revert with error selector
                }
                // return 1 if ETH
                fromETH := 1
            }
            // If token is not ETH
            if xor(token, 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
                // if msg.value is not equal to 0, then revert
                if gt(callvalue(), 0) {
                    mstore(0, 0x8b6ebb4d00000000000000000000000000000000000000000000000000000000) // store the selector
                    // (error IncorrectEthAmount())
                    revert(0, 4) // revert with error selector
                }
            }
        }
        // return 0 if not ETH
    }

    /*//////////////////////////////////////////////////////////////
                                TRANSFER
    //////////////////////////////////////////////////////////////*/

    /// @dev Executes transfer and reverts if it fails, works for both ETH and ERC20 transfers
    function safeTransfer(IERC20 token, address recipient, uint256 amount) internal returns (bool success) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            switch eq(token, 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
            // ETH
            case 1 {
                // transfer ETH
                // Cap gas at 10000 to avoid reentrancy
                success := call(10000, recipient, amount, 0, 0, 0, 0)
            }
            // ERC20
            default {
                let x := mload(64) // get the free memory pointer
                mstore(x, 0xa9059cbb00000000000000000000000000000000000000000000000000000000) // store the selector
                    // (function transfer(address recipient, uint256 amount))
                mstore(add(x, 4), recipient) // store the recipient
                mstore(add(x, 36), amount) // store the amount
                success := call(gas(), token, 0, x, 68, 0, 32) // call transfer
                if success {
                    switch returndatasize()
                    // check the return data size
                    case 0 { success := gt(extcodesize(token), 0) }
                    default { success := and(gt(returndatasize(), 31), eq(mload(0), 1)) }
                }
            }
            if iszero(success) {
                mstore(0, 0x90b8ec1800000000000000000000000000000000000000000000000000000000) // store the selector
                    // (error TransferFailed())
                revert(0, 4) // revert with error selector
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                             TRANSFER FROM
    //////////////////////////////////////////////////////////////*/

    /// @dev Executes transferFrom and reverts if it fails
    function safeTransferFrom(
        IERC20 srcToken,
        address sender,
        address recipient,
        uint256 amount
    )
        internal
        returns (bool success)
    {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let x := mload(64) // get the free memory pointer
            mstore(x, 0x23b872dd00000000000000000000000000000000000000000000000000000000) // store the selector
                // (function transferFrom(address sender, address recipient,
                // uint256 amount))
            mstore(add(x, 4), sender) // store the sender
            mstore(add(x, 36), recipient) // store the recipient
            mstore(add(x, 68), amount) // store the amount
            success := call(gas(), srcToken, 0, x, 100, 0, 32) // call transferFrom
            if success {
                switch returndatasize()
                // check the return data size
                case 0 { success := gt(extcodesize(srcToken), 0) }
                default { success := and(gt(returndatasize(), 31), eq(mload(0), 1)) }
            }
            if iszero(success) {
                mstore(x, 0x7939f42400000000000000000000000000000000000000000000000000000000) // store the selector
                    // (error TransferFromFailed())
                revert(x, 4) // revert with error selector
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                                BALANCE
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns the balance of an account, works for both ETH and ERC20 tokens
    function getBalance(IERC20 token, address account) internal view returns (uint256 balanceOf) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            switch eq(token, 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
            // ETH
            case 1 { balanceOf := balance(account) }
            // ERC20
            default {
                let x := mload(64) // get the free memory pointer
                mstore(x, 0x70a0823100000000000000000000000000000000000000000000000000000000) // store the selector
                    // (function balanceOf(address account))
                mstore(add(x, 4), account) // store the account
                let success := staticcall(gas(), token, x, 36, x, 32) // call balanceOf
                if success { balanceOf := mload(x) } // load the balance
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

// Interfaces
import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";

/*//////////////////////////////////////////////////////////////
                        GENERIC SWAP DATA
//////////////////////////////////////////////////////////////*/

/// @notice Struct containg data for generic swapExactAmountIn/swapExactAmountOut
/// @param srcToken The token to swap from
/// @param destToken The token to swap to
/// @param fromAmount The amount of srcToken to swap
/// = amountIn for swapExactAmountIn and maxAmountIn for swapExactAmountOut
/// @param toAmount The minimum amount of destToken to receive
/// = minAmountOut for swapExactAmountIn and amountOut for swapExactAmountOut
/// @param quotedAmount The quoted expected amount of destToken/srcToken
/// = quotedAmountOut for swapExactAmountIn and quotedAmountIn for swapExactAmountOut
/// @param metadata Packed uuid and additional metadata
/// @param beneficiary The address to send the swapped tokens to
struct GenericData {
    IERC20 srcToken;
    IERC20 destToken;
    uint256 fromAmount;
    uint256 toAmount;
    uint256 quotedAmount;
    bytes32 metadata;
    address payable beneficiary;
}

/*//////////////////////////////////////////////////////////////
                            UNISWAPV2
//////////////////////////////////////////////////////////////*/

/// @notice Struct for UniswapV2 swapExactAmountIn/swapExactAmountOut data
/// @param srcToken The token to swap from
/// @param destToken The token to swap to
/// @param fromAmount The amount of srcToken to swap
/// = amountIn for swapExactAmountIn and maxAmountIn for swapExactAmountOut
/// @param quotedAmount The quoted expected amount of destToken/srcToken
/// = quotedAmountOut for swapExactAmountIn and quotedAmountIn for swapExactAmountOut
/// @param toAmount The minimum amount of destToken to receive
/// = minAmountOut for swapExactAmountIn and amountOut for swapExactAmountOut
/// @param metadata Packed uuid and additional metadata
/// @param beneficiary The address to send the swapped tokens to
/// @param pools data consisting of concatenated token0 and token1 address for each pool with the direction flag being
/// the right most bit of the packed token0-token1 pair bytes used in the path
struct UniswapV2Data {
    IERC20 srcToken;
    IERC20 destToken;
    uint256 fromAmount;
    uint256 toAmount;
    uint256 quotedAmount;
    bytes32 metadata;
    address payable beneficiary;
    bytes pools;
}

/*//////////////////////////////////////////////////////////////
                            UNISWAPV3
//////////////////////////////////////////////////////////////*/

/// @notice Struct for UniswapV3 swapExactAmountIn/swapExactAmountOut data
/// @param srcToken The token to swap from
/// @param destToken The token to swap to
/// @param fromAmount The amount of srcToken to swap
/// = amountIn for swapExactAmountIn and maxAmountIn for swapExactAmountOut
/// @param quotedAmount The quoted expected amount of destToken/srcToken
/// = quotedAmountOut for swapExactAmountIn and quotedAmountIn for swapExactAmountOut
/// @param toAmount The minimum amount of destToken to receive
/// = minAmountOut for swapExactAmountIn and amountOut for swapExactAmountOut
/// @param metadata Packed uuid and additional metadata
/// @param beneficiary The address to send the swapped tokens to
/// @param pools data consisting of concatenated token0-
/// token1-fee bytes for each pool used in the path, with the direction flag being the left most bit of token0 in the
/// concatenated bytes
struct UniswapV3Data {
    IERC20 srcToken;
    IERC20 destToken;
    uint256 fromAmount;
    uint256 toAmount;
    uint256 quotedAmount;
    bytes32 metadata;
    address payable beneficiary;
    bytes pools;
}

/*//////////////////////////////////////////////////////////////
                            CURVE V1
//////////////////////////////////////////////////////////////*/

/// @notice Struct for CurveV1 swapExactAmountIn data
/// @param curveData Packed data for the Curve pool, first 160 bits is the target exchange address,
/// the 161st bit is the approve flag, bits from (162 - 163) are used for the wrap flag,
//// bits from (164 - 165) are used for the swapType flag and the last 91 bits are unused:
/// Approve Flag - a) 0 -> do not approve b) 1 -> approve
/// Wrap Flag - a) 0 -> do not wrap b) 1 -> wrap native & srcToken == eth
/// c) 2 -> unwrap and destToken == eth d) 3 - >srcToken == eth && do not wrap
/// Swap Type Flag -  a) 0 -> EXCHANGE b) 1 -> EXCHANGE_UNDERLYING
/// @param curveAssets Packed uint128 index i and uint128 index j of the pool
/// The first 128 bits is the index i and the second 128 bits is the index j
/// @param srcToken The token to swap from
/// @param destToken The token to swap to
/// @param fromAmount The amount of srcToken to swap
/// = amountIn for swapExactAmountIn and maxAmountIn for swapExactAmountOut
/// @param toAmount The minimum amount that must be recieved
/// = minAmountOut for swapExactAmountIn and amountOut for swapExactAmountOut
/// @param quotedAmount The expected amount of destToken to be recieved
/// = quotedAmountOut for swapExactAmountIn and quotedAmountIn for swapExactAmountOut
/// @param metadata Packed uuid and additional metadata
/// @param beneficiary The address to send the swapped tokens to
struct CurveV1Data {
    uint256 curveData;
    uint256 curveAssets;
    IERC20 srcToken;
    IERC20 destToken;
    uint256 fromAmount;
    uint256 toAmount;
    uint256 quotedAmount;
    bytes32 metadata;
    address payable beneficiary;
}

/*//////////////////////////////////////////////////////////////
                            CURVE V2
//////////////////////////////////////////////////////////////*/

/// @notice Struct for CurveV2 swapExactAmountIn data
/// @param curveData Packed data for the Curve pool, first 160 bits is the target exchange address,
/// the 161st bit is the approve flag, bits from (162 - 163) are used for the wrap flag,
//// bits from (164 - 165) are used for the swapType flag and the last 91 bits are unused
/// Approve Flag - a) 0 -> do not approve b) 1 -> approve
/// Approve Flag - a) 0 -> do not approve b) 1 -> approve
/// Wrap Flag - a) 0 -> do not wrap b) 1 -> wrap native & srcToken == eth
/// c) 2 -> unwrap and destToken == eth d) 3 - >srcToken == eth && do not wrap
/// Swap Type Flag -  a) 0 -> EXCHANGE b) 1 -> EXCHANGE_UNDERLYING c) 2 -> EXCHANGE_UNDERLYING_FACTORY_ZAP
/// @param i The index of the srcToken
/// @param j The index of the destToken
/// The first 128 bits is the index i and the second 128 bits is the index j
/// @param poolAddress The address of the CurveV2 pool (only used for EXCHANGE_UNDERLYING_FACTORY_ZAP)
/// @param srcToken The token to swap from
/// @param destToken The token to swap to
/// @param fromAmount The amount of srcToken to swap
/// = amountIn for swapExactAmountIn and maxAmountIn for swapExactAmountOut
/// @param toAmount The minimum amount that must be recieved
/// = minAmountOut for swapExactAmountIn and amountOut for swapExactAmountOut
/// @param quotedAmount The expected amount of destToken to be recieved
/// = quotedAmountOut for swapExactAmountIn and quotedAmountIn for swapExactAmountOut
/// @param metadata Packed uuid and additional metadata
/// @param beneficiary The address to send the swapped tokens to
struct CurveV2Data {
    uint256 curveData;
    uint256 i;
    uint256 j;
    address poolAddress;
    IERC20 srcToken;
    IERC20 destToken;
    uint256 fromAmount;
    uint256 toAmount;
    uint256 quotedAmount;
    bytes32 metadata;
    address payable beneficiary;
}

/*//////////////////////////////////////////////////////////////
                            BALANCER V2
//////////////////////////////////////////////////////////////*/

/// @notice Struct for BalancerV2 swapExactAmountIn data
/// @param fromAmount The amount of srcToken to swap
/// = amountIn for swapExactAmountIn and maxAmountIn for swapExactAmountOut
/// @param toAmount The minimum amount of destToken to receive
/// = minAmountOut for swapExactAmountIn and amountOut for swapExactAmountOut
/// @param quotedAmount The quoted expected amount of destToken/srcToken
/// = quotedAmountOut for swapExactAmountIn and quotedAmountIn for swapExactAmountOut
/// @param metadata Packed uuid and additional metadata
/// @param beneficiaryAndApproveFlag The beneficiary address and approve flag packed into one uint256,
/// the first 20 bytes are the beneficiary address and the left most bit is the approve flag
struct BalancerV2Data {
    uint256 fromAmount;
    uint256 toAmount;
    uint256 quotedAmount;
    bytes32 metadata;
    uint256 beneficiaryAndApproveFlag;
}

/*//////////////////////////////////////////////////////////////
                            MAKERPSM
//////////////////////////////////////////////////////////////*/

/// @notice Struct for Maker PSM swapExactAmountIn data
/// @param srcToken The token to swap from
/// @param destToken The token to swap to
/// @param fromAmount The amount of srcToken to swap
/// = amountIn for swapExactAmountIn and maxAmountIn for swapExactAmountOut
/// @param toAmount The minimum amount of destToken to receive
/// = minAmountOut for swapExactAmountIn and amountOut for swapExactAmountOut
/// @param toll Used to calculate gem amount for the swapExactAmountIn
/// @param to18ConversionFactor Used to calculate gem amount for the swapExactAmountIn
/// @param gemJoinAddress The address of the gemJoin contract
/// @param exchange The address of the exchange contract
/// @param metadata Packed uuid and additional metadata
/// @param beneficiaryDirectionApproveFlag The beneficiary address, swap direction and approve flag packed
/// into one uint256, the first 20 bytes are the beneficiary address, the left most bit is the approve flag and the
/// second left most bit is the swap direction flag, 0 for swapExactAmountIn and 1 for swapExactAmountOut
struct MakerPSMData {
    IERC20 srcToken;
    IERC20 destToken;
    uint256 fromAmount;
    uint256 toAmount;
    uint256 toll;
    uint256 to18ConversionFactor;
    address exchange;
    address gemJoinAddress;
    bytes32 metadata;
    uint256 beneficiaryDirectionApproveFlag;
}

/*//////////////////////////////////////////////////////////////
                            AUGUSTUS RFQ
//////////////////////////////////////////////////////////////*/

/// @notice Order struct for Augustus RFQ
/// @param nonceAndMeta The nonce and meta data packed into one uint256,
/// the first 160 bits is the user address and the last 96 bits is the nonce
/// @param expiry The expiry of the order
/// @param makerAsset The address of the maker asset
/// @param takerAsset The address of the taker asset
/// @param maker The address of the maker
/// @param taker The address of the taker, if the taker is address(0) anyone can take the order
/// @param makerAmount The amount of makerAsset
/// @param takerAmount The amount of takerAsset
struct Order {
    uint256 nonceAndMeta;
    uint128 expiry;
    address makerAsset;
    address takerAsset;
    address maker;
    address taker;
    uint256 makerAmount;
    uint256 takerAmount;
}

/// @notice Struct containing order info for Augustus RFQ
/// @param order The order struct
/// @param signature The signature for the order
/// @param takerTokenFillAmount The amount of takerToken to fill
/// @param permitTakerAsset The permit data for the taker asset
/// @param permitMakerAsset The permit data for the maker asset
struct OrderInfo {
    Order order;
    bytes signature;
    uint256 takerTokenFillAmount;
    bytes permitTakerAsset;
    bytes permitMakerAsset;
}

/// @notice Struct containing common data for executing swaps on Augustus RFQ
/// @param fromAmount The amount of srcToken to swap
/// = amountIn for swapExactAmountIn and maxAmountIn for swapExactAmountOut
/// @param toAmount The minimum amount of destToken to receive
/// = minAmountOut for swapExactAmountIn and amountOut for swapExactAmountOut
/// @param wrapApproveDirection The wrap, approve and direction flag packed into one uint8,
/// the first 2 bits is wrap flag (10 for wrap dest, 01 for wrap src, 00 for no wrap), the next bit is the approve flag
/// (1 for approve, 0 for no approve) and the last bit is the direction flag (0 for swapExactAmountIn and 1 for
/// swapExactAmountOut)
/// @param metadata Packed uuid and additional metadata
struct AugustusRFQData {
    uint256 fromAmount;
    uint256 toAmount;
    uint8 wrapApproveDirection;
    bytes32 metadata;
    address payable beneficiary;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

// Interfaces
import { IErrors } from "./IErrors.sol";

// Types
import { CurveV1Data } from "../AugustusV6Types.sol";

/// @title ICurveV1SwapExactAmountIn
/// @notice Interface for direct swaps on Curve V1
interface ICurveV1SwapExactAmountIn is IErrors {
    /*//////////////////////////////////////////////////////////////
                          SWAP EXACT AMOUNT IN
    //////////////////////////////////////////////////////////////*/

    /// @notice Executes a swapExactAmountIn on Curve V1 pools
    /// @param curveV1Data Struct containing data for the swap
    /// @param partnerAndFee packed partner address and fee percentage, the first 12 bytes is the feeData and the last
    /// 20 bytes is the partner address
    /// @param permit Permit data for the swap
    /// @return receivedAmount The amount of destToken received after fees
    /// @return paraswapShare The share of the fees for Paraswap
    /// @return partnerShare The share of the fees for the partner
    function swapExactAmountInOnCurveV1(
        CurveV1Data calldata curveV1Data,
        uint256 partnerAndFee,
        bytes calldata permit
    )
        external
        payable
        returns (uint256 receivedAmount, uint256 paraswapShare, uint256 partnerShare);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

// Storage
import { AugustusStorage } from "../storage/AugustusStorage.sol";

/// @title PauseUtils
/// @notice Provides a modifier to check if the contract is paused
abstract contract PauseUtils is AugustusStorage {
    /*//////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/

    /// @notice Error emitted when the contract is paused
    error ContractPaused();

    /*//////////////////////////////////////////////////////////////
                               MODIFIERS
    //////////////////////////////////////////////////////////////*/

    // Check if the contract is paused, if it is, revert
    modifier whenNotPaused() {
        if (paused) {
            revert ContractPaused();
        }
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

// Interfaces
import { IErrors } from "./IErrors.sol";

// Types
import { CurveV2Data } from "../AugustusV6Types.sol";

/// @title ICurveV2SwapExactAmountIn
/// @notice Interface for direct swaps on Curve V2
interface ICurveV2SwapExactAmountIn is IErrors {
    /*//////////////////////////////////////////////////////////////
                          SWAP EXACT AMOUNT IN
    //////////////////////////////////////////////////////////////*/

    /// @notice Executes a swapExactAmountIn on Curve V2 pools
    /// @param curveV2Data Struct containing data for the swap
    /// @param partnerAndFee packed partner address and fee percentage, the first 12 bytes is the feeData and the last
    /// 20 bytes is the partner address
    /// @param permit Permit data for the swap
    /// @return receivedAmount The amount of destToken received after fees
    /// @return paraswapShare The share of the fees for Paraswap
    /// @return partnerShare The share of the fees for the partner
    function swapExactAmountInOnCurveV2(
        CurveV2Data calldata curveV2Data,
        uint256 partnerAndFee,
        bytes calldata permit
    )
        external
        payable
        returns (uint256 receivedAmount, uint256 paraswapShare, uint256 partnerShare);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

// Interfaces
import { IErrors } from "./IErrors.sol";

// Types
import { UniswapV2Data } from "../AugustusV6Types.sol";

/// @title IUniswapV2SwapExactAmountIn
/// @notice Interface for direct swaps on Uniswap V2
interface IUniswapV2SwapExactAmountIn is IErrors {
    /*//////////////////////////////////////////////////////////////
                         SWAP EXACT AMOUNT OUT
    //////////////////////////////////////////////////////////////*/

    /// @notice Executes a swapExactAmountIn on Uniswap V2 pools
    /// @param uniData struct containing data for the swap
    /// @param partnerAndFee packed partner address and fee percentage, the first 12 bytes is the feeData and the last
    /// 20 bytes is the partner address
    /// @param permit The permit data
    /// @return receivedAmount The amount of destToken received after fees
    /// @return paraswapShare The share of the fees for Paraswap
    /// @return partnerShare The share of the fees for the partner
    function swapExactAmountInOnUniswapV2(
        UniswapV2Data calldata uniData,
        uint256 partnerAndFee,
        bytes calldata permit
    )
        external
        payable
        returns (uint256 receivedAmount, uint256 paraswapShare, uint256 partnerShare);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

// Interfaces
import { IErrors } from "./IErrors.sol";

// Types
import { UniswapV3Data } from "../AugustusV6Types.sol";

/// @title IUniswapV3SwapExactAmountIn
/// @notice Interface for executing direct swapExactAmountIn on Uniswap V3
interface IUniswapV3SwapExactAmountIn is IErrors {
    /*//////////////////////////////////////////////////////////////
                          SWAP EXACT AMOUNT IN
    //////////////////////////////////////////////////////////////*/

    /// @notice Executes a swapExactAmountIn on Uniswap V3 pools
    /// @param uniData struct containing data for the swap
    /// @param partnerAndFee packed partner address and fee percentage, the first 12 bytes is the feeData and the last
    /// 20 bytes is the partner address
    /// @param permit The permit data
    /// @return receivedAmount The amount of destToken received after fees
    /// @return paraswapShare The share of the fees for Paraswap
    /// @return partnerShare The share of the fees for the partner
    function swapExactAmountInOnUniswapV3(
        UniswapV3Data calldata uniData,
        uint256 partnerAndFee,
        bytes calldata permit
    )
        external
        payable
        returns (uint256 receivedAmount, uint256 paraswapShare, uint256 partnerShare);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Safe integer casting library that reverts on overflow.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/SafeCastLib.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeCast.sol)
library SafeCastLib {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    error Overflow();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*          UNSIGNED INTEGER SAFE CASTING OPERATIONS          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    function toUint8(uint256 x) internal pure returns (uint8) {
        if (x >= 1 << 8) _revertOverflow();
        return uint8(x);
    }

    function toUint16(uint256 x) internal pure returns (uint16) {
        if (x >= 1 << 16) _revertOverflow();
        return uint16(x);
    }

    function toUint24(uint256 x) internal pure returns (uint24) {
        if (x >= 1 << 24) _revertOverflow();
        return uint24(x);
    }

    function toUint32(uint256 x) internal pure returns (uint32) {
        if (x >= 1 << 32) _revertOverflow();
        return uint32(x);
    }

    function toUint40(uint256 x) internal pure returns (uint40) {
        if (x >= 1 << 40) _revertOverflow();
        return uint40(x);
    }

    function toUint48(uint256 x) internal pure returns (uint48) {
        if (x >= 1 << 48) _revertOverflow();
        return uint48(x);
    }

    function toUint56(uint256 x) internal pure returns (uint56) {
        if (x >= 1 << 56) _revertOverflow();
        return uint56(x);
    }

    function toUint64(uint256 x) internal pure returns (uint64) {
        if (x >= 1 << 64) _revertOverflow();
        return uint64(x);
    }

    function toUint72(uint256 x) internal pure returns (uint72) {
        if (x >= 1 << 72) _revertOverflow();
        return uint72(x);
    }

    function toUint80(uint256 x) internal pure returns (uint80) {
        if (x >= 1 << 80) _revertOverflow();
        return uint80(x);
    }

    function toUint88(uint256 x) internal pure returns (uint88) {
        if (x >= 1 << 88) _revertOverflow();
        return uint88(x);
    }

    function toUint96(uint256 x) internal pure returns (uint96) {
        if (x >= 1 << 96) _revertOverflow();
        return uint96(x);
    }

    function toUint104(uint256 x) internal pure returns (uint104) {
        if (x >= 1 << 104) _revertOverflow();
        return uint104(x);
    }

    function toUint112(uint256 x) internal pure returns (uint112) {
        if (x >= 1 << 112) _revertOverflow();
        return uint112(x);
    }

    function toUint120(uint256 x) internal pure returns (uint120) {
        if (x >= 1 << 120) _revertOverflow();
        return uint120(x);
    }

    function toUint128(uint256 x) internal pure returns (uint128) {
        if (x >= 1 << 128) _revertOverflow();
        return uint128(x);
    }

    function toUint136(uint256 x) internal pure returns (uint136) {
        if (x >= 1 << 136) _revertOverflow();
        return uint136(x);
    }

    function toUint144(uint256 x) internal pure returns (uint144) {
        if (x >= 1 << 144) _revertOverflow();
        return uint144(x);
    }

    function toUint152(uint256 x) internal pure returns (uint152) {
        if (x >= 1 << 152) _revertOverflow();
        return uint152(x);
    }

    function toUint160(uint256 x) internal pure returns (uint160) {
        if (x >= 1 << 160) _revertOverflow();
        return uint160(x);
    }

    function toUint168(uint256 x) internal pure returns (uint168) {
        if (x >= 1 << 168) _revertOverflow();
        return uint168(x);
    }

    function toUint176(uint256 x) internal pure returns (uint176) {
        if (x >= 1 << 176) _revertOverflow();
        return uint176(x);
    }

    function toUint184(uint256 x) internal pure returns (uint184) {
        if (x >= 1 << 184) _revertOverflow();
        return uint184(x);
    }

    function toUint192(uint256 x) internal pure returns (uint192) {
        if (x >= 1 << 192) _revertOverflow();
        return uint192(x);
    }

    function toUint200(uint256 x) internal pure returns (uint200) {
        if (x >= 1 << 200) _revertOverflow();
        return uint200(x);
    }

    function toUint208(uint256 x) internal pure returns (uint208) {
        if (x >= 1 << 208) _revertOverflow();
        return uint208(x);
    }

    function toUint216(uint256 x) internal pure returns (uint216) {
        if (x >= 1 << 216) _revertOverflow();
        return uint216(x);
    }

    function toUint224(uint256 x) internal pure returns (uint224) {
        if (x >= 1 << 224) _revertOverflow();
        return uint224(x);
    }

    function toUint232(uint256 x) internal pure returns (uint232) {
        if (x >= 1 << 232) _revertOverflow();
        return uint232(x);
    }

    function toUint240(uint256 x) internal pure returns (uint240) {
        if (x >= 1 << 240) _revertOverflow();
        return uint240(x);
    }

    function toUint248(uint256 x) internal pure returns (uint248) {
        if (x >= 1 << 248) _revertOverflow();
        return uint248(x);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*           SIGNED INTEGER SAFE CASTING OPERATIONS           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    function toInt8(int256 x) internal pure returns (int8) {
        int8 y = int8(x);
        if (x != y) _revertOverflow();
        return y;
    }

    function toInt16(int256 x) internal pure returns (int16) {
        int16 y = int16(x);
        if (x != y) _revertOverflow();
        return y;
    }

    function toInt24(int256 x) internal pure returns (int24) {
        int24 y = int24(x);
        if (x != y) _revertOverflow();
        return y;
    }

    function toInt32(int256 x) internal pure returns (int32) {
        int32 y = int32(x);
        if (x != y) _revertOverflow();
        return y;
    }

    function toInt40(int256 x) internal pure returns (int40) {
        int40 y = int40(x);
        if (x != y) _revertOverflow();
        return y;
    }

    function toInt48(int256 x) internal pure returns (int48) {
        int48 y = int48(x);
        if (x != y) _revertOverflow();
        return y;
    }

    function toInt56(int256 x) internal pure returns (int56) {
        int56 y = int56(x);
        if (x != y) _revertOverflow();
        return y;
    }

    function toInt64(int256 x) internal pure returns (int64) {
        int64 y = int64(x);
        if (x != y) _revertOverflow();
        return y;
    }

    function toInt72(int256 x) internal pure returns (int72) {
        int72 y = int72(x);
        if (x != y) _revertOverflow();
        return y;
    }

    function toInt80(int256 x) internal pure returns (int80) {
        int80 y = int80(x);
        if (x != y) _revertOverflow();
        return y;
    }

    function toInt88(int256 x) internal pure returns (int88) {
        int88 y = int88(x);
        if (x != y) _revertOverflow();
        return y;
    }

    function toInt96(int256 x) internal pure returns (int96) {
        int96 y = int96(x);
        if (x != y) _revertOverflow();
        return y;
    }

    function toInt104(int256 x) internal pure returns (int104) {
        int104 y = int104(x);
        if (x != y) _revertOverflow();
        return y;
    }

    function toInt112(int256 x) internal pure returns (int112) {
        int112 y = int112(x);
        if (x != y) _revertOverflow();
        return y;
    }

    function toInt120(int256 x) internal pure returns (int120) {
        int120 y = int120(x);
        if (x != y) _revertOverflow();
        return y;
    }

    function toInt128(int256 x) internal pure returns (int128) {
        int128 y = int128(x);
        if (x != y) _revertOverflow();
        return y;
    }

    function toInt136(int256 x) internal pure returns (int136) {
        int136 y = int136(x);
        if (x != y) _revertOverflow();
        return y;
    }

    function toInt144(int256 x) internal pure returns (int144) {
        int144 y = int144(x);
        if (x != y) _revertOverflow();
        return y;
    }

    function toInt152(int256 x) internal pure returns (int152) {
        int152 y = int152(x);
        if (x != y) _revertOverflow();
        return y;
    }

    function toInt160(int256 x) internal pure returns (int160) {
        int160 y = int160(x);
        if (x != y) _revertOverflow();
        return y;
    }

    function toInt168(int256 x) internal pure returns (int168) {
        int168 y = int168(x);
        if (x != y) _revertOverflow();
        return y;
    }

    function toInt176(int256 x) internal pure returns (int176) {
        int176 y = int176(x);
        if (x != y) _revertOverflow();
        return y;
    }

    function toInt184(int256 x) internal pure returns (int184) {
        int184 y = int184(x);
        if (x != y) _revertOverflow();
        return y;
    }

    function toInt192(int256 x) internal pure returns (int192) {
        int192 y = int192(x);
        if (x != y) _revertOverflow();
        return y;
    }

    function toInt200(int256 x) internal pure returns (int200) {
        int200 y = int200(x);
        if (x != y) _revertOverflow();
        return y;
    }

    function toInt208(int256 x) internal pure returns (int208) {
        int208 y = int208(x);
        if (x != y) _revertOverflow();
        return y;
    }

    function toInt216(int256 x) internal pure returns (int216) {
        int216 y = int216(x);
        if (x != y) _revertOverflow();
        return y;
    }

    function toInt224(int256 x) internal pure returns (int224) {
        int224 y = int224(x);
        if (x != y) _revertOverflow();
        return y;
    }

    function toInt232(int256 x) internal pure returns (int232) {
        int232 y = int232(x);
        if (x != y) _revertOverflow();
        return y;
    }

    function toInt240(int256 x) internal pure returns (int240) {
        int240 y = int240(x);
        if (x != y) _revertOverflow();
        return y;
    }

    function toInt248(int256 x) internal pure returns (int248) {
        int248 y = int248(x);
        if (x != y) _revertOverflow();
        return y;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*               OTHER SAFE CASTING OPERATIONS                */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    function toInt256(uint256 x) internal pure returns (int256) {
        if (x >= 1 << 255) _revertOverflow();
        return int256(x);
    }

    function toUint256(int256 x) internal pure returns (uint256) {
        if (x < 0) _revertOverflow();
        return uint256(x);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      PRIVATE HELPERS                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    function _revertOverflow() private pure {
        /// @solidity memory-safe-assembly
        assembly {
            // Store the function selector of `Overflow()`.
            mstore(0x00, 0x35278d12)
            // Revert with (offset, size).
            revert(0x1c, 0x04)
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

// Interfaces
import { IErrors } from "./IErrors.sol";

// Types
import { BalancerV2Data } from "../AugustusV6Types.sol";

/// @title IBalancerV2SwapExactAmountOut
/// @notice Interface for executing swapExactAmountOut directly on Balancer V2 pools
interface IBalancerV2SwapExactAmountOut is IErrors {
    /*//////////////////////////////////////////////////////////////
                         SWAP EXACT AMOUNT OUT
    //////////////////////////////////////////////////////////////*/

    /// @notice Executes a swapExactAmountOut on Balancer V2 pools
    /// @param balancerData Struct containing data for the swap
    /// @param partnerAndFee packed partner address and fee percentage, the first 12 bytes is the feeData and the last
    /// 20 bytes is the partner address
    /// @param permit Permit data for the swap
    /// @param data The calldata to execute
    /// @return spentAmount The actual amount of tokens used to swap
    /// @return receivedAmount The amount of tokens received
    /// @return paraswapShare The share of the fees for Paraswap
    /// @return partnerShare The share of the fees for the partner
    function swapExactAmountOutOnBalancerV2(
        BalancerV2Data calldata balancerData,
        uint256 partnerAndFee,
        bytes calldata permit,
        bytes calldata data
    )
        external
        payable
        returns (uint256 spentAmount, uint256 receivedAmount, uint256 paraswapShare, uint256 partnerShare);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

// Interfaces
import { IErrors } from "./IErrors.sol";

// Types
import { UniswapV2Data } from "../AugustusV6Types.sol";

/// @title IUniswapV2SwapExactAmountOut
/// @notice Interface for direct swapExactAmountOut on Uniswap V2
interface IUniswapV2SwapExactAmountOut is IErrors {
    /*//////////////////////////////////////////////////////////////
                          SWAP EXACT AMOUNT IN
    //////////////////////////////////////////////////////////////*/

    /// @notice Executes a swapExactAmountOut on Uniswap V2 pools
    /// @param swapData struct containing data for the swap
    /// @param partnerAndFee packed partner address and fee percentage, the first 12 bytes is the feeData and the last
    /// 20 bytes is the partner address
    /// @param permit The permit data
    /// @return spentAmount The actual amount of tokens used to swap
    /// @return receivedAmount The amount of tokens received
    /// @return paraswapShare The share of the fees for Paraswap
    /// @return partnerShare The share of the fees for the partner
    function swapExactAmountOutOnUniswapV2(
        UniswapV2Data calldata swapData,
        uint256 partnerAndFee,
        bytes calldata permit
    )
        external
        payable
        returns (uint256 spentAmount, uint256 receivedAmount, uint256 paraswapShare, uint256 partnerShare);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

// Interfaces
import { IErrors } from "./IErrors.sol";

// Types
import { UniswapV3Data } from "../AugustusV6Types.sol";

/// @title IUniswapV3SwapExactAmountOut
/// @notice Interface for executing direct swapExactAmountOut on Uniswap V3
interface IUniswapV3SwapExactAmountOut is IErrors {
    /*//////////////////////////////////////////////////////////////
                         SWAP EXACT AMOUNT OUT
    //////////////////////////////////////////////////////////////*/

    /// @notice Executes a swapExactAmountOut on Uniswap V3 pools
    /// @param swapData struct containing data for the swap
    /// @param partnerAndFee packed partner address and fee percentage, the first 12 bytes is the feeData and the last
    /// 20 bytes is the partner address
    /// @param permit The permit data
    /// @return spentAmount The actual amount of tokens used to swap
    /// @return receivedAmount The amount of tokens received
    /// @return paraswapShare The share of the fees for Paraswap
    /// @return partnerShare The share of the fees for the partner
    function swapExactAmountOutOnUniswapV3(
        UniswapV3Data calldata swapData,
        uint256 partnerAndFee,
        bytes calldata permit
    )
        external
        payable
        returns (uint256 spentAmount, uint256 receivedAmount, uint256 paraswapShare, uint256 partnerShare);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

// Interfaces
import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";

/// @title IAugustusFeeVault
/// @notice Interface for the AugustusFeeVault contract
interface IAugustusFeeVault {
    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    /// @notice Error emitted when withdraw amount is zero or exceeds the stored amount
    error InvalidWithdrawAmount();

    /// @notice Error emmitted when caller is not an approved augustus contract
    error UnauthorizedCaller();

    /// @notice Error emitted when an invalid parameter length is passed
    error InvalidParameterLength();

    /// @notice Error emitted when batch withdraw fails
    error BatchCollectFailed();

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Emitted when an augustus contract approval status is set
    /// @param augustus The augustus contract address
    /// @param approved The approval status
    event AugustusApprovalSet(address indexed augustus, bool approved);

    /*//////////////////////////////////////////////////////////////
                                STRUCTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Struct to register fees
    /// @param addresses The addresses to register fees for
    /// @param token The token to register fees for
    /// @param fees The fees to register
    struct FeeRegistration {
        address[] addresses;
        IERC20 token;
        uint256[] fees;
    }

    /*//////////////////////////////////////////////////////////////
                                COLLECT
    //////////////////////////////////////////////////////////////*/

    /// @notice Allows partners to withdraw fees allocated to them and stored in the vault
    /// @param token The token to withdraw fees in
    /// @param amount The amount of fees to withdraw
    /// @param recipient The address to send the fees to
    /// @return success Whether the transfer was successful or not
    function withdrawSomeERC20(IERC20 token, uint256 amount, address recipient) external returns (bool success);

    /// @notice Allows partners to withdraw all fees allocated to them and stored in the vault for a given token
    /// @param token The token to withdraw fees in
    /// @param recipient The address to send the fees to
    /// @return success Whether the transfer was successful or not
    function withdrawAllERC20(IERC20 token, address recipient) external returns (bool success);

    /// @notice Allows partners to withdraw all fees allocated to them and stored in the vault for multiple tokens
    /// @param tokens The tokens to withdraw fees i
    /// @param recipient The address to send the fees to
    /// @return success Whether the transfer was successful or not
    function batchWithdrawAllERC20(IERC20[] calldata tokens, address recipient) external returns (bool success);

    /// @notice Allows partners to withdraw fees allocated to them and stored in the vault
    /// @param tokens The tokens to withdraw fees in
    /// @param amounts The amounts of fees to withdraw
    /// @param recipient The address to send the fees to
    /// @return success Whether the transfer was successful or not
    function batchWithdrawSomeERC20(
        IERC20[] calldata tokens,
        uint256[] calldata amounts,
        address recipient
    )
        external
        returns (bool success);

    /*//////////////////////////////////////////////////////////////
                            BALANCE GETTERS
    //////////////////////////////////////////////////////////////*/

    /// @notice Get the balance of a given token for a given partner
    /// @param token The token to get the balance of
    /// @param partner The partner to get the balance for
    /// @return feeBalance The balance of the given token for the given partner
    function getBalance(IERC20 token, address partner) external view returns (uint256 feeBalance);

    /// @notice Get the balances of a given partner for multiple tokens
    /// @param tokens The tokens to get the balances of
    /// @param partner The partner to get the balances for
    /// @return feeBalances The balances of the given tokens for the given partner
    function batchGetBalance(
        IERC20[] calldata tokens,
        address partner
    )
        external
        view
        returns (uint256[] memory feeBalances);

    /// @notice Returns the unallocated fees for a given token
    /// @param token The token to get the unallocated fees for
    /// @return unallocatedFees The unallocated fees for the given token
    function getUnallocatedFees(IERC20 token) external view returns (uint256 unallocatedFees);

    /*//////////////////////////////////////////////////////////////
                                 OWNER
    //////////////////////////////////////////////////////////////*/

    /// @notice Registers the given feeData to the vault
    /// @param feeData The fee registration data
    function registerFees(FeeRegistration memory feeData) external;

    /// @notice Sets the augustus contract approval status
    /// @param augustus The augustus contract address
    /// @param approved The approval status
    function setAugustusApproval(address augustus, bool approved) external;

    /// @notice Sets the contract pause state
    /// @param _isPaused The new pause state
    function setContractPauseState(bool _isPaused) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

/// @title IAugustusFees
/// @notice Interface for the AugustusFees contract, which handles the fees for the Augustus aggregator
interface IAugustusFees {
    /*//////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/

    /// @notice Error emmited when the balance is not enough to pay the fees
    error InsufficientBalanceToPayFees();

    /// @notice Error emmited when the quotedAmount is bigger than the fromAmount
    error InvalidQuotedAmount();

    /*//////////////////////////////////////////////////////////////
                                 PUBLIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Parses the `partnerAndFee` parameter to extract the partner address and fee data.
    /// @dev `partnerAndFee` is a uint256 value where data is packed in a specific bit layout.
    ///
    ///      The bit layout for `partnerAndFee` is as follows:
    ///      - The most significant 160 bits (positions 255 to 96) represent the partner address.
    ///      - Bits 95 to 92 are reserved for flags indicating various fee processing conditions:
    ///          - 95th bit: `IS_TAKE_SURPLUS_MASK` - Partner takes surplus
    ///          - 94th bit: `IS_REFERRAL_MASK` - Referral takes surplus
    ///          - 93rd bit: `IS_SKIP_BLACKLIST_MASK` - Bypass token blacklist when processing fees
    ///          - 92nd bit: `IS_CAP_SURPLUS_MASK` - Cap surplus to 1% of quoted amount
    ///      - The least significant 16 bits (positions 15 to 0) encode the fee percentage.
    ///
    /// @param partnerAndFee Packed uint256 containing both partner address and fee data.
    /// @return partner The extracted partner address as a payable address.
    /// @return feeData The extracted fee data containing the fee percentage and flags.
    function parsePartnerAndFeeData(uint256 partnerAndFee)
        external
        pure
        returns (address payable partner, uint256 feeData);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

// Interfaces
import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";

// @title AugustusStorage
// @notice Inherited storage layout for AugustusV6,
// contracts should inherit this contract to access the storage layout
contract AugustusStorage {
    /*//////////////////////////////////////////////////////////////
                               FEES
    //////////////////////////////////////////////////////////////*/

    // @dev Mapping of tokens to boolean indicating if token is blacklisted for fee collection
    mapping(IERC20 token => bool isBlacklisted) public blacklistedTokens;

    // @dev Fee wallet to directly transfer paraswap share to
    address payable public feeWallet;

    // @dev Fee wallet address to register the paraswap share to in the fee vault
    address payable public feeWalletDelegate;

    /*//////////////////////////////////////////////////////////////
                                CONTROL
    //////////////////////////////////////////////////////////////*/

    // @dev Contract paused state
    bool public paused;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

// Contracts
import { AugustusFees } from "../fees/AugustusFees.sol";

// Utils
import { Permit2Utils } from "./Permit2Utils.sol";
import { PauseUtils } from "./PauseUtils.sol";

/// @title GenericUtils
/// @notice A contract containing common utilities for Generic swaps
abstract contract GenericUtils is AugustusFees, Permit2Utils, PauseUtils {
    /*//////////////////////////////////////////////////////////////
                                INTERNAL
    //////////////////////////////////////////////////////////////*/

    /// @dev Call executor with executorData and amountIn
    function _callSwapExactAmountInExecutor(
        address executor,
        bytes calldata executorData,
        uint256 amountIn
    )
        internal
    {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // get the length of the executorData
            // + 4 bytes for the selector
            // + 32 bytes for fromAmount
            // + 32 bytes for sender
            let totalLength := add(executorData.length, 68)
            calldatacopy(add(0x7c, 4), executorData.offset, executorData.length) // store the executorData
            mstore(add(0x7c, add(4, executorData.length)), amountIn) // store the amountIn
            mstore(add(0x7c, add(36, executorData.length)), caller()) // store the sender
            // call executor and forward call value
            if iszero(call(gas(), executor, callvalue(), 0x7c, totalLength, 0, 0)) {
                returndatacopy(0x7c, 0, returndatasize()) // copy the revert data to memory
                revert(0x7c, returndatasize()) // revert with the revert data
            }
        }
    }

    /// @dev Call executor with executorData, maxAmountIn, amountOut
    function _callSwapExactAmountOutExecutor(
        address executor,
        bytes calldata executorData,
        uint256 maxAmountIn,
        uint256 amountOut
    )
        internal
    {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // get the length of the executorData
            // + 4 bytes for the selector
            // + 32 bytes for fromAmount
            // + 32 bytes for toAmount
            // + 32 bytes for sender
            let totalLength := add(executorData.length, 100)
            calldatacopy(add(0x7c, 4), executorData.offset, executorData.length) // store the executorData
            mstore(add(0x7c, add(4, executorData.length)), maxAmountIn) // store the maxAmountIn
            mstore(add(0x7c, add(36, executorData.length)), amountOut) // store the amountOut
            mstore(add(0x7c, add(68, executorData.length)), caller()) // store the sender
            // call executor and forward call value
            if iszero(call(gas(), executor, callvalue(), 0x7c, totalLength, 0, 0)) {
                returndatacopy(0x7c, 0, returndatasize()) // copy the revert data to memory
                revert(0x7c, returndatasize()) // revert with the revert data
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

// Interfaces
import { IErrors } from "./IErrors.sol";

// Types
import { GenericData } from "../AugustusV6Types.sol";

/// @title IGenericSwapExactAmountIn
/// @notice Interface for executing a generic swapExactAmountIn through an Augustus executor
interface IGenericSwapExactAmountIn is IErrors {
    /*//////////////////////////////////////////////////////////////
                          SWAP EXACT AMOUNT IN
    //////////////////////////////////////////////////////////////*/

    /// @notice Executes a generic swapExactAmountIn using the given executorData on the given executor
    /// @param executor The address of the executor contract to use
    /// @param swapData Generic data containing the swap information
    /// @param partnerAndFee packed partner address and fee percentage, the first 12 bytes is the feeData and the last
    /// 20 bytes is the partner address
    /// @param permit The permit data
    /// @param executorData The data to execute on the executor
    /// @return receivedAmount The amount of destToken received after fees
    /// @return paraswapShare The share of the fees for Paraswap
    /// @return partnerShare The share of the fees for the partner
    function swapExactAmountIn(
        address executor,
        GenericData calldata swapData,
        uint256 partnerAndFee,
        bytes calldata permit,
        bytes calldata executorData
    )
        external
        payable
        returns (uint256 receivedAmount, uint256 paraswapShare, uint256 partnerShare);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

// Interfaces
import { IErrors } from "./IErrors.sol";

// Types
import { GenericData } from "../AugustusV6Types.sol";

/// @title IGenericSwapExactAmountOut
/// @notice Interface for executing a generic swapExactAmountOut through an Augustus executor
interface IGenericSwapExactAmountOut is IErrors {
    /*//////////////////////////////////////////////////////////////
                         SWAP EXACT AMOUNT OUT
    //////////////////////////////////////////////////////////////*/

    /// @notice Executes a generic swapExactAmountOut using the given executorData on the given executor
    /// @param executor The address of the executor contract to use
    /// @param swapData Generic data containing the swap information
    /// @param partnerAndFee packed partner address and fee percentage, the first 12 bytes is the feeData and the last
    /// 20 bytes is the partner address
    /// @param permit The permit data
    /// @param executorData The data to execute on the executor
    /// @return spentAmount The actual amount of tokens used to swap
    /// @return receivedAmount The amount of tokens received from the swap
    /// @return paraswapShare The share of the fees for Paraswap
    /// @return partnerShare The share of the fees for the partner
    function swapExactAmountOut(
        address executor,
        GenericData calldata swapData,
        uint256 partnerAndFee,
        bytes calldata permit,
        bytes calldata executorData
    )
        external
        payable
        returns (uint256 spentAmount, uint256 receivedAmount, uint256 paraswapShare, uint256 partnerShare);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

// Interfaces
import { IErrors } from "./IErrors.sol";

// Types
import { AugustusRFQData, OrderInfo } from "../AugustusV6Types.sol";

/// @title IAugustusRFQRouter
/// @notice Interface for direct swaps on AugustusRFQ
interface IAugustusRFQRouter is IErrors {
    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    /// @notice Emitted when the passed msg.value is not equal to the fromAmount
    error IncorrectEthAmount();

    /*//////////////////////////////////////////////////////////////
                             TRY BATCH FILL
    //////////////////////////////////////////////////////////////*/

    /// @notice Executes a tryBatchFillTakerAmount or tryBatchFillMakerAmount call on AugustusRFQ
    /// the function that is executed is defined by the direction flag in the data param
    /// @param data Struct containing common data for AugustusRFQ
    /// @param orders An array containing AugustusRFQ orderInfo data
    /// @param permit Permit data for the swap
    /// @return spentAmount The amount of tokens spent
    /// @return receivedAmount The amount of tokens received
    function swapOnAugustusRFQTryBatchFill(
        AugustusRFQData calldata data,
        OrderInfo[] calldata orders,
        bytes calldata permit
    )
        external
        payable
        returns (uint256 spentAmount, uint256 receivedAmount);
}

// SPDX-License-Identifier: ISC

pragma solidity 0.8.22;
pragma abicoder v2;

// Types
import { Order, OrderInfo } from "../AugustusV6Types.sol";

interface IAugustusRFQ {
    /// @dev Allows taker to fill an order
    /// @param order Order quote to fill
    /// @param signature Signature of the maker corresponding to the order
    function fillOrder(Order calldata order, bytes calldata signature) external;

    /// @dev The same as fillOrder but allows sender to specify the target beneficiary address
    /// @param order Order quote to fill
    /// @param signature Signature of the maker corresponding to the order
    /// @param target Address of the receiver
    function fillOrderWithTarget(Order calldata order, bytes calldata signature, address target) external;

    /// @dev Allows taker to fill an order partially
    /// @param order Order quote to fill
    /// @param signature Signature of the maker corresponding to the order
    /// @param takerTokenFillAmount Maximum taker token to fill this order with.
    function partialFillOrder(
        Order calldata order,
        bytes calldata signature,
        uint256 takerTokenFillAmount
    )
        external
        returns (uint256 makerTokenFilledAmount);

    /// @dev Same as `partialFillOrder` but it allows to specify the destination address
    ///  @param order Order quote to fill
    ///  @param signature Signature of the maker corresponding to the order
    ///  @param takerTokenFillAmount Maximum taker token to fill this order with.
    ///  @param target Address that will receive swap funds
    function partialFillOrderWithTarget(
        Order calldata order,
        bytes calldata signature,
        uint256 takerTokenFillAmount,
        address target
    )
        external
        returns (uint256 makerTokenFilledAmount);

    /// @dev Same as `partialFillOrderWithTarget` but it allows to pass permit
    ///  @param order Order quote to fill
    ///  @param signature Signature of the maker corresponding to the order
    ///  @param takerTokenFillAmount Maximum taker token to fill this order with.
    ///  @param target Address that will receive swap funds
    ///  @param permitTakerAsset Permit calldata for taker
    ///  @param permitMakerAsset Permit calldata for maker
    function partialFillOrderWithTargetPermit(
        Order calldata order,
        bytes calldata signature,
        uint256 takerTokenFillAmount,
        address target,
        bytes calldata permitTakerAsset,
        bytes calldata permitMakerAsset
    )
        external
        returns (uint256 makerTokenFilledAmount);

    /// @dev batch fills orders until the takerFillAmount is swapped
    /// @dev skip the order if it fails
    /// @param orderInfos OrderInfo to fill
    /// @param takerFillAmount total taker amount to fill
    /// @param target Address of receiver

    function tryBatchFillOrderTakerAmount(
        OrderInfo[] calldata orderInfos,
        uint256 takerFillAmount,
        address target
    )
        external;

    /// @dev batch fills orders until the makerFillAmount is swapped
    /// @dev skip the order if it fails
    /// @param orderInfos OrderInfo to fill
    /// @param makerFillAmount total maker amount to fill
    /// @param target Address of receiver
    function tryBatchFillOrderMakerAmount(
        OrderInfo[] calldata orderInfos,
        uint256 makerFillAmount,
        address target
    )
        external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

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
    function uniswapV3SwapCallback(int256 amount0Delta, int256 amount1Delta, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";

/// @title IWETH
/// @notice An interface for WETH IERC20
interface IWETH is IERC20 {
    function deposit() external payable;
    function withdraw(uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

/// @title IErrors
/// @notice Common interface for errors
interface IErrors {
    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    /// @notice Emitted when the returned amount is less than the minimum amount
    error InsufficientReturnAmount();

    /// @notice Emitted when the specified toAmount is less than the minimum amount (2)
    error InvalidToAmount();

    /// @notice Emmited when the srcToken and destToken are the same
    error ArbitrageNotSupported();
}