// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Simple single owner authorization mixin.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/auth/Owned.sol)
abstract contract Owned {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnershipTransferred(address indexed user, address indexed newOwner);

    /*//////////////////////////////////////////////////////////////
                            OWNERSHIP STORAGE
    //////////////////////////////////////////////////////////////*/

    address public owner;

    modifier onlyOwner() virtual {
        require(msg.sender == owner, "UNAUTHORIZED");

        _;
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner) {
        owner = _owner;

        emit OwnershipTransferred(address(0), _owner);
    }

    /*//////////////////////////////////////////////////////////////
                             OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

    function transferOwnership(address newOwner) public virtual onlyOwner {
        owner = newOwner;

        emit OwnershipTransferred(msg.sender, newOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    function getRoundData(uint80 _roundId)
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);

    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.4;

import {Owned} from "solmate/auth/Owned.sol";
import "../interfaces/AggregatorV3Interface.sol";

contract MockAggregatorV3 is AggregatorV3Interface, Owned {
    /* -------------------------------------------------------------------------- */
    /*                                  CONSTANTS                                 */
    /* -------------------------------------------------------------------------- */
    uint256 public constant override version = 0;

    /* -------------------------------------------------------------------------- */
    /*                                  VARIABLES                                 */
    /* -------------------------------------------------------------------------- */
    uint8 public override decimals;
    string internal s_description;

    int256 public latestAnswer;
    uint256 public latestTimestamp;
    uint256 public latestRound;

    mapping(uint256 => int256) public getAnswer;
    mapping(uint256 => uint256) private getStartedAt;
    mapping(uint256 => uint256) public getTimestamp;

    /* -------------------------------------------------------------------------- */
    /*                                 CONSTRUCTOR                                */
    /* -------------------------------------------------------------------------- */
    constructor(uint8 _decimals, string memory _description, int256 _initialAnswer) Owned(msg.sender) {
        decimals = _decimals;
        s_description = _description;
        updateAnswer(_initialAnswer);
    }

    /* -------------------------------------------------------------------------- */
    /*                                 GET METHODS                                */
    /* -------------------------------------------------------------------------- */
    function description() external view override returns (string memory) {
        return s_description;
    }

    function getRoundData(uint80 _roundId)
        external
        view
        override
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        return (_roundId, getAnswer[_roundId], getStartedAt[_roundId], getTimestamp[_roundId], _roundId);
    }

    function latestRoundData()
        external
        view
        override
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        return (
            uint80(latestRound),
            getAnswer[latestRound],
            getStartedAt[latestRound],
            getTimestamp[latestRound],
            uint80(latestRound)
        );
    }

    /* -------------------------------------------------------------------------- */
    /*                                 SET METHODS                                */
    /* -------------------------------------------------------------------------- */
    /// @notice Update specific round data
    function updateRoundData(uint80 _roundId, int256 _answer, uint256 _startAt, uint256 _timestamp)
        external
        onlyOwner
    {
        getAnswer[_roundId] = _answer;
        getStartedAt[_roundId] = _startAt;
        getTimestamp[_roundId] = _timestamp;
    }

    /// @notice Update answer for latest round, increase the latest round counter by one
    function updateAnswer(int256 _answer) public onlyOwner {
        latestAnswer = _answer;
        latestTimestamp = block.timestamp;
        latestRound++;
        getAnswer[latestRound] = _answer;
        getStartedAt[latestRound] = block.timestamp;
        getTimestamp[latestRound] = block.timestamp;
    }
}