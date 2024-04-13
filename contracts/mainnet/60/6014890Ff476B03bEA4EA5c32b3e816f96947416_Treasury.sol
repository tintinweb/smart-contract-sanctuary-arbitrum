// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;
pragma abicoder v2;

import {LibMeta } from "../shared/libraries/LibMeta.sol";
import {IERC20} from "../shared/interfaces/IERC20.sol";

struct TreasuryStorage {
    address manager;
    mapping(address => mapping(address => uint)) balances;
}

event TreasuryDeposited(address indexed account, address indexed token, uint amount);
event TreasuryWithdrawn(address indexed account, address indexed token, uint amount);

error LowTokenBalance(address to, address token);
error TrasnferFailed(address to, address token, uint amount);
error WithdarwalFailure(address to, address token, uint amount);

struct ExecutionParams {
    address to;
    uint value;
    bytes data;
}
struct ExecutionReturn {
    bool success;
    bytes data;
}

library LibTreasury {
    bytes32 constant STORAGE_POTISION = keccak256("fraktal.protocol.treasury.storage");

    function diamondStorage () internal pure returns (TreasuryStorage storage ds) {
        bytes32 position = STORAGE_POTISION;
        assembly {
            ds.slot := position
        }
    }
    function isManager (address account) internal view returns(bool isM) {
        return diamondStorage().manager == account;
    }
    function isManager () internal view returns (bool isM) {
        isM = isManager(LibMeta.msgSender());
    }
    function deposit (address to, address token, uint amount) internal {
        TreasuryStorage storage ds = diamondStorage();
        if (IERC20(token).balanceOf(to) < amount) revert LowTokenBalance(to, address(token));

        ds.balances[to][token] += amount;
        if (!IERC20(token).transferFrom(to, address(this), amount)) revert TrasnferFailed(to, address(token), amount);

        emit TreasuryDeposited(to, token, amount);
    }
    function withdraw (address to, address token, uint amount) internal {
        TreasuryStorage storage ds = diamondStorage();
        if (ds.balances[to][token] < amount) revert WithdarwalFailure(to, token, amount);
        emit TreasuryWithdrawn(to, token, amount);

    }
    function execute (ExecutionParams memory params) internal returns(ExecutionReturn memory returnData) {
        (returnData.success, returnData.data) = params.to.call{value: params.value}(params.data);
    }
    function execute (ExecutionParams[] memory params) internal returns(ExecutionReturn[] memory returnData) {
        uint len = params.length;
        uint i;

        returnData = new ExecutionReturn[](len);

        for (i; i < len; i++) {
            (returnData[i].success, returnData[i].data) = params[i].to.call{value: params[i].value}(params[i].data);
        }
    }

}
contract Treasury {
    address payable immutable deployer;
    constructor () payable {
        deployer = payable(LibMeta.msgSender());
    }
    receive () external payable {
        if (msg.value > 0) LibTreasury.deposit(LibMeta.msgSender(), address(0), msg.value);
    }
    function deposit (address to, address token, uint amount) external {
        LibTreasury.deposit(to, token, amount);
    }
    function deposit (address token, uint amount) external {
        address to = address(0);
        LibTreasury.deposit(to, token, amount);
    }
    function deposit (uint amount) external {
        address to = address(0);
        address token = address(0);
        LibTreasury.deposit(to, token, amount);
    }
    function withdraw (address to, address token, uint amount) internal {
        LibTreasury.withdraw(to, token, amount);
    }
    function withdraw ( address token, uint amount) internal {
        address to = address(0);
        LibTreasury.withdraw(to, token, amount);
    }
    function withdraw (uint amount) internal {
        address to = address(0);
        address token = address(0);
        LibTreasury.withdraw(to, token, amount);
    }
    function execute (ExecutionParams memory params) internal returns(ExecutionReturn memory returnData) {
        returnData = LibTreasury.execute (params);
    }
    function execute (ExecutionParams[] memory params) internal returns(ExecutionReturn[] memory returnData) {
        returnData = LibTreasury.execute (params);
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

// SPDX-License-Identifier: COPPER-PROTOCOL
pragma solidity 0.8.24;

library LibMeta {
    // EIP712 domain type hash
    bytes32 internal constant EIP712_DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,string version,uint256 salt,address verifyingContract)");

    // /**
    //  * @dev Generates the domain separator for EIP712 signatures.
    //  * @param name The name of the contract.
    //  * @param version The version of the contract.
    //  * @return The generated domain separator.
    //  */
    function domainSeparator(string memory name, string memory version) internal view returns (bytes32 domainSeparator_) {
        // Generate the domain separator hash using EIP712_DOMAIN_TYPEHASH and contract-specific information
        domainSeparator_ = keccak256(
            abi.encode(EIP712_DOMAIN_TYPEHASH, keccak256(bytes(name)), keccak256(bytes(version)), getChainID(), address(this))
        );
    }

    // /**
    //  * @dev Gets the current chain ID.
    //  * @return The chain ID.
    //  */
    function getChainID() internal view returns (uint256 id) {
        assembly {
            id := chainid()
        }
    }

    // /**
    //  * @dev Gets the actual sender of the message.
    //  * @return The actual sender of the message.
    //  */
    function msgSender() internal view returns (address sender_) {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender_ := and(mload(add(array, index)), 0xffffffffffffffffffffffffffffffffffffffff)
            }
        } else {
            sender_ = msg.sender;
        }
    }
}