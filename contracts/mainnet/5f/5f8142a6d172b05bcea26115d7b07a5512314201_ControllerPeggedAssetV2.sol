// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IVaultFactoryV2} from "../interfaces/IVaultFactoryV2.sol";
import {IVaultV2} from "../interfaces/IVaultV2.sol";
import "@chainlink/interfaces/AggregatorV3Interface.sol";
import "@chainlink/interfaces/AggregatorV2V3Interface.sol";
import {FixedPointMathLib} from "@solmate/utils/FixedPointMathLib.sol";

/// @author Y2K Finance Team

contract ControllerPeggedAssetV2 {
    using FixedPointMathLib for uint256;
    IVaultFactoryV2 public immutable vaultFactory;
    AggregatorV2V3Interface internal sequencerUptimeFeed;

    uint256 private constant MAX_UPDATE_TRESHOLD = 2 days;
    uint16 private constant GRACE_PERIOD_TIME = 3600;

    /*//////////////////////////////////////////////////////////////
                                CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /** @notice Contract constructor
     * @param _factory VaultFactory address
     * @param _l2Sequencer Arbitrum sequencer address
     */
    constructor(address _factory, address _l2Sequencer) {
        if (_factory == address(0)) revert ZeroAddress();

        if (_l2Sequencer == address(0)) revert ZeroAddress();

        vaultFactory = IVaultFactoryV2(_factory);
        sequencerUptimeFeed = AggregatorV2V3Interface(_l2Sequencer);
    }

    /*//////////////////////////////////////////////////////////////
                                FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /** @notice Trigger depeg event
     * @param _marketId Target market index
     * @param _epochId End of epoch set for market
     */
    function triggerDepeg(uint256 _marketId, uint256 _epochId) public {
        address[2] memory vaults = vaultFactory.getVaults(_marketId);

        if (vaults[0] == address(0) || vaults[1] == address(0))
            revert MarketDoesNotExist(_marketId);

        IVaultV2 premiumVault = IVaultV2(vaults[0]);
        IVaultV2 collateralVault = IVaultV2(vaults[1]);

        if (premiumVault.epochExists(_epochId) == false) revert EpochNotExist();

        int256 price = getLatestPrice(_marketId);

        if (int256(premiumVault.strike()) <= price)
            revert PriceNotAtStrikePrice(price);

        (uint40 epochStart, uint40 epochEnd, ) = premiumVault.getEpochConfig(
            _epochId
        );

        if (uint256(epochStart) > block.timestamp) revert EpochNotStarted();

        if (block.timestamp > uint256(epochEnd)) revert EpochExpired();

        //require this function cannot be called twice in the same epoch for the same vault
        if (premiumVault.epochResolved(_epochId)) revert EpochFinishedAlready();
        if (collateralVault.epochResolved(_epochId))
            revert EpochFinishedAlready();

        // check if epoch qualifies for null epoch
        if (
            premiumVault.totalAssets(_epochId) == 0 ||
            collateralVault.totalAssets(_epochId) == 0
        ) {
            revert VaultZeroTVL();
        }

        premiumVault.resolveEpoch(_epochId);
        collateralVault.resolveEpoch(_epochId);

        uint256 epochFee = vaultFactory.getEpochFee(_epochId);

        uint256 premiumTVL = premiumVault.finalTVL(_epochId);
        uint256 collateralTVL = collateralVault.finalTVL(_epochId);

        uint256 premiumFee = calculateWithdrawalFeeValue(premiumTVL, epochFee);
        uint256 collateralFee = calculateWithdrawalFeeValue(
            collateralTVL,
            epochFee
        );

        // avoid stack too deep error by avoiding local variables
        // uint256 premiumTVLAfterFee = premiumTVL - premiumFee;
        // uint256 collateralTVLAfterFee = collateralTVL - collateralFee;

        premiumVault.setClaimTVL(_epochId, collateralTVL - collateralFee);
        collateralVault.setClaimTVL(_epochId, premiumTVL - premiumFee);

        // send fees to treasury and remaining TVL to respective counterparty vault
        // strike price reached so premium is entitled to collateralTVL - collateralFee
        premiumVault.sendTokens(
            _epochId,
            premiumFee,
            IVaultFactoryV2(vaultFactory).treasury()
        );
        premiumVault.sendTokens(
            _epochId,
            premiumTVL - premiumFee,
            address(collateralVault)
        );
        // strike price is reached so collateral is still entitled to premiumTVL - premiumFee but looses collateralTVL
        collateralVault.sendTokens(
            _epochId,
            collateralFee,
            IVaultFactoryV2(vaultFactory).treasury()
        );
        collateralVault.sendTokens(
            _epochId,
            collateralTVL - collateralFee,
            address(premiumVault)
        );

        emit EpochResolved(
            _epochId,
            _marketId,
            VaultTVL(
                premiumTVL - premiumFee,
                collateralTVL,
                collateralTVL - collateralFee,
                premiumTVL
            ),
            true,
            block.timestamp,
            uint256(price)
        );

        emit ProtocolFeeCollected(
            _epochId,
            _marketId,
            premiumFee,
            collateralFee,
            block.timestamp
        );
    }

    /** @notice Trigger epoch end without depeg event
     * @param _marketId Target market index
     * @param _epochId End of epoch set for market
     */
    function triggerEndEpoch(uint256 _marketId, uint256 _epochId) public {
        address[2] memory vaults = vaultFactory.getVaults(_marketId);

        if (vaults[0] == address(0) || vaults[1] == address(0))
            revert MarketDoesNotExist(_marketId);

        IVaultV2 premiumVault = IVaultV2(vaults[0]);
        IVaultV2 collateralVault = IVaultV2(vaults[1]);

        if (
            premiumVault.epochExists(_epochId) == false ||
            collateralVault.epochExists(_epochId) == false
        ) revert EpochNotExist();

        if (
            premiumVault.totalAssets(_epochId) == 0 ||
            collateralVault.totalAssets(_epochId) == 0
        ) {
            revert VaultZeroTVL();
        }

        (, uint40 epochEnd, ) = premiumVault.getEpochConfig(_epochId);

        if (block.timestamp <= uint256(epochEnd)) revert EpochNotExpired();

        //require this function cannot be called twice in the same epoch for the same vault
        if (premiumVault.epochResolved(_epochId)) revert EpochFinishedAlready();
        if (collateralVault.epochResolved(_epochId))
            revert EpochFinishedAlready();

        premiumVault.resolveEpoch(_epochId);
        collateralVault.resolveEpoch(_epochId);

        uint256 epochFee = vaultFactory.getEpochFee(_epochId);

        uint256 premiumTVL = premiumVault.finalTVL(_epochId);
        uint256 collateralTVL = collateralVault.finalTVL(_epochId);

        uint256 premiumFee = calculateWithdrawalFeeValue(premiumTVL, epochFee);

        uint256 premiumTVLAfterFee = premiumTVL - premiumFee;
        uint256 collateralTVLAfterFee = collateralTVL + premiumTVLAfterFee;

        // strike price is not reached so premium is entiled to 0
        premiumVault.setClaimTVL(_epochId, 0);
        // strike price is not reached so collateral is entitled to collateralTVL + premiumTVLAfterFee
        collateralVault.setClaimTVL(_epochId, collateralTVLAfterFee);

        // send premium fees to treasury and remaining TVL to collateral vault
        premiumVault.sendTokens(
            _epochId,
            premiumFee,
            IVaultFactoryV2(vaultFactory).treasury()
        );
        // strike price reached so collateral is entitled to collateralTVLAfterFee
        premiumVault.sendTokens(
            _epochId,
            premiumTVLAfterFee,
            address(collateralVault)
        );

        emit EpochResolved(
            _epochId,
            _marketId,
            VaultTVL(collateralTVLAfterFee, collateralTVL, 0, premiumTVL),
            false,
            block.timestamp,
            0
        );

        emit ProtocolFeeCollected(
            _epochId,
            _marketId,
            premiumFee,
            0,
            block.timestamp
        );
    }

    /** @notice Trigger epoch invalid when one vault has 0 TVL
     * @param _marketId Target market index
     * @param _epochId End of epoch set for market
     */
    function triggerNullEpoch(uint256 _marketId, uint256 _epochId) public {
        address[2] memory vaults = vaultFactory.getVaults(_marketId);

        if (vaults[0] == address(0) || vaults[1] == address(0))
            revert MarketDoesNotExist(_marketId);

        IVaultV2 premiumVault = IVaultV2(vaults[0]);
        IVaultV2 collateralVault = IVaultV2(vaults[1]);

        if (
            premiumVault.epochExists(_epochId) == false ||
            collateralVault.epochExists(_epochId) == false
        ) revert EpochNotExist();

        (uint40 epochStart, , ) = premiumVault.getEpochConfig(_epochId);

        if (block.timestamp < uint256(epochStart)) revert EpochNotStarted();

        //require this function cannot be called twice in the same epoch for the same vault
        if (premiumVault.epochResolved(_epochId)) revert EpochFinishedAlready();
        if (collateralVault.epochResolved(_epochId))
            revert EpochFinishedAlready();

        //set claim TVL to final TVL if total assets are 0
        if (premiumVault.totalAssets(_epochId) == 0) {
            premiumVault.resolveEpoch(_epochId);
            collateralVault.resolveEpoch(_epochId);

            premiumVault.setClaimTVL(_epochId, 0);
            collateralVault.setClaimTVL(
                _epochId,
                collateralVault.finalTVL(_epochId)
            );

            collateralVault.setEpochNull(_epochId);
        } else if (collateralVault.totalAssets(_epochId) == 0) {
            premiumVault.resolveEpoch(_epochId);
            collateralVault.resolveEpoch(_epochId);

            premiumVault.setClaimTVL(_epochId, premiumVault.finalTVL(_epochId));
            collateralVault.setClaimTVL(_epochId, 0);

            premiumVault.setEpochNull(_epochId);
        } else revert VaultNotZeroTVL();

        emit NullEpoch(
            _epochId,
            _marketId,
            VaultTVL(
                collateralVault.claimTVL(_epochId),
                collateralVault.finalTVL(_epochId),
                premiumVault.claimTVL(_epochId),
                premiumVault.finalTVL(_epochId)
            ),
            block.timestamp
        );
    }

    /*//////////////////////////////////////////////////////////////
                                GETTERS
    //////////////////////////////////////////////////////////////*/
    /** @notice Lookup token price
     * @param _marketId Target token address
     * @return nowPrice Current token price
     */
    function getLatestPrice(uint256 _marketId) public view returns (int256) {
        (
            ,
            /*uint80 roundId*/
            int256 answer,
            uint256 startedAt, /*uint256 updatedAt*/ /*uint80 answeredInRound*/
            ,

        ) = sequencerUptimeFeed.latestRoundData();

        // Answer == 0: Sequencer is up
        // Answer == 1: Sequencer is down
        bool isSequencerUp = answer == 0;
        if (!isSequencerUp) {
            revert SequencerDown();
        }

        // Make sure the grace period has passed after the sequencer is back up.
        uint256 timeSinceUp = block.timestamp - startedAt;
        if (timeSinceUp <= GRACE_PERIOD_TIME) {
            revert GracePeriodNotOver();
        }

        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            vaultFactory.marketToOracle(_marketId)
        );
        (
            uint80 roundID,
            int256 price,
            ,
            uint256 updatedAt,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();

        if (updatedAt < block.timestamp - MAX_UPDATE_TRESHOLD)
            revert PriceOutdated();

        uint256 decimals = priceFeed.decimals();

        if (decimals < 18) {
            decimals = 10**(18 - (decimals));
            price = price * int256(decimals);
        } else if (decimals == 18) {
            price = price;
        } else {
            decimals = 10**((decimals - 18));
            price = price / int256(decimals);
        }

        if (price <= 0) revert OraclePriceZero();

        if (answeredInRound < roundID) revert RoundIDOutdated();

        return price;
    }

    function canExecDepeg(uint256 _marketId, uint256 _epochId) public view returns (bool){
        address[2] memory vaults = vaultFactory.getVaults(_marketId);

        if (vaults[0] == address(0) || vaults[1] == address(0))
            return false;

        IVaultV2 premiumVault = IVaultV2(vaults[0]);
        IVaultV2 collateralVault = IVaultV2(vaults[1]);

        if (premiumVault.epochExists(_epochId) == false) return false;

        int256 price = getLatestPrice(_marketId);

        if (int256(premiumVault.strike()) <= price)
            return false;

        (uint40 epochStart, uint40 epochEnd, ) = premiumVault.getEpochConfig(
            _epochId
        );

        if (uint256(epochStart) > block.timestamp) return false;

        if (block.timestamp > uint256(epochEnd)) return false;

        //require this function cannot be called twice in the same epoch for the same vault
        if (premiumVault.epochResolved(_epochId)) return false;
        if (collateralVault.epochResolved(_epochId))
            return false;

        // check if epoch qualifies for null epoch
        if (
            premiumVault.totalAssets(_epochId) == 0 ||
            collateralVault.totalAssets(_epochId) == 0
        ) {
            return false;
        }
        return true;
    }

    function canExecNullEpoch(uint256 _marketId, uint256 _epochId) public view returns (bool) {
        address[2] memory vaults = vaultFactory.getVaults(_marketId);

        if (vaults[0] == address(0) || vaults[1] == address(0))
            return false;

        IVaultV2 premiumVault = IVaultV2(vaults[0]);
        IVaultV2 collateralVault = IVaultV2(vaults[1]);

        if (
            premiumVault.epochExists(_epochId) == false ||
            collateralVault.epochExists(_epochId) == false
        ) return false;

        (uint40 epochStart, , ) = premiumVault.getEpochConfig(_epochId);

        if (block.timestamp < uint256(epochStart)) return false;

        if (premiumVault.epochResolved(_epochId)) return false;
        if (collateralVault.epochResolved(_epochId))
            return false;

        if (premiumVault.totalAssets(_epochId) == 0) {
           return true;
        } else if (collateralVault.totalAssets(_epochId) == 0) {
           return true;
        } else  return false;
    }

    function canExecEnd(uint256 _marketId, uint256 _epochId)public view returns (bool) {
        address[2] memory vaults = vaultFactory.getVaults(_marketId);

        if (vaults[0] == address(0) || vaults[1] == address(0))
            return false;

        IVaultV2 premiumVault = IVaultV2(vaults[0]);
        IVaultV2 collateralVault = IVaultV2(vaults[1]);

        if (
            premiumVault.epochExists(_epochId) == false ||
            collateralVault.epochExists(_epochId) == false
        ) return false;

        if (
            premiumVault.totalAssets(_epochId) == 0 ||
            collateralVault.totalAssets(_epochId) == 0
        ) {
           return false;
        }

        (, uint40 epochEnd, ) = premiumVault.getEpochConfig(_epochId);

        if (block.timestamp <= uint256(epochEnd)) return false;

        //require this function cannot be called twice in the same epoch for the same vault
        if (premiumVault.epochResolved(_epochId)) return false;
        if (collateralVault.epochResolved(_epochId))
            return false;
        return true;
    }

    /** @notice Lookup target VaultFactory address
     * @dev need to find way to express typecasts in NatSpec
     */
    function getVaultFactory() external view returns (address) {
        return address(vaultFactory);
    }

    /** @notice Calculate amount to withdraw after subtracting protocol fee
     * @param amount Amount of tokens to withdraw
     * @param fee Fee to be applied
     */
    function calculateWithdrawalFeeValue(uint256 amount, uint256 fee)
        public
        pure
        returns (uint256 feeValue)
    {
        // 0.5% = multiply by 10000 then divide by 50
        return amount.mulDivDown(fee, 10000);
    }

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    error MarketDoesNotExist(uint256 marketId);
    error SequencerDown();
    error GracePeriodNotOver();
    error ZeroAddress();
    error EpochFinishedAlready();
    error PriceNotAtStrikePrice(int256 price);
    error EpochNotStarted();
    error EpochExpired();
    error OraclePriceZero();
    error RoundIDOutdated();
    error EpochNotExist();
    error EpochNotExpired();
    error VaultNotZeroTVL();
    error VaultZeroTVL();
    error PriceOutdated();

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    /** @notice Resolves epoch when event is emitted
     * @param epochId market epoch ID
     * @param marketId market ID
     * @param tvl TVL
     * @param strikeMet Flag if event isDisaster
     * @param time time
     * @param strikeData Data that triggered depeg
     */
    event EpochResolved(
        uint256 indexed epochId,
        uint256 indexed marketId,
        VaultTVL tvl,
        bool strikeMet,
        uint256 time,
        uint256 strikeData
    );

    /** @notice Indexes protocol fees collected
     * @param epochId market epoch ID
     * @param marketId market ID
     * @param premiumFee premium fee
     * @param collateralFee collateral fee
     * @param time timestamp
     */
    event ProtocolFeeCollected(
        uint256 indexed epochId,
        uint256 indexed marketId,
        uint256 premiumFee,
        uint256 collateralFee,
        uint256 time
    );

    /** @notice Sets epoch to null when event is emitted
     * @param epochId market epoch ID
     * @param marketId market ID
     * @param tvl TVL
     * @param time timestamp
     */
    event NullEpoch(
        uint256 indexed epochId,
        uint256 indexed marketId,
        VaultTVL tvl,
        uint256 time
    );

    struct VaultTVL {
        uint256 COLLAT_claimTVL;
        uint256 COLLAT_finalTVL;
        uint256 PREM_claimTVL;
        uint256 PREM_finalTVL;
    }
}

