pragma solidity ^0.8.0;
//SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IEllerianHeroUpgradeable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/** 
 * Tales of Elleria
*/
contract TokenUriHelper is Ownable {
    using Strings for uint256;

    mapping (uint256 => mapping (uint256 => string)) private tokenUris;
    mapping (uint256 => string) private classNames;

    mapping (uint256 => bool) private isBugged;
    
    IEllerianHeroUpgradeable upgradeableAbi;  // Reference to the NFT's upgrade logic.

    constructor () {
        upgradeableAbi = IEllerianHeroUpgradeable(0x7A0D491469fb5D7D3aDbF186221891AfE3b5d028);

        classNames[1] = "Warrior";
        classNames[2] = "Assassin";
        classNames[3] = "Mage";
        classNames[4] = "Ranger";

        tokenUris[1][0] = "https://ipfs.moralis.io:2053/ipfs/QmXdUDFBCx3MfCMZK9nK3AeFayxCYi7SiKU4xz98MdMC49";
        tokenUris[1][1] = "https://ipfs.moralis.io:2053/ipfs/QmbXmaaWNFx8jK9DaxGF3x4Zj9RbTaRKQF3UkhuLfQLheG";
        tokenUris[1][2] = "https://ipfs.moralis.io:2053/ipfs/QmXB9VvdGXGu7gbmcKGamhJpTLYrtJFrtyeGf2YzgFHA3J";
        tokenUris[2][0] = "https://ipfs.moralis.io:2053/ipfs/QmVVGAmNvUgUhyLy3HPKmwbzCnRfjGrV9kjW1G6ALUZUNF";
        tokenUris[2][1] = "https://ipfs.moralis.io:2053/ipfs/Qmd66PRkYUWN78VUSzYyxmZeP4zLpC8Wroif3QNCyofvj7";
        tokenUris[2][2] = "https://ipfs.moralis.io:2053/ipfs/QmP8X5uSrp6D4HGCkQ7asTQAaRxsn2eVS4TcapEf5evk4f";
        tokenUris[3][0] = "https://ipfs.moralis.io:2053/ipfs/QmVWzYTi7pYBZcMrzoHJ82ucRxPxVyEUNPZDtjbewzhfEC";
        tokenUris[3][1] = "https://ipfs.moralis.io:2053/ipfs/QmQuAxvgQP9r8cuV8sJxrjA7ttZYb2UdM4JdC17PgWv29U";
        tokenUris[3][2] = "https://ipfs.moralis.io:2053/ipfs/QmVdphWGBK78DupEntsxDut2mks9ihitxzu21hkpQJGVQ8";
        tokenUris[4][0] = "https://ipfs.moralis.io:2053/ipfs/QmZZGVv1rHm6KQ5ng7ehT9Dd38wnSCFZD9tWFfKgRpyeMa";
        tokenUris[4][1] = "https://ipfs.moralis.io:2053/ipfs/QmSvcrDYijxrZ5Fpz97P3t2dChEnq2syNwLQ6qGZ2nDzKc";
        tokenUris[4][2] = "https://ipfs.moralis.io:2053/ipfs/QmWBudHCS6wcSeJTVbHSYPddnLaBGdPJbHynwYG95Ambs3";

        tokenUris[1][3] = "https://ipfs.moralis.io:2053/ipfs/QmdvJr2XjPoepJoxT8kH6RGJeuxopCpC2JahQfrtGATdkE";
        tokenUris[2][3] = "https://ipfs.moralis.io:2053/ipfs/QmdvJr2XjPoepJoxT8kH6RGJeuxopCpC2JahQfrtGATdkE";
        tokenUris[3][3] = "https://ipfs.moralis.io:2053/ipfs/QmdvJr2XjPoepJoxT8kH6RGJeuxopCpC2JahQfrtGATdkE";
        tokenUris[4][3] = "https://ipfs.moralis.io:2053/ipfs/QmdvJr2XjPoepJoxT8kH6RGJeuxopCpC2JahQfrtGATdkE";

        tokenUris[1][4] = "https://ipfs.moralis.io:2053/ipfs/QmafevGMgE4pTF1Z3UjL3PBm2SZqj3ZSK6Hue7iKte5Rk1";
        tokenUris[2][4] = "https://ipfs.moralis.io:2053/ipfs/QmafevGMgE4pTF1Z3UjL3PBm2SZqj3ZSK6Hue7iKte5Rk1";
        tokenUris[3][4] = "https://ipfs.moralis.io:2053/ipfs/QmafevGMgE4pTF1Z3UjL3PBm2SZqj3ZSK6Hue7iKte5Rk1";
        tokenUris[4][4] = "https://ipfs.moralis.io:2053/ipfs/QmafevGMgE4pTF1Z3UjL3PBm2SZqj3ZSK6Hue7iKte5Rk1";
    }

    /*
    * Link with other contracts necessary for this to function.
    */
    function SetAddresses(address _upgradeableAddr) external onlyOwner {
            upgradeableAbi = IEllerianHeroUpgradeable(_upgradeableAddr);
    }

    function SetUri(uint256 _class, uint256 _rarity, string memory _newUri) external onlyOwner {
        tokenUris[_class][_rarity] = _newUri;
    }

    function SetClassNames(uint256 _class, string memory _className) external onlyOwner {
        classNames[_class] = _className;
    }

    function SetBuggedIndex(uint256[] memory indexes, bool isBug) external onlyOwner {
        for (uint256 i = 0; i < indexes.length; i++) {
            isBugged[indexes[i]] = isBug;
        }
    }

    function GetTokenUri(uint256 _tokenId) external view returns (string memory) {

        uint256 _class =  upgradeableAbi.GetHeroClass(_tokenId);
        uint256 _rarity = upgradeableAbi.GetAttributeRarity(_tokenId);
        
        // Check if affected by the rarity issue, and alter the rarity if so.
        if (isBugged[_tokenId]) {
            _rarity += 3; // From 0 = common, 1 = epic, 2 = legendary, 3 = jester, 4 = witch
        }

        uint256[9] memory heroDetails = upgradeableAbi.GetHeroDetails(_tokenId);

        string memory stats =  string(abi.encodePacked(
            Strings.toString(heroDetails[0]),';',  
            Strings.toString(heroDetails[1]), ';', 
            Strings.toString(heroDetails[2]), ';', 
            Strings.toString(heroDetails[3]), ';', 
            Strings.toString(heroDetails[4]), ';', 
            Strings.toString(heroDetails[5]), ';', 
            Strings.toString(heroDetails[6]), ';', 
            Strings.toString(heroDetails[7]), ';',
            GetClassName(heroDetails[7]),';')
        );

        return string(abi.encodePacked(
            Strings.toString(_tokenId),';', // tokenId
            tokenUris[_class][_rarity],';', // image
            stats, // str, agi, vit, end, int, will, total, class id, class name
            Strings.toString(upgradeableAbi.GetHeroLevel(_tokenId)),';', // level
            Strings.toString(upgradeableAbi.GetHeroExperience(_tokenId)[0]),';', // exp
            Strings.toString(heroDetails[8]),';', // time summoned
            Strings.toString(_rarity),';', // rarity id
            Strings.toString(upgradeableAbi.IsStaked(_tokenId) ? 1 : 0)) // is staked?
        );
    }

    function GetClassName(uint256 _class) public view returns (string memory) {
        return classNames[_class];
    }
}

