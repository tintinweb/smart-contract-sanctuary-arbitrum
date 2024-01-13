// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

// This line imports the NonblockingLzApp contract from LayerZero's solidity-examples Github repo.
import "../lzApp/NonblockingLzApp.sol";
import "../interfaces/IMultichain.sol";
import "../util/IERC20_.sol";
import "./ReentrancyGuard.sol";

// This contract is inheritting from the NonblockingLzApp contract.
contract Spoke is NonblockingLzApp, Multi, ReentrancyGuard {

  //Orderbook (chain_id,source_token,destination_token)
  mapping(uint => mapping (address => mapping( address => Pair ))) internal book;

  //PUBLIC Variables
  uint16                    public lzc;
  mapping (uint16 => address)      public spokes;
  address public dao_address;

  //Variables used inside the contract
  uint                      public epochspan=240; //4 minutes
  uint                      public MARGIN_BPS=10; //10 basis point margin. $1 per $1000 order
  uint                      public max_epochs=5; //After 5 epochs on the book, taker orders will be refunded. 
  uint                      public fee=1; //1 basis point

  uint                      constant MAXBPS  = 1e4;
  uint                      constant MINGAS=1e7 gwei;
  uint                      constant max_orders=20;
  uint                      constant gasForDestinationLzReceive = 1500000;


  //Constructor
  constructor (address _lzEndpoint, uint16 _lzc) NonblockingLzApp(_lzEndpoint) { 
    lzc = _lzc;
    dao_address=msg.sender;
  }



  //1.1 -- placeTaker
  event OrderPlaced(address indexed sell_token, address indexed buy_token, uint lz_cid, address sender, uint amount);

  function placeTaker(address sell_token, address buy_token, uint lz_cid, uint96 _quantity) public nonReentrant {
    /*
    Public function for users to place Taker orders
    */
      uint96 magnitude = uint96(10**(decimals(sell_token)));
      uint8 decimal = decimals(sell_token);

      require(transferFrom(sell_token, msg.sender, _quantity), "!transfer");
      require(_quantity >= magnitude, "!minOrder");
      require(spokes[uint16(lz_cid)]!=address(0), "!VoidDestChain"); //Issue 3.5

      Pair storage selected_pair=book[lz_cid][sell_token][buy_token];

      if (selected_pair.decimal==0) {
          selected_pair.decimal=decimal;
      }

      uint24 taker_tail=selected_pair.index.taker_tail;

      Order memory newOrder = Order({
          sender: msg.sender,
          amount: (_quantity/magnitude),
          prev: taker_tail,
          next:uint24(selected_pair.taker_orders.length)+1,
          epoch: selected_pair.epoch,
          balance: 0
          });



      //update the tail
      selected_pair.index.taker_tail=uint24(selected_pair.taker_orders.length);
      
      //require taker orders to be resolved
      require((selected_pair.index.taker_tail-selected_pair.index.taker_head) < max_orders, "!takerStack");

      //push the new order
      selected_pair.taker_orders.push(newOrder);
      emit OrderPlaced(sell_token,buy_token,lz_cid,msg.sender,_quantity);

  }

  //1.2 -- placeMaker
  function placeMaker(address sell_token, address buy_token, uint lz_cid, uint96 _quantity) public nonReentrant {
      uint96 magnitude = uint96(10**(decimals(sell_token)));
      uint8 decimal = decimals(sell_token);
      
      require(transferFrom(sell_token, msg.sender, (_quantity*MARGIN_BPS) / MAXBPS), "!transfer");
      require(_quantity >= magnitude, "!minOrder"); //Issue 3.11
      require(spokes[uint16(lz_cid)]!=address(0), "!VoidDestChain"); //Issue 3.5      

      Pair storage selected_pair=book[lz_cid][sell_token][buy_token];
      if (selected_pair.decimal==0) {
          selected_pair.decimal=decimal;
      }

      uint24 maker_tail=selected_pair.index.maker_tail;

      Order memory newOrder = Order({
          sender: msg.sender,
          amount: (_quantity/magnitude),
          prev:maker_tail,
          next:uint24(selected_pair.maker_orders.length)+1,
          epoch: selected_pair.epoch,
          balance: 0
        });

      selected_pair.index.maker_tail=uint24(selected_pair.maker_orders.length);
      
      //push the new order
      selected_pair.maker_orders.push(newOrder);

      //increment the maker count
      require(selected_pair.mkr_count < max_orders, "!makerStack");

      selected_pair.mkr_count++;

      selected_pair.sums.maker_tracking+=(_quantity/magnitude);

      emit OrderPlaced(sell_token,buy_token,lz_cid,msg.sender,_quantity);
  }



  //1.3 -- deleteMaker
  function delink(address sell_token, address buy_token, uint lz_cid, uint order_index) internal {
    /*
    This function removes orders from the linked list (either takers or makers). It does so by delinking the order associated with the passed order_index.
    For example if there are three orders in the linked list with order_index 0,1,2. To delink the order with index 1, we set the next of 0 to 2 and the prev of 2 to 0.
    In this way, the order will never be reached when traversing through the linked list. 
    */
    uint24 start;
    uint24 end;
    Order[] storage orders;

    Pair storage selected_pair=book[lz_cid][sell_token][buy_token];

    //load maker orders
    orders=selected_pair.maker_orders;
    start=selected_pair.index.maker_head;
    end=selected_pair.index.maker_tail;
    selected_pair.sums.maker_tracking-=orders[order_index].amount;

    //decrement the maker count
    selected_pair.mkr_count-=1;


    //Possibility 1 The order is the very first order in the linked list
    if (order_index==start) {
        //advance the head
        selected_pair.index.maker_head=orders[order_index].next;

    }

    //Possibility 2 The order is the very last order in the linked list
    else if (order_index==end){

        orders[orders[order_index].prev].next=orders[order_index].next;
        //regress the tail
        selected_pair.index.maker_tail=orders[order_index].prev;

    }

    //Possibility 3 (The most common) The order is somewhere in the middle of the linked list. We simply delink it and do not need to adjust the head or tail of the list. 
    else {

        orders[orders[order_index].prev].next=orders[order_index].next;
        orders[orders[order_index].next].prev=orders[order_index].prev;

    }
    
    orders[order_index].amount=0;

  }

  function delete_maker(address sell_token, address buy_token, uint lz_cid, uint maker_index) internal {
      delink(sell_token, buy_token, lz_cid, maker_index);
  }


  //Section 2 View Functions.  

  //2.1
  function getTakers(address sell_token, address buy_token, uint lz_cid) public view returns (OrderEndpoint[] memory active_takers) {
    Pair storage selected_pair=book[lz_cid][sell_token][buy_token];
  
    uint24 start=selected_pair.index.taker_head;

    Order[] storage takers = selected_pair.taker_orders;

    active_takers = new OrderEndpoint[](takers.length);

    uint i=0;
    
    while (start != takers.length) {

        Order memory this_order=takers[start];

        OrderEndpoint memory newOrder = OrderEndpoint({
          index:start,
          sender: this_order.sender,
          amount: this_order.amount*uint96(10**selected_pair.decimal),
          prev:this_order.prev,
          next:this_order.next,
          epoch: this_order.epoch,
          balance: this_order.balance
        });


        active_takers[i]=newOrder;

        start = this_order.next;
        i++;

    }

    assembly { mstore(active_takers, i)}

  }

  //2.2
  function getMakers(address sell_token, address buy_token, uint lz_cid) public view returns (OrderEndpoint[] memory active_makers) {
    Pair storage selected_pair=book[lz_cid][sell_token][buy_token];
    uint24 start=selected_pair.index.maker_head;
    uint24 end=selected_pair.index.maker_tail;

    Order[] storage makers = selected_pair.maker_orders;
    active_makers = new OrderEndpoint[](makers.length);

    uint i=0;
    while(start<=end && start<(makers.length)) {
      Order memory this_order=makers[start];

      OrderEndpoint memory newOrder = OrderEndpoint({
        index:start,
        sender: this_order.sender,
        amount: this_order.amount*uint96(10**selected_pair.decimal),
        prev:this_order.prev,
        next:this_order.next,
        epoch: this_order.epoch,
        balance: this_order.balance
      });

      active_makers[i]=newOrder;

      start = this_order.next;
      i++;
    }

    assembly { mstore(active_makers, i)}

  }


  //2.5
  function canResolve(address sell_token, address buy_token, uint lz_cid) public view returns(bool) {
      Pair storage selected_pair=book[lz_cid][sell_token][buy_token];
      return (!selected_pair.isAwaiting && (block.timestamp-selected_pair.index.timestamp)>=epochspan); //change epoch off by 1
  }
  
  //2.6
  function getEpoch(address sell_token, address buy_token, uint lz_cid) public view returns(uint epoch_result){
      Pair storage selected_pair=book[lz_cid][sell_token][buy_token];
      epoch_result=selected_pair.epoch;
  }

  //2.7
  function getIndex(address sell_token, address buy_token, uint lz_cid) public view returns(Index memory){
      Pair storage selected_pair=book[lz_cid][sell_token][buy_token];
      return (selected_pair.index);
  }

  //2.8
  function getSums(address sell_token, address buy_token, uint lz_cid) public view returns(Sums memory){
      Pair storage selected_pair=book[lz_cid][sell_token][buy_token];
      return (selected_pair.sums);
  }
  
  
  function send_taker_sum(address sell_token, address buy_token, uint lz_cid) internal returns(uint96 taker_sum) {

    /*
      The function iterates through the taker orders of the selected pair stored in the instance and sums them. 

      This function processes all orders up to epoch N which have yet to be paid. 
      
      If a taker order is "too" old we will cancel and refund it here.
      
      Returns:
          taker_sum (uint96): The net quantity of taker demanded on this spoke.
    */

   
    Pair storage selected_pair=book[lz_cid][sell_token][buy_token];
    Order[] storage taker_orders=selected_pair.taker_orders;
    uint24 current_epoch=selected_pair.epoch;

    uint24 current_index=selected_pair.index.taker_head;
    uint24 canceled_index=0;

    while (current_index < taker_orders.length) {
        Order memory temp_order = taker_orders[current_index];
        if (temp_order.epoch+max_epochs < current_epoch) {
            //If this if condition hits...the order is too old. We will refund it.
            transfer(sell_token, temp_order.sender, temp_order.amount*(10**selected_pair.decimal));
            
            //advance the current index
            current_index=temp_order.next;
            canceled_index=current_index;

        }
        else{
            taker_sum += temp_order.amount;
            current_index=temp_order.next;
        }

    }

    //If we did cancel any taker orders get them out of the list by advancing the taker_head;
    if (canceled_index!=0) {
        selected_pair.index.taker_head=canceled_index;
    }
    
    return taker_sum;
  }

  //3.2 
  function get_demands(uint96 taker_sum, uint96 maker_sum, uint96 contra_taker_sum, uint96 contra_maker_sum, uint96 quant_default) public pure returns (uint96 taker_demand, uint96 maker_demand){
        /*.
        A utility function to determine demands given thTis spokes's taker_sum and maker_sum with the contra_spoke's taker_sum and maker_sum.

        Returns:
            uint96 taker_demand: The amount requested by the taker
            uint96 maker_demand The amount requested by the maker

        */


        //Case 1 - When there is more demand on this spoke. (This spoke's takers takers match with contra-makers).
        if (taker_sum > contra_taker_sum){

          taker_sum -= contra_taker_sum;
          
          taker_demand = contra_maker_sum > taker_sum 
              ? contra_taker_sum + (taker_sum - quant_default)
              : contra_taker_sum + (contra_maker_sum - quant_default);

          maker_demand=0;
        }
        
        //Case 2 - When there is more demand on the contra spoke. (This spoke's makers match with contra-takers) 
        else {
          contra_taker_sum -= taker_sum;
          
          taker_demand=taker_sum;
          
          maker_demand = maker_sum > contra_taker_sum  
              ? contra_taker_sum 
              : maker_sum;
        }
  }

  //3.3
  event MakerDefaulted(address indexed sell_token, address indexed buy_token, uint lz_cid, address sender, uint amount, uint index);
  event MakerPulled(address indexed sell_token, address indexed buy_token,  uint lz_cid, address sender, uint amount, uint index);

    function send_orders(address sell_token, address buy_token, uint lz_cid, uint96 quant_default) internal returns(Payout[] memory orders_to_send, uint96 quantity_default) {
        /*
        The function figures out what orders to send to the other spoke for payout.

        It compares the four sums. This spokes's taker_sum and maker_sum against the contra_spoke's taker_sum and maker_sum to answer the following.
        1) Which of our takers should be sent to be paid out?
        2) Which if any of our makers needs to fund? 
        
        ERC-20 funds are pulled from the makers. If a maker doesn't fund, the order is delinked from the list.

        The end results are arranged in a list.

        Returns:
            orders ([]]): A list of orders which will be sent to the opposite spoke, 
            uint96 quantity_default The total amount that makers should have funded for but did not;
        */

        //Initalize the orders to send
        orders_to_send = new Payout[](100);


        //Load the pair and taker orders
        Pair storage selected_pair=book[lz_cid][sell_token][buy_token];
        Order[] storage taker_orders=selected_pair.taker_orders;
        Order[] storage maker_orders=selected_pair.maker_orders;
        
        //Set the local variables these are items that we use to iterate through the linked lists
        LocalVariables memory quantities = LocalVariables(0, 0, 0, 0, 0, 0);
        quantities.i=selected_pair.index.taker_head;
        quantities.i2=selected_pair.index.maker_head;
        (quantities.taker_demand, quantities.maker_demand) = get_demands(selected_pair.sums.taker_sum, selected_pair.sums.maker_sum, selected_pair.sums.contra_taker_sum, selected_pair.sums.contra_maker_sum, quant_default);
        
        uint96 order_amount;
        address order_sender;
        uint24 order_next;

        //match Takers
        while (quantities.taker_demand>0) {
        //load order
        order_amount = taker_orders[quantities.i].amount < quantities.taker_demand ? taker_orders[quantities.i].amount : quantities.taker_demand;
        order_sender=taker_orders[quantities.i].sender;
        order_next=taker_orders[quantities.i].next;
        
        //append order
        Payout memory newPayout = Payout({
                sender: order_sender,
                amount: order_amount,
                maker: false
        });

        orders_to_send[quantities.index]=newPayout;
        quantities.index+=1;
        

        //End Conditions
        if (quantities.taker_demand==order_amount){
            selected_pair.index.taker_capital=order_amount;
            selected_pair.index.taker_sent=quantities.i;
            selected_pair.index.taker_amount=taker_orders[quantities.i].amount;


            if (order_amount==taker_orders[quantities.i].amount){
                quantities.i=order_next;
            }
            else {
                taker_orders[quantities.i].amount-=order_amount;
            }
            quantities.taker_demand=0;
        }
        
        else{
            quantities.i=order_next;
            quantities.taker_demand-=order_amount;
        }
        }

        //match Makers
        while (quantities.maker_demand>0) {
        //load order
        order_amount = maker_orders[quantities.i2].amount < quantities.maker_demand ? maker_orders[quantities.i2].amount : quantities.maker_demand;
        order_sender=maker_orders[quantities.i2].sender;
        order_next=maker_orders[quantities.i2].next;
        
        //Pull the maker order
        bool status=transferFrom(sell_token, order_sender, apply_fee(order_amount,selected_pair.decimal));
        
        //THE MAKER DID FUND
        if (status) { // maker funds

            emit MakerPulled(sell_token, buy_token, lz_cid, order_sender, scale_to_raw(order_amount,selected_pair.decimal), quantities.i2);

            //append order
            Payout memory newPayout = Payout({
                sender: order_sender,
                amount: order_amount,
                maker: true
            });
            
            orders_to_send[quantities.index]=newPayout;
            quantities.index++;

            //Add it to cummulative balance
            maker_orders[quantities.i2].balance += order_amount;
            
        }
        
        //THE MAKER DID NOT FUND
        else {
            emit MakerDefaulted(sell_token, buy_token, lz_cid, order_sender, scale_to_raw(order_amount,selected_pair.decimal), quantities.i2);
            order_sender=sell_token;
            transfer(order_sender, dao_address, (maker_orders[quantities.i2].amount*(10**selected_pair.decimal)*MARGIN_BPS) / MAXBPS);


            quantity_default += order_amount;


            delete_maker(sell_token, buy_token, lz_cid, quantities.i2);

            //Transfer out the seized collateral
            maker_orders[quantities.i2].amount=0;


        }
        quantities.maker_demand -= order_amount;
        quantities.i2 = order_next;

        }

        selected_pair.index.taker_head = quantities.i; // SENT TAKER INDEX
        
        order_next=quantities.index;
        assembly { mstore(orders_to_send, order_next)}
    }



    
    //3.4
    event OrderPaidOut(address indexed sell_token, address indexed buy_token, uint lz_cid, address receiver, uint amount, bool maker);

    function payout_orders(address sell_token, address buy_token, uint16 lz_cid, Payout[] memory orders, uint96 quant_default) internal {
        /*.
        A simple function to payout orders recived as part of the layer-zero payload. 
        */
        Pair storage selected_pair=book[lz_cid][sell_token][buy_token];

        uint order_len = orders.length;

        for (uint i = 1; i <= order_len; i++) {
            Payout memory order = orders[order_len - i];
            if (quant_default == 0) {
                    
                    if (order.maker) {
                        transfer(sell_token, order.sender, order.amount*(10**selected_pair.decimal));
                        emit OrderPaidOut(sell_token, buy_token, lz_cid, order.sender, order.amount*(10**selected_pair.decimal),order.maker);

                    }
                    else {
                        transfer(sell_token, order.sender,apply_fee(order.amount,selected_pair.decimal));
                        emit OrderPaidOut(sell_token, buy_token, lz_cid, order.sender, apply_fee(order.amount,selected_pair.decimal),order.maker);
                    }


            } else if (quant_default > order.amount) {
                    quant_default -= order.amount;
            } else { // order.amount >= quant_default > 0

                    if (order.maker) {
                        transfer(sell_token, order.sender, (order.amount-quant_default)*(10**selected_pair.decimal));
                        emit OrderPaidOut(sell_token, buy_token, lz_cid, order.sender, (order.amount-quant_default)*(10**selected_pair.decimal),order.maker);

                    }
                    else {
                        transfer(sell_token, order.sender,apply_fee(order.amount-quant_default,selected_pair.decimal));
                        emit OrderPaidOut(sell_token, buy_token, lz_cid, order.sender, apply_fee(order.amount-quant_default,selected_pair.decimal),order.maker);
                    }

                    quant_default = 0;
            }
        }
    }



    //3.5
    function roll_taker_orders(address sell_token, address buy_token, uint lz_cid, uint96 quant_default) internal {
        /*
        
        This function is used when this spoke's taker orders were sent to be distributed at the opposite spoke, but some or all opposite spoke's makers failed to fund.

        Starting at the point where we left off after sending orders to the contra-spoke, the function moves backwards in the taker_order list. If needed, it splits the last order by placing a new taker order.

        */

        Pair storage selected_pair=book[lz_cid][sell_token][buy_token];
        Order[] storage taker_orders=selected_pair.taker_orders;
        uint24 current_epoch=selected_pair.epoch;

        uint24 i = selected_pair.index.taker_sent;
        uint24 i2=i;
        uint24 last_index=i;

        bool isSplit;

        Order storage order=taker_orders[i2];
        uint96 sent_capital=selected_pair.index.taker_capital;

        uint96 new_order_amount = 0;
        uint96 qd = quant_default;
        bool roll;



        if (qd>0) {
        if (sent_capital != selected_pair.index.taker_amount) {

            if (qd>sent_capital){
            i=taker_orders[i].prev;
            last_index=i;
            }

            new_order_amount = (qd < sent_capital) ? quant_default : sent_capital;
            qd -= new_order_amount;

            

            order=taker_orders[i];
            isSplit=true;
        }

        while (qd>order.amount){

            roll=true;
            order.epoch=current_epoch;
            qd-=order.amount;

            //go to the prior order
            i=taker_orders[i].prev;
            order=taker_orders[i];

        }

        if (qd>0){
            roll=true;
            order.amount=qd;
            order.epoch=current_epoch;
            qd=0;
        }
        }

        //If the orders need to be rolled, it does so below
        if (roll && taker_orders[last_index].next != taker_orders.length) {


            //set the head
            if (i2==last_index) {
            selected_pair.index.taker_head=taker_orders[i2].next;
            }
            else {
            selected_pair.index.taker_head=i2;
            }

            taker_orders[selected_pair.index.taker_tail].next=i;
            taker_orders[i].prev=selected_pair.index.taker_tail;

            taker_orders[last_index].next=uint24(taker_orders.length);

            //set the head and the tail
            selected_pair.index.taker_tail=last_index;
        }
        else {
        selected_pair.index.taker_head=i;
        }
    
        //If an extra split order is required, it does so below
        if (isSplit) {
        Order memory newOrder = Order({
            sender:  taker_orders[i2].sender,
            amount: new_order_amount,
            prev: selected_pair.index.taker_tail,
            next:uint24(selected_pair.taker_orders.length)+1,
            epoch: selected_pair.epoch,
            balance: 0
        });

        //update the tail
        selected_pair.index.taker_tail=uint24(selected_pair.taker_orders.length);

        //push the new order
        selected_pair.taker_orders.push(newOrder);
        }
    }
    

    //SECTION 4 Send and Receieve
    event Resolved(address indexed sell_token, address indexed buy_token, uint lz_cid, uint epoch);

    function resolve_epoch(address sell_token, address buy_token, uint lz_cid) internal {

        /*
        Core matching logic. Orders are matched; the layer-zero payload is generated; and the state of the pair (sums, epoch, taker_order list) is updated in preperation of the next epoch.   
        */
        
        Pair storage selected_pair=book[lz_cid][sell_token][buy_token];
        uint24 current_epoch=selected_pair.epoch;

        //(N-1) Step 1
        (Payout[] memory orders_to_send, uint96 quantity_default) = send_orders(sell_token, buy_token, lz_cid, 0);
        
        //N Step 2
        uint96 taker_sum=send_taker_sum(sell_token, buy_token, lz_cid);
        uint96 maker_sum=selected_pair.sums.maker_tracking;

        // Create and store things in the payload
        Payload memory newPayload = Payload({
            source: sell_token,
            destination: buy_token,
            lz_cid: uint16(lzc),
            taker_sum: taker_sum,
            maker_sum: maker_sum,
            orders: orders_to_send,
            default_quantity: quantity_default,
            epoch: uint24(current_epoch)
        });

        //Update the epoch
        selected_pair.epoch+=1;

        //Update the sums
        selected_pair.sums.taker_sum=taker_sum;
        selected_pair.sums.maker_sum=maker_sum;

        //Update the reneged makers
        selected_pair.sums.maker_default_quantity=quantity_default;
        
        //uint16 version = 1;
        bytes memory adapterParams = abi.encodePacked(uint16(1), gasForDestinationLzReceive);

        _lzSend(uint16(lz_cid), abi.encode(newPayload), payable(this), address(0x0), adapterParams, address(this).balance);

        emit Resolved(sell_token, buy_token, lz_cid, current_epoch);

    }


    //SECTION 5 -- LAYER-ZERO FUNCTIONS

    // This function is called to send the data string to the destination.
    // It's payable, so that we can use our native gas token to pay for gas fees.
    function send(address sell_token, address buy_token, uint lz_cid) public nonReentrant {
        /*
        Function callable my anyone who wants to resolve orders on a given pair. Control conditions are used to make sure that nessecary information from the contra-spoke are received. 
        */

        //load the pair
        Pair storage selected_pair=book[lz_cid][sell_token][buy_token];
        
        //Require conditions: 1) The pair on this spoke isn't waiting for an inbound layer zero message; 2) Enough time has passed since the last recieved message at this spoke. 
        require(!selected_pair.isAwaiting, "!await lz inbound msg");
        require (block.timestamp - uint(selected_pair.index.timestamp) >= epochspan, "!await timestamp");
        require(address(this).balance >= 2*MINGAS,  "!gasLimit send");

        //RESOLVE THE PAIR
        resolve_epoch(sell_token, buy_token, lz_cid);

        //lopck the contract
        selected_pair.isAwaiting=true;

    }

    event ResponseStatus(bool canResolve, uint24 payload_epoch, uint24 this_spoke_epoch, uint96 this_timestamp);

    // This function is called when data is received. It overrides the equivalent function in the parent contract.
    function _nonblockingLzReceive(uint16, bytes memory, uint64, bytes memory _payload) internal override {
        /*
        Logic to recieve the payload.
        */

        // The LayerZero _payload (message) is decoded
        Payload memory payload  = abi.decode(_payload, (Payload));

        //get our variables
        uint16 lz_cid=payload.lz_cid;
        address sell_token=payload.destination;
        address buy_token=payload.source; 
        
        //load the pair
        Pair storage selected_pair=book[lz_cid][sell_token][buy_token];

        //set timestamp
        selected_pair.index.timestamp=uint96(block.timestamp);

        uint24 current_epoch=uint24(payload.epoch);
        emit ResponseStatus(!selected_pair.isAwaiting, current_epoch, selected_pair.epoch, uint96(block.timestamp));


        uint96 qd=payload.default_quantity;


        //**IF NEEDED: BOUNCE BACK A LZ MESSAGE
        if (!selected_pair.isAwaiting) {
            //RESOLVE THE PAIR
            require(address(this).balance >= MINGAS, "!gasLimit bounce");
            resolve_epoch(sell_token, buy_token, lz_cid);
        }

        //Payout the orders
        payout_orders(sell_token, buy_token, lz_cid, payload.orders, selected_pair.sums.maker_default_quantity);
        
        if (qd>0) {
            roll_taker_orders(sell_token, buy_token, lz_cid, qd);
        }

        //Store new sums
        selected_pair.sums.contra_taker_sum=payload.taker_sum;
        selected_pair.sums.contra_maker_sum=payload.maker_sum;

        //unlock the contract
        selected_pair.isAwaiting=false;

    }

    //SECION 5: Utility Functions
    function setspoke(address _contraspoke, uint16 contra_cid) public onlyOwner {
        /* This function allows the contract owner to designate another contract address to trust.
        It can only be called by the owner due to the "onlyOwner" modifier.
        NOTE: In standard LayerZero contract's, this is done through SetTrustedRemote.
        */
        require(contra_cid!=lzc);
        trustedRemoteLookup[contra_cid] = abi.encodePacked(_contraspoke, address(this));
        spokes[contra_cid]=_contraspoke;
    }

    //TransferFunctions
    function transferFrom (address tkn, address from, uint amt) internal returns (bool s)
    { 
        (s,) = tkn.call(abi.encodeWithSelector(IERC20_.transferFrom.selector, from, address(this), amt)); 
    }

    function transfer (address tkn, address to, uint amt) internal
    {tkn.call(abi.encodeWithSelector(IERC20_.transfer.selector, to, amt));}
    
    function setDaoAddress(address new_address) public onlyOwner {
        dao_address=new_address;
    }

    function decimals (address tkn) public view returns(uint8) {
    IERC20_ token = IERC20_(tkn);
    return token.decimals();
    }

    function apply_fee(uint number, uint decimal) public view returns (uint) {
        // Raise the number to the power of 10**decimals
        uint final_number=number*10**decimal;
        return final_number-fee*(final_number/MAXBPS);
    }

    function scale_to_raw(uint number, uint decimal) public pure returns (uint) {
        // Raise the number to the power of 10**decimals
        uint final_number=number*10**decimal;
        return final_number;
    }

    //Allows owner to claim gas (Used for testing)
    function cash () public onlyOwner { ( bool s, ) = msg.sender.call{value:address(this).balance}(""); }

    receive() external payable {}
    
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.17;

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
    uint256 private constant NOT_ENTERED = 1;
    uint256 private constant ENTERED = 2;

    uint256 private _status;

    /**
     * @dev Unauthorized reentrant call.
     */
    error ReentrancyGuardReentrantCall();

    constructor() {
        _status = NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be NOT_ENTERED
        if (_status == ENTERED) {
            revert ReentrancyGuardReentrantCall();
        }

        // Any calls to nonReentrant after this point will fail
        _status = ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity >=0.4.22 <0.9.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20_ {
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

        
    /*
     Returns the decimals of a given token address.
     */
    function decimals() external view returns (uint8);

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.4.22 <0.9.0;

interface Multi  {

  //1.1 Stardard Orders Struct. If you place a trade on the platform this is how your trade is stored.
  struct Order {
    address sender;
    uint96 amount;
    uint24 prev;
    uint24 next;
    uint24 epoch;
    uint96 balance;
  }

  //1.2 Compact Order Struct for sending layer-zero messages. These order types are stored in memory and paid out on reciept.
  struct Payout {
    address sender;
    uint96 amount;
    bool maker;
   }

  //1.3 Payload is the data strucutre used for transmitting messages cross-chain
  struct Payload {
    address source;
    address destination; 
    uint16 lz_cid;

    uint96 taker_sum;
    uint96 maker_sum;

    Payout[] orders;

    uint96 default_quantity;
    uint24 epoch;
  }

  //1.4 Keeps track of important variables on a pair by pair basis. 
  struct Pair {
    address             source;
    address             destination;
    uint16              lz_cid;

    Order[] taker_orders; //taker order on this spoke
    Order[]  maker_orders; //contra-takers (orders recived from the other spoke)
    
    Index               index;
    Sums                sums;

    uint24              epoch;
    bool              isAwaiting;
    uint24              mkr_count;
    uint8               decimal;
  }

  //1.5 Struct to hold indcies for iterating through maker and taker orders
  struct Index {
    uint24 taker_head;
    uint24 taker_tail;

    uint24 maker_head;
    uint24 maker_tail;

    uint96 taker_capital;
    uint96 taker_amount;
    uint24 taker_sent;

    uint96 timestamp;
  }

  //1.6 Struct to hold sums both for this chain's spoke and "contra" sums from spoke's on other chains.
  struct Sums {
      uint96 taker_sum;
      uint96 maker_sum;
      
      uint96 maker_tracking;
      uint96 maker_default_quantity;

      uint96 contra_taker_sum;
      uint96 contra_maker_sum;
    }

  //1.7 Used to serve orders to front-end users and analytics. Includes the "Index" of the order within the array as well as it's position in the linked list. 
  struct OrderEndpoint {
    uint24 index;
    address sender;
    uint96 amount;
    uint24 prev;
    uint24 next;
    uint24 epoch;
    uint96 balance;
  }
  
  //1.8 Local Variables
  struct LocalVariables {
    uint96 taker_demand;
    uint96 maker_demand;
    uint24 i;
    uint24 j;
    uint24 i2;
    uint24 index;
  }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./LzApp.sol";
import "../util/ExcessivelySafeCall.sol";

/*
 * the default LayerZero messaging behaviour is blocking, i.e. any failed message will block the channel
 * this abstract class try-catch all fail messages and store locally for future retry. hence, non-blocking
 * NOTE: if the srcAddress is not configured properly, it will still block the message pathway from (srcChainId, srcAddress)
 */
abstract contract NonblockingLzApp is LzApp {
    using ExcessivelySafeCall for address;

    constructor(address _endpoint) LzApp(_endpoint) {}

    mapping(uint16 => mapping(bytes => mapping(uint64 => bytes32))) public failedMessages;

    event MessageFailed(uint16 _srcChainId, bytes _srcAddress, uint64 _nonce, bytes _payload, bytes _reason);
    event RetryMessageSuccess(uint16 _srcChainId, bytes _srcAddress, uint64 _nonce, bytes32 _payloadHash);

    // overriding the virtual function in LzReceiver
    function _blockingLzReceive(uint16 _srcChainId, bytes memory _srcAddress, uint64 _nonce, bytes memory _payload) internal virtual override {
        (bool success, bytes memory reason) = address(this).excessivelySafeCall(gasleft(), 150, abi.encodeWithSelector(this.nonblockingLzReceive.selector, _srcChainId, _srcAddress, _nonce, _payload));
        // try-catch all errors/exceptions
        if (!success) {
            _storeFailedMessage(_srcChainId, _srcAddress, _nonce, _payload, reason);
        }
    }

    function _storeFailedMessage(uint16 _srcChainId, bytes memory _srcAddress, uint64 _nonce, bytes memory _payload, bytes memory _reason) internal virtual {
        failedMessages[_srcChainId][_srcAddress][_nonce] = keccak256(_payload);
        emit MessageFailed(_srcChainId, _srcAddress, _nonce, _payload, _reason);
    }

    function nonblockingLzReceive(uint16 _srcChainId, bytes calldata _srcAddress, uint64 _nonce, bytes calldata _payload) public virtual {
        // only internal transaction
        require(_msgSender() == address(this), "NonblockingLzApp: caller must be LzApp");
        _nonblockingLzReceive(_srcChainId, _srcAddress, _nonce, _payload);
    }

    //@notice override this function
    function _nonblockingLzReceive(uint16 _srcChainId, bytes memory _srcAddress, uint64 _nonce, bytes memory _payload) internal virtual;

    function retryMessage(uint16 _srcChainId, bytes calldata _srcAddress, uint64 _nonce, bytes calldata _payload) public payable virtual {
        // assert there is message to retry
        bytes32 payloadHash = failedMessages[_srcChainId][_srcAddress][_nonce];
        require(payloadHash != bytes32(0), "NonblockingLzApp: no stored message");
        require(keccak256(_payload) == payloadHash, "NonblockingLzApp: invalid payload");
        // clear the stored message
        failedMessages[_srcChainId][_srcAddress][_nonce] = bytes32(0);
        // execute the message. revert if it fails again
        _nonblockingLzReceive(_srcChainId, _srcAddress, _nonce, _payload);
        emit RetryMessageSuccess(_srcChainId, _srcAddress, _nonce, payloadHash);
    }
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.7.6;

library ExcessivelySafeCall {
    uint256 constant LOW_28_MASK =
    0x00000000ffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    /// @notice Use when you _really_ really _really_ don't trust the called
    /// contract. This prevents the called contract from causing reversion of
    /// the caller in as many ways as we can.
    /// @dev The main difference between this and a solidity low-level call is
    /// that we limit the number of bytes that the callee can cause to be
    /// copied to caller memory. This prevents stupid things like malicious
    /// contracts returning 10,000,000 bytes causing a local OOG when copying
    /// to memory.
    /// @param _target The address to call
    /// @param _gas The amount of gas to forward to the remote contract
    /// @param _maxCopy The maximum number of bytes of returndata to copy
    /// to memory.
    /// @param _calldata The data to send to the remote contract
    /// @return success and returndata, as `.call()`. Returndata is capped to
    /// `_maxCopy` bytes.
    function excessivelySafeCall(
        address _target,
        uint256 _gas,
        uint16 _maxCopy,
        bytes memory _calldata
    ) internal returns (bool, bytes memory) {
        // set up for assembly call
        uint256 _toCopy;
        bool _success;
        bytes memory _returnData = new bytes(_maxCopy);
        // dispatch message to recipient
        // by assembly calling "handle" function
        // we call via assembly to avoid memcopying a very large returndata
        // returned by a malicious contract
        assembly {
            _success := call(
            _gas, // gas
            _target, // recipient
            0, // ether value
            add(_calldata, 0x20), // inloc
            mload(_calldata), // inlen
            0, // outloc
            0 // outlen
            )
        // limit our copy to 256 bytes
            _toCopy := returndatasize()
            if gt(_toCopy, _maxCopy) {
                _toCopy := _maxCopy
            }
        // Store the length of the copied bytes
            mstore(_returnData, _toCopy)
        // copy the bytes from returndata[0:_toCopy]
            returndatacopy(add(_returnData, 0x20), 0, _toCopy)
        }
        return (_success, _returnData);
    }

    /// @notice Use when you _really_ really _really_ don't trust the called
    /// contract. This prevents the called contract from causing reversion of
    /// the caller in as many ways as we can.
    /// @dev The main difference between this and a solidity low-level call is
    /// that we limit the number of bytes that the callee can cause to be
    /// copied to caller memory. This prevents stupid things like malicious
    /// contracts returning 10,000,000 bytes causing a local OOG when copying
    /// to memory.
    /// @param _target The address to call
    /// @param _gas The amount of gas to forward to the remote contract
    /// @param _maxCopy The maximum number of bytes of returndata to copy
    /// to memory.
    /// @param _calldata The data to send to the remote contract
    /// @return success and returndata, as `.call()`. Returndata is capped to
    /// `_maxCopy` bytes.
    function excessivelySafeStaticCall(
        address _target,
        uint256 _gas,
        uint16 _maxCopy,
        bytes memory _calldata
    ) internal view returns (bool, bytes memory) {
        // set up for assembly call
        uint256 _toCopy;
        bool _success;
        bytes memory _returnData = new bytes(_maxCopy);
        // dispatch message to recipient
        // by assembly calling "handle" function
        // we call via assembly to avoid memcopying a very large returndata
        // returned by a malicious contract
        assembly {
            _success := staticcall(
            _gas, // gas
            _target, // recipient
            add(_calldata, 0x20), // inloc
            mload(_calldata), // inlen
            0, // outloc
            0 // outlen
            )
        // limit our copy to 256 bytes
            _toCopy := returndatasize()
            if gt(_toCopy, _maxCopy) {
                _toCopy := _maxCopy
            }
        // Store the length of the copied bytes
            mstore(_returnData, _toCopy)
        // copy the bytes from returndata[0:_toCopy]
            returndatacopy(add(_returnData, 0x20), 0, _toCopy)
        }
        return (_success, _returnData);
    }

    /**
     * @notice Swaps function selectors in encoded contract calls
     * @dev Allows reuse of encoded calldata for functions with identical
     * argument types but different names. It simply swaps out the first 4 bytes
     * for the new selector. This function modifies memory in place, and should
     * only be used with caution.
     * @param _newSelector The new 4-byte selector
     * @param _buf The encoded contract args
     */
    function swapSelector(bytes4 _newSelector, bytes memory _buf)
    internal
    pure
    {
        require(_buf.length >= 4);
        uint256 _mask = LOW_28_MASK;
        assembly {
        // load the first word of
            let _word := mload(add(_buf, 0x20))
        // mask out the top 4 bytes
        // /x
            _word := and(_word, _mask)
            _word := or(_newSelector, _word)
            mstore(add(_buf, 0x20), _word)
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/ILayerZeroReceiver.sol";
import "../interfaces/ILayerZeroUserApplicationConfig.sol";
import "../interfaces/ILayerZeroEndpoint.sol";
import "../util/BytesLib.sol";

/*
 * a generic LzReceiver implementation
 */
abstract contract LzApp is Ownable, ILayerZeroReceiver, ILayerZeroUserApplicationConfig {
    using BytesLib for bytes;

    // ua can not send payload larger than this by default, but it can be changed by the ua owner
    uint constant public DEFAULT_PAYLOAD_SIZE_LIMIT = 10000;

    ILayerZeroEndpoint public immutable lzEndpoint;
    mapping(uint16 => bytes) public trustedRemoteLookup;
    mapping(uint16 => mapping(uint16 => uint)) public minDstGasLookup;
    mapping(uint16 => uint) public payloadSizeLimitLookup;
    address public precrime;

    event SetPrecrime(address precrime);
    event SetTrustedRemote(uint16 _remoteChainId, bytes _path);
    event SetTrustedRemoteAddress(uint16 _remoteChainId, bytes _remoteAddress);
    event SetMinDstGas(uint16 _dstChainId, uint16 _type, uint _minDstGas);

    constructor(address _endpoint) {
        lzEndpoint = ILayerZeroEndpoint(_endpoint);
    }

    function lzReceive(uint16 _srcChainId, bytes calldata _srcAddress, uint64 _nonce, bytes calldata _payload) public virtual override {
        // lzReceive must be called by the endpoint for security
        require(_msgSender() == address(lzEndpoint), "LzApp: invalid endpoint caller");

        bytes memory trustedRemote = trustedRemoteLookup[_srcChainId];
        // if will still block the message pathway from (srcChainId, srcAddress). should not receive message from untrusted remote.
        require(_srcAddress.length == trustedRemote.length && trustedRemote.length > 0 && keccak256(_srcAddress) == keccak256(trustedRemote), "LzApp: invalid source sending contract");

        _blockingLzReceive(_srcChainId, _srcAddress, _nonce, _payload);
    }

    // abstract function - the default behaviour of LayerZero is blocking. See: NonblockingLzApp if you dont need to enforce ordered messaging
    function _blockingLzReceive(uint16 _srcChainId, bytes memory _srcAddress, uint64 _nonce, bytes memory _payload) internal virtual;

    function _lzSend(uint16 _dstChainId, bytes memory _payload, address payable _refundAddress, address _zroPaymentAddress, bytes memory _adapterParams, uint _nativeFee) internal virtual {
        bytes memory trustedRemote = trustedRemoteLookup[_dstChainId];
        require(trustedRemote.length != 0, "LzApp: destination chain is not a trusted source");
        _checkPayloadSize(_dstChainId, _payload.length);
        lzEndpoint.send{value: _nativeFee}(_dstChainId, trustedRemote, _payload, _refundAddress, _zroPaymentAddress, _adapterParams);
    }

    function _checkGasLimit(uint16 _dstChainId, uint16 _type, bytes memory _adapterParams, uint _extraGas) internal view virtual {
        uint providedGasLimit = _getGasLimit(_adapterParams);
        uint minGasLimit = minDstGasLookup[_dstChainId][_type] + _extraGas;
        require(minGasLimit > 0, "LzApp: minGasLimit not set");
        require(providedGasLimit >= minGasLimit, "LzApp: gas limit is too low");
    }

    function _getGasLimit(bytes memory _adapterParams) internal pure virtual returns (uint gasLimit) {
        require(_adapterParams.length >= 34, "LzApp: invalid adapterParams");
        assembly {
            gasLimit := mload(add(_adapterParams, 34))
        }
    }

    function _checkPayloadSize(uint16 _dstChainId, uint _payloadSize) internal view virtual {
        uint payloadSizeLimit = payloadSizeLimitLookup[_dstChainId];
        if (payloadSizeLimit == 0) { // use default if not set
            payloadSizeLimit = DEFAULT_PAYLOAD_SIZE_LIMIT;
        }
        require(_payloadSize <= payloadSizeLimit, "LzApp: payload size is too large");
    }

    //---------------------------UserApplication config----------------------------------------
    function getConfig(uint16 _version, uint16 _chainId, address, uint _configType) external view returns (bytes memory) {
        return lzEndpoint.getConfig(_version, _chainId, address(this), _configType);
    }

    // generic config for LayerZero user Application
    function setConfig(uint16 _version, uint16 _chainId, uint _configType, bytes calldata _config) external override onlyOwner {
        lzEndpoint.setConfig(_version, _chainId, _configType, _config);
    }

    function setSendVersion(uint16 _version) external override onlyOwner {
        lzEndpoint.setSendVersion(_version);
    }

    function setReceiveVersion(uint16 _version) external override onlyOwner {
        lzEndpoint.setReceiveVersion(_version);
    }

    function forceResumeReceive(uint16 _srcChainId, bytes calldata _srcAddress) external override onlyOwner {
        lzEndpoint.forceResumeReceive(_srcChainId, _srcAddress);
    }

    // _path = abi.encodePacked(remoteAddress, localAddress)
    // this function set the trusted path for the cross-chain communication
    function setTrustedRemote(uint16 _remoteChainId, bytes calldata _path) external onlyOwner {
        trustedRemoteLookup[_remoteChainId] = _path;
        emit SetTrustedRemote(_remoteChainId, _path);
    }

    function setTrustedRemoteAddress(uint16 _remoteChainId, bytes calldata _remoteAddress) external onlyOwner {
        trustedRemoteLookup[_remoteChainId] = abi.encodePacked(_remoteAddress, address(this));
        emit SetTrustedRemoteAddress(_remoteChainId, _remoteAddress);
    }

    function getTrustedRemoteAddress(uint16 _remoteChainId) external view returns (bytes memory) {
        bytes memory path = trustedRemoteLookup[_remoteChainId];
        require(path.length != 0, "LzApp: no trusted path record");
        return path.slice(0, path.length - 20); // the last 20 bytes should be address(this)
    }

    function setPrecrime(address _precrime) external onlyOwner {
        precrime = _precrime;
        emit SetPrecrime(_precrime);
    }

    function setMinDstGas(uint16 _dstChainId, uint16 _packetType, uint _minGas) external onlyOwner {
        require(_minGas > 0, "LzApp: invalid minGas");
        minDstGasLookup[_dstChainId][_packetType] = _minGas;
        emit SetMinDstGas(_dstChainId, _packetType, _minGas);
    }

    // if the size is 0, it means default size limit
    function setPayloadSizeLimit(uint16 _dstChainId, uint _size) external onlyOwner {
        payloadSizeLimitLookup[_dstChainId] = _size;
    }

    //--------------------------- VIEW FUNCTION ----------------------------------------
    function isTrustedRemote(uint16 _srcChainId, bytes calldata _srcAddress) external view returns (bool) {
        bytes memory trustedSource = trustedRemoteLookup[_srcChainId];
        return keccak256(trustedSource) == keccak256(_srcAddress);
    }
}

// SPDX-License-Identifier: Unlicense
/*
 * @title Solidity Bytes Arrays Utils
 * @author Gonçalo Sá <[email protected]>
 *
 * @dev Bytes tightly packed arrays utility library for ethereum contracts written in Solidity.
 *      The library lets you concatenate, slice and type cast bytes arrays both in memory and storage.
 */
pragma solidity >=0.8.0 <0.9.0;


library BytesLib {
    function concat(
        bytes memory _preBytes,
        bytes memory _postBytes
    )
    internal
    pure
    returns (bytes memory)
    {
        bytes memory tempBytes;

        assembly {
        // Get a location of some free memory and store it in tempBytes as
        // Solidity does for memory variables.
            tempBytes := mload(0x40)

        // Store the length of the first bytes array at the beginning of
        // the memory for tempBytes.
            let length := mload(_preBytes)
            mstore(tempBytes, length)

        // Maintain a memory counter for the current write location in the
        // temp bytes array by adding the 32 bytes for the array length to
        // the starting location.
            let mc := add(tempBytes, 0x20)
        // Stop copying when the memory counter reaches the length of the
        // first bytes array.
            let end := add(mc, length)

            for {
            // Initialize a copy counter to the start of the _preBytes data,
            // 32 bytes into its memory.
                let cc := add(_preBytes, 0x20)
            } lt(mc, end) {
            // Increase both counters by 32 bytes each iteration.
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
            // Write the _preBytes data into the tempBytes memory 32 bytes
            // at a time.
                mstore(mc, mload(cc))
            }

        // Add the length of _postBytes to the current length of tempBytes
        // and store it as the new length in the first 32 bytes of the
        // tempBytes memory.
            length := mload(_postBytes)
            mstore(tempBytes, add(length, mload(tempBytes)))

        // Move the memory counter back from a multiple of 0x20 to the
        // actual end of the _preBytes data.
            mc := end
        // Stop copying when the memory counter reaches the new combined
        // length of the arrays.
            end := add(mc, length)

            for {
                let cc := add(_postBytes, 0x20)
            } lt(mc, end) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                mstore(mc, mload(cc))
            }

        // Update the free-memory pointer by padding our last write location
        // to 32 bytes: add 31 bytes to the end of tempBytes to move to the
        // next 32 byte block, then round down to the nearest multiple of
        // 32. If the sum of the length of the two arrays is zero then add
        // one before rounding down to leave a blank 32 bytes (the length block with 0).
            mstore(0x40, and(
            add(add(end, iszero(add(length, mload(_preBytes)))), 31),
            not(31) // Round down to the nearest 32 bytes.
            ))
        }

        return tempBytes;
    }

    function concatStorage(bytes storage _preBytes, bytes memory _postBytes) internal {
        assembly {
        // Read the first 32 bytes of _preBytes storage, which is the length
        // of the array. (We don't need to use the offset into the slot
        // because arrays use the entire slot.)
            let fslot := sload(_preBytes.slot)
        // Arrays of 31 bytes or less have an even value in their slot,
        // while longer arrays have an odd value. The actual length is
        // the slot divided by two for odd values, and the lowest order
        // byte divided by two for even values.
        // If the slot is even, bitwise and the slot with 255 and divide by
        // two to get the length. If the slot is odd, bitwise and the slot
        // with -1 and divide by two.
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)
            let newlength := add(slength, mlength)
        // slength can contain both the length and contents of the array
        // if length < 32 bytes so let's prepare for that
        // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
            switch add(lt(slength, 32), lt(newlength, 32))
            case 2 {
            // Since the new array still fits in the slot, we just need to
            // update the contents of the slot.
            // uint256(bytes_storage) = uint256(bytes_storage) + uint256(bytes_memory) + new_length
                sstore(
                _preBytes.slot,
                // all the modifications to the slot are inside this
                // next block
                add(
                // we can just add to the slot contents because the
                // bytes we want to change are the LSBs
                fslot,
                add(
                mul(
                div(
                // load the bytes from memory
                mload(add(_postBytes, 0x20)),
                // zero all bytes to the right
                exp(0x100, sub(32, mlength))
                ),
                // and now shift left the number of bytes to
                // leave space for the length in the slot
                exp(0x100, sub(32, newlength))
                ),
                // increase length by the double of the memory
                // bytes length
                mul(mlength, 2)
                )
                )
                )
            }
            case 1 {
            // The stored value fits in the slot, but the combined value
            // will exceed it.
            // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes.slot)
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

            // save new length
                sstore(_preBytes.slot, add(mul(newlength, 2), 1))

            // The contents of the _postBytes array start 32 bytes into
            // the structure. Our first read should obtain the `submod`
            // bytes that can fit into the unused space in the last word
            // of the stored array. To get this, we read 32 bytes starting
            // from `submod`, so the data we read overlaps with the array
            // contents by `submod` bytes. Masking the lowest-order
            // `submod` bytes allows us to add that value directly to the
            // stored value.

                let submod := sub(32, slength)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(
                sc,
                add(
                and(
                fslot,
                0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00
                ),
                and(mload(mc), mask)
                )
                )

                for {
                    mc := add(mc, 0x20)
                    sc := add(sc, 1)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
            default {
            // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes.slot)
            // Start copying to the last used word of the stored array.
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

            // save new length
                sstore(_preBytes.slot, add(mul(newlength, 2), 1))

            // Copy over the first `submod` bytes of the new data as in
            // case 1 above.
                let slengthmod := mod(slength, 32)
                let mlengthmod := mod(mlength, 32)
                let submod := sub(32, slengthmod)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(sc, add(sload(sc), and(mload(mc), mask)))

                for {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
        }
    }

    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    )
    internal
    pure
    returns (bytes memory)
    {
        require(_length + 31 >= _length, "slice_overflow");
        require(_bytes.length >= _start + _length, "slice_outOfBounds");

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
            // Get a location of some free memory and store it in tempBytes as
            // Solidity does for memory variables.
                tempBytes := mload(0x40)

            // The first word of the slice result is potentially a partial
            // word read from the original array. To read it, we calculate
            // the length of that partial word and start copying that many
            // bytes into the array. The first word we copy will start with
            // data we don't care about, but the last `lengthmod` bytes will
            // land at the beginning of the contents of the new array. When
            // we're done copying, we overwrite the full first word with
            // the actual length of the slice.
                let lengthmod := and(_length, 31)

            // The multiplication in the next line is necessary
            // because when slicing multiples of 32 bytes (lengthmod == 0)
            // the following copy loop was copying the origin's length
            // and then ending prematurely not copying everything it should.
                let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, _length)

                for {
                // The multiplication in the next line has the same exact purpose
                // as the one above.
                    let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, _length)

            //update free-memory pointer
            //allocating the array padded to 32 bytes like the compiler does now
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            //if we want a zero-length slice let's just return a zero-length array
            default {
                tempBytes := mload(0x40)
            //zero out the 32 bytes slice we are about to return
            //we need to do it because Solidity does not garbage collect
                mstore(tempBytes, 0)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }

    function toAddress(bytes memory _bytes, uint256 _start) internal pure returns (address) {
        require(_bytes.length >= _start + 20, "toAddress_outOfBounds");
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }

    function toUint8(bytes memory _bytes, uint256 _start) internal pure returns (uint8) {
        require(_bytes.length >= _start + 1 , "toUint8_outOfBounds");
        uint8 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x1), _start))
        }

        return tempUint;
    }

    function toUint16(bytes memory _bytes, uint256 _start) internal pure returns (uint16) {
        require(_bytes.length >= _start + 2, "toUint16_outOfBounds");
        uint16 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x2), _start))
        }

        return tempUint;
    }

    function toUint32(bytes memory _bytes, uint256 _start) internal pure returns (uint32) {
        require(_bytes.length >= _start + 4, "toUint32_outOfBounds");
        uint32 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x4), _start))
        }

        return tempUint;
    }

    function toUint64(bytes memory _bytes, uint256 _start) internal pure returns (uint64) {
        require(_bytes.length >= _start + 8, "toUint64_outOfBounds");
        uint64 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x8), _start))
        }

        return tempUint;
    }

    function toUint96(bytes memory _bytes, uint256 _start) internal pure returns (uint96) {
        require(_bytes.length >= _start + 12, "toUint96_outOfBounds");
        uint96 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0xc), _start))
        }

        return tempUint;
    }

    function toUint128(bytes memory _bytes, uint256 _start) internal pure returns (uint128) {
        require(_bytes.length >= _start + 16, "toUint128_outOfBounds");
        uint128 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x10), _start))
        }

        return tempUint;
    }

    function toUint256(bytes memory _bytes, uint256 _start) internal pure returns (uint256) {
        require(_bytes.length >= _start + 32, "toUint256_outOfBounds");
        uint256 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x20), _start))
        }

        return tempUint;
    }

    function toBytes32(bytes memory _bytes, uint256 _start) internal pure returns (bytes32) {
        require(_bytes.length >= _start + 32, "toBytes32_outOfBounds");
        bytes32 tempBytes32;

        assembly {
            tempBytes32 := mload(add(add(_bytes, 0x20), _start))
        }

        return tempBytes32;
    }

    function equal(bytes memory _preBytes, bytes memory _postBytes) internal pure returns (bool) {
        bool success = true;

        assembly {
            let length := mload(_preBytes)

        // if lengths don't match the arrays are not equal
            switch eq(length, mload(_postBytes))
            case 1 {
            // cb is a circuit breaker in the for loop since there's
            //  no said feature for inline assembly loops
            // cb = 1 - don't breaker
            // cb = 0 - break
                let cb := 1

                let mc := add(_preBytes, 0x20)
                let end := add(mc, length)

                for {
                    let cc := add(_postBytes, 0x20)
                // the next line is the loop condition:
                // while(uint256(mc < end) + cb == 2)
                } eq(add(lt(mc, end), cb), 2) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                // if any of these checks fails then arrays are not equal
                    if iszero(eq(mload(mc), mload(cc))) {
                    // unsuccess:
                        success := 0
                        cb := 0
                    }
                }
            }
            default {
            // unsuccess:
                success := 0
            }
        }

        return success;
    }

    function equalStorage(
        bytes storage _preBytes,
        bytes memory _postBytes
    )
    internal
    view
    returns (bool)
    {
        bool success = true;

        assembly {
        // we know _preBytes_offset is 0
            let fslot := sload(_preBytes.slot)
        // Decode the length of the stored array like in concatStorage().
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)

        // if lengths don't match the arrays are not equal
            switch eq(slength, mlength)
            case 1 {
            // slength can contain both the length and contents of the array
            // if length < 32 bytes so let's prepare for that
            // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
                if iszero(iszero(slength)) {
                    switch lt(slength, 32)
                    case 1 {
                    // blank the last byte which is the length
                        fslot := mul(div(fslot, 0x100), 0x100)

                        if iszero(eq(fslot, mload(add(_postBytes, 0x20)))) {
                        // unsuccess:
                            success := 0
                        }
                    }
                    default {
                    // cb is a circuit breaker in the for loop since there's
                    //  no said feature for inline assembly loops
                    // cb = 1 - don't breaker
                    // cb = 0 - break
                        let cb := 1

                    // get the keccak hash to get the contents of the array
                        mstore(0x0, _preBytes.slot)
                        let sc := keccak256(0x0, 0x20)

                        let mc := add(_postBytes, 0x20)
                        let end := add(mc, mlength)

                    // the next line is the loop condition:
                    // while(uint256(mc < end) + cb == 2)
                        for {} eq(add(lt(mc, end), cb), 2) {
                            sc := add(sc, 1)
                            mc := add(mc, 0x20)
                        } {
                            if iszero(eq(sload(sc), mload(mc))) {
                            // unsuccess:
                                success := 0
                                cb := 0
                            }
                        }
                    }
                }
            }
            default {
            // unsuccess:
                success := 0
            }
        }

        return success;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

