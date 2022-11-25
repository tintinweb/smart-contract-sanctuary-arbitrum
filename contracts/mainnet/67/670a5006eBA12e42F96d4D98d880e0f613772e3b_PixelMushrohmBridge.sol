// SPDX-License-Identifier: GPLv2
pragma solidity ^0.8.1;

import "arbos-precompiles/arbos/builtin/ArbSys.sol";
import "@arbitrum/nitro-contracts/src/libraries/AddressAliasHelper.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "./interfaces/IMushrohmBridge.sol";
import "./interfaces/IPixelMushrohmBridge.sol";
import "./interfaces/IPixelMushrohmERC721.sol";
import "./types/PixelMushrohmAccessControlled.sol";

contract PixelMushrohmBridge is IPixelMushrohmBridge, PixelMushrohmAccessControlled, ReentrancyGuard {
    /* ========== CONSTANTS ========== */

    ArbSys constant arbsys = ArbSys(address(100));

    /* ========== STATE VARIABLES ========== */

    address public l1Target;
    IPixelMushrohmERC721 public pixelMushrohm;

    /* ======== CONSTRUCTOR ======== */

    constructor(address _authority) PixelMushrohmAccessControlled(IPixelMushrohmAuthority(_authority)) {}

    /* ======== ADMIN FUNCTIONS ======== */

    function setPixelMushrohm(address _pixelMushrohm) external override onlyOwner {
        pixelMushrohm = IPixelMushrohmERC721(_pixelMushrohm);
    }

    function setL1Target(address _l1Target) external override onlyOwner {
        l1Target = _l1Target;
    }

    // Incase of a problem. Allows admin to transfer stuck NFT back to user
    function transferStuckNFT(uint256 _tokenId) external override onlyPolicy {
        IERC721(address(pixelMushrohm)).safeTransferFrom(address(this), msg.sender, _tokenId);
    }

    /* ======== MUTABLE FUNCTIONS ======== */

    /*
    @desc:
        Function will initate a transcation to transfer the NFT from the L1 Contract to the user.

    @security :
        @impact: Critical : Should only be executed, after retrieving a PixelMushrohm from the user, that is in the range of 0-1500.
 
    @args : 
        token_id : uint256 : ID of the token, to be transfered from the L1 Contract to the user.
        
    @emits:
        L2ToL1TxCreated(withdrawalId);
    */
    function transferPixelMushrohmtoL1(uint256 _tokenId)
        external
        override
        whenNotPaused
        nonReentrant
        returns (uint256)
    {
        require(_tokenId <= 1500);

        IERC721(address(pixelMushrohm)).safeTransferFrom(msg.sender, address(this), _tokenId);
        bytes memory data = abi.encodeWithSelector(IMushrohmBridge.acceptTransferFromL2.selector, _tokenId, msg.sender);
        uint256 withdrawalId = arbsys.sendTxToL1(l1Target, data);

        emit L2ToL1TxCreated(withdrawalId);
        return withdrawalId;
    }

    /*
    @desc:
        This function is the function that is targeted by the retryable ticket that is executed on L1 by the ETH Bridge Contract. 
        Will send the target_user the NFT, stored in the contract.

    @security :
        Should only be able to be called by the L1 Target Address, if not then the NFTs stored in the contract can be stolen.

    @args : 
        _tokenId : uint256 : the token id of the NFT that the L1 contract is trying to send.
        target_user : address : the address the L1 contract has been told to, send the NFT to.

    @emits:
        NFTSentToUser(tokenId, targetUser, msgSender);
    */
    function acceptTransferFromL1(uint256 _tokenId, address _targetUser) external override whenNotPaused nonReentrant {
        // Need to make sure this actually stops, hash collisions on the L2 Contract PIN: Security
        require(
            msg.sender == AddressAliasHelper.applyL1ToL2Alias(l1Target),
            "Only ETH side of the bridge can transfer NFTs"
        );
        require(_tokenId <= 1500);

        if (pixelMushrohm.exists(_tokenId)) {
            IERC721(address(pixelMushrohm)).safeTransferFrom(address(this), _targetUser, _tokenId);
        } else {
            pixelMushrohm.bridgeMint(_targetUser, _tokenId);
        }

        emit NFTSentToUser(_tokenId, _targetUser, msg.sender);
    }

    /* ======== HELPER FUNCTIONS ======== */

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) public pure override returns (bytes4) {
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }
}

