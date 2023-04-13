pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IArcane {
    function ownerOf(uint256 tokenId) external returns (address);
}

interface IProfessions {
    function checkSpec(
        uint256 _wizId,
        uint256 _specStructureId
    ) external returns (bool);

    function earnXP(uint256 _wizId, uint256 _points) external;
}

interface IItems {
    function mintItems(
        address _to,
        uint256[] memory _itemIds,
        uint256[] memory _amounts
    ) external;

    function destroy(
        address _from,
        uint256[] memory _ids,
        uint256[] memory _amounts
    ) external;

    function balanceOf(address account, uint256 id) external returns (uint256);
}

contract Crafting is Ownable {
    struct Recipe {
        uint16 id;
        uint256[] inputIds;
        uint256[] inputAmounts;
        uint256[] outputIds;
        uint256[] outputAmounts;
        uint16 cooldown;
        uint16 structure;
        uint16 xp;
    }

    IArcane public ARCANE;
    IProfessions public PROFESSIONS;
    IItems public ITEMS;

    mapping(uint256 => Recipe) public recipes;
    mapping(uint256 => mapping(uint256 => uint256)) public cooldowns;

    modifier isOwner(uint256 _wizId) {
        require(ARCANE.ownerOf(_wizId) == msg.sender, "Not owner");
        _;
    }

    function executeRecipe(
        uint256 _wizId,
        uint256 _recipeId
    ) external isOwner(_wizId) {
        Recipe memory recipe = recipes[_recipeId];
        require(recipe.inputAmounts.length > 0, "Empty");
        if (recipe.structure < 1640) {
            require(
                PROFESSIONS.checkSpec(_wizId, recipe.structure),
                "Cannot execute this recipe"
            );
            PROFESSIONS.earnXP(_wizId, recipe.xp);
        } else {
            require(
                ITEMS.balanceOf(msg.sender, recipe.structure) > 0,
                "Cannot execute this recipe"
            );
        }
        require(
            block.timestamp > cooldowns[_wizId][_recipeId] + recipe.cooldown,
            "On cooldown"
        );
        ITEMS.destroy(msg.sender, recipe.inputIds, recipe.inputAmounts);
        ITEMS.mintItems(msg.sender, recipe.outputIds, recipe.outputAmounts);
        cooldowns[_wizId][_recipeId] = block.timestamp;
    }

    function createRecipe(
        uint256 _recipeId,
        uint256[] memory _requiredIds,
        uint256[] memory _requiredAmounts,
        uint256[] memory _rewardIds,
        uint256[] memory _rewardAmounts,
        uint16 _cooldown,
        uint16 _structure,
        uint16 _xp
    ) external onlyOwner {
        recipes[_recipeId].id = uint16(_recipeId);
        recipes[_recipeId].inputIds = _requiredIds;
        recipes[_recipeId].inputAmounts = _requiredAmounts;
        recipes[_recipeId].outputIds = _rewardIds;
        recipes[_recipeId].outputAmounts = _rewardAmounts;
        recipes[_recipeId].cooldown = _cooldown;
        recipes[_recipeId].structure = _structure;
        recipes[_recipeId].xp = _xp;
    }

    function getTimer(
        uint256 _wizId,
        uint256 _recipeId
    ) external view returns (uint256 timestamp) {
        return cooldowns[_wizId][_recipeId];
    }

    function setData(
        address _arcane,
        address _professions,
        address _items
    ) external onlyOwner {
        ARCANE = IArcane(_arcane);
        PROFESSIONS = IProfessions(_professions);
        ITEMS = IItems(_items);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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