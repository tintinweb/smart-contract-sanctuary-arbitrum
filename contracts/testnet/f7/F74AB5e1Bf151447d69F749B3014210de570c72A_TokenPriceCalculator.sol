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

// Abstract contract that implements access check functions
// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "../../interfaces/admin/IEntity.sol";
import "../../interfaces/access/IDAOAuthority.sol";

abstract contract DAOAccessControlled is Context {

    /* ========== EVENTS ========== */

    event AuthorityUpdated(IDAOAuthority indexed authority);

    string UNAUTHORIZED = "UNAUTHORIZED"; // save gas

    /* ========== STATE VARIABLES ========== */

    IDAOAuthority public authority;

    /* ========== Constructor ========== */

    constructor(IDAOAuthority _authority) {
        authority = _authority;
        emit AuthorityUpdated(_authority);
    }

    /* ========== MODIFIERS ========== */

    modifier onlyAuthority() {
        require(address(authority) == _msgSender(), UNAUTHORIZED);
        _;
    }
    
    modifier onlyGovernor() {
        require(authority.governor() == _msgSender(), UNAUTHORIZED);
        _;
    }

    modifier onlyPolicy() {
        require(authority.policy() == _msgSender(), UNAUTHORIZED);
        _;
    }

    modifier onlyAdmin() {
        require(authority.admin() == _msgSender(), UNAUTHORIZED);
        _;
    }

    modifier onlyEntityAdmin(address _entity) {
        require(IEntity(_entity).getEntityAdminDetails(_msgSender()).isActive, UNAUTHORIZED);
        _;
    }

    modifier onlyBartender(address _entity) {
        require(IEntity(_entity).getBartenderDetails(_msgSender()).isActive, UNAUTHORIZED);
        _;
    }

    modifier onlyOrderDispatcher() {
        require(authority.orderDispatcher() == _msgSender(), UNAUTHORIZED);
        _;
    }
         
    /* ========== GOV ONLY ========== */
    
    function setAuthority(IDAOAuthority _newAuthority) external onlyGovernor {
        authority = _newAuthority;
        emit AuthorityUpdated(_newAuthority);
    }

    /* ========= ERC2771 ============ */
    function isTrustedForwarder(address forwarder) public view returns (bool) {
        return forwarder == authority.forwarder();
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

    modifier onlyForwarder() {
        // this modifier must check msg.sender directly (not through _msgSender()!)
        require(isTrustedForwarder(msg.sender), UNAUTHORIZED);
        _;
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import "../access/DAOAccessControlled.sol";
import "../../interfaces/tokens/ITokenPriceCalculator.sol";

contract TokenPriceCalculator is ITokenPriceCalculator, DAOAccessControlled {

    // Amount of USD needed to mint 3 tokens(1 for entity, 1 for bartender and 1 for patron)
    uint256 public pricePerMint; // 6 decimals precision 9000000 = 9 USD

    constructor(
        address _authority
    ) DAOAccessControlled(IDAOAuthority(_authority)) {

    }

    function setPricePerMint(uint256 _price) external onlyGovernor {
        pricePerMint = _price;
        emit SetPricePerMint(_price);
    }

}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

interface IDAOAuthority {

    /*********** EVENTS *************/
    event ChangedGovernor(address);
    event ChangedPolicy(address);
    event ChangedAdmin(address);
    event ChangedForwarder(address);
    event ChangedOrderDispatcher(address);

    function governor() external returns(address);
    function policy() external returns(address);
    function admin() external returns(address);
    function forwarder() external view returns(address);
    function orderDispatcher() external view returns(address);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import "../../interfaces/location/ILocationBased.sol";

interface IEntity is ILocationBased {

    /* ========== EVENTS ========== */
    event EntityToggled(address _entity, bool _status);
    event EntityUpdated(address _entity, Area _area, string _dataURI, address _walletAddress);
    event EntityAdminGranted(address _entity, address _entAdmin);
    event BartenderGranted(address _entity, address _bartender);
    event EntityAdminToggled(address _entity, address _entAdmin, bool _status);
    event BartenderToggled(address _entity, address _bartender, bool _status);
    event CollectibleAdded(address _entity, address _collectible);

    event CollectibleWhitelisted(address indexed _entity, address indexed _collectible, uint256 indexed _chainId);
    event CollectibleDelisted(address indexed _entity, address indexed _collectible, uint256 indexed _chainId);

    struct Operator {
        uint256 id;
        string dataURI;
        bool isActive;
    }

    struct BlacklistDetails {
        // Timestamp after which the patron should be removed from blacklist
        uint256 end; 
    }

    struct ContractDetails {
        // Contract address
        address source;

        // ChainId where the contract deployed
        uint256 chainId;
    }

    function updateEntity(
        Area memory _area,
        string memory _dataURI,
        address _walletAddress
    ) external;

    function toggleEntity() external returns(bool _status);

    function addCollectibleToEntity(address _collectible) external;

    function addEntityAdmin(address _entAdmin, string memory _dataURI) external;

    function addBartender(address _bartender, string memory _dataURI) external;

    function toggleEntityAdmin(address _entAdmin) external returns(bool _status);

    function toggleBartender(address _bartender) external returns(bool _status);

    function getEntityAdminDetails(address _entAdmin) external view returns(Operator memory);

    function getBartenderDetails(address _bartender) external view returns(Operator memory);

    function addPatronToBlacklist(address _patron, uint256 _end) external;

    function removePatronFromBlacklist(address _patron) external;

    function whitelistedCollectibles(uint256 index) external view returns(address, uint256);

    function whitelistCollectible(address _source, uint256 _chainId) external;

    function delistCollectible(address _source, uint256 _chainId) external;

    function getWhitelistedCollectibles() external view returns (ContractDetails[] memory);

    function getLocationDetails() external view returns(string[] memory, uint256);

    function getAllEntityAdmins() external view returns(address[] memory);

    function getAllBartenders() external view returns(address[] memory);

    function getAllCollectibles() external view returns(address[] memory);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

interface ILocationBased {

    struct Area {
        // Area Co-ordinates.
        // For circular area, points[] length = 1 and radius > 0
        // For arbitrary area, points[] length > 1 and radius = 0
        // For arbitrary areas UI should connect the points with a
        // straight line in the same sequence as specified in the points array
        string[] points; // Each element in this array should be specified in "lat,long" format
        uint256 radius; // Unit: Meters. 2 decimals(5000 = 50 meters)
    }
    
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

interface ITokenPriceCalculator {

    event SetPricePerMint(uint256);

    function pricePerMint() external returns(uint256);

    function setPricePerMint(uint256 _price) external;
}