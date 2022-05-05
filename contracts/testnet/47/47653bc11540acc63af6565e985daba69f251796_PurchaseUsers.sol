/**
 *Submitted for verification at Arbiscan on 2022-05-04
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;
//import safeRemotePurchase.sol;
contract PurchaseUsers {

    enum State {Idle, Created, Locked, Release, Inactive, Finished}
    /// For each order
    struct Order {
        address payable seller;
        address payable buyer;
        uint price;
        State state;
    }
    uint public ORDER_NO_;
    mapping(uint => Order) public ORDER_;

    /// Only the buyer can call this function.
    error OnlyBuyer();
    /// Only the seller can call this function.
    error OnlySeller();
    /// The function cannot be called at the current state.
    error InvalidState();
    /// The provided value has to be even.
    error ValueNotEven();
    /// The buyer's pay is not enough
    error PayNotEnough();
    
    /// Set up an item 
    event SetUp(address indexed seller, uint order_no, uint price);
    event Aborted(address indexed seller, uint order_no, uint price);
    event Buy(address indexed buyer, uint order_no, uint price, uint change);
    event ItemReceived(address indexed buyer, address indexed seller, uint order_no, uint price);
    event SellerRefunded(address indexed seller, uint order_no, uint price);

    modifier onlySeller(uint order_no) {
        if (msg.sender != ORDER_[order_no].seller)
            revert OnlySeller();
        _;
    }
    modifier onlyBuyer(uint order_no) {
        if (msg.sender != ORDER_[order_no].buyer)
            revert OnlyBuyer();
        _;
    }
    modifier inState(uint order_no, State state) {
        if (ORDER_[order_no].state != state)
            revert InvalidState();
        _;
    }

    /// Set up an item to sell
    function setUp() external payable {
        if (((msg.value % 2) != 0) || (msg.value == 0))  revert ValueNotEven();
        uint order_no = ORDER_NO_;
        ORDER_[order_no].seller = payable(msg.sender);
        uint price = msg.value / 2;
        ORDER_[order_no].price = price;
        ORDER_[order_no].state = State.Created;
        ORDER_NO_ += 1;
        emit SetUp(msg.sender, order_no, price);
    }
        
    /// Abort the sell before Locked
    function abortSell(
        uint order_no
    ) 
        external
        inState(order_no, State.Created)
        onlySeller(order_no)
    {    
        ORDER_[order_no].state = State.Inactive;
        
        ORDER_[order_no].seller.transfer(ORDER_[order_no].price * 2);
        
        emit Aborted(msg.sender, order_no, ORDER_[order_no].price);
    }

    /// Confirm buy
    function buy(
        uint order_no
    )
        external
        payable
        inState(order_no, State.Created)
    {
        if (msg.value < ORDER_[order_no].price*2 ) revert PayNotEnough();
        ORDER_[order_no].buyer = payable(msg.sender);
        ORDER_[order_no].state = State.Locked;

        payable(msg.sender).transfer(msg.value - ORDER_[order_no].price*2);
        
        emit Buy(msg.sender, order_no, ORDER_[order_no].price, msg.value - ORDER_[order_no].price*2);
    }

    function confirmReceived(
        uint order_no
    )
        external
        inState(order_no, State.Locked)
        onlyBuyer(order_no)
    {
        ORDER_[order_no].state = State.Release;

        ORDER_[order_no].buyer.transfer(ORDER_[order_no].price);

        emit ItemReceived(msg.sender, ORDER_[order_no].seller, order_no, ORDER_[order_no].price);
    }

    function refundSeller(
        uint order_no
    )
        external
        inState(order_no, State.Release)
        onlySeller(order_no)
    {
        ORDER_[order_no].state = State.Finished;

        ORDER_[order_no].seller.transfer(ORDER_[order_no].price * 3);

        emit SellerRefunded(msg.sender, order_no, ORDER_[order_no].price);
    }

}