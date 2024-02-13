// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import { IAoriVault } from "./interfaces/IAoriVault.sol";
import { IAoriV2 } from "aori-v2-contracts/src/interfaces/IAoriV2.sol";
import { Instruction } from "./interfaces/IBatchExecutor.sol";
import { BatchExecutor } from "./BatchExecutor.sol";

contract AoriVault is IAoriVault, BatchExecutor {

    // bytes4(keccak256("isValidSignature(bytes32,bytes)")
    bytes4 constant internal ERC1271_MAGICVALUE = 0x1626ba7e;
    
    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    address public aoriProtocol;

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        address _owner,
        address _aoriProtocol
    ) BatchExecutor(_owner) {
        aoriProtocol = _aoriProtocol;
    }

    /*//////////////////////////////////////////////////////////////
                                 HOOKS
    //////////////////////////////////////////////////////////////*/

    function beforeAoriTrade(IAoriV2.MatchingDetails calldata matching, bytes calldata hookData) external returns (bool) {
        if (hookData.length == 0) {
            return true;
        }

        require(managers[tx.origin], "Only a manager can force the execution of this trade");
        require(msg.sender == aoriProtocol, "Only aoriProtocol can interact with this contract");

        (Instruction[] memory preSwapInstructions,) = abi.decode(hookData, (Instruction[], Instruction[]));
        _execute(preSwapInstructions);
        return true;
    }

    function afterAoriTrade(IAoriV2.MatchingDetails calldata matching, bytes calldata hookData) external returns (bool) {
        if (hookData.length == 0) {
            return true;
        }

        require(managers[tx.origin], "Only a manager can force the execution of this trade");
        require(msg.sender == aoriProtocol, "Only aoriProtocol can trade");

        (, Instruction[] memory postSwapInstructions) = abi.decode(hookData, (Instruction[], Instruction[]));
        _execute(postSwapInstructions);
        return true;
    }

    /*//////////////////////////////////////////////////////////////
                                EIP-1271
    //////////////////////////////////////////////////////////////*/

    function isValidSignature(bytes32 _hash, bytes memory _signature) public view returns (bytes4) {
        require(_signature.length == 65);

        // Deconstruct the signature into v, r, s
        uint8 v;
        bytes32 r;
        bytes32 s;
        assembly {
            // first 32 bytes, after the length prefix.
            r := mload(add(_signature, 32))
            // second 32 bytes.
            s := mload(add(_signature, 64))
            // final byte (first byte of the next 32 bytes).
            v := byte(0, mload(add(_signature, 96)))
        }

        address ethSignSigner = ecrecover(_hash, v, r, s);

        // EIP1271 - dangerous if the eip151-eip1271 pairing can be found
        address eip1271Signer = ecrecover(
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    _hash
                )
            ), v, r, s);

        // check if the signature comes from a valid manager
        if (managers[ethSignSigner] || managers[eip1271Signer]) {
            return ERC1271_MAGICVALUE;
        }

        return 0x0;
    }

    /*//////////////////////////////////////////////////////////////
                                EIP-165
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 _interfaceId) public view returns (bool) {
        return
            (_interfaceId == IAoriVault.beforeAoriTrade.selector) ||
            (_interfaceId == IAoriVault.afterAoriTrade.selector);
    }
}

pragma solidity 0.8.17;

import { IAoriV2 } from "aori-v2-contracts/src/interfaces/IAoriV2.sol";
import { IAoriHook } from "aori-v2-contracts/src/interfaces/IAoriHook.sol";
import { IERC1271 } from "aori-v2-contracts/src/interfaces/IERC1271.sol";
import { IERC165 } from "aori-v2-contracts/src/interfaces/IERC165.sol";
import { IBatchExecutor } from "./IBatchExecutor.sol";

interface IAoriVault is IERC1271, IERC165, IAoriHook, IBatchExecutor {
    function beforeAoriTrade(IAoriV2.MatchingDetails calldata matching, bytes calldata hookData) external returns (bool);
    function afterAoriTrade(IAoriV2.MatchingDetails calldata matching, bytes calldata hookData) external returns (bool);
    function isValidSignature(bytes32 _hash, bytes memory _signature) external view returns (bytes4);
}

pragma solidity 0.8.17;

interface IAoriV2 {

    /*//////////////////////////////////////////////////////////////
                                STRUCTS
    //////////////////////////////////////////////////////////////*/

    struct Order {
        address offerer;
        address inputToken;
        uint256 inputAmount;
        uint256 inputChainId;
        address inputZone;
        address outputToken;
        uint256 outputAmount;
        uint256 outputChainId;
        address outputZone;
        uint256 startTime;
        uint256 endTime;
        uint256 salt;
        uint256 counter;
        bool toWithdraw;
    }

    struct MatchingDetails {
        Order makerOrder;
        Order takerOrder;

        bytes makerSignature;
        bytes takerSignature;
        uint256 blockDeadline;

        // Seat details
        uint256 seatNumber;
        address seatHolder;
        uint256 seatPercentOfFees;
    }

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OrdersSettled(
        bytes32 indexed makerHash,
        bytes32 indexed takerHash,
        address inputToken,
        address outputToken,
        uint256 inputAmount,
        uint256 outputAmount,
        bytes32 matchingHash
    );

    /*//////////////////////////////////////////////////////////////
                                 SETTLE
    //////////////////////////////////////////////////////////////*/

    function settleOrders(MatchingDetails calldata matching, bytes calldata serverSignature, bytes calldata hookData, bytes calldata options) external payable;

    /*//////////////////////////////////////////////////////////////
                                DEPOSIT
    //////////////////////////////////////////////////////////////*/

    function deposit(address _account, address _token, uint256 _amount) external;

    /*//////////////////////////////////////////////////////////////
                                WITHDRAW
    //////////////////////////////////////////////////////////////*/

    function withdraw(address _token, uint256 _amount) external;

    /*//////////////////////////////////////////////////////////////
                               FLASHLOAN
    //////////////////////////////////////////////////////////////*/

    function flashLoan(address recipient, address token, uint256 amount, bytes memory userData, bool receiveToken) external;

    /*//////////////////////////////////////////////////////////////
                                 COUNTER
    //////////////////////////////////////////////////////////////*/

    function incrementCounter() external;
    function getCounter() external view returns (uint256);

    /*//////////////////////////////////////////////////////////////
                               TAKER FEE
    //////////////////////////////////////////////////////////////*/

    function setTakerFee(uint8 _takerFeeBips, address _takerFeeAddress) external;

    /*//////////////////////////////////////////////////////////////
                             VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function hasOrderSettled(bytes32 orderHash) external view returns (bool settled);
    function balanceOf(address _account, address _token) external view returns (uint256 balance);

    /*//////////////////////////////////////////////////////////////
                            HELPER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function signatureIntoComponents(
        bytes memory signature
    ) external pure returns (
        uint8 v,
        bytes32 r,
        bytes32 s
    );
    function getOrderHash(Order memory order) external view returns (bytes32 orderHash);
    function getMatchingHash(MatchingDetails calldata matching) external view returns (bytes32 matchingHash);
}

