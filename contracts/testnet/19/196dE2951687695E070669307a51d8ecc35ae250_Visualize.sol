// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (metatx/ERC2771Context.sol)

pragma solidity ^0.8.9;

import "../utils/Context.sol";

/**
 * @dev Context variant with ERC2771 support.
 */
abstract contract ERC2771Context is Context {
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    address private immutable _trustedForwarder;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address trustedForwarder) {
        _trustedForwarder = trustedForwarder;
    }

    function isTrustedForwarder(address forwarder) public view virtual returns (bool) {
        return forwarder == _trustedForwarder;
    }

    function _msgSender() internal view virtual override returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            /// @solidity memory-safe-assembly
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return super._msgSender();
        }
    }

    function _msgData() internal view virtual override returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return super._msgData();
        }
    }
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
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/metatx/ERC2771Context.sol";

/**
 * @title Visualize contract
 * @notice This contract is used to interact with the visualize app database
 * @author polarzero
 * @dev ...
 */

/// Errors
error VISUALIZE__NOT_OWNER();
error VISUALIZE__NOT_IN_ALLOWLIST(); // ? only on mainnet
error ERC2771Context__NOT_FORWARDER();
// Favorites
error VISUALIZE__ALREADY_FAVORITE();
error VISUALIZE__NOT_FAVORITE();
// URL
error VISUALIZE__INVALID_URL();

