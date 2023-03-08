/**
 *Submitted for verification at Arbiscan on 2023-03-07
*/

// SPDX-License-Identifier: MIT
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

interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the erc token owner.
     */
    function getOwner() external view returns (address);

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
    function allowance(address _owner, address spender) external view returns (uint256);

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


contract NetfyBox is Ownable {
    struct Blockchain {
        uint id;
        address owner;
        uint liquidity; // total liquidity of the blockchain
        uint liquidityPerBlock; // liquidity per block
        uint startLiquidityEarnAt;
        uint tps; // total tps of the blockchain
        uint usedTps; // tps uses by the dapps
        uint nodes;
        uint[] dappsIds;
    }

    address _net;

    mapping(address => uint[]) private _userBlockchains; // user_address -> blockchain_id[]

    mapping(uint => mapping(uint => uint)) private _blockchainDAppsAmounts; // blockchain_id -> dapp_id -> amount

    Blockchain[] private _blockchains;

    address _dev;

    NetfyBoxDB private _db;

    constructor(NetfyBoxDB db, address net, address dev) {
        _db = db;
        _net = net;
        _dev = dev;
    }

    function createBlockchain() external {
        // 1000 NET for create node
        bool success = IERC20(_net).transferFrom(msg.sender, address(this), 1000 * 1e18);
    
        require(success,"Not enough token");

        NetfyBoxDB.NodeData memory NODE_DATA = _db.getNode();

        uint blockchainId = _blockchains.length;

        _blockchains.push(Blockchain({
        id : blockchainId,
        owner : msg.sender,
        liquidity : 1000,
        liquidityPerBlock : 10,
        startLiquidityEarnAt : block.number,
        tps : NODE_DATA.tps,
        usedTps : 0,
        nodes : 1,
        dappsIds : new uint[](0)
        }));

        _userBlockchains[msg.sender].push(blockchainId);
    }

    function buy(uint blockchainId, uint nodes, uint[] calldata dapps, uint[] calldata dappsAmounts) external {
        Blockchain storage blockchain = _blockchains[blockchainId];

        require(blockchain.owner != address(0), "Blockchain not found");
        require(blockchain.owner == msg.sender, "You are not the owner of this blockchain");

        uint totalLiqudity = blockchain.liquidity + _getBlockchainPendingLiquidity(blockchain);
        uint totalPrice;

        if (nodes > 0) {
            totalPrice += _buyNodes(blockchain, nodes);
        }

        if (dapps.length > 0) {
            totalPrice += _buyDapps(blockchain, dapps, dappsAmounts);
        }

        require(totalLiqudity >= totalPrice, "Not enough liquidity");

        blockchain.liquidity = totalLiqudity - totalPrice;
        blockchain.startLiquidityEarnAt = block.number;
    }

    function _buyNodes(Blockchain storage blockchain, uint amount) internal returns (uint) {
        uint currentNodes = blockchain.nodes;

        NetfyBoxDB.NodeData memory NODE_DATA = _db.getNode();

        uint price = cumulativeCost(NODE_DATA.price, currentNodes, currentNodes + amount);

        blockchain.tps += NODE_DATA.tps * amount;
        blockchain.nodes += amount;

        return price;
    }

    function _buyDapps(Blockchain storage blockchain, uint[] memory dapps, uint[] memory dappsAmounts) internal returns (uint) {
        uint totalPrice = 0;
        uint totalLiquidityPerBlock = 0;
        uint totalTps = 0;

        for (uint i; i < dapps.length; i++) {
            uint dappId = dapps[i];
            NetfyBoxDB.DAppData memory DAPP_DATA = _db.getDAppById(dappId);
            uint amount = dappsAmounts[i];
            uint currentAmount = _blockchainDAppsAmounts[blockchain.id][dappId];

            totalPrice += cumulativeCost(DAPP_DATA.price, currentAmount, currentAmount + amount);
            totalLiquidityPerBlock += DAPP_DATA.liquidityPerBlock * amount;
            totalTps += DAPP_DATA.tps * amount;
            _blockchainDAppsAmounts[blockchain.id][dappId] += amount;

            for (uint j; j < amount; j++) {
                blockchain.dappsIds.push(dappId);
            }
        }

        require((blockchain.tps - blockchain.usedTps) >= totalTps, "Not enough tps");

        blockchain.liquidityPerBlock += totalLiquidityPerBlock;
        blockchain.usedTps += totalTps;

        return totalPrice;
    }

    function cumulativeCost(uint baseCost, uint currentAmount, uint newAmount) internal pure returns (uint) {
        uint b = (115 ** newAmount) / (100 ** (newAmount - 1));

        if (currentAmount == 0) {
            return (baseCost * (b - 100)) / 15;
        }

        if (currentAmount == 1) {
            return (baseCost * (b - 115 ** currentAmount)) / 15;
        }

        uint a = (115 ** currentAmount) / (100 ** (currentAmount - 1));

        return (baseCost * (b - a)) / 15;
    }

    // onlyOwner methods
    function setDB(NetfyBoxDB db) external onlyOwner {
        _db = db;
    }

    function _getBlockchainPendingLiquidity(Blockchain memory blockchain) private view returns (uint) {
        return (block.number - blockchain.startLiquidityEarnAt) * blockchain.liquidityPerBlock;
    }

    // public view methods
    function getBlockchain(uint blockchainId) external view returns (Blockchain memory blockchain, uint pendingLiquidity) {
        blockchain = _blockchains[blockchainId];
        pendingLiquidity = _getBlockchainPendingLiquidity(blockchain);
    }

    function claimLiquidity(uint blockchainId) internal {
        Blockchain storage blockchain = _blockchains[blockchainId];
        require(blockchain.owner != address(0), "Blockchain not found");
        require(blockchain.owner == msg.sender, "You are not the owner of this blockchain");
        uint pending = _getBlockchainPendingLiquidity(blockchain);
        require(pending > 10, "Nothing to claim");
        uint devclaim = pending * 1/10;
        //dev reclaim 1% o
        IERC20(_net).transfer(_dev, devclaim * 1e18);
        // send to user
        IERC20(_net).transfer(msg.sender, pending * 1e18);
    }

    function getUserBlockchains(address user) external view returns (uint[] memory) {
        return _userBlockchains[user];
    }
}

