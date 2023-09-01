/**
 *Submitted for verification at Arbiscan.io on 2023-08-30
*/

// SPDX-License-Identifier: MIT

// File: contracts/Pool/interfaces/IPoolDeployer.sol

pragma solidity 0.8.1;
interface IPoolDeployer {
    function deployPool(address oracleAddress,bool reserve,address rateAddress,address settingAddress) external  returns (address poolAddress);
}

// File: contracts/Pool/interfaces/IPoolSettings.sol
pragma solidity 0.8.1;

interface IPoolSettings {

    struct param {
        uint256 _rebaseThresholdRatio;
        uint256 _rebaseBlock;
        uint256 _assetLevel;
        uint256 _priceThreshold;
        uint256 _marginRatio;
        uint256 _liqRewardRatio;
        uint256 _closeRatio;
        uint256 _baseLiquidity;
        uint256 _liquidityMoveTime;
        uint256 _liquidityMoveRatio;//速率上限
    }

    struct poolParam {
        uint256 _priceShockRatio;
        uint256 _priceEffectiveTime;
    }

    function eventOut() external view returns (address);
    function getOraclePriceV2(address poolAddress) external view returns (uint256 ,uint80 ); 
    function getPrice(address poolAddress,address assetAddress,uint256 increasePosition,uint8 direction) external view returns (uint256 priceFuture,bool canAction);    //判断是否爆仓
    function checkliquidation(address poolAddress,address assetAddress,uint256 margin,uint256 transferOut) external view returns (bool isLiquidity);
    function getLiqReward(address poolAddress,address assetAddress,uint256 margin) external view returns(uint256 liqReward);
    function getRebaseFee(address poolAddress,address assetAddress) external returns (int256 rebaseFeeLong,int256 rebaseShort);
    function getCloseFee(address poolAddress,address assetAddress,uint256 position) external view returns (uint256 closeFee);
    function checkOpenPosition(address poolAddress,address assetAddress,uint16 level,uint256 position) external view returns (bool);

    function getPriceDiffRatio(address poolAddress,address assetAddress) external view returns(uint256 diffRatio,uint256 priceThreshold);
    function getLiquidity(address poolAddress,address assetAddress) external view returns (uint256 resultLiquidity);
    function InitPool(address asset,address pool) external;
    function setLegalLevel(address asset,address pool,uint256 level) external;
    function removeLegalLevel(address asset,address pool,uint256 level) external;
}

// File: contracts/Asset/interfaces/IAssetDeployer.sol

pragma solidity 0.8.1;
interface IAssetDeployer {
    function deployAsset(address assetToken, address setting) external  returns (address assetAddress,address lpAddress);
}

// File: contracts/Asset/interfaces/IAssetSettings.sol
pragma solidity 0.8.1;

interface IAssetSettings {

    struct param {
        address referPool;
        uint256 epochTime;
    }
    function eventOut() external view returns (address);
    function RecordEvent() external view returns (address);

    function lpDeployer() external view returns (address);
    function poolStatus(address asset,address pool) external view returns(uint8);

    function isNextEpoch(address asset,uint256 beginTime) external view returns(uint256);

    function setPoolStatus(address asset,address pool,uint8 poolStatus_) external;
    function setAssetParam(address asset,address pool) external;
    function getOutEpoch(address asset) external view returns(uint32);
}

// File: contracts/interfaces/IEventOut.sol

pragma solidity 0.8.1;

interface IEventOut {
    event OutEvent(
        address indexed sender,
        uint32 itype,
        bytes bvalue
    );

    function eventOut(uint32 _type,bytes memory _value) external ;
}

// File: contracts/interfaces/IRecoreEvent.sol

pragma solidity 0.8.1;

interface IRecoreEvent {
    event Operator(
        address indexed sender,
        address user,
        uint256 itype
    );

    event OperatorWithValue(
        address indexed sender,
        address user,
        uint256 itype,
        uint256 aValue,
        uint256 bValue,
        uint256 cValue
    );

    function operationEvent(address user,uint256 iType) external; 
    function operatorWithValue(address user,uint256 iType,uint256 aValue,uint256 bValue,uint256 cValue) external;
    function setWhiteList(address whiteUser) external;
}

// File: @openzeppelin/contracts/utils/Context.sol

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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
}

// File: @openzeppelin/contracts/access/Ownable.sol

// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
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
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
}

// File: contracts/Factory.sol

pragma solidity 0.8.1;

contract Factory is Ownable  {
    address public _assetDeployer;
    address public _poolDeployer;
    address public _assetSettings;
    address public _poolSettings;

    struct poolInfo {
        address asset;
        address pool;
    }
    mapping(address =>mapping(address =>mapping(address=>mapping(bool=>poolInfo)))) public _poolInfo;
    //The `createPool` function is used to create a new pool. It takes four parameters: `pt`, `oracle`, `rate`, and `reserve`.
    function createPool(address pt,address oracle,address rate,bool reserve) public {
        require((_poolInfo[pt][oracle][rate][reserve].asset == address(0) && _poolInfo[pt][oracle][rate][reserve].pool == address(0)),
        "Asset Or Pool already exist");
        (address assetAddress,address lpAddress) = IAssetDeployer(_assetDeployer).deployAsset(pt,_assetSettings);
        address poolAddress = IPoolDeployer(_poolDeployer).deployPool(oracle,reserve,rate,_poolSettings);
        
        bytes memory data = abi.encode(pt,assetAddress,_assetSettings,lpAddress,oracle,rate,reserve,poolAddress,_poolSettings);
        eventOut(2,data);
        IAssetSettings(_assetSettings).setPoolStatus(assetAddress,poolAddress,1);
        IAssetSettings(_assetSettings).setAssetParam(assetAddress,poolAddress);
        IPoolSettings(_poolSettings).setLegalLevel(assetAddress,poolAddress,2);
        IPoolSettings(_poolSettings).setLegalLevel(assetAddress,poolAddress,5);
        IPoolSettings(_poolSettings).setLegalLevel(assetAddress,poolAddress,10);
        IPoolSettings(_poolSettings).setLegalLevel(assetAddress,poolAddress,20);
        IPoolSettings(_poolSettings).InitPool(assetAddress,poolAddress);

        IRecoreEvent(IAssetSettings(_assetSettings).RecordEvent()).setWhiteList(assetAddress);
        _poolInfo[pt][oracle][rate][reserve] = poolInfo(assetAddress,poolAddress);

    }

    function initialize(address ats,address pls,address ad,address pd) public onlyOwner {
        _assetDeployer = ad;
        _poolDeployer = pd;
        _assetSettings = ats;
        _poolSettings = pls;

        bytes memory data = abi.encode(ad,ats,pd,pls);
        eventOut(1,data);
    }

    function eventOut(uint32 _type,bytes memory _value) internal {
        IEventOut(IPoolSettings(_poolSettings).eventOut()).eventOut(_type,_value);
    }
}