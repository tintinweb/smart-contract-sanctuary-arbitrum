// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable2Step.sol)

pragma solidity ^0.8.0;

import "./Ownable.sol";

/**
 * @dev Contract module which provides access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership} and {acceptOwnership}.
 *
 * This module is used through inheritance. It will make available all functions
 * from parent (Ownable).
 */
abstract contract Ownable2Step is Ownable {
    address private _pendingOwner;

    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Returns the address of the pending owner.
     */
    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }

    /**
     * @dev Starts the ownership transfer of the contract to a new account. Replaces the pending transfer if there is one.
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual override onlyOwner {
        _pendingOwner = newOwner;
        emit OwnershipTransferStarted(owner(), newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`) and deletes any pending owner.
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual override {
        delete _pendingOwner;
        super._transferOwnership(newOwner);
    }

    /**
     * @dev The new owner accepts the ownership transfer.
     */
    function acceptOwnership() public virtual {
        address sender = _msgSender();
        require(pendingOwner() == sender, "Ownable2Step: caller is not the new owner");
        _transferOwnership(sender);
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

//SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.18;

interface RouterInterface {
    function withdrawRewards(address[] memory lTokens) external;
}

interface VotingInterface {
    enum OperationType {
        SUPPLY,
        BORROW
    }

    function getResults() external view returns (string[] memory, OperationType[] memory, uint256[] memory);

    function paused() external view returns (bool);
}

interface ComptrollerInterface {
    function _setCompSpeeds(address[] memory cTokens, uint[] memory supplySpeeds, uint[] memory borrowSpeeds) external;
}

interface StakingRewardsInterface {
    function paused() external view returns (bool);
}

//SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.18;
import "./Interfaces/HandlerInterfaces.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "./Utils/Whitelist.sol";

contract LodestarHandler is Whitelist {
    RouterInterface public ROUTER;
    VotingInterface public VOTING;
    StakingRewardsInterface public immutable STAKING;
    ComptrollerInterface public UNITROLLER;
    Whitelist WHITELIST;

    address[] public markets;

    struct MarketInfo {
        address marketAddress;
        string marketName;
        uint256 marketBaseSupplySpeed;
        uint256 marketBaseBorrowSpeed;
    }

    mapping(string => MarketInfo) public tokenMapping;

    event Updated(uint256 indexed timestamp);

    constructor(
        RouterInterface _router,
        VotingInterface _voting,
        StakingRewardsInterface _staking,
        ComptrollerInterface _unitroller,
        Whitelist _whitelist,
        address[] memory _marketAddresses,
        string[] memory _marketNames,
        uint256[] memory _marketBaseSupplySpeeds,
        uint256[] memory _marketBaseBorrowSpeeds
    ) {
        ROUTER = _router;
        VOTING = _voting;
        STAKING = _staking;
        UNITROLLER = _unitroller;
        WHITELIST = _whitelist;
        markets = _marketAddresses;

        for (uint256 i = 0; i < markets.length; i++) {
            MarketInfo memory market;
            market.marketAddress = _marketAddresses[i];
            market.marketName = _marketNames[i];
            market.marketBaseSupplySpeed = _marketBaseSupplySpeeds[i];
            market.marketBaseBorrowSpeed = _marketBaseBorrowSpeeds[i];
            tokenMapping[_marketNames[i]] = market;
        }
    }

    function updateStakingRewards() internal {
        bool stakingPaused = STAKING.paused();
        if (!stakingPaused) {
            ROUTER.withdrawRewards(markets);
        }
    }

    function updateLODESpeeds() internal {
        bool votingPaused = VOTING.paused();

        if (!votingPaused) {
            (string[] memory tokens, , uint256[] memory speeds) = VOTING.getResults();

            uint8 n = uint8(tokens.length);

            address[] memory marketAddresses = new address[](n);
            uint256[] memory supplySpeeds = new uint256[](n);
            uint256[] memory borrowSpeeds = new uint256[](n);

            for (uint8 i = 0; i < n; i++) {
                MarketInfo memory market = tokenMapping[tokens[i]];
                uint256 marketBaseSupplySpeed = market.marketBaseSupplySpeed;
                uint256 marketBaseBorrowSpeed = market.marketBaseBorrowSpeed;
                address marketAddress = market.marketAddress;

                uint8 supplySpeedIndex = i * 2;
                uint8 borrowSpeedIndex = supplySpeedIndex + 1;

                uint256 supplySpeed = speeds[supplySpeedIndex];
                uint256 borrowSpeed = speeds[borrowSpeedIndex];

                marketAddresses[i] = marketAddress;
                supplySpeeds[i] = supplySpeed + marketBaseSupplySpeed;
                borrowSpeeds[i] = borrowSpeed + marketBaseBorrowSpeed;
            }

            UNITROLLER._setCompSpeeds(marketAddresses, supplySpeeds, borrowSpeeds);
        }
    }

    function update() external {
        require(WHITELIST.isWhitelisted(msg.sender), "LodestarHandler: Unauthorized");
        updateStakingRewards();
        updateLODESpeeds();
        emit Updated(block.timestamp);
    }

    //ADMIN FUNCTIONS

    event RouterUpdated(
        RouterInterface indexed oldRouter,
        RouterInterface indexed newRouter,
        uint256 indexed timestamp
    );

    event VotingUpdated(
        VotingInterface indexed oldRouter,
        VotingInterface indexed newRouter,
        uint256 indexed timestamp
    );

    event UnitrollerUpdated(
        ComptrollerInterface indexed oldRouter,
        ComptrollerInterface indexed newRouter,
        uint256 indexed timestamp
    );

    event WhitelistUpdated(Whitelist indexed oldRouter, Whitelist indexed newRouter, uint256 indexed timestamp);

    event MarketAdded(
        address indexed newMarket,
        string indexed newMarketName,
        uint256 baseSupplySpeed,
        uint256 baseBorrowSpeed,
        uint256 timestamp
    );

    event MarketUpdated(
        address indexed market,
        string indexed marketName,
        uint256 baseSupplySpeed,
        uint256 baseBorrowSpeed,
        uint256 timestamp
    );

    function updateRouter(RouterInterface newRouter) external onlyOwner {
        require(address(newRouter) != address(0), "LodestarHandler: Invalid Router Address");
        RouterInterface oldRouter = ROUTER;
        ROUTER = newRouter;
        emit RouterUpdated(oldRouter, newRouter, block.timestamp);
    }

    function updateVoting(VotingInterface newVoting) external onlyOwner {
        require(address(newVoting) != address(0), "LodestarHandler: Invalid Voting Address");
        VotingInterface oldVoting = VOTING;
        VOTING = newVoting;
        emit VotingUpdated(oldVoting, newVoting, block.timestamp);
    }

    function updateUnitroller(ComptrollerInterface newUnitroller) external onlyOwner {
        require(address(newUnitroller) != address(0), "LodestarHandler: Invalid Unitroller Address");
        ComptrollerInterface oldUnitroller = UNITROLLER;
        UNITROLLER = newUnitroller;
        emit UnitrollerUpdated(oldUnitroller, newUnitroller, block.timestamp);
    }

    function updateWhitelist(Whitelist newWhitelist) external onlyOwner {
        require(address(newWhitelist) != address(0), "LodestarHandler: Invalid Whitelist Address");
        Whitelist oldWhitelist = WHITELIST;
        WHITELIST = newWhitelist;
        emit WhitelistUpdated(oldWhitelist, newWhitelist, block.timestamp);
    }

    function addMarket(
        address newMarketAddress,
        string memory newMarketName,
        uint256 baseSupplySpeed,
        uint256 baseBorrowSpeed,
        bool isNewMarket
    ) external onlyOwner {
        require(address(newMarketAddress) != address(0), "LodestarHandler: Invalid Market Address");

        if (!isNewMarket) {
            tokenMapping[newMarketName].marketAddress = newMarketAddress;
            tokenMapping[newMarketName].marketName = newMarketName;
            tokenMapping[newMarketName].marketBaseSupplySpeed = baseSupplySpeed;
            tokenMapping[newMarketName].marketBaseBorrowSpeed = baseBorrowSpeed;
            emit MarketUpdated(newMarketAddress, newMarketName, baseSupplySpeed, baseBorrowSpeed, block.timestamp);
        } else {
            MarketInfo memory market;
            market.marketAddress = newMarketAddress;
            market.marketName = newMarketName;
            market.marketBaseSupplySpeed = baseSupplySpeed;
            market.marketBaseBorrowSpeed = baseBorrowSpeed;
            tokenMapping[newMarketName] = market;
            markets.push(newMarketAddress);
            emit MarketAdded(newMarketAddress, newMarketName, baseSupplySpeed, baseBorrowSpeed, block.timestamp);
        }
    }
}

//SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import "@openzeppelin/contracts/access/Ownable2Step.sol";

contract Whitelist is Ownable2Step {
    mapping(address => bool) public isWhitelisted;

    function updateWhitelist(
        address _address,
        bool _isActive
    ) external onlyOwner {
        isWhitelisted[_address] = _isActive;
    }

    function getWhitelisted(address _address) external view returns (bool) {
        return isWhitelisted[_address];
    }
}