contract NetfyBoxDB {
    struct NodeData {
        uint price;
        uint tps;
    }

    struct DAppData {
        uint id;
        uint price;
        uint tps;
        uint liquidityPerBlock;
    }

    struct ChestData {
        uint id;
        uint price;
        uint256 ratio;
    }

    NodeData private _node;
    DAppData[] private _dapps;
    ChestData[] private _chest;

    constructor() {
        initNode();
        initDApps();
    }

    function initNode() internal {
        _node = NodeData({
        price : 100,
        tps : 10
        });
    }

    function initChest() internal {
        //big_chest
        _chest.push(ChestData({
        id : 0,
        price : 5000,
        ratio : 1 //0,0001%
        }));
        //normal_chest
        _chest.push(ChestData({
        id : 0,
        price : 500,
        ratio : 1 //0,001%
        }));
        //small_chest
        _chest.push(ChestData({
        id : 0,
        price : 50,
        ratio : 1 //0,1%
        }));
        //tiny_chest
        _chest.push(ChestData({
        id : 0,
        price : 5,
        ratio : 1 //2%
        }));
    }

    function initDApps() internal {
        // dex
        _dapps.push(DAppData({
        id : 0,
        price : 750,
        tps : 1,
        liquidityPerBlock : 5
        }));

        // farm
        _dapps.push(DAppData({
        id : 1,
        price : 5000,
        tps : 3,
        liquidityPerBlock : 50
        }));

        // gamefi
        _dapps.push(DAppData({
        id : 2,
        price : 55000,
        tps : 9,
        liquidityPerBlock : 400
        }));

        // bridge
        _dapps.push(DAppData({
        id : 3,
        price : 600000,
        tps : 27,
        liquidityPerBlock : 2350
        }));

        // dao
        _dapps.push(DAppData({
        id : 4,
        price : 6500000,
        tps : 81,
        liquidityPerBlock : 13000
        }));
    }

    function getNode() public view returns (NodeData memory) {
        return _node;
    }

    function getDAppById(uint id) public view returns (DAppData memory) {
        return _dapps[id];
    }

    function getAllDApps() external view returns (DAppData[] memory dapps) {
        return _dapps;
    }
}