// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    // transfer and tranferFrom have been removed, because they don't work on all tokens (some aren't ERC20 complaint).
    // By removing them you can't accidentally use them.
    // name, symbol and decimals have been removed, because they are optional and sometimes wrongly implemented (MKR).
    // Use BoringERC20 with `using BoringERC20 for IERC20` and call `safeTransfer`, `safeTransferFrom`, etc instead.
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /// @notice EIP 2612
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

interface IStrictERC20 {
    // This is the strict ERC20 interface. Don't use this, certainly not if you don't control the ERC20 token you're calling.
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address _owner) external view returns (uint256 balance);
    function transfer(address _to, uint256 _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function approve(address _spender, uint256 _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /// @notice EIP 2612
    function permit(
        address owner,
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
import "../interfaces/IERC20.sol";

// solhint-disable avoid-low-level-calls

library BoringERC20 {
    bytes4 private constant SIG_SYMBOL = 0x95d89b41; // symbol()
    bytes4 private constant SIG_NAME = 0x06fdde03; // name()
    bytes4 private constant SIG_DECIMALS = 0x313ce567; // decimals()
    bytes4 private constant SIG_BALANCE_OF = 0x70a08231; // balanceOf(address)
    bytes4 private constant SIG_TOTALSUPPLY = 0x18160ddd; // balanceOf(address)
    bytes4 private constant SIG_TRANSFER = 0xa9059cbb; // transfer(address,uint256)
    bytes4 private constant SIG_TRANSFER_FROM = 0x23b872dd; // transferFrom(address,address,uint256)

    function returnDataToString(bytes memory data) internal pure returns (string memory) {
        if (data.length >= 64) {
            return abi.decode(data, (string));
        } else if (data.length == 32) {
            uint8 i = 0;
            while (i < 32 && data[i] != 0) {
                i++;
            }
            bytes memory bytesArray = new bytes(i);
            for (i = 0; i < 32 && data[i] != 0; i++) {
                bytesArray[i] = data[i];
            }
            return string(bytesArray);
        } else {
            return "???";
        }
    }

    /// @notice Provides a safe ERC20.symbol version which returns '???' as fallback string.
    /// @param token The address of the ERC-20 token contract.
    /// @return (string) Token symbol.
    function safeSymbol(IERC20 token) internal view returns (string memory) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(SIG_SYMBOL));
        return success ? returnDataToString(data) : "???";
    }

    /// @notice Provides a safe ERC20.name version which returns '???' as fallback string.
    /// @param token The address of the ERC-20 token contract.
    /// @return (string) Token name.
    function safeName(IERC20 token) internal view returns (string memory) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(SIG_NAME));
        return success ? returnDataToString(data) : "???";
    }

    /// @notice Provides a safe ERC20.decimals version which returns '18' as fallback value.
    /// @param token The address of the ERC-20 token contract.
    /// @return (uint8) Token decimals.
    function safeDecimals(IERC20 token) internal view returns (uint8) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(SIG_DECIMALS));
        return success && data.length == 32 ? abi.decode(data, (uint8)) : 18;
    }

    /// @notice Provides a gas-optimized balance check to avoid a redundant extcodesize check in addition to the returndatasize check.
    /// @param token The address of the ERC-20 token.
    /// @param to The address of the user to check.
    /// @return amount The token amount.
    function safeBalanceOf(IERC20 token, address to) internal view returns (uint256 amount) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(SIG_BALANCE_OF, to));
        require(success && data.length >= 32, "BoringERC20: BalanceOf failed");
        amount = abi.decode(data, (uint256));
    }

    /// @notice Provides a gas-optimized totalSupply to avoid a redundant extcodesize check in addition to the returndatasize check.
    /// @param token The address of the ERC-20 token.
    /// @return totalSupply The token totalSupply.
    function safeTotalSupply(IERC20 token) internal view returns (uint256 totalSupply) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(SIG_TOTALSUPPLY));
        require(success && data.length >= 32, "BoringERC20: totalSupply failed");
        totalSupply = abi.decode(data, (uint256));
    }

    /// @notice Provides a safe ERC20.transfer version for different ERC-20 implementations.
    /// Reverts on a failed transfer.
    /// @param token The address of the ERC-20 token.
    /// @param to Transfer tokens to.
    /// @param amount The token amount.
    function safeTransfer(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(SIG_TRANSFER, to, amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "BoringERC20: Transfer failed");
    }

    /// @notice Provides a safe ERC20.transferFrom version for different ERC-20 implementations.
    /// Reverts on a failed transfer.
    /// @param token The address of the ERC-20 token.
    /// @param from Transfer tokens from.
    /// @param to Transfer tokens to.
    /// @param amount The token amount.
    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(SIG_TRANSFER_FROM, from, to, amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "BoringERC20: TransferFrom failed");
    }
}

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

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.5.0;

