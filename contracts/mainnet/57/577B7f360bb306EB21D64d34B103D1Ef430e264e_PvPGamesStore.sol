// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IPvPGamesStore {

    /// @notice Token's house edge allocations struct.
    /// The games house edge is split into several allocations.
    /// The allocated amounts stays in the controct until authorized parties withdraw. They are subtracted from the balance.
    /// @param dividend Rate to be allocated as staking rewards, on bet payout.
    /// @param treasury Rate to be allocated to the treasury, on bet payout.
    /// @param team Rate to be allocated to the team, on bet payout.
    /// @param dividendAmount The number of tokens to be sent as staking rewards.
    /// @param treasuryAmount The number of tokens to be sent to the treasury.
    /// @param teamAmount The number of tokens to be sent to the team.
    struct HouseEdgeSplit {
        uint16 dividend;
        uint16 treasury;
        uint16 team;
        uint16 initiator;
    }

    /// @notice Token struct.
    /// @param houseEdge House edge rate.
    /// @param pendingCount Number of pending bets.
    /// @param VRFFees Chainlink's VRF collected fees amount.
    struct Token {
        uint64 vrfSubId;
        HouseEdgeSplit houseEdgeSplit;
    }

    /// @notice Token's metadata struct. It contains additional information from the ERC20 token.
    /// @dev Only used on the `getTokens` getter for the front-end.
    /// @param decimals Number of token's decimals.
    /// @param tokenAddress Contract address of the token.
    /// @param name Name of the token.
    /// @param symbol Symbol of the token.
    /// @param token Token data.
    struct TokenMetadata {
        uint8 decimals;
        address tokenAddress;
        string name;
        string symbol;
        Token token;
    }

  function setHouseEdgeSplit(
        address token,
        uint16 dividend,
        uint16 treasury,
        uint16 team,
        uint16 initiator
    ) external;

  function addToken(address token) external;
  function setVRFSubId(address token, uint64 vrfSubId) external;
  function setTeamWallet(address teamWallet) external;
  function getTokenConfig(address token) external view returns (Token memory config);
  function getTreasuryAndTeamAddresses() external view returns (address, address);
  function getTokensAddresses() external view returns (address[] memory);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {IPvPGamesStore} from "./IPvPGamesStore.sol";

