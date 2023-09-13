// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import { L1CustomGateway } from "./L1CustomGateway.sol";
import { IERC20Inbox } from "../L1ArbitrumMessenger.sol";
import { IERC20Bridge } from "../../libraries/IERC20Bridge.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title Gateway for "custom" bridging functionality in an ERC20-based rollup.
 * @notice Adds new entrypoints that have `_feeAmount` as parameter, while entrypoints without that parameter are reverted.
 */
contract L1OrbitCustomGateway is L1CustomGateway {
    using SafeERC20 for IERC20;

    /**
     * @notice Allows L1 Token contract to trustlessly register its custom L2 counterpart, in an ERC20-based rollup. Retryable costs are paid in native token.
     * @param _l2Address counterpart address of L1 token
     * @param _maxGas max gas for L2 retryable execution
     * @param _gasPriceBid gas price for L2 retryable ticket
     * @param _maxSubmissionCost base submission cost for L2 retryable ticket
     * @param _feeAmount total amount of fees in native token to cover for retryable ticket costs. This amount will be transferred from user to bridge.
     * @return Retryable ticket ID
     */
    function registerTokenToL2(
        address _l2Address,
        uint256 _maxGas,
        uint256 _gasPriceBid,
        uint256 _maxSubmissionCost,
        uint256 _feeAmount
    ) external returns (uint256) {
        return
            registerTokenToL2(
                _l2Address,
                _maxGas,
                _gasPriceBid,
                _maxSubmissionCost,
                msg.sender,
                _feeAmount
            );
    }

    /**
     * @notice Allows L1 Token contract to trustlessly register its custom L2 counterpart, in an ERC20-based rollup. Retryable costs are paid in native token.
     * @param _l2Address counterpart address of L1 token
     * @param _maxGas max gas for L2 retryable execution
     * @param _gasPriceBid gas price for L2 retryable ticket
     * @param _maxSubmissionCost base submission cost for L2 retryable ticket
     * @param _creditBackAddress address for crediting back overpayment of _maxSubmissionCost
     * @param _feeAmount total amount of fees in native token to cover for retryable ticket costs. This amount will be transferred from user to bridge.
     * @return Retryable ticket ID
     */
    function registerTokenToL2(
        address _l2Address,
        uint256 _maxGas,
        uint256 _gasPriceBid,
        uint256 _maxSubmissionCost,
        address _creditBackAddress,
        uint256 _feeAmount
    ) public returns (uint256) {
        return
            _registerTokenToL2(
                _l2Address,
                _maxGas,
                _gasPriceBid,
                _maxSubmissionCost,
                _creditBackAddress,
                _feeAmount
            );
    }

    /**
     * @notice Allows owner to force register a custom L1/L2 token pair.
     * @dev _l1Addresses[i] counterpart is assumed to be _l2Addresses[i]
     * @param _l1Addresses array of L1 addresses
     * @param _l2Addresses array of L2 addresses
     * @param _maxGas max gas for L2 retryable execution
     * @param _gasPriceBid gas price for L2 retryable ticket
     * @param _maxSubmissionCost base submission cost for L2 retryable ticket
     * @param _feeAmount total amount of fees in native token to cover for retryable ticket costs. This amount will be transferred from user to bridge.
     * @return Retryable ticket ID
     */
    function forceRegisterTokenToL2(
        address[] calldata _l1Addresses,
        address[] calldata _l2Addresses,
        uint256 _maxGas,
        uint256 _gasPriceBid,
        uint256 _maxSubmissionCost,
        uint256 _feeAmount
    ) external payable onlyOwner returns (uint256) {
        return
            _forceRegisterTokenToL2(
                _l1Addresses,
                _l2Addresses,
                _maxGas,
                _gasPriceBid,
                _maxSubmissionCost,
                _feeAmount
            );
    }

    /**
     * @notice Revert 'registerTokenToL2' entrypoint which doesn't have total amount of token fees as an argument.
     */
    function registerTokenToL2(
        address,
        uint256,
        uint256,
        uint256,
        address
    ) public payable override returns (uint256) {
        revert("NOT_SUPPORTED_IN_ORBIT");
    }

    /**
     * @notice Revert 'registerTokenToL2' entrypoint which doesn't have total amount of token fees as an argument.
     */
    function registerTokenToL2(
        address,
        uint256,
        uint256,
        uint256
    ) external payable override returns (uint256) {
        revert("NOT_SUPPORTED_IN_ORBIT");
    }

    /**
     * @notice Revert 'forceRegisterTokenToL2' entrypoint which doesn't have total amount of token fees as an argument.
     */
    function forceRegisterTokenToL2(
        address[] calldata,
        address[] calldata,
        uint256,
        uint256,
        uint256
    ) external payable override onlyOwner returns (uint256) {
        revert("NOT_SUPPORTED_IN_ORBIT");
    }

    function _parseUserEncodedData(bytes memory data)
        internal
        pure
        override
        returns (
            uint256 maxSubmissionCost,
            bytes memory callHookData,
            uint256 tokenTotalFeeAmount
        )
    {
        (maxSubmissionCost, callHookData, tokenTotalFeeAmount) = abi.decode(
            data,
            (uint256, bytes, uint256)
        );
    }

    function _initiateDeposit(
        address _refundTo,
        address _from,
        uint256, // _amount, this info is already contained in _data
        uint256 _maxGas,
        uint256 _gasPriceBid,
        uint256 _maxSubmissionCost,
        uint256 tokenTotalFeeAmount,
        bytes memory _data
    ) internal override returns (uint256) {
        return
            sendTxToL2CustomRefund(
                inbox,
                counterpartGateway,
                _refundTo,
                _from,
                tokenTotalFeeAmount,
                0,
                L2GasParams({
                    _maxSubmissionCost: _maxSubmissionCost,
                    _maxGas: _maxGas,
                    _gasPriceBid: _gasPriceBid
                }),
                _data
            );
    }

    function _createRetryable(
        address _inbox,
        address _to,
        address _refundTo,
        address _user,
        uint256 _totalFeeAmount,
        uint256 _l2CallValue,
        uint256 _maxSubmissionCost,
        uint256 _maxGas,
        uint256 _gasPriceBid,
        bytes memory _data
    ) internal override returns (uint256) {
        {
            // Transfer native token amount needed to pay for retryable fees to the inbox.
            // Fee tokens will be transferred from user who initiated the action - that's `_user` account in
            // case call was routed by router, or msg.sender in case gateway's entrypoint was called directly.
            address nativeFeeToken = IERC20Bridge(address(getBridge(_inbox))).nativeToken();
            uint256 inboxNativeTokenBalance = IERC20(nativeFeeToken).balanceOf(_inbox);
            if (inboxNativeTokenBalance < _totalFeeAmount) {
                address transferFrom = isRouter(msg.sender) ? _user : msg.sender;
                IERC20(nativeFeeToken).safeTransferFrom(
                    transferFrom,
                    _inbox,
                    _totalFeeAmount - inboxNativeTokenBalance
                );
            }
        }

        return
            IERC20Inbox(_inbox).createRetryableTicket(
                _to,
                _l2CallValue,
                _maxSubmissionCost,
                _refundTo,
                _user,
                _maxGas,
                _gasPriceBid,
                _totalFeeAmount,
                _data
            );
    }
}

// SPDX-License-Identifier: Apache-2.0

/*
 * Copyright 2020, Offchain Labs, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

pragma solidity ^0.8.0;

import { ArbitrumEnabledToken } from "../ICustomToken.sol";
import "./L1ArbitrumExtendedGateway.sol";
import "../../arbitrum/gateway/L2CustomGateway.sol";
import "../../libraries/gateway/ICustomGateway.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "../../libraries/Whitelist.sol";

/**
 * @title Gatway for "custom" bridging functionality
 * @notice Handles some (but not all!) custom Gateway needs.
 */
contract L1CustomGateway is L1ArbitrumExtendedGateway, ICustomGateway {
    using Address for address;
    // stores addresses of L2 tokens to be used
    mapping(address => address) public override l1ToL2Token;
    // owner is able to force add custom mappings
    address public owner;

    // whitelist not used anymore
    address public whitelist;

    // start of inline reentrancy guard
    // https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.4.2/contracts/utils/ReentrancyGuard.sol
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;

    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "ONLY_OWNER");
        _;
    }

    function outboundTransferCustomRefund(
        address _l1Token,
        address _refundTo,
        address _to,
        uint256 _amount,
        uint256 _maxGas,
        uint256 _gasPriceBid,
        bytes calldata _data
    ) public payable override nonReentrant returns (bytes memory res) {
        return
            super.outboundTransferCustomRefund(
                _l1Token,
                _refundTo,
                _to,
                _amount,
                _maxGas,
                _gasPriceBid,
                _data
            );
    }

    function finalizeInboundTransfer(
        address _token,
        address _from,
        address _to,
        uint256 _amount,
        bytes calldata _data
    ) public payable override nonReentrant {
        // the superclass checks onlyCounterpartGateway
        super.finalizeInboundTransfer(_token, _from, _to, _amount, _data);
    }

    function initialize(
        address _l1Counterpart,
        address _l1Router,
        address _inbox,
        address _owner
    ) public {
        L1ArbitrumGateway._initialize(_l1Counterpart, _l1Router, _inbox);
        owner = _owner;
        // disable whitelist by default
        whitelist = address(0);
        // reentrancy guard
        _status = _NOT_ENTERED;
    }

    /**
     * @notice Calculate the address used when bridging an ERC20 token
     * @dev the L1 and L2 address oracles may not always be in sync.
     * For example, a custom token may have been registered but not deploy or the contract self destructed.
     * @param l1ERC20 address of L1 token
     * @return L2 address of a bridged ERC20 token
     */
    function calculateL2TokenAddress(address l1ERC20)
        public
        view
        override(ITokenGateway, TokenGateway)
        returns (address)
    {
        return l1ToL2Token[l1ERC20];
    }

    /**
     * @notice Allows L1 Token contract to trustlessly register its custom L2 counterpart. (other registerTokenToL2 method allows excess eth recovery from _maxSubmissionCost and is recommended)
     * @param _l2Address counterpart address of L1 token
     * @param _maxGas max gas for L2 retryable exrecution
     * @param _gasPriceBid gas price for L2 retryable ticket
     * @param  _maxSubmissionCost base submission cost  L2 retryable tick3et
     * @return Retryable ticket ID
     */
    function registerTokenToL2(
        address _l2Address,
        uint256 _maxGas,
        uint256 _gasPriceBid,
        uint256 _maxSubmissionCost
    ) external payable virtual returns (uint256) {
        return registerTokenToL2(_l2Address, _maxGas, _gasPriceBid, _maxSubmissionCost, msg.sender);
    }

    /**
     * @notice Allows L1 Token contract to trustlessly register its custom L2 counterpart.
     * param _l2Address counterpart address of L1 token
     * param _maxGas max gas for L2 retryable exrecution
     * param _gasPriceBid gas price for L2 retryable ticket
     * param  _maxSubmissionCost base submission cost  L2 retryable tick3et
     * param _creditBackAddress address for crediting back overpayment of _maxSubmissionCost
     * return Retryable ticket ID
     */
    function registerTokenToL2(
        address _l2Address,
        uint256 _maxGas,
        uint256 _gasPriceBid,
        uint256 _maxSubmissionCost,
        address _creditBackAddress
    ) public payable virtual returns (uint256) {
        return
            _registerTokenToL2(
                _l2Address,
                _maxGas,
                _gasPriceBid,
                _maxSubmissionCost,
                _creditBackAddress,
                msg.value
            );
    }

    function _registerTokenToL2(
        address _l2Address,
        uint256 _maxGas,
        uint256 _gasPriceBid,
        uint256 _maxSubmissionCost,
        address _creditBackAddress,
        uint256 _feeAmount
    ) internal returns (uint256) {
        {
            require(
                ArbitrumEnabledToken(msg.sender).isArbitrumEnabled() == uint8(0xb1),
                "NOT_ARB_ENABLED"
            );

            address currL2Addr = l1ToL2Token[msg.sender];
            if (currL2Addr != address(0)) {
                // if token is already set, don't allow it to set a different L2 address
                require(currL2Addr == _l2Address, "NO_UPDATE_TO_DIFFERENT_ADDR");
            }
        }

        l1ToL2Token[msg.sender] = _l2Address;

        address[] memory l1Addresses = new address[](1);
        address[] memory l2Addresses = new address[](1);
        l1Addresses[0] = msg.sender;
        l2Addresses[0] = _l2Address;

        emit TokenSet(l1Addresses[0], l2Addresses[0]);

        bytes memory _data = abi.encodeWithSelector(
            L2CustomGateway.registerTokenFromL1.selector,
            l1Addresses,
            l2Addresses
        );

        return
            sendTxToL2(
                inbox,
                counterpartGateway,
                _creditBackAddress,
                _feeAmount,
                0,
                _maxSubmissionCost,
                _maxGas,
                _gasPriceBid,
                _data
            );
    }

    function setOwner(address newOwner) external onlyOwner {
        require(newOwner != address(0), "INVALID_OWNER");
        owner = newOwner;
    }

    /**
     * @notice Allows owner to force register a custom L1/L2 token pair.
     * @dev _l1Addresses[i] counterpart is assumed to be _l2Addresses[i]
     * @param _l1Addresses array of L1 addresses
     * @param _l2Addresses array of L2 addresses
     * @param _maxGas max gas for L2 retryable exrecution
     * @param _gasPriceBid gas price for L2 retryable ticket
     * @param  _maxSubmissionCost base submission cost  L2 retryable tick3et
     * @return Retryable ticket ID
     */
    function forceRegisterTokenToL2(
        address[] calldata _l1Addresses,
        address[] calldata _l2Addresses,
        uint256 _maxGas,
        uint256 _gasPriceBid,
        uint256 _maxSubmissionCost
    ) external payable virtual onlyOwner returns (uint256) {
        return
            _forceRegisterTokenToL2(
                _l1Addresses,
                _l2Addresses,
                _maxGas,
                _gasPriceBid,
                _maxSubmissionCost,
                msg.value
            );
    }

    function _forceRegisterTokenToL2(
        address[] calldata _l1Addresses,
        address[] calldata _l2Addresses,
        uint256 _maxGas,
        uint256 _gasPriceBid,
        uint256 _maxSubmissionCost,
        uint256 _feeAmount
    ) internal returns (uint256) {
        require(_l1Addresses.length == _l2Addresses.length, "INVALID_LENGTHS");

        for (uint256 i = 0; i < _l1Addresses.length; i++) {
            // here we assume the owner checked both addresses offchain before force registering
            // require(address(_l1Addresses[i]).isContract(), "MUST_BE_CONTRACT");
            l1ToL2Token[_l1Addresses[i]] = _l2Addresses[i];
            emit TokenSet(_l1Addresses[i], _l2Addresses[i]);
        }

        bytes memory _data = abi.encodeWithSelector(
            L2CustomGateway.registerTokenFromL1.selector,
            _l1Addresses,
            _l2Addresses
        );

        return
            sendTxToL2(
                inbox,
                counterpartGateway,
                msg.sender,
                _feeAmount,
                0,
                _maxSubmissionCost,
                _maxGas,
                _gasPriceBid,
                _data
            );
    }
}

