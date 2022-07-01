///SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "../../interfaces/IMultichain.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
interface IAnyCall {
    function anyCall(address _to, bytes calldata _data, address _fallback, uint256 _toChainID, uint256 _flags) external;
}


contract TestArbitrum {
    address public owner;
    address public constant anyCallAddress = 0xC10Ef9F491C9B59f936957026020C321651ac078;
    address public nextChainExecutor;
    uint256 public nextChainId;
    address public lastChainExecutor;
    uint256 public lastChainId;
    address public constant multichainRouter = 0x650Af55D5877F289837c30b94af91538a7504b76;
    mapping(address => address) public tokenToAnyToken;
    uint256 lastCalledTime;
    modifier isOwner {
        require(owner == msg.sender);
        _;
    }

    constructor(address _token1, address _anyToken1, address _token2, address _anyToken2) {
        tokenToAnyToken[_token1] = _anyToken1;
        tokenToAnyToken[_token2] = _anyToken2;
        owner = msg.sender;
    }

    function anyExecute(bytes memory _data) external returns (bool success, bytes memory result) {
        lastCalledTime = block.timestamp;
        success=true;
        result="";
        // Gelato should listen out for messageReceived and start calling checkExecuteDeposits()
        // If it returns true, it can trigger it. Then stop listening.
    }

    function bridge(address[] memory _tokens) public isOwner {
        for (uint256 i; i< _tokens.length; i++) {
            address _token = _tokens[i];
            uint256 balance = IERC20(_token).balanceOf(address(this));
            IERC20(_token).approve(multichainRouter, balance);
            IMultichain(multichainRouter).anySwapOutUnderlying(tokenToAnyToken[_token], lastChainExecutor, balance, lastChainId);
        }
        
    }


    function setChainInformation(address _nextChainExecutor, uint256 _nextChainId, address _lastChainExecutor, uint256 _lastChainId) public isOwner {
        nextChainExecutor = _nextChainExecutor;
        nextChainId = _nextChainId;
        lastChainExecutor = _lastChainExecutor;
        lastChainId = _lastChainId;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface IMultichain {
     // Swaps `amount` `token` from this chain to `toChainID` chain with recipient `to` by minting with `underlying`
    //  Token == anyXYZ coin
    // Address to = address to receive
    function anySwapOutUnderlying(address token, address to, uint amount, uint toChainID) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

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