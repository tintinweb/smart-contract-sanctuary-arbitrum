// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;
pragma abicoder v2;

import {IERC20, IERC20Meta} from "../../../shared/interfaces/IERC20.sol";
import { LibInitializer } from "../../../shared/libraries/LibInitializer.sol";
import {
    TokenInfo, TokenInfoExtended, TokenAlreadyAdded, ZeroAddress, InvalidTokenRangeValues, TokenAdded
} from "../../interfaces/ITokenHelper.sol";

struct TokenStorage {
    mapping(uint => TokenInfo) tokens;
    uint tokensCount;
}

library LibTokenHelper {
    bytes32 constant STORAGE_POSITION = keccak256("fraktal.protocol.token.helper.storage");
    function diamondStorage() internal pure returns(TokenStorage storage ds) {
        bytes32 position = STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }
    function initialize () internal {
        LibInitializer.initialize(getId());
    }
    function initialized () internal view returns (bool isInit) {
        isInit = LibInitializer.initialized(getId());

    }
    function getId () internal pure returns (bytes32 id) {
        return bytes32(abi.encodePacked(STORAGE_POSITION));
    }


    function hasToken(address _token) internal view returns (bool hasIt) {
        uint len = diamondStorage().tokensCount;
        if (len == 0) return hasIt;

        for (uint i = 0; i < len; i++) {
            if (diamondStorage().tokens[i].token == _token) {
                return hasIt = true;
            }
        }
        return false;
    }
    
    function addToken(address _token) internal {

        // If token exists, revert
        if (hasToken(_token)) revert TokenAlreadyAdded(_token);
        // If token is ZeroAddress, revert
        if (_token == address(0)) revert ZeroAddress();

        TokenStorage storage ds = diamondStorage();
        TokenInfo storage token = ds.tokens[ds.tokensCount];

        // IERC20Meta metaToken = IERC20Meta(_token);
        string memory symbol;
        try IERC20Meta(_token).symbol() returns(string memory sym) {
            symbol = sym;

        } catch {

        }

        uint8 decimals;
        try IERC20Meta(_token).decimals() returns (uint8 dec) {
            decimals = dec;
        } catch {
            decimals = 18;
        }

        token.token = _token;
        token.symbol = symbol;
        token.decimals = decimals;
        ds.tokensCount++;

        emit TokenAdded(_token, symbol, decimals);

    }

    function addTokens(address[] memory tokens) internal {
        uint len = tokens.length;

        for (uint i = 0; i < len; i++) {
            addToken(tokens[i]);
        }
    }
    function getTokenId(address _token) internal view returns (uint _id) {
        
        uint len = diamondStorage().tokensCount;
        for (uint i = 0; i < len; i++) {
            if (diamondStorage().tokens[i].token == _token) {
                return _id = i;
            }
        }
        revert("Token not found");
    }

    function getToken(uint _id) internal view returns (TokenInfo memory token) {
        require(_id < diamondStorage().tokensCount, "Invalid token ID");
        token = diamondStorage().tokens[_id];
    }

    function getTokenByAddress(address _token) internal view returns (TokenInfo memory token) {
        return getToken(getTokenId(_token));
    }

    function getTokens(uint[] memory _ids) internal view returns (TokenInfo[] memory tokens) {
        uint len = _ids.length;
        tokens = new TokenInfo[](len);

        for (uint i = 0; i < len; i++) {
            tokens[i] = diamondStorage().tokens[_ids[i]];
        }
    }

    function getTokensRange(uint start, uint stop) internal view returns (TokenInfo[] memory tokens) {
        if (start >= stop) revert InvalidTokenRangeValues(start, stop);

        uint len = stop - start;
        tokens = new TokenInfo[](len);

        for (uint i = 0; i < len; i++) {
            tokens[i] = diamondStorage().tokens[start + i];
        }
    }
    function getTokensCount () internal view returns(uint count) {
        count = diamondStorage().tokensCount;
    }
    function getTokenInfoExtended (address _token) internal view returns(TokenInfoExtended memory token) {
        token.token = _token;
        IERC20Meta _t = IERC20Meta(_token);
        token.name = _t.name();
        token.decimals = _t.decimals();
        token.symbol = _t.symbol();
        token.totalSupply = _t.totalSupply();
        return token;
    }
    function getTokenInfo (address _token) internal view returns(TokenInfo memory token) {
        token.token = _token;
        IERC20Meta _t = IERC20Meta(_token);
        token.decimals = _t.decimals();
        token.symbol = _t.symbol();
        return token;
    }
    function getTokenInfoExtendedMulti (address[] memory _tokens) internal view returns(TokenInfoExtended[] memory tokens) {
        uint i;
        uint len = _tokens.length;

        tokens = new TokenInfoExtended[](len);

        for (i; i < len; i++) {
            tokens[i] = getTokenInfoExtended(_tokens[0]);
        }
        return tokens;
    }
    function getTokenInfoMulti (address[] memory _tokens) internal view returns(TokenInfo[] memory tokens) {
        uint i;
        uint len = _tokens.length;

        tokens = new TokenInfo[](len);

        for (i; i < len; i++) {
            tokens[i] = getTokenInfo(_tokens[0]);
        }
        return tokens;

    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;
pragma abicoder v2;

import {IERC20, IERC20Meta} from "../../../shared/interfaces/IERC20.sol";
import {LibTokenHelper} from "../TokenHelper/LibTokenHelper.sol";
import { ITokenHelper, TokenInfo, TokenInfoExtended } from "../../interfaces/ITokenHelper.sol";

contract TokenHelper is ITokenHelper {
    function THInit () external {
        LibTokenHelper.initialize();
    }
    function hasToken(address _token) external view returns (bool hasIt) {
        hasIt = LibTokenHelper.hasToken(_token);
    }
    function getTokenId(address _token) external view returns (uint _id) {
        _id = LibTokenHelper.getTokenId(_token);
    }
    function getToken(uint _id) external view returns (TokenInfo memory token) {
        token = LibTokenHelper.getToken(_id);
    }

    function getTokenByAddress(address _token) external view returns (TokenInfo memory token) {
        token = LibTokenHelper.getTokenByAddress(_token);
    }
    function getTokens(uint[] memory _ids) external view returns (TokenInfo[] memory tokens) {
        tokens = LibTokenHelper.getTokens(_ids);
    }
    function getTokensRange (uint start, uint stop) external view returns (TokenInfo[] memory tokens) {
        tokens = LibTokenHelper.getTokensRange(start, stop);
    }
    function addToken(address _token) external {
        LibTokenHelper.addToken(_token);
    }
    function addTokens (address[] memory tokens) external {
        LibTokenHelper.addTokens(tokens);
    }
    function getTokensCount () external view returns(uint count) {
        count = LibTokenHelper.getTokensCount();
    }
    function getTokenInfoExtended (address _token) external view returns(TokenInfoExtended memory token) {
        token = LibTokenHelper.getTokenInfoExtended( _token);
    }
    function getTokenInfo (address _token) external view returns(TokenInfo memory token) {
        token = LibTokenHelper.getTokenInfo( _token);
    }
    function getTokenInfoExtendedMulti (address[] memory _tokens) external view returns(TokenInfoExtended[] memory tokens) {
        tokens = LibTokenHelper.getTokenInfoExtendedMulti( _tokens);
    }
    function getTokenInfoMulti (address[] memory _tokens) external view returns(TokenInfo[] memory tokens) {
        tokens = LibTokenHelper.getTokenInfoMulti( _tokens);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;
pragma abicoder v2;

error TokenAlreadyAdded(address _token);
error ZeroAddress();
error InvalidTokenRangeValues(uint start, uint stop);

event TokenAdded(address indexed _token, string indexed symbol, uint8 indexed decimals);

struct TokenInfo {
    string symbol;
    uint8 decimals;
    address token;
}
struct TokenInfoExtended {
    string  name;
    string symbol;
    uint8 decimals;
    address token;
    uint totalSupply;
}


interface ITokenHelper {
    function THInit () external;
    function hasToken(address _token) external view returns (bool hasIt);
    function getTokenId(address _token) external view returns (uint _id);
    function getToken(uint _id) external view returns (TokenInfo memory token);
    function getTokenByAddress(address _token) external view returns (TokenInfo memory token);
    function getTokens(uint[] memory _ids) external view returns (TokenInfo[] memory tokens);
    function getTokensRange (uint start, uint stop) external view returns (TokenInfo[] memory tokens);
    function addToken(address _token) external;
    function addTokens (address[] memory tokens) external;
    function getTokensCount () external view returns(uint count);
    function getTokenInfoExtended (address _token) external view returns(TokenInfoExtended memory token);
    function getTokenInfo (address _token) external view returns(TokenInfo memory token);
    function getTokenInfoExtendedMulti (address[] memory _tokens) external view returns(TokenInfoExtended[] memory tokens);
    function getTokenInfoMulti (address[] memory _tokens) external view returns(TokenInfo[] memory tokens);
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

    interface IERC20Meta is IERC20 {
        function name() external view returns (string memory);
        function symbol() external view returns (string memory);
        function decimals () external view returns (uint8);

    }

// SPDX-License-Identifier: COPPER-PROTOCOL
pragma solidity 0.8.24;

struct InitializationStorage {
    mapping(bytes32 => bool) initialized;
}

library LibInitializer {
    error NotInitialized(bytes32 id);
    error HasInitialized(bytes32 id);

    bytes32 constant STORAGE_POSITION = keccak256("copper-protocol.util.initializer.storage");

    function diamondStorage() internal pure returns (InitializationStorage storage ds) {
        bytes32 position = STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }
    function _ds () internal  pure returns (InitializationStorage storage ds) {
        ds = diamondStorage();
    }
    function initialize (bytes32 _id) internal {
        _ds().initialized[_id] = true;
    }
    function initialized (bytes32 _id) internal view returns (bool init) {
        init = _ds().initialized[_id];
    }
    function notInitialized  (bytes32 _id) internal view {
        if (!initialized(_id)) revert NotInitialized(_id);
    }
    function hasInitialized  (bytes32 _id) internal view {
        if (initialized(_id)) revert HasInitialized(_id);
    }

}