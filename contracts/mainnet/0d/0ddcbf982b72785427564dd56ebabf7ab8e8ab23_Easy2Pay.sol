// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title A payment requesting contract
/// @author Lulox
/// @notice You can use this contract for requesting payments with a reason
/// @dev This is a base contract that requires further development to include payment in other tokens
contract Easy2Pay {
    /*//////////////////////////////////////////////////////////////
                                STRUCTS
    //////////////////////////////////////////////////////////////*/

    struct PayRequest {
        address requester;
        uint256 requestId;
        address payer;
        uint256 amount;
        string reason;
        bool completed;
    }

    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    AggregatorV3Interface internal ethUsdPriceFeed;
    IERC20 internal usdcToken;

    uint256 public requestCount;
    mapping(uint256 => PayRequest) public payRequestsById;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event RequestCreated(
        uint256 indexed requestId,
        address indexed requester,
        address indexed payer,
        uint256 amount,
        string reason,
        uint256 creationTime
    );
    event RequestPaid(uint256 indexed requestId);

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    error Easy2Pay__InvalidRequest(address requester);
    error Easy2Pay__InvalidPayer(address payer);
    error Easy2Pay__InsufficientEther(uint256 requestedAmount, uint256 actualAmount);
    error Easy2Pay__PaymentAlreadyCompleted();
    error Easy2Pay__FailedToSendEther();
    error Easy2Pay__FailedToSendUsdc();

    /*//////////////////////////////////////////////////////////////
                            PUBLIC FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    constructor(address _ethUsdPriceFeed, address _usdcTokenAddress) {
        ethUsdPriceFeed = AggregatorV3Interface(_ethUsdPriceFeed);
        usdcToken = IERC20(_usdcTokenAddress);
    }

    /**
     * @notice Request payment in ETH to a specific address with a reason
     * @param _amount How much ETH is the payer expected to pay.
     * @param _payer Who is expected to fulfill this payment
     * @param _reason The reason why this payment is being required
     */
    function requestPayment(uint248 _amount, address _payer, string memory _reason) public {
        if (_payer == msg.sender) {
            revert Easy2Pay__InvalidRequest(msg.sender);
        }

        PayRequest memory newRequest = PayRequest({
            requester: msg.sender,
            requestId: requestCount,
            payer: _payer,
            amount: _amount,
            reason: _reason,
            completed: false
        });

        payRequestsById[requestCount] = newRequest;

        emit RequestCreated(requestCount, msg.sender, _payer, _amount, _reason, block.timestamp);

        requestCount++;
    }

    /**
     * @notice Pay a previously created PayRequest by sending ETH
     * @param _requestId ID for the PayRequest being paid
     */
    function pay(uint256 _requestId) public payable {
        PayRequest storage request = payRequestsById[_requestId];

        if (request.payer != msg.sender) {
            revert Easy2Pay__InvalidPayer(msg.sender);
        }

        if (msg.value < request.amount) {
            revert Easy2Pay__InsufficientEther(request.amount, msg.value);
        }

        if (request.completed) revert Easy2Pay__PaymentAlreadyCompleted();

        request.completed = true;

        (bool sent,) = request.requester.call{value: msg.value}("");
        if (!sent) revert Easy2Pay__FailedToSendEther();
        emit RequestPaid(_requestId);
    }

    /**
     * @notice Pay a previously created PayRequest by sending USDC
     * @param _requestId ID for the PayRequest being paid
     */
    function payWithUsdc(uint256 _requestId) public {
        PayRequest storage request = payRequestsById[_requestId];

        if (request.payer != msg.sender) {
            revert Easy2Pay__InvalidPayer(msg.sender);
        }

        if (request.completed) revert Easy2Pay__PaymentAlreadyCompleted();

        // Fetch the latest ETH price
        uint256 ethPrice = getLatestEthPrice();

        // Convert the requested ETH amount to USDC (6 decimals) using the ETH price
        uint256 usdcAmount = (ethPrice * request.amount) / (1e18 / 1e6); // Scaling to 6 decimals

        // Ensure the payer has enough USDC
        require(usdcToken.balanceOf(msg.sender) >= usdcAmount, "Insufficient USDC");

        // Transfer USDC from the payer to the requester
        usdcToken.transferFrom(msg.sender, request.requester, usdcAmount);

        request.completed = true;

        emit RequestPaid(_requestId);
    }

    /*//////////////////////////////////////////////////////////////
                             VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice View information about a PayRequest
     * @param _requestId ID for the PayRequest being consulted
     * @return PayRequest A struct containing info about the consulted PayRequest
     */
    function getRequest(uint256 _requestId) public view returns (PayRequest memory) {
        require(_requestId <= requestCount, "Invalid requestId");
        return payRequestsById[_requestId];
    }

    function getLatestEthPrice() internal view returns (uint256) {
        (, int256 answer,,,) = ethUsdPriceFeed.latestRoundData(); // Use ethUsdPriceFeed here
        // ETH/USD rate in 18 digit
        return uint256(answer * 10000000000);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
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
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.20;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
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
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}