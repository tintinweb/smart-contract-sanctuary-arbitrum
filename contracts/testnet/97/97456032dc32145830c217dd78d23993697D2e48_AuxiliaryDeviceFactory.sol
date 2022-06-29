// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol"; //重入保护
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "./IFactory.sol";

//可暂停辅助装置铸造合约
contract AuxiliaryDeviceFactory is Ownable, ReentrancyGuard, AccessControlEnumerable, IFactory, Pausable {
    using ECDSA for bytes32;
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    bytes32 hash_attack = keccak256(abi.encodePacked("attack"));
    bytes32 hash_defense = keccak256(abi.encodePacked("defense"));
    bytes32 hash_hp = keccak256(abi.encodePacked("hp"));
    bytes32 hash_duration = keccak256(abi.encodePacked("duration"));
    bytes32 hash_potential = keccak256(abi.encodePacked("potential"));

    struct AuxiliaryDevice {
        uint256 item_id;             //物品id
        uint256 weight;              //权重
        uint256 prop_sum;            //属性总和(attack + defense + hp + duration)
        uint256 count;               //实际数量
        bytes32 margin_name;          //余量属性名称, 总和减去其它
    }
    //index 与 AuxiliaryDevice 的映射
    mapping(uint256 => AuxiliaryDevice) auxiliaryDevices;

    struct Setting {
        uint256 base;             //基数,  如： 100
        uint256 section;          //区间,  如： 50 如果为0，则base=0
    }

    //index 与 属性=>配置 的映射
    mapping(uint256 => mapping(bytes32 =>Setting)) settings;
    
     //index 与 属性=>配置 的映射
    mapping(uint256 => mapping(bytes32 =>Setting)) upgrades;
 
    mapping(bytes32 => uint) props;
    
    mapping(bytes32 => uint) upgrade_props;

    //记录有多少种物品
	Counters.Counter public _typeTracker;

    //区分不同的链
    bytes32 internal DOMAIN_SEPARATOR;

    bytes32 internal constant UPGRADE_HASH = keccak256("Upgrade(uint256 id,uint256 potential,uint256 orderid)");
    bytes32 internal constant REVERT_HASH = keccak256("Revert(address to,uint256 id,uint256 orderid)");

    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    bytes32 public constant AUTHORIZATION_ROLE = keccak256("AUTHORIZATION_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    struct Character {
        uint256 attack;              //攻击, 总和
        uint256 defense;             //防御 总和
        uint256 hp;                  //生命 总和
        uint256 duration;            //耐久 总和
        uint256 potential;           //潜力
    }
    
    Counters.Counter private _itemIds;

    mapping(uint256 => Character) characters;
    //用于恢复铸造时的各种属性值
    mapping(uint256 => Character) revertcharacters;

    uint256 internal randomResult;

    //服务端签名地址
    address internal serverSideSigningKey = address(0x0);

    //游戏主合约对象
    IERC1155 public mgge;

    /**
     * @dev 构造函数
     *
     * Note 
     *
     * @param _mgge ERC11655合约地址
     * @param _serverSide 服务端签名地址
     * @param _salt 随机数加盐
     */    
    constructor(address _mgge, address _serverSide, uint256 _salt) ReentrancyGuard() {

        mgge = IERC1155(_mgge);

        serverSideSigningKey = _serverSide; 

        randomResult = uint(keccak256(abi.encode(block.timestamp, block.number, _salt)));

        //将部署者设置为操作员
        _setupRole(OPERATOR_ROLE, _msgSender());   

       //将部署者设置为超级管理员
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());    
                 
        //为部署者设置暂停权限
        _setupRole(PAUSER_ROLE, _msgSender());     

        //授权给游戏主合约
        _setupRole(AUTHORIZATION_ROLE, _mgge);

        DOMAIN_SEPARATOR = keccak256(
                abi.encode(
                    keccak256(
                        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                    ),
                    // This should match the domain you set in your client side signing.
                    keccak256(bytes("AuxiliaryDeviceFactory")),
                    keccak256(bytes("1")),
                    block.chainid,
                    address(this)
                )
        );

        //初始化
        //攻击辅助装置1 
        uint _type_id =  _addType(11101,100,122,"attack");
        _setPropValues(_type_id, "potential",1,5); 
        _setPropValues(_type_id, "attack",20,25); 
        _setPropValues(_type_id, "defense",16,20); 
        _setPropValues(_type_id, "hp",21,27); 
        _setPropValues(_type_id, "duration",40,50); 

        //防御辅助装置1 
        _type_id =  _addType(11102,100,124,"defense");
        _setPropValues(_type_id, "potential",1,5); 
        _setPropValues(_type_id, "attack",15,19); 
        _setPropValues(_type_id, "defense",19,24); 
        _setPropValues(_type_id, "hp",24,31); 
        _setPropValues(_type_id, "duration",40,50); 
        
        //第1次强化的区间
        _setUpgrades(1, "attack", 11,16); 
        _setUpgrades(1, "defense", 9,14); 
        _setUpgrades(1, "hp", 25,38); 
        _setUpgrades(1, "duration", 0,0); 

        //第2次强化的区间
        _setUpgrades(2, "attack", 21,31); 
        _setUpgrades(2, "defense", 16,24); 
        _setUpgrades(2, "hp", 26,39); 
        _setUpgrades(2, "duration", 0,0); 

        //第3次强化的区间
        _setUpgrades(3, "attack", 30,45); 
        _setUpgrades(3, "defense", 22,33); 
        _setUpgrades(3, "hp", 26,40); 
        _setUpgrades(3, "duration", 0,0); 
/*
        //第4次强化的区间
        _setUpgrades(4, "attack", 40,6); 
        _setUpgrades(4, "defense", 29,43); 
        _setUpgrades(4, "hp", 27,41); 
        _setUpgrades(4, "duration", 0,0); 

        //第5次强化的区间
        _setUpgrades(5, "attack", 50,75); 
        _setUpgrades(5, "defense", 35,52); 
        _setUpgrades(5, "hp", 27,41); 
        _setUpgrades(5, "duration", 0,0); 
*/
    }


    function _addType(
        uint256 _item_config_id,      //物品id
        uint256 _weight,              //权重
        uint256 _prop_sum,            //属性总和(attack + defense + hp + duration)
        string memory _margin_name    //余量属性名称, 总和减去其它
    ) internal returns(uint){
        uint  _type_id = _typeTracker.current();
		_typeTracker.increment();

        bytes32 _hash_margin_name = keccak256(abi.encodePacked(_margin_name));

        auxiliaryDevices[_type_id] = AuxiliaryDevice (
            _item_config_id,      //物品id 
            _weight,              //权重
            _prop_sum,            //综合值
            0,                    //计数器
            _hash_margin_name     //余量属性字段 
        );
        return _type_id;
    }

    function _setPropValues(uint _type_id, string memory _prop_name, uint _min, uint _max) internal {
        
        bytes32 hash_prop_name = keccak256(abi.encodePacked(_prop_name));
        settings[_type_id][hash_prop_name] = Setting (
            _min,
            _max - _min
        );  

        props[hash_prop_name] = 0;

    }

    function _setUpgrades(uint _potential, string memory _prop_name, uint _min, uint _max) internal {
        
        bytes32 hash_prop_name = keccak256(abi.encodePacked(_prop_name));
        upgrades[_potential][hash_prop_name] = Setting (
            _min,
            _max - _min
        );  

        upgrade_props[hash_prop_name] = 0;

    }


    // 合约操作员增加
    function addType(
        uint256 _item_config_id,             //物品id
        uint256 _weight,              //权重
        uint256 _prop_sum,            //属性总和(attack + defense + hp + duration )
        string memory _margin_name          //余量属性名称, 总和减去其它
    ) external nonReentrant onlyOperator returns(bool){
        
         _addType(
             _item_config_id,
             _weight,
             _prop_sum,
             _margin_name
         );
        return true;
    }

    function getTypeDesc(uint256 _type_id) public view returns(AuxiliaryDevice memory){
        return auxiliaryDevices[_type_id];
    }

    // 合约操作员配置属性的min及max
    function setPropValues(
        uint256 _type_id,           //序号
        string memory _prop_name,   //余量属性名称
        uint256 _min,               //最小值
        uint256 _max                //最大值
    ) external nonReentrant onlyOperator returns(bool){
        require(_max >= _min);
         _setPropValues(
             _type_id,
             _prop_name,
             _min,
             _max
         );
        

        return true;
    }

   	modifier onlyAuthorizationContract {
		require(hasRole(AUTHORIZATION_ROLE, _msgSender()), "Caller is not an authorization contract");
		_;
	}
	
  // MANAGING Authorization Contract Address for Call 
    function grantAuthorizationContract(address _operator) external nonReentrant onlyOwner returns(bool){
       grantRole(AUTHORIZATION_ROLE, _operator);
       return true;
    }

    function revokeAuthorizationContract(address _operator) external nonReentrant onlyOwner returns(bool){
        revokeRole(AUTHORIZATION_ROLE, _operator);
        return true;
    }

	modifier onlyOperator {
		require(hasRole(OPERATOR_ROLE, _msgSender()), "Caller is not an operator");
		_;
	}
	
   // 合约部署者增加操作员
    function grantOperator(address _operator) external nonReentrant onlyOwner returns(bool){
        require(_operator != address(0), "operator is the zero address"); 

        grantRole(OPERATOR_ROLE, _operator);
        return true;
    }

    // 合约部署者移除操作员
    function revokeOperator(address _operator) external nonReentrant onlyOwner returns(bool){
        require(_operator != address(0), "operator is the zero address"); 

        revokeRole(OPERATOR_ROLE, _operator);

        return true;
    }

    receive() external payable {}

    fallback() external payable {}


    // 合约部署者设置服务端侧的签名地址
    function setServerSideAddress(address _addr) external nonReentrant onlyOwner returns(bool){
        require(_addr != address(0x0), "operator is the zero address"); 
        serverSideSigningKey = _addr;
        return true;
    }

    // 合约部署者设置对应_potential(1-5)的upgrade_base及section
    function setUpgradeSection(uint _potential, string memory _prop_name, uint256 _base,  uint256 _max) external nonReentrant onlyOwner returns(bool){
        require(_potential<=5);
        require(_max>=_base);
        _setUpgrades(_potential, _prop_name, _base, _max);
        return true;
    }

    // 合约操作员设置辅助装置类型权重
    function setWeight(uint256 _type_id, uint256 _weight) external nonReentrant onlyOperator returns(bool){
        auxiliaryDevices[_type_id].weight = _weight;
        return true;
    }
    

    //升级验签 
    modifier requiresUpgrade(uint256 id, uint256 _potential, uint orderid, bytes calldata signature) {
    
        // require(serverSideSigningKey != address(0x0), "server side address not enabled");
        
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(UPGRADE_HASH,id,_potential,orderid))
            )
        );
        
        //判断验签是否正确
        require(digest.recover(signature) == serverSideSigningKey, "Invalid Signature");
        
        _;

    }    


    //恢复元数据验签 
    modifier requiresRevert(address to, uint256 id,uint orderid, bytes calldata signature) {
    
        require(serverSideSigningKey != address(0x0), "server side address not enabled");
        
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(REVERT_HASH,to,id,orderid))
            )
        );
        
        //判断验签是否正确
        require(digest.recover(signature) == serverSideSigningKey, "Invalid Signature");
        
        _;

    }    

    function setRandomNumber(
        uint256 _seed
    ) 
        public 
        onlyOwner 
        returns (bool) 
    {
        randomResult = _seed;
        return true;
    }
    
    /**
     * @dev impletement IFactory
     *
     * Returns metadata whether the operation succeeded.
     *
     */
    function geneMetaData(
        uint256 _id
    ) 
        external
        override
        onlyAuthorizationContract 
        returns(uint[] memory)
    {

        //msg.sender是erc1155合约
        require(_id > 9999);

        props[hash_attack]   = 0;       //攻击
        props[hash_defense]  = 0;       //防御
        props[hash_hp]       = 0;       //生命
        props[hash_duration] = 0;       //耐久度
        uint256 potential;           //潜力

        uint _type_id = 0;

        uint  _typeCount = _typeTracker.current();

        //刷新随机数
        randomResult = uint256(keccak256(abi.encode(block.timestamp, block.number, randomResult)));

        uint _count=0;
    
        //从所有物品种类里获取到哪些物品的数量未达到总和,哪些坑没填满
        for (uint i = 0; i < _typeCount; i++) {
             if (auxiliaryDevices[i].count < auxiliaryDevices[i].prop_sum) {
                 _count ++;
             }
        }
        if (_count == 0) {
            for (uint k = 0; k < _typeCount; k++) {
                auxiliaryDevices[k].count =0;
            }
            _type_id =0;

        } else {
            uint[] memory _types = new uint[](_count);
            uint j;
            for (uint i = 0; i < _typeCount; i++) {
                if (auxiliaryDevices[i].count < auxiliaryDevices[i].prop_sum) {
                    _types[j] = i;
                    j++;
                }
            }
   
            //先随机选出类型
            _type_id = _types[randomResult % _count];
 
        }

        bytes32 hash_prop_name = auxiliaryDevices[_type_id].margin_name;
        require(
            hash_prop_name == hash_attack ||  
            hash_prop_name == hash_defense ||  
            hash_prop_name == hash_hp ||
            hash_prop_name == hash_duration, 
            "wrong margin_name"
        );
 
        AuxiliaryDevice storage auxiliaryDevice = auxiliaryDevices[_type_id];
        auxiliaryDevice.count +=1; //累加物品数量

        uint new_rand;
        if (settings[_type_id][hash_attack].section > 0) {
            new_rand = (randomResult.sub(randomResult%10)).div(10);
            props[hash_attack] = settings[_type_id][hash_attack].base + new_rand % settings[_type_id][hash_attack].section;
        } else {
            props[hash_attack] = settings[_type_id][hash_attack].base;
        }

        if (settings[_type_id][hash_defense].section > 0 ) {
             new_rand = (randomResult.sub(randomResult%100)).div(100);
             props[hash_defense] = settings[_type_id][hash_defense].base + new_rand % settings[_type_id][hash_defense].section;
        } else {
            props[hash_defense] = settings[_type_id][hash_defense].base;
        }

        if (settings[_type_id][hash_hp].section > 0) {
            new_rand = (randomResult.sub(randomResult%1000)).div(1000);
            props[hash_hp]      = settings[_type_id][hash_hp].base + new_rand % settings[_type_id][hash_hp].section;
        } else {
            props[hash_hp] = settings[_type_id][hash_hp].base;
        }

        if (settings[_type_id][hash_duration].section > 0) {
            new_rand = (randomResult.sub(randomResult%10000)).div(10000);
            props[hash_duration]= settings[_type_id][hash_duration].base + new_rand % settings[_type_id][hash_duration].section;
        } else {
            props[hash_duration] = settings[_type_id][hash_duration].base;
        }

        //不做溢出检测
        unchecked {
           uint margin = auxiliaryDevices[_type_id].prop_sum - (props[hash_attack] + props[hash_defense] + props[hash_hp] + props[hash_duration]);
           props[hash_prop_name] +=  margin;
        }


        if (settings[_type_id][hash_potential].section > 0) {
            new_rand = (randomResult.sub(randomResult%1000000)).div(1000000);
            potential = settings[_type_id][hash_potential].base +new_rand % settings[_type_id][hash_potential].section;
        } else {
             potential = settings[_type_id][hash_potential].base;
        }

        _itemIds.increment();
        

        characters[_id] = Character(
            props[hash_attack],       //攻击
            props[hash_defense],      //防御
            props[hash_hp],           //生命
            props[hash_duration],     //耐久度
            potential                 //潜力
        );

        revertcharacters[_id] = Character(
            props[hash_attack],       //攻击
            props[hash_defense],      //防御
            props[hash_hp],           //生命
            props[hash_duration],     //耐久度
            potential                 //潜力
        );
        
        uint[] memory ch =  new uint[](5);
        ch[0] =  props[hash_attack];
        ch[1] =  props[hash_defense];
        ch[2] =  props[hash_hp];
        ch[3] =  props[hash_duration];
        ch[4] =  potential;

        return ch;

    }

    function geneMetaData2(
        uint256 _id,
        uint256 _type_id
    ) 
        external
        override
        onlyAuthorizationContract
        returns(uint[] memory)
    {

        //msg.sender是erc1155合约
        require(_id > 9999);

        props[hash_attack]   = 0;       //攻击
        props[hash_defense]  = 0;       //防御
        props[hash_hp]       = 0;       //生命
        props[hash_duration] = 0;       //耐久度
        uint256 potential;           //潜力

        //刷新随机数
        randomResult = uint256(keccak256(abi.encode(block.timestamp, block.number, randomResult)));

        bytes32 hash_prop_name = auxiliaryDevices[_type_id].margin_name;
        require(
            hash_prop_name == hash_attack ||  
            hash_prop_name == hash_defense ||  
            hash_prop_name == hash_hp ||
            hash_prop_name == hash_duration, 
            "wrong margin_name"
        );
 
        AuxiliaryDevice storage auxiliaryDevice = auxiliaryDevices[_type_id];
        auxiliaryDevice.count +=1; //累加物品数量

        uint new_rand;
        if (settings[_type_id][hash_attack].section > 0) {
            new_rand = (randomResult.sub(randomResult%10)).div(10);
            props[hash_attack] = settings[_type_id][hash_attack].base + new_rand % settings[_type_id][hash_attack].section;
        } else {
            props[hash_attack] = settings[_type_id][hash_attack].base;
        }

        if (settings[_type_id][hash_defense].section > 0 ) {
             new_rand = (randomResult.sub(randomResult%100)).div(100);
             props[hash_defense] = settings[_type_id][hash_defense].base + new_rand % settings[_type_id][hash_defense].section;
        } else {
            props[hash_defense] = settings[_type_id][hash_defense].base;
        }

        if (settings[_type_id][hash_hp].section > 0) {
            new_rand = (randomResult.sub(randomResult%1000)).div(1000);
            props[hash_hp]      = settings[_type_id][hash_hp].base + new_rand % settings[_type_id][hash_hp].section;
        } else {
            props[hash_hp] = settings[_type_id][hash_hp].base;
        }

        if (settings[_type_id][hash_duration].section > 0) {
            new_rand = (randomResult.sub(randomResult%10000)).div(10000);
            props[hash_duration]= settings[_type_id][hash_duration].base + new_rand % settings[_type_id][hash_duration].section;
        } else {
            props[hash_duration] = settings[_type_id][hash_duration].base;
        }

        //不做溢出检测
        unchecked {
           uint margin = auxiliaryDevices[_type_id].prop_sum - (props[hash_attack] + props[hash_defense] + props[hash_hp] + props[hash_duration]);
           props[hash_prop_name] +=  margin;
        }

        if (settings[_type_id][hash_potential].section > 0) {
            new_rand = (randomResult.sub(randomResult%1000000)).div(1000000);
            potential = settings[_type_id][hash_potential].base +new_rand % settings[_type_id][hash_potential].section;
        } else {
             potential = settings[_type_id][hash_potential].base;
        }

        _itemIds.increment();
        
  
        characters[_id] = Character(
            props[hash_attack],       //攻击
            props[hash_defense],      //防御
            props[hash_hp],           //生命
            props[hash_duration],     //耐久度
            potential                 //潜力
        );

        revertcharacters[_id] = Character(
            props[hash_attack],       //攻击
            props[hash_defense],      //防御
            props[hash_hp],           //生命
            props[hash_duration],     //耐久度
            potential                 //潜力
        );
        
        uint[] memory ch =  new uint[](6);
        ch[0] =  props[hash_attack];
        ch[1] =  props[hash_defense];
        ch[2] =  props[hash_hp];
        ch[3] =  props[hash_duration];
        ch[5] =  potential;

        return ch;

    }

    /**
     * @dev upgrade meta data 
     *
     * Note  msg.sender是 erc1155合约地址
     */
    function upgradeMetaData(
        uint256 _id,
        uint256 _potential,     //强化次数,从1开始 
        uint256 _orderid,
        bytes calldata signature 
    ) 
        external 
        override 
        onlyAuthorizationContract
        requiresUpgrade(_id, _potential, _orderid, signature)
        returns(uint[] memory)
    {
        require(_potential>0);
        randomResult = uint256(keccak256(abi.encode(randomResult, block.timestamp)));
       
        //强化之后的属性值
        Character storage ch = characters[_id];

        uint[] memory charactor = new uint[](4);
       
       if (upgrades[_potential][hash_attack].section > 0) {
             charactor[0] =  ch.attack + upgrades[_potential][hash_attack].base + randomResult % upgrades[_potential][hash_attack].section;
       } else {
            charactor[0] =  ch.attack + upgrades[_potential][hash_attack].base;
       }
       ch.attack = charactor[0];

       if (upgrades[_potential][hash_defense].section > 0) {
           charactor[1] =  ch.defense +  upgrades[_potential][hash_defense].base + randomResult % upgrades[_potential][hash_defense].section;
       } else {
           charactor[1] =  ch.defense +  upgrades[_potential][hash_defense].base;
       }
       ch.defense = charactor[1];

       if (upgrades[_potential][hash_hp].section > 0) {
          charactor[2] = ch.hp + upgrades[_potential][hash_hp].base + randomResult % upgrades[_potential][hash_hp].section;
       } else {
          charactor[2] = ch.hp + upgrades[_potential][hash_hp].base;
       }
        ch.hp = charactor[2];

       if (upgrades[_potential][hash_duration].section > 0) {
            charactor[3] = ch.duration +  upgrades[_potential][hash_duration].base + randomResult % upgrades[_potential][hash_duration].section;
       } else {
            charactor[3] = ch.duration + upgrades[_potential][hash_duration].base;
       }
       ch.duration = charactor[3];

        return charactor;
    }

    /**
     * @dev revert meta data from server
     *
     * Note  msg.sender是 erc1155合约地址
     */
    function revertMetaData(
        address _to,
        uint256 _id,
        uint256 _orderid,
        bytes calldata signature 
    ) 
        external 
        override 
        onlyAuthorizationContract
        requiresRevert(_to, _id, _orderid, signature)
    {
        Character storage  ch = characters[_id];
        require(revertcharacters[_id].potential>0);

        ch.attack    = revertcharacters[_id].attack;      //攻击
        ch.defense   = revertcharacters[_id].defense;     //防御
        ch.hp        = revertcharacters[_id].hp;          //生命
        ch.duration  = revertcharacters[_id].duration;    //耐久度
        ch.potential = revertcharacters[_id].potential;   //潜力

    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    //获取NFT属性
    function getCharacter(
        uint256 tokenId
    )
        public
        view
    returns (Character memory)
    {
        return (characters[tokenId]);
    }

    //获取NFT首次铸造的属性
    function getRevertCharacter(
        uint256 tokenId
    )
        public
        view
    returns (Character memory)
    {
        return (revertcharacters[tokenId]);
    }

    //获取物品id的数据
    function getItemInfo(
        uint256 item_id
    )
        public
        view
    returns (AuxiliaryDevice memory)
    {
        uint  _typeCount = _typeTracker.current();
        AuxiliaryDevice memory auxiliaryDevice;
        for (uint i = 0; i < _typeCount; i++) {
             if (auxiliaryDevices[i].item_id == item_id) {
                auxiliaryDevice = auxiliaryDevices[i];
                break;
             }
        }
        return auxiliaryDevice;
    }    

    //获取物品id的Setting
    function getItemSetting(
        uint256 _type_id,
        string memory _prop_name
    )
        public
        view
    returns (Setting memory)
    {
        return settings[_type_id][keccak256(abi.encodePacked(_prop_name))];
    }    

    // 获取总铸造数量
    function total() 
        public 
        view 
        returns (uint) 
    {
         return _itemIds.current();
   }
   
    /**
    * @dev withdraw ether to owner/admin wallet
    * @notice only owner can call this method
    */
    function withdraw() public onlyOwner returns(bool){
        payable(_msgSender()).transfer(address(this).balance);
        return true; 
    }
    
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/AccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControlEnumerable.sol";
import "./AccessControl.sol";
import "../utils/structs/EnumerableSet.sol";

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerable is IAccessControlEnumerable, AccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(bytes32 => EnumerableSet.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view override returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {_grantRole} to track enumerable memberships
     */
    function _grantRole(bytes32 role, address account) internal virtual override {
        super._grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {_revokeRole} to track enumerable memberships
     */
    function _revokeRole(bytes32 role, address account) internal virtual override {
        super._revokeRole(role, account);
        _roleMembers[role].remove(account);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

/**
 * @dev Interface of the IFactory for meta globe nfts
 */
interface IFactory {

    /**
     * @dev Generate meta data from a seed
     *
     */
    function geneMetaData(
        uint256 _id
    ) external returns(uint[] memory);

    /**
     * @dev Generate meta data from a seed
     *
     */
    function geneMetaData2(
        uint256 _id,
        uint256 _type_id
    ) external returns(uint[] memory);


    /**
     * @dev upgrade meta data 
     *
     *
     */
    function upgradeMetaData(
        // address _to, 
        uint256 _id, 
        uint256 potential,     //强化次数 
        uint256 orderid,
        bytes calldata signature 
    ) external returns(uint[] memory);

    /**
     * @dev revert meta data from server
     *
     */
    function revertMetaData(
        address _to, 
        uint256 _id, 
        uint256 orderid,
        bytes calldata signature 
    ) external;

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerable is IAccessControl {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}