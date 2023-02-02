// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IAuthorizationUtilsV0.sol";
import "./ITemplateUtilsV0.sol";
import "./IWithdrawalUtilsV0.sol";

interface IAirnodeRrpV0 is
    IAuthorizationUtilsV0,
    ITemplateUtilsV0,
    IWithdrawalUtilsV0
{
    event SetSponsorshipStatus(
        address indexed sponsor,
        address indexed requester,
        bool sponsorshipStatus
    );

    event MadeTemplateRequest(
        address indexed airnode,
        bytes32 indexed requestId,
        uint256 requesterRequestCount,
        uint256 chainId,
        address requester,
        bytes32 templateId,
        address sponsor,
        address sponsorWallet,
        address fulfillAddress,
        bytes4 fulfillFunctionId,
        bytes parameters
    );

    event MadeFullRequest(
        address indexed airnode,
        bytes32 indexed requestId,
        uint256 requesterRequestCount,
        uint256 chainId,
        address requester,
        bytes32 endpointId,
        address sponsor,
        address sponsorWallet,
        address fulfillAddress,
        bytes4 fulfillFunctionId,
        bytes parameters
    );

    event FulfilledRequest(
        address indexed airnode,
        bytes32 indexed requestId,
        bytes data
    );

    event FailedRequest(
        address indexed airnode,
        bytes32 indexed requestId,
        string errorMessage
    );

    function setSponsorshipStatus(address requester, bool sponsorshipStatus)
        external;

    function makeTemplateRequest(
        bytes32 templateId,
        address sponsor,
        address sponsorWallet,
        address fulfillAddress,
        bytes4 fulfillFunctionId,
        bytes calldata parameters
    ) external returns (bytes32 requestId);

    function makeFullRequest(
        address airnode,
        bytes32 endpointId,
        address sponsor,
        address sponsorWallet,
        address fulfillAddress,
        bytes4 fulfillFunctionId,
        bytes calldata parameters
    ) external returns (bytes32 requestId);

    function fulfill(
        bytes32 requestId,
        address airnode,
        address fulfillAddress,
        bytes4 fulfillFunctionId,
        bytes calldata data,
        bytes calldata signature
    ) external returns (bool callSuccess, bytes memory callData);

    function fail(
        bytes32 requestId,
        address airnode,
        address fulfillAddress,
        bytes4 fulfillFunctionId,
        string calldata errorMessage
    ) external;

    function sponsorToRequesterToSponsorshipStatus(
        address sponsor,
        address requester
    ) external view returns (bool sponsorshipStatus);

    function requesterToRequestCountPlusOne(address requester)
        external
        view
        returns (uint256 requestCountPlusOne);

    function requestIsAwaitingFulfillment(bytes32 requestId)
        external
        view
        returns (bool isAwaitingFulfillment);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAuthorizationUtilsV0 {
    function checkAuthorizationStatus(
        address[] calldata authorizers,
        address airnode,
        bytes32 requestId,
        bytes32 endpointId,
        address sponsor,
        address requester
    ) external view returns (bool status);

    function checkAuthorizationStatuses(
        address[] calldata authorizers,
        address airnode,
        bytes32[] calldata requestIds,
        bytes32[] calldata endpointIds,
        address[] calldata sponsors,
        address[] calldata requesters
    ) external view returns (bool[] memory statuses);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITemplateUtilsV0 {
    event CreatedTemplate(
        bytes32 indexed templateId,
        address airnode,
        bytes32 endpointId,
        bytes parameters
    );

    function createTemplate(
        address airnode,
        bytes32 endpointId,
        bytes calldata parameters
    ) external returns (bytes32 templateId);

    function getTemplates(bytes32[] calldata templateIds)
        external
        view
        returns (
            address[] memory airnodes,
            bytes32[] memory endpointIds,
            bytes[] memory parameters
        );

    function templates(bytes32 templateId)
        external
        view
        returns (
            address airnode,
            bytes32 endpointId,
            bytes memory parameters
        );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IWithdrawalUtilsV0 {
    event RequestedWithdrawal(
        address indexed airnode,
        address indexed sponsor,
        bytes32 indexed withdrawalRequestId,
        address sponsorWallet
    );

    event FulfilledWithdrawal(
        address indexed airnode,
        address indexed sponsor,
        bytes32 indexed withdrawalRequestId,
        address sponsorWallet,
        uint256 amount
    );

    function requestWithdrawal(address airnode, address sponsorWallet) external;

    function fulfillWithdrawal(
        bytes32 withdrawalRequestId,
        address airnode,
        address sponsor
    ) external payable;

    function sponsorToWithdrawalRequestCount(address sponsor)
        external
        view
        returns (uint256 withdrawalRequestCount);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IAirnodeRrpV0.sol";

/// @title The contract to be inherited to make Airnode RRP requests
contract RrpRequesterV0 {
    IAirnodeRrpV0 public immutable airnodeRrp;

    /// @dev Reverts if the caller is not the Airnode RRP contract.
    /// Use it as a modifier for fulfill and error callback methods, but also
    /// check `requestId`.
    modifier onlyAirnodeRrp() {
        require(msg.sender == address(airnodeRrp), "Caller not Airnode RRP");
        _;
    }

    /// @dev Airnode RRP address is set at deployment and is immutable.
    /// RrpRequester is made its own sponsor by default. RrpRequester can also
    /// be sponsored by others and use these sponsorships while making
    /// requests, i.e., using this default sponsorship is optional.
    /// @param _airnodeRrp Airnode RRP contract address
    constructor(address _airnodeRrp) {
        airnodeRrp = IAirnodeRrpV0(_airnodeRrp);
        IAirnodeRrpV0(_airnodeRrp).setSponsorshipStatus(address(this), true);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "airnode/contracts/rrp/requesters/RrpRequesterV0.sol";

contract Lottery is RrpRequesterV0 {
    uint256 constant FEE_TAKE = 30; // 3 basis points
    uint256 constant FEE_MULTIPLE = 10_000;

    uint256 public roundNumber;
    uint256 public totalPayouts;
    uint256 public roundTotalEth;

    uint256 public queuedWager;
    uint256 public queuedRoundMax;
    uint256 public wager;
    uint256 public roundMax;

    bool public resolveCalled;
    //QRNG
    bytes32 endpointIdUint256;
    address airnode;
    address public sponsorWallet;

    address public owner;

    mapping(address => uint256) public payouts;
    mapping(bytes32 => bool) expectingRequestWithIdToBeFulfilled;
    address[] public users;

    constructor(address _airnodeRrp, uint256 _wager, uint256 _roundMax) RrpRequesterV0(_airnodeRrp) {
        checkLotteryParams(_wager, _roundMax);
        wager = _wager;
        roundMax = _roundMax;
        owner = msg.sender;
    }

    function checkLotteryParams(uint256 _wager, uint256 _roundMax) internal pure {
        // if roundMax is too low, fee isnt large enough to cover gas cost of API3 QRNG
        if (_roundMax < 1 ether || _wager == 0 || _wager == _roundMax || _roundMax % _wager != 0) {
            revert Lottery_BadParams();
        }
    }

    function getUsers() external view returns (address[] memory) {
        return users;
    }

    function enter() external payable {
        if (airnode == address(0)) revert Lottery_AirnodeNotInitialized();
        if (msg.value == 0 || msg.value % wager != 0 || roundTotalEth + msg.value > roundMax) {
            revert Lottery_WrongAmount();
        }
        roundTotalEth += msg.value;

        uint256 ticketsBought = msg.value / wager;

        for (uint256 i = 0; i < ticketsBought; ++i) {
            users.push(msg.sender);
        }
        emit Wager(msg.sender, roundNumber, msg.value, ticketsBought);
    }

    function queueResolve(address _to) external {
        if (resolveCalled) revert Lottery_ResolveAlreadyCalled();
        uint256 totalEth = roundTotalEth;
        if (totalEth != roundMax) revert Lottery_RoundNotOver();

        resolveCalled = true;

        // 1/3 of overall fee amount
        uint256 tip = totalEth * FEE_TAKE / FEE_MULTIPLE / 3;

        // Fund sponsorWallet so it can pay gas for API3 QRNG
        (bool success,) = sponsorWallet.call{value: tip}("");
        if (!success) revert Lottery_SponsorWalletFundingFailed();

        bytes32 requestId = airnodeRrp.makeFullRequest(
            airnode, endpointIdUint256, address(this), sponsorWallet, address(this), this.resolve.selector, ""
        );
        expectingRequestWithIdToBeFulfilled[requestId] = true;

        // Give _to a tip to incentivize this function getting called ASAP
        (bool tipSuccess,) = _to.call{value: tip}("");
        if (!tipSuccess) revert Lottery_ResolveTipFailed();

        emit QueueResolve(msg.sender, roundNumber);
    }

    function resolve(bytes32 requestId, bytes calldata data) external onlyAirnodeRrp {
        if (!expectingRequestWithIdToBeFulfilled[requestId]) revert Lottery_IDNotKnown();
        expectingRequestWithIdToBeFulfilled[requestId] = false;

        address[] memory _users = users;
        uint256 usersLength = _users.length;

        uint256 totalEth = roundTotalEth;
        uint256 fee = (totalEth * FEE_TAKE / FEE_MULTIPLE);
        totalEth -= fee;

        uint256 winningsPerUser = totalEth / (usersLength - 1);
        totalEth = (winningsPerUser * (usersLength - 1)); //account for round down dust
        totalPayouts += totalEth;

        uint256 loserIndex = abi.decode(data, (uint256)) % usersLength;
        for (uint256 i = 0; i < usersLength; ++i) {
            if (i != loserIndex) {
                payouts[_users[i]] += winningsPerUser;
            }
        }

        emit RoundComplete(roundNumber, totalEth, winningsPerUser, fee);
        roundNumber++;
        maybeUpdateLotteryParams();
        delete roundTotalEth;
        delete users;
        delete resolveCalled;
    }

    function maybeUpdateLotteryParams() internal {
        if (queuedWager != 0 && queuedRoundMax != 0) {
            wager = queuedWager;
            roundMax = queuedRoundMax;
            emit UpdateLotteryParams(queuedWager, queuedRoundMax);
            delete queuedWager;
            delete queuedRoundMax;
        }
    }

    function withdraw(address _to) external {
        if (payouts[msg.sender] == 0) revert Lottery_NoPayoutAvailable();
        uint256 amount = payouts[msg.sender];
        payouts[msg.sender] = 0;
        totalPayouts -= amount;
        (bool success,) = _to.call{value: amount}("");
        if (!success) revert Lottery_WithdrawFailed();
        emit Withdraw(msg.sender, _to, amount);
    }

    function queueLotteryParams(uint256 _wager, uint256 _roundMax) external onlyOwner {
        checkLotteryParams(_wager, _roundMax);

        if (_wager == wager && _roundMax == roundMax || _wager == queuedWager && _roundMax == queuedRoundMax) {
            revert Lottery_BadParams();
        }
        queuedRoundMax = _roundMax;
        queuedWager = _wager;
    }

    //TODO: maybe add functionality to withdraw under some catastrophic situation like API3 doesnt work anymore
    function ownerWithdraw(address _to) external onlyOwner {
        // Owner can only withdraw owner's share of fees and dust from payout division
        uint256 amount = address(this).balance - totalPayouts - roundTotalEth;
        if (amount == 0) revert Lottery_NoPayoutAvailable();
        (bool success,) = _to.call{value: amount}("");
        if (!success) revert Lottery_WithdrawFailed();
        emit OwnerWithdraw(_to, amount);
    }

    function setRequestParameters(address _airnode, bytes32 _endpointIdUint256, address _sponsorWallet)
        external
        onlyOwner
    {
        // endpointIdUint256 is allowed to be 0
        if (_airnode == address(0) || _sponsorWallet == address(0)) {
            revert Lottery_AirnodeBadParams();
        }
        airnode = _airnode;
        endpointIdUint256 = _endpointIdUint256;
        sponsorWallet = _sponsorWallet;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) revert Lottery_OnlyOwner();
        _;
    }

    event Wager(address indexed user, uint256 indexed _roundNumber, uint256 _value, uint256 _tickets);
    event RoundComplete(uint256 indexed _roundNumber, uint256 _totalPot, uint256 _winAmtPerUser, uint256 fee);
    event QueueResolve(address indexed _caller, uint256 indexed _roundNumber);
    event UpdateLotteryParams(uint256 _wager, uint256 _roundMax);
    event Withdraw(address indexed user, address indexed _to, uint256 _value);
    event OwnerWithdraw(address indexed _to, uint256 _value);

    error Lottery_OnlyOwner();
    error Lottery_WrongAmount();
    error Lottery_BadParams();
    error Lottery_RoundNotOver();
    error Lottery_NoPayoutAvailable();
    error Lottery_WithdrawFailed();
    error Lottery_IDNotKnown();
    error Lottery_ResolveAlreadyCalled();
    error Lottery_SponsorWalletFundingFailed();
    error Lottery_ResolveTipFailed();
    error Lottery_AirnodeNotInitialized();
    error Lottery_AirnodeBadParams();
}