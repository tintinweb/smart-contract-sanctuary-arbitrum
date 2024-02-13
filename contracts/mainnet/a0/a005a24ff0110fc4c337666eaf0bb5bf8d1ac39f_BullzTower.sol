/**
 *Submitted for verification at Arbiscan.io on 2024-02-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IBullzCoin {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function mint(address account, uint256 amount) external;

    function burn(address account, uint256 amount) external;
}

contract Ownable {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract BullzTower is Ownable {
    IBullzCoin public BullzCoin;

    address[3] public leaderBoard = [address(0), address(0), address(0)];
    uint256[3] public winnerPrizes = [30, 20, 10];
    uint256 public totalMinted;
    uint256 public totalBurned;
    uint256 public totaltraders;
    uint256 public totalusers;
    uint256 public currentWeek;
    uint256 public timeStep;
    uint256 public launchTime;
    uint256 public accumulationDuration;
    bool public accumulationStatus;
    bool public leaderBoardStatus;

    struct User {
        uint256 totalInvested;
        uint256 realizedProfit;
        uint256 unrealizedProfit;
        uint256 claimedProfit;
        uint256 yield;
        uint256 percent;
        uint256 checkPoint;
        uint8[8] traders;
    }
    struct Ref {
        address referrer;
        uint256 totalReferrals;
        uint256 refRewards;
        uint256 refPrizes;
        mapping(uint256 => uint256) weeklyData;
    }

    mapping(address => User) public userData;
    mapping(address => Ref) public refData;
    mapping(address => uint256[8]) public floorData;
    mapping(uint256 => address[3]) public winners;
    mapping(uint256 => uint256[8]) private traderYield;
    mapping(uint256 => uint256[8]) private traderPrice;
    mapping(uint256 => uint256[8]) private yieldPercent;

    event UPGRADE(address user, uint256 amount);
    event REALIZE(address user, uint256 amount);
    event WITHDRAW(address user, uint256 amount);
    event LEADERBOARD(address user1, address user2, address user3);

    constructor(address _token) {
        BullzCoin = IBullzCoin(_token);
        timeStep = 3600;
        accumulationDuration = 48;
        accumulationStatus = true;
        leaderBoardStatus = true;
        initializeYeild();
        initializePrice();
        initializePercent();
    }

    function initializeYeild() private {
        traderYield[1] = [
            29,
            2_16,
            8_33,
            20_00,
            58_33,
            208_33,
            375_00,
            875_00
        ];
        traderYield[2] = [
            66,
            3_54,
            12_50,
            29_16,
            84_37,
            275_00,
            473_95,
            1250_00
        ];
        traderYield[3] = [
            1_87,
            5_00,
            20_41,
            45_00,
            103_12,
            379_16,
            625_00,
            1770_83
        ];
    }

    function initializePrice() private {
        traderPrice[1] = [
            1000,
            4000,
            10_000,
            16_000,
            35_000,
            100_000,
            150_000,
            300_000
        ];
        traderPrice[2] = [
            2000,
            5000,
            12_000,
            20_000,
            45_000,
            120_000,
            175_000,
            400_000
        ];
        traderPrice[3] = [
            3000,
            6000,
            14_000,
            24_000,
            55_000,
            140_000,
            200_000,
            500_000
        ];
    }

    function initializePercent() private {
        yieldPercent[1] = [
            292,
            542,
            833,
            1250,
            1667,
            2083,
            2500,
            2917
        ];
        yieldPercent[2] = [
            333,
            708,
            1042,
            1458,
            1875,
            2292,
            2708,
            3125
        ];
        yieldPercent[3] = [
            625,
            833,
            1458,
            1875,
            1875,
            2708,
            3125,
            3542
        ];
    }

    function Launch() external onlyOwner {
        require(launchTime == 0, "Already launched");
        launchTime = block.timestamp;
    }

    function updateWeekly() public {
        if (currentWeek != calculateWeek()) {
            if (leaderBoardStatus) {
                checkForWinner();
            }
            currentWeek = calculateWeek();
        }
    }

    function upgradeTower(address ref, uint256 floorId) external {
        require(launchTime != 0, "Wait for launch");
        updateWeekly();
        require(floorId < 8, "Max 8 floors");
        address user = msg.sender;
        if (floorId != 0) {
            require(
                userData[user].traders[floorId - 1] == 3,
                "Buy previous floor first"
            );
        }
        userData[user].traders[floorId]++;
        uint256 traders = userData[user].traders[floorId];
        uint256 coins = getUpgradePrice(floorId, traders);
        uint256 tokenAmount = coins * 1e9;
        uint256 refReward = tokenAmount / 100;
        totalBurned += tokenAmount;
        BullzCoin.burn(user, tokenAmount);
        userData[user].totalInvested += coins;
        userData[user].percent += getPercent(floorId, traders);
        userData[user].yield = (userData[user].percent * userData[user].totalInvested)/1e4;
        floorData[user][floorId] = getUserFloorYield(user, floorId);

        if (userData[user].checkPoint == 0) {
            totalusers++;
            userData[user].checkPoint = block.timestamp;
            refData[user].referrer = ref;
            refData[ref].totalReferrals++;
        }
        if (ref == owner() || userData[ref].checkPoint != 0) {
            totalMinted += refReward;
            BullzCoin.mint(user, refReward);
        }
        syncTower(user);
        totaltraders++;

        ref = refData[user].referrer;
        if (ref != address(0)) {
            updateRefferer(ref, refReward);
        }

        emit UPGRADE(user, tokenAmount);
    }

    function withdrawProfit() external {
        updateWeekly();
        address user = msg.sender;
        uint256 realizedProfit = userData[user].realizedProfit;
        require(realizedProfit > 0, "No profit yet");
        userData[user].realizedProfit = 0;
        uint256 tokenAmount = (realizedProfit * 1e9) / 1e4;
        userData[user].claimedProfit += tokenAmount;
        totalMinted += tokenAmount;
        BullzCoin.mint(user, tokenAmount);

        emit WITHDRAW(user, tokenAmount);
    }

    function realizeProfit() external {
        updateWeekly();
        address user = msg.sender;
        syncTower(user);
        userData[user].realizedProfit += userData[user].unrealizedProfit;
        userData[user].unrealizedProfit = 0;

        emit REALIZE(user, userData[user].realizedProfit);
    }

    function updateRefferer(address ref, uint256 refReward) private {
        refData[ref].refRewards += refReward;
        refData[ref].weeklyData[currentWeek] += refReward;
        totalMinted += refReward;
        BullzCoin.mint(ref, refReward);

        if (
            refData[ref].weeklyData[currentWeek] >=
            refData[leaderBoard[2]].weeklyData[currentWeek]
        ) {
            if (
                refData[ref].weeklyData[currentWeek] >=
                refData[leaderBoard[1]].weeklyData[currentWeek]
            ) {
                if (
                    refData[ref].weeklyData[currentWeek] >=
                    refData[leaderBoard[0]].weeklyData[currentWeek]
                ) {
                    if (ref != leaderBoard[0]) updateWinner1(ref);
                } else {
                    if (ref != leaderBoard[1]) updateWinner2(ref);
                }
            } else {
                if (ref != leaderBoard[2]) updateWinner3(ref);
            }
        }
    }

    function updateWinner1(address ref) private {
        address temp;
        if (ref == leaderBoard[1]) {
            temp = leaderBoard[0];
            leaderBoard[0] = ref;
            leaderBoard[1] = temp;
        } else {
            temp = leaderBoard[0];
            leaderBoard[0] = ref;
            ref = temp;
            temp = leaderBoard[1];
            leaderBoard[1] = ref;
            leaderBoard[2] = temp;
        }
    }

    function updateWinner2(address ref) private {
        address temp = leaderBoard[1];
        leaderBoard[1] = ref;
        leaderBoard[2] = temp;
    }

    function updateWinner3(address ref) private {
        leaderBoard[2] = ref;
    }

    function syncTower(address user) private {
        require(userData[user].checkPoint > 0, "Buy tower first");
        userData[user].unrealizedProfit += calculateProfit(user);
        userData[user].checkPoint = block.timestamp;
    }

    function checkForWinner() private {
        uint256 prizeAmount;
        if (leaderBoard[0] != address(0)) {
            winners[currentWeek][0] = leaderBoard[0];
            prizeAmount =
                (refData[leaderBoard[0]].weeklyData[currentWeek] *
                    winnerPrizes[0]) /
                100;
            if (prizeAmount > 0) {
                refData[leaderBoard[0]].refPrizes += prizeAmount;
                BullzCoin.mint(leaderBoard[0], prizeAmount);
            }
        }
        if (leaderBoard[1] != address(0)) {
            winners[currentWeek][1] = leaderBoard[1];
            prizeAmount =
                (refData[leaderBoard[1]].weeklyData[currentWeek] *
                    winnerPrizes[1]) /
                100;
            if (prizeAmount > 0) {
                refData[leaderBoard[1]].refPrizes += prizeAmount;
                BullzCoin.mint(leaderBoard[1], prizeAmount);
            }
        }
        if (leaderBoard[2] != address(0)) {
            winners[currentWeek][2] = leaderBoard[2];
            prizeAmount =
                (refData[leaderBoard[2]].weeklyData[currentWeek] *
                    winnerPrizes[2]) /
                100;
            if (prizeAmount > 0) {
                refData[leaderBoard[2]].refPrizes += prizeAmount;
                BullzCoin.mint(leaderBoard[2], prizeAmount);
            }
        }

        emit LEADERBOARD(leaderBoard[0], leaderBoard[1], leaderBoard[2]);
    }

    function calculateProfit(
        address user
    ) public view returns (uint256 profit) {
        uint256 checkPoint = userData[user].checkPoint;
        if (checkPoint <= 0) return 0;
        uint256 profitDuration = (block.timestamp / timeStep) -
            (checkPoint / timeStep);
        if (profitDuration > accumulationDuration && accumulationStatus) {
            profitDuration = accumulationDuration;
        }
        profit = (profitDuration * userData[user].percent * userData[user].totalInvested)/1e4;
    }

    function calculateWeek() public view returns (uint256) {
        return (block.timestamp - launchTime) / (7 * 1 days);
    }

    function getTraders(address user) external view returns (uint8[8] memory) {
        return userData[user].traders;
    }

    function getWeeklyRefs(
        address user,
        uint256 week
    ) external view returns (uint256) {
        return refData[user].weeklyData[week];
    }

    function getUpgradePrice(
        uint256 floorId,
        uint256 traderId
    ) public view returns (uint256) {
        if (traderId < 1 || traderId > 3) {
            revert("Incorrect traderId");
        }
        return traderPrice[traderId][floorId];
    }

    function getYield(
        uint256 floorId,
        uint256 traderId
    ) public view returns (uint256) {
        if (traderId < 1 || traderId > 3) {
            revert("Incorrect traderId");
        }
        return traderYield[traderId][floorId];
    }

    function getPercent(
        uint256 floorId,
        uint256 traderId
    ) public view returns (uint256) {
        if (traderId < 1 || traderId > 3) {
            revert("Incorrect traderId");
        }
        return yieldPercent[traderId][floorId];
    }

    function getUserFloorYield(
        address user,
        uint256 floorId
    ) public view returns (uint256) {
        uint256 userTraders = userData[user].traders[floorId];
        uint256 floorPercent;
        uint256 floorPrice;
        for(uint8 i=1 ; i<=userTraders ; i++){
            floorPercent += getPercent(floorId, i);
            floorPrice += getUpgradePrice(floorId, i);
        }
        return (floorPrice * floorPercent)/1e4;
    }

    function removeStuckEth(address _receiver) public onlyOwner {
        payable(_receiver).transfer(address(this).balance);
    }

    function removeStuckToken(
        address _token,
        address _receiver,
        uint256 _amount
    ) public onlyOwner {
        IBullzCoin(_token).transfer(_receiver, _amount);
    }

    function setLederboardStatus(bool _status) external onlyOwner {
        leaderBoardStatus = _status;
    }

    function setAccumulation(uint256 _duration, bool _status) external onlyOwner {
        require(accumulationDuration > 48);
        accumulationDuration = _duration;
        accumulationStatus = _status;
    }
}