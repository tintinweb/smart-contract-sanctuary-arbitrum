/**
 *Submitted for verification at Arbiscan.io on 2023-11-13
*/

interface IERC1155 {
  function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes calldata _data) external;
  function balanceOf(address account, uint256 id) external view returns (uint256);
  function setApprovalForAll(address _operator, bool _approved) external;
  function isApprovedForAll(address _owner, address _operator) external view returns (bool);
  function getProperty(uint256 id, string memory key) external view returns (uint256);
}
contract HarvestRewardType{
  uint256 public total;
  mapping(uint256 => uint256) public indexes;//index->rewardid
  mapping(uint256 => uint256) public rewards;//rewardid=>amount

  function updateReward(uint256 rewardId, uint256 amount) external{
    if(rewards[rewardId] == 0){
      indexes[total] = rewardId;
      total++;
    }
    rewards[rewardId] += amount;
  }
}
contract ReceiveERC1155{
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external pure returns (bytes4) {
        return
            bytes4(
                keccak256(
                    "onERC1155Received(address,address,uint256,uint256,bytes)"
                )
            );
    }

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external pure returns (bytes4) {
        return
            bytes4(
                keccak256(
                    "onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"
                )
            );
    }
}
contract Ownable{
  address public owner;
  modifier onlyOwner() {
    require(msg.sender == owner, "Not owner");
    _;
  }
  constructor() {
    owner = msg.sender;
  }
  function transferOwnership(address newOwner) external onlyOwner{
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    owner = newOwner;
  }
}
contract Farm is Ownable, ReceiveERC1155{
  event PutInBatchEvent(uint256 landId, BatchPutInParams[] params);
  event HarvestBatchEvent(uint256 landId, uint256[] indexes, HarvestRewardType rewards);


  struct BatchPutInParams{
    uint256 plantId;
    uint256[] indexes;
  }

  struct PlantType{
    uint256 plantId;
    uint256 plantAt;
  }

  IERC1155 ItemsContract = IERC1155(address(0x194EF66fcffe3B77Cac322decBD5dCE724BA9ef5));

  mapping(address => mapping(uint256 => bool)) public lands;//user -> landId -> bool
  mapping(uint256 => bool) public isPlant;
  mapping(uint256 => bool) public isLand;//landid -> status

  mapping(uint256 => uint256) public totalPlant;//landId -> plant count
  mapping(uint256 => mapping(uint256 => PlantType)) public plants;//landid -> index -> plant


  function approvePlant(uint256 plantId, bool status) external onlyOwner{
    isPlant[plantId] = status;
  }

  function approveLand(uint256 landId, bool status) external onlyOwner{
    isLand[landId] = status;
  }

  function depositLand(uint256 landId) public{
    require(isLand[landId], "Not land");
    ItemsContract.safeTransferFrom(msg.sender, address(this), landId, 1, "");
    lands[msg.sender][landId] = true;
  }
  function withdrawLand() public{
    
  }
  //put in and deposit land 
  function putIn(uint256 landId, uint256 index, uint256 plantId, uint256 maxPlant) internal{
    
    require(index < maxPlant, "Out of index");
    require(isPlant[plantId], "Not plant");
    require(plants[landId][index].plantId == 0, "Planted");

    plants[landId][index] = PlantType(plantId, block.timestamp);
    totalPlant[landId]++;
  }
  function batchPutIn(uint256 landId, BatchPutInParams[] memory params) public{
    uint256 maxPlant = ItemsContract.getProperty(landId, "maxPlant");
    
    require(lands[msg.sender][landId], "Not owner");
    uint256 paramsLength = params.length;
    uint256 indexLength = 0;
    uint256 i = 0;
    uint256 j = 0;

    for(i = 0; i < paramsLength; i++){
      indexLength = params[i].indexes.length;

      ItemsContract.safeTransferFrom(msg.sender, address(this), params[i].plantId, indexLength, "");

      for(j = 0; j < indexLength; j++){
        putIn(landId, params[i].indexes[j], params[i].plantId, maxPlant);
      }
    }
    emit PutInBatchEvent(landId, params);
  }

  function harvest(uint256 landId, uint256 index) internal returns(uint256 id, uint256 amount){
    PlantType memory plant = plants[landId][index];
    uint256 harvestCycle = ItemsContract.getProperty(plant.plantId, "harvestCycle");
    uint256 harvestTime = plant.plantAt + harvestCycle;

    uint256 fruitId = ItemsContract.getProperty(plant.plantId, "fruitId");
    uint256 fruitAmount = ItemsContract.getProperty(plant.plantId, "fruitAmount");

    require(plant.plantId > 0, "Not planted");
    require(harvestCycle > 0, "harvestCycle > 0");
    require(harvestTime <= block.timestamp, "Can't harvest now");

    plants[landId][index] = PlantType(0, 0);
    totalPlant[landId]--;
    return (fruitId, fruitAmount);
    // ItemsContract.safeTransferFrom(address(this), msg.sender, fruitId, fruitAmount, "");
  }
  function batchHarvest(uint256 landId, uint256[] memory indexes) public{
    require(lands[msg.sender][landId], "Not owner");
    HarvestRewardType harvestReward = new HarvestRewardType();
    uint256 i = 0;
    uint256 loopLength = indexes.length;

    uint256 fruitId;
    uint256 fruitAmount;

    for(i = 0; i < loopLength; i++){
      (fruitId, fruitAmount) = harvest(landId, indexes[i]);
      harvestReward.updateReward(fruitId, fruitAmount);
    }

    loopLength = harvestReward.total();
    for(i = 0; i < loopLength; i++){
      fruitId = harvestReward.indexes(i);
      fruitAmount = harvestReward.rewards(fruitId);

      ItemsContract.safeTransferFrom(address(this), msg.sender, fruitId, fruitAmount, "");
    }
    emit HarvestBatchEvent(landId, indexes, harvestReward);
  }
}