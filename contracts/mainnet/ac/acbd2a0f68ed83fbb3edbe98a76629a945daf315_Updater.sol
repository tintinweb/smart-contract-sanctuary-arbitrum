/**
 *Submitted for verification at Arbiscan.io on 2024-05-27
*/

/**
 *Submitted for verification at Arbiscan.io on 2024-05-26
*/

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts (last updated v5.0.1) (utils/Context.sol)

pragma solidity ^0.8.20;

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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable.sol)

pragma solidity ^0.8.20;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is set to the address provided by the deployer. This can
 * later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
    }

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
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
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

// File: Interfaces.sol

pragma solidity ^0.8.20;

interface IAddressProvider{
    function getContractsRegister() external view returns (address);
    function getDataCompressor() external view returns (address);
}

interface IDataCompressor{
    struct PoolData {
        address addr;
        bool isWETH;
        address underlying;
        address dieselToken;
        uint256 linearCumulativeIndex;
        uint256 availableLiquidity;
        uint256 expectedLiquidity;
        uint256 expectedLiquidityLimit;
        uint256 totalBorrowed;
        uint256 depositAPY_RAY;
        uint256 borrowAPY_RAY;
        uint256 dieselRate_RAY;
        uint256 withdrawFee;
        uint256 cumulativeIndex_RAY;
        uint256 timestampLU;
        uint8 version;
    }
    function getPoolData(address _pool) external view returns (PoolData memory);
}

interface IContractsRegister{
    function getPoolsCount() external view returns (uint256);
    function getPools() external view returns (address[] memory);
}

interface IPoolQuotaKeeper{
    function gauge() external view returns (address);
}

interface IPool{
    function poolQuotaKeeper() external view returns (address);
    function name() external view returns (string memory);
}

interface IGauge{
    function updateEpoch() external;
}

interface ICvx{
    function earmarkRewards(uint256 _pid) external returns(bool);
}

interface ICrv{
    function refreshGaugeRewards() external;
}


// File: arbiUpdater.sol

pragma solidity ^0.8.20;



contract Updater is Ownable(msg.sender) {
    IAddressProvider public provider;
    uint256 public delayUntil;
    uint256 public interval;
    uint256 public canExecAt;
    event updatedGauge(string indexed name);
    
    constructor(address _addressProvider, uint256 _delayUntil, uint256 _interval){
        provider = IAddressProvider(_addressProvider);
        delayUntil = _delayUntil;
        interval = _interval;
        canExecAt = delayUntil;
    }

    function setParams (address _addressProvider, uint256 _delayUntil, uint256 _interval) public onlyOwner {
        provider = IAddressProvider(_addressProvider);
        delayUntil = _delayUntil;
        uint256 dummy = canExecAt - interval;
        interval = _interval;
        canExecAt = dummy + interval;
    }

    function canExec() public view returns (bool, bytes memory) {
        if ((getBlockTimestamp() >= canExecAt) && (getBlockTimestamp()>=delayUntil)){
            bytes memory cdata = abi.encodePacked(this.performFullUpdate.selector);
            return (true, cdata);
        }
    }

    function getBlockTimestamp() public view returns (uint256){
        return block.timestamp;
    }


    function updateGauges() public {
        IContractsRegister register = IContractsRegister(provider.getContractsRegister());
        address[] memory pools = register.getPools();
        for (uint256 i = 0; i<pools.length; i++){
            IPool pool = IPool(pools[i]);
            (bool ok, bytes memory output) = address(pool).call(abi.encodePacked(pool.poolQuotaKeeper.selector));
            if (ok){
                (address keeperAddress) = abi.decode(output, (address));
                IPoolQuotaKeeper keeper = IPoolQuotaKeeper(keeperAddress);
                IGauge gauge = IGauge(keeper.gauge());
                gauge.updateEpoch();
                string memory name = pool.name();
                emit updatedGauge(name);
            }
            //otherwise the pool don't have a quota keeper - that can happen
        }
    }

    function performFullUpdate() public returns (bool){
        updateGauges();
        canExecAt = getBlockTimestamp() + interval;
        return true;
    }
}