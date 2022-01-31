/**
 *Submitted for verification at arbiscan.io on 2022-01-28
*/

pragma solidity ^0.8.0;

interface IFrySwapTool
{
    function convertExactEthToFry() 
        external 
        payable;
}

interface IDaiSwapTool
{
    function convertExactEthToDai() 
        external 
        payable;
}

interface IERC20
{
    function transfer(address _to, uint256 _value) external;
    function balanceOf(address) external view returns (uint256);
}

interface IWETH 
{
    function deposit() 
        payable 
        external;
}

contract Splitter
{
    // This contract recieved Eth and LEVR tokens and sends them to their respective gulper contracts.

    IERC20 public levrErc20;
    IERC20 public daiErc20;
    IERC20 public fryErc20;

    address public ethGulper;
    address public daiGulper;
    address public dEthGulper;

    IDaiSwapTool public daiSwapTool;
    IFrySwapTool public frySwapTool;

    constructor (
        address _levrErc20,
        address _daiErc20,
        address _fryErc20,
        address _ethGulper,
        address _daiGulper,
        address _dEthGulper,
        IDaiSwapTool _daiSwapTool,
        IFrySwapTool _frySwapTool)
    {
        levrErc20 = IERC20(_levrErc20);
        daiErc20 = IERC20(_daiErc20);
        fryErc20 = IERC20(_fryErc20);

        ethGulper = _ethGulper;
        daiGulper = _daiGulper;
        dEthGulper = _dEthGulper;

        daiSwapTool = _daiSwapTool;
        frySwapTool = _frySwapTool;
    }
    
    function Split() 
        public
    { 
        uint ethBalance = address(this).balance;
        uint levrBalance = levrErc20.balanceOf(address(this));
        GulpEth(ethBalance*475/1000, levrBalance/3);
        GulpDai(ethBalance*475/1000, levrBalance/3);
        GulpDeth(levrBalance/3);
        BurnFry(ethBalance*50/1000);
    }

    function GulpEth(uint _ethBalance, uint _levrBalance)
        private
    {
        (bool success,) = ethGulper.call{ value:_ethBalance }(""); 
        require(success, "ethGulper transfer failed");
        levrErc20.transfer(ethGulper, _levrBalance);
    }

    function GulpDai(uint _ethBalance, uint _levrBalance)
        private
    {
        SwapWethForDai(_ethBalance);
        daiErc20.transfer(daiGulper, daiErc20.balanceOf(address(this)));
        levrErc20.transfer(daiGulper, _levrBalance);
    }

    function SwapWethForDai(uint _ethBalance)
        private
    {
        daiSwapTool.convertExactEthToDai{ value:_ethBalance }();
    }

    function GulpDeth(uint _levrBalance)
        private
    {
        levrErc20.transfer(dEthGulper, _levrBalance);
    }

    function BurnFry(uint _ethBalance)
        private
    {
        SwapWethForFry(_ethBalance);
        fryErc20.transfer(address(1), fryErc20.balanceOf(address(this)));
    }

    function SwapWethForFry(uint _ethBalance)
        private
    {
        frySwapTool.convertExactEthToFry{ value:_ethBalance }();
    }

    receive()
        payable
        external
    { }
}

contract ArbitrumSplitter is Splitter
{
    constructor() Splitter(
        address(0x7A416Afc042537f290CB44A7c2C269Caf0Edc93C),                 // levrErc20
        address(0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1),                 // daiErc20
        address(0x633A3d2091dc7982597A0f635d23Ba5EB1223f48),                 // fryErc20
        address(0x16e2970EcE9c7eB02e46caeE4a9e6eA000a5155E),                 // ethGulper
        address(0xbfAC76BD6AFB65B0F861Dc41B44bF63a6127A4F9),                 // daiGulper
        address(0x4CE79e64236a6dB46E712070D5B9A63483C8786A),                 // dEthGulper
        IDaiSwapTool(payable(0x11C0429D5352D49f81A18aF3B4BB0209c6858033)),    // daiSwapTool
        IFrySwapTool(payable(0x0c789e194DfE4bAC8Acaef344382A754133A5C6f)))    // frySwapTool
    {}
}