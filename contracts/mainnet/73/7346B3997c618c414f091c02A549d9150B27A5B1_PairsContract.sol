// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IPairsContract.sol";
import "./interfaces/IPosition.sol";

contract PairsContract is Ownable, IPairsContract {

    address public protocol;

    mapping(uint256 => bool) public allowedAsset;

    uint256 private maxBaseFundingRate = 1e10;

    mapping(uint256 => Asset) private _idToAsset;
    function idToAsset(uint256 _asset) public view returns (Asset memory) {
        return _idToAsset[_asset];
    }

    mapping(uint256 => mapping(address => OpenInterest)) private _idToOi;
    function idToOi(uint256 _asset, address _tigAsset) public view returns (OpenInterest memory) {
        return _idToOi[_asset][_tigAsset];
    }

    // OWNER

    /**
     * @dev Update the Chainlink price feed of an asset
     * @param _asset index of the requested asset
     * @param _feed contract address of the Chainlink price feed
     */
    function setAssetChainlinkFeed(uint256 _asset, address _feed) external onlyOwner exists(_asset) {
        _idToAsset[_asset].chainlinkFeed = _feed;
    }

    /**
     * @dev Add an allowed asset to fetch prices for
     * @param _asset index of the requested asset
     * @param _name name of the asset
     * @param _chainlinkFeed optional address of the respective Chainlink price feed
     * @param _minLeverage minimum allowed leverage
     * @param _maxLeverage maximum allowed leverage
     * @param _feeMultiplier percent value that the opening/closing fee is multiplied by in BP
     * @param _baseFundingRate Funding rate applied to pair when open interest is completely unbalanced
     */
    function addAsset(uint256 _asset, string memory _name, address _chainlinkFeed, uint256 _minLeverage, uint256 _maxLeverage, uint256 _feeMultiplier, uint256 _baseFundingRate) external onlyOwner {
        bytes memory _assetName  = bytes(_idToAsset[_asset].name);
        require(_assetName.length == 0, "Already exists");
        require(bytes(_name).length > 0, "No name");
        require(_maxLeverage >= _minLeverage, "Wrong leverage values");
        require(_minLeverage > 0, "Wrong leverage values");

        allowedAsset[_asset] = true;
        _idToAsset[_asset].name = _name;

        _idToAsset[_asset].chainlinkFeed = _chainlinkFeed;

        _idToAsset[_asset].minLeverage = _minLeverage;
        _idToAsset[_asset].maxLeverage = _maxLeverage;
        _idToAsset[_asset].feeMultiplier = _feeMultiplier;
        _idToAsset[_asset].baseFundingRate = _baseFundingRate;

        emit AssetAdded(_asset, _name);
    }

    /**
     * @dev Update the leverage allowed per asset
     * @param _asset index of the asset
     * @param _minLeverage minimum leverage allowed
     * @param _maxLeverage Maximum leverage allowed
     */
    function updateAssetLeverage(uint256 _asset, uint256 _minLeverage, uint256 _maxLeverage) external onlyOwner exists(_asset) {

        if (_maxLeverage > 0) {
            _idToAsset[_asset].maxLeverage = _maxLeverage;
        }
        if (_minLeverage > 0) {
            _idToAsset[_asset].minLeverage = _minLeverage;
        }
        
        require(_idToAsset[_asset].maxLeverage >= _idToAsset[_asset].minLeverage, "Wrong leverage values");
    }

    /**
     * @notice update the base rate for funding fees per asset
     * @param _asset index of the asset
     * @param _baseFundingRate the rate to set
     */
    function setAssetBaseFundingRate(uint256 _asset, uint256 _baseFundingRate) external onlyOwner exists(_asset) {
        require(_baseFundingRate <= maxBaseFundingRate, "baseFundingRate too high");
        _idToAsset[_asset].baseFundingRate = _baseFundingRate;
    }

    /**
     * @notice update the fee multiplier per asset
     * @param _asset index of the asset
     * @param _feeMultiplier the fee multiplier
     */
    function updateAssetFeeMultiplier(uint256 _asset, uint256 _feeMultiplier) external onlyOwner exists(_asset) {
        _idToAsset[_asset].feeMultiplier = _feeMultiplier;
    }

     /**
     * @notice pause an asset from being traded
     * @param _asset index of the asset
     * @param _isPaused paused if true
     */
    function pauseAsset(uint256 _asset, bool _isPaused) external onlyOwner exists(_asset) {
        allowedAsset[_asset] = !_isPaused;
    }

    /**
     * @notice sets the max rate for funding fees
     * @param _maxBaseFundingRate max base funding rate
     */
    function setMaxBaseFundingRate(uint256 _maxBaseFundingRate) external onlyOwner {
        maxBaseFundingRate = _maxBaseFundingRate;
    }

    function setProtocol(address _protocol) external onlyOwner {
        protocol = _protocol;
    }

    /**
     * @dev Update max open interest limits
     * @param _asset index of the asset
     * @param _tigAsset contract address of the tigAsset
     * @param _maxOi Maximum open interest value per side
     */
    function setMaxOi(uint256 _asset, address _tigAsset, uint256 _maxOi) external onlyOwner exists(_asset) {
        _idToOi[_asset][_tigAsset].maxOi = _maxOi;
    }

    // Protocol-only

    /**
     * @dev edits the current open interest for long
     * @param _asset index of the asset
     * @param _tigAsset contract address of the tigAsset
     * @param _onOpen true if adding to open interest
     * @param _amount amount to be added/removed from open interest
     */
    function modifyLongOi(uint256 _asset, address _tigAsset, bool _onOpen, uint256 _amount) external onlyProtocol {
        if (_onOpen) {
            _idToOi[_asset][_tigAsset].longOi += _amount;
            require(_idToOi[_asset][_tigAsset].longOi <= _idToOi[_asset][_tigAsset].maxOi || _idToOi[_asset][_tigAsset].maxOi == 0, "MaxLongOi");
        }
        else {
            _idToOi[_asset][_tigAsset].longOi -= _amount;
            if (_idToOi[_asset][_tigAsset].longOi < 1e9) {
                _idToOi[_asset][_tigAsset].longOi = 0;
            }
        }
    }

     /**
     * @dev edits the current open interest for short
     * @param _asset index of the asset
     * @param _tigAsset contract address of the tigAsset
     * @param _onOpen true if adding to open interest
     * @param _amount amount to be added/removed from open interest
     */
    function modifyShortOi(uint256 _asset, address _tigAsset, bool _onOpen, uint256 _amount) external onlyProtocol {
        if (_onOpen) {
            _idToOi[_asset][_tigAsset].shortOi += _amount;
            require(_idToOi[_asset][_tigAsset].shortOi <= _idToOi[_asset][_tigAsset].maxOi || _idToOi[_asset][_tigAsset].maxOi == 0, "MaxShortOi");
            }
        else {
            _idToOi[_asset][_tigAsset].shortOi -= _amount;
            if (_idToOi[_asset][_tigAsset].shortOi < 1e9) {
                _idToOi[_asset][_tigAsset].shortOi = 0;
            }
        }
    }

    // Modifiers

    modifier onlyProtocol() {
        require(_msgSender() == address(protocol), "!Protocol");
        _;
    }

    modifier exists(uint256 _asset){
        bytes memory _name  = bytes(_idToAsset[_asset].name);
        require(_name.length > 0, "!Asset");
        _;
    }

    // EVENTS

    event AssetAdded(
        uint256 _asset,
        string _name
    );

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

interface IPairsContract {

    struct Asset {
        string name;
        address chainlinkFeed;
        uint256 minLeverage;
        uint256 maxLeverage;
        uint256 feeMultiplier;
        uint256 baseFundingRate;
    }

    struct OpenInterest {
        uint256 longOi;
        uint256 shortOi;
        uint256 maxOi;
    }

    function allowedAsset(uint) external view returns (bool);
    function idToAsset(uint256 _asset) external view returns (Asset memory);
    function idToOi(uint256 _asset, address _tigAsset) external view returns (OpenInterest memory);
    function setAssetBaseFundingRate(uint256 _asset, uint256 _baseFundingRate) external;
    function modifyLongOi(uint256 _asset, address _tigAsset, bool _onOpen, uint256 _amount) external;
    function modifyShortOi(uint256 _asset, address _tigAsset, bool _onOpen, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

interface IPosition {

    struct Trade {
        uint256 margin;
        uint256 leverage;
        uint256 asset;
        bool direction;
        uint256 price;
        uint256 tpPrice;
        uint256 slPrice;
        uint256 orderType;
        address trader;
        uint256 id;
        address tigAsset;
        int accInterest;
    }

    struct MintTrade {
        address account;
        uint256 margin;
        uint256 leverage;
        uint256 asset;
        bool direction;
        uint256 price;
        uint256 tp;
        uint256 sl;
        uint256 orderType;
        address tigAsset;
    }

    function trades(uint256) external view returns (Trade memory);
    function executeLimitOrder(uint256 _id, uint256 _price, uint256 _newMargin) external;
    function modifyMargin(uint256 _id, uint256 _newMargin, uint256 _newLeverage) external;
    function addToPosition(uint256 _id, uint256 _newMargin, uint256 _newPrice) external;
    function reducePosition(uint256 _id, uint256 _newMargin) external;
    function assetOpenPositions(uint256 _asset) external view returns (uint256[] calldata);
    function assetOpenPositionsIndexes(uint256 _asset, uint256 _id) external view returns (uint256);
    function limitOrders(uint256 _asset) external view returns (uint256[] memory);
    function limitOrderIndexes(uint256 _asset, uint256 _id) external view returns (uint256);
    function assetOpenPositionsLength(uint256 _asset) external view returns (uint256);
    function limitOrdersLength(uint256 _asset) external view returns (uint256);
    function ownerOf(uint256 _id) external view returns (address);
    function mint(MintTrade memory _mintTrade) external;
    function burn(uint256 _id) external;
    function modifyTp(uint256 _id, uint256 _tpPrice) external;
    function modifySl(uint256 _id, uint256 _slPrice) external;
    function getCount() external view returns (uint);
    function updateFunding(uint256 _asset, address _tigAsset, uint256 _longOi, uint256 _shortOi, uint256 _baseFundingRate, uint256 _vaultFundingPercent) external;
    function setAccInterest(uint256 _id) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
}

// SPDX-License-Identifier: MIT
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