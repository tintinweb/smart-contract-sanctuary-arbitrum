// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;
// pragma experimental ABIEncoderV2;



interface IERC20 {
    //需要提前授权
    function transferFrom(address sender, address recipient, uint256 amount) external ;
    function transfer(address _to, uint _value) external ;
    function decimals() external view returns (uint8);
}

interface IMToken is IERC20{
    //需要提前授权
    function settleMint(address account, uint256 amount) external ;
    function settleBurn(uint256 amount) external ;
}



interface PriceOracle {

    function getLastPrice()  external view returns (uint256 price);
    function decimals()  external view returns (uint256 price);
}


library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }


    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }


    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }


    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }


    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }


    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }


    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract Ownable {
    // Owner of the contract
    address private _owner;


    event OwnershipTransferred(address previousOwner, address newOwner);


    constructor() {
        setOwner(msg.sender);
    }


    function owner() external view returns (address) {
        return _owner;
    }


    function setOwner(address newOwner) internal {
        _owner = newOwner;
    }


    modifier onlyOwner() {
        require(msg.sender == _owner, "Ownable: caller is not the owner");
        _;
    }


    function transferOwnership(address newOwner) external onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        setOwner(newOwner);
    }
}

contract OrderBook is Ownable{

    using SafeMath for uint;

    enum Type { LIMIT, MARKET }
    enum Side { BUY, SELL }

    enum Status { NEW, PARTIALLY_FILLED,FILLED,CANCELED,EXPIRED }


    event OrderEvent(address indexed trader, uint256 indexed orderId);

    event CancelEvent(address indexed trader, uint256 indexed orderId);


    address private _trustedForwarder;

    mapping(address => bool) private _settleMans;

    mapping(address => bool) private _withdrawMans;

    address private _withdrawalTargetAddress;

    struct Order {
        address trader;
        Type orderType;
        Side side;
        uint256 price;
        uint256 origQty;
        uint256 origQuoteOrderQty;
        uint256 executedQty;
        uint256 cummulativeQuoteQty;
        uint256 fee;
        uint256 time;
        uint256 updateTime;
        uint256 expireTime;
        Status status;
    }


    Order[] public orderBook;


    string public symbol;
    IMToken public baseAsset;

    IERC20 public quoteAsset;


    uint256 public lotShareNumber;

    uint256 public excessMarginNumerator;
    uint256 public excessMarginDenominator;

    uint256 public minimumPrice;

    constructor(
        string memory tokenSymbol,
        address baseAssetAddress,
        address quoteAssetAddress,
        uint256 lotShare,
        uint256 excessMargin,
        uint256 excessMarginDenomin
    ) {
        symbol = tokenSymbol;
        baseAsset = IMToken(baseAssetAddress);
        quoteAsset = IERC20(quoteAssetAddress);
        lotShareNumber = lotShare;
        excessMarginNumerator = excessMargin;
        excessMarginDenominator = excessMarginDenomin;

    }


    function limitBuy(uint256 price, uint256 amount) public returns (uint256){

        require(price > 0);
        require(amount > 0);
        require(checkAmount(amount));
        require(checkPrice(price));

        uint256 origQuoteOrderQty = lockAmount(price,amount);


        quoteAsset.transferFrom(_msgSender(), address(this), origQuoteOrderQty);

        Order memory order = newOrder(
            Type.LIMIT,
            Side.BUY,
            price,
            amount,
            origQuoteOrderQty);

        orderBook.push(order);

        emit OrderEvent(_msgSender(),orderBook.length - 1);

        return orderBook.length - 1;

    }

    function limitSell(uint price, uint amount) public returns (uint256){
        require(price > 0);
        require(amount > 0);
        require(checkPrice(price));
        baseAsset.transferFrom(_msgSender(), address(this), amount);

        Order memory order = newOrder(
            Type.LIMIT,
            Side.SELL,
            price,
            amount,
            0);

        orderBook.push(order);

        emit OrderEvent(_msgSender(),orderBook.length - 1);

        return orderBook.length - 1;

    }

    function marketSell(uint amount) public returns (uint256) {

        require(amount > 0);

        baseAsset.transferFrom(_msgSender(), address(this), amount);

        Order memory order = newOrder(
            Type.MARKET,
            Side.SELL,
            0,
            amount,
            0);

        orderBook.push(order);

        emit OrderEvent(_msgSender(),orderBook.length - 1);

        return orderBook.length - 1;
    }


    function tryCancel(uint orderId) public {

        require(orderId < orderBook.length);
        require(_msgSender() == orderBook[orderId].trader);

        emit CancelEvent(_msgSender(),orderId);
    }

    function settleOut(uint orderId,uint256 executedQty,uint256 cummulativeQuoteQty,uint256 fee) public onlySettleMans{

        require(orderId >= 0);
        require(executedQty > 0);
        require(cummulativeQuoteQty > 0);
        require(fee > 0);


        Order memory order = getOrder(orderId);

        require(executedQty <= order.origQty);
        require(executedQty > order.executedQty);
        require(cummulativeQuoteQty > order.cummulativeQuoteQty);
        require(fee > order.fee);
        require(order.status != Status.CANCELED && order.status != Status.FILLED);


        uint256 curExecutedQty = order.executedQty;
        uint256 curCummulativeQuoteQty = order.cummulativeQuoteQty;
        uint256 curFee = order.fee;
        order.executedQty = executedQty;
        order.cummulativeQuoteQty = cummulativeQuoteQty;
        order.fee = fee;

        order.status = Status.PARTIALLY_FILLED;

        orderBook[orderId] = order;

        if(Side.BUY == order.side){

            require(order.origQuoteOrderQty.sub(order.cummulativeQuoteQty).sub(order.fee) >= 0);

            uint256 newMint = executedQty.sub(curExecutedQty);
            baseAsset.settleMint(order.trader, newMint);
        }

        if(Side.SELL == order.side){
            uint256 toUserAmount = cummulativeQuoteQty.sub(curCummulativeQuoteQty);

            toUserAmount = toUserAmount.sub(fee.sub(curFee));

            quoteAsset.transfer(order.trader, toUserAmount);

            //burn Mtoken
            uint256 burnAmount = executedQty.sub(curExecutedQty);
            baseAsset.settleBurn(burnAmount);
        }


        if(order.origQty == order.executedQty){
            clearOrder(orderId,Status.FILLED);
        }
    }

    function cancel(uint orderId) public onlySettleMans{
        clearOrder(orderId, Status.CANCELED);
    }

    function clearOrder(uint orderId, Status status) internal{
        require(status == Status.CANCELED || status == Status.FILLED);

        require(orderBook[orderId].status != Status.CANCELED && orderBook[orderId].status != Status.FILLED && orderBook[orderId].status != Status.EXPIRED );

        orderBook[orderId].status = status;



        Order memory order = getOrder(orderId);

        if(Side.SELL == order.side ){
            uint256 restBaseAsset = order.origQty.sub(order.executedQty);
            require(restBaseAsset >= 0);
            if(restBaseAsset > 0){
                baseAsset.transfer(order.trader, restBaseAsset);
            }
        }
        if(Side.BUY == order.side  ){
            uint256 restQuoteAsset = order.origQuoteOrderQty.sub(order.cummulativeQuoteQty).sub(order.fee);
            require(restQuoteAsset >= 0);
            if(restQuoteAsset > 0){
                quoteAsset.transfer(order.trader, restQuoteAsset);
            }

        }


    }


    function getOrder(uint orderId) public view returns (Order memory) {
        return orderBook[orderId];
    }

    function newOrder(Type orderType, Side side,uint256 price, uint256 amount, uint256 origQuoteOrderQty) internal returns (Order memory) {
        Order memory order = Order(
            _msgSender(),
            orderType,
            side,
            price,
            amount,
            origQuoteOrderQty,
            0,
            0,

            0,
            block.timestamp,
            block.timestamp,
            0,
            Status.NEW
        );
        return order;
    }

    function checkAmount(uint amount) public view returns (bool ok) {
        uint lot = amount.div(lotShareNumber);
        return amount == lot.mul(lotShareNumber);
    }

    function checkPrice(uint price) public view returns (bool ok) {
        return price >= minimumPrice;
    }


    function excess(uint amount) public view returns (uint excessAmount) {
        uint excess = amount.mul(excessMarginNumerator).div(excessMarginDenominator);
        return amount.add(excess) ;
    }

    function lockAmount(uint256 price, uint256 amount) public view returns (uint lockAmount) {
        uint256 origQuoteOrderQty = price.mul(amount);
        return excess(origQuoteOrderQty) ;
    }

    function baseDecimal() public view returns (uint8 decimal) {
        return baseAsset.decimals();
    }


    function quoteDecimal() public view returns (uint8 decimal) {
        return quoteAsset.decimals();
    }



    function updateMinimumPrice(uint price)  public onlyOwner{
        minimumPrice = price;
    }

    function updateExcessMarginDenominator(uint updateExcessMarginDenominator)  public onlyOwner{
        excessMarginDenominator = updateExcessMarginDenominator;
    }

    function updateExcessMarginNumerator(uint updateExcessMarginNumerator)  public onlyOwner{
        excessMarginNumerator = updateExcessMarginNumerator;
    }

    function updateLotShareNumber(uint updateLotShareNumber)  public onlyOwner{
        lotShareNumber = updateLotShareNumber;
    }

    function updateBaseAsset(address updateBaseAsset)  public onlyOwner{
        baseAsset = IMToken(updateBaseAsset);
    }
    function updateQuoteAsset(address updateQuoteAsset)  public onlyOwner{
        quoteAsset = IERC20(updateQuoteAsset);
    }

    function updateSymbol(string memory updateSymbol)  public onlyOwner{
        symbol = updateSymbol;
    }

    function setSettleMans(address account, bool _isSettleMans) external onlyOwner {
        _settleMans[account] = _isSettleMans;
        if (_isSettleMans == false)
        {
            delete _settleMans[account];
        }
    }

    function isSettleMans(address account) public view returns(bool) {
        return _settleMans[account];
    }
    modifier onlySettleMans(){
        require(_settleMans[_msgSender()] == true, "Ownable: caller is not the _settleMans");
        _;
    }

    function setWithdrawMans(address account, bool _isWithdrawMans) external onlyOwner {
        _withdrawMans[account] = _isWithdrawMans;
        if (_isWithdrawMans == false)
        {
            delete _withdrawMans[account];
        }
    }

    function isWithdrawMans(address account) public view returns(bool) {
        return _withdrawMans[account];
    }
    modifier onlyWithdrawMans(){
        require(_withdrawMans[_msgSender()] == true, "Ownable: caller is not the _withdrawMans");
        _;
    }


    function setWithdrawalTargetAddress(address targetAddress) external onlyOwner {
        _withdrawalTargetAddress = targetAddress;
    }


    function withdrawalTargetAddress() public view virtual returns (address) {
        return _withdrawalTargetAddress;
    }



    function withdrawQuoteAsset(uint _value)  public onlyWithdrawMans{
        require(_withdrawalTargetAddress != address(0x0), "Ownable: _withdrawalTargetAddress is 0x0");
        quoteAsset.transfer(_withdrawalTargetAddress,_value);
    }



    function setTrustedForwarder(address forwarder) external onlyOwner {
        _trustedForwarder = forwarder;
    }

    /**
     * @dev Returns the address of the trusted forwarder.
     */
    function trustedForwarder() public view virtual returns (address) {
        return _trustedForwarder;
    }

    /**
     * @dev Indicates whether any particular address is the trusted forwarder.
     */
    function isTrustedForwarder(address forwarder) public view virtual returns (bool) {
        return forwarder == trustedForwarder();
    }

    /**
     * @dev Override for `msg.sender`. Defaults to the original `msg.sender` whenever
     * a call is not performed by the trusted forwarder or the calldata length is less than
     * 20 bytes (an address length).
     */
    function _msgSender() internal view   returns (address sender) {
        if (isTrustedForwarder(msg.sender) && msg.data.length >= 20) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            /// @solidity memory-safe-assembly
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return msg.sender;
        }
    }

    /**
     * @dev Override for `msg.data`. Defaults to the original `msg.data` whenever
     * a call is not performed by the trusted forwarder or the calldata length is less than
     * 20 bytes (an address length).
     */
    function _msgData() internal view   returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender) && msg.data.length >= 20) {
            return msg.data[:msg.data.length - 20];
        } else {
            return msg.data;
        }
    }

}