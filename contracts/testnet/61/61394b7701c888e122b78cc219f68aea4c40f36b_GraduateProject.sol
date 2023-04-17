/**
 *Submitted for verification at Arbiscan on 2023-04-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;


// import "@openzeppelin/contracts/access/Ownable.sol";

// in Formal version should add onlyOwner limit to backend Call Contract only!!

contract GraduateProject{
    /* Token */
    string private  constant _name="Environmental Friendly Token";
    string private  constant _symbol="EFT";
    uint256 private _totalSupply;

    /* Variables */
    struct Club{
        string name;
        address addr;
        uint256 balance;
    }

    struct Resource{
        string name;
        uint256 cost;
    }

    uint256 club_num;
    uint256 resource_num;
    mapping (uint => Club) clubs;
    mapping  (uint => Resource) resources;

    /* Events */
    event AddClub(
        uint256 indexed _clubID,
        string _clubName,
        address _addr
    );

    event AddResource(
        uint256 indexed _resourceID,
        string _resourceName,
        uint256 _cost
    );

    event ChangeResourceCost(
        uint256 _id,
        string _resourceName,
        uint256 _newCost
    );

    event BookedResource(
        uint256 indexed _clubID,
        string _clubName,
        string _date,
        uint256 indexed _resourceID,
        string _resourceName,
        uint256 _cost
    );

    event EnvironmentalFriendly(
        uint256 indexed _clubID,
        string _clubName,
        uint256 indexed _activityID,
        string _activityName,
        string _date,
        uint256 indexed _pictureID,
        uint256 _number,
        uint256 _token
    );

    event ModifyPicture(
        uint256 indexed _clubID,
        string _clubName,
        uint256 indexed _activityID,
        string _activityName,
        uint256 indexed _newpicID,
        uint256 _oldnum,
        uint256 _newnum,
        uint256 _balance,
        string _action,
        uint256 _token
    );



    constructor(){
        club_num = 0;
        resource_num = 0;

        //     _mint(msg.sender, 1000000 * 10**12, "constructor"); //just in case

    }


    /* Picture - Token*/
    function UploadPicture(
        uint256 _clubID,
        uint256 _activityID,
        string memory _activityName,
        string memory _date,
        uint256 _picID,
        uint256 _picNum
    ) external {
        uint256 _token = _picNum;   //1:1 or not?
        clubs[_clubID].balance += _token;
        _totalSupply += _token;

        emit EnvironmentalFriendly(_clubID, clubs[_clubID].name, _activityID, _activityName, _date, _picID, _picNum, _token);
    }

    function ModifyPicnum_Add(
        uint256 _clubID,
        uint256 _activityID,
        string memory _activityName,
        uint256 _oldnum,
        uint256 _picID,
        uint256 _picNum,
        uint256 _add
    ) external {
        uint256 _token = _add;   //1:1 or not?
        clubs[_clubID].balance += _token;
        uint256 _balance = clubs[_clubID].balance;
        _totalSupply += _token;        

        emit ModifyPicture(_clubID, clubs[_clubID].name, _activityID, _activityName, _picID, _oldnum, _picNum, _balance, "Add", _token);
    }

    function ModifyPicnum_Retake(
        uint256 _clubID,
        uint256 _activityID,
        string memory _activityName,
        uint256 _oldnum,
        uint256 _picID,
        uint256 _picNum,
        uint256 _minus
    ) external {
        uint256 _token = _minus;   //1:1 or not?
        clubs[_clubID].balance -= _token;
        uint256 _balance = clubs[_clubID].balance;
        _totalSupply -= _token;        

        emit ModifyPicture(_clubID, clubs[_clubID].name, _activityID, _activityName, _picID, _oldnum, _picNum, _balance, "Minus", _token);
    }


    /* Book Resources */
    function BookResource(
        uint256 _clubID,
        uint256 _resourceID,
        string memory _date
    ) external {
        uint256 _cost = resources[_resourceID].cost;
        require(clubs[_clubID].balance >= _cost, "Not enough EFT in club balance left!");
        clubs[_clubID].balance -= _cost;

        emit BookedResource(_clubID, clubs[_clubID].name, _date, _resourceID, resources[_resourceID].name, _cost);
    }

    /* Resource Detail*/
    function ResourceCost(
        uint256 _id
    ) external view returns(uint256){
        return resources[_id].cost;
    }

    function ResourceName(
        uint256 _id
    ) external view returns(string memory){
        return resources[_id].name;
    }


    /* Club Detail */
    function ClubBalance(
        uint256 _clubID
    ) external view returns(uint256){
        return clubs[_clubID].balance;
    }
    
    function ClubAddress(
        uint256 _clubID
    ) external view returns(address){
        return clubs[_clubID].addr;
    }

    function ClubName(
        uint256 _clubID
    ) external view returns(string memory){
        return clubs[_clubID].name;
    }

    // function _mint()
    // function _transfer()

    /* Set Function */
    function ModifyResourceCost(
        uint256 _ID,
        uint256 _newcost
    ) external {
        resources[_ID].cost = _newcost;

        emit ChangeResourceCost(_ID, resources[_ID].name, _newcost);
    }

    function CreateResource(
        uint256 _id,
        string memory name_,
        uint256 _cost
    ) external {
        resources[_id].name = name_;
        resources[_id].cost = _cost;

        emit AddResource(_id, name_, _cost);
    }

    function CreateClub(        
        uint256 _id,
        string memory  name_,
        address _addr
    ) external{
        clubs[_id].name = name_;
        clubs[_id].addr = _addr;
        clubs[_id].balance = 0;

        emit AddClub(_id, name_, _addr);
    }


    /* Get Variables */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function name() public pure returns (string memory) {
        return _name;
    }
    
}