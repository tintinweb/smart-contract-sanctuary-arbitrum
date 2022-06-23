// SPDX-License-Identifier: GPL-3.0

/// @title The Lucid Longhorns ERC-721 token

/*********************************
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░██░░░████░░██░░░████░░░ *
 * ░░██████░░░████████░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 *********************************/

pragma solidity ^0.8.6;

import { Ownable } from './Ownable.sol';
import { ERC721Checkpointable } from './ERC721Checkpointable.sol';
import { ILucidLonghornsDescriptor } from './ILucidLonghornsDescriptor.sol';
import { ILucidLonghornsSeeder } from './ILucidLonghornsSeeder.sol';
import { ILucidLonghornsToken } from './ILucidLonghornsToken.sol';
import { ERC721 } from './ERC721.sol';
import { IERC721 } from './IERC721.sol';
import { IProxyRegistry } from './IProxyRegistry.sol';

contract LucidLonghornsToken is ILucidLonghornsToken, Ownable, ERC721Checkpointable {
    // The founders DAO address
    address public foundersDAO;

    // The Texas Blockchain address
    address public txBlockchain;

    // The artist address
    address public artist;

    // The developer address
    address public developer;

    // An address who has permissions to mint Lucid Longhorns
    address public minter;

    // The Lucid Longhorns token URI descriptor
    ILucidLonghornsDescriptor public descriptor;

    // The Lucid Longhorns token seeder
    ILucidLonghornsSeeder public seeder;

    // Whether the minter can be updated
    bool public isMinterLocked;

    // Whether the descriptor can be updated
    bool public isDescriptorLocked;

    // Whether the seeder can be updated
    bool public isSeederLocked;

    // The lucid longhorn seeds
    mapping(uint256 => ILucidLonghornsSeeder.Seed) public seeds;

    // The internal lucid longhorn ID tracker
    uint256 private _currentLucidLonghornId;

    // IPFS content hash of contract-level metadata
    string private _contractURIHash = 'QmZi1n79FqWt2tTLwCqiy6nLM6xLGRsEPQ5JmReJQKNNzX';

    // The founder to reward next
    uint256 private _founderToReward;

    // OpenSea's Proxy Registry
    IProxyRegistry public immutable proxyRegistry;

    /**
     * @notice Require that the minter has not been locked.
     */
    modifier whenMinterNotLocked() {
        require(!isMinterLocked, 'Minter is locked');
        _;
    }

    /**
     * @notice Require that the descriptor has not been locked.
     */
    modifier whenDescriptorNotLocked() {
        require(!isDescriptorLocked, 'Descriptor is locked');
        _;
    }

    /**
     * @notice Require that the seeder has not been locked.
     */
    modifier whenSeederNotLocked() {
        require(!isSeederLocked, 'Seeder is locked');
        _;
    }

    /**
     * @notice Require that the sender is the founders DAO.
     */
    modifier onlyFoundersDAO() {
        require(msg.sender == foundersDAO, 'Sender is not the founders DAO');
        _;
    }

    /**
     * @notice Require that the sender is the minter.
     */
    modifier onlyMinter() {
        require(msg.sender == minter, 'Sender is not the minter');
        _;
    }

    constructor(
        address _foundersDAO,
        address _txBlockchain,
        address _artist,
        address _developer,
        address _minter,
        ILucidLonghornsDescriptor _descriptor,
        ILucidLonghornsSeeder _seeder,
        IProxyRegistry _proxyRegistry
    ) ERC721('Lucid Longhorns', 'LL') {
        foundersDAO = _foundersDAO;
        txBlockchain = _txBlockchain;
        artist = _artist;
        developer = _developer;
        minter = _minter;
        descriptor = _descriptor;
        seeder = _seeder;
        proxyRegistry = _proxyRegistry;
    }

    /**
     * @notice The IPFS URI of contract-level metadata.
     */
    function contractURI() public view returns (string memory) {
        return string(abi.encodePacked('ipfs://', _contractURIHash));
    }

    /**
     * @notice Set the _contractURIHash.
     * @dev Only callable by the owner.
     */
    function setContractURIHash(string memory newContractURIHash) external onlyOwner {
        _contractURIHash = newContractURIHash;
    }

    /**
     * @notice Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator) public view override(IERC721, ERC721) returns (bool) {
        // Whitelist OpenSea proxy contract for easy trading.
        if (proxyRegistry.proxies(owner) == operator) {
            return true;
        }
        return super.isApprovedForAll(owner, operator);
    }

    /**
     * @notice Mint a Lucid Longhorn to the minter, along with a possible founders reward
     * Lucid Longhorn. Founders reward Lucid Longhorns are minted every 10 Lucid Longhorns, starting at 0,
     * until 183 founder Lucid Longhorns have been minted (5 years w/ 24 hour auctions).
     * @dev Call _mintTo with the to address(es).
     */
    function mint() public override onlyMinter returns (uint256) {
        if (_currentLucidLonghornId <= 1820 && _currentLucidLonghornId % 10 == 0) {
            if (_founderToReward == 1) {
                _mintTo(txBlockchain, _currentLucidLonghornId++);
                _founderToReward += 1;
            } else if (_founderToReward == 2) {
                _mintTo(artist, _currentLucidLonghornId++);
                _founderToReward += 1;
            } else {
                _mintTo(developer, _currentLucidLonghornId++);
                _founderToReward = 1;
            }
        }
        return _mintTo(minter, _currentLucidLonghornId++);
    }

    /**
     * @notice Burn a lucid longhorn.
     */
    function burn(uint256 lucidLonghornId) public override onlyMinter {
        _burn(lucidLonghornId);
        emit LucidLonghornBurned(lucidLonghornId);
    }

    /**
     * @notice A distinct Uniform Resource Identifier (URI) for a given asset.
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), 'LucidLonghornsToken: URI query for nonexistent token');
        return descriptor.tokenURI(tokenId, seeds[tokenId]);
    }

    /**
     * @notice Similar to `tokenURI`, but always serves a base64 encoded data URI
     * with the JSON contents directly inlined.
     */
    function dataURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), 'LucidLonghornsToken: URI query for nonexistent token');
        return descriptor.dataURI(tokenId, seeds[tokenId]);
    }

    /**
     * @notice Set the founders DAO.
     * @dev Only callable by the founders DAO when not locked.
     */
    function setFoundersDAO(address _foundersDAO) external override onlyFoundersDAO {
        foundersDAO = _foundersDAO;

        emit FoundersDAOUpdated(_foundersDAO);
    }

    /**
     * @notice Set the Texas Blockchain.
     * @dev Only callable by the founders DAO when not locked.
     */
    function setTxBlockchain(address _txBlockchain) external override onlyFoundersDAO {
        txBlockchain = _txBlockchain;

        emit TxBlockchainUpdated(_txBlockchain);
    }

    /**
     * @notice Set the artist.
     * @dev Only callable by the founders DAO when not locked.
     */
    function setArtist(address _artist) external override onlyFoundersDAO {
        artist = _artist;

        emit ArtistUpdated(_artist);
    }

    /**
     * @notice Set the developer.
     * @dev Only callable by the founders DAO when not locked.
     */
    function setDeveloper(address _developer) external override onlyFoundersDAO {
        developer = _developer;

        emit DeveloperUpdated(_developer);
    }

    /**
     * @notice Set the token minter.
     * @dev Only callable by the owner when not locked.
     */
    function setMinter(address _minter) external override onlyOwner whenMinterNotLocked {
        minter = _minter;

        emit MinterUpdated(_minter);
    }

    /**
     * @notice Lock the minter.
     * @dev This cannot be reversed and is only callable by the owner when not locked.
     */
    function lockMinter() external override onlyOwner whenMinterNotLocked {
        isMinterLocked = true;

        emit MinterLocked();
    }

    /**
     * @notice Set the token URI descriptor.
     * @dev Only callable by the owner when not locked.
     */
    function setDescriptor(ILucidLonghornsDescriptor _descriptor) external override onlyOwner whenDescriptorNotLocked {
        descriptor = _descriptor;

        emit DescriptorUpdated(_descriptor);
    }

    /**
     * @notice Lock the descriptor.
     * @dev This cannot be reversed and is only callable by the owner when not locked.
     */
    function lockDescriptor() external override onlyOwner whenDescriptorNotLocked {
        isDescriptorLocked = true;

        emit DescriptorLocked();
    }

    /**
     * @notice Set the token seeder.
     * @dev Only callable by the owner when not locked.
     */
    function setSeeder(ILucidLonghornsSeeder _seeder) external override onlyOwner whenSeederNotLocked {
        seeder = _seeder;

        emit SeederUpdated(_seeder);
    }

    /**
     * @notice Lock the seeder.
     * @dev This cannot be reversed and is only callable by the owner when not locked.
     */
    function lockSeeder() external override onlyOwner whenSeederNotLocked {
        isSeederLocked = true;

        emit SeederLocked();
    }

    /**
     * @notice Mint a Lucid Longhorn with `lucidLonghornId` to the provided `to` address.
     */
    function _mintTo(address to, uint256 lucidLonghornId) internal returns (uint256) {
        ILucidLonghornsSeeder.Seed memory seed = seeds[lucidLonghornId] = seeder.generateSeed(lucidLonghornId, descriptor);

        _mint(owner(), to, lucidLonghornId);
        emit LucidLonghornCreated(lucidLonghornId, seed);

        return lucidLonghornId;
    }
}