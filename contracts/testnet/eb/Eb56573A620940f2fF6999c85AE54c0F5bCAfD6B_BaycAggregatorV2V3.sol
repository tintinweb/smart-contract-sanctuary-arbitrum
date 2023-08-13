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

// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";

import {AggregatorV2V3Interface} from "./interfaces/AggregatorV2V3Interface.sol";
import {IOracleContract} from "./interfaces/IOracleContract.sol";

contract BaycAggregatorV2V3 is AggregatorV2V3Interface, Ownable {
    uint256 public roundId = 0;
    uint256 public keyDecimals = 0;

    struct Entry {
        uint80 roundId;
        int256 answer;
        uint256 startedAt;
        uint256 updatedAt;
        uint80 answeredInRound;
    }

    mapping(uint256 => Entry) public entries;

    address public diaOracle;
    address public ethAggregator;

    function setDiaOracle(address _diaOracle) external onlyOwner {
        diaOracle = _diaOracle;
    }

    function getDiaOracle() external view returns (address) {
        return diaOracle;
    }

    function setEthAggregator(address _ethAggregator) external onlyOwner {
        ethAggregator = _ethAggregator;
    }

    function getEthAggregator() external view returns (address) {
        return ethAggregator;
    }

    // Mock setup function
    function setLatestAnswer() external {        
        uint256 _priceBaycETH = 0;
        uint256 _timestamp = 0;
        (_priceBaycETH, _timestamp) = IOracleContract(diaOracle).getValue("Ethereum-0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D-FloorMA");
        
        bool updateAnswer = true;

        if( roundId > 0 ){
            Entry memory entry = entries[roundId];
            if( _timestamp == entry.updatedAt ){
                updateAnswer = false;
            }
        } 

        if (!updateAnswer) {
            revert("Latest answer updated already");
        }

        int256 _priceEth = 0;        
        (, _priceEth, , , ) = AggregatorV2V3Interface(ethAggregator).latestRoundData();
        uint256 ethDecimal = AggregatorV2V3Interface(ethAggregator).decimals();

        uint256 _priceBaycUSD = 0;
        _priceBaycUSD = (_priceBaycETH  / (10**ethDecimal)) * (uint256(_priceEth) / (10**keyDecimals)) * (10**keyDecimals);

        roundId++;
        entries[roundId] = Entry({
            roundId: uint80(roundId),
            answer: int256(_priceBaycUSD),
            startedAt: _timestamp,
            updatedAt: _timestamp,
            answeredInRound: uint80(roundId)
        });
    }

    function setDecimals(uint8 _decimals) external onlyOwner {
        keyDecimals = _decimals;
    }

    function latestRoundData()
        external
        view
        returns (
            uint80,
            int256,
            uint256,
            uint256,
            uint80
        )
    {
        return getRoundData(uint80(latestRound()));
    }

    function latestRound() public view returns (uint256) {
        return roundId;
    }

    function decimals() external view returns (uint8) {
        return uint8(keyDecimals);
    }

    function getAnswer(uint256 _roundId) external view returns (int256) {
        Entry memory entry = entries[_roundId];
        return entry.answer;
    }

    function getTimestamp(uint256 _roundId) external view returns (uint256) {
        Entry memory entry = entries[_roundId];
        return entry.updatedAt;
    }

    function latestAnswer() public view returns (int256) {
        Entry memory entry = entries[uint80(latestRound())];
        // Emulate a Chainlink aggregator
        return entry.answer;
    }

    function getRoundData(uint80 _roundId)
        public
        view
        returns (
            uint80,
            int256,
            uint256,
            uint256,
            uint80
        )
    {
        Entry memory entry = entries[_roundId];
        // Emulate a Chainlink aggregator
        return (entry.roundId, entry.answer, entry.startedAt, entry.updatedAt, entry.answeredInRound);
    }
}

// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.18;

interface AggregatorV2V3Interface {
    function latestRound() external view returns (uint256);

    function decimals() external view returns (uint8);

    function getAnswer(uint256 roundId) external view returns (int256);

    function getTimestamp(uint256 roundId) external view returns (uint256);

    function getRoundData(uint80 _roundId)
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.18;

interface IOracleContract {
    // Events
    event OracleUpdate(string key, uint128 value, uint128 timestamp);
    event UpdaterAddressChange(address newUpdater);

    // Functions
    function getValue(string calldata key) external view returns (uint128 value, uint128 timestamp);
    function setValue(string calldata key, uint128 value, uint128 timestamp) external;
    function updateOracleUpdaterAddress(address newOracleUpdaterAddress) external;
    function values(string calldata key) external view returns (uint256);
}