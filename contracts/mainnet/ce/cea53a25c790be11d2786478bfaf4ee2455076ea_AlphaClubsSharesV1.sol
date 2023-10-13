/**
 *Submitted for verification at Arbiscan.io on 2023-10-12
*/

// SPDX-License-Identifier: MIT

// File @openzeppelin/contracts/utils/[email protected]

// Original license: SPDX_License_Identifier: MIT
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


// File @openzeppelin/contracts/access/[email protected]

// Original license: SPDX_License_Identifier: MIT
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


// File contracts/AlphaClubsSharesV1.sol

// Original license: SPDX_License_Identifier: MIT
pragma solidity ^0.8.0;

// pragma solidity >=0.8.2 <0.9.0;

contract AlphaClubsSharesV1 is Ownable {
    address public platformTreasuryAddress;
    uint256 public defaultCreatorFeePercent;
    uint256 public defaultPlatformFeePercent;
    uint256 public defaultHoldersRevFeePercent;
    mapping(address => uint256) public creatorsFeePercent;
    mapping(address => uint256) public creatorsPlatformFeePercent;
    mapping(address => uint256) public creatorsHoldersRevFeePercent;
    uint256 public globalFeeMultiplier = 100;

    event InitializeCreator(address creator);
    event Trade(
        address trader,
        address creator,
        bool isBuy,
        uint256 shareAmount,
        uint256 ethAmount,
        uint256 platformEthFee,
        uint256 creatorEthFee,
        uint256 creatorHoldersRevEthFee,
        uint256 supply
    );
    event HolderRevenueDistribution(
        address creator,
        uint256 supply,
        uint256 totalRevDistributed,
        address[] holders
    );

    // Creator => (Holder => Balance)
    mapping(address => mapping(address => uint256))
        public creatorSharesHolderBalances;
    mapping(address => mapping(address => bool)) public userHeldCreators;
    // Creator => Supply;
    mapping(address => uint256) public creatorSharesSupply;
    // Creator => ShareSplits; power of 2s
    mapping(address => uint256) public creatorShareSplits;

    // Creator => Holder rev amount
    mapping(address => uint256) public creatorsHoldersRev;
    uint256 public minRevShareThreshold;

    uint256 SHARES_MULTIPLIER = 1e9;

    constructor(
        address _platformTreasuryAddress,
        uint256 _defaultCreatorFeePercent,
        uint256 _defaultPlatformFeePercent,
        uint256 _defaultHoldersRevFeePercent,
        uint256 _minRevShareThreshold
    ) {
        platformTreasuryAddress = _platformTreasuryAddress;

        defaultCreatorFeePercent = _defaultCreatorFeePercent;
        defaultPlatformFeePercent = _defaultPlatformFeePercent;
        defaultHoldersRevFeePercent = _defaultHoldersRevFeePercent;

        minRevShareThreshold = _minRevShareThreshold;
    }

    function setPlatformFeeAddress(
        address _platformTreasuryAddress
    ) public onlyOwner {
        platformTreasuryAddress = _platformTreasuryAddress;
    }

    function setDefaultFees(
        uint256 _defaultCreatorFeePercent,
        uint256 _defaultPlatformFeePercent,
        uint256 _defaultHoldersRevFeePercent
    ) public onlyOwner {
        defaultCreatorFeePercent = _defaultCreatorFeePercent;
        defaultPlatformFeePercent = _defaultPlatformFeePercent;
        defaultHoldersRevFeePercent = _defaultHoldersRevFeePercent;
    }

    function changeCreatorFeeDistribution(
        address creator,
        uint256 creatorFeePercent,
        uint256 creatorPlatformFeePercent,
        uint256 creatorHoldersRevFeePercent
    ) public onlyOwner {
        creatorsFeePercent[creator] = creatorFeePercent;
        creatorsPlatformFeePercent[creator] = creatorPlatformFeePercent;
        creatorsHoldersRevFeePercent[creator] = creatorHoldersRevFeePercent;
    }

    function setGlobalFeeMultiplier(
        uint256 _globalFeeMultiplier
    ) public onlyOwner {
        globalFeeMultiplier = _globalFeeMultiplier;
    }

    function setMinRevShareThreshold(
        uint256 _minRevShareThreshold
    ) public onlyOwner {
        minRevShareThreshold = _minRevShareThreshold;
    }

    function getPrice(
        uint256 supply,
        uint256 amount
    ) internal view returns (uint256) {
        uint256 sum1 = supply == 0
            ? 0
            : ((supply - SHARES_MULTIPLIER) *
                (supply) *
                (2 * (supply - SHARES_MULTIPLIER) + SHARES_MULTIPLIER)) / 6;
        uint256 sum2 = supply == 0 && amount == SHARES_MULTIPLIER
            ? 0
            : ((supply - SHARES_MULTIPLIER + amount) *
                (supply + amount) *
                (2 *
                    (supply - SHARES_MULTIPLIER + amount) +
                    SHARES_MULTIPLIER)) / 6;
        uint256 summation = sum2 - sum1;
        return (summation * 1 ether) / 16000 / (SHARES_MULTIPLIER ** 3);
    }

    function getBuyPrice(
        address creator,
        uint256 amount
    ) public view returns (uint256) {
        return getPrice(creatorSharesSupply[creator], amount);
    }

    function getSellPrice(
        address creator,
        uint256 amount
    ) public view returns (uint256) {
        return getPrice(creatorSharesSupply[creator] - amount, amount);
    }

    function getBuyPriceWithFee(
        address creator,
        uint256 amount
    ) public view returns (uint256) {
        uint256 price = getPrice(creatorSharesSupply[creator], amount);
        (
            uint256 platformFee,
            uint256 creatorFee,
            uint256 holdersRevFee
        ) = getFees(creator, price);
        return price + platformFee + creatorFee + holdersRevFee;
    }

    function getSellPriceAfterFee(
        address creator,
        uint256 amount
    ) public view returns (uint256) {
        uint256 price = getPrice(creatorSharesSupply[creator] - amount, amount);
        (
            uint256 platformFee,
            uint256 creatorFee,
            uint256 holdersRevFee
        ) = getFees(creator, price);
        return price - platformFee - creatorFee - holdersRevFee;
    }

    function getFees(
        address creator,
        uint256 price
    ) private view returns (uint256, uint256, uint256) {
        uint256 platformFee = (((price * creatorsPlatformFeePercent[creator]) /
            1 ether) * globalFeeMultiplier) / 100;
        uint256 creatorFee = (((price * creatorsFeePercent[creator]) /
            1 ether) * globalFeeMultiplier) / 100;
        uint256 holdersRevFee = (((price *
            creatorsHoldersRevFeePercent[creator]) / 1 ether) *
            globalFeeMultiplier) / 100;
        return (platformFee, creatorFee, holdersRevFee);
    }

    function getNumSharesHeld(
        address creator,
        address holder
    ) public view returns (uint256) {
        return
            (creatorSharesHolderBalances[creator][holder] *
                creatorShareSplits[creator]) / SHARES_MULTIPLIER;
    }

    function initializeCreator() public {
        require(
            creatorSharesSupply[msg.sender] == 0,
            "Creator already initialized"
        );
        creatorSharesHolderBalances[msg.sender][msg.sender] =
            1 *
            SHARES_MULTIPLIER;
        creatorSharesSupply[msg.sender] = 1 * SHARES_MULTIPLIER;
        creatorShareSplits[msg.sender] = 1;
        userHeldCreators[msg.sender][msg.sender] = true;

        creatorsFeePercent[msg.sender] = defaultCreatorFeePercent;
        creatorsPlatformFeePercent[msg.sender] = defaultPlatformFeePercent;
        creatorsHoldersRevFeePercent[msg.sender] = defaultHoldersRevFeePercent;

        emit InitializeCreator(msg.sender);
    }

    function increaseShareSplit(address creator) public onlyOwner {
        creatorShareSplits[creator] *= 2;
    }

    function buyShares(address creator, uint256 amount) public payable {
        uint256 supply = creatorSharesSupply[creator];
        require(supply > 0, "Creator is not yet initialized");
        require(
            amount % (SHARES_MULTIPLIER / creatorShareSplits[creator]) == 0 &&
                amount > 0,
            "Amount fractionalized passed limit for current creator share split"
        );
        uint256 price = getPrice(supply, amount);
        (
            uint256 platformFee,
            uint256 creatorFee,
            uint256 holdersRevFee
        ) = getFees(creator, price);
        require(
            msg.value >= price + platformFee + creatorFee + holdersRevFee,
            "Insufficient payment"
        );
        creatorSharesHolderBalances[creator][msg.sender] += amount;
        creatorSharesSupply[creator] += amount;
        userHeldCreators[msg.sender][creator] = true;
        creatorsHoldersRev[creator] += holdersRevFee;
        emit Trade(
            msg.sender,
            creator,
            true,
            amount,
            price,
            platformFee,
            creatorFee,
            holdersRevFee,
            supply + amount
        );
        (bool success1, ) = platformTreasuryAddress.call{value: platformFee}(
            ""
        );
        (bool success2, ) = creator.call{value: creatorFee}("");
        require(success1 && success2, "Unable to send funds");
    }

    function sellShares(address creator, uint256 amount) public payable {
        uint256 supply = creatorSharesSupply[creator];
        require(supply > amount, "Cannot sell the last share");
        require(
            amount % (SHARES_MULTIPLIER / creatorShareSplits[creator]) == 0 &&
                amount > 0,
            "Amount fractionalized passed limit for current creator share split"
        );
        uint256 price = getPrice(
            supply - amount,
            amount
            // creatorShareSplits[creator]
        );
        (
            uint256 platformFee,
            uint256 creatorFee,
            uint256 holdersRevFee
        ) = getFees(creator, price);
        require(
            creatorSharesHolderBalances[creator][msg.sender] >= amount,
            "Insufficient shares"
        );
        creatorSharesHolderBalances[creator][msg.sender] -= amount;
        creatorSharesSupply[creator] -= amount;
        if (creatorSharesHolderBalances[creator][msg.sender] <= 0)
            userHeldCreators[msg.sender][creator] = false;
        creatorsHoldersRev[creator] += holdersRevFee;
        emit Trade(
            msg.sender,
            creator,
            false,
            amount,
            price,
            platformFee,
            creatorFee,
            holdersRevFee,
            supply - amount
        );
        (bool success1, ) = msg.sender.call{
            value: price - platformFee - creatorFee - holdersRevFee
        }("");
        (bool success2, ) = platformTreasuryAddress.call{value: platformFee}(
            ""
        );
        (bool success3, ) = creator.call{value: creatorFee}("");
        require(success1 && success2 && success3, "Unable to send funds");
    }

    // Using holders as an input here because tracking them would increase cost of other functions
    function distributeCreatorHoldersRev(
        address creator,
        address[] memory holders
    ) public onlyOwner {
        uint256 revenueDistributed = 0;
        uint256 totalSharesDistributedTo = 0;
        require(
            creatorsHoldersRev[creator] >= minRevShareThreshold,
            "Not enough revenue accrued by creator to distribute to holders"
        );
        for (uint256 i = 0; i < holders.length; i++) {
            uint256 holderRev = (creatorsHoldersRev[creator] *
                creatorSharesHolderBalances[creator][holders[i]]) /
                creatorSharesSupply[creator];
            revenueDistributed += holderRev;
            totalSharesDistributedTo += creatorSharesHolderBalances[creator][
                holders[i]
            ];
            (bool success, ) = holders[i].call{value: holderRev}("");
            require(success, "Failed to distribute to holder");
        }
        emit HolderRevenueDistribution(
            creator,
            creatorSharesSupply[creator],
            revenueDistributed,
            holders
        );
        creatorsHoldersRev[creator] -= revenueDistributed;
        require(
            totalSharesDistributedTo == creatorSharesSupply[creator],
            "Missing holders to distribute revenue to"
        );
    }
}