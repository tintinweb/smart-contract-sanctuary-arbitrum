// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IVault } from "./interfaces/IVault.sol";
import { IPositionRegistry } from "./interfaces/IPositionRegistry.sol";
import { IMarketManager } from "./interfaces/manage/IMarketManager.sol";
import { IDexWrapper } from "./interfaces/IDexWrapper.sol";
import { AdminAbstract, IAdminStructure } from "./abstract/AdminAbstract.sol";
import { AbsoluteMath } from "src/libraries/AbsoluteMath.sol";
import { Errors } from "./libraries/Errors.sol";
import { IWETH } from "./interfaces/IWETH.sol";
import { IOracle } from "./interfaces/IOracle.sol";
import { IERC20 } from "openzeppelin-contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "openzeppelin-contracts/token/ERC20/utils/SafeERC20.sol";
import { PausableUpgradeable } from "openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";

contract Vault is IVault, PausableUpgradeable, AdminAbstract {
    using SafeERC20 for IERC20;
    using AbsoluteMath for int256;

    mapping(address => mapping(address => uint256)) private deposits;
    mapping(address => mapping(address => uint256)) private depositLocked;
    mapping(address => bool) private allowedTokens;
    mapping(address => uint8) private allowedTokensListIndex;
    mapping(address => uint256) private liquidated;

    IMarketManager private marketManager;
    IPositionRegistry private positionRegistry;
    IDexWrapper private dexWrapper;
    IOracle private usdcEthOracle;
    IOracle private eEthEthOracle;

    address private swapRouter;
    address private lrtToken;
    address private manager;
    address private weth;

    address[] private allowedTokensList;

    uint8 public withdrawFee = 100; // 1%

    uint256 public withdrawNonce = 0;

    /// @notice check non-zero address
    modifier nonZeroAddress(address _address) {
        if (_address == address(0)) revert Errors.AddressZero();
        _;
    }

    modifier onlyPositionRegistry() {
        if (msg.sender != address(positionRegistry)) revert Errors.NotPositionRegistry();
        _;
    }

    modifier onlyOrderBook() {
        if (!marketManager.isOpenMarket(msg.sender)) revert Errors.NotOrderBook();
        _;
    }

    modifier onlyManager() {
        if (msg.sender != manager) revert Errors.NotManager();
        _;
    }

    constructor() {
        _disableInitializers();
    }

    function initialize(
        address _adminStructureAddress,
        address _marketManagerAddress,
        address _collateral,
        address _swapRouter,
        //address _dexWrapper,
        address _lrtToken,
        address _manager,
        address _weth,
        // address _eEthEthOracle,
        // address _usdcEthOracle,
        uint8 _withdrawFee
    ) external initializer {
        if (_collateral == address(0)) revert Errors.AddressZero();

        _setAdminStructure(_adminStructureAddress);
        _setMarketManager(_marketManagerAddress);
        // _setEEthEthOracle(_eEthEthOracle);
        // _setUsdcEthOracle(_usdcEthOracle);
        _setSwapRouter(_swapRouter);
        //_setDexWrapper(_dexWrapper);
        _setLRTToken(_lrtToken);
        _setManager(_manager);
        _setWETH(_weth);

        _setAllowedToken(_collateral, true);
        withdrawFee = _withdrawFee;
    }

    function setAllowedToken(address _tokenAddress, bool _allowed)
        external
        override
        onlyAdmin
        nonZeroAddress(_tokenAddress)
    {
        _setAllowedToken(_tokenAddress, _allowed);
    }

    function setWETH(address _weth) external onlyAdmin {
        _setWETH(_weth);
    }

    function setManager(address _manager) external onlyAdmin {
        _setManager(_manager);
    }

    function setLRTToken(address _lrtToken) external onlyAdmin {
        _setLRTToken(_lrtToken);
    }

    function setDexWrapper(address _dexWrapper) external onlyAdmin {
        _setDexWrapper(_dexWrapper);
    }

    function setSwapRouter(address _swapRouter) external onlyAdmin {
        _setSwapRouter(_swapRouter);
    }

    function setLRTEthOracle(address _eEthEthOracle) external override onlyAdmin {
        _setLRTEthOracle(_eEthEthOracle);
    }

    function setUsdcEthOracle(address _usdcEthOracle) external override onlyAdmin {
        _setUsdcEthOracle(_usdcEthOracle);
    }

    function setMarketManager(address _marketManager) external override onlyAdmin {
        _setMarketManager(_marketManager);
    }

    function setPositionRegistry(address _positionRegistry) external override onlyAdmin {
        _setPositionRegistry(_positionRegistry);
    }

    function emergencyPause() external whenNotPaused onlyAdmin {
        _pause();
    }

    function emergencyUnpause() external whenPaused onlyAdmin {
        _unpause();
    }

    function isAllowedToken(address _tokenAddress) external view returns (bool) {
        return allowedTokens[_tokenAddress];
    }

    function getDeposit(address _user, address _tokenAddress) external view returns (uint256) {
        return deposits[_user][_tokenAddress];
    }

    function getDepositLocked(address _user, address _tokenAddress) external view returns (uint256) {
        return depositLocked[_user][_tokenAddress];
    }

    function getWETH() external view returns (address) {
        return weth;
    }

    function getManager() external view returns (address) {
        return manager;
    }

    function getEEthEthOracle() external view returns (address) {
        return address(eEthEthOracle);
    }

    function getUsdcEthOracle() external view returns (address) {
        return address(usdcEthOracle);
    }

    function getlrtToken() external view returns (address) {
        return lrtToken;
    }

    function getDexWrapper() external view returns (IDexWrapper) {
        return dexWrapper;
    }

    function getSwapRouter() external view returns (address) {
        return swapRouter;
    }

    function getMarketManager() external view returns (address) {
        return address(marketManager);
    }

    function getPositionRegistry() external view returns (address) {
        return address(positionRegistry);
    }

    function getAllAllowedTokens() external view returns (address[] memory) {
        return allowedTokensList;
    }

    function deposit(Deposit calldata data) external payable override {
        _deposit(msg.sender, data);
    }

    function withdraw(Withdraw calldata data) external override {
        _withdraw(msg.sender, data);
    }

    function depositTo(address _receiver, Deposit calldata data) external payable override nonZeroAddress(_receiver) {
        _deposit(_receiver, data);
    }

    function lockMargin(address _orderBookAddress, address _user, uint256 _margin) external onlyPositionRegistry {
        address _tokenAddress = marketManager.getCollateral(_orderBookAddress);
        if (_margin > deposits[_user][_tokenAddress] - depositLocked[_user][_tokenAddress]) {
            revert Errors.InvalidSize();
        }

        depositLocked[_user][_tokenAddress] += _margin;

        emit LockedMargin(_user, _tokenAddress, _margin, block.timestamp);
    }

    function unlockMargin(address _orderBookAddress, address _user, uint256 _margin) external onlyPositionRegistry {
        address _tokenAddress = marketManager.getCollateral(_orderBookAddress);

        _unlockMargin(_user, _tokenAddress, _margin);
    }

    function cutFee(address _orderBookAddress, address _user, uint256 _fee, address _feeWallet)
        external
        onlyPositionRegistry
    {
        address _tokenAddress = marketManager.getCollateral(_orderBookAddress);

        _unlockMargin(_user, _tokenAddress, _fee);
        deposits[_user][_tokenAddress] -= _fee;

        IERC20(_tokenAddress).safeTransfer(_feeWallet, _fee);
    }

    function realizePNL(address _orderBookAddress, address _user, int256 _pnl, uint256 _margin)
        external
        onlyPositionRegistry
    {
        if (_pnl == 0) revert Errors.ZeroPNL();

        address _tokenAddress = marketManager.getCollateral(_orderBookAddress);

        if (liquidated[_user] > 0) {
            deposits[_user][_tokenAddress] = uint256(int256(deposits[_user][_tokenAddress]) + _pnl);
        } else {
            uint256 _priceUsdcInEth = uint256(usdcEthOracle.latestAnswer()); // price usdc in eth
            uint256 _priceEEthInEth = uint256(eEthEthOracle.latestAnswer()); // price eETH in eth
            uint256 _priceEthInUsdc = (1e18 * 1e18) / _priceUsdcInEth;
            uint256 _priceEETHInUsdc = (_priceEEthInEth * _priceEthInUsdc) / 1e18;
            if (_pnl < 0) {
                int256 _pnlInEEth = -int256(_pnl.abs() * 1e18 / _priceEETHInUsdc);
                deposits[_user][lrtToken] = uint256(int256(deposits[_user][lrtToken]) + (_pnlInEEth));
            } else {
                uint256 _pnlInEEth = uint256(_pnl) * 1e18 / _priceEETHInUsdc;
                deposits[_user][lrtToken] = deposits[_user][lrtToken] + (_pnlInEEth);
            }
        }

        _unlockMargin(_user, _tokenAddress, _margin);
        emit RealizedPNL(_user, _tokenAddress, _pnl, block.timestamp);
    }

    function liquidateCollateral(
        address _user,
        address _orderBookAddress,
        uint256 _minAmount,
        IDexWrapper.route[] calldata _routes
    ) external onlyManager {
        address _tokenAddress = marketManager.getCollateral(_orderBookAddress);
        uint256[] memory received = _swap(deposits[_user][lrtToken], _minAmount, _routes);

        deposits[_user][_tokenAddress] += received[_routes.length];
        liquidated[_user] += received[_routes.length];
    }

    function _unlockMargin(address _user, address _tokenAddress, uint256 _margin) private {
        depositLocked[_user][_tokenAddress] -= _margin;

        if (liquidated[_user] > 0) {
            IDexWrapper.route[] memory _routes = new IDexWrapper.route[](1);
            _routes[0] = IDexWrapper.route(_tokenAddress, lrtToken, true);

            uint256[] memory received = _swap(liquidated[_user], 0, _routes);
            deposits[_user][lrtToken] += received[0];
            liquidated[_user] = 0;
        }

        emit UnlockedMargin(_user, _tokenAddress, _margin, block.timestamp);
    }

    /// @notice The function to call deposit
    function _deposit(address receiver, Deposit calldata data) private whenNotPaused {
        _validateDeposit(data);

        uint256[] memory _received;

        if (data.tokenAddress == address(0)) {
            IWETH(weth).deposit{ value: data.tokenAmount }();
            IERC20(weth).safeIncreaseAllowance(address(dexWrapper), data.tokenAmount);

            // data.tokenAddress, lrtToken
            _received = _swap(data.tokenAmount, data.minAmount, data.routes);

            deposits[receiver][lrtToken] += _received[data.routes.length];

            emit UserDeposit(receiver, lrtToken, _received[data.routes.length], block.timestamp);

            return;
        } else if (data.tokenAddress != lrtToken) {
            IERC20(data.tokenAddress).safeIncreaseAllowance(address(dexWrapper), data.tokenAmount);

            // data.tokenAddress, lrtToken
            _received = _swap(data.tokenAmount, data.minAmount, data.routes);

            deposits[receiver][lrtToken] += _received[data.routes.length];

            emit UserDeposit(receiver, lrtToken, _received[data.routes.length], block.timestamp);

            return;
        }

        deposits[receiver][lrtToken] += data.tokenAmount;

        IERC20(data.tokenAddress).safeTransferFrom(msg.sender, address(this), data.tokenAmount);

        emit UserDeposit(receiver, lrtToken, data.tokenAmount, block.timestamp);
    }

    function _swap(uint256 _tokenAmount, uint256 _minAmount, IDexWrapper.route[] memory routes)
        private
        returns (uint256[] memory)
    {
        return dexWrapper.swapAny(
            swapRouter,
            _tokenAmount,
            _minAmount == 0 ? dexWrapper.getAmountsOut(swapRouter, _tokenAmount, routes)[routes.length] : _minAmount,
            routes
        );
    }

    function _withdraw(address user, Withdraw calldata data) private whenNotPaused {
        _validateWithdraw(user, data);

        address feeReceiver = adminStructure.admin();
        deposits[user][lrtToken] -= data.tokenAmount;

        uint256 fee = (data.tokenAmount * withdrawFee) / 10000;
        IERC20(lrtToken).safeTransfer(feeReceiver, fee);

        uint256 withdrawAmountAfterFee = data.tokenAmount - fee;
        uint256[] memory withdrawn;

        if (data.tokenTo != lrtToken) {
            withdrawn = _swap(withdrawAmountAfterFee, data.minAmount, data.routes);
            IERC20(data.tokenTo).safeTransfer(data.receiver, withdrawn[data.routes.length]);
        } else {
            IERC20(data.tokenTo).safeTransfer(data.receiver, withdrawAmountAfterFee);
        }

        emit UserWithdhraw(
            user,
            lrtToken,
            data.tokenTo,
            data.tokenTo != lrtToken ? withdrawn[data.routes.length] : withdrawAmountAfterFee,
            data.tokenTo,
            fee,
            feeReceiver,
            block.timestamp
        );
    }

    /// @notice The function to validate deposit data
    function _validateDeposit(Deposit calldata data) private view {
        // check if tokenAddress is allowed
        if (!allowedTokens[data.tokenAddress]) revert Errors.TokenNotAllowed(data.tokenAddress);
        // check if tokenAmount > 0
        if (data.tokenAmount == 0 || (msg.value == 0 && data.tokenAddress == address(0))) revert Errors.ZeroDeposit();

        if (msg.value > 0) {
            // check if tokenAddress is ETH
            if (data.tokenAddress != address(0)) revert Errors.WrongAddress();
            // check if tokenAmount == msg.value
            if (data.tokenAmount != msg.value) revert Errors.InvalidTokenAmount();
        }
    }

    /// @notice The function to validate withdraw data
    function _validateWithdraw(address user, Withdraw calldata data) private view {
        // check if tokenFrom is allowed
        if (!allowedTokens[lrtToken]) revert Errors.TokenNotAllowed(lrtToken);
        // check if tokenTo is allowed
        if (!allowedTokens[data.tokenTo]) revert Errors.TokenNotAllowed(data.tokenTo);

        // check if tokenAmount > 0
        if (data.tokenAmount == 0) revert Errors.ZeroWithdraw();

        uint256 _userBalance = deposits[user][lrtToken];

        // check if tokenAmount < balance
        if (data.tokenAmount > _userBalance) revert Errors.NotEnoughBalanceToWithdraw();
        // check if tokenAmount <= deposit - depositLocked
        if (data.tokenAmount > _userBalance - depositLocked[user][lrtToken]) {
            revert Errors.DepositLocked();
        }
    }

    function _setWETH(address _weth) private nonZeroAddress(_weth) {
        if (_weth == address(weth)) revert Errors.NothingToChange();
        weth = _weth;
    }

    function _setManager(address _manager) private nonZeroAddress(_manager) {
        if (_manager == address(manager)) revert Errors.NothingToChange();
        manager = _manager;
    }

    function _setLRTToken(address _lrtToken) private nonZeroAddress(_lrtToken) {
        if (_lrtToken == address(lrtToken)) revert Errors.NothingToChange();
        lrtToken = _lrtToken;
    }

    function _setDexWrapper(address _dexWrapper) private nonZeroAddress(_dexWrapper) {
        if (_dexWrapper == address(dexWrapper)) revert Errors.NothingToChange();
        dexWrapper = IDexWrapper(_dexWrapper);
    }

    function _setSwapRouter(address _swapRouter) private nonZeroAddress(_swapRouter) {
        if (_swapRouter == address(swapRouter)) revert Errors.NothingToChange();
        swapRouter = _swapRouter;
    }

    function _setLRTEthOracle(address _eEthEthOracle) private nonZeroAddress(_eEthEthOracle) {
        if (_eEthEthOracle == address(eEthEthOracle)) revert Errors.NothingToChange();
        eEthEthOracle = IOracle(_eEthEthOracle);
    }

    function _setUsdcEthOracle(address _usdcEthOracle) private nonZeroAddress(_usdcEthOracle) {
        if (_usdcEthOracle == address(usdcEthOracle)) revert Errors.NothingToChange();
        usdcEthOracle = IOracle(_usdcEthOracle);
    }

    function _setMarketManager(address _marketManager) private nonZeroAddress(_marketManager) {
        if (_marketManager == address(marketManager)) revert Errors.NothingToChange();
        marketManager = IMarketManager(_marketManager);
    }

    function _setPositionRegistry(address _positionRegistry) private nonZeroAddress(_positionRegistry) {
        if (_positionRegistry == address(positionRegistry)) revert Errors.NothingToChange();
        positionRegistry = IPositionRegistry(_positionRegistry);
    }

    function _setAllowedToken(address _tokenAddress, bool _allowed) private {
        if ((allowedTokens[_tokenAddress] && _allowed) || (!allowedTokens[_tokenAddress] && !_allowed)) {
            revert Errors.NothingToChange();
        }

        allowedTokens[_tokenAddress] = _allowed;

        if (_allowed) {
            allowedTokensListIndex[_tokenAddress] = uint8(allowedTokensList.length);
            allowedTokensList.push(_tokenAddress);
        } else {
            if (allowedTokensList.length > 1) {
                allowedTokensList[allowedTokensListIndex[_tokenAddress]] =
                    allowedTokensList[allowedTokensList.length - 1];
            }

            allowedTokensList.pop();
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { IDexWrapper } from "./IDexWrapper.sol";

interface IVault {
    struct Deposit {
        uint256 tokenAmount;
        uint256 minAmount;
        address tokenAddress;
        IDexWrapper.route[] routes;
    }

    struct Withdraw {
        uint256 tokenAmount;
        uint256 minAmount;
        address tokenTo;
        address receiver;
        IDexWrapper.route[] routes;
    }

    event SetAllowedToken(address indexed _tokenAddress, bool _allowed);
    event RealizedPNL(address indexed _user, address tokenAddress, int256 _pnl, uint256 timestamp);
    event LockedMargin(address indexed _user, address tokenAddress, uint256 margin, uint256 timestamp);
    event UnlockedMargin(address indexed _user, address tokenAddress, uint256 margin, uint256 timestamp);
    event UserDeposit(address indexed userAddress, address tokenAddress, uint256 tokenAmount, uint256 timestamp);
    event UserWithdhraw(
        address indexed receiver,
        address tokenFrom,
        address tokenTo,
        uint256 tokenAmount,
        address feePayedIn,
        uint256 fee,
        address feeReceiver,
        uint256 timestamp
    );

    function lockMargin(address _orderBookAddress, address _user, uint256 _margin) external;
    function unlockMargin(address _orderBookAddress, address _user, uint256 _margin) external;
    function realizePNL(address _orderBookAddress, address _user, int256 _pnl, uint256 _margin) external;
    function deposit(Deposit calldata data) external payable;
    function depositTo(address _receiver, Deposit calldata data) external payable;
    function withdraw(Withdraw calldata data) external;
    function cutFee(address _orderBookAddress, address _user, uint256 _fee, address _feeWallet) external;

    function emergencyPause() external;
    function emergencyUnpause() external;
    function setPositionRegistry(address _positionRegistery) external;
    function setMarketManager(address _marketManager) external;
    function setLRTEthOracle(address _lrtEthOracle) external;
    function setUsdcEthOracle(address _usdcEthOracle) external;
    function setManager(address _manager) external;
    function setAllowedToken(address _tokenAddress, bool _allowed) external;
    function isAllowedToken(address _tokenAddress) external view returns (bool);
    function getEEthEthOracle() external view returns (address);
    function getUsdcEthOracle() external view returns (address);
    function getAllAllowedTokens() external view returns (address[] memory);
    function getPositionRegistry() external view returns (address);
    function getMarketManager() external view returns (address);
    function getManager() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

interface IPositionRegistry {
    struct Position {
        address orderBookAddress;
        address user;
        int256 quantity;
        uint256 entryPrice;
        uint256 liqPrice;
        uint256 margin;
        int256 pnl;
        bool open;
    }

    event PositionOpened(
        address indexed _orderBookAddress, address indexed _user, int256 _quantity, uint256 indexed _margin
    );
    event PositionUpdated(
        address indexed _orderBookAddress, address indexed _user, int256 _quantity, uint256 indexed _margin
    );
    event PositionClosed(address indexed _orderBookAddress, address indexed _user, uint256 indexed _margin);
    event MarketManagerSet(address _marketManagerAddress);
    event FeeManagerSet(address _feeManager);
    event VaultSet(address _vaultAddress);

    function lockCollateral(address _user, uint256 _margin) external;

    function unlockCollateral(address _user, uint256 _margin) external;

    function matchPosition(address _user, int256 _quantity) external returns (uint256 _matchedQuantity);

    function makePosition(address _user, int256 _quantity, uint256 _margin) external;

    function positionQuantity(address _orderBookAddress, address _user) external view returns (int256 _quantity);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

interface IMarketManager {
    struct Market {
        address orderBookAddress;
        address collateral;
        address underlying;
        bool isOpen;
        uint256 maxLeverage;
    }

    event MarketOpened(address _collateral, address _underlying);
    event MarketClosed(address _collateral, address _underlying);
    event OrderManagerSet(address _orderManagerAddress);
    event PositionRegistrySet(address _positionRegistryAddress);
    event MaxLeverageSet(address _orderBookAddress, uint256 _maxLeverage);

    function getCollateral(address _orderBookAddress) external view returns (address _collateral);

    function isOpenMarket(address _orderBookAddress) external view returns (bool);

    function getMaxLeverage(address _orderBookAddress) external view returns (uint256 _maxLeverage);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

interface IDexWrapper {
    struct route {
        address from;
        address to;
        bool stable;
    }

    function swapAny(address router, uint256 amountIn, uint256 amountOutMin, route[] calldata routes)
        external
        payable
        returns (uint256[] memory amounts);

    function getAmountsOut(address router, uint256 amountIn, route[] calldata routes)
        external
        view
        returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import "src/interfaces/admin/IAdminStructure.sol";

import "src/libraries/Errors.sol";

abstract contract AdminAbstract {
    IAdminStructure internal adminStructure;

    event AdminStructureSet(address _adminStructureAddress);

    modifier onlySuperAdmin() {
        if (msg.sender != IAdminStructure(adminStructure).superAdmin()) revert Errors.NotSuperAdmin();
        _;
    }

    modifier onlyAdmin() {
        if (msg.sender != IAdminStructure(adminStructure).admin()) revert Errors.NotAdmin();
        _;
    }

    // SETTINGS

    function setAdminStructure(address _adminStructureAddress) external onlySuperAdmin {
        _setAdminStructure(_adminStructureAddress);

        emit AdminStructureSet(_adminStructureAddress);
    }

    function _setAdminStructure(address _adminStructureAddress) internal {
        if (_adminStructureAddress == address(0)) revert Errors.WrongAddress();

        adminStructure = IAdminStructure(_adminStructureAddress);
    }

    // GETTERS

    function getAdminStructure() external view returns (address _adminStructureAddress) {
        return address(adminStructure);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

library AbsoluteMath {
    function abs(int256 x) internal pure returns (uint256) {
        return x >= 0 ? uint256(x) : uint256(-x);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

library Errors {
    // Global
    error WrongAddress();
    error NotOrderBook();
    error NotPositionRegistry();

    // AdminStructure
    error NotSuperAdmin();
    error NotAdmin();

    // MarketManager
    error AlreadyOpened();
    error AlreadyClosed();
    error MaxLeverageTooHigh();

    // OrderBook
    error NotOpened();
    error ZeroMargin();
    error WrongLeverage();
    error HasOppositeOrder();
    error IsClosingOrder();
    error PriceIsZero();
    error TooManyOrders();
    error WrongOrder();

    // PositionRegistry
    error WrongPosition();
    error PositionClosed();
    error WrongQuantity();

    // Vault
    error TokenNotAllowed(address _token);
    error NothingToChange();
    error AddressZero();
    error ZeroDeposit();
    error ZeroWithdraw();
    error DepositLocked();
    error NotEnoughBalanceToWithdraw();
    error ZeroPNL();
    error InvalidSize();
    error InvalidTokenAmount();
    error InvalidSignature();
    error NotManager();

    // Fee
    error WrongFee();
}

pragma solidity 0.8.20;

interface IWETH {
    function deposit() external payable;
    function withdraw(uint256) external;
    function balanceOf(address owner) external view returns (uint256);
    function approve(address spender, uint256 value) external returns (bool);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.20;

interface IOracle {
    /**
     * @notice Returns the latest answer.
     * @return _answer The latest answer.
     */
    function latestAnswer() external view returns (int256 _answer);

    /**
     * @notice Returns the data from the latest round.
     * @return _roundId The round ID.
     * @return _answer The answer from the latest round.
     * @return _startedAt Timestamp of when the round started.
     * @return _updatedAt Timestamp of when the round was updated.
     * @return _answeredInRound Deprecated. Previously used when answers could take multiple rounds to be computed.
     */
    function latestRoundData()
        external
        view
        returns (uint80 _roundId, int256 _answer, uint256 _startedAt, uint256 _updatedAt, uint80 _answeredInRound);

    /**
     * @notice Returns the number of decimals in the answer.
     * @return The number of decimals in the answer.
     */
    function decimals() external pure returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.20;

/**
 * @dev Interface of the ERC-20 standard as defined in the ERC.
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

    /**
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
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
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.20;

import {IERC20} from "../IERC20.sol";
import {IERC1363} from "../../../interfaces/IERC1363.sol";
import {Address} from "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC-20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    /**
     * @dev An operation with an ERC-20 token failed.
     */
    error SafeERC20FailedOperation(address token);

    /**
     * @dev Indicates a failed `decreaseAllowance` request.
     */
    error SafeERC20FailedDecreaseAllowance(address spender, uint256 currentAllowance, uint256 requestedDecrease);

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeCall(token.transfer, (to, value)));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeCall(token.transferFrom, (from, to, value)));
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        forceApprove(token, spender, oldAllowance + value);
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `requestedDecrease`. If `token` returns no
     * value, non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 requestedDecrease) internal {
        unchecked {
            uint256 currentAllowance = token.allowance(address(this), spender);
            if (currentAllowance < requestedDecrease) {
                revert SafeERC20FailedDecreaseAllowance(spender, currentAllowance, requestedDecrease);
            }
            forceApprove(token, spender, currentAllowance - requestedDecrease);
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Meant to be used with tokens that require the approval
     * to be set to zero before setting it to a non-zero value, such as USDT.
     */
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeCall(token.approve, (spender, value));

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeCall(token.approve, (spender, 0)));
            _callOptionalReturn(token, approvalCall);
        }
    }

    /**
     * @dev Performs an {ERC1363} transferAndCall, with a fallback to the simple {ERC20} transfer if the target has no
     * code. This can be used to implement an {ERC721}-like safe transfer that rely on {ERC1363} checks when
     * targeting contracts.
     *
     * Reverts if the returned value is other than `true`.
     */
    function transferAndCallRelaxed(IERC1363 token, address to, uint256 value, bytes memory data) internal {
        if (to.code.length == 0) {
            safeTransfer(token, to, value);
        } else if (!token.transferAndCall(to, value, data)) {
            revert SafeERC20FailedOperation(address(token));
        }
    }

    /**
     * @dev Performs an {ERC1363} transferFromAndCall, with a fallback to the simple {ERC20} transferFrom if the target
     * has no code. This can be used to implement an {ERC721}-like safe transfer that rely on {ERC1363} checks when
     * targeting contracts.
     *
     * Reverts if the returned value is other than `true`.
     */
    function transferFromAndCallRelaxed(
        IERC1363 token,
        address from,
        address to,
        uint256 value,
        bytes memory data
    ) internal {
        if (to.code.length == 0) {
            safeTransferFrom(token, from, to, value);
        } else if (!token.transferFromAndCall(from, to, value, data)) {
            revert SafeERC20FailedOperation(address(token));
        }
    }

    /**
     * @dev Performs an {ERC1363} approveAndCall, with a fallback to the simple {ERC20} approve if the target has no
     * code. This can be used to implement an {ERC721}-like safe transfer that rely on {ERC1363} checks when
     * targeting contracts.
     *
     * NOTE: When the recipient address (`to`) has no code (i.e. is an EOA), this function behaves as {forceApprove}.
     * Opposedly, when the recipient address (`to`) has code, this function only attempts to call {ERC1363-approveAndCall}
     * once without retrying, and relies on the returned value to be true.
     *
     * Reverts if the returned value is other than `true`.
     */
    function approveAndCallRelaxed(IERC1363 token, address to, uint256 value, bytes memory data) internal {
        if (to.code.length == 0) {
            forceApprove(token, to, value);
        } else if (!token.approveAndCall(to, value, data)) {
            revert SafeERC20FailedOperation(address(token));
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
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data);
        if (returndata.length != 0 && !abi.decode(returndata, (bool))) {
            revert SafeERC20FailedOperation(address(token));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     *
     * This is a variant of {_callOptionalReturn} that silents catches all reverts and returns a bool instead.
     */
    function _callOptionalReturnBool(IERC20 token, bytes memory data) private returns (bool) {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We cannot use {Address-functionCall} here since this should return false
        // and not revert is the subcall reverts.

        (bool success, bytes memory returndata) = address(token).call(data);
        return success && (returndata.length == 0 || abi.decode(returndata, (bool))) && address(token).code.length > 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/Pausable.sol)

pragma solidity ^0.8.20;

import {ContextUpgradeable} from "../utils/ContextUpgradeable.sol";
import {Initializable} from "../proxy/utils/Initializable.sol";

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
    /// @custom:storage-location erc7201:openzeppelin.storage.Pausable
    struct PausableStorage {
        bool _paused;
    }

    // keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.Pausable")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant PausableStorageLocation = 0xcd5ed15c6e187e77e9aee88184c21f4f2182ab5827cb3b7e07fbedcd63f03300;

    function _getPausableStorage() private pure returns (PausableStorage storage $) {
        assembly {
            $.slot := PausableStorageLocation
        }
    }

    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    /**
     * @dev The operation failed because the contract is paused.
     */
    error EnforcedPause();

    /**
     * @dev The operation failed because the contract is not paused.
     */
    error ExpectedPause();

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        PausableStorage storage $ = _getPausableStorage();
        $._paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
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
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        PausableStorage storage $ = _getPausableStorage();
        return $._paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        if (paused()) {
            revert EnforcedPause();
        }
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        if (!paused()) {
            revert ExpectedPause();
        }
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        PausableStorage storage $ = _getPausableStorage();
        $._paused = true;
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
        PausableStorage storage $ = _getPausableStorage();
        $._paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

interface IAdminStructure {
    event AdminRigthsTransfered(address _admin);

    function superAdmin() external view returns (address _superAdmin);

    function admin() external view returns (address _admin);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (interfaces/IERC1363.sol)

pragma solidity ^0.8.20;

import {IERC20} from "./IERC20.sol";
import {IERC165} from "./IERC165.sol";

/**
 * @title IERC1363
 * @dev Interface of the ERC-1363 standard as defined in the https://eips.ethereum.org/EIPS/eip-1363[ERC-1363].
 *
 * Defines an extension interface for ERC-20 tokens that supports executing code on a recipient contract
 * after `transfer` or `transferFrom`, or code on a spender contract after `approve`, in a single transaction.
 */
interface IERC1363 is IERC20, IERC165 {
    /*
     * Note: the ERC-165 identifier for this interface is 0xb0202a11.
     * 0xb0202a11 ===
     *   bytes4(keccak256('transferAndCall(address,uint256)')) ^
     *   bytes4(keccak256('transferAndCall(address,uint256,bytes)')) ^
     *   bytes4(keccak256('transferFromAndCall(address,address,uint256)')) ^
     *   bytes4(keccak256('transferFromAndCall(address,address,uint256,bytes)')) ^
     *   bytes4(keccak256('approveAndCall(address,uint256)')) ^
     *   bytes4(keccak256('approveAndCall(address,uint256,bytes)'))
     */

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`
     * and then calls {IERC1363Receiver-onTransferReceived} on `to`.
     * @param to The address which you want to transfer to.
     * @param value The amount of tokens to be transferred.
     * @return A boolean value indicating whether the operation succeeded unless throwing.
     */
    function transferAndCall(address to, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`
     * and then calls {IERC1363Receiver-onTransferReceived} on `to`.
     * @param to The address which you want to transfer to.
     * @param value The amount of tokens to be transferred.
     * @param data Additional data with no specified format, sent in call to `to`.
     * @return A boolean value indicating whether the operation succeeded unless throwing.
     */
    function transferAndCall(address to, uint256 value, bytes calldata data) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the allowance mechanism
     * and then calls {IERC1363Receiver-onTransferReceived} on `to`.
     * @param from The address which you want to send tokens from.
     * @param to The address which you want to transfer to.
     * @param value The amount of tokens to be transferred.
     * @return A boolean value indicating whether the operation succeeded unless throwing.
     */
    function transferFromAndCall(address from, address to, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the allowance mechanism
     * and then calls {IERC1363Receiver-onTransferReceived} on `to`.
     * @param from The address which you want to send tokens from.
     * @param to The address which you want to transfer to.
     * @param value The amount of tokens to be transferred.
     * @param data Additional data with no specified format, sent in call to `to`.
     * @return A boolean value indicating whether the operation succeeded unless throwing.
     */
    function transferFromAndCall(address from, address to, uint256 value, bytes calldata data) external returns (bool);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens and then calls {IERC1363Spender-onApprovalReceived} on `spender`.
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to be spent.
     * @return A boolean value indicating whether the operation succeeded unless throwing.
     */
    function approveAndCall(address spender, uint256 value) external returns (bool);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens and then calls {IERC1363Spender-onApprovalReceived} on `spender`.
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to be spent.
     * @param data Additional data with no specified format, sent in call to `spender`.
     * @return A boolean value indicating whether the operation succeeded unless throwing.
     */
    function approveAndCall(address spender, uint256 value, bytes calldata data) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/Address.sol)

pragma solidity ^0.8.20;

import {Errors} from "./Errors.sol";

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev There's no code at `target` (it is not a contract).
     */
    error AddressEmptyCode(address target);

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.20/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        if (address(this).balance < amount) {
            revert Errors.InsufficientBalance(address(this).balance, amount);
        }

        (bool success, ) = recipient.call{value: amount}("");
        if (!success) {
            revert Errors.FailedCall();
        }
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason or custom error, it is bubbled
     * up by this function (like regular Solidity function calls). However, if
     * the call reverted with no returned reason, this function reverts with a
     * {Errors.FailedCall} error.
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        if (address(this).balance < value) {
            revert Errors.InsufficientBalance(address(this).balance, value);
        }
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and reverts if the target
     * was not a contract or bubbling up the revert reason (falling back to {Errors.FailedCall}) in case
     * of an unsuccessful call.
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata
    ) internal view returns (bytes memory) {
        if (!success) {
            _revert(returndata);
        } else {
            // only check if target is a contract if the call was successful and the return data is empty
            // otherwise we already know that it was a contract
            if (returndata.length == 0 && target.code.length == 0) {
                revert AddressEmptyCode(target);
            }
            return returndata;
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and reverts if it wasn't, either by bubbling the
     * revert reason or with a default {Errors.FailedCall} error.
     */
    function verifyCallResult(bool success, bytes memory returndata) internal pure returns (bytes memory) {
        if (!success) {
            _revert(returndata);
        } else {
            return returndata;
        }
    }

    /**
     * @dev Reverts with returndata if present. Otherwise reverts with {Errors.FailedCall}.
     */
    function _revert(bytes memory returndata) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert Errors.FailedCall();
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.1) (utils/Context.sol)

pragma solidity ^0.8.20;
import {Initializable} from "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.20;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```solidity
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 *
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Storage of the initializable contract.
     *
     * It's implemented on a custom ERC-7201 namespace to reduce the risk of storage collisions
     * when using with upgradeable contracts.
     *
     * @custom:storage-location erc7201:openzeppelin.storage.Initializable
     */
    struct InitializableStorage {
        /**
         * @dev Indicates that the contract has been initialized.
         */
        uint64 _initialized;
        /**
         * @dev Indicates that the contract is in the process of being initialized.
         */
        bool _initializing;
    }

    // keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.Initializable")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant INITIALIZABLE_STORAGE = 0xf0c57e16840df040f15088dc2f81fe391c3923bec73e23a9662efc9c229c6a00;

    /**
     * @dev The contract is already initialized.
     */
    error InvalidInitialization();

    /**
     * @dev The contract is not initializing.
     */
    error NotInitializing();

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint64 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that in the context of a constructor an `initializer` may be invoked any
     * number of times. This behavior in the constructor can be useful during testing and is not expected to be used in
     * production.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        // solhint-disable-next-line var-name-mixedcase
        InitializableStorage storage $ = _getInitializableStorage();

        // Cache values to avoid duplicated sloads
        bool isTopLevelCall = !$._initializing;
        uint64 initialized = $._initialized;

        // Allowed calls:
        // - initialSetup: the contract is not in the initializing state and no previous version was
        //                 initialized
        // - construction: the contract is initialized at version 1 (no reininitialization) and the
        //                 current contract is just being deployed
        bool initialSetup = initialized == 0 && isTopLevelCall;
        bool construction = initialized == 1 && address(this).code.length == 0;

        if (!initialSetup && !construction) {
            revert InvalidInitialization();
        }
        $._initialized = 1;
        if (isTopLevelCall) {
            $._initializing = true;
        }
        _;
        if (isTopLevelCall) {
            $._initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: Setting the version to 2**64 - 1 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint64 version) {
        // solhint-disable-next-line var-name-mixedcase
        InitializableStorage storage $ = _getInitializableStorage();

        if ($._initializing || $._initialized >= version) {
            revert InvalidInitialization();
        }
        $._initialized = version;
        $._initializing = true;
        _;
        $._initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        _checkInitializing();
        _;
    }

    /**
     * @dev Reverts if the contract is not in an initializing state. See {onlyInitializing}.
     */
    function _checkInitializing() internal view virtual {
        if (!_isInitializing()) {
            revert NotInitializing();
        }
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        // solhint-disable-next-line var-name-mixedcase
        InitializableStorage storage $ = _getInitializableStorage();

        if ($._initializing) {
            revert InvalidInitialization();
        }
        if ($._initialized != type(uint64).max) {
            $._initialized = type(uint64).max;
            emit Initialized(type(uint64).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint64) {
        return _getInitializableStorage()._initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _getInitializableStorage()._initializing;
    }

    /**
     * @dev Returns a pointer to the storage namespace.
     */
    // solhint-disable-next-line var-name-mixedcase
    function _getInitializableStorage() private pure returns (InitializableStorage storage $) {
        assembly {
            $.slot := INITIALIZABLE_STORAGE
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (interfaces/IERC20.sol)

pragma solidity ^0.8.20;

import {IERC20} from "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (interfaces/IERC165.sol)

pragma solidity ^0.8.20;

import {IERC165} from "../utils/introspection/IERC165.sol";

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

/**
 * @dev Collection of common custom errors used in multiple contracts
 *
 * IMPORTANT: Backwards compatibility is not guaranteed in future versions of the library.
 * It is recommended to avoid relying on the error API for critical functionality.
 */
library Errors {
    /**
     * @dev The ETH balance of the account is not enough to perform the operation.
     */
    error InsufficientBalance(uint256 balance, uint256 needed);

    /**
     * @dev A call to an address target failed. The target may have reverted.
     */
    error FailedCall();

    /**
     * @dev The deployment failed.
     */
    error FailedDeployment();
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/introspection/IERC165.sol)

pragma solidity ^0.8.20;

/**
 * @dev Interface of the ERC-165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[ERC].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[ERC section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}