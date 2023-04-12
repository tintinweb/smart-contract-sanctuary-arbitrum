// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "./oracle/interfaces/IVaultPriceFeed.sol";
import "./oracle/interfaces/IPythPriceFeed.sol";
import "./interfaces/IOrderBook.sol";
import "./interfaces/IRouter.sol";
import "./interfaces/IDipxStorage.sol";
import "./libraries/TransferHelper.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract OrderBook is IOrderBook,Initializable,OwnableUpgradeable,ReentrancyGuardUpgradeable {
    using EnumerableSet for EnumerableSet.UintSet;

    uint256 public constant PRICE_PRECISION = 1e10;

    mapping (address => mapping(uint256 => Order)) public increaseOrders;
    mapping (address => uint256) public increaseOrdersIndex;

    mapping (address => mapping(uint256 => Order)) public decreaseOrders;
    mapping (address => uint256) public decreaseOrdersIndex;
    
    address public dipxStorage;
    uint256 public minExecutionFee;

    mapping (address => EnumerableSet.UintSet) private accountIncreaseOrdersIndex;
    mapping (address => EnumerableSet.UintSet) private accountDecreaseOrdersIndex;

    event CreateIncreaseOrder(
        address indexed account,
        uint256 orderIndex,
        address collateralToken,
        address indexToken,
        uint256 collateralDelta,
        uint256 sizeDelta,
        bool isLong,
        uint256 triggerPrice,
        uint256 executionFee,
        bool triggerAboveThreshold
    );
    event CancelIncreaseOrder(
        address indexed account,
        uint256 orderIndex,
        address collateralToken,
        address indexToken,
        uint256 collateralDelta,
        uint256 sizeDelta,
        bool isLong,
        uint256 triggerPrice,
        uint256 executionFee,
        bool triggerAboveThreshold
    );
    event ExecuteIncreaseOrder(
        address indexed account,
        uint256 orderIndex,
        address collateralToken,
        address indexToken,
        uint256 collateralDelta,
        uint256 sizeDelta,
        bool isLong,
        uint256 triggerPrice,
        uint256 executionFee,
        uint256 executionPrice,
        bool triggerAboveThreshold,
        uint256 liqFee
    );
    event UpdateIncreaseOrder(
        address indexed account,
        uint256 orderIndex,
        address collateralToken,
        address indexToken,
        bool isLong,
        uint256 sizeDelta,
        uint256 triggerPrice,
        bool triggerAboveThreshold
    );
    event CreateDecreaseOrder(
        address indexed account,
        uint256 orderIndex,
        address collateralToken,
        uint256 collateralDelta,
        address indexToken,
        uint256 sizeDelta,
        bool isLong,
        uint256 triggerPrice,
        uint256 executionFee,
        bool triggerAboveThreshold
    );
    event CancelDecreaseOrder(
        address indexed account,
        uint256 orderIndex,
        address collateralToken,
        uint256 collateralDelta,
        address indexToken,
        uint256 sizeDelta,
        bool isLong,
        uint256 triggerPrice,
        uint256 executionFee,
        bool triggerAboveThreshold
    );
    event ExecuteDecreaseOrder(
        address indexed account,
        uint256 orderIndex,
        address collateralToken,
        uint256 collateralDelta,
        address indexToken,
        uint256 sizeDelta,
        bool isLong,
        uint256 triggerPrice,
        uint256 executionFee,
        uint256 executionPrice,
        bool triggerAboveThreshold,
        uint256 liqFee
    );
    event UpdateDecreaseOrder(
        address indexed account,
        uint256 orderIndex,
        address collateralToken,
        uint256 collateralDelta,
        address indexToken,
        uint256 sizeDelta,
        bool isLong,
        uint256 triggerPrice,
        bool triggerAboveThreshold
    );

    event UpdateMinExecutionFee(uint256 minExecutionFee);

    function initialize(address _dipxStorage,uint256 _minExecutionFee) public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        dipxStorage = _dipxStorage;
        minExecutionFee = _minExecutionFee;
    }

    receive() external payable {
    }

    function setDipxStorage(address _dipxStorage) external override onlyOwner {
        dipxStorage = _dipxStorage;
    }
    function priceFeed() public view returns(address){
        return IDipxStorage(dipxStorage).priceFeed();
    }
    function router() public view returns(address){
        return IDipxStorage(dipxStorage).router();
    }

    function setMinExecutionFee(uint256 _minExecutionFee) external onlyOwner {
        minExecutionFee = _minExecutionFee;

        emit UpdateMinExecutionFee(_minExecutionFee);
    }

    function cancelMultiple(
        uint256[] memory _increaseOrderIndexes,
        uint256[] memory _decreaseOrderIndexes
    ) external {
        for (uint256 i = 0; i < _increaseOrderIndexes.length; i++) {
            cancelIncreaseOrder(_increaseOrderIndexes[i]);
        }
        for (uint256 i = 0; i < _decreaseOrderIndexes.length; i++) {
            cancelDecreaseOrder(_decreaseOrderIndexes[i]);
        }
    }

    function validatePositionOrderPrice(
        bool _triggerAboveThreshold,
        uint256 _triggerPrice,
        address _indexToken,
        bool _maximizePrice,
        bool _raise
    ) public view returns (uint256, bool) {
        uint256 currentPrice = IVaultPriceFeed(priceFeed()).getPrice(_indexToken,_maximizePrice);
        bool isPriceValid = _triggerAboveThreshold ? currentPrice > _triggerPrice : currentPrice < _triggerPrice;
        if (_raise) {
            require(isPriceValid, "OrderBook: invalid price for execution");
        }
        return (currentPrice, isPriceValid);
    }
    
    function getIncreaseOrdersLength(address _account) public view returns (uint256) {
        return accountIncreaseOrdersIndex[_account].length();
    }
    function getIncreaseOrderIndexAt(address _account,uint256 _at) public view returns (uint256) {
        return accountIncreaseOrdersIndex[_account].at(_at);
    }

    function getDecreaseOrdersLength(address _account) public view returns (uint256) {
        return accountDecreaseOrdersIndex[_account].length();
    }
    function getDecreaseOrderIndexAt(address _account, uint256 _at) public view returns (uint256) {
        return accountDecreaseOrdersIndex[_account].at(_at);
    }

    function getIncreaseOrders(address _account) public view returns (Order[] memory) {
        uint256 len = accountIncreaseOrdersIndex[_account].length();

        Order[] memory orders = new Order[](len);
        for (uint256 i = 0; i < len; i++) {
            uint256 orderIndex = accountIncreaseOrdersIndex[_account].at(i);
            orders[i] = increaseOrders[_account][orderIndex];
        }
        return orders;
    }
    function getDecreaseOrders(address _account) public view returns (Order[] memory) {
        uint256 len = accountDecreaseOrdersIndex[_account].length();

        Order[] memory orders = new Order[](len);
        for (uint256 i = 0; i < len; i++) {
            uint256 orderIndex = accountDecreaseOrdersIndex[_account].at(i);
            orders[i] = decreaseOrders[_account][orderIndex];
        }
        return orders;
    }

    function getDecreaseOrder(address _account, uint256 _orderIndex) override public view returns (Order memory) {
        return decreaseOrders[_account][_orderIndex];
    }

    function getIncreaseOrder(address _account, uint256 _orderIndex) override public view returns (Order memory) {
        return increaseOrders[_account][_orderIndex];
    }

    function _addAccountOrder(address _account, uint256 _orderIndex, bool _isIncrease) private{
        if(_isIncrease){
            EnumerableSet.UintSet storage accountOrders = accountIncreaseOrdersIndex[_account];
            accountOrders.add(_orderIndex);
        }else{
            EnumerableSet.UintSet storage accountOrders = accountDecreaseOrdersIndex[_account];
            accountOrders.add(_orderIndex);
        }
    }
    function _removeAccountOrder(address _account, uint256 _orderIndex, bool _isIncrease) private{
        if(_isIncrease){
            EnumerableSet.UintSet storage accountOrders = accountIncreaseOrdersIndex[_account];
            accountOrders.remove(_orderIndex);
        }else{
            EnumerableSet.UintSet storage accountOrders = accountDecreaseOrdersIndex[_account];
            accountOrders.remove(_orderIndex);
        }
    }

    function createIncreaseOrder(
        uint256 _amountIn,
        address _indexToken,
        uint256 _sizeDelta,
        address _collateralToken,
        bool _isLong,
        uint256 _triggerPrice,
        uint256 _executionFee,
        bool _triggerAboveThreshold
    ) external payable nonReentrant {
        uint256 liqFee = IRouter(router()).getPoolLiqFee(_collateralToken);
        require(_executionFee >= minExecutionFee+liqFee, "OrderBook: insufficient execution fee");
        require(msg.value >= _executionFee, "OrderBook: incorrect execution fee transferred");
        TransferHelper.safeTransferFrom(_collateralToken,msg.sender,address(this),_amountIn);

        _createIncreaseOrder(
            msg.sender,
            _collateralToken,
            _indexToken,
            _amountIn,
            _sizeDelta,
            _isLong,
            _triggerPrice,
            msg.value,
            _triggerAboveThreshold
        );
    }

    function _createIncreaseOrder(
        address _account,
        address _collateralToken,
        address _indexToken,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        bool _isLong,
        uint256 _triggerPrice,
        uint256 _executionFee,
        bool _triggerAboveThreshold
    ) private {
        uint256 _orderIndex = increaseOrdersIndex[msg.sender];
        Order memory order = Order(
            _orderIndex,
            true,
            _account,
            _collateralToken,
            _indexToken,
            _collateralDelta,
            _sizeDelta,
            _isLong,
            _triggerPrice,
            _executionFee,
            _triggerAboveThreshold
        );
        increaseOrdersIndex[_account] = _orderIndex + 1;
        increaseOrders[_account][_orderIndex] = order;
        _addAccountOrder(_account,_orderIndex,true);

        emit CreateIncreaseOrder(
            _account,
            _orderIndex,
            _collateralToken,
            _indexToken,
            _collateralDelta,
            _sizeDelta,
            _isLong,
            _triggerPrice,
            _executionFee,
            _triggerAboveThreshold
        );
    }

    function updateIncreaseOrder(uint256 _orderIndex, uint256 _sizeDelta, uint256 _triggerPrice,bool _triggerAboveThreshold) external nonReentrant {
        Order storage order = increaseOrders[msg.sender][_orderIndex];
        require(order.account != address(0), "OrderBook: non-existent order");

        order.triggerPrice = _triggerPrice;
        order.sizeDelta = _sizeDelta;
        order.triggerAboveThreshold = _triggerAboveThreshold;

        emit UpdateIncreaseOrder(
            msg.sender,
            _orderIndex,
            order.collateralToken,
            order.indexToken,
            order.isLong,
            _sizeDelta,
            _triggerPrice,
            _triggerAboveThreshold
        );
    }

    function cancelIncreaseOrder(uint256 _orderIndex) public nonReentrant {
        Order memory order = increaseOrders[msg.sender][_orderIndex];
        require(order.account != address(0), "OrderBook: non-existent order");

        delete increaseOrders[msg.sender][_orderIndex];
        _removeAccountOrder(msg.sender,_orderIndex,true);

        TransferHelper.safeTransfer(order.collateralToken,msg.sender,order.collateralDelta);
        _transferOutETH(order.executionFee, msg.sender);

        emit CancelIncreaseOrder(
            order.account,
            _orderIndex,
            order.collateralToken,
            order.indexToken,
            order.collateralDelta,
            order.sizeDelta,
            order.isLong,
            order.triggerPrice,
            order.executionFee,
            order.triggerAboveThreshold
        );
    }

    function _updatePrice(bytes[] memory _priceUpdateData) private{
        if(_priceUpdateData.length == 0){
            return;
        }

        IVaultPriceFeed pricefeed = IVaultPriceFeed(IDipxStorage(dipxStorage).priceFeed());
        IPythPriceFeed pythPricefeed = IPythPriceFeed(pricefeed.pythPriceFeed());
        pythPricefeed.updatePriceFeeds(_priceUpdateData);
    }

    function executeOrders(address[] memory _addressArray, uint256[] memory _orderIndexArray, bool[] memory _orderTypes, address _feeReceiver, bool _raise,bytes[] memory _priceUpdateData) external nonReentrant{
        require(_addressArray.length == _orderIndexArray.length && _addressArray.length == _orderTypes.length);
        _updatePrice(_priceUpdateData);
        for (uint256 i = 0; i < _addressArray.length; i++) {
            if(_orderTypes[i]){
                _executeIncreaseOrder(_addressArray[i], _orderIndexArray[i], _feeReceiver, _raise);
            }else{
                _executeDecreaseOrder(_addressArray[i], _orderIndexArray[i], _feeReceiver, _raise);
            }
            
        }
    }

    function executeIncreaseOrders(address[] memory _addressArray, uint256[] memory _orderIndexArray, address _feeReceiver, bool _raise, bytes[] memory _priceUpdateData) external nonReentrant{
        require(_addressArray.length == _orderIndexArray.length);
        _updatePrice(_priceUpdateData);
        for (uint256 i = 0; i < _addressArray.length; i++) {
            _executeIncreaseOrder(_addressArray[i], _orderIndexArray[i], _feeReceiver, _raise);
        }
    }

    function executeIncreaseOrder(address _address, uint256 _orderIndex, address _feeReceiver, bool _raise, bytes[] memory _priceUpdateData) external nonReentrant {
        _updatePrice(_priceUpdateData);
        _executeIncreaseOrder(_address, _orderIndex, _feeReceiver, _raise);
    }

    function _executeIncreaseOrder(address _address, uint256 _orderIndex, address _feeReceiver, bool _raise) private{
        Order memory order = increaseOrders[_address][_orderIndex];
        if(order.account == address(0)){
            require(!_raise, "OrderBook: non-existent order");
            return;
        }

        (uint256 currentPrice, bool isPriceValid) = validatePositionOrderPrice(
            order.triggerAboveThreshold,
            order.triggerPrice,
            order.indexToken,
            order.isLong,
            _raise
        );
        if(!isPriceValid){
            return;
        }
        
        address routerAddr = router();
        uint256 liqFee = IRouter(routerAddr).getPoolLiqFee(order.collateralToken);
        TransferHelper.safeTransfer(order.collateralToken,routerAddr,order.collateralDelta);
        IRouter(routerAddr).pluginIncreasePosition{value:liqFee}(
            order.account, 
            order.indexToken, 
            order.collateralToken, 
            order.collateralDelta, 
            order.sizeDelta, 
            order.isLong
        );

        // pay executor
        _transferOutETH(order.executionFee-liqFee, _feeReceiver);
        delete increaseOrders[_address][_orderIndex];
        _removeAccountOrder(_address,_orderIndex,true);
        emit ExecuteIncreaseOrder(
            order.account,
            _orderIndex,
            order.collateralToken,
            order.indexToken,
            order.collateralDelta,
            order.sizeDelta,
            order.isLong,
            order.triggerPrice,
            order.executionFee,
            currentPrice,
            order.triggerAboveThreshold,
            liqFee
        );
    }

    function createDecreaseOrder(
        address _indexToken,
        uint256 _sizeDelta,
        address _collateralToken,
        uint256 _collateralDelta,
        bool _isLong,
        uint256 _triggerPrice,
        bool _triggerAboveThreshold
    ) external payable nonReentrant {
        uint256 liqFee = IRouter(router()).getPoolLiqFee(_collateralToken);
        require(msg.value >= minExecutionFee+liqFee, "OrderBook: insufficient execution fee");

        _createDecreaseOrder(
            msg.sender,
            _collateralToken,
            _collateralDelta,
            _indexToken,
            _sizeDelta,
            _isLong,
            _triggerPrice,
            _triggerAboveThreshold
        );
    }

    function _createDecreaseOrder(
        address _account,
        address _collateralToken,
        uint256 _collateralDelta,
        address _indexToken,
        uint256 _sizeDelta,
        bool _isLong,
        uint256 _triggerPrice,
        bool _triggerAboveThreshold
    ) private {
        uint256 _orderIndex = decreaseOrdersIndex[_account];
        Order memory order = Order(
            _orderIndex,
            false,
            _account,
            _collateralToken,
            _indexToken,
            _collateralDelta,
            _sizeDelta,
            _isLong,
            _triggerPrice,
            msg.value,
            _triggerAboveThreshold
        );
        decreaseOrdersIndex[_account] = _orderIndex + 1;
        decreaseOrders[_account][_orderIndex] = order;
        _addAccountOrder(_account,_orderIndex,false);

        emit CreateDecreaseOrder(
            _account,
            _orderIndex,
            _collateralToken,
            _collateralDelta,
            _indexToken,
            _sizeDelta,
            _isLong,
            _triggerPrice,
            msg.value,
            _triggerAboveThreshold
        );
    }

    function executeDecreaseOrders(address[] memory _addressArray, uint256[] memory _orderIndexArray, address _feeReceiver, bool _raise, bytes[] memory _priceUpdateData) external nonReentrant {
        require(_addressArray.length == _orderIndexArray.length);
        _updatePrice(_priceUpdateData);
        for (uint256 i = 0; i < _addressArray.length; i++) {
            _executeDecreaseOrder(_addressArray[i], _orderIndexArray[i], _feeReceiver,_raise);
        }
    }

    function executeDecreaseOrder(address _address, uint256 _orderIndex, address _feeReceiver, bool _raise, bytes[] memory _priceUpdateData) external nonReentrant {
        _updatePrice(_priceUpdateData);
        _executeDecreaseOrder(_address, _orderIndex, _feeReceiver,_raise);
    }

    function _executeDecreaseOrder(address _address, uint256 _orderIndex, address _feeReceiver, bool _raise) private {
        Order memory order = decreaseOrders[_address][_orderIndex];
        if(order.account == address(0)){
            require(!_raise, "OrderBook: non-existent order");
            return;
        }

        (uint256 currentPrice,bool isPriceValid) = validatePositionOrderPrice(
            order.triggerAboveThreshold,
            order.triggerPrice,
            order.indexToken,
            !order.isLong,
            _raise
        );
        if(!isPriceValid){
            return;
        }

        address routerAddr = router();
        uint256 liqFee = IRouter(routerAddr).getPoolLiqFee(order.collateralToken);
        try IRouter(routerAddr).pluginDecreasePosition{value:liqFee}(
            order.account, 
            order.indexToken, 
            order.collateralToken, 
            order.sizeDelta,
            order.collateralDelta, 
            order.isLong, 
            order.account
        ){}catch Error(string memory _err) {
            if(_raise){
                revert(_err);
            }
            return;
        }catch{
            if(_raise){
                revert("OrderBook: DecreasePosition error");
            }
            return;
        }

        // pay executor
        _transferOutETH(order.executionFee-liqFee, _feeReceiver);
        delete decreaseOrders[_address][_orderIndex];
        _removeAccountOrder(_address,_orderIndex,false);

        emit ExecuteDecreaseOrder(
            order.account,
            _orderIndex,
            order.collateralToken,
            order.collateralDelta,
            order.indexToken,
            order.sizeDelta,
            order.isLong,
            order.triggerPrice,
            order.executionFee,
            currentPrice,
            order.triggerAboveThreshold,
            liqFee
        );
    }

    function cancelDecreaseOrder(uint256 _orderIndex) public nonReentrant {
        Order memory order = decreaseOrders[msg.sender][_orderIndex];
        require(order.account != address(0), "OrderBook: non-existent order");

        delete decreaseOrders[msg.sender][_orderIndex];
        _removeAccountOrder(msg.sender,_orderIndex,false);
        _transferOutETH(order.executionFee, msg.sender);

        emit CancelDecreaseOrder(
            order.account,
            _orderIndex,
            order.collateralToken,
            order.collateralDelta,
            order.indexToken,
            order.sizeDelta,
            order.isLong,
            order.triggerPrice,
            order.executionFee,
            order.triggerAboveThreshold
        );
    }

    function updateDecreaseOrder(
        uint256 _orderIndex,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        uint256 _triggerPrice,
        bool _triggerAboveThreshold
    ) external nonReentrant {
        Order storage order = decreaseOrders[msg.sender][_orderIndex];
        require(order.account != address(0), "OrderBook: non-existent order");

        order.triggerPrice = _triggerPrice;
        order.triggerAboveThreshold = _triggerAboveThreshold;
        order.sizeDelta = _sizeDelta;
        order.collateralDelta = _collateralDelta;

        emit UpdateDecreaseOrder(
            msg.sender,
            _orderIndex,
            order.collateralToken,
            _collateralDelta,
            order.indexToken,
            _sizeDelta,
            order.isLong,
            _triggerPrice,
            _triggerAboveThreshold
        );
    }

    function transferOutETH(uint256 _amountOut, address _receiver) external onlyOwner {
        _transferOutETH(_amountOut, _receiver);
    }

    function _transferOutETH(uint256 _amountOut, address _receiver) private {
        TransferHelper.safeTransferETH(_receiver, _amountOut);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

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
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
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
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = _setInitializedVersion(1);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !AddressUpgradeable.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.4;

interface IVaultPriceFeed {
  function chainlinkPriceFeed() external view returns(address);
  function pythPriceFeed() external view returns(address);
  function eth() external view returns(address);
  function btc() external view returns(address);
  function decimals() external view returns(uint8);
  function getPrice(address _token, bool _maximise) external view returns (uint256);
  function setPythEnabled(bool _isEnabled) external;
  function setAmmEnabled(bool _isEnabled) external;
  function setTokens(address _btc, address _eth) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.4;

interface IPythPriceFeed{
  function getBtcUsdPrice() external view returns (int256,uint32);
  function getEthUsdPrice() external view returns (int256,uint32);
  function getPrice(address _token) external view returns (int256,uint32);
  function updatePriceFeeds(bytes[] memory _priceUpdateData) external payable;
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.4;

import "./IStorageSet.sol";

interface IOrderBook is IStorageSet{
    struct Order{
        uint256 orderIndex;
        bool isInc;
        address account;
        address collateralToken;
        address indexToken;
        uint256 collateralDelta;
        uint256 sizeDelta;
        bool isLong;
        uint256 triggerPrice;
        uint256 executionFee;
        bool triggerAboveThreshold;
    }

    function getIncreaseOrder(address _account, uint256 _orderIndex) external view returns (Order memory);
    function getDecreaseOrder(address _account, uint256 _orderIndex) external view returns (Order memory);
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.4;

import "./IStorageSet.sol";

interface IRouter is IStorageSet{
  struct Liquidity{
    address pool;
    string name;
    string symbol;
    uint8 decimals;
    uint256 balance;
  }
  function isLpToken(address token) external view returns(bool,bool);
  function getLpToken(address collateralToken) external view returns(address);
  function getPoolPrice(address _pool,bool _maximise,bool _includeProfit,bool _includeLoss) external view returns(uint256);

  function addLiquidityNative(
    address _targetPool,
    uint256 _amount, 
    address _to,
    uint256 _price,
    address _referrer,
    bytes[] memory _priceUpdateData
  ) external payable returns(uint256);
  function addLiquidity(
    address _collateralToken,
    address _targetPool,
    uint256 _amount,
    address _to,
    uint256 _price,
    address _referrer,
    bytes[] memory _priceUpdateData
  ) external returns(uint256);
  function removeLiquidity(
    address _collateralToken,
    address _receiveToken,
    uint256 _liquidity,
    address _to,
    uint256 _price,
    address _referrer,
    bytes[] memory _priceUpdateData
  ) external returns(uint256);

  function getPoolLiqFee(address pool) external view returns(uint256);
  function addPlugin(address _plugin) external;
  function removePlugin(address _plugin) external;
  
  function increasePosition(
    address _indexToken,
    address _collateralToken,
    uint256 _amountIn,
    uint256 _sizeDelta,
    uint256 _price,
    bool _isLong,
    address _referrer,
    bytes[] memory _priceUpdateData
  ) external payable;

  function decreasePosition(
    address _indexToken, 
    address _collateralToken, 
    uint256 _sizeDelta, 
    uint256 _collateralDelta, 
    bool _isLong, 
    address _receiver,
    uint256 _price,
    address _referrer,
    bytes[] memory _priceUpdateData
  )external payable returns(uint256);

  function pluginIncreasePosition(
    address _account,
    address _indexToken,
    address _collateralToken,
    uint256 _amountIn,
    uint256 _sizeDelta,
    bool _isLong
  ) external payable;

  function pluginDecreasePosition(
    address _account,
    address _indexToken, 
    address _collateralToken, 
    uint256 _sizeDelta, 
    uint256 _collateralDelta, 
    bool _isLong, 
    address _receiver
  )external payable returns(uint256);

  function liquidatePosition(
    address _account,
    address _indexToken, 
    address _collateralToken, 
    bool _isLong,
    address _feeReceiver,
    bytes[] memory _priceUpdateData
  ) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.4;

interface IDipxStorage{
  struct SkewRule{
    uint256 min;             // BASIS_POINT_DIVISOR = 1
    uint256 max;             // BASIS_POINT_DIVISOR = 1
    uint256 delta;
    int256 light;            // BASIS_POINT_DIVISOR = 1
    uint256 heavy;
  }

  function initConfig(
    address _genesisPass,
    address _feeTo,
    address _vault, 
    address _lpManager, 
    address _positionManager, 
    address _priceFeed,
    address _router,
    address _referral,
    uint256 _positionFeePoints,
    uint256 _lpFeePoints,
    uint256 _fundingRateFactor,
    uint256 _gasFee
  ) external;

  function setContracts(
    address _genesisPass,
    address _feeTo,
    address _vault, 
    address _lpManager, 
    address _positionManager,
    address _priceFeed,
    address _router,
    address _handler,
    address _referral
  ) external;

  function genesisPass() external view returns(address);
  function vault() external view returns(address);
  function lpManager() external view returns(address);
  function positionManager() external view returns(address);
  function priceFeed() external view returns(address);
  function router() external view returns(address);
  function handler() external view returns(address);
  function referral() external view returns(address);

  function setGenesisPass(address _genesisPass,uint256 _gpDiscount) external;
  function setLpManager(address _lpManager) external;
  function setPositionManager(address _positionManager) external;
  function setVault(address _vault) external;
  function setPriceFeed(address _priceFeed) external;
  function setRouter(address _router) external;
  function setHandler(address _handler) external;
  function setReferral(address _referral) external;

  function feeTo() external view returns(address);
  function setFeeTo(address _feeTo) external;

  function setDefaultGasFee(uint256 _gasFee) external;
  function setTokenGasFee(address _collateralToken, bool _requireFee, uint256 _fee) external;
  function getTokenGasFee(address _collateralToken) external view returns(uint256);

  function currentFundingFactor(address _account,address _indexToken, address _collateralToken, bool _isLong) external view returns(int256);
  function cumulativeFundingRates(address indexToken, address collateralToken) external returns(uint256);
  function lastFundingTimes(address indexToken, address collateralToken) external returns(uint256);
  function setFundingInterval(uint256 _fundingInterval) external;
  function setFundingRateFactor(uint256 _fundingRateFactor) external;
  function updateCumulativeFundingRate(address _indexToken,address _collateralToken) external;
  function getFundingFee(
    address _account,
    address _indexToken, 
    address _collateralToken, 
    bool _isLong
  ) external view returns (int256);
  function setDefaultSkewRules(
    SkewRule[] memory _rules
  ) external;
  function setTokenSkewRules(
    address _collateralToken,
    SkewRule[] memory _rules
  ) external;

  function setAccountsFeePoint(
    address[] memory _accounts, 
    bool[] memory _whitelisted, 
    uint256[] memory _feePoints
  ) external;

  function setPositionFeePoints(uint256 _point,uint256 _lpPoint) external;
  function setTokenPositionFeePoints(address[] memory _lpTokens, uint256[] memory _rates) external;

  function getPositionFeePoints(address _collateralToken) external view returns(uint256);
  function getLpPositionFee(address _collateralToken,uint256 totalFee) external view returns(uint256);
  function getPositionFee(address _account,address _indexToken,address _collateralToken, uint256 _tradeAmount) external view returns(uint256);

  function setLpTaxPoints(address _pool, uint256 _buyFeePoints, uint256 _sellFeePoints) external;

  function eth() external view returns(address);
  function nativeCurrencyDecimals() external view returns(uint8);
  function nativeCurrency() external view returns(address);
  function nativeCurrencySymbol() external view returns(string memory);
  function isNativeCurrency(address token) external view returns(bool);
  function getTokenDecimals(address token) external view returns(uint256);

  function BASIS_POINT_DIVISOR() external view returns(uint256);
  function getBuyLpFeePoints(address _pool, address token,uint256 tokenDelta) external view returns(uint256);
  function getSellLpFeePoints(address _pool, address receiveToken,uint256 dlpDelta) external view returns(uint256);

  function greylist(address _account) external view returns(bool);
  function greylistAddress(address _address) external;
  function greylistedTokens(address _token) external view returns(bool);
  function setGreyListTokens(address[] memory _tokens, bool[] memory _disables) external;

  function increasePaused() external view returns(bool);
  function toggleIncrease() external;
  function tokenIncreasePaused(address _token) external view returns(bool);
  function toggleTokenIncrease(address _token) external;

  function decreasePaused() external view returns(bool);
  function toggleDecrease() external;
  function tokenDecreasePaused(address _token) external view returns(bool);
  function toggleTokenDecrease(address _token) external;

  function liquidatePaused() external view returns(bool);
  function toggleLiquidate() external;
  function tokenLiquidatePaused(address _token) external view returns(bool);
  function toggleTokenLiquidate(address _token) external;

  function maxLeverage() external view returns(uint256);
  function setMaxLeverage(uint256) external;
  
  function minProfitTime() external view returns(uint256);
  function minProfitBasisPoints(address) external view returns(uint256);
  function setMinProfit(uint256 _minProfitTime,address[] memory _indexTokens, uint256[] memory _minProfitBps) external;

  function approvedRouters(address,address) external view returns(bool);
  function approveRouter(address _router, bool _enable) external;
  function isLiquidator(address _account) external view returns (bool);
  function setLiquidator(address _liquidator, bool _isActive) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.4;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeApprove: approve failed'
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeTransfer: transfer failed'
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::transferFrom: transferFrom failed'
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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
        return verifyCallResult(success, returndata, errorMessage);
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
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
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

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.4;

interface IStorageSet{
  function setDipxStorage(address _dipxStorage) external;
}