/**
 *Submitted for verification at Arbiscan on 2023-08-10
*/

/** 
 *  SourceUnit: f:\protocolCreate\stfx\contracts-v2\src\protocols\DdexReader\DdexReader.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: UNLICENSED
pragma solidity ^0.8.17;

library Errors {
    // Zero Errors
    error ZeroAmount();
    error ZeroAddress();
    error ZeroTotalRaised();
    error ZeroClaimableAmount();

    // Modifier Errors
    error NotOwner();
    error NotAdmin();
    error CallerNotVault();
    error CallerNotTrade();
    error CallerNotVaultOwner();
    error CallerNotGenerate();
    error NoAccess();
    error NotPlugin();

    // State Errors
    error BelowMinFundraisingPeriod();
    error AboveMaxFundraisingPeriod();
    error BelowMinLeverage();
    error AboveMaxLeverage();
    error BelowMinEndTime();
    error TradeTokenNotApplicable();

    // STV errors
    error StvDoesNotExist();
    error AlreadyOpened();
    error MoreThanTotalRaised();
    error MoreThanTotalReceived();
    error StvNotOpen();
    error StvNotClose();
    error ClaimNotApplicable();
    error StvStatusMismatch();

    // General Errors
    error BalanceLessThanAmount();
    error FundraisingPeriodEnded();
    error TotalRaisedMoreThanCapacity();
    error StillFundraising();
    error CommandMisMatch();
    error TradeCommandMisMatch();
    error NotInitialised();
    error Initialised();
    error LengthMismatch();
    error TransferFailed();
    error DelegateCallFailed();
    error CallFailed(bytes);
    error AccountAlreadyExists();
    error SwapFailed();
    error ExchangeDataMismatch();
    error AccountNotExists();
    error InputMismatch();

    // Protocol specific errors
    error GmxFeesMisMatch();
    error UpdateOrderRequestMisMatch();
    error CancelOrderRequestMisMatch();
}




/** 
 *  SourceUnit: f:\protocolCreate\stfx\contracts-v2\src\protocols\DdexReader\DdexReader.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: UNLICENSED
pragma solidity ^0.8.17;

interface IReader {
    // CAP
    struct Market {
        string name; // Market's full name, e.g. Bitcoin / U.S. Dollar
        string category; // crypto, fx, commodities, or indices
        address chainlinkFeed; // Price feed contract address
        uint256 maxLeverage; // No decimals
        uint256 maxDeviation; // In bps, max price difference from oracle to chainlink price
        uint256 fee; // In bps. 10 = 0.1%
        uint256 liqThreshold; // In bps
        uint256 fundingFactor; // Yearly funding rate if OI is completely skewed to one side. In bps.
        uint256 minOrderAge; // Min order age before is can be executed. In seconds
        uint256 pythMaxAge; // Max Pyth submitted price age, in seconds
        bytes32 pythFeed; // Pyth price feed id
        bool allowChainlinkExecution; // Allow anyone to execute orders with chainlink
        bool isReduceOnly; // accepts only reduce only orders
    }

    // CAP
    function get(string memory market) external view returns (Market memory);
    function getOI(address asset, string memory market) external view returns (uint256);
    function getOILong(address asset, string memory market) external view returns (uint256);
    function getOIShort(address asset, string memory market) external view returns (uint256);
    function getMaxOI(string memory market, address asset) external view returns (uint256);
    function getMarketCount() external view returns (uint256);
    function getMarketList() external view returns (string[] memory);
}


/** 
 *  SourceUnit: f:\protocolCreate\stfx\contracts-v2\src\protocols\DdexReader\DdexReader.sol
*/

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: UNLICENSED
pragma solidity ^0.8.17;

////import {IReader} from "src/protocols/DdexReader/interfaces/IReader.sol";
////import {Errors} from "src/libraries/Errors.sol";

