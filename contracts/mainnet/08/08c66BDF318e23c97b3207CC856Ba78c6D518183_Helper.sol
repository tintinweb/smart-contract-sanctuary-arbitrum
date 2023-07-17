// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.17;

import {IERC20} from "./IERC20.sol";

import {IHelper} from "./IHelper.sol";
import {Constants} from "./Constants.sol";
import {Allowed} from "./Allowed.sol";

interface IGlpManager {
    function getPrice(bool) external view returns (uint256);    
}

interface IRewardsTracker {
    function claimForAccount(address _account, address _receiver) external returns (uint256);
    function claimable(address user) external view returns (uint256);
}

interface IFeed {
    function latestRoundData() external view returns (uint80, int256, uint256, uint256, uint80);
}

/**
 * @title Helper contract
 * @author m7
 * @notice 
 * 
 * supports two usecases
 *  a) providing functions to claim the fees of GLP in WETH
 *  b) providing price for WETH in USD
 * this contracts is suppose to be stateless 
 */
contract Helper is IHelper, Allowed {

    uint256 public constant GLP_PRICE_PRECISION = 10 ** 30; // Price precision in GLP
    uint256 public constant PRICE_FEED_PRECISION = 10 ** 8; // Price feed precision
    uint256 private constant GRACE_PERIOD_TIME = 3600;

    IGlpManager public glpMgr;
    IERC20 public native;
    IRewardsTracker public gmxRewards;
    IRewardsTracker public glpRewards;

    IFeed public priceFeed;
    IFeed public sequencer;

    constructor(address _glpMgr, address _native, address _gmxRewards, 
    address _glpRewards, address _priceFeed, address _sequencer) Allowed(msg.sender) {
        glpMgr = IGlpManager(_glpMgr);
        native = IERC20(_native);
        gmxRewards = IRewardsTracker(_gmxRewards);
        glpRewards = IRewardsTracker(_glpRewards);
        priceFeed = IFeed(_priceFeed); // Price feed
        sequencer = IFeed(_sequencer); // ARB Sequencer
    }

    function isSequencerActive() internal view returns (bool) {
        (, int256 answer, uint256 startedAt,,) = sequencer.latestRoundData();
        if (block.timestamp - startedAt <= GRACE_PERIOD_TIME || answer == 1)
            return false;
        return true;
    }

    function setGlpManager(address _glpManager) public onlyOwner {
        require(_glpManager != address(0), "Invalid GLP Manager");
        glpMgr = IGlpManager(_glpManager);
    }

    function setGmxRewards(address _gmxRewards) public onlyOwner {
        gmxRewards = IRewardsTracker(_gmxRewards);
    }

    function setGlpRewards(address _glpRewards) public onlyOwner {
        glpRewards = IRewardsTracker(_glpRewards);
    }

    function setPriceFeed(address _priceFeed) public onlyOwner {
        require(_priceFeed != address(0), "Invalid price feed");
        priceFeed = IFeed(_priceFeed);
    }

    function setSequencer(address _sequencer) public onlyOwner {
        require(_sequencer != address(0), "Invalid arb sequencer");
        sequencer = IFeed(_sequencer);
    }

    function getPriceOfGLP() external view returns (uint256) {
        return (glpMgr.getPrice(true) * Constants.PINT) / GLP_PRICE_PRECISION;
    }

    function getPriceOfRewardToken() external view returns (uint256) {
        (uint80 roundId,int256 price,,uint256 updateTime, uint80 answeredInRound) = priceFeed.latestRoundData();
        require(isSequencerActive(), "HLP: Sequencer is down");
        require(price > 0, "HLP: Invalid chainlink price");
        require(updateTime > 0, "HLP: Incomplete round");
        require(answeredInRound >= roundId, "HLP: Stale price");
        return (uint256(price) * Constants.PINT) / PRICE_FEED_PRECISION;
    }

    function getRewardToken() external view  returns (address) {
        return address(native);
    }

    function getTotalClaimableFees(address _account) external view returns (uint256) {
        uint256 rewardGLP = glpRewards.claimable(_account);
        uint256 rewardGMX = gmxRewards.claimable(_account);
        return rewardGLP + rewardGMX;
    }
}