/**
 * @dev Interface of the IOFT core standard
 */
interface ISendFrom {
    struct LzCallParams {
        address payable refundAddress;
        address zroPaymentAddress;
        bytes adapterParams;
    }

    /**
     * @dev send `_amount` amount of token to (`_dstChainId`, `_toAddress`) from `_from`
     * `_from` the owner of token
     * `_dstChainId` the destination chain identifier
     * `_toAddress` can be any size depending on the `dstChainId`.
     * `_amount` the quantity of tokens in wei
     * `_refundAddress` the address LayerZero refunds if too much message fee is sent
     * `_zroPaymentAddress` set to address(0x0) if not paying in ZRO (LayerZero Token)
     * `_adapterParams` is a flexible bytes array to indicate messaging adapter services
     */
    function sendFrom(
        address _from,
        uint16 _dstChainId,
        bytes32 _toAddress,
        uint256 _amount,
        LzCallParams calldata _callParams
    ) external payable;

    function useCustomAdapterParams() external view returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@boringcrypto/boring-solidity/contracts/libraries/BoringERC20.sol";

import "./MagnetarData.sol";

/*

__/\\\\\\\\\\\\\\\_____/\\\\\\\\\_____/\\\\\\\\\\\\\____/\\\\\\\\\\\_______/\\\\\_____________/\\\\\\\\\_____/\\\\\\\\\____        
 _\///////\\\/////____/\\\\\\\\\\\\\__\/\\\/////////\\\_\/////\\\///______/\\\///\\\________/\\\////////____/\\\\\\\\\\\\\__       
  _______\/\\\________/\\\/////////\\\_\/\\\_______\/\\\_____\/\\\_______/\\\/__\///\\\____/\\\/____________/\\\/////////\\\_      
   _______\/\\\_______\/\\\_______\/\\\_\/\\\\\\\\\\\\\/______\/\\\______/\\\______\//\\\__/\\\_____________\/\\\_______\/\\\_     
    _______\/\\\_______\/\\\\\\\\\\\\\\\_\/\\\/////////________\/\\\_____\/\\\_______\/\\\_\/\\\_____________\/\\\\\\\\\\\\\\\_    
     _______\/\\\_______\/\\\/////////\\\_\/\\\_________________\/\\\_____\//\\\______/\\\__\//\\\____________\/\\\/////////\\\_   
      _______\/\\\_______\/\\\_______\/\\\_\/\\\_________________\/\\\______\///\\\__/\\\_____\///\\\__________\/\\\_______\/\\\_  
       _______\/\\\_______\/\\\_______\/\\\_\/\\\______________/\\\\\\\\\\\____\///\\\\\/________\////\\\\\\\\\_\/\\\_______\/\\\_ 
        _______\///________\///________\///__\///______________\///////////_______\/////_____________\/////////__\///________\///__

*/

//TODO: decide if we should add whitelisted contracts or 'target' is always passed from outside
contract Magnetar is Ownable, MagnetarData {
    using BoringERC20 for IERC20;

    // ************************ //
    // *** PUBLIC FUNCTIONS *** //
    // ************************ //

    /// @notice Batch multiple calls together
    /// @param actions The list of actions to perform
    /// @param callDatas The list of actions' data
    function burst(
        uint32[] calldata actions,
        bytes[] calldata callDatas
    ) external payable returns (Result[] memory returnData) {
        require(
            actions.length == callDatas.length,
            "Magnetar: array length mismatch"
        );
        require(actions.length > 0, "Magnetar: no objects around");

        uint256 valAccumulator;

        uint256 length = actions.length;
        returnData = new Result[](length);

        for (uint256 i = 0; i < length; i++) {
            uint32 _action = actions[i];
            bytes memory _actionCalldata = callDatas[i];

            if (_action == PERMIT_ALL) {
                _permit(_actionCalldata, true);
            } else if (_action == PERMIT) {
                _permit(_actionCalldata, false);
            } else if (_action == TOFT_WRAP) {
                WrapData memory data = abi.decode(_actionCalldata, (WrapData));
                if (data.isNative) {
                    unchecked {
                        valAccumulator += data.value;
                    }
                    ITOFTOperations(data.target).wrapNative{value: data.value}(
                        data.to
                    );
                } else {
                    ITOFTOperations(data.target).wrap(
                        msg.sender,
                        data.to,
                        data.value
                    );
                }
            } else if (_action == TOFT_SEND_FROM) {
                SendFromData memory data = abi.decode(
                    _actionCalldata,
                    (SendFromData)
                );
                unchecked {
                    valAccumulator += data.value;
                }
                ISendFrom(data.target).sendFrom{value: data.value}(
                    msg.sender,
                    data.dstChainId,
                    data.to,
                    data.amount,
                    data.callParams
                );
            } else if (_action == YB_DEPOSIT_ASSET) {
                YieldBoxDepositData memory data = abi.decode(
                    _actionCalldata,
                    (YieldBoxDepositData)
                );
                (uint256 amountOut, uint256 shareOut) = IDepositAsset(
                    data.target
                ).depositAsset(
                        data.assetId,
                        msg.sender,
                        data.to,
                        data.amount,
                        data.share
                    );
                returnData[i] = Result({
                    success: true,
                    returnData: abi.encode(amountOut, shareOut)
                });
            } else if (_action == SGL_ADD_COLLATERAL) {
                SGLAddCollateralData memory data = abi.decode(
                    _actionCalldata,
                    (SGLAddCollateralData)
                );
                ISingularityOperations(data.target).addCollateral(
                    msg.sender,
                    data.to,
                    data.skim,
                    data.share
                );
            } else if (_action == SGL_BORROW) {
                SGLBorrowData memory data = abi.decode(
                    _actionCalldata,
                    (SGLBorrowData)
                );
                (uint256 part, uint256 share) = ISingularityOperations(
                    data.target
                ).borrow(msg.sender, data.to, data.amount);
                returnData[i] = Result({
                    success: true,
                    returnData: abi.encode(part, share)
                });
            } else if (_action == SGL_WITHDRAW_TO) {
                SGLWithdrawToData memory data = abi.decode(
                    _actionCalldata,
                    (SGLWithdrawToData)
                );
                ISingularityOperations(data.target).withdrawTo(
                    msg.sender,
                    data.dstChainId,
                    data.receiver,
                    data.amount,
                    data.adapterParams,
                    data.refundAddress
                );
            } else if (_action == SGL_LEND) {
                SGLLendData memory data = abi.decode(
                    _actionCalldata,
                    (SGLLendData)
                );
                uint256 fraction = ISingularityOperations(data.target).addAsset(
                    msg.sender,
                    data.to,
                    data.skim,
                    data.share
                );
                returnData[i] = Result({
                    success: true,
                    returnData: abi.encode(fraction)
                });
            } else if (_action == SGL_REPAY) {
                SGLRepayData memory data = abi.decode(
                    _actionCalldata,
                    (SGLRepayData)
                );
                uint256 amount = ISingularityOperations(data.target).repay(
                    msg.sender,
                    data.to,
                    data.skim,
                    data.part
                );
                returnData[i] = Result({
                    success: true,
                    returnData: abi.encode(amount)
                });
            } else if (_action == TOFT_SEND_APPROVAL) {
                SendApprovalData memory data = abi.decode(
                    _actionCalldata,
                    (SendApprovalData)
                );

                ITOFTOperations(data.target).sendApproval{value: data.value}(
                    data.lzDstChainId,
                    data.approval,
                    data.sendOptions
                );
            } else if (_action == TOFT_SEND_AND_BORROW) {
                TOFTSendAndBorrowData memory data = abi.decode(
                    _actionCalldata,
                    (TOFTSendAndBorrowData)
                );

                ITOFTOperations(data.target).sendToYBAndBorrow{
                    value: data.value
                }(
                    msg.sender,
                    data.to,
                    data.amount,
                    data.borrowAmount,
                    data.marketHelper,
                    data.market,
                    data.lzDstChainId,
                    data.withdrawLzFeeAmount,
                    data.sendOptions
                );
            } else {
                revert("Magnetar: action not valid");
            }
        }

        require(msg.value == valAccumulator, "Magnetar: value mismatch");
    }

    // ********************** //
    // *** VIEW FUNCTIONS *** //
    // ********************** //
    /// @notice Returns the block hash for the given block number
    /// @param blockNumber The block number
    function getBlockHash(
        uint256 blockNumber
    ) public view returns (bytes32 blockHash) {
        blockHash = blockhash(blockNumber);
    }

    /// @notice Returns the block number
    function getBlockNumber() public view returns (uint256 blockNumber) {
        blockNumber = block.number;
    }

    /// @notice Returns the block coinbase
    function getCurrentBlockCoinbase() public view returns (address coinbase) {
        coinbase = block.coinbase;
    }

    /// @notice Returns the block difficulty
    function getCurrentBlockDifficulty()
        public
        view
        returns (uint256 difficulty)
    {
        difficulty = block.prevrandao;
    }

    /// @notice Returns the block gas limit
    function getCurrentBlockGasLimit() public view returns (uint256 gaslimit) {
        gaslimit = block.gaslimit;
    }

    /// @notice Returns the block timestamp
    function getCurrentBlockTimestamp()
        public
        view
        returns (uint256 timestamp)
    {
        timestamp = block.timestamp;
    }

    /// @notice Returns the (ETH) balance of a given address
    function getEthBalance(address addr) public view returns (uint256 balance) {
        balance = addr.balance;
    }

    /// @notice Returns the block hash of the last block
    function getLastBlockHash() public view returns (bytes32 blockHash) {
        unchecked {
            blockHash = blockhash(block.number - 1);
        }
    }

    /// @notice Gets the base fee of the given block
    /// @notice Can revert if the BASEFEE opcode is not implemented by the given chain
    function getBasefee() public view returns (uint256 basefee) {
        basefee = block.basefee;
    }

    /// @notice Returns the chain id
    function getChainId() public view returns (uint256 chainid) {
        chainid = block.chainid;
    }

    // ************************* //
    // *** PRIVATE FUNCTIONS *** //
    // ************************* //
    function _permit(bytes memory actionCalldata, bool permitAll) private {
        PermitData memory permitData = abi.decode(actionCalldata, (PermitData));

        if (!permitAll) {
            IPermit(permitData.target).permit(
                msg.sender,
                permitData.spender,
                permitData.value,
                permitData.deadline,
                permitData.v,
                permitData.r,
                permitData.s
            );
        } else {
            IPermitAll(permitData.target).permitAll(
                msg.sender,
                permitData.spender,
                permitData.deadline,
                permitData.v,
                permitData.r,
                permitData.s
            );
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "../../interfaces/ISendFrom.sol";

interface IPermit {
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

interface IPermitAll {
    function permitAll(
        address owner,
        address spender,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

interface ITOFTOperations {
    function wrap(
        address _fromAddress,
        address _toAddress,
        uint256 _amount
    ) external;

    function wrapNative(address _toAddress) external payable;

    struct SendOptions {
        uint256 extraGasLimit;
        address zroPaymentAddress;
        bool strategyDeposit;
        bool wrap;
    }

    struct IApproval {
        address target;
        address owner;
        address spender;
        uint256 value;
        uint256 deadline;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    function sendApproval(
        uint16 lzDstChainId,
        IApproval calldata approval,
        SendOptions calldata options
    ) external payable;

    function sendToYBAndBorrow(
        address _from,
        address _to,
        uint256 amount,
        uint256 borrowAmount,
        address _marketHelper,
        address _market,
        uint16 lzDstChainId,
        uint256 withdrawLzFeeAmount,
        SendOptions calldata options
    ) external payable;
}

interface IDepositAsset {
    function depositAsset(
        uint256 assetId,
        address from,
        address to,
        uint256 amount,
        uint256 share
    ) external returns (uint256 amountOut, uint256 shareOut);
}

interface ISingularityOperations {
    function addCollateral(
        address from,
        address to,
        bool skim,
        uint256 share
    ) external;

    function borrow(
        address from,
        address to,
        uint256 amount
    ) external returns (uint256 part, uint256 share);

    function withdrawTo(
        address from,
        uint16 dstChainId,
        bytes32 receiver,
        uint256 amount,
        bytes calldata adapterParams,
        address payable refundAddress
    ) external payable;

    function addAsset(
        address from,
        address to,
        bool skim,
        uint256 share
    ) external returns (uint256 fraction);

    function repay(
        address from,
        address to,
        bool skim,
        uint256 part
    ) external returns (uint256 amount);
}

contract MagnetarData {
    // ************ //
    // *** VARS *** //
    // ************ //

    //TODO: decide on uint size after all operations
    uint32 internal constant PERMIT_ALL = 1;
    uint32 internal constant PERMIT = 2;
    uint32 internal constant YB_DEPOSIT_ASSET = 3;
    uint32 internal constant SGL_ADD_COLLATERAL = 4;
    uint32 internal constant SGL_BORROW = 5;
    uint32 internal constant SGL_WITHDRAW_TO = 6;
    uint32 internal constant SGL_LEND = 7;
    uint32 internal constant SGL_REPAY = 8;
    uint32 internal constant TOFT_WRAP = 9;
    uint32 internal constant TOFT_SEND_FROM = 10;
    uint32 internal constant TOFT_SEND_APPROVAL = 11;
    uint32 internal constant TOFT_SEND_AND_BORROW = 12;

    struct Result {
        bool success;
        bytes returnData;
    }

    struct PermitData {
        address target;
        address spender;
        uint256 value;
        uint256 deadline;
        uint8 v;
        bytes32 r;
        bytes32 s;
        bool isPermitAll;
    }

    struct WrapData {
        address target;
        address to;
        uint256 value;
        bool isNative;
    }

    struct SendApprovalData {
        address target;
        uint256 value;
        uint16 lzDstChainId;
        ITOFTOperations.IApproval approval;
        ITOFTOperations.SendOptions sendOptions;
    }

    struct TOFTSendAndBorrowData {
        address target;
        uint256 value;
        address to;
        uint256 amount;
        uint256 borrowAmount;
        address marketHelper;
        address market;
        uint16 lzDstChainId;
        uint256 withdrawLzFeeAmount;
        ITOFTOperations.SendOptions sendOptions;
    }

    struct SendFromData {
        address target;
        bytes32 to;
        uint16 dstChainId;
        uint256 amount;
        ISendFrom.LzCallParams callParams;
        uint256 value;
    }

    struct YieldBoxDepositData {
        address target;
        address to;
        uint256 amount;
        uint256 share;
        uint256 assetId;
    }

    struct SGLAddCollateralData {
        address target;
        address to;
        bool skim;
        uint256 share;
    }

    struct SGLBorrowData {
        address target;
        address to;
        uint256 amount;
    }

    struct SGLWithdrawToData {
        address target;
        uint16 dstChainId;
        bytes32 receiver;
        uint256 amount;
        bytes adapterParams;
        address payable refundAddress;
    }

    struct SGLLendData {
        address target;
        address to;
        bool skim;
        uint256 share;
    }

    struct SGLRepayData {
        address target;
        address to;
        bool skim;
        uint256 part;
    }
}