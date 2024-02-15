// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.4) (utils/Context.sol)

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

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}

// SPDX-License-Identifier: UNLICENSED

//BBBBBBBBBBBBBBBBB                                         kkkkkkkk         XXXXXXX       XXXXXXX
//B::::::::::::::::B                                        k::::::k         X:::::X       X:::::X
//B::::::BBBBBB:::::B                                       k::::::k         X:::::X       X:::::X
//BB:::::B     B:::::B                                      k::::::k         X::::::X     X::::::X
//  B::::B     B:::::B   aaaaaaaaaaaaa   nnnn  nnnnnnnn      k:::::k kkkkkkk XXX:::::X   X:::::XXX
//  B::::B     B:::::B   a::::::::::::a  n:::nn::::::::nn    k:::::k k:::::k    X:::::X X:::::X
//  B::::BBBBBB:::::B    aaaaaaaaa:::::a n::::::::::::::nn   k:::::k k:::::k     X:::::X:::::X
//  B:::::::::::::BB              a::::a nn:::::::::::::::n  k:::::k k:::::k      X:::::::::X
//  B::::BBBBBB:::::B      aaaaaaa:::::a   n:::::nnnn:::::n  k::::::k:::::k       X:::::::::X
//  B::::B     B:::::B   aa::::::::::::a   n::::n    n::::n  k:::::::::::k       X:::::X:::::X
//  B::::B     B:::::B  a::::aaaa::::::a   n::::n    n::::n  k:::::::::::k      X:::::X X:::::X
//  B::::B     B:::::B a::::a    a:::::a   n::::n    n::::n  k::::::k:::::k  XXX:::::X   X:::::XXX
//BB:::::BBBBBB::::::B a::::a    a:::::a   n::::n    n::::n k::::::k k:::::k X::::::X     X::::::X
//B:::::::::::::::::B  a:::::aaaa::::::a   n::::n    n::::n k::::::k k:::::k X:::::X       X:::::X
//B::::::::::::::::B    a::::::::::aa:::a  n::::n    n::::n k::::::k k:::::k X:::::X       X:::::X
//BBBBBBBBBBBBBBBBB      aaaaaaaaaa  aaaa  nnnnnn    nnnnnn kkkkkkkk kkkkkkk XXXXXXX       XXXXXXX
//
//Currency Creators Manifesto
//
//Our world faces an urgent crisis of currency manipulation, theft and inflation.  Under the current system,
// currency is controlled by and benefits elite families, governments and large banking institutions.  We believe
// currencies should be minted by and benefit the individual, not the establishment.  It is time to take back the
// control of and the freedom that money can provide.
//
//BankX is rebuilding the legacy banking system from the ground up by providing you with the capability to create
// currency and be in complete control of wealth creation with a concept we call ‘Individual Created Digital Currency’
// (ICDC). You own the collateral.  You mint currency.  You earn interest.  You leverage without the risk of liquidation.
// You stake to earn even more returns.  All of this is done with complete autonomy and decentralization.  BankX has
// built a stablecoin for Individual Freedom.
//
//BankX is the antidote for the malevolent financial system bringing in a new future of freedom where you are in
// complete control with no middlemen, bank or central bank between you and your finances. This capability to create
// currency and be in complete control of wealth creation will be in the hands of every individual that uses BankX.
//
//By 2030, we will rid the world of the corrupt, tyrannical and incompetent banking system replacing it with a system
// where billions of people will be in complete control of their financial future.  Everyone will be given ultimate
// freedom to use their assets to create currency, earn interest and multiply returns to accomplish their individual
// goals.  The mission of BankX is to be the first to mint $1 trillion in stablecoin.
//
//We will bring about this transformation by attracting people that believe what we believe.  We will partner with
// other blockchain protocols and build decentralized applications that drive even more usage.  Finally, we will deploy
// a private network that is never connected to the Internet to communicate between counterparties, that allows for
// blockchain-to-blockchain interoperability and stores private keys and cryptocurrency wallets.  Our ecosystem,
// network and platform has never been seen in the market and provides us with a long term sustainable competitive advantage.
//
//We value individual freedom.
//We believe in financial autonomy.
//We are anti-establishment.
//We envision a future of self-empowerment.

pragma solidity 0.8.16;

import "./GlobalsAndStats.sol";
//import "hardhat/console.sol";

