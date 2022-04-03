/**
 *Submitted for verification at Arbiscan on 2022-04-02
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external;
    function balanceOf(address _owner) external;
    function approve(address _spender, uint256 amount) external;
}
interface ArbSys {
     function arbBlockNumber() external returns (uint256);
}

library utils {
    function dec(bytes32 x) internal pure returns (uint64 a,uint64 b, uint64 c, uint64 d) {
        assembly {
            d := x
            mstore(0x18, x)
            a := mload(0)
            mstore(0x10, x)
            b := mload(0)
            mstore(0x8, x)
            c := mload(0)
        }
    }
}



contract metaShop{
    
    uint public saleid;

    address owner;
    address public paymentContract;
    uint public managers;

    uint public dutchEpoch = 10;
    uint public dutchPercent = 3;
    uint public dutchFloor = 50;
    bool public status;

    event promoted(address indexed _manager);
    event demoted(address indexed _manager);
    event purchase(address indexed _buyer, uint indexed _saleid);
    event listing(uint indexed _saleid);

    constructor(address _paymentContract){
        paymentContract = _paymentContract;
        Manager[tx.origin] = true;
        owner = tx.origin;
    }
    struct buys {
        uint saleid;
        string discord;
    }
    struct sales {
        uint supply;
        uint256 price;
        uint sold;
        uint maxWallet;
        uint64 start;
        uint64 end;
        uint8 listType;
        string data;
    }
    mapping(address => string) public Discord;
    mapping(address => bool) public Manager;
    mapping (uint => sales) public Sales;
    mapping(uint => bool) public Delist;
    mapping(uint => address[]) internal Buyers;
    mapping(address=>uint[]) internal Inventory;


    modifier isManager() {
        require(Manager[msg.sender] == true, "not a manager");
        _;
    }

    modifier isOwner(){
        require(msg.sender == owner, "not owner");
        _;
    }
 
    modifier isRaffle(uint _id){
        require(Sales[_id].listType == 2, "not a raffle");
        require(Sales[_id].end < block.timestamp, "raffle is not over");
        _;
    }

    modifier buyCheck(uint _id, uint _amount) {
        uint d = bytes(Discord[msg.sender]).length;
        require(status == true, "shop is currently paused");
        require(Delist[_id]==false,"item has been delisted");
        require(d > 0,"discord not set");
        require(block.timestamp > Sales[_id].start,"sale not open.");
        require(Sales[_id].end > block.timestamp,"sale is closed.");
        require(itemBalance(_id,msg.sender)+_amount<= Sales[_id].maxWallet,"transaction would be over max wallet limit.");
        require(Sales[_id].sold+_amount <= Sales[_id].maxWallet, "transaction would be over supply limit.");
        _;
    }
    //user functions
    function setDiscord(string memory _discord) public {
        Discord[msg.sender] = _discord;
    }
    //

    //functional payables
    function createSale(uint _supply, uint _price, uint _maxWallet, uint64 _starttime, uint64 _endTime,uint8 _type, string memory _data) public isManager {
        sales memory s = sales(_supply,_price,0,_maxWallet,_starttime,_endTime,_type,_data);
        Sales[saleid] = s;
        emit listing(saleid);
        saleid ++;
        
    }

    function buyItem(uint _saleid,uint _amount) public buyCheck(_saleid,_amount) {
        IERC20(paymentContract).transferFrom(msg.sender, address(this),getPrice(_saleid)*_amount);
        
        uint sold;
        for (uint i=0;i<_amount;){
            Inventory[msg.sender].push(_saleid);
            Buyers[_saleid].push(msg.sender);
            sold++;
            unchecked{
               
                i++;
            }
        }
        Sales[_saleid].sold = sold;
    }
    //

    //functional views
    function getRaffleWinner(uint _id) public view isRaffle(_id) returns (address _winner){
        uint _max = Buyers[_id].length;
        (uint64 a,uint64 b, uint64 c, uint64 d) = utils.dec(keccak256(abi.encodePacked(Sales[_id].sold,Sales[_id].maxWallet,Sales[_id].price,Sales[_id].start)));
        uint256 _seed = uint256(keccak256(abi.encodePacked(b,d,Sales[_id].end,Sales[_id].supply,_max)));
        return Buyers[_id][_seed%_max-1];
    }
    function getPrice(uint _id) public view returns (uint256 _price) {
        if (Sales[_id].listType == 1) {
            return dutchPrice(_id);
        } else {
            return Sales[_id].price;
        }
        
    }
    function dutchPrice(uint _id) internal view returns (uint256 _price) {
        uint epochs = (block.timestamp - Sales[_id].start)/dutchEpoch;
       
        uint256 price = Sales[_id].price;
        uint256 floor = (Sales[_id].price/100)*dutchFloor;
        for (uint i=0;i<epochs;) {
            uint parts = price/100;
            price -= parts*dutchPercent;
            unchecked{
                i++;
            }
        }
        if (price <= floor) {
            return floor;
        } else {
            return price;
        }
    }
    function itemBalance(uint _id,address _owner) internal view returns (uint){
        uint total;
        for (uint i=0;i<Buyers[_id].length;){
            if (Buyers[_id][i] == _owner) {
                total ++;
            }
            unchecked {
                i++;
            }
        }
        return total;
    }
    function getInventory(address _owner) public view returns (uint[] memory) {
        return Inventory[msg.sender];
    }
    function buyers(uint _id) public view returns (address[] memory) {
        return Buyers[_id];
    }
    function buyersDiscord(uint _id) public view returns (string[] memory) {
        uint l = Buyers[_id].length;
        string[] memory discords;
        for (uint i=0;i<l;){
            discords[i]=Discord[Buyers[_id][i]];
            unchecked{
                i++;
            }
        }
        return discords;
    }
    //

    //admin functions
    function changeDutchEpoch(uint _seconds) public isManager {
        dutchEpoch = _seconds;
    }
    function changeDutchPercent(uint _percent) public isManager {
        dutchPercent = _percent;
    }
    function changeDutchFloor(uint _percent) public isManager {
        dutchFloor = _percent;
    }
    function delist(uint _id) public isManager {
        Delist[_id] = true;
    }
    function changePrice(uint _id, uint256 _newprice) public isManager {
        Sales[_id].price = _newprice;
    }
    function changeSupply(uint _id, uint _newsupply) public isManager{
        Sales[_id].supply = _newsupply;
    }
    function changeStart(uint _id, uint64 _newDate) public isManager{
        Sales[_id].start = _newDate;
    }
    function changeEnd(uint _id, uint64 _newDate) public isManager{
        Sales[_id].end = _newDate;
    }

    //owner functions
    function addManager(address _manager) public isOwner {
        Manager[_manager] = true;
    }
    function removeManager(address _manager) public isOwner{
        Manager[_manager] = false;
    }
    function stopShop() public isOwner{
        status = false;
    }
    function startShop() public isOwner{
        status = true;
    }
    function transferOwnership(address _newOwner) public isOwner{
        owner = _newOwner;
    }
    function changePaymentToken(address _paymentToken) public isOwner{
        paymentContract = _paymentToken;
    }
}