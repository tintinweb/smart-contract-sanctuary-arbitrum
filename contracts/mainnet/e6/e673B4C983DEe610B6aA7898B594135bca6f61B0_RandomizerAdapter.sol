// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IACLManager {
    function addEmergencyAdmin(address _admin) external;

    function isEmergencyAdmin(address _admin) external view returns (bool);

    function removeEmergencyAdmin(address _admin) external;

    function addGovernance(address _governance) external;

    function isGovernance(address _governance) external view returns (bool);

    function removeGovernance(address _governance) external;

    function addOperator(address _operator) external;

    function isOperator(address _operator) external view returns (bool);

    function removeOperator(address _operator) external;

    function addBidsContract(address _bids) external;

    function isBidsContract(address _bids) external view returns (bool);

    function removeBidsContract(address _bids) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBids {
    function draw(uint256 raffleId) external;

    function drawCallback(uint256 raffleId, uint256 randomNumber) external;

    function getCurrentRaffleId() external view returns (uint256);

    function isAvailableToDraw(uint256 raffleId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRandomizerAdapter {
    function requestRandomNumber(uint256 raffleId) external returns (uint256);

    function randomizerCallback(uint256 _id, bytes32 _value) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IRandomizerAdapter.sol";
import "../interfaces/IBids.sol";
import "../interfaces/IACLManager.sol";

interface IRandomizer {
    function request(uint256 callbackGasLimit) external returns (uint256);

    function request(
        uint256 callbackGasLimit,
        uint256 confirmations
    ) external returns (uint256);

    function clientWithdrawTo(address _to, uint256 _amount) external;
}

contract RandomizerAdapter is IRandomizerAdapter {
    IRandomizer public immutable randomizer;
    IACLManager public immutable aclManager;

    struct RaffleInfo {
        address bidPool;
        uint256 raffleId;
    }

    mapping(uint256 => RaffleInfo) public raffles;

    modifier onlyRandomizer {
        require(msg.sender == address(randomizer), "ONLY_RANDOMIZER");
        _;
    }

    modifier onlyGovernance {
        require(aclManager.isGovernance(msg.sender), "ONLY_GOVERNANCE_ROLE");
        _;
    }

    modifier onlyBids() {
        require(aclManager.isBidsContract(msg.sender), "ONLY_BIDS_CONTRACT");
        _;
    }

    constructor(address _randomizer, address _aclManager) {
        randomizer = IRandomizer(_randomizer);
        aclManager = IACLManager(_aclManager);
    }

    function requestRandomNumber(uint256 raffleId) external onlyBids returns (uint256) {
        uint256 requestId = randomizer.request(500000);
        raffles[requestId] = RaffleInfo({
            bidPool: msg.sender,
            raffleId: raffleId
        });
        return requestId;
    }

    function randomizerCallback(uint256 requestId, bytes32 value) external onlyRandomizer {
        RaffleInfo memory raffleInfo = raffles[requestId];
        IBids(raffleInfo.bidPool).drawCallback(raffleInfo.raffleId, uint256(value));
    }

    function randomizerWithdraw(uint256 amount) external onlyGovernance {
        randomizer.clientWithdrawTo(msg.sender, amount);
    }
}