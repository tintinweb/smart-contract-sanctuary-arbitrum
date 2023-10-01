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

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./interfaces/IGiftDepotManager.sol";
import "./libs/Constants.sol";

// GiftDepotManager maintains a central source of parameters and allowLists for the GiftDepot protocol.
contract GiftDepotManager is IGiftDepotManager, Constants {
    address public globalAdmin;         // The Global Admin of the whole network.
    address public arbitrator;          // The Arbitrator of the whole network.
    bool    public protocolPaused;      // Switch to pause the functionality of the entire protocol.
    address public escrowImplementation;
    uint256 public platformFeeBps;

    mapping(address => bool) public validEscrowFactory;   // Mapping of valid Escrow Factories
    mapping(address => bool) public validToken;           // Mapping of valid Tokens

    event ProtocolPaused(bool pause);
    event Initialized();
    event GlobalAdminSet(address indexed newGlobalAdmin);
    event ArbitratorSet(address indexed arbitrator);
    event EscrowImplementationSet(address indexed newEscrowImplementation);
    event ValidTokenSet(address token, uint256 decimals, string symbol, bool valid);
    event PlatformFeeSet(uint256 platformfee);

    // Checks that `msg.sender` is the Admin
    modifier isAdmin() {
        require(msg.sender == globalAdmin, "GDM:NOT_ADMIN");
        _;
    }

    modifier whenProtocolNotPaused() {
        require(!protocolPaused, "GDM:PROTO_PAUSED");
        _;
    }

    constructor() {
        require(msg.sender != address(0), "GDM:ZERO_ADMIN");
        globalAdmin = msg.sender;
        emit Initialized();
    }

    // Sets the Global Admin. Only the Governor can call this function
    function setGlobalAdmin(address _globalAdmin) external isAdmin whenProtocolNotPaused {
        require(_globalAdmin != address(0), "GDM:ZERO_ADMIN");
        globalAdmin = _globalAdmin;
        emit GlobalAdminSet(_globalAdmin);
    }

    // Sets the Global Admin. Only the Governor can call this function
    function setEscrowImplementation(address _escrowImplementation) external isAdmin whenProtocolNotPaused {
        require(_escrowImplementation != address(0), "GDM:ZERO_ESCROW_IMPL");
        escrowImplementation = _escrowImplementation;
        emit EscrowImplementationSet(_escrowImplementation);
    }

    // Sets the paused/unpaused state of the protocol. Only the Global Admin can call this function
    function setProtocolPause(bool _pause) external isAdmin {
        protocolPaused = _pause;
        emit ProtocolPaused(_pause);
    }

    // Sets the validity of a EscrowFactory. Only the Admin can call this function
    function setValidEscrowFactory(address _escrowFactory, bool _valid) external isAdmin whenProtocolNotPaused {
        require(_escrowFactory != address(0), "GDM:ZERO_ESCROW_FACTORY");
        validEscrowFactory[_escrowFactory] = _valid;
    }

    // Sets the validity of a token. Only the Admin can call this function
    function setValidToken(address _token, bool _valid) external isAdmin whenProtocolNotPaused {
        require(_token != address(0), "GDM:ZERO_TOKEN");
        validToken[_token] = _valid;
        emit ValidTokenSet(_token, IERC20Metadata(_token).decimals(), IERC20Metadata(_token).symbol(), _valid);
    }

    // Sets the validity of a token. Only the Admin can call this function
    function setArbitrator(address _arbitrator) external isAdmin whenProtocolNotPaused {
        require(_arbitrator != address(0), "GDM:ZERO_ARBITRATOR");
        arbitrator = _arbitrator;
        emit ArbitratorSet(arbitrator);
    }

    // Sets the Protocol Fee Bps. Only the Global Admin can call this function
    function setPlatformFeeBps(uint256 _platformFeeBps) external isAdmin {
        require(_platformFeeBps <= BPS_MAX_VALUE, "GDM:WRONG_BPS");
        platformFeeBps = _platformFeeBps;
        emit PlatformFeeSet(_platformFeeBps);
    }

    // Gets the Protocol Fee Bps. Only the Global Admin can call this function
    function getPlatformFeeBps() external override view returns (uint256) {
        return platformFeeBps;
    }

    function getGlobalAdmin() external override view returns (address) {
        return globalAdmin;
    }

    function getArbitrator() external override view returns (address) {
        return arbitrator;
    }

    function isProtocolPaused() external override view returns (bool) {
        return protocolPaused;
    }

    function isValidEscrowFactory(address escrowFactory) external override view returns (bool){
        return validEscrowFactory[escrowFactory];
    }

    function isValidToken(address token) external override view returns (bool){
        return validToken[token];
    }

    function getEscrowImplementation() external override view returns (address){
        return escrowImplementation;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IGiftDepotManager {
    function getGlobalAdmin() external view returns (address);

    function getArbitrator() external view returns (address);

    function isProtocolPaused() external view returns (bool);

    function isValidEscrowFactory(address escrowFactory) external view returns (bool);

    function isValidToken(address token) external view returns (bool);

    function getEscrowImplementation() external view returns (address);

    function getPlatformFeeBps() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Constants
{
    uint256 public constant BPS_MAX_VALUE = 10000;
}