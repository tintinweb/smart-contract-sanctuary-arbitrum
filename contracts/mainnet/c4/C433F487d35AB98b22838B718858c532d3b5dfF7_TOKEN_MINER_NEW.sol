/**
 *Submitted for verification at Arbiscan.io on 2023-09-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

pragma solidity ^0.8.0;

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

pragma solidity ^0.8.0;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

pragma solidity ^0.8.0;

contract TOKEN_MINER_NEW is Ownable {
    address public token;
    uint256 public EGGS_TO_HATCH_1MINERS;
    uint256 public PSN;
    uint256 public PSNH;
    bool public initialized = false;
    mapping (address => uint256) public hatcheryMiners;
    mapping (address => uint256) public claimedEggs;
    mapping (address => uint256) public lastHatch;
    mapping (address => address) public referrals;
    uint256 public marketEggs;
    uint256 public referralPercentage = 7;
    mapping (address => uint256) public referralCounts; // Добавлено для подсчета реферралов

    constructor(address _token, uint256 _psn, uint256 _psnh) {
        token = _token;
        PSN = _psn;
        PSNH = _psnh;
        EGGS_TO_HATCH_1MINERS = 540000;
    }

    function hatchEggs(address ref) public {
        require(initialized);

        if (ref == msg.sender) {
            ref = address(0);
        }

        if (referrals[msg.sender] == address(0) && ref != msg.sender) {
            referrals[msg.sender] = ref;
        }

        if (ref != address(0)) {
            referralCounts[ref]++; // Увеличить счетчик реферралов для данного реферрала
        }

        uint256 eggsUsed = getMyEggs(msg.sender);
        uint256 newMiners = eggsUsed / EGGS_TO_HATCH_1MINERS;

        hatcheryMiners[msg.sender] += newMiners;
        claimedEggs[msg.sender] = 0;
        lastHatch[msg.sender] = block.timestamp;

        uint256 referralPercent = getReferralPercentage(msg.sender);
        claimedEggs[referrals[msg.sender]] += (eggsUsed * referralPercent) / 100;
        marketEggs += eggsUsed / 5;
    }

    function sellEggs() public {
        require(initialized);
        uint256 hasEggs = getMyEggs(msg.sender);
        uint256 eggValue = calculateEggSell(hasEggs);

        claimedEggs[msg.sender] = 0;
        lastHatch[msg.sender] = block.timestamp;
        marketEggs += hasEggs;

        IERC20(token).transfer(msg.sender, eggValue);
    }

    function buyEggs(address ref, uint256 amount) public {
        require(initialized);
        IERC20(token).transferFrom(msg.sender, address(this), amount);
        uint256 balance = IERC20(token).balanceOf(address(this));
        uint256 eggsBought = calculateEggBuy(amount, balance - amount);

        claimedEggs[msg.sender] += eggsBought;
        hatchEggs(ref);
    }

    function setReferralPercentage(uint256 newPercentage) public onlyOwner {
        require(newPercentage <= 100);
        referralPercentage = newPercentage;
    }

    function setEGGS_TO_HATCH_1MINERS(uint256 newValue) public onlyOwner {
        EGGS_TO_HATCH_1MINERS = newValue;
    }

    function setPSN(uint256 newPSN) public onlyOwner {
        PSN = newPSN;
    }

    function setPSNH(uint256 newPSNH) public onlyOwner {
        PSNH = newPSNH;
    }

    function calculateTrade(uint256 rt, uint256 rs, uint256 bs) internal view returns (uint256) {
        return (PSN * bs) / (PSNH + ((PSN * rs + PSNH * rt) / rt));
    }

    function calculateEggSell(uint256 eggs) public view returns (uint256) {
        return calculateTrade(eggs, marketEggs, IERC20(token).balanceOf(address(this)));
    }

    function calculateEggBuy(uint256 eth, uint256 contractBalance) public view returns (uint256) {
        return calculateTrade(eth, contractBalance, marketEggs);
    }

    function getMyEggs(address adr) public view returns (uint256) {
        return claimedEggs[adr] + getEggsSinceLastHatch(adr);
    }

    function getEggsSinceLastHatch(address adr) public view returns (uint256) {
        uint256 secondsPassed = block.timestamp - lastHatch[adr];
        return secondsPassed * hatcheryMiners[adr];
    }

    function getReferralPercentage(address adr) public view returns (uint256) {
        if (referralCounts[adr] >= 500) {
            return 20;
        } else if (referralCounts[adr] >= 100) {
            return 15;
        } else if (referralCounts[adr] >= 50) {
            return 13;
        } else if (referralCounts[adr] >= 20) {
            return 12;
        } else if (referralCounts[adr] >= 10) {
            return 10;
        } else {
            return referralPercentage;
        }
    }
}