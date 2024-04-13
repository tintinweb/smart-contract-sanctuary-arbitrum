// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;


import "./ERC1155Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ERC1155PausableUpgradeable.sol";
import "./ERC1155BurnableUpgradeable.sol";
import "./ERC1155SupplyUpgradeable.sol";
import "./IERC1155ReceiverUpgradeable.sol";
import "./Initializable.sol";
import "./ReentrancyGuardUpgradeable.sol";

import {Operatable} from "./Operator.sol";


contract PoglinLodestars is Initializable, ERC1155Upgradeable, OwnableUpgradeable, ERC1155PausableUpgradeable, ERC1155BurnableUpgradeable, ERC1155SupplyUpgradeable, Operatable {
    uint256 public constant NATURE = 1;
    uint256 public constant FIRE = 2;
    uint256 public constant WATER = 3;
    uint256 public constant EARTH = 4;

    uint256 public constant DARK = 5;
    uint256 public constant LIGHTNING = 6;
    uint256 public constant AETHER = 7;

    uint256 public constant SPACE = 8;
    uint256 public constant TIME = 9;
    uint256 public constant PNEUMA = 10;

    uint256 public constant CHAOS = 11;

    string public name;
    string public symbol;

    bool private _smeltingActive;
    uint private _smeltAmount;
    uint[] private _smeltWeights;
    uint private _totalWeight;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() initializer public {
        __ERC1155_init("https://assets.poglinslam.com/lds/m/{id}");
        /* __Ownable_init(); */
        __ERC1155Pausable_init();
        __ERC1155Burnable_init();
        __ERC1155Supply_init();

        OwnableUpgradeable.__Ownable_init_unchained();
        Operatable.__Operatable_init_unchained();

        name = "PRC Token";
        symbol = "PRC";

        _smeltAmount = 3;

        transferOwnership(msg.sender);
    }

    function onERC1155Received(address, address, uint256, uint256, bytes calldata) external pure returns (bytes4) {
        return IERC1155ReceiverUpgradeable.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address, address, uint256[] calldata, uint256[] calldata, bytes calldata) external pure returns (bytes4) {
        return IERC1155ReceiverUpgradeable.onERC1155BatchReceived.selector;
    }

    function setURI(string memory newuri) public onlyOperator {
        _setURI(newuri);
    }

    function setSmeltingActive(bool flag) public onlyOperator {
        _smeltingActive = flag;
    }

    function setSmeltingActive(uint amount) public onlyOperator {
        _smeltAmount = amount;
    }

    function setSmeltWeights(uint[] calldata weights) public onlyOperator returns (uint) {
        require(weights.length == 11, "Invalid weight count.");
        _smeltWeights = weights;
        uint totalWeight = 0;
        for (uint i = 0; i < weights.length; i++) {
            totalWeight += weights[i];
        }
        _totalWeight = totalWeight;
        return totalWeight;
    }

    function pause() public onlyOperator {
        _pause();
    }

    function unpause() public onlyOperator {
        _unpause();
    }

    function mint(address account, uint256 id, uint256 amount, bytes memory data)
        public
        onlyOperator
    {
        require(id >= NATURE && id <= CHAOS, "Invalid tokenID.");
        _mint(account, id, amount, data);
    }

    function mintBatch(address to, uint256[] calldata ids, uint256[] calldata amounts, bytes memory data)
        public
        onlyOperator
    {
        for (uint256 i = 0; i < ids.length; i++) {
            require(ids[i] >= NATURE && ids[i] <= CHAOS, "Invalid tokenID.");
        }
        _mintBatch(to, ids, amounts, data);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    )
        internal
        override(ERC1155Upgradeable, ERC1155PausableUpgradeable, ERC1155SupplyUpgradeable)
    {
        ERC1155SupplyUpgradeable._beforeTokenTransfer(operator, from, to, ids, amounts, data);
        ERC1155PausableUpgradeable._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function smelt(uint[] calldata ids, uint[] calldata amounts) public returns (uint) {
        require(_smeltingActive == true, "Smelting is currently not active");
        require(_smeltWeights.length == 11, "Smelting weights are not set.");
        require(ids.length == amounts.length, "IDs and amounts must be the same length");
        uint totalAmount;
        for (uint i = 0; i < amounts.length; i++) {
            require(balanceOf(msg.sender, ids[i]) >= amounts[i], "Insufficient balance");
            totalAmount += amounts[i];
        }
        require(totalAmount == _smeltAmount, "Incorrect amount of tokens for smelting");

        uint rn = uint(keccak256(abi.encodePacked(block.timestamp, block.basefee, block.coinbase))) % _totalWeight + 1;
        uint newTokenId = 1;
        uint cumulativeWeight = 0;

        for (uint i = 0; i < _smeltWeights.length; i++) {
            if (rn > cumulativeWeight && rn <= cumulativeWeight + _smeltWeights[i]) {
                newTokenId = i+1;
                break;
            }
            cumulativeWeight += _smeltWeights[i];
        }

        burnBatch(msg.sender, ids, amounts);
        mint(msg.sender, newTokenId, 1, '');

        return newTokenId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}