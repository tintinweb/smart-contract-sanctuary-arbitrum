import "../Utils/ArrayUtils.sol";

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./IBatchAdventurerData.sol";
import "./IAdventurerData.sol";
import "../Adventurer/TraitConstants.sol";
import "../Manager/ManagerModifier.sol";

contract BatchAdventurerData is IBatchAdventurerData, ManagerModifier {
  event AddedTo(
    uint256 _type,
    address addr,
    uint256 id,
    uint256 property,
    uint256 value,
    uint256 total
  );

  event UpdatedTo(uint256 _type, address addr, uint256 id, uint256 property, uint256 value);

  event RemovedFrom(
    uint256 _type,
    address addr,
    uint256 id,
    uint256 property,
    uint256 value,
    uint256 total
  );

  error UnsupportedType(uint256 _type);
  error InvalidValue(
    uint256 _type,
    address _addr,
    uint _id,
    uint256 _prop,
    uint256 _val,
    uint256 _current
  );

  IAdventurerData public LEGACY_DATA;

  mapping(address => mapping(uint256 => mapping(uint256 => uint24[10]))) public STORAGE;

  constructor(address _manager, address _legacyData) ManagerModifier(_manager) {
    LEGACY_DATA = IAdventurerData(_legacyData);
  }

  function add(
    address _addr,
    uint256 _id,
    uint256 _type,
    uint256 _prop,
    uint256 _val
  ) public onlyManager {
    _add(_addr, _id, _type, _prop, _val);
  }

  function addBatch(
    address[] calldata _addr,
    uint256[] calldata _id,
    uint256 _type,
    uint256[][] calldata _prop,
    uint256[][] calldata _val
  ) external onlyManager {
    ArrayUtils.ensureSameLength(_addr.length, _id.length, _prop.length, _val.length);

    uint currentProp;
    for (uint i = 0; i < _addr.length; i++) {
      uint24[10] storage values = _load(_addr[i], _id[i], _type);
      uint24[10] memory mem = values;
      for (uint j = 0; j < _prop[i].length; j++) {
        if (_val[i][j] == 0) {
          continue;
        }

        currentProp = _prop[i][j];
        mem[currentProp] += uint24(_val[i][j]);
        values[currentProp] = mem[currentProp];
        emit AddedTo(_type, _addr[i], _id[i], currentProp, _val[i][j], mem[currentProp]);
      }
    }
  }

  function addBatch(
    address[] calldata _addr,
    uint256[] calldata _id,
    uint256 _type,
    uint256 _prop,
    uint256 _val
  ) external onlyManager {
    ArrayUtils.ensureSameLength(_addr.length, _id.length);

    for (uint i = 0; i < _addr.length; i++) {
      add(_addr[i], _id[i], _type, _prop, _val);
    }
  }

  function addBatch(
    address[] calldata _addr,
    uint256[] calldata _id,
    uint256 _type,
    uint256 _prop,
    uint256[] calldata _val
  ) external onlyManager {
    ArrayUtils.ensureSameLength(_addr.length, _id.length);

    for (uint i = 0; i < _addr.length; i++) {
      add(_addr[i], _id[i], _type, _prop, _val[i]);
    }
  }

  function update(
    address _addr,
    uint256 _id,
    uint256 _type,
    uint256 _prop,
    uint256 _val
  ) external onlyManager {
    _update(_type, _addr, _id, _prop, _val);
  }

  function updateRaw(
    address _addr,
    uint256 _id,
    uint256 _type,
    uint24[10] calldata _val
  ) external onlyManager {
    _updateRaw(_addr, _id, _type, _val);
  }

  function updateBatch(
    address[] calldata _addr,
    uint256[] calldata _id,
    uint256 _type,
    uint256[][] calldata _prop,
    uint256[][] calldata _val
  ) external onlyManager {
    ArrayUtils.ensureSameLength(_addr.length, _id.length, _prop.length, _val.length);

    uint currentProp;
    for (uint i = 0; i < _addr.length; i++) {
      ArrayUtils.ensureSameLength(_prop[i].length, _val[i].length);
      uint24[10] storage values = _load(_addr[i], _id[i], _type);
      for (uint j = 0; j < _prop[i].length; j++) {
        values[_prop[i][j]] = uint24(_val[i][j]);
        emit UpdatedTo(_type, _addr[i], _id[i], _prop[i][j], _val[i][j]);
      }
    }
  }

  function updateBatch(
    address[] calldata _addr,
    uint256[] calldata _id,
    uint256 _type,
    uint256 _prop,
    uint256[] calldata _val
  ) external onlyManager {
    ArrayUtils.ensureSameLength(_addr.length, _id.length, _val.length);

    uint currentProp;
    for (uint i = 0; i < _addr.length; i++) {
      uint24[10] storage values = _load(_addr[i], _id[i], _type);
      values[_prop] = uint24(_val[i]);
      emit UpdatedTo(_type, _addr[i], _id[i], _prop, _val[i]);
    }
  }

  function updateBatchRaw(
    address[] calldata _addr,
    uint256[] calldata _id,
    uint256 _type,
    uint24[10][] calldata _val
  ) external onlyManager {
    ArrayUtils.ensureSameLength(_addr.length, _id.length, _val.length);
    for (uint i = 0; i < _addr.length; i++) {
      _updateRaw(_addr[i], _id[i], _type, _val[i]);
    }
  }

  function _updateRaw(address _addr, uint256 _id, uint256 _type, uint24[10] memory _val) internal {
    uint24[10] storage values = _load(_addr, _id, _type);
    for (uint j = 0; j < 10; j++) {
      if (values[j] != _val[j]) {
        values[j] = _val[j];
        emit UpdatedTo(_type, _addr, _id, j, _val[j]);
      }
    }
  }

  function remove(
    address _addr,
    uint256 _id,
    uint256 _type,
    uint256 _prop,
    uint256 _val
  ) external onlyManager {
    _remove(_addr, _id, _type, _prop, _val);
  }

  function removeBatch(
    address[] calldata _addr,
    uint256[] calldata _id,
    uint256 _type,
    uint256 _prop,
    uint256 _val
  ) external onlyManager {
    ArrayUtils.ensureSameLength(_addr.length, _id.length);

    for (uint i = 0; i < _addr.length; i++) {
      _remove(_addr[i], _id[i], _type, _prop, _val);
    }
  }

  function removeBatch(
    address[] calldata _addr,
    uint256[] calldata _id,
    uint256 _type,
    uint256 _prop,
    uint256[] calldata _val
  ) external onlyManager {
    ArrayUtils.ensureSameLength(_addr.length, _id.length, _val.length);

    for (uint i = 0; i < _addr.length; i++) {
      _remove(_addr[i], _id[i], _type, _prop, _val[i]);
    }
  }

  function removeBatch(
    address[] calldata _addr,
    uint256[] calldata _id,
    uint256 _type,
    uint256[][] calldata _prop,
    uint256[][] calldata _val
  ) external onlyManager {
    ArrayUtils.ensureSameLength(_addr.length, _id.length, _prop.length, _val.length);

    uint currentProp;
    for (uint i = 0; i < _addr.length; i++) {
      uint24[10] storage values = _load(_addr[i], _id[i], _type);
      uint24[10] memory mem = values;
      for (uint j = 0; j < _prop[i].length; j++) {
        if (_val[i][j] == 0) {
          continue;
        }
        currentProp = _prop[i][j];
        if (mem[currentProp] < uint24(_val[i][j])) {
          revert InvalidValue(_type, _addr[i], _id[i], currentProp, _val[i][j], mem[currentProp]);
        }
        mem[currentProp] -= uint24(_val[i][j]);
        values[currentProp] = mem[currentProp];
        emit RemovedFrom(_type, _addr[i], _id[i], _prop[i][j], _val[i][j], mem[currentProp]);
      }
    }
  }

  function get(
    address _addr,
    uint256 _id,
    uint256 _type,
    uint256 _prop
  ) external returns (uint256) {
    return _load(_addr, _id, _type)[_prop];
  }

  function getRaw(address _addr, uint256 _id, uint256 _type) external returns (uint24[10] memory) {
    return _load(_addr, _id, _type);
  }

  function getMulti(
    address _addr,
    uint256 _id,
    uint256 _type,
    uint256[] calldata _prop
  ) external returns (uint256[] memory result) {
    result = new uint[](_prop.length);
    uint24[10] memory mem = _load(_addr, _id, _type);
    for (uint i = 0; i < _prop.length; i++) {
      result[i] = mem[_prop[i]];
    }
  }

  function getBatch(
    address[] calldata _addr,
    uint256[] calldata _id,
    uint256 _type,
    uint256 _prop
  ) external returns (uint256[] memory result) {
    result = new uint[](_addr.length);
    uint24[10] memory mem;
    for (uint i = 0; i < _addr.length; i++) {
      mem = _load(_addr[i], _id[i], _type);
      result[i] = mem[_prop];
    }
  }

  function getBatchMulti(
    address[] calldata _addr,
    uint256[] calldata _id,
    uint256 _type,
    uint256[] calldata _prop
  ) external returns (uint256[][] memory result) {
    result = new uint[][](_addr.length);
    uint24[10] memory mem;
    for (uint i = 0; i < _addr.length; i++) {
      result[i] = new uint[](_prop.length);
      mem = _load(_addr[i], _id[i], _type);
      for (uint j = 0; j < _prop.length; j++) {
        result[i][j] = mem[_prop[j]];
      }
    }
  }

  function getRawBatch(
    address[] calldata _addrs,
    uint256[] calldata _ids,
    uint256 _type
  ) external returns (uint24[10][] memory result) {
    result = new uint24[10][](_addrs.length);
    for (uint i = 0; i < _addrs.length; i++) {
      result[i] = _load(_addrs[i], _ids[i], _type);
    }
  }

  function _update(
    uint256 _type,
    address _addr,
    uint256 _id,
    uint256 _prop,
    uint256 _val
  ) internal {
    uint24[10] storage values = _load(_addr, _id, _type);
    if (values[_prop] != _val) {
      values[_prop] = uint24(_val);
      emit UpdatedTo(_type, _addr, _id, _prop, _val);
    }
  }

  function _add(address _addr, uint256 _id, uint256 _type, uint256 _prop, uint256 _val) internal {
    if (_val == 0) {
      return;
    }
    uint24[10] storage values = _load(_addr, _id, _type);
    uint24 total = values[_prop];
    total += uint24(_val);
    values[_prop] = total;
    emit AddedTo(_type, _addr, _id, _prop, _val, total);
  }

  function _remove(
    address _addr,
    uint256 _id,
    uint256 _type,
    uint256 _prop,
    uint256 _val
  ) internal {
    if (_val == 0) {
      return;
    }
    uint24[10] storage values = _load(_addr, _id, _type);
    uint24 total = values[_prop];
    if (total < uint24(_val)) {
      revert InvalidValue(_type, _addr, _id, _prop, _val, total);
    }
    total -= uint24(_val);
    values[_prop] = total;
    emit RemovedFrom(_type, _addr, _id, _prop, _val, total);
  }

  function _load(
    address _addr,
    uint256 _id,
    uint256 _type
  ) internal returns (uint24[10] storage result) {
    result = STORAGE[_addr][_id][_type];

    if (_type > 1 || _isInitialized(result)) {
      return result;
    }
    _initLegacy(_addr, _id, result, _type);
  }

  function _isInitialized(uint24[10] storage _values) internal returns (bool) {
    return _values[0] != 0;
  }

  function _initLegacy(
    address _addr,
    uint256 _id,
    uint24[10] storage values,
    uint256 _type
  ) internal {
    if (_type == 0) {
      // Load legacy values
      values[traits.ADV_TRAIT_BASE_LEVEL] = uint24(
        LEGACY_DATA.aov(_addr, _id, traits.LEGACY_ADV_AOV_TRAIT_LEVEL)
      );
      emit UpdatedTo(
        _type,
        _addr,
        _id,
        traits.ADV_TRAIT_BASE_LEVEL,
        values[traits.ADV_TRAIT_BASE_LEVEL]
      );

      uint legacyHp = LEGACY_DATA.base(_addr, _id, traits.LEGACY_ADV_BASE_TRAIT_XP_BROKEN);
      if (legacyHp >= 100) {
        legacyHp -= 100;
      }
      values[traits.ADV_TRAIT_BASE_XP] = uint24(
        LEGACY_DATA.base(_addr, _id, traits.LEGACY_ADV_BASE_TRAIT_XP) + legacyHp
      );

      emit UpdatedTo(_type, _addr, _id, traits.ADV_TRAIT_BASE_XP, values[traits.ADV_TRAIT_BASE_XP]);

      uint totalTraits;
      values[traits.ADV_TRAIT_BASE_STRENGTH] = uint24(
        LEGACY_DATA.base(_addr, _id, traits.LEGACY_ADV_BASE_TRAIT_STRENGTH)
      );
      emit UpdatedTo(
        _type,
        _addr,
        _id,
        traits.ADV_TRAIT_BASE_STRENGTH,
        values[traits.ADV_TRAIT_BASE_STRENGTH]
      );
      totalTraits += values[traits.ADV_TRAIT_BASE_STRENGTH];

      values[traits.ADV_TRAIT_BASE_DEXTERITY] = uint24(
        LEGACY_DATA.base(_addr, _id, traits.LEGACY_ADV_BASE_TRAIT_DEXTERITY)
      );
      emit UpdatedTo(
        _type,
        _addr,
        _id,
        traits.ADV_TRAIT_BASE_DEXTERITY,
        values[traits.ADV_TRAIT_BASE_DEXTERITY]
      );
      totalTraits += values[traits.ADV_TRAIT_BASE_DEXTERITY];

      values[traits.ADV_TRAIT_BASE_CONSTITUTION] = uint24(
        LEGACY_DATA.base(_addr, _id, traits.LEGACY_ADV_BASE_TRAIT_CONSTITUTION)
      );
      emit UpdatedTo(
        _type,
        _addr,
        _id,
        traits.ADV_TRAIT_BASE_CONSTITUTION,
        values[traits.ADV_TRAIT_BASE_CONSTITUTION]
      );
      totalTraits += values[traits.ADV_TRAIT_BASE_CONSTITUTION];

      values[traits.ADV_TRAIT_BASE_INTELLIGENCE] = uint24(
        LEGACY_DATA.base(_addr, _id, traits.LEGACY_ADV_BASE_TRAIT_INTELLIGENCE)
      );
      emit UpdatedTo(
        _type,
        _addr,
        _id,
        traits.ADV_TRAIT_BASE_INTELLIGENCE,
        values[traits.ADV_TRAIT_BASE_INTELLIGENCE]
      );
      totalTraits += values[traits.ADV_TRAIT_BASE_INTELLIGENCE];

      values[traits.ADV_TRAIT_BASE_WISDOM] = uint24(
        LEGACY_DATA.base(_addr, _id, traits.LEGACY_ADV_BASE_TRAIT_WISDOM)
      );
      emit UpdatedTo(
        _type,
        _addr,
        _id,
        traits.ADV_TRAIT_BASE_WISDOM,
        values[traits.ADV_TRAIT_BASE_WISDOM]
      );
      totalTraits += values[traits.LEGACY_ADV_BASE_TRAIT_WISDOM];

      values[traits.ADV_TRAIT_BASE_CHARISMA] = uint24(
        LEGACY_DATA.base(_addr, _id, traits.LEGACY_ADV_BASE_TRAIT_CHARISMA)
      );
      emit UpdatedTo(
        _type,
        _addr,
        _id,
        traits.ADV_TRAIT_BASE_CHARISMA,
        values[traits.ADV_TRAIT_BASE_CHARISMA]
      );
      totalTraits += values[traits.ADV_TRAIT_BASE_CHARISMA];

      // Set base traits
      if (totalTraits < 30) {
        for (
          uint stat = traits.ADV_TRAIT_BASE_STRENGTH;
          stat < traits.ADV_TRAIT_BASE_CLASS;
          stat++
        ) {
          values[stat] += 5;
        }
      }

      values[traits.ADV_TRAIT_BASE_CLASS] = uint24(
        LEGACY_DATA.aov(_addr, _id, traits.LEGACY_ADV_AOV_TRAIT_CLASS)
      );
      if (values[traits.ADV_TRAIT_BASE_CLASS] == 0) {
        values[traits.ADV_TRAIT_BASE_CLASS] = 1;
      }
      emit UpdatedTo(
        _type,
        _addr,
        _id,
        traits.ADV_TRAIT_BASE_CLASS,
        values[traits.ADV_TRAIT_BASE_CLASS]
      );
    } else if (_type == 1) {
      values[traits.ADV_TRAIT_ADVANCED_ARCHETYPE] = uint24(
        LEGACY_DATA.aov(_addr, _id, traits.LEGACY_ADV_AOV_TRAIT_ARCHETYPE)
      );
      emit UpdatedTo(
        _type,
        _addr,
        _id,
        traits.ADV_TRAIT_ADVANCED_ARCHETYPE,
        values[traits.ADV_TRAIT_ADVANCED_ARCHETYPE]
      );

      values[traits.ADV_TRAIT_ADVANCED_PROFESSION] = uint24(
        LEGACY_DATA.aov(_addr, _id, traits.LEGACY_ADV_AOV_TRAIT_PROFESSION)
      );
      emit UpdatedTo(
        _type,
        _addr,
        _id,
        traits.ADV_TRAIT_ADVANCED_PROFESSION,
        values[traits.ADV_TRAIT_ADVANCED_PROFESSION]
      );
    }

    if (values[0] == 0) {
      values[0] = 1;
    }
  }

  function _loadLegacyValue(
    address _addr,
    uint256 _id,
    uint256 _type,
    uint256 _prop
  ) internal returns (uint24) {
    if (_type == ADVENTURER_DATA_BASE) {
      return uint24(LEGACY_DATA.base(_addr, _id, _prop));
    }
    if (_type == ADVENTURER_DATA_AOV) {
      return uint24(LEGACY_DATA.aov(_addr, _id, _prop));
    }
    if (_type == ADVENTURER_DATA_EXTENSION) {
      return uint24(LEGACY_DATA.extension(_addr, _id, _prop));
    }
    revert UnsupportedType(_type);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IAdventurerData {
  function initData(
    address[] calldata _addresses,
    uint256[] calldata _ids,
    bytes32[][] calldata _proofs,
    uint256[] calldata _professions,
    uint256[][] calldata _points
  ) external;

  function baseProperties(
    address _addr,
    uint256 _id,
    uint256 _start,
    uint256 _end
  ) external view returns (uint256[] memory);

  function aovProperties(
    address _addr,
    uint256 _id,
    uint256 _start,
    uint256 _end
  ) external view returns (uint256[] memory);

  function extensionProperties(
    address _addr,
    uint256 _id,
    uint256 _start,
    uint256 _end
  ) external view returns (uint256[] memory);

  function createFor(
    address _addr,
    uint256 _id,
    uint256[] calldata _points
  ) external;

  function createFor(address _addr, uint256 _id, uint256 _archetype) external;

  function addToBase(
    address _addr,
    uint256 _id,
    uint256 _prop,
    uint256 _val
  ) external;

  function updateBase(
    address _addr,
    uint256 _id,
    uint256 _prop,
    uint256 _val
  ) external;

  function removeFromBase(
    address _addr,
    uint256 _id,
    uint256 _prop,
    uint256 _val
  ) external;

  function addToAov(
    address _addr,
    uint256 _id,
    uint256 _prop,
    uint256 _val
  ) external;

  function updateAov(
    address _addr,
    uint256 _id,
    uint256 _prop,
    uint256 _val
  ) external;

  function removeFromAov(
    address _addr,
    uint256 _id,
    uint256 _prop,
    uint256 _val
  ) external;

  function addToExtension(
    address _addr,
    uint256 _id,
    uint256 _prop,
    uint256 _val
  ) external;

  function updateExtension(
    address _addr,
    uint256 _id,
    uint256 _prop,
    uint256 _val
  ) external;

  function removeFromExtension(
    address _addr,
    uint256 _id,
    uint256 _prop,
    uint256 _val
  ) external;

  function base(
    address _addr,
    uint256 _id,
    uint256 _prop
  ) external view returns (uint256);

  function aov(
    address _addr,
    uint256 _id,
    uint256 _prop
  ) external view returns (uint256);

  function extension(
    address _addr,
    uint256 _id,
    uint256 _prop
  ) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

uint constant ADVENTURER_DATA_BASE = 0;
uint constant ADVENTURER_DATA_AOV = 1;
uint constant ADVENTURER_DATA_EXTENSION = 2;

interface IBatchAdventurerData {
  function add(address _addr, uint256 _id, uint256 _type, uint256 _prop, uint256 _val) external;

  function addBatch(
    address[] calldata _addr,
    uint256[] calldata _id,
    uint256 _type,
    uint256[][] calldata _prop,
    uint256[][] calldata _val
  ) external;

  function addBatch(
    address[] calldata _addr,
    uint256[] calldata _id,
    uint256 _type,
    uint256 _prop,
    uint256 _val
  ) external;

  function addBatch(
    address[] calldata _addr,
    uint256[] calldata _id,
    uint256 _type,
    uint256 _prop,
    uint256[] calldata _val
  ) external;

  function update(address _addr, uint256 _id, uint256 _type, uint256 _prop, uint256 _val) external;

  function updateRaw(address _addr, uint256 _id, uint256 _type, uint24[10] calldata _val) external;

  function updateBatch(
    address[] calldata _addr,
    uint256[] calldata _id,
    uint256 _type,
    uint256 _prop,
    uint256[] calldata _val
  ) external;

  function updateBatchRaw(
    address[] calldata _addr,
    uint256[] calldata _id,
    uint256 _type,
    uint24[10][] calldata _val
  ) external;

  function remove(address _addr, uint256 _id, uint256 _type, uint256 _prop, uint256 _val) external;

  function removeBatch(
    address[] calldata _addr,
    uint256[] calldata _id,
    uint256 _type,
    uint256[][] calldata _prop,
    uint256[][] calldata _val
  ) external;

  function get(address _addr, uint256 _id, uint256 _type, uint256 _prop) external returns (uint256);

  function getRaw(address _addr, uint256 _id, uint256 _type) external returns (uint24[10] memory);

  function getMulti(
    address _addr,
    uint256 _id,
    uint256 _type,
    uint256[] calldata _prop
  ) external returns (uint256[] memory result);

  function getBatch(
    address[] calldata _addr,
    uint256[] calldata _id,
    uint256 _type,
    uint256 _prop
  ) external returns (uint256[] memory);

  function getBatchMulti(
    address[] calldata _addrs,
    uint256[] calldata _ids,
    uint256 _type,
    uint256[] calldata _props
  ) external returns (uint256[][] memory);

  function getRawBatch(
    address[] calldata _addrs,
    uint256[] calldata _ids,
    uint256 _type
  ) external returns (uint24[10][] memory result);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

library traits {
  uint256 public constant ADV_TRAIT_GROUP_BASE = 0;

  // Base, _type = 0
  uint256 public constant ADV_TRAIT_BASE_LEVEL = 0;
  uint256 public constant ADV_TRAIT_BASE_XP = 1;
  uint256 public constant ADV_TRAIT_BASE_STRENGTH = 2;
  uint256 public constant ADV_TRAIT_BASE_DEXTERITY = 3;
  uint256 public constant ADV_TRAIT_BASE_CONSTITUTION = 4;
  uint256 public constant ADV_TRAIT_BASE_INTELLIGENCE = 5;
  uint256 public constant ADV_TRAIT_BASE_WISDOM = 6;
  uint256 public constant ADV_TRAIT_BASE_CHARISMA = 7;
  uint256 public constant ADV_TRAIT_BASE_CLASS = 8;

  uint256 public constant ADV_TRAIT_GROUP_ADVANCED = 1;
  // Advanced, _type = 1
  uint256 public constant ADV_TRAIT_ADVANCED_ARCHETYPE = 0;
  uint256 public constant ADV_TRAIT_ADVANCED_PROFESSION = 1;
  uint256 public constant ADV_TRAIT_ADVANCED_TRAINING_POINTS = 2;

  // Base Ttraits
  // See AdventurerData.sol for details
  uint256 public constant LEGACY_ADV_BASE_TRAIT_XP = 0;
  uint256 public constant LEGACY_ADV_BASE_TRAIT_XP_BROKEN = 1;
  uint256 public constant LEGACY_ADV_BASE_TRAIT_STRENGTH = 2;
  uint256 public constant LEGACY_ADV_BASE_TRAIT_DEXTERITY = 3;
  uint256 public constant LEGACY_ADV_BASE_TRAIT_CONSTITUTION = 4;
  uint256 public constant LEGACY_ADV_BASE_TRAIT_INTELLIGENCE = 5;
  uint256 public constant LEGACY_ADV_BASE_TRAIT_WISDOM = 6;
  uint256 public constant LEGACY_ADV_BASE_TRAIT_CHARISMA = 7;
  uint256 public constant LEGACY_ADV_BASE_TRAIT_HP = 8;
  uint256 public constant LEGACY_ADV_BASE_TRAIT_HP_USED = 9;

  // AoV Traits
  // See AdventurerData.sol for details
  uint256 public constant LEGACY_ADV_AOV_TRAIT_LEVEL = 0;
  uint256 public constant LEGACY_ADV_AOV_TRAIT_ARCHETYPE = 1;
  uint256 public constant LEGACY_ADV_AOV_TRAIT_CLASS = 2;
  uint256 public constant LEGACY_ADV_AOV_TRAIT_PROFESSION = 3;

  function baseTraitNames() public pure returns (string[10] memory) {
    return [
      "Level",
      "XP",
      "Strength",
      "Dexterity",
      "Constitution",
      "Intelligence",
      "Wisdom",
      "Charisma",
      "Class",
      ""
    ];
  }

  function advancedTraitNames() public pure returns (string[2] memory) {
    return ["Archetype", "Profession"];
  }

  function baseTraitName(uint256 traitId) public pure returns (string memory) {
    return baseTraitNames()[traitId];
  }

  function advancedTraitName(uint256 traitId) public pure returns (string memory) {
    return advancedTraitNames()[traitId];
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IManager {
  function isAdmin(address _addr) external view returns (bool);

  function isManager(address _addr, uint256 _type) external view returns (bool);

  function addManager(address _addr, uint256 _type) external;

  function removeManager(address _addr, uint256 _type) external;

  function addAdmin(address _addr) external;

  function removeAdmin(address _addr) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "../Manager/IManager.sol";

abstract contract ManagerModifier {
  //=======================================
  // Immutables
  //=======================================
  IManager public immutable MANAGER;

  //=======================================
  // Constructor
  //=======================================
  constructor(address _manager) {
    MANAGER = IManager(_manager);
  }

  //=======================================
  // Modifiers
  //=======================================
  modifier onlyAdmin() {
    require(MANAGER.isAdmin(msg.sender), "Manager: Not an Admin");
    _;
  }

  modifier onlyManager() {
    require(MANAGER.isManager(msg.sender, 0), "Manager: Not manager");
    _;
  }

  modifier onlyMinter() {
    require(MANAGER.isManager(msg.sender, 1), "Manager: Not minter");
    _;
  }

  modifier onlyTokenMinter() {
    require(MANAGER.isManager(msg.sender, 2), "Manager: Not token minter");
    _;
  }

  modifier onlyBinder() {
    require(MANAGER.isManager(msg.sender, 3), "Manager: Not binder");
    _;
  }
}

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.17;

library ArrayUtils {
  error ArrayLengthMismatch(uint _length1, uint _length2);
  error InvalidArrayOrder(uint index);

  function ensureSameLength(uint _l1, uint _l2) internal pure {
    if (_l1 != _l2) {
      revert ArrayLengthMismatch(_l1, _l2);
    }
  }

  function ensureSameLength(uint _l1, uint _l2, uint _l3) internal pure {
    ensureSameLength(_l1, _l2);
    ensureSameLength(_l1, _l3);
  }

  function ensureSameLength(uint _l1, uint _l2, uint _l3, uint _l4) internal pure {
    ensureSameLength(_l1, _l2);
    ensureSameLength(_l1, _l3);
    ensureSameLength(_l1, _l4);
  }

  function ensureSameLength(uint _l1, uint _l2, uint _l3, uint _l4, uint _l5) internal pure {
    ensureSameLength(_l1, _l2);
    ensureSameLength(_l1, _l3);
    ensureSameLength(_l1, _l4);
    ensureSameLength(_l1, _l5);
  }

  function checkAddressesForDuplicates(address[] memory _tokenAddrs) internal pure {
    address lastAddress;
    for (uint i = 0; i < _tokenAddrs.length; i++) {
      if (lastAddress > _tokenAddrs[i]) {
        revert InvalidArrayOrder(i);
      }
      lastAddress = _tokenAddrs[i];
    }
  }

  function checkForDuplicates(uint[] memory _ids) internal pure {
    uint lastId;
    for (uint i = 0; i < _ids.length; i++) {
      if (lastId > _ids[i]) {
        revert InvalidArrayOrder(i);
      }
      lastId = _ids[i];
    }
  }

  function checkForDuplicates(address[] memory _tokenAddrs, uint[] memory _tokenIds) internal pure {
    address lastAddress;
    int256 lastTokenId = -1;
    for (uint i = 0; i < _tokenAddrs.length; i++) {
      if (_tokenAddrs[i] > lastAddress) {
        lastTokenId = -1;
      }

      if (_tokenAddrs[i] < lastAddress || int(_tokenIds[i]) <= lastTokenId) {
        revert InvalidArrayOrder(i);
      }
      lastAddress = _tokenAddrs[i];
      lastTokenId = int(_tokenIds[i]);
    }
  }

  function toMemoryArray(uint _value, uint _length) internal pure returns (uint[] memory result) {
    result = new uint[](_length);
    for (uint i = 0; i < _length; i++) {
      result[i] = _value;
    }
  }

  function toMemoryArray(uint[] calldata _value) internal pure returns (uint[] memory result) {
    result = new uint[](_value.length);
    for (uint i = 0; i < _value.length; i++) {
      result[i] = _value[i];
    }
  }

  function toMemoryArray(
    address _address,
    uint _length
  ) internal pure returns (address[] memory result) {
    result = new address[](_length);
    for (uint i = 0; i < _length; i++) {
      result[i] = _address;
    }
  }

  function toMemoryArray(
    address[] calldata _addresses
  ) internal pure returns (address[] memory result) {
    result = new address[](_addresses.length);
    for (uint i = 0; i < _addresses.length; i++) {
      result[i] = _addresses[i];
    }
  }
}