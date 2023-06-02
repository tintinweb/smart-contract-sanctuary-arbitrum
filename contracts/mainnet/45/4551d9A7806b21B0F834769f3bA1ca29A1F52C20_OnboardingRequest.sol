// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/**
 * @title OnboardingRequest
 * @dev Interface for the DAO OnboardingRequest.
 */
interface IOnboardingRequest {
    /**
     * @notice Event emitted when a new request is added.
     * @param sender Address of the sender adding the request.
     * @param gov Address of the associated government.
     * @param index Index assigned to the request.
     */
    event AddedRequest(
        address indexed sender,
        address indexed gov,
        uint128 index
    );

    /**
     * @notice Event emitted when an existing request is removed.
     * @param gov Address of the associated government.
     * @param index Index of the removed request.
     */
    event RemovedRequest(
        address indexed gov,
        uint128 indexed index
    );

    /**
     * @notice Struct representing an onboarding request.
     * @param sender Address of the sender creating the request.
     * @param timelock Address of the associated timelock.
     * @param tokenApproved Address of the approved token for the request.
     * @param amountApproved Approved amount of the token for the request.
     * @param requestedMint Requested amount for minting.
     * @param timestamp Timestamp of the request creation.
     */
    struct Request {
        address sender;
        address timelock;
        address tokenApproved;
        uint256 amountApproved;
        uint256 requestedMint;
        uint256 timestamp;
    }

    /**
     * @notice Adds a new onboarding request.
     * @param _gov Address of the associated government.
     * @param _timelock Address of the associated timelock.
     * @param _tokenApproved Address of the approved token for the request.
     * @param _amountApproved Approved amount of the token for the request.
     * @param _requestedMint Requested amount for minting.
     */
    function addRequest(
        address _gov,
        address _timelock,
        address _tokenApproved,
        uint256 _amountApproved,
        uint256 _requestedMint
    ) external;

    /**
     * @notice Removes an existing onboarding request. Only the associated timelock can remove a request.
     * @param _gov Address of the associated government.
     * @param _index Index of the request to be removed.
     */
    function removeRequest(address _gov, uint128 _index) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interface/IOnboardingRequest.sol";

contract OnboardingRequest is IOnboardingRequest {
    // gov => index
    mapping(address => uint128) public nextIndex;
    // gov => index => Request
    mapping(address => mapping(uint128 => Request)) public requests;

    /**
     *  @inheritdoc IOnboardingRequest
     */
    function addRequest(
        address _gov,
        address _timelock,
        address _tokenApproved,
        uint256 _amountApproved,
        uint256 _requestedMint
    ) public override {
        require(
            IERC20(_tokenApproved).allowance(msg.sender, _timelock) >=
                _amountApproved,
            "Insuficient approval to add request"
        );

        Request memory newRequest = Request({
            sender: msg.sender,
            timelock: _timelock,
            tokenApproved: _tokenApproved,
            amountApproved: _amountApproved,
            requestedMint: _requestedMint,
            timestamp: block.timestamp
        });

        uint128 index = nextIndex[_gov];
        requests[_gov][index] = newRequest;
        nextIndex[_gov]++;

        emit AddedRequest(msg.sender, _gov, index);
    }


    /**
     *  @inheritdoc IOnboardingRequest
     */
    function removeRequest(address _gov, uint128 _index) public override {
        Request memory request = requests[_gov][_index];
        require(request.sender != address(0), "Request does not exist");
        require(
            request.timelock == msg.sender,
            "Only the timelock can delete a request"
        );
        delete requests[_gov][_index];
        emit RemovedRequest(_gov, _index);
    }
}