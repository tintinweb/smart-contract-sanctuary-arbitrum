// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { Ownable } from "@solidstate/contracts/access/ownable/Ownable.sol";
import { ERC165Base } from "@solidstate/contracts/introspection/ERC165/base/ERC165Base.sol";
import { Pausable } from "@solidstate/contracts/security/pausable/Pausable.sol";
import { ERC1155Base } from "@solidstate/contracts/token/ERC1155/base/ERC1155Base.sol";
import { ERC1155Metadata } from "@solidstate/contracts/token/ERC1155/metadata/ERC1155Metadata.sol";

import { ERC1155MetadataExtension } from "./ERC1155MetadataExtension.sol";
import { IPerpetualMint } from "./IPerpetualMint.sol";
import { PerpetualMintInternal } from "./PerpetualMintInternal.sol";
import { PerpetualMintStorage as Storage, TiersData, VRFConfig } from "./Storage.sol";

/// @title PerpetualMint facet contract
/// @dev contains all externally called functions
contract PerpetualMint is
    ERC1155Base,
    ERC1155Metadata,
    ERC165Base,
    IPerpetualMint,
    Ownable,
    Pausable,
    ERC1155MetadataExtension,
    PerpetualMintInternal
{
    constructor(address vrf) PerpetualMintInternal(vrf) {}

    /// @inheritdoc IPerpetualMint
    function accruedConsolationFees()
        external
        view
        returns (uint256 accruedFees)
    {
        accruedFees = _accruedConsolationFees();
    }

    /// @inheritdoc IPerpetualMint
    function accruedMintEarnings()
        external
        view
        returns (uint256 accruedEarnings)
    {
        accruedEarnings = _accruedMintEarnings();
    }

    /// @inheritdoc IPerpetualMint
    function accruedProtocolFees() external view returns (uint256 accruedFees) {
        accruedFees = _accruedProtocolFees();
    }

    /// @inheritdoc IPerpetualMint
    function attemptBatchMintWithEth(
        address collection,
        uint32 numberOfMints
    ) external payable whenNotPaused {
        _attemptBatchMintWithEth(msg.sender, collection, numberOfMints);
    }

    /// @inheritdoc IPerpetualMint
    function attemptBatchMintWithMint(
        address collection,
        uint32 numberOfMints
    ) external whenNotPaused {
        _attemptBatchMintWithMint(msg.sender, collection, numberOfMints);
    }

    /// @inheritdoc IPerpetualMint
    function BASIS() external pure returns (uint32 value) {
        value = _BASIS();
    }

    /// @inheritdoc IPerpetualMint
    function burnReceipt(uint256 tokenId) external onlyOwner {
        _burnReceipt(tokenId);
    }

    /// @inheritdoc IPerpetualMint
    function cancelClaim(address claimer, uint256 tokenId) external onlyOwner {
        _cancelClaim(claimer, tokenId);
    }

    /// @inheritdoc IPerpetualMint
    function claimMintEarnings() external onlyOwner {
        _claimMintEarnings(msg.sender);
    }

    /// @inheritdoc IPerpetualMint
    function claimPrize(address prizeRecipient, uint256 tokenId) external {
        _claimPrize(msg.sender, prizeRecipient, tokenId);
    }

    /// @inheritdoc IPerpetualMint
    function claimProtocolFees() external onlyOwner {
        _claimProtocolFees(msg.sender);
    }

    /// @inheritdoc IPerpetualMint
    function collectionMintPrice(
        address collection
    ) external view returns (uint256 mintPrice) {
        mintPrice = _collectionMintPrice(
            Storage.layout().collections[collection]
        );
    }

    /// @inheritdoc IPerpetualMint
    function collectionPriceToMintRatioBP()
        external
        view
        returns (uint32 collectionPriceToMintRatioBasisPoints)
    {
        collectionPriceToMintRatioBasisPoints = _collectionPriceToMintRatioBP();
    }

    /// @inheritdoc IPerpetualMint
    function collectionRisk(
        address collection
    ) external view returns (uint32 risk) {
        risk = _collectionRisk(Storage.layout().collections[collection]);
    }

    /// @inheritdoc IPerpetualMint
    function consolationFeeBP()
        external
        view
        returns (uint32 consolationFeeBasisPoints)
    {
        consolationFeeBasisPoints = _consolationFeeBP();
    }

    /// @inheritdoc IPerpetualMint
    function defaultCollectionMintPrice()
        external
        pure
        returns (uint256 mintPrice)
    {
        mintPrice = _defaultCollectionMintPrice();
    }

    /// @inheritdoc IPerpetualMint
    function defaultCollectionRisk() external pure returns (uint32 risk) {
        risk = _defaultCollectionRisk();
    }

    /// @inheritdoc IPerpetualMint
    function defaultEthToMintRatio() external pure returns (uint32 ratio) {
        ratio = _defaultEthToMintRatio();
    }

    /// @inheritdoc IPerpetualMint
    function ethToMintRatio() external view returns (uint256 ratio) {
        ratio = _ethToMintRatio(Storage.layout());
    }

    /// @inheritdoc IPerpetualMint
    function mintFeeBP() external view returns (uint32 mintFeeBasisPoints) {
        mintFeeBasisPoints = _mintFeeBP();
    }

    /// @inheritdoc IPerpetualMint
    function mintToken() external view returns (address token) {
        token = _mintToken();
    }

    /// @inheritdoc IPerpetualMint
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    /// @inheritdoc IPerpetualMint
    function pause() external onlyOwner {
        _pause();
    }

    /// @inheritdoc IPerpetualMint
    function redeem(uint256 amount) external {
        _redeem(msg.sender, amount);
    }

    /// @inheritdoc IPerpetualMint
    function redemptionFeeBP() external view returns (uint32 feeBP) {
        feeBP = _redemptionFeeBP();
    }

    /// @inheritdoc IPerpetualMint
    function setCollectionMintPrice(
        address collection,
        uint256 price
    ) external onlyOwner {
        _setCollectionMintPrice(collection, price);
    }

    /// @inheritdoc IPerpetualMint
    function setCollectionPriceToMintRatioBP(
        uint32 _collectionPriceToMintRatioBP
    ) external onlyOwner {
        _setCollectionPriceToMintRatioBP(_collectionPriceToMintRatioBP);
    }

    /// @inheritdoc IPerpetualMint
    function setCollectionRisk(
        address collection,
        uint32 risk
    ) external onlyOwner {
        _setCollectionRisk(collection, risk);
    }

    /// @inheritdoc IPerpetualMint
    function setConsolationFeeBP(uint32 _consolationFeeBP) external onlyOwner {
        _setConsolationFeeBP(_consolationFeeBP);
    }

    /// @inheritdoc IPerpetualMint
    function setEthToMintRatio(uint256 ratio) external onlyOwner {
        _setEthToMintRatio(ratio);
    }

    /// @inheritdoc IPerpetualMint
    function setMintFeeBP(uint32 _mintFeeBP) external onlyOwner {
        _setMintFeeBP(_mintFeeBP);
    }

    /// @inheritdoc IPerpetualMint
    function setMintToken(address _mintToken) external onlyOwner {
        _setMintToken(_mintToken);
    }

    /// @inheritdoc IPerpetualMint
    function setReceiptBaseURI(string calldata baseURI) external onlyOwner {
        _setBaseURI(baseURI);
    }

    /// @inheritdoc IPerpetualMint
    function setReceiptTokenURI(
        uint256 tokenId,
        string calldata tokenURI
    ) external onlyOwner {
        _setTokenURI(tokenId, tokenURI);
    }

    /// @inheritdoc IPerpetualMint
    function setRedemptionFeeBP(uint32 _redemptionFeeBP) external onlyOwner {
        _setRedemptionFeeBP(_redemptionFeeBP);
    }

    /// @inheritdoc IPerpetualMint
    function setTiers(TiersData calldata tiersData) external onlyOwner {
        _setTiers(tiersData);
    }

    /// @inheritdoc IPerpetualMint
    function setVRFConfig(VRFConfig calldata config) external onlyOwner {
        _setVRFConfig(config);
    }

    /// @inheritdoc IPerpetualMint
    function tiers() external view returns (TiersData memory tiersData) {
        tiersData = _tiers();
    }

    /// @inheritdoc IPerpetualMint
    function unpause() external onlyOwner {
        _unpause();
    }

    /// @inheritdoc IPerpetualMint
    function vrfConfig() external view returns (VRFConfig memory config) {
        config = _vrfConfig();
    }

    /// @notice Chainlink VRF Coordinator callback
    /// @param requestId id of request for random values
    /// @param randomWords random values returned from Chainlink VRF coordination
    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal override {
        _fulfillRandomWords(requestId, randomWords);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC173 } from '../../interfaces/IERC173.sol';
import { IOwnable } from './IOwnable.sol';
import { OwnableInternal } from './OwnableInternal.sol';

/**
 * @title Ownership access control based on ERC173
 */
abstract contract Ownable is IOwnable, OwnableInternal {
    /**
     * @inheritdoc IERC173
     */
    function owner() public view virtual returns (address) {
        return _owner();
    }

    /**
     * @inheritdoc IERC173
     */
    function transferOwnership(address account) public virtual onlyOwner {
        _transferOwnership(account);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC165 } from '../../../interfaces/IERC165.sol';
import { IERC165Base } from './IERC165Base.sol';
import { ERC165BaseInternal } from './ERC165BaseInternal.sol';
import { ERC165BaseStorage } from './ERC165BaseStorage.sol';

/**
 * @title ERC165 implementation
 */
abstract contract ERC165Base is IERC165Base, ERC165BaseInternal {
    /**
     * @inheritdoc IERC165
     */
    function supportsInterface(bytes4 interfaceId) public view returns (bool) {
        return _supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IPausable } from './IPausable.sol';
import { PausableInternal } from './PausableInternal.sol';

/**
 * @title Pausable security control module.
 */
abstract contract Pausable is IPausable, PausableInternal {
    /**
     * @inheritdoc IPausable
     */
    function paused() external view virtual returns (bool status) {
        status = _paused();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC1155 } from '../../../interfaces/IERC1155.sol';
import { IERC1155Receiver } from '../../../interfaces/IERC1155Receiver.sol';
import { IERC1155Base } from './IERC1155Base.sol';
import { ERC1155BaseInternal, ERC1155BaseStorage } from './ERC1155BaseInternal.sol';

/**
 * @title Base ERC1155 contract
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts/ (MIT license)
 * @dev inheritor must either implement ERC165 supportsInterface or inherit ERC165Base
 */
abstract contract ERC1155Base is IERC1155Base, ERC1155BaseInternal {
    /**
     * @inheritdoc IERC1155
     */
    function balanceOf(
        address account,
        uint256 id
    ) public view virtual returns (uint256) {
        return _balanceOf(account, id);
    }

    /**
     * @inheritdoc IERC1155
     */
    function balanceOfBatch(
        address[] memory accounts,
        uint256[] memory ids
    ) public view virtual returns (uint256[] memory) {
        if (accounts.length != ids.length)
            revert ERC1155Base__ArrayLengthMismatch();

        mapping(uint256 => mapping(address => uint256))
            storage balances = ERC1155BaseStorage.layout().balances;

        uint256[] memory batchBalances = new uint256[](accounts.length);

        unchecked {
            for (uint256 i; i < accounts.length; i++) {
                if (accounts[i] == address(0))
                    revert ERC1155Base__BalanceQueryZeroAddress();
                batchBalances[i] = balances[ids[i]][accounts[i]];
            }
        }

        return batchBalances;
    }

    /**
     * @inheritdoc IERC1155
     */
    function isApprovedForAll(
        address account,
        address operator
    ) public view virtual returns (bool) {
        return ERC1155BaseStorage.layout().operatorApprovals[account][operator];
    }

    /**
     * @inheritdoc IERC1155
     */
    function setApprovalForAll(address operator, bool status) public virtual {
        if (msg.sender == operator) revert ERC1155Base__SelfApproval();
        ERC1155BaseStorage.layout().operatorApprovals[msg.sender][
            operator
        ] = status;
        emit ApprovalForAll(msg.sender, operator, status);
    }

    /**
     * @inheritdoc IERC1155
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual {
        if (from != msg.sender && !isApprovedForAll(from, msg.sender))
            revert ERC1155Base__NotOwnerOrApproved();
        _safeTransfer(msg.sender, from, to, id, amount, data);
    }

    /**
     * @inheritdoc IERC1155
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual {
        if (from != msg.sender && !isApprovedForAll(from, msg.sender))
            revert ERC1155Base__NotOwnerOrApproved();
        _safeTransferBatch(msg.sender, from, to, ids, amounts, data);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { UintUtils } from '../../../utils/UintUtils.sol';
import { IERC1155Metadata } from './IERC1155Metadata.sol';
import { ERC1155MetadataInternal } from './ERC1155MetadataInternal.sol';
import { ERC1155MetadataStorage } from './ERC1155MetadataStorage.sol';

/**
 * @title ERC1155 metadata extensions
 */
abstract contract ERC1155Metadata is IERC1155Metadata, ERC1155MetadataInternal {
    using UintUtils for uint256;

    /**
     * @notice inheritdoc IERC1155Metadata
     */
    function uri(uint256 tokenId) public view virtual returns (string memory) {
        ERC1155MetadataStorage.Layout storage l = ERC1155MetadataStorage
            .layout();

        string memory tokenIdURI = l.tokenURIs[tokenId];
        string memory baseURI = l.baseURI;

        if (bytes(baseURI).length == 0) {
            return tokenIdURI;
        } else if (bytes(tokenIdURI).length > 0) {
            return string(abi.encodePacked(baseURI, tokenIdURI));
        } else {
            return string(abi.encodePacked(baseURI, tokenId.toString()));
        }
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { ERC1155MetadataExtensionInternal } from "./ERC1155MetadataExtensionInternal.sol";
import { IERC1155MetadataExtension } from "./IERC1155MetadataExtension.sol";

/// @title ERC1155MetadataExtension
/// @dev ERC1155MetadataExtension contract
abstract contract ERC1155MetadataExtension is
    ERC1155MetadataExtensionInternal,
    IERC1155MetadataExtension
{
    /// @inheritdoc IERC1155MetadataExtension
    function name() external view virtual returns (string memory) {
        return _name();
    }

    /// @inheritdoc IERC1155MetadataExtension
    function symbol() external view virtual returns (string memory) {
        return _symbol();
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { IOwnable } from "@solidstate/contracts/access/ownable/IOwnable.sol";
import { IERC165Base } from "@solidstate/contracts/introspection/ERC165/base/IERC165Base.sol";
import { IPausable } from "@solidstate/contracts/security/pausable/IPausable.sol";
import { IERC1155Base } from "@solidstate/contracts/token/ERC1155/base/IERC1155Base.sol";
import { IERC1155Metadata } from "@solidstate/contracts/token/ERC1155/metadata/IERC1155Metadata.sol";

import { IERC1155MetadataExtension } from "./IERC1155MetadataExtension.sol";
import { IPerpetualMintInternal } from "./IPerpetualMintInternal.sol";
import { PerpetualMintStorage as Storage, TiersData, VRFConfig } from "./Storage.sol";

/// @title IPerpetualMint
/// @dev Interface of the PerpetualMint facet
interface IPerpetualMint is
    IERC1155Base,
    IERC1155Metadata,
    IERC165Base,
    IOwnable,
    IPerpetualMintInternal,
    IPausable,
    IERC1155MetadataExtension
{
    /// @notice Returns the current accrued consolation fees
    /// @return accruedFees the current amount of accrued consolation fees
    function accruedConsolationFees()
        external
        view
        returns (uint256 accruedFees);

    /// @notice returns the current accrued mint earnings across all collections
    /// @return accruedEarnings the current amount of accrued mint earnings across all collections
    function accruedMintEarnings()
        external
        view
        returns (uint256 accruedEarnings);

    /// @notice returns the current accrued protocol fees
    /// @return accruedFees the current amount of accrued protocol fees
    function accruedProtocolFees() external view returns (uint256 accruedFees);

    /// @notice Attempts a batch mint for the msg.sender for a single collection using ETH as payment.
    /// @param collection address of collection for mint attempts
    /// @param numberOfMints number of mints to attempt
    function attemptBatchMintWithEth(
        address collection,
        uint32 numberOfMints
    ) external payable;

    /// @notice Attempts a batch mint for the msg.sender for a single collection using $MINT tokens as payment.
    /// @param collection address of collection for mint attempts
    /// @param numberOfMints number of mints to attempt
    function attemptBatchMintWithMint(
        address collection,
        uint32 numberOfMints
    ) external;

    /// @notice returns the value of BASIS
    /// @return value BASIS value
    function BASIS() external pure returns (uint32 value);

    /// @notice burns a receipt after a claim request is fulfilled
    /// @param tokenId id of receipt to burn
    function burnReceipt(uint256 tokenId) external;

    /// @notice Cancels a claim for a given claimer for given token ID
    /// @param claimer address of rejected claimer
    /// @param tokenId token ID of rejected claim
    function cancelClaim(address claimer, uint256 tokenId) external;

    /// @notice claims all accrued mint earnings across collections
    function claimMintEarnings() external;

    /// @notice Initiates a claim for a prize for a given collection
    /// @param prizeRecipient address of intended prize recipient
    /// @param tokenId token ID of prize, which is the prize collection address encoded as uint256
    function claimPrize(address prizeRecipient, uint256 tokenId) external;

    /// @notice claims all accrued protocol fees
    function claimProtocolFees() external;

    /// @notice Returns the current mint price for a collection
    /// @param collection address of collection
    /// @return mintPrice current collection mint price
    function collectionMintPrice(
        address collection
    ) external view returns (uint256 mintPrice);

    /// @notice Returns the current collection price to $MINT ratio in basis points
    /// @return collectionPriceToMintRatioBasisPoints collection price to $MINT ratio in basis points
    function collectionPriceToMintRatioBP()
        external
        view
        returns (uint32 collectionPriceToMintRatioBasisPoints);

    /// @notice Returns the current collection-wide risk of a collection
    /// @param collection address of collection
    /// @return risk value of collection-wide risk
    function collectionRisk(
        address collection
    ) external view returns (uint32 risk);

    /// @notice Returns the consolation fee in basis points
    /// @return consolationFeeBasisPoints consolation fee in basis points
    function consolationFeeBP()
        external
        view
        returns (uint32 consolationFeeBasisPoints);

    /// @notice Returns the default mint price for a collection
    /// @return mintPrice default collection mint price
    function defaultCollectionMintPrice()
        external
        pure
        returns (uint256 mintPrice);

    /// @notice Returns the default risk for a collection
    /// @return risk default collection risk
    function defaultCollectionRisk() external pure returns (uint32 risk);

    /// @notice Returns the default ETH to $MINT ratio
    /// @return ratio default ETH to $MINT ratio
    function defaultEthToMintRatio() external pure returns (uint32 ratio);

    /// @notice Returns the current ETH to $MINT ratio
    /// @return ratio current ETH to $MINT ratio
    function ethToMintRatio() external view returns (uint256 ratio);

    /// @notice Returns the mint fee in basis points
    /// @return mintFeeBasisPoints mint fee in basis points
    function mintFeeBP() external view returns (uint32 mintFeeBasisPoints);

    /// @notice Returns the address of the current $MINT token
    /// @return token address of the current $MINT token
    function mintToken() external view returns (address token);

    /// @notice Validates receipt of an ERC1155 transfer.
    /// @param operator Executor of transfer.
    /// @param from Sender of tokens.
    /// @param id Token ID received.
    /// @param value Quantity of tokens received.
    /// @param data Data payload.
    /// @return bytes4 Function's own selector if transfer is accepted.
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external pure returns (bytes4);

    /// @notice Triggers paused state, when contract is unpaused.
    function pause() external;

    /// @notice redeems an amount of $MINT tokens for ETH (native token) for the msg.sender
    /// @param amount amount of $MINT
    function redeem(uint256 amount) external;

    /// @notice returns the current redemption fee in basis points
    /// @return feeBP redemptionFee in basis points
    function redemptionFeeBP() external view returns (uint32 feeBP);

    /// @notice set the mint price for a given collection
    /// @param collection address of collection
    /// @param price mint price of the collection
    function setCollectionMintPrice(address collection, uint256 price) external;

    /// @notice sets the ratio of collection price to $MINT in basis points for mint consolations
    /// @param collectionPriceToMintRatioBP collection price to $MINT ratio in basis points
    function setCollectionPriceToMintRatioBP(
        uint32 collectionPriceToMintRatioBP
    ) external;

    /// @notice sets the risk of a given collection
    /// @param collection address of collection
    /// @param risk new risk value for collection
    function setCollectionRisk(address collection, uint32 risk) external;

    /// @notice sets the consolation fee in basis points
    /// @param consolationFeeBP consolation fee in basis points
    function setConsolationFeeBP(uint32 consolationFeeBP) external;

    /// @notice sets the ratio of ETH (native token) to $MINT for mint attempts using $MINT as payment
    /// @param ratio ratio of ETH to $MINT
    function setEthToMintRatio(uint256 ratio) external;

    /// @notice sets the mint fee in basis points
    /// @param mintFeeBP mint fee in basis points
    function setMintFeeBP(uint32 mintFeeBP) external;

    /// @notice sets the address of the mint consolation token
    /// @param mintToken address of the mint consolation token
    function setMintToken(address mintToken) external;

    /// @notice sets the baseURI for the ERC1155 token receipts
    /// @param baseURI URI string
    function setReceiptBaseURI(string calldata baseURI) external;

    /// @notice sets the tokenURI for ERC1155 token receipts
    /// @param tokenId token ID, which is the collection address encoded as uint256
    /// @param tokenURI URI string
    function setReceiptTokenURI(
        uint256 tokenId,
        string calldata tokenURI
    ) external;

    /// @notice sets the redemption fee in basis points
    /// @param _redemptionFeeBP redemption fee in basis points
    function setRedemptionFeeBP(uint32 _redemptionFeeBP) external;

    /// @notice sets the $MINT consolation tiers
    /// @param tiersData TiersData struct holding all related data to $MINT consolation tiers
    function setTiers(TiersData calldata tiersData) external;

    /// @notice sets the Chainlink VRF config
    /// @param config VRFConfig struct holding all related data to ChainlinkVRF setup
    function setVRFConfig(VRFConfig calldata config) external;

    /// @notice Returns the current $MINT consolation tiers
    function tiers() external view returns (TiersData memory tiersData);

    ///  @notice Triggers unpaused state, when contract is paused.
    function unpause() external;

    /// @notice returns the current VRF config
    /// @return config VRFConfig struct
    function vrfConfig() external view returns (VRFConfig memory config);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { VRFCoordinatorV2Interface } from "@chainlink/interfaces/VRFCoordinatorV2Interface.sol";
import { VRFConsumerBaseV2 } from "@chainlink/vrf/VRFConsumerBaseV2.sol";
import { EnumerableSet } from "@solidstate/contracts/data/EnumerableSet.sol";
import { ERC1155BaseInternal } from "@solidstate/contracts/token/ERC1155/base/ERC1155BaseInternal.sol";
import { AddressUtils } from "@solidstate/contracts/utils/AddressUtils.sol";

import { ERC1155MetadataExtensionInternal } from "./ERC1155MetadataExtensionInternal.sol";
import { IPerpetualMintInternal } from "./IPerpetualMintInternal.sol";
import { CollectionData, PerpetualMintStorage as Storage, RequestData, TiersData, VRFConfig } from "./Storage.sol";
import { IToken } from "../Token/IToken.sol";
import { GuardsInternal } from "../../common/GuardsInternal.sol";

/// @title PerpetualMintInternal facet contract
/// @dev defines modularly all logic for the PerpetualMint mechanism in internal functions
abstract contract PerpetualMintInternal is
    ERC1155BaseInternal,
    ERC1155MetadataExtensionInternal,
    GuardsInternal,
    IPerpetualMintInternal,
    VRFConsumerBaseV2
{
    using AddressUtils for address payable;
    using EnumerableSet for EnumerableSet.UintSet;

    /// @dev denominator used in percentage calculations
    uint32 private constant BASIS = 1000000000;

    /// @dev default mint price for a collection
    uint64 internal constant DEFAULT_COLLECTION_MINT_PRICE = 0.01 ether;

    /// @dev default risk for a collection
    uint32 internal constant DEFAULT_COLLECTION_RISK = 1000000; // 0.1%

    // Starting default conversion ratio: 1 ETH = 1,000,000 $MINT
    uint32 internal constant DEFAULT_ETH_TO_MINT_RATIO = 1000000;

    /// @dev address of Chainlink VRFCoordinatorV2 contract
    address private immutable VRF;

    constructor(address vrfCoordinator) VRFConsumerBaseV2(vrfCoordinator) {
        VRF = vrfCoordinator;
    }

    /// @notice returns the current accrued consolation fees
    /// @return accruedFees the current amount of accrued consolation fees
    function _accruedConsolationFees()
        internal
        view
        returns (uint256 accruedFees)
    {
        accruedFees = Storage.layout().consolationFees;
    }

    /// @notice returns the current accrued mint earnings across all collections
    /// @return accruedMintEarnings the current amount of accrued mint earnings across all collections
    function _accruedMintEarnings()
        internal
        view
        returns (uint256 accruedMintEarnings)
    {
        accruedMintEarnings = Storage.layout().mintEarnings;
    }

    /// @notice returns the current accrued protocol fees
    /// @return accruedFees the current amount of accrued protocol fees
    function _accruedProtocolFees()
        internal
        view
        returns (uint256 accruedFees)
    {
        accruedFees = Storage.layout().protocolFees;
    }

    /// @notice Attempts a batch mint for the msg.sender for a single collection using ETH as payment.
    /// @param minter address of minter
    /// @param collection address of collection for mint attempts
    /// @param numberOfMints number of mints to attempt
    function _attemptBatchMintWithEth(
        address minter,
        address collection,
        uint32 numberOfMints
    ) internal {
        Storage.Layout storage l = Storage.layout();

        uint256 msgValue = msg.value;

        if (numberOfMints == 0) {
            revert InvalidNumberOfMints();
        }

        CollectionData storage collectionData = l.collections[collection];

        uint256 collectionMintPrice = _collectionMintPrice(collectionData);

        if (msgValue != collectionMintPrice * numberOfMints) {
            revert IncorrectETHReceived();
        }

        // calculate the consolation fee
        uint256 consolationFee = (msgValue * l.consolationFeeBP) / BASIS;

        // calculate the protocol mint fee
        uint256 mintFee = (msgValue * l.mintFeeBP) / BASIS;

        // update the accrued consolation fees
        l.consolationFees += consolationFee;

        // update the accrued depositor mint earnings
        l.mintEarnings += msgValue - consolationFee - mintFee;

        // update the accrued protocol fees
        l.protocolFees += mintFee;

        // if the number of words requested is greater than the max allowed by the VRF coordinator,
        // the request for random words will fail (max random words is currently 500 per request).
        uint32 numWords = numberOfMints * 2; // 2 words per mint, current max of 250 mints per tx

        _requestRandomWords(l, collectionData, minter, collection, numWords);
    }

    /// @notice Attempts a batch mint for the msg.sender for a single collection using $MINT tokens as payment.
    /// @param minter address of minter
    /// @param collection address of collection for mint attempts
    /// @param numberOfMints number of mints to attempt
    function _attemptBatchMintWithMint(
        address minter,
        address collection,
        uint32 numberOfMints
    ) internal {
        Storage.Layout storage l = Storage.layout();

        if (numberOfMints == 0) {
            revert InvalidNumberOfMints();
        }

        CollectionData storage collectionData = l.collections[collection];

        uint256 collectionMintPrice = _collectionMintPrice(collectionData);
        uint256 ethToMintRatio = _ethToMintRatio(l);

        uint256 ethRequired = collectionMintPrice * numberOfMints;

        if (ethRequired > l.consolationFees) {
            revert InsufficientConsolationFees();
        }

        // calculate amount of $MINT required
        uint256 mintRequired = ethRequired * ethToMintRatio;

        IToken(l.mintToken).burn(minter, mintRequired);

        // calculate the consolation fee
        uint256 consolationFee = (ethRequired * l.consolationFeeBP) / BASIS;

        // calculate the protocol mint fee
        uint256 mintFee = (ethRequired * l.mintFeeBP) / BASIS;

        // update the accrued consolation fees
        // ETH required for mint taken from consolationFees
        l.consolationFees -= ethRequired - consolationFee;

        // update the accrued depositor mint earnings
        l.mintEarnings += ethRequired - consolationFee - mintFee;

        // update the accrued protocol fees
        l.protocolFees += mintFee;

        // if the number of words requested is greater than the max allowed by the VRF coordinator,
        // the request for random words will fail (max random words is currently 500 per request).
        uint32 numWords = numberOfMints * 2; // 2 words per mint, current max of 250 mints per tx

        _requestRandomWords(l, collectionData, minter, collection, numWords);
    }

    /// @notice returns the value of BASIS
    /// @return value BASIS value
    function _BASIS() internal pure returns (uint32 value) {
        value = BASIS;
    }

    /// @notice burns a receipt after a claim request is fulfilled
    /// @param tokenId id of receipt to burn
    function _burnReceipt(uint256 tokenId) internal {
        _burn(address(this), tokenId, 1);
    }

    /// @notice Cancels a claim for a given claimer for given token ID
    /// @param claimer address of rejected claimer
    /// @param tokenId token ID of rejected claim
    function _cancelClaim(address claimer, uint256 tokenId) internal {
        _safeTransfer(address(this), address(this), claimer, tokenId, 1, "");

        emit ClaimCancelled(
            claimer,
            address(uint160(tokenId)) // decode tokenId to get collection address
        );
    }

    /// @notice claims all accrued mint earnings across collections
    /// @param recipient address of mint earnings recipient
    function _claimMintEarnings(address recipient) internal {
        Storage.Layout storage l = Storage.layout();

        uint256 mintEarnings = l.mintEarnings;
        l.mintEarnings = 0;

        payable(recipient).sendValue(mintEarnings);
    }

    /// @notice Initiates a claim for a prize for a given collection
    /// @param claimer address of claimer
    /// @param prizeRecipient address of intended prize recipient
    /// @param tokenId token ID of prize, which is the prize collection address encoded as uint256
    function _claimPrize(
        address claimer,
        address prizeRecipient,
        uint256 tokenId
    ) internal {
        _safeTransfer(msg.sender, claimer, address(this), tokenId, 1, "");

        emit PrizeClaimed(
            claimer,
            prizeRecipient,
            address(uint160(tokenId)) // decode tokenId to get collection address
        );
    }

    /// @notice claims all accrued protocol fees
    /// @param recipient address of protocol fees recipient
    function _claimProtocolFees(address recipient) internal {
        Storage.Layout storage l = Storage.layout();

        uint256 protocolFees = l.protocolFees;
        l.protocolFees = 0;

        payable(recipient).sendValue(protocolFees);
    }

    /// @notice Returns the current mint price for a given collection
    /// @param collectionData the CollectionData struct for a given collection
    /// @return mintPrice current collection mint price
    function _collectionMintPrice(
        CollectionData storage collectionData
    ) internal view returns (uint256 mintPrice) {
        mintPrice = collectionData.mintPrice;

        mintPrice = mintPrice == 0 ? DEFAULT_COLLECTION_MINT_PRICE : mintPrice;
    }

    /// @notice Returns the current collection price to $MINT ratio in basis points
    /// @return collectionPriceToMintRatioBasisPoints collection price to $MINT ratio in basis points
    function _collectionPriceToMintRatioBP()
        internal
        view
        returns (uint32 collectionPriceToMintRatioBasisPoints)
    {
        collectionPriceToMintRatioBasisPoints = Storage
            .layout()
            .collectionPriceToMintRatioBP;
    }

    /// @notice Returns the current collection-wide risk of a collection
    /// @param collectionData the CollectionData struct for a given collection
    /// @return risk value of collection-wide risk
    function _collectionRisk(
        CollectionData storage collectionData
    ) internal view returns (uint32 risk) {
        risk = collectionData.risk;

        risk = risk == 0 ? DEFAULT_COLLECTION_RISK : risk;
    }

    /// @notice Returns the current consolation fee in basis points
    /// @return consolationFeeBasisPoints consolation fee in basis points
    function _consolationFeeBP()
        internal
        view
        returns (uint32 consolationFeeBasisPoints)
    {
        consolationFeeBasisPoints = Storage.layout().consolationFeeBP;
    }

    /// @notice Returns the default mint price for a collection
    /// @return mintPrice default collection mint price
    function _defaultCollectionMintPrice()
        internal
        pure
        returns (uint256 mintPrice)
    {
        mintPrice = DEFAULT_COLLECTION_MINT_PRICE;
    }

    /// @notice Returns the default risk for a collection
    /// @return risk default collection risk
    function _defaultCollectionRisk() internal pure returns (uint32 risk) {
        risk = DEFAULT_COLLECTION_RISK;
    }

    /// @notice Returns the default ETH to $MINT ratio
    /// @return ratio default ETH to $MINT ratio
    function _defaultEthToMintRatio() internal pure returns (uint32 ratio) {
        ratio = DEFAULT_ETH_TO_MINT_RATIO;
    }

    /// @dev enforces that there are no pending mint requests for a collection
    /// @param collectionData the CollectionData struct for a given collection
    function _enforceNoPendingMints(
        CollectionData storage collectionData
    ) internal view {
        if (collectionData.pendingRequests.length() != 0) {
            revert PendingRequests();
        }
    }

    /// @notice Returns the current ETH to $MINT ratio
    /// @param l the PerpetualMint storage layout
    /// @return ratio current ETH to $MINT ratio
    function _ethToMintRatio(
        Storage.Layout storage l
    ) internal view returns (uint256 ratio) {
        ratio = l.ethToMintRatio;

        ratio = ratio == 0 ? DEFAULT_ETH_TO_MINT_RATIO : ratio;
    }

    /// @notice internal Chainlink VRF callback
    /// @notice is executed by the ChainlinkVRF Coordinator contract
    /// @param requestId id of chainlinkVRF request
    /// @param randomWords random values return by ChainlinkVRF Coordinator
    function _fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal virtual {
        Storage.Layout storage l = Storage.layout();

        RequestData storage request = l.requests[requestId];

        address collection = request.collection;
        address minter = request.minter;

        CollectionData storage collectionData = l.collections[collection];

        _resolveMints(
            l.mintToken,
            collectionData,
            l.tiers,
            minter,
            collection,
            randomWords,
            l.collectionPriceToMintRatioBP
        );

        collectionData.pendingRequests.remove(requestId);

        delete l.requests[requestId];
    }

    /// @notice Returns the current mint fee in basis points
    /// @return mintFeeBasisPoints mint fee in basis points
    function _mintFeeBP() internal view returns (uint32 mintFeeBasisPoints) {
        mintFeeBasisPoints = Storage.layout().mintFeeBP;
    }

    /// @notice Returns the address of the current $MINT token
    /// @return mintToken address of the current $MINT token
    function _mintToken() internal view returns (address mintToken) {
        mintToken = Storage.layout().mintToken;
    }

    /// @notice ensures a value is within the BASIS range
    /// @param value value to normalize
    /// @return normalizedValue value after normalization
    function _normalizeValue(
        uint256 value,
        uint32 basis
    ) internal pure returns (uint256 normalizedValue) {
        normalizedValue = value % basis;
    }

    /// @notice redeems an amount of $MINT tokens for ETH (native token) for an account
    /// @dev only one-sided ($MINT => ETH (native token)) supported
    /// @param account address of account
    /// @param amount amount of $MINT
    function _redeem(address account, uint256 amount) internal {
        Storage.Layout storage l = Storage.layout();

        // burn amount of $MINT to be swapped
        IToken(l.mintToken).burn(account, amount);

        // calculate amount of ETH given for $MINT amount
        uint256 ethAmount = (amount * (BASIS - l.redemptionFeeBP)) /
            (BASIS * _ethToMintRatio(l));

        if (ethAmount > l.consolationFees) {
            revert InsufficientConsolationFees();
        }

        // decrease consolationFees
        l.consolationFees -= ethAmount;

        payable(account).sendValue(ethAmount);
    }

    /// @notice returns the current redemption fee in basis points
    /// @return feeBP redemptionFee in basis points
    function _redemptionFeeBP() internal view returns (uint32 feeBP) {
        feeBP = Storage.layout().redemptionFeeBP;
    }

    /// @notice requests random values from Chainlink VRF
    /// @param l the PerpetualMint storage layout
    /// @param collectionData the CollectionData struct for a given collection
    /// @param minter address calling this function
    /// @param collection address of collection to attempt mint for
    /// @param numWords amount of random values to request
    function _requestRandomWords(
        Storage.Layout storage l,
        CollectionData storage collectionData,
        address minter,
        address collection,
        uint32 numWords
    ) internal {
        uint256 requestId = VRFCoordinatorV2Interface(VRF).requestRandomWords(
            l.vrfConfig.keyHash,
            l.vrfConfig.subscriptionId,
            l.vrfConfig.minConfirmations,
            l.vrfConfig.callbackGasLimit,
            numWords
        );

        collectionData.pendingRequests.add(requestId);

        RequestData storage request = l.requests[requestId];

        request.collection = collection;
        request.minter = minter;
    }

    /// @notice resolves the outcomes of attempted mints for a given collection
    /// @param mintToken address of $MINT token
    /// @param collectionData the CollectionData struct for a given collection
    /// @param tiersData the TiersData struct for mint consolations
    /// @param minter address of minter
    /// @param collection address of collection for mint attempts
    /// @param randomWords array of random values relating to number of attempts
    /// @param collectionPriceToMintRatioBP collection price to $MINT ratio in basis points
    function _resolveMints(
        address mintToken,
        CollectionData storage collectionData,
        TiersData memory tiersData,
        address minter,
        address collection,
        uint256[] memory randomWords,
        uint32 collectionPriceToMintRatioBP
    ) internal {
        // ensure the number of random words is even
        // each valid mint attempt requires two random words
        if (randomWords.length % 2 != 0) {
            revert UnmatchedRandomWords();
        }

        uint256 totalMintAmount;
        uint256 totalReceiptAmount;

        for (uint256 i = 0; i < randomWords.length; i += 2) {
            // first random word is used to determine whether the mint attempt was successful
            uint256 firstNormalizedValue = _normalizeValue(
                randomWords[i],
                BASIS
            );

            // second random word is used to determine the consolation tier
            uint256 secondNormalizedValue = _normalizeValue(
                randomWords[i + 1],
                BASIS
            );

            // if the first normalized value is less than the collection risk, the mint attempt is unsuccessful
            // and the second normalized value is used to determine the consolation tier
            if (!(_collectionRisk(collectionData) > firstNormalizedValue)) {
                uint256 tierMintAmount;
                uint256 cumulativeRisk;

                // iterate through tiers to find the tier that the random value falls into
                for (uint256 j = 0; j < tiersData.tierRisks.length; ++j) {
                    cumulativeRisk += tiersData.tierRisks[j];

                    // if the cumulative risk is greater than the second normalized value, the tier has been found
                    if (cumulativeRisk > secondNormalizedValue) {
                        tierMintAmount =
                            (tiersData.tierMultipliers[j] *
                                collectionPriceToMintRatioBP *
                                _collectionMintPrice(collectionData)) /
                            BASIS;
                        break;
                    }
                }

                totalMintAmount += tierMintAmount;
            } else {
                // mint attempt is successful, so the total receipt amount is incremented
                ++totalReceiptAmount;
            }
        }

        // Mint the cumulative amounts at the end
        if (totalMintAmount > 0) {
            IToken(mintToken).mint(minter, totalMintAmount);
        }

        if (totalReceiptAmount > 0) {
            _safeMint(
                minter,
                uint256(bytes32(abi.encode(collection))), // encode collection address as tokenId
                totalReceiptAmount,
                ""
            );
        }

        emit MintResult(
            minter,
            collection,
            randomWords.length / 2,
            totalMintAmount,
            totalReceiptAmount
        );
    }

    /// @notice set the mint price for a given collection
    /// @param collection address of collection
    /// @param price mint price of the collection
    function _setCollectionMintPrice(
        address collection,
        uint256 price
    ) internal {
        Storage.layout().collections[collection].mintPrice = price;

        emit MintPriceSet(collection, price);
    }

    /// @notice sets the ratio of collection price to $MINT in basis points for mint consolations
    /// @param collectionPriceToMintRatioBP new ratio of collection price to $MINT in basis points
    function _setCollectionPriceToMintRatioBP(
        uint32 collectionPriceToMintRatioBP
    ) internal {
        Storage
            .layout()
            .collectionPriceToMintRatioBP = collectionPriceToMintRatioBP;

        emit CollectionPriceToMintRatioSet(collectionPriceToMintRatioBP);
    }

    /// @notice sets the risk for a given collection
    /// @param collection address of collection
    /// @param risk risk of the collection
    function _setCollectionRisk(address collection, uint32 risk) internal {
        CollectionData storage collectionData = Storage.layout().collections[
            collection
        ];

        _enforceBasis(risk, BASIS);

        _enforceNoPendingMints(collectionData);

        collectionData.risk = risk;

        emit CollectionRiskSet(collection, risk);
    }

    /// @notice sets the consolation fee in basis points
    /// @param consolationFeeBP consolation fee in basis points
    function _setConsolationFeeBP(uint32 consolationFeeBP) internal {
        _enforceBasis(consolationFeeBP, BASIS);

        Storage.layout().consolationFeeBP = consolationFeeBP;

        emit ConsolationFeeSet(consolationFeeBP);
    }

    /// @notice sets the ratio of ETH (native token) to $MINT for mint attempts using $MINT as payment
    /// @param ratio new ratio of ETH to $MINT
    function _setEthToMintRatio(uint256 ratio) internal {
        Storage.layout().ethToMintRatio = ratio;

        emit EthToMintRatioSet(ratio);
    }

    /// @notice sets the mint fee in basis points
    /// @param mintFeeBP mint fee in basis points
    function _setMintFeeBP(uint32 mintFeeBP) internal {
        _enforceBasis(mintFeeBP, BASIS);

        Storage.layout().mintFeeBP = mintFeeBP;

        emit MintFeeSet(mintFeeBP);
    }

    /// @notice sets the address of the mint consolation token
    /// @param mintToken address of the mint consolation token
    function _setMintToken(address mintToken) internal {
        Storage.layout().mintToken = mintToken;

        emit MintTokenSet(mintToken);
    }

    /// @notice sets the redemption fee in basis points
    /// @param redemptionFeeBP redemption fee in basis points
    function _setRedemptionFeeBP(uint32 redemptionFeeBP) internal {
        _enforceBasis(redemptionFeeBP, BASIS);

        Storage.layout().redemptionFeeBP = redemptionFeeBP;

        emit RedemptionFeeSet(redemptionFeeBP);
    }

    /// @notice sets the $MINT consolation tiers data
    /// @param tiersData TiersData struct holding all related data to $MINT consolations
    function _setTiers(TiersData calldata tiersData) internal {
        Storage.layout().tiers = tiersData;

        emit TiersSet(tiersData);
    }

    /// @notice sets the Chainlink VRF config
    /// @param config VRFConfig struct holding all related data to ChainlinkVRF
    function _setVRFConfig(VRFConfig calldata config) internal {
        Storage.layout().vrfConfig = config;

        emit VRFConfigSet(config);
    }

    function _tiers() internal view returns (TiersData memory tiersData) {
        tiersData = Storage.layout().tiers;
    }

    /// @notice Returns the current Chainlink VRF config
    /// @return config VRFConfig struct
    function _vrfConfig() internal view returns (VRFConfig memory config) {
        config = Storage.layout().vrfConfig;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import "./types/DataTypes.sol";

/// @title PerpetualMintStorage
/// @dev defines storage layout for the PerpetualMint facet
library PerpetualMintStorage {
    struct Layout {
        /// @dev $MINT consolation tiers data
        TiersData tiers;
        /// @dev all variables related to Chainlink VRF configuration
        VRFConfig vrfConfig;
        /// @dev collection price to $MINT ratio in basis points
        uint32 collectionPriceToMintRatioBP;
        /// @dev consolation fee in basis points
        uint32 consolationFeeBP;
        /// @dev mint fee in basis points
        uint32 mintFeeBP;
        /// @dev redemption fee in basis points
        uint32 redemptionFeeBP;
        /// @dev amount of consolation fees accrued in ETH (native token) from mint attempts
        uint256 consolationFees;
        /// @dev amount of mint earnings accrued in ETH (native token) from mint attempts
        uint256 mintEarnings;
        /// @dev amount of protocol fees accrued in ETH (native token) from mint attempts
        uint256 protocolFees;
        /// @dev ratio of ETH (native token) to $MINT for mint attempts using $MINT as payment
        uint256 ethToMintRatio;
        /// @dev mapping of collection addresses to collection-specific data
        mapping(address collection => CollectionData) collections;
        /// @dev mapping of mint attempt VRF requests which have not yet been fulfilled
        mapping(uint256 requestId => RequestData) requests;
        /// @dev address of the current $MINT token
        address mintToken;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256("insrt.contracts.storage.PerpetualMint");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC173Internal } from './IERC173Internal.sol';

/**
 * @title Contract ownership standard interface
 * @dev see https://eips.ethereum.org/EIPS/eip-173
 */
interface IERC173 is IERC173Internal {
    /**
     * @notice get the ERC173 contract owner
     * @return contract owner
     */
    function owner() external view returns (address);

    /**
     * @notice transfer contract ownership to new account
     * @param account address of new owner
     */
    function transferOwnership(address account) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC173 } from '../../interfaces/IERC173.sol';
import { IOwnableInternal } from './IOwnableInternal.sol';

interface IOwnable is IOwnableInternal, IERC173 {}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC173 } from '../../interfaces/IERC173.sol';
import { AddressUtils } from '../../utils/AddressUtils.sol';
import { IOwnableInternal } from './IOwnableInternal.sol';
import { OwnableStorage } from './OwnableStorage.sol';

abstract contract OwnableInternal is IOwnableInternal {
    using AddressUtils for address;

    modifier onlyOwner() {
        if (msg.sender != _owner()) revert Ownable__NotOwner();
        _;
    }

    modifier onlyTransitiveOwner() {
        if (msg.sender != _transitiveOwner())
            revert Ownable__NotTransitiveOwner();
        _;
    }

    function _owner() internal view virtual returns (address) {
        return OwnableStorage.layout().owner;
    }

    function _transitiveOwner() internal view virtual returns (address owner) {
        owner = _owner();

        while (owner.isContract()) {
            try IERC173(owner).owner() returns (address transitiveOwner) {
                owner = transitiveOwner;
            } catch {
                break;
            }
        }
    }

    function _transferOwnership(address account) internal virtual {
        _setOwner(account);
    }

    function _setOwner(address account) internal virtual {
        OwnableStorage.Layout storage l = OwnableStorage.layout();
        emit OwnershipTransferred(l.owner, account);
        l.owner = account;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC165Internal } from './IERC165Internal.sol';

/**
 * @title ERC165 interface registration interface
 * @dev see https://eips.ethereum.org/EIPS/eip-165
 */
interface IERC165 is IERC165Internal {
    /**
     * @notice query whether contract has registered support for given interface
     * @param interfaceId interface id
     * @return bool whether interface is supported
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC165 } from '../../../interfaces/IERC165.sol';
import { IERC165BaseInternal } from './IERC165BaseInternal.sol';

interface IERC165Base is IERC165, IERC165BaseInternal {}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC165BaseInternal } from './IERC165BaseInternal.sol';
import { ERC165BaseStorage } from './ERC165BaseStorage.sol';

/**
 * @title ERC165 implementation
 */
abstract contract ERC165BaseInternal is IERC165BaseInternal {
    /**
     * @notice indicates whether an interface is already supported based on the interfaceId
     * @param interfaceId id of interface to check
     * @return bool indicating whether interface is supported
     */
    function _supportsInterface(
        bytes4 interfaceId
    ) internal view virtual returns (bool) {
        return ERC165BaseStorage.layout().supportedInterfaces[interfaceId];
    }

    /**
     * @notice sets status of interface support
     * @param interfaceId id of interface to set status for
     * @param status boolean indicating whether interface will be set as supported
     */
    function _setSupportsInterface(
        bytes4 interfaceId,
        bool status
    ) internal virtual {
        if (interfaceId == 0xffffffff) revert ERC165Base__InvalidInterfaceId();
        ERC165BaseStorage.layout().supportedInterfaces[interfaceId] = status;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

library ERC165BaseStorage {
    struct Layout {
        mapping(bytes4 => bool) supportedInterfaces;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.ERC165Base');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IPausableInternal } from './IPausableInternal.sol';

interface IPausable is IPausableInternal {
    /**
     * @notice query whether contract is paused
     * @return status whether contract is paused
     */
    function paused() external view returns (bool status);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IPausableInternal } from './IPausableInternal.sol';
import { PausableStorage } from './PausableStorage.sol';

/**
 * @title Internal functions for Pausable security control module.
 */
abstract contract PausableInternal is IPausableInternal {
    modifier whenNotPaused() {
        if (_paused()) revert Pausable__Paused();
        _;
    }

    modifier whenPaused() {
        if (!_paused()) revert Pausable__NotPaused();
        _;
    }

    /**
     * @notice query whether contract is paused
     * @return status whether contract is paused
     */
    function _paused() internal view virtual returns (bool status) {
        status = PausableStorage.layout().paused;
    }

    /**
     * @notice Triggers paused state, when contract is unpaused.
     */
    function _pause() internal virtual whenNotPaused {
        PausableStorage.layout().paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @notice Triggers unpaused state, when contract is paused.
     */
    function _unpause() internal virtual whenPaused {
        delete PausableStorage.layout().paused;
        emit Unpaused(msg.sender);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC165 } from './IERC165.sol';
import { IERC1155Internal } from './IERC1155Internal.sol';

/**
 * @title ERC1155 interface
 * @dev see https://eips.ethereum.org/EIPS/eip-1155
 */
interface IERC1155 is IERC1155Internal, IERC165 {
    /**
     * @notice query the balance of given token held by given address
     * @param account address to query
     * @param id token to query
     * @return token balance
     */
    function balanceOf(
        address account,
        uint256 id
    ) external view returns (uint256);

    /**
     * @notice query the balances of given tokens held by given addresses
     * @param accounts addresss to query
     * @param ids tokens to query
     * @return token balances
     */
    function balanceOfBatch(
        address[] calldata accounts,
        uint256[] calldata ids
    ) external view returns (uint256[] memory);

    /**
     * @notice query approval status of given operator with respect to given address
     * @param account address to query for approval granted
     * @param operator address to query for approval received
     * @return whether operator is approved to spend tokens held by account
     */
    function isApprovedForAll(
        address account,
        address operator
    ) external view returns (bool);

    /**
     * @notice grant approval to or revoke approval from given operator to spend held tokens
     * @param operator address whose approval status to update
     * @param status whether operator should be considered approved
     */
    function setApprovalForAll(address operator, bool status) external;

    /**
     * @notice transfer tokens between given addresses, checking for ERC1155Receiver implementation if applicable
     * @param from sender of tokens
     * @param to receiver of tokens
     * @param id token ID
     * @param amount quantity of tokens to transfer
     * @param data data payload
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @notice transfer batch of tokens between given addresses, checking for ERC1155Receiver implementation if applicable
     * @param from sender of tokens
     * @param to receiver of tokens
     * @param ids list of token IDs
     * @param amounts list of quantities of tokens to transfer
     * @param data data payload
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC165 } from './IERC165.sol';

/**
 * @title ERC1155 transfer receiver interface
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @notice validate receipt of ERC1155 transfer
     * @param operator executor of transfer
     * @param from sender of tokens
     * @param id token ID received
     * @param value quantity of tokens received
     * @param data data payload
     * @return function's own selector if transfer is accepted
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @notice validate receipt of ERC1155 batch transfer
     * @param operator executor of transfer
     * @param from sender of tokens
     * @param ids token IDs received
     * @param values quantities of tokens received
     * @param data data payload
     * @return function's own selector if transfer is accepted
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC1155 } from '../../../interfaces/IERC1155.sol';
import { IERC1155BaseInternal } from './IERC1155BaseInternal.sol';

/**
 * @title ERC1155 base interface
 */
interface IERC1155Base is IERC1155BaseInternal, IERC1155 {

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC1155Receiver } from '../../../interfaces/IERC1155Receiver.sol';
import { AddressUtils } from '../../../utils/AddressUtils.sol';
import { IERC1155BaseInternal } from './IERC1155BaseInternal.sol';
import { ERC1155BaseStorage } from './ERC1155BaseStorage.sol';

/**
 * @title Base ERC1155 internal functions
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts/ (MIT license)
 */
abstract contract ERC1155BaseInternal is IERC1155BaseInternal {
    using AddressUtils for address;

    /**
     * @notice query the balance of given token held by given address
     * @param account address to query
     * @param id token to query
     * @return token balance
     */
    function _balanceOf(
        address account,
        uint256 id
    ) internal view virtual returns (uint256) {
        if (account == address(0))
            revert ERC1155Base__BalanceQueryZeroAddress();
        return ERC1155BaseStorage.layout().balances[id][account];
    }

    /**
     * @notice mint given quantity of tokens for given address
     * @dev ERC1155Receiver implementation is not checked
     * @param account beneficiary of minting
     * @param id token ID
     * @param amount quantity of tokens to mint
     * @param data data payload
     */
    function _mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        if (account == address(0)) revert ERC1155Base__MintToZeroAddress();

        _beforeTokenTransfer(
            msg.sender,
            address(0),
            account,
            _asSingletonArray(id),
            _asSingletonArray(amount),
            data
        );

        ERC1155BaseStorage.layout().balances[id][account] += amount;

        emit TransferSingle(msg.sender, address(0), account, id, amount);
    }

    /**
     * @notice mint given quantity of tokens for given address
     * @param account beneficiary of minting
     * @param id token ID
     * @param amount quantity of tokens to mint
     * @param data data payload
     */
    function _safeMint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        _mint(account, id, amount, data);

        _doSafeTransferAcceptanceCheck(
            msg.sender,
            address(0),
            account,
            id,
            amount,
            data
        );
    }

    /**
     * @notice mint batch of tokens for given address
     * @dev ERC1155Receiver implementation is not checked
     * @param account beneficiary of minting
     * @param ids list of token IDs
     * @param amounts list of quantities of tokens to mint
     * @param data data payload
     */
    function _mintBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        if (account == address(0)) revert ERC1155Base__MintToZeroAddress();
        if (ids.length != amounts.length)
            revert ERC1155Base__ArrayLengthMismatch();

        _beforeTokenTransfer(
            msg.sender,
            address(0),
            account,
            ids,
            amounts,
            data
        );

        mapping(uint256 => mapping(address => uint256))
            storage balances = ERC1155BaseStorage.layout().balances;

        for (uint256 i; i < ids.length; ) {
            balances[ids[i]][account] += amounts[i];
            unchecked {
                i++;
            }
        }

        emit TransferBatch(msg.sender, address(0), account, ids, amounts);
    }

    /**
     * @notice mint batch of tokens for given address
     * @param account beneficiary of minting
     * @param ids list of token IDs
     * @param amounts list of quantities of tokens to mint
     * @param data data payload
     */
    function _safeMintBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        _mintBatch(account, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(
            msg.sender,
            address(0),
            account,
            ids,
            amounts,
            data
        );
    }

    /**
     * @notice burn given quantity of tokens held by given address
     * @param account holder of tokens to burn
     * @param id token ID
     * @param amount quantity of tokens to burn
     */
    function _burn(
        address account,
        uint256 id,
        uint256 amount
    ) internal virtual {
        if (account == address(0)) revert ERC1155Base__BurnFromZeroAddress();

        _beforeTokenTransfer(
            msg.sender,
            account,
            address(0),
            _asSingletonArray(id),
            _asSingletonArray(amount),
            ''
        );

        mapping(address => uint256) storage balances = ERC1155BaseStorage
            .layout()
            .balances[id];

        unchecked {
            if (amount > balances[account])
                revert ERC1155Base__BurnExceedsBalance();
            balances[account] -= amount;
        }

        emit TransferSingle(msg.sender, account, address(0), id, amount);
    }

    /**
     * @notice burn given batch of tokens held by given address
     * @param account holder of tokens to burn
     * @param ids token IDs
     * @param amounts quantities of tokens to burn
     */
    function _burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        if (account == address(0)) revert ERC1155Base__BurnFromZeroAddress();
        if (ids.length != amounts.length)
            revert ERC1155Base__ArrayLengthMismatch();

        _beforeTokenTransfer(msg.sender, account, address(0), ids, amounts, '');

        mapping(uint256 => mapping(address => uint256))
            storage balances = ERC1155BaseStorage.layout().balances;

        unchecked {
            for (uint256 i; i < ids.length; i++) {
                uint256 id = ids[i];
                if (amounts[i] > balances[id][account])
                    revert ERC1155Base__BurnExceedsBalance();
                balances[id][account] -= amounts[i];
            }
        }

        emit TransferBatch(msg.sender, account, address(0), ids, amounts);
    }

    /**
     * @notice transfer tokens between given addresses
     * @dev ERC1155Receiver implementation is not checked
     * @param operator executor of transfer
     * @param sender sender of tokens
     * @param recipient receiver of tokens
     * @param id token ID
     * @param amount quantity of tokens to transfer
     * @param data data payload
     */
    function _transfer(
        address operator,
        address sender,
        address recipient,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        if (recipient == address(0))
            revert ERC1155Base__TransferToZeroAddress();

        _beforeTokenTransfer(
            operator,
            sender,
            recipient,
            _asSingletonArray(id),
            _asSingletonArray(amount),
            data
        );

        mapping(uint256 => mapping(address => uint256))
            storage balances = ERC1155BaseStorage.layout().balances;

        unchecked {
            uint256 senderBalance = balances[id][sender];
            if (amount > senderBalance)
                revert ERC1155Base__TransferExceedsBalance();
            balances[id][sender] = senderBalance - amount;
        }

        balances[id][recipient] += amount;

        emit TransferSingle(operator, sender, recipient, id, amount);
    }

    /**
     * @notice transfer tokens between given addresses
     * @param operator executor of transfer
     * @param sender sender of tokens
     * @param recipient receiver of tokens
     * @param id token ID
     * @param amount quantity of tokens to transfer
     * @param data data payload
     */
    function _safeTransfer(
        address operator,
        address sender,
        address recipient,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        _transfer(operator, sender, recipient, id, amount, data);

        _doSafeTransferAcceptanceCheck(
            operator,
            sender,
            recipient,
            id,
            amount,
            data
        );
    }

    /**
     * @notice transfer batch of tokens between given addresses
     * @dev ERC1155Receiver implementation is not checked
     * @param operator executor of transfer
     * @param sender sender of tokens
     * @param recipient receiver of tokens
     * @param ids token IDs
     * @param amounts quantities of tokens to transfer
     * @param data data payload
     */
    function _transferBatch(
        address operator,
        address sender,
        address recipient,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        if (recipient == address(0))
            revert ERC1155Base__TransferToZeroAddress();
        if (ids.length != amounts.length)
            revert ERC1155Base__ArrayLengthMismatch();

        _beforeTokenTransfer(operator, sender, recipient, ids, amounts, data);

        mapping(uint256 => mapping(address => uint256))
            storage balances = ERC1155BaseStorage.layout().balances;

        for (uint256 i; i < ids.length; ) {
            uint256 token = ids[i];
            uint256 amount = amounts[i];

            unchecked {
                uint256 senderBalance = balances[token][sender];

                if (amount > senderBalance)
                    revert ERC1155Base__TransferExceedsBalance();

                balances[token][sender] = senderBalance - amount;

                i++;
            }

            // balance increase cannot be unchecked because ERC1155Base neither tracks nor validates a totalSupply
            balances[token][recipient] += amount;
        }

        emit TransferBatch(operator, sender, recipient, ids, amounts);
    }

    /**
     * @notice transfer batch of tokens between given addresses
     * @param operator executor of transfer
     * @param sender sender of tokens
     * @param recipient receiver of tokens
     * @param ids token IDs
     * @param amounts quantities of tokens to transfer
     * @param data data payload
     */
    function _safeTransferBatch(
        address operator,
        address sender,
        address recipient,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        _transferBatch(operator, sender, recipient, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(
            operator,
            sender,
            recipient,
            ids,
            amounts,
            data
        );
    }

    /**
     * @notice wrap given element in array of length 1
     * @param element element to wrap
     * @return singleton array
     */
    function _asSingletonArray(
        uint256 element
    ) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;
        return array;
    }

    /**
     * @notice revert if applicable transfer recipient is not valid ERC1155Receiver
     * @param operator executor of transfer
     * @param from sender of tokens
     * @param to receiver of tokens
     * @param id token ID
     * @param amount quantity of tokens to transfer
     * @param data data payload
     */
    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try
                IERC1155Receiver(to).onERC1155Received(
                    operator,
                    from,
                    id,
                    amount,
                    data
                )
            returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector)
                    revert ERC1155Base__ERC1155ReceiverRejected();
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert ERC1155Base__ERC1155ReceiverNotImplemented();
            }
        }
    }

    /**
     * @notice revert if applicable transfer recipient is not valid ERC1155Receiver
     * @param operator executor of transfer
     * @param from sender of tokens
     * @param to receiver of tokens
     * @param ids token IDs
     * @param amounts quantities of tokens to transfer
     * @param data data payload
     */
    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try
                IERC1155Receiver(to).onERC1155BatchReceived(
                    operator,
                    from,
                    ids,
                    amounts,
                    data
                )
            returns (bytes4 response) {
                if (
                    response != IERC1155Receiver.onERC1155BatchReceived.selector
                ) revert ERC1155Base__ERC1155ReceiverRejected();
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert ERC1155Base__ERC1155ReceiverNotImplemented();
            }
        }
    }

    /**
     * @notice ERC1155 hook, called before all transfers including mint and burn
     * @dev function should be overridden and new implementation must call super
     * @dev called for both single and batch transfers
     * @param operator executor of transfer
     * @param from sender of tokens
     * @param to receiver of tokens
     * @param ids token IDs
     * @param amounts quantities of tokens to transfer
     * @param data data payload
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title utility functions for uint256 operations
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts/ (MIT license)
 */
library UintUtils {
    error UintUtils__InsufficientHexLength();

    bytes16 private constant HEX_SYMBOLS = '0123456789abcdef';

    function add(uint256 a, int256 b) internal pure returns (uint256) {
        return b < 0 ? sub(a, -b) : a + uint256(b);
    }

    function sub(uint256 a, int256 b) internal pure returns (uint256) {
        return b < 0 ? add(a, -b) : a - uint256(b);
    }

    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return '0';
        }

        uint256 temp = value;
        uint256 digits;

        while (temp != 0) {
            digits++;
            temp /= 10;
        }

        bytes memory buffer = new bytes(digits);

        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }

        return string(buffer);
    }

    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return '0x00';
        }

        uint256 length = 0;

        for (uint256 temp = value; temp != 0; temp >>= 8) {
            unchecked {
                length++;
            }
        }

        return toHexString(value, length);
    }

    function toHexString(
        uint256 value,
        uint256 length
    ) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = '0';
        buffer[1] = 'x';

        unchecked {
            for (uint256 i = 2 * length + 1; i > 1; --i) {
                buffer[i] = HEX_SYMBOLS[value & 0xf];
                value >>= 4;
            }
        }

        if (value != 0) revert UintUtils__InsufficientHexLength();

        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC1155MetadataInternal } from './IERC1155MetadataInternal.sol';

/**
 * @title ERC1155Metadata interface
 */
interface IERC1155Metadata is IERC1155MetadataInternal {
    /**
     * @notice get generated URI for given token
     * @return token URI
     */
    function uri(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC1155MetadataInternal } from './IERC1155MetadataInternal.sol';
import { ERC1155MetadataStorage } from './ERC1155MetadataStorage.sol';

/**
 * @title ERC1155Metadata internal functions
 */
abstract contract ERC1155MetadataInternal is IERC1155MetadataInternal {
    /**
     * @notice set base metadata URI
     * @dev base URI is a non-standard feature adapted from the ERC721 specification
     * @param baseURI base URI
     */
    function _setBaseURI(string memory baseURI) internal {
        ERC1155MetadataStorage.layout().baseURI = baseURI;
    }

    /**
     * @notice set per-token metadata URI
     * @param tokenId token whose metadata URI to set
     * @param tokenURI per-token URI
     */
    function _setTokenURI(uint256 tokenId, string memory tokenURI) internal {
        ERC1155MetadataStorage.layout().tokenURIs[tokenId] = tokenURI;
        emit URI(tokenURI, tokenId);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title ERC1155 metadata extensions
 */
library ERC1155MetadataStorage {
    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.ERC1155Metadata');

    struct Layout {
        string baseURI;
        mapping(uint256 => string) tokenURIs;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { ERC1155MetadataExtensionStorage } from "./ERC1155MetadataExtensionStorage.sol";

/// @title ERC1155MetadataExtensionInternal
/// @dev ERC1155MetadataExtension internal functions
abstract contract ERC1155MetadataExtensionInternal {
    /// @notice reads the ERC1155 collection name
    /// @return name ERC1155 collection name
    function _name() internal view returns (string memory name) {
        name = ERC1155MetadataExtensionStorage.layout().name;
    }

    /// @notice sets a new name for the ERC1155 collection
    /// @param name name to set
    function _setName(string memory name) internal {
        ERC1155MetadataExtensionStorage.layout().name = name;
    }

    /// @notice sets a new symbol for the ERC1155 collection
    /// @param symbol symbol to set
    function _setSymbol(string memory symbol) internal {
        ERC1155MetadataExtensionStorage.layout().symbol = symbol;
    }

    /// @notice reads the ERC1155 collection symbol
    /// @return symbol ERC1155 collection symbol
    function _symbol() internal view returns (string memory symbol) {
        symbol = ERC1155MetadataExtensionStorage.layout().symbol;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

/// @title IERC1155MetadataExtension
/// @dev ERC1155MetadataExtension interface
interface IERC1155MetadataExtension {
    /// @notice reads the ERC1155 collection name
    /// @return name ERC1155 collection name
    function name() external view returns (string memory name);

    /// @notice reads the ERC1155 collection symbol
    /// @return symbol ERC1155 collection symbol
    function symbol() external view returns (string memory symbol);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { PerpetualMintStorage as Storage, VRFConfig, TiersData } from "./Storage.sol";

/// @title IPerpetualMintInternal interface
/// @dev contains all errors and events used in the PerpetualMint facet contract
interface IPerpetualMintInternal {
    /// @notice thrown when an incorrect amount of ETH is received
    error IncorrectETHReceived();

    /// @notice thrown when there are not enough consolation fees accrued to faciliate
    /// minting with $MINT
    error InsufficientConsolationFees();

    /// @notice thrown when attempting to mint 0 tokens
    error InvalidNumberOfMints();

    /// @dev thrown when attempting to update a collection risk and
    /// there are pending mint requests in a collection
    error PendingRequests();

    /// @notice thrown when fulfilled random words do not match for attempted mints
    error UnmatchedRandomWords();

    /// @notice emitted when a claim is cancelled
    /// @param claimer address of rejected claimer
    /// @param collection address of rejected claim collection
    event ClaimCancelled(address claimer, address indexed collection);

    /// @notice emitted when the collection price to $MINT ratio is set
    /// @param collectionPriceToMintRatioBP collection price to $MINT ratio in basis points
    event CollectionPriceToMintRatioSet(uint32 collectionPriceToMintRatioBP);

    /// @notice emitted when the risk for a collection is set
    /// @param collection address of collection
    /// @param risk risk of collection
    event CollectionRiskSet(address collection, uint32 risk);

    /// @notice emitted when the consolation fee is set
    /// @param consolationFeeBP consolation fee in basis points
    event ConsolationFeeSet(uint32 consolationFeeBP);

    /// @notice emitted when the ETH:MINT ratio is set
    /// @param ratio value of ETH:MINT ratio
    event EthToMintRatioSet(uint256 ratio);

    /// @notice emitted when the mint fee is set
    /// @param mintFeeBP mint fee in basis points
    event MintFeeSet(uint32 mintFeeBP);

    /// @notice emitted when the mint price of a collection is set
    /// @param collection address of collection
    /// @param price mint price of collection
    event MintPriceSet(address collection, uint256 price);

    /// @notice emitted when the address of the $MINT token is set
    /// @param mintToken address of mint token
    event MintTokenSet(address mintToken);

    /// @notice emitted when the outcome of an attempted mint is resolved
    /// @param minter address of account attempting the mint
    /// @param collection address of collection that attempted mint is for
    /// @param attempts number of mint attempts
    /// @param totalMintAmount amount of $MINT tokens minted
    /// @param totalReceiptAmount amount of receipts (ERC1155 tokens) minted (successful mint attempts)
    event MintResult(
        address indexed minter,
        address indexed collection,
        uint256 attempts,
        uint256 totalMintAmount,
        uint256 totalReceiptAmount
    );

    /// @notice emitted when a prize is claimed
    /// @param claimer address of claimer
    /// @param prizeRecipient address of specified prize recipient
    /// @param collection address of collection prize
    event PrizeClaimed(
        address claimer,
        address prizeRecipient,
        address indexed collection
    );

    /// @notice emitted when the redemption fee is set
    /// @param redemptionFeeBP redemption fee in basis points
    event RedemptionFeeSet(uint32 redemptionFeeBP);

    /// @notice emitted when the tiers are set
    /// @param tiersData new tiers
    event TiersSet(TiersData tiersData);

    /// @notice emitted when the Chainlink VRF config is set
    /// @param config VRFConfig struct holding all related data to ChainlinkVRF
    event VRFConfigSet(VRFConfig config);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface VRFCoordinatorV2Interface {
  /**
   * @notice Get configuration relevant for making requests
   * @return minimumRequestConfirmations global min for request confirmations
   * @return maxGasLimit global max for request gas limit
   * @return s_provingKeyHashes list of registered key hashes
   */
  function getRequestConfig() external view returns (uint16, uint32, bytes32[] memory);

  /**
   * @notice Request a set of random words.
   * @param keyHash - Corresponds to a particular oracle job which uses
   * that key for generating the VRF proof. Different keyHash's have different gas price
   * ceilings, so you can select a specific one to bound your maximum per request cost.
   * @param subId  - The ID of the VRF subscription. Must be funded
   * with the minimum subscription balance required for the selected keyHash.
   * @param minimumRequestConfirmations - How many blocks you'd like the
   * oracle to wait before responding to the request. See SECURITY CONSIDERATIONS
   * for why you may want to request more. The acceptable range is
   * [minimumRequestBlockConfirmations, 200].
   * @param callbackGasLimit - How much gas you'd like to receive in your
   * fulfillRandomWords callback. Note that gasleft() inside fulfillRandomWords
   * may be slightly less than this amount because of gas used calling the function
   * (argument decoding etc.), so you may need to request slightly more than you expect
   * to have inside fulfillRandomWords. The acceptable range is
   * [0, maxGasLimit]
   * @param numWords - The number of uint256 random values you'd like to receive
   * in your fulfillRandomWords callback. Note these numbers are expanded in a
   * secure way by the VRFCoordinator from a single random value supplied by the oracle.
   * @return requestId - A unique identifier of the request. Can be used to match
   * a request to a response in fulfillRandomWords.
   */
  function requestRandomWords(
    bytes32 keyHash,
    uint64 subId,
    uint16 minimumRequestConfirmations,
    uint32 callbackGasLimit,
    uint32 numWords
  ) external returns (uint256 requestId);

  /**
   * @notice Create a VRF subscription.
   * @return subId - A unique subscription id.
   * @dev You can manage the consumer set dynamically with addConsumer/removeConsumer.
   * @dev Note to fund the subscription, use transferAndCall. For example
   * @dev  LINKTOKEN.transferAndCall(
   * @dev    address(COORDINATOR),
   * @dev    amount,
   * @dev    abi.encode(subId));
   */
  function createSubscription() external returns (uint64 subId);

  /**
   * @notice Get a VRF subscription.
   * @param subId - ID of the subscription
   * @return balance - LINK balance of the subscription in juels.
   * @return reqCount - number of requests for this subscription, determines fee tier.
   * @return owner - owner of the subscription.
   * @return consumers - list of consumer address which are able to use this subscription.
   */
  function getSubscription(
    uint64 subId
  ) external view returns (uint96 balance, uint64 reqCount, address owner, address[] memory consumers);

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @param newOwner - proposed new owner of the subscription
   */
  function requestSubscriptionOwnerTransfer(uint64 subId, address newOwner) external;

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @dev will revert if original owner of subId has
   * not requested that msg.sender become the new owner.
   */
  function acceptSubscriptionOwnerTransfer(uint64 subId) external;

  /**
   * @notice Add a consumer to a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - New consumer which can use the subscription
   */
  function addConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Remove a consumer from a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - Consumer to remove from the subscription
   */
  function removeConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Cancel a subscription
   * @param subId - ID of the subscription
   * @param to - Where to send the remaining LINK to
   */
  function cancelSubscription(uint64 subId, address to) external;

  /*
   * @notice Check to see if there exists a request commitment consumers
   * for all consumers and keyhashes for a given sub.
   * @param subId - ID of the subscription
   * @return true if there exists at least one unfulfilled request for the subscription, false
   * otherwise.
   */
  function pendingRequestExists(uint64 subId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness. It ensures 2 things:
 * @dev 1. The fulfillment came from the VRFCoordinator
 * @dev 2. The consumer contract implements fulfillRandomWords.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constructor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash). Create subscription, fund it
 * @dev and your consumer contract as a consumer of it (see VRFCoordinatorInterface
 * @dev subscription management functions).
 * @dev Call requestRandomWords(keyHash, subId, minimumRequestConfirmations,
 * @dev callbackGasLimit, numWords),
 * @dev see (VRFCoordinatorInterface for a description of the arguments).
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomWords method.
 *
 * @dev The randomness argument to fulfillRandomWords is a set of random words
 * @dev generated from your requestId and the blockHash of the request.
 *
 * @dev If your contract could have concurrent requests open, you can use the
 * @dev requestId returned from requestRandomWords to track which response is associated
 * @dev with which randomness request.
 * @dev See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ.
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request. It is for this reason that
 * @dev that you can signal to an oracle you'd like them to wait longer before
 * @dev responding to the request (however this is not enforced in the contract
 * @dev and so remains effective only in the case of unmodified oracle software).
 */
abstract contract VRFConsumerBaseV2 {
  error OnlyCoordinatorCanFulfill(address have, address want);
  address private immutable vrfCoordinator;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   */
  constructor(address _vrfCoordinator) {
    vrfCoordinator = _vrfCoordinator;
  }

  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBaseV2 expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomWords the VRF output expanded to the requested number of words
   */
  function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal virtual;

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords) external {
    if (msg.sender != vrfCoordinator) {
      revert OnlyCoordinatorCanFulfill(msg.sender, vrfCoordinator);
    }
    fulfillRandomWords(requestId, randomWords);
  }
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

pragma solidity ^0.8.8;

import { UintUtils } from './UintUtils.sol';

library AddressUtils {
    using UintUtils for uint256;

    error AddressUtils__InsufficientBalance();
    error AddressUtils__NotContract();
    error AddressUtils__SendValueFailed();

    function toString(address account) internal pure returns (string memory) {
        return uint256(uint160(account)).toHexString(20);
    }

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function sendValue(address payable account, uint256 amount) internal {
        (bool success, ) = account.call{ value: amount }('');
        if (!success) revert AddressUtils__SendValueFailed();
    }

    function functionCall(
        address target,
        bytes memory data
    ) internal returns (bytes memory) {
        return
            functionCall(target, data, 'AddressUtils: failed low-level call');
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory error
    ) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, error);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                'AddressUtils: failed low-level call with value'
            );
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory error
    ) internal returns (bytes memory) {
        if (value > address(this).balance)
            revert AddressUtils__InsufficientBalance();
        return _functionCallWithValue(target, data, value, error);
    }

    /**
     * @notice execute arbitrary external call with limited gas usage and amount of copied return data
     * @dev derived from https://github.com/nomad-xyz/ExcessivelySafeCall (MIT License)
     * @param target recipient of call
     * @param gasAmount gas allowance for call
     * @param value native token value to include in call
     * @param maxCopy maximum number of bytes to copy from return data
     * @param data encoded call data
     * @return success whether call is successful
     * @return returnData copied return data
     */
    function excessivelySafeCall(
        address target,
        uint256 gasAmount,
        uint256 value,
        uint16 maxCopy,
        bytes memory data
    ) internal returns (bool success, bytes memory returnData) {
        returnData = new bytes(maxCopy);

        assembly {
            // execute external call via assembly to avoid automatic copying of return data
            success := call(
                gasAmount,
                target,
                value,
                add(data, 0x20),
                mload(data),
                0,
                0
            )

            // determine whether to limit amount of data to copy
            let toCopy := returndatasize()

            if gt(toCopy, maxCopy) {
                toCopy := maxCopy
            }

            // store the length of the copied bytes
            mstore(returnData, toCopy)

            // copy the bytes from returndata[0:toCopy]
            returndatacopy(add(returnData, 0x20), 0, toCopy)
        }
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory error
    ) private returns (bytes memory) {
        if (!isContract(target)) revert AddressUtils__NotContract();

        (bool success, bytes memory returnData) = target.call{ value: value }(
            data
        );

        if (success) {
            return returnData;
        } else if (returnData.length > 0) {
            assembly {
                let returnData_size := mload(returnData)
                revert(add(32, returnData), returnData_size)
            }
        } else {
            revert(error);
        }
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { ISolidStateERC20 } from "@solidstate/contracts/token/ERC20/ISolidStateERC20.sol";
import { AccrualData } from "./types/DataTypes.sol";

/// @title ITokenMint interface
/// @dev contains all external functions for Token facet
interface IToken is ISolidStateERC20 {
    /// @notice returns AccrualData struct pertaining to account, which contains Token accrual
    /// information
    /// @param account address of account
    /// @return data AccrualData of account
    function accrualData(
        address account
    ) external view returns (AccrualData memory data);

    /// @notice adds an account to the mintingContracts enumerable set
    /// @param account address of account
    function addMintingContract(address account) external;

    /// @notice returns the value of BASIS
    /// @return value BASIS value
    function BASIS() external pure returns (uint32 value);

    /// @notice burns an amount of tokens of an account
    /// @param account account to burn from
    /// @param amount amount of tokens to burn
    function burn(address account, uint256 amount) external;

    /// @notice claims all claimable tokens for the msg.sender
    function claim() external;

    /// @notice returns all claimable tokens of a given account
    /// @param account address of account
    /// @return amount amount of claimable tokens
    function claimableTokens(
        address account
    ) external view returns (uint256 amount);

    /// @notice Disperses tokens to a list of recipients
    /// @param recipients assumed ordered array of recipient addresses
    /// @param amounts assumed ordered array of token amounts to disperse
    function disperseTokens(
        address[] calldata recipients,
        uint256[] calldata amounts
    ) external;

    /// @notice returns the distributionFractionBP value
    /// @return fractionBP value of distributionFractionBP
    function distributionFractionBP() external view returns (uint32 fractionBP);

    /// @notice returns the distribution supply value
    /// @return supply distribution supply value
    function distributionSupply() external view returns (uint256 supply);

    /// @notice returns the global ratio value
    /// @return ratio global ratio value
    function globalRatio() external view returns (uint256 ratio);

    /// @notice disburses (mints) an amount of tokens to an account
    /// @param account address of account receive the tokens
    /// @param amount amount of tokens to disburse
    function mint(address account, uint256 amount) external;

    /// @notice returns all addresses of contracts which are allowed to call mint/burn
    /// @return contracts array of addresses of contracts which are allowed to call mint/burn
    function mintingContracts()
        external
        view
        returns (address[] memory contracts);

    /// @notice removes an account from the mintingContracts enumerable set
    /// @param account address of account
    function removeMintingContract(address account) external;

    /// @notice returns the value of SCALE
    /// @return value SCALE value
    function SCALE() external pure returns (uint256 value);

    /// @notice sets a new value for distributionFractionBP
    /// @param _distributionFractionBP new distributionFractionBP value
    function setDistributionFractionBP(uint32 _distributionFractionBP) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { IGuardsInternal } from "./IGuardsInternal.sol";

/// @title GuardsInternal contract
/// @dev contains common internal guard functions
abstract contract GuardsInternal is IGuardsInternal {
    /// @notice enforces that a value does not exceed the basis
    /// @param value value to check
    function _enforceBasis(uint32 value, uint32 basis) internal pure {
        if (value > basis) {
            revert BasisExceeded();
        }
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { EnumerableSet } from "@solidstate/contracts/data/EnumerableSet.sol";

/// @dev DataTypes.sol defines the PerpetualMint struct data types used in the PerpetualMintStorage layout

/// @dev Represents data specific to a collection
struct CollectionData {
    /// @dev keeps track of mint requests which have not yet been fulfilled
    /// @dev used to implement the collection risk update "state-machine" check
    EnumerableSet.UintSet pendingRequests;
    /// @dev price of mint attempt in ETH (native token) for a collection
    uint256 mintPrice;
    /// @dev risk of ruin for a collection
    uint32 risk;
}

/// @dev Represents data specific to mint requests
/// @dev Updated as a new request is made and removed when the request is fulfilled
struct RequestData {
    /// @dev address of collection for mint attempt
    address collection;
    /// @dev address of minter who made the request
    address minter;
}

/// @dev Represents data specific to $MINT consolation tiers
struct TiersData {
    /// @dev assumed ordered array of risks for each tier
    uint32[] tierRisks;
    /// @dev assumed ordered array of $MINT consolation multipliers for each tier
    uint256[] tierMultipliers;
}

/// @dev Encapsulates variables related to Chainlink VRF
/// @dev see: https://docs.chain.link/vrf/v2/subscription#set-up-your-contract-and-request
struct VRFConfig {
    /// @dev Chainlink identifier for prioritizing transactions
    /// different keyhashes have different gas prices thus different priorities
    bytes32 keyHash;
    /// @dev id of Chainlink subscription to VRF for PerpetualMint contract
    uint64 subscriptionId;
    /// @dev maximum amount of gas a user is willing to pay for completing the callback VRF function
    uint32 callbackGasLimit;
    /// @dev number of block confirmations the VRF service will wait to respond
    uint16 minConfirmations;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title Partial ERC173 interface needed by internal functions
 */
interface IERC173Internal {
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC173Internal } from '../../interfaces/IERC173Internal.sol';

interface IOwnableInternal is IERC173Internal {
    error Ownable__NotOwner();
    error Ownable__NotTransitiveOwner();
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

library OwnableStorage {
    struct Layout {
        address owner;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.Ownable');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title ERC165 interface registration interface
 */
interface IERC165Internal {

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC165Internal } from '../../../interfaces/IERC165Internal.sol';

interface IERC165BaseInternal is IERC165Internal {
    error ERC165Base__InvalidInterfaceId();
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

interface IPausableInternal {
    error Pausable__Paused();
    error Pausable__NotPaused();

    event Paused(address account);
    event Unpaused(address account);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

library PausableStorage {
    struct Layout {
        bool paused;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.Pausable');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title Partial ERC1155 interface needed by internal functions
 */
interface IERC1155Internal {
    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 value
    );

    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    event ApprovalForAll(
        address indexed account,
        address indexed operator,
        bool approved
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC1155Internal } from '../../../interfaces/IERC1155Internal.sol';

/**
 * @title ERC1155 base interface
 */
interface IERC1155BaseInternal is IERC1155Internal {
    error ERC1155Base__ArrayLengthMismatch();
    error ERC1155Base__BalanceQueryZeroAddress();
    error ERC1155Base__NotOwnerOrApproved();
    error ERC1155Base__SelfApproval();
    error ERC1155Base__BurnExceedsBalance();
    error ERC1155Base__BurnFromZeroAddress();
    error ERC1155Base__ERC1155ReceiverRejected();
    error ERC1155Base__ERC1155ReceiverNotImplemented();
    error ERC1155Base__MintToZeroAddress();
    error ERC1155Base__TransferExceedsBalance();
    error ERC1155Base__TransferToZeroAddress();
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

library ERC1155BaseStorage {
    struct Layout {
        mapping(uint256 => mapping(address => uint256)) balances;
        mapping(address => mapping(address => bool)) operatorApprovals;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.ERC1155Base');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title Partial ERC1155Metadata interface needed by internal functions
 */
interface IERC1155MetadataInternal {
    event URI(string value, uint256 indexed tokenId);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

/// @title ERC1155MetadataExtensionStorage
library ERC1155MetadataExtensionStorage {
    struct Layout {
        string name;
        string symbol;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256("insrt.contracts.storage.ERC1155MetadataExtensionStorage");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;

        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC20Base } from './base/IERC20Base.sol';
import { IERC20Extended } from './extended/IERC20Extended.sol';
import { IERC20Metadata } from './metadata/IERC20Metadata.sol';
import { IERC20Permit } from './permit/IERC20Permit.sol';

interface ISolidStateERC20 is
    IERC20Base,
    IERC20Extended,
    IERC20Metadata,
    IERC20Permit
{}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

/// @dev DataTypes.sol defines the Token struct data types used in the TokenStorage layout

/// @dev represents data related to $MINT token accruals (linked to a specific account)
struct AccrualData {
    /// @dev last ratio an account had when one of their actions led to a change in the
    /// reservedSupply
    uint256 offset;
    /// @dev amount of tokens accrued as a result of distribution to token holders
    uint256 accruedTokens;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

/// @title IGuardsInternal interface
/// @dev interface holding all errors related to common guards
interface IGuardsInternal {
    /// @notice thrown when attempting to set a value larger than basis
    error BasisExceeded();
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC20 } from '../../../interfaces/IERC20.sol';
import { IERC20BaseInternal } from './IERC20BaseInternal.sol';

/**
 * @title ERC20 base interface
 */
interface IERC20Base is IERC20BaseInternal, IERC20 {

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC20ExtendedInternal } from './IERC20ExtendedInternal.sol';

/**
 * @title ERC20 extended interface
 */
interface IERC20Extended is IERC20ExtendedInternal {
    /**
     * @notice increase spend amount granted to spender
     * @param spender address whose allowance to increase
     * @param amount quantity by which to increase allowance
     * @return success status (always true; otherwise function will revert)
     */
    function increaseAllowance(
        address spender,
        uint256 amount
    ) external returns (bool);

    /**
     * @notice decrease spend amount granted to spender
     * @param spender address whose allowance to decrease
     * @param amount quantity by which to decrease allowance
     * @return success status (always true; otherwise function will revert)
     */
    function decreaseAllowance(
        address spender,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC20MetadataInternal } from './IERC20MetadataInternal.sol';

/**
 * @title ERC20 metadata interface
 */
interface IERC20Metadata is IERC20MetadataInternal {
    /**
     * @notice return token name
     * @return token name
     */
    function name() external view returns (string memory);

    /**
     * @notice return token symbol
     * @return token symbol
     */
    function symbol() external view returns (string memory);

    /**
     * @notice return token decimals, generally used only for display purposes
     * @return token decimals
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC20Metadata } from '../metadata/IERC20Metadata.sol';
import { IERC2612 } from './IERC2612.sol';
import { IERC20PermitInternal } from './IERC20PermitInternal.sol';

// TODO: note that IERC20Metadata is needed for eth-permit library

interface IERC20Permit is IERC20PermitInternal, IERC2612 {

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC20Internal } from './IERC20Internal.sol';

/**
 * @title ERC20 interface
 * @dev see https://eips.ethereum.org/EIPS/eip-20
 */
interface IERC20 is IERC20Internal {
    /**
     * @notice query the total minted token supply
     * @return token supply
     */
    function totalSupply() external view returns (uint256);

    /**
     * @notice query the token balance of given account
     * @param account address to query
     * @return token balance
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @notice query the allowance granted from given holder to given spender
     * @param holder approver of allowance
     * @param spender recipient of allowance
     * @return token allowance
     */
    function allowance(
        address holder,
        address spender
    ) external view returns (uint256);

    /**
     * @notice grant approval to spender to spend tokens
     * @dev prefer ERC20Extended functions to avoid transaction-ordering vulnerability (see https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729)
     * @param spender recipient of allowance
     * @param amount quantity of tokens approved for spending
     * @return success status (always true; otherwise function should revert)
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @notice transfer tokens to given recipient
     * @param recipient beneficiary of token transfer
     * @param amount quantity of tokens to transfer
     * @return success status (always true; otherwise function should revert)
     */
    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @notice transfer tokens to given recipient on behalf of given holder
     * @param holder holder of tokens prior to transfer
     * @param recipient beneficiary of token transfer
     * @param amount quantity of tokens to transfer
     * @return success status (always true; otherwise function should revert)
     */
    function transferFrom(
        address holder,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC20Internal } from '../../../interfaces/IERC20Internal.sol';

/**
 * @title ERC20 base interface
 */
interface IERC20BaseInternal is IERC20Internal {
    error ERC20Base__ApproveFromZeroAddress();
    error ERC20Base__ApproveToZeroAddress();
    error ERC20Base__BurnExceedsBalance();
    error ERC20Base__BurnFromZeroAddress();
    error ERC20Base__InsufficientAllowance();
    error ERC20Base__MintToZeroAddress();
    error ERC20Base__TransferExceedsBalance();
    error ERC20Base__TransferFromZeroAddress();
    error ERC20Base__TransferToZeroAddress();
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC20BaseInternal } from '../base/IERC20BaseInternal.sol';

/**
 * @title ERC20 extended internal interface
 */
interface IERC20ExtendedInternal is IERC20BaseInternal {
    error ERC20Extended__ExcessiveAllowance();
    error ERC20Extended__InsufficientAllowance();
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title ERC20 metadata internal interface
 */
interface IERC20MetadataInternal {

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC2612Internal } from './IERC2612Internal.sol';

/**
 * @title ERC2612 interface
 * @dev see https://eips.ethereum.org/EIPS/eip-2612.
 */
interface IERC2612 is IERC2612Internal {
    /**
     * @notice return the EIP-712 domain separator unique to contract and chain
     * @return domainSeparator domain separator
     */
    function DOMAIN_SEPARATOR() external view returns (bytes32 domainSeparator);

    /**
     * @notice get the current ERC2612 nonce for the given address
     * @return current nonce
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @notice approve spender to transfer tokens held by owner via signature
     * @dev this function may be vulnerable to approval replay attacks
     * @param owner holder of tokens and signer of permit
     * @param spender beneficiary of approval
     * @param amount quantity of tokens to approve
     * @param v secp256k1 'v' value
     * @param r secp256k1 'r' value
     * @param s secp256k1 's' value
     */
    function permit(
        address owner,
        address spender,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC2612Internal } from './IERC2612Internal.sol';

interface IERC20PermitInternal is IERC2612Internal {
    error ERC20Permit__ExpiredDeadline();
    error ERC20Permit__InvalidSignature();
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title Partial ERC20 interface needed by internal functions
 */
interface IERC20Internal {
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

interface IERC2612Internal {}