contract Visualize is ERC2771Context {
    /// Structs
    // ...

    /// Constants
    // ...

    /// Variables
    address private immutable i_owner;
    address private s_trustedForwarder;
    string private s_baseUrl;
    // Shortened URLs
    string[] private s_shortenedURLs;

    /// Mappings
    // Allowlist
    mapping(address => bool) private s_allowlist; // ? only on mainnet
    // Favorites
    mapping(address => string[]) private s_favorites;

    /// Events
    event VISUALIZE__ALLOWLISTED(address[] _addresses); // ? only on mainnet
    event VISUALIZE__REMOVED_FROM_ALLOWLIST(address[] _addresses); // ? only on mainnet
    event VISUALIZE__FAVORITE_ADDED(address _address, string _favorite);
    event VISUALIZE__FAVORITE_REMOVED(address _address, string _favorite);
    event VISUALIZE__URL_SHORTENED(uint256 _id, string _url, address _sender);
    // Dev functions
    event ERC2771Context__TRUSTED_FORWARDER_UPDATED(address _address);
    event VISUALIZE__BASE_URL_UPDATED(string _baseUrl);

    /// Modifiers
    modifier onlyOwner() {
        if (_msgSender() != i_owner) revert VISUALIZE__NOT_OWNER();
        _;
    }

    // ? only on mainnet
    modifier onlyAllowlist() {
        if (!s_allowlist[_msgSender()]) revert VISUALIZE__NOT_IN_ALLOWLIST();
        _;
    }

    modifier onlyForwarder() {
        if (!isTrustedForwarder(_msgSender()))
            revert ERC2771Context__NOT_FORWARDER();
        _;
    }

    /**
     * @notice Constructor
     */
    constructor(
        address _trustedForwarder,
        string memory _baseUrl
    )
        // Let's just initialize it anyway, even if overriden
        ERC2771Context(address(_trustedForwarder))
    {
        i_owner = _msgSender();
        s_trustedForwarder = _trustedForwarder;
        s_baseUrl = _baseUrl;
    }

    /**
     * @notice Add a favorite to the database
     * @param _address The address of the user
     * @param _favorite The favorite to add
     */
    function addFavorite(
        address _address,
        string calldata _favorite
    ) external /* onlyAllowlist */ {
        // Is it already in the list?
        uint256 index = getFavoriteIndex(_address, _favorite);
        if (index != s_favorites[_address].length)
            revert VISUALIZE__ALREADY_FAVORITE();

        s_favorites[_address].push(_favorite);

        emit VISUALIZE__FAVORITE_ADDED(_address, _favorite);
    }

    /**
     * @notice Remove a favorite from the database
     * @param _address The address of the user
     * @param _favorite The favorite to remove
     */
    function removeFavorite(
        address _address,
        string calldata _favorite
    ) external /* onlyAllowlist */ {
        uint256 index = getFavoriteIndex(_address, _favorite);
        if (index == s_favorites[_address].length)
            revert VISUALIZE__NOT_FAVORITE();

        uint256 length = s_favorites[_address].length;
        for (uint256 i = index; i < length - 1; i++) {
            s_favorites[_address][i] = s_favorites[_address][i + 1];
        }
        s_favorites[_address].pop();

        emit VISUALIZE__FAVORITE_REMOVED(_address, _favorite);
    }

    /**
     * @notice Add a shortened URL to the database
     * @param _url The complete URL
     * @return id The ID of the shortened URL
     */
    function shortenURL(
        string calldata _url /* onlyAllowlist */
    ) external returns (uint256 id) {
        if (!isCorrectBaseURL(_url)) revert VISUALIZE__INVALID_URL();

        id = s_shortenedURLs.length;
        s_shortenedURLs.push(_url);

        emit VISUALIZE__URL_SHORTENED(id, _url, _msgSender());
    }

    /**
     * @notice Add addresses to the allowlist
     * @param _addresses The addresses to add
     */
    function addToAllowlist(address[] calldata _addresses) external onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            s_allowlist[_addresses[i]] = true;
        }

        emit VISUALIZE__ALLOWLISTED(_addresses);
    }

    /**
     * @notice Remove addresses from the allowlist
     * @param _addresses The addresses to remove
     */
    function removeFromAllowlist(
        address[] calldata _addresses
    ) external onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            s_allowlist[_addresses[i]] = false;
        }

        emit VISUALIZE__REMOVED_FROM_ALLOWLIST(_addresses);
    }

    /**
     * @notice Update the trusted forwarder
     * @param _address The address of the new forwarder
     */
    function updateTrustedForwarder(address _address) external onlyOwner {
        s_trustedForwarder = _address;
        emit ERC2771Context__TRUSTED_FORWARDER_UPDATED(_address);
    }

    /**
     * @notice Update the base URL
     * @param _baseUrl The new base URL
     */
    function updateBaseURL(string calldata _baseUrl) external onlyOwner {
        s_baseUrl = _baseUrl;
        emit VISUALIZE__BASE_URL_UPDATED(_baseUrl);
    }

    /**
     * @notice Verify if an address is the trusted forwarder
     * @param _address The address to check
     * @dev override ERC2771Context 'isTrustedForwarder'
     */
    function isTrustedForwarder(
        address _address
    ) public view override returns (bool) {
        return _address == s_trustedForwarder;
    }

    function getTrustedForwarder() public view returns (address) {
        return s_trustedForwarder;
    }

    /**
     * @notice Verify if an address is allowlisted
     * @param _address The address to check
     */
    function isAllowlisted(address _address) public view returns (bool) {
        return s_allowlist[_address];
    }

    /**
     * @notice Verify if a string matches the base URL
     * @param _url The string to check
     */
    function isCorrectBaseURL(string calldata _url) public view returns (bool) {
        bytes memory urlBytes = bytes(_url);
        bytes memory domainBytes = bytes(s_baseUrl);

        if (urlBytes.length < domainBytes.length) {
            return false;
        }

        for (uint256 i = 0; i < domainBytes.length; i++) {
            if (urlBytes[i] != domainBytes[i]) {
                return false;
            }
        }

        return true;
    }

    /**
     * @notice Get the base URL
     */
    function getBaseURL() public view returns (string memory) {
        return s_baseUrl;
    }

    /**
     * @notice Get the complete URL for an ID
     * @param _id The ID of the shortened URL
     */
    function getShortenedURL(uint256 _id) public view returns (string memory) {
        return s_shortenedURLs[_id];
    }

    /**
     * @notice Get the favorites for an address
     * @param _address The address of the user
     */
    function getFavorites(
        address _address
    ) public view returns (string[] memory) {
        return s_favorites[_address];
    }

    /**
     * @notice Get the index of a favorite for an address
     * @param _address The address of the user
     * @param _favorite The favorite to find
     */
    function getFavoriteIndex(
        address _address,
        string calldata _favorite
    ) public view returns (uint256) {
        uint256 length = s_favorites[_address].length;
        for (uint256 i = 0; i < length; i++) {
            if (
                keccak256(abi.encodePacked(s_favorites[_address][i])) ==
                keccak256(abi.encodePacked(_favorite))
            ) {
                return i;
            }
        }
        return length;
    }

    /**
     * @notice Get the owner
     */
    function getOwner() public view returns (address) {
        return i_owner;
    }
}