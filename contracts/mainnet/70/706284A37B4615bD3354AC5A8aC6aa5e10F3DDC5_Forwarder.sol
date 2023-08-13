// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import {GELATO_RELAY, GELATO_RELAY_ZKSYNC} from "../constants/GelatoRelay.sol";

abstract contract GelatoRelayBase {
    modifier onlyGelatoRelay() {
        require(_isGelatoRelay(msg.sender), "onlyGelatoRelay");
        _;
    }

    function _isGelatoRelay(address _forwarder) internal view returns (bool) {
        return
            block.chainid == 324 || block.chainid == 280
                ? _forwarder == GELATO_RELAY_ZKSYNC
                : _forwarder == GELATO_RELAY;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import {
    GELATO_RELAY_ERC2771,
    GELATO_RELAY_ERC2771_ZKSYNC
} from "../constants/GelatoRelay.sol";

abstract contract GelatoRelayERC2771Base {
    modifier onlyGelatoRelayERC2771() {
        require(_isGelatoRelayERC2771(msg.sender), "onlyGelatoRelayERC2771");
        _;
    }

    function _isGelatoRelayERC2771(address _forwarder)
        internal
        view
        returns (bool)
    {
        // Use another address on zkSync
        if (block.chainid == 324 || block.chainid == 280) {
            return _forwarder == GELATO_RELAY_ERC2771_ZKSYNC;
        }
        return _forwarder == GELATO_RELAY_ERC2771;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

address constant GELATO_RELAY = 0xaBcC9b596420A9E9172FD5938620E265a0f9Df92;
address constant GELATO_RELAY_ERC2771 = 0xb539068872230f20456CF38EC52EF2f91AF4AE49;

address constant GELATO_RELAY_ZKSYNC = 0xB16a1DbE755f992636705fDbb3A8678a657EB3ea;
address constant GELATO_RELAY_ERC2771_ZKSYNC = 0x22DCC39b2AC376862183dd35A1664798dafC7Da6;

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
pragma solidity 0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ITokenMessenger} from "./interfaces/ITokenMessenger.sol";
import {IMessageTransmitter} from "./interfaces/IMessageTransmitter.sol";
import {GelatoRelayContext} from "./vendor/GelatoRelayContext.sol";

contract Forwarder is GelatoRelayContext {
    IERC20 public immutable token;
    ITokenMessenger public immutable tokenMessenger;
    IMessageTransmitter public immutable messageTransmitter;

    constructor(
        IERC20 _token,
        ITokenMessenger _tokenMessenger,
        IMessageTransmitter _messageTransmitter
    ) {
        token = _token;
        tokenMessenger = _tokenMessenger;
        messageTransmitter = _messageTransmitter;
    }

    function deposit(
        uint256 maxFee,
        uint32 destinationDomain,
        bytes calldata receiveAuthorization
    ) external onlyGelatoRelayERC2771 {
        address owner = abi.decode(receiveAuthorization, (address));
        require(
            _getMsgSender() == owner,
            "Forwarder.deposit: signer must be authorizer"
        );

        _receiveWithAuthorization(receiveAuthorization);
        _transferRelayFeeCappedERC2771(maxFee);

        uint256 remaining = token.balanceOf(address(this));
        token.approve(address(tokenMessenger), remaining);

        tokenMessenger.depositForBurn(
            remaining,
            destinationDomain,
            _addressToBytes32(owner),
            address(token)
        );
    }

    function withdraw(
        bytes calldata message,
        bytes calldata attestation,
        bytes calldata receiveAuthorization
    ) external onlyGelatoRelay {
        messageTransmitter.receiveMessage(message, attestation);

        _receiveWithAuthorization(receiveAuthorization);
        _transferRelayFee();

        address owner = abi.decode(receiveAuthorization, (address));
        uint256 remaining = token.balanceOf(address(this));

        token.transfer(owner, remaining);
    }

    function _receiveWithAuthorization(bytes calldata authorization) internal {
        _requireCall(
            address(token),
            abi.encodePacked(bytes4(0xef55bec6), authorization)
        );
    }

    function _requireCall(address target, bytes memory data) internal {
        (bool success, bytes memory result) = address(target).call(data);
        assembly {
            if eq(success, false) {
                revert(add(result, 32), mload(result))
            }
        }
    }

    function _addressToBytes32(address addr) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(addr)));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IMessageTransmitter {
    function receiveMessage(
        bytes calldata message,
        bytes calldata attestation
    ) external returns (bool success);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface ITokenMessenger {
    function depositForBurn(
        uint256 amount,
        uint32 destinationDomain,
        bytes32 mintRecipient,
        address burnToken
    ) external returns (uint64 nonce);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {
    GelatoRelayBase
} from "@gelatonetwork/relay-context/contracts/base/GelatoRelayBase.sol";
import {
    GelatoRelayERC2771Base
} from "@gelatonetwork/relay-context/contracts/base/GelatoRelayERC2771Base.sol";

uint256 constant _ERC2771_FEE_COLLECTOR_START = 92;
uint256 constant _ERC2771_FEE_TOKEN_START = 72;
uint256 constant _ERC2771_FEE_START = 52;
uint256 constant _ERC2771_MSG_SENDER_START = 20;

uint256 constant _FEE_COLLECTOR_START = 72;
uint256 constant _FEE_TOKEN_START = 52;
uint256 constant _FEE_START = 32;

// solhint-disable-next-line private-vars-leading-underscore
function _getFeeCollectorRelayContextERC2771()
    pure
    returns (address feeCollector)
{
    assembly {
        feeCollector := shr(
            96,
            calldataload(sub(calldatasize(), _ERC2771_FEE_COLLECTOR_START))
        )
    }
}

// solhint-disable-next-line private-vars-leading-underscore
function _getFeeTokenRelayContextERC2771() pure returns (address feeToken) {
    assembly {
        feeToken := shr(
            96,
            calldataload(sub(calldatasize(), _ERC2771_FEE_TOKEN_START))
        )
    }
}

// solhint-disable-next-line private-vars-leading-underscore
function _getFeeRelayContextERC2771() pure returns (uint256 fee) {
    assembly {
        fee := calldataload(sub(calldatasize(), _ERC2771_FEE_START))
    }
}

// solhint-disable-next-line private-vars-leading-underscore
function _getMsgSenderRelayContextERC2771() pure returns (address _msgSender) {
    assembly {
        _msgSender := shr(
            96,
            calldataload(sub(calldatasize(), _ERC2771_MSG_SENDER_START))
        )
    }
}

// solhint-disable-next-line private-vars-leading-underscore
function _getFeeCollectorRelayContext() pure returns (address feeCollector) {
    assembly {
        feeCollector := shr(
            96,
            calldataload(sub(calldatasize(), _FEE_COLLECTOR_START))
        )
    }
}

// solhint-disable-next-line private-vars-leading-underscore
function _getFeeTokenRelayContext() pure returns (address feeToken) {
    assembly {
        feeToken := shr(96, calldataload(sub(calldatasize(), _FEE_TOKEN_START)))
    }
}

// solhint-disable-next-line private-vars-leading-underscore
function _getFeeRelayContext() pure returns (uint256 fee) {
    assembly {
        fee := calldataload(sub(calldatasize(), _FEE_START))
    }
}

abstract contract GelatoRelayContext is
    GelatoRelayBase,
    GelatoRelayERC2771Base
{
    function _transferRelayFee() internal {
        _getFeeToken().transfer(_getFeeCollector(), _getFee());
    }

    function _transferRelayFeeERC2771() internal {
        _getFeeTokenERC2771().transfer(
            _getFeeCollectorERC2771(),
            _getFeeERC2771()
        );
    }

    function _transferRelayFeeCapped(uint256 maxFee) internal {
        uint256 fee = _getFee();
        require(
            fee <= maxFee,
            "GelatoRelayContext._transferRelayFeeCapped: maxFee"
        );
        _getFeeToken().transfer(_getFeeCollector(), fee);
    }

    function _transferRelayFeeCappedERC2771(uint256 maxFee) internal {
        uint256 fee = _getFeeERC2771();
        require(
            fee <= maxFee,
            "GelatoRelayContext._transferRelayFeeCappedERC2771: maxFee"
        );
        _getFeeTokenERC2771().transfer(_getFeeCollectorERC2771(), fee);
    }

    function _getMsgSender() internal view virtual returns (address) {
        return
            _isGelatoRelayERC2771(msg.sender)
                ? _getMsgSenderRelayContextERC2771()
                : msg.sender;
    }

    function _getFeeCollectorERC2771() internal pure returns (address) {
        return _getFeeCollectorRelayContextERC2771();
    }

    function _getFeeTokenERC2771() internal pure returns (IERC20) {
        return IERC20(_getFeeTokenRelayContextERC2771());
    }

    function _getFeeERC2771() internal pure returns (uint256) {
        return _getFeeRelayContextERC2771();
    }

    function _getFeeCollector() internal pure returns (address) {
        return _getFeeCollectorRelayContext();
    }

    function _getFeeToken() internal pure returns (IERC20) {
        return IERC20(_getFeeTokenRelayContext());
    }

    function _getFee() internal pure returns (uint256) {
        return _getFeeRelayContext();
    }
}