pragma solidity 0.8.17;

interface IVaultFactoryV2 {
    function createNewMarket(
        uint256 fee,
        address token,
        address depeg,
        uint256 beginEpoch,
        uint256 endEpoch,
        address oracle,
        string memory name
    ) external returns (address);

    function treasury() external view returns (address);

    function getVaults(uint256) external view returns (address[2] memory);

    function getEpochFee(uint256) external view returns (uint16);

    function marketToOracle(uint256 _marketId) external view returns (address);

    function transferOwnership(address newOwner) external;

    function marketIdToVaults(uint256 _marketId) external view returns (address[2] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IVaultV2 {
    // function name() external view  returns (string memory);
    // function symbol() external view  returns (string memory);
    // function asset() external view  returns (address);

    function token() external view returns (address);

    function strike() external view returns (uint256);

    function controller() external view returns (address);

    function counterPartyVault() external view returns (address);

    function getEpochConfig(uint256)
        external
        view
        returns (
            uint40,
            uint40,
            uint40
        );

    function totalAssets(uint256) external view returns (uint256);

    function epochExists(uint256 _id) external view returns (bool);

    function epochResolved(uint256 _id) external view returns (bool);

    function finalTVL(uint256 _id) external view returns (uint256);

    function claimTVL(uint256 _id) external view returns (uint256);

    function setEpoch(
        uint40 _epochBegin,
        uint40 _epochEnd,
        uint256 _epochId
    ) external;

    function resolveEpoch(uint256 _id) external;

    function setClaimTVL(uint256 _id, uint256 _amount) external;

    function changeController(address _controller) external;

    function sendTokens(
        uint256 _id,
        uint256 _amount,
        address _receiver
    ) external;

    function whiteListAddress(address _treasury) external;

    function setCounterPartyVault(address _counterPartyVault) external;

    function setEpochNull(uint256 _id) external;

    function whitelistedAddresses(address _address)
        external
        view
        returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AggregatorInterface.sol";
import "./AggregatorV3Interface.sol";

interface AggregatorV2V3Interface is AggregatorInterface, AggregatorV3Interface {}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Arithmetic library with operations for fixed-point numbers.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/FixedPointMathLib.sol)
/// @author Inspired by USM (https://github.com/usmfum/USM/blob/master/contracts/WadMath.sol)
library FixedPointMathLib {
    /*//////////////////////////////////////////////////////////////
                    SIMPLIFIED FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    uint256 internal constant WAD = 1e18; // The scalar of ETH and most ERC20s.

    function mulWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, y, WAD); // Equivalent to (x * y) / WAD rounded down.
    }

    function mulWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, y, WAD); // Equivalent to (x * y) / WAD rounded up.
    }

    function divWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, WAD, y); // Equivalent to (x * WAD) / y rounded down.
    }

    function divWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, WAD, y); // Equivalent to (x * WAD) / y rounded up.
    }

    /*//////////////////////////////////////////////////////////////
                    LOW LEVEL FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function mulDivDown(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
            if iszero(and(iszero(iszero(denominator)), or(iszero(x), eq(div(z, x), y)))) {
                revert(0, 0)
            }

            // Divide z by the denominator.
            z := div(z, denominator)
        }
    }

    function mulDivUp(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
            if iszero(and(iszero(iszero(denominator)), or(iszero(x), eq(div(z, x), y)))) {
                revert(0, 0)
            }

            // First, divide z - 1 by the denominator and add 1.
            // We allow z - 1 to underflow if z is 0, because we multiply the
            // end result by 0 if z is zero, ensuring we return 0 if z is zero.
            z := mul(iszero(iszero(z)), add(div(sub(z, 1), denominator), 1))
        }
    }