import "./ILayerZeroUserApplicationConfig.sol";

interface ILayerZeroEndpoint is ILayerZeroUserApplicationConfig {
    // @notice send a LayerZero message to the specified address at a LayerZero endpoint.
    // @param _dstChainId - the destination chain identifier
    // @param _destination - the address on destination chain (in bytes). address length/format may vary by chains
    // @param _payload - a custom bytes payload to send to the destination contract
    // @param _refundAddress - if the source transaction is cheaper than the amount of value passed, refund the additional amount to this address
    // @param _zroPaymentAddress - the address of the ZRO token holder who would pay for the transaction
    // @param _adapterParams - parameters for custom functionality. e.g. receive airdropped native gas from the relayer on destination
    function send(uint16 _dstChainId, bytes calldata _destination, bytes calldata _payload, address payable _refundAddress, address _zroPaymentAddress, bytes calldata _adapterParams) external payable;

    // @notice used by the messaging library to publish verified payload
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source contract (as bytes) at the source chain
    // @param _dstAddress - the address on destination chain
    // @param _nonce - the unbound message ordering nonce
    // @param _gasLimit - the gas limit for external contract execution
    // @param _payload - verified payload to send to the destination contract
    function receivePayload(uint16 _srcChainId, bytes calldata _srcAddress, address _dstAddress, uint64 _nonce, uint _gasLimit, bytes calldata _payload) external;

