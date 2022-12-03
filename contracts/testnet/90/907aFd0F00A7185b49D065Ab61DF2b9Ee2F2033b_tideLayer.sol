// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
pragma abicoder v2;

import "./safemath.sol";
import "./erc20interface.sol";
import "./storageinterface.sol";
import "./NonblockingLzApp.sol";

contract tideLayer is NonblockingLzApp   {
    using SafeMath for uint256;

    struct tidecmd {
        uint cmd;
        address sender;
        uint orderType;
        uint slippageP;
        tideStorage.Trade  t;
    }


    // Params (adjustable)
    address public bnbtrading = address(0);
    uint public positionFee = 35; // milipercent 0.1%
    uint public executorFee = 10000000000000000; // 0.05 bnb
    uint16 public dstChainId = 10102;
    address public quoteToken = address(0x8a76Ca7044A0dA49dA73d24D183e876b8c16436B);
    constructor(address _lzEndpoint,address _bnbtrading) NonblockingLzApp(_lzEndpoint) {
        bnbtrading = _bnbtrading;
    }

    function setPositionFee( uint _fee) onlyOwner external {
        positionFee = _fee;
    }
    function setQuoteToken( address token) onlyOwner external {
        quoteToken = token;
    }
    function setBnbtrading( address _bnbtrading) onlyOwner external {
        bnbtrading = _bnbtrading;
    }
    function setExecutorFee( uint _fee) onlyOwner external {
        executorFee = _fee;
    }
    function _nonblockingLzReceive(uint16, bytes memory, uint64, bytes memory) internal override {
    }


    function openTrade(
        tideStorage.Trade calldata t,
        uint orderType,
        uint slippageP // for market orders only
        )  external payable {

        address sender = msg.sender;
        uint execute = orderType == 0 ? executorFee:executorFee.mul(2);
        //require(msg.value>=execute, "Invalid fee");

        uint fee = t.positionSizeDai.mul(positionFee).div(10000);
        uint depositTotal = fee.add(t.positionSizeDai);
        TransferHelper.safeTransferFrom(quoteToken, msg.sender, address(this), depositTotal);

        tidecmd memory tcmd = tidecmd(
            0,
            sender,
            orderType,
            slippageP,
            tideStorage.Trade(
                t.trader,
                t.pairIndex,
                t.index,
                t.positionSizeDai,
                t.openPrice,
                t.buy,
                t.leverage,
                t.tp,
                t.sl,
                t.liq
            )
        );
        bytes memory payload = abi.encode(tcmd);
        
        bytes memory adapterParams = abi.encodePacked(
            uint16(2),uint(600000),uint(execute),address(bnbtrading)
        );
        _lzSend(dstChainId, payload, payable(msg.sender), address(0x0), adapterParams,msg.value);
    }
    
    function updateSl(
        uint pairIndex,
        uint index,
        uint newSl
    )  external payable {

        address sender = msg.sender;

        tidecmd memory tcmd = tidecmd(
            1,
            sender,
            0,
            0,
            tideStorage.Trade(
                address(0),
                pairIndex,
                index,
                0,
                0,
                false,
                0,
                0,
                newSl,
                0
            )
        );
        bytes memory payload = abi.encode(tcmd);
        bytes memory adapterParams = abi.encodePacked(
            uint16(2),uint(600000)
        );

        _lzSend(dstChainId, payload, payable(msg.sender), address(0x0), adapterParams,msg.value);
    }
    
    function updateTp(
        uint pairIndex,
        uint index,
        uint newTp
    )  external payable  {

        address sender = msg.sender;
        tidecmd memory tcmd = tidecmd(
            2,
            sender,
            0,
            0,
            tideStorage.Trade(
                address(0),
                pairIndex,
                index,
                0,
                0,
                false,
                0,
                newTp,
                0,
                0
            )
        );
        bytes memory payload = abi.encode(tcmd);
        bytes memory adapterParams = abi.encodePacked(
            uint16(2),uint(600000)
        );

        _lzSend(dstChainId, payload, payable(msg.sender), address(0x0), adapterParams,msg.value);

    }
    
    function closeTradeByUser(
        uint pairIndex,
        uint index,
        uint slippageP
    )  external payable {

        address sender = msg.sender;
        tidecmd memory tcmd = tidecmd(
            3,
            sender,
            0,
            slippageP,
            tideStorage.Trade(
                address(0),
                pairIndex,
                index,
                0,
                0,
                false,
                0,
                0,
                0,
                0
            )
        );
        bytes memory payload = abi.encode(tcmd);
        bytes memory adapterParams = abi.encodePacked(
            uint16(2),uint(600000)
        );
        _lzSend(dstChainId, payload, payable(msg.sender), address(0x0), adapterParams,msg.value);

    }
    

    function cancelOrder(
        uint pairIndex,
        uint index
    )  external payable {
        
        address sender = msg.sender;
        tidecmd memory tcmd = tidecmd(
            4,
            sender,
            0,
            0,
            tideStorage.Trade(
                address(0),
                pairIndex,
                index,
                0,
                0,
                false,
                0,
                0,
                0,
                0
            )
        );
        bytes memory payload = abi.encode(tcmd);
        bytes memory adapterParams = abi.encodePacked(
            uint16(2),uint(600000)
        );
        _lzSend(dstChainId, payload, payable(msg.sender), address(0x0), adapterParams,msg.value);

    }
    function withdraw(address _token, uint256 _amount) external onlyOwner {
        require(ERC20(_token).transfer(msg.sender, _amount), 'transferFrom() failed.');
    }
    function payout () public onlyOwner returns(bool res) {

        address payable to = payable(msg.sender);
        to.transfer(address(this).balance);
        return true;
    }   
    // allow this contract to receive ether
    receive() external payable {}
}