contract CD is GlobalsAndStats {
  bool public initiated;

  function init() external {
    require(initiated == false, "initiated");

    _transferOwnership(_msgSender());

    /* Initialize global cdRate to 1 */
    globals.cdRate = uint40(1 * CD_RATE_SCALE);
    globals.dailyDataCount = 1;
    launchTime = block.timestamp;
    LPBBonusPercent = 20;
    LPB = 364 * 100 / LPBBonusPercent;  // 1820

    initiated = true;
  }

  /**
   * @dev PUBLIC FACING: Open a stake.
     * @param newStakedXs Number of Xs to stake
     * @param newStakedDays Number of days to stake
     */
  function stakeStart(uint256 newStakedXs, uint256 newStakedDays) external
  {
    GlobalsCache memory g;
    GlobalsCache memory gSnapshot;
    _globalsLoad(g, gSnapshot);

    updateLPB();

    /* Enforce the minimum stake time */
    require(newStakedDays >= MIN_STAKE_DAYS, "newStakedDays low");

    /* Check if log data needs to be updated */
    _dailyDataUpdateAuto(g);

    _stakeStart(g, newStakedXs, newStakedDays);

    /* Remove staked Xs from balance of staker */
    bankXContract.pool_burn_from(msg.sender, newStakedXs * 1e10);

    _globalsSync(g, gSnapshot);
  }

  /**
   * @dev PUBLIC FACING: Unlocks a completed stake, distributing the proceeds of any penalty
     * immediately. The staker must still call stakeEnd() to retrieve their stake return (if any).
     * @param stakerAddr Address of staker
     * @param stakeIndex Index of stake within stake list
     * @param stakeIdParam The stake's id
     */
  function stakeGoodAccounting(address stakerAddr, uint256 stakeIndex, uint40 stakeIdParam)
  external
  {
    GlobalsCache memory g;
    GlobalsCache memory gSnapshot;
    _globalsLoad(g, gSnapshot);

    require(stakeLists[stakerAddr].length != 0, "empty stake list");
    require(stakeIndex < stakeLists[stakerAddr].length, "stakeIndex invalid");

    StakeStore storage stRef = stakeLists[stakerAddr][stakeIndex];

    /* Get stake copy */
    StakeCache memory st;
    _stakeLoad(stRef, stakeIdParam, st);

    /* Stake must have served full term */
    require(g._currentDay >= st._lockedDay + st._stakedDays, "Stake not fully served");

    /* Stake must still be locked */
    require(st._unlockedDay == 0, "Stake already unlocked");

    /* Check if log data needs to be updated */
    _dailyDataUpdateAuto(g);

    /* Unlock the completed stake */
    _stakeUnlock(g, st);

    /* stakeReturn value is unused here */
    (, uint256 payout, uint256 penalty, uint256 cappedPenalty) = _stakePerformance(
      g,
      st,
      st._stakedDays
    );

    _emitStakeGoodAccounting(
      stakerAddr,
      stakeIdParam,
      st._stakedXs,
      st._stakeShares,
      payout,
      penalty
    );

    if (cappedPenalty != 0) {
      _splitPenaltyProceeds(g, cappedPenalty);
    }

    /* st._unlockedDay has changed */
    _stakeUpdate(stRef, st);

    _globalsSync(g, gSnapshot);
  }

  /**
   * @dev PUBLIC FACING: Closes a stake. The order of the stake list can change so
     * a stake id is used to reject stale indexes.
     * @param stakeIndex Index of stake within stake list
     * @param stakeId The stake's id
     */
  function stakeEnd(uint256 stakeIndex, uint40 stakeId) external {
    GlobalsCache memory g;
    GlobalsCache memory gSnapshot;
    _globalsLoad(g, gSnapshot);

    updateLPB();

    StakeStore[] storage stakeListRef = stakeLists[msg.sender];

    require(stakeListRef.length != 0, "empty stake list");
    require(stakeIndex < stakeListRef.length, "stakeIndex invalid");

    /* Get stake copy */
    StakeCache memory st;
    _stakeLoad(stakeListRef[stakeIndex], stakeId, st);

    /* Check if log data needs to be updated */
    _dailyDataUpdateAuto(g);

    uint256 servedDays = 0;

    bool prevUnlocked = (st._unlockedDay != 0);
    uint256 stakeReturn;
    uint256 payout = 0;
    uint256 penalty = 0;
    uint256 cappedPenalty = 0;

    if (g._currentDay >= st._lockedDay) {
      if (prevUnlocked) {
        /* Previously unlocked in stakeGoodAccounting(), so must have served full term */
        servedDays = st._stakedDays;
      } else {
        _stakeUnlock(g, st);

        servedDays = g._currentDay - st._lockedDay;
        if (servedDays > st._stakedDays) {
          servedDays = st._stakedDays;
        }
      }

      (stakeReturn, payout, penalty, cappedPenalty) = _stakePerformance(g, st, servedDays);
    } else {
      /* Stake hasn't been added to the total yet, so no penalties or rewards apply */
      g._nextStakeSharesTotal -= st._stakeShares;
      stakeReturn = st._stakedXs;
    }

    _emitStakeEnd(
      stakeId,
      st._stakedXs,
      st._stakeShares,
      payout,
      penalty,
      servedDays,
      prevUnlocked
    );

    if (cappedPenalty != 0 && !prevUnlocked) {
      /* Split penalty proceeds only if not previously unlocked by stakeGoodAccounting() */
      _splitPenaltyProceeds(g, cappedPenalty);
    }

    /* Pay the stake return, if any, to the staker */
    if (stakeReturn != 0) {
      bankXContract.pool_mint(msg.sender, stakeReturn * 1e10);

      /* Update the share rate if necessary */
      _cdRateUpdate(g, st, stakeReturn);
    }
    g._lockedXsTotal -= st._stakedXs;

    _stakeRemove(stakeListRef, stakeIndex);

    _globalsSync(g, gSnapshot);

    nftBonusContract.stakeEnd(msg.sender, stakeId);
  }

  /**
   * @dev PUBLIC FACING: Return the current stake count for a staker address
     * @param stakerAddr Address of staker
     */
  function stakeCount(address stakerAddr) external view returns (uint256)
  {
    return stakeLists[stakerAddr].length;
  }

  /**
   * @dev Open a stake.
     * @param g Cache of stored globals
     * @param newStakedXs Number of Xs to stake
     * @param newStakedDays Number of days to stake
     */
  function _stakeStart(GlobalsCache memory g, uint256 newStakedXs, uint256 newStakedDays) internal
  {
    /* Enforce the maximum stake time */
    require(newStakedDays <= MAX_STAKE_DAYS, "newStakedDays high");

    uint40 newStakeId = ++g._latestStakeId;

    nftBonusContract.assignStakeId(msg.sender, newStakeId);

    uint256 bonusXs = _stakeStartBonusXs(newStakedXs, newStakedDays, newStakeId);
    uint256 newStakeShares = (newStakedXs + bonusXs) * CD_RATE_SCALE / g._cdRate;

//    console.log("bonusXs", bonusXs);
//    console.log("newStakedXs", newStakedXs);
//    console.log("newStakeShares", newStakeShares);

    /* Ensure newStakedXs is enough for at least one stake share */
    require(newStakeShares != 0, "newStakedXs must be >= min cdRate");

    /*
        The stakeStart timestamp will always be part-way through the current
        day, so it needs to be rounded-up to the next day to ensure all
        stakes align with the same fixed calendar days. The current day is
        already rounded-down, so rounded-up is current day + 1.
    */
    uint256 newLockedDay = g._currentDay + 1;

    /* Create Stake */
    _stakeAdd(
      stakeLists[msg.sender],
      newStakeId,
      newStakedXs,
      newStakeShares,
      newLockedDay,
      newStakedDays
    );

    _emitStakeStart(newStakeId, newStakedXs, newStakeShares, newStakedDays);

    /* Stake is added to total in the next round, not the current round */
    g._nextStakeSharesTotal += newStakeShares;

    /* Track total staked Xs for inflation calculations */
    g._lockedXsTotal += newStakedXs;
  }

  /**
   * @dev Calculates total stake payout including rewards for a multi-day range
     * @param stakeSharesParam Param from stake to calculate bonuses for
     * @param beginDay First day to calculate bonuses for
     * @param endDay Last day (non-inclusive) of range to calculate bonuses for
     * @return payout Payout in Xs
     */
  function _calcPayoutRewards(uint256 stakeSharesParam, uint256 beginDay, uint256 endDay)
  private view returns (uint256 payout)
  {
    for (uint256 day = beginDay; day < endDay; day++) {
      payout += dailyData[day].dayPayoutTotal * stakeSharesParam
      / dailyData[day].dayStakeSharesTotal;
    }

    return payout;
  }

  /**
   * @dev Calculate bonus Xs for a new stake, if any
     * @param newStakedXs Number of Xs to stake
     * @param newStakedDays Number of days to stake
     */
  function _stakeStartBonusXs(uint256 newStakedXs, uint256 newStakedDays, uint40 newStakeId) private view returns (uint256 bonusXs)
  {
    /*
        LONGER PAYS BETTER:

        If longer than 1 day stake is committed to, each extra day
        gives bonus shares of approximately 0.0548%, which is approximately 20%
        extra per year of increased stake length committed to, but capped to a
        maximum of 200% extra.

        extraDays       =  stakedDays - 1

        longerBonus%    = (extraDays / 364) * 33.33%
                        = (extraDays / 364) / 3
                        =  extraDays / 1092
                        =  extraDays / LPB

        extraDays       =  longerBonus% * 1092

        extraDaysMax    =  longerBonusMax% * 1092
                        =  200% * 1092
                        =  2184
                        =  LPB_MAX_DAYS

        BIGGER PAYS BETTER:

        Bonus percentage scaled 0% to 10% for the first 150M BankX of stake.

        biggerBonus%    = (cappedXs /  BPB_MAX_XS) * 10%
                        = (cappedXs /  BPB_MAX_XS) / 10
                        =  cappedXs / (BPB_MAX_XS * 10)
                        =  cappedXs /  BPB

        COMBINED:

        combinedBonus%  =            longerBonus%  +  biggerBonus%

                                  cappedExtraDays     cappedXs
                        =         ---------------  +  ------------
                                        LPB               BPB

                            cappedExtraDays * BPB     cappedXs * LPB
                        =   ---------------------  +  ------------------
                                  LPB * BPB               LPB * BPB

                            cappedExtraDays * BPB  +  cappedXs * LPB
                        =   --------------------------------------------
                                              LPB  *  BPB

        bonusXs     = Xs * combinedBonus%
                        = Xs * (cappedExtraDays * BPB  +  cappedXs * LPB) / (LPB * BPB)
    */
    uint256 cappedExtraDays = 0;

    /* Must be more than 1 day for Longer-Pays-Better */
    if (newStakedDays > 1) {
      cappedExtraDays = newStakedDays <= LPB_MAX_DAYS ? newStakedDays - 1 : LPB_MAX_DAYS;
    }

    uint256 cappedStakedXs = newStakedXs <= BPB_MAX_XS ? newStakedXs : BPB_MAX_XS;

//    console.log("newStakedXs", newStakedXs);
//    console.log("cappedStakedXs", cappedStakedXs);


    bonusXs = cappedExtraDays * BPB + cappedStakedXs * LPB;

//    console.log("LPB", LPB);
//    console.log("cappedStakedXs * LPB", cappedStakedXs * LPB);
//    console.log("BPB", BPB);
//    console.log("cappedExtraDays * BPB", cappedExtraDays * BPB);
//    console.log("cappedExtraDays * BPB + cappedStakedXs * LPB", bonusXs);

    bonusXs = newStakedXs * bonusXs / (LPB * BPB);

//    console.log("newStakedXs * bonusXs / (LPB * BPB)", bonusXs);

    return bonusXs + bonusXs * nftBonusContract.getNftsCount(newStakeId) / 10;
  }

  function updateLPB() public {
    bool lastUpdatedWeekAgo = (block.timestamp - LPBLastUpdated) >= 7 days;
    bool positiveInflation = bankXContract.totalSupply() > bankXContract.genesis_supply();

    if (positiveInflation && LPBBonusPercent < 40 && lastUpdatedWeekAgo) {
      LPBBonusPercent = LPBBonusPercent + 5;
      LPBLastUpdated = block.timestamp;
    }
    else if (!positiveInflation && LPBBonusPercent > 20) {
      LPBBonusPercent = 20;
      LPBLastUpdated = block.timestamp;
    }

    LPB = 36400 / LPBBonusPercent;
  }

  function _stakeUnlock(GlobalsCache memory g, StakeCache memory st) private pure {
    g._stakeSharesTotal -= st._stakeShares;
    st._unlockedDay = g._currentDay;
  }

  function _stakePerformance(GlobalsCache memory g, StakeCache memory st, uint256 servedDays) private view
  returns (uint256 stakeReturn, uint256 payout, uint256 penalty, uint256 cappedPenalty){
    if (servedDays < st._stakedDays) {
      (payout, penalty) = _calcPayoutAndEarlyPenalty(
        g,
        st._lockedDay,
        st._stakedDays,
        servedDays,
        st._stakeShares
      );
      stakeReturn = st._stakedXs + payout;
    } else {
      // servedDays must == stakedDays here
      payout = _calcPayoutRewards(
        st._stakeShares,
        st._lockedDay,
        st._lockedDay + servedDays
      );
      stakeReturn = st._stakedXs + payout;

      penalty = _calcLatePenalty(st._lockedDay, st._stakedDays, st._unlockedDay, stakeReturn);
    }
    if (penalty != 0) {
      if (penalty > stakeReturn) {
        /* Cannot have a negative stake return */
        cappedPenalty = stakeReturn;
        stakeReturn = 0;
      } else {
        /* Remove penalty from the stake return */
        cappedPenalty = penalty;
        stakeReturn -= cappedPenalty;
      }
    }
    return (stakeReturn, payout, penalty, cappedPenalty);
  }

  function _calcPayoutAndEarlyPenalty(GlobalsCache memory g, uint256 lockedDay, uint256 stakedDays, uint256 servedDays, uint256 stakeShares)
  private view returns (uint256 payout, uint256 penalty) {
    uint256 servedEndDay = lockedDay + servedDays;

    /* 50% of stakedDays (rounded up) with a minimum applied */
    uint256 penaltyDays = (stakedDays + 1) / 2;
    if (penaltyDays < EARLY_PENALTY_MIN_DAYS) {
      penaltyDays = EARLY_PENALTY_MIN_DAYS;
    }

    if (servedDays == 0) {
      /* Fill penalty days with the estimated average payout */
      uint256 expected = _estimatePayoutRewardsDay(g, stakeShares, lockedDay);
      penalty = expected * penaltyDays;
      return (payout, penalty);
      // Actual payout was 0
    }

    if (penaltyDays < servedDays) {
      /*
          Simplified explanation of intervals where end-day is non-inclusive:

          penalty:    [lockedDay  ...  penaltyEndDay)
          delta:                      [penaltyEndDay  ...  servedEndDay)
          payout:     [lockedDay  .......................  servedEndDay)
      */
      uint256 penaltyEndDay = lockedDay + penaltyDays;
      penalty = _calcPayoutRewards(stakeShares, lockedDay, penaltyEndDay);

      uint256 delta = _calcPayoutRewards(stakeShares, penaltyEndDay, servedEndDay);
      payout = penalty + delta;
      return (payout, penalty);
    }

    /* penaltyDays >= servedDays  */
    payout = _calcPayoutRewards(stakeShares, lockedDay, servedEndDay);

    if (penaltyDays == servedDays) {
      penalty = payout;
    } else {
      /*
          (penaltyDays > servedDays) means not enough days served, so fill the
          penalty days with the average payout from only the days that were served.
      */
      penalty = payout * penaltyDays / servedDays;

      if (LPBBonusPercent > 20) {
        penalty += calculateLPBPenalty(payout, stakedDays, servedDays);
      }
    }
    return (payout, penalty);
  }

  function calculateLPBPenalty(uint payout, uint stakedDays, uint servedDays) public view returns (uint) {
    return payout * (((LPBBonusPercent - 20) * (stakedDays - servedDays)) / 10) * 11;
  }

  function _calcLatePenalty(uint256 lockedDay, uint256 stakedDays, uint256 unlockedDay, uint256 rawStakeReturn)
  private pure returns (uint256){
    /* Allow grace time before penalties accrue */
    uint256 maxUnlockedDay = lockedDay + stakedDays + LATE_PENALTY_GRACE_DAYS;
    if (unlockedDay <= maxUnlockedDay) {
      return 0;
    }

    /* Calculate penalty as a percentage of stake return based on time */
    return rawStakeReturn * (unlockedDay - maxUnlockedDay) / LATE_PENALTY_SCALE_DAYS;
  }

  function _splitPenaltyProceeds(GlobalsCache memory g, uint256 penalty) private
  {
    /* Split a penalty 50:50 between Origin and stakePenaltyTotal */
    uint256 splitPenalty = penalty / 2;

    if (splitPenalty != 0) {
      bankXContract.pool_mint(ORIGIN_ADDR, splitPenalty * 1e10);
    }

    /* Use the other half of the penalty to account for an odd-numbered penalty */
    splitPenalty = penalty - splitPenalty;
    g._stakePenaltyTotal += splitPenalty;
  }

  function _cdRateUpdate(GlobalsCache memory g, StakeCache memory st, uint256 stakeReturn) private
  {
    if (stakeReturn > st._stakedXs) {
      /*
          Calculate the new cdRate that would yield the same number of shares if
          the user re-staked this stakeReturn, factoring in any bonuses they would
          receive in stakeStart().
      */
      uint256 bonusXs = _stakeStartBonusXs(stakeReturn, st._stakedDays, st._stakeId);
      uint256 newCDRate = (stakeReturn + bonusXs) * CD_RATE_SCALE / st._stakeShares;

      // Realistically this can't happen, but capped to prevent anyway.
      if (newCDRate > CD_RATE_MAX) {
        newCDRate = CD_RATE_MAX;
      }

      if (newCDRate > g._cdRate) {
        g._cdRate = newCDRate;

        _emitCDRateChange(newCDRate, st._stakeId);
      }
    }
  }

  function _emitStakeStart(uint40 stakeId, uint256 stakedXs, uint256 stakeShares, uint256 stakedDays) private
  {
    emit StakeStart(
      uint256(uint40(block.timestamp))
      | (uint256(uint72(stakedXs)) << 40)
      | (uint256(uint72(stakeShares)) << 112)
      | (uint256(uint16(stakedDays)) << 184)
      | 0,
      msg.sender,
      stakeId
    );
  }

  function _emitStakeGoodAccounting(
    address stakerAddr,
    uint40 stakeId,
    uint256 stakedXs,
    uint256 stakeShares,
    uint256 payout,
    uint256 penalty
  )
  private
  {
    emit StakeGoodAccounting(
      uint256(uint40(block.timestamp))
      | (uint256(uint72(stakedXs)) << 40)
      | (uint256(uint72(stakeShares)) << 112)
      | (uint256(uint72(payout)) << 184),
      uint256(uint72(penalty)),
      stakerAddr,
      stakeId,
      msg.sender
    );
  }

  function _emitStakeEnd(
    uint40 stakeId,
    uint256 stakedXs,
    uint256 stakeShares,
    uint256 payout,
    uint256 penalty,
    uint256 servedDays,
    bool prevUnlocked
  )
  private
  {
    emit StakeEnd(
      uint256(uint40(block.timestamp))
      | (uint256(uint72(stakedXs)) << 40)
      | (uint256(uint72(stakeShares)) << 112)
      | (uint256(uint72(payout)) << 184),
      uint256(uint72(penalty))
      | (uint256(uint16(servedDays)) << 72)
      | (prevUnlocked ? (1 << 88) : 0),
      msg.sender,
      stakeId
    );
  }

  function _emitCDRateChange(uint256 cdRate, uint40 stakeId)
  private
  {
    emit CDRateChange(
      uint256(uint40(block.timestamp))
      | (uint256(uint40(cdRate)) << 40),
      stakeId
    );
  }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.16;

import './lib/Ownable.sol';
import "./interfaces/BankXInterface.sol";
import "./interfaces/NFTBonusInterface.sol";
import "./interfaces/CollateralPoolInterface.sol";

contract GlobalsAndStats is Ownable {

  /*  DailyDataUpdate

      uint40            timestamp       -->  data0 [ 39:  0]
      uint16            beginDay        -->  data0 [ 55: 40]
      uint16            endDay          -->  data0 [ 71: 56]
      bool              isAutoUpdate    -->  data0 [ 79: 72]
      address  indexed  updaterAddr
  */
  event DailyDataUpdate(
    uint256 data0,
    address indexed updaterAddr
  );

  /*  StakeStart

      uint40            timestamp       -->  data0 [ 39:  0]
      address  indexed  stakerAddr
      uint40   indexed  stakeId
      uint72            stakedXs        -->  data0 [111: 40]
      uint72            stakeShares     -->  data0 [183:112]
      uint16            stakedDays      -->  data0 [199:184]
      bool              isAutoStake     -->  data0 [207:200]
  */
  event StakeStart(
    uint256 data0,
    address indexed stakerAddr,
    uint40 indexed stakeId
  );

  /*  StakeGoodAccounting

      uint40            timestamp       -->  data0 [ 39:  0]
      address  indexed  stakerAddr
      uint40   indexed  stakeId
      uint72            stakedXs        -->  data0 [111: 40]
      uint72            stakeShares     -->  data0 [183:112]
      uint72            payout          -->  data0 [255:184]
      uint72            penalty         -->  data1 [ 71:  0]
      address  indexed  senderAddr
  */
  event StakeGoodAccounting(
    uint256 data0,
    uint256 data1,
    address indexed stakerAddr,
    uint40 indexed stakeId,
    address indexed senderAddr
  );

  /*  StakeEnd

      uint40            timestamp       -->  data0 [ 39:  0]
      address  indexed  stakerAddr
      uint40   indexed  stakeId
      uint72            stakedXs        -->  data0 [111: 40]
      uint72            stakeShares     -->  data0 [183:112]
      uint72            payout          -->  data0 [255:184]
      uint72            penalty         -->  data1 [ 71:  0]
      uint16            servedDays      -->  data1 [ 87: 72]
      bool              prevUnlocked    -->  data1 [ 95: 88]
  */
  event StakeEnd(
    uint256 data0,
    uint256 data1,
    address indexed stakerAddr,
    uint40 indexed stakeId
  );

  /*  CDRateChange
      // pricing control CD rate - requires BankX to make price go up.
      // keeps staking ahead of inflation
      uint40            timestamp    -->  data0 [ 39:  0]
      uint40            CDRate       -->  data0 [ 79: 40]
      uint40   indexed  stakeId
  */
  event CDRateChange(uint256 data0, uint40 indexed stakeId);

  /* Origin BankX address */
  address internal constant ORIGIN_ADDR = 0xC0C607cF29852476311B4C17328D18A2D02A845c;
  BankXInterface public bankXContract;
  NFTBonusInterface public nftBonusContract;
  CollateralPoolInterface public collateralPoolContract;

  /* Size of a Xs or CD uint */
  uint256 internal constant X_UINT_SIZE = 72;

  /* Stake timing parameters */
  uint256 internal constant MIN_STAKE_DAYS = 1;
  uint256 internal constant MAX_STAKE_DAYS = 5555; // Approx 15 years

  uint256 internal constant EARLY_PENALTY_MIN_DAYS = 90;

  uint256 internal constant LATE_PENALTY_GRACE_DAYS = 2 * 7;
  uint256 internal constant LATE_PENALTY_SCALE_DAYS = 100 * 7;

  /* Time of contract launch */
  uint256 internal launchTime;

  /* Stake shares Longer Pays Better bonus constants used by _stakeStartBonusXs() */
  uint256 public LPBBonusPercent;
  uint256 public LPB;
  uint256 public constant LPB_MAX_DAYS = 3640;
  uint256 public LPBLastUpdated;

  /* Stake shares Bigger Pays Better bonus constants used by _stakeStartBonusXs() */
  uint256 private constant XS_PER_BANKX = 1e8;
  uint256 private constant BPB_BONUS_PERCENT = 10;
  uint256 private constant BPB_MAX_BANKX = 150 * 1e6;
  uint256 internal constant BPB_MAX_XS = BPB_MAX_BANKX * XS_PER_BANKX;
  uint256 internal constant BPB = BPB_MAX_XS * 100 / BPB_BONUS_PERCENT;

  /* Share rate is scaled to increase precision */
  uint256 internal constant CD_RATE_SCALE = 1e5;

  /* Share rate max (after scaling) */
  uint256 internal constant CD_RATE_UINT_SIZE = 40;
  uint256 internal constant CD_RATE_MAX = (1 << CD_RATE_UINT_SIZE) - 1;

  /* Globals expanded for memory (except _latestStakeId) and compact for storage */
  struct GlobalsCache {
    // 1
    uint256 _lockedXsTotal;
    uint256 _nextStakeSharesTotal;
    uint256 _cdRate;
    uint256 _stakePenaltyTotal;
    // 2
    uint256 _dailyDataCount;
    uint256 _stakeSharesTotal;
    uint40 _latestStakeId;
    //
    uint256 _currentDay;
  }

  struct GlobalsStore {
    // 1
    uint72 lockedXsTotal;
    uint72 nextStakeSharesTotal;
    uint40 cdRate;
    uint72 stakePenaltyTotal;
    // 2
    uint16 dailyDataCount;
    uint72 stakeSharesTotal;
    uint40 latestStakeId;
  }

  GlobalsStore public globals;

  /* Daily data */
  struct DailyDataStore {
    uint72 dayPayoutTotal;
    uint72 dayStakeSharesTotal;
    uint56 dayUnclaimedSatoshisTotal;
  }

  mapping(uint256 => DailyDataStore) public dailyData;

  /* Stake expanded for memory (except _stakeId) and compact for storage */
  struct StakeCache {
    uint40 _stakeId;
    uint256 _stakedXs;
    uint256 _stakeShares;
    uint256 _lockedDay;
    uint256 _stakedDays;
    uint256 _unlockedDay;
  }

  struct StakeStore {
    uint40 stakeId;
    uint72 stakedXs;
    uint72 stakeShares;
    uint16 lockedDay;
    uint16 stakedDays;
    uint16 unlockedDay;
  }

  mapping(address => StakeStore[]) public stakeLists;

  /* Temporary state for calculating daily rounds */
  struct DailyRoundState {
    uint256 _allocSupplyCached;
    uint256 _mintOriginBatch;
    uint256 _payoutTotal;
  }

  /**
   * @dev PUBLIC FACING: Optionally update daily data for a smaller
     * range to reduce gas cost for a subsequent operation
     * @param beforeDay Only update days before this day number (optional; 0 for current day)
     */
  function dailyDataUpdate(uint256 beforeDay) external
  {
    GlobalsCache memory g;
    GlobalsCache memory gSnapshot;
    _globalsLoad(g, gSnapshot);

    if (beforeDay != 0) {
      require(beforeDay <= g._currentDay, "beforeDay cannot be in the future");

      _dailyDataUpdate(g, beforeDay, false);
    } else {
      /* Default to updating before current day */
      _dailyDataUpdate(g, g._currentDay, false);
    }

    _globalsSync(g, gSnapshot);
  }

  /**
   * @dev PUBLIC FACING: Helper to return multiple values of daily data with a single call.
     * @param beginDay First day of data range
     * @param endDay Last day (non-inclusive) of data range
     * @return list Fixed array of packed values
     */
  function dailyDataRange(uint256 beginDay, uint256 endDay) external view returns (uint256[] memory list)
  {
    require(beginDay < endDay && endDay <= globals.dailyDataCount, "range invalid");

    list = new uint256[](endDay - beginDay);

    uint256 src = beginDay;
    uint256 dst = 0;
    uint256 v;
    do {
      v = uint256(dailyData[src].dayUnclaimedSatoshisTotal) << (X_UINT_SIZE * 2);
      v |= uint256(dailyData[src].dayStakeSharesTotal) << X_UINT_SIZE;
      v |= uint256(dailyData[src].dayPayoutTotal);

      list[dst++] = v;
    }
    while (++src < endDay);

    return list;
  }

  /**
   * @dev PUBLIC FACING: External helper to return most global info with a single call.
     * @return Fixed array of values
     */
  function globalInfo() external view returns (uint256[9] memory) {
    return [
    // 1
    globals.lockedXsTotal,
    globals.nextStakeSharesTotal,
    globals.cdRate,
    globals.stakePenaltyTotal,
    // 2
    globals.dailyDataCount,
    globals.stakeSharesTotal,
    globals.latestStakeId,
    block.timestamp,
    bankXContract.totalSupply() / 1e10
    ];
  }

  /**
   * @dev PUBLIC FACING: ERC20 totalSupply() is the circulating supply and does not include any
     * staked Xs. allocatedSupply() includes both.
     * @return Allocated Supply in Xs
     */
  function allocatedSupply() external view returns (uint256){
    return bankXContract.totalSupply() / 1e10 + collateralPoolContract.bankx_minted_count() / 1e10 + globals.lockedXsTotal;
  }

  /**
   * @dev PUBLIC FACING: External helper for the current day number since launch time
     * @return Current day number (zero-based)
     */
  function currentDay() external view returns (uint256) {
    return _currentDay();
  }

  function _currentDay() internal view returns (uint256) {
    return (block.timestamp - launchTime) / 1 days;
  }

  function _dailyDataUpdateAuto(GlobalsCache memory g) internal {
    _dailyDataUpdate(g, g._currentDay, true);
  }

  function _globalsLoad(GlobalsCache memory g, GlobalsCache memory gSnapshot) internal view {
    // 1
    g._lockedXsTotal = globals.lockedXsTotal;
    g._nextStakeSharesTotal = globals.nextStakeSharesTotal;
    g._cdRate = globals.cdRate;
    g._stakePenaltyTotal = globals.stakePenaltyTotal;
    // 2
    g._dailyDataCount = globals.dailyDataCount;
    g._stakeSharesTotal = globals.stakeSharesTotal;
    g._latestStakeId = globals.latestStakeId;
    g._currentDay = _currentDay();

    _globalsCacheSnapshot(g, gSnapshot);
  }

  function _globalsCacheSnapshot(GlobalsCache memory g, GlobalsCache memory gSnapshot) internal pure
  {
    // 1
    gSnapshot._lockedXsTotal = g._lockedXsTotal;
    gSnapshot._nextStakeSharesTotal = g._nextStakeSharesTotal;
    gSnapshot._cdRate = g._cdRate;
    gSnapshot._stakePenaltyTotal = g._stakePenaltyTotal;
    // 2
    gSnapshot._dailyDataCount = g._dailyDataCount;
    gSnapshot._stakeSharesTotal = g._stakeSharesTotal;
    gSnapshot._latestStakeId = g._latestStakeId;
  }

  function _globalsSync(GlobalsCache memory g, GlobalsCache memory gSnapshot) internal {
    if (g._lockedXsTotal != gSnapshot._lockedXsTotal
    || g._nextStakeSharesTotal != gSnapshot._nextStakeSharesTotal
    || g._cdRate != gSnapshot._cdRate
      || g._stakePenaltyTotal != gSnapshot._stakePenaltyTotal) {
      // 1
      globals.lockedXsTotal = uint72(g._lockedXsTotal);
      globals.nextStakeSharesTotal = uint72(g._nextStakeSharesTotal);
      globals.cdRate = uint40(g._cdRate);
      globals.stakePenaltyTotal = uint72(g._stakePenaltyTotal);
    }
    if (g._dailyDataCount != gSnapshot._dailyDataCount
    || g._stakeSharesTotal != gSnapshot._stakeSharesTotal
      || g._latestStakeId != gSnapshot._latestStakeId) {
      // 2
      globals.dailyDataCount = uint16(g._dailyDataCount);
      globals.stakeSharesTotal = uint72(g._stakeSharesTotal);
      globals.latestStakeId = g._latestStakeId;
    }
  }

  function _stakeLoad(StakeStore storage stRef, uint40 stakeIdParam, StakeCache memory st) internal view
  {
    /* Ensure caller's stakeIndex is still current */
    require(stakeIdParam == stRef.stakeId, "stakeIdParam not in stake");

    st._stakeId = stRef.stakeId;
    st._stakedXs = stRef.stakedXs;
    st._stakeShares = stRef.stakeShares;
    st._lockedDay = stRef.lockedDay;
    st._stakedDays = stRef.stakedDays;
    st._unlockedDay = stRef.unlockedDay;
  }

  function _stakeUpdate(StakeStore storage stRef, StakeCache memory st) internal
  {
    stRef.stakeId = st._stakeId;
    stRef.stakedXs = uint72(st._stakedXs);
    stRef.stakeShares = uint72(st._stakeShares);
    stRef.lockedDay = uint16(st._lockedDay);
    stRef.stakedDays = uint16(st._stakedDays);
    stRef.unlockedDay = uint16(st._unlockedDay);
  }

  function _stakeAdd(
    StakeStore[] storage stakeListRef,
    uint40 newStakeId,
    uint256 newStakedXs,
    uint256 newStakeShares,
    uint256 newLockedDay,
    uint256 newStakedDays
  )
  internal
  {
    stakeListRef.push(
      StakeStore(
        newStakeId,
        uint72(newStakedXs),
        uint72(newStakeShares),
        uint16(newLockedDay),
        uint16(newStakedDays),
        uint16(0) // unlockedDay
      )
    );
  }

  /**
   * @dev Efficiently delete from an unordered array by moving the last element
     * to the "hole" and reducing the array length. Can change the order of the list
     * and invalidate previously held indexes.
     * @notice stakeListRef length and stakeIndex are already ensured valid in stakeEnd()
     * @param stakeListRef Reference to stakeLists[stakerAddr] array in storage
     * @param stakeIndex Index of the element to delete
     */
  function _stakeRemove(StakeStore[] storage stakeListRef, uint256 stakeIndex) internal
  {
    uint256 lastIndex = stakeListRef.length - 1;

    /* Skip the copy if element to be removed is already the last element */
    if (stakeIndex != lastIndex) {
      /* Copy last element to the requested element's "hole" */
      stakeListRef[stakeIndex] = stakeListRef[lastIndex];
    }

    /*
        Reduce the array length now that the array is contiguous.
        Surprisingly, 'pop()' uses less gas than 'stakeListRef.length = lastIndex'
    */
    stakeListRef.pop();
  }

  /**
   * @dev Estimate the stake payout for an incomplete day
     * @param g Cache of stored globals
     * @param stakeSharesParam Param from stake to calculate bonuses for
     * @param day Day to calculate bonuses for
     * @return payout Payout in Xs
     */
  function _estimatePayoutRewardsDay(GlobalsCache memory g, uint256 stakeSharesParam, uint256 day)
  internal view returns (uint256 payout)
  {
    /* Prevent updating state for this estimation */
    GlobalsCache memory gTmp;
    _globalsCacheSnapshot(g, gTmp);

    DailyRoundState memory rs;
    rs._allocSupplyCached = bankXContract.totalSupply() / 1e10 + g._lockedXsTotal;

    _dailyRoundCalc(gTmp, rs, day);

    /* Stake is no longer locked so it must be added to total as if it were */
    gTmp._stakeSharesTotal += stakeSharesParam;

    payout = rs._payoutTotal * stakeSharesParam / gTmp._stakeSharesTotal;

    return payout;
  }

  function _dailyRoundCalc(GlobalsCache memory g, DailyRoundState memory rs, uint256 day) private pure
  {
    /*
        Calculate payout round

        Inflation of 5.28% inflation per 364 days             (approx 1 year)
        dailyInterestRate   = exp(log(1 + 5.28%)  / 364) - 1
                            = exp(log(1 + 0.0528) / 364) - 1
                            = exp(log(1.0528) / 364) - 1
                            = 0.000141365                     (approx)

        payout  = allocSupply * dailyInterestRate
                = allocSupply / (1 / dailyInterestRate)
                = allocSupply / (1 / 0.000141365)
                = allocSupply / 7073.88674707                 (approx)
                = allocSupply * 10000 / 70738867              (* 10000/10000 for int precision)
    */

    rs._payoutTotal = rs._allocSupplyCached * 10000 / 70738867;

    if (g._stakePenaltyTotal != 0) {
      rs._payoutTotal += g._stakePenaltyTotal;
      g._stakePenaltyTotal = 0;
    }
  }

  function _dailyRoundCalcAndStore(GlobalsCache memory g, DailyRoundState memory rs, uint256 day) private
  {
    _dailyRoundCalc(g, rs, day);

    dailyData[day].dayPayoutTotal = uint72(rs._payoutTotal);
    dailyData[day].dayStakeSharesTotal = uint72(g._stakeSharesTotal);
  }

  function _dailyDataUpdate(GlobalsCache memory g, uint256 beforeDay, bool isAutoUpdate) private
  {
    if (g._dailyDataCount >= beforeDay) {
      /* Already up-to-date */
      return;
    }

    DailyRoundState memory rs;
    rs._allocSupplyCached = bankXContract.totalSupply() / 1e10 + g._lockedXsTotal;

    uint256 day = g._dailyDataCount;

    _dailyRoundCalcAndStore(g, rs, day);

    /* Stakes started during this day are added to the total the next day */
    if (g._nextStakeSharesTotal != 0) {
      g._stakeSharesTotal += g._nextStakeSharesTotal;
      g._nextStakeSharesTotal = 0;
    }

    while (++day < beforeDay) {
      _dailyRoundCalcAndStore(g, rs, day);
    }

    _emitDailyDataUpdate(g._dailyDataCount, day, isAutoUpdate);
    g._dailyDataCount = day;

    if (rs._mintOriginBatch != 0) {
      bankXContract.pool_mint(ORIGIN_ADDR, rs._mintOriginBatch * 1e10);
    }
  }

  function _emitDailyDataUpdate(uint256 beginDay, uint256 endDay, bool isAutoUpdate) private
  {
    emit DailyDataUpdate(
      uint256(uint40(block.timestamp))
      | (uint256(uint16(beginDay)) << 40)
      | (uint256(uint16(endDay)) << 56)
      | (isAutoUpdate ? (1 << 72) : 0),
      msg.sender
    );
  }

  function updateBankXContract(address _bankXContract) public onlyOwner() {
    bankXContract = BankXInterface(_bankXContract);
  }

  function updateNFTBonusContract(address _nftBonusContract) public onlyOwner() {
    nftBonusContract = NFTBonusInterface(_nftBonusContract);
  }

  function updateCollateralPoolContract(address _collateralPoolContract) public onlyOwner() {
    collateralPoolContract = CollateralPoolInterface(_collateralPoolContract);
  }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.16;

interface BankXInterface {

    function balanceOf(address account) external view returns (uint256);

    function pool_mint(address _entity, uint _amount) external;

    function pool_burn_from(address _entity, uint _amount) external;

    function genesis_supply() external returns (uint);

    function totalSupply() external view returns (uint);

    function updateTVLReached() external;

}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.16;

interface CollateralPoolInterface {

  function bankx_minted_count() external view returns (uint);

  function collatDollarBalance() external view returns (uint);

}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.16;

interface NFTBonusInterface {

  function getNftsCount(uint _stakeId) external view returns (uint);

  function assignStakeId(address _owner, uint _stakeId) external returns (bool);

  function stakeEnd(address _owner, uint _stakeId) external;

  function nftIdStakedToEntity(uint _nftId) external view returns (address);

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/Context.sol';

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender() || owner() == address(0), "Ownable: caller is not the owner");
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