pragma solidity >=0.4.21 <0.9.0;

/**
* @title Precompiled contract that exists in every Arbitrum chain at address(100), 0x0000000000000000000000000000000000000064. Exposes a variety of system-level functionality.
 */
interface ArbSys {
    /**
    * @notice Get internal version number identifying an ArbOS build
    * @return version number as int
     */
    function arbOSVersion() external pure returns (uint);

    function arbChainID() external view returns(uint);

    /**
    * @notice Get Arbitrum block number (distinct from L1 block number; Arbitrum genesis block has block number 0)
    * @return block number as int
     */ 
    function arbBlockNumber() external view returns (uint);

    /** 
    * @notice Send given amount of Eth to dest from sender.
    * This is a convenience function, which is equivalent to calling sendTxToL1 with empty calldataForL1.
    * @param destination recipient address on L1
    * @return unique identifier for this L2-to-L1 transaction.
    */
    function withdrawEth(address destination) external payable returns(uint);

    /** 
    * @notice Send a transaction to L1
    * @param destination recipient address on L1 
    * @param calldataForL1 (optional) calldata for L1 contract call
    * @return a unique identifier for this L2-to-L1 transaction.
    */
    function sendTxToL1(address destination, bytes calldata calldataForL1) external payable returns(uint);

    /** 
    * @notice get the number of transactions issued by the given external account or the account sequence number of the given contract
    * @param account target account
    * @return the number of transactions issued by the given external account or the account sequence number of the given contract
    */
    function getTransactionCount(address account) external view returns(uint256);

    /**  
    * @notice get the value of target L2 storage slot 
    * This function is only callable from address 0 to prevent contracts from being able to call it
    * @param account target account
    * @param index target index of storage slot 
    * @return stotage value for the given account at the given index
    */
    function getStorageAt(address account, uint256 index) external view returns (uint256);

    /**
    * @notice check if current call is coming from l1
    * @return true if the caller of this was called directly from L1
    */
    function isTopLevelCall() external view returns (bool);

    /**
     * @notice check if the caller (of this caller of this) is an aliased L1 contract address
     * @return true iff the caller's address is an alias for an L1 contract address
     */
    function wasMyCallersAddressAliased() external view returns (bool);

    /**
     * @notice return the address of the caller (of this caller of this), without applying L1 contract address aliasing
     * @return address of the caller's caller, without applying L1 contract address aliasing
     */
    function myCallersAddressWithoutAliasing() external view returns (address);

    /**
     * @notice map L1 sender contract address to its L2 alias
     * @param sender sender address
     * @param dest destination address
     * @return aliased sender address
     */
    function mapL1SenderContractAddressToL2Alias(address sender, address dest) external pure returns(address);

    /**
     * @notice get the caller's amount of available storage gas
     * @return amount of storage gas available to the caller
     */
    function getStorageGasAvailable() external view returns(uint);

    event L2ToL1Transaction(address caller, address indexed destination, uint indexed uniqueId,
                            uint indexed batchNumber, uint indexInBatch,
                            uint arbBlockNum, uint ethBlockNum, uint timestamp,
                            uint callvalue, bytes data);
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: GPLv2
pragma solidity ^0.8.1;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

import "./IBaseBridge.sol";

interface IMushrohmBridge is IERC721Receiver, IBaseBridge {
    /* ========== EVENTS ========== */

    event RetryableTicketCreated(uint256 indexed ticketId);

    /* ======== ADMIN FUNCTIONS ======== */

    function setInbox(address _inbox) external;

    function setL2Target(address _l2Target) external;

    function setMushrohmAddress(address _mushrohmAddr) external;

    /* ======== MUTABLE FUNCTIONS ======== */

    function transferMushrohmtoL2(
        uint256 _tokenId,
        uint256 _maxSubmissionCost,
        uint256 _maxGas,
        uint256 _gasPriceBid
    ) external payable returns (uint256);

    function acceptTransferFromL2(uint256 tokenId, address userAddress) external;
}

// SPDX-License-Identifier: GPLv2
pragma solidity ^0.8.1;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

import "./IBaseBridge.sol";

interface IPixelMushrohmBridge is IERC721Receiver, IBaseBridge {
    /* ========== EVENTS ========== */