pragma solidity 0.8.17;

struct Instruction {
    address to;
    uint256 value;
    bytes data;
}

interface IBatchExecutor {
    function execute(Instruction[] calldata instructions) external payable;
    function withdrawAll(address token, address recipient) external;
    function setManager(address _manager, bool _isManager) external;
}

pragma solidity 0.8.17;
import {IBatchExecutor, Instruction } from "./interfaces/IBatchExecutor.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";

contract BatchExecutor is IBatchExecutor {

    /*//////////////////////////////////////////////////////////////
                                 STATE
    //////////////////////////////////////////////////////////////*/

    address internal owner;
    mapping (address => bool) public managers;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Call(address to, uint256 value, bytes data);

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        address _owner
    ) {
        owner = _owner;

        // Set owner as a manager
        managers[_owner] = true;

        // Set own contract as a manager
        managers[address(this)] = true;
    }

    /*//////////////////////////////////////////////////////////////
                                EXECUTE
    //////////////////////////////////////////////////////////////*/

    function execute(
        Instruction[] calldata instructions
    ) public payable {
        require(managers[msg.sender], "Only a manager can execute");
        _execute(instructions);
    }

    function _execute(
        Instruction[] memory instructions
    ) internal {
        uint256 length = instructions.length;
        for (uint256 i; i < length; i++) {
            address to = instructions[i].to;
            uint256 value = instructions[i].value;
            bytes memory _data = instructions[i].data;

            // If call to external function is not successful, revert
            (bool success, ) = to.call{value: value}(_data);
            require(success, "Call to external function failed");
            emit Call(to, value, _data);
        }
    }

    /*//////////////////////////////////////////////////////////////
                              WITHDRAWALL
    //////////////////////////////////////////////////////////////*/

    function withdrawAll(address token, address recipient) public {
        require(managers[msg.sender], "Only owner or this contract can execute");
        IERC20(token).transfer(recipient, IERC20(token).balanceOf(address(this)));
    }

    /*//////////////////////////////////////////////////////////////
                               MANAGEMENT
    //////////////////////////////////////////////////////////////*/

    function setManager(address _manager, bool _isManager) external {
        require(owner == msg.sender, "Only owner can call this function");
        managers[_manager] = _isManager;
    }

    /*//////////////////////////////////////////////////////////////
                                  MISC
    //////////////////////////////////////////////////////////////*/

    fallback() external payable {}

    receive() external payable {}
}

