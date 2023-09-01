// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title Valha MultiSend Call Only - Allows to batch multiple transactions into one.
 * @notice This code is heavily inspired from the MultiSend Call developped by Gnosis Safe. The only addition is 
 *         an owner address and a mapping in the state, two modifiers and functions to let the whitelisted addresses 
 *         receive the tokens resulting from the mutlicall and to let users remove any ERC20 or native dust.
 * @author Valha Team - [email protected]
 */
contract ValhaMultiCall {
    /// ============== STATE ================

    /// @notice Address that own this contract and can whitelist new addresses.
    address public                      owner;

    /// @notice Addresses that can interact with this contract and therefore receive tokens (and dust)
    ///         from this contract.
    mapping(address => bool) public     whitelistAddresses;      

    /// ============ CONSTRUCTOR ============

    /// @notice Creates a new Multicall contract
    /// @param  _owner address that has the capacity to withdraw dust money from this contract
    constructor(address _owner) {
        owner = _owner;
        whitelistAddresses[_owner] = true;
    }

    /// ============ MODIFIERS ==============

    /// @notice Modifier to let only the owner whitelist new addresses.
    modifier onlyOwner() {
        require(msg.sender == owner, 'Only the owner can perform this action.');
        _;
    }

    /// @notice Modifier to let only the whitelisted address interact with call functions 
    ///         to avoid anyone to steal the potential ERC20 dust that can be on this contract between the calls.
    modifier onlyWhitelisted() {
        require(whitelistAddresses[msg.sender] == true, 'Only whitelisted address can interact with the contract.');
        _;
    }

    /// ========== PUBLIC FUNCTIONS =========

    /**
     * @dev Sends multiple transactions and reverts all if one fails.
     * @param transactions Encoded transactions. Each transaction is encoded as a packed bytes of
     *                     operation has to be uint8(0) in this version (=> 1 byte),
     *                     to as a address (=> 20 bytes),
     *                     value as a uint256 (=> 32 bytes),
     *                     data length as a uint256 (=> 32 bytes),
     *                     data as bytes.
     *                     see abi.encodePacked for more information on packed encoding
     * @notice The code is for most part the same as the normal MultiSend (to keep compatibility),
     *         but reverts if a transaction tries to use a delegatecall.
     * @notice This method is payable as delegatecalls keep the msg.value from the previous call
     *         If the calling method (e.g. execTransaction) received ETH this would revert otherwise
     * @notice Only the whitelised addresses can call this function.
     */
    function multiSend(bytes memory transactions) public payable onlyWhitelisted {
        // solhint-disable-next-line no-inline-assembly
        /// @solidity memory-safe-assembly
        assembly {
            let length := mload(transactions)
            let i := 0x20
            for {
                // Pre block is not used in "while mode"
            } lt(i, length) {
                // Post block is not used in "while mode"
            } {
                // First byte of the data is the operation.
                // We shift by 248 bits (256 - 8 [operation byte]) it right since mload 
                // will always load 32 bytes (a word).
                // This will also zero out unused data.
                let operation := shr(0xf8, mload(add(transactions, i)))
                // We offset the load address by 1 byte (operation byte)
                // We shift it right by 96 bits (256 - 160 [20 address bytes]) to right-align 
                // the data and zero out unused data.
                let to := shr(0x60, mload(add(transactions, add(i, 0x01))))
                // We offset the load address by 21 byte (operation byte + 20 address bytes)
                let value := mload(add(transactions, add(i, 0x15)))
                // We offset the load address by 53 byte (operation byte + 20 address bytes + 32 value bytes)
                let dataLength := mload(add(transactions, add(i, 0x35)))
                // We offset the load address by 
                // 85 byte (operation byte + 20 address bytes + 32 value bytes + 32 data length bytes)
                let data := add(transactions, add(i, 0x55))
                let success := 0
                switch operation
                case 0 {
                    success := call(gas(), to, value, data, dataLength, 0, 0)
                }
                // This version does not allow delegatecalls
                case 1 {
                    revert(0, 0)
                }
                if eq(success, 0) {
                    let errorLength := returndatasize()
                    returndatacopy(0, 0, errorLength)
                    revert(0, errorLength)
                }
                // Next entry starts at 85 byte + data length
                i := add(i, add(0x55, dataLength))
            }
        }
    }

    /**
     * @dev Sends multiple transactions, reverts all if one fails and send the whole balance of specified token 
     *      to the specified receiver.
     * @param _transactions     Encoded transactions. Each transaction is encoded as a packed bytes of
     *                          operation has to be uint8(0) in this version (=> 1 byte),
     *                          to as a address (=> 20 bytes),
     *                          value as a uint256 (=> 32 bytes),
     *                          data length as a uint256 (=> 32 bytes),
     *                          data as bytes.
     *                          see abi.encodePacked for more information on packed encoding
     * @param _receiver         address that will receive the whole ERC20 token balance of this contract.
     * @param _tokenToReceive   address of the token to be sent to the receiver. 
     *                          Should be the token expected at the end of the multicall actions.
     * @notice The code is for most part the same as the Gnosis Safe MultiSend (to keep compatibility),
     *         but reverts if a transaction tries to use a delegatecall and send the balance of the 
     *          specified token to a specified address at the end of the process.
     * @notice This method is payable as delegatecalls keep the msg.value from the previous call
     *         If the calling method (e.g. execTransaction) received ETH this would revert otherwise
     * @notice Only the whitelised addresses can call this function.
     */
    function multiSendAndReceive(
        bytes memory    _transactions,
        address         _receiver,
        address         _tokenToReceive
    ) public payable onlyWhitelisted {
        multiSend(_transactions);
        uint256 amount = IERC20(_tokenToReceive).balanceOf(address(this));
        IERC20(_tokenToReceive).transfer(_receiver, amount);
    }


    /// ========== EXTERNAL FUNCTIONS =======

    /**
     * @dev Sends the whole balance of the specified token from this contract to the owner.
     * @param _tokenToReceive address of the ERC20 token to withdraw the balance to the owner.
     * @notice Only the whitelised addresses can call this function.
     */
    function withdrawERC20(address _tokenToReceive) external onlyWhitelisted {
        uint256 amount = IERC20(_tokenToReceive).balanceOf(address(this));
        IERC20(_tokenToReceive).transfer(owner, amount);
    }

    /**
     * @dev Sends the whole native balance from this contract to the owner.
     * @notice Only the whitelised addresses can call this function.
     */
    function withdrawNative() external onlyWhitelisted {
        uint256 amount = address(this).balance;
        payable(owner).transfer(amount);
    }

    /**
     * @dev Sends the whole balances of the specified tokens from this contract to the owner.
     * @param _tokensToReceive  array of addresses of the ERC20 token to withdraw the balance to the owner.
     * @param _length           number representing the length of the tokens array.
     * @notice Only the whitelised addresses can call this function.
     */
    function sweep(address[] calldata _tokensToReceive, uint256 _length) external onlyWhitelisted {
        for (uint i = 0; i < _length; i++) {
            uint256 amount = IERC20(_tokensToReceive[i]).balanceOf(address(this));
            IERC20(_tokensToReceive[i]).transfer(owner, amount);
        }
    }

    /**
     * @dev Add new address to the whitelist.
     * @param _newAddress address that must be added.
     * @notice Only the owner address can call this function.
     */
    function addNewAddressToWhitelist(address _newAddress) external onlyOwner {
        whitelistAddresses[_newAddress] = true;
    }

    /**
     * @dev Remove address from the whitelist.
     * @param _addressToRemove address that must be removed.
     * @notice Only the owner address can call this function.
     */
    function removeAddressfromWhitelist(address _addressToRemove) external onlyOwner {
        whitelistAddresses[_addressToRemove] = false;
    }

    /// @notice In case of error, to receive native token.
    receive() external payable {}
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