// SPDX-License-Identifier: Apache-2.0

/*
 * Copyright 2020, Offchain Labs, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

pragma solidity ^0.8.0;

import "@arbitrum/nitro-contracts/src/bridge/IInbox.sol";
import "@arbitrum/nitro-contracts/src/bridge/IOutbox.sol";

/// @notice L1 utility contract to assist with L1 <=> L2 interactions
/// @dev this is an abstract contract instead of library so the functions can be easily overriden when testing
abstract contract L1ArbitrumMessenger {
    event TxToL2(address indexed _from, address indexed _to, uint256 indexed _seqNum, bytes _data);

    struct L2GasParams {
        uint256 _maxSubmissionCost;
        uint256 _maxGas;
        uint256 _gasPriceBid;
    }

    function sendTxToL2CustomRefund(
        address _inbox,
        address _to,
        address _refundTo,
        address _user,
        uint256 _l1CallValue,
        uint256 _l2CallValue,
        L2GasParams memory _l2GasParams,
        bytes memory _data
    ) internal returns (uint256) {
        // alternative function entry point when struggling with the stack size
        return
            sendTxToL2CustomRefund(
                _inbox,
                _to,
                _refundTo,
                _user,
                _l1CallValue,
                _l2CallValue,
                _l2GasParams._maxSubmissionCost,
                _l2GasParams._maxGas,
                _l2GasParams._gasPriceBid,
                _data
            );
    }

    function sendTxToL2(
        address _inbox,
        address _to,
        address _user,
        uint256 _l1CallValue,
        uint256 _l2CallValue,
        L2GasParams memory _l2GasParams,
        bytes memory _data
    ) internal returns (uint256) {
        // alternative function entry point when struggling with the stack size
        return
            sendTxToL2(
                _inbox,
                _to,
                _user,
                _l1CallValue,
                _l2CallValue,
                _l2GasParams._maxSubmissionCost,
                _l2GasParams._maxGas,
                _l2GasParams._gasPriceBid,
                _data
            );
    }

    function sendTxToL2CustomRefund(
        address _inbox,
        address _to,
        address _refundTo,
        address _user,
        uint256 _l1CallValue,
        uint256 _l2CallValue,
        uint256 _maxSubmissionCost,
        uint256 _maxGas,
        uint256 _gasPriceBid,
        bytes memory _data
    ) internal returns (uint256) {
        uint256 seqNum = _createRetryable(
            _inbox,
            _to,
            _refundTo,
            _user,
            _l1CallValue,
            _l2CallValue,
            _maxSubmissionCost,
            _maxGas,
            _gasPriceBid,
            _data
        );
        emit TxToL2(_user, _to, seqNum, _data);
        return seqNum;
    }

    function sendTxToL2(
        address _inbox,
        address _to,
        address _user,
        uint256 _l1CallValue,
        uint256 _l2CallValue,
        uint256 _maxSubmissionCost,
        uint256 _maxGas,
        uint256 _gasPriceBid,
        bytes memory _data
    ) internal returns (uint256) {
        return
            sendTxToL2CustomRefund(
                _inbox,
                _to,
                _user,
                _user,
                _l1CallValue,
                _l2CallValue,
                _maxSubmissionCost,
                _maxGas,
                _gasPriceBid,
                _data
            );
    }

    function getBridge(address _inbox) internal view returns (IBridge) {
        return IInbox(_inbox).bridge();
    }

    /// @dev the l2ToL1Sender behaves as the tx.origin, the msg.sender should be validated to protect against reentrancies
    function getL2ToL1Sender(address _inbox) internal view returns (address) {
        IOutbox outbox = IOutbox(getBridge(_inbox).activeOutbox());
        address l2ToL1Sender = outbox.l2ToL1Sender();

        require(l2ToL1Sender != address(0), "NO_SENDER");
        return l2ToL1Sender;
    }

    /**
     * @notice Calls inbox to create retryable ticket. Default implementation is for standard Eth-based rollup, but it can be overriden to create retryable in ERC20-based rollup.
     * @param _inbox address of the rollup's inbox
     * @param _to destination L2 contract address
     * @param _refundTo refund address for excess fee
     * @param _user refund address for callvalue
     * @param _totalFeeAmount amount of fees to pay, in Eth or native token, for retryable's execution
     * @param _l2CallValue call value for retryable L2 message
     * @param _maxSubmissionCost Max gas deducted from user's L2 balance to cover base submission fee
     * @param _maxGas Max gas deducted from user's L2 balance to cover L2 execution
     * @param _gasPriceBid price bid for L2 execution
     * @param _data ABI encoded data of L2 message
     * @return unique message number of the retryable transaction
     */
    function _createRetryable(
        address _inbox,
        address _to,
        address _refundTo,
        address _user,
        uint256 _totalFeeAmount,
        uint256 _l2CallValue,
        uint256 _maxSubmissionCost,
        uint256 _maxGas,
        uint256 _gasPriceBid,
        bytes memory _data
    ) internal virtual returns (uint256) {
        return
            IInbox(_inbox).createRetryableTicket{ value: _totalFeeAmount }(
                _to,
                _l2CallValue,
                _maxSubmissionCost,
                _refundTo,
                _user,
                _maxGas,
                _gasPriceBid,
                _data
            );
    }
}

interface IERC20Inbox {
    function createRetryableTicket(
        address to,
        uint256 l2CallValue,
        uint256 maxSubmissionCost,
        address excessFeeRefundAddress,
        address callValueRefundAddress,
        uint256 gasLimit,
        uint256 maxFeePerGas,
        uint256 tokenTotalFeeAmount,
        bytes calldata data
    ) external returns (uint256);
}

// SPDX-License-Identifier: Apache-2.0

// solhint-disable-next-line compiler-version
pragma solidity >=0.6.9 <0.9.0;

interface IERC20Bridge {
    /**
     * @dev token that is escrowed in bridge on L1 side and minted on L2 as native currency. Also fees are paid in this token.
     */
    function nativeToken() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
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
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
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
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
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
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
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
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
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
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
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
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: Apache-2.0

/*
 * Copyright 2020, Offchain Labs, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

// solhint-disable-next-line compiler-version
pragma solidity >=0.6.9 <0.9.0;

interface ArbitrumEnabledToken {
    /// @notice should return `0xb1` if token is enabled for arbitrum gateways
    /// @dev Previous implmentation used to return `uint8(0xa4b1)`, however that causes compile time error in Solidity 0.8. due to type mismatch.
    ///      In current version `uint8(0xb1)` shall be returned, which results in no change as that's the same value as truncated `uint8(0xa4b1)`.
    function isArbitrumEnabled() external view returns (uint8);
}

/**
 * @title Minimum expected interface for L1 custom token (see TestCustomTokenL1.sol for an example implementation)
 */
interface ICustomToken is ArbitrumEnabledToken {
    /**
     * @notice Should make an external call to EthERC20Bridge.registerCustomL2Token
     */
    function registerTokenOnL2(
        address l2CustomTokenAddress,
        uint256 maxSubmissionCostForCustomBridge,
        uint256 maxSubmissionCostForRouter,
        uint256 maxGasForCustomBridge,
        uint256 maxGasForRouter,
        uint256 gasPriceBid,
        uint256 valueForGateway,
        uint256 valueForRouter,
        address creditBackAddress
    ) external payable;

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function balanceOf(address account) external view returns (uint256);
}

interface L1MintableToken is ICustomToken {
    function bridgeMint(address account, uint256 amount) external;
}

interface L1ReverseToken is L1MintableToken {
    function bridgeBurn(address account, uint256 amount) external;
}

// SPDX-License-Identifier: Apache-2.0

/*
 * Copyright 2020, Offchain Labs, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

pragma solidity ^0.8.0;

import "../../libraries/ITransferAndCall.sol";

import "./L1ArbitrumGateway.sol";

interface ITradeableExitReceiver {
    function onExitTransfer(
        address sender,
        uint256 exitNum,
        bytes calldata data
    ) external returns (bool);
}

abstract contract L1ArbitrumExtendedGateway is L1ArbitrumGateway {
    using Address for address;

    struct ExitData {
        bool isExit;
        address _newTo;
        bytes _newData;
    }

    mapping(bytes32 => ExitData) public redirectedExits;

    event WithdrawRedirected(
        address indexed from,
        address indexed to,
        uint256 indexed exitNum,
        bytes newData,
        bytes data,
        bool madeExternalCall
    );

    /**
     * @notice Allows a user to redirect their right to claim a withdrawal to another address.
     * @dev This method also allows you to make an arbitrary call after the transfer.
     * This does not validate if the exit was already triggered. It is assumed the `_exitNum` is
     * validated off-chain to ensure this was not yet triggered.
     * @param _exitNum Sequentially increasing exit counter determined by the L2 bridge
     * @param _initialDestination address the L2 withdrawal call initially set as the destination.
     * @param _newDestination address the L1 will now call instead of the previously set destination
     * @param _newData data to be used in inboundEscrowAndCall
     * @param _data optional data for external call upon transfering the exit
     */
    function transferExitAndCall(
        uint256 _exitNum,
        address _initialDestination,
        address _newDestination,
        bytes calldata _newData,
        bytes calldata _data
    ) external {
        // the initial data doesn't make a difference when transfering you exit
        // since the L2 bridge gives a unique exit ID to each exit
        (address expectedSender, ) = getExternalCall(_exitNum, _initialDestination, "");

        // if you want to transfer your exit, you must be the current destination
        require(msg.sender == expectedSender, "NOT_EXPECTED_SENDER");
        // the inboundEscrowAndCall functionality has been disabled, so no data is allowed
        require(_newData.length == 0, "NO_DATA_ALLOWED");

        setRedirectedExit(_exitNum, _initialDestination, _newDestination, _newData);

        if (_data.length > 0) {
            require(_newDestination.isContract(), "TO_NOT_CONTRACT");
            bool success = ITradeableExitReceiver(_newDestination).onExitTransfer(
                expectedSender,
                _exitNum,
                _data
            );
            require(success, "TRANSFER_HOOK_FAIL");
        }

        emit WithdrawRedirected(
            expectedSender,
            _newDestination,
            _exitNum,
            _newData,
            _data,
            _data.length > 0
        );
    }

