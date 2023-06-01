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
pragma solidity ^0.8.0;

interface IACLManager {
    function addEmergencyAdmin(address _admin) external;

    function isEmergencyAdmin(address _admin) external view returns (bool);

    function removeEmergencyAdmin(address _admin) external;

    function addGovernance(address _governance) external;

    function isGovernance(address _governance) external view returns (bool);

    function removeGovernance(address _governance) external;

    function addOperator(address _operator) external;

    function isOperator(address _operator) external view returns (bool);

    function removeOperator(address _operator) external;

    function addBidsContract(address _bids) external;

    function isBidsContract(address _bids) external view returns (bool);

    function removeBidsContract(address _bids) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IWETH {
    function deposit() external payable;

    function withdraw(uint256) external;

    function allowance(address, address) external view returns (uint256);

    function approve(address guy, uint256 wad) external returns (bool);

    function transferFrom(
        address src,
        address dst,
        uint256 wad
    ) external returns (bool);

    function transfer(address dst, uint256 wad) external returns (bool);

    function balanceOf(address) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IWETHWithdrawAdapter {
    function withdraw(address recipient, uint256 amount, bytes memory data) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IWETHWithdrawAdapter.sol";
import "../interfaces/IWETH.sol";
import "../mocks/stargate/interfaces/IStargateRouter.sol";
import "../interfaces/IACLManager.sol";

interface IStargateRouterETH {
    function stargateRouter() external view returns (IStargateRouter);

    function swapETH(
        uint16 _dstChainId, // destination Stargate chainId
        address payable _refundAddress, // refund additional messageFee to this address
        bytes calldata _toAddress, // the receiver of the destination ETH
        uint256 _amountLD, // the amount, in Local Decimals, to be swapped
        uint256 _minAmountLD // the minimum amount accepted out on destination
    ) external payable;
}

contract WETHWithdrawAdapter is IWETHWithdrawAdapter {
    IStargateRouterETH public immutable stargateRouterETH;
    IWETH public immutable WETH;
    IACLManager public immutable aclManager;
    address public refundAddress;
    uint16 public layer1ChainId;

    event SetRefundAddress(address indexed _refundAddress);
    event SetLayer1ChainId(uint16 indexed _chainId);

    modifier onlyGovernance() {
        require(aclManager.isGovernance(msg.sender), "ONLY_GOVERNANCE");
        _;
    }

    constructor(address _stargateRouterETH, address _weth, address _refundAddress, uint16 _layer1ChainId, address _aclManager) {
        stargateRouterETH = IStargateRouterETH(_stargateRouterETH);
        WETH = IWETH(_weth);
        layer1ChainId = _layer1ChainId;
        aclManager = IACLManager(_aclManager);

        _setRefundAddress(_refundAddress);
    }

    function setRefundAddress(address _refundAddress) external onlyGovernance {
        _setRefundAddress(_refundAddress);
    }

    function _setRefundAddress(address _refundAddress) internal {
        refundAddress = _refundAddress;
        emit SetRefundAddress(_refundAddress);
    }

    function setLayer1ChainId(uint16 _layer1ChainId) external onlyGovernance {
        _setLayer1ChainId(_layer1ChainId);
    }

    function _setLayer1ChainId(uint16 _layer1ChainId) internal {
        layer1ChainId = _layer1ChainId;
        emit SetLayer1ChainId(_layer1ChainId);
    }

    function withdraw(
        address recipient,
        uint256 amount,
        bytes memory
    ) external {
        WETH.transferFrom(msg.sender, address(this), amount);
        WETH.withdraw(amount);

        IStargateRouter.lzTxObj memory params = IStargateRouter.lzTxObj({
            dstGasForCall: 0,
            dstNativeAmount: 0,
            dstNativeAddr: abi.encodePacked(address(0))
        });

        IStargateRouter stargateRouter = stargateRouterETH.stargateRouter();
        (uint256 fee, ) = stargateRouter.quoteLayerZeroFee(
            layer1ChainId,
            1,
            abi.encodePacked(recipient),
            abi.encodePacked(''),
            params
        );

        stargateRouterETH.swapETH{value: amount}(
            layer1ChainId,
            payable(refundAddress),
            abi.encodePacked(recipient),
            amount - fee,
            amount - fee * 2
        );
    }

    receive() external payable {
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;
pragma abicoder v2;

interface IStargateRouter {
    struct lzTxObj {
        uint256 dstGasForCall;
        uint256 dstNativeAmount;
        bytes dstNativeAddr;
    }

    function addLiquidity(
        uint256 _poolId,
        uint256 _amountLD,
        address _to
    ) external;

    function swap(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress,
        uint256 _amountLD,
        uint256 _minAmountLD,
        lzTxObj memory _lzTxParams,
        bytes calldata _to,
        bytes calldata _payload
    ) external payable;

    function redeemRemote(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress,
        uint256 _amountLP,
        uint256 _minAmountLD,
        bytes calldata _to,
        lzTxObj memory _lzTxParams
    ) external payable;

    function instantRedeemLocal(
        uint16 _srcPoolId,
        uint256 _amountLP,
        address _to
    ) external returns (uint256);

    function redeemLocal(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress,
        uint256 _amountLP,
        bytes calldata _to,
        lzTxObj memory _lzTxParams
    ) external payable;

    function sendCredits(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress
    ) external payable;

    function quoteLayerZeroFee(
        uint16 _dstChainId,
        uint8 _functionType,
        bytes calldata _toAddress,
        bytes calldata _transferAndCallPayload,
        lzTxObj memory _lzTxParams
    ) external view returns (uint256, uint256);
}