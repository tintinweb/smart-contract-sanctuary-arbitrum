// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.19;

import {IV1_Portal} from "./interfaces/IV1_Portal.sol";
import {IV2_Portal} from "./interfaces/IV2_Portal.sol";

/// @title Updater contract to conveniently update maxLockDuration of all Portals
/// @author Possum Labs
/// @notice This contract extends the maxLockDuration of all Portals
contract Updater {
    constructor() {}

    // Portal V1 related variables
    address payable private constant HLP_PORTAL_ADDRESS = payable(0x24b7d3034C711497c81ed5f70BEE2280907Ea1Fa);
    IV1_Portal public constant HLP_PORTAL = IV1_Portal(HLP_PORTAL_ADDRESS);

    // Portal V2 related variables
    address payable private constant ETH_PORTAL_ADDRESS = payable(0xe771545aaDF6feC3815B982fe2294F7230C9c55b);
    address payable private constant USDC_PORTAL_ADDRESS = payable(0x9167CFf02D6f55912011d6f498D98454227F4e16);
    address payable private constant USDCE_PORTAL_ADDRESS = payable(0xE8EfFf304D01aC2D9BA256b602D736dB81f20984);
    address payable private constant WBTC_PORTAL_ADDRESS = payable(0x919B37b5f2f1DEd2a1f6230Bf41790e27b016609);
    address payable private constant ARB_PORTAL_ADDRESS = payable(0x523a93037c47Ba173E9080FE8EBAeae834c24082);
    address payable private constant LINK_PORTAL_ADDRESS = payable(0x51623b54753E07Ba9B3144Ba8bAB969D427982b6);

    IV2_Portal public constant ETH_PORTAL = IV2_Portal(ETH_PORTAL_ADDRESS);
    IV2_Portal public constant USDC_PORTAL = IV2_Portal(USDC_PORTAL_ADDRESS);
    IV2_Portal public constant USDCE_PORTAL = IV2_Portal(USDCE_PORTAL_ADDRESS);
    IV2_Portal public constant WBTC_PORTAL = IV2_Portal(WBTC_PORTAL_ADDRESS);
    IV2_Portal public constant ARB_PORTAL = IV2_Portal(ARB_PORTAL_ADDRESS);
    IV2_Portal public constant LINK_PORTAL = IV2_Portal(LINK_PORTAL_ADDRESS);

    // returns the lock durations of all Portals
    function getCurrentLockDurations()
        external
        view
        returns (
            uint256 durationHLP,
            uint256 durationETH,
            uint256 durationUSDC,
            uint256 durationUSDCE,
            uint256 durationWBTC,
            uint256 durationARB,
            uint256 durationLINK
        )
    {
        durationHLP = HLP_PORTAL.maxLockDuration();
        durationETH = ETH_PORTAL.maxLockDuration();
        durationUSDC = USDC_PORTAL.maxLockDuration();
        durationUSDCE = USDCE_PORTAL.maxLockDuration();
        durationWBTC = WBTC_PORTAL.maxLockDuration();
        durationARB = ARB_PORTAL.maxLockDuration();
        durationLINK = LINK_PORTAL.maxLockDuration();
    }

    // update the maxLockDuration of all Portals
    function updateLockDurations() external {
        HLP_PORTAL.updateMaxLockDuration();
        ETH_PORTAL.updateMaxLockDuration();
        USDC_PORTAL.updateMaxLockDuration();
        USDCE_PORTAL.updateMaxLockDuration();
        WBTC_PORTAL.updateMaxLockDuration();
        ARB_PORTAL.updateMaxLockDuration();
        LINK_PORTAL.updateMaxLockDuration();
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.19;

interface IV2_Portal {
    function PRINCIPAL_TOKEN_ADDRESS() external view returns (address PRINCIPAL_TOKEN_ADDRESS);
    function maxLockDuration() external view returns (uint256 maxLockDuration);
    function updateMaxLockDuration() external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.19;

interface IV1_Portal {
    function getPendingRewards(address _rewarder) external view returns (uint256 claimableReward);
    function claimRewardsHLPandHMX() external;
    function convert(address _token, uint256 _minReceived, uint256 _deadline) external;
    function maxLockDuration() external view returns (uint256 maxLockDuration);
    function updateMaxLockDuration() external;
}