contract PvPGamesStore is Ownable, IPvPGamesStore {

    /// @notice Maps tokens addresses to token configuration.
    mapping(address => Token) public tokens;

    /// @notice Number of tokens added.
    uint256 private _tokensCount;

    /// @notice Maps tokens indexes to token address.
    mapping(uint256 => address) private _tokensList;

    address public immutable treasuryWallet;
    address public teamWallet;
    event SetTeamWallet(address teamWallet);

    /// @notice Emitted after the Chainlink callback subId is set for a token.
    /// @param token Address of the token.
    /// @param vrfSubId New vrfSubId.
    event SetVRFSubId(
        address indexed token,
        uint64 vrfSubId
    );

    /// @notice Emitted after the token's house edge allocations for bet payout is set.
    /// @param token Address of the token.
    /// @param dividend Rate to be allocated as staking rewards, on bet payout.
    /// @param treasury Rate to be allocated to the treasury, on bet payout.
    /// @param team Rate to be allocated to the team, on bet payout.
    event SetTokenHouseEdgeSplit(
        address indexed token,
        uint16 dividend,
        uint16 treasury,
        uint16 team,
        uint16 initiator
    );

    /// @notice Emitted after a token is added.
    /// @param token Address of the token.
    event AddToken(address token);

    /// @notice Emitted after a token is paused.
    /// @param token Address of the token.
    /// @param paused Whether the token is paused for betting.
    event SetPausedToken(address indexed token, bool paused);

    /// @notice Reverting error when trying to add an existing token.
    error TokenExists();

    /// @notice Reverting error when setting the house edge allocations, but the sum isn't 100%.
    /// @param sum of the house edge allocations rates.
    error WrongHouseEdgeSplit(uint256 sum);

    /// @notice Reverting error when provided address isn't valid.
    error InvalidAddress();

    /// @param treasuryWalletAddress Treasury multi-sig wallet.
    /// @param teamWalletAddress Team wallet.
    constructor (address treasuryWalletAddress,
        address teamWalletAddress
    ) {
        if (
            treasuryWalletAddress == address(0)
        ) {
            revert InvalidAddress();
        }
        treasuryWallet = treasuryWalletAddress;
        setTeamWallet(teamWalletAddress);
    }

    /// @notice Sets the token's house edge allocations for bet payout.
    /// @param token Address of the token.
    /// @param dividend Rate to be allocated as staking rewards, on bet payout.
    /// @param treasury Rate to be allocated to the treasuryWallet, on bet payout.
    /// @param team Rate to be allocated to the team, on bet payout.
    /// @param initiator Rate to be allocated to the initiator of the bet, on bet payout.
    /// @dev `dividend`, `_treasuryWallet` and `team` rates sum must equals 10000.
    function setHouseEdgeSplit(
        address token,
        uint16 dividend,
        uint16 treasury,
        uint16 team,
        uint16 initiator
    ) external onlyOwner {
        uint16 splitSum = dividend + team + treasury + initiator;
        if (splitSum != 10000) {
            revert WrongHouseEdgeSplit(splitSum);
        }

        HouseEdgeSplit storage tokenHouseEdge = tokens[token].houseEdgeSplit;
        tokenHouseEdge.dividend = dividend;
        tokenHouseEdge.treasury = treasury;
        tokenHouseEdge.team = team;
        tokenHouseEdge.initiator = initiator;

        emit SetTokenHouseEdgeSplit(
            token,
            dividend,
            treasury,
            team,
            initiator
        );
    }

    /// @notice Adds a new token that'll be enabled for the games' betting.
    /// Token shouldn't exist yet.
    /// @param token Address of the token.
    function addToken(address token) external onlyOwner {
        if (_tokensCount != 0) {
            for (uint8 i; i < _tokensCount; i++) {
                if (_tokensList[i] == token) {
                    revert TokenExists();
                }
            }
        }
        _tokensList[_tokensCount] = token;
        _tokensCount += 1;
        emit AddToken(token);
    }

    /// @notice Sets the Chainlink VRF subId.
    /// @param vrfSubId New subId.
    function setVRFSubId(address token, uint64 vrfSubId)
        public
        onlyOwner
    {
        tokens[token].vrfSubId = vrfSubId;
        emit SetVRFSubId(token, vrfSubId);
    }

    /// @notice Sets the new team wallet.
    /// @param _teamWallet The team wallet address.
    function setTeamWallet(address _teamWallet)
        public
        onlyOwner()
    {
        if (_teamWallet == address(0)) {
            revert InvalidAddress();
        }
        teamWallet = _teamWallet;
        emit SetTeamWallet(teamWallet);
    }

    /// @dev For the front-end
    function getTokens() external view returns (TokenMetadata[] memory) {
        TokenMetadata[] memory _tokens = new TokenMetadata[](_tokensCount);
        for (uint8 i; i < _tokensCount; i++) {
            address tokenAddress = _tokensList[i];
            Token memory token = tokens[tokenAddress];
            if (tokenAddress == address(0)) {
                _tokens[i] = TokenMetadata({
                    decimals: 18,
                    tokenAddress: tokenAddress,
                    name: "ETH",
                    symbol: "ETH",
                    token: token
                });
            } else {
                IERC20Metadata erc20Metadata = IERC20Metadata(tokenAddress);
                _tokens[i] = TokenMetadata({
                    decimals: erc20Metadata.decimals(),
                    tokenAddress: tokenAddress,
                    name: erc20Metadata.name(),
                    symbol: erc20Metadata.symbol(),
                    token: token
                });
            }
        }
        return _tokens;
    }

    function getTokensAddresses() external view returns (address[] memory) {
        address[] memory _tokens = new address[](_tokensCount);
        for (uint8 i; i < _tokensCount; i++) {
            _tokens[i] = _tokensList[i];
        }
        return _tokens;
    }

    function getTokenConfig(address token) public view returns (Token memory config) {
      config = tokens[token];
    }

    function getTreasuryAndTeamAddresses() public view returns (address, address) {
        return (treasuryWallet, teamWallet);
    }
}