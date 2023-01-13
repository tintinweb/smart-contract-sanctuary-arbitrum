// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

/*

School.sol

Written by: mousedev.eth

*/
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./utilities/OwnableOrAdminable.sol";

contract School is OwnableOrAdminable {
    struct TokenDetails {
        uint128 statAccrued;
        uint64 timestampJoined;
        bool joined;
    }

    struct StatDetails {
        uint128 globalStatAccrued;
        uint128 emissionRate;
        bool exists;
        bool joinable;
    }

    mapping(address => bool) public allowedAdjuster;

    //Each tokens details within a stat within a collection.
    //Collection address to statId to tokenId to token details.
    mapping(address => mapping(uint64 => mapping(uint256 => TokenDetails)))
        public tokenDetails;

    //A record of how many stats this token is in at once.
    mapping(address => mapping(uint256 => uint256))
        public totalStatsJoinedWithinCollection;

    //Each stat details within a collection.
    //Collection address to statId to stat details.
    mapping(address => mapping(uint256 => StatDetails)) public statDetails;

    /**
     * @dev Joins a stat with a tokenId.
     * @param _collectionAddress collection address token belongs to
     * @param _statId statId to join
     * @param _tokenIds tokens to join stat with
     */
    function joinStat(
        address _collectionAddress,
        uint64 _statId,
        uint256[] memory _tokenIds
    ) external {
        //Require this stat exists.
        require(
            statDetails[_collectionAddress][_statId].exists,
            "Stat does not exist!"
        );
        //Require stat is joinable.
        require(
            statDetails[_collectionAddress][_statId].joinable,
            "Stat not currently joinable!"
        );

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            uint256 _tokenId = _tokenIds[i];

            //Require they are the owner of this token
            require(
                msg.sender == IERC721(_collectionAddress).ownerOf(_tokenId),
                "You don't own this token!"
            );
            //Require they are not currently in this stat.
            require(
                tokenDetails[_collectionAddress][_statId][_tokenId].joined ==
                    false,
                "Token already joined this stat!"
            );

            //Set the timestamp and joined vars.
            tokenDetails[_collectionAddress][_statId][_tokenId] = TokenDetails(
                tokenDetails[_collectionAddress][_statId][_tokenId].statAccrued,
                uint64(block.timestamp),
                true
            );

            //Increment their total stats joined by one
            totalStatsJoinedWithinCollection[_collectionAddress][_tokenId]++;
        }
    }

    /**
     * @dev Leaves a stat with a tokenId.
     * @param _collectionAddress collection address token belongs to
     * @param _statId statId to leave
     * @param _tokenIds tokens to leave stat with
     */
    function leaveStat(
        address _collectionAddress,
        uint64 _statId,
        uint256[] memory _tokenIds
    ) external {
        //Require this stat exists.
        require(
            statDetails[_collectionAddress][_statId].exists,
            "Stat does not exist!"
        );

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            uint256 _tokenId = _tokenIds[i];

            //Require they are the owner of this.
            require(
                msg.sender == IERC721(_collectionAddress).ownerOf(_tokenId),
                "You don't own this token!"
            );

            //Create an in memory struct of the token details.
            TokenDetails memory _thisTokenDetails = tokenDetails[
                _collectionAddress
            ][_statId][_tokenId];

            //Require is it locked in order to leave.
            require(_thisTokenDetails.joined, "Token not in this stat!");

            //Get how many seconds passed this joining.
            uint128 timeElapsed = uint128(block.timestamp) -
                _thisTokenDetails.timestampJoined;

            //Multiply that by emission rate to get total stat accrued.
            uint128 statAccrued = statDetails[_collectionAddress][_statId]
                .emissionRate * timeElapsed;

            //Set statAccrued and clear timestamp and joined vars.
            tokenDetails[_collectionAddress][_statId][_tokenId] = TokenDetails(
                _thisTokenDetails.statAccrued + statAccrued,
                0,
                false
            );

            //Add this much stat to global accrual of this stat.
            statDetails[_collectionAddress][_statId]
                .globalStatAccrued += statAccrued;

            //Decrement their total stats joined by one
            totalStatsJoinedWithinCollection[_collectionAddress][_tokenId]--;
        }
    }

    /**
     * @dev Gets pending emissions on stat.
     * @param _collectionAddress collection address token belongs to
     * @param _statId statId to get
     * @param _tokenId token to get stat with
     */
    function getPendingStatEmissions(
        address _collectionAddress,
        uint64 _statId,
        uint256 _tokenId
    ) public view returns (uint128) {
        //Require this stat exists.
        require(
            statDetails[_collectionAddress][_statId].exists,
            "Stat does not exist!"
        );

        //Create an in memory struct of the token details.
        TokenDetails memory _thisTokenDetails = tokenDetails[
            _collectionAddress
        ][_statId][_tokenId];

        //This is for view functions that request pending emissions in order to do things.
        if (!_thisTokenDetails.joined) return 0;

        //Get how many seconds passed this joining.
        uint128 timeElapsed = uint128(block.timestamp) -
            _thisTokenDetails.timestampJoined;

        //Multiply that by emission rate to get total stat accrued.
        uint128 statAccrued = statDetails[_collectionAddress][_statId]
            .emissionRate * timeElapsed;

        return statAccrued;
    }

    /**
     * @dev Claims total stat for a token PLUS it's pending stat emission.
     * @param _collectionAddress collection address token belongs to
     * @param _statId statId to get
     * @param _tokenId token to get for
     */
    function getTotalStatPlusPendingEmissions(address _collectionAddress, uint64 _statId, uint256 _tokenId) external view returns (uint128){
        return getPendingStatEmissions(_collectionAddress, _statId, _tokenId) + tokenDetails[_collectionAddress][_statId][_tokenId].statAccrued;
    }

    /**
     * @dev Claims pending emissions on stat.
     * @param _collectionAddress collection address token belongs to
     * @param _statId statId to claim
     * @param _tokenIds tokens to claim stat with
     */
    function claimPendingStatEmissions(
        address _collectionAddress,
        uint64 _statId,
        uint256[] memory _tokenIds
    ) external {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            uint256 _tokenId = _tokenIds[i];

            //Require they are the owner of this.
            require(
                msg.sender == IERC721(_collectionAddress).ownerOf(_tokenId),
                "You don't own this token!"
            );

            //Create an in memory struct of the token details.
            TokenDetails memory _thisTokenDetails = tokenDetails[
                _collectionAddress
            ][_statId][_tokenId];

            //Require it is joined, to claim.
            require(_thisTokenDetails.joined, "Token not in this stat!");

            //Multiply that by emission rate to get total stat accrued.
            uint128 statAccrued = getPendingStatEmissions(
                _collectionAddress,
                _statId,
                _tokenId
            );

            //Set statAccrued and clear timestamp and joined vars.
            tokenDetails[_collectionAddress][_statId][_tokenId] = TokenDetails(
                _thisTokenDetails.statAccrued + statAccrued,
                uint64(block.timestamp),
                true
            );

            //Add this much stat to global accrual of this stat.
            statDetails[_collectionAddress][_statId]
                .globalStatAccrued += statAccrued;
        }
    }

    /**
     * @dev Sets an allowed adjuster.
     * @param _adjuster address to set
     * @param _allowed whether this address is allowed
     */
    function setAllowedAdjuster(address _adjuster, bool _allowed)
        external
        onlyOwnerOrAdmin
    {
        allowedAdjuster[_adjuster] = _allowed;
    }

    /**
     * @dev Removes stats from a token.
     * @param _collectionAddress Address this token belongs to.
     * @param _statId StatId to adjust.
     * @param _tokenId TokenId to remove stats from.
     * @param _amountOfStatToRemove amount of stat to remove.
     */
    function removeStatAsAllowedAdjuster(
        address _collectionAddress,
        uint64 _statId,
        uint256 _tokenId,
        uint128 _amountOfStatToRemove
    ) external {
        require(
            allowedAdjuster[msg.sender],
            "You are not an allowed adjuster!"
        );
        tokenDetails[_collectionAddress][_statId][_tokenId]
            .statAccrued -= _amountOfStatToRemove;

        statDetails[_collectionAddress][_statId]
            .globalStatAccrued -= _amountOfStatToRemove;
    }

    /**
     * @dev Add stats to a token.
     * @param _collectionAddress Address this token belongs to.
     * @param _statId StatId to adjust.
     * @param _tokenId TokenId to add stats to.
     * @param _amountOfStatToAdd amount of stat to add.
     */
    function addStatAsAllowedAdjuster(
        address _collectionAddress,
        uint64 _statId,
        uint256 _tokenId,
        uint128 _amountOfStatToAdd
    ) external {
        require(
            allowedAdjuster[msg.sender],
            "You are not an allowed adjuster!"
        );
        tokenDetails[_collectionAddress][_statId][_tokenId]
            .statAccrued += _amountOfStatToAdd;

        statDetails[_collectionAddress][_statId]
            .globalStatAccrued += _amountOfStatToAdd;
    }

    /**
     * @dev Creates a stat for a collection.
     * @param _collectionAddress Address to add stat for.
     * @param _statId StatID of stat.
     * @param _statDetails Stat details.
     */
    function setStatDetails(
        address _collectionAddress,
        uint64 _statId,
        StatDetails memory _statDetails
    ) external onlyOwnerOrAdmin {
        require(
            !statDetails[_collectionAddress][_statId].exists,
            "Stat already initialized"
        );
        //Don't override globalStatAccrued
        statDetails[_collectionAddress][_statId].emissionRate = _statDetails
            .emissionRate;
        statDetails[_collectionAddress][_statId].emissionRate = _statDetails
            .emissionRate;
        statDetails[_collectionAddress][_statId].joinable = _statDetails
            .joinable;
        //Ensure exists is true.
        statDetails[_collectionAddress][_statId].exists = true;
    }

    /**
     * @dev Adjusts a stat for a collection.
     * @param _collectionAddress Address to adjust stat for.
     * @param _statId StatID of stat.
     * @param _statDetails Stat details.
     */
    function adjustStatDetails(
        address _collectionAddress,
        uint64 _statId,
        StatDetails memory _statDetails
    ) external onlyOwnerOrAdmin {
        require(
            statDetails[_collectionAddress][_statId].exists,
            "Stat doesn't exist!"
        );
        //Don't overwrite globalStatAccrued
        statDetails[_collectionAddress][_statId].emissionRate = _statDetails
            .emissionRate;
        statDetails[_collectionAddress][_statId].joinable = _statDetails
            .joinable;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

abstract contract OwnableOrAdminable {
    address private _owner;

    mapping(address => bool) private _isAdmin;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(msg.sender);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwnerOrAdmin() {
        require(
            owner() == msg.sender || _isAdmin[msg.sender],
            "Ownable: caller is not the owner or admin"
        );
        _;
    }

    /**
     * @dev Allows owner or admin to add admins
     */

    function setAdmins(address[] memory _addresses, bool[] memory _isAdmins) public {
        require(
            owner() == msg.sender,
            "Ownable: caller is not the owner"
        );

        for (uint256 i = 0; i < _addresses.length; i++) {
            _isAdmin[_addresses[i]] = _isAdmins[i];
        }
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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