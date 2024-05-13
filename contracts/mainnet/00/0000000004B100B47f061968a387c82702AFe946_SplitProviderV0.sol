// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/introspection/ERC165.sol)

pragma solidity ^0.8.20;

import {IERC165} from "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/introspection/IERC165.sol)

pragma solidity ^0.8.20;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: LGPL-3.0-only
// Created By: Art Blocks Inc. to support the 0xSplits V2 integration
// Sourced from:
//  - https://github.com/0xSplits/splits-contracts-monorepo/blob/main/packages/splits-v2/src/libraries/SplitV2.sol
//  - https://github.com/0xSplits/splits-contracts-monorepo/blob/main/packages/splits-v2/src/splitters/SplitFactoryV2.sol

pragma solidity 0.8.22;

interface ISplitFactoryV2 {
    /* -------------------------------------------------------------------------- */
    /*                                   STRUCTS                                  */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Split struct
     * @dev This struct is used to store the split information.
     * @dev There are no hard caps on the number of recipients/totalAllocation/allocation unit. Thus the chain and its
     * gas limits will dictate these hard caps. Please double check if the split you are creating can be distributed on
     * the chain.
     * @param recipients The recipients of the split.
     * @param allocations The allocations of the split.
     * @param totalAllocation The total allocation of the split.
     * @param distributionIncentive The incentive for distribution. Limits max incentive to 6.5%.
     */
    struct Split {
        address[] recipients;
        uint256[] allocations;
        uint256 totalAllocation;
        uint16 distributionIncentive;
    }

    /* -------------------------------------------------------------------------- */
    /*                                 FUNCTIONS                                  */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Create a new split with params and owner.
     * @param _splitParams Params to create split with.
     * @param _owner Owner of created split.
     * @param _creator Creator of created split.
     * @param _salt Salt for create2.
     * @return split Address of the created split.
     */
    function createSplitDeterministic(
        Split calldata _splitParams,
        address _owner,
        address _creator,
        bytes32 _salt
    ) external returns (address split);

    /**
     * @notice Predict the address of a new split and check if it is deployed.
     * @param _splitParams Params to create split with.
     * @param _owner Owner of created split.
     * @param _salt Salt for create2.
     */
    function isDeployed(
        Split calldata _splitParams,
        address _owner,
        bytes32 _salt
    ) external view returns (address split, bool exists);
}

// SPDX-License-Identifier: LGPL-3.0-only
// Creatd By: Art Blocks Inc.

pragma solidity ^0.8.0;

import {ISplitFactoryV2} from "./integration-refs/splits-0x-v2/ISplitFactoryV2.sol";

interface ISplitProviderV0 {
    /**
     * @notice SplitInputs struct defines the inputs for requested splitters.
     * It is defined in a way easily communicated from the Art Blocks GenArt721V3 contract,
     * to allow for easy integration and minimal additional bytecode in the GenArt721V3 contract.
     */
    struct SplitInputs {
        address platformProviderSecondarySalesAddress;
        uint16 platformProviderSecondarySalesBPS;
        address renderProviderSecondarySalesAddress;
        uint16 renderProviderSecondarySalesBPS;
        uint8 artistTotalRoyaltyPercentage;
        address artist;
        address additionalPayee;
        uint8 additionalPayeePercentage;
    }

    /**
     * @notice Emitted when a new splitter contract is created.
     * @param splitter address of the splitter contract
     */
    event SplitterCreated(address indexed splitter);

    /**
     * @notice Gets or creates an immutable splitter contract at a deterministic address.
     * Splits in the splitter contract are determined by the input split parameters,
     * so we can safely create the splitter contract at a deterministic address (or use
     * the existing splitter contract if it already exists at that address).
     * @dev Uses the 0xSplits v2 implementation to create a splitter contract
     * @param splitInputs The split input parameters.
     * @return splitter The newly created splitter contract address.
     */
    function getOrCreateSplitter(
        SplitInputs calldata splitInputs
    ) external returns (address);

