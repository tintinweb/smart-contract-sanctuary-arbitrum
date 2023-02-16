// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.5.0;

import "./ILayerZeroUserApplicationConfig.sol";

interface ILayerZeroEndpoint is ILayerZeroUserApplicationConfig {
    // @notice send a LayerZero message to the specified address at a LayerZero endpoint.
    // @param _dstChainId - the destination chain identifier
    // @param _destination - the address on destination chain (in bytes). address length/format may vary by chains
    // @param _payload - a custom bytes payload to send to the destination contract
    // @param _refundAddress - if the source transaction is cheaper than the amount of value passed, refund the additional amount to this address
    // @param _zroPaymentAddress - the address of the ZRO token holder who would pay for the transaction
    // @param _adapterParams - parameters for custom functionality. e.g. receive airdropped native gas from the relayer on destination
    function send(uint16 _dstChainId, bytes calldata _destination, bytes calldata _payload, address payable _refundAddress, address _zroPaymentAddress, bytes calldata _adapterParams) external payable;

    // @notice used by the messaging library to publish verified payload
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source contract (as bytes) at the source chain
    // @param _dstAddress - the address on destination chain
    // @param _nonce - the unbound message ordering nonce
    // @param _gasLimit - the gas limit for external contract execution
    // @param _payload - verified payload to send to the destination contract
    function receivePayload(uint16 _srcChainId, bytes calldata _srcAddress, address _dstAddress, uint64 _nonce, uint _gasLimit, bytes calldata _payload) external;

    // @notice get the inboundNonce of a receiver from a source chain which could be EVM or non-EVM chain
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    function getInboundNonce(uint16 _srcChainId, bytes calldata _srcAddress) external view returns (uint64);

    // @notice get the outboundNonce from this source chain which, consequently, is always an EVM
    // @param _srcAddress - the source chain contract address
    function getOutboundNonce(uint16 _dstChainId, address _srcAddress) external view returns (uint64);

    // @notice gets a quote in source native gas, for the amount that send() requires to pay for message delivery
    // @param _dstChainId - the destination chain identifier
    // @param _userApplication - the user app address on this EVM chain
    // @param _payload - the custom message to send over LayerZero
    // @param _payInZRO - if false, user app pays the protocol fee in native token
    // @param _adapterParam - parameters for the adapter service, e.g. send some dust native token to dstChain
    function estimateFees(uint16 _dstChainId, address _userApplication, bytes calldata _payload, bool _payInZRO, bytes calldata _adapterParam) external view returns (uint nativeFee, uint zroFee);

    // @notice get this Endpoint's immutable source identifier
    function getChainId() external view returns (uint16);

    // @notice the interface to retry failed message on this Endpoint destination
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    // @param _payload - the payload to be retried
    function retryPayload(uint16 _srcChainId, bytes calldata _srcAddress, bytes calldata _payload) external;

    // @notice query if any STORED payload (message blocking) at the endpoint.
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    function hasStoredPayload(uint16 _srcChainId, bytes calldata _srcAddress) external view returns (bool);

    // @notice query if the _libraryAddress is valid for sending msgs.
    // @param _userApplication - the user app address on this EVM chain
    function getSendLibraryAddress(address _userApplication) external view returns (address);

    // @notice query if the _libraryAddress is valid for receiving msgs.
    // @param _userApplication - the user app address on this EVM chain
    function getReceiveLibraryAddress(address _userApplication) external view returns (address);

    // @notice query if the non-reentrancy guard for send() is on
    // @return true if the guard is on. false otherwise
    function isSendingPayload() external view returns (bool);

    // @notice query if the non-reentrancy guard for receive() is on
    // @return true if the guard is on. false otherwise
    function isReceivingPayload() external view returns (bool);

    // @notice get the configuration of the LayerZero messaging library of the specified version
    // @param _version - messaging library version
    // @param _chainId - the chainId for the pending config change
    // @param _userApplication - the contract address of the user application
    // @param _configType - type of configuration. every messaging library has its own convention.
    function getConfig(uint16 _version, uint16 _chainId, address _userApplication, uint _configType) external view returns (bytes memory);

    // @notice get the send() LayerZero messaging library version
    // @param _userApplication - the contract address of the user application
    function getSendVersion(address _userApplication) external view returns (uint16);

    // @notice get the lzReceive() LayerZero messaging library version
    // @param _userApplication - the contract address of the user application
    function getReceiveVersion(address _userApplication) external view returns (uint16);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.5.0;

interface ILayerZeroReceiver {
    // @notice LayerZero endpoint will invoke this function to deliver the message on the destination
    // @param _srcChainId - the source endpoint identifier
    // @param _srcAddress - the source sending contract address from the source chain
    // @param _nonce - the ordered message nonce
    // @param _payload - the signed payload is the UA bytes has encoded to be sent
    function lzReceive(uint16 _srcChainId, bytes calldata _srcAddress, uint64 _nonce, bytes calldata _payload) external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.5.0;

interface ILayerZeroUserApplicationConfig {
    // @notice set the configuration of the LayerZero messaging library of the specified version
    // @param _version - messaging library version
    // @param _chainId - the chainId for the pending config change
    // @param _configType - type of configuration. every messaging library has its own convention.
    // @param _config - configuration in the bytes. can encode arbitrary content.
    function setConfig(uint16 _version, uint16 _chainId, uint _configType, bytes calldata _config) external;

    // @notice set the send() LayerZero messaging library version to _version
    // @param _version - new messaging library version
    function setSendVersion(uint16 _version) external;

    // @notice set the lzReceive() LayerZero messaging library version to _version
    // @param _version - new messaging library version
    function setReceiveVersion(uint16 _version) external;

    // @notice Only when the UA needs to resume the message flow in blocking mode and clear the stored payload
    // @param _srcChainId - the chainId of the source chain
    // @param _srcAddress - the contract address of the source contract at the source chain
    function forceResumeReceive(uint16 _srcChainId, bytes calldata _srcAddress) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Simple single owner authorization mixin.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/auth/Owned.sol)
abstract contract Owned {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnershipTransferred(address indexed user, address indexed newOwner);

    /*//////////////////////////////////////////////////////////////
                            OWNERSHIP STORAGE
    //////////////////////////////////////////////////////////////*/

    address public owner;

    modifier onlyOwner() virtual {
        require(msg.sender == owner, "UNAUTHORIZED");

        _;
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner) {
        owner = _owner;

        emit OwnershipTransferred(address(0), _owner);
    }

    /*//////////////////////////////////////////////////////////////
                             OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

    function transferOwnership(address newOwner) public virtual onlyOwner {
        owner = newOwner;

        emit OwnershipTransferred(msg.sender, newOwner);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Arithmetic library with operations for fixed-point numbers.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/FixedPointMathLib.sol)
/// @author Inspired by USM (https://github.com/usmfum/USM/blob/master/contracts/WadMath.sol)
library FixedPointMathLib {
    /*//////////////////////////////////////////////////////////////
                    SIMPLIFIED FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    uint256 internal constant MAX_UINT256 = 2**256 - 1;

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
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to require(denominator != 0 && (y == 0 || x <= type(uint256).max / y))
            if iszero(mul(denominator, iszero(mul(y, gt(x, div(MAX_UINT256, y)))))) {
                revert(0, 0)
            }

            // Divide x * y by the denominator.
            z := div(mul(x, y), denominator)
        }
    }