pragma solidity 0.8.17;

import "./IAoriV2.sol";

interface IAoriHook {
    function beforeAoriTrade(IAoriV2.MatchingDetails calldata matching, bytes calldata hookData) external returns (bool);
    function afterAoriTrade(IAoriV2.MatchingDetails calldata matching, bytes calldata hookData) external returns (bool);
}

pragma solidity 0.8.17;

interface IERC1271 {
  // bytes4(keccak256("isValidSignature(bytes32,bytes)")
  // bytes4 constant internal MAGICVALUE = 0x1626ba7e;

  /**
   * @dev Should return whether the signature provided is valid for the provided hash
   * @param _hash      Hash of the data to be signed
   * @param _signature Signature byte array associated with _hash
   *
   * MUST return the bytes4 magic value 0x1626ba7e when function passes.
   * MUST NOT modify state (using STATICCALL for solc < 0.5, view modifier for solc > 0.5)
   * MUST allow external calls
   */ 
  function isValidSignature(
    bytes32 _hash, 
    bytes memory _signature)
    external
    view 
    returns (bytes4 magicValue);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/introspection/IERC165.sol)

pragma solidity 0.8.17;

/**
 * @dev Interface of the ERC-165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[ERC].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[ERC section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2;

/// @dev Interface of the ERC20 standard as defined in the EIP.
/// @dev This includes the optional name, symbol, and decimals metadata.
interface IERC20 {
    /// @dev Emitted when `value` tokens are moved from one account (`from`) to another (`to`).
    event Transfer(address indexed from, address indexed to, uint256 value);

    /// @dev Emitted when the allowance of a `spender` for an `owner` is set, where `value`
    /// is the new allowance.
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /// @notice Returns the amount of tokens in existence.
    function totalSupply() external view returns (uint256);

    /// @notice Returns the amount of tokens owned by `account`.
    function balanceOf(address account) external view returns (uint256);

    /// @notice Moves `amount` tokens from the caller's account to `to`.
    function transfer(address to, uint256 amount) external returns (bool);

    /// @notice Returns the remaining number of tokens that `spender` is allowed
    /// to spend on behalf of `owner`
    function allowance(address owner, address spender) external view returns (uint256);

    /// @notice Sets `amount` as the allowance of `spender` over the caller's tokens.
    /// @dev Be aware of front-running risks: https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    function approve(address spender, uint256 amount) external returns (bool);

    /// @notice Moves `amount` tokens from `from` to `to` using the allowance mechanism.
    /// `amount` is then deducted from the caller's allowance.
    function transferFrom(address from, address to, uint256 amount) external returns (bool);

    /// @notice Returns the name of the token.
    function name() external view returns (string memory);

    /// @notice Returns the symbol of the token.
    function symbol() external view returns (string memory);

    /// @notice Returns the decimals places of the token.
    function decimals() external view returns (uint8);
}