// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface IERC20Permit {
    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function nonces(address account) external view returns (uint256);

    function permit(
        address issuer,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    error InvalidAccount();

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IInterchainToken } from '../interfaces/IInterchainToken.sol';
import { ITokenManager } from '../interfaces/ITokenManager.sol';
import { ERC20 } from '../token-implementations/ERC20.sol';

/**
 * @title An example implementation of the IInterchainToken.
 * @notice The implementation ERC20 can be done in any way, however this example assumes that an _approve internal function exists
 * that can be used to create approvals, and that `allowance` is a mapping.
 * @dev You can skip the `tokenManagerRequiresApproval()` function altogether if you know what it should return for your token.
 */
abstract contract InterchainToken is IInterchainToken, ERC20 {
    /**
     * @notice Getter for the tokenManager used for this token.
     * @dev Needs to be overwitten.
     * @return tokenManager the TokenManager called to facilitate cross chain transfers.
     */
    function getTokenManager() public view virtual returns (ITokenManager tokenManager);

    /**
     * @notice Getter function specifiying if the tokenManager requires approval to facilitate cross-chain transfers.
     * Usually, only mint/burn tokenManagers do not need approval.
     * @dev The return value depends on the implementation of ERC20.
     * In case of lock/unlock and liquidity pool TokenManagers it is possible to implement transferFrom to allow the
     * TokenManager specifically to do it permissionlesly.
     * On the other hand you can implement burn in a way that requires approval for a mint/burn TokenManager
     * @return tokenManager the TokenManager called to facilitate cross chain transfers.
     */
    function tokenManagerRequiresApproval() public view virtual returns (bool);

    /**
     * @notice Implementation of the interchainTransfer method
     * @dev We chose to either pass `metadata` as raw data on a remote contract call, or, if no data is passed, just do a transfer.
     * A different implementation could have `metadata` that tells this function which function to use or that it is used for anything else as well.
     * @param destinationChain The destination chain identifier.
     * @param recipient The bytes representation of the address of the recipient.
     * @param amount The amount of token to be transfered.
     * @param metadata Either empty, to just facilitate an interchain transfer, or the data can be passed for an interchain contract call with transfer as per semantics defined by the token service.
     */
    function interchainTransfer(
        string calldata destinationChain,
        bytes calldata recipient,
        uint256 amount,
        bytes calldata metadata
    ) external payable {
        address sender = msg.sender;
        ITokenManager tokenManager = getTokenManager();
        /**
         * @dev if you know the value of `tokenManagerRequiresApproval()` you can just skip the if statement and just do nothing or _approve.
         */
        if (tokenManagerRequiresApproval()) {
            uint256 allowance_ = allowance[sender][address(tokenManager)];
            if (allowance_ != type(uint256).max) {
                if (allowance_ > type(uint256).max - amount) {
                    allowance_ = type(uint256).max - amount;
                }

                _approve(sender, address(tokenManager), allowance_ + amount);
            }
        }

        // Metadata semantics are defined by the token service and thus should be passed as-is.
        tokenManager.transmitInterchainTransfer{ value: msg.value }(sender, destinationChain, recipient, amount, metadata);
    }

    /**
     * @notice Implementation of the interchainTransferFrom method
     * @dev We chose to either pass `metadata` as raw data on a remote contract call, or, if no data is passed, just do a transfer.
     * A different implementation could have `metadata` that tells this function which function to use or that it is used for anything else as well.
     * @param sender the sender of the tokens. They need to have approved `msg.sender` before this is called.
     * @param destinationChain the string representation of the destination chain.
     * @param recipient the bytes representation of the address of the recipient.
     * @param amount the amount of token to be transfered.
     * @param metadata either empty, to just facilitate a cross-chain transfer, or the data to be passed to a cross-chain contract call and transfer.
     */
    function interchainTransferFrom(
        address sender,
        string calldata destinationChain,
        bytes calldata recipient,
        uint256 amount,
        bytes calldata metadata
    ) external payable {
        uint256 _allowance = allowance[sender][msg.sender];

        if (_allowance != type(uint256).max) {
            _approve(sender, msg.sender, _allowance - amount);
        }

        ITokenManager tokenManager = getTokenManager();
        if (tokenManagerRequiresApproval()) {
            uint256 allowance_ = allowance[sender][address(tokenManager)];
            if (allowance_ != type(uint256).max) {
                if (allowance_ > type(uint256).max - amount) {
                    allowance_ = type(uint256).max - amount;
                }

                _approve(sender, address(tokenManager), allowance_ + amount);
            }
        }

        tokenManager.transmitInterchainTransfer{ value: msg.value }(sender, destinationChain, recipient, amount, metadata);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IDistributable {
    error NotDistributor();

    event DistributorChanged(address distributor);

    /**
     * @notice Get the address of the distributor
     * @return distributor of the distributor
     */
    function distributor() external view returns (address distributor);

    /**
     * @notice Change the distributor of the contract
     * @dev Can only be called by the current distributor
     * @param distributor The address of the new distributor
     */
    function setDistributor(address distributor) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC20 } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IERC20.sol';

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20BurnableMintable is IERC20 {
    /**
     * @notice Function to mint new tokens
     * Can only be called by the distributor address.
     * @param to The address that will receive the minted tokens
     * @param amount The amount of tokens to mint
     */
    function mint(address to, uint256 amount) external;

    /**
     * @notice Function to burn tokens
     * Can only be called by the distributor address.
     * @param from The address that will have its tokens burnt
     * @param amount The amount of tokens to burn
     */
    function burn(address from, uint256 amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IFlowLimit {
    error FlowLimitExceeded();

    event FlowLimitSet(uint256 flowLimit);

    /**
     * @notice Returns the current flow limit
     * @return flowLimit The current flow limit value
     */
    function getFlowLimit() external view returns (uint256 flowLimit);

    /**
     * @notice Returns the current flow out amount
     * @return flowOutAmount The current flow out amount
     */
    function getFlowOutAmount() external view returns (uint256 flowOutAmount);

    /**
     * @notice Returns the current flow in amount
     * @return flowInAmount The current flow in amount
     */
    function getFlowInAmount() external view returns (uint256 flowInAmount);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IImplementation {
    error NotProxy();
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC20 } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IERC20.sol';

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IInterchainToken is IERC20 {
    /**
     * @notice Implementation of the interchainTransfer method
     * @dev We chose to either pass `metadata` as raw data on a remote contract call, or, if no data is passed, just do a transfer.
     * A different implementation could have `metadata` that tells this function which function to use or that it is used for anything else as well.
     * @param destinationChain The destination chain identifier.
     * @param recipient The bytes representation of the address of the recipient.
     * @param amount The amount of token to be transfered.
     * @param metadata Either empty, to just facilitate an interchain transfer, or the data can be passed for an interchain contract call with transfer as per semantics defined by the token service.
     */
    function interchainTransfer(
        string calldata destinationChain,
        bytes calldata recipient,
        uint256 amount,
        bytes calldata metadata
    ) external payable;

    /**
     * @notice Implementation of the interchainTransferFrom method
     * @dev We chose to either pass `metadata` as raw data on a remote contract call, or, if no data is passed, just do a transfer.
     * A different implementation could have `metadata` that tells this function which function to use or that it is used for anything else as well.
     * @param sender the sender of the tokens. They need to have approved `msg.sender` before this is called.
     * @param destinationChain the string representation of the destination chain.
     * @param recipient the bytes representation of the address of the recipient.
     * @param amount the amount of token to be transfered.
     * @param metadata either empty, to just facilitate a cross-chain transfer, or the data to be passed to a cross-chain contract call and transfer.
     */
    function interchainTransferFrom(
        address sender,
        string calldata destinationChain,
        bytes calldata recipient,
        uint256 amount,
        bytes calldata metadata
    ) external payable;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IOperatable {
    error NotOperator();

    event OperatorChanged(address operator);

    /**
     * @notice Get the address of the operator
     * @return operator_ of the operator
     */
    function operator() external view returns (address operator_);

    /**
     * @notice Change the operator of the contract
     * @dev Can only be called by the current operator
     * @param operator_ The address of the new operator
     */
    function setOperator(address operator_) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { ITokenManagerType } from './ITokenManagerType.sol';
import { IOperatable } from './IOperatable.sol';
import { IFlowLimit } from './IFlowLimit.sol';
import { IImplementation } from './IImplementation.sol';

/**
 * @title ITokenManager
 * @notice This contract is responsible for handling tokens before initiating a cross chain token transfer, or after receiving one.
 */
interface ITokenManager is ITokenManagerType, IOperatable, IFlowLimit, IImplementation {
    error TokenLinkerZeroAddress();
    error NotService();
    error TakeTokenFailed();
    error GiveTokenFailed();
    error NotToken();

    /**
     * @notice A function that should return the address of the token.
     * Must be overridden in the inheriting contract.
     * @return address address of the token.
     */
    function tokenAddress() external view returns (address);

    /**
     * @notice A function that should return the implementation type of the token manager.
     */
    function implementationType() external pure returns (uint256);

    /**
     * @notice Calls the service to initiate the a cross-chain transfer after taking the appropriate amount of tokens from the user.
     * @param destinationChain the name of the chain to send tokens to.
     * @param destinationAddress the address of the user to send tokens to.
     * @param amount the amount of tokens to take from msg.sender.
     */
    function sendToken(
        string calldata destinationChain,
        bytes calldata destinationAddress,
        uint256 amount,
        bytes calldata metadata
    ) external payable;

    /**
     * @notice Calls the service to initiate the a cross-chain transfer with data after taking the appropriate amount of tokens from the user.
     * @param destinationChain the name of the chain to send tokens to.
     * @param destinationAddress the address of the user to send tokens to.
     * @param amount the amount of tokens to take from msg.sender.
     * @param data the data to pass to the destination contract.
     */
    function callContractWithInterchainToken(
        string calldata destinationChain,
        bytes calldata destinationAddress,
        uint256 amount,
        bytes calldata data
    ) external payable;

    /**
     * @notice Calls the service to initiate the a cross-chain transfer after taking the appropriate amount of tokens from the user. This can only be called by the token itself.
     * @param sender the address of the user paying for the cross chain transfer.
     * @param destinationChain the name of the chain to send tokens to.
     * @param destinationAddress the address of the user to send tokens to.
     * @param amount the amount of tokens to take from msg.sender.
     */
    function transmitInterchainTransfer(
        address sender,
        string calldata destinationChain,
        bytes calldata destinationAddress,
        uint256 amount,
        bytes calldata metadata
    ) external payable;

    /**
     * @notice This function gives token to a specified address. Can only be called by the service.
     * @param destinationAddress the address to give tokens to.
     * @param amount the amount of token to give.
     * @return the amount of token actually given, which will onle be differen than `amount` in cases where the token takes some on-transfer fee.
     */
    function giveToken(address destinationAddress, uint256 amount) external returns (uint256);

    /**
     * @notice This function sets the flow limit for this TokenManager. Can only be called by the operator.
     * @param flowLimit the maximum difference between the tokens flowing in and/or out at any given interval of time (6h)
     */
    function setFlowLimit(uint256 flowLimit) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ITokenManagerType
 * @notice A simple interface that defines all the token manager types
 */
interface ITokenManagerType {
    enum TokenManagerType {
        LOCK_UNLOCK,
        MINT_BURN,
        LIQUIDITY_POOL
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title AddressBytesUtils
 * @dev This library provides utility functions to convert between `address` and `bytes`.
 */
library AddressBytesUtils {
    error InvalidBytesLength(bytes bytesAddress);

    /**
     * @dev Converts a bytes address to an address type.
     * @param bytesAddress The bytes representation of an address
     * @return addr The converted address
     */
    function toAddress(bytes memory bytesAddress) internal pure returns (address addr) {
        if (bytesAddress.length != 20) revert InvalidBytesLength(bytesAddress);

        assembly {
            addr := mload(add(bytesAddress, 20))
        }
    }

    /**
     * @dev Converts an address to bytes.
     * @param addr The address to be converted
     * @return bytesAddress The bytes representation of the address
     */
    function toBytes(address addr) internal pure returns (bytes memory bytesAddress) {
        bytesAddress = new bytes(20);

        assembly {
            mstore(add(bytesAddress, 20), addr)
            mstore(bytesAddress, 20)
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC20 } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IERC20.sol';

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is IERC20 {
    mapping(address => uint256) public override balanceOf;

    mapping(address => mapping(address => uint256)) public override allowance;

    uint256 public override totalSupply;

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) external virtual override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) external virtual override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external virtual override returns (bool) {
        uint256 _allowance = allowance[sender][msg.sender];

        if (_allowance != type(uint256).max) {
            _approve(sender, msg.sender, _allowance - amount);
        }

        _transfer(sender, recipient, amount);

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) external virtual returns (bool) {
        _approve(msg.sender, spender, allowance[msg.sender][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) external virtual returns (bool) {
        _approve(msg.sender, spender, allowance[msg.sender][spender] - subtractedValue);
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        if (sender == address(0) || recipient == address(0)) revert InvalidAccount();

        balanceOf[sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        if (account == address(0)) revert InvalidAccount();

        totalSupply += amount;
        balanceOf[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        if (account == address(0)) revert InvalidAccount();

        balanceOf[account] -= amount;
        totalSupply -= amount;
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        if (owner == address(0) || spender == address(0)) revert InvalidAccount();

        allowance[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC20 } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IERC20.sol';
import { IERC20Permit } from '@axelar-network/axelar-cgp-solidity/contracts/interfaces/IERC20Permit.sol';

import { ERC20 } from './ERC20.sol';

/**
 * @title ERC20Permit Contract
 * @dev Extension of ERC20 to include permit functionality (EIP-2612).
 * Allows for approval of ERC20 tokens by signature rather than transaction.
 */
abstract contract ERC20Permit is IERC20, IERC20Permit, ERC20 {
    error PermitExpired();
    error InvalidS();
    error InvalidV();
    error InvalidSignature();

    /**
     * @dev Represents hash of the EIP-712 Domain Separator.
     */
    // solhint-disable-next-line var-name-mixedcase
    bytes32 public DOMAIN_SEPARATOR;

    string private constant EIP191_PREFIX_FOR_EIP712_STRUCTURED_DATA = '\x19\x01';

    // keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)')
    bytes32 private constant DOMAIN_TYPE_SIGNATURE_HASH = bytes32(0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f);

    // keccak256('Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)')
    bytes32 private constant PERMIT_SIGNATURE_HASH = bytes32(0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9);

    /**
     * @dev Mapping of nonces for each address.
     */
    mapping(address => uint256) public nonces;

    /**
     * @notice Internal function to set the domain type signature hash
     * @param name The token name
     */
    function _setDomainTypeSignatureHash(string memory name) internal {
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(DOMAIN_TYPE_SIGNATURE_HASH, keccak256(bytes(name)), keccak256(bytes('1')), block.chainid, address(this))
        );
    }

    /**
     * @notice Permit the designated spender to spend the holder's tokens
     * @dev The permit function is used to allow a holder to designate a spender
     * to spend tokens on their behalf via a signed message.
     * @param issuer The address of the token holder
     * @param spender The address of the designated spender
     * @param value The number of tokens to be spent
     * @param deadline The time at which the permission to spend expires
     * @param v The recovery id of the signature
     * @param r Half of the ECDSA signature pair
     * @param s Half of the ECDSA signature pair
     */
    function permit(address issuer, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external {
        if (block.timestamp > deadline) revert PermitExpired();

        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) revert InvalidS();

        if (v != 27 && v != 28) revert InvalidV();

        bytes32 digest = keccak256(
            abi.encodePacked(
                EIP191_PREFIX_FOR_EIP712_STRUCTURED_DATA,
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_SIGNATURE_HASH, issuer, spender, value, nonces[issuer]++, deadline))
            )
        );

        address recoveredAddress = ecrecover(digest, v, r, s);

        if (recoveredAddress != issuer) revert InvalidSignature();

        // _approve will revert if issuer is address(0x0)
        _approve(issuer, spender, value);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC20BurnableMintable } from '../interfaces/IERC20BurnableMintable.sol';

import { InterchainToken } from '../interchain-token/InterchainToken.sol';
import { ERC20Permit } from '../token-implementations/ERC20Permit.sol';
import { AddressBytesUtils } from '../libraries/AddressBytesUtils.sol';
import { ITokenManager } from '../interfaces/ITokenManager.sol';
import { Implementation } from '../utils/Implementation.sol';
import { Distributable } from '../utils/Distributable.sol';

/**
 * @title StandardizedToken
 * @notice This contract implements a standardized token which extends InterchainToken functionality.
 * This contract also inherits Distributable and Implementation logic.
 */
abstract contract StandardizedToken is InterchainToken, ERC20Permit, Implementation, Distributable {
    using AddressBytesUtils for bytes;

    address public tokenManager;
    string public name;
    string public symbol;
    uint8 public decimals;

    bytes32 private constant CONTRACT_ID = keccak256('standardized-token');

    /**
     * @notice Getter for the contract id.
     */
    function contractId() external pure returns (bytes32) {
        return CONTRACT_ID;
    }

    /**
     * @notice Returns the token manager for this token
     * @return ITokenManager The token manager contract
     */
    function getTokenManager() public view override returns (ITokenManager) {
        return ITokenManager(tokenManager);
    }

    /**
     * @notice Setup function to initialize contract parameters
     * @param params The setup parameters in bytes
     * The setup params include tokenManager, distributor, tokenName, symbol, decimals, mintAmount and mintTo
     */
    function setup(bytes calldata params) external override onlyProxy {
        {
            address distributor_;
            address tokenManager_;
            string memory tokenName;
            (tokenManager_, distributor_, tokenName, symbol, decimals) = abi.decode(params, (address, address, string, string, uint8));
            _setDistributor(distributor_);
            tokenManager = tokenManager_;
            _setDomainTypeSignatureHash(tokenName);
            name = tokenName;
        }
        {
            uint256 mintAmount;
            address mintTo;
            (, , , , , mintAmount, mintTo) = abi.decode(params, (address, address, string, string, uint8, uint256, address));
            if (mintAmount > 0) {
                _mint(mintTo, mintAmount);
            }
        }
    }

    /**
     * @notice Function to mint new tokens
     * Can only be called by the distributor address.
     * @param account The address that will receive the minted tokens
     * @param amount The amount of tokens to mint
     */
    function mint(address account, uint256 amount) external onlyDistributor {
        _mint(account, amount);
    }

    /**
     * @notice Function to burn tokens
     * Can only be called by the distributor address.
     * @param account The address that will have its tokens burnt
     * @param amount The amount of tokens to burn
     */
    function burn(address account, uint256 amount) external onlyDistributor {
        _burn(account, amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { StandardizedToken } from './StandardizedToken.sol';

contract StandardizedTokenLockUnlock is StandardizedToken {
    function tokenManagerRequiresApproval() public pure override returns (bool) {
        return true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IDistributable } from '../interfaces/IDistributable.sol';

/**
 * @title Distributable Contract
 * @dev A contract module which provides a basic access control mechanism, where
 * there is an account (a distributor) that can be granted exclusive access to
 * specific functions. This module is used through inheritance.
 */
contract Distributable is IDistributable {
    // uint256(keccak256('distributor')) - 1
    uint256 internal constant DISTRIBUTOR_SLOT = 0x71c5a35e45a25c49e8f747acd4bcb869814b3d104c492d2554f4c46e12371f56;

    /**
     * @dev Throws a NotDistributor custom eror if called by any account other than the distributor.
     */
    modifier onlyDistributor() {
        if (distributor() != msg.sender) revert NotDistributor();
        _;
    }

    /**
     * @notice Get the address of the distributor
     * @return distr of the distributor
     */
    function distributor() public view returns (address distr) {
        assembly {
            distr := sload(DISTRIBUTOR_SLOT)
        }
    }

    /**
     * @dev Internal function that stores the new distributor address in the correct storage slot
     * @param distributor_ The address of the new distributor
     */
    function _setDistributor(address distributor_) internal {
        assembly {
            sstore(DISTRIBUTOR_SLOT, distributor_)
        }
        emit DistributorChanged(distributor_);
    }

    /**
     * @notice Change the distributor of the contract
     * @dev Can only be called by the current distributor
     * @param distr The address of the new distributor
     */
    function setDistributor(address distr) external onlyDistributor {
        _setDistributor(distr);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IImplementation } from '../interfaces/IImplementation.sol';

/**
 * @title Implementation
 * @notice This contract serves as a base for other contracts and enforces a proxy-first access restriction.
 * @dev Derived contracts must implement the setup function.
 */
abstract contract Implementation is IImplementation {
    address private immutable implementationAddress;

    /**
     * @dev Contract constructor that sets the implementation address to the address of this contract.
     */
    constructor() {
        implementationAddress = address(this);
    }

    /**
     * @dev Modifier to require the caller to be the proxy contract.
     * Reverts if the caller is the current contract (i.e., the implementation contract itself).
     */
    modifier onlyProxy() {
        if (implementationAddress == address(this)) revert NotProxy();
        _;
    }

    /**
     * @notice Initializes contract parameters.
     * This function is intended to be overridden by derived contracts.
     * The overriding function must have the onlyProxy modifier.
     * @param params The parameters to be used for initialization
     */
    function setup(bytes calldata params) external virtual;
}