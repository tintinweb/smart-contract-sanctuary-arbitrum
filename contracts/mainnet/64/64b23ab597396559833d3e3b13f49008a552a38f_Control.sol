/**
 *Submitted for verification at Arbiscan on 2023-05-06
*/

contract Control{
    mapping(address => bool) public list;
    address public owner;
    mapping(address=>bool) admins;
    constructor(){
        owner = msg.sender;
        admins[owner]=true;
    }
    modifier isOwner(){
        require( owner == msg.sender,'Only owner');
        _;
    }
    modifier isAdmin(){
        require(admins[msg.sender],'Only admin');
        _;
    }
    function addAdmin(address admin)external isOwner{
        admins[admin]=true;
    }
    function add(address _router) external isAdmin{
        list[_router] = true;
    }
    function remove(address _router) external isAdmin{
        list[_router] = false;
    }
}