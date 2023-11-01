// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../../helpers/Errors.sol";
import "../../helpers/TransferHelper.sol";
import "../../BridgeBase.sol";

interface ICircleRouter {
    function depositForBurn(
        uint256 amount,
        uint32 destinationDomain,
        bytes32 mintRecipient,
        address burnToken
    ) external;
}

contract CircleBridgeBaseImpl is BridgeBase, ReentrancyGuard {
    ICircleRouter public immutable circleRouter;

    constructor(
        ICircleRouter _circleRouter,
        address _router
    ) BridgeBase(_router) {
        circleRouter = _circleRouter;
    }

    event Bridge(
        uint256 amount,
        address fromToken,
        uint256 toChainId,
        address toAddress,
        address toToken,
        string channel,
        uint256 channelFee
    );

    struct CircleData {
        uint32 _destinationDomain;
        address _toTokenAddress;
        bytes32 _mintRecipient;
        address _gasAddress;
        uint256 _gasTokenAmount;
        string _channel;
        uint256 _channelFee;
    }

    receive() external payable {}

    function bridge(
        address _fromAddress,
        address _fromToken,
        uint256 _amount,
        address _receiverAddress,
        uint256 _toChainId,
        bytes memory _extraData,
        address _feeAddress
    ) external payable override onlyRouter nonReentrant {
        require(_fromToken != NATIVE_TOKEN_ADDRESS, Errors.TOKEN_NOT_SUPPORTED);
        CircleData memory _circleData = abi.decode(_extraData, (CircleData));

        TransferHelper.safeTransferFrom(
            _fromToken,
            _fromAddress,
            address(this),
            _amount
        );
        uint256 _channelFee = _circleData._channelFee;
        if (_channelFee != 0) {
            uint256 feeAmount = (_amount * _channelFee) / 1000000;
            TransferHelper.safeTransfer(_fromToken, _feeAddress, feeAmount);
            _amount = _amount - feeAmount;
        }
        TransferHelper.safeTransfer(
            _fromToken,
            _circleData._gasAddress,
            _circleData._gasTokenAmount
        );
        uint256 bridgeAmt = _amount - _circleData._gasTokenAmount;
        TransferHelper.safeApprove(_fromToken, address(circleRouter), bridgeAmt);
        circleRouter.depositForBurn(
            bridgeAmt,
            _circleData._destinationDomain,
            _circleData._mintRecipient,
            _fromToken
        );
        emit Bridge(
            _amount,
            _fromToken,
            _toChainId,
            _receiverAddress,
            _circleData._toTokenAddress,
            _circleData._channel,
            _channelFee
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

library Errors {
    string internal constant ADDRESS_0_PROVIDED = "ADDRESS_0_PROVIDED";
    string internal constant DEX_NOT_ALLOWED = "DEX_NOT_ALLOWED";
    string internal constant TOKEN_NOT_SUPPORTED = "TOKEN_NOT_SUPPORTED";
    string internal constant SWAP_FAILED = "SWAP_FAILED";
    string internal constant VALUE_SHOULD_BE_ZERO = "VALUE_SHOULD_BE_ZERO";
    string internal constant VALUE_SHOULD_NOT_BE_ZERO = "VALUE_SHOULD_NOT_BE_ZERO";
    string internal constant VALUE_NOT_EQUAL_TO_AMOUNT = "VALUE_NOT_EQUAL_TO_AMOUNT";

    string internal constant INVALID_AMT = "INVALID_AMT";
    string internal constant INVALID_ADDRESS = "INVALID_ADDRESS";
    string internal constant INVALID_SENDER = "INVALID_SENDER";

    string internal constant UNKNOWN_TRANSFER_ID = "UNKNOWN_TRANSFER_ID";
    string internal constant CALL_DATA_MUST_SIGNED_BY_OWNER = "CALL_DATA_MUST_SIGNED_BY_OWNER";

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
import "@openzeppelin/contracts/access/Ownable.sol";
import "./helpers/Errors.sol";
import "./helpers/TransferHelper.sol";


abstract contract BridgeBase is Ownable {
    address public router;
    address public constant NATIVE_TOKEN_ADDRESS = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
    

    constructor(address _router) Ownable() {
        router = _router;
    }

    event UpdateRouterAddress(address indexed routerAddress);

    event WithdrawETH(uint256 amount);

    event Withdraw(address token, uint256 amount);

    modifier onlyRouter() {
        require(msg.sender == router, Errors.INVALID_SENDER);
        _;
    }

    function updateRouterAddress(address newRouter) external onlyOwner {
        router = newRouter;
        emit UpdateRouterAddress(newRouter);
    }

    function bridge(
        address _fromAddress,
        address _fromToken,
        uint256 _amount,
        address _receiverAddress,
        uint256 _toChainId,
        bytes memory _extraData,
        address feeAddress
    ) external payable virtual;


    function withdraw(address _token, address _receiverAddress, uint256 _amount) external onlyOwner {
        require(_receiverAddress != address(0), Errors.ADDRESS_0_PROVIDED);
        TransferHelper.safeTransfer(_token, _receiverAddress, _amount);
        emit Withdraw(_token, _amount);
    }

    function withdrawETH(address _receiverAddress, uint256 _amount) external onlyOwner {
        require(_receiverAddress != address(0), Errors.ADDRESS_0_PROVIDED);
        TransferHelper.safeTransferETH(_receiverAddress, _amount);
        emit WithdrawETH(_amount);
    }

}

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

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
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}