    // @notice get the inboundNonce of a lzApp from a source chain which could be EVM or non-EVM chain
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    function getInboundNonce(uint16 _srcChainId, bytes calldata _srcAddress) external view returns (uint64);

    // @notice get the outboundNonce from this source chain which, consequently, is always an EVM
    // @param _srcAddress - the source chain contract address
    function getOutboundNonce(uint16 _dstChainId, address _srcAddress) external view returns (uint64);

    // @notice gets a quote in source native gas, for the amount that send() requires to pay for message delivery
    // @param _dstChainId - the destination chain identifier
    // @param _userApplication - the user app address on this EVM chain
    // @param _payload - the custom message to send over LayerZero
    // @param _payInZRO - if false, user app pays the protocol fee in native token
    // @param _adapterParam - parameters for the adapter service, e.g. send some dust native token to dstChain
    function estimateFees(uint16 _dstChainId, address _userApplication, bytes calldata _payload, bool _payInZRO, bytes calldata _adapterParam) external view returns (uint nativeFee, uint zroFee);

    // @notice get this Endpoint's immutable source identifier
    function getChainId() external view returns (uint16);

    // @notice the interface to retry failed message on this Endpoint destination
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    // @param _payload - the payload to be retried
    function retryPayload(uint16 _srcChainId, bytes calldata _srcAddress, bytes calldata _payload) external;

