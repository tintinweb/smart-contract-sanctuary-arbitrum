// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.17;

import "./common/DelegateInterface.sol";
import "./common/Adminable.sol";
import "./common/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./libraries/TransferHelper.sol";
import "./libraries/DexData.sol";
import "./libraries/Utils.sol";
import "./interfaces/OPBuyBackInterface.sol";
import "./libraries/Aggregator1InchV5.sol";
import "./IWrappedNativeToken.sol";

contract OPBuyBack is DelegateInterface, Adminable, ReentrancyGuard {
    using TransferHelper for IERC20;
    using DexData for bytes;
    event Received(address token, uint256 inAmount, uint256 received);
    event BuyBacked(address token, uint256 sellAmount, uint256 boughtAmount);

    address public ole;
    address public wrappedNativeToken;
    address public router1inch;

    address private constant _ZERO_ADDRESS = address(0);

    constructor() {}

    /// @notice Initialize contract only by admin
    /// @dev This function is supposed to call multiple times
    /// @param _ole The ole token address
    /// @param _router1inch The 1inch router address
    function initialize(address _ole, address _wrappedNativeToken, address _router1inch) external onlyAdmin {
        ole = _ole;
        wrappedNativeToken = _wrappedNativeToken;
        router1inch = _router1inch;
    }

    function transferIn(address token, uint amount) external payable {
        if (isNativeToken(token)) {
            emit Received(token, msg.value, msg.value);
        } else {
            uint256 received = IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
            emit Received(token, amount, received);
        }
    }

    function withdraw(address token, address to, uint amount) external onlyAdmin {
        if (isNativeToken(token)) {
            (bool success, ) = to.call{ value: amount }("");
            require(success);
        } else {
            IERC20(token).safeTransfer(to, amount);
        }
    }

    function buyBack(address sellToken, uint sellAmount, uint minBuyAmount, bytes memory data) external nonReentrant onlyAdminOrDeveloper {
        require(sellToken != ole, "Token err");
        if (isNativeToken(sellToken)) {
            sellToken = wrappedNativeToken;
            IWrappedNativeToken(wrappedNativeToken).deposit{ value: sellAmount }();
        }
        uint boughtAmount = Aggregator1InchV5.swap1inch(router1inch, data, address(this), ole, sellToken, sellAmount, minBuyAmount);
        emit BuyBacked(sellToken, sellAmount, boughtAmount);
    }

    function setRouter1inch(address _router1inch) external onlyAdmin {
        router1inch = _router1inch;
    }

    function isNativeToken(address token) private pure returns (bool) {
        return token == _ZERO_ADDRESS;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

library Utils {
    uint private constant FEE_RATE_PRECISION = 10 ** 6;

    function toAmountBeforeTax(uint256 amount, uint24 feeRate) internal pure returns (uint) {
        uint denominator = FEE_RATE_PRECISION - feeRate;
        uint numerator = amount * FEE_RATE_PRECISION + denominator - 1;
        return numerator / denominator;
    }

    function toAmountAfterTax(uint256 amount, uint24 feeRate) internal pure returns (uint) {
        return (amount * (FEE_RATE_PRECISION - feeRate)) / FEE_RATE_PRECISION;
    }

    function minOf(uint a, uint b) internal pure returns (uint) {
        return a < b ? a : b;
    }

    function maxOf(uint a, uint b) internal pure returns (uint) {
        return a > b ? a : b;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title TransferHelper
 * @dev Wrappers around ERC20 operations that returns the value received by recipent and the actual allowance of approval.
 * To use this library you can add a `using TransferHelper for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library TransferHelper {
    function safeTransfer(IERC20 _token, address _to, uint256 _amount) internal {
        if (_amount > 0) {
            bool success;
            (success, ) = address(_token).call(abi.encodeWithSelector(_token.transfer.selector, _to, _amount));
            require(success, "TF");
        }
    }

    function safeTransferFrom(IERC20 _token, address _from, address _to, uint256 _amount) internal returns (uint256 amountReceived) {
        if (_amount > 0) {
            bool success;
            uint256 balanceBefore = _token.balanceOf(_to);
            (success, ) = address(_token).call(abi.encodeWithSelector(_token.transferFrom.selector, _from, _to, _amount));
            require(success, "TFF");
            uint256 balanceAfter = _token.balanceOf(_to);
            amountReceived = balanceAfter - balanceBefore;
        }
    }

    function safeApprove(IERC20 _token, address _spender, uint256 _amount) internal {
        bool success;
        if (_token.allowance(address(this), _spender) != 0) {
            (success, ) = address(_token).call(abi.encodeWithSelector(_token.approve.selector, _spender, 0));
            require(success, "AF");
        }
        (success, ) = address(_token).call(abi.encodeWithSelector(_token.approve.selector, _spender, _amount));
        require(success, "AF");
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

/// @dev DexDataFormat addPair = byte(dexID) + bytes3(feeRate) + bytes(arrayLength) + byte3[arrayLength](trasferFeeRate Lpool <-> openlev)
/// + byte3[arrayLength](transferFeeRate openLev -> Dex) + byte3[arrayLength](Dex -> transferFeeRate openLev)
/// exp: 0x0100000002011170000000011170000000011170000000
/// DexDataFormat dexdata = byte(dexID）+ bytes3(feeRate) + byte(arrayLength) + path
/// uniV2Path = bytes20[arraylength](address)
/// uniV3Path = bytes20(address)+ bytes20[arraylength-1](address + fee)
library DexData {
    // in byte
    uint constant DEX_INDEX = 0;
    uint constant FEE_INDEX = 1;
    uint constant ARRYLENTH_INDEX = 4;
    uint constant TRANSFERFEE_INDEX = 5;
    uint constant PATH_INDEX = 5;
    uint constant FEE_SIZE = 3;
    uint constant ADDRESS_SIZE = 20;
    uint constant NEXT_OFFSET = ADDRESS_SIZE + FEE_SIZE;

    uint8 constant DEX_UNIV2 = 1;
    uint8 constant DEX_UNIV3 = 2;
    uint8 constant DEX_PANCAKE = 3;
    uint8 constant DEX_SUSHI = 4;
    uint8 constant DEX_MDEX = 5;
    uint8 constant DEX_TRADERJOE = 6;
    uint8 constant DEX_SPOOKY = 7;
    uint8 constant DEX_QUICK = 8;
    uint8 constant DEX_SHIBA = 9;
    uint8 constant DEX_APE = 10;
    uint8 constant DEX_PANCAKEV1 = 11;
    uint8 constant DEX_BABY = 12;
    uint8 constant DEX_MOJITO = 13;
    uint8 constant DEX_KU = 14;
    uint8 constant DEX_BISWAP = 15;
    uint8 constant DEX_VVS = 20;

    function toDex(bytes memory data) internal pure returns (uint8) {
        require(data.length >= FEE_INDEX, "DexData: toDex wrong data format");
        uint8 temp;
        assembly {
            temp := byte(0, mload(add(data, add(0x20, DEX_INDEX))))
        }
        return temp;
    }

    function toFee(bytes memory data) internal pure returns (uint24) {
        require(data.length >= ARRYLENTH_INDEX, "DexData: toFee wrong data format");
        uint temp;
        assembly {
            temp := mload(add(data, add(0x20, FEE_INDEX)))
        }
        return uint24(temp >> (256 - (ARRYLENTH_INDEX - FEE_INDEX) * 8));
    }

    function toDexDetail(bytes memory data) internal pure returns (uint32) {
        require(data.length >= FEE_INDEX, "DexData: toDexDetail wrong data format");
        if (isUniV2Class(data)) {
            uint8 temp;
            assembly {
                temp := byte(0, mload(add(data, add(0x20, DEX_INDEX))))
            }
            return uint32(temp);
        } else {
            uint temp;
            assembly {
                temp := mload(add(data, add(0x20, DEX_INDEX)))
            }
            return uint32(temp >> (256 - ((FEE_SIZE + FEE_INDEX) * 8)));
        }
    }

    function isUniV2Class(bytes memory data) internal pure returns (bool) {
        return toDex(data) != DEX_UNIV3;
    }

    function subByte(bytes memory data, uint startIndex, uint len) internal pure returns (bytes memory bts) {
        require(startIndex <= data.length && data.length - startIndex >= len, "DexData: wrong data format");
        uint addr;
        assembly {
            addr := add(data, 32)
        }
        addr = addr + startIndex;
        bts = new bytes(len);
        uint btsptr;
        assembly {
            btsptr := add(bts, 32)
        }
        for (; len > 32; len -= 32) {
            assembly {
                mstore(btsptr, mload(addr))
            }
            btsptr += 32;
            addr += 32;
        }
        uint mask = 256 ** (32 - len) - 1;
        assembly {
            let srcpart := and(mload(addr), not(mask))
            let destpart := and(mload(btsptr), mask)
            mstore(btsptr, or(destpart, srcpart))
        }
    }

    function bytesToAddress(bytes memory bys) internal pure returns (address addr) {
        require(bys.length == 32, "length error");
        assembly {
            addr := mload(add(bys, 32))
        }
    }

    function toBytes(uint _num) internal pure returns (bytes memory _ret) {
        assembly {
            _ret := mload(0x10)
            mstore(_ret, 0x20)
            mstore(add(_ret, 0x20), _num)
        }
    }

    function concat(bytes memory _preBytes, bytes memory _postBytes) internal pure returns (bytes memory) {
        bytes memory tempBytes;
        assembly {
            tempBytes := mload(0x40)
            let length := mload(_preBytes)
            mstore(tempBytes, length)
            let mc := add(tempBytes, 0x20)
            let end := add(mc, length)
            for {
                let cc := add(_preBytes, 0x20)
            } lt(mc, end) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                mstore(mc, mload(cc))
            }
            length := mload(_postBytes)
            mstore(tempBytes, add(length, mload(tempBytes)))
            mc := end
            end := add(mc, length)
            for {
                let cc := add(_postBytes, 0x20)
            } lt(mc, end) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                mstore(mc, mload(cc))
            }
            mstore(0x40, and(add(add(end, iszero(add(length, mload(_preBytes)))), 31), not(31)))
        }
        return tempBytes;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./TransferHelper.sol";
import "./DexData.sol";

library Aggregator1InchV5 {
    using TransferHelper for IERC20;
    using DexData for bytes;

    bytes4 constant UNISWAP_V3_SWAP = 0xe449022e;
    bytes4 constant UNO_SWAP = 0x0502b1c5;
    bytes4 constant SWAP = 0x12aa3caf;
    uint constant default_length = 32;

    function swap1inch(
        address router,
        bytes memory data,
        address payee,
        address buyToken,
        address sellToken,
        uint sellAmount,
        uint minBuyAmount
    ) internal returns (uint boughtAmount) {
        bytes4 functionName = getCallFunctionName(data);
        if (functionName != UNISWAP_V3_SWAP) {
            // verify sell token
            require(to1InchSellToken(data, functionName) == sellToken, "sell token error");
        }
        data = replace1InchSellAmount(data, functionName, sellAmount);
        uint buyTokenBalanceBefore = IERC20(buyToken).balanceOf(payee);
        IERC20(sellToken).safeApprove(router, sellAmount);
        (bool success, bytes memory returnData) = router.call(data);
        assembly {
            if eq(success, 0) {
                revert(add(returnData, 0x20), returndatasize())
            }
        }
        IERC20(sellToken).safeApprove(router, 0);
        boughtAmount = IERC20(buyToken).balanceOf(payee) - buyTokenBalanceBefore;
        require(boughtAmount >= minBuyAmount, "1inch: buy amount less than min");
    }

    function getCallFunctionName(bytes memory data) private pure returns (bytes4 bts) {
        bytes memory subData = DexData.subByte(data, 0, 4);
        assembly {
            bts := mload(add(subData, 32))
        }
    }

    function replace1InchSellAmount(bytes memory data, bytes4 functionName, uint sellAmount) private pure returns (bytes memory) {
        uint startIndex;
        if (functionName == SWAP) {
            startIndex = 164;
        } else if (functionName == UNO_SWAP) {
            startIndex = 36;
        } else if (functionName == UNISWAP_V3_SWAP) {
            startIndex = 4;
        } else {
            revert("USF");
        }
        bytes memory b1 = DexData.concat(DexData.subByte(data, 0, startIndex), DexData.toBytes(sellAmount));
        uint secondIndex = startIndex + default_length;
        return DexData.concat(b1, DexData.subByte(data, secondIndex, data.length - secondIndex));
    }

    function to1InchSellToken(bytes memory data, bytes4 functionName) private pure returns (address) {
        uint startIndex;
        if (functionName == SWAP) {
            startIndex = 36;
        } else if (functionName == UNO_SWAP) {
            startIndex = 4;
        } else {
            revert("USF");
        }
        bytes memory bts = DexData.subByte(data, startIndex, default_length);
        return DexData.bytesToAddress(bts);
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.17;

interface OPBuyBackInterface {
    function transferIn(address token, uint amount) external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.17;

contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        check();
        _status = _ENTERED;

        _;

        _status = _NOT_ENTERED;
    }

    function check() private view {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

contract DelegateInterface {
    /**
     * Implementation address for this contract
     */
    address public implementation;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.17;

abstract contract Adminable {
    address payable public admin;
    address payable public pendingAdmin;
    address payable public developer;

    event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);

    event NewAdmin(address oldAdmin, address newAdmin);

    constructor() {
        developer = payable(msg.sender);
    }

    modifier onlyAdmin() {
        checkAdmin();
        _;
    }
    modifier onlyAdminOrDeveloper() {
        require(msg.sender == admin || msg.sender == developer, "Only admin or dev");
        _;
    }

    function setPendingAdmin(address payable newPendingAdmin) external virtual onlyAdmin {
        // Save current value, if any, for inclusion in log
        address oldPendingAdmin = pendingAdmin;
        // Store pendingAdmin with value newPendingAdmin
        pendingAdmin = newPendingAdmin;
        // Emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin)
        emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin);
    }

    function acceptAdmin() external virtual {
        require(msg.sender == pendingAdmin, "Only pendingAdmin");
        // Save current values for inclusion in log
        address oldAdmin = admin;
        address oldPendingAdmin = pendingAdmin;
        // Store admin with value pendingAdmin
        admin = pendingAdmin;
        // Clear the pending value
        pendingAdmin = payable(0);
        emit NewAdmin(oldAdmin, admin);
        emit NewPendingAdmin(oldPendingAdmin, pendingAdmin);
    }

    function checkAdmin() private view {
        require(msg.sender == admin, "caller must be admin");
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

interface IWrappedNativeToken {
    function deposit() external payable;

    function withdraw(uint256) external;
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