    event L2ToL1TxCreated(uint256 indexed withdrawalId);

    /* ======== ADMIN FUNCTIONS ======== */

    function setPixelMushrohm(address _pixelMushrohm) external;

    function setL1Target(address _l1Target) external;

    /* ======== MUTABLE FUNCTIONS ======== */

    function transferPixelMushrohmtoL1(uint256 _tokenId) external returns (uint256);

    function acceptTransferFromL1(uint256 _tokenId, address _targetUser) external;
}

// SPDX-License-Identifier: GPLv2
pragma solidity ^0.8.1;

import "@openzeppelin/contracts/interfaces/IERC721Enumerable.sol";

interface IPixelMushrohmERC721 is IERC721Enumerable {
    /* ========== EVENTS ========== */

    event PixelMushrohmMint(address to, uint256 tokenId);
    event RedeemSporePower(uint256 tokenId, uint256 amount);
    event SporePowerCost(uint256 sporePowerCost);
    event MaxSporePowerLevel(uint256 maxSporePowerLevel);
    event LevelCost(uint256 levelCost);
    event MaxLevel(uint256 maxLevel);
    event BaseLevelMultiplier(uint256 levelMultiplier);
    event AdditionalMultiplier(uint256 tokenId, uint256 multiplier);
    event FirstGenLevelMintLevel(uint256 level);
    event StakingSet(address staking);
    event RedeemerAdded(address redeemer);
    event RedeemerRemoved(address redeemer);
    event MultiplierAdded(address multiplier);
    event MultiplierRemoved(address multiplier);
    event BridgeSet(address bridge);
    event Withdraw(address tokenAddr, uint256 amount, address to);

    /* ========== ENUMS ========== */

    enum MintType {
        APELIEN_AIRDROP,
        NOOSH_AIRDROP,
        PILOT_AIRDROP,
        R3L0C_AIRDROP,
        BRIDGE,
        STANDARD
    }

    /* ========== STRUCTS ========== */

    struct TokenData {
        uint256 sporePower;
        uint256 sporePowerPerWeek;
        uint256 level;
        uint256 levelPower;
        uint256 additionalMultiplier;
    }

    /* ======== ADMIN FUNCTIONS ======== */

    function setStaking(address _staking) external;

    function addRedeemer(address _redeemer) external;

    function removeRedeemer(address _redeemer) external;

    function addMultiplier(address _multiplier) external;

    function removeMultiplier(address _multiplier) external;

    function setBridge(address _bridge) external;

    function setMaxSporePowerLevel(uint256 _max) external;

    function setMaxLevel(uint256 _max) external;

    function setBaseLevelMultiplier(uint256 _multiplier) external;

    function setFirstGenLevelMintLevel(uint256 _level) external;

    function setSporePowerPerWeek(uint256 _sporePowerPerWeek, uint256[] calldata _tokenIds) external;

    function setBaseURI(string memory _baseURItoSet) external;

    function setPrerevealURI(string memory _prerevealURI) external;

    function setMintToken(address _tokenAddr) external;

    function setMintTokenPrice(uint256 _price) external;

    function setMaxMintPerWallet(uint256 _maxPerWallet) external;

    function setMerkleRoot(bytes32 _merkleRoot) external;

    function toggleReveal() external;

    function withdraw(address _tokenAddr, uint256 _amount) external;

    function airdrop(
        MintType _mintType,
        address[] calldata _to,
        uint256[] calldata _amount
    ) external;

    /* ======== MUTABLE FUNCTIONS ======== */

    function whitelistMint(uint256 _amount, bytes32[] calldata _merkleProof) external;

    function bridgeMint(address _to, uint256 _tokenId) external;

    function firstGenLevelMint(uint256 _tokenId) external;

    function updateSporePower(uint256 _tokenId, uint256 _sporePowerEarned) external;

    function updateLevelPower(uint256 _tokenId, uint256 _levelPowerEarned) external;

    function updateLevel(uint256 _tokenId) external;

    function redeemSporePower(uint256 _tokenId, uint256 _amount) external;

    function setAdditionalMultiplier(uint256 _tokenId, uint256 _multiplier) external;

    /* ======== VIEW FUNCTIONS ======== */

    function exists(uint256 _tokenId) external view returns (bool);

