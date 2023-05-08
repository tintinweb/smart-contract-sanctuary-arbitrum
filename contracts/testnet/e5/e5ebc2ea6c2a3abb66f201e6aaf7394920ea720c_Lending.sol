// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.7.0 <0.9.0;

contract Lending {
    address public owner = msg.sender;
    uint public min_ir = 100;
    uint public max_ir = 200;
    uint public penalty_ir = 1; 
    uint public penalty_days = 30;
    uint public cycle = 31 days;
    uint public deadline = 36 days;
    uint public commission_rate = 10;
    uint public curr_order_sn;
    uint public curr_receipt_sn;

    mapping (address => uint) public balances;
    
    struct Collateral {
        address source;
        address token;
        uint frozen;
        uint amount;
        uint status;
    }
    mapping (address => mapping(uint => mapping (uint => Collateral))) public userCollaterals;
    
    struct LoanReceipt {
        address borrower;
        address lender;
        uint chainid;
        uint c_sn;
        uint amount;
        uint time;
        uint rate;
    }
    mapping (uint => LoanReceipt) public loanReceipts;
    mapping (address => uint[]) public lenderItems;
    mapping (uint => mapping(address => uint[])) public sourceItems;

    struct Order {
        address lender;
        uint balance;
        uint rate;
    }
    mapping (uint => Order) public orders;
    uint[] public orderIDs;
    mapping (address => uint[]) public lenderOrders;

    event PlaceOrder(address lender, uint order_sn, uint balance, uint rate);
    event CancelOrder(address lender, uint order_sn, uint balance);
    event BorrowSuccess(address borrower, uint receipt_sn, uint amount, uint time, uint rate, address lender, uint order_sn, uint order_balance, uint chainid, uint c_sn);
    event BorrowIncomplete(address borrower, uint amount, uint chainid, uint c_sn);
    event RepaySuccess(address borrower, uint receipt_sn, uint amount, address lender, uint income, uint changed_order, uint order_balance, uint chainid, uint c_sn, address source, uint c_frozen);
    event StartLiquidation(address lender, uint receipt_sn, address borrower, uint chainid, uint c_sn, address source, uint c_frozen, address receiver);
    event Deposit(address user, uint amount, uint balance);
    event Withdraw(address user, uint amount, uint balance);

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function borrow(address borrower, uint chainid, uint c_sn, address source, address token, uint frozen, uint amount, uint order_sn, uint[] calldata candidate_orders) external onlyOwner {
        require(userCollaterals[borrower][chainid][c_sn].status == 0);
        require(amount > 0);
        userCollaterals[borrower][chainid][c_sn] = Collateral({
            source: source,
            token: token,
            frozen: frozen,
            amount: amount,
            status: 1
        });

        uint final_order_sn = 0;
        if (orders[order_sn].balance >= amount) {
            final_order_sn = order_sn;
        } else {
            for (uint i = 0; i < candidate_orders.length; i++) {
                uint sn = candidate_orders[i];
                if (orders[sn].balance >= amount) {
                    final_order_sn = sn;
                    break;
                }
            }
            if (final_order_sn == 0) {
                emit BorrowIncomplete(borrower, amount, chainid, c_sn);
                return;
            }
        }
        Order storage order = orders[final_order_sn];

        userCollaterals[borrower][chainid][c_sn].status = 2;
        curr_receipt_sn++;
        loanReceipts[curr_receipt_sn] = LoanReceipt({
            borrower: borrower,
            lender: order.lender,
            chainid: chainid,
            c_sn: c_sn,
            amount: amount,
            time: block.timestamp,
            rate: order.rate
        });
        sourceItems[chainid][source].push(curr_receipt_sn);
        lenderItems[order.lender].push(curr_receipt_sn);         
        
        order.balance -= amount;
        uint order_balance = order.balance;
        uint rate = order.rate;
        address lender = order.lender;
        if (order.balance == 0) {
            delete orders[final_order_sn];
            for (uint i = 0; i < orderIDs.length; i++) {
                if (orderIDs[i] == final_order_sn) {
                    delete orderIDs[i];
                    orderIDs[i] = orderIDs[orderIDs.length - 1];
                    orderIDs.pop();
                }
            }
            uint[] storage ids = lenderOrders[lender];
            for (uint i = 0; i < ids.length; i++) {
                if (ids[i] == final_order_sn) {
                    delete ids[i];
                    ids[i] = ids[ids.length - 1];
                    ids.pop();
                }
            }
        }
      
        (bool success, ) = borrower.call{value: amount}("");
        require(success);
        emit BorrowSuccess(borrower, curr_receipt_sn, amount, block.timestamp, rate, lender, final_order_sn, order_balance, chainid, c_sn);
    }

    function placeOrder(uint amount, uint rate) external {
        require(balances[msg.sender] >= amount, "InsufficientBalance");
        require(rate >= min_ir && rate <= max_ir, "IllegalInterestRate");
        
        curr_order_sn++;
        balances[msg.sender] -= amount;
        orders[curr_order_sn] = Order({
            lender: msg.sender,
            balance: amount,
            rate: rate
        });
        orderIDs.push(curr_order_sn);
        lenderOrders[msg.sender].push(curr_order_sn);

        emit PlaceOrder(msg.sender, curr_order_sn, amount, rate);
    }

    function cancelOrder(uint order_sn) external {
        require(orders[order_sn].lender == msg.sender, "NoOrderFound");
        uint amount = orders[order_sn].balance;
        balances[msg.sender] += amount;
        delete orders[order_sn];

        for (uint i = 0; i < orderIDs.length; i++) {
            if (orderIDs[i] == order_sn) {
                delete orderIDs[i];
                orderIDs[i] = orderIDs[orderIDs.length - 1];
                orderIDs.pop();
            }
        }
        uint[] storage ids = lenderOrders[msg.sender];
        for (uint i = 0; i < ids.length; i++) {
            if (ids[i] == order_sn) {
                delete ids[i];
                ids[i] = ids[ids.length - 1];
                ids.pop();
            }
        }
        emit CancelOrder(msg.sender, order_sn, amount);
    }

    function repay(uint receipt_sn) external payable {
        LoanReceipt memory receipt = loanReceipts[receipt_sn];
        require(receipt.borrower == msg.sender, "NoReceiptFound");

        uint amount = receipt.amount + (receipt.amount * receipt.rate) / 10000;
        if (block.timestamp > receipt.time + cycle) {
            uint overdue_days = (block.timestamp - receipt.time - cycle) / 1 days + 1;
            if (overdue_days > penalty_days) overdue_days = penalty_days;
            amount += (receipt.amount * penalty_ir) / 1000 * overdue_days;
        }
        require(msg.value >= amount, "InsufficientRepayment");
        uint commission = (msg.value - receipt.amount) * commission_rate / 100;

        Collateral storage collateral = userCollaterals[msg.sender][receipt.chainid][receipt.c_sn];
        collateral.status = 3;
        uint[] storage items = sourceItems[receipt.chainid][collateral.source];
        for (uint i = 0; i < items.length; i++) {
            if (items[i] == receipt_sn) {
                delete items[i];
                items[i] = items[items.length - 1];
                items.pop();
            }
        }   
        uint[] storage lender_items = lenderItems[receipt.lender];
        for (uint i = 0; i < lender_items.length; i++) {
            if (lender_items[i] == receipt_sn) {
                delete lender_items[i];
                lender_items[i] = lender_items[lender_items.length - 1];
                lender_items.pop();
            }
        }      
        delete loanReceipts[receipt_sn];
        
        balances[owner] += commission;
        uint income = msg.value - commission;
        uint[] storage order_ids = lenderOrders[receipt.lender];
        uint latest_order = 0;
        uint order_balance = 0;
        for (uint i = 0; i < order_ids.length; i++) {
            if (order_ids[i] > latest_order) {
                latest_order = order_ids[i];
            }
        }
        if (latest_order > 0) {
            orders[latest_order].balance += income;
            order_balance = orders[latest_order].balance;
        } else {
            balances[receipt.lender] += income;
        }

        emit RepaySuccess(msg.sender, receipt_sn, msg.value, receipt.lender, income, latest_order, order_balance, receipt.chainid, receipt.c_sn, collateral.source, collateral.frozen);
    }

    function liquidate(uint receipt_sn, address receiver) external {
        LoanReceipt memory receipt = loanReceipts[receipt_sn];
        require(receipt.lender == msg.sender, "NoReceiptFound");
        require(block.timestamp > receipt.time + deadline, "DeadlineNotMeet");

        Collateral storage collateral = userCollaterals[receipt.borrower][receipt.chainid][receipt.c_sn];
        collateral.status = 4;
        uint[] storage items = sourceItems[receipt.chainid][collateral.source];
        for (uint i = 0; i < items.length; i++) {
            if (items[i] == receipt_sn) {
                delete items[i];
                items[i] = items[items.length - 1];
                items.pop();
            }
        }   
        uint[] storage lender_items = lenderItems[msg.sender];
        for (uint i = 0; i < lender_items.length; i++) {
            if (lender_items[i] == receipt_sn) {
                delete lender_items[i];
                lender_items[i] = lender_items[lender_items.length - 1];
                lender_items.pop();
            }
        }             
        delete loanReceipts[receipt_sn];

        emit StartLiquidation(msg.sender, receipt_sn, receipt.borrower, receipt.chainid, receipt.c_sn, collateral.source, collateral.frozen, receiver);
    }

    function deposit() external payable {
        require(msg.value > 0);
        balances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value, balances[msg.sender]);
    }

    function withdraw(uint amount) external {
        require(balances[msg.sender] >= amount, "InsufficientBalance");
        balances[msg.sender] -= amount;
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success);
        emit Withdraw(msg.sender, amount, balances[msg.sender]);
    }

    function configure(
        uint min_ir_,
        uint max_ir_,
        uint penalty_ir_,
        uint penalty_days_,
        uint cycle_,
        uint deadline_,
        uint commission_rate_
    ) external onlyOwner {
        min_ir = min_ir_;
        max_ir = max_ir_;
        penalty_ir = penalty_ir_;
        penalty_days = penalty_days_;
        cycle = cycle_;
        deadline = deadline_;
        commission_rate = commission_rate_;
    }

    struct ReceiptView {
        uint receipt_sn;
        address borrower;
        uint amount;
        uint time;
        uint rate;
        uint c_sn;
        address c_token;
        uint c_frozen;
    }

    function getReceiptsBySource(uint chainid, address source) external view returns (ReceiptView[] memory) {
        uint[] storage items = sourceItems[chainid][source];
        ReceiptView[] memory receipts = new ReceiptView[](items.length);
        for (uint i = 0; i < items.length; i++) {
            LoanReceipt storage receipt = loanReceipts[items[i]];
            Collateral storage collateral = userCollaterals[receipt.borrower][chainid][receipt.c_sn];
            receipts[i] = ReceiptView({
                receipt_sn: items[i],
                borrower: receipt.borrower,
                amount: receipt.amount,
                time: receipt.time,
                rate: receipt.rate,
                c_sn: receipt.c_sn,
                c_token: collateral.token,
                c_frozen: collateral.frozen
            });
        }
        return receipts;
    }

    function getReceiptsByLender(address lender) external view returns (ReceiptView[] memory) {
        uint[] storage items = lenderItems[lender];
        ReceiptView[] memory receipts = new ReceiptView[](items.length);
        for (uint i = 0; i < items.length; i++) {
            LoanReceipt storage receipt = loanReceipts[items[i]];
            Collateral storage collateral = userCollaterals[receipt.borrower][receipt.chainid][receipt.c_sn];
            receipts[i] = ReceiptView({
                receipt_sn: items[i],
                borrower: receipt.borrower,
                amount: receipt.amount,
                time: receipt.time,
                rate: receipt.rate,
                c_sn: receipt.c_sn,
                c_token: collateral.token,
                c_frozen: collateral.frozen
            });
        }
        return receipts;
    }

    struct OrderView {
        uint order_sn;
        address lender;
        uint balance;
        uint rate;
    }
    function getAllOrders() external view returns (OrderView[] memory) {
        OrderView[] memory allOrders = new OrderView[](orderIDs.length);
        for (uint i = 0; i < orderIDs.length; i++) {
            uint order_sn = orderIDs[i];
            Order storage order = orders[order_sn];
            allOrders[i] = OrderView({
                order_sn: order_sn,
                lender: order.lender,
                balance: order.balance,
                rate: order.rate
            });
        }
        return allOrders;
    }

    struct LenderOrderView {
        uint order_sn;
        uint balance;
        uint rate;
    }
    function getOrdersByLender(address lender) external view returns (LenderOrderView[] memory) {
        uint[] storage ids = lenderOrders[lender];
        LenderOrderView[] memory views = new LenderOrderView[](ids.length);
        for (uint i = 0; i < ids.length; i++) {
            Order storage order = orders[ids[i]];
            views[i] = LenderOrderView({
                order_sn: ids[i],
                balance: order.balance,
                rate: order.rate
            });
        }
        return views;
    }

    function reborrow(uint order_sn, uint amount, uint chainid, uint c_sn) external {
        require(amount > 0);
        Collateral storage collateral = userCollaterals[msg.sender][chainid][c_sn];
        require(collateral.status == 1 && collateral.amount == amount, "NoCollateralFound");
        Order storage order = orders[order_sn];
        require(order.balance >= amount, "InsufficientLendable");

        collateral.status = 2;
        curr_receipt_sn++;
        loanReceipts[curr_receipt_sn] = LoanReceipt({
            borrower: msg.sender,
            lender: order.lender,
            chainid: chainid,
            c_sn: c_sn,
            amount: amount,
            time: block.timestamp,
            rate: order.rate
        });
        sourceItems[chainid][collateral.source].push(curr_receipt_sn);
        lenderItems[order.lender].push(curr_receipt_sn);         
        
        order.balance -= amount;
        uint balance = order.balance;
        uint rate = order.rate;
        address lender = order.lender;
        if (order.balance == 0) {
            delete orders[order_sn];
            for (uint i = 0; i < orderIDs.length; i++) {
                if (orderIDs[i] == order_sn) {
                    delete orderIDs[i];
                    orderIDs[i] = orderIDs[orderIDs.length - 1];
                    orderIDs.pop();
                }
            }
            uint[] storage ids = lenderOrders[lender];
            for (uint i = 0; i < ids.length; i++) {
                if (ids[i] == order_sn) {
                    delete ids[i];
                    ids[i] = ids[ids.length - 1];
                    ids.pop();
                }
            }
        }
                
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success);
        emit BorrowSuccess(msg.sender, curr_receipt_sn, amount, block.timestamp, rate, lender, order_sn, balance, chainid, c_sn);
    }
}