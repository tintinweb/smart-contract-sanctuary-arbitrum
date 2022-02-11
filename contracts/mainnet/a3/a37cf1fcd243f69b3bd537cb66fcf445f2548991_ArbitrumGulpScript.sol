/**
 *Submitted for verification at arbiscan.io on 2022-02-04
*/

pragma solidity 0.8.10;

interface ISplitter
{
    function Split() external payable;
}

interface IGulper
{
    function gulp() external payable;
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

    function gulp()
        public
    {
        splitter.Split();
        ethGulper.gulp();
        dEthGulper.gulp();
        daiGulper.gulp();
    }
}

contract ArbitrumGulpScript is GulpScript
{
    constructor()
    GulpScript (
        ISplitter(0x158c793236636756e8B83B0112B2e33315d298c7),  // splitter
        IGulper(0xbe3a1490153Ae6f497852e75E8d022562CAb71C7),    // ethGulper
        IGulper(0xf339039197592067f6a5F69cBFF6d8235643942D),    // dEthGulper
        IGulper(0x78c33207e8E1ddd7634062C3b198266756b30Ba4))    // daiGulper
    { }
}