contract DdexReader {
    address public owner;

    // GMX
    // https://github.com/gmx-io/gmx-contracts/blob/0b5a5371a77bf584298d46958543a1405dd1c403/contracts/peripherals/Reader.sol#L301

    // CAP
    address constant RISK_STORE = 0xF7C9E1bE73dD1a028BB45b86cfB78608c4eCB61c;
    address constant POSITION_STORE = 0x29087096c889Fd7158CB6cBA675ED561d36DBFa7;
    address constant MARKET_STORE = 0x328416146a3caa51BfD3f3e25C6F08784f03E276;
    // TODO change asset for CAP in a way to use ETH & USDC both
    address constant USDC = 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8; // USDC.e // asset param for CAP
    address constant WETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
    string constant ETH_MARKET = "ETH-USD";
    string constant BTC_MARKET = "BTC-USD";
    // @notice market list changes when they add
    // 30 markets as of 10 Aug 2023 => [ETH-USD,BTC-USD,EUR-USD,XAU-USD,AAVE-USD,ADA-USD,BNB-USD,MATIC-USD,NEAR-USD,SOL-USD,AUD-USD,USD-CNH,USD-CAD,GBP-USD,USD-JPY,USD-CHF,XAG-USD,NZD-USD,USD-MXN,USD-SGD,USD-ZAR,SPY-USD,QQQ-USD,ARB-USD,FLOKI-USD,DOGE-USD,SUI-USD,PEPE-USD,LTC-USD,XRP-USD]
    string[] public capMarkets;

    constructor() {
        owner = msg.sender;
        capMarkets = IReader(MARKET_STORE).getMarketList();
    }

    modifier onlyOwner() {
        if (msg.sender != owner) revert Errors.NotOwner();
        _;
    }

    function setCapMarkets() external onlyOwner {
        capMarkets = IReader(MARKET_STORE).getMarketList();
    }

    function setOwner(address newOwner) external onlyOwner {
        if (newOwner == address(0)) revert Errors.ZeroAddress();
        owner = newOwner;
    }

    function getCapLiquidity(string memory market) public view returns (uint256 availableLiq) {
        uint256 maxOI = IReader(RISK_STORE).getMaxOI(market, USDC);
        uint256 currentOI = IReader(POSITION_STORE).getOI(USDC, market);
        availableLiq = maxOI - currentOI;
    }

    function getAllCapLiquidity() external view returns (uint256[] memory availableLiq) {
        availableLiq = new uint256[](capMarkets.length);
        uint256 i;
        for (; i < availableLiq.length;) {
            availableLiq[i] = getCapLiquidity(capMarkets[i]);
            unchecked {
                ++i;
            }
        }
    }

    function getCapLiquidityBTCandETH() external view returns (uint256 availableLiqBTC, uint256 availableLiqETH) {
        availableLiqBTC = getCapLiquidity(BTC_MARKET);
        availableLiqETH = getCapLiquidity(ETH_MARKET);
    }

    function getCapFunding(string memory market) public view returns (int256 fundingRate) {
        uint256 fundingFactor = IReader(MARKET_STORE).get(market).fundingFactor;
        uint256 longOI = IReader(POSITION_STORE).getOILong(USDC, market);
        uint256 shortOI = IReader(POSITION_STORE).getOIShort(USDC, market);

        if (longOI + shortOI > 0) {
            fundingRate = int256(fundingFactor)
                * ((int256(shortOI) - int256(longOI)) * 1e18 / int256((longOI) + (shortOI))) / (365 * 24);
        }
    }

    function getAllCapFunding(uint256 marketsLength) public view returns (int256[] memory fundingRates) {
        if (marketsLength > capMarkets.length) revert Errors.LengthMismatch();
        fundingRates = new int256[](marketsLength);
        uint256 i;
        for (; i < marketsLength;) {
            fundingRates[i] = getCapFunding(capMarkets[i]);
            unchecked {
                ++i;
            }
        }
    }
}