    function getMintToken() external view returns (address);

    function getMintTokenPrice() external view returns (uint256);

    function getMaxMintPerWallet() external view returns (uint256);

    function getSporePower(uint256 _tokenId) external view returns (uint256);

    function getSporePowerLevel(uint256 _tokenId) external view returns (uint256);

    function averageSporePower() external view returns (uint256);

    function getSporePowerCost() external view returns (uint256);

    function getMaxSporePowerLevel() external view returns (uint256);

    function getSporePowerPerWeek(uint256 _tokenId) external view returns (uint256);

    function getLevel(uint256 _tokenId) external view returns (uint256);

    function getLevelPower(uint256 _tokenId) external view returns (uint256);

    function getLevelCost() external view returns (uint256);

    function getMaxLevel() external view returns (uint256);

    function getBaseLevelMultiplier() external view returns (uint256);

    function getLevelMultiplier(uint256 _tokenId) external view returns (uint256);

    function getAdditionalMultiplier(uint256 _tokenId) external view returns (uint256);

    function getTokenURIsForOwner(address _owner) external view returns (string[] memory);

    function isEligibleForLevelMint(uint256 _tokenId) external view returns (bool);

    function getNumTokensMinted(address _owner) external view returns (uint256);

    function isSporePowerMaxed(uint256 _tokenId) external view returns (bool);

    function isLevelPowerMaxed(uint256 _tokenId) external view returns (bool);

    function isLevelMaxed(uint256 _tokenId) external view returns (bool);

    function hasUserHitMaxMint(address _user) external view returns (bool);
}

// SPDX-License-Identifier: GPLv2
pragma solidity ^0.8.1;

import "../interfaces/IPixelMushrohmAuthority.sol";

abstract contract PixelMushrohmAccessControlled {
    /* ========== EVENTS ========== */

    event AuthorityUpdated(IPixelMushrohmAuthority indexed authority);

    string UNAUTHORIZED = "UNAUTHORIZED"; // save gas
    string PAUSED = "PAUSED";
    string UNPAUSED = "UNPAUSED";

    /* ========== STATE VARIABLES ========== */

    IPixelMushrohmAuthority public authority;

    /* ========== Constructor ========== */

    constructor(IPixelMushrohmAuthority _authority) {
        authority = _authority;
        emit AuthorityUpdated(_authority);
    }

    /* ========== MODIFIERS ========== */

    modifier onlyOwner() {
        require(msg.sender == authority.owner(), UNAUTHORIZED);
        _;
    }

    modifier onlyPolicy() {
        require(msg.sender == authority.policy(), UNAUTHORIZED);
        _;
    }

    modifier onlyVault() {
        require(msg.sender == authority.vault(), UNAUTHORIZED);
        _;
    }

    modifier whenNotPaused() {
        require(!authority.paused(), PAUSED);
        _;
    }

    modifier whenPaused() {
        require(authority.paused(), UNPAUSED);
        _;
    }

    /* ========== OWNER ONLY ========== */

    function setAuthority(IPixelMushrohmAuthority _newAuthority) external onlyOwner {
        authority = _newAuthority;
        emit AuthorityUpdated(_newAuthority);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: GPLv2
pragma solidity ^0.8.1;

interface IBaseBridge {
    /* ========== EVENTS ========== */

    event NFTSentToUser(uint256 tokenId, address targetUser, address msgSender);

    /* ======== ADMIN FUNCTIONS ======== */

    function transferStuckNFT(uint256 _tokenId) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/extensions/IERC721Enumerable.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: GPLv2
pragma solidity ^0.8.1;

interface IPixelMushrohmAuthority {
    /* ========== EVENTS ========== */

    event OwnerPushed(address indexed from, address indexed to, bool _effectiveImmediately);
    event PolicyPushed(address indexed from, address indexed to, bool _effectiveImmediately);
    event VaultPushed(address indexed from, address indexed to, bool _effectiveImmediately);

    event OwnerPulled(address indexed from, address indexed to);
    event PolicyPulled(address indexed from, address indexed to);
    event VaultPulled(address indexed from, address indexed to);

    event Paused(address by);
    event Unpaused(address by);

    /* ========== VIEW ========== */

    function owner() external view returns (address);

    function policy() external view returns (address);

    function vault() external view returns (address);

    function paused() external view returns (bool);
}