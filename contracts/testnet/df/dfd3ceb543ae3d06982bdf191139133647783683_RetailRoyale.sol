// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./StringUtil.sol";
import "./NumberUtil.sol";
import "./SafeMath.sol";
import "./RRDataset.sol";
import "./RREvent.sol";
import "./RRPayInterface.sol";

contract RetailRoyale is RREvent {
    using SafeMath for *;
    using StringUtil for string;
    using NumberUtil for *;

    uint256 private constant RoundTime = 28800; //86400; //一局初始时间
    uint256 private constant MaxTime = 28800; //最大时长
    uint256 private constant AddTime = 60; //抽一个英雄增加时间
    uint256 private constant HeroPrice = 0.1 ether; //购买英雄价格
    uint256 private constant RankLen = 10; //排行榜长度

    address s_owner;

    mapping(uint256 => uint256) private mapRankWeight; //(rank => weight)
    RRDataset.RankItem[RankLen] arrRank;
    RRDataset.HeroInfo robot;

    uint256 roundIndex;
    mapping(uint256 => RRDataset.Round) mapRound; //(roundId => RRDataset.Round)
    mapping(uint256 => address[]) mapArrPlayer; //(roundId => address[])
    mapping(uint256 => mapping(address => uint256[])) mapPlayer; //(roundId => (address => heroId[]))
    mapping(uint256 => mapping(uint256 => RRDataset.HeroInfo)) mapHero; //(roundId => (heroId => HeroInfo))
    mapping (address => uint256) mapPlayerEth;

    //BattleKey = roundIndex_selfHeroId_enemyHeroId
    mapping(string => RRDataset.BattleInfo) mapBattleInfo; //(BattleKey => BattleInfo)
    mapping(string => mapping(uint256 => RRDataset.BattleRecord)) mapBattleRecord; //(BattleKey => (index => BattleRecord))

    address[] arrPayAddrTempKeys;
    mapping(address => uint256) mapPayAddrTemp; //(address => payVal)

    mapping(uint256 => mapping(address => uint256)) mapPlayerReward;//(roundId => (address => reward))
    mapping(uint256 => address[5]) mapArrRewardRank;//(roundId => address[])

    RRPayInterface private rrPay;

    // VRFConsumer randomVRFConsumer;

    // constructor(address _randomVRFConsumer) {
    //     require(_randomVRFConsumer != address(0),'Random Number Consumer must be a valid address');
    //     // require(_randomVRFConsumer.isContract(),'Random Number Consumer must be a contract');
    //     randomVRFConsumer = VRFConsumer(_randomVRFConsumer);

    //     initGame();
    // }

    constructor(RRPayInterface _rrPay) {
        rrPay = _rrPay;
        s_owner = msg.sender;

        initGame();
        startGame();
    }

    modifier isActivated() {
        require(activated_ == true, "its not ready yet");
        _;
    }

    modifier isInTime() {
        require(
            mapRound[roundIndex].endTime == 0 ||
                mapRound[roundIndex].endTime > block.timestamp,
            "game is over"
        );
        _;
    }

    /**
     * @dev prevents contracts from interacting with game
     */
    modifier isHuman() {
        address _addr = msg.sender;
        uint256 _codeLength;

        assembly {
            _codeLength := extcodesize(_addr)
        }
        require(_codeLength == 0, "sorry humans only");
        _;
    }

    /**
     * @dev sets boundaries for incoming tx
     */
    modifier isWithinLimits(uint256 _eth) {
        require(_eth >= 1000000000, "min error");
        require(_eth <= 100000000000000000000000, "max error");
        _;
    }

    //创建者
    modifier onlySeller() {
        require(msg.sender != s_owner);
        _;
    }

    function initGame() private {
        roundIndex = 0;
        uint8[RankLen] memory arrRankWeight = [
            30,
            20,
            15,
            10,
            8,
            6,
            5,
            3,
            2,
            1
        ];

        uint256 heroId = createRobot();
        robot = mapHero[roundIndex][heroId];

        for (uint256 rank = 1; rank <= RankLen; rank++) {
            mapRankWeight[rank] = arrRankWeight[rank - 1];
            arrRank[rank - 1] = RRDataset.RankItem(rank, heroId, 0);
        }
    }

    function startGame() private {
        roundIndex += 1;
        RRDataset.Round storage round = mapRound[roundIndex];
        round.roundId = roundIndex;
        round.endTime = 0;
        round.heroIndex = 10;
        round.totalBounty = 0;
        round.totalDividend = 0;

        rrPay.curToTotalPayAddr();

        if (roundIndex != 1) {
            delete arrRank;
        }

        //  for (uint256 i = 0; i < RankLen; i++) {
        //     arrRank[i].heroId = arrRobot[i].heroId;
        //     arrRank[i].reward = 0;

        //     round.heroIndex++;
        //     mapHero[roundIndex][arrRobot[i].heroId] = arrRobot[i];
        //  }
    }

    // 初始化创建机器人
    function createRobot() private returns (uint256) {
        RRDataset.HeroSkill memory heroSkill = RRDataset.HeroSkill(
            0,
            0,
            0,
            0,
            0,
            0
        );
        RRDataset.HeroIncome memory income = RRDataset.HeroIncome(0, 0, 0);
        return
            addHero(
                true,
                "img_tx01",
                [uint256(1), uint256(1), uint256(1)],
                heroSkill,
                income
            );
    }

    // 添加英雄
    function addHero(
        bool isBot,
        string memory _head,
        uint256[3] memory _HP_ATK_SPE,
        RRDataset.HeroSkill memory _heroSkill,
        RRDataset.HeroIncome memory _income
    ) private returns (uint256) {
        uint256 heroId;
        address _addr;
        if (isBot) {
            _addr = rrPay.getCurBank();
            heroId = 1;
        } else {
            _addr = msg.sender;
            mapRound[roundIndex].heroIndex += 1;
            heroId = mapRound[roundIndex].heroIndex;
        }

        RRDataset.HeroInfo storage hero = mapHero[roundIndex][heroId];
        hero.addr = _addr;
        hero.heroId = heroId;
        hero.head = _head;
        hero.HP = _HP_ATK_SPE[0];
        hero.ATK = _HP_ATK_SPE[1];
        hero.SPE = _HP_ATK_SPE[2];
        hero.time = block.timestamp;
        hero.heroSkill = _heroSkill;
        hero.income = _income;
        hero.status = RRDataset.HeroStatus.Ready;
        mapPlayer[roundIndex][_addr].push(heroId);

        bool isNew = true;
        for (uint256 i = 0; i < mapArrPlayer[roundIndex].length; i++) {
            if (mapArrPlayer[roundIndex][i] == _addr) {
                isNew = false;
                break;
            }
        }
        if (isNew) {
            mapArrPlayer[roundIndex].push(_addr);
        }

        return heroId;
    }

    //miss && 格挡
    function funcMiss(uint256 _r, uint256 heavyCoat)
        private
        view
        returns (
            bool,
            bool,
            uint256
        )
    {
        //miss
        uint256 num = _r % 100;
        bool isMiss = num <= 20;
    
        //格挡
        bool isHeavyCoat = false;
        if (heavyCoat > 0) {
            isHeavyCoat = num > 20 && num <= 20+heavyCoat;
        }
         _r = randomUp(_r);

        return (isMiss, isHeavyCoat, _r);
    }

    //攻击
    function funcAtt(
        uint256 _r,
        RRDataset.HeroInfo memory _attHero,
        RRDataset.HeroInfo memory _hitHero
    ) private view returns (RRDataset.ReturnFuncAtt memory returnFuncAtt) {
        returnFuncAtt = RRDataset.ReturnFuncAtt(
            false,
            false,
            false,
            false,
            _attHero.ATK,
            _r
        );

        (returnFuncAtt.isMiss, returnFuncAtt.isHeavyCoat, returnFuncAtt.r) = funcMiss(
            returnFuncAtt.r,
            _hitHero.heroSkill.HeavyCoat
        );

        if (returnFuncAtt.isMiss) {
            return returnFuncAtt;
        } else if (returnFuncAtt.isHeavyCoat) {
            return returnFuncAtt;
        } else {
            //杀手
            uint256 attAtk = _attHero.ATK;
            if (
                _attHero.heroSkill.Usurper > 0 &&
                _attHero.heroId > _hitHero.heroId
            ) {
                attAtk += attAtk.mul(25).div(100);
            }
            //暴击
            returnFuncAtt.atk = attAtk;
            (returnFuncAtt.isPrecision, returnFuncAtt.r, returnFuncAtt.atk) = funcPrecision(
                returnFuncAtt.r,
                _attHero.heroSkill.Precision,
                _attHero.heroSkill.Assasin,
                returnFuncAtt.atk
            );
            //免死
            if (returnFuncAtt.atk >= _hitHero.HP) {
                (
                    returnFuncAtt.isGuardianAngel,
                    returnFuncAtt.r
                ) = funcGuardianAngel(returnFuncAtt.r, _hitHero.heroSkill.GuardianAngel);
            }

            return returnFuncAtt;
        }
    }

    //连击
    function funcDoubleBarrel(
        uint256 _r,
        RRDataset.HeroInfo memory _attHero,
        RRDataset.HeroInfo memory _hitHero
    )
        private
        view
        returns (
            bool,
            uint256,
            RRDataset.ReturnFuncAtt memory,
            RRDataset.ReturnFuncAtt memory
        )
    {
        bool isDoubleBarrel = false;
        RRDataset.ReturnFuncAtt memory returnFuncAtt = RRDataset.ReturnFuncAtt(
            false,
            false,
            false,
            false,
            _attHero.ATK,
            _r
        );

        if (_attHero.heroSkill.DoubleBarrel <= 0) {
            return (isDoubleBarrel, returnFuncAtt.r, returnFuncAtt, returnFuncAtt);
        }

        isDoubleBarrel = returnFuncAtt.r % 100 <= _attHero.heroSkill.DoubleBarrel;
        returnFuncAtt.r = randomUp(returnFuncAtt.r);
        if (!isDoubleBarrel) {
            return (isDoubleBarrel, returnFuncAtt.r, returnFuncAtt, returnFuncAtt);
        }

        //第一次攻击
        RRDataset.ReturnFuncAtt memory returnFuncAtt1 = funcAtt(
            returnFuncAtt.r,
            _attHero,
            _hitHero
        );

        //第二次攻击
        RRDataset.ReturnFuncAtt memory returnFuncAtt2 = funcAtt(
            returnFuncAtt1.r,
            _attHero,
            _hitHero
        );

        return (isDoubleBarrel, returnFuncAtt2.r, returnFuncAtt1, returnFuncAtt2);
    }

    //暴击
    function funcPrecision(
        uint256 _r,
        uint256 _precision,
        uint256 _assasin,
        uint256 atk
    )
        private
        view
        returns (
            // view
            bool,
            uint256,
            uint256
        )
    {
        uint256 Precision = 20;
        if (_precision > 0) {
            Precision = Precision.add(_precision);
        }
        bool isPrecision = _r % 100 <= Precision;
        _r = randomUp(_r);

        if (isPrecision) {
            //杀手（assasin）：额外造成100%暴击伤害
            uint256 multiplier = 100;
            if (_assasin > 0) {
                multiplier = 100 + _assasin;
            }
            atk += atk.mul(multiplier.div(100));
        }
        return (isPrecision, _r, atk);
    }

    //免死
    function funcGuardianAngel(uint256 _r, uint256 _GuardianAngel)
        private
        view
        returns (bool, uint256)
    {
        bool isGuardianAngel = false;
        if (_GuardianAngel > 0) {
            isGuardianAngel = _r % 100 <= _GuardianAngel;
            _r = randomUp(_r);
        }

        return (isGuardianAngel, _r);
    }

    //获取当前份数（奖金分配规则）
    function getDenominator() private view returns (uint256) {
        uint256 denominator = 0;
        for (uint256 i = 0; i < arrRank.length; i++) {
            if (arrRank[i].heroId <= RankLen) {
                continue;
            }
            uint256 weight = mapRankWeight[arrRank[i].rank];
            denominator = denominator.add(weight);
        }

        return denominator;
    }

    function changeRank(
        uint256 _oldHeroId,
        uint256 _newHeroId,
        uint256 _rank
    ) private {
        RRDataset.RankItem memory rankItem;
        // RRDataset.HeroInfo memory heroInfo;
        if (_oldHeroId <= RankLen) {
            if (arrRank[_rank - 1].heroId <= RankLen) {
                arrRank[_rank - 1].heroId = _newHeroId;
                arrRank[_rank - 1].rank = _rank;
                updateGrandPot();
                rankItem = arrRank[_rank - 1];
            }
        } else {
            for (uint256 i = 0; i < arrRank.length; i++) {
                if (arrRank[i].heroId == _oldHeroId) {
                    arrRank[i].heroId = _newHeroId;
                    rankItem = arrRank[i];
                    break;
                }
            }
            mapHero[roundIndex][_newHeroId].income.grandPot = mapHero[
                roundIndex
            ][_oldHeroId].income.grandPot;
        }

        if (_oldHeroId > RankLen) {
            mapHero[roundIndex][_oldHeroId].income.grandPot = 0;
        }
        emit RankChangeEvent(rankItem, mapHero[roundIndex][_newHeroId]);
    }

    function updateGrandPot() private {
        uint256 denominator = getDenominator();
        if (denominator == 0) {
            return;
        }
        uint256 unit = mapRound[roundIndex].totalBounty.div(denominator);

        for (uint256 i = 0; i < arrRank.length; i++) {
            if (arrRank[i].heroId <= RankLen) {
                continue;
            }
            uint256 grandPot = unit.mul(mapRankWeight[arrRank[i].rank]);
            arrRank[i].reward = grandPot;
            mapHero[roundIndex][arrRank[i].heroId].income.grandPot = grandPot;
        }
    }

    // 取余产生区间为[0, number]的随机数；
    function random() private view returns (uint256) {
        return
            uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender)));
    }

    function randomUp(uint256 r) private view returns (uint256) {
        r /= 100;
        if (r < 1) {
            r = random();
        }
        return r;
    }

    function addEndTime() private {
        uint256 curTime = mapRound[roundIndex].endTime.add(
                AddTime
            );

            if(curTime.sub(block.timestamp) >= MaxTime){
                mapRound[roundIndex].endTime =  block.timestamp + MaxTime;
            }else{
                mapRound[roundIndex].endTime = curTime;
            }
    }

    //createHero and battle
    function createHero(string memory _head)
        external
        payable
        isActivated
        isInTime
        isHuman
        isWithinLimits(msg.value)
    {
        require(msg.value >= HeroPrice, "Hero Price: 0.1 ETH");

        rrPay.tranform{value:msg.value}();

        uint256 unit = msg.value.div(10);
        //生态基金
        uint256 ecosystem = unit;
        //生态基金
        rrPay.payCorp(ecosystem);
        //大奖池
        uint256 grandPot;
        //第一次创建
        if (mapRound[roundIndex].endTime == 0) {
            mapRound[roundIndex].endTime = block.timestamp.add(RoundTime);
            //大奖池
            grandPot = msg.value.sub(ecosystem);
            mapRound[roundIndex].totalBounty = mapRound[roundIndex]
                .totalBounty
                .add(grandPot);

            _createHero(_head, random());
            return;
        }

        addEndTime();

        //分红(30%立即支付给榜上玩家（按照1-10名权重分配）)
        uint256 dividend = 0;
        //上贡(立即平均支付给目前游戏内全部英雄)
        uint256 tribute = unit.mul(3);

        uint256 denominator = getDenominator();

        if (denominator != 0) {
            dividend = unit.mul(3);

            //大奖池
            grandPot = msg.value.sub(ecosystem).sub(dividend).sub(tribute);
            mapRound[roundIndex].totalBounty = mapRound[roundIndex]
                .totalBounty
                .add(grandPot);
            uint256 unitRank = mapRound[roundIndex].totalBounty.div(
                denominator
            );

            mapRound[roundIndex].totalDividend = mapRound[roundIndex]
                .totalDividend
                .add(dividend);

            //分红(30%立即支付给榜上玩家（按照1-10名权重分配）)
            for (uint256 i = 0; i < arrRank.length; i++) {
                if (arrRank[i].heroId <= RankLen) {
                    arrRank[i].reward = 0;
                    continue;
                }

                uint256 weight = mapRankWeight[arrRank[i].rank];
                uint256 add = (dividend.div(denominator)).mul(weight);

                mapHero[roundIndex][arrRank[i].heroId]
                    .income
                    .dividend = mapHero[roundIndex][arrRank[i].heroId]
                    .income
                    .dividend
                    .add(add);
                address addr = mapHero[roundIndex][arrRank[i].heroId].addr;
                rrPay.addPayAddrTemp(
                    addr,
                    add
                );
                //更新奖励榜
                addReward(addr, add);

                //更新排行榜奖金
                arrRank[i].reward = unitRank.mul(weight);
                mapHero[roundIndex][arrRank[i].heroId]
                    .income
                    .grandPot = unitRank.mul(weight);
            }
        } else {
            //大奖池
            grandPot = msg.value.sub(ecosystem).sub(dividend).sub(tribute);
            mapRound[roundIndex].totalBounty = mapRound[roundIndex]
                .totalBounty
                .add(grandPot);
        }

        //上贡(立即平均支付给目前游戏内全部英雄)
        for (
            uint256 i = RankLen + 1;
            i <= mapRound[roundIndex].heroIndex;
            i++
        ) {
            uint256 add2 = tribute.div(
                mapRound[roundIndex].heroIndex - RankLen
            );

            mapHero[roundIndex][i].income.tribute = mapHero[roundIndex][i]
                .income
                .tribute
                .add(add2);
            
            address addr2 = mapHero[roundIndex][i].addr;
            rrPay.addPayAddrTemp(addr2, add2);
            //更新奖励榜
            addReward(addr2, add2);
        }

        // randomVRFConsumer.sendRandom();
        _createHero(_head, random());
    }

    function _createHero(string memory _head, uint256 _random) private {
        uint256 r = _random;

        uint256 randomNum;

        randomNum = r % 100;
        uint256 doubleBarrel = randomNum <= 20 ? 20 : 0; //连击
        r /= 100;

        randomNum = r % 100;
        uint256 precision = randomNum <= 20 ? 20 : 0; //暴击
        r /= 100;

        randomNum = r % 100;
        uint256 guardianAngel = randomNum <= 20 ? 35 : 0; //免死
        r /= 100;

        randomNum = r % 100;
        uint256 heavyCoat = randomNum <= 20 ? 20 : 0; //格挡
        r /= 100;

        randomNum = r % 100;
        uint256 assasin = randomNum <= 20 ? 100 : 0; //杀手
        r /= 100;

        randomNum = r % 100;
        uint256 usurper = randomNum <= 20 ? 25 : 0; //弑君者
        r /= 100;

        RRDataset.HeroSkill memory heroSkill = RRDataset.HeroSkill(
            doubleBarrel,
            precision,
            guardianAngel,
            heavyCoat,
            assasin,
            usurper
        );

        uint256[3] memory HP_ATK_SPE;
        r /= 1000;
        // HP_ATK_SPE[0] = 700.add(r % (1000 - 700));
        HP_ATK_SPE[0] = 400.add(r % (600 - 400));
        r /= 1000;
        HP_ATK_SPE[1] = 60.add(r % (100 - 60));
        r /= 1000;
        HP_ATK_SPE[2] = 1.add(r % (5 - 1));

        uint256 newHeroId = addHero(
            false,
            _head,
            HP_ATK_SPE,
            heroSkill,
            RRDataset.HeroIncome(0, 0, 0)
        );

        emit CreateHeroEvent(newHeroId, mapHero[roundIndex][newHeroId]);
    }

    mapping(uint256 => bool) mapBattlingRank;

    function battle(
        uint256 selfHeroId,
        uint256 enemyHeroId,
        uint256 _rank
    ) external isActivated isInTime isHuman {
        require(selfHeroId != enemyHeroId, "Can Not Battle Same Hero");

        RRDataset.HeroInfo memory self = mapHero[roundIndex][selfHeroId];
        require(self.status != RRDataset.HeroStatus.Dead, "Self Hero Dead");

        RRDataset.HeroInfo memory enemy;
        if (enemyHeroId <= RankLen) {
            enemy = robot;
        } else {
            enemy = mapHero[roundIndex][enemyHeroId];
        }
        require(enemy.status != RRDataset.HeroStatus.Dead, "Enemy Hero Dead");
        require(self.addr != enemy.addr, "Can Not Battle Self");

        require(!mapBattlingRank[_rank], "This Rank Is Batting");
        mapBattlingRank[_rank] = true;

        for (uint256 i = 0; i < arrRank.length; i++) {
            if (arrRank[i].rank == _rank) {
                if (arrRank[i].heroId != enemyHeroId) {
                    revert("Rank Hero Is Change");
                } else if (
                    arrRank[i].heroId > RankLen &&
                    mapHero[roundIndex][arrRank[i].heroId].status ==
                    RRDataset.HeroStatus.Dead
                ) {
                    revert("Rank Hero Dead");
                }
            }
        }

        addEndTime();

        string memory battleInfoId = roundIndex
            .uintToString()
            .strConcat("_")
            .strConcat(
                selfHeroId.uintToString().strConcat("_").strConcat(
                    enemyHeroId.uintToString()
                )
            );
        RRDataset.BattleInfo storage battleInfo = mapBattleInfo[battleInfoId];

        mapping(uint256 => RRDataset.BattleRecord)
            storage battleRecord = mapBattleRecord[battleInfoId];

        battleInfo.selfId = selfHeroId;
        battleInfo.enemyId = enemyHeroId;

        uint256 index = 0;
        uint256 r = random();

        emit Log("log r:", r);

        // uint256 attHeroId = enemy.SPE > self.SPE ? enemy.heroId : self.heroId;
        uint256 attHeroId = enemy.heroId > self.heroId
            ? enemy.heroId
            : self.heroId;

        while (self.HP > 0 && enemy.HP > 0) {
            index++;
            battleInfo.sizeRecord = index;

            RRDataset.BattleRecord storage record = battleRecord[index];
            record.index = index;

            bool isSelf = attHeroId == self.heroId;
            record.isSelf = isSelf;
            attHeroId = isSelf ? enemy.heroId : self.heroId;

            RRDataset.HeroInfo memory attHero = isSelf ? self : enemy;
            RRDataset.HeroInfo memory hitHero = isSelf ? enemy : self;

            //连击
            bool isDoubleBarrel = false;
            RRDataset.ReturnFuncAtt memory returnFuncAtt1;
            RRDataset.ReturnFuncAtt memory returnFuncAtt2;

            (
                isDoubleBarrel,
                r,
                returnFuncAtt1,
                returnFuncAtt2
            ) = funcDoubleBarrel(r, attHero, hitHero);
            if (isDoubleBarrel) {
                hitHero.HP = hitHero.HP.sub(returnFuncAtt1.atk);
                hitHero.HP = hitHero.HP.sub(returnFuncAtt2.atk);

                if (returnFuncAtt2.isGuardianAngel) {
                    record.attType = RRDataset.BattleType.GuardianAngel;
                } else {
                    record.attType = RRDataset.BattleType.DoubleBarrel;
                }
                record.arrVal = [returnFuncAtt1.atk, returnFuncAtt2.atk];
                continue;
            }

            //普通攻击
            RRDataset.ReturnFuncAtt memory returnFuncAtt = funcAtt(
                r,
                attHero,
                hitHero
            );

            r = returnFuncAtt.r;
            if(returnFuncAtt.isMiss){
                record.attType = RRDataset.BattleType.Miss;
                record.arrVal = [0, 0];
                continue;
            }

            if(returnFuncAtt.isHeavyCoat){
                record.attType = RRDataset.BattleType.HeavyCoat;
                record.arrVal = [0, 0];
                continue;
            }

            //免死
            if (returnFuncAtt.isGuardianAngel) {
                record.attType = RRDataset.BattleType.GuardianAngel;
                record.arrVal = [0, 0];
                continue;
            }
            //暴击
            if (returnFuncAtt.isPrecision) {
                record.attType = RRDataset.BattleType.Precision;
            } else {
                record.attType = RRDataset.BattleType.Hit;
            }
            record.arrVal = [returnFuncAtt.atk, 0];
            hitHero.HP = hitHero.HP.sub(returnFuncAtt.atk);
        }

        bool isWin = enemy.HP <= 0;
        if (isWin) {
            changeRank(enemy.heroId, self.heroId, _rank);
        }
        mapHero[roundIndex][self.heroId].status = isWin
            ? RRDataset.HeroStatus.Win
            : RRDataset.HeroStatus.Dead;
        if (enemy.heroId > RankLen) {
            mapHero[roundIndex][enemy.heroId].status = isWin
                ? RRDataset.HeroStatus.Dead
                : RRDataset.HeroStatus.Win;
        }

        battleInfo.isWin = isWin;

        delete mapBattlingRank[_rank];
    }

    //external
    function getRound() external view returns (uint256 result) {
        return roundIndex;
    }

    function getArrPlayer() external view returns (address[] memory result) {
        return mapArrPlayer[roundIndex];
    }

    function getHeroCnt() external view returns (uint256 result) {
        return mapRound[roundIndex].heroIndex - RankLen;
    }

    function getEndTime() external view returns (uint256 result) {
        return mapRound[roundIndex].endTime;
    }

    function getTotalBounty() external view returns (uint256 result) {
        return mapRound[roundIndex].totalBounty;
    }

    function getTotalDividend() external view returns (uint256 result) {
        return mapRound[roundIndex].totalDividend;
    }

    function getArrHeroIdSelf(address _addr)
        external
        view
        returns (uint256[] memory result)
    {
        return mapPlayer[roundIndex][_addr];
    }

    function getHero(uint256 _heroId)
        external
        view
        returns (RRDataset.HeroInfo memory)
    {
        if (_heroId >= RankLen) {
            return mapHero[roundIndex][_heroId];
        } else {
            return robot;
        }
    }

    function getBattleInfo(string calldata battleInfoId)
        external
        view
        returns (RRDataset.BattleInfo memory)
    {
        // string memory battleInfoId = roundIndex.uintToString().strConcat("_").strConcat(
        //     selfHeroId.uintToString().strConcat("_").strConcat(enemyHeroId.uintToString())
        // );
        return mapBattleInfo[battleInfoId];
    }

    function getBattleRecord(string calldata battleInfoId, uint256 index)
        external
        view
        returns (RRDataset.BattleRecord memory)
    {
        // string memory battleInfoId = roundIndex.uintToString().strConcat("_").strConcat(
        //     selfHeroId.uintToString().strConcat("_").strConcat(enemyHeroId.uintToString())
        // );
        return mapBattleRecord[battleInfoId][index];
    }

    function getRankList()
        external
        view
        returns (RRDataset.RankItem[10] memory result)
    {
        result = arrRank;
        return result;
    }

    function getRankList(uint256 index)
        external
        view
        returns (RRDataset.RankItem memory result)
    {
        result = arrRank[index];
        return result;
    }

    //on-off
    bool public activated_ = true;
    uint256 private timeRemaining;

    function activate() public {
        // only team just can activate
        require(
            msg.sender == 0x1D199373FdA2f12a51250C6589e148Cc0B75fEE1 ||
                msg.sender == 0xb7a46fE564c43c9BF41F824FE6c1e49ca03633c8 ||
                msg.sender == 0xcE724Ae32dDf98D99ffE73585A2Bb716393c88b7,
            "only team just can activate"
        );
        if (activated_) {
            if (mapRound[roundIndex].endTime > 0) {
                timeRemaining = mapRound[roundIndex].endTime - block.timestamp;
                mapRound[roundIndex].endTime = 0;
            }
        } else {
            if (timeRemaining > 0) {
                mapRound[roundIndex].endTime = block.timestamp + timeRemaining;
            }
        }

        activated_ = !activated_;
    }

    function gameOver() external {
        // require(block.timestamp > mapRound[roundIndex].endTime, "no over");
        uint256 denominator = getDenominator();
        if (denominator != 0) {
            uint256 unitRank = mapRound[roundIndex].totalBounty.div(
                denominator
            );

            //结束瓜分奖池给榜上玩家（按照1-10名权重分配）)
            for (uint256 i = 0; i < arrRank.length; i++) {
                if (arrRank[i].heroId <= RankLen) {
                    continue;
                }
                address addr = mapHero[roundIndex][arrRank[i].heroId].addr;
                uint256 val = mapRankWeight[arrRank[i].rank].mul(unitRank);
                rrPay.payPlayer(addr, val);
            }
        }
      

        startGame();

        emit GameOverEvent();
    }

    // receive() external payable{
    //     //接收函数
    // }

    // fallback() external payable{
    //     //回退函数
    // }

    //test
    function setTime(uint256 time) public {
        mapRound[roundIndex].endTime = block.timestamp + time;
        emit SetEndTimeEvent();
    }

    // function testKeeper() external {
    //     arrRank[0].reward = 88888;
    //     mapRound[roundIndex].endTime = 0;
    //     emit GameOverEvent();
    // }

    function getDataTempByAddr() external view  returns (uint256){
        return rrPay.getDataTempByAddr(msg.sender);
    }
    function getDataTotalByAddr() external view  returns (uint256){
            return rrPay.getDataTotalByAddr(msg.sender);
    }

    function payAddrTempByAddr() external {
        rrPay.payAddrTempByAddr(msg.sender);
    }
    function payAddrTotalByAddr() external {
        rrPay.payAddrTotalByAddr(msg.sender);
    }

    function addReward(address addr, uint256 add) private {
        mapPlayerReward[roundIndex][addr] += add;
    }
    
}