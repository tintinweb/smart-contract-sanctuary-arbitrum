/**
 *Submitted for verification at arbiscan.io on 2022-01-30
*/

pragma solidity 0.8.10;

interface ISplitter
{
    function Split() external payable;
}

interface IGulper
{
    function Gulp() external payable;
}

contract GulpScript
{
    ISplitter splitter;
    IGulper ethGulper;
    IGulper dEthGulper;
    IGulper daiGulper;

    constructor(
        ISplitter _splitter, 
        IGulper _ethGulper, 
        IGulper _dEthGulper, 
        IGulper _daiGulper)
    {
        splitter = _splitter;
        ethGulper = _ethGulper;
        dEthGulper = _dEthGulper;
        daiGulper = _daiGulper;
    }

    function Gulp()
        public
    {
        splitter.Split();
        ethGulper.Gulp();
        dEthGulper.Gulp();
        daiGulper.Gulp();
    }
}

contract ArbitrumGulpScript is GulpScript
{
    constructor()
    GulpScript (
        ISplitter(0x91ABD747E28AD2D28bE910C8b8B965cfB1AD92eE), 
        IGulper(0x16e2970EcE9c7eB02e46caeE4a9e6eA000a5155E), 
        IGulper(0x4CE79e64236a6dB46E712070D5B9A63483C8786A), 
        IGulper(0xbfAC76BD6AFB65B0F861Dc41B44bF63a6127A4F9))
    { }
}