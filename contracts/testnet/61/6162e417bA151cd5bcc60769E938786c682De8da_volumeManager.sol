/**
 *Submitted for verification at Arbiscan on 2022-05-31
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


abstract contract BlockContext {
    function _blockTimestamp() internal view virtual returns (uint256) {
        // Reply from Arbitrum
        // block.timestamp returns timestamp at the time at which the sequencer receives the tx.
        // It may not actually correspond to a particular L1 block
        return block.timestamp;
    }

    function _blockNumber() internal view virtual returns (uint256) {
        return block.number;
    }
}


contract volumeManager is BlockContext{


     struct volumeData{
        uint256 volume;
        uint256 timestamp;
    }

    uint256 public idGenerator;

    uint256 public secondsIn30Days=300;
   
    // mapping to store the 30 days trading amount
    // first key : trader , second key : index.
    mapping(address =>mapping(uint256 => volumeData)) public traderVolume;

    mapping(address => uint256[]) public traderIds;

    function updateTraderVolumeAndTradingFeesRatio(
        address _trader,
        uint256  _traderVolume
       )  external  
    {
        uint256 length=traderIds[_trader].length;
        
        if(length==0){
           idGenerator += 1; 
           volumeData memory data=volumeData({
               volume:_traderVolume,
               timestamp:_blockTimestamp()
           });
            traderVolume[_trader][idGenerator]=data;  
            traderIds[_trader].push(idGenerator); 
        }else{
            uint256 lastID=traderIds[_trader][length-1];
            volumeData storage lastVolumeData=traderVolume[_trader][lastID];
            if(lastVolumeData.timestamp + 20 > _blockTimestamp()){
                lastVolumeData.volume += _traderVolume;
            }else{
                idGenerator += 1; 
                volumeData memory data=volumeData({
                        volume:_traderVolume,
                        timestamp:_blockTimestamp()
                    });
                traderVolume[_trader][idGenerator]=data;
                traderIds[_trader].push(idGenerator); 
            }
        }
        
    }

    function getTraderIds(address _trader) public view returns(uint[] memory){
        return traderIds[_trader];
    }

    function getLast30DaysVolume(address _trader) public view returns(uint256 totalVolume){
        volumeData memory data;
        uint256 currentTimestamp=_blockTimestamp();
        uint[] memory ids=traderIds[_trader];
        int256 i=int256(ids.length-1);
        while(i>=0){
           data=traderVolume[_trader][ids[uint256(i)]];
            if(data.timestamp >= (currentTimestamp-secondsIn30Days)){
                totalVolume += data.volume;
            }else{
                break;
            } 
            i--;
        } 
    }

}