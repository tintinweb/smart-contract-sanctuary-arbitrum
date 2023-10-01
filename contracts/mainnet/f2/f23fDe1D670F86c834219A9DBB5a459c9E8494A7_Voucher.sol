/**
 *Submitted for verification at Arbiscan.io on 2023-09-28
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.14;


// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeApprove: approve failed'
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeTransfer: transfer failed'
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::transferFrom: transferFrom failed'
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');
    }
}

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 */
contract Cloneable {

    /**
        @dev Deploys and returns the address of a clone of address(this
        Created by DeFi Mark To Allow Clone Contract To Easily Create Clones Of Itself
        Without redundancy
     */
    function clone() external returns(address) {
        return _clone(address(this));
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function _clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

}

interface ICore {
    enum PositionStatus {
        PENDING,
        EXECUTED,
        CANCELED
    }

    enum OrderDirectionType {
        UP,
        DOWN
    }

    struct Counters {
        uint256 ordersCount;
        uint256 positionsCount;
        uint256 totalStableAmount;
    }

    struct Order {
        OrderDescription data;
        address creator;
        uint256 amount;
        uint256 reserved;
        uint256 available;
        bool closed;
    }

    struct OrderDescription {
        address oracle;
        uint256 percent;
        OrderDirectionType direction;
        uint256 rate;
        uint256 duration;
        bool reinvest;
    }

    struct Position {
        uint256 startTime;
        uint256 endTime;
        uint256 startPrice;
        uint256 endPrice;
        uint256 deviationPrice;
        uint256 protocolFee;
        uint256 amountCreator;
        uint256 amountAccepter;
        address winner;
        bool isCreatorWinner;
        PositionStatus status;
    }

    struct Accept {
        uint256 orderId;
        uint256 amount;
    }

    function positionIdToOrderId(uint256) external view returns (uint256);
    function creatorToOrders(address, uint256) external view returns (uint256);
    function orderIdToPositions(uint256, uint256) external view returns (uint256);
    function counters() external view returns (Counters memory);
    function creatorOrdersCount(address creator) external view returns (uint256);
    function orderIdPositionsCount(uint256 orderId) external view returns (uint256);
    function positions(uint256 id) external view returns (Position memory);
    function orders(uint256 id) external view returns (Order memory);
    function availableFeeAmount() external view returns (uint256);
    function permitPeriphery() external view returns (address);

    event Accepted(
        uint256 indexed orderId,
        uint256 indexed positionId,
        Order order,
        Position position,
        uint256 amount
    );
    event OrderCreated(uint256 orderId, Order order);
    event OrderClosed(uint256 orderId, Order order);
    event Flashloan(
        address indexed caller,
        address indexed receiver,
        uint256 amount,
        uint256 fee
    );
    event FeeClaimed(uint256 amount);
    event OrderIncreased(uint256 indexed orderId, uint256 amount);
    event OrderWithdrawal(uint256 indexed orderId, uint256 amount);

    function accept(address accepter, Accept[] memory data) external returns (uint256[] memory positionIds);
    function autoResolve(uint256 positionId, uint256 roundId) external returns (bool);
    function closeOrder(uint256 orderId) external returns (bool);
    function createOrder(address creator, OrderDescription memory data, uint256 amount) external returns (uint256 orderId);
    function flashloan(address recipient, uint256 amount, bytes calldata data) external returns (bool);
    function increaseOrder(uint256 orderId, uint256 amount) external returns (bool);
    function withdrawOrder(uint256 orderId, uint256 amount) external returns (bool);
}


interface IERC20 {

    function totalSupply() external view returns (uint256);
    
    function symbol() external view returns(string memory);
    
    function name() external view returns(string memory);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);
    
    /**
     * @dev Returns the number of decimal places
     */
    function decimals() external view returns (uint8);

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

interface IVoucher {
    function __init__(
        uint8 _tradeType,
        uint256 _spendLimit,
        address _user,
        uint256 roundID_
    ) external;
}

interface ITradeManager {
    function stable() external view returns (address);
    function usedVoucher(uint256 roundId) external;
}

contract VoucherData {

    /**
        Core Foxify Contract
     */
    address public foxify_core;

    /**
        0. Free Trade - owner pays winner if you lose, no money up front
        1. Double Your Trade (up to maximum)
        2. No Loss Trade - trade is refunded to you if you lose, requires money up front
     */
    uint8 public tradeType;

    /**
        Max amount of USDC to spend on trade
     */
    uint256 public spendLimit;

    /**
        User who was gifted the voucher
     */
    address public user;

    /**
        Trade Manager Contract
     */
    address public tradeManager;

    /**
        Stable Address
     */
    address public stable;

    /**
        Has Used This Voucher Already
     */
    bool public hasUsed;

    /**
        Has claimed refund if trade type 2
     */
    bool public hasClaimedRefund;

    /**
        Position ID From Trade
     */
    uint256 public positionId;

    /**
        Round ID For Max Uses
     */
    uint256 public roundID;

}

contract Voucher is IVoucher, VoucherData, Cloneable {

    
    function __init__(
        uint8 _tradeType,
        uint256 _spendLimit,
        address _user,
        uint256 roundID_
    ) external override {
        require(
            user == address(0),
            'Voucher: already initialized'
        );

        // set all of our data
        user = _user;
        tradeType = _tradeType;
        spendLimit = _spendLimit;
        tradeManager = msg.sender;
        stable = ITradeManager(msg.sender).stable();
        hasUsed = false;
        hasClaimedRefund = false;
        roundID = roundID_;
    }

    function withdrawToken(
        address token,
        uint256 amount
    ) external {
        require(
            msg.sender == user,
            'Only User Can Use'
        );
        TransferHelper.safeTransfer(token, user, amount);
    }

    function withdrawETH() external {
        require(
            msg.sender == user,
            'Only User Can Use'
        );
        TransferHelper.safeTransferETH(user, address(this).balance);
    }


    function claimRefund() external {
        require(
            tradeType == 2,
            'Only Works For No Loss Trade'
        );
        require(
            hasClaimedRefund == false,
            'Has Already Claimed Refund'
        );
        require(
            hasUsed == true,
            'Has Not Used Voucher Yet'
        );
        require(
            positionId > 0,
            'Position Not Saved'
        );

        // toggle has claimed refund to true
        hasClaimedRefund = true;

        // make sure the user lost the position
        ICore.Position memory pos = viewPosition();

        // make sure the position has expired
        require(
            pos.endTime <= block.timestamp,
            'Position Has Not Ended'
        );
        require(
            pos.winner != address(0),
            'No Winner Determined Yet'
        );
        require(
            pos.winner != user,
            'The User Won, No Refund Available'
        );

        // transfer the USDC in from the TradeManager
        TransferHelper.safeTransferFrom(stable, tradeManager, user, spendLimit);
    }

    function acceptTrade(
        address _foxify_core,
        uint256 orderId
    ) external {
        require(
            msg.sender == user,
            'Only User Can Use'
        );
        require(
            hasUsed == false,
            'Has Already Used This Voucher'
        );

        // save the foxify core contract
        foxify_core = _foxify_core;

        // toggle hasUsed to true
        hasUsed = true;

        // use voucher in trade manager
        ITradeManager(tradeManager).usedVoucher(roundID);

        // initialize some variables before
        uint256 amountToBet;

        // decide on trade type logic
        if (tradeType == 0) {

            // free trade, both are equal to the spend limit
            amountToBet = spendLimit;

            // transfer the USDC in from the TradeManager
            TransferHelper.safeTransferFrom(
                stable,
                tradeManager,
                address(this),
                spendLimit
            );

        } else if (tradeType == 1) {

            // double trade
            amountToBet = spendLimit * 2;

            // transfer the USDC in from the TradeManager
            TransferHelper.safeTransferFrom(
                stable,
                tradeManager,
                address(this),
                spendLimit
            );

            // transfer the USDC in from the User
            TransferHelper.safeTransferFrom(
                stable,
                user,
                address(this),
                spendLimit
            );

        } else {

            // no loss trade
            amountToBet = spendLimit;

            // transfer the USDC in from the User
            TransferHelper.safeTransferFrom(
                stable,
                user,
                address(this),
                spendLimit
            );

        }

        // Approve of the Foxify Core contract so it can take our money
        TransferHelper.safeApprove(stable, _foxify_core, amountToBet);

        // Build Call Data
        ICore.Accept[] memory acceptData = new ICore.Accept[](1);
        acceptData[0] = ICore.Accept({
            orderId: orderId,
            amount: amountToBet
        });
        
        // call contract on Core
        uint256[] memory positionIds = ICore(_foxify_core).accept(
            address(this),
            acceptData
        );

        // locally save position ID
        positionId = positionIds[0];

    }

    function autoResolve(uint256 roundId) external returns (bool) {
        return ICore(foxify_core).autoResolve(positionId, roundId);
    }

    function viewPosition() public view returns (ICore.Position memory) {
        return ICore(foxify_core).positions(positionId);
    }

    function isRefundAvailable() external view returns (bool) {
        if (tradeType < 2) {
            return false;
        }
        if (hasClaimedRefund || !hasUsed || positionId == 0) {
            return false;
        }

        // make sure the user lost the position
        ICore.Position memory pos = viewPosition();

        // return true if the position has expired and the user lost
        return (
            pos.endTime <= block.timestamp &&
            pos.winner != address(0) &&
            pos.winner != user
        );
    }

    function amountToClaim() external view returns (uint256) {
        return IERC20(stable).balanceOf(address(this));
    }

}