    /// @notice this does not verify if the external call was already done
    function getExternalCall(
        uint256 _exitNum,
        address _initialDestination,
        bytes memory _initialData
    ) public view virtual override returns (address target, bytes memory data) {
        // this function is virtual so that subclasses can override it with custom logic where necessary
        bytes32 withdrawData = encodeWithdrawal(_exitNum, _initialDestination);
        ExitData storage exit = redirectedExits[withdrawData];

        // here we don't authenticate `_initialData`. we could hash it into `withdrawData` but would increase gas costs
        // this is safe because if the exit isn't overriden, the _initialData coming from L2 is trusted
        // but if the exit is traded, all we care about is the latest user calldata
        if (exit.isExit) {
            return (exit._newTo, exit._newData);
        } else {
            return (_initialDestination, _initialData);
        }
    }

    function setRedirectedExit(
        uint256 _exitNum,
        address _initialDestination,
        address _newDestination,
        bytes memory _newData
    ) internal virtual {
        bytes32 withdrawData = encodeWithdrawal(_exitNum, _initialDestination);
        redirectedExits[withdrawData] = ExitData(true, _newDestination, _newData);
    }

    function encodeWithdrawal(uint256 _exitNum, address _initialDestination)
        public
        pure
        returns (bytes32)
    {
        // here we assume the L2 bridge gives a unique exitNum to each exit
        return keccak256(abi.encode(_exitNum, _initialDestination));
    }
}

// SPDX-License-Identifier: Apache-2.0

/*
 * Copyright 2020, Offchain Labs, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

pragma solidity ^0.8.0;

import "./L2ArbitrumGateway.sol";
import "../../libraries/gateway/ICustomGateway.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract L2CustomGateway is L2ArbitrumGateway, ICustomGateway {
    // stores addresses of L2 tokens to be used
    mapping(address => address) public override l1ToL2Token;

    function initialize(address _l1Counterpart, address _router) public {
        L2ArbitrumGateway._initialize(_l1Counterpart, _router);
    }

    /**
     * @notice internal utility function used to handle when no contract is deployed at expected address
     */
    function handleNoContract(
        address _l1Token,
        address, /* expectedL2Address */
        address _from,
        address, /* _to */
        uint256 _amount,
        bytes memory /* gatewayData */
    ) internal override returns (bool shouldHalt) {
        // it is assumed that the custom token is deployed in the L2 before deposits are made
        // trigger withdrawal
        // we don't need the return value from triggerWithdrawal since this is forcing a withdrawal back to the L1
        // instead of composing with a L2 dapp
        triggerWithdrawal(_l1Token, address(this), _from, _amount, "");
        return true;
    }

    /**
     * @notice Calculate the address used when bridging an ERC20 token
     * @dev the L1 and L2 address oracles may not always be in sync.
     * For example, a custom token may have been registered but not deploy or the contract self destructed.
     * @param l1ERC20 address of L1 token
     * @return L2 address of a bridged ERC20 token
     */
    function calculateL2TokenAddress(address l1ERC20) public view override returns (address) {
        return l1ToL2Token[l1ERC20];
    }

    function registerTokenFromL1(address[] calldata l1Address, address[] calldata l2Address)
        external
        onlyCounterpartGateway
    {
        // we assume both arrays are the same length, safe since its encoded by the L1
        for (uint256 i = 0; i < l1Address.length; i++) {
            // here we don't check if l2Address is a contract and instead deal with that behaviour
            // in `handleNoContract` this way we keep the l1 and l2 address oracles in sync
            l1ToL2Token[l1Address[i]] = l2Address[i];
            emit TokenSet(l1Address[i], l2Address[i]);
        }
    }
}

// SPDX-License-Identifier: Apache-2.0

/*
 * Copyright 2020, Offchain Labs, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

// solhint-disable-next-line compiler-version
pragma solidity >=0.6.9 <0.9.0;

// import "./ITokenGateway.sol";

interface ICustomGateway {
    function l1ToL2Token(address _l1Token) external view returns (address _l2Token);

    event TokenSet(address indexed l1Address, address indexed l2Address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: Apache-2.0

/*
 * Copyright 2021, Offchain Labs, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

pragma solidity ^0.8.0;

abstract contract WhitelistConsumer {
    address public whitelist;

    event WhitelistSourceUpdated(address newSource);

    modifier onlyWhitelisted() {
        if (whitelist != address(0)) {
            require(Whitelist(whitelist).isAllowed(msg.sender), "NOT_WHITELISTED");
        }
        _;
    }

    function updateWhitelistSource(address newSource) external {
        require(msg.sender == whitelist, "NOT_FROM_LIST");
        whitelist = newSource;
        emit WhitelistSourceUpdated(newSource);
    }
}

contract Whitelist {
    address public owner;
    mapping(address => bool) public isAllowed;

    event OwnerUpdated(address newOwner);
    event WhitelistUpgraded(address newWhitelist, address[] targets);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "ONLY_OWNER");
        _;
    }

    function setOwner(address newOwner) external onlyOwner {
        owner = newOwner;
        emit OwnerUpdated(newOwner);
    }

    function setWhitelist(address[] memory user, bool[] memory val) external onlyOwner {
        require(user.length == val.length, "INVALID_INPUT");

        for (uint256 i = 0; i < user.length; i++) {
            isAllowed[user[i]] = val[i];
        }
    }

    // set new whitelist to address(0) to disable whitelist
    function triggerConsumers(address newWhitelist, address[] memory targets) external onlyOwner {
        for (uint256 i = 0; i < targets.length; i++) {
            WhitelistConsumer(targets[i]).updateWhitelistSource(newWhitelist);
        }
        emit WhitelistUpgraded(newWhitelist, targets);
    }
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

// solhint-disable-next-line compiler-version
pragma solidity >=0.6.9 <0.9.0;

import "./IBridge.sol";
import "./IDelayedMessageProvider.sol";
import "./ISequencerInbox.sol";

interface IInbox is IDelayedMessageProvider {
    function bridge() external view returns (IBridge);

    function sequencerInbox() external view returns (ISequencerInbox);

    /**
     * @notice Send a generic L2 message to the chain
     * @dev This method is an optimization to avoid having to emit the entirety of the messageData in a log. Instead validators are expected to be able to parse the data from the transaction's input
     *      This method will be disabled upon L1 fork to prevent replay attacks on L2
     * @param messageData Data of the message being sent
     */
    function sendL2MessageFromOrigin(bytes calldata messageData) external returns (uint256);

    /**
     * @notice Send a generic L2 message to the chain
     * @dev This method can be used to send any type of message that doesn't require L1 validation
     *      This method will be disabled upon L1 fork to prevent replay attacks on L2
     * @param messageData Data of the message being sent
     */
    function sendL2Message(bytes calldata messageData) external returns (uint256);

    function sendL1FundedUnsignedTransaction(
        uint256 gasLimit,
        uint256 maxFeePerGas,
        uint256 nonce,
        address to,
        bytes calldata data
    ) external payable returns (uint256);

    function sendL1FundedContractTransaction(
        uint256 gasLimit,
        uint256 maxFeePerGas,
        address to,
        bytes calldata data
    ) external payable returns (uint256);

    function sendUnsignedTransaction(
        uint256 gasLimit,
        uint256 maxFeePerGas,
        uint256 nonce,
        address to,
        uint256 value,
        bytes calldata data
    ) external returns (uint256);

    function sendContractTransaction(
        uint256 gasLimit,
        uint256 maxFeePerGas,
        address to,
        uint256 value,
        bytes calldata data
    ) external returns (uint256);

    /**
     * @dev This method can only be called upon L1 fork and will not alias the caller
     *      This method will revert if not called from origin
     */
    function sendL1FundedUnsignedTransactionToFork(
        uint256 gasLimit,
        uint256 maxFeePerGas,
        uint256 nonce,
        address to,
        bytes calldata data
    ) external payable returns (uint256);

    /**
     * @dev This method can only be called upon L1 fork and will not alias the caller
     *      This method will revert if not called from origin
     */
    function sendUnsignedTransactionToFork(
        uint256 gasLimit,
        uint256 maxFeePerGas,
        uint256 nonce,
        address to,
        uint256 value,
        bytes calldata data
    ) external returns (uint256);

    /**
     * @notice Send a message to initiate L2 withdrawal
     * @dev This method can only be called upon L1 fork and will not alias the caller
     *      This method will revert if not called from origin
     */
    function sendWithdrawEthToFork(
        uint256 gasLimit,
        uint256 maxFeePerGas,
        uint256 nonce,
        uint256 value,
        address withdrawTo
    ) external returns (uint256);

    /**
     * @notice Get the L1 fee for submitting a retryable
     * @dev This fee can be paid by funds already in the L2 aliased address or by the current message value
     * @dev This formula may change in the future, to future proof your code query this method instead of inlining!!
     * @param dataLength The length of the retryable's calldata, in bytes
     * @param baseFee The block basefee when the retryable is included in the chain, if 0 current block.basefee will be used
     */
    function calculateRetryableSubmissionFee(uint256 dataLength, uint256 baseFee)
        external
        view
        returns (uint256);

    /**
     * @notice Deposit eth from L1 to L2 to address of the sender if sender is an EOA, and to its aliased address if the sender is a contract
     * @dev This does not trigger the fallback function when receiving in the L2 side.
     *      Look into retryable tickets if you are interested in this functionality.
     * @dev This function should not be called inside contract constructors
     */
    function depositEth() external payable returns (uint256);

    /**
     * @notice Put a message in the L2 inbox that can be reexecuted for some fixed amount of time if it reverts
     * @dev all msg.value will deposited to callValueRefundAddress on L2
     * @dev Gas limit and maxFeePerGas should not be set to 1 as that is used to trigger the RetryableData error
     * @param to destination L2 contract address
     * @param l2CallValue call value for retryable L2 message
     * @param maxSubmissionCost Max gas deducted from user's L2 balance to cover base submission fee
     * @param excessFeeRefundAddress gasLimit x maxFeePerGas - execution cost gets credited here on L2 balance
     * @param callValueRefundAddress l2Callvalue gets credited here on L2 if retryable txn times out or gets cancelled
     * @param gasLimit Max gas deducted from user's L2 balance to cover L2 execution. Should not be set to 1 (magic value used to trigger the RetryableData error)
     * @param maxFeePerGas price bid for L2 execution. Should not be set to 1 (magic value used to trigger the RetryableData error)
     * @param data ABI encoded data of L2 message
     * @return unique message number of the retryable transaction
     */
    function createRetryableTicket(
        address to,
        uint256 l2CallValue,
        uint256 maxSubmissionCost,
        address excessFeeRefundAddress,
        address callValueRefundAddress,
        uint256 gasLimit,
        uint256 maxFeePerGas,
        bytes calldata data
    ) external payable returns (uint256);

    /**
     * @notice Put a message in the L2 inbox that can be reexecuted for some fixed amount of time if it reverts
     * @dev Same as createRetryableTicket, but does not guarantee that submission will succeed by requiring the needed funds
     * come from the deposit alone, rather than falling back on the user's L2 balance
     * @dev Advanced usage only (does not rewrite aliases for excessFeeRefundAddress and callValueRefundAddress).
     * createRetryableTicket method is the recommended standard.
     * @dev Gas limit and maxFeePerGas should not be set to 1 as that is used to trigger the RetryableData error
     * @param to destination L2 contract address
     * @param l2CallValue call value for retryable L2 message
     * @param maxSubmissionCost Max gas deducted from user's L2 balance to cover base submission fee
     * @param excessFeeRefundAddress gasLimit x maxFeePerGas - execution cost gets credited here on L2 balance
     * @param callValueRefundAddress l2Callvalue gets credited here on L2 if retryable txn times out or gets cancelled
     * @param gasLimit Max gas deducted from user's L2 balance to cover L2 execution. Should not be set to 1 (magic value used to trigger the RetryableData error)
     * @param maxFeePerGas price bid for L2 execution. Should not be set to 1 (magic value used to trigger the RetryableData error)
     * @param data ABI encoded data of L2 message
     * @return unique message number of the retryable transaction
     */
    function unsafeCreateRetryableTicket(
        address to,
        uint256 l2CallValue,
        uint256 maxSubmissionCost,
        address excessFeeRefundAddress,
        address callValueRefundAddress,
        uint256 gasLimit,
        uint256 maxFeePerGas,
        bytes calldata data
    ) external payable returns (uint256);

    // ---------- onlyRollupOrOwner functions ----------

    /// @notice pauses all inbox functionality
    function pause() external;

    /// @notice unpauses all inbox functionality
    function unpause() external;

    // ---------- initializer ----------

    /**
     * @dev function to be called one time during the inbox upgrade process
     *      this is used to fix the storage slots
     */
    function postUpgradeInit(IBridge _bridge) external;

    function initialize(IBridge _bridge, ISequencerInbox _sequencerInbox) external;
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