    /**
     * @notice Indicates the type of the contract, e.g. `SplitProviderV0`.
     * @return type_ The type of the contract.
     */
    function type_() external pure returns (bytes32);
}

// SPDX-License-Identifier: LGPL-3.0-only
// Created By: Art Blocks Inc.

pragma solidity 0.8.22;

import {ISplitProviderV0} from "../../interfaces/v0.8.x/ISplitProviderV0.sol";
import {ISplitFactoryV2} from "../../interfaces/v0.8.x/integration-refs/splits-0x-v2/ISplitFactoryV2.sol";

import {ERC165} from "@openzeppelin-5.0/contracts/utils/introspection/ERC165.sol";

/**
 * @title SplitProviderV0
 * @author Art Blocks Inc.
 * @notice Split Provider to get or create immutable split contracts.
 * This version of SplitProvider integrates with 0xSplits v2 to provide
 * immutable split contracts.
 * This contract is permissionless and does not have an owner. It is intended
 * to be used by other contracts to create immutable split contracts, while
 * adding a layer of abstraction to reduce the complexity of interacting with
 * 0xSplits v2 directly, as well as to enable future migration paths to new
 * upgrades.
 * ----------------------------------------------------------------------------
 * All split contracts will be created with the following properties:
 * - The split contract will be immutable.
 * - The split contract will be created with the provided split parameters.
 * - The split contract includes zero distribution incentive.
 * - The split contract will be created at a deterministic address, given the
 *   input split parameters and contract calling this contract (as well as the
 *   third party 0xSplits SplitFactoryV2 address).
 */
