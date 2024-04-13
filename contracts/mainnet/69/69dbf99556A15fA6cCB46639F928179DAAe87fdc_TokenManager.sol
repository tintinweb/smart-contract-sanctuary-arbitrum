// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;
pragma abicoder v2;

import {IERC20, IERC20Meta} from "../../shared/interfaces/IERC20.sol";

error TokenAlreadyAdded(address _token);
error ZeroAddress();

event TokenAdded(address _token, uint8 decimals);

struct TokenInfo {
    string symbol;
    uint8 decimals;
    address token;
}

struct TokenStorage {
    mapping(uint => TokenInfo) tokens;
    uint tokensCount;
}

library LibTokenHelper {
    bytes32 constant EXECUTOR_STORAGE_POSITION = keccak256("fraktal.protocol.token.helper.storage");
    function diamondStorage () internal pure returns(TokenStorage storage ds) {
        bytes32 position = EXECUTOR_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }

    }    
    function hasToken (address _token) internal view returns (bool hasIt) {
        uint i;
        uint len = diamondStorage().tokensCount;
        if (len == 0) return hasIt;

        for (i; i < len; i++) {
            if (diamondStorage().tokens[i].token == _token) return hasIt = true;
        }
    }
    function getTokenId (address _token) internal view returns (uint _id) {
        uint i;
        uint len = diamondStorage().tokensCount;
        for (i; i < len; i++) {
            if (diamondStorage().tokens[i].token == _token) return _id = i;
        }
    }

    function getToken (uint _id) internal view returns (TokenInfo memory token) {
        token = diamondStorage().tokens[_id];
    }

    function getToken (address _token) internal view returns (TokenInfo memory token) {
        token = getToken(getTokenId(_token));
    }
    function getTokens (uint[] memory _id) internal view returns (TokenInfo[] memory tokens) {
        uint i;
        uint len = diamondStorage().tokensCount;

        for (i; i < len; i++) {
            tokens[i] = diamondStorage().tokens[_id[i]];
        }
    }


    function addToken (address _token) internal {
        if (hasToken(_token)) revert TokenAlreadyAdded(_token);
        if (_token == address(0)) revert ZeroAddress();

        TokenInfo memory token = diamondStorage().tokens[diamondStorage().tokensCount];

        string memory symbol = IERC20Meta(_token).symbol();
        uint8 decimals = IERC20Meta(_token).decimals();

        token.token = _token;
        token.symbol = symbol;
        token.decimals = decimals;

        diamondStorage().tokensCount++;
        emit TokenAdded(_token, decimals);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;
pragma abicoder v2;

import {IERC20, IERC20Meta} from "../shared/interfaces/IERC20.sol";
import {LibTokenHelper, TokenInfo} from "./libraries/LibTokenHelper.sol";

contract TokenManager {
    function addToken (address token) external {
        LibTokenHelper.addToken(token);
    }
    function getToken (uint id) external view returns (TokenInfo memory token) {
        token = LibTokenHelper.getToken(id);
    }
    function getToken (address _token) external view returns (TokenInfo memory token) {
        token = LibTokenHelper.getToken(_token);
    }
    function getTokens (uint[] memory ids) external view returns (TokenInfo[] memory tokens) {
        tokens = LibTokenHelper.getTokens(ids);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

interface IERC20Events {
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

}
/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {

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

interface IERC20BaseModifiers {
    // modifier onlyMinter() {}
    // modifier onlyBurner() {}
    function _isERC20BaseInitialized() external view returns (bool);
}

interface IERC20Meta {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals () external view returns (uint8);

}