// solhint-disable-next-line compiler-version
pragma solidity >=0.6.9 <0.9.0;

import "./IBridge.sol";

interface IOutbox {
    event SendRootUpdated(bytes32 indexed outputRoot, bytes32 indexed l2BlockHash);
    event OutBoxTransactionExecuted(
        address indexed to,
        address indexed l2Sender,
        uint256 indexed zero,
        uint256 transactionIndex
    );

    function rollup() external view returns (address); // the rollup contract

    function bridge() external view returns (IBridge); // the bridge contract

    function spent(uint256) external view returns (bytes32); // packed spent bitmap

    function roots(bytes32) external view returns (bytes32); // maps root hashes => L2 block hash

    // solhint-disable-next-line func-name-mixedcase
    function OUTBOX_VERSION() external view returns (uint128); // the outbox version

    function updateSendRoot(bytes32 sendRoot, bytes32 l2BlockHash) external;

    /// @notice When l2ToL1Sender returns a nonzero address, the message was originated by an L2 account
    ///         When the return value is zero, that means this is a system message
    /// @dev the l2ToL1Sender behaves as the tx.origin, the msg.sender should be validated to protect against reentrancies
    function l2ToL1Sender() external view returns (address);

    /// @return l2Block return L2 block when the L2 tx was initiated or 0 if no L2 to L1 transaction is active
    function l2ToL1Block() external view returns (uint256);

    /// @return l1Block return L1 block when the L2 tx was initiated or 0 if no L2 to L1 transaction is active
    function l2ToL1EthBlock() external view returns (uint256);

    /// @return timestamp return L2 timestamp when the L2 tx was initiated or 0 if no L2 to L1 transaction is active
    function l2ToL1Timestamp() external view returns (uint256);

    /// @return outputId returns the unique output identifier of the L2 to L1 tx or 0 if no L2 to L1 transaction is active
    function l2ToL1OutputId() external view returns (bytes32);

    /**
     * @notice Executes a messages in an Outbox entry.
     * @dev Reverts if dispute period hasn't expired, since the outbox entry
     *      is only created once the rollup confirms the respective assertion.
     * @dev it is not possible to execute any L2-to-L1 transaction which contains data
     *      to a contract address without any code (as enforced by the Bridge contract).
     * @param proof Merkle proof of message inclusion in send root
     * @param index Merkle path to message
     * @param l2Sender sender if original message (i.e., caller of ArbSys.sendTxToL1)
     * @param to destination address for L1 contract call
     * @param l2Block l2 block number at which sendTxToL1 call was made
     * @param l1Block l1 block number at which sendTxToL1 call was made
     * @param l2Timestamp l2 Timestamp at which sendTxToL1 call was made
     * @param value wei in L1 message
     * @param data abi-encoded L1 message data
     */
    function executeTransaction(
        bytes32[] calldata proof,
        uint256 index,
        address l2Sender,
        address to,
        uint256 l2Block,
        uint256 l1Block,
        uint256 l2Timestamp,
        uint256 value,
        bytes calldata data
    ) external;

    /**
     *  @dev function used to simulate the result of a particular function call from the outbox
     *       it is useful for things such as gas estimates. This function includes all costs except for
     *       proof validation (which can be considered offchain as a somewhat of a fixed cost - it's
     *       not really a fixed cost, but can be treated as so with a fixed overhead for gas estimation).
     *       We can't include the cost of proof validation since this is intended to be used to simulate txs
     *       that are included in yet-to-be confirmed merkle roots. The simulation entrypoint could instead pretend
     *       to confirm a pending merkle root, but that would be less practical for integrating with tooling.
     *       It is only possible to trigger it when the msg sender is address zero, which should be impossible
     *       unless under simulation in an eth_call or eth_estimateGas
     */
    function executeTransactionSimulation(
        uint256 index,
        address l2Sender,
        address to,
        uint256 l2Block,
        uint256 l1Block,
        uint256 l2Timestamp,
        uint256 value,
        bytes calldata data
    ) external;

    /**
     * @param index Merkle path to message
     * @return true if the message has been spent
     */
    function isSpent(uint256 index) external view returns (bool);

    function calculateItemHash(
        address l2Sender,
        address to,
        uint256 l2Block,
        uint256 l1Block,
        uint256 l2Timestamp,
        uint256 value,
        bytes calldata data
    ) external pure returns (bytes32);