contract SplitProviderV0 is ISplitProviderV0, ERC165 {
    bytes32 private constant _TYPE = "SplitProviderV0";

    // 0xSplits SplitFactoryV2 address immutably configured on this contract
    ISplitFactoryV2 private immutable _splitFactoryV2;

    /**
     * @notice Construct a new SplitProviderV0 contract.
     * @param splitFactoryV2Address The immutable 0xSplits SplitFactoryV2 address.
     */
    constructor(ISplitFactoryV2 splitFactoryV2Address) {
        _splitFactoryV2 = ISplitFactoryV2(splitFactoryV2Address);
    }

    /**
     * @notice Gets or creates an immutable splitter contract at a deterministic address.
     * Splits in the splitter contract are determined by the input split parameters,
     * so we can safely create the splitter contract at a deterministic address (or use
     * the existing splitter contract if it already exists at that address).
     * Returns null address if no royalties are due.
     * @dev Uses the 0xSplits v2 implementation to create a splitter contract
     * @dev Intentionally unpermissioned; no owner required; all created splits
     * are immutable and deterministic
     * @param splitInputs The split input parameters.
     * @return splitter The newly created splitter contract address.
     */
    function getOrCreateSplitter(
        SplitInputs calldata splitInputs
    ) external override returns (address) {
        // edge case: no royalties due; return zero address
        if (
            splitInputs.artistTotalRoyaltyPercentage +
                splitInputs.renderProviderSecondarySalesBPS +
                splitInputs.platformProviderSecondarySalesBPS ==
            0
        ) {
            return address(0);
        }
        // create Split struct from SplitInputs
        ISplitFactoryV2.Split memory splitParams = _getSplitParams({
            splitInputs: splitInputs
        });
        // use sender as salt to ensure unique splitters across contracts/partners for accounting
        bytes32 salt = bytes32(bytes20(msg.sender));
        // determine if splitter already exists
        (address splitter, bool exists) = _splitFactoryV2.isDeployed({
            _splitParams: splitParams,
            _owner: address(0), // no owner, immutable,
            _salt: salt
        });
        if (!exists) {
            // create new splitter contract
            // @dev no need to re-assign returned address; isDeployed already populated it
            _splitFactoryV2.createSplitDeterministic({
                _splitParams: splitParams,
                _owner: address(0), // no owner, immutable
                _creator: address(this),
                _salt: salt
            });

            // emit event for new splitter creation
            emit SplitterCreated({splitter: splitter});
        }

        return splitter;
    }

    /**
     * @notice Get the immutable 0xSplits SplitFactoryV2 address used by this SplitProviderV0.
     * @return splitFactoryV2 The 0xSplits SplitFactoryV2 address.
     */
    function getSplitFactoryV2() external view returns (ISplitFactoryV2) {
        return _splitFactoryV2;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view override returns (bool) {
        // broadcast support of the getOrCreateSplitter function
        // @dev intentionally only including getOrCreateSplitter, as that is the only function
        // that is intended to be used for on-chain integration (type_ is for indexing and introspection only)
        return
            interfaceId == this.getOrCreateSplitter.selector ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @notice Indicates the type of the contract, e.g. `SplitProviderV0`.
     * @return type_ The type of the contract.
     */
    function type_() external pure returns (bytes32) {
        return _TYPE;
    }

    /**
     * Converts the split inputs to the split parameters used by 0xSplits V2.
     * This function assumes there is at least one party with a non-zero allocation,
     * and should not be called if there are no royalties due.
     * @param splitInputs The split input parameters.
     * @return splitParams The split parameters in the form used by 0xSplits V2.
     */
    function _getSplitParams(
        SplitInputs calldata splitInputs
    ) private pure returns (ISplitFactoryV2.Split memory splitParams) {
        // define allocations in BPS to avoid any rounding errors
        uint256 artistAndAdditionalRoyaltyPercentage = splitInputs
            .artistTotalRoyaltyPercentage;
        uint256 artistAndAdditionalRoyaltyBPS = 100 *
            artistAndAdditionalRoyaltyPercentage;
        // load render provider royalty BPS
        uint256 renderProviderRoyaltyBPS = splitInputs
            .renderProviderSecondarySalesBPS;
        // load platform provider royalty BPS
        uint256 platformProviderRoyaltyBPS = splitInputs
            .platformProviderSecondarySalesBPS;

        bool artistNonZero = artistAndAdditionalRoyaltyPercentage > 0 &&
            splitInputs.additionalPayeePercentage < 100;
        bool additionalPayeeNonZero = artistAndAdditionalRoyaltyPercentage >
            0 &&
            splitInputs.additionalPayeePercentage > 0;
        bool renderNonZero = renderProviderRoyaltyBPS > 0;
        bool platformNonZero = platformProviderRoyaltyBPS > 0;

        // allocate memory for splitParams arrays
        uint256 partyLength = (artistNonZero ? 1 : 0) +
            (additionalPayeeNonZero ? 1 : 0) +
            (renderNonZero ? 1 : 0) +
            (platformNonZero ? 1 : 0);
        splitParams.recipients = new address[](partyLength);
        splitParams.allocations = new uint256[](partyLength);
        splitParams.totalAllocation =
            artistAndAdditionalRoyaltyBPS +
            renderProviderRoyaltyBPS +
            platformProviderRoyaltyBPS;

        // populate each party's split
        uint256 currentIndex = 0;
        if (artistNonZero) {
            splitParams.recipients[currentIndex] = splitInputs.artist;
            // @dev percent * 100 converts to BPS
            splitParams.allocations[currentIndex++] =
                artistAndAdditionalRoyaltyPercentage *
                (100 - splitInputs.additionalPayeePercentage);
        }
        if (additionalPayeeNonZero) {
            splitParams.recipients[currentIndex] = splitInputs.additionalPayee;
            // @dev percent * 100 converts to BPS
            splitParams.allocations[currentIndex++] =
                artistAndAdditionalRoyaltyPercentage *
                splitInputs.additionalPayeePercentage;
        }
        if (renderNonZero) {
            splitParams.recipients[currentIndex] = splitInputs
                .renderProviderSecondarySalesAddress;
            splitParams.allocations[currentIndex++] = renderProviderRoyaltyBPS;
        }
        if (platformNonZero) {
            splitParams.recipients[currentIndex] = splitInputs
                .platformProviderSecondarySalesAddress;
            splitParams.allocations[
                currentIndex // no need to increment, last element
            ] = platformProviderRoyaltyBPS;
        }

        // @dev leave distribution incentive as zero on all splits
    }
}