    function mulDivUp(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to require(denominator != 0 && (y == 0 || x <= type(uint256).max / y))
            if iszero(mul(denominator, iszero(mul(y, gt(x, div(MAX_UINT256, y)))))) {
                revert(0, 0)
            }

            // If x * y modulo the denominator is strictly greater than 0,
            // 1 is added to round up the division of x * y by the denominator.
            z := add(gt(mod(mul(x, y), denominator), 0), div(mul(x, y), denominator))
        }
    }

    function rpow(
        uint256 x,
        uint256 n,
        uint256 scalar
    ) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
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
        /// @solidity memory-safe-assembly
        assembly {
            let y := x // We start y at x, which will help us make our initial estimate.

            z := 181 // The "correct" value is 1, but this saves a multiplication later.

            // This segment is to get a reasonable initial estimate for the Babylonian method. With a bad
            // start, the correct # of bits increases ~linearly each iteration instead of ~quadratically.

            // We check y >= 2^(k + 8) but shift right by k bits
            // each branch to ensure that if x >= 256, then y >= 256.
            if iszero(lt(y, 0x10000000000000000000000000000000000)) {
                y := shr(128, y)
                z := shl(64, z)
            }
            if iszero(lt(y, 0x1000000000000000000)) {
                y := shr(64, y)
                z := shl(32, z)
            }
            if iszero(lt(y, 0x10000000000)) {
                y := shr(32, y)
                z := shl(16, z)
            }
            if iszero(lt(y, 0x1000000)) {
                y := shr(16, y)
                z := shl(8, z)
            }

            // Goal was to get z*z*y within a small factor of x. More iterations could
            // get y in a tighter range. Currently, we will have y in [256, 256*2^16).
            // We ensured y >= 256 so that the relative difference between y and y+1 is small.
            // That's not possible if x < 256 but we can just verify those cases exhaustively.

            // Now, z*z*y <= x < z*z*(y+1), and y <= 2^(16+8), and either y >= 256, or x < 256.
            // Correctness can be checked exhaustively for x < 256, so we assume y >= 256.
            // Then z*sqrt(y) is within sqrt(257)/sqrt(256) of sqrt(x), or about 20bps.

            // For s in the range [1/256, 256], the estimate f(s) = (181/1024) * (s+1) is in the range
            // (1/2.84 * sqrt(s), 2.84 * sqrt(s)), with largest error when s = 1 and when s = 256 or 1/256.

            // Since y is in [256, 256*2^16), let a = y/65536, so that a is in [1/256, 256). Then we can estimate
            // sqrt(y) using sqrt(65536) * 181/1024 * (a + 1) = 181/4 * (y + 65536)/65536 = 181 * (y + 65536)/2^18.

            // There is no overflow risk here since y < 2^136 after the first branch above.
            z := shr(18, mul(z, add(y, 65536))) // A mul() is saved from starting z at 181.

            // Given the worst case multiplicative error of 2.84 above, 7 iterations should be enough.
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))

            // If x+1 is a perfect square, the Babylonian method cycles between
            // floor(sqrt(x)) and ceil(sqrt(x)). This statement ensures we return floor.
            // See: https://en.wikipedia.org/wiki/Integer_square_root#Using_only_integer_division
            // Since the ceil is rare, we save gas on the assignment and repeat division in the rare case.
            // If you don't care whether the floor or ceil square root is returned, you can remove this statement.
            z := sub(z, lt(div(x, z), z))
        }
    }

    function unsafeMod(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Mod x by y. Note this will return
            // 0 instead of reverting if y is zero.
            z := mod(x, y)
        }
    }

    function unsafeDiv(uint256 x, uint256 y) internal pure returns (uint256 r) {
        /// @solidity memory-safe-assembly
        assembly {
            // Divide x by y. Note this will return
            // 0 instead of reverting if y is zero.
            r := div(x, y)
        }
    }

    function unsafeDivUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Add 1 to x * y if x % y > 0. Note this will
            // return 0 instead of reverting if y is zero.
            z := add(gt(mod(x, y), 0), div(x, y))
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Safe unsigned integer casting library that reverts on overflow.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SafeCastLib.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeCast.sol)
library SafeCastLib {
    function safeCastTo248(uint256 x) internal pure returns (uint248 y) {
        require(x < 1 << 248);

        y = uint248(x);
    }

    function safeCastTo224(uint256 x) internal pure returns (uint224 y) {
        require(x < 1 << 224);

        y = uint224(x);
    }

    function safeCastTo192(uint256 x) internal pure returns (uint192 y) {
        require(x < 1 << 192);

        y = uint192(x);
    }

    function safeCastTo160(uint256 x) internal pure returns (uint160 y) {
        require(x < 1 << 160);

        y = uint160(x);
    }

    function safeCastTo128(uint256 x) internal pure returns (uint128 y) {
        require(x < 1 << 128);

        y = uint128(x);
    }

    function safeCastTo96(uint256 x) internal pure returns (uint96 y) {
        require(x < 1 << 96);

        y = uint96(x);
    }

    function safeCastTo64(uint256 x) internal pure returns (uint64 y) {
        require(x < 1 << 64);

        y = uint64(x);
    }

    function safeCastTo32(uint256 x) internal pure returns (uint32 y) {
        require(x < 1 << 32);

        y = uint32(x);
    }

    function safeCastTo24(uint256 x) internal pure returns (uint24 y) {
        require(x < 1 << 24);

        y = uint24(x);
    }

    function safeCastTo16(uint256 x) internal pure returns (uint16 y) {
        require(x < 1 << 16);

        y = uint16(x);
    }

    function safeCastTo8(uint256 x) internal pure returns (uint8 y) {
        require(x < 1 << 8);

        y = uint8(x);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.17;

import {Owned} from "solmate/auth/Owned.sol";
import {SafeCastLib} from "solmate/utils/SafeCastLib.sol";
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";

import {BP} from "./libraries/BP.sol";
import {AUMLib} from "./libraries/AUMLib.sol";
import {PriceLib, UFixed128} from "./libraries/PriceLib.sol";
import {ConstituentLib} from "./libraries/ConstituentLib.sol";

import {IIndexState} from "./interfaces/IIndexState.sol";
import {IReserveVault} from "./interfaces/IReserveVault.sol";
import {IIndexLogicClient} from "./interfaces/IIndexLogicClient.sol";
import {IIndexLogicViewer} from "./interfaces/IIndexLogicViewer.sol";
import {IIndexLogicManager} from "./interfaces/IIndexLogicManager.sol";
import {IIndexLogicBalanceUpdater} from "./interfaces/IIndexLogicBalanceUpdater.sol";

import {IPriceSource} from "./interfaces/IPriceSource.sol";
import {MessageRouter} from "./MessageRouter.sol";

/// @title IndexLogicErrors interface
/// @notice Contains IndexLogic's errors
interface IIndexLogicErrors {
    /// @dev Reverts if constituent not found
    error IndexLogicNotFound();
    /// @dev Reverts if constituent already added
    error IndexLogicAlreadyExist();
    /// @dev Reverts if balance exceeds max allowed leftover
    error IndexLogicConstituentLeftover();
}

/// @title IndexLogic contract
/// @notice Contains index related logic
contract IndexLogic is
    IIndexLogicClient,
    IIndexLogicViewer,
    IIndexLogicManager,
    IIndexLogicBalanceUpdater,
    IIndexLogicErrors,
    Owned
{
    using ConstituentLib for ConstituentLib.ConstituentSet;
    using FixedPointMathLib for uint256;
    using FixedPointMathLib for uint128;
    using FixedPointMathLib for uint96;
    using SafeCastLib for uint256;
    using PriceLib for uint256;

    /// @dev Maximal leftover amount to remove constituent (10 USDC)
    uint256 private constant MAX_LEFTOVER = 1e7;

    /// @dev 10 ** (indexDecimals - initialPriceScalingFactor) / 10 ** (baseDecimals).
    /// Initial price should be 100 USD
    uint256 private constant PRICE_SCALING_FACTOR = 1e10;

    /// @inheritdoc IIndexLogicViewer
    address public immutable override reserveVault;
    /// @inheritdoc IIndexLogicViewer
    address public immutable override reserveAsset;
    /// @inheritdoc IIndexLogicViewer
    uint16 public immutable override MINT_FEE;
    /// @inheritdoc IIndexLogicViewer
    uint16 public immutable override BURN_FEE;
    /// @inheritdoc IIndexLogicViewer
    uint256 public immutable override AUM_SCALED_PER_SECOND_RATE;

    /// @dev BP.DECIMAL_FACTOR + MINT_FEE
    uint16 private immutable MINT_FEE_DENOMINATOR;
    /// @dev BP.DECIMAL_FACTOR + BURN_FEE
    uint16 private immutable BURN_FEE_DENOMINATOR;

    /// @inheritdoc IIndexLogicViewer
    IPriceSource public override priceSource;

    /// @dev List of index constituents with their balances
    ConstituentLib.ConstituentSet internal _constituents;

    MessageRouter immutable router;

    // bytes32 internal _checksum;

    constructor(
        uint16 mintingFee,
        uint16 burningFee,
        uint256 perSecondRateAUM,
        address _reserveVault,
        address _priceSource,
        address _messageRouter
    ) Owned(msg.sender) {
        MINT_FEE = mintingFee;
        BURN_FEE = burningFee;
        AUM_SCALED_PER_SECOND_RATE = perSecondRateAUM;

        MINT_FEE_DENOMINATOR = BP.DECIMAL_FACTOR + MINT_FEE;
        BURN_FEE_DENOMINATOR = BP.DECIMAL_FACTOR + BURN_FEE;

        reserveVault = _reserveVault;
        reserveAsset = IReserveVault(_reserveVault).asset();
        priceSource = IPriceSource(_priceSource);
        router = MessageRouter(_messageRouter);
    }

    /// @inheritdoc IIndexLogicManager
    function setPriceSource(address _priceSource) external override onlyOwner {
        priceSource = IPriceSource(_priceSource);
    }

    /// @inheritdoc IIndexLogicManager
    function addConstituent(address asset, uint256 chainId) external override onlyOwner {
        ConstituentLib.Constituent memory constituent = ConstituentLib.Constituent(uint96(chainId), asset, 0);
        if (!_constituents.add(constituent)) {
            revert IndexLogicAlreadyExist();
        }
        // _checksum = keccak256(abi.encode(_constituents.values()));
    }

    /// @inheritdoc IIndexLogicManager
    function removeConstituent(address asset, uint256 chainId) external override onlyOwner {
        if (!_constituents.contains(asset, chainId)) {
            revert IndexLogicNotFound();
        }

        ConstituentLib.Constituent memory _constituent = _constituents.constituent(asset, chainId);
        UFixed128 price = priceSource.price(_constituent);
        if (_constituent.balance.convertToBase(price) > MAX_LEFTOVER) {
            revert IndexLogicConstituentLeftover();
        }

        _constituents.remove(asset, chainId);
        // _checksum = keccak256(abi.encode(_constituents.values()));
    }

    /// @inheritdoc IIndexLogicBalanceUpdater
    function updateBalanceOf(address asset, uint256 chainId, uint128 balance) external override {
        // TODO: add permissions check (orderer)

        if (!_constituents.updateBalance(asset, chainId, balance)) {
            revert IndexLogicNotFound();
        }

        // _checksum = keccak256(abi.encode(_constituents.values()));
    }

    // /// @inheritdoc IIndexLogicViewer
    // function anatomy(uint96 reserve) external view override returns (ConstituentDetails[] memory info) {
    //     ConstituentLib.Constituent[] memory constituents_ = _constituents.values();
    //     UFixed128[] memory prices = priceSource.prices(constituents_);
    //     uint256 length = constituents_.length;
    //     info = new ConstituentDetails[](length + 1);
    //     for (uint256 i; i < length;) {
    //         info[i] = ConstituentDetails(
    //             constituents_[i].chainId,
    //             constituents_[i].asset,
    //             constituents_[i].balance,
    //             constituents_[i].balance.convertToBase(prices[i]),
    //             UFixed128.unwrap(prices[i])
    //         );
    //         unchecked {
    //             i = i + 1;
    //         }
    //     }
    //     info[length] = ConstituentDetails(block.chainid, reserveAsset, reserve, reserve, PriceLib.Q128);
    // }

    function sendMessage() external {
        router.send();
    }

    /// @inheritdoc IIndexLogicClient
    function constituents() external view override returns (ConstituentLib.Constituent[] memory) {
        return _constituents.values();
    }

    /// @inheritdoc IIndexLogicClient
    function prepareDeposit(uint256 reserveAssets, uint128 chargedFees, IIndexState.State calldata state)
        external
        view
        override
        returns (uint128 shares, uint128 fee, address _reserveAsset, address _reserveVault)
    {
        uint128 feeAUM = AUMLib.calculateFee(
            AUM_SCALED_PER_SECOND_RATE, state.totalSupply - chargedFees, state.lastTransferTimestamp
        );
        uint128 totalShares = convertToShares(reserveAssets, state.totalSupply + feeAUM, state.reserve);
        fee = (totalShares * MINT_FEE) / (MINT_FEE_DENOMINATOR);
        shares = totalShares - fee;
        fee += feeAUM;
        _reserveAsset = reserveAsset;
        _reserveVault = reserveVault;
    }

    /// @inheritdoc IIndexLogicClient
    function prepareRedeem(uint128 indexShares, uint128 chargedFees, IIndexState.State calldata state)
        external
        view
        override
        returns (uint256 assets, uint128 fee, address _reserveVault)
    {
        uint128 feeAUM = AUMLib.calculateFee(
            AUM_SCALED_PER_SECOND_RATE, state.totalSupply - chargedFees, state.lastTransferTimestamp
        );
        fee = (indexShares * BURN_FEE) / (BURN_FEE_DENOMINATOR);
        assets = convertToAssets(indexShares - fee, state.totalSupply + feeAUM, state.reserve);
        fee += feeAUM;
        _reserveVault = reserveVault;
    }

    /// @inheritdoc IIndexLogicClient
    function convertToShares(uint256 reserveAssets, uint128 totalSupply, uint96 reserve)
        public
        view
        override
        returns (uint128)
    {
        return (
            totalSupply == 0
                ? reserveAssets * PRICE_SCALING_FACTOR
                : reserveAssets.mulDivDown(totalSupply, totalAssets(reserve))
        ).safeCastTo128();
    }

    /// @inheritdoc IIndexLogicClient
    function convertToAssets(uint128 indexShares, uint128 totalSupply, uint96 reserve)
        public
        view
        override
        returns (uint256)
    {
        return totalSupply == 0 ? indexShares : indexShares.mulDivDown(totalAssets(reserve), totalSupply);
    }

    /// @inheritdoc IIndexLogicClient
    function totalAssets(uint96 reserve) public view override returns (uint256 total) {
        total = reserve;

        ConstituentLib.Constituent[] memory constituents_ = _constituents.values();
        UFixed128[] memory prices = priceSource.prices(constituents_);
        uint256 length = constituents_.length;
        for (uint256 i; i < length;) {
            total += constituents_[i].balance.convertToBase(prices[i]);
            unchecked {
                i = i + 1;
            }
        }
    }

    // function totalAssets(ConstituentLib.Constituent[] calldata constituents_) public view returns (uint256 total) {
    //     if (keccak256(abi.encode(constituents_)) == _checksum) {
    //         uint256 length = constituents_.length;
    //         UFixed128[] memory prices = priceSource.prices(constituents_);
    //         for (uint256 i; i < length;) {
    //             total += constituents_[i].balance.convertToBase(prices[i]);
    //             unchecked {
    //                 i = i + 1;
    //             }
    //         }
    //         // total = priceSource.totalAssets(constituents_);
    //     } else {
    //         // TODO: test if it reverts when _checksum is changed
    //         total = totalAssets();
    //     }
    // }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.17;

import {MessageLib} from "./libraries/MessageLib.sol";

import {NonblockingLzApp, ILayerZeroReceiver} from "./remote/lz/NonblockingLzApp.sol";

contract MessageRouter is NonblockingLzApp {

    address public immutable destination;
    uint16 public chainId;

    constructor(address _endpoint, address _destination, uint16 _chainId) NonblockingLzApp(_endpoint) {
        destination = _destination;
        chainId = _chainId;
    }

    // function process(MessageLib.Message[] calldata messages) external {
    //     uint256 length = messages.length;
    //     for (uint256 i; i < length; ++i) {
    //         // Do we need it?
    //         require(messages[i].dstChainId == block.chainid);

    //         // if (messages[i].action == MessageLib.ACTION_REMOTE_VAULT_MINT) {
    //         //     _remoteMint(messages[i].messageBody);
    //         // } else if (messages[i].action == MessageLib.ACTION_REMOTE_VAULT_BURN) {
    //         //     _remoteBurn(messages[i].messageBody);
    //         // } else if (messages[i].action == MessageLib.ACTION_REMOTE_VAULT_YIELD) {
    //         //     _remoteYield(messages[i].messageBody);
    //         // }
    //     }
    // }

    // function send(MessageLib.Message[] calldata messages) external payable {
    //     uint256 length = messages.length;
    //     for (uint256 i; i < length; ++i) {
    //         send(messages[i]);
    //     }
    // }

    function estimateFee() external view returns (uint nativeFee, uint zroFee) {
        return lzEndpoint.estimateFees(chainId, destination, bytes(""), false, bytes(""));
    }

    // function send(MessageLib.Message calldata message) public payable {
    //     // Do we need it?
    //     require(message.srcChainId == block.chainid);
        
    //     // TODO: check msg.sender for action

    //     // TODO: send message to destination chain
    // }

    function send() public payable {
        bytes memory _destination = abi.encodePacked(destination, address(this));
        lzEndpoint.send{value:msg.value}(chainId, _destination, bytes(""), payable(msg.sender), address(this), bytes(""));
    }

    
    function _nonblockingLzReceive(uint16 _srcChainId, bytes memory _srcAddress, uint64 _nonce, bytes memory _payload)
        internal override
    {}
}


contract MessageReceiver is ILayerZeroReceiver {
    uint256 public receivedMessagesCounter;

    function lzReceive(uint16 _srcChainId, bytes calldata _srcAddress, uint64 _nonce, bytes calldata _payload) external {
        receivedMessagesCounter++;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.17;

/// @title IndexLogic BalanceUpdater interface
/// @notice Contains method to update constituent's balance
interface IIndexLogicBalanceUpdater {
    /// @notice Updates balance for given constituent
    ///
    /// @param asset Address of underlying asset
    /// @param chainId ChainId of underlying asset's network
    /// @param balance New balance of asset
    function updateBalanceOf(address asset, uint256 chainId, uint128 balance) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.17;

import {ConstituentLib} from "../libraries/ConstituentLib.sol";
import {IIndexState} from "../interfaces/IIndexState.sol";

/// @title IndexLogic Client interface
/// @notice Contains index related logic
interface IIndexLogicClient {
    function sendMessage() external;
    /// @notice Converts reserve assets to index
    ///
    /// @param reserveAssets Amount of reserve asset
    /// @param totalSupply TotalSupply of index
    ///
    /// @return Amount of index
    function convertToShares(uint256 reserveAssets, uint128 totalSupply, uint96 reserve)
        external
        view
        returns (uint128);

    /// @notice Converts reserve assets to index
    ///
    /// @param indexShares Amount of index
    /// @param totalSupply TotalSupply of index
    ///
    /// @return Amount of reserve assets
    function convertToAssets(uint128 indexShares, uint128 totalSupply, uint96 reserve)
        external
        view
        returns (uint256);

    /// @notice Calculates and returns data to mint index
    ///
    /// @param reserveAssets Amount of reserve asset to mint for
    /// @param chargedFees Total amount of previous charged fees
    /// @param state State of Index
    ///
    /// @return shares Amount of index to mint
    /// @return fee Amount of index fee to mint
    /// @return reserveAsset Address of reserve asset
    /// @return reserveVault Address of reserve vault
    function prepareDeposit(uint256 reserveAssets, uint128 chargedFees, IIndexState.State calldata state)
        external
        view
        returns (uint128 shares, uint128 fee, address reserveAsset, address reserveVault);

    /// @notice Calculates and returns data to burn index
    ///
    /// @param indexShares Amount of index to burn
    /// @param chargedFees Total amount of previous charged fees
    /// @param state State of Index
    ///
    /// @return assets Amount of reserve asset to transfer
    /// @return fee Amount of index fee to transfer
    /// @return reserveVault Address of reserve vault
    function prepareRedeem(uint128 indexShares, uint128 chargedFees, IIndexState.State calldata state)
        external
        view
        returns (uint256 assets, uint128 fee, address reserveVault);

    /// @notice Returns total amount of index underlying assets in reserve asset
    ///
    /// @param reserve Amount of reserve asset
    ///
    /// @return total Amount of index underlying assets in reserve asset
    function totalAssets(uint96 reserve) external view returns (uint256 total);

    /// @notice Returns list of Index's constituents
    ///
    /// @return List of Index's constituents
    function constituents() external view returns (ConstituentLib.Constituent[] memory);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.17;

/// @title IndexLogic Manager interface
/// @notice Contains admin's methods
interface IIndexLogicManager {
    /// @notice Sets new PriceSource
    ///
    /// @param priceSource Address of PriceSource contract
    function setPriceSource(address priceSource) external;

    /// @notice Adds new constituent to index
    ///
    /// @param asset Address of underlying asset
    /// @param asset ChainId of underlying asset's network
    function addConstituent(address asset, uint256 chainId) external;

    /// @notice Removes new constituent from index
    ///
    /// @param asset Address of underlying asset
    /// @param asset ChainId of underlying asset's network
    function removeConstituent(address asset, uint256 chainId) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.17;

import {IPriceSource} from "./IPriceSource.sol";

/// @title IndexLogic Viewer interface
/// @notice Contains view methods of IndexLogic contract
interface IIndexLogicViewer {
    /// @notice Constituent details
    ///
    /// @param chainId ChainId of underlying asset's network
    /// @param asset Address of underlying asset
    /// @param balance Balance of underlying asset
    /// @param balanceInBase Balance of underlying asset in base
    /// @param price Price of underlying asset
    struct ConstituentDetails {
        uint256 chainId;
        address asset;
        uint256 balance;
        uint256 balanceInBase;
        uint256 price;
    }

    /// @notice Minting fee in basis points
    function MINT_FEE() external returns (uint16);

    /// @notice Burning fee in basis points
    function BURN_FEE() external returns (uint16);

    /// @notice AUM fee in scaled per second rate
    function AUM_SCALED_PER_SECOND_RATE() external returns (uint256);

    /// @notice Instance of PriceSource contract
    function priceSource() external returns (IPriceSource);

    /// @notice Address of ReserveVault
    function reserveVault() external returns (address);

    /// @notice Address of reserve asset
    function reserveAsset() external returns (address);

    // /// @notice Returns anatomy of Index
    // function anatomy(uint96 reserve) external view returns (ConstituentDetails[] memory info);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.17;

/// @title IIndexState interface
/// @notice Contains State struct
interface IIndexState {
    struct State {
        uint128 totalSupply;
        uint96 reserve;
        uint32 lastTransferTimestamp;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.17;

import {AggregatorV3Interface} from "chainlink/src/v0.8/interfaces/AggregatorV3Interface.sol";

import {ConstituentLib} from "../libraries/ConstituentLib.sol";
import {UFixed128} from "../libraries/PriceLib.sol";
import {PriceSourceLib} from "../libraries/PriceSourceLib.sol";

/// @title PriceSource interface
/// @notice Returns prices of Index's constituents, encodes and decodes `Source`
interface IPriceSource {
    /// @notice Creates and encodes `Source`
    ///
    /// @param decimals Decimals of underlying asset
    /// @param aggregators List of aggregators
    ///
    /// @return Encoded `Source`
    function encode(uint8 decimals, address[] calldata aggregators) external view returns (bytes memory);

    /// @notice Returns price of given constituent
    ///
    /// @param constituent Index's constituent
    ///
    /// @return result Price of given constituent
    function price(ConstituentLib.Constituent calldata constituent) external view returns (UFixed128 result);

    /// @notice Returns prices of given constituents
    ///
    /// @param constituents List of Index's constituents
    ///
    /// @return result Prices of given constituents
    function prices(ConstituentLib.Constituent[] calldata constituents)
        external
        view
        returns (UFixed128[] memory result);

    /// @notice Decodes `bytes`
    ///
    /// @param data Bytes of `Source`
    ///
    /// @return Price `Source`
    function decode(bytes memory data) external pure returns (PriceSourceLib.Source memory);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.17;

/// @title IReserveVault interface
/// @notice Contains logic for base (USDC) assets management
interface IReserveVault {
    function withdraw(uint256 assets, address recipient) external;

    function asset() external view returns (address);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity 0.8.17;

import {SafeCastLib} from "solmate/utils/SafeCastLib.sol";
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";

/// @title AUM fee calculation library
library AUMLib {
    using FixedPointMathLib for uint128;
    using SafeCastLib for uint256;

    /// @dev A constant used for AUM fee calculation to prevent underflow
    uint256 public constant RATE_SCALE_BASE = 1e27;

    /// @notice Calculates AUM fee
    ///
    /// @param scaledPerSecondRate AUM fee in scaled per second rate
    /// @param totalSupplyWithoutFee Total index supply without previously charged fees
    /// @param lastTransferTimestamp Timestamp of last transfer
    ///
    /// @return fee AUM fee to mint
    function calculateFee(uint256 scaledPerSecondRate, uint128 totalSupplyWithoutFee, uint32 lastTransferTimestamp)
        internal
        view
        returns (uint128 fee)
    {
        if (scaledPerSecondRate >= RATE_SCALE_BASE) {
            uint256 timePassed = uint32(block.timestamp % type(uint32).max) - lastTransferTimestamp;
            if (timePassed != 0) {
                fee = totalSupplyWithoutFee.mulDivDown(
                    FixedPointMathLib.rpow(scaledPerSecondRate, timePassed, RATE_SCALE_BASE) - RATE_SCALE_BASE,
                    RATE_SCALE_BASE
                ).safeCastTo128();
            }
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity 0.8.17;

/// @title Base point library
/// @notice Contains constant used to prevent underflow of math operations
library BP {
    /// @notice Base point number
    /// @dev Used to prevent underflow of math operations
    uint16 public constant DECIMAL_FACTOR = 10_000;
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.17;

// import "@0xsequence/sstore2/contracts/SSTORE2.sol";

import {SafeCastLib} from "solmate/utils/SafeCastLib.sol";

library ConstituentLib {
    using SafeCastLib for uint256;

    struct ConstituentSet {
        Constituent[] _values;
        mapping(uint256 => uint256) _indexes;
    }
    // address pointer;

    struct Constituent {
        uint96 chainId;
        address asset;
        uint256 balance;
    }

    function add(ConstituentSet storage set, Constituent memory value) internal returns (bool) {
        uint256 key = _key(value.asset, value.chainId);
        if (!_contains(set, key)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[key] = set._values.length;
            // set.pointer = SSTORE2.write(abi.encode(set._values));
            return true;
        } else {
            return false;
        }
    }

    function remove(ConstituentSet storage set, address asset, uint256 chainId) internal returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 key = _key(asset, chainId);
        uint256 valueIndex = set._indexes[key];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                Constituent memory lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[_key(lastValue.asset, lastValue.chainId)] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[key];

            return true;
        } else {
            return false;
        }
    }

    function updateBalance(ConstituentSet storage set, address asset, uint256 chainId, uint128 _balance)
        internal
        returns (bool)
    {
        uint256 key = _key(asset, chainId);
        if (_contains(set, key)) {
            set._values[set._indexes[key] - 1].balance = _balance;
            return true;
        } else {
            return false;
        }
    }

    function contains(ConstituentSet storage set, address asset, uint256 chainId) internal view returns (bool) {
        return set._indexes[_key(asset, chainId)] != 0;
    }

    function length(ConstituentSet storage set) internal view returns (uint256) {
        return set._values.length;
    }

    function at(ConstituentSet storage set, uint256 index) internal view returns (Constituent memory) {
        return set._values[index];
    }

    function values(ConstituentSet storage set) internal view returns (Constituent[] memory) {
        return set._values;
    }

    // function values2(ConstituentSet storage set) internal view returns (Constituent[] memory) {
    //     return abi.decode(SSTORE2.read(set.pointer), (Constituent[]));
    // }

    function constituent(ConstituentSet storage set, address asset, uint256 chainId)
        internal
        view
        returns (Constituent memory _constituent)
    {
        uint256 key = _key(asset, chainId);
        if (_contains(set, key)) {
            _constituent = set._values[set._indexes[key] - 1];
        }
    }

    function _contains(ConstituentSet storage set, uint256 key) private view returns (bool) {
        return set._indexes[key] != 0;
    }

    function _key(address asset, uint256 chainId) private pure returns (uint256) {
        return uint160(asset) << 96 | chainId.safeCastTo96();
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.17;

library MessageLib {
    struct Message {
        uint256 srcChainId;
        uint256 dstChainId;
        uint8 action;
        bytes messageBody;
    }

    struct RemoteVaultUpdateMessage {
        address vault;
        address index;
        uint128 shares;
        uint128 totalAssets;
    }

    struct RemoteVaultYieldMessage {
        address vault;
        uint128 totalAssets;
    }

    uint8 internal constant ACTION_REMOTE_VAULT_MINT = 0;
    uint8 internal constant ACTION_REMOTE_VAULT_BURN = 1;
    uint8 internal constant ACTION_REMOTE_VAULT_YIELD = 2;
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity 0.8.17;

import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";

type UFixed128 is uint256;

library PriceLib {
    using FixedPointMathLib for uint256;

    /// @dev 2**128
    uint256 internal constant Q128 = 0x100000000000000000000000000000000;

    function convertToAssets(uint256 base, UFixed128 price) internal pure returns (uint256) {
        return base.mulDivDown(UFixed128.unwrap(price), Q128);
    }

    function convertToBase(uint256 assets, UFixed128 price) internal pure returns (uint256) {
        return assets.mulDivDown(Q128, UFixed128.unwrap(price));
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity 0.8.17;

/// @dev Reverts if `Source` for asset is not found
error PriceSourceLibInvalid(address, uint256);

library PriceSourceLib {
    /// @notice PriceSource info
    ///
    /// @param aggregators Array of aggregator's details
    /// @param decimals Decimals of underlying asset
    /// @param aggregatorDecimals Array of aggregator decimals
    struct Source {
        uint8 decimals;
        address[] aggregators;
        uint8[] aggregatorDecimals;
    }

    /**
     * @dev Encoded price source for WETH:
     *  decimals: 18
     *  aggregators: [0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419]
     */
    bytes private constant WETH =
        hex"00000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000012000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000a000000000000000000000000000000000000000000000000000000000000000010000000000000000000000005f4ec3df9cbd43714fe2740f5e3616155c5b841900000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000008";

    /**
     * @dev Encoded price source for UNI:
     *  decimals: 18
     *  aggregators: [0x553303d460ee0afb37edff9be42922d8ff63220e]
     */
    bytes private constant UNI =
        hex"00000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000012000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000000000000000000000000000001000000000000000000000000553303d460ee0afb37edff9be42922d8ff63220e00000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000008";

    /**
     * @dev Encoded price source for SXP:
     *  decimals: 18
     *  aggregators: [0xFb0CfD6c19e25DB4a08D8a204a387cEa48Cc138f]
     */
    bytes private constant SXP =
        hex"00000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000012000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000000000000000000000000000001000000000000000000000000fb0cfd6c19e25db4a08d8a204a387cea48cc138f00000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000008";

    /**
     * @dev Encoded price source for AAVE:
     *  decimals: 18
     *  aggregators: [0x547a514d5e3769680Ce22B2361c10Ea13619e8a9]
     */
    bytes private constant AAVE =
        hex"00000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000012000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000000000000000000000000000001000000000000000000000000547a514d5e3769680ce22b2361c10ea13619e8a900000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000008";

    /**
     * @dev Encoded price source for MKR:
     *  decimals: 18
     *  aggregators: [0xec1D1B3b0443256cc3860e24a46F108e699484Aa]
     */
    bytes private constant MKR =
        hex"00000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000012000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000000000000000000000000000001000000000000000000000000ec1d1b3b0443256cc3860e24a46f108e699484aa00000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000008";

    /**
     * @dev Encoded price source for LDO:
     *  decimals: 18
     *  aggregators: [0x4e844125952D32AcdF339BE976c98E22F6F318dB, 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419]
     */
    bytes private constant LDO =
        hex"00000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000012000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000c000000000000000000000000000000000000000000000000000000000000000020000000000000000000000004e844125952d32acdf339be976c98e22f6f318db0000000000000000000000005f4ec3df9cbd43714fe2740f5e3616155c5b8419000000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000120000000000000000000000000000000000000000000000000000000000000008";

    /**
     * @dev Encoded price source for INCH:
     *  decimals: 18
     *  aggregators: [0xc929ad75B72593967DE83E7F7Cda0493458261D9]
     */
    bytes private constant INCH =
        hex"00000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000012000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000000000000000000000000000001000000000000000000000000c929ad75b72593967de83e7f7cda0493458261d900000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000008";

    /**
     * @dev Encoded price source for AMP:
     *  decimals: 18
     *  aggregators: [0xD9BdD9f5ffa7d89c846A5E3231a093AE4b3469D2]
     */
    bytes private constant AMP =
        hex"00000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000012000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000000000000000000000000000001000000000000000000000000d9bdd9f5ffa7d89c846a5e3231a093ae4b3469d200000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000008";

    /**
     * @dev Encoded price source for COMP:
     *  decimals: 18
     *  aggregators: [0xdbd020CAeF83eFd542f4De03e3cF0C28A4428bd5]
     */
    bytes private constant COMP =
        hex"00000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000012000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000000000000000000000000000001000000000000000000000000dbd020caef83efd542f4de03e3cf0c28a4428bd500000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000008";

    /**
     * @dev Encoded price source for YFI:
     *  decimals: 18
     *  aggregators: [0xA027702dbb89fbd58938e4324ac03B58d812b0E1]
     */
    bytes private constant YFI =
        hex"00000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000012000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000000000000000000000000000001000000000000000000000000a027702dbb89fbd58938e4324ac03b58d812b0e100000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000008";

    /**
     * @dev Encoded price source for SUSHI:
     *  decimals: 18
     *  aggregators: [0xCc70F09A6CC17553b2E31954cD36E4A2d89501f7]
     */
    bytes private constant SUSHI =
        hex"00000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000012000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000000000000000000000000000001000000000000000000000000cc70f09a6cc17553b2e31954cd36e4a2d89501f700000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000008";

    /**
     * @dev Encoded price source for BAL:
     *  decimals: 18
     *  aggregators: [0xdF2917806E30300537aEB49A7663062F4d1F2b5F]
     */
    bytes private constant BAL =
        hex"00000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000012000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000000000000000000000000000001000000000000000000000000df2917806e30300537aeb49a7663062f4d1f2b5f00000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000008";

    /**
     * @dev Encoded price source for SNX:
     *  decimals: 18
     *  aggregators: [0xDC3EA94CD0AC27d9A86C180091e7f78C683d3699]
     */
    bytes private constant SNX =
        hex"00000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000012000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000000000000000000000000000001000000000000000000000000dc3ea94cd0ac27d9a86c180091e7f78c683d369900000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000008";

    /**
     * @dev Encoded price source for CRV:
     *  decimals: 18
     *  aggregators: [0xCd627aA160A6fA45Eb793D19Ef54f5062F20f33f]
     */
    bytes private constant CRV =
        hex"00000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000012000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000000000000000000000000000001000000000000000000000000cd627aa160a6fa45eb793d19ef54f5062f20f33f00000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000008";

    /**
     * @dev Encoded price source for CVX:
     *  decimals: 18
     *  aggregators: [0xd962fC30A72A84cE50161031391756Bf2876Af5D]
     */
    bytes private constant CVX =
        hex"00000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000012000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000000000000000000000000000001000000000000000000000000d962fc30a72a84ce50161031391756bf2876af5d00000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000008";

    /**
     * @dev Encoded price source for LRC:
     *  decimals: 18
     *  aggregators: [0x160AC928A16C93eD4895C2De6f81ECcE9a7eB7b4, 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419]
     */
    bytes private constant LRC =
        hex"00000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000012000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000c00000000000000000000000000000000000000000000000000000000000000002000000000000000000000000160ac928a16c93ed4895c2de6f81ecce9a7eb7b40000000000000000000000005f4ec3df9cbd43714fe2740f5e3616155c5b8419000000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000120000000000000000000000000000000000000000000000000000000000000008";

    /**
     * @dev Encoded price source for FXS:
     *  decimals: 18
     *  aggregators: [0x6Ebc52C8C1089be9eB3945C4350B68B8E4C2233f]
     */
    bytes private constant FXS =
        hex"00000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000012000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000a000000000000000000000000000000000000000000000000000000000000000010000000000000000000000006ebc52c8c1089be9eb3945c4350b68b8e4c2233f00000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000008";

    /**
     * @dev Encoded price source for LINK:
     *  decimals: 18
     *  aggregators: [0x2c1d072e956AFFC0D435Cb7AC38EF18d24d9127c]
     */
    bytes private constant LINK =
        hex"00000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000012000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000a000000000000000000000000000000000000000000000000000000000000000010000000000000000000000002c1d072e956affc0d435cb7ac38ef18d24d9127c00000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000008";

    /**
     * @dev Encoded price source for DAI:
     *  decimals: 18
     *  aggregators: [0xAed0c38402a5d19df6E4c03F4E2DceD6e29c1ee9]
     */
    bytes private constant DAI =
        hex"00000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000012000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000000000000000000000000000001000000000000000000000000aed0c38402a5d19df6e4c03f4e2dced6e29c1ee900000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000008";

    /**
     * @dev Encoded price source for BNB:
     *  decimals: 18
     *  aggregators: [0x14e613AC84a31f709eadbdF89C6CC390fDc9540A]
     */
    bytes private constant BNB =
        hex"00000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000012000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000a0000000000000000000000000000000000000000000000000000000000000000100000000000000000000000014e613ac84a31f709eadbdf89c6cc390fdc9540a00000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000008";

    /**
     * @dev Encoded price source for MATIC:
     *  decimals: 18
     *  aggregators: [0x7bAC85A8a13A4BcD8abb3eB7d6b4d632c5a57676]
     */
    bytes private constant MATIC =
        hex"00000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000012000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000a000000000000000000000000000000000000000000000000000000000000000010000000000000000000000007bac85a8a13a4bcd8abb3eb7d6b4d632c5a5767600000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000008";

    /**
     * @dev Encoded price source for ZRX:
     *  decimals: 18
     *  aggregators: [0x2Da4983a622a8498bb1a21FaE9D8F6C664939962]
     */
    bytes private constant ZRX =
        hex"00000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000012000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000a000000000000000000000000000000000000000000000000000000000000000010000000000000000000000002da4983a622a8498bb1a21fae9d8f6c66493996200000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000012";

    /**
     * @dev Encoded price source for BAT:
     *  decimals: 18
     *  aggregators: [0x0d16d4528239e9ee52fa531af613AcdB23D88c94]
     */
    bytes private constant BAT =
        hex"00000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000012000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000a000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000d16d4528239e9ee52fa531af613acdb23d88c9400000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000012";

    /**
     * @dev Encoded price source for MANA:
     *  decimals: 18
     *  aggregators: [0x82A44D92D6c329826dc557c5E1Be6ebeC5D5FeB9, 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419]
     */
    bytes private constant MANA =
        hex"00000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000012000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000c0000000000000000000000000000000000000000000000000000000000000000200000000000000000000000082a44d92d6c329826dc557c5e1be6ebec5d5feb90000000000000000000000005f4ec3df9cbd43714fe2740f5e3616155c5b8419000000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000120000000000000000000000000000000000000000000000000000000000000008";

    /**
     * @dev Encoded price source for DASH:
     *  decimals: 18
     *  aggregators: [0xFb0cADFEa136E9E343cfb55B863a6Df8348ab912]
     */
    bytes private constant DASH =
        hex"00000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000012000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000000000000000000000000000001000000000000000000000000fb0cadfea136e9e343cfb55b863a6df8348ab91200000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000008";

    /// @dev Returns encoded `Source` for given constiturnt info
    ///
    /// @param asset Address of underlying asset
    /// @param chainId ChainIf of underlying asset's network
    ///
    /// @return Encoded `Source`
    function priceSourceOf(address asset, uint256 chainId) internal pure returns (bytes memory) {
        if (chainId == 1) {
            if (asset == 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2) return WETH;
            else if (asset == 0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984) return UNI;
            else if (asset == 0x8CE9137d39326AD0cD6491fb5CC0CbA0e089b6A9) return SXP;
            else if (asset == 0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9) return AAVE;
            else if (asset == 0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2) return MKR;
            else if (asset == 0x5A98FcBEA516Cf06857215779Fd812CA3beF1B32) return LDO;
            else if (asset == 0x111111111117dC0aa78b770fA6A738034120C302) return INCH;
            else if (asset == 0xfF20817765cB7f73d4bde2e66e067E58D11095C2) return AMP;
            else if (asset == 0xc00e94Cb662C3520282E6f5717214004A7f26888) return COMP;
            else if (asset == 0x0bc529c00C6401aEF6D220BE8C6Ea1667F6Ad93e) return YFI;
            else if (asset == 0x6B3595068778DD592e39A122f4f5a5cF09C90fE2) return SUSHI;
            else if (asset == 0xba100000625a3754423978a60c9317c58a424e3D) return BAL;
            else if (asset == 0xC011a73ee8576Fb46F5E1c5751cA3B9Fe0af2a6F) return SNX;
            else if (asset == 0xD533a949740bb3306d119CC777fa900bA034cd52) return CRV;
            else if (asset == 0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B) return CVX;
            else if (asset == 0xBBbbCA6A901c926F240b89EacB641d8Aec7AEafD) return LRC;
            else if (asset == 0x3432B6A60D23Ca0dFCa7761B7ab56459D9C964D0) return FXS;
            else if (asset == 0x514910771AF9Ca656af840dff83E8264EcF986CA) return LINK;
            else if (asset == 0x6B175474E89094C44Da98b954EedeAC495271d0F) return DAI;
            else if (asset == 0xE41d2489571d322189246DaFA5ebDe1F4699F498) return ZRX;
            else if (asset == 0x0D8775F648430679A709E98d2b0Cb6250d2887EF) return BAT;
            else if (asset == 0x0F5D2fB29fb7d3CFeE444a200298f468908cC942) return MANA;
        } else if (chainId == 56) {
            if (asset == 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c) return BNB;
            else if (asset == 0x023B5F2e3779171380383b4CA8aA751ACfBbeF4c) return DASH;
        } else if (chainId == 137) {
            if (asset == 0x0000000000000000000000000000000000001010) return MATIC;
        }

        revert PriceSourceLibInvalid(asset, chainId);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import {Owned} from "solmate/auth/Owned.sol";

import {BytesLib} from "./libraries/BytesLib.sol";
import {ExcessivelySafeCall} from "./libraries/ExcessivelySafeCall.sol";

import {ILayerZeroEndpoint} from "layerzero/interfaces/ILayerZeroEndpoint.sol";
import {ILayerZeroReceiver} from "layerzero/interfaces/ILayerZeroReceiver.sol";
import {ILayerZeroUserApplicationConfig} from "layerzero/interfaces/ILayerZeroUserApplicationConfig.sol";

error NonblockingLzApp__InvalidAdapterParams();
error NonblockingLzApp__InvalidCaller();
error NonblockingLzApp__InvalidMinGas();
error NonblockingLzApp__InvalidPayload();
error NonblockingLzApp__InvalidSource();
error NonblockingLzApp__NoStoredMessage();
error NonblockingLzApp__NoTrustedPath();
error NonblockingLzApp__NotTrustedSource();

abstract contract NonblockingLzApp is Owned, ILayerZeroReceiver, ILayerZeroUserApplicationConfig {
    using BytesLib for bytes;
    using ExcessivelySafeCall for address;

    ILayerZeroEndpoint public immutable lzEndpoint;
    mapping(uint16 => bytes) public trustedRemoteLookup;
    mapping(uint16 => mapping(uint16 => uint256)) public minDstGasLookup;
    address public precrime;

    mapping(uint16 => mapping(bytes => mapping(uint64 => bytes32))) public failedMessages;

    event MessageFailed(uint16 _srcChainId, bytes _srcAddress, uint64 _nonce, bytes _payload, bytes _reason);
    event RetryMessageSuccess(uint16 _srcChainId, bytes _srcAddress, uint64 _nonce, bytes32 _payloadHash);
    event SetMinDstGas(uint16 _dstChainId, uint16 _type, uint256 _minDstGas);
    event SetPrecrime(address precrime);
    event SetTrustedRemote(uint16 _remoteChainId, bytes _path);
    event SetTrustedRemoteAddress(uint16 _remoteChainId, bytes _remoteAddress);

    // @todo use roles instead of owner
    constructor(address _lzEndpoint) Owned(msg.sender) {
        lzEndpoint = ILayerZeroEndpoint(_lzEndpoint);
    }

    function lzReceive(uint16 _srcChainId, bytes calldata _srcAddress, uint64 _nonce, bytes calldata _payload)
        public
        virtual
        override
    {
        if (msg.sender != address(lzEndpoint)) {
            revert NonblockingLzApp__InvalidCaller();
        }

        bytes memory trustedRemote = trustedRemoteLookup[_srcChainId];
        bool isValidSource = _srcAddress.length == trustedRemote.length && trustedRemote.length > 0
            && keccak256(_srcAddress) == keccak256(trustedRemote);
        if (!isValidSource) {
            revert NonblockingLzApp__InvalidSource();
        }

        _blockingLzReceive(_srcChainId, _srcAddress, _nonce, _payload);
    }

    function nonblockingLzReceive(
        uint16 _srcChainId,
        bytes calldata _srcAddress,
        uint64 _nonce,
        bytes calldata _payload
    ) public virtual {
        if (msg.sender != address(this)) {
            revert NonblockingLzApp__InvalidCaller();
        }

        _nonblockingLzReceive(_srcChainId, _srcAddress, _nonce, _payload);
    }

    function retryMessage(uint16 _srcChainId, bytes calldata _srcAddress, uint64 _nonce, bytes calldata _payload)
        public
        payable
        virtual
    {
        bytes32 payloadHash = failedMessages[_srcChainId][_srcAddress][_nonce];
        if (payloadHash == bytes32(0)) {
            revert NonblockingLzApp__NoStoredMessage();
        }

        if (keccak256(_payload) != payloadHash) {
            revert NonblockingLzApp__InvalidPayload();
        }

        delete failedMessages[_srcChainId][_srcAddress][_nonce];

        _nonblockingLzReceive(_srcChainId, _srcAddress, _nonce, _payload);
        emit RetryMessageSuccess(_srcChainId, _srcAddress, _nonce, payloadHash);
    }

    function _nonblockingLzReceive(uint16 _srcChainId, bytes memory _srcAddress, uint64 _nonce, bytes memory _payload)
        internal
        virtual;

    function _blockingLzReceive(uint16 _srcChainId, bytes memory _srcAddress, uint64 _nonce, bytes memory _payload)
        internal
        virtual
    {
        (bool success, bytes memory reason) = address(this).excessivelySafeCall(
            gasleft(),
            150,
            abi.encodeWithSelector(this.nonblockingLzReceive.selector, _srcChainId, _srcAddress, _nonce, _payload)
        );
        if (!success) {
            failedMessages[_srcChainId][_srcAddress][_nonce] = keccak256(_payload);
            emit MessageFailed(_srcChainId, _srcAddress, _nonce, _payload, reason);
        }
    }

    function _lzSend(
        uint16 _dstChainId,
        bytes memory _payload,
        address payable _refundAddress,
        address _zroPaymentAddress,
        bytes memory _adapterParams,
        uint256 _nativeFee
    ) internal virtual {
        bytes memory trustedRemote = trustedRemoteLookup[_dstChainId];
        if (trustedRemote.length == 0) {
            revert NonblockingLzApp__NotTrustedSource();
        }

        lzEndpoint.send{value: _nativeFee}(
            _dstChainId, trustedRemote, _payload, _refundAddress, _zroPaymentAddress, _adapterParams
        );
    }

    function _checkGasLimit(uint16 _dstChainId, uint16 _type, bytes memory _adapterParams, uint256 _extraGas)
        internal
        view
        virtual
    {
        uint256 minGasLimit = minDstGasLookup[_dstChainId][_type] + _extraGas;
        if (minGasLimit > 0) {
            revert NonblockingLzApp__InvalidMinGas();
        }

        uint256 providedGasLimit = _getGasLimit(_adapterParams);
        if (providedGasLimit < minGasLimit) {
            revert NonblockingLzApp__InvalidMinGas();
        }
    }

    function _getGasLimit(bytes memory _adapterParams) internal pure virtual returns (uint256 gasLimit) {
        if (_adapterParams.length < 34) {
            revert NonblockingLzApp__InvalidAdapterParams();
        }

        assembly {
            gasLimit := mload(add(_adapterParams, 34))
        }
    }

    function getConfig(uint16 _version, uint16 _chainId, address, uint256 _configType)
        external
        view
        returns (bytes memory)
    {
        return lzEndpoint.getConfig(_version, _chainId, address(this), _configType);
    }

    function setConfig(uint16 _version, uint16 _chainId, uint256 _configType, bytes calldata _config)
        external
        override
        onlyOwner
    {
        lzEndpoint.setConfig(_version, _chainId, _configType, _config);
    }

    function setSendVersion(uint16 _version) external override onlyOwner {
        lzEndpoint.setSendVersion(_version);
    }

    function setReceiveVersion(uint16 _version) external override onlyOwner {
        lzEndpoint.setReceiveVersion(_version);
    }

    function forceResumeReceive(uint16 _srcChainId, bytes calldata _srcAddress) external override onlyOwner {
        lzEndpoint.forceResumeReceive(_srcChainId, _srcAddress);
    }

    function setTrustedRemote(uint16 _srcChainId, bytes calldata _path) external onlyOwner {
        trustedRemoteLookup[_srcChainId] = _path;
        emit SetTrustedRemote(_srcChainId, _path);
    }

    function setTrustedRemoteAddress(uint16 _remoteChainId, bytes calldata _remoteAddress) external onlyOwner {
        trustedRemoteLookup[_remoteChainId] = abi.encodePacked(_remoteAddress, address(this));
        emit SetTrustedRemoteAddress(_remoteChainId, _remoteAddress);
    }

    function getTrustedRemoteAddress(uint16 _remoteChainId) external view returns (bytes memory) {
        bytes memory path = trustedRemoteLookup[_remoteChainId];
        if (path.length == 0) {
            revert NonblockingLzApp__NoTrustedPath();
        }

        return path.slice(0, path.length - 20);
    }

    function setPrecrime(address _precrime) external onlyOwner {
        precrime = _precrime;
        emit SetPrecrime(_precrime);
    }

    function setMinDstGas(uint16 _dstChainId, uint16 _packetType, uint256 _minGas) external onlyOwner {
        if (_minGas == 0) {
            revert NonblockingLzApp__InvalidMinGas();
        }

        minDstGasLookup[_dstChainId][_packetType] = _minGas;
        emit SetMinDstGas(_dstChainId, _packetType, _minGas);
    }

    function isTrustedRemote(uint16 _srcChainId, bytes calldata _srcAddress) external view returns (bool) {
        return keccak256(trustedRemoteLookup[_srcChainId]) == keccak256(_srcAddress);
    }
}

// SPDX-License-Identifier: Unlicense
/*
 * @title Solidity Bytes Arrays Utils
 * @author Gonçalo Sá <[email protected]>
 *
 * @dev Bytes tightly packed arrays utility library for ethereum contracts written in Solidity.
 *      The library lets you concatenate, slice and type cast bytes arrays both in memory and storage.
 */
pragma solidity ^0.8.17;

library BytesLib {
    function concat(bytes memory _preBytes, bytes memory _postBytes) internal pure returns (bytes memory) {
        bytes memory tempBytes;

        assembly {
            // Get a location of some free memory and store it in tempBytes as
            // Solidity does for memory variables.
            tempBytes := mload(0x40)

            // Store the length of the first bytes array at the beginning of
            // the memory for tempBytes.
            let length := mload(_preBytes)
            mstore(tempBytes, length)

            // Maintain a memory counter for the current write location in the
            // temp bytes array by adding the 32 bytes for the array length to
            // the starting location.
            let mc := add(tempBytes, 0x20)
            // Stop copying when the memory counter reaches the length of the
            // first bytes array.
            let end := add(mc, length)

            for {
                // Initialize a copy counter to the start of the _preBytes data,
                // 32 bytes into its memory.
                let cc := add(_preBytes, 0x20)
            } lt(mc, end) {
                // Increase both counters by 32 bytes each iteration.
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                // Write the _preBytes data into the tempBytes memory 32 bytes
                // at a time.
                mstore(mc, mload(cc))
            }

            // Add the length of _postBytes to the current length of tempBytes
            // and store it as the new length in the first 32 bytes of the
            // tempBytes memory.
            length := mload(_postBytes)
            mstore(tempBytes, add(length, mload(tempBytes)))

            // Move the memory counter back from a multiple of 0x20 to the
            // actual end of the _preBytes data.
            mc := end
            // Stop copying when the memory counter reaches the new combined
            // length of the arrays.
            end := add(mc, length)

            for { let cc := add(_postBytes, 0x20) } lt(mc, end) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } { mstore(mc, mload(cc)) }

            // Update the free-memory pointer by padding our last write location
            // to 32 bytes: add 31 bytes to the end of tempBytes to move to the
            // next 32 byte block, then round down to the nearest multiple of
            // 32. If the sum of the length of the two arrays is zero then add
            // one before rounding down to leave a blank 32 bytes (the length block with 0).
            mstore(
                0x40,
                and(
                    add(add(end, iszero(add(length, mload(_preBytes)))), 31),
                    not(31) // Round down to the nearest 32 bytes.
                )
            )
        }

        return tempBytes;
    }

    function concatStorage(bytes storage _preBytes, bytes memory _postBytes) internal {
        assembly {
            // Read the first 32 bytes of _preBytes storage, which is the length
            // of the array. (We don't need to use the offset into the slot
            // because arrays use the entire slot.)
            let fslot := sload(_preBytes.slot)
            // Arrays of 31 bytes or less have an even value in their slot,
            // while longer arrays have an odd value. The actual length is
            // the slot divided by two for odd values, and the lowest order
            // byte divided by two for even values.
            // If the slot is even, bitwise and the slot with 255 and divide by
            // two to get the length. If the slot is odd, bitwise and the slot
            // with -1 and divide by two.
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)
            let newlength := add(slength, mlength)
            // slength can contain both the length and contents of the array
            // if length < 32 bytes so let's prepare for that
            // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
            switch add(lt(slength, 32), lt(newlength, 32))
            case 2 {
                // Since the new array still fits in the slot, we just need to
                // update the contents of the slot.
                // uint(bytes_storage) = uint(bytes_storage) + uint(bytes_memory) + new_length
                sstore(
                    _preBytes.slot,
                    // all the modifications to the slot are inside this
                    // next block
                    add(
                        // we can just add to the slot contents because the
                        // bytes we want to change are the LSBs
                        fslot,
                        add(
                            mul(
                                div(
                                    // load the bytes from memory
                                    mload(add(_postBytes, 0x20)),
                                    // zero all bytes to the right
                                    exp(0x100, sub(32, mlength))
                                ),
                                // and now shift left the number of bytes to
                                // leave space for the length in the slot
                                exp(0x100, sub(32, newlength))
                            ),
                            // increase length by the double of the memory
                            // bytes length
                            mul(mlength, 2)
                        )
                    )
                )
            }
            case 1 {
                // The stored value fits in the slot, but the combined value
                // will exceed it.
                // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes.slot)
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                // save new length
                sstore(_preBytes.slot, add(mul(newlength, 2), 1))

                // The contents of the _postBytes array start 32 bytes into
                // the structure. Our first read should obtain the `submod`
                // bytes that can fit into the unused space in the last word
                // of the stored array. To get this, we read 32 bytes starting
                // from `submod`, so the data we read overlaps with the array
                // contents by `submod` bytes. Masking the lowest-order
                // `submod` bytes allows us to add that value directly to the
                // stored value.

                let submod := sub(32, slength)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(
                    sc,
                    add(
                        and(fslot, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00),
                        and(mload(mc), mask)
                    )
                )

                for {
                    mc := add(mc, 0x20)
                    sc := add(sc, 1)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } { sstore(sc, mload(mc)) }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
            default {
                // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes.slot)
                // Start copying to the last used word of the stored array.
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                // save new length
                sstore(_preBytes.slot, add(mul(newlength, 2), 1))

                // Copy over the first `submod` bytes of the new data as in
                // case 1 above.
                let slengthmod := mod(slength, 32)
                let mlengthmod := mod(mlength, 32)
                let submod := sub(32, slengthmod)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(sc, add(sload(sc), and(mload(mc), mask)))

                for {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } { sstore(sc, mload(mc)) }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
        }
    }

    function slice(bytes memory _bytes, uint256 _start, uint256 _length) internal pure returns (bytes memory) {
        require(_length + 31 >= _length, "slice_overflow");
        require(_bytes.length >= _start + _length, "slice_outOfBounds");

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
                // Get a location of some free memory and store it in tempBytes as
                // Solidity does for memory variables.
                tempBytes := mload(0x40)

                // The first word of the slice result is potentially a partial
                // word read from the original array. To read it, we calculate
                // the length of that partial word and start copying that many
                // bytes into the array. The first word we copy will start with
                // data we don't care about, but the last `lengthmod` bytes will
                // land at the beginning of the contents of the new array. When
                // we're done copying, we overwrite the full first word with
                // the actual length of the slice.
                let lengthmod := and(_length, 31)

                // The multiplication in the next line is necessary
                // because when slicing multiples of 32 bytes (lengthmod == 0)
                // the following copy loop was copying the origin's length
                // and then ending prematurely not copying everything it should.
                let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, _length)

                for {
                    // The multiplication in the next line has the same exact purpose
                    // as the one above.
                    let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } { mstore(mc, mload(cc)) }

                mstore(tempBytes, _length)

                //update free-memory pointer
                //allocating the array padded to 32 bytes like the compiler does now
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            //if we want a zero-length slice let's just return a zero-length array
            default {
                tempBytes := mload(0x40)
                //zero out the 32 bytes slice we are about to return
                //we need to do it because Solidity does not garbage collect
                mstore(tempBytes, 0)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }

    function toAddress(bytes memory _bytes, uint256 _start) internal pure returns (address) {
        require(_bytes.length >= _start + 20, "toAddress_outOfBounds");
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }

    function toUint8(bytes memory _bytes, uint256 _start) internal pure returns (uint8) {
        require(_bytes.length >= _start + 1, "toUint8_outOfBounds");
        uint8 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x1), _start))
        }

        return tempUint;
    }

    function toUint16(bytes memory _bytes, uint256 _start) internal pure returns (uint16) {
        require(_bytes.length >= _start + 2, "toUint16_outOfBounds");
        uint16 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x2), _start))
        }

        return tempUint;
    }

    function toUint32(bytes memory _bytes, uint256 _start) internal pure returns (uint32) {
        require(_bytes.length >= _start + 4, "toUint32_outOfBounds");
        uint32 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x4), _start))
        }

        return tempUint;
    }

    function toUint64(bytes memory _bytes, uint256 _start) internal pure returns (uint64) {
        require(_bytes.length >= _start + 8, "toUint64_outOfBounds");
        uint64 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x8), _start))
        }

        return tempUint;
    }

    function toUint96(bytes memory _bytes, uint256 _start) internal pure returns (uint96) {
        require(_bytes.length >= _start + 12, "toUint96_outOfBounds");
        uint96 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0xc), _start))
        }

        return tempUint;
    }

    function toUint128(bytes memory _bytes, uint256 _start) internal pure returns (uint128) {
        require(_bytes.length >= _start + 16, "toUint128_outOfBounds");
        uint128 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x10), _start))
        }

        return tempUint;
    }

    function touint(bytes memory _bytes, uint256 _start) internal pure returns (uint256) {
        require(_bytes.length >= _start + 32, "touint_outOfBounds");
        uint256 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x20), _start))
        }

        return tempUint;
    }

    function toBytes32(bytes memory _bytes, uint256 _start) internal pure returns (bytes32) {
        require(_bytes.length >= _start + 32, "toBytes32_outOfBounds");
        bytes32 tempBytes32;

        assembly {
            tempBytes32 := mload(add(add(_bytes, 0x20), _start))
        }

        return tempBytes32;
    }

    function equal(bytes memory _preBytes, bytes memory _postBytes) internal pure returns (bool) {
        bool success = true;

        assembly {
            let length := mload(_preBytes)

            // if lengths don't match the arrays are not equal
            switch eq(length, mload(_postBytes))
            case 1 {
                // cb is a circuit breaker in the for loop since there's
                //  no said feature for inline assembly loops
                // cb = 1 - don't breaker
                // cb = 0 - break
                let cb := 1

                let mc := add(_preBytes, 0x20)
                let end := add(mc, length)

                for { let cc := add(_postBytes, 0x20) }
                // the next line is the loop condition:
                // while(uint(mc < end) + cb == 2)
                eq(add(lt(mc, end), cb), 2) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    // if any of these checks fails then arrays are not equal
                    if iszero(eq(mload(mc), mload(cc))) {
                        // unsuccess:
                        success := 0
                        cb := 0
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }

    function equalStorage(bytes storage _preBytes, bytes memory _postBytes) internal view returns (bool) {
        bool success = true;

        assembly {
            // we know _preBytes_offset is 0
            let fslot := sload(_preBytes.slot)
            // Decode the length of the stored array like in concatStorage().
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)

            // if lengths don't match the arrays are not equal
            switch eq(slength, mlength)
            case 1 {
                // slength can contain both the length and contents of the array
                // if length < 32 bytes so let's prepare for that
                // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
                if iszero(iszero(slength)) {
                    switch lt(slength, 32)
                    case 1 {
                        // blank the last byte which is the length
                        fslot := mul(div(fslot, 0x100), 0x100)

                        if iszero(eq(fslot, mload(add(_postBytes, 0x20)))) {
                            // unsuccess:
                            success := 0
                        }
                    }
                    default {
                        // cb is a circuit breaker in the for loop since there's
                        //  no said feature for inline assembly loops
                        // cb = 1 - don't breaker
                        // cb = 0 - break
                        let cb := 1

                        // get the keccak hash to get the contents of the array
                        mstore(0x0, _preBytes.slot)
                        let sc := keccak256(0x0, 0x20)

                        let mc := add(_postBytes, 0x20)
                        let end := add(mc, mlength)

                        // the next line is the loop condition:
                        // while(uint(mc < end) + cb == 2)
                        for {} eq(add(lt(mc, end), cb), 2) {
                            sc := add(sc, 1)
                            mc := add(mc, 0x20)
                        } {
                            if iszero(eq(sload(sc), mload(mc))) {
                                // unsuccess:
                                success := 0
                                cb := 0
                            }
                        }
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity 0.8.17;

library ExcessivelySafeCall {
    uint256 constant LOW_28_MASK = 0x00000000ffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    /// @notice Use when you _really_ really _really_ don't trust the called
    /// contract. This prevents the called contract from causing reversion of
    /// the caller in as many ways as we can.
    /// @dev The main difference between this and a solidity low-level call is
    /// that we limit the number of bytes that the callee can cause to be
    /// copied to caller memory. This prevents stupid things like malicious
    /// contracts returning 10,000,000 bytes causing a local OOG when copying
    /// to memory.
    /// @param _target The address to call
    /// @param _gas The amount of gas to forward to the remote contract
    /// @param _maxCopy The maximum number of bytes of returndata to copy
    /// to memory.
    /// @param _calldata The data to send to the remote contract
    /// @return success and returndata, as `.call()`. Returndata is capped to
    /// `_maxCopy` bytes.
    function excessivelySafeCall(address _target, uint256 _gas, uint16 _maxCopy, bytes memory _calldata)
        internal
        returns (bool, bytes memory)
    {
        // set up for assembly call
        uint256 _toCopy;
        bool _success;
        bytes memory _returnData = new bytes(_maxCopy);
        // dispatch message to recipient
        // by assembly calling "handle" function
        // we call via assembly to avoid memcopying a very large returndata
        // returned by a malicious contract
        assembly {
            _success :=
                call(
                    _gas, // gas
                    _target, // recipient
                    0, // ether value
                    add(_calldata, 0x20), // inloc
                    mload(_calldata), // inlen
                    0, // outloc
                    0 // outlen
                )
            // limit our copy to 256 bytes
            _toCopy := returndatasize()
            if gt(_toCopy, _maxCopy) { _toCopy := _maxCopy }
            // Store the length of the copied bytes
            mstore(_returnData, _toCopy)
            // copy the bytes from returndata[0:_toCopy]
            returndatacopy(add(_returnData, 0x20), 0, _toCopy)
        }
        return (_success, _returnData);
    }

    /// @notice Use when you _really_ really _really_ don't trust the called
    /// contract. This prevents the called contract from causing reversion of
    /// the caller in as many ways as we can.
    /// @dev The main difference between this and a solidity low-level call is
    /// that we limit the number of bytes that the callee can cause to be
    /// copied to caller memory. This prevents stupid things like malicious
    /// contracts returning 10,000,000 bytes causing a local OOG when copying
    /// to memory.
    /// @param _target The address to call
    /// @param _gas The amount of gas to forward to the remote contract
    /// @param _maxCopy The maximum number of bytes of returndata to copy
    /// to memory.
    /// @param _calldata The data to send to the remote contract
    /// @return success and returndata, as `.call()`. Returndata is capped to
    /// `_maxCopy` bytes.
    function excessivelySafeStaticCall(address _target, uint256 _gas, uint16 _maxCopy, bytes memory _calldata)
        internal
        view
        returns (bool, bytes memory)
    {
        // set up for assembly call
        uint256 _toCopy;
        bool _success;
        bytes memory _returnData = new bytes(_maxCopy);
        // dispatch message to recipient
        // by assembly calling "handle" function
        // we call via assembly to avoid memcopying a very large returndata
        // returned by a malicious contract
        assembly {
            _success :=
                staticcall(
                    _gas, // gas
                    _target, // recipient
                    add(_calldata, 0x20), // inloc
                    mload(_calldata), // inlen
                    0, // outloc
                    0 // outlen
                )
            // limit our copy to 256 bytes
            _toCopy := returndatasize()
            if gt(_toCopy, _maxCopy) { _toCopy := _maxCopy }
            // Store the length of the copied bytes
            mstore(_returnData, _toCopy)
            // copy the bytes from returndata[0:_toCopy]
            returndatacopy(add(_returnData, 0x20), 0, _toCopy)
        }
        return (_success, _returnData);
    }

    /**
     * @notice Swaps function selectors in encoded contract calls
     * @dev Allows reuse of encoded calldata for functions with identical
     * argument types but different names. It simply swaps out the first 4 bytes
     * for the new selector. This function modifies memory in place, and should
     * only be used with caution.
     * @param _newSelector The new 4-byte selector
     * @param _buf The encoded contract args
     */
    function swapSelector(bytes4 _newSelector, bytes memory _buf) internal pure {
        require(_buf.length >= 4);
        uint256 _mask = LOW_28_MASK;
        assembly {
            // load the first word of
            let _word := mload(add(_buf, 0x20))
            // mask out the top 4 bytes
            // /x
            _word := and(_word, _mask)
            _word := or(_newSelector, _word)
            mstore(add(_buf, 0x20), _word)
        }
    }
}