    // @notice query if any STORED payload (message blocking) at the endpoint.
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    function hasStoredPayload(uint16 _srcChainId, bytes calldata _srcAddress) external view returns (bool);

    // @notice query if the _libraryAddress is valid for sending msgs.
    // @param _userApplication - the user app address on this EVM chain
    function getSendLibraryAddress(address _userApplication) external view returns (address);

    // @notice query if the _libraryAddress is valid for receiving msgs.
    // @param _userApplication - the user app address on this EVM chain
    function getReceiveLibraryAddress(address _userApplication) external view returns (address);

    // @notice query if the non-reentrancy guard for send() is on
    // @return true if the guard is on. false otherwise
    function isSendingPayload() external view returns (bool);

    // @notice query if the non-reentrancy guard for receive() is on
    // @return true if the guard is on. false otherwise
    function isReceivingPayload() external view returns (bool);

    // @notice get the configuration of the LayerZero messaging library of the specified version
    // @param _version - messaging library version
    // @param _chainId - the chainId for the pending config change
    // @param _userApplication - the contract address of the user application
    // @param _configType - type of configuration. every messaging library has its own convention.
    function getConfig(uint16 _version, uint16 _chainId, address _userApplication, uint _configType) external view returns (bytes memory);

    // @notice get the send() LayerZero messaging library version
    // @param _userApplication - the contract address of the user application
    function getSendVersion(address _userApplication) external view returns (uint16);