    function calculateMerkleRoot(
        bytes32[] memory proof,
        uint256 path,
        bytes32 item
    ) external pure returns (bytes32);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// solhint-disable-next-line compiler-version
pragma solidity >0.6.0 <0.9.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface ITransferAndCall is IERC20Upgradeable {
    function transferAndCall(
        address to,
        uint256 value,
        bytes memory data
    ) external returns (bool success);

    event Transfer(address indexed from, address indexed to, uint256 value, bytes data);
}

/**
 * @notice note that implementation of ITransferAndCallReceiver is not expected to return a success bool
 */
interface ITransferAndCallReceiver {
    function onTokenTransfer(
        address _sender,
        uint256 _value,
        bytes memory _data
    ) external;
}

// SPDX-License-Identifier: Apache-2.0

/*
 * Copyright 2020, Offchain Labs, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Create2.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "../L1ArbitrumMessenger.sol";
import "./IL1ArbitrumGateway.sol";
import "../../libraries/ProxyUtil.sol";
import "../../libraries/gateway/GatewayMessageHandler.sol";
import "../../libraries/gateway/TokenGateway.sol";
import "../../libraries/ITransferAndCall.sol";
import "../../libraries/ERC165.sol";

/**
 * @title Common interface for gatways on L1 messaging to Arbitrum.
 */
abstract contract L1ArbitrumGateway is
    L1ArbitrumMessenger,
    TokenGateway,
    ERC165,
    IL1ArbitrumGateway
{
    using SafeERC20 for IERC20;
    using Address for address;

    address public override inbox;

    event DepositInitiated(
        address l1Token,
        address indexed _from,
        address indexed _to,
        uint256 indexed _sequenceNumber,
        uint256 _amount
    );

    event WithdrawalFinalized(
        address l1Token,
        address indexed _from,
        address indexed _to,
        uint256 indexed _exitNum,
        uint256 _amount
    );

    modifier onlyCounterpartGateway() override {
        address _inbox = inbox;

        // a message coming from the counterpart gateway was executed by the bridge
        address bridge = address(super.getBridge(_inbox));
        require(msg.sender == bridge, "NOT_FROM_BRIDGE");

        // and the outbox reports that the L2 address of the sender is the counterpart gateway
        address l2ToL1Sender = super.getL2ToL1Sender(_inbox);
        require(l2ToL1Sender == counterpartGateway, "ONLY_COUNTERPART_GATEWAY");
        _;
    }

    function postUpgradeInit() external {
        // it is assumed the L1 Arbitrum Gateway contract is behind a Proxy controlled by a proxy admin
        // this function can only be called by the proxy admin contract
        address proxyAdmin = ProxyUtil.getProxyAdmin();
        require(msg.sender == proxyAdmin, "NOT_FROM_ADMIN");
        // this has no other logic since the current upgrade doesn't require this logic
    }

    function _initialize(
        address _l2Counterpart,
        address _router,
        address _inbox
    ) internal {
        TokenGateway._initialize(_l2Counterpart, _router);
        // L1 gateway must have a router
        require(_router != address(0), "BAD_ROUTER");
        require(_inbox != address(0), "BAD_INBOX");
        inbox = _inbox;
    }

    /**
     * @notice Finalizes a withdrawal via Outbox message; callable only by L2Gateway.outboundTransfer
     * @param _token L1 address of token being withdrawn from
     * @param _from initiator of withdrawal
     * @param _to address the L2 withdrawal call set as the destination.
     * @param _amount Token amount being withdrawn
     * @param _data encoded exitNum (Sequentially increasing exit counter determined by the L2Gateway) and additinal hook data
     */
    function finalizeInboundTransfer(
        address _token,
        address _from,
        address _to,
        uint256 _amount,
        bytes calldata _data
    ) public payable virtual override onlyCounterpartGateway {
        // this function is marked as virtual so superclasses can override it to add modifiers
        (uint256 exitNum, bytes memory callHookData) = GatewayMessageHandler.parseToL1GatewayMsg(
            _data
        );

        if (callHookData.length != 0) {
            // callHookData should always be 0 since inboundEscrowAndCall is disabled
            callHookData = bytes("");
        }

        // we ignore the returned data since the callHook feature is now disabled
        (_to, ) = getExternalCall(exitNum, _to, callHookData);
        inboundEscrowTransfer(_token, _to, _amount);

        emit WithdrawalFinalized(_token, _from, _to, exitNum, _amount);
    }

    function getExternalCall(
        uint256, /* _exitNum */
        address _initialDestination,
        bytes memory _initialData
    ) public view virtual returns (address target, bytes memory data) {
        // this method is virtual so the destination of a call can be changed
        // using tradeable exits in a subclass (L1ArbitrumExtendedGateway)
        target = _initialDestination;
        data = _initialData;
    }

    function inboundEscrowTransfer(
        address _l1Token,
        address _dest,
        uint256 _amount
    ) internal virtual {
        // this method is virtual since different subclasses can handle escrow differently
        IERC20(_l1Token).safeTransfer(_dest, _amount);
    }

    /**
     * @dev Only excess gas is refunded to the _refundTo account, l2 call value is always returned to the _to account
     */
    function createOutboundTxCustomRefund(
        address _refundTo,
        address _from,
        uint256, /* _tokenAmount */
        uint256 _maxGas,
        uint256 _gasPriceBid,
        uint256 _maxSubmissionCost,
        bytes memory _outboundCalldata
    ) internal virtual returns (uint256) {
        // We make this function virtual since outboundTransfer logic is the same for many gateways
        // but sometimes (ie weth) you construct the outgoing message differently.

        // msg.value is sent, but 0 is set to the L2 call value
        // the eth sent is used to pay for the tx's gas
        return
            sendTxToL2CustomRefund(
                inbox,
                counterpartGateway,
                _refundTo,
                _from,
                msg.value, // we forward the L1 call value to the inbox
                0, // l2 call value 0 by default
                L2GasParams({
                    _maxSubmissionCost: _maxSubmissionCost,
                    _maxGas: _maxGas,
                    _gasPriceBid: _gasPriceBid
                }),
                _outboundCalldata
            );
    }

    /**
     * @notice DEPRECATED - look at createOutboundTxCustomRefund instead
     */
    function createOutboundTx(
        address _from,
        uint256 _tokenAmount,
        uint256 _maxGas,
        uint256 _gasPriceBid,
        uint256 _maxSubmissionCost,
        bytes memory _outboundCalldata
    ) internal returns (uint256) {
        return
            createOutboundTxCustomRefund(
                _from,
                _from,
                _tokenAmount,
                _maxGas,
                _gasPriceBid,
                _maxSubmissionCost,
                _outboundCalldata
            );
    }

    /**
     * @notice DEPRECATED - look at outboundTransferCustomRefund instead
     */
    function outboundTransfer(
        address _l1Token,
        address _to,
        uint256 _amount,
        uint256 _maxGas,
        uint256 _gasPriceBid,
        bytes calldata _data
    ) public payable override returns (bytes memory res) {
        return
            outboundTransferCustomRefund(_l1Token, _to, _to, _amount, _maxGas, _gasPriceBid, _data);
    }

    /**
     * @notice Deposit ERC20 token from Ethereum into Arbitrum. If L2 side hasn't been deployed yet, includes name/symbol/decimals data for initial L2 deploy. Initiate by GatewayRouter.
     * @dev L2 address alias will not be applied to the following types of addresses on L1:
     *      - an externally-owned account
     *      - a contract in construction
     *      - an address where a contract will be created
     *      - an address where a contract lived, but was destroyed
     * @param _l1Token L1 address of ERC20
     * @param _refundTo Account, or its L2 alias if it have code in L1, to be credited with excess gas refund in L2
     * @param _to Account to be credited with the tokens in the L2 (can be the user's L2 account or a contract), not subject to L2 aliasing
                  This account, or its L2 alias if it have code in L1, will also be able to cancel the retryable ticket and receive callvalue refund
     * @param _amount Token Amount
     * @param _maxGas Max gas deducted from user's L2 balance to cover L2 execution
     * @param _gasPriceBid Gas price for L2 execution
     * @param _data encoded data from router and user
     * @return res abi encoded inbox sequence number
     */
    //  * @param maxSubmissionCost Max gas deducted from user's L2 balance to cover base submission fee
    function outboundTransferCustomRefund(
        address _l1Token,
        address _refundTo,
        address _to,
        uint256 _amount,
        uint256 _maxGas,
        uint256 _gasPriceBid,
        bytes calldata _data
    ) public payable virtual override returns (bytes memory res) {
        require(isRouter(msg.sender), "NOT_FROM_ROUTER");
        // This function is set as public and virtual so that subclasses can override
        // it and add custom validation for callers (ie only whitelisted users)
        address _from;
        uint256 seqNum;
        bytes memory extraData;
        {
            uint256 _maxSubmissionCost;
            uint256 tokenTotalFeeAmount;
            if (super.isRouter(msg.sender)) {
                // router encoded
                (_from, extraData) = GatewayMessageHandler.parseFromRouterToGateway(_data);
            } else {
                _from = msg.sender;
                extraData = _data;
            }
            // unpack user encoded data
            (_maxSubmissionCost, extraData, tokenTotalFeeAmount) = _parseUserEncodedData(extraData);

            // the inboundEscrowAndCall functionality has been disabled, so no data is allowed
            require(extraData.length == 0, "EXTRA_DATA_DISABLED");

            require(_l1Token.isContract(), "L1_NOT_CONTRACT");
            address l2Token = calculateL2TokenAddress(_l1Token);
            require(l2Token != address(0), "NO_L2_TOKEN_SET");

            _amount = outboundEscrowTransfer(_l1Token, _from, _amount);

            // we override the res field to save on the stack
            res = getOutboundCalldata(_l1Token, _from, _to, _amount, extraData);

            seqNum = _initiateDeposit(
                _refundTo,
                _from,
                _amount,
                _maxGas,
                _gasPriceBid,
                _maxSubmissionCost,
                tokenTotalFeeAmount,
                res
            );
        }
        emit DepositInitiated(_l1Token, _from, _to, seqNum, _amount);
        return abi.encode(seqNum);
    }

    function outboundEscrowTransfer(
        address _l1Token,
        address _from,
        uint256 _amount
    ) internal virtual returns (uint256 amountReceived) {
        // this method is virtual since different subclasses can handle escrow differently
        // user funds are escrowed on the gateway using this function
        uint256 prevBalance = IERC20(_l1Token).balanceOf(address(this));
        IERC20(_l1Token).safeTransferFrom(_from, address(this), _amount);
        uint256 postBalance = IERC20(_l1Token).balanceOf(address(this));
        return postBalance - prevBalance;
    }

    function getOutboundCalldata(
        address _l1Token,
        address _from,
        address _to,
        uint256 _amount,
        bytes memory _data
    ) public view virtual override returns (bytes memory outboundCalldata) {
        // this function is public so users can query how much calldata will be sent to the L2
        // before execution
        // it is virtual since different gateway subclasses can build this calldata differently
        // ( ie the standard ERC20 gateway queries for a tokens name/symbol/decimals )
        bytes memory emptyBytes = "";

        outboundCalldata = abi.encodeWithSelector(
            ITokenGateway.finalizeInboundTransfer.selector,
            _l1Token,
            _from,
            _to,
            _amount,
            GatewayMessageHandler.encodeToL2GatewayMsg(emptyBytes, _data)
        );

        return outboundCalldata;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165, IERC165)
        returns (bool)
    {
        // registering interfaces that is added after arb-bridge-peripherals >1.0.11
        // using function selector instead of single function interfaces to reduce bloat
        return
            interfaceId == this.outboundTransferCustomRefund.selector ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @notice Parse data that was encoded by user and passed into the outbound TX entrypoint
     * @dev In case of standard ETH-based rollup, format of encoded data is expected to be:
     *      - maxSubmissionCost (uint256)
     *      - callHookData (bytes)
     *      In case of ERC20-based rollup, format of encoded data is expected to be:
     *      - maxSubmissionCost (uint256)
     *      - tokenTotalFeeAmount (uint256)
     *      - callHookData (bytes)
     * @param data data encoded by user
     * @return maxSubmissionCost Max gas deducted from user's L2 balance to cover base submission fee
     * @return callHookData Calldata for extra call in inboundEscrowAndCall on L2
     * @return tokenTotalFeeAmount Amount of fees to be deposited in native token to cover for retryable ticket cost (used only in ERC20-based rollups, otherwise 0)
     */
    function _parseUserEncodedData(bytes memory data)
        internal
        pure
        virtual
        returns (
            uint256 maxSubmissionCost,
            bytes memory callHookData,
            uint256 tokenTotalFeeAmount
        )
    {
        (maxSubmissionCost, callHookData) = abi.decode(data, (uint256, bytes));
    }

    /**
     * @notice Intermediate internal function that passes on parameters needed to trigger creation of retryable ticket.
     * @param _refundTo Account, or its L2 alias if it have code in L1, to be credited with excess gas refund in L2
     * @param _from Initiator of deposit
     * @param _amount Token amount being deposited
     * @param _maxGas Max gas deducted from user's L2 balance to cover L2 execution
     * @param _gasPriceBid Gas price for L2 execution
     * @param _maxSubmissionCost Max gas deducted from user's L2 balance to cover base submission fee
     * @param _data encoded data from router and user
     * @return res abi encoded inbox sequence number
     */
    function _initiateDeposit(
        address _refundTo,
        address _from,
        uint256 _amount,
        uint256 _maxGas,
        uint256 _gasPriceBid,
        uint256 _maxSubmissionCost,
        uint256, // tokenTotalFeeAmount - amount of fees to be deposited in native token to cover for retryable ticket cost (used only in ERC20-based rollups)
        bytes memory _data
    ) internal virtual returns (uint256) {
        return
            createOutboundTxCustomRefund(
                _refundTo,
                _from,
                _amount,
                _maxGas,
                _gasPriceBid,
                _maxSubmissionCost,
                _data
            );
    }
}

// SPDX-License-Identifier: Apache-2.0

/*
 * Copyright 2020, Offchain Labs, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";
import "../../libraries/AddressAliasHelper.sol";
import "../../libraries/BytesLib.sol";
import "../../libraries/ProxyUtil.sol";

import "../IArbToken.sol";

import "../L2ArbitrumMessenger.sol";
import "../../libraries/gateway/GatewayMessageHandler.sol";
import "../../libraries/gateway/TokenGateway.sol";

/**
 * @title Common interface for gatways on Arbitrum messaging to L1.
 */
abstract contract L2ArbitrumGateway is L2ArbitrumMessenger, TokenGateway {
    using Address for address;

    uint256 public exitNum;

    event DepositFinalized(
        address indexed l1Token,
        address indexed _from,
        address indexed _to,
        uint256 _amount
    );

    event WithdrawalInitiated(
        address l1Token,
        address indexed _from,
        address indexed _to,
        uint256 indexed _l2ToL1Id,
        uint256 _exitNum,
        uint256 _amount
    );

    modifier onlyCounterpartGateway() override {
        require(
            msg.sender == AddressAliasHelper.applyL1ToL2Alias(counterpartGateway),
            "ONLY_COUNTERPART_GATEWAY"
        );
        _;
    }

    function postUpgradeInit() external {
        // it is assumed the L2 Arbitrum Gateway contract is behind a Proxy controlled by a proxy admin
        // this function can only be called by the proxy admin contract
        address proxyAdmin = ProxyUtil.getProxyAdmin();
        require(msg.sender == proxyAdmin, "NOT_FROM_ADMIN");
        // this has no other logic since the current upgrade doesn't require this logic
    }

    function _initialize(address _l1Counterpart, address _router) internal override {
        TokenGateway._initialize(_l1Counterpart, _router);
        // L1 gateway must have a router
        require(_router != address(0), "BAD_ROUTER");
    }

    function createOutboundTx(
        address _from,
        uint256, /* _tokenAmount */
        bytes memory _outboundCalldata
    ) internal virtual returns (uint256) {
        // We make this function virtual since outboundTransfer logic is the same for many gateways
        // but sometimes (ie weth) you construct the outgoing message differently.

        // exitNum incremented after being included in _outboundCalldata
        exitNum++;
        return
            sendTxToL1(
                // default to sending no callvalue to the L1
                0,
                _from,
                counterpartGateway,
                _outboundCalldata
            );
    }

    function getOutboundCalldata(
        address _token,
        address _from,
        address _to,
        uint256 _amount,
        bytes memory _data
    ) public view override returns (bytes memory outboundCalldata) {
        outboundCalldata = abi.encodeWithSelector(
            ITokenGateway.finalizeInboundTransfer.selector,
            _token,
            _from,
            _to,
            _amount,
            GatewayMessageHandler.encodeFromL2GatewayMsg(exitNum, _data)
        );

        return outboundCalldata;
    }

    function outboundTransfer(
        address _l1Token,
        address _to,
        uint256 _amount,
        bytes calldata _data
    ) public payable returns (bytes memory) {
        return outboundTransfer(_l1Token, _to, _amount, 0, 0, _data);
    }

    /**
     * @notice Initiates a token withdrawal from Arbitrum to Ethereum
     * @param _l1Token l1 address of token
     * @param _to destination address
     * @param _amount amount of tokens withdrawn
     * @return res encoded unique identifier for withdrawal
     */
    function outboundTransfer(
        address _l1Token,
        address _to,
        uint256 _amount,
        uint256, /* _maxGas */
        uint256, /* _gasPriceBid */
        bytes calldata _data
    ) public payable override returns (bytes memory res) {
        // This function is set as public and virtual so that subclasses can override
        // it and add custom validation for callers (ie only whitelisted users)

        // the function is marked as payable to conform to the inheritance setup
        // this particular code path shouldn't have a msg.value > 0
        // TODO: remove this invariant for execution markets
        require(msg.value == 0, "NO_VALUE");

        address _from;
        bytes memory _extraData;
        {
            if (isRouter(msg.sender)) {
                (_from, _extraData) = GatewayMessageHandler.parseFromRouterToGateway(_data);
            } else {
                _from = msg.sender;
                _extraData = _data;
            }
        }
        // the inboundEscrowAndCall functionality has been disabled, so no data is allowed
        require(_extraData.length == 0, "EXTRA_DATA_DISABLED");

        uint256 id;
        {
            address l2Token = calculateL2TokenAddress(_l1Token);
            require(l2Token.isContract(), "TOKEN_NOT_DEPLOYED");
            require(IArbToken(l2Token).l1Address() == _l1Token, "NOT_EXPECTED_L1_TOKEN");

            _amount = outboundEscrowTransfer(l2Token, _from, _amount);
            id = triggerWithdrawal(_l1Token, _from, _to, _amount, _extraData);
        }
        return abi.encode(id);
    }

    function triggerWithdrawal(
        address _l1Token,
        address _from,
        address _to,
        uint256 _amount,
        bytes memory _data
    ) internal returns (uint256) {
        // exit number used for tradeable exits
        uint256 currExitNum = exitNum;
        // unique id used to identify the L2 to L1 tx
        uint256 id = createOutboundTx(
            _from,
            _amount,
            getOutboundCalldata(_l1Token, _from, _to, _amount, _data)
        );
        emit WithdrawalInitiated(_l1Token, _from, _to, id, currExitNum, _amount);
        return id;
    }

    function outboundEscrowTransfer(
        address _l2Token,
        address _from,
        uint256 _amount
    ) internal virtual returns (uint256 amountBurnt) {
        // this method is virtual since different subclasses can handle escrow differently
        // user funds are escrowed on the gateway using this function
        // burns L2 tokens in order to release escrowed L1 tokens
        IArbToken(_l2Token).bridgeBurn(_from, _amount);
        // by default we assume that the amount we send to bridgeBurn is the amount burnt
        // this might not be the case for every token
        return _amount;
    }

    function inboundEscrowTransfer(
        address _l2Address,
        address _dest,
        uint256 _amount
    ) internal virtual {
        // this method is virtual since different subclasses can handle escrow differently
        IArbToken(_l2Address).bridgeMint(_dest, _amount);
    }

    /**
     * @notice Mint on L2 upon L1 deposit.
     * If token not yet deployed and symbol/name/decimal data is included, deploys StandardArbERC20
     * @dev Callable only by the L1ERC20Gateway.outboundTransfer method. For initial deployments of a token the L1 L1ERC20Gateway
     * is expected to include the deployData. If not a L1 withdrawal is automatically triggered for the user
     * @param _token L1 address of ERC20
     * @param _from account that initiated the deposit in the L1
     * @param _to account to be credited with the tokens in the L2 (can be the user's L2 account or a contract)
     * @param _amount token amount to be minted to the user
     * @param _data encoded symbol/name/decimal data for deploy, in addition to any additional callhook data
     */
    function finalizeInboundTransfer(
        address _token,
        address _from,
        address _to,
        uint256 _amount,
        bytes calldata _data
    ) external payable override onlyCounterpartGateway {
        (bytes memory gatewayData, bytes memory callHookData) = GatewayMessageHandler
            .parseFromL1GatewayMsg(_data);

        if (callHookData.length != 0) {
            // callHookData should always be 0 since inboundEscrowAndCall is disabled
            callHookData = bytes("");
        }

        address expectedAddress = calculateL2TokenAddress(_token);

        if (!expectedAddress.isContract()) {
            bool shouldHalt = handleNoContract(
                _token,
                expectedAddress,
                _from,
                _to,
                _amount,
                gatewayData
            );
            if (shouldHalt) return;
        }
        // ignores gatewayData if token already deployed

        {
            // validate if L1 address supplied matches that of the expected L2 address
            (bool success, bytes memory _l1AddressData) = expectedAddress.staticcall(
                abi.encodeWithSelector(IArbToken.l1Address.selector)
            );

            bool shouldWithdraw;
            if (!success || _l1AddressData.length < 32) {
                shouldWithdraw = true;
            } else {
                // we do this in the else branch since we want to avoid reverts
                // and `toAddress` reverts if _l1AddressData has a short length
                // `_l1AddressData` should be 12 bytes of padding then 20 bytes for the address
                address expectedL1Address = BytesLib.toAddress(_l1AddressData, 12);
                if (expectedL1Address != _token) {
                    shouldWithdraw = true;
                }
            }

            if (shouldWithdraw) {
                // we don't need the return value from triggerWithdrawal since this is forcing
                // a withdrawal back to the L1 instead of composing with a L2 dapp
                triggerWithdrawal(_token, address(this), _from, _amount, "");
                return;
            }
        }

        inboundEscrowTransfer(expectedAddress, _to, _amount);
        emit DepositFinalized(_token, _from, _to, _amount);

        return;
    }

    // returns if function should halt after
    function handleNoContract(
        address _l1Token,
        address expectedL2Address,
        address _from,
        address _to,
        uint256 _amount,
        bytes memory gatewayData
    ) internal virtual returns (bool shouldHalt);
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

// solhint-disable-next-line compiler-version
pragma solidity >=0.6.9 <0.9.0;

import "./IOwnable.sol";

interface IBridge {
    event MessageDelivered(
        uint256 indexed messageIndex,
        bytes32 indexed beforeInboxAcc,
        address inbox,
        uint8 kind,
        address sender,
        bytes32 messageDataHash,
        uint256 baseFeeL1,
        uint64 timestamp
    );

    event BridgeCallTriggered(
        address indexed outbox,
        address indexed to,
        uint256 value,
        bytes data
    );

    event InboxToggle(address indexed inbox, bool enabled);

    event OutboxToggle(address indexed outbox, bool enabled);

    event SequencerInboxUpdated(address newSequencerInbox);

    function allowedDelayedInboxList(uint256) external returns (address);

    function allowedOutboxList(uint256) external returns (address);

    /// @dev Accumulator for delayed inbox messages; tail represents hash of the current state; each element represents the inclusion of a new message.
    function delayedInboxAccs(uint256) external view returns (bytes32);

    /// @dev Accumulator for sequencer inbox messages; tail represents hash of the current state; each element represents the inclusion of a new message.
    function sequencerInboxAccs(uint256) external view returns (bytes32);

    function rollup() external view returns (IOwnable);

    function sequencerInbox() external view returns (address);

    function activeOutbox() external view returns (address);

    function allowedDelayedInboxes(address inbox) external view returns (bool);

    function allowedOutboxes(address outbox) external view returns (bool);

    function sequencerReportedSubMessageCount() external view returns (uint256);

    /**
     * @dev Enqueue a message in the delayed inbox accumulator.
     *      These messages are later sequenced in the SequencerInbox, either
     *      by the sequencer as part of a normal batch, or by force inclusion.
     */
    function enqueueDelayedMessage(
        uint8 kind,
        address sender,
        bytes32 messageDataHash
    ) external payable returns (uint256);

    function executeCall(
        address to,
        uint256 value,
        bytes calldata data
    ) external returns (bool success, bytes memory returnData);

    function delayedMessageCount() external view returns (uint256);

    function sequencerMessageCount() external view returns (uint256);

    // ---------- onlySequencerInbox functions ----------

    function enqueueSequencerMessage(
        bytes32 dataHash,
        uint256 afterDelayedMessagesRead,
        uint256 prevMessageCount,
        uint256 newMessageCount
    )
        external
        returns (
            uint256 seqMessageIndex,
            bytes32 beforeAcc,
            bytes32 delayedAcc,
            bytes32 acc
        );

    /**
     * @dev Allows the sequencer inbox to submit a delayed message of the batchPostingReport type
     *      This is done through a separate function entrypoint instead of allowing the sequencer inbox
     *      to call `enqueueDelayedMessage` to avoid the gas overhead of an extra SLOAD in either
     *      every delayed inbox or every sequencer inbox call.
     */
    function submitBatchSpendingReport(address batchPoster, bytes32 dataHash)
        external
        returns (uint256 msgNum);

    // ---------- onlyRollupOrOwner functions ----------

    function setSequencerInbox(address _sequencerInbox) external;

    function setDelayedInbox(address inbox, bool enabled) external;

    function setOutbox(address inbox, bool enabled) external;

    // ---------- initializer ----------

    function initialize(IOwnable rollup_) external;
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

// solhint-disable-next-line compiler-version
pragma solidity >=0.6.9 <0.9.0;

interface IDelayedMessageProvider {
    /// @dev event emitted when a inbox message is added to the Bridge's delayed accumulator
    event InboxMessageDelivered(uint256 indexed messageNum, bytes data);

    /// @dev event emitted when a inbox message is added to the Bridge's delayed accumulator
    /// same as InboxMessageDelivered but the batch data is available in tx.input
    event InboxMessageDeliveredFromOrigin(uint256 indexed messageNum);
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

// solhint-disable-next-line compiler-version
pragma solidity >=0.6.9 <0.9.0;
pragma experimental ABIEncoderV2;

import "../libraries/IGasRefunder.sol";
import "./IDelayedMessageProvider.sol";
import "./IBridge.sol";

interface ISequencerInbox is IDelayedMessageProvider {
    struct MaxTimeVariation {
        uint256 delayBlocks;
        uint256 futureBlocks;
        uint256 delaySeconds;
        uint256 futureSeconds;
    }

    struct TimeBounds {
        uint64 minTimestamp;
        uint64 maxTimestamp;
        uint64 minBlockNumber;
        uint64 maxBlockNumber;
    }

    enum BatchDataLocation {
        TxInput,
        SeparateBatchEvent,
        NoData
    }

    event SequencerBatchDelivered(
        uint256 indexed batchSequenceNumber,
        bytes32 indexed beforeAcc,
        bytes32 indexed afterAcc,
        bytes32 delayedAcc,
        uint256 afterDelayedMessagesRead,
        TimeBounds timeBounds,
        BatchDataLocation dataLocation
    );

    event OwnerFunctionCalled(uint256 indexed id);

    /// @dev a separate event that emits batch data when this isn't easily accessible in the tx.input
    event SequencerBatchData(uint256 indexed batchSequenceNumber, bytes data);

    /// @dev a valid keyset was added
    event SetValidKeyset(bytes32 indexed keysetHash, bytes keysetBytes);

    /// @dev a keyset was invalidated
    event InvalidateKeyset(bytes32 indexed keysetHash);

    function totalDelayedMessagesRead() external view returns (uint256);

    function bridge() external view returns (IBridge);

    /// @dev The size of the batch header
    // solhint-disable-next-line func-name-mixedcase
    function HEADER_LENGTH() external view returns (uint256);

    /// @dev If the first batch data byte after the header has this bit set,
    ///      the sequencer inbox has authenticated the data. Currently not used.
    // solhint-disable-next-line func-name-mixedcase
    function DATA_AUTHENTICATED_FLAG() external view returns (bytes1);

    function rollup() external view returns (IOwnable);

    function isBatchPoster(address) external view returns (bool);

    struct DasKeySetInfo {
        bool isValidKeyset;
        uint64 creationBlock;
    }

    // https://github.com/ethereum/solidity/issues/11826
    // function maxTimeVariation() external view returns (MaxTimeVariation calldata);
    // function dasKeySetInfo(bytes32) external view returns (DasKeySetInfo calldata);

    /// @notice Remove force inclusion delay after a L1 chainId fork
    function removeDelayAfterFork() external;

    /// @notice Force messages from the delayed inbox to be included in the chain
    ///         Callable by any address, but message can only be force-included after maxTimeVariation.delayBlocks and
    ///         maxTimeVariation.delaySeconds has elapsed. As part of normal behaviour the sequencer will include these
    ///         messages so it's only necessary to call this if the sequencer is down, or not including any delayed messages.
    /// @param _totalDelayedMessagesRead The total number of messages to read up to
    /// @param kind The kind of the last message to be included
    /// @param l1BlockAndTime The l1 block and the l1 timestamp of the last message to be included
    /// @param baseFeeL1 The l1 gas price of the last message to be included
    /// @param sender The sender of the last message to be included
    /// @param messageDataHash The messageDataHash of the last message to be included
    function forceInclusion(
        uint256 _totalDelayedMessagesRead,
        uint8 kind,
        uint64[2] calldata l1BlockAndTime,
        uint256 baseFeeL1,
        address sender,
        bytes32 messageDataHash
    ) external;

    function inboxAccs(uint256 index) external view returns (bytes32);

    function batchCount() external view returns (uint256);

    function isValidKeysetHash(bytes32 ksHash) external view returns (bool);

    /// @notice the creation block is intended to still be available after a keyset is deleted
    function getKeysetCreationBlock(bytes32 ksHash) external view returns (uint256);

    // ---------- BatchPoster functions ----------

    function addSequencerL2BatchFromOrigin(
        uint256 sequenceNumber,
        bytes calldata data,
        uint256 afterDelayedMessagesRead,
        IGasRefunder gasRefunder
    ) external;

    function addSequencerL2Batch(
        uint256 sequenceNumber,
        bytes calldata data,
        uint256 afterDelayedMessagesRead,
        IGasRefunder gasRefunder,
        uint256 prevMessageCount,
        uint256 newMessageCount
    ) external;

    // ---------- onlyRollupOrOwner functions ----------

    /**
     * @notice Set max delay for sequencer inbox
     * @param maxTimeVariation_ the maximum time variation parameters
     */
    function setMaxTimeVariation(MaxTimeVariation memory maxTimeVariation_) external;

    /**
     * @notice Updates whether an address is authorized to be a batch poster at the sequencer inbox
     * @param addr the address
     * @param isBatchPoster_ if the specified address should be authorized as a batch poster
     */
    function setIsBatchPoster(address addr, bool isBatchPoster_) external;

    /**
     * @notice Makes Data Availability Service keyset valid
     * @param keysetBytes bytes of the serialized keyset
     */
    function setValidKeyset(bytes calldata keysetBytes) external;

    /**
     * @notice Invalidates a Data Availability Service keyset
     * @param ksHash hash of the keyset
     */
    function invalidateKeysetHash(bytes32 ksHash) external;

    // ---------- initializer ----------

    function initialize(IBridge bridge_, MaxTimeVariation calldata maxTimeVariation_) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Create2.sol)

pragma solidity ^0.8.0;

/**
 * @dev Helper to make usage of the `CREATE2` EVM opcode easier and safer.
 * `CREATE2` can be used to compute in advance the address where a smart
 * contract will be deployed, which allows for interesting new mechanisms known
 * as 'counterfactual interactions'.
 *
 * See the https://eips.ethereum.org/EIPS/eip-1014#motivation[EIP] for more
 * information.
 */
library Create2 {
    /**
     * @dev Deploys a contract using `CREATE2`. The address where the contract
     * will be deployed can be known in advance via {computeAddress}.
     *
     * The bytecode for a contract can be obtained from Solidity with
     * `type(contractName).creationCode`.
     *
     * Requirements:
     *
     * - `bytecode` must not be empty.
     * - `salt` must have not been used for `bytecode` already.
     * - the factory must have a balance of at least `amount`.
     * - if `amount` is non-zero, `bytecode` must have a `payable` constructor.
     */
    function deploy(
        uint256 amount,
        bytes32 salt,
        bytes memory bytecode
    ) internal returns (address addr) {
        require(address(this).balance >= amount, "Create2: insufficient balance");
        require(bytecode.length != 0, "Create2: bytecode length is zero");
        /// @solidity memory-safe-assembly
        assembly {
            addr := create2(amount, add(bytecode, 0x20), mload(bytecode), salt)
        }
        require(addr != address(0), "Create2: Failed on deploy");
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy}. Any change in the
     * `bytecodeHash` or `salt` will result in a new destination address.
     */
    function computeAddress(bytes32 salt, bytes32 bytecodeHash) internal view returns (address) {
        return computeAddress(salt, bytecodeHash, address(this));
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy} from a contract located at
     * `deployer`. If `deployer` is this contract's address, returns the same value as {computeAddress}.
     */
    function computeAddress(
        bytes32 salt,
        bytes32 bytecodeHash,
        address deployer
    ) internal pure returns (address addr) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40) // Get free memory pointer

            // |                   | ↓ ptr ...  ↓ ptr + 0x0B (start) ...  ↓ ptr + 0x20 ...  ↓ ptr + 0x40 ...   |
            // |-------------------|---------------------------------------------------------------------------|
            // | bytecodeHash      |                                                        CCCCCCCCCCCCC...CC |
            // | salt              |                                      BBBBBBBBBBBBB...BB                   |
            // | deployer          | 000000...0000AAAAAAAAAAAAAAAAAAA...AA                                     |
            // | 0xFF              |            FF                                                             |
            // |-------------------|---------------------------------------------------------------------------|
            // | memory            | 000000...00FFAAAAAAAAAAAAAAAAAAA...AABBBBBBBBBBBBB...BBCCCCCCCCCCCCC...CC |
            // | keccak(start, 85) |            ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑ |

            mstore(add(ptr, 0x40), bytecodeHash)
            mstore(add(ptr, 0x20), salt)
            mstore(ptr, deployer) // Right-aligned with 12 preceding garbage bytes
            let start := add(ptr, 0x0b) // The hashed data starts at the final garbage byte which we will set to 0xff
            mstore8(start, 0xff)
            addr := keccak256(start, 85)
        }
    }
}

// SPDX-License-Identifier: Apache-2.0

/*
 * Copyright 2020, Offchain Labs, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

// solhint-disable-next-line compiler-version
pragma solidity >=0.6.9 <0.9.0;

import "../../libraries/gateway/ITokenGateway.sol";
import "../../libraries/IERC165.sol";

/**
 * @title Common interface for gatways on L1 messaging to Arbitrum.
 */
interface IL1ArbitrumGateway is ITokenGateway, IERC165 {
    function inbox() external view returns (address);

    /**
     * @notice Deposit ERC20 token from Ethereum into Arbitrum. If L2 side hasn't been deployed yet, includes name/symbol/decimals data for initial L2 deploy. Initiate by GatewayRouter.
     * @dev L2 address alias will not be applied to the following types of addresses on L1:
     *      - an externally-owned account
     *      - a contract in construction
     *      - an address where a contract will be created
     *      - an address where a contract lived, but was destroyed
     * @param _l1Token L1 address of ERC20
     * @param _refundTo Account, or its L2 alias if it have code in L1, to be credited with excess gas refund in L2
     * @param _to Account to be credited with the tokens in the L2 (can be the user's L2 account or a contract), not subject to L2 aliasing
                  This account, or its L2 alias if it have code in L1, will also be able to cancel the retryable ticket and receive callvalue refund
     * @param _amount Token Amount
     * @param _maxGas Max gas deducted from user's L2 balance to cover L2 execution
     * @param _gasPriceBid Gas price for L2 execution
     * @param _data encoded data from router and user
     * @return res abi encoded inbox sequence number
     */
    //  * @param maxSubmissionCost Max gas deducted from user's L2 balance to cover base submission fee
    function outboundTransferCustomRefund(
        address _l1Token,
        address _refundTo,
        address _to,
        uint256 _amount,
        uint256 _maxGas,
        uint256 _gasPriceBid,
        bytes calldata _data
    ) external payable returns (bytes memory);
}

// SPDX-License-Identifier: Apache-2.0

/*
 * Copyright 2021, Offchain Labs, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

pragma solidity ^0.8.0;

library ProxyUtil {
    function getProxyAdmin() internal view returns (address admin) {
        // https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.4.0/contracts/proxy/TransparentUpgradeableProxy.sol#L48
        // Storage slot with the admin of the proxy contract.
        // This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
        bytes32 slot = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;
        assembly {
            admin := sload(slot)
        }
    }
}

// SPDX-License-Identifier: Apache-2.0

/*
 * Copyright 2021, Offchain Labs, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

pragma solidity ^0.8.0;

/// @notice this library manages encoding and decoding of gateway communication
library GatewayMessageHandler {
    // these are for communication from L1 to L2 gateway

    function encodeToL2GatewayMsg(bytes memory gatewayData, bytes memory callHookData)
        internal
        pure
        returns (bytes memory res)
    {
        res = abi.encode(gatewayData, callHookData);
    }

    function parseFromL1GatewayMsg(bytes calldata _data)
        internal
        pure
        returns (bytes memory gatewayData, bytes memory callHookData)
    {
        // abi decode may revert, but the encoding is done by L1 gateway, so we trust it
        (gatewayData, callHookData) = abi.decode(_data, (bytes, bytes));
    }

    // these are for communication from L2 to L1 gateway

    function encodeFromL2GatewayMsg(uint256 exitNum, bytes memory callHookData)
        internal
        pure
        returns (bytes memory res)
    {
        res = abi.encode(exitNum, callHookData);
    }

    function parseToL1GatewayMsg(bytes calldata _data)
        internal
        pure
        returns (uint256 exitNum, bytes memory callHookData)
    {
        // abi decode may revert, but the encoding is done by L1 gateway, so we trust it
        (exitNum, callHookData) = abi.decode(_data, (uint256, bytes));
    }

    // these are for communication from router to gateway

    function encodeFromRouterToGateway(address _from, bytes calldata _data)
        internal
        pure
        returns (bytes memory res)
    {
        // abi decode may revert, but the encoding is done by L1 gateway, so we trust it
        return abi.encode(_from, _data);
    }

    function parseFromRouterToGateway(bytes calldata _data)
        internal
        pure
        returns (address, bytes memory res)
    {
        // abi decode may revert, but the encoding is done by L1 gateway, so we trust it
        return abi.decode(_data, (address, bytes));
    }
}

// SPDX-License-Identifier: Apache-2.0

/*
 * Copyright 2020, Offchain Labs, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

pragma solidity ^0.8.0;

import "./ITokenGateway.sol";
import "@openzeppelin/contracts/utils/Address.sol";

abstract contract TokenGateway is ITokenGateway {
    using Address for address;

    address public counterpartGateway;
    address public router;

    // This modifier is overriden in gateways to validate the message sender
    // For L1 to L2 messages need to be validated against the aliased counterpartGateway
    // For L2 to L1 messages need to be validated against the bridge and L2ToL1Sender
    // prettier-ignore
    modifier onlyCounterpartGateway() virtual;

    function _initialize(address _counterpartGateway, address _router) internal virtual {
        // This initializes internal variables of the abstract contract it can be chained together with other functions.
        // It is virtual so subclasses can override or wrap around this logic.
        // An example where this is useful is different subclasses that validate the router address differently
        require(_counterpartGateway != address(0), "INVALID_COUNTERPART");
        require(counterpartGateway == address(0), "ALREADY_INIT");
        counterpartGateway = _counterpartGateway;
        router = _router;
    }

    function isRouter(address _target) internal view returns (bool isTargetRouter) {
        return _target == router;
    }

    /**
     * @notice Calculate the address used when bridging an ERC20 token
     * @dev the L1 and L2 address oracles may not always be in sync.
     * For example, a custom token may have been registered but not deploy or the contract self destructed.
     * @param l1ERC20 address of L1 token
     * @return L2 address of a bridged ERC20 token
     */
    function calculateL2TokenAddress(address l1ERC20)
        public
        view
        virtual
        override
        returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

// With pragma modification to support ^0.6.11
// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v4.6/contracts/utils/introspection/ERC165.sol

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: Apache-2.0

/*
 * Copyright 2019-2021, Offchain Labs, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

pragma solidity ^0.8.0;

library AddressAliasHelper {
    uint160 constant offset = uint160(0x1111000000000000000000000000000000001111);

    /// @notice Utility function that converts the address in the L1 that submitted a tx to
    /// the inbox to the msg.sender viewed in the L2
    /// @param l1Address the address in the L1 that triggered the tx to L2
    /// @return l2Address L2 address as viewed in msg.sender
    function applyL1ToL2Alias(address l1Address) internal pure returns (address l2Address) {
        unchecked {
            l2Address = address(uint160(l1Address) + offset);
        }
    }

    /// @notice Utility function that converts the msg.sender viewed in the L2 to the
    /// address in the L1 that submitted a tx to the inbox
    /// @param l2Address L2 address as viewed in msg.sender
    /// @return l1Address the address in the L1 that triggered the tx to L2
    function undoL1ToL2Alias(address l2Address) internal pure returns (address l1Address) {
        unchecked {
            l1Address = address(uint160(l2Address) - offset);
        }
    }
}

// SPDX-License-Identifier: MIT

/*
 * @title Solidity Bytes Arrays Utils
 * @author Gonçalo Sá <[email protected]>
 *
 * @dev Bytes tightly packed arrays utility library for ethereum contracts written in Solidity.
 *      The library lets you concatenate, slice and type cast bytes arrays both in memory and storage.
 */

pragma solidity ^0.8.0;

/* solhint-disable no-inline-assembly */
library BytesLib {
    function toAddress(bytes memory _bytes, uint256 _start) internal pure returns (address) {
        require(_bytes.length >= (_start + 20), "Read out of bounds");
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }

    function toUint8(bytes memory _bytes, uint256 _start) internal pure returns (uint8) {
        require(_bytes.length >= (_start + 1), "Read out of bounds");
        uint8 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x1), _start))
        }

        return tempUint;
    }

    function toUint(bytes memory _bytes, uint256 _start) internal pure returns (uint256) {
        require(_bytes.length >= (_start + 32), "Read out of bounds");
        uint256 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x20), _start))
        }

        return tempUint;
    }

    function toBytes32(bytes memory _bytes, uint256 _start) internal pure returns (bytes32) {
        require(_bytes.length >= (_start + 32), "Read out of bounds");
        bytes32 tempBytes32;

        assembly {
            tempBytes32 := mload(add(add(_bytes, 0x20), _start))
        }

        return tempBytes32;
    }
}
/* solhint-enable no-inline-assembly */

