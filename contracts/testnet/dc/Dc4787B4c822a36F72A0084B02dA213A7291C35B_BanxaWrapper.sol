// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IBilling } from "./IBilling.sol";
import { Governed } from "./Governed.sol";
import { Rescuable } from "./Rescuable.sol";

/**
 * @title Banxa Wrapper
 * @dev Wraps the billing contract to provide a custom interface for the Banxa Fulfillment Service
 */
contract BanxaWrapper is Governed, Rescuable {
    // -- State --

    /// The Graph Token contract
    IERC20 public immutable graphToken;

    /// The billing contract
    IBilling public immutable billing;

    // -- Events --

    /**
     * @dev Order fullfilled by Banxa fulfilment service
     */
    event OrderFulfilled(address indexed fulfiller, address indexed to, uint256 amount);

    // -- Errors --

    /**
     * @dev Zero address not allowed.
     */
    error InvalidZeroAddress();

    /**
     * @dev Zero amount not allowed.
     */
    error InvalidZeroAmount();

    /**
     * @notice Constructor function for the contract
     * @param _token Graph Token address
     * @param _billing billing contract address
     */
    constructor(
        IERC20 _token,
        IBilling _billing,
        address _governor
    ) Governed(_governor) {
        if (address(_token) == address(0) || address(_billing) == address(0)) {
            revert InvalidZeroAddress();
        }

        graphToken = _token;
        billing = _billing;
    }

    /**
     * @notice Pulls tokens from sender and adds them into the billing contract for any user
     * Ensure graphToken.approve() is called on the wrapper contract first
     * @param _to  Address that tokens are being added to
     * @param _amount  Amount of tokens to add
     */
    function fulfil(address _to, uint256 _amount) external {
        if (_to == address(0)) {
            revert InvalidZeroAddress();
        }

        if (_amount == 0) {
            revert InvalidZeroAmount();
        }

        graphToken.transferFrom(msg.sender, address(this), _amount);
        graphToken.approve(address(billing), _amount);
        billing.addTo(_to, _amount);

        emit OrderFulfilled(msg.sender, _to, _amount);
    }

    /**
     * @notice Allows the Governor to rescue any ERC20 tokens sent to this contract by accident
     * @param _to  Destination address to send the tokens
     * @param _token  Token address of the token that was accidentally sent to the contract
     * @param _amount  Amount of tokens to pull
     */
    function rescueTokens(
        address _to,
        address _token,
        uint256 _amount
    ) external onlyGovernor {
        _rescueTokens(_to, _token, _amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

interface IBilling {
    /**
     * @dev Set or unset an address as an allowed Collector
     * @param _collector  Collector address
     * @param _enabled True to set the _collector address as a Collector, false to remove it
     */
    function setCollector(address _collector, bool _enabled) external; // onlyGovernor

    /**
     * @dev Sets the L2 token gateway address
     * @param _l2TokenGateway New address for the L2 token gateway
     */
    function setL2TokenGateway(address _l2TokenGateway) external;

    /**
     * @dev Sets the L1 Billing Connector address
     * @param _l1BillingConnector New address for the L1 BillingConnector (without any aliasing!)
     */
    function setL1BillingConnector(address _l1BillingConnector) external;

    /**
     * @dev Add tokens into the billing contract
     * @param _amount  Amount of tokens to add
     */
    function add(uint256 _amount) external;

    /**
     * @dev Add tokens into the billing contract for any user
     * @param _to  Address that tokens are being added to
     * @param _amount  Amount of tokens to add
     */
    function addTo(address _to, uint256 _amount) external;

    /**
     * @dev Receive tokens with a callhook from the Arbitrum GRT bridge
     * Expects an `address user` in the encoded _data.
     * @param _from Token sender in L1
     * @param _amount Amount of tokens that were transferred
     * @param _data ABI-encoded callhook data: contains address that tokens are being added to
     */
    function onTokenTransfer(
        address _from,
        uint256 _amount,
        bytes calldata _data
    ) external;

    /**
     * @dev Remove tokens from the billing contract, from L1
     * This can only be called from the BillingConnector on L1.
     * @param _from  Address from which the tokens are removed
     * @param _to Address to send the tokens
     * @param _amount  Amount of tokens to remove
     */
    function removeFromL1(
        address _from,
        address _to,
        uint256 _amount
    ) external;

    /**
     * @dev Add tokens into the billing contract in bulk
     * Ensure graphToken.approve() is called on the billing contract first
     * @param _to  Array of addresses where to add tokens
     * @param _amount  Array of amount of tokens to add to each account
     */
    function addToMany(address[] calldata _to, uint256[] calldata _amount) external;

    /**
     * @dev Remove tokens from the billing contract
     * Tokens will be removed from the sender's balance
     * @param _to  Address that tokens are being moved to
     * @param _amount  Amount of tokens to remove
     */
    function remove(address _to, uint256 _amount) external;

    /**
     * @dev Collector pulls tokens from the billing contract
     * @param _user  Address that tokens are being pulled from
     * @param _amount  Amount of tokens to pull
     * @param _to Destination to send pulled tokens
     */
    function pull(
        address _user,
        uint256 _amount,
        address _to
    ) external;

    /**
     * @dev Collector pulls tokens from many users in the billing contract
     * @param _users  Addresses that tokens are being pulled from
     * @param _amounts  Amounts of tokens to pull from each user
     * @param _to Destination to send pulled tokens
     */
    function pullMany(
        address[] calldata _users,
        uint256[] calldata _amounts,
        address _to
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title Rescuable contract
 * @dev Allows a contract to have a function to rescue tokens sent by mistake.
 * The contract must implement the external rescueTokens function or similar,
 * that calls this contract's _rescueTokens.
 */
contract Rescuable {
    /**
     * @dev Tokens rescued by the permissioned user
     */
    event TokensRescued(address indexed to, address indexed token, uint256 amount);

    /**
     * @dev Allows a permissioned user to rescue any ERC20 tokens sent to this contract by accident
     * @param _to  Destination address to send the tokens
     * @param _token  Token address of the token that was accidentally sent to the contract
     * @param _amount  Amount of tokens to pull
     */
    function _rescueTokens(
        address _to,
        address _token,
        uint256 _amount
    ) internal {
        require(_to != address(0), "Cannot send to address(0)");
        require(_amount != 0, "Cannot rescue 0 tokens");
        IERC20 token = IERC20(_token);
        require(token.transfer(_to, _amount), "Rescue tokens failed");
        emit TokensRescued(_to, _token, _amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

/**
 * @title Graph Governance contract
 * @dev Allows a contract to be owned and controlled by the 'governor'
 */
contract Governed {
    // -- State --

    // The address of the governor
    address public governor;
    // The address of the pending governor
    address public pendingGovernor;

    // -- Events --

    // Emit when the pendingGovernor state variable is updated
    event NewPendingOwnership(address indexed from, address indexed to);
    // Emit when the governor state variable is updated
    event NewOwnership(address indexed from, address indexed to);

    /**
     * @dev Check if the caller is the governor.
     */
    modifier onlyGovernor() {
        require(msg.sender == governor, "Only Governor can call");
        _;
    }

    /**
     * @dev Initialize the governor with the _initGovernor param.
     * @param _initGovernor Governor address
     */
    constructor(address _initGovernor) {
        require(_initGovernor != address(0), "Governor must not be 0");
        governor = _initGovernor;
    }

    /**
     * @dev Admin function to begin change of governor. The `_newGovernor` must call
     * `acceptOwnership` to finalize the transfer.
     * @param _newGovernor Address of new `governor`
     */
    function transferOwnership(address _newGovernor) external onlyGovernor {
        require(_newGovernor != address(0), "Governor must be set");

        address oldPendingGovernor = pendingGovernor;
        pendingGovernor = _newGovernor;

        emit NewPendingOwnership(oldPendingGovernor, pendingGovernor);
    }

    /**
     * @dev Admin function for pending governor to accept role and update governor.
     * This function must called by the pending governor.
     */
    function acceptOwnership() external {
        require(pendingGovernor != address(0) && msg.sender == pendingGovernor, "Caller must be pending governor");

        address oldGovernor = governor;
        address oldPendingGovernor = pendingGovernor;

        governor = pendingGovernor;
        pendingGovernor = address(0);

        emit NewOwnership(oldGovernor, governor);
        emit NewPendingOwnership(oldPendingGovernor, pendingGovernor);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}