pragma solidity ^0.8.0;
//SPDX-License-Identifier: MIT

// Interface for upgradeable logic.
contract IEllerianHeroUpgradeable {

    function GetHeroDetails(uint256 _tokenId) external view returns (uint256[9] memory) {}
    function GetHeroClass(uint256 _tokenId) external view returns (uint256) {}
    function GetHeroLevel(uint256 _tokenId) external view returns (uint256) {}
    function GetHeroName(uint256 _tokenId) external view returns (string memory) {}
    function GetHeroExperience(uint256 _tokenId) external view returns (uint256[2] memory) {}
    function GetAttributeRarity(uint256 _tokenId) external view returns (uint256) {}

    function GetUpgradeCost(uint256 _level) external view returns (uint256[2] memory) {}
    function GetUpgradeCostFromTokenId(uint256 _tokenId) public view returns (uint256[2] memory) {}

    function ResetHeroExperience(uint256 _tokenId, uint256 _exp) external {}
    function UpdateHeroExperience(uint256 _tokenId, uint256 _exp) external {}

    function SetHeroLevel (uint256 _tokenId, uint256 _level) external {}
    function SetNameChangeFee(uint256 _feeInWEI) external {}
    function SetHeroName(uint256 _tokenId, string memory _name) public {}

    function SynchronizeHero (bytes memory _signature, uint256[] memory _data) external {}
    function IsStaked(uint256 _tokenId) external view returns (bool) {}
    function Stake(uint256 _tokenId) external {}
    function Unstake(uint256 _tokenId) external {}

    function initHero(uint256 _tokenId, uint256 _str, uint256 _agi, uint256 _vit, uint256 _end, uint256 _intel, uint256 _will, uint256 _total, uint256 _class) external {}

    function AttemptHeroUpgrade(address sender, uint256 tokenId, uint256 goldAmountInEther, uint256 tokenAmountInEther) public {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
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

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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