    // @notice get the lzReceive() LayerZero messaging library version
    // @param _userApplication - the contract address of the user application
    function getReceiveVersion(address _userApplication) external view returns (uint16);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

interface ILayerZeroUserApplicationConfig {
    // @notice set the configuration of the LayerZero messaging library of the specified version
    // @param _version - messaging library version
    // @param _chainId - the chainId for the pending config change
    // @param _configType - type of configuration. every messaging library has its own convention.
    // @param _config - configuration in the bytes. can encode arbitrary content.
    function setConfig(uint16 _version, uint16 _chainId, uint _configType, bytes calldata _config) external;

    // @notice set the send() LayerZero messaging library version to _version
    // @param _version - new messaging library version
    function setSendVersion(uint16 _version) external;

    // @notice set the lzReceive() LayerZero messaging library version to _version
    // @param _version - new messaging library version
    function setReceiveVersion(uint16 _version) external;

    // @notice Only when the UA needs to resume the message flow in blocking mode and clear the stored payload
    // @param _srcChainId - the chainId of the source chain
    // @param _srcAddress - the contract address of the source contract at the source chain
    function forceResumeReceive(uint16 _srcChainId, bytes calldata _srcAddress) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

interface ILayerZeroReceiver {
    // @notice LayerZero endpoint will invoke this function to deliver the message on the destination
    // @param _srcChainId - the source endpoint identifier
    // @param _srcAddress - the source sending contract address from the source chain
    // @param _nonce - the ordered message nonce
    // @param _payload - the signed payload is the UA bytes has encoded to be sent
    function lzReceive(uint16 _srcChainId, bytes calldata _srcAddress, uint64 _nonce, bytes calldata _payload) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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