    function rpow(
        uint256 x,
        uint256 n,
        uint256 scalar
    ) internal pure returns (uint256 z) {
        assembly {
            switch x
            case 0 {
                switch n
                case 0 {
                    // 0 ** 0 = 1
                    z := scalar
                }
                default {
                    // 0 ** n = 0
                    z := 0
                }
            }
            default {
                switch mod(n, 2)
                case 0 {
                    // If n is even, store scalar in z for now.
                    z := scalar
                }
                default {
                    // If n is odd, store x in z for now.
                    z := x
                }

                // Shifting right by 1 is like dividing by 2.
                let half := shr(1, scalar)

                for {
                    // Shift n right by 1 before looping to halve it.
                    n := shr(1, n)
                } n {
                    // Shift n right by 1 each iteration to halve it.
                    n := shr(1, n)
                } {
                    // Revert immediately if x ** 2 would overflow.
                    // Equivalent to iszero(eq(div(xx, x), x)) here.
                    if shr(128, x) {
                        revert(0, 0)
                    }

                    // Store x squared.
                    let xx := mul(x, x)

                    // Round to the nearest number.
                    let xxRound := add(xx, half)

                    // Revert if xx + half overflowed.
                    if lt(xxRound, xx) {
                        revert(0, 0)
                    }

                    // Set x to scaled xxRound.
                    x := div(xxRound, scalar)

                    // If n is even:
                    if mod(n, 2) {
                        // Compute z * x.
                        let zx := mul(z, x)

                        // If z * x overflowed:
                        if iszero(eq(div(zx, x), z)) {
                            // Revert if x is non-zero.
                            if iszero(iszero(x)) {
                                revert(0, 0)
                            }
                        }

                        // Round to the nearest number.
                        let zxRound := add(zx, half)

                        // Revert if zx + half overflowed.
                        if lt(zxRound, zx) {
                            revert(0, 0)
                        }

                        // Return properly scaled zxRound.
                        z := div(zxRound, scalar)
                    }
                }
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                        GENERAL NUMBER UTILITIES
    //////////////////////////////////////////////////////////////*/

    function sqrt(uint256 x) internal pure returns (uint256 z) {
        assembly {
            // Start off with z at 1.
            z := 1

            // Used below to help find a nearby power of 2.
            let y := x

            // Find the lowest power of 2 that is at least sqrt(x).
            if iszero(lt(y, 0x100000000000000000000000000000000)) {
                y := shr(128, y) // Like dividing by 2 ** 128.
                z := shl(64, z) // Like multiplying by 2 ** 64.
            }
            if iszero(lt(y, 0x10000000000000000)) {
                y := shr(64, y) // Like dividing by 2 ** 64.
                z := shl(32, z) // Like multiplying by 2 ** 32.
            }
            if iszero(lt(y, 0x100000000)) {
                y := shr(32, y) // Like dividing by 2 ** 32.
                z := shl(16, z) // Like multiplying by 2 ** 16.
            }
            if iszero(lt(y, 0x10000)) {
                y := shr(16, y) // Like dividing by 2 ** 16.
                z := shl(8, z) // Like multiplying by 2 ** 8.
            }
            if iszero(lt(y, 0x100)) {
                y := shr(8, y) // Like dividing by 2 ** 8.
                z := shl(4, z) // Like multiplying by 2 ** 4.
            }
            if iszero(lt(y, 0x10)) {
                y := shr(4, y) // Like dividing by 2 ** 4.
                z := shl(2, z) // Like multiplying by 2 ** 2.
            }
            if iszero(lt(y, 0x8)) {
                // Equivalent to 2 ** z.
                z := shl(1, z)
            }

            // Shifting right by 1 is like dividing by 2.
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))

            // Compute a rounded down version of z.
            let zRoundDown := div(x, z)

            // If zRoundDown is smaller, use it.
            if lt(zRoundDown, z) {
                z := zRoundDown
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorInterface {
  function latestAnswer() external view returns (int256);

  function latestTimestamp() external view returns (uint256);

  function latestRound() external view returns (uint256);

  function getAnswer(uint256 roundId) external view returns (int256);

  function getTimestamp(uint256 roundId) external view returns (uint256);

  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt);

  event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);
}