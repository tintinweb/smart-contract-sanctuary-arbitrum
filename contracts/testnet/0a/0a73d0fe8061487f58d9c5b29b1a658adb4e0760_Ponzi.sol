/**
 *Submitted for verification at Arbiscan on 2023-04-22
*/

pragma solidity  0.8.17;

contract Ponzi
{
    mapping(address => uint) private _balances;

    event TotalETHUpdated(uint);

    function Deposit() external payable
    {
        _balances[msg.sender] += msg.value;

        emit TotalETHUpdated(GetContractBalance());
    }

    function Withdraw(address payable addr) public payable  //withdraws total deposit plus "interest" if possible
    {
        require(CanWithdraw(addr), "Need at least 110% of deposit available total in contract to withdraw");
        (bool sent, bytes memory data) = addr.call{value: GetAddressValuePlusInterest(addr)}("");
        require(sent, "Could not withdraw");

        _balances[addr] = 0;
        emit TotalETHUpdated(GetContractBalance());
    }

    function GetAddressValuePlusInterest(address addr) public view returns(uint)
    {
        return _balances[addr] + (_balances[addr] * 10 / 100);
    }

    function GetAddressValue(address addr) public view returns(uint)
    {
        return _balances[addr];
    }

    function GetContractBalance() public view returns(uint)
    {
        return address(this).balance;
    }

    function CanWithdraw(address addr) public view returns(bool)
    {
        return GetContractBalance() >= GetAddressValuePlusInterest(addr);
    }
}