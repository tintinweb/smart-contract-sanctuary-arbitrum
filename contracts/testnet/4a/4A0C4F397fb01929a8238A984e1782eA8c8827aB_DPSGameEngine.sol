// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
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

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 expanded to include mint functionality
 * @dev
 */
interface IERC20Mintable {
    /**
     * @dev mints `amount` to `receiver`
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits an {Minted} event.
     */
    function mint(address receiver, uint256 amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20Mintable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @dev Interface of the ERC20 expanded to include mint and burn functionality
 * @dev
 */
interface IERC20MintableBurnable is IERC20Mintable, IERC20 {
    /**
     * @dev burns `amount` from `receiver`
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits an {BURN} event.
     */
    function burn(address _from, uint256 _amount) external;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/DPSStructs.sol";
import "./interfaces/DPSInterfaces.sol";
import "./../interfaces/IERC20MintableBurnable.sol";

contract DPSGameEngine is DPSGameEngineI, Ownable {
    DPSQRNGI public random;
    DPSSupportShipI public supportShip;
    MintableBurnableIERC1155 public artifact;
    DPSCartographerI public cartographer;
    DPSGameSettingsI public gameSettings;
    DPSGameEngineI public gameEngine;
    DPSDocksI public docks;
    DPSDoubloonMinterI public doubloonsMinter;
    DPSChestsIV2 public chests;
    DPSCrewForCoinI public crewForCoin;
    address public treasury;
    address public plunderers;

    /// @notice an array that keeps for each pirate contract, a contract to get the features out of
    mapping(IERC721 => DPSPirateFeaturesI) public featuresPerPirate;

    /// @notice mapping to keep a nonce for an user at each random action
    mapping(address => uint256) public nonces;

    event SetContract(uint256 _target, address _contract);
    event TreasuryUpdate(uint256 _amount);
    event WonLockBocks(address indexed _user, uint256 _amount);
    event ChangedTreasury(address _newTreasury);
    event OpenedLockBox(address indexed _owner, ARTIFACT_TYPE _type);
    event FeaturesPerPirateChanged(IERC721 indexed _pirate, DPSPirateFeaturesI _feature);
    event RandomNumberGeneratedRewardChest(address indexed owner, uint256 randomResult);
    event RandomNumberGeneratedRewardLockedBox(address indexed owner, uint256 randomResult);

    /**
     * @notice computes skills for the flagship based on the level of the part of the flagship + base skills of the flagship
     * @param levels levels for each part, needs to respect the order of the levels from flagship
     * @param _claimingRewardsCache the cache object that contains the skill points per skill type
     * @return cached object with the skill points updated
     */
    function computeFlagShipSkills(
        uint8[7] memory levels,
        VoyageStatusCache memory _claimingRewardsCache
    ) private view returns (VoyageStatusCache memory) {
        unchecked {
            uint16[7] memory skillsPerPart = gameSettings.getSkillsPerFlagshipParts();
            uint8[7] memory skillTypes = gameSettings.getSkillTypeOfEachFlagshipPart();
            uint256 flagshipBaseSkills = gameSettings.flagshipBaseSkills();
            _claimingRewardsCache.luck += flagshipBaseSkills;
            _claimingRewardsCache.navigation += flagshipBaseSkills;
            _claimingRewardsCache.strength += flagshipBaseSkills;
            for (uint256 i; i < 7; ++i) {
                if (skillTypes[i] == uint8(SKILL_TYPE.LUCK)) _claimingRewardsCache.luck += skillsPerPart[i] * levels[i];
                if (skillTypes[i] == uint8(SKILL_TYPE.NAVIGATION))
                    _claimingRewardsCache.navigation += skillsPerPart[i] * levels[i];
                if (skillTypes[i] == uint8(SKILL_TYPE.STRENGTH))
                    _claimingRewardsCache.strength += skillsPerPart[i] * levels[i];
            }
            return _claimingRewardsCache;
        }
    }

    /**
     * @notice computes skills for the support ships as there are multiple types that apply skills to different skill type: navigation, luck, strength
     * @param _supportShips the array of support ships
     * @param _artifactIds the array of artifacts
     * @param _claimingRewardsCache the cache object that contains the skill points per skill type
     * @return cached object with the skill points updated
     */
    function computeSupportSkills(
        uint8[9] memory _supportShips,
        uint16[13] memory _artifactIds,
        VoyageStatusCache memory _claimingRewardsCache
    ) private view returns (VoyageStatusCache memory) {
        unchecked {
            uint16 skill;
            for (uint256 i = 1; i < 13; ++i) {
                ARTIFACT_TYPE _type = ARTIFACT_TYPE(i);
                if (_artifactIds[i] == 0) continue;
                skill = gameSettings.artifactsSkillBoosts(_type);
                if (
                    _type == ARTIFACT_TYPE.COMMON_STRENGTH ||
                    _type == ARTIFACT_TYPE.RARE_STRENGTH ||
                    _type == ARTIFACT_TYPE.EPIC_STRENGTH ||
                    _type == ARTIFACT_TYPE.LEGENDARY_STRENGTH
                ) _claimingRewardsCache.strength += skill * _artifactIds[i];
                else if (
                    _type == ARTIFACT_TYPE.COMMON_LUCK ||
                    _type == ARTIFACT_TYPE.RARE_LUCK ||
                    _type == ARTIFACT_TYPE.EPIC_LUCK ||
                    _type == ARTIFACT_TYPE.LEGENDARY_LUCK
                ) _claimingRewardsCache.luck += skill * _artifactIds[i];
                else if (
                    _type == ARTIFACT_TYPE.COMMON_NAVIGATION ||
                    _type == ARTIFACT_TYPE.RARE_NAVIGATION ||
                    _type == ARTIFACT_TYPE.EPIC_NAVIGATION ||
                    _type == ARTIFACT_TYPE.LEGENDARY_NAVIGATION
                ) _claimingRewardsCache.navigation += skill * _artifactIds[i];
            }

            for (uint256 i; i < 9; ++i) {
                if (_supportShips[i] == 0) continue;
                SUPPORT_SHIP_TYPE supportShipType = SUPPORT_SHIP_TYPE(i);
                skill = gameSettings.supportShipsSkillBoosts(supportShipType);
                if (
                    supportShipType == SUPPORT_SHIP_TYPE.SLOOP_STRENGTH ||
                    supportShipType == SUPPORT_SHIP_TYPE.CARAVEL_STRENGTH ||
                    supportShipType == SUPPORT_SHIP_TYPE.GALLEON_STRENGTH
                ) _claimingRewardsCache.strength += skill * _supportShips[i];
                else if (
                    supportShipType == SUPPORT_SHIP_TYPE.SLOOP_LUCK ||
                    supportShipType == SUPPORT_SHIP_TYPE.CARAVEL_LUCK ||
                    supportShipType == SUPPORT_SHIP_TYPE.GALLEON_LUCK
                ) _claimingRewardsCache.luck += skill * _supportShips[i];
                else if (
                    supportShipType == SUPPORT_SHIP_TYPE.SLOOP_NAVIGATION ||
                    supportShipType == SUPPORT_SHIP_TYPE.CARAVEL_NAVIGATION ||
                    supportShipType == SUPPORT_SHIP_TYPE.GALLEON_NAVIGATION
                ) _claimingRewardsCache.navigation += skill * _supportShips[i];
            }
            return _claimingRewardsCache;
        }
    }

    /**
     * @notice interprets a randomness result, meaning that based on the skill points accumulated from base pirate skills,
     *         flagship + support ships, we do a comparison between the result of the randomness and the skill points.
     *         if random > skill points than this interaction fails. Things to notice: if STORM or ENEMY fails then we
     *         destroy a support ship (if exists) or do health damage of 100% which will result in skipping all the upcoming
     *         interactions
     * @param _result - random number generated
     * @param _voyageResult - the result object that is cached and sent along for later on saving into storage
     * @param _lockedVoyage - locked voyage that contains the support ship objects that will get modified (sent as storage) if interaction failed
     * @param _claimingRewardsCache - cache object sent along for points updates
     * @param _interaction - interaction that we compute the outcome for
     * @param _index - current index of interaction, used to update the outcome
     * @return updated voyage results and claimingRewardsCache (this updates in case of a support ship getting destroyed)
     */
    function interpretResults(
        uint256 _result,
        VoyageResult memory _voyageResult,
        LockedVoyageV2 memory _lockedVoyage,
        VoyageStatusCache memory _claimingRewardsCache,
        INTERACTION _interaction,
        uint256 _randomNumber,
        uint256 _index
    ) private view returns (VoyageResult memory, VoyageStatusCache memory) {
        if (_interaction == INTERACTION.CHEST && _result <= _claimingRewardsCache.luck && _lockedVoyage.voyageType != 4) {
            _voyageResult.awardedChests++;
            _voyageResult.interactionResults[_index] = 1;
        } else if (_lockedVoyage.voyageType == 4) {
            _voyageResult.awardedChests = 1;
        } else if (
            (_interaction == INTERACTION.STORM && _result > _claimingRewardsCache.navigation) ||
            (_interaction == INTERACTION.ENEMY && _result > _claimingRewardsCache.strength)
        ) {
            if (_lockedVoyage.totalSupportShips - _voyageResult.totalSupportShipsDestroyed > 0) {
                _voyageResult.totalSupportShipsDestroyed++;
                uint256 supportShipTypesLength;
                for (uint256 i; i < 9; ++i) {
                    if (
                        _lockedVoyage.supportShips[i] > _voyageResult.destroyedSupportShips[i] &&
                        _lockedVoyage.supportShips[i] - _voyageResult.destroyedSupportShips[i] > 0
                    ) supportShipTypesLength++;
                }

                uint256[] memory supportShipTypes = new uint256[](supportShipTypesLength);
                uint256 j;
                for (uint256 i; i < 9; ++i) {
                    if (
                        _lockedVoyage.supportShips[i] > _voyageResult.destroyedSupportShips[i] &&
                        _lockedVoyage.supportShips[i] - _voyageResult.destroyedSupportShips[i] > 0
                    ) {
                        supportShipTypes[j] = i;
                        j++;
                    }
                }

                uint256 chosenType = random.getRandomNumber(
                    _randomNumber,
                    _lockedVoyage.lockedBlock,
                    string(abi.encode("SUPPORT_SHIP_", _index)),
                    uint8(1),
                    supportShipTypesLength
                ) % (supportShipTypesLength);

                SUPPORT_SHIP_TYPE supportShipType = SUPPORT_SHIP_TYPE.SLOOP_STRENGTH;
                for (uint256 i; i < supportShipTypesLength; ++i) {
                    if (chosenType == i) {
                        supportShipType = SUPPORT_SHIP_TYPE(supportShipTypes[i]);
                    }
                }
                _voyageResult.destroyedSupportShips[uint8(supportShipType)]++;
                _voyageResult.intDestroyedSupportShips[_index] = uint8(supportShipType);

                uint16 points = gameSettings.supportShipsSkillBoosts(supportShipType);

                if (
                    supportShipType == SUPPORT_SHIP_TYPE.SLOOP_STRENGTH ||
                    supportShipType == SUPPORT_SHIP_TYPE.CARAVEL_STRENGTH ||
                    supportShipType == SUPPORT_SHIP_TYPE.GALLEON_STRENGTH
                ) _claimingRewardsCache.strength -= points;
                else if (
                    supportShipType == SUPPORT_SHIP_TYPE.SLOOP_LUCK ||
                    supportShipType == SUPPORT_SHIP_TYPE.CARAVEL_LUCK ||
                    supportShipType == SUPPORT_SHIP_TYPE.GALLEON_LUCK
                ) _claimingRewardsCache.luck -= points;
                else if (
                    supportShipType == SUPPORT_SHIP_TYPE.SLOOP_NAVIGATION ||
                    supportShipType == SUPPORT_SHIP_TYPE.CARAVEL_NAVIGATION ||
                    supportShipType == SUPPORT_SHIP_TYPE.GALLEON_NAVIGATION
                ) _claimingRewardsCache.navigation -= points;
            } else {
                _voyageResult.healthDamage = 100;

                if (_lockedVoyage.voyageType == 4) {
                    _voyageResult.awardedChests = 0;
                }
            }
        } else if (_interaction != INTERACTION.CHEST) {
            _voyageResult.interactionResults[_index] = 1;
        }

        return (_voyageResult, _claimingRewardsCache);
    }

    function debuffVoyage(
        uint16 _voyageType,
        VoyageStatusCache memory _claimingRewardsCache
    ) private view returns (VoyageStatusCache memory) {
        uint16 debuffs = gameSettings.voyageDebuffs(uint256(_voyageType));

        if (_claimingRewardsCache.strength > debuffs) _claimingRewardsCache.strength -= debuffs;
        else _claimingRewardsCache.strength = 0;

        if (_claimingRewardsCache.luck > debuffs) _claimingRewardsCache.luck -= debuffs;
        else _claimingRewardsCache.luck = 0;

        if (_claimingRewardsCache.navigation > debuffs) _claimingRewardsCache.navigation -= debuffs;
        else _claimingRewardsCache.navigation = 0;
        return _claimingRewardsCache;
    }

    function sanityCheckLockVoyages(
        LockedVoyageV2 memory _existingVoyage,
        LockedVoyageV2 memory _finishedVoyage,
        LockedVoyageV2 memory _lockedVoyage,
        VoyageConfigV2 memory _voyageConfig,
        uint256 _totalSupportShips,
        DPSFlagshipI _flagship
    ) external view override {
        // if flagship is unhealthy
        if (_flagship.getPartsLevel(_lockedVoyage.flagshipId)[uint256(FLAGSHIP_PART.HEALTH)] != 100) revert Unhealthy();

        // if it is already started
        if (_existingVoyage.voyageId != 0) revert WrongState(1);

        // if it is already finished
        if (_finishedVoyage.voyageId != 0) revert WrongState(2);

        uint256 totalArtifacts;
        for (uint256 i; i < 13; ++i) {
            if (_lockedVoyage.artifactIds[i] > 0) totalArtifacts += _lockedVoyage.artifactIds[i];
        }

        if (totalArtifacts > gameSettings.maxArtifactsPerVoyage(_voyageConfig.typeOfVoyage)) revert WrongParams(1);

        // too many support ships
        if (
            _totalSupportShips > gameSettings.maxSupportShipsPerVoyageType(_voyageConfig.typeOfVoyage) ||
            _totalSupportShips != _lockedVoyage.totalSupportShips
        ) revert WrongState(3);
    }

    /**
     * @notice computing voyage state based on the locked voyage skills and config and causality params
     * @param _lockedVoyage - locked voyage items
     * @param _sequence - sequence of interactions
     * @param _randomNumber - the random number generated for this voyage
     * @return VoyageResult - containing the results of a voyage based on interactions
     */
    function computeVoyageState(
        LockedVoyageV2 memory _lockedVoyage,
        uint8[] memory _sequence,
        uint256 _randomNumber
    ) external view override returns (VoyageResult memory) {
        uint16[3] memory features;
        DPSPirateFeaturesI dpsFeatures = featuresPerPirate[_lockedVoyage.pirate];

        if (address(dpsFeatures) != address(0)) {
            (, features) = dpsFeatures.getTraitsAndSkills(uint16(_lockedVoyage.dpsId));
        } else {
            features[0] = 150;
            features[1] = 150;
            features[2] = 150;
        }
        VoyageStatusCache memory claimingRewardsCache;

        // traits not set
        if (features[0] == 0) revert WrongState(6);
        unchecked {
            claimingRewardsCache.luck += features[0];
            claimingRewardsCache.navigation += features[1];
            claimingRewardsCache.strength += features[2];
            claimingRewardsCache = computeFlagShipSkills(
                _lockedVoyage.flagship.getPartsLevel(_lockedVoyage.flagshipId),
                claimingRewardsCache
            );
            claimingRewardsCache = computeSupportSkills(
                _lockedVoyage.supportShips,
                _lockedVoyage.artifactIds,
                claimingRewardsCache
            );

            VoyageResult memory voyageResult;
            uint256 maxRollCap = gameSettings.maxRollCap();
            voyageResult.interactionResults = new uint8[](_sequence.length);
            voyageResult.interactionRNGs = new uint16[](_sequence.length);
            voyageResult.intDestroyedSupportShips = new uint8[](_sequence.length);
            claimingRewardsCache = debuffVoyage(_lockedVoyage.voyageType, claimingRewardsCache);
            claimingRewardsCache = applyMaxSkillCap(claimingRewardsCache);

            for (uint256 i; i < _sequence.length; ++i) {
                INTERACTION interaction = INTERACTION(_sequence[i]);
                if (interaction == INTERACTION.NONE || voyageResult.healthDamage == 100) {
                    voyageResult.skippedInteractions++;
                    continue;
                }

                claimingRewardsCache.entropy = string(abi.encode("INTERACTION_RESULT_", i, "_", _lockedVoyage.voyageId));
                uint256 result = random.getRandomNumber(
                    _randomNumber,
                    _lockedVoyage.lockedBlock,
                    claimingRewardsCache.entropy,
                    0,
                    maxRollCap
                );

                (voyageResult, claimingRewardsCache) = interpretResults(
                    result,
                    voyageResult,
                    _lockedVoyage,
                    claimingRewardsCache,
                    interaction,
                    _randomNumber,
                    i
                );
                voyageResult.interactionRNGs[i] = uint16(result);
            }
            return voyageResult;
        }
    }

    function rewardChest(uint256 _randomNumber, uint256 _amount, uint256 voyageType, address _owner) external override {
        if (msg.sender != plunderers && msg.sender != owner()) revert Unauthorized();
        uint256 maxRoll = gameSettings.maxRollPerChest(voyageType);
        uint256 rewardedLockBox = 0;
        uint256 doubloonsRewards;

        for (uint256 i; i < _amount; ++i) {
            uint256 result = random.getRandomNumber(
                _randomNumber,
                nonces[_owner]++,
                string(abi.encode("REWARDS_TYPE_", i)),
                0,
                10000
            );
            emit RandomNumberGeneratedRewardChest(_owner, result);
            if (result <= maxRoll) rewardedLockBox++;
        }
        doubloonsRewards = gameSettings.chestDoubloonRewards(voyageType) * _amount;

        if (doubloonsRewards > 0) {
            doubloonsMinter.mintDoubloons(_owner, doubloonsRewards);

            uint256 doubloonsRewardForTreasury = (doubloonsRewards * 5) / 100;
            // 5% goes is minted to the treasury
            doubloonsMinter.mintDoubloons(treasury, doubloonsRewardForTreasury);
            emit TreasuryUpdate(doubloonsRewardForTreasury);
        }

        if (rewardedLockBox > 0) {
            // minting lock boxes
            chests.mint(_owner, 4, rewardedLockBox);
            emit WonLockBocks(_owner, rewardedLockBox);
        }
    }

    function rewardLockedBox(uint256 _randomNumber, uint256 _amount, address _owner) external override {
        if (msg.sender != plunderers && msg.sender != owner()) revert Unauthorized();
        ARTIFACT_TYPE[] memory artifacts = new ARTIFACT_TYPE[](_amount);

        for (uint i; i < _amount; ++i) {
            uint256 result = random.getRandomNumber(
                _randomNumber,
                nonces[_owner]++,
                string(abi.encode("LOCK_BOX_", i)),
                0,
                gameSettings.maxRollCapLockBoxes()
            );

            emit RandomNumberGeneratedRewardLockedBox(_owner, result);
            artifacts[i] = interpretLockedBoxResult(result);
        }

        for (uint i; i < _amount; ++i) {
            ARTIFACT_TYPE rewardType = artifacts[i];
            if (rewardType == ARTIFACT_TYPE.NONE) continue;
            artifact.mint(_owner, uint256(rewardType), 1);
            emit OpenedLockBox(_owner, rewardType);
        }
    }

    /**
     * @notice in case the pirate or flagship was borrowed, the owners can claim so they can claim their assets back once they expired
     *         or if none are borrowed, then the owner must be the msg.sender
     * @param _claimer who claims the voyage
     * @param _lockedVoyage the voyage we want to claim
     * @param _ownerOfVoyage the owner of the voyage stored in the docks
     */
    function checkIfViableClaimer(
        address _claimer,
        LockedVoyageV2 memory _lockedVoyage,
        address _ownerOfVoyage
    ) external view returns (bool) {
        DPSCrewForCoinI.Asset memory assetDPS = crewForCoin.isDPSInMarket(_lockedVoyage.dpsId);
        DPSCrewForCoinI.Asset memory assetFlagship = crewForCoin.isFlagshipInMarket(_lockedVoyage.flagshipId);
        if (assetDPS.borrower != address(0) || assetFlagship.borrower != address(0)) {
            return
                (crewForCoin.isDPSExpired(assetDPS.targetId) && assetDPS.lender == _claimer) ||
                assetDPS.borrower == _claimer ||
                (crewForCoin.isFlagshipExpired(assetFlagship.targetId) && assetFlagship.lender == _claimer) ||
                assetFlagship.borrower == _claimer;
        } else return _claimer == _ownerOfVoyage;
    }

    /**
     * @notice determines what type of artifact to give as reward
     * @param _result of randomness
     */
    function interpretLockedBoxResult(uint256 _result) internal view returns (ARTIFACT_TYPE) {
        unchecked {
            for (uint256 i = 1; i <= 12; ++i) {
                uint16[2] memory limits = gameSettings.getLockBoxesDistribution(ARTIFACT_TYPE(i));
                if (_result >= limits[0] && _result <= limits[1]) return ARTIFACT_TYPE(i);
            }
            return ARTIFACT_TYPE.NONE;
        }
    }

    function getLockedVoyageByOwnerAndId(
        address _owner,
        uint256 _voyageId,
        DPSVoyageIV2 _voyage
    ) external view returns (LockedVoyageV2 memory locked) {
        LockedVoyageV2[] memory cachedVoyages = docks.getLockedVoyagesForOwner(_owner, 0, _voyage.maxMintedId());
        for (uint256 i; i < cachedVoyages.length; ++i) {
            if (cachedVoyages[i].voyageId == _voyageId) return cachedVoyages[i];
        }
    }

    function getFinishedVoyageByOwnerAndId(
        address _owner,
        uint256 _voyageId,
        DPSVoyageIV2 _voyage
    ) external view returns (LockedVoyageV2 memory locked) {
        LockedVoyageV2[] memory cachedVoyages = docks.getFinishedVoyagesForOwner(_owner, 0, _voyage.maxMintedId());
        for (uint256 i; i < cachedVoyages.length; ++i) {
            if (cachedVoyages[i].voyageId == _voyageId) return cachedVoyages[i];
        }
    }

    function applyMaxSkillCap(
        VoyageStatusCache memory _claimingRewardsCache
    ) internal view returns (VoyageStatusCache memory modifiedCached) {
        uint256 maxSkillsCap = gameSettings.maxSkillsCap();
        if (_claimingRewardsCache.navigation > maxSkillsCap) _claimingRewardsCache.navigation = maxSkillsCap;

        if (_claimingRewardsCache.luck > maxSkillsCap) _claimingRewardsCache.luck = maxSkillsCap;

        if (_claimingRewardsCache.strength > maxSkillsCap) _claimingRewardsCache.strength = maxSkillsCap;
        modifiedCached = _claimingRewardsCache;
    }

    /**
     * SETTERS & GETTERS
     */
    function setContract(address _contract, uint8 _target) external onlyOwner {
        if (_target == 1) random = DPSQRNGI(_contract);
        else if (_target == 2) supportShip = DPSSupportShipI(_contract);
        else if (_target == 3) artifact = MintableBurnableIERC1155(_contract);
        else if (_target == 4) gameSettings = DPSGameSettingsI(_contract);
        else if (_target == 5) cartographer = DPSCartographerI(_contract);
        else if (_target == 6) chests = DPSChestsIV2(_contract);
        else if (_target == 7) docks = DPSDocksI(_contract);
        else if (_target == 8) doubloonsMinter = DPSDoubloonMinterI(_contract);
        else if (_target == 9) treasury = _contract;
        else if (_target == 10) plunderers = _contract;
        else if (_target == 11) crewForCoin = DPSCrewForCoinI(_contract);
        emit SetContract(_target, _contract);
    }

    function setFeaturesPerPirate(IERC721 _pirate, DPSPirateFeaturesI _feature) external onlyOwner {
        featuresPerPirate[_pirate] = _feature;
        emit FeaturesPerPirateChanged(_pirate, _feature);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "./DPSStructs.sol";

interface DPSVoyageI is IERC721Enumerable {
    function mint(address _owner, uint256 _tokenId, VoyageConfig calldata config) external;

    function burn(uint256 _tokenId) external;

    function getVoyageConfig(uint256 _voyageId) external view returns (VoyageConfig memory config);

    function tokensOfOwner(address _owner) external view returns (uint256[] memory);

    function exists(uint256 _tokenId) external view returns (bool);

    function maxMintedId() external view returns (uint256);

    function maxMintedId(uint16 _voyageType) external view returns (uint256);
}

interface DPSVoyageIV2 is IERC721Enumerable {
    function mint(address _owner, uint256 _tokenId, VoyageConfigV2 calldata config) external;

    function burn(uint256 _tokenId) external;

    function getVoyageConfig(uint256 _voyageId) external view returns (VoyageConfigV2 memory config);

    function tokensOfOwner(address _owner) external view returns (uint256[] memory);

    function exists(uint256 _tokenId) external view returns (bool);

    function maxMintedId() external view returns (uint256);

    function maxMintedId(uint16 _voyageType) external view returns (uint256);
}

interface DPSRandomI {
    function getRandomBatch(
        address _address,
        uint256[] memory _blockNumber,
        bytes32[] memory _hash1,
        bytes32[] memory _hash2,
        uint256[] memory _timestamp,
        bytes[] calldata _signature,
        string[] calldata _entropy,
        uint256 _min,
        uint256 _max
    ) external view returns (uint256[] memory randoms);

    function getRandomUnverifiedBatch(
        address _address,
        uint256[] memory _blockNumber,
        bytes32[] memory _hash1,
        bytes32[] memory _hash2,
        uint256[] memory _timestamp,
        string[] calldata _entropy,
        uint256 _min,
        uint256 _max
    ) external pure returns (uint256[] memory randoms);

    function getRandom(
        address _address,
        uint256 _blockNumber,
        bytes32 _hash1,
        bytes32 _hash2,
        uint256 _timestamp,
        bytes calldata _signature,
        string calldata _entropy,
        uint256 _min,
        uint256 _max
    ) external view returns (uint256 randoms);

    function getRandomUnverified(
        address _address,
        uint256 _blockNumber,
        bytes32 _hash1,
        bytes32 _hash2,
        uint256 _timestamp,
        string calldata _entropy,
        uint256 _min,
        uint256 _max
    ) external pure returns (uint256 randoms);

    function checkCausalityParams(
        CausalityParams calldata _causalityParams,
        VoyageConfigV2 calldata _voyageConfig,
        LockedVoyageV2 calldata _lockedVoyage
    ) external pure;
}

interface DPSGameSettingsI {
    function voyageConfigPerType(uint256 _type) external view returns (CartographerConfig memory);

    function maxSkillsCap() external view returns (uint16);

    function maxRollCap() external view returns (uint16);

    function flagshipBaseSkills() external view returns (uint16);

    function maxOpenLockBoxes() external view returns (uint256);

    function getSkillsPerFlagshipParts() external view returns (uint16[7] memory skills);

    function getSkillTypeOfEachFlagshipPart() external view returns (uint8[7] memory skillTypes);

    function tmapPerVoyage(uint256 _type) external view returns (uint256);

    function gapBetweenVoyagesCreation() external view returns (uint256);

    function isPaused(uint8 _component) external returns (uint8);

    function isPausedNonReentrant(uint8 _component) external view;

    function tmapPerDoubloon() external view returns (uint256);

    function repairFlagshipCost() external view returns (uint256);

    function doubloonPerFlagshipUpgradePerLevel(uint256 _level) external view returns (uint256);

    function voyageDebuffs(uint256 _type) external view returns (uint16);

    function maxArtifactsPerVoyage(uint16 _type) external view returns (uint256);

    function chestDoubloonRewards(uint256 _type) external view returns (uint256);

    function doubloonsPerSupportShipType(SUPPORT_SHIP_TYPE _type) external view returns (uint256);

    function supportShipsSkillBoosts(SUPPORT_SHIP_TYPE _type) external view returns (uint16);

    function maxSupportShipsPerVoyageType(uint256 _type) external view returns (uint8);

    function maxRollPerChest(uint256 _type) external view returns (uint256);

    function maxRollCapLockBoxes() external view returns (uint16);

    function lockBoxesDistribution(ARTIFACT_TYPE _type) external view returns (uint16[2] memory);

    function getLockBoxesDistribution(ARTIFACT_TYPE _type) external view returns (uint16[2] memory);

    function artifactsSkillBoosts(ARTIFACT_TYPE _type) external view returns (uint16);
}

interface DPSGameEngineI {
    function sanityCheckLockVoyages(
        LockedVoyageV2 memory existingVoyage,
        LockedVoyageV2 memory finishedVoyage,
        LockedVoyageV2 memory lockedVoyage,
        VoyageConfigV2 memory voyageConfig,
        uint256 totalSupportShips,
        DPSFlagshipI _flagship
    ) external view;

    function computeVoyageState(
        LockedVoyageV2 memory _lockedVoyage,
        uint8[] memory _sequence,
        uint256 _randomNumber
    ) external view returns (VoyageResult memory);

    function rewardChest(
        uint256 _randomNumber,
        uint256 _amount,
        uint256 _voyageType,
        address _owner
    ) external;

    function rewardLockedBox(
        uint256 _randomNumber,
        uint256 _amount,
        address _owner
    ) external;

    function checkIfViableClaimer(
        address _claimer,
        LockedVoyageV2 memory _lockedVoyage,
        address _ownerOfVoyage
    ) external view returns (bool);
}

interface DPSPirateFeaturesI {
    function getTraitsAndSkills(uint16 _dpsId) external view returns (string[8] memory, uint16[3] memory);
}

interface DPSSupportShipI is IERC1155 {
    function burn(address _from, uint256 _type, uint256 _amount) external;

    function mint(address _owner, uint256 _type, uint256 _amount) external;
}

interface DPSFlagshipI is IERC721 {
    function mint(address _owner, uint256 _id) external;

    function burn(uint256 _id) external;

    function upgradePart(FLAGSHIP_PART _trait, uint256 _tokenId, uint8 _level) external;

    function getPartsLevel(uint256 _flagshipId) external view returns (uint8[7] memory);

    function tokensOfOwner(address _owner) external view returns (uint256[] memory);

    function exists(uint256 _tokenId) external view returns (bool);
}

interface DPSCartographerI {
    function viewVoyageConfiguration(
        uint256 _voyageId,
        DPSVoyageIV2 _voyage
    ) external view returns (VoyageConfigV2 memory voyageConfig);

    function buyers(uint256 _voyageId) external view returns (address);
}

interface DPSChestsI is IERC1155 {
    function mint(address _to, uint16 _voyageType, uint256 _amount) external;

    function burn(address _from, uint16 _voyageType, uint256 _amount) external;
}

interface DPSChestsIV2 is IERC1155 {
    function mint(address _to, uint256 _type, uint256 _amount) external;

    function burn(address _from, uint256 _type, uint256 _amount) external;
}

interface MintableBurnableIERC1155 is IERC1155 {
    function mint(address _to, uint256 _type, uint256 _amount) external;

    function burn(address _from, uint256 _type, uint256 _amount) external;
}

interface DPSDocksI {
    function getFinishedVoyagesForOwner(
        address _owner,
        uint256 _start,
        uint256 _stop
    ) external view returns (LockedVoyageV2[] memory finished);

    function getLockedVoyagesForOwner(
        address _owner,
        uint256 _start,
        uint256 _stop
    ) external view returns (LockedVoyageV2[] memory locked);
}

interface DPSQRNGI {
    function makeRequestUint256(bytes calldata _uniqueId) external;

    function makeRequestUint256Array(uint256 _size, bytes32 _uniqueId) external;

    function getRandomResult(bytes calldata _uniqueId) external view returns (uint256);

    function getRandomResultArray(bytes32 _uniqueId) external view returns (uint256[] memory);

    function getRandomNumber(
        uint256 _randomNumber,
        uint256 _blockNumber,
        string calldata _entropy,
        uint256 _min,
        uint256 _max
    ) external pure returns (uint256);
}

interface DPSCrewForCoinI {
    struct Asset {
        uint32 targetId;
        bool borrowed;
        address borrower;
        uint32 epochs;
        address lender;
        uint64 startTime;
        uint64 endTime;
        uint256 doubloonsPerEpoch;
    }

    function isDPSInMarket(uint256 _tokenId) external view returns (Asset memory);

    function isFlagshipInMarket(uint256 _tokenId) external view returns (Asset memory);

    function isDPSExpired(uint256 _assetId) external view returns (bool);

    function isFlagshipExpired(uint256 _assetId) external view returns (bool);
}

interface DPSDoubloonMinterI {
    function mintDoubloons(address _to, uint256 _amount) external;

    function burnDoubloons(address _from, uint256 _amount) external;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./DPSInterfaces.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

enum VOYAGE_TYPE {
    EASY,
    MEDIUM,
    HARD,
    LEGENDARY,
    CUSTOM
}

enum SUPPORT_SHIP_TYPE {
    SLOOP_STRENGTH,
    SLOOP_LUCK,
    SLOOP_NAVIGATION,
    CARAVEL_STRENGTH,
    CARAVEL_LUCK,
    CARAVEL_NAVIGATION,
    GALLEON_STRENGTH,
    GALLEON_LUCK,
    GALLEON_NAVIGATION
}

enum ARTIFACT_TYPE {
    NONE,
    COMMON_STRENGTH,
    COMMON_LUCK,
    COMMON_NAVIGATION,
    RARE_STRENGTH,
    RARE_LUCK,
    RARE_NAVIGATION,
    EPIC_STRENGTH,
    EPIC_LUCK,
    EPIC_NAVIGATION,
    LEGENDARY_STRENGTH,
    LEGENDARY_LUCK,
    LEGENDARY_NAVIGATION
}

enum INTERACTION {
    NONE,
    CHEST,
    STORM,
    ENEMY
}

enum FLAGSHIP_PART {
    HEALTH,
    CANNON,
    HULL,
    SAILS,
    HELM,
    FLAG,
    FIGUREHEAD
}

enum SKILL_TYPE {
    LUCK,
    STRENGTH,
    NAVIGATION
}

struct VoyageConfig {
    VOYAGE_TYPE typeOfVoyage;
    uint8 noOfInteractions;
    uint16 noOfBlockJumps;
    // 1 - Chest 2 - Storm 3 - Enemy
    uint8[] sequence;
    uint256 boughtAt;
    uint256 gapBetweenInteractions;
}

struct VoyageConfigV2 {
    uint16 typeOfVoyage;
    uint8 noOfInteractions;
    // 1 - Chest 2 - Storm 3 - Enemy
    uint8[] sequence;
    uint256 boughtAt;
    uint256 gapBetweenInteractions;
    bytes uniqueId;
}

struct CartographerConfig {
    uint8 minNoOfChests;
    uint8 maxNoOfChests;
    uint8 minNoOfStorms;
    uint8 maxNoOfStorms;
    uint8 minNoOfEnemies;
    uint8 maxNoOfEnemies;
    uint8 totalInteractions;
    uint256 gapBetweenInteractions;
}

struct RandomInteractions {
    uint256 randomNoOfChests;
    uint256 randomNoOfStorms;
    uint256 randomNoOfEnemies;
    uint8 generatedChests;
    uint8 generatedStorms;
    uint8 generatedEnemies;
    uint256[] positionsForGeneratingInteractions;
    uint256 randomPosition;
}

struct CausalityParams {
    uint256[] blockNumber;
    bytes32[] hash1;
    bytes32[] hash2;
    uint256[] timestamp;
    bytes[] signature;
}

struct LockedVoyage {
    uint8 totalSupportShips;
    VOYAGE_TYPE voyageType;
    ARTIFACT_TYPE artifactId;
    uint8[9] supportShips; //this should be an array for each type, expressing the quantities he took on a trip
    uint8[] sequence;
    uint16 navigation;
    uint16 luck;
    uint16 strength;
    uint256 voyageId;
    uint256 dpsId;
    uint256 flagshipId;
    uint256 lockedBlock;
    uint256 lockedTimestamp;
    uint256 claimedTime;
}

struct LockedVoyageV2 {
    uint8 totalSupportShips;
    uint16 voyageType;
    uint16[13] artifactIds;
    uint8[9] supportShips; //this should be an array for each type, expressing the quantities he took on a trip
    uint8[] sequence;
    uint16 navigation;
    uint16 luck;
    uint16 strength;
    uint256 voyageId;
    uint256 dpsId;
    uint256 flagshipId;
    uint256 lockedBlock;
    uint256 lockedTimestamp;
    uint256 claimedTime;
    bytes uniqueId;
    DPSVoyageIV2 voyage;
    IERC721Metadata pirate;
    DPSFlagshipI flagship;
}

struct VoyageResult {
    uint16 awardedChests;
    uint8[9] destroyedSupportShips;
    uint8 totalSupportShipsDestroyed;
    uint8 healthDamage;
    uint16 skippedInteractions;
    uint16[] interactionRNGs;
    uint8[] interactionResults;
    uint8[] intDestroyedSupportShips;
}

struct VoyageStatusCache {
    uint256 strength;
    uint256 luck;
    uint256 navigation;
    string entropy;
}

error AddressZero();
error Paused();
error WrongParams(uint256 _location);
error WrongState(uint256 _state);
error Unauthorized();
error NotEnoughTokens();
error Unhealthy();
error ExternalCallFailed();
error NotFulfilled();
error NotViableClaimer();
error InvalidPartToUpgrade();