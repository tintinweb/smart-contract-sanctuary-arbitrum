// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// Copied from OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity 0.8.18;

import "@openzeppelin/contracts/utils/Context.sol";

import {LibTerm} from "../libraries/LibTerm.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that starts a new term. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyTermOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract TermOwnable is Context {
    event TermOwnershipTransferred(address indexed previousTermOwner, address indexed newTermOwner);

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyTermOwner(uint termId) {
        _checkTermOwner(termId);
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function _termOwner(uint termId) internal view virtual returns (address) {
        return LibTerm._termStorage().terms[termId].termOwner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkTermOwner(uint termId) internal view virtual {
        require(_termOwner(termId) == _msgSender(), "TermOwnable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyTermOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function _renounceTermOwnership(uint termId) internal virtual onlyTermOwner(termId) {
        _transferTermOwnership(termId, address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    // function transferTermOwnership(
    //     uint termId,
    //     address newTermOwner
    // ) internal virtual onlyTermOwner(termId) {
    //     require(newTermOwner != address(0), "Ownable: new owner is the zero address");
    //     _transferTermOwnership(termId, newTermOwner);
    // }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferTermOwnership(
        uint termId,
        address newTermOwner
    ) internal virtual onlyTermOwner(termId) {
        require(newTermOwner != address(0), "Ownable: new owner is the zero address");
        LibTerm.Term storage term = LibTerm._termStorage().terms[termId];
        address oldOwner = term.termOwner;
        term.termOwner = newTermOwner;
        emit TermOwnershipTransferred(oldOwner, newTermOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

library LibTerm {
    uint public constant TERM_VERSION = 1;
    bytes32 constant TERM_CONSTS_POSITION = keccak256("diamond.standard.term.consts");
    bytes32 constant TERM_STORAGE_POSITION = keccak256("diamond.standard.term.storage");

    struct TermConsts {
        uint sequencerStartupTime;
        address sequencerUptimeFeedAddress;
    }

    struct Term {
        bool initialized;
        address termOwner;
        uint creationTime;
        uint termId;
        uint totalParticipants; // Max number of participants
        uint cycleTime; // Time for single cycle (seconds)
        uint contributionAmount; // Amount user must pay per cycle (USD)
        uint contributionPeriod; // The portion of cycle user must make payment
        uint fixedCollateralEth;
        address stableTokenAddress;
        address aggregatorAddress;
    }

    struct TermStorage {
        uint nextTermId;
        mapping(uint => Term) terms; // termId => Term struct
    }

    function _termExists(uint termId) internal view returns (bool) {
        return _termStorage().terms[termId].initialized;
    }

    function _termConsts() internal pure returns (TermConsts storage termConsts) {
        bytes32 position = TERM_CONSTS_POSITION;
        assembly {
            termConsts.slot := position
        }
    }

    function _termStorage() internal pure returns (TermStorage storage termStorage) {
        bytes32 position = TERM_STORAGE_POSITION;
        assembly {
            termStorage.slot := position
        }
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.18;

import {IYGFacetZaynFi} from "../interfaces/IYGFacetZaynFi.sol";
import {IZaynZapV2TakaDAO} from "../interfaces/IZaynZapV2TakaDAO.sol";

import {LibYieldGeneration} from "../libraries/LibYieldGeneration.sol";
import {LibCollateralV2} from "../libraries/LibCollateralV2.sol";
import {LibDiamond} from "hardhat-deploy/solc_0.8/diamond/libraries/LibDiamond.sol";

import {TermOwnable} from "../../version-1/access/TermOwnable.sol";

contract YGFacetZaynFi is IYGFacetZaynFi, TermOwnable {
    event OnYGOptInToggled(uint indexed termId, address indexed participant, bool indexed optedIn); // Emits when a participant succesfully toggles yield generation

    modifier onlyOwner() {
        LibDiamond.enforceIsContractOwner();
        _;
    }

    /// @notice This function is used to deposit collateral for yield generation
    /// @param termId The term id for which the collateral is being deposited
    /// @param ethAmount The amount of collateral being deposited
    function depositYG(uint termId, uint ethAmount) external /*onlyTermOwner(termId)*/ {
        LibYieldGeneration.YieldGeneration storage yield = LibYieldGeneration
            ._yieldStorage()
            .yields[termId];

        yield.totalDeposit = ethAmount;
        yield.currentTotalDeposit = ethAmount;

        IZaynZapV2TakaDAO(yield.zap).zapInEth{value: ethAmount}(yield.vault, termId);
    }

    /// @notice This function is used to withdraw collateral from yield generation
    /// @param termId The term id for which the collateral is being withdrawn
    /// @param user The user who is withdrawing the collateral
    /// @param ethAmount The amount of collateral being withdrawn
    function withdrawYG(
        uint termId,
        address user,
        uint256 ethAmount
    ) external /*onlyTermOwner(termId)*/ {
        LibYieldGeneration.YieldGeneration storage yield = LibYieldGeneration
            ._yieldStorage()
            .yields[termId];

        yield.currentTotalDeposit -= ethAmount;
        yield.withdrawnYield[user] += ethAmount;

        IZaynZapV2TakaDAO(yield.zap).zapOutETH(yield.vault, ethAmount, termId);

        // (bool success, ) = payable(user).call{value: ethAmount}("");
        // require(success);
    }

    function toggleOptInYG(uint termId) external {
        LibYieldGeneration.YieldGeneration storage yield = LibYieldGeneration
            ._yieldStorage()
            .yields[termId];

        LibCollateralV2.Collateral storage collateral = LibCollateralV2
            ._collateralStorage()
            .collaterals[termId];

        require(
            collateral.state == LibCollateralV2.CollateralStates.AcceptingCollateral,
            "Too late to change YG opt in"
        );
        require(collateral.isCollateralMember[msg.sender], "Not part of term");

        bool newDecision = !yield.hasOptedIn[msg.sender];

        yield.hasOptedIn[msg.sender] = newDecision;
        emit OnYGOptInToggled(termId, msg.sender, newDecision);
    }

    function addYieldProviders(address zap, address vault) external onlyOwner {
        LibYieldGeneration.YieldProviders storage yieldProvider = LibYieldGeneration
            ._yieldProviders();

        yieldProvider.zaps.push(zap);
        yieldProvider.vaults.push(vault);
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.18;

import {LibTermV2} from "../libraries/LibTermV2.sol";

interface IYGFacetZaynFi {
    function depositYG(uint termId, uint amount) external;

    function withdrawYG(uint termId, address user, uint256 ethAmount) external;

    function toggleOptInYG(uint termId) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.5;

interface IZaynZapV2TakaDAO {
    function zapInEth(address vault, uint256 termID) external payable;

    function zapOutETH(address vault, uint256 _shares, uint256 termID) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

library LibCollateralV2 {
    uint public constant COLLATERAL_VERSION = 1;
    bytes32 constant COLLATERAL_STORAGE_POSITION = keccak256("diamond.standard.collateral.storage");

    enum CollateralStates {
        AcceptingCollateral, // Initial state where collateral are deposited
        CycleOngoing, // Triggered when a fund instance is created, no collateral can be accepted
        ReleasingCollateral, // Triggered when the fund closes
        Closed // Triggered when all depositors withdraw their collaterals
    }

    struct Collateral {
        bool initialized;
        CollateralStates state;
        uint firstDepositTime;
        uint counterMembers;
        address[] depositors;
        mapping(address => bool) isCollateralMember; // Determines if a depositor is a valid user
        mapping(address => uint) collateralMembersBank; // Users main balance
        mapping(address => uint) collateralPaymentBank; // Users reimbursement balance after someone defaults
        mapping(address => uint) collateralDepositByUser; // Depends on the depositors index
    }

    struct CollateralStorage {
        mapping(uint => Collateral) collaterals; // termId => Collateral struct
    }

    function _collateralExists(uint termId) internal view returns (bool) {
        return _collateralStorage().collaterals[termId].initialized;
    }

    function _collateralStorage()
        internal
        pure
        returns (CollateralStorage storage collateralStorage)
    {
        bytes32 position = COLLATERAL_STORAGE_POSITION;
        assembly {
            collateralStorage.slot := position
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

library LibTermV2 {
    uint public constant TERM_VERSION = 2;
    bytes32 constant TERM_CONSTS_POSITION = keccak256("diamond.standard.term.consts");
    bytes32 constant TERM_STORAGE_POSITION = keccak256("diamond.standard.term.storage");

    struct TermConsts {
        uint sequencerStartupTime;
        address sequencerUptimeFeedAddress;
        mapping(string => address) aggregatorsAddresses; // "ETH/USD" => address , "USD/USDC" => address
    }

    struct Term {
        bool initialized;
        bool expired;
        address termOwner;
        uint creationTime;
        uint termId;
        uint registrationPeriod; // Time for registration (seconds)
        uint totalParticipants; // Max number of participants
        uint cycleTime; // Time for single cycle (seconds)
        uint contributionAmount; // Amount user must pay per cycle (USD)
        uint contributionPeriod; // The portion of cycle user must make payment
        address stableTokenAddress;
    }

    struct TermStorage {
        uint nextTermId;
        mapping(uint => Term) terms; // termId => Term struct
        mapping(address => uint[]) participantToTermId; // userAddress => [termId1, termId2, ...]
    }

    function _termExists(uint termId) internal view returns (bool) {
        return _termStorage().terms[termId].initialized;
    }

    function _termConsts() internal pure returns (TermConsts storage termConsts) {
        bytes32 position = TERM_CONSTS_POSITION;
        assembly {
            termConsts.slot := position
        }
    }

    function _termStorage() internal pure returns (TermStorage storage termStorage) {
        bytes32 position = TERM_STORAGE_POSITION;
        assembly {
            termStorage.slot := position
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

library LibYieldGeneration {
    uint public constant YIELD_GENERATION_VERSION = 1;
    bytes32 constant YIELD_PROVIDERS_POSITION = keccak256("diamond.standard.yield.providers");
    bytes32 constant YIELD_STORAGE_POSITION = keccak256("diamond.standard.yield.storage");

    enum YGProviders {
        InHouse,
        ZaynFi
    }

    // Both index 0 are reserved for ZaynFi
    struct YieldProviders {
        address[] zaps;
        address[] vaults;
    }

    struct YieldGeneration {
        bool initialized;
        YGProviders provider;
        uint startTimeStamp;
        uint totalDeposit;
        uint currentTotalDeposit;
        address zap;
        address vault;
        address[] yieldUsers;
        mapping(address => bool) hasOptedIn;
        mapping(address => uint256) withdrawnYield;
        mapping(address => uint256) withdrawnCollateral;
    }

    struct YieldStorage {
        mapping(uint => YieldGeneration) yields; // termId => YieldGeneration struct
    }

    function _yieldExists(uint termId) internal view returns (bool) {
        return _yieldStorage().yields[termId].initialized;
    }

    function _yieldProviders() internal pure returns (YieldProviders storage yieldProviders) {
        bytes32 position = YIELD_PROVIDERS_POSITION;
        assembly {
            yieldProviders.slot := position
        }
    }

    function _yieldStorage() internal pure returns (YieldStorage storage yieldStorage) {
        bytes32 position = YIELD_STORAGE_POSITION;
        assembly {
            yieldStorage.slot := position
        }
    }
}

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/
import { IDiamondCut } from "../interfaces/IDiamondCut.sol";

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
}