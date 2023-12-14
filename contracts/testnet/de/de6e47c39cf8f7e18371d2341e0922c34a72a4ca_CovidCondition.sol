// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "./interfaces/IAzuranceCondition.sol";
import "./interfaces/IAzurancePool.sol";
import "./interfaces/ICovidFunction.sol";

contract CovidCondition is IAzuranceCondition {
    ICovidFunction public covidFunction;

    constructor(address _covidFunctionAddress) {
        covidFunction = ICovidFunction(_covidFunctionAddress);
    }

    bytes32 public s_lastRequestId;

    event ResponseDetected(
        bytes32 indexed requestId,
        string character,
        bytes response,
        bytes err
    );

    function checkUnlockClaim(address target) external override {
        IAzurancePool(target).unlockClaim();
    }

    function checkUnlockTerminate(address target) external override {
        IAzurancePool(target).unlockTerminate();
    }

    function sendRequest(
        uint64 subscriptionId,
        string[] memory args
    ) external returns (bytes32 requestId) {
        if (args.length == 0) {
            revert ICovidFunction.EmptyArgs();
        }

        string memory character = args[0];
        if (bytes(character).length == 0) {
            revert ICovidFunction.EmptySource();
        }

        requestId = covidFunction.sendRequest(subscriptionId, args);
        s_lastRequestId = requestId;
    }

    function handleResponse(
        bytes32 _requestId,
        string memory _character,
        bytes memory _response,
        bytes memory _err
    ) public {
        emit ResponseDetected(_requestId, _character, _response, _err);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

interface IAzuranceCondition {
    function checkUnlockClaim(address target) external ;
    function checkUnlockTerminate(address target) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

interface IAzurancePool {
    // Enum for the state of the pool
    enum State {
        Ongoing,
        Claimable,
        Matured,
        Terminated
    }

    // Events
    event InsuranceBought(address indexed buyer, address token, uint256 amount);
    event InsuranceSold(address indexed seller, address token, uint256 amount);
    event StateChanged(State oldState, State newState);
    event Withdrew(address token, uint256 amount, address indexed to);

    // State variables
    function multiplier() external view returns (uint256);
    function multiplierDecimals() external view returns (uint256);
    function maturityBlock() external view returns (uint256);
    function staleBlock() external view returns (uint256);
    function underlyingToken() external view returns (address);
    function fee() external view returns (uint256);
    function feeDecimals() external view returns (uint256);
    function feeTo() external view returns (address);
    function condition() external view returns (address);
    function buyerToken() external view returns (address);
    function sellerToken() external view returns (address);
    function status() external view returns (State);

    // Write Functions
    function buyInsurance(uint256 amount) external;
    function sellInsurance(uint256 amount) external;
    function unlockClaim() external;
    function unlockMaturity() external;
    function unlockTerminate() external;
    function checkUnlockClaim() external;
    function checkUnlockTerminate() external;
    function withdraw(uint256 buyerAmount, uint256 sellerAmount) external;
    function withdrawFee(uint256 amount) external;

    // Read Functions
    function getAmountClaimable(uint256 buyerAmount, uint256 sellerAmount) external view returns (uint256);
    function getAmountMatured(uint256 buyerAmount, uint256 sellerAmount) external view returns (uint256);
    function getAmountTerminated(uint256 buyerAmount, uint256 sellerAmount) external view returns (uint256);
    function totalValueLocked() external view returns (uint256);
    function totalShares() external view returns (uint256);
    function totalSellShare() external view returns (uint256);
    function totalBuyShare() external view returns (uint256);
    function settledShare() external view returns (uint256);
    function settledSellShare() external view returns (uint256);
    function settledBuyShare() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ICovidFunction {
    function acceptOwnership() external;

    error EmptyArgs();
    error EmptySource();

    function handleOracleFulfillment(
        bytes32 requestId,
        bytes memory response,
        bytes memory err
    ) external;

    error NoInlineSecrets();
    error OnlyRouterCanFulfill();
    error UnexpectedRequestID(bytes32 requestId);
    
    event OwnershipTransferRequested(address indexed from, address indexed to);
    event OwnershipTransferred(address indexed from, address indexed to);
    event RequestFulfilled(bytes32 indexed id);
    event RequestSent(bytes32 indexed id);
    event Response(
        bytes32 indexed requestId,
        string character,
        bytes response,
        bytes err
    );

    function sendRequest(uint64 subscriptionId, string[] memory args)
        external
        returns (bytes32 requestId);

    function transferOwnership(address to) external;

    function character() external view returns (string memory);

    function owner() external view returns (address);

    function s_lastError() external view returns (bytes memory);

    function s_lastRequestId() external view returns (bytes32);

    function s_lastResponse() external view returns (bytes memory);
}