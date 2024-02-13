// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

// ==============================================================
//  _____                 _      _____ _                        |
// |  _  |_ _ ___ ___ ___| |_   |   __|_|___ ___ ___ ___ ___    |
// |   __| | | . | . | -_|  _|  |   __| |   | .'|   |  _| -_|   |
// |__|  |___|  _|  _|___|_|    |__|  |_|_|_|__,|_|_|___|___|   |
//           |_| |_|                                            |
// ==============================================================
// ========================== Minter ============================
// ==============================================================

// Modified fork from Curve Finance: https://github.com/curvefi 
// @title Token Minter
// @author Curve Finance
// @license MIT

// Puppet Finance: https://github.com/GMX-Blueberry-Club/puppet-contracts

// Primary Author
// johnnyonline: https://github.com/johnnyonline

// Reviewers
// itburnz: https://github.com/nissoh

// ==============================================================

import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import {IMinter} from "./interfaces/IMinter.sol";
import {IPuppet} from "./interfaces/IPuppet.sol";
import {IoPuppet} from "./interfaces/IoPuppet.sol";
import {IScoreGauge} from "./interfaces/IScoreGauge.sol";
import {IGaugeController} from "./interfaces/IGaugeController.sol";

contract Minter is ReentrancyGuard, IMinter {

    mapping(uint256 => mapping(address => bool)) public minted; // epoch -> gauge -> hasMinted

    IPuppet public immutable puppet;
    IoPuppet public immutable oPuppet;

    IGaugeController private immutable _controller;

    // ============================================================================================
    // Constructor
    // ============================================================================================

    constructor(address _puppet, address _oPuppet, address __controller) {
        puppet = IPuppet(_puppet);
        oPuppet = IoPuppet(_oPuppet);

        _controller = IGaugeController(__controller);
    }

    // ============================================================================================
    // External functions
    // ============================================================================================

    /// @inheritdoc IMinter
    function controller() external view override returns (address) {
        return address(_controller);
    }

    /// @inheritdoc IMinter
    function mint(address _gauge) external nonReentrant {
        _mint(_gauge);
    }

    /// @inheritdoc IMinter
    function mintMany(address[] memory _gauges) external nonReentrant {
        for (uint256 i = 0; i < _gauges.length; i++) {
            if (_gauges[i] == address(0)) {
                break;
            }
            _mint(_gauges[i]);
        }
    }

    // ============================================================================================
    // Internal functions
    // ============================================================================================

    function _mint(address _gauge) internal {
        if (IScoreGauge(_gauge).isKilled()) revert GaugeIsKilled();

        IGaugeController __controller = _controller;
        if (__controller.gaugeTypes(_gauge) < 0) revert GaugeNotAdded();

        uint256 _epoch = __controller.epoch() - 1; // underflows if epoch() is 0
        if (!__controller.hasEpochEnded(_epoch)) revert EpochNotEnded();
        if (minted[_epoch][_gauge]) revert AlreadyMinted();

        (uint256 _epochStartTime, uint256 _epochEndTime) = __controller.epochTimeframe(_epoch);
        if (block.timestamp < _epochEndTime) revert EpochNotEnded();

        uint256 _totalMint = puppet.mintableInTimeframe(_epochStartTime, _epochEndTime);
        uint256 _mintForGauge = _totalMint * __controller.gaugeWeightForEpoch(_epoch, _gauge) / 1e18;

        if (_mintForGauge > 0) {
            minted[_epoch][_gauge] = true;

            puppet.mint(address(oPuppet), _mintForGauge);
            oPuppet.addRewards(_mintForGauge, _gauge);

            IScoreGauge(_gauge).addRewards(_epoch, _mintForGauge);

            emit Minted(_gauge, _mintForGauge, _epoch);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

// ==============================================================
//  _____                 _      _____ _                        |
// |  _  |_ _ ___ ___ ___| |_   |   __|_|___ ___ ___ ___ ___    |
// |   __| | | . | . | -_|  _|  |   __| |   | .'|   |  _| -_|   |
// |__|  |___|  _|  _|___|_|    |__|  |_|_|_|__,|_|_|___|___|   |
//           |_| |_|                                            |
// ==============================================================
// =========================== IMinter ==========================
// ==============================================================

// Modified fork from Curve Finance: https://github.com/curvefi 
// @title Token Minter
// @author Curve Finance
// @license MIT

// Puppet Finance: https://github.com/GMX-Blueberry-Club/puppet-contracts

// Primary Author
// johnnyonline: https://github.com/johnnyonline

// Reviewers
// itburnz: https://github.com/nissoh

// ==============================================================

interface IMinter {

    /// @notice Returns the address of the controller
    /// @return _controller The address of the controller
    function controller() external view returns (address _controller);

    /// @notice Mint everything which belongs to `_gauge` and send to it
    /// @param _gauge `ScoreGauge` address to mint for
    function mint(address _gauge) external;

    /// @notice Mint for multiple gauges
    /// @param _gauges List of `ScoreGauge` addresses
    function mintMany(address[] memory _gauges) external;

    // ============================================================================================
    // Events
    // ============================================================================================

    event Minted(address indexed gauge, uint256 minted, uint256 epoch);

    // ============================================================================================
    // Errors
    // ============================================================================================

    error GaugeIsKilled();
    error GaugeNotAdded();
    error EpochNotEnded();
    error AlreadyMinted();
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

// ==============================================================
//  _____                 _      _____ _                        |
// |  _  |_ _ ___ ___ ___| |_   |   __|_|___ ___ ___ ___ ___    |
// |   __| | | . | . | -_|  _|  |   __| |   | .'|   |  _| -_|   |
// |__|  |___|  _|  _|___|_|    |__|  |_|_|_|__,|_|_|___|___|   |
//           |_| |_|                                            |
// ==============================================================
// =========================== IPuppet ==========================
// ==============================================================

// Modified fork from Curve Finance: https://github.com/curvefi 
// @title Curve Finance Token
// @author Curve Finance
// @license MIT
// @notice ERC20 with piecewise-linear mining supply.
// @dev Based on the ERC-20 token standard as defined @ https://eips.ethereum.org/EIPS/eip-20

// Puppet Finance: https://github.com/GMX-Blueberry-Club/puppet-contracts

// Primary Author
// johnnyonline: https://github.com/johnnyonline

// Reviewers
// itburnz: https://github.com/nissoh

// ==============================================================

interface IPuppet {
    
        // ============================================================================================
        // External functions
        // ============================================================================================

        // view functions

        /// @notice Current number of tokens in existence (claimed or unclaimed)
        /// @return _availableSupply Total available supply of tokens
        function availableSupply() external view returns (uint256 _availableSupply);

        /// @notice How much supply is mintable from start timestamp till end timestamp
        /// @param start Start of the time interval (timestamp)
        /// @param end End of the time interval (timestamp)
        /// @return _mintable mintable from `start` till `end`
        function mintableInTimeframe(uint256 start, uint256 end) external view returns (uint256 _mintable);

        /// @notice Total number of tokens in existence.
        /// @return _totalSupply Total supply of tokens
        function totalSupply() external view returns (uint256 _totalSupply);

        /// @notice Check the amount of tokens that an owner allowed to a spender
        /// @param _owner The address which owns the funds
        /// @param _spender The address which will spend the funds
        /// @return _allowance uint256 specifying the amount of tokens still available for the spender
        function allowance(address _owner, address _spender) external view returns (uint256 _allowance);

        // mutated functions

        /// @notice Update mining rate and supply at the start of the epoch
        /// @dev Callable by any address, but only once per epoch. Total supply becomes slightly larger if this function is called late
        function updateMiningParameters() external;

        /// @notice Get timestamp of the current mining epoch start while simultaneously updating mining parameters
        /// @return _startEpochTime Timestamp of the epoch
        function startEpochTimeWrite() external returns (uint256 _startEpochTime);

        /// @notice Get timestamp of the next mining epoch start while simultaneously updating mining parameters
        /// @return _futureEpochTime Timestamp of the next epoch
        function futureEpochTimeWrite() external returns (uint256 _futureEpochTime);

        /// @notice Set the minter address
        /// @dev Only callable once, when minter has not yet been set
        /// @param _minter Address of the minter
        function setMinter(address _minter) external;

        /// @notice Transfer `_value` tokens from `msg.sender` to `_to`
        /// @dev Vyper/Solidity does not allow underflows, so the subtraction in this function will revert on an insufficient balance
        /// @param _to The address to transfer to
        /// @param _value The amount to be transferred
        /// @return _success bool success
        function transfer(address _to, uint256 _value) external returns (bool _success);

        /// @notice Transfer `_value` tokens from `_from` to `_to`
        /// @param _from address The address which you want to send tokens from
        /// @param _to address The address which you want to transfer to
        /// @param _value uint256 the amount of tokens to be transferred
        /// @return _success bool success
        function transferFrom(address _from, address _to, uint256 _value) external returns (bool _success);

        /// @notice Approve `_spender` to transfer `_value` tokens on behalf of `msg.sender`
        /// @dev Approval may only be from zero -> nonzero or from nonzero -> zero in order 
        /// to mitigate the potential race condition described here:
        /// https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
        /// @param _spender The address which will spend the funds
        /// @param _value The amount of tokens to be spent
        /// @return _success bool success
        function approve(address _spender, uint256 _value) external returns (bool _success);

        /// @notice Mint `_value` tokens and assign them to `_to`
        /// @dev Emits a Transfer event originating from 0x00
        /// @param _to The account that will receive the created tokens
        /// @param _value The amount that will be created
        /// @return _success bool success
        function mint(address _to, uint256 _value) external returns (bool _success);

        /// @notice Burn `_value` tokens belonging to `msg.sender`
        /// @dev Emits a Transfer event with a destination of 0x00
        /// @param _value The amount that will be burned
        /// @return _success bool success
        function burn(uint256 _value) external returns (bool _success);
        
        // ============================================================================================
        // Events
        // ============================================================================================

        event Transfer(address indexed from, address indexed to, uint256 value);
        event Approval(address indexed owner, address indexed spender, uint256 value);
        event UpdateMiningParameters(uint256 time, uint256 rate, uint256 supply);
        event SetMinter(address minter);

        // ============================================================================================
        // Errors
        // ============================================================================================

        error NotMinter();
        error ZeroAddress();
        error StartGreaterThanEnd();
        error TooFarInFuture();
        error RateHigherThanInitialRate();
        error TooSoon();
        error MinterAlreadySet();
        error NonZeroApproval();
        error MintExceedsAvailableSupply();

}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

// ==============================================================
//  _____                 _      _____ _                        |
// |  _  |_ _ ___ ___ ___| |_   |   __|_|___ ___ ___ ___ ___    |
// |   __| | | . | . | -_|  _|  |   __| |   | .'|   |  _| -_|   |
// |__|  |___|  _|  _|___|_|    |__|  |_|_|_|__,|_|_|___|___|   |
//           |_| |_|                                            |
// ==============================================================
// ========================== IoPuppet ==========================
// ==============================================================

// Puppet Finance: https://github.com/GMX-Blueberry-Club/puppet-contracts

// Primary Author
// johnnyonline: https://github.com/johnnyonline

// Reviewers
// itburnz: https://github.com/nissoh

// ==============================================================

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IoPuppet {

    struct Option {
        uint256 amount;
        uint256 strike;
        uint256 expiry;
        bool exercised;
    }

    // ============================================================================================
    // External Functions
    // ============================================================================================

    // view functions

    /// @notice Returns the amount to pay to exercise an option
    /// @param _id The id of the option
    /// @return _amountToPay The amount to pay
    function amountToPay(uint256 _id) external view returns (uint256 _amountToPay);

    /// @notice Returns the strike price of an option
    /// @param _id The id of the option
    /// @return _strike The strike price
    function strike(uint256 _id) external view returns (uint256 _strike);

    /// @notice Returns the amount of underlying token for an option
    /// @param _id The id of the option
    /// @return _amount The amount of underlying token
    function amount(uint256 _id) external view returns (uint256 _amount);

    /// @notice Returns the expiry of an option
    /// @param _id The id of the option
    /// @return _expiry The expiry of the option
    function expiry(uint256 _id) external view returns (uint256 _expiry);

    /// @notice Returns the price of the underlying token, in USD, with 18 decimals
    /// @return _price The price of the underlying token
    function price() external view returns (uint256 _price);

    /// @notice Returns whether an option has been exercised
    /// @param _id The id of the option
    /// @return _exercised Whether the option has been exercised
    function exercised(uint256 _id) external view returns (bool _exercised);

    /// @notice Returns the settlement token. A USD stablecoin
    /// @return _token The settlement token
    function payWith() external view returns (address _token);

    // mutated functions

    /// @notice Adds rewards to a gauge
    /// @param _amount The amount of rewards to add
    /// @param _gauge The gauge to add rewards to
    function addRewards(uint256 _amount, address _gauge) external;

    /// @notice Mints an option
    /// @param _amount The amount of underlying tokens to mint
    /// @param _receiver The address to receive the option
    /// @return _id The id of the option
    function mint(uint256 _amount, address _receiver) external returns (uint256 _id);

    /// @notice Exercises an option
    /// @param _id The id of the option
    /// @param _receiver The address to receive the underlying tokens
    /// @param _useFlashLoan Whether to use a flash loans
    function exercise(uint256 _id, address _receiver, bool _useFlashLoan) external;

    /// @notice Refunds an unexercised expired option
    /// @param _ids The ids of the options to refund
    /// @return _amount The amount of underlying tokens refunded
    function refund(uint[] memory _ids) external returns (uint256 _amount);

    // Owner

    /// @notice Sets the minter
    /// @param _minter The address of the minter
    function setMinter(address _minter) external;

    /// @notice Sets whether an address is a score gauge
    /// @param _scoreGauge The address of the score gauge
    /// @param _isScoreGauge Whether the address is a score gauge
    function setScoreGauge(address _scoreGauge, bool _isScoreGauge) external;

    /// @notice Sets the settlement token
    /// @param _usd The address of the settlement token
    function setUSD(IERC20 _usd) external;

    /// @notice Sets the discount
    /// @param _discount The discount
    function setDiscount(uint _discount) external;

    /// @notice Sets the treasury
    /// @param _treasury The address of the treasury
    function setTreasury(address _treasury) external;

    /// @notice Sets the price oracle
    /// @param _priceOracle The address of the price oracle
    function setPriceOracle(address _priceOracle) external;

    /// @notice Sets the flash loan handler
    /// @param _flashLoanHandler The address of the flash loan handler
    function setFlashLoanHandler(address _flashLoanHandler) external;

    // ============================================================================================
    // Events
    // ============================================================================================

    event AddRewards(uint256 amount, address gauge);
    event Mint(uint256 price, uint256 amount, uint256 strike, uint256 expiry, uint256 id, address gauge, address receiver);
    event Exercise(uint256 amount, uint256 strike, uint256 id, address receiver, address sender);
    event Refund(address sender, address receiver, uint256 amount, uint256 strike, uint256 id);
    event SetMinter(address minter);
    event SetScoreGauge(address scoreGauge, bool isScoreGauge);
    event SetUSD(IERC20 usd);
    event SetDiscount(uint discount);
    event SetTreasury(address treasury);
    event SetPriceOracle(address priceOracle);
    event SetFlashLoanHandler(address flashLoanHandler);

    // ============================================================================================
    // Errors
    // ============================================================================================

    error NotMinter();
    error NotScoreGauge();
    error Expired();
    error AlreadyExercised();
    error NotApprovedOrOwner();
    error ZeroAddress();
    error MinterAlreadySet();
    error InvalidDiscount();
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

// ==============================================================
//  _____                 _      _____ _                        |
// |  _  |_ _ ___ ___ ___| |_   |   __|_|___ ___ ___ ___ ___    |
// |   __| | | . | . | -_|  _|  |   __| |   | .'|   |  _| -_|   |
// |__|  |___|  _|  _|___|_|    |__|  |_|_|_|__,|_|_|___|___|   |
//           |_| |_|                                            |
// ==============================================================
// ========================= IScoreGauge ========================
// ==============================================================

// Modified fork from Curve Finance: https://github.com/curvefi 
// @title Liquidity Gauge
// @author Curve Finance
// @license MIT
// @notice Used for measuring liquidity and insurance

// Puppet Finance: https://github.com/GMX-Blueberry-Club/puppet-contracts

// Primary Author
// johnnyonline: https://github.com/johnnyonline

// Reviewers
// itburnz: https://github.com/nissoh

// ==============================================================

interface IScoreGauge {

    struct EpochInfo {
        uint256 profitRewards;
        uint256 volumeRewards;
        uint256 totalProfit;
        uint256 totalVolume;
        uint256 profitWeight;
        uint256 volumeWeight;
        mapping(address => bool) claimed;
        mapping(address => UserPerformance) userPerformance;
    }

    struct UserPerformance {
        uint256 volume;
        uint256 profit;
    }

    /// @notice The ```claimableRewards``` returns the amount of rewards claimable by a user for a given epoch
    /// @param _epoch The uint256 value of the epoch
    /// @param _user The address of the user
    /// @return _userReward The uint256 value of the claimable rewards, with 18 decimals
    function claimableRewards(uint256 _epoch, address _user) external view returns (uint256 _userReward);

    /// @notice The ```userPerformance``` function returns the performance of a user for a given epoch
    /// @param _epoch The uint256 value of the epoch
    /// @param _user The address of the user
    /// @return _volume The uint256 value of the volume generated by the user, USD denominated, with 30 decimals
    /// @return _profit The uint256 value of the profit generated by the user, USD denominated, with 30 decimals
    function userPerformance(uint256 _epoch, address _user) external view returns (uint256 _volume, uint256 _profit);

    /// @notice The ```hasClaimed``` function returns whether a user has claimed rewards for a given epoch
    /// @param _epoch The uint256 value of the epoch
    /// @param _user The address of the user
    /// @return _hasClaimed The bool value of whether the user has claimed rewards or not
    function hasClaimed(uint256 _epoch, address _user) external view returns (bool _hasClaimed);

    /// @notice The ```isKilled``` function returns whether the ScoreGauge is killed or not
    /// @return _isKilled The bool value of the gauge status
    function isKilled() external view returns (bool _isKilled);

    /// @notice The ```claim``` function allows a user to claim rewards for a given epoch
    /// @param _epoch The uint256 value of the epoch
    /// @param _receiver The address of the receiver of rewards
    /// @return _rewards The uint256 value of the claimable rewards, with 18 decimals
    /// @return _id The uint256 value of the newly minted oPuppet id
    function claim(uint256 _epoch, address _receiver) external returns (uint256 _rewards, uint256 _id);

    /// @notice The ```claimMany``` function allows a user to claim rewards for multiple epochs
    /// @param _epochs The uint256[] value of the epochs
    /// @param _receiver The address of the receiver of rewards
    /// @return _rewards The uint256 value of the claimable rewards, with 18 decimals
    /// @return _ids The uint256[] value of the newly minted oPuppet ids
    function claimMany(uint256[] calldata _epochs, address _receiver) external returns (uint256 _rewards, uint256[] memory _ids);

    /// @notice The ```claimAndExcercise``` function allows a user to claim rewards for a given epoch and exercise the oPuppet in the same transaction
    /// @param _epoch The uint256 value of the epoch
    /// @param _receiver The address of the receiver of rewards
    /// @param _useFlashLoan The bool value of whether to use flash loan or not
    /// @return _rewards The uint256 value of the claimable rewards, with 18 decimals
    /// @return _id The uint256 value of the newly minted (and exercised) oPuppet id
    function claimAndExcercise(uint256 _epoch, address _receiver, bool _useFlashLoan) external returns (uint256 _rewards, uint256 _id);

    /// @notice The ```claimAndExcerciseMany``` function allows a user to claim rewards for multiple epochs and exercise the oPuppet in the same transaction
    /// @param _epochs The uint256[] value of the epochs
    /// @param _receiver The address of the receiver of rewards
    /// @param _useFlashLoan The bool value of whether to use flash loan or not
    /// @return _rewards The uint256 value of the claimable rewards, with 18 decimals
    /// @return _ids The uint256[] value of the newly minted (and exercised) oPuppet ids
    function claimAndExcerciseMany(uint256[] calldata _epochs, address _receiver, bool _useFlashLoan) external returns (uint256 _rewards, uint256[] memory _ids);

    /// @notice The ```claimExcerciseAndLock``` function allows a user to claim rewards for a given epoch, exercise the oPuppet and lock the rewards in the Voting Escrow the same transaction
    /// @param _epoch The uint256 value of the epoch
    /// @param _unlockTime The uint256 value of the unlock time. Used only if there's no existing lock
    /// @param _useFlashLoan The bool value of whether to use flash loan or not
    /// @return _rewards The uint256 value of the claimable rewards, with 18 decimals
    /// @return _id The uint256 value of the newly minted (and locked) oPuppet id
    function claimExcerciseAndLock(uint256 _epoch, uint256 _unlockTime, bool _useFlashLoan) external returns (uint256 _rewards, uint256 _id);

    /// @notice The ```claimExcerciseAndLockMany``` function allows a user to claim rewards for multiple epochs, exercise the oPuppet and lock the rewards in the Voting Escrow the same transaction
    /// @param _epochs The uint256[] value of the epochs
    /// @param _unlockTime The uint256 value of the unlock time. Used only if there's no existing lock
    /// @param _useFlashLoan The bool value of whether to use flash loan or not
    /// @return _rewards The uint256 value of the claimable rewards, with 18 decimals
    /// @return _ids The uint256[] value of the newly minted (and locked) oPuppet ids
    function claimExcerciseAndLockMany(uint256[] memory _epochs, uint256 _unlockTime, bool _useFlashLoan) external returns (uint256 _rewards, uint256[] memory _ids);

    /// @notice The ```addRewards``` function allows the Minter to mint rewards for the specified epoch and update the accounting
    /// @param _epoch The uint256 value of the epoch
    /// @param _amount The uint256 value of the amount of minted rewards, with 18 decimals
    function addRewards(uint256 _epoch, uint256 _amount) external;

    /// @notice The ```updateUserScore``` is called by a Route Account when a trade is settled, for each user (Trader/Puppet)
    /// @param _route The address of the route
    function updateUsersScore(address _route) external;

    /// @notice The ```updateUserScore``` is callable by a Route Account when a trade is settled, for each user (Trader/Puppet)
    /// @dev This is used for testing purposes
    /// @param _volume The uint256 value of the volume generated by the user, USD denominated, with 30 decimals
    /// @param _profit The uint256 value of the profit generated by the user, USD denominated, with 30 decimals
    /// @param _user The address of the user
    function updateUserScore(uint256 _volume, uint256 _profit, address _user) external;

    /// @notice The ```killMe``` is called by the admin to kill the gauge
    function killMe() external;

    // ============================================================================================
    // Events
    // ============================================================================================

    event DepositRewards(uint256 amount);
    event Claim(uint256 indexed epoch, uint256 userReward, address indexed user, address indexed receiver);
    event UserScoreUpdate(address indexed user, uint256 volume, uint256 profit);
    event WeightsUpdate(uint256 profitWeight, uint256 volumeWeight);

    // ============================================================================================
    // Errors
    // ============================================================================================

    error NotMinter();
    error InvalidEpoch();
    error AlreadyClaimed();
    error NotRoute();
    error InvalidWeights();
    error NoRewards();
    error ZeroAddress();
    error NotOPuppet();
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

// ==============================================================
//  _____                 _      _____ _                        |
// |  _  |_ _ ___ ___ ___| |_   |   __|_|___ ___ ___ ___ ___    |
// |   __| | | . | . | -_|  _|  |   __| |   | .'|   |  _| -_|   |
// |__|  |___|  _|  _|___|_|    |__|  |_|_|_|__,|_|_|___|___|   |
//           |_| |_|                                            |
// ==============================================================
// ===================== IGaugeController =======================
// ==============================================================

// Modified fork from Curve Finance: https://github.com/curvefi 
// @title Gauge Controller
// @author Curve Finance
// @license MIT
// @notice Controls liquidity gauges and the issuance of coins through the gauges

// Puppet Finance: https://github.com/GMX-Blueberry-Club/puppet-contracts

// Primary Author
// johnnyonline: https://github.com/johnnyonline

// Reviewers
// itburnz: https://github.com/nissoh

// ==============================================================

interface IGaugeController {

        struct Point {
                uint256 bias;
                uint256 slope;
        }

        struct VotedSlope {
                uint256 slope;
                uint256 power;
                uint256 end;
        }

        struct EpochData {
                uint256 startTime;
                uint256 endTime;
                bool hasEnded;
                mapping(address => uint256) gaugeWeights; // gauge_addr -> weight
        }

        // view functions
    
        /// @notice Get current weight for the profit metric, used for calculating reward distribution
        /// @return _profitWeight The uint256 value of the profit weight, must be less than 10_000
        function profitWeight() external view returns (uint256 _profitWeight);

        /// @notice Get current weight for the volume metric, used for calculating reward distribution
        /// @return _volumeWeight The uint256 value of the volume weight, must be less than 10_000
        function volumeWeight() external view returns (uint256 _volumeWeight);

        /// @notice Get current gauge weight
        /// @param _gauge Gauge address
        /// @return _weight Gauge weight
        function getGaugeWeight(address _gauge) external view returns (uint256 _weight);

        /// @notice Get current type weight
        /// @param _typeID Type id
        /// @return _weight Type weight
        function getTypeWeight(int128 _typeID) external view returns (uint256 _weight);

        /// @notice Get current total (type-weighted) weight
        /// @return _totalWeight Total weight
        function getTotalWeight() external view returns (uint256 _totalWeight);

        /// @notice Get sum of gauge weights per type
        /// @param _typeID Type id
        /// @return _sum Sum of gauge weights per type
        function getWeightsSumPerType(int128 _typeID) external view returns (uint256 _sum);

        /// @notice Get gauge type for address
        /// @param _gauge Gauge address
        /// @return _type Gauge type
        function gaugeTypes(address _gauge) external view returns (int128 _type);

        /// @notice Get Gauge relative weight (not more than 1.0) normalized to 1e18
        //          (e.g. 1.0 == 1e18). Inflation which will be received by it is
        //          inflation_rate * relative_weight / 1e18
        /// @param _gauge Gauge address
        /// @param _time Relative weight at the specified timestamp in the past or present
        /// @return _relativeWeight Value of relative weight normalized to 1e18
        function gaugeRelativeWeight(address _gauge, uint256 _time) external view returns (uint256 _relativeWeight);

        /// @notice Get the current rewards epoch
        /// @return _currentEpoch The current rewards epoch
        function epoch() external view returns (uint256 _currentEpoch);

        /// @notice Get the start and end time for the specified epoch
        /// @param _epoch The epoch to get the start and end time for
        /// @return _startTime The start time for the specified epoch
        /// @return _endTime The end time for the specified epoch
        function epochTimeframe(uint256 _epoch) external view returns (uint256 _startTime, uint256 _endTime);

        /// @notice Get relative gauge weight for the specified epoch
        /// @param _epoch The epoch to get the relative gauge weight for
        /// @param _gauge Gauge address
        /// @return _weight Relative gauge weight for the specified epoch
        function gaugeWeightForEpoch(uint256 _epoch, address _gauge) external view returns (uint256 _weight);

        /// @notice Get whether the specified epoch has ended
        /// @param _epoch The epoch to check if it has ended
        /// @return _hasEnded Whether the specified epoch has ended
        function hasEpochEnded(uint256 _epoch) external view returns (bool _hasEnded);

        // mutated functions

        /// @notice Get gauge weight normalized to 1e18 and also fill all the unfilled values for type and gauge records
        /// @dev Any address can call, however nothing is recorded if the values are filled already
        /// @param _gauge Gauge address
        /// @param _time Relative weight at the specified timestamp in the past or present
        /// @return _relativeWeight Value of relative weight normalized to 1e18
        function gaugeRelativeWeightWrite(address _gauge, uint256 _time) external returns (uint256 _relativeWeight);

        /// @notice Checkpoint to fill data common for all gauges
        function checkpoint() external;

        /// @notice Checkpoint to fill data for both a specific gauge and common for all gauges
        /// @param _gauge Gauge address
        function checkpointGauge(address _gauge) external;

        /// @notice Add gauge `_gauge` of type `_gaugeType` with weight `_weight`
        /// @param _gauge Gauge address
        /// @param _gaugeType Gauge type
        /// @param _weight Gauge weight
        function addGauge(address _gauge, int128 _gaugeType, uint256 _weight) external;

        /// @notice Add gauge type with name `_name` and weight `_weight`
        /// @param _name Name of gauge type
        /// @param _weight Weight of gauge type
        function addType(string memory _name, uint256 _weight) external;

        /// @notice Change gauge type `_typeID` weight to `_weight`
        /// @param _typeID Gauge type id
        /// @param _weight New Gauge weight
        function changeTypeWeight(int128 _typeID, uint256 _weight) external;

        /// @notice Change weight of gauge `_gauge` to `_weight`
        /// @param _gauge `GaugeController` contract address
        /// @param _weight New Gauge weight
        function changeGaugeWeight(address _gauge, uint256 _weight) external;

        /// @notice Allocate voting power for changing pool weights
        /// @param _gauge Gauge which `msg.sender` votes for
        /// @param _userWeight Weight for a gauge in bps (units of 0.01%). Minimal is 0.01%. Ignored if 0
        function voteForGaugeWeights(address _gauge, uint256 _userWeight) external;

        /// @notice Initialize the first rewards epoch and update the mining parameters
        function initializeEpoch() external;

        /// @notice Advance to the next rewards epoch
        function advanceEpoch() external;

        /// @notice Set weights for profit and volume. Sum of weights must be 100% (10_000)
        /// @param _profit Profit weight
        /// @param _volume Volume weight
        function setWeights(uint256 _profit, uint256 _volume) external;

        // ============================================================================================
        // Events
        // ============================================================================================

        event AddType(string name, int128 typeID);
        event NewTypeWeight(int128 typeID, uint256 time, uint256 weight, uint256 totalWeight);
        event NewGaugeWeight(address gauge, uint256 time, uint256 weight, uint256 totalWeight);
        event VoteForGauge(uint256 time, address user, address gauge, uint256 weight);
        event NewGauge(address addr, int128 gaugeType, uint256 weight);
        event InitializeEpoch(uint256 timestamp);
        event AdvanceEpoch(uint256 currentEpoch);
        event SetWeights(uint256 profitWeight, uint256 volumeWeight);

        // ============================================================================================
        // Errors
        // ============================================================================================

        error TooMuchPowerUsed();
        error InvalidWeights();
        error EpochNotEnded();
        error EpochNotSet();
        error AlreadyInitialized();
        error GaugeNotAdded();
        error TokenLockExpiresTooSoon();
        error AlreadyVoted();
        error InvalidUserWeight();
        error GaugeAlreadyAdded();
        error InvalidGaugeType();
        error GaugeTypeNotSet();
        error ZeroAddress();
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function decimals() external view returns (uint8);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}