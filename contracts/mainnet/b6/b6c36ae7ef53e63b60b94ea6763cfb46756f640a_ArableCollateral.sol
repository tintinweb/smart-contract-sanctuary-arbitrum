// SPDX-License-Identifier: MIT

/// @title Arable Collateral Contract
/// @author Nithronium

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "./interfaces/IArableAddressRegistry.sol";
import "./interfaces/IArableOracle.sol";
import "./interfaces/IArableLiquidation.sol";
import "./interfaces/IArableManager.sol";
import "./interfaces/IArableSynth.sol";
import "./interfaces/IERC20Extented.sol";

contract ArableCollateral is Initializable, OwnableUpgradeable, ReentrancyGuardUpgradeable, PausableUpgradeable {
    using SafeERC20 for IERC20;

    /**
     * @dev state variable for holding Address registry object
     */
    IArableAddressRegistry private _addressRegistry;

    string private constant _arUSD = "arUSD";

    // *** COLLATERAL VARIABLES AND STRUCTS *** //

    /**
     * @notice struct to keep individual asset data
     *
     */
    struct CollateralAssetData {
        bool isEnabled;
        uint256 allowedRate;
        uint256 index;
    }

    /**
     * @notice state variables for collateral data
     */
    address[] public _supportedCollaterals;
    mapping(address => CollateralAssetData) public _collateralAssetData;

    /**
     * @notice this is used for determining user's deposited token amount
     *
     * @dev mapping of user address => token address => token balance
     */
    mapping(address => mapping(address => uint256)) public _individualCollateral;

    // *** DEBT VARIABLES AND STRUCTS *** //

    /**
     * @notice total debt of the system in terms of USD
     *
     * @dev value will be in 18 decimals (10**18 for $10)
     */
    uint256 public _totalDebt;

    /**
     * @notice total debt factor of the system
     *
     * @dev increases with each {mint} function
     * and decreases with each {burn} function
     */
    uint256 public _totalDebtFactor;

    /**
     * @notice mapping of individual debt factor
     *
     * @dev current debt rate = _totalDebt * _debtFactor / _totalDebtFactor
     * and _totalDebt / _totalDebtFactor is the scale ratio of debt
     */
    mapping(address => uint256) public _debtFactor;

    /**
     * @notice mapping of depositRestricted
     *
     * deposit restricted tokens can be withdrawn, but not deposited
     */
    mapping(address => bool) public depositRestricted;

    uint256 public mintFee;

    event SupportedCollateralAdded(
        address indexed token,
        uint256 allowedRate,
        uint256 index,
        address admin,
        uint256 blockNumber
    );
    event SupportedCollateralRemoved(address indexed token, uint256 index, address admin, uint256 blockNumber);
    event CollateralAllowedRateChanged(
        address indexed token,
        uint256 previousAllowedRate,
        uint256 newAllowedRate,
        uint256 index,
        address admin,
        uint256 blockNumber
    );

    event CollateralDeposited(address indexed user, address indexed token, uint256 amount, uint256 blockNumber);
    event CollateralWithdrawn(address indexed user, address indexed token, uint256 amount, uint256 blockNumber);
    event Mint(address indexed user, uint256 amount, uint256 blockNumber);
    event Burn(address indexed user, uint256 amount, uint256 blockNumber);
    event Liquidate(address indexed user, address indexed beneficiary, uint256 amount, uint256 blockNumber);

    event UserDebtFactorIncrease(address indexed user, uint256 amount, uint256 blockNumber);
    event UserDebtFactorDecrease(address indexed user, uint256 amount, uint256 blockNumber);
    event TotalDebtUpdate(uint256 newTotalDebt, uint256 timestamp);

    event Pause();
    event Unpause();

    modifier onlyAddress(bytes32 id) {
        require(msg.sender == _addressRegistry.getAddress(id), "Contract mismatch");
        _;
    }

    /**
     * @notice modifier to allow only supported collateral to be deposited
     */
    modifier onlySupportedCollateral(address token) {
        require(_collateralAssetData[token].isEnabled, "Collateral: Token not supported");
        _;
    }

    /**
     * @notice modifier to allow only Debt Manager to add or remove debt
     * @dev {addToDebt} & {removeFromDebt} functions are used
     */
    modifier onlyDebtManager(address sender) {
        require(
            sender == _addressRegistry.getArableManager() ||
                sender == _addressRegistry.getArableFarming() ||
                sender == _addressRegistry.getArableExchange(),
            "not authorized"
        );
        _;
    }

    function initialize(address addressRegistry) external initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
        __ReentrancyGuard_init();
        __Pausable_init_unchained();

        setAddressRegistry(addressRegistry);
    }

    /**
     * @notice Triggers stopped state
     * @dev Only possible when contract not paused.
     */
    function pause() external onlyOwner whenNotPaused {
        _pause();
        emit Pause();
    }

    /**
     * @notice Returns to normal state
     * @dev Only possible when contract is paused.
     */
    function unpause() external onlyOwner whenPaused {
        _unpause();
        emit Unpause();
    }

    // ** EXTERNAL DEBT FUNCTIONS ** //
    function addToDebt(uint256 amount) external onlyDebtManager(msg.sender) returns (bool) {
        _totalDebt += amount;
        emit TotalDebtUpdate(_totalDebt, block.timestamp);
        return true;
    }

    function removeFromDebt(uint256 amount) external onlyDebtManager(msg.sender) returns (bool) {
        require(_totalDebt >= amount, "totalDebt should be bigger than amount");
        _totalDebt -= amount;
        emit TotalDebtUpdate(_totalDebt, block.timestamp);
        return true;
    }

    // ** COLLATERAL OPERATIONS ** //

    /**
     * @notice allows deposit of collateral by user
     *
     * @param token contract address of the token
     * @param amount amount of tokens to be deposited
     *
     * Emits a {CollateralDeposited} event.
     *
     * @return bool
     *
     * @dev amount in atomic units
     */
    function depositCollateral(address token, uint256 amount)
        external
        onlySupportedCollateral(token)
        nonReentrant
        returns (bool)
    {
        require(token != address(0), "Invalid token");
        require(!depositRestricted[token], "Deposit is restricted!");
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        _addCollateral(msg.sender, token, amount);
        IArableLiquidation liquidation = IArableLiquidation(_addressRegistry.getArableLiquidation());
        liquidation.removeFlagIfHealthy(msg.sender);
        return true;
    }

    /**
     * @notice allows withdrawal of collateral by user
     *
     * @param token contract address of the token
     * @param amount amount of tokens to be withdrawn
     *
     * Emits a {CollateralWithdrawn} event.
     *
     * @return bool
     *
     * @dev amount in atomic units
     */
    function withdrawCollateral(address token, uint256 amount)
        external
        onlySupportedCollateral(token)
        whenNotPaused
        nonReentrant
        returns (bool)
    {
        // Checks if user has previously deposited the collateral
        require(userCollateralBalance(msg.sender, token) >= amount, "Collateral: not enough tokens");

        require(
            maxWithdrawableTokenVal(msg.sender, token) >= calculateTokenValue(token, amount),
            "Collateral: not enough collateral"
        );

        _removeCollateral(msg.sender, token, amount);
        IERC20(token).safeTransfer(msg.sender, amount);
        return true;
    }

    /**
     * @notice external liquidation collateral that is called from liquidation
     * contract only
     *
     * @dev be careful with accessControl `onlyAddress`
     *
     *
     * @param user address of the user to be liquidated
     * @param beneficiary address of the liquidator
     * @param liqAmount amount to be liquidated in terms of collateral
     *
     * Emits a {Liquidate} event.
     * Emits a {CollateralDeposited} event.
     * Emits a {CollateralWithdrawn} event.
     *
     */

    function _liquidateCollateral(
        address user,
        address beneficiary,
        uint256 liqAmount
    ) external onlyAddress("ARABLE_LIQUIDATION") nonReentrant {
        // Get user balance
        uint256 userBalance_ = calculateCollateralValue(user);
        _removeDebtFromUser(user, currentDebt(user));
        emit Liquidate(user, beneficiary, liqAmount, block.number);

        // Calculate decimal collateralization rate
        uint256 collateralizationRate_ = (liqAmount * 1 ether) / userBalance_;

        // Check if collateral balance is bigger than liquidation amount
        // require(collateralizationRate_ <= 1 ether, "Can NOT liquidate more than what user has");
        // Note: this case happens when a user's debt * liquidationPenalty is bigger than collateral
        // - but for good protocol maintenance, these positions should be removed

        // Liquidate from all collaterals for proportional amounts
        for (uint256 i = 0; i < _supportedCollaterals.length; i++) {
            // Check if user has balance of that type of collateral
            address collateral = _supportedCollaterals[i];
            uint256 collateralBalance_ = userCollateralBalance(user, collateral);

            if (collateralBalance_ > 0) {
                // Calculate the proportional amount to be removed from user's collateral balance
                uint256 toBeRemoved_ = (collateralBalance_ * collateralizationRate_) / 1 ether;
                if (toBeRemoved_ > collateralBalance_) {
                    toBeRemoved_ = collateralBalance_;
                }

                // Remove from the user + add it to beneficiary
                _removeCollateral(user, _supportedCollaterals[i], toBeRemoved_);

                // withdraw collateral token after liquidation
                IERC20(collateral).safeTransfer(beneficiary, toBeRemoved_);
            }
        }
    }

    function getSupportedCollaterals() external view returns (address[] memory) {
        return _supportedCollaterals;
    }

    function getSupportedCollateralsWithStatus() external view returns (address[] memory, bool[] memory) {
        bool[] memory depositRestrictedStatus = new bool[](_supportedCollaterals.length);

        for (uint256 index = 0; index < _supportedCollaterals.length; index++) {
            depositRestrictedStatus[index] = depositRestricted[_supportedCollaterals[index]];
        }

        return (_supportedCollaterals, depositRestrictedStatus);
    }

    function getSupportedCollateralsCount() external view returns (uint256) {
        return _supportedCollaterals.length;
    }

    function getTotalDebt() external view returns (uint256) {
        return _totalDebt;
    }

    function setAddressRegistry(address newAddressRegistry) public onlyOwner {
        require(newAddressRegistry != address(0), "Invalid address");

        _addressRegistry = IArableAddressRegistry(newAddressRegistry);
    }

    // ** EXTERNAL ASSET FUNCTIONS ** //

    function setMintFee(uint256 _mintFee) public onlyOwner {
        mintFee = _mintFee;
    }

    function addSupportedCollateral(address token, uint256 allowedRate) public onlyOwner returns (bool) {
        require(_collateralAssetData[token].isEnabled == false, "collateral already supported");
        require(_collateralAssetData[token].index == 0, "collateral is already indexed");
        require(allowedRate >= 1 ether, "ratio should be more than 1");
        _collateralAssetData[token].isEnabled = true;
        _collateralAssetData[token].allowedRate = allowedRate;
        _collateralAssetData[token].index = _supportedCollaterals.length;
        _supportedCollaterals.push(token);
        emit SupportedCollateralAdded(token, allowedRate, _collateralAssetData[token].index, msg.sender, block.number);
        return true;
    }

    function removeSupportedCollateral(address token) public onlyOwner returns (bool) {
        require(_collateralAssetData[token].isEnabled == true, "collateral already disabled");
        address lastToken = _supportedCollaterals[_supportedCollaterals.length - 1];
        _collateralAssetData[lastToken].index = _collateralAssetData[token].index;
        _supportedCollaterals[_collateralAssetData[token].index] = lastToken;
        _supportedCollaterals.pop();
        emit SupportedCollateralRemoved(token, _collateralAssetData[token].index, msg.sender, block.number);
        _collateralAssetData[token].isEnabled = false;
        _collateralAssetData[token].index = 0;
        return true;
    }

    function restrictDeposits(address[] calldata tokens, bool restrict) external onlyOwner {
        for (uint256 index = 0; index < tokens.length; index++) {
            depositRestricted[tokens[index]] = restrict;
        }
    }

    function changeAllowedRate(address token, uint256 newAllowedRate) public onlyOwner returns (bool) {
        require(_collateralAssetData[token].isEnabled == true, "collateral not supported");
        require(newAllowedRate >= 1 ether, "ratio should not be less than 1");

        emit CollateralAllowedRateChanged(
            token,
            _collateralAssetData[token].allowedRate,
            newAllowedRate,
            _collateralAssetData[token].index,
            msg.sender,
            block.number
        );
        _collateralAssetData[token].allowedRate = newAllowedRate;
        return true;
    }

    /**
     * @notice function to return the user's risk rate
     * this function is used to calculate if user is flaggable or not
     *
     * @param user address of the user
     *
     * @return uint256 risk rate in decimals
     */
    function userRiskRate(address user) public view returns (uint256) {
        // maxDebt: 1 currDebt: 2    =>   rate: 200%
        // maxDebt: 1 currDebt: 1    =>   rate: 100%
        // maxDebt: 1 currDebt: 0.5  =>   rate: 50%
        // maxDebt: 0 currDebt: 0    =>   rate: 0%
        // maxDebt: 0 currDebt: 1    =>   rate: 10000% - force-liquidatable

        uint256 maxDebt = maxIssuableArUSD(user);
        uint256 currDebt = currentDebt(user);
        if (maxDebt == 0) {
            // Note: this could happen in following cases
            // 1) an asset is disabled for collateral
            // 2) collateral is fully liquidated
            // 3) user never added collateral
            if (currDebt == 0) {
                return 0;
            }
            return 100 ether; // 10000%
        }
        return (currDebt * 1 ether) / maxDebt;
    }

    /**
     * @notice calculates maximum issuable arUSD by the user
     *
     * @param user address of the user
     *
     * @return uint
     *
     * @dev could be gas optimized by checking whether if clause is
     * consuming too much gas or not
     */
    function maxIssuableArUSD(address user) public view returns (uint256) {
        uint256 maxIssuable = 0;

        // Loop through all supported collaterals
        for (uint256 i = 0; i < _supportedCollaterals.length; i++) {
            if (userCollateralBalance(user, _supportedCollaterals[i]) > 0) {
                uint256 allowedRate = _collateralAssetData[_supportedCollaterals[i]].allowedRate;
                if (allowedRate > 0) {
                    uint256 collateralValue = _calculateSingleCollateralValue(user, _supportedCollaterals[i]);
                    // Multiply by (10**18) to allow decimal calculation on `allowedRate`
                    maxIssuable += (collateralValue * 1 ether) / allowedRate;
                }
            }
        }
        return maxIssuable;
    }

    /**
     * @notice returns user's current debt in USD
     *
     * @param user user's wallet address
     *
     * @return uint debt amount
     */
    function currentDebt(address user) public view returns (uint256) {
        if (_totalDebtFactor == 0) {
            return 0;
        }
        return (_totalDebt * _debtFactor[user]) / _totalDebtFactor;
    }

    /**
     * @notice view function to return user's collateral value in USD
     *
     * @param user user's wallet
     *
     * @return uint collateral amount
     */
    function calculateCollateralValue(address user) public view returns (uint256) {
        uint256 calculatedValue_ = 0;
        for (uint256 i = 0; i < _supportedCollaterals.length; i++) {
            if (userCollateralBalance(user, _supportedCollaterals[i]) > 0) {
                calculatedValue_ += _calculateSingleCollateralValue(user, _supportedCollaterals[i]);
            }
        }
        return calculatedValue_;
    }

    /**
     * @notice function that returns user's individual collateral amount
     *
     * @param user address of the user
     * @param token contract address of the token to query
     *
     * @return uint amount of tokens collateralized
     */
    function userCollateralBalance(address user, address token) public view returns (uint256) {
        return _individualCollateral[user][token];
    }

    function maxWithdrawableTokenVal(address user, address token) public view returns (uint256) {
        uint256 maxDebt = maxIssuableArUSD(user);
        uint256 curDebt = currentDebt(user);
        if (maxDebt <= curDebt) {
            return 0;
        }
        return (_collateralAssetData[token].allowedRate * (maxDebt - curDebt)) / 1 ether;
    }

    function maxWithdrawableTokenAmount(address user, address token) public view returns (uint256) {
        IArableOracle oracle = IArableOracle(_addressRegistry.getArableOracle());
        uint256 tokenPrice = oracle.getPrice(token);
        if (tokenPrice == 0) {
            return 0;
        }
        uint256 userTokenDeposit = userCollateralBalance(user, token);

        // maxWithdrawableTokenVal is returning withdrawable token value in decimal 18.
        uint256 maxWithdrawable = (maxWithdrawableTokenVal(user, token) * 10**(IERC20Extented(token).decimals())) /
            tokenPrice;
        if (userTokenDeposit < maxWithdrawable) {
            return userTokenDeposit;
        }
        return maxWithdrawable;
    }

    // ** STAKE & MINT FUNCTIONS ** //

    /**
     * @notice mints requested amount of arUSD
     *
     * @param amount amount of arUSD to be minted
     *
     * Emits a {Mint} event.
     *
     * @return bool - to enable calls from other contracts
     */
    function mint(uint256 amount) public nonReentrant whenNotPaused returns (bool) {
        require(maxIssuableArUSD(msg.sender) >= currentDebt(msg.sender) + amount, "Not enough collateral");
        _addDebtFromUser(msg.sender, amount);
        emit Mint(msg.sender, amount, block.number);
        uint256 fee = amount * mintFee / 1 ether;
        uint256 amountWithoutFee = amount - fee;
        address feeCollectorAddress = IArableAddressRegistry(_addressRegistry).getArableFeeCollector();

        IArableSynth(IArableManager(_addressRegistry.getArableManager()).getSynthAddress(_arUSD)).mint(
            feeCollectorAddress,
            fee
        );
        IArableSynth(IArableManager(_addressRegistry.getArableManager()).getSynthAddress(_arUSD)).mint(
            msg.sender,
            amountWithoutFee
        );
        return true;
    }

    /**
     * @notice burns arUSD to free collateral & remove debt
     *
     * @param amount amount of arUSD to be burned
     *
     * @return bool - to enable calls from other contracts
     */
    function burn(address beneficiary, uint256 amount) public nonReentrant whenNotPaused returns (bool) {
        require(currentDebt(beneficiary) >= amount, "Can't burn more than debt");
        // burn tokens from msg.sender
        IArableSynth(IArableManager(_addressRegistry.getArableManager()).getSynthAddress(_arUSD)).burnFrom(
            msg.sender,
            amount
        );
        // remove debt from beneficiary
        _removeDebtFromUser(beneficiary, amount);
        emit Burn(msg.sender, amount, block.number);

        IArableLiquidation liquidation = IArableLiquidation(_addressRegistry.getArableLiquidation());
        liquidation.removeFlagIfHealthy(msg.sender);
        return true;
    }

    function removeTotalDebtByBurn(uint256 amount) external returns (bool) {
        require(_totalDebt >= amount, "totalDebt should be bigger than amount");

        // burn tokens from msg.sender
        IArableSynth(IArableManager(_addressRegistry.getArableManager()).getSynthAddress(_arUSD)).burnFrom(
            msg.sender,
            amount
        );

        _totalDebt -= amount;
        emit TotalDebtUpdate(_totalDebt, block.timestamp);
        return true;
    }

    /**
     * @notice view function to calculate debt factor with given amount
     *
     * @param amount amount of arUSD
     *
     * @return uint returns the debt factor
     */
    function calculateDebtFactor(uint256 amount) public view returns (uint256) {
        if (_totalDebtFactor == 0 || _totalDebt == 0) {
            return amount;
        }
        return (_totalDebtFactor * amount) / _totalDebt;
    }

    /**
     * @notice internal function to increment user's collateral amount
     *
     * @param user address of the user
     * @param token address of the token contract
     * @param amount amount of tokens
     */
    function _addCollateral(
        address user,
        address token,
        uint256 amount
    ) internal {
        _individualCollateral[user][token] += amount;
        emit CollateralDeposited(user, token, amount, block.number);
    }

    /**
     * @notice internal function to decrement user's collateral amount
     *
     * @param user address of the user
     * @param token address of the token contract
     * @param amount amount of tokens
     */
    function _removeCollateral(
        address user,
        address token,
        uint256 amount
    ) internal {
        require(_individualCollateral[user][token] >= amount, "user token collateral should be bigger than amount");
        _individualCollateral[user][token] -= amount;
        emit CollateralWithdrawn(user, token, amount, block.number);
    }

    /**
     * @notice calculates single collateral value in USD
     *
     * @dev divide by (10**18) because of decimal calculation
     *
     * @param user address of the user
     * @param token contract address of the token
     *
     * @return uint value in USD
     */
    function _calculateSingleCollateralValue(address user, address token) internal view returns (uint256) {
        IArableOracle oracle = IArableOracle(_addressRegistry.getArableOracle());
        uint256 tokenPrice = oracle.getPrice(token);

        // convert to normalized collateral balance with 18 decimals and return usd value
        uint256 decimals = IERC20Extented(token).decimals();
        uint256 normalizedCollateralBalance = (userCollateralBalance(user, token) * 1 ether) / (10**decimals);
        return (normalizedCollateralBalance * tokenPrice) / 1 ether;
    }

    function calculateTokenValue(address token, uint256 amount) internal view returns (uint256) {
        IArableOracle oracle = IArableOracle(_addressRegistry.getArableOracle());
        uint256 tokenPrice = oracle.getPrice(token);
        return (amount * tokenPrice) / 10**(IERC20Extented(token).decimals());
    }

    /**
     * @notice internal function to increment user's and total debt
     *
     * @dev if collateral contract's address is added as debt manager
     * to the address registery, total debt increment function could be used
     * instead of _totalDebt += amount
     *
     * @param user address of the user
     * @param amount amount of arUSD to be added as debt
     */
    function _addDebtFromUser(address user, uint256 amount) internal {
        _incrementDebtRate(user, calculateDebtFactor(amount));
        _totalDebt += amount;
        emit TotalDebtUpdate(_totalDebt, block.timestamp);
    }

    /**
     * @notice internal function to decrease user's and total debt
     *
     * @dev if collateral contract's address is added as debt manager
     * to the address registery, total debt decrease function could be used
     * instead of _totalDebt -= amount
     *
     * @param user address of the user
     * @param amount amount of arUSD to be removed from debt
     */
    function _removeDebtFromUser(address user, uint256 amount) internal {
        _decrementDebtRate(user, calculateDebtFactor(amount));
        require(_totalDebt >= amount, "totalDebt should be bigger than amount");
        _totalDebt -= amount;
        emit TotalDebtUpdate(_totalDebt, block.timestamp);
    }

    /**
     * @notice internal function to increment debt rate
     *
     * @param user address of the user
     * @param amount calculated debt factor
     */
    function _incrementDebtRate(address user, uint256 amount) internal {
        _debtFactor[user] += amount;
        _totalDebtFactor += amount;
        emit UserDebtFactorIncrease(user, amount, block.number);
    }

    /**
     * @notice internal function to decrement debt rate
     *
     * @param user address of the user
     * @param amount calculated debt factor
     */
    function _decrementDebtRate(address user, uint256 amount) internal {
        _debtFactor[user] -= amount;
        _totalDebtFactor -= amount;
        emit UserDebtFactorDecrease(user, amount, block.number);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: GNU-GPL v3.0 or later

pragma solidity ^0.8.0;

/**
 * @title Provider interface for Arable
 * @dev
 */
interface IArableAddressRegistry {
    function getAddress(bytes32 id) external view returns (address);

    function setAddress(bytes32 id, address address_) external;

    function getArableOracle() external view returns (address);

    function setArableOracle(address arableOracle_) external;

    function getArableExchange() external view returns (address);

    function setArableExchange(address arableExchange_) external;

    function getArableManager() external view returns (address);

    function setArableManager(address arableManager_) external;

    function getArableFarming() external view returns (address);

    function setArableFarming(address arableFarming_) external;

    function getArableCollateral() external view returns (address);

    function setArableCollateral(address arableCollateral_) external;

    function getArableLiquidation() external view returns (address);

    function setArableLiquidation(address arableLiquidation_) external;

    function getArableFeeCollector() external view returns (address);

    function setArableFeeCollector(address arableFeeCollector_) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IArableOracle {
    function getPrice(address token) external view returns (uint256);
    function getDailyRewardRate(uint256 farmId, address rewardToken) external view returns (uint256);
    function registerPrice(address token_, uint256 price_) external;
    function registerRewardRate(
        uint256 farmId_,
        address token_,
        uint256 dailyRewardRate_
    ) external;
    function isAllowedProvider(address provider) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IArableLiquidation {
    function isFlaggable(address user) external view returns (bool);
    function isFlagged(address user) external view returns (bool);
    function userRiskRate(address user) external view returns (uint);
    function flagForLiquidation(address user) external returns (uint);
    function removeFlagIfHealthy(address user) external;
    function liquidate(address user) external;
    function setAddressRegistry(address newAddressRegistry) external ;
    function setLiquidationRate(uint newRate) external ;
    function setImmediateLiquidationRate(uint newRate) external;
    function setLiquidationDelay(uint newDelay) external;
    function setLiquidationPenalty(uint newPenalty) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IArableManager {
    function isSynth(address _token) external view returns (bool);
    function isSynthDisabled(address _token) external view returns (bool);
    function isEnabledSynth(address _token) external view returns (bool);
    function getSynthAddress(string memory tokenSymbol) external view returns (address);
    function onAssetPriceChange(address asset, uint256 oldPrice, uint256 newPrice) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IArableSynth is IERC20 {
    function mint(address toAddress, uint256 amount) external;

    function burn(uint256 amount) external;

    function burnFrom(address account, uint256 amount) external;

    function safeMint(address toAddress, uint256 amount) external returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20Extented is IERC20 {
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}