// SPDX-License-Identifier: Apache-2.0

/*
 * Copyright 2020, Offchain Labs, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/**
 * @title Minimum expected interface for L2 token that interacts with the L2 token bridge (this is the interface necessary
 * for a custom token that interacts with the bridge, see TestArbCustomToken.sol for an example implementation).
 */

// solhint-disable-next-line compiler-version
pragma solidity >=0.6.9 <0.9.0;

interface IArbToken {
    /**
     * @notice should increase token supply by amount, and should (probably) only be callable by the L1 bridge.
     */
    function bridgeMint(address account, uint256 amount) external;

    /**
     * @notice should decrease token supply by amount, and should (probably) only be callable by the L1 bridge.
     */
    function bridgeBurn(address account, uint256 amount) external;

    /**
     * @return address of layer 1 token
     */
    function l1Address() external view returns (address);
}

// SPDX-License-Identifier: Apache-2.0

/*
 * Copyright 2020, Offchain Labs, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

pragma solidity ^0.8.0;

import "@arbitrum/nitro-contracts/src/precompiles/ArbSys.sol";

/// @notice L2 utility contract to assist with L1 <=> L2 interactions
/// @dev this is an abstract contract instead of library so the functions can be easily overriden when testing
abstract contract L2ArbitrumMessenger {
    address internal constant ARB_SYS_ADDRESS = address(100);

    event TxToL1(address indexed _from, address indexed _to, uint256 indexed _id, bytes _data);

    function sendTxToL1(
        uint256 _l1CallValue,
        address _from,
        address _to,
        bytes memory _data
    ) internal returns (uint256) {
        uint256 _id = ArbSys(ARB_SYS_ADDRESS).sendTxToL1{ value: _l1CallValue }(_to, _data);
        emit TxToL1(_from, _to, _id, _data);
        return _id;
    }
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.21 <0.9.0;

interface IOwnable {
    function owner() external view returns (address);
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

// solhint-disable-next-line compiler-version
pragma solidity >=0.6.9 <0.9.0;

interface IGasRefunder {
    function onGasSpent(
        address payable spender,
        uint256 gasUsed,
        uint256 calldataSize
    ) external returns (bool success);
}

abstract contract GasRefundEnabled {
    /// @dev this refunds the sender for execution costs of the tx
    /// calldata costs are only refunded if `msg.sender == tx.origin` to guarantee the value refunded relates to charging
    /// for the `tx.input`. this avoids a possible attack where you generate large calldata from a contract and get over-refunded
    modifier refundsGas(IGasRefunder gasRefunder) {
        uint256 startGasLeft = gasleft();
        _;
        if (address(gasRefunder) != address(0)) {
            uint256 calldataSize;
            assembly {
                calldataSize := calldatasize()
            }
            uint256 calldataWords = (calldataSize + 31) / 32;
            // account for the CALLDATACOPY cost of the proxy contract, including the memory expansion cost
            startGasLeft += calldataWords * 6 + (calldataWords**2) / 512;
            // if triggered in a contract call, the spender may be overrefunded by appending dummy data to the call
            // so we check if it is a top level call, which would mean the sender paid calldata as part of tx.input
            // solhint-disable-next-line avoid-tx-origin
            if (msg.sender != tx.origin) {
                // We can't be sure if this calldata came from the top level tx,
                // so to be safe we tell the gas refunder there was no calldata.
                calldataSize = 0;
            }
            gasRefunder.onGasSpent(payable(msg.sender), startGasLeft - gasleft(), calldataSize);
        }
    }
}

// SPDX-License-Identifier: Apache-2.0

/*
 * Copyright 2020, Offchain Labs, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

// solhint-disable-next-line compiler-version
pragma solidity >=0.6.9 <0.9.0;

interface ITokenGateway {
    /// @notice event deprecated in favor of DepositInitiated and WithdrawalInitiated
    // event OutboundTransferInitiated(
    //     address token,
    //     address indexed _from,
    //     address indexed _to,
    //     uint256 indexed _transferId,
    //     uint256 _amount,
    //     bytes _data
    // );

    /// @notice event deprecated in favor of DepositFinalized and WithdrawalFinalized
    // event InboundTransferFinalized(
    //     address token,
    //     address indexed _from,
    //     address indexed _to,
    //     uint256 indexed _transferId,
    //     uint256 _amount,
    //     bytes _data
    // );

    function outboundTransfer(
        address _token,
        address _to,
        uint256 _amount,
        uint256 _maxGas,
        uint256 _gasPriceBid,
        bytes calldata _data
    ) external payable returns (bytes memory);

    function finalizeInboundTransfer(
        address _token,
        address _from,
        address _to,
        uint256 _amount,
        bytes calldata _data
    ) external payable;

    /**
     * @notice Calculate the address used when bridging an ERC20 token
     * @dev the L1 and L2 address oracles may not always be in sync.
     * For example, a custom token may have been registered but not deploy or the contract self destructed.
     * @param l1ERC20 address of L1 token
     * @return L2 address of a bridged ERC20 token
     */
    function calculateL2TokenAddress(address l1ERC20) external view returns (address);

    function getOutboundCalldata(
        address _token,
        address _from,
        address _to,
        uint256 _amount,
        bytes memory _data
    ) external view returns (bytes memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

// With pragma modification to allow interface compatibility with >=0.6.9 <0.9.0
// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v4.6/contracts/utils/introspection/IERC165.sol

// solhint-disable-next-line compiler-version
pragma solidity >=0.6.9 <0.9.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
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
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.4.21 <0.9.0;

/**
 * @title System level functionality
 * @notice For use by contracts to interact with core L2-specific functionality.
 * Precompiled contract that exists in every Arbitrum chain at address(100), 0x0000000000000000000000000000000000000064.
 */
interface ArbSys {
    /**
     * @notice Get Arbitrum block number (distinct from L1 block number; Arbitrum genesis block has block number 0)
     * @return block number as int
     */
    function arbBlockNumber() external view returns (uint256);

    /**
     * @notice Get Arbitrum block hash (reverts unless currentBlockNum-256 <= arbBlockNum < currentBlockNum)
     * @return block hash
     */
    function arbBlockHash(uint256 arbBlockNum) external view returns (bytes32);

    /**
     * @notice Gets the rollup's unique chain identifier
     * @return Chain identifier as int
     */
    function arbChainID() external view returns (uint256);

    /**
     * @notice Get internal version number identifying an ArbOS build
     * @return version number as int
     */
    function arbOSVersion() external view returns (uint256);

    /**
     * @notice Returns 0 since Nitro has no concept of storage gas
     * @return uint 0
     */
    function getStorageGasAvailable() external view returns (uint256);

    /**
     * @notice (deprecated) check if current call is top level (meaning it was triggered by an EoA or a L1 contract)
     * @dev this call has been deprecated and may be removed in a future release
     * @return true if current execution frame is not a call by another L2 contract
     */
    function isTopLevelCall() external view returns (bool);

    /**
     * @notice map L1 sender contract address to its L2 alias
     * @param sender sender address
     * @param unused argument no longer used
     * @return aliased sender address
     */
    function mapL1SenderContractAddressToL2Alias(address sender, address unused)
        external
        pure
        returns (address);

    /**
     * @notice check if the caller (of this caller of this) is an aliased L1 contract address
     * @return true iff the caller's address is an alias for an L1 contract address
     */
    function wasMyCallersAddressAliased() external view returns (bool);

    /**
     * @notice return the address of the caller (of this caller of this), without applying L1 contract address aliasing
     * @return address of the caller's caller, without applying L1 contract address aliasing
     */
    function myCallersAddressWithoutAliasing() external view returns (address);

    /**
     * @notice Send given amount of Eth to dest from sender.
     * This is a convenience function, which is equivalent to calling sendTxToL1 with empty data.
     * @param destination recipient address on L1
     * @return unique identifier for this L2-to-L1 transaction.
     */
    function withdrawEth(address destination) external payable returns (uint256);

    /**
     * @notice Send a transaction to L1
     * @dev it is not possible to execute on the L1 any L2-to-L1 transaction which contains data
     * to a contract address without any code (as enforced by the Bridge contract).
     * @param destination recipient address on L1
     * @param data (optional) calldata for L1 contract call
     * @return a unique identifier for this L2-to-L1 transaction.
     */
    function sendTxToL1(address destination, bytes calldata data)
        external
        payable
        returns (uint256);

    /**
     * @notice Get send Merkle tree state
     * @return size number of sends in the history
     * @return root root hash of the send history
     * @return partials hashes of partial subtrees in the send history tree
     */
    function sendMerkleTreeState()
        external
        view
        returns (
            uint256 size,
            bytes32 root,
            bytes32[] memory partials
        );

    /**
     * @notice creates a send txn from L2 to L1
     * @param position = (level << 192) + leaf = (0 << 192) + leaf = leaf
     */
    event L2ToL1Tx(
        address caller,
        address indexed destination,
        uint256 indexed hash,
        uint256 indexed position,
        uint256 arbBlockNum,
        uint256 ethBlockNum,
        uint256 timestamp,
        uint256 callvalue,
        bytes data
    );

    /// @dev DEPRECATED in favour of the new L2ToL1Tx event above after the nitro upgrade
    event L2ToL1Transaction(
        address caller,
        address indexed destination,
        uint256 indexed uniqueId,
        uint256 indexed batchNumber,
        uint256 indexInBatch,
        uint256 arbBlockNum,
        uint256 ethBlockNum,
        uint256 timestamp,
        uint256 callvalue,
        bytes data
    );

    /**
     * @notice logs a merkle branch for proof synthesis
     * @param reserved an index meant only to align the 4th index with L2ToL1Transaction's 4th event
     * @param hash the merkle hash
     * @param position = (level << 192) + leaf
     */
    event SendMerkleUpdate(
        uint256 indexed reserved,
        bytes32 indexed hash,
        uint256 indexed position
    );

    error InvalidBlockNumber(uint256 requested, uint256 current);
}